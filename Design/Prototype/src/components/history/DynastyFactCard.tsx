interface DynastyFactCardProps {
  value: string
  label: string
  accessibilityLabel: string
  transitionId: string
  onOpen: () => void
}

export function DynastyFactCard({
  value,
  label,
  accessibilityLabel,
  transitionId,
  onOpen,
}: DynastyFactCardProps) {
  return (
    <button
      type="button"
      data-transition-id={transitionId}
      onClick={onOpen}
      aria-label={accessibilityLabel}
    >
      <span className="dynasty-fact-grid__number">{value}</span>
      <strong>{label}</strong>
      <span className="dynasty-fact-grid__chevron" aria-hidden="true">›</span>
    </button>
  )
}
