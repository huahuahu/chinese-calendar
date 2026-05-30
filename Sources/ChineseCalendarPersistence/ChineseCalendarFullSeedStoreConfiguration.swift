import Foundation

public struct FullSeedStoreConfig: Sendable {
    public static let infoPlistManifestURLKey = "ChineseCalendarFullSeedStoreManifestURL"
    public static let environmentManifestURLKey = "CHINESE_CALENDAR_FULL_SEED_STORE_MANIFEST_URL"

    public let manifestURL: URL

    public init(manifestURL: URL) {
        self.manifestURL = manifestURL
    }

    public static func fromBundle(
        _ bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Self? {
        if let manifestURL = environment[environmentManifestURLKey].flatMap(URL.init(trimmedString:)) {
            return Self(manifestURL: manifestURL)
        }

        guard let bundleValue = bundle.object(forInfoDictionaryKey: infoPlistManifestURLKey) as? String,
              let manifestURL = URL(trimmedString: bundleValue)
        else {
            return nil
        }

        return Self(manifestURL: manifestURL)
    }
}

private extension URL {
    init?(trimmedString: String) {
        let value = trimmedString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, let url = URL(string: value) else {
            return nil
        }

        self = url
    }
}
