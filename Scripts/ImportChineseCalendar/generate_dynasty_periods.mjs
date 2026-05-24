#!/usr/bin/env node
import { createHash } from "node:crypto";
import { createWriteStream } from "node:fs";
import { mkdir, readFile, stat, writeFile } from "node:fs/promises";
import { execFile } from "node:child_process";
import path from "node:path";
import process from "node:process";
import { once } from "node:events";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const execFileAsync = promisify(execFile);

const SOURCE_URL = "https://ytliu0.github.io/ChineseCalendar/era_names_simp.html";
const RAW_FILE_NAME = "era_names_simp.html";
const ORTHODOX_SEGMENT_NAMES = [
  "秦汉",
  "魏晋南朝",
  "唐五代两宋",
  "元明清"
];

const OUTPUT_FILES = {
  dynasties: "dynasties.jsonl",
  dateExpressions: "chinese_date_expressions.jsonl",
  orthodoxTraditions: "orthodox_traditions.jsonl",
  orthodoxBoundaries: "orthodox_boundaries.jsonl",
  orthodoxPeriods: "orthodox_periods.jsonl"
};

const SECTION_ID_MAP = new Map([
  ["chunqiu", "spring_autumn"],
  ["warring", "warring_states"],
  ["qin", "qin"],
  ["han1", "western_han_xin_gengshi"],
  ["han2", "eastern_han"],
  ["3kingdoms", "three_kingdoms"],
  ["jin", "jin_dynasty"],
  ["qinliang", "later_qin_northern_liang"],
  ["northdynasties", "northern_dynasties"],
  ["southdynasties", "southern_dynasties"],
  ["sui", "sui"],
  ["tang", "tang"],
  ["5dynasties", "five_dynasties"],
  ["song", "song"],
  ["khitan", "khitan_liao"],
  ["jurchen", "jin_jurchen"],
  ["mongol", "mongol_yuan"],
  ["ming", "ming_southern_ming_ming_zheng"],
  ["qing", "manchu_later_jin_qing"]
]);

const DIRECT_DYNASTY_SOURCE_SECTION_IDS = new Set([
  "qin",
  "han2",
  "jin",
  "sui",
  "tang",
  "song",
  "khitan",
  "jurchen"
]);

const SUPPLEMENTAL_DYNASTIES = [
  dynastySpec("western_han", "西汉", "西汉", -205, 8, "西汉 (公元前206-公元8)"),
  dynastySpec("xin", "新", "新", 8, 23, "新 (8-23)"),
  dynastySpec("gengshi", "更始", "更始", 23, 25, "更始 (23-25)"),
  dynastySpec("cao_wei", "魏", "魏", 220, 265, "曹魏 (220 — 265)"),
  dynastySpec("shu_han", "蜀汉", "蜀", 221, 263, "蜀汉 (221 — 263)"),
  dynastySpec("sun_wu", "孙吴", "吴", 222, 280, "孙吴 (222 — 280)"),
  dynastySpec("western_jin", "西晋", "西晋", 265, 317, "西晋 (265-317)"),
  dynastySpec("eastern_jin", "东晋", "东晋", 317, 420, "东晋 (317-420)"),
  dynastySpec("later_qin", "后秦", "后秦", 384, 417, "后秦 (384-417)"),
  dynastySpec("northern_liang", "北凉", "北凉", 397, 439, "北凉 (397-439)"),
  dynastySpec("northern_wei", "北魏", "北魏", 386, 534, "北魏 (386-534)"),
  dynastySpec("eastern_wei", "东魏", "东魏", 534, 550, "东魏 (534-550)"),
  dynastySpec("western_wei", "西魏", "西魏", 535, 557, "西魏 (535-557)"),
  dynastySpec("northern_qi", "北齐", "北齐", 550, 577, "北齐 (550-577)"),
  dynastySpec("northern_zhou", "北周", "北周", 557, 581, "北周 (557-581)"),
  dynastySpec("liu_song", "刘宋", "刘宋", 420, 479, "宋 (420-479)"),
  dynastySpec("southern_qi", "齐", "齐", 479, 502, "齐 (479-502)"),
  dynastySpec("southern_liang", "梁", "梁", 502, 557, "梁 (502-557)"),
  dynastySpec("chen", "陈", "陈", 557, 589, "陈 (557-589)"),
  dynastySpec("later_liang", "后梁", "后梁", 907, 923, "五代梁 (907 — 923)"),
  dynastySpec("later_tang", "后唐", "后唐", 923, 936, "五代唐 (923 — 936)"),
  dynastySpec("later_jin", "后晋", "后晋", 936, 947, "五代晋 (936 — 946)"),
  dynastySpec("later_han", "后汉", "后汉", 947, 951, "五代汉 (947 — 950)"),
  dynastySpec("later_zhou", "后周", "后周", 951, 960, "五代周 (951 — 960)"),
  dynastySpec("northern_song", "北宋", "北宋", 960, 1127, "北宋 (960 — 1127)"),
  dynastySpec("southern_song", "南宋", "南宋", 1127, 1279, "南宋 (1127 — 1279)"),
  dynastySpec("yuan", "元", "元", 1271, 1368, "至元八年建国号大元; 正统期从宋亡后的 1279 年起算"),
  dynastySpec("ming", "明", "明", 1368, 1644, "明 (1368 — 1644)"),
  dynastySpec("qing", "清", "清", 1636, 1912, "1636 年改国号大清; 正统期从 1644 年起算")
];

const ORTHODOX_PERIOD_SPECS = [
  periodSpec("qin", "秦汉", -220, -205, "秦 (公元前221 — 前207)"),
  periodSpec("western_han", "秦汉", -205, 8, "西汉 (公元前206-公元8)"),
  periodSpec("xin", "秦汉", 8, 23, "新 (8-23)"),
  periodSpec("gengshi", "秦汉", 23, 25, "更始 (23-25)"),
  periodSpec("eastern_han", "秦汉", 25, 220, "东汉 (25 — 220)"),
  periodSpec("cao_wei", "魏晋南朝", 220, 265, "曹魏 (220 — 265)"),
  periodSpec("western_jin", "魏晋南朝", 265, 317, "西晋 (265-317)"),
  periodSpec("eastern_jin", "魏晋南朝", 317, 420, "东晋 (317-420)"),
  periodSpec("liu_song", "魏晋南朝", 420, 479, "宋 (420-479)"),
  periodSpec("southern_qi", "魏晋南朝", 479, 502, "齐 (479-502)"),
  periodSpec("southern_liang", "魏晋南朝", 502, 557, "梁 (502-557)"),
  periodSpec("chen", "魏晋南朝", 557, 589, "陈 (557-589)"),
  periodSpec("sui", "魏晋南朝", 589, 618, "隋 (581 — 618); 正统期接陈亡后的 589 年"),
  periodSpec("tang", "唐五代两宋", 618, 907, "唐 (618 — 907)"),
  periodSpec("later_liang", "唐五代两宋", 907, 923, "五代梁 (907 — 923)"),
  periodSpec("later_tang", "唐五代两宋", 923, 936, "五代唐 (923 — 936)"),
  periodSpec("later_jin", "唐五代两宋", 936, 947, "五代晋 (936 — 946)"),
  periodSpec("later_han", "唐五代两宋", 947, 951, "五代汉 (947 — 950)"),
  periodSpec("later_zhou", "唐五代两宋", 951, 960, "五代周 (951 — 960)"),
  periodSpec("northern_song", "唐五代两宋", 960, 1127, "北宋 (960 — 1127)"),
  periodSpec("southern_song", "唐五代两宋", 1127, 1279, "南宋 (1127 — 1279)"),
  periodSpec("yuan", "元明清", 1279, 1368, "元; 正统期从南宋亡后的 1279 年起算"),
  periodSpec("ming", "元明清", 1368, 1644, "明 (1368 — 1644)"),
  periodSpec("qing", "元明清", 1644, 1912, "清; 正统期从 1644 年起算")
];

function dynastySpec(id, name, shortName, startYear, endYear, sourceText, note) {
  return {
    id,
    name,
    shortName,
    startYear,
    endYear,
    sourceText,
    note: note ?? "Supplemental polity split from era_names_simp.html h3/table text."
  };
}

function periodSpec(dynastyID, segmentName, startYear, endYear, sourceText) {
  return { dynastyID, segmentName, startYear, endYear, sourceText };
}

const scriptPath = fileURLToPath(import.meta.url);
const scriptDirectory = path.dirname(scriptPath);
const repositoryRoot = path.resolve(scriptDirectory, "../..");

async function main() {
  const options = parseArguments(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  if (options.validateOnly) {
    const result = await validateArtifact(options.output);
    console.log(
      `Validated dynasty-period artifact under ${options.output}: ${result.dynasties} dynasties, ` +
        `${result.dateExpressions} date expressions, ${result.orthodoxTraditions} tradition, ` +
        `${result.orthodoxBoundaries} boundaries, ${result.orthodoxPeriods} periods.`
    );
    return;
  }

  const rawSource = await ensureRawEraPage(options);
  const baseManifest = await readOptionalJson(path.join(options.output, "manifest.json"));
  const artifact = await buildArtifact(rawSource, baseManifest, options);

  await writeArtifact(options.output, artifact);
  await writeProcessedManifest(options.output, baseManifest, artifact, rawSource);

  console.log(
    `Generated dynasty-period artifact under ${options.output}: ${artifact.dynasties.length} dynasties, ` +
      `${artifact.dateExpressions.length} date expressions, ${artifact.orthodoxTraditions.length} tradition, ` +
      `${artifact.orthodoxBoundaries.length} boundaries, ${artifact.orthodoxPeriods.length} periods.`
  );
}

function parseArguments(argumentsList) {
  const options = {
    rawSource: path.join(repositoryRoot, "Data/Raw/ChineseCalendar"),
    output: path.join(repositoryRoot, "Data/Processed/swiftdata_import"),
    forceRefresh: false,
    validateOnly: false,
    help: false
  };

  for (let index = 0; index < argumentsList.length; index += 1) {
    const argument = argumentsList[index];
    switch (argument) {
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

function resolveRepositoryPath(value) {
  return path.isAbsolute(value) ? value : path.resolve(repositoryRoot, value);
}

function requireOptionValue(name, value) {
  if (value === undefined || value.startsWith("--")) {
    throw new Error(`${name} requires a value.`);
  }
  return value;
}

function printHelp() {
  console.log(`Usage:
  Scripts/ImportChineseCalendar/generate_dynasty_periods.swift [options]

Options:
  --raw-source <path>      Raw ChineseCalendar source directory. Default: Data/Raw/ChineseCalendar
  --output <path>          SwiftData import output directory. Default: Data/Processed/swiftdata_import
  --force-refresh          Re-fetch era_names_simp.html before generating.
  --validate-only          Validate an existing dynasty-period artifact without regenerating it.
  --help                   Show this help text.
`);
}

async function ensureRawEraPage(options) {
  await mkdir(options.rawSource, { recursive: true });
  const htmlPath = path.join(options.rawSource, RAW_FILE_NAME);
  const manifestPath = path.join(options.rawSource, "manifest.json");
  const manifest = (await readOptionalJson(manifestPath)) ?? {};
  const shouldFetch = options.forceRefresh || !(await pathExists(htmlPath));
  let fetchedAt;
  let fetchedFrom;

  if (shouldFetch) {
    const fetchResult = await fetchEraPage(manifest.upstreamCommit);
    const { stdout } = fetchResult;
    fetchedFrom = fetchResult.url;
    await writeFile(htmlPath, stdout, "utf8");
    fetchedAt = new Date().toISOString();
  }

  const html = await readFile(htmlPath, "utf8");
  const sha256 = sha256Hex(html);
  const existingWebSource = manifest.webSources?.find((entry) => entry.file === RAW_FILE_NAME);
  const webSource = {
    file: RAW_FILE_NAME,
    url: SOURCE_URL,
    fetchedFrom: fetchedFrom ?? existingWebSource?.fetchedFrom ?? SOURCE_URL,
    fetchedAt: fetchedAt ?? existingWebSource?.fetchedAt ?? new Date().toISOString(),
    sha256,
    versionNote: "GitHub Pages HTML has no explicit version; sha256 records the fetched page body."
  };

  const files = Array.isArray(manifest.files) ? [...manifest.files] : [];
  if (!files.includes(RAW_FILE_NAME)) {
    files.push(RAW_FILE_NAME);
  }
  const webSources = [
    ...(Array.isArray(manifest.webSources)
      ? manifest.webSources.filter((entry) => entry.file !== RAW_FILE_NAME)
      : []),
    webSource
  ];
  const updatedManifest = {
    ...manifest,
    files,
    webSources
  };
  await writeFile(manifestPath, `${JSON.stringify(updatedManifest, null, 2)}\n`, "utf8");

  return {
    html,
    file: RAW_FILE_NAME,
    path: htmlPath,
    url: SOURCE_URL,
    sha256,
    fetchedAt: webSource.fetchedAt,
    upstreamRepository: updatedManifest.upstreamRepository,
    upstreamCommit: updatedManifest.upstreamCommit
  };
}

async function fetchEraPage(upstreamCommit) {
  const urls = [
    SOURCE_URL,
    upstreamCommit === undefined
      ? undefined
      : `https://raw.githubusercontent.com/ytliu0/ChineseCalendar/${upstreamCommit}/${RAW_FILE_NAME}`,
    `https://raw.githubusercontent.com/ytliu0/ChineseCalendar/master/${RAW_FILE_NAME}`
  ].filter((url) => url !== undefined);

  const failures = [];
  for (const url of urls) {
    try {
      const { stdout } = await execFileAsync("/usr/bin/curl", [
        "-L",
        "--fail",
        "--silent",
        "--show-error",
        "--retry",
        "3",
        "--retry-delay",
        "1",
        "--retry-all-errors",
        "--connect-timeout",
        "5",
        "--max-time",
        "20",
        url
      ], {
        maxBuffer: 2 * 1024 * 1024
      });
      return { url, stdout };
    } catch (error) {
      failures.push(`${url}: ${error.message}`);
    }
  }

  throw new Error(`Unable to fetch ${RAW_FILE_NAME}. Attempts:\n${failures.join("\n")}`);
}

async function buildArtifact(rawSource, baseManifest, options) {
  const parsedSource = parseEraPage(rawSource.html);
  const availableIndexes = await loadAvailableIndexes(options.output, baseManifest);

  const records = {
    dynasties: [],
    dateExpressions: [],
    orthodoxTraditions: [],
    orthodoxBoundaries: [],
    orthodoxPeriods: []
  };
  const expressionIDs = new Set();

  function addDateExpression(record) {
    if (expressionIDs.has(record.id)) {
      throw new Error(`Duplicate ChineseDateExpression id ${record.id}.`);
    }
    expressionIDs.add(record.id);
    records.dateExpressions.push({
      id: record.id,
      precision: record.precision,
      index: record.index ?? null,
      uncertainRange: record.uncertainRange ?? null,
      sourceText: record.sourceText,
      note: record.note ?? null
    });
  }

  for (const section of parsedSource.sections) {
    const dynastyID = SECTION_ID_MAP.get(section.sourceID) ?? slugify(section.sourceID);
    if (!DIRECT_DYNASTY_SOURCE_SECTION_IDS.has(section.sourceID)) {
      continue;
    }
    const name = section.name;
    const startExpressionID = `${dynastyID}_claimed_start`;
    const endExpressionID = `${dynastyID}_claimed_end`;
    addDateExpression(yearExpression(
      startExpressionID,
      section.startYear,
      section.heading,
      "Claimed start parsed from era_names_simp.html h2 civil-year range.",
      availableIndexes
    ));
    addDateExpression(yearExpression(
      endExpressionID,
      section.endYear,
      section.heading,
      "Claimed end parsed from era_names_simp.html h2 civil-year range.",
      availableIndexes
    ));
    records.dynasties.push({
      id: dynastyID,
      name,
      shortName: name,
      claimedStartDateID: startExpressionID,
      claimedEndDateID: endExpressionID,
      note: `Parsed from era_names_simp.html section id=${section.sourceID}; boundary precision is year.`
    });
  }

  for (const supplementalDynasty of SUPPLEMENTAL_DYNASTIES) {
    const startExpressionID = `${supplementalDynasty.id}_claimed_start`;
    const endExpressionID = `${supplementalDynasty.id}_claimed_end`;
    addDateExpression(yearExpression(
      startExpressionID,
      supplementalDynasty.startYear,
      supplementalDynasty.sourceText,
      "Supplemental polity claimed start boundary.",
      availableIndexes
    ));
    addDateExpression(yearExpression(
      endExpressionID,
      supplementalDynasty.endYear,
      supplementalDynasty.sourceText,
      "Supplemental polity claimed end boundary.",
      availableIndexes
    ));
    records.dynasties.push({
      id: supplementalDynasty.id,
      name: supplementalDynasty.name,
      shortName: supplementalDynasty.shortName,
      claimedStartDateID: startExpressionID,
      claimedEndDateID: endExpressionID,
      note: supplementalDynasty.note
    });
  }

  const tradition = {
    id: "orthodox_sequence_qin_han_to_qing",
    name: ORTHODOX_SEGMENT_NAMES.join(" -> "),
    note: "Issue 18 first-version orthodox narrative sequence; ordered by OrthodoxPeriod.sequenceIndex."
  };
  records.orthodoxTraditions.push(tradition);

  const boundaries = orthodoxBoundaries();
  for (const boundary of boundaries) {
    const dateID = `${boundary.id}_date`;
    addDateExpression(yearExpression(dateID, boundary.year, boundary.sourceText, boundary.dateNote, availableIndexes));
    records.orthodoxBoundaries.push({
      id: boundary.id,
      traditionID: tradition.id,
      dateExpressionID: dateID,
      note: boundary.note
    });
  }

  const boundaryIDsByYear = new Map(boundaries.map((boundary) => [boundary.year, boundary.id]));
  for (let index = 0; index < ORTHODOX_PERIOD_SPECS.length; index += 1) {
    const period = ORTHODOX_PERIOD_SPECS[index];
    const segmentIndex = ORTHODOX_SEGMENT_NAMES.indexOf(period.segmentName);
    if (segmentIndex === -1) {
      throw new Error(`Orthodox period ${period.dynastyID} has unknown segment ${period.segmentName}.`);
    }
    const startBoundaryID = boundaryIDsByYear.get(period.startYear);
    const endBoundaryID = boundaryIDsByYear.get(period.endYear);
    if (startBoundaryID === undefined || endBoundaryID === undefined) {
      throw new Error(`Missing boundary for OrthodoxPeriod ${period.dynastyID}.`);
    }
    records.orthodoxPeriods.push({
      id: `${tradition.id}_${period.dynastyID}`,
      traditionID: tradition.id,
      dynastyID: period.dynastyID,
      startBoundaryID,
      endBoundaryID,
      sequenceIndex: index,
      segmentIndex,
      segmentName: period.segmentName,
      note: `Specific orthodox period inside the ${period.segmentName} narrative segment; sourceText: ${period.sourceText}`
    });
  }

  const sourceAudit = buildSourceAudit(parsedSource, records, rawSource, baseManifest);
  const artifact = {
    ...records,
    sourceAudit
  };
  validateRecords(artifact, availableIndexes);
  return artifact;
}

function parseEraPage(html) {
  const sections = [];
  const sectionPattern = /<input[^>]+id="([^"]+)"[^>]*>\s*<label[^>]*>\s*<h2[^>]*>(.*?)<\/h2>/g;
  for (const match of html.matchAll(sectionPattern)) {
    const sourceID = match[1];
    const heading = cleanHtmlText(match[2]);
    const range = parseHeadingRange(heading);
    if (range === undefined) {
      continue;
    }
    sections.push({
      sourceID,
      heading,
      name: cleanDynastyName(heading),
      startYear: range.startYear,
      endYear: range.endYear
    });
  }

  const h3Headings = [];
  for (const match of html.matchAll(/<h3[^>]*>(.*?)<\/h3>/g)) {
    h3Headings.push(cleanHtmlText(match[1]));
  }

  if (sections.length === 0) {
    throw new Error("No dynasty sections could be parsed from era_names_simp.html.");
  }

  return { sections, h3Headings };
}

function cleanHtmlText(value) {
  return value
    .replace(/<[^>]+>/g, "")
    .replace(/&ndash;/g, "–")
    .replace(/&mdash;/g, "—")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function cleanDynastyName(value) {
  return value.replace(/\([^()]+\)/g, "").replace(/\s+/g, "").replace(/:$/, "");
}

function parseHeadingRange(heading) {
  const matches = [...heading.matchAll(/\(([^()]+?)\s*[—–-]\s*([^()]+?)\)/g)];
  if (matches.length === 0) {
    return undefined;
  }
  const ranges = matches.map((match) => ({
    startYear: parseCivilYear(match[1]),
    endYear: parseCivilYear(match[2])
  }));

  return {
    startYear: Math.min(...ranges.map((range) => range.startYear)),
    endYear: Math.max(...ranges.map((range) => range.endYear))
  };
}

function parseCivilYear(value) {
  const compact = value.replace(/\s+/g, "");
  const match = compact.match(/^(?:公元)?(前)?(\d+)$/);
  if (!match) {
    throw new Error(`Unable to parse civil year token: ${value}`);
  }
  const year = Number.parseInt(match[2], 10);
  return match[1] === "前" ? 1 - year : year;
}

function yearExpression(id, year, sourceText, note, availableIndexes) {
  if (!availableIndexes.years.has(year)) {
    return {
      id,
      precision: "unknown",
      index: null,
      sourceText,
      note:
        `${note} Civil year ${year} is outside the current imported ChineseLunarYear coverage; ` +
        "sourceText is preserved without a synthetic index."
    };
  }

  return {
    id,
    precision: "year",
    index: year,
    sourceText,
    note: `${note} BCE years use astronomical numbering, so 前221 maps to -220.`
  };
}

function orthodoxBoundaries() {
  const byYear = new Map();
  for (const period of ORTHODOX_PERIOD_SPECS) {
    byYear.set(period.startYear, period.sourceText);
    byYear.set(period.endYear, period.sourceText);
  }

  return [...byYear.entries()]
    .sort(([left], [right]) => left - right)
    .map(([year, sourceText]) => ({
      id: `orthodox_boundary_${boundaryIDComponent(year)}`,
      year,
      sourceText,
      note: year === 2200
        ? "Technical seed coverage end boundary, not a historical end."
        : "Shared orthodox period boundary for the issue 18 narrative sequence.",
      dateNote: year === 1949 || year === 2200 || year === 1912
        ? "Manual supplement boundary required by issue 18 or current seed coverage."
        : "Boundary derived from era_names_simp.html h2 year ranges."
    }));
}

function boundaryIDComponent(year) {
  return year < 0 ? `bce_${Math.abs(year)}` : String(year);
}

function buildSourceAudit(parsedSource, records, rawSource, baseManifest) {
  const h2ExpressionIDs = new Set(parsedSource.sections.flatMap((section) => {
    const dynastyID = SECTION_ID_MAP.get(section.sourceID) ?? slugify(section.sourceID);
    return [`${dynastyID}_claimed_start`, `${dynastyID}_claimed_end`];
  }));
  const h2Expressions = records.dateExpressions.filter((expression) => h2ExpressionIDs.has(expression.id));
  const nonH2Expressions = records.dateExpressions.filter((expression) => !h2ExpressionIDs.has(expression.id));
  return {
    sourceURL: rawSource.url,
    rawFile: `Data/Raw/ChineseCalendar/${rawSource.file}`,
    rawSha256: rawSource.sha256,
    rawFetchedAt: rawSource.fetchedAt,
    upstreamRepository: rawSource.upstreamRepository ?? baseManifest?.sourceUpstreamRepository,
    upstreamCommit: rawSource.upstreamCommit ?? baseManifest?.sourceUpstreamCommit,
    parsedH2SectionCount: parsedSource.sections.length,
    parsedH3HeadingCount: parsedSource.h3Headings.length,
    parsedH2Sections: parsedSource.sections.map((section) => ({
      sourceID: section.sourceID,
      heading: section.heading,
      startYear: section.startYear,
      endYear: section.endYear
    })),
    nonEmittedH2Sections: parsedSource.sections
      .filter((section) => !DIRECT_DYNASTY_SOURCE_SECTION_IDS.has(section.sourceID))
      .map((section) => ({
        sourceID: section.sourceID,
        heading: section.heading,
        reason: "Source h2 is a period label, composite section, or lineage grouping rather than one concrete Dynasty record."
      })),
    auditedH3Headings: parsedSource.h3Headings,
    conclusion: [
      "era_names_simp.html is the priority source for first-version dynasty civil-year ranges.",
      "Automatically parsed h2 boundaries are civil-year ranges; boundaries inside imported calendar coverage resolve to ChineseDateExpression.precision = year.",
      "Period labels and composite h2 source sections such as 春秋时期、战国时期、西汉/新/更始、魏/蜀/吴、南北朝、五代 are audited but not emitted as Dynasty records.",
      "Automatically parsed h2 boundaries outside imported calendar coverage are kept as precision = unknown with sourceText preserved.",
      "No month-precision or day-precision dynasty boundary is automatically extracted in this version; sourceText is preserved for later refinement.",
      "OrthodoxPeriod records are concrete orthodox dynasty periods; segmentIndex and segmentName preserve the required narrative groups.",
      "Supplemental dynasties split compound h2 sections into specific h3/table polities such as 西汉、新、更始、魏、蜀汉、孙吴、刘宋、五代后梁后唐后晋后汉后周、北宋、南宋、元、明、清.",
      "Non-orthodox polities such as 蜀汉、孙吴、北凉 remain Dynasty records but are not included in OrthodoxPeriod. 魏 is the Three Kingdoms orthodox period."
    ],
    automaticPrecisionCounts: countPrecisions(h2Expressions),
    manualPrecisionCounts: countPrecisions(nonH2Expressions),
    dateIndexRules: {
      year: "ChineseDateExpression.index is ChineseLunarYear.lunarYearNumber.",
      month: "ChineseDateExpression.index is ChineseLunarMonth.lunarMonthIndex; not emitted by this generator yet.",
      day: "ChineseDateExpression.index is CalendarDay.dayIndex; not emitted by this generator yet.",
      range: "uncertainRange uses half-open [lowerBound, upperBound); range records are validated if emitted.",
      bceConversion: "Civil BCE year N maps to astronomical year 1 - N, so 前221 maps to -220."
    },
    orthodoxSequence: ORTHODOX_SEGMENT_NAMES,
    orthodoxPeriodsBySegment: groupPeriodSpecsBySegment()
  };
}

function groupPeriodSpecsBySegment() {
  const result = Object.fromEntries(ORTHODOX_SEGMENT_NAMES.map((name) => [name, []]));
  for (const period of ORTHODOX_PERIOD_SPECS) {
    result[period.segmentName].push({
      dynastyID: period.dynastyID,
      startYear: period.startYear,
      endYear: period.endYear
    });
  }
  return result;
}

function countPrecisions(expressions) {
  const result = { year: 0, month: 0, day: 0, range: 0, unknown: 0 };
  for (const expression of expressions) {
    result[expression.precision] = (result[expression.precision] ?? 0) + 1;
  }
  return result;
}

async function writeArtifact(output, artifact) {
  await mkdir(output, { recursive: true });
  await Promise.all([
    writeJsonl(path.join(output, OUTPUT_FILES.dynasties), artifact.dynasties),
    writeJsonl(path.join(output, OUTPUT_FILES.dateExpressions), artifact.dateExpressions),
    writeJsonl(path.join(output, OUTPUT_FILES.orthodoxTraditions), artifact.orthodoxTraditions),
    writeJsonl(path.join(output, OUTPUT_FILES.orthodoxBoundaries), artifact.orthodoxBoundaries),
    writeJsonl(path.join(output, OUTPUT_FILES.orthodoxPeriods), artifact.orthodoxPeriods)
  ]);
}

async function writeProcessedManifest(output, baseManifest, artifact, rawSource) {
  const manifest = {
    ...(baseManifest ?? { artifact: "swiftdata_import" }),
    dynastyArtifact: {
      artifact: "dynasty_periods",
      generatedAt: new Date().toISOString(),
      generator: "Scripts/ImportChineseCalendar/generate_dynasty_periods.swift",
      sourceURL: rawSource.url,
      rawFile: `Data/Raw/ChineseCalendar/${rawSource.file}`,
      rawSha256: rawSource.sha256,
      rawFetchedAt: rawSource.fetchedAt,
      sourceUpstreamRepository: rawSource.upstreamRepository ?? baseManifest?.sourceUpstreamRepository,
      sourceUpstreamCommit: rawSource.upstreamCommit ?? baseManifest?.sourceUpstreamCommit,
      totalDynasties: artifact.dynasties.length,
      totalChineseDateExpressions: artifact.dateExpressions.length,
      totalOrthodoxTraditions: artifact.orthodoxTraditions.length,
      totalOrthodoxBoundaries: artifact.orthodoxBoundaries.length,
      totalOrthodoxPeriods: artifact.orthodoxPeriods.length,
      files: {
        Dynasty: OUTPUT_FILES.dynasties,
        ChineseDateExpression: OUTPUT_FILES.dateExpressions,
        OrthodoxTradition: OUTPUT_FILES.orthodoxTraditions,
        OrthodoxBoundary: OUTPUT_FILES.orthodoxBoundaries,
        OrthodoxPeriod: OUTPUT_FILES.orthodoxPeriods
      },
      importOrder: [
        "ChineseDateExpression",
        "Dynasty",
        "OrthodoxTradition",
        "OrthodoxBoundary",
        "OrthodoxPeriod"
      ],
      relationshipKeys: {
        "Dynasty.claimedStartDate": "dynasty.claimedStartDateID -> ChineseDateExpression.id",
        "Dynasty.claimedEndDate": "dynasty.claimedEndDateID -> ChineseDateExpression.id",
        "OrthodoxBoundary.tradition": "orthodoxBoundary.traditionID -> OrthodoxTradition.id",
        "OrthodoxBoundary.date": "orthodoxBoundary.dateExpressionID -> ChineseDateExpression.id",
        "OrthodoxPeriod.tradition": "orthodoxPeriod.traditionID -> OrthodoxTradition.id",
        "OrthodoxPeriod.dynasty": "orthodoxPeriod.dynastyID -> Dynasty.id",
        "OrthodoxPeriod.startBoundary": "orthodoxPeriod.startBoundaryID -> OrthodoxBoundary.id",
        "OrthodoxPeriod.endBoundary": "orthodoxPeriod.endBoundaryID -> OrthodoxBoundary.id"
      },
      sourceAudit: artifact.sourceAudit
    }
  };

  manifest.files = {
    ...(baseManifest?.files ?? {}),
    Dynasty: OUTPUT_FILES.dynasties,
    ChineseDateExpression: OUTPUT_FILES.dateExpressions,
    OrthodoxTradition: OUTPUT_FILES.orthodoxTraditions,
    OrthodoxBoundary: OUTPUT_FILES.orthodoxBoundaries,
    OrthodoxPeriod: OUTPUT_FILES.orthodoxPeriods
  };
  manifest.importOrder = appendImportOrder(baseManifest?.importOrder ?? [], manifest.dynastyArtifact.importOrder);

  await writeFile(path.join(output, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
}

function appendImportOrder(existing, additions) {
  const result = [...existing];
  for (const value of additions) {
    if (!result.includes(value)) {
      result.push(value);
    }
  }
  return result;
}

async function validateArtifact(output) {
  const manifest = await readRequiredJson(path.join(output, "manifest.json"));
  const availableIndexes = await loadAvailableIndexes(output, manifest);
  const artifact = {
    dynasties: await readJsonl(path.join(output, OUTPUT_FILES.dynasties)),
    dateExpressions: await readJsonl(path.join(output, OUTPUT_FILES.dateExpressions)),
    orthodoxTraditions: await readJsonl(path.join(output, OUTPUT_FILES.orthodoxTraditions)),
    orthodoxBoundaries: await readJsonl(path.join(output, OUTPUT_FILES.orthodoxBoundaries)),
    orthodoxPeriods: await readJsonl(path.join(output, OUTPUT_FILES.orthodoxPeriods)),
    sourceAudit: manifest.dynastyArtifact?.sourceAudit
  };
  validateRecords(artifact, availableIndexes);

  const dynastyManifest = manifest.dynastyArtifact;
  if (dynastyManifest !== undefined) {
    assertManifestCount(dynastyManifest, "totalDynasties", artifact.dynasties.length);
    assertManifestCount(dynastyManifest, "totalChineseDateExpressions", artifact.dateExpressions.length);
    assertManifestCount(dynastyManifest, "totalOrthodoxTraditions", artifact.orthodoxTraditions.length);
    assertManifestCount(dynastyManifest, "totalOrthodoxBoundaries", artifact.orthodoxBoundaries.length);
    assertManifestCount(dynastyManifest, "totalOrthodoxPeriods", artifact.orthodoxPeriods.length);
  }

  return {
    dynasties: artifact.dynasties.length,
    dateExpressions: artifact.dateExpressions.length,
    orthodoxTraditions: artifact.orthodoxTraditions.length,
    orthodoxBoundaries: artifact.orthodoxBoundaries.length,
    orthodoxPeriods: artifact.orthodoxPeriods.length
  };
}

function assertManifestCount(manifest, key, actual) {
  if (manifest[key] !== actual) {
    throw new Error(`Manifest ${key} ${manifest[key]} does not match actual count ${actual}.`);
  }
}

function validateRecords(artifact, availableIndexes) {
  const expressionIDs = new Set();
  for (const expression of artifact.dateExpressions) {
    requireStableID(expression.id, "ChineseDateExpression.id");
    if (expressionIDs.has(expression.id)) {
      throw new Error(`Duplicate ChineseDateExpression ${expression.id}.`);
    }
    expressionIDs.add(expression.id);
    validateDateExpression(expression, availableIndexes);
  }

  const dynastyIDs = new Set();
  for (const dynasty of artifact.dynasties) {
    requireStableID(dynasty.id, "Dynasty.id");
    requireNonEmptyString(dynasty.name, `Dynasty ${dynasty.id} name`);
    requireExpressionReference(expressionIDs, dynasty.claimedStartDateID, `Dynasty ${dynasty.id} claimedStartDateID`);
    requireExpressionReference(expressionIDs, dynasty.claimedEndDateID, `Dynasty ${dynasty.id} claimedEndDateID`);
    if (dynastyIDs.has(dynasty.id)) {
      throw new Error(`Duplicate Dynasty ${dynasty.id}.`);
    }
    dynastyIDs.add(dynasty.id);
  }

  const traditionIDs = new Set();
  for (const tradition of artifact.orthodoxTraditions) {
    requireStableID(tradition.id, "OrthodoxTradition.id");
    requireNonEmptyString(tradition.name, `OrthodoxTradition ${tradition.id} name`);
    if (traditionIDs.has(tradition.id)) {
      throw new Error(`Duplicate OrthodoxTradition ${tradition.id}.`);
    }
    traditionIDs.add(tradition.id);
  }

  const boundaryIDs = new Set();
  for (const boundary of artifact.orthodoxBoundaries) {
    requireStableID(boundary.id, "OrthodoxBoundary.id");
    requireReference(traditionIDs, boundary.traditionID, `OrthodoxBoundary ${boundary.id} traditionID`);
    requireExpressionReference(expressionIDs, boundary.dateExpressionID, `OrthodoxBoundary ${boundary.id} dateExpressionID`);
    if (boundaryIDs.has(boundary.id)) {
      throw new Error(`Duplicate OrthodoxBoundary ${boundary.id}.`);
    }
    boundaryIDs.add(boundary.id);
  }

  const periodIDs = new Set();
  for (const period of artifact.orthodoxPeriods) {
    requireStableID(period.id, "OrthodoxPeriod.id");
    requireReference(traditionIDs, period.traditionID, `OrthodoxPeriod ${period.id} traditionID`);
    requireReference(dynastyIDs, period.dynastyID, `OrthodoxPeriod ${period.id} dynastyID`);
    requireReference(boundaryIDs, period.startBoundaryID, `OrthodoxPeriod ${period.id} startBoundaryID`);
    requireReference(boundaryIDs, period.endBoundaryID, `OrthodoxPeriod ${period.id} endBoundaryID`);
    requireInteger(period.sequenceIndex, `OrthodoxPeriod ${period.id} sequenceIndex`);
    requireInteger(period.segmentIndex, `OrthodoxPeriod ${period.id} segmentIndex`);
    requireNonEmptyString(period.segmentName, `OrthodoxPeriod ${period.id} segmentName`);
    if (periodIDs.has(period.id)) {
      throw new Error(`Duplicate OrthodoxPeriod ${period.id}.`);
    }
    periodIDs.add(period.id);
  }

  const periodsBySequence = [...artifact.orthodoxPeriods].sort((left, right) => left.sequenceIndex - right.sequenceIndex);
  for (let index = 0; index < periodsBySequence.length; index += 1) {
    const period = periodsBySequence[index];
    const expectedSegmentIndex = ORTHODOX_SEGMENT_NAMES.indexOf(period.segmentName);
    if (period.sequenceIndex !== index) {
      throw new Error("OrthodoxPeriod sequenceIndex must be contiguous from zero.");
    }
    if (period.segmentIndex !== expectedSegmentIndex) {
      throw new Error(`OrthodoxPeriod ${period.id} has segmentIndex ${period.segmentIndex}, expected ${expectedSegmentIndex}.`);
    }
    if (index > 0 && period.segmentIndex < periodsBySequence[index - 1].segmentIndex) {
      throw new Error("OrthodoxPeriod segmentIndex must be nondecreasing in sequence order.");
    }
  }

  const compressedSegments = [];
  for (const period of periodsBySequence) {
    if (compressedSegments.at(-1) !== period.segmentName) {
      compressedSegments.push(period.segmentName);
    }
  }
  if (JSON.stringify(compressedSegments) !== JSON.stringify(ORTHODOX_SEGMENT_NAMES)) {
    throw new Error(
      `Orthodox segment sequence is ${compressedSegments.join(" -> ")}, ` +
      `expected ${ORTHODOX_SEGMENT_NAMES.join(" -> ")}.`
    );
  }
}

function validateDateExpression(expression, availableIndexes) {
  const precision = expression.precision;
  requireNonEmptyString(expression.sourceText, `ChineseDateExpression ${expression.id} sourceText`);
  if (!["year", "month", "day", "range", "unknown"].includes(precision)) {
    throw new Error(`Invalid ChineseDateExpression precision ${precision} for ${expression.id}.`);
  }

  if (precision === "year" || precision === "month" || precision === "day") {
    requireInteger(expression.index, `ChineseDateExpression ${expression.id} index`);
    if (expression.uncertainRange !== null && expression.uncertainRange !== undefined) {
      throw new Error(`ChineseDateExpression ${expression.id} must not have uncertainRange for ${precision} precision.`);
    }
    validatePointIndex(expression, availableIndexes);
    return;
  }

  if (precision === "range") {
    if (expression.index !== null && expression.index !== undefined) {
      throw new Error(`ChineseDateExpression ${expression.id} must not have index for range precision.`);
    }
    if (expression.uncertainRange === null || expression.uncertainRange === undefined) {
      throw new Error(`ChineseDateExpression ${expression.id} must have uncertainRange for range precision.`);
    }
    validateRange(expression.id, expression.uncertainRange, availableIndexes);
    return;
  }

  if (expression.index !== null && expression.index !== undefined) {
    throw new Error(`ChineseDateExpression ${expression.id} must not have index for unknown precision.`);
  }
  if (expression.uncertainRange !== null && expression.uncertainRange !== undefined) {
    throw new Error(`ChineseDateExpression ${expression.id} must not have uncertainRange for unknown precision.`);
  }
}

function validatePointIndex(expression, availableIndexes) {
  switch (expression.precision) {
    case "year":
      if (!availableIndexes.years.has(expression.index)) {
        throw new Error(`ChineseDateExpression ${expression.id} references missing lunar year ${expression.index}.`);
      }
      return;
    case "month":
      if (!availableIndexes.months.has(expression.index)) {
        throw new Error(`ChineseDateExpression ${expression.id} references missing lunar month ${expression.index}.`);
      }
      return;
    case "day":
      if (expression.index < availableIndexes.startDayIndex || expression.index > availableIndexes.endDayIndex) {
        throw new Error(`ChineseDateExpression ${expression.id} references missing dayIndex ${expression.index}.`);
      }
      return;
    default:
      return;
  }
}

function validateRange(expressionID, range, availableIndexes) {
  requireStableID(range.id, `ChineseDateRange id for ${expressionID}`);
  validateBound(expressionID, range.lowerBound, "lowerBound", availableIndexes);
  validateBound(expressionID, range.upperBound, "upperBound", availableIndexes);

  const lower = comparableBoundIndex(range.lowerBound);
  const upper = comparableBoundIndex(range.upperBound);
  if (lower.kind !== upper.kind) {
    throw new Error(`ChineseDateExpression ${expressionID} range bounds must use the same precision in v1 validation.`);
  }
  if (lower.index >= upper.index) {
    throw new Error(`ChineseDateExpression ${expressionID} range must satisfy lower < upper.`);
  }
}

function validateBound(expressionID, bound, fieldName, availableIndexes) {
  if (bound === null || typeof bound !== "object" || Array.isArray(bound)) {
    throw new Error(`ChineseDateExpression ${expressionID} ${fieldName} must be an object.`);
  }
  requireStableID(bound.id, `ChineseDateBound id for ${expressionID}`);
  if (!["year", "month", "day"].includes(bound.precision)) {
    throw new Error(`ChineseDateExpression ${expressionID} ${fieldName} has invalid precision ${bound.precision}.`);
  }
  requireInteger(bound.index, `ChineseDateExpression ${expressionID} ${fieldName}.index`);
  validatePointIndex({ id: `${expressionID}.${fieldName}`, precision: bound.precision, index: bound.index }, availableIndexes);
}

function comparableBoundIndex(bound) {
  return { kind: bound.precision, index: bound.index };
}

function requireExpressionReference(expressionIDs, id, context) {
  requireReference(expressionIDs, id, context);
}

function requireReference(ids, id, context) {
  requireStableID(id, context);
  if (!ids.has(id)) {
    throw new Error(`${context} references missing id ${id}.`);
  }
}

function requireStableID(value, context) {
  requireNonEmptyString(value, context);
  if (!/^[a-z0-9_]+$/.test(value)) {
    throw new Error(`${context} must be a stable lowercase snake_case identifier: ${value}.`);
  }
}

function requireNonEmptyString(value, context) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`${context} must be a non-empty string.`);
  }
}

function requireInteger(value, context) {
  if (!Number.isInteger(value)) {
    throw new Error(`${context} must be an integer.`);
  }
}

async function loadAvailableIndexes(output, manifest) {
  const years = new Set();
  const months = new Set();
  const yearFile = path.join(output, manifest?.files?.ChineseLunarYear ?? "chinese_lunar_years.jsonl");
  const monthFile = path.join(output, manifest?.files?.ChineseLunarMonth ?? "chinese_lunar_months.jsonl");

  for (const record of await readJsonl(yearFile)) {
    years.add(record.lunarYearNumber);
  }
  for (const record of await readJsonl(monthFile)) {
    months.add(record.lunarMonthIndex);
  }

  return {
    years,
    months,
    startDayIndex: manifest?.startDayIndex ?? 0,
    endDayIndex: manifest?.endDayIndex ?? Number.MAX_SAFE_INTEGER
  };
}

async function writeJsonl(filePath, records) {
  const writer = createWriteStream(filePath, { encoding: "utf8" });
  try {
    for (const record of records) {
      if (!writer.write(`${JSON.stringify(record)}\n`, "utf8")) {
        await once(writer, "drain");
      }
    }
  } finally {
    await new Promise((resolve, reject) => {
      writer.once("error", reject);
      writer.end(resolve);
    });
  }
}

async function readJsonl(filePath) {
  const text = await readFile(filePath, "utf8");
  return text
    .split("\n")
    .filter((line) => line.trim().length > 0)
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`Invalid JSON in ${filePath}:${index + 1}: ${error.message}`);
      }
    });
}

async function readRequiredJson(filePath) {
  return JSON.parse(await readFile(filePath, "utf8"));
}

async function readOptionalJson(filePath) {
  if (!(await pathExists(filePath))) {
    return undefined;
  }
  return readRequiredJson(filePath);
}

async function pathExists(filePath) {
  try {
    await stat(filePath);
    return true;
  } catch (error) {
    if (error?.code === "ENOENT") {
      return false;
    }
    throw error;
  }
}

function sha256Hex(value) {
  return createHash("sha256").update(value, "utf8").digest("hex");
}

function slugify(value) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
}

main().catch((error) => {
  console.error(error.stack ?? error.message);
  process.exit(1);
});
