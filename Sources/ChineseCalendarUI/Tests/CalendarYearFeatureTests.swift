import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite("年份 Binding 由发起页持有")
struct CalendarYearFeatureTests {
    @Test func independentBindingsReturnOnlyToTheirOriginatingPage() throws {
        let firstContainer = try PreviewSampleData.makeModelContainer()
        let secondContainer = try PreviewSampleData.makeModelContainer()
        let first = makeFeature(firstContainer.mainContext, day: 315)
        let second = makeFeature(secondContainer.mainContext, day: 115)
        let firstRoute = try #require(first.beginYearPicker())
        let secondRoute = try #require(second.beginYearPicker())
        guard case let .yearPicker(_, binding, context) = firstRoute,
              case let .yearPicker(_, otherBinding, otherContext) = secondRoute
        else {
            Issue.record("应创建带参数的年份路由")
            return
        }
        #expect(context === firstContainer.mainContext)
        #expect(otherContext === secondContainer.mainContext)
        let previousOtherYear = otherBinding.wrappedValue
        binding.wrappedValue = 2025
        first.completeYearTransitionPreparation(3)
        #expect(first.selection.selectedDayIndex == 201)
        #expect(second.selection.selectedDayIndex == 115)
        #expect(otherBinding.wrappedValue == previousOtherYear)
        #expect(second.pendingYearTransition == nil)
    }

    @Test func bindingConsumesOnlyOneResultAndPreservesBoundaryTransition() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(container.mainContext, day: 315)
        guard case let .yearPicker(_, binding, _) = try #require(feature.beginYearPicker()) else { return }
        binding.wrappedValue = 2025
        binding.wrappedValue = 2027
        #expect(feature.pendingYearTransition?.sourceMonthIndex == 3)
        #expect(feature.pendingYearTransition?.destinationMonthIndex == 2)
        #expect(feature.pendingYearTransition?.destinationYearNumber == 2025)
        #expect(feature.selection.selectedDayIndex == 315)
        feature.completeYearTransitionPreparation(5)
        #expect(feature.selection.selectedDayIndex == 315)
        feature.completeYearTransitionPreparation(3)
        #expect(feature.selection.selectedDayIndex == 201)
    }

    @Test func oldBindingAndOldDismissalCannotChangeReplacement() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(container.mainContext, day: 315)
        guard case let .yearPicker(id, binding, _) = try #require(feature.beginYearPicker()) else { return }
        #expect(feature.beginYearPicker() == nil)
        feature.finishYearPicker(id: id)
        let replacement = try #require(feature.beginYearPicker())
        let replacementID = feature.yearPickerID
        binding.wrappedValue = 2025
        feature.finishYearPicker(id: id)
        #expect(feature.yearPickerID == replacementID)
        #expect(replacementID != id)
        #expect(feature.pendingYearTransition == nil)
        #expect(feature.selection.selectedDayIndex == 315)
        withExtendedLifetime(replacement) {}
    }

    @Test func replacingStoreInvalidatesOldBindingImmediately() throws {
        let first = try PreviewSampleData.makeModelContainer()
        let second = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(first.mainContext, day: 315)
        guard case let .yearPicker(_, binding, _) = try #require(feature.beginYearPicker()) else { return }
        binding.wrappedValue = 2025
        feature.connect(modelContext: second.mainContext, storeCoordinator: nil)
        binding.wrappedValue = 2027
        feature.completeYearTransitionPreparation(3)
        #expect(feature.yearPickerID == nil)
        #expect(feature.pendingYearTransition == nil)
        #expect(feature.selection.value == nil)
        guard case let .yearPicker(_, _, context) = try #require(feature.beginYearPicker()) else { return }
        #expect(context === second.mainContext)
    }

    private func makeFeature(_ context: ModelContext, day: Int) -> CalendarYearFeature {
        let feature = CalendarYearFeature(selection: CalendarSelection(selectedDayIndex: day))
        feature.connect(modelContext: context, storeCoordinator: nil)
        return feature
    }
}
