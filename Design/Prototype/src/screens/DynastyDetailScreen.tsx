import { DynastyFactCard } from '../components/history/DynastyFactCard'
import { HistoryTabBar } from './HistoryTabBar'

interface DynastyDetailScreenProps {
  onBack: () => void
  onOpenEmperors: () => void
  onOpenEras: () => void
  onOpenSpan: () => void
}

export function DynastyDetailScreen({
  onBack,
  onOpenEmperors,
  onOpenEras,
  onOpenSpan,
}: DynastyDetailScreenProps) {
  return (
    <div className="screen history-screen dynasty-detail-screen">
      <nav className="inline-navigation">
        <button type="button" data-transition-id="back-history" onClick={onBack}>
          <span aria-hidden="true">‹</span> 朝代
        </button>
        <h1 className="inline-navigation__title">明</h1>
      </nav>

      <div className="history-scroll history-scroll--under-nav">
        <section className="dynasty-fact-grid" aria-label="明朝资料入口">
          <DynastyFactCard
            value="16"
            label="位皇帝"
            accessibilityLabel="查看明朝 16 位皇帝"
            transitionId="open-emperors"
            onOpen={onOpenEmperors}
          />
          <DynastyFactCard
            value="17"
            label="个年号"
            accessibilityLabel="查看明朝 17 个年号"
            transitionId="open-eras"
            onOpen={onOpenEras}
          />
          <DynastyFactCard
            value="276"
            label="年"
            accessibilityLabel="查看明朝国祚与起讫大事"
            transitionId="open-span"
            onOpen={onOpenSpan}
          />
        </section>

        <p className="context-note">明英宗两度在位，因此 16 位皇帝对应 17 个年号。</p>
      </div>
      <HistoryTabBar />
    </div>
  )
}
