const pageSize = 200;

const state = {
  meta: null,
  datasetID: "calendar-days",
  year: null,
  query: "",
  offset: 0,
  selected: null,
  recordsResponse: null
};

const elements = {
  dataRoot: document.querySelector("#data-root"),
  datasetList: document.querySelector("#dataset-list"),
  manifestSummary: document.querySelector("#manifest-summary"),
  yearField: document.querySelector("#year-field"),
  yearSelect: document.querySelector("#year-select"),
  queryInput: document.querySelector("#query-input"),
  reloadButton: document.querySelector("#reload-button"),
  diffButton: document.querySelector("#diff-button"),
  validateButton: document.querySelector("#validate-button"),
  buildButton: document.querySelector("#build-button"),
  datasetTitle: document.querySelector("#dataset-title"),
  filePath: document.querySelector("#file-path"),
  recordCount: document.querySelector("#record-count"),
  recordList: document.querySelector("#record-list"),
  previousButton: document.querySelector("#previous-button"),
  nextButton: document.querySelector("#next-button"),
  pageLabel: document.querySelector("#page-label"),
  editorTitle: document.querySelector("#editor-title"),
  editorSubtitle: document.querySelector("#editor-subtitle"),
  saveButton: document.querySelector("#save-button"),
  readablePreview: document.querySelector("#readable-preview"),
  jsonEditor: document.querySelector("#json-editor"),
  editorMessage: document.querySelector("#editor-message"),
  commandOutput: document.querySelector("#command-output"),
  outputSubtitle: document.querySelector("#output-subtitle"),
  clearOutputButton: document.querySelector("#clear-output-button")
};

init().catch((error) => {
  appendOutput(`Failed to load Data Admin.\n${error.message}`);
});

async function init() {
  bindEvents();
  state.meta = await getJSON("/api/meta");
  state.year = defaultYear(state.meta.calendarYears);
  renderMeta();
  await loadRecords();
}

function bindEvents() {
  elements.yearSelect.addEventListener("change", async () => {
    state.year = Number(elements.yearSelect.value);
    state.offset = 0;
    await loadRecords();
  });

  elements.queryInput.addEventListener("input", debounce(async () => {
    state.query = elements.queryInput.value;
    state.offset = 0;
    await loadRecords();
  }, 220));

  elements.reloadButton.addEventListener("click", async () => {
    await loadRecords();
  });

  elements.previousButton.addEventListener("click", async () => {
    state.offset = Math.max(0, state.offset - pageSize);
    await loadRecords();
  });

  elements.nextButton.addEventListener("click", async () => {
    state.offset += pageSize;
    await loadRecords();
  });

  elements.saveButton.addEventListener("click", async () => {
    await saveSelectedRecord();
  });

  elements.diffButton.addEventListener("click", async () => {
    await showDiff();
  });

  elements.validateButton.addEventListener("click", async () => {
    await runCommand("/api/commands/validate", "Validating JSONL artifacts...");
  });

  elements.buildButton.addEventListener("click", async () => {
    await runCommand("/api/commands/build-seed", "Generating SwiftData SQLite seed store...");
  });

  elements.clearOutputButton.addEventListener("click", () => {
    elements.commandOutput.textContent = "";
  });
}

function renderMeta() {
  elements.dataRoot.textContent = state.meta.dataRoot;
  elements.datasetList.replaceChildren(...state.meta.datasets.map(renderDatasetButton));
  renderManifest();
  renderYearSelect();
}

function renderDatasetButton(dataset) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = dataset.id === state.datasetID ? "dataset-button active" : "dataset-button";
  button.innerHTML = `<strong>${escapeHTML(dataset.label)}</strong><code>${escapeHTML(dataset.recordType)}</code><span>${escapeHTML(dataset.detail)}</span>`;
  button.addEventListener("click", async () => {
    state.datasetID = dataset.id;
    state.offset = 0;
    state.selected = null;
    elements.datasetList.replaceChildren(...state.meta.datasets.map(renderDatasetButton));
    await loadRecords();
  });
  return button;
}

function renderManifest() {
  const manifest = state.meta.manifest;
  if (!manifest) {
    elements.manifestSummary.textContent = "No manifest found.";
    return;
  }

  const entries = [
    ["Range", `${manifest.startYear}...${manifest.endYear}`],
    ["Days", formatNumber(manifest.totalCalendarDays)],
    ["Years", formatNumber(manifest.totalChineseLunarYears)],
    ["Months", formatNumber(manifest.totalChineseLunarMonths)],
    ["Dynasties", formatNumber(manifest.totalDynasties)],
    ["Emperors", formatNumber(manifest.totalEmperors)],
    ["Reign segments", formatNumber(manifest.totalEmperorReignSegments)],
    ["Reign eras", formatNumber(manifest.totalReignEras)],
    ["Generated", manifest.generatedAt],
    ["Commit", manifest.sourceUpstreamCommit]
  ];

  elements.manifestSummary.replaceChildren(...entries.flatMap(([key, value]) => {
    const dt = document.createElement("dt");
    dt.textContent = key;
    const dd = document.createElement("dd");
    dd.textContent = value ?? "-";
    return [dt, dd];
  }));
}

function renderYearSelect() {
  const years = state.meta.calendarYears;
  const fragment = document.createDocumentFragment();
  for (const year of years) {
    const option = document.createElement("option");
    option.value = String(year);
    option.textContent = String(year);
    if (year === state.year) {
      option.selected = true;
    }
    fragment.append(option);
  }
  elements.yearSelect.replaceChildren(fragment);
}

async function loadRecords() {
  const dataset = selectedDataset();
  elements.yearField.classList.toggle("hidden", !dataset.yearScoped);
  elements.saveButton.disabled = true;
  elements.jsonEditor.disabled = true;
  elements.jsonEditor.value = "";
  setEditorMessage("Loading records...");

  const params = new URLSearchParams({
    dataset: state.datasetID,
    offset: String(state.offset),
    limit: String(pageSize),
    query: state.query
  });
  if (dataset.yearScoped) {
    params.set("year", String(state.year));
  }

  const response = await getJSON(`/api/records?${params}`);
  state.recordsResponse = response;
  state.selected = null;
  renderRecords(response);
  setEditorEmpty();
}

function renderRecords(response) {
  elements.datasetTitle.textContent = `${response.dataset.label} · ${response.dataset.recordType}`;
  elements.filePath.textContent = response.path;
  elements.recordCount.textContent = formatNumber(response.matchedCount);

  if (response.records.length === 0) {
    const empty = document.createElement("div");
    empty.className = "message";
    empty.textContent = "No records match the current filter.";
    elements.recordList.replaceChildren(empty);
  } else {
    elements.recordList.replaceChildren(...response.records.map(renderRecordItem));
  }

  elements.previousButton.disabled = response.offset === 0;
  elements.nextButton.disabled = response.offset + response.limit >= response.matchedCount;
  const first = response.matchedCount === 0 ? 0 : response.offset + 1;
  const last = Math.min(response.offset + response.records.length, response.matchedCount);
  elements.pageLabel.textContent = `${formatNumber(first)} - ${formatNumber(last)} of ${formatNumber(response.matchedCount)}`;
}

function renderRecordItem(record) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "record-item";
  button.innerHTML = `
    <span class="record-title">${escapeHTML(record.summary)}</span>
    <span class="record-meta"><span>line ${record.lineNumber}</span><span>${escapeHTML(String(record.key ?? ""))}</span></span>
  `;
  button.addEventListener("click", () => selectRecord(record, button));
  return button;
}

function selectRecord(record, button) {
  state.selected = record;
  for (const item of elements.recordList.querySelectorAll(".record-item")) {
    item.classList.remove("active");
  }
  button.classList.add("active");

  elements.editorTitle.textContent = `Line ${record.lineNumber}`;
  elements.editorSubtitle.textContent = `${state.recordsResponse.path} · ${record.summary}`;
  elements.jsonEditor.disabled = false;
  elements.saveButton.disabled = false;
  elements.jsonEditor.value = prettyJSON(record.raw);
  renderReadablePreview(record);
  setEditorMessage(record.parseError ? record.parseError : "Ready.", Boolean(record.parseError));
}

function setEditorEmpty() {
  elements.editorTitle.textContent = "Select a record";
  elements.editorSubtitle.textContent = "No record selected.";
  elements.jsonEditor.value = "";
  elements.readablePreview.replaceChildren(...emptyReadableItem("请选择一条记录。"));
  elements.jsonEditor.disabled = true;
  elements.saveButton.disabled = true;
  setEditorMessage("Ready.");
}

async function saveSelectedRecord() {
  if (!state.selected) {
    return;
  }

  let record;
  try {
    record = JSON.parse(elements.jsonEditor.value);
  } catch (error) {
    setEditorMessage(`Invalid JSON: ${error.message}`, true);
    return;
  }

  const payload = {
    dataset: state.datasetID,
    year: selectedDataset().yearScoped ? state.year : null,
    lineNumber: state.selected.lineNumber,
    record
  };

  elements.saveButton.disabled = true;
  setEditorMessage("Saving...");

  try {
    const response = await putJSON("/api/record", payload);
    state.selected = {
      ...state.selected,
      raw: response.raw,
      record: response.record,
      summary: response.summary,
      key: valueAtPath(response.record, selectedDataset().keyPath),
      parseError: null
    };
    setEditorMessage("Saved. Run validation before generating SQLite.");
    await loadRecords();
  } catch (error) {
    setEditorMessage(error.message, true);
  } finally {
    elements.saveButton.disabled = false;
  }
}

function renderReadablePreview(record) {
  const dataset = selectedDataset();
  const items = Array.isArray(record.readable) ? record.readable : [];
  if (items.length === 0) {
    elements.readablePreview.replaceChildren(...emptyReadableItem("没有可读预览。"));
    return;
  }

  elements.readablePreview.replaceChildren(...items.flatMap((entry) => {
    const dt = document.createElement("dt");
    dt.textContent = entry.label;
    const dd = document.createElement("dd");
    dd.textContent = entry.value;
    const description = entry.path ? dataset.schema?.[entry.path] : null;
    if (description) {
      const small = document.createElement("small");
      small.textContent = description;
      dd.append(small);
    }
    return [dt, dd];
  }));
}

function emptyReadableItem(message) {
  const dt = document.createElement("dt");
  dt.textContent = "状态";
  const dd = document.createElement("dd");
  dd.textContent = message;
  return [dt, dd];
}

async function showDiff() {
  const dataset = selectedDataset();
  const params = new URLSearchParams({ dataset: state.datasetID });
  if (dataset.yearScoped) {
    params.set("year", String(state.year));
  }

  appendOutput(`$ git diff -- ${dataset.yearScoped ? `calendar_days/${state.year}/calendar_days.jsonl` : dataset.detail}\n`);
  const response = await getJSON(`/api/diff?${params}`);
  appendOutput(response.diff || "No diff for this JSONL file.");
}

async function runCommand(endpoint, heading) {
  appendOutput(`${heading}\n`);
  setCommandButtonsDisabled(true);
  try {
    const response = await postJSON(endpoint, {});
    for (const result of response.results) {
      appendOutput(`\n$ ${result.command} ${result.args.join(" ")}\n${result.output || "(no output)"}\nstatus: ${result.status}`);
    }
    appendOutput(response.ok ? "\nDone.\n" : "\nCommand failed.\n");
  } catch (error) {
    appendOutput(`\n${error.message}\n`);
  } finally {
    setCommandButtonsDisabled(false);
  }
}

function setCommandButtonsDisabled(disabled) {
  elements.validateButton.disabled = disabled;
  elements.buildButton.disabled = disabled;
  elements.diffButton.disabled = disabled;
}

function selectedDataset() {
  return state.meta.datasets.find((dataset) => dataset.id === state.datasetID);
}

function defaultYear(years) {
  if (years.includes(2024)) {
    return 2024;
  }
  return years[Math.max(0, Math.floor(years.length / 2))] ?? 0;
}

function prettyJSON(raw) {
  try {
    return JSON.stringify(JSON.parse(raw), null, 2);
  } catch {
    return raw;
  }
}

function setEditorMessage(message, isError = false) {
  elements.editorMessage.textContent = message;
  elements.editorMessage.classList.toggle("error", isError);
}

function appendOutput(text) {
  const separator = elements.commandOutput.textContent.length > 0 && !elements.commandOutput.textContent.endsWith("\n") ? "\n" : "";
  elements.commandOutput.textContent += `${separator}${text}`;
  elements.commandOutput.scrollTop = elements.commandOutput.scrollHeight;
}

async function getJSON(url) {
  return requestJSON(url);
}

async function postJSON(url, body) {
  return requestJSON(url, { method: "POST", body: JSON.stringify(body) });
}

async function putJSON(url, body) {
  return requestJSON(url, { method: "PUT", body: JSON.stringify(body) });
}

async function requestJSON(url, options = {}) {
  const response = await fetch(url, {
    headers: { "Content-Type": "application/json" },
    ...options
  });
  const value = await response.json();
  if (!response.ok) {
    throw new Error(value.error ?? `Request failed: ${response.status}`);
  }
  return value;
}

function debounce(fn, delay) {
  let timeout = null;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => fn(...args), delay);
  };
}

function escapeHTML(value) {
  return String(value).replace(/[&<>"]/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;"
  })[character]);
}

function formatNumber(value) {
  if (value === null || value === undefined) {
    return "-";
  }
  return Number(value).toLocaleString("en-US");
}

function valueAtPath(record, keyPath) {
  return keyPath.split(".").reduce((value, key) => value?.[key], record) ?? null;
}
