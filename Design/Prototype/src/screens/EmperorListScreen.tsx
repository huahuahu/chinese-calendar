import { EmperorCard } from '../components/history/EmperorCard'
import { mingEmperors } from './historyData'
import { HistoryTabBar } from './HistoryTabBar'

export function EmperorListScreen({ onBack }: { onBack: () => void }) {
  return (
    <div className="screen history-screen emperor-list-screen">
      <nav className="inline-navigation">
        <button type="button" data-transition-id="back-emperors" onClick={onBack}>
          <span aria-hidden="true">‹</span> 明
        </button>
        <h1 className="inline-navigation__title">帝王</h1>
      </nav>

      <div className="history-scroll history-scroll--under-nav">
        <p className="list-summary">16 位皇帝 · 17 段纪年</p>

        <section aria-label="明朝帝王列表">
          <div className="emperor-list">
            {mingEmperors.map((emperor, index) => (
              <EmperorCard key={emperor.id} emperor={emperor} index={index} />
            ))}
          </div>
        </section>
      </div>
      <HistoryTabBar />
    </div>
  )
}
