#!/usr/bin/env python3
"""通过真实 Git worktree 和模拟的 simctl 验证工作区模拟器分配。"""

import copy
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import textwrap
import unittest

import yaml


SCRIPT = Path(__file__).resolve().parents[1] / "ensure_worktree_simulator.py"
CONFIG = Path(".xcodebuildmcp/config.yaml")
TEMPLATE = Path(".xcodebuildmcp/config.example.yaml")
ORIGINAL_ID = "AAAAAAAA-1111-2222-3333-444444444444"
OTHER_ID = "BBBBBBBB-1111-2222-3333-444444444444"
DEVICE_NAME = "Calendar simulator"
DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-27-0"
NEWER_RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-27-1"
SNAPSHOT_RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-27-0"


# fake xcrun 自己使用文件锁，防止测试库存损坏；分配脚本仍须保护读取配置到写回的整个事务。
FAKE_XCRUN = r'''import fcntl
import json
import os
from pathlib import Path
import sys
import time

state_path = Path(os.environ["SIMULATOR_TEST_STATE"])
with state_path.with_suffix(".lock").open("a") as lock:
    fcntl.flock(lock, fcntl.LOCK_EX)
    state = json.loads(state_path.read_text())
    arguments = sys.argv[1:]
    state["calls"].append(arguments)
    output = ""
    error = None
    if arguments == ["simctl", "list", "--json"]:
        output = json.dumps({key: state[key] for key in ("devices", "runtimes", "devicetypes")})
    elif len(arguments) == 5 and arguments[:2] == ["simctl", "create"]:
        state["create_attempts"] += 1
        time.sleep(state.get("create_delay", 0))
        if state.get("fail_create"):
            error = "Requested simulator creation failure"
        else:
            name, device_type, runtime = arguments[2:]
            identifier = "CCCCCCCC-1111-2222-3333-{:012d}".format(state["create_attempts"])
            state["devices"].setdefault(runtime, []).append({
                "udid": identifier,
                "name": name,
                "deviceTypeIdentifier": device_type,
                "isAvailable": True,
                "state": "Shutdown",
            })
            output = identifier
            if state.get("mutate_config"):
                Path(state["mutate_config"]["path"]).write_text(state["mutate_config"]["text"])
    elif len(arguments) == 3 and arguments[:2] == ["simctl", "delete"]:
        for runtime in state["devices"]:
            state["devices"][runtime] = [
                device for device in state["devices"][runtime] if device["udid"] != arguments[2]
            ]
    else:
        error = "Unexpected xcrun invocation: " + repr(arguments)
    state_path.write_text(json.dumps(state))
    if error:
        print(error, file=sys.stderr)
        sys.exit(1)
    if output:
        print(output)
'''


# 只接受截图入口需要的三个命令，任何意外调用都使测试失败。
FAKE_XCODEBUILD = r'''import json
import os
from pathlib import Path
import sys

arguments = sys.argv[1:]
with Path(os.environ["SNAPSHOT_TEST_XCODEBUILD_LOG"]).open("a") as log:
    log.write(json.dumps(arguments) + "\n")
if arguments == ["-version"]:
    print("Xcode 27.1\nBuild version 18B00")
elif arguments == ["-sdk", "iphonesimulator", "-version", "SDKVersion"]:
    print("27.1")
elif arguments and arguments[-1] == "test" and "-destination" in arguments:
    print("Fake snapshot tests passed")
else:
    sys.exit("Unexpected xcodebuild invocation: " + repr(arguments))
'''


class WorktreeSimulatorTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="simulator allocation tests ")
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.root = self.base / "main checkout with spaces"
        self.root.mkdir()
        self.state_path = self.base / "simulator state.json"
        self.bin_path = self.base / "fake tools"
        self.bin_path.mkdir()
        self.write_fake_python_tool("xcrun", FAKE_XCRUN)
        self.env = os.environ.copy()
        self.env.update({
            "PATH": str(self.bin_path) + os.pathsep + self.env.get("PATH", ""),
            "SIMULATOR_TEST_STATE": str(self.state_path),
            "GIT_AUTHOR_NAME": "Simulator Tests",
            "GIT_AUTHOR_EMAIL": "simulator-tests@example.invalid",
            "GIT_COMMITTER_NAME": "Simulator Tests",
            "GIT_COMMITTER_EMAIL": "simulator-tests@example.invalid",
        })
        # 不继承调用者的仓库上下文，确保所有 Git 操作仅发生在临时目录。
        for key in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
            self.env.pop(key, None)
        self.git("init", "--quiet")
        (self.root / ".gitignore").write_text(".xcodebuildmcp/config.yaml\n")
        self.git("add", ".gitignore")
        self.git("-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null",
                 "commit", "--quiet", "-m", "Create temporary fixture")
        self.config = {
            "schemaVersion": 1,
            "enabledWorkflows": ["debugging", "simulator", "ui-automation"],
            "debug": True,
            "sentryDisabled": False,
            "setupPreferences": {"platforms": ["iOS"], "label": "测试设置"},
            "sessionDefaults": {
                "projectPath": "A project/Calendar.xcodeproj",
                "scheme": "Calendar-iOS",
                "configuration": "Debug",
                "simulatorId": ORIGINAL_ID,
                "simulatorName": DEVICE_NAME,
                "derivedDataPath": "build data",
            },
        }
        self.save_state({
            "devices": {RUNTIME: [self.device(ORIGINAL_ID, DEVICE_NAME)]},
            "runtimes": [self.runtime(RUNTIME, "27.0"), self.runtime(NEWER_RUNTIME, "27.1")],
            "devicetypes": [{"identifier": DEVICE_TYPE, "name": "iPhone 18 Pro Max"}],
            "create_attempts": 0,
            "calls": [],
        })

    @staticmethod
    def device(identifier, name, available=True):
        return {"udid": identifier, "name": name, "deviceTypeIdentifier": DEVICE_TYPE,
                "isAvailable": available, "state": "Shutdown"}

    @staticmethod
    def runtime(identifier, version, available=True):
        return {"identifier": identifier, "version": version, "isAvailable": available,
                "supportedDeviceTypes": [{"identifier": DEVICE_TYPE}]}

    def git(self, *arguments):
        return subprocess.run(["git", "-C", str(self.root), *arguments], env=self.env,
                              capture_output=True, text=True, check=True, timeout=15)

    def worktree(self, name="linked checkout with spaces"):
        path = self.base / name
        self.git("worktree", "add", "--quiet", "--detach", str(path), "HEAD")
        return path

    def save_state(self, state):
        self.state_path.write_text(json.dumps(state))

    def state(self):
        return json.loads(self.state_path.read_text())

    def write_config(self, root=None, config=None, template=False):
        path = (root or self.root) / (TEMPLATE if template else CONFIG)
        path.parent.mkdir(parents=True, exist_ok=True)
        # JSON 是合法 YAML，输入序列化与脚本的 YAML 输出实现保持独立。
        path.write_text(json.dumps(config if config is not None else self.config,
                                   ensure_ascii=False, indent=2) + "\n")
        return path

    def read_config(self, root=None):
        # 比较 YAML 的语义而非序列化格式。
        return yaml.safe_load(((root or self.root) / CONFIG).read_text())

    def command(self, root=None, dry_run=False):
        command = [sys.executable, str(SCRIPT), "--worktree", str(root or self.root)]
        if dry_run:
            command.append("--dry-run")
        return command

    def run_allocator(self, root=None, dry_run=False, success=True):
        result = subprocess.run(self.command(root, dry_run), env=self.env,
                                capture_output=True, text=True, timeout=20)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(result.stdout, "")
            self.assertTrue(result.stderr.strip())
        return result

    def assert_selected(self, result, identifier):
        self.assertEqual(result.stdout, identifier + "\n")

    def assert_other_settings_unchanged(self, actual, expected=None):
        expected = copy.deepcopy(expected if expected is not None else self.config)
        actual = copy.deepcopy(actual)
        for document in (expected, actual):
            for field in ("simulatorId", "simulatorName"):
                document["sessionDefaults"].pop(field, None)
        self.assertEqual(actual, expected)

    def shared_device(self):
        other = self.worktree()
        self.write_config(other)
        self.write_config()
        return other

    def write_fake_python_tool(self, name, source):
        payload = self.bin_path / (name + ".py")
        payload.write_text(source)
        launcher = self.bin_path / name
        # shebang 无法引用含空格的解释器路径；用 shell 的 exec 精确启动工具载荷。
        launcher.write_text("#!/bin/sh\nexec " + shlex.quote(sys.executable) + " "
                            + shlex.quote(str(payload)) + ' "$@"\n')
        launcher.chmod(0o755)

    def prepare_snapshot_entrypoint(self):
        scripts = self.root / "Scripts"
        scripts.mkdir()
        for source in (SCRIPT, SCRIPT.with_name("test_snapshots.sh")):
            (scripts / source.name).write_bytes(source.read_bytes())
        (self.root / "ChineseCalendar.xcodeproj").mkdir()
        fake_sources = {
            "uname": "import sys\nassert sys.argv[1:] == ['-m']\nprint('arm64')\n",
            "xcodebuild": FAKE_XCODEBUILD,
        }
        for name, source in fake_sources.items():
            self.write_fake_python_tool(name, source)
        # shell 中的 python3 与测试进程共用解释器和已经安装的 PyYAML。
        python = self.bin_path / "python3"
        python.write_text("#!/bin/sh\nexec " + shlex.quote(sys.executable) + ' "$@"\n')
        python.chmod(0o755)
        state = self.state()
        state["devices"] = {SNAPSHOT_RUNTIME: [
            self.device(ORIGINAL_ID, "First inventory simulator"),
            self.device(OTHER_ID, DEVICE_NAME),
        ]}
        self.save_state(state)

    def run_snapshot_entrypoint(self, overrides=None):
        env = self.env.copy()
        for key in ("CI", "GITHUB_ACTIONS", "SNAPSHOT_SIMULATOR_ID", "SNAPSHOT_RECORD"):
            env.pop(key, None)
        env.update(overrides or {})
        log = self.base / "snapshot xcodebuild calls.jsonl"
        log.write_text("")
        env["SNAPSHOT_TEST_XCODEBUILD_LOG"] = str(log)
        result = subprocess.run(["bash", str(self.root / "Scripts/test_snapshots.sh")],
                                env=env, cwd=self.root, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        commands = [json.loads(line) for line in log.read_text().splitlines()]
        tests = [arguments for arguments in commands if arguments[-1] == "test"]
        self.assertEqual(len(tests), 1, commands)
        arguments = tests[0]
        return arguments[arguments.index("-destination") + 1]

    def test_snapshot_entrypoint_uses_configured_uuid_with_commented_or_flow_yaml(self):
        self.prepare_snapshot_entrypoint()
        config = copy.deepcopy(self.config)
        config["sessionDefaults"]["simulatorId"] = OTHER_ID
        path = self.write_config(config=config)
        sources = {
            "commented": textwrap.dedent(f"""\
                schemaVersion: 1
                sessionDefaults: # 工作区默认配置
                  simulatorId: {OTHER_ID}
                  simulatorName: {DEVICE_NAME}
                  scheme: ChineseCalendar-iOS
            """),
            "flow": json.dumps(config),
        }
        for name, source in sources.items():
            with self.subTest(format=name):
                path.write_text(source)
                destination = self.run_snapshot_entrypoint()
                self.assertEqual(destination, f"platform=iOS Simulator,id={OTHER_ID},arch=arm64")
                self.assertEqual(path.read_text(), source)
                self.assertEqual(self.state()["create_attempts"], 0)

    def test_snapshot_explicit_uuid_bypasses_local_allocator(self):
        self.prepare_snapshot_entrypoint()
        path = self.write_config()
        source = "sessionDefaults: [无效配置\n"
        path.write_text(source)
        destination = self.run_snapshot_entrypoint({"SNAPSHOT_SIMULATOR_ID": OTHER_ID})
        self.assertEqual(destination, f"platform=iOS Simulator,id={OTHER_ID},arch=arm64")
        self.assertEqual(path.read_text(), source)
        self.assertEqual(self.state()["calls"], [["simctl", "list", "--json"]])

    def test_snapshot_ci_uses_runner_inventory_without_reading_local_config(self):
        self.prepare_snapshot_entrypoint()
        path = self.write_config()
        source = "sessionDefaults: [无效配置\n"
        path.write_text(source)
        destination = self.run_snapshot_entrypoint({"CI": "true", "GITHUB_ACTIONS": "true"})
        self.assertEqual(destination, f"platform=iOS Simulator,id={ORIGINAL_ID},arch=arm64")
        self.assertEqual(path.read_text(), source)
        self.assertEqual(self.state()["calls"], [["simctl", "list", "--json"]])

    def test_missing_pyyaml_reports_dependency_without_changing_configuration(self):
        path = self.write_config()
        before = path.read_bytes()
        command = self.command()
        # 隔离 PYTHONPATH 并禁用 site packages，模拟尚未安装 PyYAML 的 CI 环境。
        command[1:1] = ["-I", "-S"]
        result = subprocess.run(command, env=self.env, capture_output=True,
                                text=True, timeout=20)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("PyYAML", result.stderr)
        self.assertNotIn("Traceback", result.stderr)
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(self.state()["calls"], [])

    def test_unique_configured_device_preserves_exact_file(self):
        path = self.root / CONFIG
        path.parent.mkdir(parents=True)
        source = textwrap.dedent(f"""\
            # 保留已有工作区的注释与格式。
            schemaVersion: 1
            debug: true
            sessionDefaults:
              simulatorId: {ORIGINAL_ID}
              simulatorName: '{DEVICE_NAME}'
              scheme: Calendar-iOS
        """)
        path.write_text(source)
        self.assert_selected(self.run_allocator(), ORIGINAL_ID)
        self.assertEqual(path.read_text(), source)
        self.assertEqual(self.state()["create_attempts"], 0)
        self.assertEqual(self.state()["calls"], [["simctl", "list", "--json"]])

    def test_shared_uuid_creates_same_type_and_runtime_only_for_current_worktree(self):
        other = self.shared_device()
        other_before = (other / CONFIG).read_bytes()
        result = self.run_allocator()
        actual = self.read_config()
        identifier = actual["sessionDefaults"]["simulatorId"]
        self.assertNotEqual(identifier, ORIGINAL_ID)
        self.assert_selected(result, identifier)
        self.assert_other_settings_unchanged(actual)
        self.assertEqual((other / CONFIG).read_bytes(), other_before)
        state = self.state()
        self.assertEqual(state["create_attempts"], 1)
        created = next(device for device in state["devices"][RUNTIME]
                       if device["udid"] == identifier)
        self.assertEqual(created["deviceTypeIdentifier"], DEVICE_TYPE)
        self.assertEqual(created["name"], actual["sessionDefaults"]["simulatorName"])
        self.assertEqual([call for call in state["calls"] if call[:2] == ["simctl", "create"]][0][3:],
                         [DEVICE_TYPE, RUNTIME])
        self.assertEqual(len(state["devices"][RUNTIME]), 2)

    def test_uuid_conflict_is_case_insensitive(self):
        other = self.shared_device()
        config = copy.deepcopy(self.config)
        config["sessionDefaults"]["simulatorId"] = ORIGINAL_ID.lower()
        self.write_config(other, config)
        self.run_allocator()
        self.assertEqual(self.state()["create_attempts"], 1)

    def test_same_name_with_different_explicit_uuid_is_not_a_conflict(self):
        other = self.worktree()
        config = copy.deepcopy(self.config)
        config["sessionDefaults"]["simulatorId"] = OTHER_ID
        self.write_config(other, config)
        path = self.write_config()
        before = path.read_bytes()
        self.assert_selected(self.run_allocator(), ORIGINAL_ID)
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_missing_uuid_does_not_fall_back_to_matching_name(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"]["simulatorId"] = OTHER_ID
        path = self.write_config(config=config)
        before = path.read_bytes()
        self.run_allocator(success=False)
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_unavailable_device_or_runtime_is_rejected_without_changes(self):
        path = self.write_config()
        before = path.read_bytes()
        original_state = self.state()
        for unavailable in ("device", "runtime"):
            with self.subTest(unavailable=unavailable):
                state = copy.deepcopy(original_state)
                if unavailable == "device":
                    state["devices"][RUNTIME][0]["isAvailable"] = False
                else:
                    state["runtimes"][0]["isAvailable"] = False
                self.save_state(state)
                self.run_allocator(success=False)
                self.assertEqual(path.read_bytes(), before)
                self.assertEqual(self.state()["create_attempts"], 0)

    def test_creation_failure_preserves_configuration_and_existing_devices(self):
        other = self.shared_device()
        before = (self.root / CONFIG).read_bytes()
        other_before = (other / CONFIG).read_bytes()
        state = self.state()
        state["fail_create"] = True
        devices_before = copy.deepcopy(state["devices"])
        self.save_state(state)
        self.run_allocator(success=False)
        self.assertEqual((self.root / CONFIG).read_bytes(), before)
        self.assertEqual((other / CONFIG).read_bytes(), other_before)
        self.assertEqual(self.state()["create_attempts"], 1)
        self.assertEqual(self.state()["devices"], devices_before)

    def test_dry_run_conflict_does_not_create_or_rewrite(self):
        self.shared_device()
        before = (self.root / CONFIG).read_bytes()
        result = self.run_allocator(dry_run=True)
        self.assertEqual(result.stdout, "")
        self.assertTrue(result.stderr.strip())
        self.assertEqual((self.root / CONFIG).read_bytes(), before)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_name_only_configuration_reuses_unique_device_and_records_uuid(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        self.write_config(config=config)
        self.assert_selected(self.run_allocator(), ORIGINAL_ID)
        actual = self.read_config()
        self.assertEqual(actual["sessionDefaults"]["simulatorId"], ORIGINAL_ID)
        self.assert_other_settings_unchanged(actual, config)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_name_only_reference_in_another_worktree_reserves_existing_device(self):
        other = self.worktree()
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        self.write_config(other, config)
        self.write_config()
        self.run_allocator()
        self.assertEqual(self.state()["create_attempts"], 1)
        self.assertNotEqual(self.read_config()["sessionDefaults"]["simulatorId"], ORIGINAL_ID)

    def test_ambiguous_existing_name_is_rejected(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        path = self.write_config(config=config)
        before = path.read_bytes()
        state = self.state()
        state["devices"][RUNTIME].append(self.device(OTHER_ID, DEVICE_NAME))
        self.save_state(state)
        self.run_allocator(success=False)
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_unknown_device_type_is_rejected(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        config["sessionDefaults"]["simulatorName"] = "Not an installed device type"
        path = self.write_config(config=config)
        before = path.read_bytes()
        self.run_allocator(success=False)
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_template_creates_pinned_device_even_with_newer_compatible_runtime(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        config["sessionDefaults"]["simulatorName"] = "iPhone 18 Pro Max"
        template = self.write_config(config=config, template=True)
        before = template.read_bytes()
        state = self.state()
        state["runtimes"].append(self.runtime("com.apple.CoreSimulator.SimRuntime.iOS-28-0", "28.0", False))
        incompatible = self.runtime("com.apple.CoreSimulator.SimRuntime.iOS-29-0", "29.0")
        incompatible["supportedDeviceTypes"] = []
        state["runtimes"].append(incompatible)
        self.save_state(state)
        result = self.run_allocator()
        actual = self.read_config()
        self.assert_selected(result, actual["sessionDefaults"]["simulatorId"])
        self.assert_other_settings_unchanged(actual, config)
        self.assertEqual(template.read_bytes(), before)
        self.assertEqual(self.state()["create_attempts"], 1)
        creates = [call for call in self.state()["calls"] if call[:2] == ["simctl", "create"]]
        self.assertEqual(creates[0][3:], [DEVICE_TYPE, RUNTIME])
        self.assertNotIn(NEWER_RUNTIME, self.state()["devices"])

    def test_configured_uuid_with_wrong_runtime_or_device_type_is_rejected(self):
        path = self.write_config()
        before = path.read_bytes()
        original_state = self.state()
        for mismatch in ("runtime", "device_type"):
            with self.subTest(mismatch=mismatch):
                state = copy.deepcopy(original_state)
                if mismatch == "runtime":
                    state["devices"][NEWER_RUNTIME] = state["devices"].pop(RUNTIME)
                else:
                    state["devices"][RUNTIME][0]["deviceTypeIdentifier"] = (
                        "com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro"
                    )
                self.save_state(state)
                result = self.run_allocator(success=False)
                self.assertIn("iPhone 18 Pro Max / iOS 27.0", result.stderr)
                self.assertEqual(path.read_bytes(), before)
                self.assertEqual(self.state()["create_attempts"], 0)

    def test_name_only_selection_ignores_other_runtime_and_device_type(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        self.write_config(config=config)
        state = self.state()
        state["devices"][NEWER_RUNTIME] = [self.device(OTHER_ID, DEVICE_NAME)]
        other_type = self.device("DDDDDDDD-1111-2222-3333-444444444444", DEVICE_NAME)
        other_type["deviceTypeIdentifier"] = "com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro"
        state["devices"][RUNTIME].insert(0, other_type)
        self.save_state(state)
        self.assert_selected(self.run_allocator(), ORIGINAL_ID)
        self.assertEqual(self.read_config()["sessionDefaults"]["simulatorId"], ORIGINAL_ID)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_missing_pinned_runtime_does_not_fall_back_to_newer_runtime(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        config["sessionDefaults"]["simulatorName"] = "iPhone 18 Pro Max"
        self.write_config(config=config, template=True)
        state = self.state()
        state["runtimes"] = [self.runtime(NEWER_RUNTIME, "27.1")]
        state["devices"] = {NEWER_RUNTIME: [self.device(OTHER_ID, "iPhone 18 Pro Max")]}
        self.save_state(state)
        result = self.run_allocator(success=False)
        self.assertIn("iOS 27.0", result.stderr)
        self.assertFalse((self.root / CONFIG).exists())
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_template_can_bind_existing_unique_name_without_creation(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        self.write_config(config=config, template=True)
        self.assert_selected(self.run_allocator(), ORIGINAL_ID)
        self.assertEqual(self.read_config()["sessionDefaults"]["simulatorId"], ORIGINAL_ID)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_template_without_supported_runtime_does_not_create_config(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        config["sessionDefaults"]["simulatorName"] = "iPhone 18 Pro Max"
        self.write_config(config=config, template=True)
        state = self.state()
        for runtime in state["runtimes"]:
            runtime["supportedDeviceTypes"] = []
        self.save_state(state)
        self.run_allocator(success=False)
        self.assertFalse((self.root / CONFIG).exists())
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_dry_run_template_leaves_local_config_absent(self):
        config = copy.deepcopy(self.config)
        config["sessionDefaults"].pop("simulatorId")
        config["sessionDefaults"]["simulatorName"] = "iPhone 18 Pro Max"
        template = self.write_config(config=config, template=True)
        before = template.read_bytes()
        self.assertEqual(self.run_allocator(dry_run=True).stdout, "")
        self.assertFalse((self.root / CONFIG).exists())
        self.assertEqual(template.read_bytes(), before)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_missing_config_and_template_fail_without_creating_device(self):
        self.run_allocator(success=False)
        self.assertFalse((self.root / CONFIG).exists())
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_malformed_config_in_other_worktree_fails_conservatively(self):
        other = self.worktree()
        path = self.write_config(other)
        path.write_text("sessionDefaults: [invalid\n")
        current = self.write_config()
        before = current.read_bytes()
        self.run_allocator(success=False)
        self.assertEqual(current.read_bytes(), before)
        self.assertEqual(self.state()["create_attempts"], 0)

    def test_external_config_edit_is_preserved_and_new_device_is_removed(self):
        self.shared_device()
        external_text = "# 用户在分配期间保存的新配置\nsessionDefaults:\n  scheme: Changed\n"
        state = self.state()
        devices_before = copy.deepcopy(state["devices"])
        state["mutate_config"] = {"path": str(self.root / CONFIG), "text": external_text}
        self.save_state(state)
        self.run_allocator(success=False)
        self.assertEqual((self.root / CONFIG).read_text(), external_text)
        state = self.state()
        self.assertEqual(state["create_attempts"], 1)
        self.assertEqual(state["devices"], devices_before)
        deleted = [call for call in state["calls"] if call[:2] == ["simctl", "delete"]]
        self.assertEqual(len(deleted), 1)
        self.assertNotIn(deleted[0][2], (ORIGINAL_ID, OTHER_ID))

    def run_concurrently(self, roots):
        state = self.state()
        state["create_delay"] = 0.25
        self.save_state(state)
        processes = [subprocess.Popen(self.command(root), env=self.env,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                     for root in roots]
        results = []
        try:
            for process in processes:
                stdout, stderr = process.communicate(timeout=20)
                self.assertEqual(process.returncode, 0, stderr)
                results.append(stdout)
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                    process.communicate()
        return results

    def test_concurrent_processes_in_same_worktree_create_only_once(self):
        self.shared_device()
        outputs = self.run_concurrently([self.root] * 4)
        identifier = self.read_config()["sessionDefaults"]["simulatorId"]
        self.assertNotEqual(identifier, ORIGINAL_ID)
        self.assertEqual(outputs, [identifier + "\n"] * 4)
        self.assertEqual(self.state()["create_attempts"], 1)

    def test_concurrent_different_worktrees_receive_different_devices(self):
        self.write_config()
        first = self.worktree("first linked worktree")
        second = self.worktree("second linked worktree")
        self.write_config(first)
        self.write_config(second)
        outputs = self.run_concurrently([first, second])
        first_id = self.read_config(first)["sessionDefaults"]["simulatorId"]
        second_id = self.read_config(second)["sessionDefaults"]["simulatorId"]
        self.assertEqual(len({ORIGINAL_ID, first_id, second_id}), 3)
        self.assertEqual(outputs, [first_id + "\n", second_id + "\n"])
        self.assertEqual(self.read_config()["sessionDefaults"]["simulatorId"], ORIGINAL_ID)
        self.assertEqual(self.state()["create_attempts"], 2)

    def test_concurrent_worktrees_recheck_references_after_first_allocation(self):
        first = self.worktree("first competing worktree")
        second = self.worktree("second competing worktree")
        self.write_config(first)
        self.write_config(second)
        outputs = self.run_concurrently([first, second])
        first_id = self.read_config(first)["sessionDefaults"]["simulatorId"]
        second_id = self.read_config(second)["sessionDefaults"]["simulatorId"]
        self.assertNotEqual(first_id, second_id)
        self.assertIn(ORIGINAL_ID, (first_id, second_id))
        self.assertEqual(outputs, [first_id + "\n", second_id + "\n"])
        # 第一份配置迁移后，另一份可以独占原设备；跨 worktree 的锁应避免多建一个。
        self.assertEqual(self.state()["create_attempts"], 1)


if __name__ == "__main__":
    unittest.main()
