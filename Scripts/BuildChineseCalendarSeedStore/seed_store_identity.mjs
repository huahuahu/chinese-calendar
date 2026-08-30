#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile, readdir, writeFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

export const SEED_STORE_FORMAT_VERSION = 4;
export const SEED_RECIPE_VERSION = 1;

export const BASE_INPUT_FILES = Object.freeze([
  "chinese_lunar_years.jsonl",
  "chinese_lunar_months.jsonl",
  "chinese_date_expressions.jsonl",
  "dynasties.jsonl",
  "emperors.jsonl",
  "emperor_reign_segments.jsonl",
  "reign_eras.jsonl",
  "orthodox_traditions.jsonl",
  "orthodox_boundaries.jsonl",
  "orthodox_periods.jsonl"
]);

const scriptPath = fileURLToPath(import.meta.url);
const scriptDirectory = path.dirname(scriptPath);
const repositoryRoot = path.resolve(scriptDirectory, "../..");
const defaultInputDirectory = path.join(repositoryRoot, "Data/Processed/swiftdata_import");
const defaultSchemaSource = path.join(
  repositoryRoot,
  "Sources/ChineseCalendarPersistence/PersistenceSupport.swift"
);

export async function calculateSeedStoreIdentity({
  inputDirectory,
  contentLevel,
  schemaSource = defaultSchemaSource,
  seedStoreFormatVersion = SEED_STORE_FORMAT_VERSION,
  seedRecipeVersion = SEED_RECIPE_VERSION
}) {
  if (contentLevel !== "base" && contentLevel !== "full") {
    throw new Error("contentLevel must be base or full.");
  }

  const schemaVersion = await readSchemaVersion(schemaSource);
  const inputFiles = await inputFilesForContentLevel(inputDirectory, contentLevel);
  const datasetVersion = await hashDataset(inputDirectory, inputFiles);
  const artifactDescription = {
    datasetVersion,
    schemaVersion,
    seedStoreFormatVersion,
    seedStoreContentLevel: contentLevel,
    seedRecipeVersion
  };
  const artifactVersion = sha256(JSON.stringify(artifactDescription));

  return {
    ...artifactDescription,
    artifactVersion,
    inputFiles
  };
}

export async function validateSeedStoreManifest(identity, manifestPath) {
  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") {
      throw new Error(`Bundled seed store manifest is missing: ${manifestPath}`);
    }
    throw error;
  }

  const identityKeys = [
    "datasetVersion",
    "schemaVersion",
    "seedStoreFormatVersion",
    "seedStoreContentLevel",
    "seedRecipeVersion",
    "artifactVersion"
  ];
  const mismatches = identityKeys.filter((key) => manifest[key] !== identity[key]);
  if (mismatches.length > 0) {
    const details = mismatches
      .map((key) => `${key}: expected ${JSON.stringify(identity[key])}, found ${JSON.stringify(manifest[key])}`)
      .join("; ");
    throw new Error(`Bundled seed store is stale (${details}). Run \`make seed-store\` from the repository root.`);
  }
}

async function readSchemaVersion(schemaSource) {
  const source = await readFile(schemaSource, "utf8");
  const match = source.match(/public static let versionIdentifier = "([^"]+)"/);
  if (!match) {
    throw new Error(`Unable to read ChineseCalendarModelSchema.versionIdentifier from ${schemaSource}.`);
  }
  return match[1];
}

async function inputFilesForContentLevel(inputDirectory, contentLevel) {
  const inputFiles = [...BASE_INPUT_FILES];
  if (contentLevel === "full") {
    const calendarDaysDirectory = path.join(inputDirectory, "calendar_days");
    const dayFiles = await collectJSONLFiles(calendarDaysDirectory, "calendar_days");
    inputFiles.push(...dayFiles);
  }
  return inputFiles.sort();
}

async function collectJSONLFiles(directory, relativeDirectory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const relativePath = path.posix.join(relativeDirectory, entry.name);
    const absolutePath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await collectJSONLFiles(absolutePath, relativePath)));
    } else if (entry.isFile() && entry.name.endsWith(".jsonl")) {
      files.push(relativePath);
    }
  }
  return files.sort();
}

async function hashDataset(inputDirectory, inputFiles) {
  const hash = createHash("sha256");
  hash.update("ChineseCalendarSeedStoreDataset-v1\0", "utf8");

  for (const relativePath of inputFiles) {
    const data = await readFile(path.join(inputDirectory, relativePath));
    hash.update(relativePath, "utf8");
    hash.update("\0", "utf8");
    hash.update(String(data.byteLength), "utf8");
    hash.update("\0", "utf8");
    hash.update(data);
    hash.update("\0", "utf8");
  }

  return hash.digest("hex");
}

function sha256(value) {
  return createHash("sha256").update(value, "utf8").digest("hex");
}

async function parseArguments(argumentsList) {
  const options = {
    inputDirectory: defaultInputDirectory,
    schemaSource: defaultSchemaSource,
    contentLevel: "base",
    checkManifest: undefined,
    output: undefined,
    help: false
  };

  for (let index = 0; index < argumentsList.length; index += 1) {
    const argument = argumentsList[index];
    switch (argument) {
      case "--input":
        options.inputDirectory = path.resolve(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--schema-source":
        options.schemaSource = path.resolve(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--content-level":
        options.contentLevel = requireOptionValue(argument, argumentsList[++index]);
        break;
      case "--check-manifest":
        options.checkManifest = path.resolve(requireOptionValue(argument, argumentsList[++index]));
        break;
      case "--output":
        options.output = path.resolve(requireOptionValue(argument, argumentsList[++index]));
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

function printHelp() {
  console.log(`Usage:
  node seed_store_identity.mjs [options]

Options:
  --input <path>            SwiftData import JSONL directory.
  --schema-source <path>    Swift source containing the model schema version identifier.
  --content-level <level>   Identity content level: base or full. Default: base
  --check-manifest <path>   Fail unless the manifest contains the calculated identity.
  --output <path>           Write the calculated identity JSON to this file.
  --help                    Show this help text.
`);
}

async function main() {
  const options = await parseArguments(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  const identity = await calculateSeedStoreIdentity(options);
  if (options.checkManifest) {
    await validateSeedStoreManifest(identity, options.checkManifest);
  }

  const output = `${JSON.stringify(identity, null, 2)}\n`;
  if (options.output) {
    await writeFile(options.output, output, "utf8");
  } else if (!options.checkManifest) {
    process.stdout.write(output);
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === scriptPath) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
