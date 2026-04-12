# Data Sources

## Purpose

This document defines where the first-release dataset comes from and what each source is responsible for.
The project uses separate sources for:

- calendar and date-conversion facts
- political and reign-era attribution

This keeps historical calendar logic separate from reign-era curation.

## Source Categories

### Calendar Source

Primary source:

- `https://github.com/ytliu0/ChineseCalendar`

Responsibilities:

- Chinese calendar calculations
- Lunar date mapping
- Leap-month information
- Sexagenary values if available from the source or derivable from its outputs
- Day-level calendar facts that can be normalized into processed artifacts

This source should not be treated as the authority for emperor, dynasty, or reign-era information.

### Reign-Era Source

Primary role:

- Provide dynasty, emperor, reign-era, and regnal-year attribution

Responsibilities:

- Dynasty names
- Emperor identities
- Reign-era names
- Reign-era start and end spans
- Parallel regime coverage when multiple records apply on the same day

This source may be composed from one or more curated historical references.

## Source Boundary Rules

### Calendar Data Must Stay Focused

Calendar ingestion should only produce:

- absolute day mapping
- civil-date display values
- lunar date values
- sexagenary values

It should not assign dynasties or emperors.

### Reign-Era Data Must Stay Focused

Reign-era ingestion should only produce:

- dynasties
- emperors
- reign eras
- day-to-era assignment spans

It should not recalculate lunar or civil dates.

### Merge Only in the Processed Layer

The app should merge the two source categories only after both have been normalized.

This merge step should:

- align both sources on the same day index
- preserve one-to-many reign-era assignments
- avoid modifying original raw files

## Storage Layout

Suggested repository layout:

- `Data/Raw/ChineseCalendar`: upstream clone or extracted raw source files
- `Data/Raw/ReignEras`: manually curated reign-era source material
- `Data/Processed/calendar_days`: normalized day-level calendar outputs
- `Data/Processed/reign_eras`: normalized political outputs

Guidelines:

- Do not place raw historical source files under app target directories.
- Do not depend on `Data/Raw` directly from app runtime code.
- Treat `Data/Processed` as the import boundary for persistence.

## Recommended Raw Formats

### Calendar Raw Data

Acceptable forms:

- cloned upstream repository content
- extracted tables copied from the upstream project
- intermediate files generated directly from the upstream source

Requirements:

- preserve provenance
- preserve the exact upstream version or commit when possible

### Reign-Era Raw Data

Acceptable forms:

- curated CSV files
- curated JSON files
- manually maintained reference tables with source notes

Requirements:

- stable IDs for dynasties, emperors, and reign eras
- clear source notes for ambiguous or contested spans
- support for overlapping assignments when regimes coexist

## Recommended Processed Outputs

### Calendar-Day Artifact

Suggested file:

- `Data/Processed/calendar_days/calendar_days.jsonl`

Each line should include:

- absolute day identity
- Julian day number or equivalent anchor
- civil-date display values
- lunar date values
- sexagenary values

### Reign-Era Assignment Artifact

Suggested file:

- `Data/Processed/reign_eras/reign_era_assignments.jsonl`

Each line should include:

- absolute day identity or an assignment span resolvable to day identities
- dynasty ID and name
- emperor ID and name
- reign-era ID and name
- regnal year number
- primary-display marker
- ordering information for parallel records

## Source Provenance

Each processed artifact should be traceable back to its input source.

Recommended metadata to track during import:

- upstream repository URL
- upstream commit hash or release tag
- local source file path
- importer version or script name
- generation timestamp

This metadata can live in:

- sidecar metadata files in `Data/Processed`
- import logs
- future manifest files

## Validation Expectations

### Calendar Validation

Validate that:

- day indices are continuous
- civil-date conversion follows the 1582 reform rule
- lunar months and days are within valid bounds
- leap-month markers match the source

### Reign-Era Validation

Validate that:

- all foreign IDs are stable and unique
- assignment spans resolve to valid day indices
- regnal year numbers are positive
- overlapping records are intentional, not accidental duplicates

### Merge Validation

Validate that:

- every assignment points to a real calendar day
- summary selection rules produce at most one primary assignment per day
- days without reign-era records are handled intentionally rather than silently dropped

## Open Questions

- Which historical reference will be the first authoritative reign-era source?
- Do we want one manually curated source, or a blend of references with conflict notes?
- Should processed outputs include provenance fields inline or in a separate manifest?
