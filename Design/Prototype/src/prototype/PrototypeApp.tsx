import { useEffect, useRef, useState } from 'react'
import { SegmentedControl } from '../design-system/components/SegmentedControl'
import { screenNames, type CalendarState, type ScreenId } from '../flows/navigationFlow'
import { CalendarHomeScreen } from '../screens/CalendarHomeScreen'
import { YearPickerScreen } from '../screens/YearPickerScreen'
import { FlowConnections } from './FlowConnections'
import { IPhoneCanvas } from './IPhoneCanvas'

type Theme = 'light' | 'dark'
type CanvasSize = 'compact' | 'regular'

export function PrototypeApp() {
  const [theme, setTheme] = useState<Theme>('light')
  const [size, setSize] = useState<CanvasSize>('regular')
  const [activeScreen, setActiveScreen] = useState<ScreenId>('calendar-home')
  const [calendarState, setCalendarState] = useState<CalendarState>('normal')
  const [year, setYear] = useState(2035)
  const boardRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    document.documentElement.dataset.size = size
  }, [theme, size])

  const selectYear = (nextYear: number) => {
    setYear(nextYear)
    setActiveScreen('calendar-home')
  }

  const activate = (screen: ScreenId) => setActiveScreen(screen)

  return (
    <div className="prototype-shell">
      <header className="workspace-header">
        <div><p>中华历 · Design Prototype</p><h1>iOS 页面与流程</h1></div>
        <div className="workspace-controls">
          <SegmentedControl label="主题" value={theme} onChange={setTheme} options={[
            { label: '浅色', value: 'light' }, { label: '深色', value: 'dark' },
          ]} />
          <SegmentedControl label="画板尺寸" value={size} onChange={setSize} options={[
            { label: '紧凑', value: 'compact' }, { label: '常规', value: 'regular' },
          ]} />
        </div>
      </header>

      <main className="prototype-board">
        <div className="prototype-board__heading">
          <div><span>页面流程</span><h2>按钮直接连接到目标页面或状态</h2></div>
          <div className="connection-legend"><span><i />同页状态</span><span><i className="sheet" />sheet / dismiss</span></div>
        </div>
        <div className="flow-board" ref={boardRef}>
          <FlowConnections boardRef={boardRef} layoutKey={`${theme}-${size}-${year}-${calendarState}`} />

          <section className="screen-artboard screen-artboard--home">
            <header><span>01</span><h2>{screenNames['calendar-home']}</h2><small>1 screen · 4 states</small></header>
            <div className="screen-state-switcher">
              <span>Screen State</span>
              <SegmentedControl label="日历页面状态" value={calendarState} onChange={setCalendarState} options={[
                { label: '普通', value: 'normal' },
                { label: '选中', value: 'selected' },
                { label: '今天', value: 'today' },
                { label: '今天已选', value: 'todaySelected' },
              ]} />
            </div>
            <IPhoneCanvas screenId="calendar-home" isActive={activeScreen === 'calendar-home'}>
              <CalendarHomeScreen
                year={year}
                state={calendarState}
                onSelectDate={() => {
                  setCalendarState('selected')
                  activate('calendar-home')
                }}
                onSelectToday={() => {
                  setCalendarState('todaySelected')
                  activate('calendar-home')
                }}
                onOpenYearPicker={() => activate('year-picker')}
              />
            </IPhoneCanvas>
            <div className="state-strip" aria-label="日期单元格状态对照">
              <div className="state-strip__heading"><strong>日期单元格状态</strong><span>局部组件对照</span></div>
              <div className="state-strip__items">
                {([
                  ['normal', '普通'],
                  ['selected', '选中'],
                  ['today', '今天'],
                  ['todaySelected', '今天已选'],
                ] as const).map(([state, label]) => (
                  <button
                    type="button"
                    key={state}
                    className={`state-sample state-sample--${state} ${calendarState === state ? 'is-active' : ''}`}
                    data-state-id={state}
                    aria-pressed={calendarState === state}
                    onClick={() => setCalendarState(state)}
                  >
                    <span>{label}</span>
                    <strong>初一</strong>
                    <small>乙丑日</small>
                  </button>
                ))}
              </div>
            </div>
          </section>

          <section className="screen-artboard screen-artboard--picker">
            <header><span>02</span><h2>{screenNames['year-picker']}</h2><small>sheet</small></header>
            <IPhoneCanvas screenId="year-picker" isActive={activeScreen === 'year-picker'}>
              <YearPickerScreen
                selectedYear={year}
                onSelect={selectYear}
                onDismiss={() => activate('calendar-home')}
              />
            </IPhoneCanvas>
          </section>
        </div>
      </main>
    </div>
  )
}
