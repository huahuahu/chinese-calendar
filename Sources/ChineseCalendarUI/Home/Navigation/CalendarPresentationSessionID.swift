/// 根宿主观察业务登记时保留身份类别，防止不同会话具有相同底层值时被集合合并。
nonisolated enum CalendarPresentationSessionID: Hashable {
    case yearPicker(YearPickerSessionID)
    case alertMessage(CalendarAlertMessageID)
    #if DEBUG
        case downloadPreview(DownloadPreviewSessionID)
    #endif
}
