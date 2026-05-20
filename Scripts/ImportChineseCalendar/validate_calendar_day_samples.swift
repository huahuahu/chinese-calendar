#!/usr/bin/env swift
import Foundation

// 样本校验也保留 Swift 入口，方便和生成器一样用 Scripts/.../*.swift 调用。
let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0])
let scriptDirectory = scriptPath.deletingLastPathComponent()
let nodeScript = scriptDirectory.appendingPathComponent("validate_calendar_day_samples.mjs").path

guard FileManager.default.fileExists(atPath: nodeScript) else {
    fputs("Missing Node sample validator at \(nodeScript)\n", stderr)
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
    fputs("Failed to run calendar-day sample validator: \(error.localizedDescription)\n", stderr)
    exit(1)
}
