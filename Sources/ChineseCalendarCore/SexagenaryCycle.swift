import Foundation

/// 十天干。
public enum HeavenlyStem: Int, Codable, CaseIterable, Hashable, Sendable {
    case jia = 0
    case yi
    case bing
    case ding
    case wu
    case ji
    case geng
    case xin
    case ren
    case gui

    public init(cyclicIndex: Int) {
        self = Self.allCases[positiveModulo(cyclicIndex, by: Self.allCases.count)]
    }

    public var chineseName: String {
        switch self {
        case .jia:
            "甲"
        case .yi:
            "乙"
        case .bing:
            "丙"
        case .ding:
            "丁"
        case .wu:
            "戊"
        case .ji:
            "己"
        case .geng:
            "庚"
        case .xin:
            "辛"
        case .ren:
            "壬"
        case .gui:
            "癸"
        }
    }
}

/// 十二地支。
public enum EarthlyBranch: Int, Codable, CaseIterable, Hashable, Sendable {
    case zi = 0
    case chou
    case yin
    case mao
    case chen
    case si
    case wu
    case wei
    case shen
    case you
    case xu
    case hai

    public init(cyclicIndex: Int) {
        self = Self.allCases[positiveModulo(cyclicIndex, by: Self.allCases.count)]
    }

    public var chineseName: String {
        switch self {
        case .zi:
            "子"
        case .chou:
            "丑"
        case .yin:
            "寅"
        case .mao:
            "卯"
        case .chen:
            "辰"
        case .si:
            "巳"
        case .wu:
            "午"
        case .wei:
            "未"
        case .shen:
            "申"
        case .you:
            "酉"
        case .xu:
            "戌"
        case .hai:
            "亥"
        }
    }
}

/// 一个天干和一个地支组成的干支名称。
public struct SexagenaryName: Codable, Equatable, Hashable, Sendable {
    public let heavenlyStem: HeavenlyStem
    public let earthlyBranch: EarthlyBranch

    public var chineseName: String {
        heavenlyStem.chineseName + earthlyBranch.chineseName
    }

    public init(heavenlyStem: HeavenlyStem, earthlyBranch: EarthlyBranch) {
        self.heavenlyStem = heavenlyStem
        self.earthlyBranch = earthlyBranch
    }

    public init(stemIndex: Int, branchIndex: Int) {
        self.init(
            heavenlyStem: HeavenlyStem(cyclicIndex: stemIndex),
            earthlyBranch: EarthlyBranch(cyclicIndex: branchIndex)
        )
    }
}

private func positiveModulo(_ value: Int, by divisor: Int) -> Int {
    let remainder = value % divisor
    return remainder >= 0 ? remainder : remainder + divisor
}
