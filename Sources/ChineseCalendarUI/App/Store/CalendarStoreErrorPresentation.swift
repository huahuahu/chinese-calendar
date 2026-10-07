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
        if let error = error as? ChineseCalendarFullSeedStoreInstallError {
            return downloadMessage(for: error)
        }
        if let error = error as? ChineseCalendarStoreError {
            return storeMessage(for: error)
        }
        if error is DecodingError {
            return CalendarStringKey.Store.Error.invalidManifest
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return nsError.code == NSURLErrorTimedOut
                ? CalendarStringKey.Store.Error.timedOut
                : CalendarStringKey.Store.Error.network
        }
        if let message = fileMessage(for: nsError) {
            return message
        }
        switch operation {
        case .prepare: return CalendarStringKey.Store.Error.prepare
        case .download: return CalendarStringKey.Store.Error.download
        case .clear: return CalendarStringKey.Store.Error.clear
        }
    }

    private static func storeMessage(for error: ChineseCalendarStoreError) -> LocalizedStringResource {
        switch error {
        case .missingAppGroupContainer:
            CalendarStringKey.Store.Error.missingContainer
        case .missingSeedResource, .missingSeedStore:
            CalendarStringKey.Store.Error.missingResource
        }
    }

    private static func fileMessage(for error: NSError) -> LocalizedStringResource? {
        guard error.domain == NSCocoaErrorDomain else { return nil }
        switch error.code {
        case NSFileWriteOutOfSpaceError:
            return CalendarStringKey.Store.Error.storage
        case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
            return CalendarStringKey.Store.Error.permission
        default:
            return nil
        }
    }

    private static func downloadMessage(
        for error: ChineseCalendarFullSeedStoreInstallError
    ) -> LocalizedStringResource {
        switch error {
        case .unsupportedSchemaVersion:
            CalendarStringKey.Store.Error.incompatible
        case .unsupportedContentLevel, .unsupportedStoreFileName,
             .invalidManifestByteCount, .invalidManifestChecksum:
            CalendarStringKey.Store.Error.invalidManifest
        case .invalidContentRange, .rangeNotSatisfiable:
            CalendarStringKey.Store.Error.expiredDownload
        case .invalidByteCount, .checksumMismatch, .missingDownloadedStore:
            CalendarStringKey.Store.Error.invalidFile
        case let .downloadFailed(status):
            CalendarStringKey.Store.Error.server(status: status)
        }
    }
}
