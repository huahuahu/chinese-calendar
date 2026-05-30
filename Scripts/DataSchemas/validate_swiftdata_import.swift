#!/usr/bin/env swift
import Foundation

// Keep a Swift-shaped command surface while the JSON Schema validator lives in Node.
let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0])
let scriptDirectory = scriptPath.deletingLastPathComponent()
let nodeScript = scriptDirectory.appendingPathComponent("validate_swiftdata_import.mjs").path

guard FileManager.default.fileExists(atPath: nodeScript) else {
    fputs("Missing SwiftData import validator at \(nodeScript)\n", stderr)
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
    fputs("Failed to run SwiftData import validator: \(error.localizedDescription)\n", stderr)
    exit(1)
}
