#!/usr/bin/env bash
#
# Build OpenRateSimple.

set -euo pipefail
cd "$(dirname "$0")"
. ./common.sh

check_toolchain
check_openrate_installed

step "Building OpenRateSimple against OpenRate $(openrate_version)"
mvn -B clean package

say ""
say "Built. Start the framework with:  ./run.sh"
say "Or run the whole demo with:       ./demo.sh"
