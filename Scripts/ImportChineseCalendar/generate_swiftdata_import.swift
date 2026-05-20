#!/usr/bin/env swift
import Foundation

// This Swift file keeps the project command surface consistent.
// The streaming JSONL transform lives in the adjacent Node script.
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
