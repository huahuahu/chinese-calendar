#!/usr/bin/env node
import { mkdir, readFile, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const UPSTREAM_REPOSITORY = "https://github.com/ytliu0/ChineseCalendar";
const UPSTREAM_COMMIT = "d6aae82b63b79a6f8659ea3e064024b7d8ac3077";
const UPSTREAM_RAW_BASE = `https://raw.githubusercontent.com/ytliu0/ChineseCalendar/${UPSTREAM_COMMIT}/src`;
const UPSTREAM_API_BASE = "https://api.github.com/repos/ytliu0/ChineseCalendar/contents/src";
const DEFAULT_START_YEAR = -220;
const DEFAULT_END_YEAR = 2200;

// 生成器默认只覆盖上游 default calendar 路径稳定的区间。
// -721...-221 需要显式选择古历 variant，v1 先不在脚本里隐式决定。
const LUNAR_MONTH_LENGTH_EXCEPTIONS = new Map([
  [
    1807637,
    {
      source: "ytliu0/ChineseCalendar",
      reason:
        "Wei Mingdi changed the month numbering in 237 CE; upstream default data contains a 28-day month segment before the reordered month 1.",
      expectedGeneratedDayCount: 28
    }
  ]
]);
const REQUIRED_UPSTREAM_FILES = [
  "utilities.js",
  "decompressSunMoonData.js",
  "calendarData.js",
  "eclipse_linksM722-2202.js",
  "ancientCalendars.js",
  "calendar.js"
];

const scriptPath = fileURLToPath(import.meta.url);
const scriptDirectory = path.dirname(scriptPath);
const repositoryRoot = path.resolve(scriptDirectory, "../..");

async function main() {
  // 所有路径参数都在解析阶段转成绝对路径，避免从不同目录执行脚本时写错位置。
  const options = parseArguments(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  if (options.startYear < DEFAULT_START_YEAR || options.endYear > DEFAULT_END_YEAR) {
    throw new Error(`Supported v1 range is ${DEFAULT_START_YEAR}...${DEFAULT_END_YEAR}.`);
  }
  if (options.startYear > options.endYear) {
    throw new Error("--start-year must be less than or equal to --end-year.");
  }

  if (options.validateOnly) {
    // validate-only 只读已生成的 JSONL，适合 CI 或快速确认大文件没有被改坏。
    const result = await validateExistingOutput(options.output, options);
    console.log(
      `Validated ${result.totalDays} days in ${result.totalYears} yearly JSONL files under ${options.output}`
    );
    console.log(`Validated ${result.totalLunarMonths} lunar months and ${result.totalLunarYears} lunar years.`);
    return;
  }

  await ensureUpstreamSources(options.rawSource, options.forceRefresh);
  const upstream = await loadUpstream(options.rawSource);
  const result = await generateCalendarDays(upstream, options);
  await writeProcessedManifest(options.output, options, result);

  console.log(
    `Generated ${result.totalDays} days in ${result.totalYears} yearly JSONL files under ${options.output}`
  );
  console.log(`Validated ${result.totalLunarMonths} lunar months and ${result.totalLunarYears} lunar years.`);
}

function parseArguments(argumentsList) {
  const options = {
    startYear: DEFAULT_START_YEAR,
    endYear: DEFAULT_END_YEAR,
    rawSource: path.join(repositoryRoot, "Data/Raw/ChineseCalendar"),
    output: path.join(repositoryRoot, "Data/Processed/calendar_days"),
    forceRefresh: false,
    validateOnly: false,
    help: false
  };

  for (let index = 0; index < argumentsList.length; index += 1) {
    const argument = argumentsList[index];
    switch (argument) {
      case "--start-year":
        options.startYear = parseIntegerOption(argument, argumentsList[++index]);
        break;
      case "--end-year":
        options.endYear = parseIntegerOption(argument, argumentsList[++index]);
        break;
      case "--raw-source":
        options.rawSource = resolveRepositoryPath(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--output":
        options.output = resolveRepositoryPath(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--force-refresh":
        options.forceRefresh = true;
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

function printHelp() {
  console.log(`Usage:
  Scripts/ImportChineseCalendar/generate_calendar_days.swift [options]

Options:
  --start-year <year>       First civil year to generate. Default: ${DEFAULT_START_YEAR}
  --end-year <year>         Last civil year to generate. Default: ${DEFAULT_END_YEAR}
  --raw-source <path>       Upstream source cache. Default: Data/Raw/ChineseCalendar
  --output <path>           Processed output directory. Default: Data/Processed/calendar_days
  --force-refresh           Re-fetch pinned upstream files even when cached.
  --validate-only           Validate existing yearly JSONL files without regenerating them.
  --help                    Show this help text.
`);
}

async function ensureUpstreamSources(rawSource, forceRefresh) {
  await mkdir(rawSource, { recursive: true });

  // 固定读取上游 commit 的源码文件，保证重新生成时不会被 upstream main 分支漂移影响。
  for (const fileName of REQUIRED_UPSTREAM_FILES) {
    const targetPath = path.join(rawSource, fileName);
    if (!forceRefresh && (await pathExists(targetPath))) {
      continue;
    }
    await writeFile(targetPath, await fetchUpstreamFile(fileName), "utf8");
  }

  const manifest = {
    upstreamRepository: UPSTREAM_REPOSITORY,
    upstreamCommit: UPSTREAM_COMMIT,
    files: REQUIRED_UPSTREAM_FILES,
    fetchedAt: new Date().toISOString()
  };
  await writeFile(path.join(rawSource, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
}

async function fetchUpstreamFile(fileName) {
  const rawUrl = `${UPSTREAM_RAW_BASE}/${fileName}`;
  try {
    const rawResponse = await fetch(rawUrl, { signal: AbortSignal.timeout(60_000) });
    if (rawResponse.ok) {
      return await rawResponse.text();
    }
  } catch {
    // raw.githubusercontent.com 偶尔不稳定；失败时再走 GitHub API 的 base64 内容接口。
  }

  const apiUrl = `${UPSTREAM_API_BASE}/${fileName}?ref=${UPSTREAM_COMMIT}`;
  const apiResponse = await fetch(apiUrl, {
    headers: { Accept: "application/vnd.github+json" },
    signal: AbortSignal.timeout(120_000)
  });
  if (!apiResponse.ok) {
    throw new Error(`Failed to fetch ${fileName}: HTTP ${apiResponse.status}`);
  }
  const payload = await apiResponse.json();
  if (payload.encoding !== "base64" || typeof payload.content !== "string") {
    throw new Error(`Unexpected GitHub API payload for ${fileName}.`);
  }
  return Buffer.from(payload.content, "base64").toString("utf8");
}

async function loadUpstream(rawSource) {
  // 上游是浏览器 JS。这里用 vm 提供最小 DOM stub，让 calDataYear 等函数可在命令行复用。
  const context = {
    console,
    Math,
    alert(message) {
      throw new Error(String(message));
    },
    document: {
      getElementById() {
        return { checked: false, classList: { contains: () => false } };
      }
    }
  };
  vm.createContext(context);

  for (const fileName of REQUIRED_UPSTREAM_FILES) {
    const source = await readFile(path.join(rawSource, fileName), "utf8");
    vm.runInContext(source, context, { filename: fileName });
  }

  for (const functionName of ["calDataYear", "NdaysGregJul", "getJD"]) {
    if (typeof context[functionName] !== "function") {
      throw new Error(`Upstream function ${functionName} was not loaded.`);
    }
  }

  return context;
}

async function generateCalendarDays(upstream, options) {
  await mkdir(options.output, { recursive: true });

  // 这些计数器跨年份递增，确保 dayIndex 和 lunarMonthIndex 在整个数据集中连续。
  const state = {
    nextDayIndex: 0,
    nextLunarMonthIndex: 0,
    previousJulianDayNumber: undefined,
    lunarMonthsByStartJDN: new Map(),
    lunarMonthsByIndex: new Map(),
    lunarYears: new Map(),
    totalYears: 0,
    totalDays: 0
  };

  for (let year = options.startYear; year <= options.endYear; year += 1) {
    // 等价调用上游网页默认区域的 calDataYear(y, langVars) 路径。
    const calVars = upstream.calDataYear(year, { region: "default", li_ancient: null });
    const lines = [];

    for (let zeroBasedMonth = 0; zeroBasedMonth < 12; zeroBasedMonth += 1) {
      const civilMonth = zeroBasedMonth + 1;
      const daySlots = calVars.mday[zeroBasedMonth + 1] - calVars.mday[zeroBasedMonth];

      for (let daySlot = 1; daySlot <= daySlots; daySlot += 1) {
        // 1582 年 10 月有 Gregorian reform 跳日，daySlot 是连续槽位，dayOfMonth 是实际 civil 日号。
        const dayOfMonth = civilDayOfMonth(year, civilMonth, daySlot);
        const dayOffset = calVars.mday[zeroBasedMonth] + daySlot;
        const julianDayNumber = calVars.jd0 + dayOffset + 1;

        if (
          state.previousJulianDayNumber !== undefined &&
          julianDayNumber !== state.previousJulianDayNumber + 1
        ) {
          throw new Error(`julianDayNumber is not continuous at ${year}-${civilMonth}-${dayOfMonth}.`);
        }
        state.previousJulianDayNumber = julianDayNumber;

        const lunarMonth = resolveLunarMonth(calVars, year, dayOffset, julianDayNumber, state);
        const lunarYearNumber = lunarMonth.yearNumber;
        const record = {
          dayIndex: state.nextDayIndex,
          julianDayNumber,
          civil: {
            year,
            month: civilMonth,
            dayOfMonth,
            calendarStyle: civilCalendarStyle(year, civilMonth, dayOfMonth)
          },
          lunarYear: {
            yearNumber: lunarYearNumber,
            yearStemIndex: positiveModulo(lunarYearNumber + 726, 10),
            yearBranchIndex: positiveModulo(lunarYearNumber + 728, 12)
          },
          lunarMonth: {
            lunarMonthIndex: lunarMonth.lunarMonthIndex,
            yearNumber: lunarYearNumber,
            monthNumberInYear: lunarMonth.monthNumberInYear,
            isLeapMonth: lunarMonth.isLeapMonth,
            monthStemIndex: lunarMonth.monthStemIndex,
            monthBranchIndex: lunarMonth.monthBranchIndex
          },
          lunarDay: {
            lunarMonthIndex: lunarMonth.lunarMonthIndex,
            dayNumberInMonth: julianDayNumber - lunarMonth.startJulianDayNumber + 1,
            dayStemIndex: positiveModulo(julianDayNumber - 1, 10),
            dayBranchIndex: positiveModulo(julianDayNumber + 1, 12)
          }
        };

        validateRecord(record);
        lunarMonth.generatedDayCount += 1;
        lines.push(JSON.stringify(record));
        state.nextDayIndex += 1;
        state.totalDays += 1;
      }
    }

    const yearOutputDirectory = path.join(options.output, String(year));
    await mkdir(yearOutputDirectory, { recursive: true });
    await writeFile(path.join(yearOutputDirectory, "calendar_days.jsonl"), `${lines.join("\n")}\n`, "utf8");
    state.totalYears += 1;
  }

  validateGeneratedState(state);
  return {
    totalDays: state.totalDays,
    totalYears: state.totalYears,
    totalLunarMonths: state.lunarMonthsByIndex.size,
    totalLunarYears: state.lunarYears.size
  };
}

function resolveLunarMonth(calVars, civilYear, dayOffset, julianDayNumber, state) {
  // cmonthDate/cmonthNum 是上游按农历月边界给出的数组；先定位当天属于哪个农历月。
  const monthPosition = findLunarMonthPosition(calVars, dayOffset);
  const startDayOffset = calVars.cmonthDate[monthPosition];
  const startJulianDayNumber = calVars.jd0 + startDayOffset + 1;
  const rawMonthNumber = calVars.cmonthNum[monthPosition];
  const rawJian = calVars.cmonthJian[monthPosition];
  const sourceMonthLength = calVars.cmonthLong[monthPosition] === 1 ? 30 : 29;
  const yearNumber = civilYear + calVars.cmonthYear[monthPosition] - 1;
  const monthNumberInYear = Math.abs(rawMonthNumber);
  const isLeapMonth = rawMonthNumber < 0;
  const jian = Math.abs(rawJian);
  const monthStemIndex = positiveModulo(
    12 * (positiveModulo(civilYear + 725, 10) + calVars.cmonthXiaYear[monthPosition]) + jian + 1,
    10
  );
  const monthBranchIndex = positiveModulo(jian + 1, 12);

  let lunarMonth = state.lunarMonthsByStartJDN.get(startJulianDayNumber);
  if (lunarMonth === undefined) {
    // 同一个农历月可能跨 civil year，只在第一次遇到它时分配新的全局 lunarMonthIndex。
    lunarMonth = {
      lunarMonthIndex: state.nextLunarMonthIndex,
      startJulianDayNumber,
      sourceMonthLength,
      yearNumber,
      monthNumberInYear,
      isLeapMonth,
      monthStemIndex,
      monthBranchIndex,
      generatedDayCount: 0
    };
    state.lunarMonthsByStartJDN.set(startJulianDayNumber, lunarMonth);
    state.lunarMonthsByIndex.set(lunarMonth.lunarMonthIndex, lunarMonth);
    state.nextLunarMonthIndex += 1;
  } else {
    assertSameLunarMonth(lunarMonth, {
      sourceMonthLength,
      yearNumber,
      monthNumberInYear,
      isLeapMonth,
      monthStemIndex,
      monthBranchIndex
    });
  }

  if (!state.lunarYears.has(yearNumber)) {
    state.lunarYears.set(yearNumber, new Set());
  }
  state.lunarYears.get(yearNumber).add(lunarMonth.lunarMonthIndex);

  const lunarDayNumber = julianDayNumber - lunarMonth.startJulianDayNumber + 1;
  if (lunarDayNumber < 1 || lunarDayNumber > sourceMonthLength) {
    throw new Error(`Invalid lunar day ${lunarDayNumber} for JDN ${julianDayNumber}.`);
  }

  return lunarMonth;
}

function findLunarMonthPosition(calVars, dayOffset) {
  for (let index = 0; index < calVars.cmonthDate.length - 1; index += 1) {
    if (dayOffset >= calVars.cmonthDate[index] && dayOffset < calVars.cmonthDate[index + 1]) {
      return index;
    }
  }
  return calVars.cmonthDate.length - 1;
}

function assertSameLunarMonth(existing, incoming) {
  for (const key of [
    "sourceMonthLength",
    "yearNumber",
    "monthNumberInYear",
    "isLeapMonth",
    "monthStemIndex",
    "monthBranchIndex"
  ]) {
    if (existing[key] !== incoming[key]) {
      throw new Error(`Conflicting lunar month metadata for start JDN ${existing.startJulianDayNumber}: ${key}`);
    }
  }
}

function civilDayOfMonth(year, month, daySlot) {
  // 上游的 mday 已经跳过 1582-10-05...1582-10-14；这里把连续槽位还原成显示日号。
  if (year === 1582 && month === 10 && daySlot >= 5) {
    return daySlot + 10;
  }
  return daySlot;
}

function civilCalendarStyle(year, month, dayOfMonth) {
  // 项目 v1 采用统一 reform boundary：1582-10-15 起使用 Gregorian，之前使用 Julian。
  if (year > 1582) {
    return "gregorian";
  }
  if (year < 1582) {
    return "julian";
  }
  if (month > 10 || (month === 10 && dayOfMonth >= 15)) {
    return "gregorian";
  }
  return "julian";
}

function validateRecord(record) {
  if (!Number.isInteger(record.dayIndex) || record.dayIndex < 0) {
    throw new Error("dayIndex must be a non-negative integer.");
  }
  if (!Number.isInteger(record.julianDayNumber)) {
    throw new Error(`julianDayNumber must be an integer at dayIndex ${record.dayIndex}.`);
  }
  if (record.lunarDay.dayNumberInMonth < 1 || record.lunarDay.dayNumberInMonth > 30) {
    throw new Error(`Invalid lunar day number at dayIndex ${record.dayIndex}.`);
  }
  for (const [name, value] of [
    ["yearStemIndex", record.lunarYear.yearStemIndex],
    ["monthStemIndex", record.lunarMonth.monthStemIndex],
    ["dayStemIndex", record.lunarDay.dayStemIndex]
  ]) {
    if (value < 0 || value > 9) {
      throw new Error(`${name} is out of range at dayIndex ${record.dayIndex}.`);
    }
  }
  for (const [name, value] of [
    ["yearBranchIndex", record.lunarYear.yearBranchIndex],
    ["monthBranchIndex", record.lunarMonth.monthBranchIndex],
    ["dayBranchIndex", record.lunarDay.dayBranchIndex]
  ]) {
    if (value < 0 || value > 11) {
      throw new Error(`${name} is out of range at dayIndex ${record.dayIndex}.`);
    }
  }
  if (record.lunarMonth.lunarMonthIndex !== record.lunarDay.lunarMonthIndex) {
    throw new Error(`Mismatched lunarMonthIndex at dayIndex ${record.dayIndex}.`);
  }
}

function validateGeneratedState(state) {
  // 跨年校验放在最后做，因为边界农历月可能从上一年延续到下一年。
  for (let index = 0; index < state.nextLunarMonthIndex; index += 1) {
    if (!state.lunarMonthsByIndex.has(index)) {
      throw new Error(`lunarMonthIndex is not continuous at ${index}.`);
    }
  }

  const monthIndexes = [...state.lunarMonthsByIndex.keys()].sort((a, b) => a - b);
  const firstMonthIndex = monthIndexes[0];
  const lastMonthIndex = monthIndexes[monthIndexes.length - 1];
  for (const month of state.lunarMonthsByIndex.values()) {
    const exception = LUNAR_MONTH_LENGTH_EXCEPTIONS.get(month.startJulianDayNumber);
    const hasSourceMonthLength = Number.isInteger(month.sourceMonthLength);
    const isPartialBoundaryMonth =
      month.lunarMonthIndex === firstMonthIndex || month.lunarMonthIndex === lastMonthIndex;

    if (hasSourceMonthLength && month.sourceMonthLength !== 29 && month.sourceMonthLength !== 30) {
      throw new Error(`Source lunar month length is invalid at index ${month.lunarMonthIndex}.`);
    }
    if (hasSourceMonthLength && !isPartialBoundaryMonth && month.generatedDayCount !== month.sourceMonthLength) {
      if (exception?.expectedGeneratedDayCount !== month.generatedDayCount) {
        throw new Error(
          `Generated day count ${month.generatedDayCount} does not match source length ${month.sourceMonthLength} at lunarMonthIndex ${month.lunarMonthIndex}.`
        );
      }
    }
    if (
      !hasSourceMonthLength &&
      !isPartialBoundaryMonth &&
      month.generatedDayCount !== 29 &&
      month.generatedDayCount !== 30 &&
      exception?.expectedGeneratedDayCount !== month.generatedDayCount
    ) {
      throw new Error(`Generated lunar month length is invalid at lunarMonthIndex ${month.lunarMonthIndex}.`);
    }
    if (month.generatedDayCount < 1 || month.generatedDayCount > 30) {
      throw new Error(`Generated day count is invalid at lunarMonthIndex ${month.lunarMonthIndex}.`);
    }
  }

  const yearNumbers = [...state.lunarYears.keys()].sort((a, b) => a - b);
  const firstYearNumber = yearNumbers[0];
  const lastYearNumber = yearNumbers[yearNumbers.length - 1];
  for (const [yearNumber, months] of state.lunarYears) {
    if (yearNumber === firstYearNumber || yearNumber === lastYearNumber) {
      continue;
    }
    if (months.size < 10 || months.size > 15) {
      throw new Error(`Unexpected lunar month count ${months.size} in lunar year ${yearNumber}.`);
    }
    const leapMonthCount = [...months].filter((monthIndex) => state.lunarMonthsByIndex.get(monthIndex).isLeapMonth)
      .length;
    if (leapMonthCount > 1) {
      throw new Error(`More than one leap month in lunar year ${yearNumber}.`);
    }
  }
}

async function writeProcessedManifest(output, options, result) {
  const manifest = {
    artifact: "calendar_days",
    layout: "Data/Processed/calendar_days/<year>/calendar_days.jsonl",
    generatedAt: new Date().toISOString(),
    generator: "Scripts/ImportChineseCalendar/generate_calendar_days.swift",
    upstreamRepository: UPSTREAM_REPOSITORY,
    upstreamCommit: UPSTREAM_COMMIT,
    startYear: options.startYear,
    endYear: options.endYear,
    totalYears: result.totalYears,
    totalDays: result.totalDays,
    totalLunarMonths: result.totalLunarMonths,
    totalLunarYears: result.totalLunarYears,
    validationExceptions: [...LUNAR_MONTH_LENGTH_EXCEPTIONS.entries()].map(([startJulianDayNumber, exception]) => ({
      startJulianDayNumber,
      ...exception
    }))
  };
  await writeFile(path.join(output, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
}

async function validateExistingOutput(output, options) {
  // 重新从 JSONL 推导月、年聚合信息，避免只检查单行字段而漏掉跨行连续性问题。
  const state = {
    nextDayIndex: 0,
    nextLunarMonthIndex: 0,
    previousJulianDayNumber: undefined,
    lunarMonthsByIndex: new Map(),
    lunarYears: new Map(),
    totalYears: 0,
    totalDays: 0
  };

  for (let year = options.startYear; year <= options.endYear; year += 1) {
    const filePath = path.join(output, String(year), "calendar_days.jsonl");
    const content = await readFile(filePath, "utf8");
    const lines = content.trim().split("\n").filter(Boolean);
    if (lines.length === 0) {
      throw new Error(`No calendar-day rows found in ${filePath}.`);
    }

    for (const line of lines) {
      const record = JSON.parse(line);
      validateRecord(record);

      if (record.dayIndex !== state.nextDayIndex) {
        throw new Error(`dayIndex is not continuous at ${filePath}: ${record.dayIndex}.`);
      }
      if (
        state.previousJulianDayNumber !== undefined &&
        record.julianDayNumber !== state.previousJulianDayNumber + 1
      ) {
        throw new Error(`julianDayNumber is not continuous at dayIndex ${record.dayIndex}.`);
      }
      state.previousJulianDayNumber = record.julianDayNumber;

      let month = state.lunarMonthsByIndex.get(record.lunarMonth.lunarMonthIndex);
      if (month === undefined) {
        if (record.lunarMonth.lunarMonthIndex !== state.nextLunarMonthIndex) {
          throw new Error(`lunarMonthIndex is not continuous at ${record.lunarMonth.lunarMonthIndex}.`);
        }
        month = {
          lunarMonthIndex: record.lunarMonth.lunarMonthIndex,
          startJulianDayNumber: record.julianDayNumber - record.lunarDay.dayNumberInMonth + 1,
          sourceMonthLength: undefined,
          yearNumber: record.lunarMonth.yearNumber,
          monthNumberInYear: record.lunarMonth.monthNumberInYear,
          isLeapMonth: record.lunarMonth.isLeapMonth,
          monthStemIndex: record.lunarMonth.monthStemIndex,
          monthBranchIndex: record.lunarMonth.monthBranchIndex,
          generatedDayCount: 0
        };
        state.lunarMonthsByIndex.set(month.lunarMonthIndex, month);
        state.nextLunarMonthIndex += 1;
      } else {
        assertSameLunarMonth(month, {
          sourceMonthLength: month.sourceMonthLength,
          yearNumber: record.lunarMonth.yearNumber,
          monthNumberInYear: record.lunarMonth.monthNumberInYear,
          isLeapMonth: record.lunarMonth.isLeapMonth,
          monthStemIndex: record.lunarMonth.monthStemIndex,
          monthBranchIndex: record.lunarMonth.monthBranchIndex
        });
      }

      if (!state.lunarYears.has(record.lunarMonth.yearNumber)) {
        state.lunarYears.set(record.lunarMonth.yearNumber, new Set());
      }
      state.lunarYears.get(record.lunarMonth.yearNumber).add(record.lunarMonth.lunarMonthIndex);

      month.generatedDayCount += 1;
      state.nextDayIndex += 1;
      state.totalDays += 1;
    }

    state.totalYears += 1;
  }

  validateGeneratedState(state);
  return {
    totalDays: state.totalDays,
    totalYears: state.totalYears,
    totalLunarMonths: state.lunarMonthsByIndex.size,
    totalLunarYears: state.lunarYears.size
  };
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

function positiveModulo(value, modulus) {
  return ((value % modulus) + modulus) % modulus;
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
