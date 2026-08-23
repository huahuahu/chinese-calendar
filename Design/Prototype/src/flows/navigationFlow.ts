export type ScreenId = 'calendar-home' | 'year-picker'
export type CalendarState = 'normal' | 'selected' | 'today' | 'todaySelected'
export type PresentationStyle = 'state' | 'sheet' | 'dismiss' | 'fullScreenCover' | 'tab'

export interface PrototypeTransition {
  id: string
  source: ScreenId
  target: ScreenId | CalendarState
  targetType: 'screen' | 'state'
  trigger: string
  presentation: PresentationStyle
}

export const screenNames: Record<ScreenId, string> = {
  'calendar-home': '日历',
  'year-picker': '年份选择器',
}

export const navigationFlow: PrototypeTransition[] = [
  {
    id: 'select-date',
    source: 'calendar-home',
    target: 'selected',
    targetType: 'state',
    trigger: '点击日期',
    presentation: 'state',
  },
  {
    id: 'select-today',
    source: 'calendar-home',
    target: 'todaySelected',
    targetType: 'state',
    trigger: '点击今天',
    presentation: 'state',
  },
  {
    id: 'open-year-picker',
    source: 'calendar-home',
    target: 'year-picker',
    targetType: 'screen',
    trigger: '点击年份标题',
    presentation: 'sheet',
  },
  {
    id: 'close-year-picker',
    source: 'year-picker',
    target: 'calendar-home',
    targetType: 'screen',
    trigger: '点击关闭',
    presentation: 'dismiss',
  },
  {
    id: 'select-year',
    source: 'year-picker',
    target: 'calendar-home',
    targetType: 'screen',
    trigger: '选择年份',
    presentation: 'dismiss',
  },
]
