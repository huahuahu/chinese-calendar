#!/usr/bin/env node
import { createReadStream, createWriteStream } from "node:fs";
import { mkdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";
import { once } from "node:events";
import { fileURLToPath } from "node:url";

const DEFAULT_START_YEAR = -220;
const DEFAULT_END_YEAR = 2200;
const OUTPUT_FILES = {
  chineseLunarYears: "chinese_lunar_years.jsonl",
  chineseLunarMonths: "chinese_lunar_months.jsonl",
  calendarDaysDirectory: "calendar_days",
  yearlyCalendarDays: "calendar_days.jsonl"
};

const scriptPath = fileURLToPath(import.meta.url);
const scriptDirectory = path.dirname(scriptPath);
const repositoryRoot = path.resolve(scriptDirectory, "../..");

async function main() {
  const options = await parseArguments(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  if (options.startYear > options.endYear) {
    throw new Error("--start-year must be less than or equal to --end-year.");
  }

  if (options.validateOnly) {
    const result = await validateSwiftDataImport(options.output);
    console.log(
      `Validated SwiftData import artifact under ${options.output}: ${result.totalCalendarDays} calendar days, ` +
        `${result.totalCivilDates} civil dates, ${result.totalChineseLunarYears} lunar years, ` +
        `${result.totalChineseLunarMonths} lunar months, ${result.totalChineseLunarDays} lunar days.`
    );
    return;
  }

  const result = await generateSwiftDataImport(options);
  await writeSwiftDataManifest(options, result);

  console.log(
    `Generated SwiftData import artifact under ${options.output}: ${result.totalCalendarDays} calendar days, ` +
      `${result.totalCivilDates} civil dates, ${result.totalChineseLunarYears} lunar years, ` +
      `${result.totalChineseLunarMonths} lunar months, ${result.totalChineseLunarDays} lunar days.`
  );
}

async function parseArguments(argumentsList) {
  const options = {
    input: path.join(repositoryRoot, "Data/Processed/calendar_days"),
    output: path.join(repositoryRoot, "Data/Processed/swiftdata_import"),
    startYear: undefined,
    endYear: undefined,
    validateOnly: false,
    help: false
  };

  for (let index = 0; index < argumentsList.length; index += 1) {
    const argument = argumentsList[index];
    switch (argument) {
      case "--input":
        options.input = resolveRepositoryPath(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--output":
        options.output = resolveRepositoryPath(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--start-year":
        options.startYear = parseIntegerOption(argument, argumentsList[++index]);
        break;
      case "--end-year":
        options.endYear = parseIntegerOption(argument, argumentsList[++index]);
        break;
      case "--validate-only":
        options.validateOnly = true;
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown argument: ${argument}`);
    }
  }

  if (!options.validateOnly && !options.help) {
    const inputManifest = await readInputManifest(options.input);
    options.inputManifest = inputManifest;
    options.startYear ??= inputManifest?.startYear ?? DEFAULT_START_YEAR;
    options.endYear ??= inputManifest?.endYear ?? DEFAULT_END_YEAR;
  } else {
    options.startYear ??= DEFAULT_START_YEAR;
    options.endYear ??= DEFAULT_END_YEAR;
  }

  return options;
}

function parseIntegerOption(name, value) {
  const rawValue = requireOptionValue(name, value);
  const parsedValue = Number.parseInt(rawValue, 10);
  if (!Number.isInteger(parsedValue) || parsedValue.toString() !== rawValue) {
    throw new Error(`${name} must be an integer.`);
  }
  return parsedValue;
}

function requireOptionValue(name, value) {
  if (value === undefined || value.startsWith("--")) {
    throw new Error(`${name} requires a value.`);
  }
  return value;
}

function resolveRepositoryPath(value) {
  return path.isAbsolute(value) ? value : path.resolve(repositoryRoot, value);
}

async function readInputManifest(input) {
  const manifestPath = path.join(input, "manifest.json");
  if (!(await pathExists(manifestPath))) {
    return undefined;
  }
  return JSON.parse(await readFile(manifestPath, "utf8"));
}

function printHelp() {
  console.log(`Usage:
  Scripts/ImportChineseCalendar/generate_swiftdata_import.swift [options]

Options:
  --input <path>            Source calendar_days artifact. Default: Data/Processed/calendar_days
  --output <path>           SwiftData import output directory. Default: Data/Processed/swiftdata_import
  --start-year <year>       First civil year to read. Defaults to input manifest startYear, or ${DEFAULT_START_YEAR}
  --end-year <year>         Last civil year to read. Defaults to input manifest endYear, or ${DEFAULT_END_YEAR}
  --validate-only           Validate an existing SwiftData import artifact without regenerating it.
  --help                    Show this help text.
`);
}

async function generateSwiftDataImport(options) {
  await cleanupGeneratedOutput(options.output);
  await mkdir(options.output, { recursive: true });

  const state = {
    expectedNextDayIndex: undefined,
    previousJulianDayNumber: undefined,
    startDayIndex: undefined,
    endDayIndex: undefined,
    chineseLunarYears: new Map(),
    chineseLunarMonths: new Map(),
    totalCalendarDays: 0,
    totalCivilDates: 0,
    totalChineseLunarDays: 0
  };

  const yearlyOutputRoot = path.join(options.output, OUTPUT_FILES.calendarDaysDirectory);
  await mkdir(yearlyOutputRoot, { recursive: true });

  for (let year = options.startYear; year <= options.endYear; year += 1) {
    const filePath = path.join(options.input, String(year), "calendar_days.jsonl");
    const yearOutputDirectory = path.join(yearlyOutputRoot, String(year));
    await mkdir(yearOutputDirectory, { recursive: true });
    const writer = createWriteStream(path.join(yearOutputDirectory, OUTPUT_FILES.yearlyCalendarDays), {
      encoding: "utf8"
    });

    try {
      await readCalendarDayFile(filePath, async (record) => {
        validateSourceRecord(record, filePath, state);
        collectChineseLunarYear(record, state);
        collectChineseLunarMonth(record, state);

        await writeJsonLine(writer, {
          calendarDay: {
            dayIndex: record.dayIndex,
            julianDayNumber: record.julianDayNumber
          },
          civilDate: {
            dayIndex: record.dayIndex,
            year: record.civil.year,
            month: record.civil.month,
            dayOfMonth: record.civil.dayOfMonth,
            calendarStyle: record.civil.calendarStyle
          },
          chineseLunarDay: {
            dayIndex: record.dayIndex,
            lunarMonthIndex: record.lunarDay.lunarMonthIndex,
            dayNumberInMonth: record.lunarDay.dayNumberInMonth,
            dayStemIndex: record.lunarDay.dayStemIndex,
            dayBranchIndex: record.lunarDay.dayBranchIndex
          }
        });

        state.totalCalendarDays += 1;
        state.totalCivilDates += 1;
        state.totalChineseLunarDays += 1;
      });
    } finally {
      await closeWriters([writer]);
    }
  }

  await writeCollectedChineseLunarYears(options.output, state.chineseLunarYears);
  await writeCollectedChineseLunarMonths(options.output, state.chineseLunarMonths);

  return {
    totalCalendarDays: state.totalCalendarDays,
    totalCivilDates: state.totalCivilDates,
    totalChineseLunarYears: state.chineseLunarYears.size,
    totalChineseLunarMonths: state.chineseLunarMonths.size,
    totalChineseLunarDays: state.totalChineseLunarDays,
    startDayIndex: state.startDayIndex,
    endDayIndex: state.endDayIndex,
    inputManifest: options.inputManifest
  };
}

async function cleanupGeneratedOutput(output) {
  await rm(path.join(output, OUTPUT_FILES.calendarDaysDirectory), { recursive: true, force: true });
  await rm(path.join(output, OUTPUT_FILES.chineseLunarYears), { force: true });
  await rm(path.join(output, OUTPUT_FILES.chineseLunarMonths), { force: true });
  await rm(path.join(output, "calendar_days.jsonl"), { force: true });
  await rm(path.join(output, "civil_dates.jsonl"), { force: true });
  await rm(path.join(output, "chinese_lunar_days.jsonl"), { force: true });
  await rm(path.join(output, "manifest.json"), { force: true });
}

async function readCalendarDayFile(filePath, onRecord) {
  const stream = createReadStream(filePath, { encoding: "utf8" });
  const lines = readline.createInterface({ input: stream, crlfDelay: Infinity });
  let lineNumber = 0;
  let recordCount = 0;

  try {
    for await (const line of lines) {
      lineNumber += 1;
      if (line.trim().length === 0) {
        continue;
      }
      let record;
      try {
        record = JSON.parse(line);
      } catch (error) {
        throw new Error(`Invalid JSON in ${filePath}:${lineNumber}: ${error.message}`);
      }
      await onRecord(record);
      recordCount += 1;
    }
  } catch (error) {
    stream.destroy();
    throw error;
  }

  if (recordCount === 0) {
    throw new Error(`No calendar-day rows found in ${filePath}.`);
  }
}

function validateSourceRecord(record, filePath, state) {
  requireInteger(record.dayIndex, "dayIndex", filePath);
  requireInteger(record.julianDayNumber, "julianDayNumber", filePath);
  requireObject(record.civil, "civil", filePath);
  requireObject(record.lunarYear, "lunarYear", filePath);
  requireObject(record.lunarMonth, "lunarMonth", filePath);
  requireObject(record.lunarDay, "lunarDay", filePath);

  if (state.expectedNextDayIndex === undefined) {
    state.expectedNextDayIndex = record.dayIndex;
  }
  if (record.dayIndex !== state.expectedNextDayIndex) {
    throw new Error(`dayIndex is not continuous at ${filePath}: ${record.dayIndex}.`);
  }
  state.expectedNextDayIndex += 1;

  if (
    state.previousJulianDayNumber !== undefined &&
    record.julianDayNumber !== state.previousJulianDayNumber + 1
  ) {
    throw new Error(`julianDayNumber is not continuous at dayIndex ${record.dayIndex}.`);
  }
  state.previousJulianDayNumber = record.julianDayNumber;

  state.startDayIndex ??= record.dayIndex;
  state.endDayIndex = record.dayIndex;

  for (const [name, value] of [
    ["civil.year", record.civil.year],
    ["civil.month", record.civil.month],
    ["civil.dayOfMonth", record.civil.dayOfMonth],
    ["lunarYear.yearNumber", record.lunarYear.yearNumber],
    ["lunarYear.yearStemIndex", record.lunarYear.yearStemIndex],
    ["lunarYear.yearBranchIndex", record.lunarYear.yearBranchIndex],
    ["lunarMonth.lunarMonthIndex", record.lunarMonth.lunarMonthIndex],
    ["lunarMonth.yearNumber", record.lunarMonth.yearNumber],
    ["lunarMonth.monthNumberInYear", record.lunarMonth.monthNumberInYear],
    ["lunarMonth.dayCount", record.lunarMonth.dayCount],
    ["lunarMonth.monthStemIndex", record.lunarMonth.monthStemIndex],
    ["lunarMonth.monthBranchIndex", record.lunarMonth.monthBranchIndex],
    ["lunarDay.lunarMonthIndex", record.lunarDay.lunarMonthIndex],
    ["lunarDay.dayNumberInMonth", record.lunarDay.dayNumberInMonth],
    ["lunarDay.dayStemIndex", record.lunarDay.dayStemIndex],
    ["lunarDay.dayBranchIndex", record.lunarDay.dayBranchIndex]
  ]) {
    requireInteger(value, name, filePath);
  }

  if (record.civil.calendarStyle !== "julian" && record.civil.calendarStyle !== "gregorian") {
    throw new Error(`Invalid civil.calendarStyle at dayIndex ${record.dayIndex}.`);
  }
  if (record.civil.month < 1 || record.civil.month > 12) {
    throw new Error(`Invalid civil.month at dayIndex ${record.dayIndex}.`);
  }
  if (record.civil.dayOfMonth < 1 || record.civil.dayOfMonth > 31) {
    throw new Error(`Invalid civil.dayOfMonth at dayIndex ${record.dayIndex}.`);
  }
  if (record.lunarMonth.monthNumberInYear < 1 || record.lunarMonth.monthNumberInYear > 12) {
    throw new Error(`Invalid lunarMonth.monthNumberInYear at dayIndex ${record.dayIndex}.`);
  }
  if (record.lunarMonth.dayCount !== 29 && record.lunarMonth.dayCount !== 30) {
    throw new Error(`Invalid lunarMonth.dayCount at dayIndex ${record.dayIndex}.`);
  }
  if (record.lunarDay.dayNumberInMonth < 1 || record.lunarDay.dayNumberInMonth > 30) {
    throw new Error(`Invalid lunarDay.dayNumberInMonth at dayIndex ${record.dayIndex}.`);
  }
  if (record.lunarDay.dayNumberInMonth > record.lunarMonth.dayCount) {
    throw new Error(`lunarDay.dayNumberInMonth exceeds dayCount at dayIndex ${record.dayIndex}.`);
  }
  if (record.lunarMonth.lunarMonthIndex !== record.lunarDay.lunarMonthIndex) {
    throw new Error(`Mismatched lunarMonthIndex at dayIndex ${record.dayIndex}.`);
  }
  if (record.lunarYear.yearNumber !== record.lunarMonth.yearNumber) {
    throw new Error(`Mismatched lunar year number at dayIndex ${record.dayIndex}.`);
  }
  if (typeof record.lunarMonth.isLeapMonth !== "boolean") {
    throw new Error(`lunarMonth.isLeapMonth must be boolean at dayIndex ${record.dayIndex}.`);
  }

  validateStemBranch("year", record.lunarYear.yearStemIndex, record.lunarYear.yearBranchIndex, record.dayIndex);
  validateStemBranch("month", record.lunarMonth.monthStemIndex, record.lunarMonth.monthBranchIndex, record.dayIndex);
  validateStemBranch("day", record.lunarDay.dayStemIndex, record.lunarDay.dayBranchIndex, record.dayIndex);
}

function validateStemBranch(kind, stemIndex, branchIndex, dayIndex) {
  if (stemIndex < 0 || stemIndex > 9) {
    throw new Error(`${kind} stem index is out of range at dayIndex ${dayIndex}.`);
  }
  if (branchIndex < 0 || branchIndex > 11) {
    throw new Error(`${kind} branch index is out of range at dayIndex ${dayIndex}.`);
  }
}

function requireObject(value, name, filePath) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${name} must be an object in ${filePath}.`);
  }
}

function requireInteger(value, name, filePath) {
  if (!Number.isInteger(value)) {
    throw new Error(`${name} must be an integer in ${filePath}.`);
  }
}

function collectChineseLunarYear(record, state) {
  const yearRecord = {
    lunarYearNumber: record.lunarYear.yearNumber,
    yearStemIndex: record.lunarYear.yearStemIndex,
    yearBranchIndex: record.lunarYear.yearBranchIndex
  };
  const existing = state.chineseLunarYears.get(yearRecord.lunarYearNumber);
  if (existing === undefined) {
    state.chineseLunarYears.set(yearRecord.lunarYearNumber, yearRecord);
    return;
  }
  assertSameRecord(existing, yearRecord, "ChineseLunarYear", yearRecord.lunarYearNumber);
}

function collectChineseLunarMonth(record, state) {
  const monthRecord = {
    lunarMonthIndex: record.lunarMonth.lunarMonthIndex,
    lunarYearNumber: record.lunarMonth.yearNumber,
    monthNumberInYear: record.lunarMonth.monthNumberInYear,
    isLeapMonth: record.lunarMonth.isLeapMonth,
    dayCount: record.lunarMonth.dayCount,
    monthStemIndex: record.lunarMonth.monthStemIndex,
    monthBranchIndex: record.lunarMonth.monthBranchIndex
  };
  const existing = state.chineseLunarMonths.get(monthRecord.lunarMonthIndex);
  if (existing === undefined) {
    state.chineseLunarMonths.set(monthRecord.lunarMonthIndex, monthRecord);
    return;
  }
  assertSameRecord(existing, monthRecord, "ChineseLunarMonth", monthRecord.lunarMonthIndex);
}

function assertSameRecord(existing, incoming, modelName, key) {
  for (const [name, value] of Object.entries(incoming)) {
    if (existing[name] !== value) {
      throw new Error(`Conflicting ${modelName} metadata for ${key}: ${name}.`);
    }
  }
}

async function writeCollectedChineseLunarYears(output, chineseLunarYears) {
  const writer = createWriteStream(path.join(output, OUTPUT_FILES.chineseLunarYears), { encoding: "utf8" });
  try {
    const records = [...chineseLunarYears.values()].sort((left, right) => left.lunarYearNumber - right.lunarYearNumber);
    for (const record of records) {
      await writeJsonLine(writer, record);
    }
  } finally {
    await closeWriters([writer]);
  }
}

async function writeCollectedChineseLunarMonths(output, chineseLunarMonths) {
  const writer = createWriteStream(path.join(output, OUTPUT_FILES.chineseLunarMonths), { encoding: "utf8" });
  try {
    const records = [...chineseLunarMonths.values()].sort((left, right) => left.lunarMonthIndex - right.lunarMonthIndex);
    for (const record of records) {
      await writeJsonLine(writer, record);
    }
  } finally {
    await closeWriters([writer]);
  }
}

async function writeJsonLine(writer, payload) {
  if (!writer.write(`${JSON.stringify(payload)}\n`, "utf8")) {
    await once(writer, "drain");
  }
}

async function closeWriters(writers) {
  await Promise.all(
    writers.map(
      (writer) =>
        new Promise((resolve, reject) => {
          if (writer.closed) {
            resolve();
            return;
          }
          writer.once("error", reject);
          writer.end(resolve);
        })
    )
  );
}

async function writeSwiftDataManifest(options, result) {
  const manifest = {
    artifact: "swiftdata_import",
    generatedAt: new Date().toISOString(),
    generator: "Scripts/ImportChineseCalendar/generate_swiftdata_import.swift",
    sourceArtifact: options.inputManifest?.artifact ?? "calendar_days",
    sourceInput: options.input,
    sourceGenerator: options.inputManifest?.generator,
    sourceUpstreamRepository: options.inputManifest?.upstreamRepository,
    sourceUpstreamCommit: options.inputManifest?.upstreamCommit,
    startYear: options.startYear,
    endYear: options.endYear,
    startDayIndex: result.startDayIndex,
    endDayIndex: result.endDayIndex,
    totalCalendarDays: result.totalCalendarDays,
    totalCivilDates: result.totalCivilDates,
    totalChineseLunarYears: result.totalChineseLunarYears,
    totalChineseLunarMonths: result.totalChineseLunarMonths,
    totalChineseLunarDays: result.totalChineseLunarDays,
    files: {
      ChineseLunarYear: OUTPUT_FILES.chineseLunarYears,
      ChineseLunarMonth: OUTPUT_FILES.chineseLunarMonths,
      CalendarDayBundleByCivilYear: `${OUTPUT_FILES.calendarDaysDirectory}/<year>/${OUTPUT_FILES.yearlyCalendarDays}`
    },
    importOrder: [
      "ChineseLunarYear",
      "ChineseLunarMonth",
      "CalendarDayBundleByCivilYear"
    ],
    dayBundleModels: ["CalendarDay", "CivilDate", "ChineseLunarDay"],
    relationshipKeys: {
      "ChineseLunarMonth.chineseLunarYear": "ChineseLunarMonth.lunarYearNumber -> ChineseLunarYear.lunarYearNumber",
      "CivilDate.calendarDay": "calendarDay.dayIndex -> civilDate.dayIndex",
      "ChineseLunarDay.calendarDay": "calendarDay.dayIndex -> chineseLunarDay.dayIndex",
      "ChineseLunarDay.chineseLunarMonth": "chineseLunarDay.lunarMonthIndex -> ChineseLunarMonth.lunarMonthIndex"
    }
  };
  await writeFile(path.join(options.output, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
}

async function validateSwiftDataImport(output) {
  const manifestPath = path.join(output, "manifest.json");
  const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  const years = new Set();
  const months = new Set();
  const calendarDays = new Set();
  const result = {
    totalCalendarDays: 0,
    totalCivilDates: 0,
    totalChineseLunarYears: 0,
    totalChineseLunarMonths: 0,
    totalChineseLunarDays: 0
  };

  await readJsonl(path.join(output, manifest.files.ChineseLunarYear), (record) => {
    requireInteger(record.lunarYearNumber, "lunarYearNumber", manifest.files.ChineseLunarYear);
    if (years.has(record.lunarYearNumber)) {
      throw new Error(`Duplicate ChineseLunarYear ${record.lunarYearNumber}.`);
    }
    years.add(record.lunarYearNumber);
    result.totalChineseLunarYears += 1;
  });

  await readJsonl(path.join(output, manifest.files.ChineseLunarMonth), (record) => {
    requireInteger(record.lunarMonthIndex, "lunarMonthIndex", manifest.files.ChineseLunarMonth);
    requireInteger(record.lunarYearNumber, "lunarYearNumber", manifest.files.ChineseLunarMonth);
    if (months.has(record.lunarMonthIndex)) {
      throw new Error(`Duplicate ChineseLunarMonth ${record.lunarMonthIndex}.`);
    }
    if (!years.has(record.lunarYearNumber)) {
      throw new Error(`Missing ChineseLunarYear ${record.lunarYearNumber}.`);
    }
    months.add(record.lunarMonthIndex);
    result.totalChineseLunarMonths += 1;
  });

  let expectedDayIndex = manifest.startDayIndex;
  let previousJulianDayNumber;
  for (let year = manifest.startYear; year <= manifest.endYear; year += 1) {
    const filePath = path.join(output, OUTPUT_FILES.calendarDaysDirectory, String(year), OUTPUT_FILES.yearlyCalendarDays);
    await readJsonl(filePath, (record) => {
      validateDayBundleRecord(record, filePath, year);
      const dayIndex = record.calendarDay.dayIndex;

      if (dayIndex !== expectedDayIndex) {
        throw new Error(`CalendarDay dayIndex is not continuous at ${filePath}: ${dayIndex}.`);
      }
      expectedDayIndex += 1;

      if (
        previousJulianDayNumber !== undefined &&
        record.calendarDay.julianDayNumber !== previousJulianDayNumber + 1
      ) {
        throw new Error(`julianDayNumber is not continuous at dayIndex ${dayIndex}.`);
      }
      previousJulianDayNumber = record.calendarDay.julianDayNumber;

      if (calendarDays.has(dayIndex)) {
        throw new Error(`Duplicate CalendarDay ${dayIndex}.`);
      }
      if (!months.has(record.chineseLunarDay.lunarMonthIndex)) {
        throw new Error(`Missing ChineseLunarMonth ${record.chineseLunarDay.lunarMonthIndex}.`);
      }

      calendarDays.add(dayIndex);
      result.totalCalendarDays += 1;
      result.totalCivilDates += 1;
      result.totalChineseLunarDays += 1;
    });
  }

  for (const [name, actual] of [
    ["totalCalendarDays", result.totalCalendarDays],
    ["totalCivilDates", result.totalCivilDates],
    ["totalChineseLunarYears", result.totalChineseLunarYears],
    ["totalChineseLunarMonths", result.totalChineseLunarMonths],
    ["totalChineseLunarDays", result.totalChineseLunarDays]
  ]) {
    if (manifest[name] !== actual) {
      throw new Error(`Manifest ${name} ${manifest[name]} does not match actual count ${actual}.`);
    }
  }

  return result;
}

function validateDayBundleRecord(record, filePath, civilYear) {
  requireObject(record.calendarDay, "calendarDay", filePath);
  requireObject(record.civilDate, "civilDate", filePath);
  requireObject(record.chineseLunarDay, "chineseLunarDay", filePath);

  requireInteger(record.calendarDay.dayIndex, "calendarDay.dayIndex", filePath);
  requireInteger(record.calendarDay.julianDayNumber, "calendarDay.julianDayNumber", filePath);
  requireInteger(record.civilDate.dayIndex, "civilDate.dayIndex", filePath);
  requireInteger(record.civilDate.year, "civilDate.year", filePath);
  requireInteger(record.civilDate.month, "civilDate.month", filePath);
  requireInteger(record.civilDate.dayOfMonth, "civilDate.dayOfMonth", filePath);
  requireInteger(record.chineseLunarDay.dayIndex, "chineseLunarDay.dayIndex", filePath);
  requireInteger(record.chineseLunarDay.lunarMonthIndex, "chineseLunarDay.lunarMonthIndex", filePath);
  requireInteger(record.chineseLunarDay.dayNumberInMonth, "chineseLunarDay.dayNumberInMonth", filePath);
  requireInteger(record.chineseLunarDay.dayStemIndex, "chineseLunarDay.dayStemIndex", filePath);
  requireInteger(record.chineseLunarDay.dayBranchIndex, "chineseLunarDay.dayBranchIndex", filePath);

  const dayIndex = record.calendarDay.dayIndex;
  if (record.civilDate.dayIndex !== dayIndex || record.chineseLunarDay.dayIndex !== dayIndex) {
    throw new Error(`Mismatched dayIndex in day bundle at ${filePath}: ${dayIndex}.`);
  }
  if (record.civilDate.year !== civilYear) {
    throw new Error(`civilDate.year does not match yearly directory at dayIndex ${dayIndex}.`);
  }
  if (record.civilDate.calendarStyle !== "julian" && record.civilDate.calendarStyle !== "gregorian") {
    throw new Error(`Invalid civilDate.calendarStyle at dayIndex ${dayIndex}.`);
  }
  if (record.civilDate.month < 1 || record.civilDate.month > 12) {
    throw new Error(`Invalid civilDate.month at dayIndex ${dayIndex}.`);
  }
  if (record.civilDate.dayOfMonth < 1 || record.civilDate.dayOfMonth > 31) {
    throw new Error(`Invalid civilDate.dayOfMonth at dayIndex ${dayIndex}.`);
  }
  if (record.chineseLunarDay.dayNumberInMonth < 1 || record.chineseLunarDay.dayNumberInMonth > 30) {
    throw new Error(`Invalid chineseLunarDay.dayNumberInMonth at dayIndex ${dayIndex}.`);
  }
  validateStemBranch(
    "day",
    record.chineseLunarDay.dayStemIndex,
    record.chineseLunarDay.dayBranchIndex,
    dayIndex
  );
}

async function readJsonl(filePath, onRecord) {
  const stream = createReadStream(filePath, { encoding: "utf8" });
  const lines = readline.createInterface({ input: stream, crlfDelay: Infinity });
  let lineNumber = 0;
  for await (const line of lines) {
    lineNumber += 1;
    if (line.trim().length === 0) {
      continue;
    }
    let record;
    try {
      record = JSON.parse(line);
    } catch (error) {
      throw new Error(`Invalid JSON in ${filePath}:${lineNumber}: ${error.message}`);
    }
    onRecord(record);
  }
}

async function pathExists(targetPath) {
  try {
    await stat(targetPath);
    return true;
  } catch (error) {
    if (error.code === "ENOENT") {
      return false;
    }
    throw error;
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
