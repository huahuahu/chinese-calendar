# Implementation Plan

## Product Goal

Build a shared iOS and macOS app for browsing the historical Chinese calendar day by day.
The first release focuses on dates from the Qin dynasty onward.

Users should be able to browse a continuous civil-date timeline and inspect a single day in detail.
Each day should show:

- Civil date
- Whether the civil date is Julian or Gregorian
- Lunar year, month, day
- Whether the lunar month is a leap month
- Sexagenary year, month, day
- Dynasty
- Emperor
- Reign era
- Regnal year in Chinese display form such as `元年`, `二年`, `三年`

The app must support multiple parallel regime records on the same day.

## First-Release Decisions

### Date Range

- Start coverage from the Qin dynasty.

### Civil Calendar Rule

- Use a continuous day index internally for ordering and lookup.
- Display civil dates using the Julian calendar before the Gregorian reform.
- Switch according to the 1582 reform boundary.

### Navigation Model

- The home screen should browse by continuous civil date.
- Chinese calendar data remains the primary content.
- Civil date acts as the navigation coordinate.

### Data Sources

- Calendar calculation and source data come from `ytliu0/ChineseCalendar`.
- Reign-era data is maintained as a separate source.
- Raw source files must stay outside the app targets.

### Persistence Strategy

- Store app query models in SwiftData.
- Do not couple SwiftData models directly to the raw upstream file formats.
- Import processed data artifacts into SwiftData.

## Repository Layout

Keep source data and app code separate.

- `Data/Raw/ChineseCalendar`: upstream raw calendar data
- `Data/Raw/ReignEras`: raw reign-era source material
- `Data/Processed/calendar_days`: normalized day-level calendar artifacts
- `Data/Processed/reign_eras`: normalized reign-era artifacts
- `Scripts/ImportChineseCalendar`: scripts for upstream calendar import
- `Scripts/ImportReignEras`: scripts for reign-era import
- `Scripts/BuildDataset`: scripts that merge processed artifacts into app import payloads

## Suggested Module Structure

- `ChineseCalendarCore`: domain types and formatting rules that do not depend on SwiftData
- `ChineseCalendarData`: import pipeline, repositories, parsing, and query services
- `ChineseCalendarPersistence`: SwiftData models and persistence services
- `ChineseCalendarUI`: shared SwiftUI views and navigation
- `Apps/iOSApp`: iOS-specific app setup
- `Apps/macOSApp`: macOS-specific app setup

## SwiftData Model Outline

### CalendarDay

One row per absolute day.

- `id`
- `dayIndex`
- `julianDayNumber`

### CivilDateRecord

Display-oriented civil date metadata.

- `calendarDayID`
- `year`
- `month`
- `day`
- `calendarStyle` (`julian` or `gregorian`)

### LunarDateRecord

- `calendarDayID`
- `lunarYear`
- `lunarMonth`
- `lunarDay`
- `isLeapMonth`

### GanzhiRecord

- `calendarDayID`
- `yearStem`
- `yearBranch`
- `monthStem`
- `monthBranch`
- `dayStem`
- `dayBranch`

### Dynasty

- `id`
- `name`
- `startDayIndex`
- `endDayIndex`

### Emperor

- `id`
- `name`
- `templeName`
- `posthumousTitle`
- `dynastyID`

### ReignEra

- `id`
- `name`
- `emperorID`
- `startDayIndex`
- `endDayIndex`

### ReignEraAssignment

Maps a day to one or more political records.

- `calendarDayID`
- `dynastyID`
- `emperorID`
- `reignEraID`
- `regnalYearNumber`
- `displayOrder`
- `isPrimary`

## Processed Data Format

Use normalized intermediate artifacts before importing into SwiftData.

Suggested files:

- `Data/Processed/calendar_days/calendar_days.jsonl`
- `Data/Processed/reign_eras/reign_era_assignments.jsonl`

The processed layer should:

- Decouple import scripts from app persistence
- Make validation and snapshot testing easier
- Allow swapping or improving reign-era sources later

## First UI Slice

### Home Timeline

- Browse by continuous civil date
- Show the current civil date with Julian or Gregorian labeling
- Show lunar date summary
- Show sexagenary summary
- Show the primary reign-era record
- Allow moving to previous and next day
- Allow jumping to a civil date

### Day Detail

- Show the full civil date presentation
- Show lunar date and leap-month flag
- Show sexagenary year, month, day
- Show all reign-era assignments for that day

## Recommended Delivery Order

1. Add a new `ChineseCalendarPersistence` target.
2. Define the SwiftData entities.
3. Build a small in-memory prototype for the timeline and day detail views.
4. Define processed-data schemas.
5. Implement import scripts for calendar data.
6. Implement import scripts for reign-era data.
7. Import processed artifacts into SwiftData.
8. Replace placeholder repositories with real queries.

## Open Questions

- Which reign-era reference source should be treated as authoritative for the first release?
- Should temple names and posthumous titles be required for every emperor or optional in v1?
- Should the first release support searching by reign-era name, or only timeline browsing?
- What is the initial lower and upper bound of the supported date dataset?
