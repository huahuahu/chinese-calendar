# Data Model

## Purpose

This document defines the first-release data model for the Chinese calendar app.
It separates:

- absolute day identity
- civil-date presentation
- Chinese calendar facts
- political and reign-era attribution

The goal is to support accurate day-level browsing from the Qin dynasty onward while keeping the import pipeline and app persistence loosely coupled.

## Modeling Principles

### One Absolute Day, Many Representations

The app should treat a day as a single absolute record even when that day has multiple display layers.

Each day can have:

- one civil-date presentation
- one lunar-date record
- one sexagenary record
- multiple reign-era assignments

### Civil Date Is a Navigation Coordinate

The app browses by civil date, but civil date is not the source of truth for identity.

- Internal identity should use a continuous day index.
- Civil date exists for display and user navigation.
- Civil date display should switch from Julian to Gregorian at the 1582 reform boundary.

### Political Attribution Is One-to-Many

The same day may belong to multiple concurrent political timelines.

- A day may map to multiple dynasties or regimes in special cases.
- A day may have multiple emperors or reign eras depending on the chosen source data.
- One assignment should be marked as the primary record for summary UI.

## Entity Overview

## CalendarDay

Represents one absolute day in the dataset.

Suggested fields:

- `id: UUID`
- `dayIndex: Int`
- `julianDayNumber: Int`

Responsibilities:

- Primary identity for a day in storage
- Sorting and timeline traversal
- Anchor point for related records

Notes:

- `dayIndex` should be continuous across the full supported range.
- `julianDayNumber` is useful for cross-checking imported source data and external calculations.

## CivilDateRecord

Represents the civil-date display for a given day.

Suggested fields:

- `id: UUID`
- `calendarDayID: UUID`
- `year: Int`
- `month: Int`
- `day: Int`
- `calendarStyle: CivilCalendarStyle`

Suggested enum:

- `julian`
- `gregorian`

Responsibilities:

- Drive timeline labels and date-jump UI
- Make the 1582 reform rule explicit in the data layer

Notes:

- Only one civil-date record is expected per day in the first release.
- The record should be generated after applying the chosen reform boundary.

## LunarDateRecord

Represents the Chinese lunar date attached to one absolute day.

Suggested fields:

- `id: UUID`
- `calendarDayID: UUID`
- `lunarYear: Int`
- `lunarMonth: Int`
- `lunarDay: Int`
- `isLeapMonth: Bool`

Optional derived fields for convenience:

- `monthDisplayName: String`
- `dayDisplayName: String`

Responsibilities:

- Store normalized lunar date facts
- Support detail display and future search features

Notes:

- Store normalized numeric fields even if display strings are also generated.
- Keep formatting logic in shared domain or presentation helpers when practical.

## GanzhiRecord

Represents sexagenary labels for a day.

Suggested fields:

- `id: UUID`
- `calendarDayID: UUID`
- `yearStem: String`
- `yearBranch: String`
- `monthStem: String`
- `monthBranch: String`
- `dayStem: String`
- `dayBranch: String`

Responsibilities:

- Support display of sexagenary year, month, and day
- Keep imported cyclical labels normalized and queryable

Notes:

- Storing stems and branches separately keeps the data flexible for future filtering.
- Combined display strings such as `甲子` should be produced by formatting helpers.

## Dynasty

Represents a dynasty or top-level historical regime grouping.

Suggested fields:

- `id: String`
- `name: String`
- `startDayIndex: Int?`
- `endDayIndex: Int?`

Optional fields:

- `sortName: String`
- `notes: String?`

Responsibilities:

- Group emperors and reign eras
- Provide readable historical context in the UI

Notes:

- Start and end bounds can be left optional if the source material is uncertain.

## Emperor

Represents one emperor within a dynasty or regime context.

Suggested fields:

- `id: String`
- `dynastyID: String`
- `name: String`
- `templeName: String?`
- `posthumousTitle: String?`
- `personalName: String?`

Responsibilities:

- Provide the ruler identity for reign-era display
- Support richer historical detail later

Notes:

- `templeName` and `posthumousTitle` should be optional in v1.
- The primary display name should be whichever historical label is most recognizable for the chosen source.

## ReignEra

Represents one named reign era.

Suggested fields:

- `id: String`
- `emperorID: String`
- `name: String`
- `startDayIndex: Int?`
- `endDayIndex: Int?`

Optional fields:

- `eraSequence: Int?`

Responsibilities:

- Model reign-era identity independently of any specific day assignment
- Allow reuse across day-level assignment records

Notes:

- A single emperor may have multiple reign eras.
- Start and end bounds help validate imported assignment spans.

## ReignEraAssignment

Maps a day to a political record.

Suggested fields:

- `id: UUID`
- `calendarDayID: UUID`
- `dynastyID: String`
- `emperorID: String`
- `reignEraID: String`
- `regnalYearNumber: Int`
- `displayOrder: Int`
- `isPrimary: Bool`

Optional fields:

- `sourceNote: String?`

Responsibilities:

- Support multiple parallel regime records for the same day
- Decide which record appears on summary cards
- Preserve the exact political attribution imported from the source material

Notes:

- `displayOrder` should make detail views deterministic.
- The first release should allow multiple assignments per day without trying to collapse disagreements.

## Relationships

Suggested first-release relationships:

- `CalendarDay` to `CivilDateRecord`: one-to-one
- `CalendarDay` to `LunarDateRecord`: one-to-one
- `CalendarDay` to `GanzhiRecord`: one-to-one
- `CalendarDay` to `ReignEraAssignment`: one-to-many
- `Dynasty` to `Emperor`: one-to-many
- `Emperor` to `ReignEra`: one-to-many
- `Dynasty` to `ReignEraAssignment`: one-to-many through foreign key reference
- `Emperor` to `ReignEraAssignment`: one-to-many through foreign key reference
- `ReignEra` to `ReignEraAssignment`: one-to-many through foreign key reference

## Formatting Rules

### Regnal Year Display

Store regnal years as integers.
Display them using Chinese historical conventions.

Examples:

- `1` -> `元年`
- `2` -> `二年`
- `3` -> `三年`

### Civil Calendar Label

The UI should explicitly label whether a civil date is:

- `Julian`
- `Gregorian`

This avoids ambiguity around the 1582 boundary.

### Ganzhi Display

Store stem and branch components separately.
Format for display by concatenating the two values.

Examples:

- `甲` + `子` -> `甲子`
- `丙` + `午` -> `丙午`

## Import Boundaries

The app should not import raw source files directly into SwiftData.

Use a processed layer that:

- normalizes day identity
- applies the civil-calendar reform rule
- resolves reign-era references to stable IDs
- keeps one record per absolute day before persistence import

## Open Modeling Questions

- Should future versions split dynasties and non-dynastic regimes into separate entity types?
- Should sexagenary values be represented as enums in shared domain code and strings in persistence?
- Do we want a dedicated search index model later for reign-era name lookup?
