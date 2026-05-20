#!/usr/bin/env swift
import Foundation

// 这个 Swift 文件是给项目保留的统一命令入口。
// 真实导入逻辑在同目录的 Node 脚本里，这里只负责转发参数并透传退出码。
let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0])
let scriptDirectory = scriptPath.deletingLastPathComponent()
let nodeScript = scriptDirectory.appendingPathComponent("generate_calendar_days.mjs").path

guard FileManager.default.fileExists(atPath: nodeScript) else {
    fputs("Missing Node generator at \(nodeScript)\n", stderr)
    exit(1)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["node", nodeScript] + Array(CommandLine.arguments.dropFirst())

do {
    // 让 Swift 入口和 Node 生成器表现得像同一个命令，方便 README 和 CI 只记录一条调用方式。
    try process.run()
    process.waitUntilExit()
    exit(process.terminationStatus)
} catch {
    fputs("Failed to run calendar-day generator: \(error.localizedDescription)\n", stderr)
    exit(1)
}
