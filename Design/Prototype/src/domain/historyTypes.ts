export interface DynastyPreview {
  id: string
  name: string
  years: string
  summary: string
}

export interface EmperorPreview {
  id: string
  name: string
  title: string
  years: string
  duration: string
  eras: string[]
  note?: string
}

export interface ReignEraPreview {
  id: string
  name: string
  emperor: string
  templeName: string
  years: string
  duration: string
  startYear: number
  endYear: number
  note: string
}

export interface DynastyEvent {
  year: string
  title: string
  description: string
}
