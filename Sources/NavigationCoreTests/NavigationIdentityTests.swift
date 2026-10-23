import Foundation
@testable import NavigationCore
import Testing

@Suite("导航身份的值语义与来源隔离")
struct NavigationIdentityTests {
    @Test nonisolated func presentationIdentityHasStableEqualityAndHashing() {
        let rawValue = UUID()
        let first = NavigationPresentationID(rawValue: rawValue)
        let sameValue = NavigationPresentationID(rawValue: rawValue)
        let other = NavigationPresentationID()

        #expect(first == sameValue)
        #expect(first != other)
        #expect(Set([first, sameValue, other]).count == 2)
        #expect([first: "presentation"][sameValue] == "presentation")
    }

    @Test nonisolated func confirmationIdentityHasStableEqualityAndHashing() {
        let rawValue = UUID()
        let first = NavigationConfirmationID(rawValue: rawValue)
        let sameValue = NavigationConfirmationID(rawValue: rawValue)
        let other = NavigationConfirmationID()

        #expect(first == sameValue)
        #expect(first != other)
        #expect(Set([first, sameValue, other]).count == 2)
        #expect([first: "confirmation"][sameValue] == "confirmation")
    }

    @Test nonisolated func alertIdentityHasStableEqualityAndHashing() {
        let rawValue = UUID()
        let first = NavigationAlertID(rawValue: rawValue)
        let sameValue = NavigationAlertID(rawValue: rawValue)
        let other = NavigationAlertID()

        #expect(first == sameValue)
        #expect(first != other)
        #expect(Set([first, sameValue, other]).count == 2)
        #expect([first: "alert"][sameValue] == "alert")
    }

    @Test nonisolated func systemAlertIdentityIncludesSourceWhenRawValuesMatch() {
        let rawValue = UUID()
        let business = NavigationSystemAlertID.business(NavigationAlertID(rawValue: rawValue))
        let sameBusiness = NavigationSystemAlertID.business(NavigationAlertID(rawValue: rawValue))
        let confirmation = NavigationSystemAlertID.confirmation(NavigationConfirmationID(rawValue: rawValue))
        let sameConfirmation = NavigationSystemAlertID.confirmation(NavigationConfirmationID(rawValue: rawValue))

        #expect(business == sameBusiness)
        #expect(confirmation == sameConfirmation)
        #expect(business != confirmation)
        #expect(Set([business, sameBusiness, confirmation, sameConfirmation]).count == 2)
        #expect([business: "business", confirmation: "confirmation"][sameBusiness] == "business")
    }
}
