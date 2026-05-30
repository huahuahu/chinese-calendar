#!/usr/bin/env bash

set -euo pipefail

./Scripts/DataSchemas/generate_schema_artifacts.swift --check
./Scripts/DataSchemas/validate_swiftdata_import.swift
