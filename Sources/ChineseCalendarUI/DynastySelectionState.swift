import Observation

@MainActor
@Observable
public final class DynastySelectionState {
    public var selectedDynastyID: String?
    public var selectedOrthodoxTraditionID: String?
    public var selectedOrthodoxPeriodID: String?

    public init(
        selectedDynastyID: String? = nil,
        selectedOrthodoxTraditionID: String? = nil,
        selectedOrthodoxPeriodID: String? = nil
    ) {
        self.selectedDynastyID = selectedDynastyID
        self.selectedOrthodoxTraditionID = selectedOrthodoxTraditionID
        self.selectedOrthodoxPeriodID = selectedOrthodoxPeriodID
    }

    public func selectDynasty(id: String?) {
        selectedDynastyID = id
    }

    public func selectOrthodoxTradition(id: String?) {
        selectedOrthodoxTraditionID = id
    }

    public func selectOrthodoxPeriod(id: String?) {
        selectedOrthodoxPeriodID = id
    }

    public func clearSelection() {
        selectedDynastyID = nil
        selectedOrthodoxTraditionID = nil
        selectedOrthodoxPeriodID = nil
    }
}
