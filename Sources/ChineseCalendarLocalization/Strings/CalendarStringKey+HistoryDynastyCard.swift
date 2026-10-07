import Foundation

public extension CalendarStringKey.History {
    enum DynastyCard {}
}

public extension CalendarStringKey.History.DynastyCard {
    static var unavailable: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyCard.unavailable",
            defaultValue: "资料暂缺",
            comment: "朝代卡片缺少相关统计或边界资料时的占位说明。"
        )
    }

    static func statistics(emperorCount: Int, eraCount: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyCard.statistics",
            defaultValue: "\(emperorCount) 位皇帝 · \(eraCount) 个年号",
            comment: "朝代卡片统计；参数依次为皇帝人数和年号数量。"
        )
    }
}
