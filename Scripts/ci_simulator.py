#!/usr/bin/env python3
"""管理实验任务独占的 Simulator，并在删除前保存证据。"""

import argparse
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import uuid


def command(*args):
    result = subprocess.run(args, capture_output=True, text=True, timeout=60)
    if result.returncode:
        raise RuntimeError(f"{' '.join(map(str, args))}: {result.stderr.strip()}")
    return result.stdout.strip()


def save(path, data):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    temporary.replace(path)


def inventory():
    return json.loads(command("xcrun", "simctl", "list", "--json"))


def owned_device(state, data):
    identifier = state["simulatorId"]
    uuid.UUID(identifier)
    for runtime, devices in data["devices"].items():
        for device in devices:
            if device["udid"].lower() == identifier.lower():
                if (device["name"] != state["name"]
                        or device.get("deviceTypeIdentifier") != state["deviceTypeIdentifier"]
                        or runtime != state["runtimeIdentifier"]):
                    raise RuntimeError("Simulator ownership does not match; refusing to operate on it.")
                return device
    return None


def compatible_runtimes(arguments, data):
    expected_runtime = "27.1" if arguments.device == "iPhone Duo" else "27.2"
    if arguments.runtime != expected_runtime:
        raise RuntimeError(f"{arguments.device} requires iOS {expected_runtime}.")
    device_type = next((item for item in data["devicetypes"] if item["name"] == arguments.device), None)
    if not device_type:
        raise RuntimeError(f"Missing device type: {arguments.device}")
    runtimes = [item for item in data["runtimes"]
                if item.get("isAvailable") and item.get("version") == arguments.runtime
                and item["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-")
                and any(supported["identifier"] == device_type["identifier"]
                        for supported in item.get("supportedDeviceTypes", []))]
    return device_type, runtimes


def prepare_runtime(arguments, path):
    data = inventory()
    save(path.parent / "simulators-before-prepare.json", data)
    _, runtimes = compatible_runtimes(arguments, data)
    if not runtimes:
        # 仅用 27.2 会选中 Duo 专用包；指定截图基准的通用 runtime build。
        build_version = "24B114" if arguments.runtime == "27.2" else arguments.runtime
        subprocess.run([
            "xcodebuild", "-downloadPlatform", "iOS", "-buildVersion", build_version,
            "-architectureVariant", "arm64",
        ], check=True, timeout=1800)
        data = inventory()
        _, runtimes = compatible_runtimes(arguments, data)
    save(path.parent / "simulators-after-prepare.json", data)
    if len(runtimes) != 1:
        raise RuntimeError(f"Runtime preparation did not produce exactly one compatible iOS "
                           f"{arguments.runtime} runtime for {arguments.device}; found {len(runtimes)}.")
    print(f"Runtime ready: {runtimes[0]['identifier']} ({runtimes[0].get('buildversion', 'unknown build')})")


def start(arguments, path):
    version = command("xcodebuild", "-version")
    if version.splitlines()[0] != "Xcode 27.2":
        raise RuntimeError("Experiment requires Xcode 27.2 (the installed RC is allowed).")
    sdk = command("xcodebuild", "-sdk", "iphonesimulator", "-version", "SDKVersion")
    if sdk != "27.2":
        raise RuntimeError("Experiment requires iPhoneSimulator SDK 27.2.")
    if path.exists():
        state = json.loads(path.read_text())
        if (state["task"] != arguments.task or state["device"] != arguments.device
                or state["runtimeVersion"] != arguments.runtime or state["status"] != "active"):
            raise RuntimeError("This state belongs to another or finished experiment; use a new state path.")
        device = owned_device(state, inventory())
        if not device or not device.get("isAvailable"):
            raise RuntimeError("The experiment's Simulator is missing or unavailable; finish it explicitly.")
        return state

    data = inventory()
    device_type, runtimes = compatible_runtimes(arguments, data)
    if len(runtimes) != 1:
        raise RuntimeError(f"Expected one compatible iOS {arguments.runtime} runtime for {arguments.device}; "
                           f"found {len(runtimes)}. Install/check the requested runtime in Xcode.")
    runtime = runtimes[0]
    label = re.sub(r"[^a-zA-Z0-9._-]+", "-", arguments.task)[:80]
    name = f"ChineseCalendar {label} {arguments.device} {uuid.uuid4().hex[:8]}"
    state = {
        "task": arguments.task, "name": name, "device": arguments.device,
        "deviceTypeIdentifier": device_type["identifier"],
        "runtimeIdentifier": runtime["identifier"], "runtimeVersion": runtime["version"],
        "runtimeBuild": runtime.get("buildversion"), "xcode": version, "sdk": sdk,
        "developerDir": os.environ.get("DEVELOPER_DIR") or command("xcode-select", "-p"),
        "createdAt": datetime.now(timezone.utc).isoformat(), "status": "creating",
    }
    # 先留下归属意图；若进程在 create 返回前被强杀，可用唯一名称定位异常残留。
    save(path, state)
    identifier = command("xcrun", "simctl", "create", name, device_type["identifier"], runtime["identifier"])
    uuid.UUID(identifier)
    state.update(simulatorId=identifier, status="active")
    save(path, state)
    return state


def finish(path):
    if not path.exists():
        return
    state = json.loads(path.read_text())
    if state["status"] == "deleted":
        return
    data = inventory()
    if "simulatorId" not in state:
        # 只恢复预先记录的唯一名称，写下实际 UUID 后才能执行删除。
        candidates = [device for devices in data["devices"].values() for device in devices
                      if device["name"] == state["name"]]
        if len(candidates) > 1:
            raise RuntimeError("Ambiguous interrupted creation; refusing cleanup.")
        if not candidates:
            state.update(status="deleted", finishedAt=datetime.now(timezone.utc).isoformat())
            save(path, state)
            return
        state["simulatorId"] = candidates[0]["udid"]
        save(path, state)
    device = owned_device(state, data)
    diagnostics = path.parent / "device"
    diagnostics.mkdir(exist_ok=True)
    save(diagnostics / "inventory-before-cleanup.json", data)
    if device:
        identifier = state["simulatorId"]
        if device.get("state") == "Booted":
            for name, args in (
                ("screenshot", ("xcrun", "simctl", "io", identifier, "screenshot", str(diagnostics / "screen.png"))),
                ("system-log", ("xcrun", "simctl", "spawn", identifier, "log", "show", "--last", "5m", "--style", "compact")),
            ):
                try:
                    (diagnostics / f"{name}.txt").write_text(command(*args))
                except (RuntimeError, subprocess.TimeoutExpired) as error:
                    (diagnostics / f"{name}-error.txt").write_text(str(error))
            command("xcrun", "simctl", "shutdown", identifier)
        command("xcrun", "simctl", "delete", identifier)
    if owned_device(state, inventory()):
        raise RuntimeError("Simulator still exists after cleanup.")
    state.update(status="deleted", finishedAt=datetime.now(timezone.utc).isoformat())
    save(path, state)


def seal(directory):
    manifest = directory / "sha256.json"
    files = {}
    for path in sorted(directory.rglob("*")):
        if path.is_file() and path != manifest:
            digest = hashlib.sha256()
            with path.open("rb") as source:
                for block in iter(lambda: source.read(1024 * 1024), b""):
                    digest.update(block)
            files[str(path.relative_to(directory))] = digest.hexdigest()
    save(manifest, files)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("prepare-runtime", "start", "finish"))
    parser.add_argument("--state", required=True, type=Path)
    parser.add_argument("--task")
    parser.add_argument("--device", choices=("iPhone 18 Pro Max", "iPad Pro 13-inch (M5)", "iPhone Duo"))
    parser.add_argument("--runtime", choices=("27.1", "27.2"))
    args = parser.parse_args()
    if args.action == "start" and not all((args.task, args.device, args.runtime)):
        parser.error("start requires --task, --device, and --runtime")
    if args.action == "prepare-runtime" and not all((args.device, args.runtime)):
        parser.error("prepare-runtime requires --device and --runtime")
    path = args.state.expanduser().resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    # 同一任务目录串行处理；不同任务不共享设备或锁。
    with path.with_suffix(".lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            if args.action == "prepare-runtime":
                prepare_runtime(args, path)
            elif args.action == "start":
                state = start(args, path)
                print(state["simulatorId"])
            else:
                try:
                    finish(path)
                finally:
                    seal(path.parent)
        except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
            print(f"error: {error}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
