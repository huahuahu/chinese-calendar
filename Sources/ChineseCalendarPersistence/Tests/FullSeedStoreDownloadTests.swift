@testable import ChineseCalendarPersistence
import CryptoKit
import Foundation
import Synchronization
import Testing

@Suite("Full seed store download progress and resume", .timeLimit(.minutes(1)))
struct FullSeedStoreDownloadTests {
    static let chunkSize = 256 * 1024
    static let body = (1 ... 4).reduce(into: Data()) { result, byte in
        result.append(Data(repeating: UInt8(byte), count: chunkSize))
    }

    @Test(arguments: [true, false])
    func reportsProgressBeforeResponseFinishes(includesContentLength: Bool) async throws {
        let fixture = try Fixture(includesContentLength: includesContentLength)
        defer { fixture.cleanUp() }
        let transfer = fixture.start()
        defer { transfer.task.cancel() }
        var iterator = transfer.events.makeAsyncIterator()

        let initial = await iterator.next()
        #expect(initial == 0)
        let partial = await iterator.next()
        let fraction = try #require(partial)
        #expect(fraction > 0 && fraction <= 0.25)
        #expect(!fixture.response.observations.withLock { $0.finished })
        #expect(!FileManager.default.fileExists(atPath: fixture.destinationURL.path))
        #expect(try Data(contentsOf: fixture.partialURL).count >= Int(fraction * Double(Self.body.count)))

        fixture.response.remainder.continuation.finish()
        let result = try await transfer.task.value
        #expect(try Data(contentsOf: result) == Self.body)
        let fractions = transfer.fractions.values.withLock { $0 }
        #expect(fractions.last == 1)
        #expect(fractions == fractions.sorted())
    }

    @Test func resumedDownloadCountsExistingBytes() async throws {
        let fixture = try Fixture(statusCode: 206, existingChunks: 1)
        defer { fixture.cleanUp() }
        let transfer = fixture.start()
        defer { transfer.task.cancel() }
        var iterator = transfer.events.makeAsyncIterator()

        let initial = await iterator.next()
        #expect(initial == 0.25)
        let partial = await iterator.next()
        let fraction = try #require(partial)
        #expect(fraction > 0.25 && fraction <= 0.5)
        #expect(fixture.response.observations.withLock { $0.rangeHeader } == "bytes=\(Self.chunkSize)-")

        fixture.response.remainder.continuation.finish()
        #expect(try await Data(contentsOf: transfer.task.value) == Self.body)
        #expect(transfer.fractions.values.withLock { $0.last } == 1)
    }

    @Test func ignoredRangeRestartsProgressAndReplacesOldPartial() async throws {
        let fixture = try Fixture(existingChunks: 2)
        defer { fixture.cleanUp() }
        let transfer = fixture.start()
        defer { transfer.task.cancel() }
        var iterator = transfer.events.makeAsyncIterator()

        let initial = await iterator.next()
        #expect(initial == 0.5)
        let partial = await iterator.next()
        let fraction = try #require(partial)
        #expect(fraction > 0 && fraction <= 0.25)
        #expect(fixture.response.observations.withLock { $0.rangeHeader } == "bytes=\(Self.chunkSize * 2)-")

        fixture.response.remainder.continuation.finish()
        #expect(try await Data(contentsOf: transfer.task.value) == Self.body)
        #expect(transfer.fractions.values.withLock { $0.last } == 1)
    }

    @Test func cancellationStopsAnUnfinishedResponse() async throws {
        let fixture = try Fixture(statusCode: 206, existingChunks: 1)
        defer { fixture.cleanUp() }
        let transfer = fixture.start()
        var iterator = transfer.events.makeAsyncIterator()
        _ = await iterator.next()
        while let fraction = await iterator.next(), fraction < 0.5 {}
        #expect(try Data(contentsOf: fixture.partialURL) == Self.body.prefix(Self.chunkSize * 2))

        transfer.task.cancel()
        do {
            _ = try await transfer.task.value
            Issue.record("Cancelled transfer unexpectedly finished")
        } catch {
            #expect(error is CancellationError || (error as? URLError)?.code == .cancelled)
        }
        #expect(!fixture.response.observations.withLock { $0.finished })
        #expect(!FileManager.default.fileExists(atPath: fixture.destinationURL.path))
        #expect(try Data(contentsOf: fixture.partialURL) == Self.body.prefix(Self.chunkSize * 2))
        #expect(fixture.requests.count == 1)
    }

    @Test func failedResponseDoesNotReportDownloadedErrorPage() async throws {
        let fixture = try Fixture(statusCode: 404)
        defer { fixture.cleanUp() }
        fixture.response.remainder.continuation.finish()
        let transfer = fixture.start()

        do {
            _ = try await transfer.task.value
            Issue.record("HTTP 404 unexpectedly succeeded")
        } catch let ChineseCalendarFullSeedStoreInstallError.downloadFailed(statusCode) {
            #expect(statusCode == 404)
        }
        #expect(transfer.fractions.values.withLock { $0 } == [0])
        #expect(!FileManager.default.fileExists(atPath: fixture.destinationURL.path))
    }

    @Test(arguments: [Int64(0), -1])
    func invalidManifestSizeIsRejectedBeforeAnyRequest(byteCount: Int64) async throws {
        let fixture = try Fixture(expectedByteCount: byteCount)
        defer { fixture.cleanUp() }
        let transfer = fixture.start()

        do {
            _ = try await transfer.task.value
            Issue.record("Invalid manifest size unexpectedly succeeded")
        } catch let ChineseCalendarFullSeedStoreInstallError.invalidManifestByteCount(actual) {
            #expect(actual == byteCount)
        }
        #expect(transfer.fractions.values.withLock { $0.isEmpty })
        #expect(!fixture.response.observations.withLock { $0.started })
    }
}

extension FullSeedStoreDownloadTests {
    @Test(arguments: [false, true])
    func newInstallerResumesPersistedHalfAfterInterruption(networkFailure: Bool) async throws {
        let first = try Fixture(
            firstChunkSize: Self.chunkSize * 2,
            failureAfterFirstChunk: networkFailure ? URLError(.networkConnectionLost) : nil
        )
        defer { first.cleanUp() }
        let transfer = first.start()
        defer { transfer.task.cancel() }
        var iterator = transfer.events.makeAsyncIterator()
        while let fraction = await iterator.next(), fraction < 0.5 {}

        // 在取消或断网之前就检查文件，证明保存数据不依赖终止回调。
        #expect(try Data(contentsOf: first.partialURL) == Self.body.prefix(Self.chunkSize * 2))
        #expect(!first.response.observations.withLock { $0.finished })
        if networkFailure {
            first.response.remainder.continuation.finish()
        } else {
            transfer.task.cancel()
        }
        do {
            _ = try await transfer.task.value
            Issue.record("Interrupted transfer unexpectedly finished")
        } catch {
            #expect(error is CancellationError || error is URLError)
        }
        first.closeSession()

        // 使用新的会话和 installer，只复用磁盘目录，不预先填入任何片段。
        let second = try Fixture(statusCode: 206, directory: first.directory, responseOffset: Self.chunkSize * 2)
        defer { second.closeSession() }
        let resumed = second.start()
        defer { resumed.task.cancel() }
        var resumedIterator = resumed.events.makeAsyncIterator()
        let initial = await resumedIterator.next()
        #expect(initial == 0.5)
        let next = await resumedIterator.next()
        #expect(try #require(next) > 0.5)
        #expect(second.response.observations.withLock { $0.rangeHeader } == "bytes=\(Self.chunkSize * 2)-")
        second.response.remainder.continuation.finish()
        #expect(try await Data(contentsOf: resumed.task.value) == Self.body)
    }

    @Test func differentFullHashesNeverReuseTheSamePartial() async throws {
        let firstHash = String(repeating: "a", count: 64)
        let secondHash = String(repeating: "a", count: 63) + "b"
        let first = try Fixture(existingChunks: 2, sha256: firstHash)
        defer { first.cleanUp() }
        let second = try Fixture(directory: first.directory, sha256: secondHash)
        defer { second.closeSession() }
        #expect(first.partialURL != second.partialURL)
        #expect(second.partialURL.deletingLastPathComponent().lastPathComponent.contains(secondHash))
        let transfer = second.start()
        defer { transfer.task.cancel() }
        var iterator = transfer.events.makeAsyncIterator()
        let initial = await iterator.next()
        #expect(initial == 0)
        _ = await iterator.next()
        #expect(second.response.observations.withLock { $0.rangeHeader } == nil)
        second.response.remainder.continuation.finish()
        #expect(try await Data(contentsOf: transfer.task.value) == Self.body)
        #expect(try Data(contentsOf: first.partialURL) == Self.body.prefix(Self.chunkSize * 2))
    }

    @Test(arguments: ["bytes 0-1048575/1048576", "bytes 262144-1048575/2097152", "invalid"])
    func invalidContentRangeRestartsWithoutAppendingWrongData(contentRange: String) async throws {
        let fixture = try Fixture(statusCode: 206, existingChunks: 1, contentRange: contentRange)
        defer { fixture.cleanUp() }
        let retry = fixture.enqueueResponse(statusCode: 200)
        fixture.response.remainder.continuation.finish()
        retry.remainder.continuation.finish()
        let transfer = fixture.start()
        #expect(try await Data(contentsOf: transfer.task.value) == Self.body)
        #expect(fixture.requests.map { $0.value(forHTTPHeaderField: "Range") } == ["bytes=\(Self.chunkSize)-", nil])
        #expect(transfer.fractions.values.withLock { Array($0.prefix(2)) } == [0.25, 0])
    }

    @Test func completePartialSkipsNetwork() async throws {
        let fixture = try Fixture(existingChunks: 4)
        defer { fixture.cleanUp() }
        let transfer = fixture.start()
        #expect(try await Data(contentsOf: transfer.task.value) == Self.body)
        #expect(!fixture.response.observations.withLock { $0.started })
        #expect(transfer.fractions.values.withLock { $0 } == [1])
    }

    @Test(arguments: ["../invalid", String(repeating: "z", count: 64), String(repeating: "a", count: 63)])
    func invalidChecksumIsRejectedBeforeAnyRequest(checksum: String) async throws {
        let fixture = try Fixture(sha256: checksum)
        defer { fixture.cleanUp() }
        let transfer = fixture.start()
        await #expect(throws: ChineseCalendarFullSeedStoreInstallError.self) {
            try await transfer.task.value
        }
        #expect(!fixture.response.observations.withLock { $0.started })
    }
}

extension FullSeedStoreDownloadTests {
    final class ProgressLog: Sendable {
        let values = Mutex<[Double]>([])
    }

    struct Transfer {
        let task: Task<URL, Error>
        let events: AsyncStream<Double>
        let fractions: ProgressLog
    }

    struct Fixture {
        let directory: URL
        let partialURL: URL
        let destinationURL: URL
        let manifest: FullSeedStoreManifest
        let session: URLSession
        let response: SeedDownloadURLProtocol.Response
        let route: SeedDownloadURLProtocol.Route

        var requests: [URLRequest] {
            route.state.withLock { $0.requests }
        }

        init(
            statusCode: Int = 200,
            existingChunks: Int = 0,
            includesContentLength: Bool = true,
            expectedByteCount: Int64 = Int64(FullSeedStoreDownloadTests.body.count),
            directory existingDirectory: URL? = nil,
            responseOffset: Int? = nil,
            firstChunkSize: Int = chunkSize,
            sha256: String? = nil,
            contentRange: String? = nil,
            failureAfterFirstChunk: URLError? = nil
        ) throws {
            directory = existingDirectory ?? FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            let url = try #require(URL(string: "https://download.invalid/\(UUID().uuidString)"))
            manifest = FullSeedStoreManifest(
                datasetVersion: "test", schemaVersion: ChineseCalendarModelSchema.versionIdentifier,
                seedStoreContentLevel: .full, seedStoreFormatVersion: 4,
                byteCount: expectedByteCount,
                sha256: sha256 ?? SHA256.hash(data: body).map { String(format: "%02x", $0) }.joined(),
                downloadURL: url
            )
            let partialDirectory = ChineseCalendarFullSeedStoreInstaller.partialStoreDirectory(
                in: directory, manifest: manifest
            )
            try FileManager.default.createDirectory(at: partialDirectory, withIntermediateDirectories: true)
            partialURL = partialDirectory.appendingPathComponent("store.partial")
            destinationURL = directory.appendingPathComponent("store.sqlite")
            let existingByteCount = existingChunks * chunkSize
            if existingByteCount > 0 {
                try body.prefix(existingByteCount).write(to: partialURL)
            }
            let offset = responseOffset ?? existingByteCount
            response = SeedDownloadURLProtocol.Response(
                statusCode: statusCode,
                body: statusCode == 206 ? Data(body.dropFirst(offset)) : body,
                includesContentLength: includesContentLength,
                firstChunkSize: firstChunkSize,
                contentRange: contentRange ??
                    (statusCode == 206 ? "bytes \(offset)-\(body.count - 1)/\(body.count)" : nil),
                failureAfterFirstChunk: failureAfterFirstChunk
            )
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [SeedDownloadURLProtocol.self]
            configuration.timeoutIntervalForRequest = 10
            configuration.timeoutIntervalForResource = 15
            session = URLSession(configuration: configuration)
            route = SeedDownloadURLProtocol.Route(responses: [response])
            SeedDownloadURLProtocol.routes.withLock { $0[url] = route }
        }

        func start(fileManager: sending FileManager = FileManager()) -> Transfer {
            let events = AsyncStream<Double>.makeStream()
            let fractions = ProgressLog()
            let installer = ChineseCalendarFullSeedStoreInstaller(
                configuration: FullSeedStoreConfig(manifestURL: manifest.downloadURL),
                session: session, fileManager: fileManager
            )
            let task = Task {
                defer { events.continuation.finish() }
                return try await installer.downloadStore(
                    manifest: manifest, partialURL: partialURL, destinationURL: destinationURL
                ) { event in
                    if case let .downloading(fraction) = event {
                        fractions.values.withLock { $0.append(fraction) }
                        events.continuation.yield(fraction)
                    }
                }
            }
            return Transfer(task: task, events: events.stream, fractions: fractions)
        }

        func enqueueResponse(statusCode: Int, contentRange: String? = nil) -> SeedDownloadURLProtocol.Response {
            let response = SeedDownloadURLProtocol.Response(
                statusCode: statusCode, body: body, includesContentLength: true,
                firstChunkSize: chunkSize, contentRange: contentRange
            )
            route.state.withLock { $0.responses.append(response) }
            return response
        }

        func closeSession() {
            response.remainder.continuation.finish()
            session.invalidateAndCancel()
            for response in route.state.withLock({ $0.responses }) {
                response.remainder.continuation.finish()
            }
            SeedDownloadURLProtocol.routes.withLock { $0[manifest.downloadURL] = nil }
        }

        func cleanUp() {
            closeSession()
            try? FileManager.default.removeItem(at: directory)
        }
    }
}
