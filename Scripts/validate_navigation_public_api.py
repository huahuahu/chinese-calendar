#!/usr/bin/env python3
"""对已构建 NavigationCore 执行普通 import 正负编译检查，不重新构建任何 target。"""

import argparse
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "Scripts/NavigationCoreAPI"


def expected_rejection(case, diagnostics):
    errors = re.findall(r"(?:^|\n)[^\n]*\berror: ([^\n]+)", diagnostics)
    symbol = re.escape(case["symbol"])
    patterns = {
        "type": rf"cannot find type '{symbol}' in scope",
        "internal": rf"'{symbol}' is inaccessible due to 'internal' protection level",
        "private": rf"'{symbol}' is inaccessible due to 'private' protection level",
        "missing": rf"value of type '.+' (?:\(aka '.+'\) )?has no member '{symbol}'",
    }
    return bool(errors) and all(re.fullmatch(patterns[case["kind"]], error) for error in errors)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("build_products", type=Path, help="已有 Debug-iphonesimulator 构建产物目录")
    parser.add_argument("sdk", type=Path, help="与构建一致的 iPhoneSimulator SDK 目录")
    parser.add_argument("target", help="与模块一致的 target，如 arm64-apple-ios26.0-simulator")
    parser.add_argument("--output-directory", type=Path, default=ROOT / ".output/navigation-public-api")
    args = parser.parse_args()
    products, sdk, output = (path.resolve() for path in (args.build_products, args.sdk, args.output_directory))
    for path in (products, sdk):
        if not path.is_dir():
            parser.error(f"目录不存在：{path}")
    sources = output / "samples"
    sources.mkdir(parents=True, exist_ok=True)
    swiftc = subprocess.check_output(["xcrun", "--find", "swiftc"], text=True).strip()
    command = [
        swiftc, "-typecheck", "-swift-version", "6", "-sdk", str(sdk), "-target", args.target,
        "-I", str(products), "-F", str(products), "-F", str(products / "PackageFrameworks"),
        "-module-cache-path", str(output / "module-cache"), str(FIXTURES / "Common.swift"),
    ]
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "build_products": str(products), "sdk": str(sdk), "target": args.target,
        "compiler": subprocess.check_output([swiftc, "--version"], text=True).strip(),
        "modules": [], "cases": [],
    }
    for path in sorted((products / "NavigationCore.swiftmodule").glob("*.swiftmodule")):
        report["modules"].append({"path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})

    def run(name, source, case=None):
        source_path = sources / f"{name}.swift"
        source_path.write_text(source)
        invocation = [*command, str(source_path)]
        completed = subprocess.run(invocation, capture_output=True, text=True, check=False)
        diagnostics = completed.stdout + completed.stderr
        passed = completed.returncode == 0 if case is None else (
            completed.returncode != 0 and expected_rejection(case, diagnostics)
        )
        result = {
            "name": name, "source_file": str(source_path),
            "source_sha256": hashlib.sha256(source.encode()).hexdigest(),
            "command": invocation, "exit_code": completed.returncode,
            "passed": passed, "diagnostics": diagnostics,
        }
        report["cases"].append(result)
        print(f"{'PASS' if passed else 'FAIL'} {name}", flush=True)
        return passed

    positive = run("positive", (FIXTURES / "Positive.swift").read_text())
    if positive:
        for case in json.loads((FIXTURES / "NegativeCases.json").read_text()):
            source = "import NavigationCore\nimport SwiftUI\n\n@MainActor func rejectedUsage(_ router: APIRouter) {\n"
            source += f"    {case['body']}\n}}\n"
            run(case["name"], source, case)
    else:
        print("正向控制失败，停止负向检查；SDK、模块或正常 API 错误不能作为边界通过证据。", file=sys.stderr)
    report["passed"] = positive and all(case["passed"] for case in report["cases"])
    report["negative_case_count"] = len(report["cases"]) - 1
    (output / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    (output / "diagnostics.txt").write_text("\n".join(
        f"{case['name']} (exit {case['exit_code']})\n{case['diagnostics']}" for case in report["cases"]
    ))
    print(f"报告：{output / 'report.json'}", flush=True)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
