import { DynastyCard } from '../components/history/DynastyCard'
import { dynasties } from './historyData'
import { HistoryTabBar } from './HistoryTabBar'

export function HistoryHomeScreen({ onOpenDynasty }: { onOpenDynasty: () => void }) {
  return (
    <div className="screen history-screen history-home-screen">
      <div className="history-scroll">
        <header className="large-title-header">
          <h1>朝代</h1>
          <span>沿正统时间线，进入一个朝代的纪年体系</span>
        </header>

        <section className="dynasty-section" aria-labelledby="dynasty-heading">
          <div className="history-section-heading">
            <h2 id="dynasty-heading">朝代序列</h2>
            <span>按起始年代</span>
          </div>
          <div className="dynasty-timeline">
            {dynasties.map((dynasty) => {
              const isMing = dynasty.id === 'ming'
              return (
                <DynastyCard
                  key={dynasty.id}
                  dynasty={dynasty}
                  isFeatured={isMing}
                  transitionId={isMing ? 'open-dynasty' : undefined}
                  onOpen={isMing ? onOpenDynasty : undefined}
                />
              )
            })}
          </div>
        </section>
      </div>
      <HistoryTabBar />
    </div>
  )
}
