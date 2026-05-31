import ChineseCalendarCore
import ChineseCalendarPersistence
import Foundation
import SwiftData

do {
    let options = try SeedStoreBuilderOptions(arguments: CommandLine.arguments)
    try SeedStoreBuilder(options: options).build()
} catch {
    fputs("Failed to build Chinese calendar seed store: \(error.localizedDescription)\n", stderr)
    exit(1)
}

private struct SeedStoreBuilderOptions {
    let inputURL: URL
    let outputURL: URL
    let contentLevel: SeedStoreContentLevel
    let resetOutput: Bool
    let saveInterval: Int

    init(arguments: [String]) throws {
        var inputPath = "../../Data/Processed/swiftdata_import"
        var outputPath = "../../Apps/Shared/Resources/ChineseCalendarSeedStore.bundle"
        var contentLevel = SeedStoreContentLevel.base
        var resetOutput = true
        var saveInterval = 2000

        var index = 1
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--input":
                inputPath = try Self.value(after: argument, in: arguments, at: &index)
            case "--output":
                outputPath = try Self.value(after: argument, in: arguments, at: &index)
            case "--content-level":
                let value = try Self.value(after: argument, in: arguments, at: &index)
                guard let parsedLevel = SeedStoreContentLevel(rawValue: value) else {
                    throw SeedStoreBuilderError.invalidArgument("--content-level must be base or full.")
                }
                contentLevel = parsedLevel
            case "--keep-output":
                resetOutput = false
            case "--save-interval":
                let value = try Self.value(after: argument, in: arguments, at: &index)
                guard let interval = Int(value), interval > 0 else {
                    throw SeedStoreBuilderError.invalidArgument("--save-interval must be a positive integer.")
                }
                saveInterval = interval
            case "--help", "-h":
                print(Self.helpText)
                Foundation.exit(0)
            default:
                throw SeedStoreBuilderError.invalidArgument("Unknown argument: \(argument)")
            }

            index += 1
        }

        inputURL = URL(fileURLWithPath: inputPath).standardizedFileURL
        outputURL = URL(fileURLWithPath: outputPath).standardizedFileURL
        self.contentLevel = contentLevel
        self.resetOutput = resetOutput
        self.saveInterval = saveInterval
    }

    private static func value(
        after argument: String,
        in arguments: [String],
        at index: inout Int
    ) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw SeedStoreBuilderError.invalidArgument("Missing value after \(argument).")
        }
        index = valueIndex
        return arguments[valueIndex]
    }

    private static let helpText = """
    Usage:
      swift run ChineseCalendarSeedStoreBuilder [options]

    Options:
      --input <path>          SwiftData import JSONL directory. Default: ../../Data/Processed/swiftdata_import
      --output <path>         Output resource bundle directory. Default: ../../Apps/Shared/Resources/ChineseCalendarSeedStore.bundle
      --content-level <level> Store content to build: base or full. Default: base
      --keep-output           Do not delete the existing output directory before building.
      --save-interval <count> Save after this many day bundles. Default: 2000
      --help                  Show this help text.
    """
}

private enum SeedStoreContentLevel: String {
    case base
    case full
}

private struct SeedStoreBuilder {
    private static let seedStoreFormatVersion = 4

    private let options: SeedStoreBuilderOptions
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default

    init(options: SeedStoreBuilderOptions) {
        self.options = options
    }

    func build() throws {
        if options.resetOutput {
            try? fileManager.removeItem(at: options.outputURL)
        }

        try fileManager.createDirectory(at: options.outputURL, withIntermediateDirectories: true)
        try removeStoreFiles(in: options.outputURL)

        let storeURL = options.outputURL.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)

        do {
            let container = try ChineseCalendarModelContainerFactory.makeContainer(at: storeURL)

            log("Importing lunar years...")
            try importLunarYears(into: container)

            log("Importing lunar months...")
            try importLunarMonths(into: container)

            if options.contentLevel == .full {
                log("Importing calendar days...")
                try importCalendarDayBundles(into: container)
            } else {
                log("Skipping calendar day import for base seed store...")
            }

            log("Importing dynasty and orthodox-period data...")
            try importDynastyArtifact(into: container)
        }

        try finalizeSQLiteStore(at: storeURL)
        try copyManifest()
        log("Seed store written to \(options.outputURL.path)")
    }

    private func importLunarYears(into container: ModelContainer) throws {
        var context = makeContext(for: container)
        var importedCount = 0

        try readJSONLines(
            at: options.inputURL.appendingPathComponent("chinese_lunar_years.jsonl"),
            as: LunarYearRecord.self
        ) { record in
            context.insert(ChineseLunarYear(
                lunarYearNumber: record.lunarYearNumber,
                yearStemIndex: record.yearStemIndex,
                yearBranchIndex: record.yearBranchIndex
            ))
            importedCount += 1

            if importedCount.isMultiple(of: options.saveInterval) {
                try saveAndReset(&context, container: container)
            }
        }

        try context.save()
    }

    private func importLunarMonths(into container: ModelContainer) throws {
        let context = makeContext(for: container)
        let yearsByNumber = try lunarYearsByNumber(in: context)
        var importedCount = 0

        try readJSONLines(
            at: options.inputURL.appendingPathComponent("chinese_lunar_months.jsonl"),
            as: LunarMonthRecord.self
        ) { record in
            guard let year = yearsByNumber[record.lunarYearNumber] else {
                throw SeedStoreBuilderError.missingLunarYear(record.lunarYearNumber)
            }
            let month = ChineseLunarMonth(
                lunarMonthIndex: record.lunarMonthIndex,
                lunarYearNumber: record.lunarYearNumber,
                monthNumberInYear: record.monthNumberInYear,
                isLeapMonth: record.isLeapMonth,
                intercalaryMonthNameStyle: record.intercalaryMonthNameStyle,
                dayCount: record.dayCount,
                monthStemIndex: record.monthStemIndex,
                monthBranchIndex: record.monthBranchIndex,
                chineseLunarYear: year
            )
            context.insert(month)
            importedCount += 1

            if importedCount.isMultiple(of: options.saveInterval) {
                try context.save()
            }
        }

        try context.save()
    }

    private func importCalendarDayBundles(into container: ModelContainer) throws {
        let calendarDaysURL = options.inputURL.appendingPathComponent("calendar_days", isDirectory: true)
        let yearDirectories = try fileManager.contentsOfDirectory(
            at: calendarDaysURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        )
        .filter { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            return values?.isDirectory == true
        }
        .sorted { lhs, rhs in
            (Int(lhs.lastPathComponent) ?? .min) < (Int(rhs.lastPathComponent) ?? .min)
        }

        var context = makeContext(for: container)
        let monthIdentifiersByIndex = try lunarMonthIdentifiersByIndex(in: context)
        var monthCache: [Int: ChineseLunarMonth] = [:]
        var importedDayCount = 0
        for yearDirectory in yearDirectories {
            let fileURL = yearDirectory.appendingPathComponent("calendar_days.jsonl")
            try readJSONLines(at: fileURL, as: CalendarDayBundleRecord.self) { record in
                let lunarMonth = try lunarMonth(
                    index: record.chineseLunarDay.lunarMonthIndex,
                    identifiersByIndex: monthIdentifiersByIndex,
                    in: context,
                    cache: &monthCache
                )
                let calendarDay = CalendarDay(
                    dayIndex: record.calendarDay.dayIndex,
                    julianDayNumber: record.calendarDay.julianDayNumber
                )
                let civilDate = CivilDate(
                    dayIndex: record.civilDate.dayIndex,
                    year: record.civilDate.year,
                    month: record.civilDate.month,
                    dayOfMonth: record.civilDate.dayOfMonth,
                    calendarStyle: record.civilDate.calendarStyle
                )
                let lunarDay = ChineseLunarDay(
                    dayIndex: record.chineseLunarDay.dayIndex,
                    lunarMonthIndex: record.chineseLunarDay.lunarMonthIndex,
                    dayNumberInMonth: record.chineseLunarDay.dayNumberInMonth,
                    dayStemIndex: record.chineseLunarDay.dayStemIndex,
                    dayBranchIndex: record.chineseLunarDay.dayBranchIndex,
                    chineseLunarMonth: lunarMonth
                )

                calendarDay.civilDate = civilDate
                calendarDay.chineseLunarDay = lunarDay
                context.insert(calendarDay)

                importedDayCount += 1
                if importedDayCount.isMultiple(of: options.saveInterval) {
                    try saveAndReset(&context, container: container)
                    monthCache.removeAll(keepingCapacity: true)
                }
            }

            log("  imported civil year \(yearDirectory.lastPathComponent)")
        }

        try context.save()
    }

    private func lunarYearsByNumber(in context: ModelContext) throws -> [Int: ChineseLunarYear] {
        let descriptor = FetchDescriptor<ChineseLunarYear>(
            sortBy: [SortDescriptor(\ChineseLunarYear.lunarYearNumber)]
        )
        let years = try context.fetch(descriptor)
        return Dictionary(uniqueKeysWithValues: years.map { ($0.lunarYearNumber, $0) })
    }

    private func lunarMonthIdentifiersByIndex(in context: ModelContext) throws -> [Int: PersistentIdentifier] {
        let descriptor = FetchDescriptor<ChineseLunarMonth>(
            sortBy: [SortDescriptor(\ChineseLunarMonth.lunarMonthIndex)]
        )
        let months = try context.fetch(descriptor)
        return Dictionary(uniqueKeysWithValues: months.map { ($0.lunarMonthIndex, $0.persistentModelID) })
    }

    private func lunarMonth(
        index lunarMonthIndex: Int,
        identifiersByIndex: [Int: PersistentIdentifier],
        in context: ModelContext,
        cache: inout [Int: ChineseLunarMonth]
    ) throws -> ChineseLunarMonth {
        if let cachedMonth = cache[lunarMonthIndex] {
            return cachedMonth
        }

        guard let identifier = identifiersByIndex[lunarMonthIndex],
              let lunarMonth = context.model(for: identifier) as? ChineseLunarMonth
        else {
            throw SeedStoreBuilderError.missingLunarMonth(lunarMonthIndex)
        }

        cache[lunarMonthIndex] = lunarMonth
        return lunarMonth
    }

    private func importDynastyArtifact(into container: ModelContainer) throws {
        let dateExpressionRecords = try readJSONLines(
            at: options.inputURL.appendingPathComponent("chinese_date_expressions.jsonl"),
            as: ChineseDateExpressionRecord.self
        )
        let dynastyRecords = try readJSONLines(
            at: options.inputURL.appendingPathComponent("dynasties.jsonl"),
            as: DynastyRecord.self
        )
        let traditionRecords = try readJSONLines(
            at: options.inputURL.appendingPathComponent("orthodox_traditions.jsonl"),
            as: OrthodoxTraditionRecord.self
        )
        let boundaryRecords = try readJSONLines(
            at: options.inputURL.appendingPathComponent("orthodox_boundaries.jsonl"),
            as: OrthodoxBoundaryRecord.self
        )
        let periodRecords = try readJSONLines(
            at: options.inputURL.appendingPathComponent("orthodox_periods.jsonl"),
            as: OrthodoxPeriodRecord.self
        )

        let context = makeContext(for: container)
        var availableDateExpressions = try keyedDateExpressions(from: dateExpressionRecords)
        var traditions: [String: OrthodoxTradition] = [:]
        var dynasties: [String: Dynasty] = [:]
        var boundaries: [String: OrthodoxBoundary] = [:]

        for record in dynastyRecords {
            let dynasty = try Dynasty(
                id: record.id,
                name: record.name,
                shortName: record.shortName,
                claimedStartDate: takeDateExpression(record.claimedStartDateID, from: &availableDateExpressions),
                claimedEndDate: takeDateExpression(record.claimedEndDateID, from: &availableDateExpressions),
                note: record.note
            )
            context.insert(dynasty)
            dynasties[record.id] = dynasty
        }

        for record in traditionRecords {
            let tradition = OrthodoxTradition(
                id: record.id,
                name: record.name,
                note: record.note
            )
            context.insert(tradition)
            traditions[record.id] = tradition
        }

        for record in boundaryRecords {
            guard let tradition = traditions[record.traditionID] else {
                throw SeedStoreBuilderError.missingReference(
                    "OrthodoxBoundary \(record.id) references missing OrthodoxTradition \(record.traditionID)."
                )
            }

            let boundary = try OrthodoxBoundary(
                id: record.id,
                traditionID: record.traditionID,
                dateExpressionID: record.dateExpressionID,
                tradition: tradition,
                date: takeDateExpression(record.dateExpressionID, from: &availableDateExpressions),
                note: record.note
            )
            context.insert(boundary)
            boundaries[record.id] = boundary
        }

        if !availableDateExpressions.isEmpty {
            let ids = availableDateExpressions.keys.sorted().joined(separator: ", ")
            throw SeedStoreBuilderError.unusedDateExpressions(ids)
        }

        for record in periodRecords.sorted(by: { $0.sequenceIndex < $1.sequenceIndex }) {
            guard let tradition = traditions[record.traditionID] else {
                throw SeedStoreBuilderError.missingReference(
                    "OrthodoxPeriod \(record.id) references missing OrthodoxTradition \(record.traditionID)."
                )
            }
            guard let dynasty = dynasties[record.dynastyID] else {
                throw SeedStoreBuilderError.missingReference(
                    "OrthodoxPeriod \(record.id) references missing Dynasty \(record.dynastyID)."
                )
            }
            guard let startBoundary = boundaries[record.startBoundaryID] else {
                throw SeedStoreBuilderError.missingReference(
                    "OrthodoxPeriod \(record.id) references missing start OrthodoxBoundary \(record.startBoundaryID)."
                )
            }
            guard let endBoundary = boundaries[record.endBoundaryID] else {
                throw SeedStoreBuilderError.missingReference(
                    "OrthodoxPeriod \(record.id) references missing end OrthodoxBoundary \(record.endBoundaryID)."
                )
            }

            context.insert(OrthodoxPeriod(
                id: record.id,
                traditionID: record.traditionID,
                dynastyID: record.dynastyID,
                startBoundaryID: record.startBoundaryID,
                endBoundaryID: record.endBoundaryID,
                sequenceIndex: record.sequenceIndex,
                segmentIndex: record.segmentIndex,
                segmentName: record.segmentName,
                tradition: tradition,
                dynasty: dynasty,
                startBoundary: startBoundary,
                endBoundary: endBoundary,
                note: record.note
            ))
        }

        try context.save()
    }

    private func takeDateExpression(
        _ id: String,
        from records: inout [String: ChineseDateExpressionRecord]
    ) throws -> ChineseDateExpression {
        guard let record = records.removeValue(forKey: id) else {
            throw SeedStoreBuilderError.missingReference("Missing ChineseDateExpression \(id).")
        }
        return makeDateExpression(from: record)
    }

    private func keyedDateExpressions(
        from records: [ChineseDateExpressionRecord]
    ) throws -> [String: ChineseDateExpressionRecord] {
        var result: [String: ChineseDateExpressionRecord] = [:]
        for record in records {
            guard result[record.id] == nil else {
                throw SeedStoreBuilderError.duplicateRecord("ChineseDateExpression", record.id)
            }
            result[record.id] = record
        }
        return result
    }

    private func makeDateExpression(from record: ChineseDateExpressionRecord) -> ChineseDateExpression {
        ChineseDateExpression(
            id: record.id,
            precision: record.precision,
            index: record.index,
            uncertainRange: record.uncertainRange.map(makeDateRange),
            sourceText: record.sourceText,
            note: record.note
        )
    }

    private func makeDateRange(from record: ChineseDateRangeRecord) -> ChineseDateRange {
        ChineseDateRange(
            id: record.id,
            lowerBound: makeDateBound(from: record.lowerBound),
            upperBound: makeDateBound(from: record.upperBound)
        )
    }

    private func makeDateBound(from record: ChineseDateBoundRecord) -> ChineseDateBound {
        ChineseDateBound(
            id: record.id,
            precision: record.precision,
            index: record.index
        )
    }

    private func makeContext(for container: ModelContainer) -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private func removeStoreFiles(in directoryURL: URL) throws {
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return
        }

        let storeFileName = ChineseCalendarSeedStore.storeFileName
        let storeFiles = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            .filter { fileURL in
                let fileName = fileURL.lastPathComponent
                return fileName == storeFileName || fileName.hasPrefix("\(storeFileName)-")
            }
        try storeFiles.forEach { try fileManager.removeItem(at: $0) }
    }

    private func saveAndReset(_ context: inout ModelContext, container: ModelContainer) throws {
        try context.save()
        context = makeContext(for: container)
    }

    private func log(_ message: String) {
        FileHandle.standardOutput.write(Data("\(message)\n".utf8))
    }

    private func finalizeSQLiteStore(at storeURL: URL) throws {
        try runSQLiteCommand(
            storeURL: storeURL,
            sql: """
            PRAGMA wal_checkpoint(TRUNCATE);
            DELETE FROM ACHANGE;
            DELETE FROM ATRANSACTION;
            DELETE FROM ATRANSACTIONSTRING;
            VACUUM;
            PRAGMA journal_mode=DELETE;
            """
        )

        for suffix in ["-shm", "-wal"] {
            let sidecarURL = URL(fileURLWithPath: "\(storeURL.path)\(suffix)")
            if fileManager.fileExists(atPath: sidecarURL.path) {
                try fileManager.removeItem(at: sidecarURL)
            }
        }
    }

    private func runSQLiteCommand(storeURL: URL, sql: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [storeURL.path, sql]

        let errorPipe = Pipe()
        let outputPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = outputPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(decoding: errorData, as: UTF8.self)
            throw SeedStoreBuilderError.sqliteCommandFailed(errorMessage)
        }
    }

    private func copyManifest() throws {
        let sourceURL = options.inputURL.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
        let destinationURL = options.outputURL.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)

        guard fileManager.fileExists(atPath: sourceURL.path) else {
            return
        }

        let sourceData = try Data(contentsOf: sourceURL)
        guard let manifest = try JSONSerialization.jsonObject(with: sourceData) as? [String: Any] else {
            throw SeedStoreBuilderError.invalidManifest(sourceURL)
        }

        var runtimeManifest = runtimeSeedStoreManifest(from: manifest)
        runtimeManifest["seedStoreBuilder"] = "Scripts/BuildChineseCalendarSeedStore"
        runtimeManifest["seedStoreContentLevel"] = options.contentLevel.rawValue
        runtimeManifest["seedStoreFormatVersion"] = Self.seedStoreFormatVersion
        runtimeManifest["seedStoreHistoryPurged"] = true
        runtimeManifest["seedStoreRelationshipsLinked"] = true

        if options.contentLevel == .base {
            runtimeManifest["totalCalendarDays"] = 0
            runtimeManifest["totalChineseLunarDays"] = 0
            runtimeManifest["totalCivilDates"] = 0
        }

        var destinationData = try JSONSerialization.data(
            withJSONObject: runtimeManifest,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        destinationData.append(Data("\n".utf8))

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try destinationData.write(to: destinationURL, options: .atomic)
    }

    private func runtimeSeedStoreManifest(from source: [String: Any]) -> [String: Any] {
        var manifest: [String: Any] = [:]
        copyManifestValues(
            [
                "artifact",
                "datasetVersion",
                "generatedAt",
                "schemaVersion",
                "sourceArtifact",
                "sourceUpstreamCommit",
                "sourceUpstreamRepository",
                "startDayIndex",
                "startYear",
                "endDayIndex",
                "endYear",
                "totalCalendarDays",
                "totalChineseLunarDays",
                "totalChineseLunarMonths",
                "totalChineseLunarYears",
                "totalCivilDates"
            ],
            from: source,
            to: &manifest
        )

        if let dynastyArtifact = source["dynastyArtifact"] as? [String: Any] {
            manifest["dynastyArtifact"] = compactDynastyArtifact(from: dynastyArtifact)
        }

        return manifest
    }

    private func compactDynastyArtifact(from source: [String: Any]) -> [String: Any] {
        var artifact: [String: Any] = [:]
        copyManifestValues(
            [
                "artifact",
                "generatedAt",
                "rawFetchedAt",
                "rawFile",
                "rawSha256",
                "sourceURL",
                "sourceUpstreamCommit",
                "sourceUpstreamRepository",
                "totalChineseDateExpressions",
                "totalDynasties",
                "totalOrthodoxBoundaries",
                "totalOrthodoxPeriods",
                "totalOrthodoxTraditions"
            ],
            from: source,
            to: &artifact
        )
        return artifact
    }

    private func copyManifestValues(
        _ keys: [String],
        from source: [String: Any],
        to destination: inout [String: Any]
    ) {
        for key in keys {
            if let value = source[key] {
                destination[key] = value
            }
        }
    }

    private func readJSONLines<Record: Decodable>(
        at fileURL: URL,
        as _: Record.Type,
        body: (Record) throws -> Void
    ) throws {
        let text = try String(contentsOf: fileURL, encoding: .utf8)
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let data = Data(line.utf8)
            try body(decoder.decode(Record.self, from: data))
        }
    }

    private func readJSONLines<Record: Decodable>(
        at fileURL: URL,
        as type: Record.Type
    ) throws -> [Record] {
        var records: [Record] = []
        try readJSONLines(at: fileURL, as: type) { record in
            records.append(record)
        }
        return records
    }
}

private enum SeedStoreBuilderError: Error, LocalizedError {
    case invalidArgument(String)
    case invalidManifest(URL)
    case missingLunarYear(Int)
    case missingLunarMonth(Int)
    case sqliteCommandFailed(String)
    case missingReference(String)
    case unusedDateExpressions(String)
    case duplicateRecord(String, String)

    var errorDescription: String? {
        switch self {
        case let .invalidArgument(message):
            message
        case let .invalidManifest(url):
            "Seed store manifest is not a JSON object: \(url.path)."
        case let .missingLunarYear(lunarYearNumber):
            "Missing lunar year while linking seed data: \(lunarYearNumber)."
        case let .missingLunarMonth(lunarMonthIndex):
            "Missing lunar month while linking seed data: \(lunarMonthIndex)."
        case let .sqliteCommandFailed(message):
            "Failed to finalize SQLite seed store. \(message)"
        case let .missingReference(message):
            message
        case let .unusedDateExpressions(ids):
            "Unused ChineseDateExpression records: \(ids)."
        case let .duplicateRecord(entity, id):
            "Duplicate \(entity) record id: \(id)."
        }
    }
}
