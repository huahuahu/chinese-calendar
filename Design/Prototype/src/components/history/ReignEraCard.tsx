import type { ReignEraPreview } from '../../domain/historyTypes'

interface ReignEraCardProps {
  era: ReignEraPreview
  isFeatured?: boolean
  transitionId?: string
  onOpen: (era: ReignEraPreview) => void
}

export function ReignEraCard({
  era,
  isFeatured = false,
  transitionId,
  onOpen,
}: ReignEraCardProps) {
  return (
    <button
      type="button"
      className={`era-row ${isFeatured ? 'era-row--featured' : ''}`}
      data-transition-id={transitionId}
      onClick={() => onOpen(era)}
      aria-label={`${era.name}，${era.years}，${era.emperor}${era.templeName}`}
    >
      <span className="era-row__rail" aria-hidden="true"><i /></span>
      <span className="era-row__year">{era.years}</span>
      <span className="era-row__body">
        <span className="era-row__title"><strong>{era.name}</strong><small>{era.duration}</small></span>
        <span className="era-row__emperor">{era.emperor} · {era.templeName}</span>
      </span>
      <span className="row-chevron" aria-hidden="true">›</span>
    </button>
  )
}
