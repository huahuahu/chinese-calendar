import { useEffect, useRef, useState, type ReactNode } from 'react'
import { SegmentedControl } from '../design-system/components/SegmentedControl'
import { screenNames, type ScreenId } from '../flows/navigationFlow'
import { DynastyDetailScreen } from '../screens/DynastyDetailScreen'
import { DynastySpanDetailScreen } from '../screens/DynastySpanDetailScreen'
import { EmperorListScreen } from '../screens/EmperorListScreen'
import { HistoryHomeScreen } from '../screens/HistoryHomeScreen'
import { mingReignEras, type ReignEraPreview } from '../screens/historyData'
import { ReignEraDetailScreen } from '../screens/ReignEraDetailScreen'
import { ReignEraListScreen } from '../screens/ReignEraListScreen'
import { FlowConnections } from './FlowConnections'
import { IPhoneCanvas } from './IPhoneCanvas'

type Theme = 'light' | 'dark'
type CanvasSize = 'compact' | 'regular'

export function PrototypeApp() {
  const [theme, setTheme] = useState<Theme>('light')
  const [size, setSize] = useState<CanvasSize>('regular')
  const [activeScreen, setActiveScreen] = useState<ScreenId>('history-home')
  const [selectedEra, setSelectedEra] = useState<ReignEraPreview>(mingReignEras[2])
  const boardRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    document.documentElement.dataset.size = size
  }, [theme, size])

  const openEra = (era: ReignEraPreview) => {
    setSelectedEra(era)
    setActiveScreen('reign-era-detail')
  }

  return (
    <div className="prototype-shell">
      <header className="workspace-header">
        <div>
          <p>中华历 · 第二个 Tab</p>
          <h1>朝代与年号流程重构</h1>
        </div>
        <div className="workspace-controls">
          <SegmentedControl label="主题" value={theme} onChange={setTheme} options={[
            { label: '浅色', value: 'light' },
            { label: '深色', value: 'dark' },
          ]} />
          <SegmentedControl label="画板尺寸" value={size} onChange={setSize} options={[
            { label: '紧凑', value: 'compact' },
            { label: '常规', value: 'regular' },
          ]} />
        </div>
      </header>

      <main className="prototype-board">
        <div className="prototype-board__heading">
          <div>
            <span>Navigation Flow</span>
            <h2>朝代目录 → 朝代总览 → 帝王 / 年号 / 国祚</h2>
          </div>
          <div className="connection-legend">
            <span><i />push</span>
            <span><i className="pop" />pop</span>
          </div>
        </div>

        <div className="flow-board" ref={boardRef}>
          <FlowConnections boardRef={boardRef} layoutKey={`${theme}-${size}-${selectedEra.id}`} />

          <ScreenArtboard index="01" screenId="history-home" detail="Tab 根页面" activeScreen={activeScreen}>
            <HistoryHomeScreen onOpenDynasty={() => setActiveScreen('dynasty-detail')} />
          </ScreenArtboard>

          <ScreenArtboard index="02" screenId="dynasty-detail" detail="push" activeScreen={activeScreen}>
            <DynastyDetailScreen
              onBack={() => setActiveScreen('history-home')}
              onOpenEmperors={() => setActiveScreen('emperor-list')}
              onOpenEras={() => setActiveScreen('reign-era-list')}
              onOpenSpan={() => setActiveScreen('dynasty-span-detail')}
            />
          </ScreenArtboard>

          <ScreenArtboard index="03" screenId="emperor-list" detail="push" activeScreen={activeScreen}>
            <EmperorListScreen onBack={() => setActiveScreen('dynasty-detail')} />
          </ScreenArtboard>

          <ScreenArtboard index="04" screenId="reign-era-list" detail="push" activeScreen={activeScreen}>
            <ReignEraListScreen
              onBack={() => setActiveScreen('dynasty-detail')}
              onOpenEra={openEra}
            />
          </ScreenArtboard>

          <ScreenArtboard index="05" screenId="dynasty-span-detail" detail="push" activeScreen={activeScreen}>
            <DynastySpanDetailScreen onBack={() => setActiveScreen('dynasty-detail')} />
          </ScreenArtboard>

          <ScreenArtboard index="06" screenId="reign-era-detail" detail="push" activeScreen={activeScreen}>
            <ReignEraDetailScreen
              era={selectedEra}
              onBack={() => setActiveScreen('reign-era-list')}
            />
          </ScreenArtboard>
        </div>
      </main>
    </div>
  )
}

function ScreenArtboard({
  index,
  screenId,
  detail,
  activeScreen,
  children,
}: {
  index: string
  screenId: ScreenId
  detail: string
  activeScreen: ScreenId
  children: ReactNode
}) {
  return (
    <section className={`screen-artboard screen-artboard--${screenId}`}>
      <header>
        <span>{index}</span>
        <h2>{screenNames[screenId]}</h2>
        <small>{detail}</small>
      </header>
      <IPhoneCanvas screenId={screenId} isActive={activeScreen === screenId}>
        {children}
      </IPhoneCanvas>
    </section>
  )
}
