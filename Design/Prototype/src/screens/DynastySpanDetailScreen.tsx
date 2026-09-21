import { mingDynastyEvents } from './historyData'
import { HistoryTabBar } from './HistoryTabBar'

export function DynastySpanDetailScreen({ onBack }: { onBack: () => void }) {
  return (
    <div className="screen history-screen dynasty-span-detail-screen">
      <nav className="inline-navigation">
        <button type="button" data-transition-id="back-span" onClick={onBack}>
          <span aria-hidden="true">‹</span> 明
        </button>
        <h1 className="inline-navigation__title">朝代起讫</h1>
      </nav>

      <div className="history-scroll history-scroll--under-nav">
        <header className="plain-summary">
          <p>明 · 正统时间线</p>
          <div><strong>1368—1644</strong><i aria-hidden="true" /><span>国祚 276 年</span></div>
        </header>

        <section className="span-detail-section" aria-labelledby="boundary-heading">
          <div className="history-section-heading history-section-heading--stacked">
            <p>边界对照</p>
            <h2 id="boundary-heading">朝代自称与正统期</h2>
          </div>
          <div className="boundary-comparison-card">
            <div>
              <span>朝代自称</span>
              <strong>1368—1644</strong>
            </div>
            <div>
              <span>正统时间线</span>
              <strong>1368—1644</strong>
            </div>
          </div>
        </section>

        <section className="span-detail-section" aria-labelledby="event-heading">
          <div className="history-section-heading history-section-heading--stacked">
            <p>相关说明</p>
            <h2 id="event-heading">关键边界事件</h2>
          </div>
          <div className="dynasty-event-timeline">
            {mingDynastyEvents.map((event) => (
              <article key={event.year}>
                <span>{event.year}</span>
                <div>
                  <strong>{event.title}</strong>
                  <p>{event.description}</p>
                </div>
              </article>
            ))}
          </div>
        </section>

        <section className="source-card source-card--scope">
          <span>范围说明</span>
          <strong>南明与明郑不计入明朝正统期</strong>
          <p>仓库将其作为补充的非正统政权另列。本页不把 1645 年之后的沿用年号并入明朝正统期。</p>
        </section>
      </div>
      <HistoryTabBar />
    </div>
  )
}
