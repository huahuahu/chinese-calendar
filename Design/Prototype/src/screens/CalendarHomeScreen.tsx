import { useEffect, useRef } from 'react'
import { lunarDays, stemBranchForYear } from './mockData'
import type { CalendarState } from '../flows/navigationFlow'

interface CalendarHomeScreenProps {
  year: number
  state: CalendarState
  onSelectDate: () => void
  onSelectToday: () => void
  onOpenYearPicker: () => void
}

export function CalendarHomeScreen({
  year,
  state,
  onSelectDate,
  onSelectToday,
  onOpenYearPicker,
}: CalendarHomeScreenProps) {
  const hasSelection = state === 'selected' || state === 'todaySelected'
  const contentRef = useRef<HTMLElement>(null)

  useEffect(() => {
    const content = contentRef.current
    if (!content) return

    const animationFrame = requestAnimationFrame(() => {
      content.scrollTop = hasSelection ? content.scrollHeight : 0
    })
    return () => cancelAnimationFrame(animationFrame)
  }, [hasSelection])

  return (
    <div className={`screen calendar-screen calendar-screen--${hasSelection ? 'selection' : 'month'}`}>
      <header className="calendar-navigation">
        <strong>日历</strong>
        <button type="button" onClick={onSelectToday} data-transition-id="select-today">今天</button>
      </header>

      <main className="calendar-content" ref={contentRef}>
        {!hasSelection && (
          <section className="calendar-card month-browser">
            <button className="round-arrow" aria-label="上个月">‹</button>
            <button
              className="month-browser__title"
              onClick={onOpenYearPicker}
              data-transition-id="open-year-picker"
            >
              <strong>{stemBranchForYear(year)}年 十月大</strong>
              <span>公历 {year}年10月31日 - 公历 {year}年11月29日</span>
            </button>
            <button className="round-arrow" aria-label="下个月">›</button>
            <div className="month-pills">
              <button>九月大</button>
              <button className="is-selected">十月大</button>
              <button>十一月小</button>
            </div>
          </section>
        )}

        <section className="calendar-card month-grid-card">
          {!hasSelection && (
            <div className="month-grid-heading">
              <h2>农历月格</h2>
              <span>连续日序</span>
            </div>
          )}
          <div className="month-day-grid">
            {lunarDays.map(([day, stem, civil], index) => {
              const isFocusCell = index === 0
              const stateClass = isFocusCell ? `is-${state}` : ''
              return (
                <button
                  key={day}
                  className={stateClass}
                  onClick={onSelectDate}
                  data-transition-id={isFocusCell ? 'select-date' : undefined}
                >
                  <strong>{day}</strong>
                  <span>{stem}日</span>
                  <span>{civil}</span>
                </button>
              )
            })}
          </div>
        </section>

        {hasSelection && (
          <section className="calendar-card selected-day-card">
            <div className="selected-day-card__hero">
              <div><span>选中日</span><h2>初一</h2><p>乙丑日 · 公历 {year}年10月31日</p></div>
              <b>一</b>
            </div>
            <div className="selected-day-facts">
              <div><span>农历表达</span><strong>十月大初一</strong></div>
              <div><span>日干支</span><strong>乙丑</strong></div>
              <div><span>公历表达</span><strong>{year}.10.31</strong></div>
              <div><span>数据层级</span><strong>完整日期数据</strong></div>
            </div>
          </section>
        )}
      </main>

      <nav className="floating-tab-bar" aria-label="主要标签页">
        <button className="is-selected"><span>▦</span>日历</button>
        <button><span>◧</span>历史</button>
        <button><span>●</span>设置</button>
      </nav>
    </div>
  )
}
