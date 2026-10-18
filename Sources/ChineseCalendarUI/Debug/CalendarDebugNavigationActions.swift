#if DEBUG
    import ChineseCalendarCore
    import ChineseCalendarLocalization
    import SwiftUI

    /// 菜单和测试页共用动作；局部导航使用当前栈，全局跳转用于调试根协调流程。
    struct CalendarDebugNavigationActions: View {
        @Environment(CalendarNavigationContext.self) private var navigation
        @Environment(CalendarPresentationContext.self) private var presentation
        /// 仅为调试跨 Tab 跳转和模拟外部 Deep Link，才在这里读取 App 级 coordinator。
        /// 普通业务页分别通过 navigation 操作栈、通过 presentation 操作模态。
        @Environment(CalendarHomeCoordinator.self) private var coordinator

        var body: some View {
            Section(CalendarStringKey.Debug.Navigation.localActions) {
                Button(CalendarStringKey.Debug.Navigation.push) {
                    navigation.push(.debugNavigation(id: UUID()))
                }
                Button(CalendarStringKey.Debug.Navigation.sheet) {
                    presentation.present(.debugNavigation(id: UUID()))
                }
                Button(CalendarStringKey.Debug.Navigation.fullScreen) {
                    presentation.present(.debugNavigation(id: UUID()), style: .fullScreen)
                }
                Button(CalendarStringKey.Debug.Alert.show) {
                    presentation.present(.alert(.debugNotice(1)))
                }
                Button(CalendarStringKey.Debug.Alert.queue) {
                    presentation.present(.alert(.debugNotice(1)))
                    presentation.present(.alert(.debugNotice(2)))
                }
                Button(CalendarStringKey.Debug.Alert.navigationChoice) {
                    presentation.present(.alert(.debugNavigationChoice))
                }
            }

            Section(CalendarStringKey.Debug.Navigation.returnActions) {
                Button(CalendarStringKey.Debug.Navigation.pop) {
                    navigation.pop()
                }
                .disabled(navigation.path.isEmpty)

                Button(CalendarStringKey.Debug.Navigation.dismiss) {
                    presentation.dismiss()
                }
                .disabled(!presentation.isPresented)
            }

            Section(CalendarStringKey.Debug.Navigation.externalActions) {
                Button(CalendarStringKey.Debug.Alert.navigateWhilePresented) {
                    presentation.present(.alert(.debugNotice(1)))
                    coordinator.router.navigation.submit(
                        .push(.debugNavigation(id: UUID()), on: .history), confirmIfPresented: true
                    )
                }
                Button(CalendarStringKey.Debug.Navigation.pushOnHistory) {
                    coordinator.router.navigation.submit(
                        .push(.debugNavigation(id: UUID()), on: .history),
                        confirmIfPresented: true
                    )
                }
                Button(CalendarStringKey.Debug.Navigation.deepLink) {
                    coordinator.openDeepLink(.lunarYear(ChineseLunarCalendar.yearNumber()))
                }
            }
        }
    }
#endif
