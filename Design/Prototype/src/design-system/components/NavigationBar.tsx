import { Button } from './Button'

interface NavigationBarProps {
  title: string
  leadingLabel?: string
  trailingLabel?: string
  onLeading?: () => void
  onTrailing?: () => void
  leadingTransitionId?: string
  trailingTransitionId?: string
}

export function NavigationBar({
  title,
  leadingLabel,
  trailingLabel,
  onLeading,
  onTrailing,
  leadingTransitionId,
  trailingTransitionId,
}: NavigationBarProps) {
  return (
    <header className="navigation-bar">
      <div className="navigation-bar__side">
        {leadingLabel && <Button onClick={onLeading} data-transition-id={leadingTransitionId}>‹ {leadingLabel}</Button>}
      </div>
      <strong>{title}</strong>
      <div className="navigation-bar__side navigation-bar__side--trailing">
        {trailingLabel && <Button onClick={onTrailing} data-transition-id={trailingTransitionId}>{trailingLabel}</Button>}
      </div>
    </header>
  )
}
