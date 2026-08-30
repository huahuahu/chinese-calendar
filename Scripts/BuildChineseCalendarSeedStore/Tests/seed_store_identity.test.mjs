import assert from "node:assert/strict";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import {
  BASE_INPUT_FILES,
  calculateSeedStoreIdentity,
  validateSeedStoreManifest
} from "../seed_store_identity.mjs";

test("dataset identity is stable across provenance changes and changes with semantic input", async () => {
  const fixture = await makeFixture();
  try {
    const first = await calculateBaseIdentity(fixture);
    await writeFile(path.join(fixture.root, "manifest.json"), '{"generatedAt":"later"}\n', "utf8");
    const provenanceOnly = await calculateBaseIdentity(fixture);
    assert.deepEqual(provenanceOnly, first);

    await writeFile(path.join(fixture.root, BASE_INPUT_FILES[0]), "changed\n", "utf8");
    const semanticChange = await calculateBaseIdentity(fixture);
    assert.notEqual(semanticChange.datasetVersion, first.datasetVersion);
    assert.notEqual(semanticChange.artifactVersion, first.artifactVersion);
  } finally {
    await fixture.remove();
  }
});

test("artifact identity changes with schema, format, content level, and recipe", async () => {
  const fixture = await makeFixture();
  try {
    const base = await calculateBaseIdentity(fixture);

    await writeFile(fixture.schemaSource, schemaSource("1.3.0"), "utf8");
    const schemaChange = await calculateBaseIdentity(fixture);
    assert.notEqual(schemaChange.artifactVersion, base.artifactVersion);

    await writeFile(fixture.schemaSource, schemaSource("1.2.0"), "utf8");
    const formatChange = await calculateBaseIdentity(fixture, { seedStoreFormatVersion: 5 });
    const recipeChange = await calculateBaseIdentity(fixture, { seedRecipeVersion: 2 });
    assert.notEqual(formatChange.artifactVersion, base.artifactVersion);
    assert.notEqual(recipeChange.artifactVersion, base.artifactVersion);

    const dayDirectory = path.join(fixture.root, "calendar_days/2000");
    await mkdir(dayDirectory, { recursive: true });
    await writeFile(path.join(dayDirectory, "calendar_days.jsonl"), "day\n", "utf8");
    const full = await calculateSeedStoreIdentity({
      inputDirectory: fixture.root,
      schemaSource: fixture.schemaSource,
      contentLevel: "full"
    });
    assert.notEqual(full.artifactVersion, base.artifactVersion);
  } finally {
    await fixture.remove();
  }
});

test("manifest validation ignores provenance but rejects a stale artifact", async () => {
  const fixture = await makeFixture();
  try {
    const identity = await calculateBaseIdentity(fixture);
    const manifestPath = path.join(fixture.root, "bundled-manifest.json");
    await writeFile(
      manifestPath,
      `${JSON.stringify({ ...identity, generatedAt: "provenance-only" })}\n`,
      "utf8"
    );
    await validateSeedStoreManifest(identity, manifestPath);

    await writeFile(
      manifestPath,
      `${JSON.stringify({ ...identity, artifactVersion: "stale" })}\n`,
      "utf8"
    );
    await assert.rejects(
      validateSeedStoreManifest(identity, manifestPath),
      /Run `make seed-store`/
    );
  } finally {
    await fixture.remove();
  }
});

async function makeFixture() {
  const root = await mkdtemp(path.join(os.tmpdir(), "seed-store-identity-"));
  const schemaSourcePath = path.join(root, "PersistenceSupport.swift");
  await writeFile(schemaSourcePath, schemaSource("1.2.0"), "utf8");
  await Promise.all(
    BASE_INPUT_FILES.map((file, index) => writeFile(path.join(root, file), `record-${index}\n`, "utf8"))
  );
  return {
    root,
    schemaSource: schemaSourcePath,
    remove: () => rm(root, { recursive: true, force: true })
  };
}

function calculateBaseIdentity(fixture, overrides = {}) {
  return calculateSeedStoreIdentity({
    inputDirectory: fixture.root,
    schemaSource: fixture.schemaSource,
    contentLevel: "base",
    ...overrides
  });
}

function schemaSource(version) {
  return `public enum ChineseCalendarModelSchema {\n    public static let versionIdentifier = "${version}"\n}\n`;
}
