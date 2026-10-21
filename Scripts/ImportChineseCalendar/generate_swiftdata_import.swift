#!/usr/bin/env swift
import Foundation

// 将命令行参数转交同目录的 generate_swiftdata_import.mjs，由 Node 流式转换 JSONL 导入数据。
// 等待子进程结束并返回其退出码，供命令行和 CI 判断是否成功。
let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0])
let scriptDirectory = scriptPath.deletingLastPathComponent()
let nodeScript = scriptDirectory.appendingPathComponent("generate_swiftdata_import.mjs").path

guard FileManager.default.fileExists(atPath: nodeScript) else {
    fputs("Missing Node generator at \(nodeScript)\n", stderr)
    exit(1)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["node", nodeScript] + Array(CommandLine.arguments.dropFirst())

do {
    try process.run()
    process.waitUntilExit()
    exit(process.terminationStatus)
} catch {
    fputs("Failed to run SwiftData import generator: \(error.localizedDescription)\n", stderr)
    exit(1)
}
