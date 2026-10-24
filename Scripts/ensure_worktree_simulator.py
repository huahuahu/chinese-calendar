#!/usr/bin/env python3
"""根据本机配置为当前 Git worktree 分配独立模拟器。"""

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import stat
import subprocess
import sys
import tempfile
import time

try:
    import yaml
except ModuleNotFoundError:
    yaml = None


class WorktreeSimulator:
    CONFIG_PATH = Path(".xcodebuildmcp/config.yaml")
    TEMPLATE_PATH = Path(".xcodebuildmcp/config.example.yaml")
    # 与截图基准固定为同一机型和系统版本，安装新 runtime 后也不自动升级。
    DEVICE_TYPE_NAME = "iPhone 18 Pro Max"
    DEVICE_TYPE_ID = "com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max"
    RUNTIME_ID = "com.apple.CoreSimulator.SimRuntime.iOS-27-0"
    UUID_PATTERN = re.compile(r"[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}", re.IGNORECASE)

    def __init__(self, root, dry_run=False):
        self.root = Path(root).resolve(strict=True)
        self.dry_run = dry_run
        self.config_path = self.root / self.CONFIG_PATH

    def run(self):
        top = Path(self.command("git", "-C", self.root, "rev-parse", "--show-toplevel").strip()).resolve()
        if top != self.root:
            raise RuntimeError("Pass the Git worktree root with --worktree.")

        common = self.command("git", "-C", self.root, "rev-parse", "--git-common-dir").strip()
        common = (self.root / common).resolve()
        # 所有 worktree 共用这把锁；不删除锁文件，避免并发进程锁住不同 inode。
        descriptor = os.open(common / "worktree-simulator.lock", os.O_RDWR | os.O_CREAT, 0o600)
        with os.fdopen(descriptor, "r+") as lock:
            deadline = time.monotonic() + 30
            while True:
                try:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    if time.monotonic() >= deadline:
                        raise RuntimeError("Timed out waiting for another simulator allocation. Retry later.")
                    time.sleep(0.1)
            self.allocate()

    @staticmethod
    def command(*arguments):
        result = subprocess.run(arguments, capture_output=True, text=True, encoding="utf-8")
        if result.returncode:
            raise RuntimeError(f"{arguments[0]} failed: {result.stderr.strip()}")
        return result.stdout

    @staticmethod
    def read_config(path, source=None):
        try:
            config = yaml.safe_load(path.read_bytes() if source is None else source)
        except yaml.YAMLError as error:
            raise RuntimeError(f"{path}: invalid YAML: {error}") from error
        if not isinstance(config, dict) or not isinstance(config.get("sessionDefaults"), dict):
            raise RuntimeError(f"{path}: expected a sessionDefaults mapping.")
        for key in ("simulatorId", "simulatorName"):
            value = config["sessionDefaults"].get(key)
            if value is not None and (not isinstance(value, str) or not value.strip()):
                raise RuntimeError(f"{path}: {key} must be a nonempty string.")
        return config

    def other_references(self):
        output = self.command("git", "-C", self.root, "worktree", "list", "--porcelain", "-z")
        references = []
        for field in output.split("\0"):
            if not field.startswith("worktree "):
                continue
            path = Path(field.removeprefix("worktree "))
            if not path.is_dir() or path.resolve() == self.root:
                continue
            config = path / self.CONFIG_PATH
            if config.is_file():
                references.append((path, self.read_config(config)["sessionDefaults"]))
        return references

    def inventory(self):
        data = json.loads(self.command("xcrun", "simctl", "list", "--json"))
        self.runtimes = [runtime for runtime in data["runtimes"] if runtime.get("isAvailable")]
        self.types = data["devicetypes"]
        self.devices = [
            dict(device, runtimeIdentifier=runtime)
            for runtime, devices in data["devices"].items()
            for device in devices
        ]

    def available(self, device):
        return device.get("isAvailable") and any(
            runtime["identifier"] == device["runtimeIdentifier"] for runtime in self.runtimes
        )

    def matches_target(self, device):
        return (device.get("deviceTypeIdentifier") == self.DEVICE_TYPE_ID
                and device["runtimeIdentifier"] == self.RUNTIME_ID)

    def configured_device(self, defaults):
        identifier = defaults.get("simulatorId")
        if identifier:
            device = next((item for item in self.devices if item["udid"].lower() == identifier.lower()), None)
            if device is None or not self.available(device):
                raise RuntimeError(
                    f"Configured simulator {identifier} is missing or unavailable. "
                    f"Fix {self.CONFIG_PATH}; no device was changed."
                )
            if not self.matches_target(device):
                raise RuntimeError(
                    f"Configured simulator {identifier} must use {self.DEVICE_TYPE_NAME} / iOS 27.0 "
                    f"for the snapshot baseline. Fix {self.CONFIG_PATH}; no device was changed."
                )
            return device

        name = defaults.get("simulatorName")
        if not name:
            raise RuntimeError(f"{self.CONFIG_PATH}: set simulatorId or simulatorName.")
        matches = [item for item in self.devices
                   if self.available(item) and self.matches_target(item) and item["name"] == name]
        if len(matches) > 1:
            raise RuntimeError(f"Multiple available simulators named {name!r}; set an explicit simulatorId.")
        return matches[0] if matches else None

    def creation_target(self, defaults, device):
        if device:
            return self.DEVICE_TYPE_ID, self.RUNTIME_ID
        if defaults.get("simulatorName") != self.DEVICE_TYPE_NAME:
            raise RuntimeError(
                f"No matching simulator named {defaults.get('simulatorName')!r}. "
                f"Set simulatorName to {self.DEVICE_TYPE_NAME!r} for the iOS 27.0 snapshot baseline."
            )
        device_type = next((item for item in self.types if item["identifier"] == self.DEVICE_TYPE_ID), None)
        if device_type is None:
            raise RuntimeError(f"Xcode is missing the {self.DEVICE_TYPE_NAME} Simulator device type.")

        runtime = next((
            runtime for runtime in self.runtimes
            if runtime["identifier"] == self.RUNTIME_ID
            and any(item["identifier"] == device_type["identifier"]
                    for item in runtime.get("supportedDeviceTypes", []))
        ), None)
        if runtime is None:
            raise RuntimeError(
                f"No available iOS 27.0 runtime supports {self.DEVICE_TYPE_NAME}. Install it in Xcode."
            )
        return device_type["identifier"], runtime["identifier"]

    def write_config(self, config, expected_source):
        if self.config_path.is_symlink():
            raise RuntimeError(f"Refusing to replace a symlink: {self.config_path}")
        current = self.config_path.read_bytes() if self.config_path.exists() else None
        if current != expected_source:
            raise RuntimeError("Configuration changed during allocation. Retry with the updated file.")

        directory = self.config_path.parent
        directory.mkdir(parents=True, exist_ok=True)
        mode = stat.S_IMODE(self.config_path.stat().st_mode) if self.config_path.exists() else 0o600
        # 在同目录写临时文件后 replace，避免其他读者看到半份 YAML。
        descriptor, name = tempfile.mkstemp(prefix=".simulator-config-", suffix=".yaml", dir=directory)
        temporary = Path(name)
        try:
            with os.fdopen(descriptor, "w", encoding="utf-8") as file:
                os.fchmod(file.fileno(), mode)
                yaml.safe_dump(config, file, allow_unicode=True, sort_keys=False)
                file.flush()
                os.fsync(file.fileno())
            os.replace(temporary, self.config_path)
        finally:
            temporary.unlink(missing_ok=True)

    def allocate(self):
        if self.config_path.is_symlink():
            raise RuntimeError(f"Refusing to replace a symlink: {self.config_path}")
        original = self.config_path.read_bytes() if self.config_path.is_file() else None
        source = self.config_path if original is not None else self.root / self.TEMPLATE_PATH
        config = self.read_config(source, original)
        defaults = config["sessionDefaults"]
        references = self.other_references()
        self.inventory()
        device = self.configured_device(defaults)
        conflicts = [
            path for path, other in references
            if device and (
                other["simulatorId"].lower() == device["udid"].lower() if other.get("simulatorId")
                else other.get("simulatorName") == device["name"]
            )
        ]

        if device and not conflicts:
            if self.dry_run:
                print(f"Would reuse {device['name']} ({device['udid']}); no other worktree references it.", file=sys.stderr)
            else:
                if (original is None or defaults.get("simulatorId") != device["udid"]
                        or defaults.get("simulatorName") != device["name"]):
                    defaults.update(simulatorId=device["udid"], simulatorName=device["name"])
                    self.write_config(config, original)
                print(f"Using {device['name']} ({device['udid']}).", file=sys.stderr)
            print(device["udid"])
            return

        for path in conflicts:
            print(f"Simulator is also referenced by {path}.", file=sys.stderr)
        device_type, runtime = self.creation_target(defaults, device)
        type_name = next((item["name"] for item in self.types if item["identifier"] == device_type),
                         defaults.get("simulatorName"))
        suffix = hashlib.sha256(str(self.root).encode("utf-8")).hexdigest()[:10]
        name = f"{self.root.name} {type_name} ({suffix})"
        if self.dry_run:
            print(f"Would create {name} using {device_type} / {runtime} and update {self.config_path}.", file=sys.stderr)
            return

        identifier = self.command("xcrun", "simctl", "create", name, device_type, runtime).strip()
        if not self.UUID_PATTERN.fullmatch(identifier):
            raise RuntimeError(f"simctl create returned an invalid UUID: {identifier!r}")
        try:
            defaults.update(simulatorId=identifier, simulatorName=name)
            self.write_config(config, original)
        except Exception:
            # 只回收本次刚创建且尚未写入配置的设备，不碰已有设备。
            try:
                self.command("xcrun", "simctl", "delete", identifier)
            except Exception as cleanup_error:
                print(f"Could not remove newly created simulator {identifier}: {cleanup_error}", file=sys.stderr)
            raise
        print(f"Created {name} ({identifier}); updated {self.config_path}.", file=sys.stderr)
        print(identifier)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worktree", type=Path, default=Path(__file__).resolve().parent.parent,
                        help="Git worktree root (defaults to this script's repository)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show the decision without creating a simulator or writing config")
    arguments = parser.parse_args()
    if yaml is None:
        requirements = Path(__file__).resolve().with_name("requirements.txt")
        install = shlex.join(["python3", "-m", "pip", "install", "-r", str(requirements)])
        print(f"error: PyYAML is required. Activate a virtual environment and install dependencies: {install}",
              file=sys.stderr)
        return 1
    try:
        WorktreeSimulator(arguments.worktree, arguments.dry_run).run()
    except (OSError, ValueError, KeyError, RuntimeError, yaml.YAMLError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
