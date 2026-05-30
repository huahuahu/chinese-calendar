#!/usr/bin/env node
import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, "../..");
const schemasDirectory = path.join(repositoryRoot, "Data/Schemas");
const defaultInput = path.join(repositoryRoot, "Data/Processed/swiftdata_import");

function usage() {
  return `
Usage: Scripts/DataSchemas/validate_swiftdata_import.mjs [options]

Options:
  --input <path>    SwiftData import JSONL directory. Default: Data/Processed/swiftdata_import
  --help            Print this help.
`;
}

function parseArguments(argv) {
  const options = { input: defaultInput };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    switch (argument) {
      case "--input":
        options.input = path.resolve(argv[++index]);
        break;
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

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const schemas = await loadSchemas();
  const manifest = await readJson(path.join(options.input, "manifest.json"));
  const files = plannedFiles(options.input, manifest, schemas);
  let recordCount = 0;

  for (const file of files) {
    const count = await validateJsonlFile(file.path, file.schema, file.label);
    recordCount += count;
  }

  console.log(`Validated ${recordCount} JSONL records in ${path.relative(repositoryRoot, options.input)}.`);
}

async function loadSchemas() {
  const files = (await readdir(schemasDirectory))
    .filter((fileName) => fileName.endsWith(".schema.json"))
    .sort();
  const schemas = new Map();

  for (const fileName of files) {
    const schema = await readJson(path.join(schemasDirectory, fileName));
    const codegen = schema["x-codegen"] ?? {};
    if (codegen.record) {
      schemas.set(codegen.typeName, schema);
    }
  }

  return schemas;
}

function plannedFiles(input, manifest, schemas) {
  const files = [];
  const manifestFiles = manifest.files ?? {};
  const explicitRecords = [
    "LunarYearRecord",
    "LunarMonthRecord",
    "ChineseDateExpressionRecord",
    "DynastyRecord",
    "OrthodoxTraditionRecord",
    "OrthodoxBoundaryRecord",
    "OrthodoxPeriodRecord"
  ];

  for (const recordType of explicitRecords) {
    const schema = requiredSchema(schemas, recordType);
    const schemaFile = schema["x-codegen"]?.dataFile;
    const manifestFile = manifestFiles[schema.title] ?? manifestFiles[recordType.replace(/Record$/, "")];
    const file = manifestFile ?? schemaFile;
    if (file) {
      files.push({ path: path.join(input, file), schema, label: file });
    }
  }

  const calendarDaySchema = requiredSchema(schemas, "CalendarDayBundleRecord");
  for (let year = manifest.startYear; year <= manifest.endYear; year += 1) {
    const file = `calendar_days/${year}/calendar_days.jsonl`;
    files.push({ path: path.join(input, file), schema: calendarDaySchema, label: file });
  }

  return files;
}

function requiredSchema(schemas, typeName) {
  const schema = schemas.get(typeName);
  if (!schema) {
    throw new Error(`Missing schema for ${typeName}`);
  }
  return schema;
}

async function validateJsonlFile(filePath, schema, label) {
  try {
    const stats = await stat(filePath);
    if (!stats.isFile()) {
      throw new Error(`${label} is not a file.`);
    }
  } catch (error) {
    throw new Error(`Missing JSONL file for schema ${schema.title}: ${filePath}. ${error.message}`);
  }

  const text = await readFile(filePath, "utf8");
  const lines = text.split("\n");
  let count = 0;
  for (let lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
    const line = lines[lineIndex];
    if (line.length === 0) {
      continue;
    }

    let value;
    try {
      value = JSON.parse(line);
    } catch (error) {
      throw new Error(`${label}:${lineIndex + 1}: invalid JSON. ${error.message}`);
    }

    validate(value, schema, schema, `${label}:${lineIndex + 1}`);
    count += 1;
  }

  return count;
}

function validate(value, schema, rootSchema, location) {
  if (schema.$ref) {
    return validate(value, resolveReference(schema.$ref, rootSchema), rootSchema, location);
  }

  if (Array.isArray(schema.anyOf)) {
    const errors = [];
    for (const option of schema.anyOf) {
      try {
        validate(value, option, rootSchema, location);
        return;
      } catch (error) {
        errors.push(error.message);
      }
    }
    throw new Error(`${location}: does not match any allowed shape. ${errors.join(" | ")}`);
  }

  const allowedTypes = Array.isArray(schema.type) ? schema.type : [schema.type];
  if (!allowedTypes.some((typeName) => matchesType(value, typeName))) {
    throw new Error(`${location}: expected ${allowedTypes.join(" or ")}, got ${actualType(value)}.`);
  }

  if (value === null) {
    return;
  }

  if (schema.enum && !schema.enum.includes(value)) {
    throw new Error(`${location}: expected one of ${schema.enum.join(", ")}, got ${JSON.stringify(value)}.`);
  }

  if (typeof value === "number") {
    if (schema.minimum !== undefined && value < schema.minimum) {
      throw new Error(`${location}: expected >= ${schema.minimum}, got ${value}.`);
    }
    if (schema.maximum !== undefined && value > schema.maximum) {
      throw new Error(`${location}: expected <= ${schema.maximum}, got ${value}.`);
    }
  }

  if (typeof value === "string" && schema.minLength !== undefined && value.length < schema.minLength) {
    throw new Error(`${location}: expected string length >= ${schema.minLength}.`);
  }

  if (schema.type === "object") {
    validateObject(value, schema, rootSchema, location);
  }
}

function validateObject(value, schema, rootSchema, location) {
  const properties = schema.properties ?? {};
  const required = new Set(schema.required ?? []);
  for (const key of required) {
    if (!(key in value)) {
      throw new Error(`${location}: missing required property ${key}.`);
    }
  }

  if (schema.additionalProperties === false) {
    for (const key of Object.keys(value)) {
      if (!(key in properties)) {
        throw new Error(`${location}: unexpected property ${key}.`);
      }
    }
  }

  for (const [key, propertySchema] of Object.entries(properties)) {
    if (key in value) {
      validate(value[key], propertySchema, rootSchema, `${location}.${key}`);
    }
  }
}

function matchesType(value, typeName) {
  switch (typeName) {
    case "object":
      return typeof value === "object" && value !== null && !Array.isArray(value);
    case "integer":
      return Number.isInteger(value);
    case "number":
      return typeof value === "number" && Number.isFinite(value);
    case "string":
      return typeof value === "string";
    case "boolean":
      return typeof value === "boolean";
    case "null":
      return value === null;
    default:
      throw new Error(`Unsupported schema type: ${typeName}`);
  }
}

function actualType(value) {
  if (value === null) {
    return "null";
  }
  if (Array.isArray(value)) {
    return "array";
  }
  return typeof value;
}

function resolveReference(reference, rootSchema) {
  const prefix = "#/$defs/";
  if (!reference.startsWith(prefix)) {
    throw new Error(`Unsupported reference: ${reference}`);
  }
  const definitionName = reference.slice(prefix.length);
  const definition = rootSchema.$defs?.[definitionName];
  if (!definition) {
    throw new Error(`Missing schema definition: ${definitionName}`);
  }
  return definition;
}

async function readJson(filePath) {
  return JSON.parse(await readFile(filePath, "utf8"));
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
