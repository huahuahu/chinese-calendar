import Foundation

/// 干支纪年采用的年界规则。
public enum 年界规则: String, Codable, CaseIterable, Sendable {
    /// 以正月初一作为新年的开始。
    case 正月初一
}

/// 十天干。
public enum 天干: Int, Codable, CaseIterable, Sendable {
    case 甲 = 0
    case 乙
    case 丙
    case 丁
    case 戊
    case 己
    case 庚
    case 辛
    case 壬
    case 癸

    public var 中文名: String {
        switch self {
        case .甲:
            "甲"
        case .乙:
            "乙"
        case .丙:
            "丙"
        case .丁:
            "丁"
        case .戊:
            "戊"
        case .己:
            "己"
        case .庚:
            "庚"
        case .辛:
            "辛"
        case .壬:
            "壬"
        case .癸:
            "癸"
        }
    }
}

/// 十二地支。
public enum 地支: Int, Codable, CaseIterable, Sendable {
    case 子 = 0
    case 丑
    case 寅
    case 卯
    case 辰
    case 巳
    case 午
    case 未
    case 申
    case 酉
    case 戌
    case 亥

    public var 中文名: String {
        switch self {
        case .子:
            "子"
        case .丑:
            "丑"
        case .寅:
            "寅"
        case .卯:
            "卯"
        case .辰:
            "辰"
        case .巳:
            "巳"
        case .午:
            "午"
        case .未:
            "未"
        case .申:
            "申"
        case .酉:
            "酉"
        case .戌:
            "戌"
        case .亥:
            "亥"
        }
    }
}

/// 六十甲子中的某一年，需要同时记录循环次数和序号。
public struct 干支年: Codable, Hashable, Sendable {
    /// 一个干支循环包含 60 年。
    public static let 循环长度 = 60

    /// 第几个六十年循环。
    public let 周期: Int

    /// 在当前六十年循环中的序号，0 表示甲子，59 表示癸亥。
    public let 序号: Int

    public init(周期: Int, 序号: Int) {
        precondition((0 ..< Self.循环长度).contains(序号), "干支序号必须在 0 到 59 之间")
        self.周期 = 周期
        self.序号 = 序号
    }

    public init?(周期: Int, 名称: String) {
        guard let 序号 = Self.全部名称.firstIndex(of: 名称) else {
            return nil
        }

        self.init(周期: 周期, 序号: 序号)
    }

    /// 当前年份对应的天干。
    public var 天干值: 天干 {
        天干.allCases[序号 % 天干.allCases.count]
    }

    /// 当前年份对应的地支。
    public var 地支值: 地支 {
        地支.allCases[序号 % 地支.allCases.count]
    }

    /// 组合后的干支名称，例如“甲子”。
    public var 名称: String {
        天干值.中文名 + 地支值.中文名
    }

    /// 六十甲子的完整名称表，序号与 `0...59` 一一对应。
    public static let 全部名称: [String] = (0 ..< 循环长度).map { 序号 in
        天干.allCases[序号 % 天干.allCases.count].中文名
            + 地支.allCases[序号 % 地支.allCases.count].中文名
    }
}

/// 农历月序，不包含闰月信息。
public enum 农历月序: Int, Codable, CaseIterable, Sendable {
    case 正月 = 1
    case 二月
    case 三月
    case 四月
    case 五月
    case 六月
    case 七月
    case 八月
    case 九月
    case 十月
    case 十一月
    case 十二月

    public var 中文名: String {
        let names = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
        return names[rawValue - 1]
    }
}

/// 农历中的某个月，闰月与普通月共享同一月序。
public struct 农历月: Codable, Hashable, Sendable {
    /// 基础月序，例如正月、二月、三月。
    public let 月序: 农历月序

    /// 是否为闰月。
    public let 是闰月: Bool

    public init(月序: 农历月序, 是闰月: Bool = false) {
        self.月序 = 月序
        self.是闰月 = 是闰月
    }

    public var 中文名: String {
        let prefix = 是闰月 ? "闰" : ""
        return prefix + 月序.中文名
    }
}

/// 农历日期，使用枚举避免出现非法日值。
public enum 农历日: Int, Codable, CaseIterable, Sendable {
    case 初一 = 1
    case 初二
    case 初三
    case 初四
    case 初五
    case 初六
    case 初七
    case 初八
    case 初九
    case 初十
    case 十一
    case 十二
    case 十三
    case 十四
    case 十五
    case 十六
    case 十七
    case 十八
    case 十九
    case 二十
    case 廿一
    case 廿二
    case 廿三
    case 廿四
    case 廿五
    case 廿六
    case 廿七
    case 廿八
    case 廿九
    case 三十

    public var 中文名: String {
        let names = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ]
        return names[rawValue - 1]
    }
}

/// 以干支年表示的某一个农历日期。
public struct 干支历日期: Codable, Hashable, Sendable {
    /// 当前日期采用的年界规则。
    public let 年界规则: 年界规则

    /// 当前日期所属的干支年。
    public let 年: 干支年

    /// 当前日期所属的农历月份。
    public let 月: 农历月

    /// 当前日期所属的农历日。
    public let 日: 农历日

    /// 可选的年号标签，例如“漢武帝太初元年”。
    public let 年号: String?

    /// 可选的儒略日数，用作绝对时间锚点。
    public let 儒略日数: Int?

    public init(
        年: 干支年,
        月: 农历月,
        日: 农历日,
        年界规则: 年界规则 = .正月初一,
        年号: String? = nil,
        儒略日数: Int? = nil
    ) {
        self.年界规则 = 年界规则
        self.年 = 年
        self.月 = 月
        self.日 = 日
        self.年号 = 年号
        self.儒略日数 = 儒略日数
    }
}
