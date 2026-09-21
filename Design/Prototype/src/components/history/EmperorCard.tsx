import type { EmperorPreview } from '../../domain/historyTypes'

interface EmperorCardProps {
  emperor: EmperorPreview
  index: number
}

export function EmperorCard({ emperor, index }: EmperorCardProps) {
  return (
    <article className="emperor-row">
      <span className="emperor-row__index">{String(index + 1).padStart(2, '0')}</span>
      <div className="emperor-row__body">
        <div className="emperor-row__title">
          <strong>{emperor.name}</strong>
          <span>{emperor.title}</span>
        </div>
        <div className="emperor-row__meta">
          <span>{emperor.years}</span>
          <i aria-hidden="true" />
          <span>{emperor.duration}</span>
        </div>
        <div className="emperor-row__eras" aria-label={`年号：${emperor.eras.join('、')}`}>
          {emperor.eras.map((era) => <span key={era}>{era}</span>)}
        </div>
        {emperor.note && <p>{emperor.note}</p>}
      </div>
    </article>
  )
}
