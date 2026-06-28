import Foundation
import SwiftData

@Model
public final class Emperor {
    #Unique<Emperor>([\.id])
    #Index<Emperor>([\.id], [\.sequenceIndex])

    /// 皇帝或国主的稳定导入标识。
    public var id: String
    /// 界面主要显示名，保留来源中的完整君主称呼。
    public var displayName: String
    /// 可解析出的本名；来源无法可靠区分时为空。
    public var personalName: String?
    /// 可解析出的庙号；来源未提供或无法可靠区分时为空。
    public var templeName: String?
    /// 可解析出的谥号、王号或其他括注称号。
    public var posthumousName: String?
    /// 同一朝代或政权下的默认展示顺序。
    public var sequenceIndex: Int

    /// 皇帝所属的朝代或政权。
    public var dynasty: Dynasty

    @Relationship(deleteRule: .cascade, inverse: \EmperorReignSegment.emperor)
    /// 该皇帝的一个或多个在位区间。
    public var reignSegments: [EmperorReignSegment]

    @Relationship(deleteRule: .cascade, inverse: \ReignEra.emperor)
    /// 归属于该皇帝名下的年号记录。
    public var reignEras: [ReignEra]

    /// 导入来源、称号解析或史料差异的补充说明。
    public var note: String?

    public init(
        id: String,
        dynasty: Dynasty,
        displayName: String,
        personalName: String? = nil,
        templeName: String? = nil,
        posthumousName: String? = nil,
        sequenceIndex: Int,
        reignSegments: [EmperorReignSegment] = [],
        reignEras: [ReignEra] = [],
        note: String? = nil
    ) {
        self.id = id
        self.dynasty = dynasty
        self.displayName = displayName
        self.personalName = personalName
        self.templeName = templeName
        self.posthumousName = posthumousName
        self.sequenceIndex = sequenceIndex
        self.reignSegments = reignSegments
        self.reignEras = reignEras
        self.note = note
    }
}

@Model
public final class EmperorReignSegment {
    #Unique<EmperorReignSegment>([\.id])
    #Index<EmperorReignSegment>([\.id], [\.sequenceIndex], [\.segmentIndex])

    /// 在位区间的稳定导入标识。
    public var id: String
    /// 同一朝代或政权政治时间线中的在位顺序。
    public var sequenceIndex: Int
    /// 同一皇帝自己的第几次在位，从 0 开始。
    public var segmentIndex: Int
    /// 在位区间显示名，例如初立、复辟；没有来源说明时为空。
    public var segmentName: String?

    /// 该在位区间所属的皇帝。
    public var emperor: Emperor

    @Relationship(deleteRule: .cascade)
    /// 在位区间开始日期。
    public var startDate: ChineseDateExpression

    @Relationship(deleteRule: .cascade)
    /// 在位区间结束日期，按 [startDate, endDate) 半开区间理解。
    public var endDate: ChineseDateExpression

    /// 该在位区间的来源备注或解析说明。
    public var note: String?

    public init(
        id: String,
        emperor: Emperor,
        sequenceIndex: Int,
        segmentIndex: Int,
        segmentName: String? = nil,
        startDate: ChineseDateExpression,
        endDate: ChineseDateExpression,
        note: String? = nil
    ) {
        self.id = id
        self.emperor = emperor
        self.sequenceIndex = sequenceIndex
        self.segmentIndex = segmentIndex
        self.segmentName = segmentName
        self.startDate = startDate
        self.endDate = endDate
        self.note = note
    }
}

@Model
public final class ReignEra {
    #Unique<ReignEra>([\.id])
    #Index<ReignEra>([\.id], [\.normalizedName], [\.sequenceIndex], [\.eraIndexWithinEmperor])

    /// 年号使用区间的稳定导入标识。
    public var id: String
    /// 来源中的年号显示名。
    public var name: String
    /// 用于检索和去重的归一化年号名。
    public var normalizedName: String
    /// 同一朝代或政权政治时间线中的年号顺序。
    public var sequenceIndex: Int
    /// 该皇帝名下的年号顺序，从 0 开始。
    public var eraIndexWithinEmperor: Int

    /// 该年号记录归属的皇帝。
    public var emperor: Emperor

    @Relationship(deleteRule: .cascade)
    /// 年号开始日期。
    public var startDate: ChineseDateExpression

    @Relationship(deleteRule: .cascade)
    /// 年号结束日期，按 [startDate, endDate) 半开区间理解。
    public var endDate: ChineseDateExpression

    /// 改元边界、沿用前任年号或来源备注等补充说明。
    public var note: String?

    public init(
        id: String,
        emperor: Emperor,
        name: String,
        normalizedName: String,
        sequenceIndex: Int,
        eraIndexWithinEmperor: Int,
        startDate: ChineseDateExpression,
        endDate: ChineseDateExpression,
        note: String? = nil
    ) {
        self.id = id
        self.emperor = emperor
        self.name = name
        self.normalizedName = normalizedName
        self.sequenceIndex = sequenceIndex
        self.eraIndexWithinEmperor = eraIndexWithinEmperor
        self.startDate = startDate
        self.endDate = endDate
        self.note = note
    }
}
