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
  'select-date': 0.54,
  'close-year-picker': 0.3,
  'open-year-picker': 0.23,
  'select-year': 0.62,
}

const labelOffsets: Record<string, number> = {
  'open-year-picker': 22,
  'close-year-picker': -34,
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
        const targetSelector = transition.targetType === 'state'
          ? `[data-state-id="${transition.target}"]`
          : `[data-screen-id="${transition.target}"]`
        const target = board.querySelector<HTMLElement>(targetSelector)
        if (!source || !target) return []

        const sourceRect = source.getBoundingClientRect()
        const targetRect = target.getBoundingClientRect()
        const isState = transition.targetType === 'state'
        const pointsRight = targetRect.left > sourceRect.left
        const sourceX = (isState ? sourceRect.left + sourceRect.width / 2 : pointsRight ? sourceRect.right : sourceRect.left) - boardRect.left
        const sourceY = (isState ? sourceRect.bottom : sourceRect.top + sourceRect.height / 2) - boardRect.top
        const targetX = (isState ? targetRect.left + targetRect.width / 2 : pointsRight ? targetRect.left : targetRect.right) - boardRect.left
        const targetY = (isState ? targetRect.top : targetRect.top + targetRect.height * (targetOffsets[transition.id] ?? 0.5)) - boardRect.top
        const routeX = isState
          ? transition.id === 'select-today'
            ? Math.max(sourceX, targetX) + 92
            : Math.min(sourceX, targetX) - 44
          : undefined

        return [{
          ...transition,
          sourceX,
          sourceY,
          targetX,
          targetY,
          labelX: isState ? (routeX ?? sourceX) + (transition.id === 'select-today' ? 58 : 62) : (sourceX + targetX) / 2,
          labelY: (sourceY + targetY) / 2 + (labelOffsets[transition.id] ?? 0),
          orientation: isState ? 'vertical' : 'horizontal',
          routeX,
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
            <path d={path} markerEnd={`url(#flow-arrow-${connection.presentation === 'sheet' || connection.presentation === 'dismiss' ? 'sheet' : 'solid'})`} />
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
