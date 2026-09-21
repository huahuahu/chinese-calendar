export type ScreenId =
  | 'history-home'
  | 'dynasty-detail'
  | 'emperor-list'
  | 'reign-era-list'
  | 'dynasty-span-detail'
  | 'reign-era-detail'
export type CalendarState = 'normal' | 'selected' | 'today' | 'todaySelected'
export type PresentationStyle = 'push' | 'pop' | 'tab'

export interface PrototypeTransition {
  id: string
  source: ScreenId
  target: ScreenId
  targetType: 'screen'
  trigger: string
  presentation: PresentationStyle
}

export const screenNames: Record<ScreenId, string> = {
  'history-home': '朝代目录',
  'dynasty-detail': '朝代详情',
  'emperor-list': '帝王列表',
  'reign-era-list': '年号列表',
  'dynasty-span-detail': '朝代起讫与大事',
  'reign-era-detail': '年号详情',
}

export const navigationFlow: PrototypeTransition[] = [
  {
    id: 'open-dynasty',
    source: 'history-home',
    target: 'dynasty-detail',
    targetType: 'screen',
    trigger: '点击“明”',
    presentation: 'push',
  },
  {
    id: 'back-history',
    source: 'dynasty-detail',
    target: 'history-home',
    targetType: 'screen',
    trigger: '点击“朝代”',
    presentation: 'pop',
  },
  {
    id: 'open-emperors',
    source: 'dynasty-detail',
    target: 'emperor-list',
    targetType: 'screen',
    trigger: '点击“16 位皇帝”',
    presentation: 'push',
  },
  {
    id: 'back-emperors',
    source: 'emperor-list',
    target: 'dynasty-detail',
    targetType: 'screen',
    trigger: '点击“明”',
    presentation: 'pop',
  },
  {
    id: 'open-eras',
    source: 'dynasty-detail',
    target: 'reign-era-list',
    targetType: 'screen',
    trigger: '点击“17 个年号”',
    presentation: 'push',
  },
  {
    id: 'back-eras',
    source: 'reign-era-list',
    target: 'dynasty-detail',
    targetType: 'screen',
    trigger: '点击“明”',
    presentation: 'pop',
  },
  {
    id: 'open-span',
    source: 'dynasty-detail',
    target: 'dynasty-span-detail',
    targetType: 'screen',
    trigger: '点击“276 年”',
    presentation: 'push',
  },
  {
    id: 'back-span',
    source: 'dynasty-span-detail',
    target: 'dynasty-detail',
    targetType: 'screen',
    trigger: '点击“明”',
    presentation: 'pop',
  },
  {
    id: 'open-era',
    source: 'reign-era-list',
    target: 'reign-era-detail',
    targetType: 'screen',
    trigger: '点击“永乐”',
    presentation: 'push',
  },
  {
    id: 'back-era-list',
    source: 'reign-era-detail',
    target: 'reign-era-list',
    targetType: 'screen',
    trigger: '点击“年号”',
    presentation: 'pop',
  },
]
