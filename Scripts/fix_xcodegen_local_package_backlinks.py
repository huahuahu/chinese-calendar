#!/usr/bin/env python3

"""Patch XcodeGen local Swift package product dependencies.

XcodeGen 2.45.x can emit XCSwiftPackageProductDependency entries for
XCLocalSwiftPackageReference packages without the required `package = ...;`
backlink. Xcode.app may then report "Missing package product" after a cold
project reload, even when xcodebuild can resolve the graph.

See: https://github.com/yonaskolb/XcodeGen/issues/1549
"""

from __future__ import annotations

import posixpath
import re
import sys
from dataclasses import dataclass
from pathlib import Path


PBXPROJ = Path("ChineseCalendar.xcodeproj/project.pbxproj")
PROJECT_YML = Path("project.yml")


@dataclass(frozen=True)
class LocalPackageRef:
    identifier: str
    comment: str
    path: str


def strip_value(value: str) -> str:
    value = value.strip().rstrip(";").strip()
    if value.startswith('"') and value.endswith('"'):
        return value[1:-1]
    return value


def normalize_path(value: str) -> str:
    return posixpath.normpath(strip_value(value)).rstrip("/")


def parse_scalar_list(value: str) -> list[str]:
    value = value.strip()
    if not value:
        return []
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [strip_value(part) for part in inner.split(",")]
    return [strip_value(value)]


def line_indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def parse_project_yml(path: Path) -> tuple[dict[str, str], dict[str, set[str]]]:
    if not path.exists():
        return {}, {}

    lines = path.read_text().splitlines()
    package_paths: dict[str, str] = {}
    product_to_package_paths: dict[str, set[str]] = {}

    index = 0
    while index < len(lines):
        if lines[index].strip() != "packages:":
            index += 1
            continue

        index += 1
        while index < len(lines):
            line = lines[index]
            stripped = line.strip()
            if stripped and line_indent(line) == 0:
                break
            package_match = re.match(r"^  ([A-Za-z0-9_.-]+):\s*$", line)
            if not package_match:
                index += 1
                continue

            package_name = package_match.group(1)
            index += 1
            while index < len(lines):
                child = lines[index]
                child_stripped = child.strip()
                if child_stripped and line_indent(child) <= 2:
                    break
                path_match = re.match(r"^    path:\s*(.+?)\s*$", child)
                if path_match:
                    package_paths[package_name] = normalize_path(path_match.group(1))
                index += 1
        break

    for index, line in enumerate(lines):
        package_match = re.match(r"^\s*-\s+package:\s*([^#]+?)\s*$", line)
        if not package_match:
            continue

        package_name = strip_value(package_match.group(1))
        package_path = package_paths.get(package_name)
        if package_path is None:
            continue

        products: list[str] = []
        item_indent = line_indent(line)
        collecting_products = False
        lookahead = index + 1
        while lookahead < len(lines):
            child = lines[lookahead]
            child_stripped = child.strip()
            if child_stripped and line_indent(child) <= item_indent:
                break
            if re.match(r"^\s*-\s+package:\s*", child):
                break

            product_match = re.match(r"^\s+product:\s*(.+?)\s*$", child)
            products_match = re.match(r"^\s+products:\s*(.*?)\s*$", child)
            nested_product_match = re.match(r"^\s+-\s+([A-Za-z0-9_.-]+)\s*$", child)
            if product_match:
                collecting_products = False
                products.extend(parse_scalar_list(product_match.group(1)))
            elif products_match:
                parsed_products = parse_scalar_list(products_match.group(1))
                products.extend(parsed_products)
                collecting_products = not parsed_products
            elif collecting_products and nested_product_match:
                products.append(nested_product_match.group(1))
            elif child_stripped:
                collecting_products = False
            lookahead += 1

        if not products:
            products = [package_name]
        for product in products:
            product_to_package_paths.setdefault(product, set()).add(package_path)

    return package_paths, product_to_package_paths


def collect_local_package_refs(lines: list[str]) -> list[LocalPackageRef]:
    refs: list[LocalPackageRef] = []
    index = 0
    start_re = re.compile(
        r'^\s*([A-F0-9]+) /\* XCLocalSwiftPackageReference "(.+?)" \*/ = \{$'
    )
    path_re = re.compile(r"^\s*relativePath = (.+?);\s*$")

    while index < len(lines):
        match = start_re.match(lines[index])
        if not match:
            index += 1
            continue

        identifier, comment = match.groups()
        package_path = comment
        index += 1
        while index < len(lines) and not re.match(r"^\s*};\s*$", lines[index]):
            path_match = path_re.match(lines[index])
            if path_match:
                package_path = strip_value(path_match.group(1))
            index += 1
        refs.append(LocalPackageRef(identifier, comment, normalize_path(package_path)))
        index += 1

    return refs


def patch_product_dependencies(
    lines: list[str],
    local_refs: list[LocalPackageRef],
    product_to_package_paths: dict[str, set[str]],
) -> tuple[list[str], int, list[str]]:
    local_refs_by_path = {ref.path: ref for ref in local_refs}
    single_local_ref = local_refs[0] if len(local_refs) == 1 else None
    output: list[str] = []
    changed = 0
    unresolved: list[str] = []
    index = 0
    start_re = re.compile(r'^\s*([A-F0-9]+) /\* (.+?) \*/ = \{$')

    while index < len(lines):
        start_match = start_re.match(lines[index])
        if not start_match:
            output.append(lines[index])
            index += 1
            continue

        block = [lines[index]]
        index += 1
        while index < len(lines):
            block.append(lines[index])
            if re.match(r"^\s*};\s*$", lines[index]):
                index += 1
                break
            index += 1

        if not any("isa = XCSwiftPackageProductDependency;" in line for line in block):
            output.extend(block)
            continue
        if any(re.match(r"^\s*package = ", line) for line in block):
            output.extend(block)
            continue

        product_name = None
        for line in block:
            product_match = re.match(r"^\s*productName = (.+?);\s*$", line)
            if product_match:
                product_name = strip_value(product_match.group(1))
                break
        if product_name is None:
            output.extend(block)
            continue

        candidate_paths = product_to_package_paths.get(product_name, set())
        candidate_refs = [local_refs_by_path[path] for path in candidate_paths if path in local_refs_by_path]
        if len(candidate_refs) == 1:
            package_ref = candidate_refs[0]
        elif single_local_ref is not None:
            package_ref = single_local_ref
        else:
            unresolved.append(product_name)
            output.extend(block)
            continue

        patched_block: list[str] = []
        inserted = False
        for line in block:
            patched_block.append(line)
            if not inserted and "isa = XCSwiftPackageProductDependency;" in line:
                indent = re.match(r"^(\s*)", line).group(1)
                patched_block.append(
                    f'{indent}package = {package_ref.identifier} '
                    f'/* XCLocalSwiftPackageReference "{package_ref.comment}" */;'
                )
                inserted = True
                changed += 1
        output.extend(patched_block)

    return output, changed, unresolved


def main() -> int:
    pbxproj = Path(sys.argv[1]) if len(sys.argv) > 1 else PBXPROJ
    if not pbxproj.exists():
        print(f"error: {pbxproj} does not exist", file=sys.stderr)
        return 1

    _, product_to_package_paths = parse_project_yml(PROJECT_YML)
    original_text = pbxproj.read_text()
    lines = original_text.splitlines()
    local_refs = collect_local_package_refs(lines)
    if not local_refs:
        print("No local Swift package references found.")
        return 0

    patched_lines, changed, unresolved = patch_product_dependencies(
        lines,
        local_refs,
        product_to_package_paths,
    )
    if unresolved:
        names = ", ".join(sorted(set(unresolved)))
        print(f"error: could not resolve local package for product(s): {names}", file=sys.stderr)
        return 1

    if changed == 0:
        print("Local Swift package backlinks already present.")
        return 0

    trailing_newline = "\n" if original_text.endswith("\n") else ""
    pbxproj.write_text("\n".join(patched_lines) + trailing_newline)
    print(f"Patched {changed} local Swift package product backlink(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
