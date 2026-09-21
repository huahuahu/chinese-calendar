import { useEffect, useRef, useState, type RefObject } from 'react'
import { navigationFlow, type PrototypeTransition } from '../flows/navigationFlow'

interface ConnectionGeometry extends PrototypeTransition {
  sourceX: number
  sourceY: number
  targetX: number
  targetY: number
  labelX: number
  labelY: number
  orientation: 'horizontal' | 'vertical'
  routeX?: number
}

const targetOffsets: Record<string, number> = {
  'open-dynasty': 0.3,
  'back-history': 0.72,
  'open-emperors': 0.28,
  'back-emperors': 0.58,
  'open-eras': 0.32,
  'back-eras': 0.66,
  'open-span': 0.32,
  'back-span': 0.66,
  'open-era': 0.34,
  'back-era-list': 0.68,
}

const labelOffsets: Record<string, number> = {
  'open-dynasty': -34,
  'back-history': 40,
  'open-emperors': -34,
  'back-emperors': 38,
  'open-eras': -36,
  'back-eras': 40,
  'open-span': -34,
  'back-span': 40,
  'open-era': -36,
  'back-era-list': 40,
}

export function FlowConnections({
  boardRef,
  layoutKey,
}: {
  boardRef: RefObject<HTMLDivElement | null>
  layoutKey: string
}) {
  const [connections, setConnections] = useState<ConnectionGeometry[]>([])
  const animationFrame = useRef<number | null>(null)

  useEffect(() => {
    const board = boardRef.current
    if (!board) return

    const measure = () => {
      const boardRect = board.getBoundingClientRect()
      const next = navigationFlow.flatMap((transition): ConnectionGeometry[] => {
        const source = board.querySelector<HTMLElement>(`[data-transition-id="${transition.id}"]`)
        const targetSelector = `[data-screen-id="${transition.target}"]`
        const target = board.querySelector<HTMLElement>(targetSelector)
        if (!source || !target) return []

        const sourceRect = source.getBoundingClientRect()
        const targetRect = target.getBoundingClientRect()
        const pointsRight = targetRect.left > sourceRect.left
        const sourceX = (pointsRight ? sourceRect.right : sourceRect.left) - boardRect.left
        const sourceY = sourceRect.top + sourceRect.height / 2 - boardRect.top
        const targetX = (pointsRight ? targetRect.left : targetRect.right) - boardRect.left
        const targetY = targetRect.top + targetRect.height * (targetOffsets[transition.id] ?? 0.5) - boardRect.top

        return [{
          ...transition,
          sourceX,
          sourceY,
          targetX,
          targetY,
          labelX: (sourceX + targetX) / 2,
          labelY: (sourceY + targetY) / 2 + (labelOffsets[transition.id] ?? 0),
          orientation: 'horizontal',
        }]
      })
      setConnections(next)
    }

    const scheduleMeasure = () => {
      if (animationFrame.current !== null) cancelAnimationFrame(animationFrame.current)
      animationFrame.current = requestAnimationFrame(measure)
    }

    const observer = new ResizeObserver(scheduleMeasure)
    observer.observe(board)
    board.querySelectorAll<HTMLElement>('.phone-frame, [data-transition-id]').forEach((element) => observer.observe(element))
    window.addEventListener('resize', scheduleMeasure)
    measure()

    return () => {
      observer.disconnect()
      window.removeEventListener('resize', scheduleMeasure)
      if (animationFrame.current !== null) cancelAnimationFrame(animationFrame.current)
    }
  }, [boardRef, layoutKey])

  return (
    <svg className="flow-connections" aria-label="页面按钮与目标页面之间的导航连线">
      <defs>
        <marker id="flow-arrow-solid" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto">
          <path d="M0,0 L9,4.5 L0,9 Z" />
        </marker>
        <marker id="flow-arrow-sheet" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto">
          <path d="M0,0 L9,4.5 L0,9 Z" />
        </marker>
      </defs>
      {connections.map((connection) => {
        const bend = Math.max(70, Math.abs(connection.targetX - connection.sourceX) * 0.48)
        const direction = connection.targetX > connection.sourceX ? 1 : -1
        const verticalBend = Math.max(70, Math.abs(connection.targetY - connection.sourceY) * 0.34)
        const routeX = connection.routeX ?? connection.sourceX
        const path = connection.orientation === 'vertical'
          ? `M ${connection.sourceX} ${connection.sourceY} C ${routeX} ${connection.sourceY}, ${routeX} ${connection.sourceY + verticalBend * 0.45}, ${routeX} ${connection.sourceY + verticalBend} L ${routeX} ${connection.targetY - verticalBend} C ${routeX} ${connection.targetY - verticalBend * 0.45}, ${connection.targetX} ${connection.targetY - 28}, ${connection.targetX} ${connection.targetY}`
          : `M ${connection.sourceX} ${connection.sourceY} C ${connection.sourceX + bend * direction} ${connection.sourceY}, ${connection.targetX - bend * direction} ${connection.targetY}, ${connection.targetX} ${connection.targetY}`
        const label = `${connection.trigger} · ${connection.presentation}`
        const labelWidth = Math.max(96, label.length * 11)
        return (
          <g key={connection.id} className={`flow-connection flow-connection--${connection.presentation}`}>
            <path d={path} markerEnd="url(#flow-arrow-solid)" />
            <circle cx={connection.sourceX} cy={connection.sourceY} r="5" />
            <g transform={`translate(${connection.labelX}, ${connection.labelY})`} className="flow-connection__label">
              <rect x={-labelWidth / 2} y="-14" width={labelWidth} height="28" rx="14" />
              <text textAnchor="middle" dominantBaseline="middle">{label}</text>
            </g>
          </g>
        )
      })}
    </svg>
  )
}
