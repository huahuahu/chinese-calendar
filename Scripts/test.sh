#!/usr/bin/env bash

set -euo pipefail

./Scripts/test_buildserver_normalization.sh
swift test --package-path Sources
