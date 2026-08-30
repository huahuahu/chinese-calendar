@testable import ChineseCalendarPersistence
import Foundation
import Testing

@Suite("Seed store artifact identity")
struct SeededModelContainerTests {
    @Test func provenanceOnlyManifestChangesDoNotReinstall() throws {
        let fixture = try SeedStoreFixture(
            seedManifest: Self.manifest(artifactVersion: "artifact-a", generatedAt: "new"),
            installedManifest: Self.manifest(artifactVersion: "artifact-a", generatedAt: "old")
        )
        defer { fixture.remove() }

        #expect(try !fixture.shouldInstall())
    }

    @Test func changedArtifactVersionReinstallsBundledBaseStore() throws {
        let fixture = try SeedStoreFixture(
            seedManifest: Self.manifest(artifactVersion: "artifact-b"),
            installedManifest: Self.manifest(artifactVersion: "artifact-a")
        )
        defer { fixture.remove() }

        #expect(try fixture.shouldInstall())
    }

    @Test func installedFullStoreIsNeverReplacedByBundledBaseStore() throws {
        let fixture = try SeedStoreFixture(
            seedManifest: Self.manifest(artifactVersion: "artifact-b", contentLevel: "base"),
            installedManifest: Self.manifest(artifactVersion: "artifact-a", contentLevel: "full")
        )
        defer { fixture.remove() }

        #expect(try !fixture.shouldInstall())
    }

    @Test func missingInstalledManifestRequiresInstallation() throws {
        let fixture = try SeedStoreFixture(
            seedManifest: Self.manifest(artifactVersion: "artifact-a"),
            installedManifest: nil
        )
        defer { fixture.remove() }

        #expect(try fixture.shouldInstall())
    }

    @Test func identityTokenPrefersArtifactThenDatasetAndNeverUsesGeneratedAt() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SeedStoreIdentityTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manifestURL = directory.appendingPathComponent("manifest.json")

        try writeJSON(
            ["artifactVersion": "artifact-a", "datasetVersion": "dataset-a", "generatedAt": "timestamp"],
            to: manifestURL
        )
        #expect(try ChineseCalendarModelContainerFactory.seedStoreIdentityToken(at: manifestURL) == "artifact-a")

        try writeJSON(["datasetVersion": "dataset-a", "generatedAt": "timestamp"], to: manifestURL)
        #expect(try ChineseCalendarModelContainerFactory.seedStoreIdentityToken(at: manifestURL) == "dataset-a")

        try writeJSON(["generatedAt": "timestamp"], to: manifestURL)
        #expect(try ChineseCalendarModelContainerFactory.seedStoreIdentityToken(at: manifestURL) == nil)
    }

    private static func manifest(
        artifactVersion: String,
        generatedAt: String = "timestamp",
        contentLevel: String = "base"
    ) -> [String: Any] {
        [
            "artifactVersion": artifactVersion,
            "datasetVersion": "dataset",
            "generatedAt": generatedAt,
            "seedStoreContentLevel": contentLevel
        ]
    }
}

private struct SeedStoreFixture {
    let rootURL: URL
    let seedDirectory: URL
    let storeDirectory: URL

    init(seedManifest: [String: Any], installedManifest: [String: Any]?) throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SeedStoreTests-\(UUID().uuidString)", isDirectory: true)
        seedDirectory = rootURL.appendingPathComponent("seed", isDirectory: true)
        storeDirectory = rootURL.appendingPathComponent("installed", isDirectory: true)
        try FileManager.default.createDirectory(at: seedDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)

        try Data().write(to: storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName))
        try writeJSON(seedManifest, to: seedDirectory.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName))
        if let installedManifest {
            try writeJSON(
                installedManifest,
                to: storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
            )
        }
    }

    func shouldInstall() throws -> Bool {
        try ChineseCalendarModelContainerFactory.shouldInstallSeedStore(
            seedDirectory: seedDirectory,
            storeDirectory: storeDirectory,
            fileManager: .default
        )
    }

    func remove() {
        try? FileManager.default.removeItem(at: rootURL)
    }
}

private func writeJSON(_ object: [String: Any], to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    try data.write(to: url, options: .atomic)
}
