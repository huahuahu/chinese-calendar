import Foundation

enum HistoryNoteFormatter {
    static func reignEraNote(_ note: String?) -> String? {
        guard let note else {
            return nil
        }

        if let sourceNoteRange = note.range(of: "; source note: ") {
            return nonempty(String(note[sourceNoteRange.upperBound...]))
        }

        if note.hasPrefix("Parsed from ") {
            return nil
        }

        return nonempty(note)
    }

    private static func nonempty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
