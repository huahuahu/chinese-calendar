#!/usr/bin/env bash

set -euo pipefail

./Scripts/format.sh --check
./Scripts/lint.sh
python3 ./Scripts/validate_localized_copy.py
./Scripts/validate_data_schemas.sh
./Scripts/generate_xcodeproj.sh
./Scripts/test.sh
./Scripts/build_apps.sh
