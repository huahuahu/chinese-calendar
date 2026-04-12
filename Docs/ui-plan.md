# UI Plan

## Purpose

This document defines the first UI slice for the Chinese calendar app.
The first release should prioritize a clear timeline-browsing experience over advanced search or analysis tools.

## Product Direction

The app should feel like a historical day browser.

- The user moves through time by civil date.
- The app reveals the Chinese calendar and political context for the selected day.
- Detail is available without overwhelming the home screen.

The core question the UI answers is:

- what was this specific day in the Chinese calendar and reign-era system?

## First-Release Screens

### Timeline Home

The home screen is the main browsing surface.

Primary jobs:

- show the currently selected day
- make it easy to move backward or forward by day
- summarize the most important information for that day
- provide a path into fuller detail

Suggested sections:

1. date header
2. lunar summary
3. sexagenary summary
4. primary reign-era summary
5. parallel records preview
6. timeline controls

### Day Detail

The detail screen expands all information for the selected day.

Primary jobs:

- show the full civil-date presentation
- show full lunar and sexagenary values
- list every applicable reign-era assignment
- make ambiguity visible instead of hiding it

## Timeline Home Structure

### Date Header Card

Show:

- civil year, month, day
- explicit `Julian` or `Gregorian` label
- a concise descriptor that the date is part of the historical browsing timeline

Purpose:

- anchor the user in the current browsing position
- make the civil-calendar system unambiguous

### Lunar Summary Card

Show:

- lunar year
- lunar month
- lunar day
- leap-month marker when needed

Purpose:

- present the Chinese calendar layer as the primary content

### Sexagenary Summary Card

Show:

- sexagenary year
- sexagenary month
- sexagenary day

Purpose:

- surface cyclical calendar information without forcing the user into a detail screen

### Primary Reign-Era Card

Show one summary line for the primary assignment.

Suggested display:

- dynasty name
- emperor name
- reign-era name
- regnal year in Chinese form

Example:

- `西汉 · 汉武帝 · 建元元年`

Purpose:

- provide immediate historical context for the selected day

### Parallel Records Preview

Show when the selected day has more than one assignment.

Suggested behavior:

- show a short note such as `另有 2 条并立政权记录`
- offer a clear path to the detail screen

Purpose:

- acknowledge ambiguity without cluttering the home screen

### Timeline Controls

First-release controls should stay simple.

Include:

- previous day
- next day
- jump to a civil date

Optional later additions:

- month jump
- year jump
- bookmark current day

## Day Detail Structure

### Civil Date Section

Show:

- full civil date
- `Julian` or `Gregorian`
- a short explanation of the current display rule if needed

### Lunar Date Section

Show:

- lunar year
- lunar month
- lunar day
- leap-month state

### Sexagenary Section

Show:

- year stem-branch
- month stem-branch
- day stem-branch

### Reign-Era Section

Show all assignments for the day.

Each row should include:

- dynasty
- emperor
- reign era
- regnal year in Chinese display form
- optional notes when the source material is ambiguous

Purpose:

- preserve parallel political records instead of forcing a single interpretation

## Interaction Notes

### Browsing Style

The first release should feel lightweight and direct.

- Day-to-day browsing should require one gesture or click.
- The user should not need to choose filters before seeing useful information.
- Detail should be one tap or click away.

### State Model

The UI can start with a single selected day in state.

Suggested state responsibilities:

- selected day index
- loaded summary record for that day
- loaded detail payload for that day when needed

### Empty and Loading States

The app should handle gaps cleanly.

Show explicit messages when:

- data is still importing
- the selected day is outside the supported range
- no reign-era assignment is available for that day

## Accessibility and Clarity

The app should remain readable on both iPhone-sized screens and wider macOS windows.

First-release UI rules:

- prefer clear typographic hierarchy over dense tables
- avoid relying on color alone to distinguish record types
- keep labels explicit for Julian versus Gregorian dates
- make parallel-record counts readable by VoiceOver

## Not in Scope for v1

The first release should not depend on these features:

- advanced search by emperor or reign era
- map views
- dynasty tree visualizations
- side-by-side comparison mode
- user-editable source data

These can be layered in later once the day model and dataset are stable.

## Suggested View Types

Potential shared SwiftUI views:

- `TimelineHomeView`
- `DateHeaderCard`
- `LunarSummaryCard`
- `GanzhiSummaryCard`
- `PrimaryReignCard`
- `ParallelRecordsBanner`
- `DayDetailView`
- `ReignEraAssignmentRow`

## Open Questions

- Should the timeline home screen show one day at a time or a short scrollable list centered on the selected day?
- Should the jump control be free-form date entry or a picker-based interaction in v1?
- Should the primary reign-era selection be manually curated in processed data or derived by app logic?
