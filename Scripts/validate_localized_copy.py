#!/usr/bin/env python3
"""核对集中资源与 String Catalog，并扫描生产 UI 中重新散落的文案。"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCE = re.compile(
    r'CalendarStringKey\.resource\(\s*"(?P<key>[^"\n]+)",\s*'
    r'defaultValue:\s*"(?P<value>(?:[^"\\]|\\.)*)",\s*'
    r'comment:\s*"(?P<comment>(?:[^"\\]|\\.)*)"', re.DOTALL
)
# 这些文件中的非文案字符串分别是导航协议、稳定数据库标识和导入来源标记。
TECHNICAL_FILES = {
    "Home/Navigation/CalendarDeepLink.swift",
    "Home/Navigation/CalendarDestination.swift",
    "History/Shared/HistoryConfiguration.swift",
    "History/Shared/Formatting/HistoryNoteFormatter.swift",
}
TECHNICAL_LITERALS = {
    "App/Store/ChineseCalendarStoreCoordinator.swift": {
        r'\(contentLevel.rawValue)-\(identityToken ?? "unknown")'
    },
    "History/Shared/Models/HistoryBoundaryEventRepository.swift": {
        r'\(period.id)-start', r'\(period.id)-end'
    },
    "Settings/CalendarColorSchemePreference.swift": {"calendarColorSchemePreference"},
}


def interpolation_end(text, start):
    """跳过插值括号，其中允许嵌套函数调用和字符串。"""
    depth, index = 1, start
    while index < len(text):
        char = text[index]
        if char == '"':
            _, index = string_end(text, index)
            continue
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    raise ValueError("字符串插值缺少右括号")


def string_end(text, start):
    index = start + 1
    while index < len(text):
        if text[index:index + 2] == r'\(':
            index = interpolation_end(text, index + 2)
        elif text[index] == "\\":
            index += 2
        elif text[index] == '"':
            return text[start + 1:index], index + 1
        else:
            index += 1
    raise ValueError("字符串缺少结束引号")


def strings(text):
    """忽略注释，返回字符串字面量及其源码偏移。"""
    index = 0
    while index < len(text):
        if text[index:index + 2] == "//":
            newline = text.find("\n", index)
            index = len(text) if newline < 0 else newline + 1
        elif text[index:index + 2] == "/*":
            end = text.find("*/", index + 2)
            index = len(text) if end < 0 else end + 2
        elif text[index] == '"':
            value, end = string_end(text, index)
            yield value, index
            index = end
        else:
            index += 1


def catalog_value(value, parameter_types):
    result, index = "", 0
    uses_format = r'\(' in value
    while index < len(value):
        if value[index:index + 2] == r'\(':
            end = interpolation_end(value, index + 2)
            expression = value[index + 2:end - 1]
            name = expression.split(",")[0]
            result += "%lld" if parameter_types.get(name) == "Int" and "," not in expression else "%@"
            index = end
        else:
            # 无插值资源直接显示原文；只有格式模板中的百分号需要转义。
            result += "%%" if uses_format and value[index] == "%" else value[index]
            index += 1
    return result


def check_catalog(errors):
    module = "ChineseCalendarLocalization"
    directory = ROOT / "Sources" / module
    catalog = json.loads((directory / "Resources/Calendar.xcstrings").read_text())
    if catalog["sourceLanguage"] != "zh-Hans":
        errors.append(f"{module}: sourceLanguage 必须为 zh-Hans")
    definitions = {}
    for path in sorted((directory / "Strings").glob("*.swift")):
        text = path.read_text()
        for dependency in re.findall(r"^import (\w+)", text, re.MULTILINE):
            if dependency != "Foundation":
                errors.append(f"{path.name}: 基础文案模块不能依赖 {dependency}")
        for match in RESOURCE.finditer(text):
            key, value, comment = match.group("key", "value", "comment")
            if key in definitions:
                errors.append(f"{path.name}: 重复 key {key}")
            signature = text[:match.start()].rsplit("static ", 1)[-1]
            types = dict(re.findall(r"(\w+): (\w+)", signature))
            definitions[key] = catalog_value(value, types)
            entry = catalog["strings"].get(key, {})
            actual = entry.get("localizations", {}).get("zh-Hans", {}).get("stringUnit", {}).get("value")
            if actual != definitions[key]:
                errors.append(f"{key}: catalog 值或插值类型与默认值不一致")
            if not comment.strip() or entry.get("comment") != comment:
                errors.append(f"{key}: 翻译注释缺失或不一致")
            if re.fullmatch(r"界面文案：[\w.]+。", comment):
                errors.append(f"{key}: 翻译注释不能只重复符号路径，需说明页面和用途")
    for key in catalog["strings"].keys() - definitions.keys():
        errors.append(f"{module}: catalog 存在没有类型化入口的 key {key}")
    print(f"{module}: 已核对 {len(definitions)} 项资源的 key、默认值、插值和注释")


def check_call_sites(errors):
    directory = ROOT / "Sources/ChineseCalendarUI"
    count = 0
    for path in sorted(directory.rglob("*.swift")):
        relative = str(path.relative_to(directory))
        if relative.startswith("Tests/") or relative in TECHNICAL_FILES:
            continue
        if "Preview" in relative and path.name != "FullStoreDownloadPreview.swift":
            continue
        # 开发者专用 #Preview 及其后续 fixture 不作为产品页面；可从设置打开的调试页仍扫描。
        text = path.read_text().split("#Preview", 1)[0]
        for value, offset in strings(text):
            count += 1
            line_start = text.rfind("\n", 0, offset) + 1
            prefix = text[line_start:offset]
            if "ChineseCalendarLog." in prefix or re.search(r"\.(error|debug|notice|info|fault)\($", prefix):
                continue
            if value in TECHNICAL_LITERALS.get(relative, set()):
                continue
            # 空布局值和只含数值的格式表达式不构成产品句式。
            if not value or re.fullmatch(r"0?\\\(\w+\)", value):
                continue
            line = text.count("\n", 0, offset) + 1
            errors.append(f"{path.relative_to(ROOT)}:{line}: 文案需移入 CalendarStringKey：{value}")
    print(f"UI: 已检查 {count} 个剩余生产字符串（含英文和插值），例外见脚本与迁移清单")


def main():
    errors = []
    check_catalog(errors)
    check_call_sites(errors)
    for error in errors:
        print(error, file=sys.stderr)
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
