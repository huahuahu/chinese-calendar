import ChineseCalendarLocalization
import ChineseCalendarPersistence
import Foundation

/// 在界面边界把结构化错误转换为恢复建议，底层诊断文本仅用于日志。
enum CalendarStoreErrorPresentation {
    enum Operation {
        case prepare
        case download
        case clear
    }

    static func message(for error: Error, operation: Operation) -> LocalizedStringResource {
        message(for: failure(for: error, operation: operation))
    }

    // Each value maps directly to one localized recovery message.
    // swiftlint:disable:next cyclomatic_complexity
    static func message(for failure: CalendarStoreFailure) -> LocalizedStringResource {
        switch failure {
        case .prepare: CalendarStringKey.Store.Error.prepare
        case .download: CalendarStringKey.Store.Error.download
        case .clear: CalendarStringKey.Store.Error.clear
        case .missingContainer: CalendarStringKey.Store.Error.missingContainer
        case .missingResource: CalendarStringKey.Store.Error.missingResource
        case .invalidManifest: CalendarStringKey.Store.Error.invalidManifest
        case .timedOut: CalendarStringKey.Store.Error.timedOut
        case .network: CalendarStringKey.Store.Error.network
        case .storage: CalendarStringKey.Store.Error.storage
        case .permission: CalendarStringKey.Store.Error.permission
        case .incompatible: CalendarStringKey.Store.Error.incompatible
        case .expiredDownload: CalendarStringKey.Store.Error.expiredDownload
        case .invalidFile: CalendarStringKey.Store.Error.invalidFile
        case let .server(status): CalendarStringKey.Store.Error.server(status: status)
        }
    }

    static func failure(for error: Error, operation: Operation) -> CalendarStoreFailure {
        if let error = error as? ChineseCalendarFullSeedStoreInstallError {
            return downloadFailure(for: error)
        }
        if let error = error as? ChineseCalendarStoreError {
            return storeFailure(for: error)
        }
        if error is DecodingError {
            return .invalidManifest
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return nsError.code == NSURLErrorTimedOut
                ? .timedOut
                : .network
        }
        if let failure = fileFailure(for: nsError) {
            return failure
        }
        switch operation {
        case .prepare: return .prepare
        case .download: return .download
        case .clear: return .clear
        }
    }

    private static func storeFailure(for error: ChineseCalendarStoreError) -> CalendarStoreFailure {
        switch error {
        case .missingAppGroupContainer:
            .missingContainer
        case .missingSeedResource, .missingSeedStore:
            .missingResource
        }
    }

    private static func fileFailure(for error: NSError) -> CalendarStoreFailure? {
        guard error.domain == NSCocoaErrorDomain else { return nil }
        switch error.code {
        case NSFileWriteOutOfSpaceError:
            return .storage
        case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
            return .permission
        default:
            return nil
        }
    }

    private static func downloadFailure(
        for error: ChineseCalendarFullSeedStoreInstallError
    ) -> CalendarStoreFailure {
        switch error {
        case .unsupportedSchemaVersion:
            .incompatible
        case .unsupportedContentLevel, .unsupportedStoreFileName,
             .invalidManifestByteCount, .invalidManifestChecksum:
            .invalidManifest
        case .invalidContentRange, .rangeNotSatisfiable:
            .expiredDownload
        case .invalidByteCount, .checksumMismatch, .missingDownloadedStore:
            .invalidFile
        case let .downloadFailed(status):
            .server(status: status)
        }
    }
}
