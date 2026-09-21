import type { DynastyPreview } from '../../domain/historyTypes'

interface DynastyCardProps {
  dynasty: DynastyPreview
  isFeatured?: boolean
  transitionId?: string
  onOpen?: () => void
}

export function DynastyCard({
  dynasty,
  isFeatured = false,
  transitionId,
  onOpen,
}: DynastyCardProps) {
  return (
    <button
      type="button"
      className={`dynasty-row ${isFeatured ? 'dynasty-row--featured' : ''}`}
      data-transition-id={transitionId}
      onClick={onOpen}
    >
      <span className="dynasty-row__dot" aria-hidden="true" />
      <span className="dynasty-row__name">{dynasty.name}</span>
      <span className="dynasty-row__content">
        <strong>{dynasty.years}</strong>
        <small>{dynasty.summary}</small>
      </span>
      <span className="row-chevron" aria-hidden="true">›</span>
    </button>
  )
}
