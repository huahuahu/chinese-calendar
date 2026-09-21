import { mingReignEras, type ReignEraPreview } from './historyData'
import { HistoryTabBar } from './HistoryTabBar'

interface ReignEraDetailScreenProps {
  era: ReignEraPreview
  onBack: () => void
}

export function ReignEraDetailScreen({ era, onBack }: ReignEraDetailScreenProps) {
  const eraIndex = mingReignEras.findIndex((candidate) => candidate.id === era.id) + 1

  return (
    <div className="screen history-screen reign-era-detail-screen">
      <nav className="inline-navigation">
        <button type="button" data-transition-id="back-era-list" onClick={onBack}>
          <span aria-hidden="true">‹</span> 年号
        </button>
        <h1 className="inline-navigation__title">{era.name}</h1>
      </nav>

      <div className="history-scroll history-scroll--under-nav">
        <header className="plain-summary">
          <p>明 · 第 {eraIndex} 个年号</p>
          <div>
            <strong>{era.years}</strong>
            <i aria-hidden="true" />
            <span>{era.duration}</span>
          </div>
        </header>

        <section className="era-owner-card">
          <div className="era-owner-card__portrait" aria-hidden="true">{era.templeName.slice(0, 1)}</div>
          <div>
            <span>所属皇帝</span>
            <strong>{era.emperor} · {era.templeName}</strong>
            <small>明朝皇帝序列</small>
          </div>
        </section>

        <section className="era-detail-section">
          <div className="history-section-heading history-section-heading--stacked">
            <p>使用区间</p>
            <h2>纪年边界</h2>
          </div>
          <div className="boundary-card">
            <div>
              <span>开始</span>
              <strong>{era.startYear}</strong>
              <small>年精度</small>
            </div>
            <span className="boundary-card__line" aria-hidden="true"><i /></span>
            <div>
              <span>结束</span>
              <strong>{era.endYear}</strong>
              <small>年精度</small>
            </div>
          </div>
        </section>

        <section className="era-detail-section">
          <div className="history-section-heading history-section-heading--stacked">
            <p>沿革说明</p>
            <h2>年号交接</h2>
          </div>
          <div className="era-note-card">
            <span aria-hidden="true">记</span>
            <p>{era.note}</p>
          </div>
        </section>
      </div>
      <HistoryTabBar />
    </div>
  )
}
