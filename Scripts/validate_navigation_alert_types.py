#!/usr/bin/env python3
"""在真实 iOS 模块上验证 alert 内容、按钮和异步 handler 的 Action 类型边界。"""

import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRELUDE = """import NavigationCore

enum FirstAction: Hashable { case one, two }
enum SecondAction: Hashable { case three, four }

@MainActor func firstContent() -> NavigationAlertContent<FirstAction> {
    NavigationAlertContent(title: "First", message: "First message",
        firstButton: NavigationAlertButton("One", action: .one),
        cancelButton: NavigationAlertCancelButton("Two", action: .two))
}

@MainActor func secondContent() -> NavigationAlertContent<SecondAction> {
    NavigationAlertContent(title: "Second", message: "Second message",
        firstButton: NavigationAlertButton("Three", action: .three),
        cancelButton: NavigationAlertCancelButton("Four", action: .four))
}

@MainActor func handleFirst(_ action: FirstAction) async {
    switch action { case .one: break; case .two: break }
}
@MainActor func handleSecond(_ action: SecondAction) async {
    switch action { case .three: break; case .four: break }
}
"""
CASES = {
    "positive": """@MainActor func definitions() -> [NavigationAlertDefinition] {
        [NavigationAlertDefinition(content: firstContent(), onAction: handleFirst),
         NavigationAlertDefinition(content: secondContent(), onAction: handleSecond)]
    }""",
    "wrong_handler_first": """@MainActor func invalid() {
        _ = NavigationAlertDefinition(content: firstContent(), onAction: handleSecond)
    }""",
    "wrong_handler_second": """@MainActor func invalid() {
        _ = NavigationAlertDefinition(content: secondContent(), onAction: handleFirst)
    }""",
    "wrong_button": """@MainActor func invalid() {
        _ = NavigationAlertContent<FirstAction>(title: "First", message: "Message",
            firstButton: NavigationAlertButton("Three", action: SecondAction.three))
    }""",
    "wrong_cancel_button": """@MainActor func invalid() {
        _ = NavigationAlertContent<FirstAction>(title: "First", message: "Message",
            cancelButton: NavigationAlertCancelButton("Four", action: SecondAction.four))
    }""",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("build_products", type=Path)
    parser.add_argument("sdk", type=Path)
    parser.add_argument("target")
    parser.add_argument("--output-directory", type=Path, default=ROOT / ".output/issue-164-typecheck")
    args = parser.parse_args()
    output = args.output_directory.resolve()
    output.mkdir(parents=True, exist_ok=True)
    command = [
        "xcrun", "swiftc", "-typecheck", "-swift-version", "6",
        "-sdk", str(args.sdk.resolve()), "-target", args.target,
        "-I", str(args.build_products.resolve()),
        "-F", str(args.build_products.resolve() / "PackageFrameworks"),
    ]
    report = {"command": command, "cases": []}
    for name, body in CASES.items():
        source = output / f"{name}.swift"
        source.write_text(PRELUDE + "\n" + body + "\n")
        result = subprocess.run([*command, str(source)], capture_output=True, text=True, check=False)
        diagnostics = result.stdout + result.stderr
        errors = re.findall(r"(?:^|\n)[^\n]*\berror: ([^\n]+)", diagnostics)
        passed = result.returncode == 0 if name == "positive" else (
            result.returncode != 0 and bool(errors)
            and all("FirstAction" in error and "SecondAction" in error for error in errors)
            and all(re.search(r"cannot convert|conflicting arguments|cannot assign", error) for error in errors)
        )
        report["cases"].append({
            "name": name, "passed": passed, "exit_code": result.returncode,
            "source": source.read_text(), "diagnostics": diagnostics,
        })
        print(f"{'PASS' if passed else 'FAIL'} {name}", flush=True)
        if name == "positive" and not passed:
            break
    report["passed"] = len(report["cases"]) == len(CASES) and all(case["passed"] for case in report["cases"])
    (output / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
