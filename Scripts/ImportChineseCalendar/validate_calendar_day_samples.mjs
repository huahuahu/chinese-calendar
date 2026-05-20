#!/usr/bin/env node
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { promisify } from "node:util";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const UPSTREAM_COMMIT = "d6aae82b63b79a6f8659ea3e064024b7d8ac3077";
const GITHUB_PAGES_INDEX_JS = "https://ytliu0.github.io/ChineseCalendar/index_c.js";
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
const execFileAsync = promisify(execFile);

async function main() {
  const options = parseArguments(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  const fixture = JSON.parse(await readFile(options.fixtures, "utf8"));
  if (fixture.calendarSource?.upstreamCommit !== UPSTREAM_COMMIT) {
    throw new Error(`Fixture upstream commit does not match generator commit ${UPSTREAM_COMMIT}.`);
  }

  const pinnedUpstream = await loadPinnedUpstream(options.rawSource);
  const pageUpstream = options.verifyWeb ? await loadGitHubPagesUpstream() : undefined;

  let checked = 0;
  for (const sample of fixture.samples) {
    const generatedRecord = await readGeneratedRecord(options.output, sample.civil);
    const pinnedRecord = recordFromUpstream(pinnedUpstream, sample.civil);

    // 第一层：实际 JSONL 必须等于 fixture 里明确记录的样本期望。
    assertRecordMatchesFixture(sample, generatedRecord);

    // 第二层：同一日期用 pinned upstream JS 重新计算一次，避免 fixture 只是复制了 JSONL。
    assertComparableRecords(sample, generatedRecord, pinnedRecord, "pinned upstream JS");

    // 第三层：可选联网校验 GitHub Pages 当前 index_c.js；它和网页展示使用同一个 bundle。
    if (pageUpstream !== undefined) {
      const pageRecord = recordFromUpstream(pageUpstream, sample.civil);
      assertComparableRecords(sample, generatedRecord, pageRecord, "GitHub Pages index_c.js");
    }

    checked += 1;
  }

  const webText = options.verifyWeb ? "，并已交叉校验 GitHub Pages index_c.js" : "";
  console.log(`已校验 ${checked} 个 calendar-day 样本${webText}。`);
}

function parseArguments(argumentsList) {
  const options = {
    fixtures: path.join(scriptDirectory, "Fixtures/calendar_day_samples.json"),
    rawSource: path.join(repositoryRoot, "Data/Raw/ChineseCalendar"),
    output: path.join(repositoryRoot, "Data/Processed/calendar_days"),
    verifyWeb: false,
    help: false
  };

  for (let index = 0; index < argumentsList.length; index += 1) {
    const argument = argumentsList[index];
    switch (argument) {
      case "--fixtures":
        options.fixtures = resolveRepositoryPath(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--raw-source":
        options.rawSource = resolveRepositoryPath(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--output":
        options.output = resolveRepositoryPath(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--verify-web":
        options.verifyWeb = true;
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
  Scripts/ImportChineseCalendar/validate_calendar_day_samples.swift [options]

Options:
  --fixtures <path>     Historical sample fixture JSON. Default: Scripts/ImportChineseCalendar/Fixtures/calendar_day_samples.json
  --raw-source <path>   Pinned upstream source cache. Default: Data/Raw/ChineseCalendar
  --output <path>       Processed calendar-day output. Default: Data/Processed/calendar_days
  --verify-web          Also fetch and compare against https://ytliu0.github.io/ChineseCalendar/index_c.js
  --help                Show this help text.
`);
}

async function loadPinnedUpstream(rawSource) {
  const context = createUpstreamContext();

  // 使用生成器缓存下来的 pinned upstream 源码，和正式生成路径保持同一套输入。
  for (const fileName of REQUIRED_UPSTREAM_FILES) {
    const source = await readFile(path.join(rawSource, fileName), "utf8");
    vm.runInContext(source, context, { filename: fileName });
  }

  assertUpstreamContext(context, "pinned upstream source");
  return context;
}

async function loadGitHubPagesUpstream() {
  const source = await fetchTextWithCurlFallback(GITHUB_PAGES_INDEX_JS);
  const context = createUpstreamContext();
  vm.runInContext(source, context, { filename: "index_c.js" });
  assertUpstreamContext(context, "GitHub Pages index_c.js");
  return context;
}

async function fetchTextWithCurlFallback(url) {
  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(120_000) });
    if (response.ok) {
      return await response.text();
    }
  } catch {
    // 有些本机网络环境里 Node fetch 对 GitHub Pages 的 TLS 连接不稳定，curl 往往更可靠。
  }

  try {
    const result = await execFileAsync("curl", ["-fsSL", "--retry", "5", "--retry-all-errors", "--retry-delay", "2", "--connect-timeout", "20", "--max-time", "120", "--http1.1", url], {
      maxBuffer: 10 * 1024 * 1024
    });
    return result.stdout;
  } catch (error) {
    throw new Error(`Failed to fetch ${url} with fetch or curl: ${error.message}`);
  }
}

function createUpstreamContext() {
  const element = () => ({
    checked: false,
    value: "",
    innerHTML: "",
    style: {},
    classList: { contains: () => false, add() {}, remove() {}, toggle() {} },
    addEventListener() {}
  });
  const context = {
    console,
    Math,
    URLSearchParams,
    alert(message) {
      throw new Error(String(message));
    },
    location: { href: "" },
    window: { location: {}, parent: { location: {} } },
    document: {
      getElementById: element,
      getElementsByClassName() {
        return [];
      },
      createElement: element,
      body: { appendChild() {} }
    }
  };
  context.window.location = context.location;
  context.window.parent.location = context.location;
  vm.createContext(context);
  return context;
}

function assertUpstreamContext(context, label) {
  for (const functionName of ["calDataYear", "NdaysGregJul", "getJD"]) {
    if (typeof context[functionName] !== "function") {
      throw new Error(`${label} did not expose ${functionName}.`);
    }
  }
}

async function readGeneratedRecord(output, civil) {
  const filePath = path.join(output, String(civil.year), "calendar_days.jsonl");
  const content = await readFile(filePath, "utf8");
  const line = content
    .split("\n")
    .find((entry) => entry.includes(`"year":${civil.year},"month":${civil.month},"dayOfMonth":${civil.dayOfMonth}`));
  if (line === undefined) {
    throw new Error(`No generated record for ${formatCivil(civil)} in ${filePath}.`);
  }
  return JSON.parse(line);
}

function recordFromUpstream(upstream, civil) {
  const langVars = typeof upstream.langConstant === "function" ? upstream.langConstant(2) : {};
  langVars.region = "default";
  langVars.li_ancient = null;

  const calVars = upstream.calDataYear(civil.year, langVars);
  const daySlot = civil.year === 1582 && civil.month === 10 && civil.dayOfMonth >= 15
    ? civil.dayOfMonth - 10
    : civil.dayOfMonth;
  const dayOffset = calVars.mday[civil.month - 1] + daySlot;
  const julianDayNumber = calVars.jd0 + dayOffset + 1;
  const monthPosition = findLunarMonthPosition(calVars, dayOffset);
  const startJulianDayNumber = calVars.jd0 + calVars.cmonthDate[monthPosition] + 1;
  const rawMonthNumber = calVars.cmonthNum[monthPosition];
  const rawJian = calVars.cmonthJian[monthPosition];
  const dayCount = calVars.cmonthLong[monthPosition] === 1 ? 30 : 29;
  const lunarYearNumber = civil.year + calVars.cmonthYear[monthPosition] - 1;
  const jian = Math.abs(rawJian);
  const monthStemIndex = positiveModulo(
    12 * (positiveModulo(civil.year + 725, 10) + calVars.cmonthXiaYear[monthPosition]) + jian + 1,
    10
  );

  return {
    julianDayNumber,
    civil: {
      year: civil.year,
      month: civil.month,
      dayOfMonth: civil.dayOfMonth,
      calendarStyle: civilCalendarStyle(civil.year, civil.month, civil.dayOfMonth)
    },
    lunarYear: {
      yearNumber: lunarYearNumber,
      yearStemIndex: positiveModulo(lunarYearNumber + 726, 10),
      yearBranchIndex: positiveModulo(lunarYearNumber + 728, 12)
    },
    lunarMonth: {
      yearNumber: lunarYearNumber,
      monthNumberInYear: Math.abs(rawMonthNumber),
      isLeapMonth: rawMonthNumber < 0,
      dayCount,
      monthStemIndex,
      monthBranchIndex: positiveModulo(jian + 1, 12)
    },
    lunarDay: {
      dayNumberInMonth: julianDayNumber - startJulianDayNumber + 1,
      dayStemIndex: positiveModulo(julianDayNumber - 1, 10),
      dayBranchIndex: positiveModulo(julianDayNumber + 1, 12)
    }
  };
}

function findLunarMonthPosition(calVars, dayOffset) {
  for (let index = 0; index < calVars.cmonthDate.length - 1; index += 1) {
    if (dayOffset >= calVars.cmonthDate[index] && dayOffset < calVars.cmonthDate[index + 1]) {
      return index;
    }
  }
  return calVars.cmonthDate.length - 1;
}

function assertRecordMatchesFixture(sample, record) {
  const expected = {
    dayIndex: sample.expected.dayIndex,
    julianDayNumber: sample.expected.julianDayNumber,
    civil: {
      ...sample.civil,
      calendarStyle: sample.expected.calendarStyle
    },
    lunarYear: sample.expected.lunarYear,
    lunarMonth: sample.expected.lunarMonth,
    lunarDay: sample.expected.lunarDay
  };
  assertDeepEqual(sample, "fixture", record, expected);
}

function assertComparableRecords(sample, generatedRecord, upstreamRecord, label) {
  const comparableGenerated = {
    julianDayNumber: generatedRecord.julianDayNumber,
    civil: generatedRecord.civil,
    lunarYear: generatedRecord.lunarYear,
    lunarMonth: {
      yearNumber: generatedRecord.lunarMonth.yearNumber,
      monthNumberInYear: generatedRecord.lunarMonth.monthNumberInYear,
      isLeapMonth: generatedRecord.lunarMonth.isLeapMonth,
      dayCount: generatedRecord.lunarMonth.dayCount,
      monthStemIndex: generatedRecord.lunarMonth.monthStemIndex,
      monthBranchIndex: generatedRecord.lunarMonth.monthBranchIndex
    },
    lunarDay: {
      dayNumberInMonth: generatedRecord.lunarDay.dayNumberInMonth,
      dayStemIndex: generatedRecord.lunarDay.dayStemIndex,
      dayBranchIndex: generatedRecord.lunarDay.dayBranchIndex
    }
  };
  assertDeepEqual(sample, label, comparableGenerated, upstreamRecord);
}

function assertDeepEqual(sample, label, actual, expected) {
  const actualJSON = stableJSONString(actual);
  const expectedJSON = stableJSONString(expected);
  if (actualJSON !== expectedJSON) {
    throw new Error(
      `${sample.id} (${formatCivil(sample.civil)}) does not match ${label}.\n` +
        `Expected: ${expectedJSON}\nActual:   ${actualJSON}`
    );
  }
}

function stableJSONString(value) {
  return JSON.stringify(sortObjectKeys(value));
}

function sortObjectKeys(value) {
  if (Array.isArray(value)) {
    return value.map(sortObjectKeys);
  }
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value)
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([key, nestedValue]) => [key, sortObjectKeys(nestedValue)])
    );
  }
  return value;
}

function civilCalendarStyle(year, month, dayOfMonth) {
  if (year > 1582) return "gregorian";
  if (year < 1582) return "julian";
  if (month > 10 || (month === 10 && dayOfMonth >= 15)) return "gregorian";
  return "julian";
}

function positiveModulo(value, modulus) {
  return ((value % modulus) + modulus) % modulus;
}

function formatCivil(civil) {
  return `${civil.year}-${String(civil.month).padStart(2, "0")}-${String(civil.dayOfMonth).padStart(2, "0")}`;
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
