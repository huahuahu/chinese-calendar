import ChineseCalendarLocalization
import Foundation
import NavigationCore

#if DEBUG
    enum CalendarDebugAlerts {
        static func notice(number: Int) -> NavigationAlertDefinition {
            CalendarNoticeAlert.definition(content: noticeContent(number: number))
        }

        static func noticeContent(number: Int) -> NavigationAlertContent<CalendarNoticeAction> {
            CalendarNoticeAlert.content(
                title: CalendarStringKey.Debug.Alert.noticeTitle(number: number),
                message: CalendarStringKey.Debug.Alert.noticeMessage
            )
        }

        static func navigationChoice(router: CalendarRouter) -> NavigationAlertDefinition {
            NavigationAlertDefinition(content: navigationChoiceContent) { action in
                handleNavigationAction(action, router: router)
            }
        }

        static var navigationChoiceContent: NavigationAlertContent<CalendarDebugNavigationAction> {
            NavigationAlertContent(
                title: CalendarStringKey.Debug.Alert.navigationTitle,
                message: CalendarStringKey.Debug.Alert.navigationMessage,
                firstButton: NavigationAlertButton(
                    CalendarStringKey.Debug.Navigation.pushOnHistory, action: .openHistory
                ),
                cancelButton: NavigationAlertCancelButton(CalendarStringKey.Common.Action.cancel, action: .cancel)
            )
        }

        static func handleNavigationAction(_ action: CalendarDebugNavigationAction, router: CalendarRouter) {
            switch action {
            case .cancel:
                break
            case .openHistory:
                router.navigation.submit(.push(.debugNavigation(id: UUID()), on: .history))
            }
        }
    }
#endif
