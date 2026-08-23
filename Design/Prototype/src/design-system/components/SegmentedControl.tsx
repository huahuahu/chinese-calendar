interface SegmentedControlProps<T extends string> {
  label: string
  value: T
  options: readonly { label: string; value: T }[]
  onChange: (value: T) => void
}

export function SegmentedControl<T extends string>({ label, value, options, onChange }: SegmentedControlProps<T>) {
  return (
    <fieldset className="segmented-control" aria-label={label}>
      {options.map((option) => (
        <button
          type="button"
          key={option.value}
          className={option.value === value ? 'is-selected' : ''}
          aria-pressed={option.value === value}
          onClick={() => onChange(option.value)}
        >
          {option.label}
        </button>
      ))}
    </fieldset>
  )
}
