import { stems, years } from './mockData'

interface YearPickerScreenProps {
  selectedYear: number
  onSelect: (year: number) => void
  onDismiss: () => void
}

export function YearPickerScreen({ selectedYear, onSelect, onDismiss }: YearPickerScreenProps) {
  return (
    <div className="screen year-picker-screen">
      <div className="year-picker-sheet">
        <header className="year-picker-navigation">
          <button onClick={onDismiss} data-transition-id="close-year-picker">关闭</button>
          <strong>年份选择器</strong>
        </header>
        <main className="year-list">
        {years.map((year, index) => (
          <button
            key={year}
            onClick={() => onSelect(year)}
            aria-pressed={year === selectedYear}
            data-transition-id={year === selectedYear ? 'select-year' : undefined}
          >
            <span><strong>公元 {year} 年</strong><small>{stems[index]}年</small></span>
            {year === selectedYear && <b aria-label="已选择">✓</b>}
          </button>
        ))}
        </main>
        <nav className="year-index" aria-label="世纪索引">
          <span>前3</span><span>前2</span><span>前1</span>
          {Array.from({ length: 22 }, (_, index) => <span key={index + 1}>{index + 1}</span>)}
        </nav>
      </div>
    </div>
  )
}
