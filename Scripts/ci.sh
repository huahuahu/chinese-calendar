#!/usr/bin/env bash

set -euo pipefail

./Scripts/format.sh --check
./Scripts/lint.sh
./Scripts/test.sh
