#!/usr/bin/env python3
"""验证设备隔离、兼容性与异常清理，不接触本机 Simulator。"""

import argparse
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "ci_simulator.py"
SPEC = importlib.util.spec_from_file_location("ci_simulator", SCRIPT)
ci = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ci)
PHONE = "iPhone 18 Pro Max"
IPAD = "iPad Pro 13-inch (M5)"
DUO = "iPhone Duo"
PHONE_TYPE = "phone-type"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-27-2"
DUO_RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-27-1"


class SimulatorTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.path = self.root / "simulator.json"
        self.data = {
            "devicetypes": [{"name": name, "identifier": identifier}
                            for name, identifier in ((PHONE, PHONE_TYPE), (IPAD, "ipad-type"), (DUO, "duo-type"))],
            "runtimes": [
                {"identifier": RUNTIME, "version": "27.2", "isAvailable": True,
                 "supportedDeviceTypes": [{"identifier": PHONE_TYPE}, {"identifier": "ipad-type"}]},
                {"identifier": DUO_RUNTIME, "version": "27.1", "isAvailable": True,
                 "supportedDeviceTypes": [{"identifier": "duo-type"}]},
                {"identifier": RUNTIME + "-iPhone19-4", "version": "27.2", "isAvailable": True,
                 "supportedDeviceTypes": [{"identifier": "duo-type"}]},
            ],
            "devices": {RUNTIME: [{"name": "Someone else's phone", "udid": "00000000-0000-0000-0000-000000000001",
                                   "deviceTypeIdentifier": PHONE_TYPE, "state": "Booted", "isAvailable": True}]},
        }
        self.calls = []
        self.fail_diagnostics = False
        self.command_patch = patch.object(ci, "command", side_effect=self.command)
        self.command_patch.start()
        self.addCleanup(self.command_patch.stop)

    def command(self, *args):
        self.calls.append(args)
        if args == ("xcodebuild", "-version"):
            return "Xcode 27.2\nBuild version 27B48"
        if args[:2] == ("xcodebuild", "-sdk"):
            return "27.2"
        if args == ("xcode-select", "-p"):
            return "/Applications/Xcode RC.app/Contents/Developer"
        if args == ("xcrun", "simctl", "list", "--json"):
            return json.dumps(self.data)
        if args[:3] == ("xcrun", "simctl", "create"):
            identifier = f"00000000-0000-0000-0000-{len(self.calls):012d}"
            self.data["devices"].setdefault(args[5], []).append({
                "name": args[3], "udid": identifier, "deviceTypeIdentifier": args[4],
                "state": "Shutdown", "isAvailable": True,
            })
            return identifier
        if args[:3] == ("xcrun", "simctl", "shutdown"):
            for devices in self.data["devices"].values():
                for device in devices:
                    if device["udid"] == args[3]:
                        device["state"] = "Shutdown"
            return ""
        if args[:3] == ("xcrun", "simctl", "delete"):
            for devices in self.data["devices"].values():
                devices[:] = [device for device in devices if device["udid"] != args[3]]
            return ""
        if args[:3] in (("xcrun", "simctl", "io"), ("xcrun", "simctl", "spawn")):
            if self.fail_diagnostics:
                raise RuntimeError("Requested diagnostic failure")
            return "Device evidence"
        self.fail(f"Unexpected command: {args}")

    @staticmethod
    def arguments(task="test-123", device=PHONE, runtime="27.2"):
        return argparse.Namespace(task=task, device=device, runtime=runtime)

    def start(self, **args):
        return ci.start(self.arguments(**args), self.path)

    def test_matrix_checks_compatibility_and_ignores_special_27_2_runtime(self):
        for device, version, runtime in ((PHONE, "27.2", RUNTIME), (IPAD, "27.2", RUNTIME), (DUO, "27.1", DUO_RUNTIME)):
            with self.subTest(device=device):
                path = self.root / f"{device}.json"
                state = ci.start(self.arguments(device=device, runtime=version), path)
                self.assertEqual(state["runtimeIdentifier"], runtime)
                self.assertEqual(state["xcode"], "Xcode 27.2\nBuild version 27B48")

    def test_same_task_reuses_uuid_and_other_task_gets_its_own(self):
        first = self.start()
        self.assertEqual(self.start()["simulatorId"], first["simulatorId"])
        other = ci.start(self.arguments(task="other-task"), self.root / "other.json")
        self.assertNotEqual(first["simulatorId"], other["simulatorId"])
        self.assertEqual(len([c for c in self.calls if c[:3] == ("xcrun", "simctl", "create")]), 2)

    def test_wrong_version_missing_or_incompatible_runtime_never_creates(self):
        baseline = copy.deepcopy(self.data)
        for failure in ("wrong-version", "missing", "incompatible", "ambiguous"):
            with self.subTest(failure=failure):
                self.data = copy.deepcopy(baseline)
                args = self.arguments(runtime="27.1" if failure == "wrong-version" else "27.2")
                if failure == "missing":
                    self.data["runtimes"][0]["isAvailable"] = False
                elif failure == "incompatible":
                    self.data["runtimes"][0]["supportedDeviceTypes"] = []
                elif failure == "ambiguous":
                    self.data["runtimes"].append(copy.deepcopy(self.data["runtimes"][0]))
                with self.assertRaises(RuntimeError):
                    ci.start(args, self.path)
                self.assertFalse(self.path.exists())
        self.assertFalse(any(c[:3] == ("xcrun", "simctl", "create") for c in self.calls))

    def test_wrong_xcode_rejected_before_creation(self):
        with patch.object(ci, "command", return_value="Xcode 27.1"):
            with self.assertRaisesRegex(RuntimeError, "Xcode 27.2"):
                self.start()
        self.assertFalse(self.path.exists())

    def test_state_cannot_be_borrowed_by_another_task(self):
        self.start()
        with self.assertRaisesRegex(RuntimeError, "another"):
            self.start(task="other-task")

    def test_deleted_device_is_not_silently_replaced(self):
        self.start()
        self.data["devices"][RUNTIME].pop()
        with self.assertRaisesRegex(RuntimeError, "missing"):
            self.start()

    def test_finish_saves_evidence_then_deletes_only_owned_uuid(self):
        state = self.start()
        self.data["devices"][RUNTIME][-1]["state"] = "Booted"
        ci.finish(self.path)
        self.assertEqual(json.loads(self.path.read_text())["status"], "deleted")
        self.assertEqual(len(self.data["devices"][RUNTIME]), 1)
        self.assertEqual(self.data["devices"][RUNTIME][0]["name"], "Someone else's phone")
        deletion = ("xcrun", "simctl", "delete", state["simulatorId"])
        evidence = next(c for c in self.calls if c[:3] == ("xcrun", "simctl", "spawn"))
        self.assertLess(self.calls.index(evidence), self.calls.index(deletion))
        before = len(self.calls)
        ci.finish(self.path)
        self.assertEqual(len(self.calls), before)
        with self.assertRaisesRegex(RuntimeError, "finished"):
            self.start()

    def test_diagnostic_failure_does_not_prevent_cleanup(self):
        self.start()
        self.data["devices"][RUNTIME][-1]["state"] = "Booted"
        self.fail_diagnostics = True
        ci.finish(self.path)
        self.assertEqual(json.loads(self.path.read_text())["status"], "deleted")
        self.assertTrue((self.root / "device/system-log-error.txt").exists())

    def test_ownership_change_prevents_deletion(self):
        self.start()
        self.data["devices"][RUNTIME][-1]["name"] = "Changed owner"
        with self.assertRaisesRegex(RuntimeError, "ownership"):
            ci.finish(self.path)
        self.assertFalse(any(c[:3] == ("xcrun", "simctl", "delete") for c in self.calls))

    def test_interrupted_creation_recovers_uuid_before_cleanup(self):
        state = self.start()
        state.pop("simulatorId")
        state["status"] = "creating"
        ci.save(self.path, state)
        ci.finish(self.path)
        self.assertEqual(json.loads(self.path.read_text())["status"], "deleted")
        self.assertEqual(len(self.data["devices"][RUNTIME]), 1)

    def test_failed_creation_and_missing_state_cleanup_are_safe(self):
        ci.finish(self.path)
        self.assertEqual(self.calls, [])
        state = self.start()
        self.data["devices"][RUNTIME].pop()
        state.pop("simulatorId")
        state["status"] = "creating"
        ci.save(self.path, state)
        ci.finish(self.path)
        self.assertEqual(json.loads(self.path.read_text())["status"], "deleted")

    def test_manifest_has_sha256_for_preserved_evidence(self):
        (self.root / "tests.log").write_text("hello\n")
        ci.seal(self.root)
        self.assertEqual(json.loads((self.root / "sha256.json").read_text()), {
            "tests.log": "5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03",
        })

    def test_ci_destination_requires_task_uuid_and_never_uses_inventory(self):
        source = SCRIPT.with_name("ios_simulator.sh")
        env = dict(os.environ, CI="true", GITHUB_ACTIONS="true")
        env.pop("CHINESE_CALENDAR_SIMULATOR_ID", None)
        command = ["bash", "-c", 'source "$1"; resolve_ios_simulator_destination', "test", str(source)]
        result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=5)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires CHINESE_CALENDAR_SIMULATOR_ID", result.stderr)
        env["CHINESE_CALENDAR_SIMULATOR_ID"] = "task-uuid"
        result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "id=task-uuid")


if __name__ == "__main__":
    unittest.main()
