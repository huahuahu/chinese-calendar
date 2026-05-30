#!/usr/bin/env node
import { createReadStream } from "node:fs";
import { mkdir, readFile, readdir, rename, stat, writeFile } from "node:fs/promises";
import http from "node:http";
import path from "node:path";
import { spawn } from "node:child_process";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, "../..");
const dataRoot = path.join(repositoryRoot, "Data/Processed/swiftdata_import");
const publicRoot = path.join(scriptDirectory, "public");
const schemasRoot = path.join(repositoryRoot, "Data/Schemas");

const heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"];
const earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];
const zodiacAnimals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"];

const datasets = [
  {
    id: "lunar-years",
    label: "年",
    detail: "ChineseLunarYear",
    recordType: "ChineseLunarYearRecord",
    schema: "chinese_lunar_year.schema.json",
    file: "chinese_lunar_years.jsonl",
    keyPath: "lunarYearNumber"
  },
  {
    id: "lunar-months",
    label: "月",
    detail: "ChineseLunarMonth",
    recordType: "ChineseLunarMonthRecord",
    schema: "chinese_lunar_month.schema.json",
    file: "chinese_lunar_months.jsonl",
    keyPath: "lunarMonthIndex"
  },
  {
    id: "calendar-days",
    label: "日",
    detail: "CalendarDayBundleByCivilYear",
    recordType: "CalendarDayBundleRecord",
    schema: "calendar_day_bundle.schema.json",
    yearScoped: true,
    keyPath: "calendarDay.dayIndex"
  },
  {
    id: "dynasties",
    label: "朝代",
    detail: "Dynasty",
    recordType: "DynastyRecord",
    schema: "dynasty.schema.json",
    file: "dynasties.jsonl",
    keyPath: "id"
  },
  {
    id: "date-expressions",
    label: "日期表达",
    detail: "ChineseDateExpression",
    recordType: "ChineseDateExpressionRecord",
    schema: "chinese_date_expression.schema.json",
    file: "chinese_date_expressions.jsonl",
    keyPath: "id"
  },
  {
    id: "orthodox-traditions",
    label: "正统叙事",
    detail: "OrthodoxTradition",
    recordType: "OrthodoxTraditionRecord",
    schema: "orthodox_tradition.schema.json",
    file: "orthodox_traditions.jsonl",
    keyPath: "id"
  },
  {
    id: "orthodox-boundaries",
    label: "正统边界",
    detail: "OrthodoxBoundary",
    recordType: "OrthodoxBoundaryRecord",
    schema: "orthodox_boundary.schema.json",
    file: "orthodox_boundaries.jsonl",
    keyPath: "id"
  },
  {
    id: "orthodox-periods",
    label: "正统时期",
    detail: "OrthodoxPeriod",
    recordType: "OrthodoxPeriodRecord",
    schema: "orthodox_period.schema.json",
    file: "orthodox_periods.jsonl",
    keyPath: "id"
  }
];

const datasetByID = new Map(datasets.map((dataset) => [dataset.id, dataset]));

function usage() {
  return `
Usage: Scripts/DataAdmin/server.mjs [options]

Options:
  --host <host>    Host to bind. Default: 127.0.0.1
  --port <port>    Port to bind. Default: 5177
  --help           Print this help.
`;
}

function parseArguments(argv) {
  const options = {
    host: process.env.CHINESE_CALENDAR_DATA_ADMIN_HOST ?? "127.0.0.1",
    port: Number(process.env.CHINESE_CALENDAR_DATA_ADMIN_PORT ?? 5177)
  };

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    switch (argument) {
      case "--host":
        options.host = requiredValue(argv, argument, ++index);
        break;
      case "--port": {
        const value = Number(requiredValue(argv, argument, ++index));
        if (!Number.isInteger(value) || value <= 0) {
          throw new Error("--port must be a positive integer.");
        }
        options.port = value;
        break;
      }
      case "--help":
      case "-h":
        console.log(usage().trim());
        process.exit(0);
      default:
        throw new Error(`Unknown argument: ${argument}`);
    }
  }

  return options;
}

function requiredValue(argv, argument, index) {
  if (index >= argv.length) {
    throw new Error(`Missing value after ${argument}.`);
  }
  return argv[index];
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const server = http.createServer((request, response) => {
    handleRequest(request, response).catch((error) => {
      sendJSON(response, error.statusCode ?? 500, {
        error: error.message ?? "Unexpected server error."
      });
    });
  });

  server.listen(options.port, options.host, () => {
    console.log(`Chinese Calendar Data Admin running at http://${options.host}:${options.port}`);
  });
}

async function handleRequest(request, response) {
  const url = new URL(request.url ?? "/", "http://localhost");

  if (url.pathname === "/api/meta" && request.method === "GET") {
    return sendJSON(response, 200, await metaResponse());
  }

  if (url.pathname === "/api/records" && request.method === "GET") {
    return sendJSON(response, 200, await recordsResponse(url.searchParams));
  }

  if (url.pathname === "/api/record" && request.method === "PUT") {
    return sendJSON(response, 200, await updateRecordResponse(await readBody(request)));
  }

  if (url.pathname === "/api/diff" && request.method === "GET") {
    return sendJSON(response, 200, await diffResponse(url.searchParams));
  }

  if (url.pathname === "/api/commands/validate" && request.method === "POST") {
    return sendJSON(response, 200, await validateResponse());
  }

  if (url.pathname === "/api/commands/build-seed" && request.method === "POST") {
    return sendJSON(response, 200, await buildSeedResponse());
  }

  return serveStatic(url.pathname, response);
}

async function metaResponse() {
  const manifest = await readOptionalJSON(path.join(dataRoot, "manifest.json"));
  const schemaDescriptions = await loadSchemaDescriptions();
  const yearDirectories = await listCalendarYears();
  const datasetMetadata = await Promise.all(datasets.map(async (dataset) => {
    const filePath = dataset.yearScoped ? null : resolveDatasetFile(dataset, null);
    return {
      ...publicDatasetFields(dataset),
      path: dataset.yearScoped ? "calendar_days/<year>/calendar_days.jsonl" : relativeToRoot(filePath),
      recordCount: dataset.yearScoped ? manifest?.totalCalendarDays ?? null : await countLinesIfPresent(filePath),
      schema: schemaDescriptions[dataset.id] ?? {},
      selectedYearCount: null
    };
  }));

  return {
    repositoryRoot,
    dataRoot: relativeToRoot(dataRoot),
    manifest: manifestSummary(manifest),
    calendarYears: yearDirectories,
    datasets: datasetMetadata
  };
}

async function loadSchemaDescriptions() {
  const result = {};
  for (const dataset of datasets) {
    const schema = await readOptionalJSON(path.join(schemasRoot, dataset.schema));
    if (!schema) {
      result[dataset.id] = {};
      continue;
    }
    result[dataset.id] = extractDescriptions(schema);
  }
  return result;
}

function extractDescriptions(schema) {
  const descriptions = {};
  collectDescriptions(schema, schema, "", descriptions);
  return descriptions;
}

function collectDescriptions(schema, rootSchema, prefix, descriptions) {
  const resolved = schema.$ref ? resolveSchemaReference(schema.$ref, rootSchema) : schema;
  const description = schema.description ?? resolved.description;
  if (description && prefix) {
    descriptions[prefix] = description;
  }

  const properties = resolved.properties ?? {};
  for (const [key, propertySchema] of Object.entries(properties)) {
    const pathPrefix = prefix ? `${prefix}.${key}` : key;
    collectDescriptions(propertySchema, rootSchema, pathPrefix, descriptions);
  }
}

function resolveSchemaReference(reference, rootSchema) {
  const prefix = "#/$defs/";
  if (!reference.startsWith(prefix)) {
    throw new Error(`Unsupported schema reference: ${reference}`);
  }
  const key = reference.slice(prefix.length);
  const definition = rootSchema.$defs?.[key];
  if (!definition) {
    throw new Error(`Missing schema definition: ${reference}`);
  }
  return definition;
}

function publicDatasetFields(dataset) {
  return {
    id: dataset.id,
    label: dataset.label,
    detail: dataset.detail,
    recordType: dataset.recordType,
    yearScoped: Boolean(dataset.yearScoped),
    keyPath: dataset.keyPath
  };
}

function manifestSummary(manifest) {
  if (!manifest) {
    return null;
  }
  return {
    generatedAt: manifest.generatedAt ?? null,
    startYear: manifest.startYear ?? null,
    endYear: manifest.endYear ?? null,
    totalCalendarDays: manifest.totalCalendarDays ?? null,
    totalChineseLunarYears: manifest.totalChineseLunarYears ?? null,
    totalChineseLunarMonths: manifest.totalChineseLunarMonths ?? null,
    totalDynasties: manifest.dynastyArtifact?.totalDynasties ?? null,
    sourceUpstreamCommit: manifest.sourceUpstreamCommit ?? null
  };
}

async function recordsResponse(searchParams) {
  const dataset = requiredDataset(searchParams.get("dataset"));
  const filePath = resolveDatasetFile(dataset, searchParams.get("year"));
  const limit = integerParam(searchParams, "limit", 200, { min: 1, max: 1000 });
  const offset = integerParam(searchParams, "offset", 0, { min: 0, max: Number.MAX_SAFE_INTEGER });
  const query = (searchParams.get("query") ?? "").trim().toLowerCase();

  const records = [];
  let matchedCount = 0;
  let lineNumber = 0;
  let invalidCount = 0;

  for await (const line of readLines(filePath)) {
    lineNumber += 1;
    if (line.length === 0) {
      continue;
    }

    let record = null;
    let parseError = null;
    try {
      record = JSON.parse(line);
    } catch (error) {
      parseError = error.message;
      invalidCount += 1;
    }

    const searchable = `${line} ${record ? summarizeRecord(dataset.id, record) : ""}`.toLowerCase();
    if (query && !searchable.includes(query)) {
      continue;
    }

    matchedCount += 1;
    if (matchedCount <= offset || records.length >= limit) {
      continue;
    }

    records.push({
      lineNumber,
      key: record ? valueAtPath(record, dataset.keyPath) : null,
      summary: record ? summarizeRecord(dataset.id, record) : "Invalid JSON",
      readable: record ? readableRecord(dataset.id, record) : [],
      raw: line,
      record,
      parseError
    });
  }

  return {
    dataset: publicDatasetFields(dataset),
    path: relativeToRoot(filePath),
    fileRecordCount: lineNumber,
    matchedCount,
    invalidCount,
    offset,
    limit,
    records
  };
}

async function updateRecordResponse(body) {
  const payload = parseJSON(body, "Request body");
  const dataset = requiredDataset(payload.dataset);
  const filePath = resolveDatasetFile(dataset, payload.year ?? null);
  const lineNumber = payload.lineNumber;
  if (!Number.isInteger(lineNumber) || lineNumber < 1) {
    throw httpError(400, "lineNumber must be a positive integer.");
  }

  const nextRecord = payload.raw !== undefined
    ? parseJSON(String(payload.raw), "JSONL line")
    : payload.record;

  if (!nextRecord || typeof nextRecord !== "object" || Array.isArray(nextRecord)) {
    throw httpError(400, "Record must be a JSON object.");
  }

  const nextLine = JSON.stringify(nextRecord);
  await replaceLine(filePath, lineNumber, nextLine);

  return {
    ok: true,
    dataset: publicDatasetFields(dataset),
    path: relativeToRoot(filePath),
    lineNumber,
    raw: nextLine,
    record: nextRecord,
    summary: summarizeRecord(dataset.id, nextRecord),
    readable: readableRecord(dataset.id, nextRecord)
  };
}

async function diffResponse(searchParams) {
  const dataset = requiredDataset(searchParams.get("dataset"));
  const filePath = resolveDatasetFile(dataset, searchParams.get("year"));
  const result = await runCommand("git", ["diff", "--", relativeToRoot(filePath)]);
  return {
    ok: result.status === 0,
    path: relativeToRoot(filePath),
    diff: result.output,
    status: result.status
  };
}

async function validateResponse() {
  const steps = [
    {
      label: "Generated schema artifacts",
      command: "Scripts/DataSchemas/generate_schema_artifacts.swift",
      args: ["--check"]
    },
    {
      label: "JSON schema",
      command: "Scripts/DataSchemas/validate_swiftdata_import.swift",
      args: []
    },
    {
      label: "Calendar import invariants",
      command: "Scripts/ImportChineseCalendar/generate_swiftdata_import.swift",
      args: ["--validate-only"]
    },
    {
      label: "Dynasty import invariants",
      command: "Scripts/ImportChineseCalendar/generate_dynasty_periods.swift",
      args: ["--validate-only"]
    }
  ];
  return runSteps(steps);
}

async function buildSeedResponse() {
  return runSteps([
    {
      label: "SwiftData SQLite seed store",
      command: "Scripts/BuildChineseCalendarSeedStore/generate_seed_store_if_needed.sh",
      args: []
    }
  ]);
}

async function runSteps(steps) {
  const results = [];
  for (const step of steps) {
    const result = await runCommand(step.command, step.args);
    results.push({ ...step, ...result });
    if (result.status !== 0) {
      return { ok: false, results };
    }
  }
  return { ok: true, results };
}

async function runCommand(command, args) {
  return new Promise((resolve) => {
    const executable = command.includes("/") ? path.join(repositoryRoot, command) : command;
    const child = spawn(executable, args, {
      cwd: repositoryRoot,
      env: command.endsWith("generate_seed_store_if_needed.sh")
        ? withoutKeys(process.env, ["SDKROOT", "TOOLCHAINS"])
        : process.env
    });
    let output = "";
    child.stdout.on("data", (chunk) => { output += chunk; });
    child.stderr.on("data", (chunk) => { output += chunk; });
    child.on("error", (error) => {
      resolve({ status: 1, output: error.message });
    });
    child.on("close", (status) => {
      resolve({ status, output: output.trimEnd() });
    });
  });
}

function withoutKeys(env, keys) {
  const next = { ...env };
  for (const key of keys) {
    delete next[key];
  }
  return next;
}

async function replaceLine(filePath, lineNumber, nextLine) {
  const text = await readFile(filePath, "utf8");
  const lines = text.endsWith("\n") ? text.slice(0, -1).split("\n") : text.split("\n");
  if (lineNumber > lines.length) {
    throw httpError(400, `Line ${lineNumber} does not exist in ${relativeToRoot(filePath)}.`);
  }

  lines[lineNumber - 1] = nextLine;
  const output = `${lines.join("\n")}\n`;
  const temporaryPath = `${filePath}.tmp-${process.pid}-${Date.now()}`;
  await writeFile(temporaryPath, output, "utf8");
  await rename(temporaryPath, filePath);
}

async function* readLines(filePath) {
  const input = createReadStream(filePath, { encoding: "utf8" });
  const reader = createInterface({ input, crlfDelay: Infinity });
  for await (const line of reader) {
    yield line;
  }
}

async function listCalendarYears() {
  const calendarRoot = path.join(dataRoot, "calendar_days");
  try {
    const entries = await readdir(calendarRoot, { withFileTypes: true });
    return entries
      .filter((entry) => entry.isDirectory() && /^-?\d+$/.test(entry.name))
      .map((entry) => Number(entry.name))
      .sort((lhs, rhs) => lhs - rhs);
  } catch {
    return [];
  }
}

async function countLinesIfPresent(filePath) {
  if (!filePath) {
    return null;
  }
  try {
    let count = 0;
    for await (const line of readLines(filePath)) {
      if (line.length > 0) {
        count += 1;
      }
    }
    return count;
  } catch {
    return null;
  }
}

function requiredDataset(id) {
  const dataset = datasetByID.get(id ?? "");
  if (!dataset) {
    throw httpError(400, `Unknown dataset: ${id ?? ""}.`);
  }
  return dataset;
}

function resolveDatasetFile(dataset, yearValue) {
  const relativePath = dataset.yearScoped
    ? `calendar_days/${requiredYear(yearValue)}/calendar_days.jsonl`
    : dataset.file;
  const filePath = path.resolve(dataRoot, relativePath);
  const relative = path.relative(dataRoot, filePath);
  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw httpError(400, "Resolved path escapes the data root.");
  }
  return filePath;
}

function requiredYear(value) {
  const year = Number(value);
  if (!Number.isInteger(year)) {
    throw httpError(400, "A civil year is required for calendar day records.");
  }
  return String(year);
}

function integerParam(searchParams, key, defaultValue, bounds) {
  const rawValue = searchParams.get(key);
  if (rawValue === null || rawValue === "") {
    return defaultValue;
  }
  const value = Number(rawValue);
  if (!Number.isInteger(value) || value < bounds.min || value > bounds.max) {
    throw httpError(400, `${key} must be an integer between ${bounds.min} and ${bounds.max}.`);
  }
  return value;
}

function summarizeRecord(datasetID, record) {
  switch (datasetID) {
    case "lunar-years":
      return `农历年 ${record.lunarYearNumber} · ${stemBranch(record.yearStemIndex, record.yearBranchIndex)}`;
    case "lunar-months":
      return `农历 ${record.lunarYearNumber} 年 ${lunarMonthName(record)} · ${record.dayCount} 日 · ${stemBranch(record.monthStemIndex, record.monthBranchIndex)}`;
    case "calendar-days":
      return `${record.civilDate?.year}-${pad(record.civilDate?.month)}-${pad(record.civilDate?.dayOfMonth)} -> 月 ${record.chineseLunarDay?.lunarMonthIndex} 日 ${record.chineseLunarDay?.dayNumberInMonth} · ${stemBranch(record.chineseLunarDay?.dayStemIndex, record.chineseLunarDay?.dayBranchIndex)}`;
    case "dynasties":
      return `${record.name}${record.shortName ? ` (${record.shortName})` : ""}`;
    case "date-expressions":
      return `${record.id}: ${record.sourceText}`;
    case "orthodox-traditions":
      return record.name;
    case "orthodox-boundaries":
      return `${record.id}: ${record.dateExpressionID}`;
    case "orthodox-periods":
      return `${record.sequenceIndex}. ${record.segmentName} / ${record.dynastyID}`;
    default:
      return JSON.stringify(record);
  }
}

function readableRecord(datasetID, record) {
  switch (datasetID) {
    case "lunar-years":
      return [
        item("农历年编号", record.lunarYearNumber, "lunarYearNumber"),
        item("年天干", stemName(record.yearStemIndex), "yearStemIndex"),
        item("年地支", branchName(record.yearBranchIndex), "yearBranchIndex"),
        item("年干支", stemBranch(record.yearStemIndex, record.yearBranchIndex)),
        item("生肖", zodiacName(record.yearBranchIndex))
      ];
    case "lunar-months":
      return [
        item("农历月索引", record.lunarMonthIndex, "lunarMonthIndex"),
        item("所属农历年", record.lunarYearNumber, "lunarYearNumber"),
        item("月名", lunarMonthName(record), "monthNumberInYear"),
        item("是否闰月", record.isLeapMonth ? "是" : "否", "isLeapMonth"),
        item("置闰显示", intercalaryStyleName(record.intercalaryMonthNameStyle), "intercalaryMonthNameStyle"),
        item("本月天数", `${record.dayCount} 天（${record.dayCount === 29 ? "小月" : "大月"}）`, "dayCount"),
        item("月天干", stemName(record.monthStemIndex), "monthStemIndex"),
        item("月地支", branchName(record.monthBranchIndex), "monthBranchIndex"),
        item("月干支", stemBranch(record.monthStemIndex, record.monthBranchIndex))
      ];
    case "calendar-days":
      return [
        item("绝对日索引", record.calendarDay?.dayIndex, "calendarDay.dayIndex"),
        item("Julian Day Number", record.calendarDay?.julianDayNumber, "calendarDay.julianDayNumber"),
        item("民用日期", civilDateLabel(record.civilDate), "civilDate"),
        item("历法", civilCalendarStyleName(record.civilDate?.calendarStyle), "civilDate.calendarStyle"),
        item("农历月索引", record.chineseLunarDay?.lunarMonthIndex, "chineseLunarDay.lunarMonthIndex"),
        item("农历月内日序", record.chineseLunarDay?.dayNumberInMonth, "chineseLunarDay.dayNumberInMonth"),
        item("日天干", stemName(record.chineseLunarDay?.dayStemIndex), "chineseLunarDay.dayStemIndex"),
        item("日地支", branchName(record.chineseLunarDay?.dayBranchIndex), "chineseLunarDay.dayBranchIndex"),
        item("日干支", stemBranch(record.chineseLunarDay?.dayStemIndex, record.chineseLunarDay?.dayBranchIndex)),
        item("日生肖", zodiacName(record.chineseLunarDay?.dayBranchIndex))
      ];
    case "dynasties":
      return [
        item("标识符", record.id, "id"),
        item("名称", record.name, "name"),
        item("简称", record.shortName ?? "无", "shortName"),
        item("开始日期 ID", record.claimedStartDateID, "claimedStartDateID"),
        item("结束日期 ID", record.claimedEndDateID, "claimedEndDateID"),
        item("说明", record.note ?? "无", "note")
      ];
    case "date-expressions":
      return [
        item("标识符", record.id, "id"),
        item("日期精度", precisionName(record.precision), "precision"),
        item("日期索引", record.index ?? "无", "index"),
        item("来源原文", record.sourceText, "sourceText"),
        item("说明", record.note ?? "无", "note")
      ];
    case "orthodox-traditions":
      return [item("标识符", record.id, "id"), item("名称", record.name, "name"), item("说明", record.note ?? "无", "note")];
    case "orthodox-boundaries":
      return [
        item("标识符", record.id, "id"),
        item("正统叙事 ID", record.traditionID, "traditionID"),
        item("日期表达 ID", record.dateExpressionID, "dateExpressionID"),
        item("说明", record.note ?? "无", "note")
      ];
    case "orthodox-periods":
      return [
        item("标识符", record.id, "id"),
        item("正统叙事 ID", record.traditionID, "traditionID"),
        item("朝代 ID", record.dynastyID, "dynastyID"),
        item("开始边界 ID", record.startBoundaryID, "startBoundaryID"),
        item("结束边界 ID", record.endBoundaryID, "endBoundaryID"),
        item("全局顺序", record.sequenceIndex, "sequenceIndex"),
        item("分段顺序", record.segmentIndex, "segmentIndex"),
        item("分段名称", record.segmentName, "segmentName"),
        item("说明", record.note ?? "无", "note")
      ];
    default:
      return [];
  }
}

function item(label, value, pathName = null) {
  return { label, value: String(value ?? "无"), path: pathName };
}

function stemName(index) {
  return indexedName(heavenlyStems, index, "天干");
}

function branchName(index) {
  return indexedName(earthlyBranches, index, "地支");
}

function zodiacName(branchIndex) {
  if (!Number.isInteger(branchIndex) || branchIndex < 0 || branchIndex >= zodiacAnimals.length) {
    return "未知";
  }
  return `${zodiacAnimals[branchIndex]}（${branchIndex}）`;
}

function indexedName(values, index, label) {
  if (!Number.isInteger(index) || index < 0 || index >= values.length) {
    return `未知${label}`;
  }
  return `${values[index]}（${index}）`;
}

function stemBranch(stemIndex, branchIndex) {
  if (!Number.isInteger(stemIndex) || !Number.isInteger(branchIndex)) {
    return "未知干支";
  }
  return `${heavenlyStems[stemIndex] ?? "?"}${earthlyBranches[branchIndex] ?? "?"}（${stemIndex}/${branchIndex}）`;
}

function lunarMonthName(record) {
  const prefix = record.isLeapMonth
    ? record.intercalaryMonthNameStyle === "post" ? "后" : "闰"
    : "";
  return `${prefix}${record.monthNumberInYear} 月`;
}

function intercalaryStyleName(style) {
  switch (style) {
    case "leap":
      return "闰月（闰 X 月）";
    case "post":
      return "后月（后 X 月）";
    default:
      return String(style ?? "未知");
  }
}

function civilDateLabel(civilDate) {
  if (!civilDate) {
    return "未知";
  }
  return `${civilDate.year}-${pad(civilDate.month)}-${pad(civilDate.dayOfMonth)}`;
}

function civilCalendarStyleName(style) {
  switch (style) {
    case "gregorian":
      return "格里历（gregorian）";
    case "julian":
      return "儒略历（julian）";
    default:
      return String(style ?? "未知");
  }
}

function precisionName(precision) {
  switch (precision) {
    case "year":
      return "年精度";
    case "month":
      return "月精度";
    case "day":
      return "日精度";
    case "range":
      return "范围";
    case "unknown":
      return "未知";
    default:
      return String(precision ?? "未知");
  }
}

function pad(value) {
  return String(value ?? "?").padStart(2, "0");
}

function valueAtPath(record, keyPath) {
  return keyPath.split(".").reduce((value, key) => value?.[key], record) ?? null;
}

async function serveStatic(pathname, response) {
  const normalizedPath = pathname === "/" ? "/index.html" : pathname;
  const filePath = path.resolve(publicRoot, `.${decodeURIComponent(normalizedPath)}`);
  const relative = path.relative(publicRoot, filePath);
  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw httpError(404, "Not found.");
  }

  try {
    const fileStat = await stat(filePath);
    if (!fileStat.isFile()) {
      throw httpError(404, "Not found.");
    }
  } catch {
    throw httpError(404, "Not found.");
  }

  response.writeHead(200, {
    "Content-Type": contentType(filePath),
    "Cache-Control": "no-store"
  });
  createReadStream(filePath).pipe(response);
}

function contentType(filePath) {
  switch (path.extname(filePath)) {
    case ".html":
      return "text/html; charset=utf-8";
    case ".css":
      return "text/css; charset=utf-8";
    case ".js":
      return "text/javascript; charset=utf-8";
    case ".json":
      return "application/json; charset=utf-8";
    default:
      return "application/octet-stream";
  }
}

function parseJSON(text, label) {
  try {
    return JSON.parse(text);
  } catch (error) {
    throw httpError(400, `${label} is not valid JSON. ${error.message}`);
  }
}

async function readOptionalJSON(filePath) {
  try {
    return JSON.parse(await readFile(filePath, "utf8"));
  } catch {
    return null;
  }
}

async function readBody(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString("utf8");
}

function sendJSON(response, statusCode, value) {
  response.writeHead(statusCode, { "Content-Type": "application/json; charset=utf-8" });
  response.end(`${JSON.stringify(value)}\n`);
}

function relativeToRoot(filePath) {
  return path.relative(repositoryRoot, filePath);
}

function httpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
