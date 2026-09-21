import { ReignEraCard } from '../components/history/ReignEraCard'
import { mingReignEras, type ReignEraPreview } from './historyData'
import { HistoryTabBar } from './HistoryTabBar'

interface ReignEraListScreenProps {
  onBack: () => void
  onOpenEra: (era: ReignEraPreview) => void
}

export function ReignEraListScreen({ onBack, onOpenEra }: ReignEraListScreenProps) {
  return (
    <div className="screen history-screen reign-era-list-screen">
      <nav className="inline-navigation">
        <button type="button" data-transition-id="back-eras" onClick={onBack}>
          <span aria-hidden="true">‹</span> 明
        </button>
        <h1 className="inline-navigation__title">年号</h1>
      </nav>

      <div className="history-scroll history-scroll--under-nav">
        <p className="list-summary">17 个年号 · 1368—1644</p>

        <section aria-label="明朝年号列表">
          <div className="era-timeline era-timeline--full">
            {mingReignEras.map((era) => (
              <ReignEraCard
                key={era.id}
                era={era}
                isFeatured={era.id === 'yongle'}
                transitionId={era.id === 'yongle' ? 'open-era' : undefined}
                onOpen={onOpenEra}
              />
            ))}
          </div>
        </section>
      </div>
      <HistoryTabBar />
    </div>
  )
}
