#!/usr/bin/env python3
"""用已构建的真实 Swift 模块检查六类导航身份，拒绝把环境错误当作类型拒绝证据。"""

import argparse
import hashlib
import itertools
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMPORTS = "import NavigationCore\n@testable import ChineseCalendarUI\n\n"
IDENTITIES = {
    "presentation": "NavigationPresentationID",
    "confirmation": "NavigationConfirmationID",
    "alert": "NavigationAlertID",
    "year_picker": "YearPickerSessionID",
    "download_preview": "DownloadPreviewSessionID",
    "alert_message": "CalendarAlertMessageID",
}
API_CALLS = {
    "presentation": "_ = coordinator.router.navigation.dismissPresentation(id: candidate)",
    "confirmation": "_ = coordinator.router.navigation.confirmNavigation(id: candidate)",
    "alert": "_ = NavigationAlertNode(id: candidate, destination: CalendarAlert.clearDataSucceeded)",
    "year_picker": "coordinator.selectYear(2026, sessionID: candidate)",
    "download_preview": "coordinator.presentDownloadPreviewDetails(sessionID: candidate)",
    "alert_message": "_ = CalendarAlert.downloadFailed(messageID: candidate)",
}


def positive_source():
    lines = [
        IMPORTS.rstrip(),
        "",
        "func requireIdentity<ID: Hashable & Sendable>(_ id: ID) {}",
        "",
        "@MainActor func validAPIs(_ coordinator: CalendarHomeCoordinator) {",
    ]
    for category, identity in IDENTITIES.items():
        lines.extend([
            "    do {",
            f"        let candidate = {identity}()",
            "        requireIdentity(candidate)",
            "        _ = candidate == candidate",
            f"        {API_CALLS[category]}",
            "    }",
        ])
    lines.append("}")
    return "\n".join(lines) + "\n"


def negative_cases():
    for (left_category, left), (right_category, right) in itertools.combinations(IDENTITIES.items(), 2):
        yield {
            "name": f"compare_{left_category}_with_{right_category}",
            "kind": "comparison",
            "source_type": left,
            "expected_type": right,
            "source": IMPORTS + (
                f"@MainActor func invalidComparison(_ lhs: {left}, _ rhs: {right}) {{\n"
                "    _ = lhs == rhs\n"
                "}\n"
            ),
        }
    for expected_category, expected in IDENTITIES.items():
        for source_category, source in IDENTITIES.items():
            if source == expected:
                continue
            yield {
                "name": f"pass_{source_category}_to_{expected_category}_api",
                "kind": "api_argument",
                "source_type": source,
                "expected_type": expected,
                "source": IMPORTS + (
                    f"@MainActor func invalidArgument(_ candidate: {source}, "
                    "_ coordinator: CalendarHomeCoordinator) {\n"
                    f"    {API_CALLS[expected_category]}\n"
                    "}\n"
                ),
            }


def is_expected_mismatch(case, diagnostics):
    # 每条 error 都须明确指出该用例的两个身份类型；导入、SDK、权限等错误不算通过。
    errors = re.findall(r"(?:^|\n)[^\n]*\berror: ([^\n]+)", diagnostics)
    source, expected = case["source_type"], case["expected_type"]
    messages = {
        f"cannot convert value of type '{source}' to expected argument type '{expected}'",
        f"binary operator '==' cannot be applied to operands of type '{source}' and '{expected}'",
        f"binary operator '==' cannot be applied to operands of type '{expected}' and '{source}'",
    }
    return bool(errors) and all(error in messages for error in errors)


def module_evidence(products):
    modules = []
    for name in ("NavigationCore", "ChineseCalendarUI"):
        for entry in sorted(products.rglob(f"{name}.swiftmodule")):
            files = sorted(entry.glob("*.swiftmodule")) if entry.is_dir() else [entry]
            for path in files:
                modules.append({
                    "module": name,
                    "path": str(path),
                    "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                })
    return modules


def run_case(case, command, output):
    source_path = output / "samples" / f"{case['name']}.swift"
    source_path.write_text(case["source"])
    invocation = [*command, str(source_path)]
    completed = subprocess.run(invocation, capture_output=True, text=True, check=False)
    diagnostics = completed.stdout + completed.stderr
    passed = completed.returncode == 0 if case["kind"] == "positive" else (
        completed.returncode != 0 and is_expected_mismatch(case, diagnostics)
    )
    return {
        **case,
        "source_file": str(source_path.relative_to(output)),
        "source_sha256": hashlib.sha256(case["source"].encode()).hexdigest(),
        "command": invocation,
        "exit_code": completed.returncode,
        "passed": passed,
        "diagnostics": diagnostics,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("build_products", type=Path, help="Xcode Debug-iphonesimulator 构建产物目录")
    parser.add_argument("sdk", type=Path, help="与构建一致的 iPhoneSimulator SDK 绝对路径")
    parser.add_argument("target", help="与模块一致的 Swift target，例如 arm64-apple-ios26.0-simulator")
    parser.add_argument(
        "--output-directory", type=Path, default=ROOT / ".output/issue-166-typed-navigation-ids",
        help="保存 JSON 报告、编译样例和完整诊断的目录",
    )
    args = parser.parse_args()
    products, sdk, output = (path.resolve() for path in (args.build_products, args.sdk, args.output_directory))
    for path in (products, sdk):
        if not path.is_dir():
            parser.error(f"目录不存在：{path}")
    (output / "samples").mkdir(parents=True, exist_ok=True)
    swiftc = subprocess.check_output(["xcrun", "--find", "swiftc"], text=True).strip()
    command = [
        swiftc, "-typecheck", "-swift-version", "6", "-D", "DEBUG",
        "-sdk", str(sdk), "-target", args.target,
        "-I", str(products), "-F", str(products), "-F", str(products / "PackageFrameworks"),
        "-F", str(sdk.parent.parent / "Library/Frameworks"),
        "-F", str(sdk / "Developer/Library/Frameworks"),
        "-module-cache-path", str(ROOT / ".output/issue-166-typecheck-module-cache"),
    ]
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "build_products": str(products),
        "sdk": str(sdk),
        "target": args.target,
        "compiler": subprocess.check_output([swiftc, "--version"], text=True).strip(),
        "modules": module_evidence(products),
        "cases": [],
    }
    positive = run_case({"name": "positive_control", "kind": "positive", "source": positive_source()}, command, output)
    report["cases"].append(positive)
    if positive["passed"]:
        for case in negative_cases():
            result = run_case(case, command, output)
            report["cases"].append(result)
            print(f"{'PASS' if result['passed'] else 'FAIL'} {case['name']}", flush=True)
    else:
        print("正向控制失败，停止负向验证；不能用模块、SDK 或正常 API 错误证明类型边界。", file=sys.stderr)
    report["passed"] = positive["passed"] and all(case["passed"] for case in report["cases"])
    report["positive_passed"] = positive["passed"]
    report["negative_case_count"] = len(report["cases"]) - 1
    report["negative_passed_count"] = sum(case["passed"] for case in report["cases"][1:])
    (output / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    (output / "compiler-diagnostics.txt").write_text("\n".join(
        f"{case['name']} (exit {case['exit_code']})\n{case['diagnostics']}" for case in report["cases"]
    ))
    print(f"报告：{output / 'report.json'}", flush=True)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
