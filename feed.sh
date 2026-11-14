#!/usr/bin/env bash
#
# Give the running framework a sample file to process.
#
#   ./feed.sh          10 records   - the default, finishes instantly
#   ./feed.sh large    327k records - ~47MB of data, takes a while

set -euo pipefail
cd "$(dirname "$0")"
. ./common.sh

DATA_DIR=Data/Simple
case "${1:-small}" in
  small) sample=testpipeline_simple_12 ;;
  large) sample=testpipeline_simple_11 ;;
  *)     fail "Usage: $0 [small|large]" ;;
esac

[ -f "${DATA_DIR}/${sample}.edr.gz" ] || fail "Missing sample ${DATA_DIR}/${sample}.edr.gz"

framework_running || say \
  "Note: nothing is listening on ${ECI_HOST}:${ECI_PORT}, so the framework
      does not look like it is running. The file will be picked up whenever
      you start it with ./run.sh"

step "Feeding ${sample} into ${DATA_DIR}"
# The input adapter matches <prefix>*<suffix>, so writing the .edr is what
# triggers processing. Keep the .gz so the sample can be replayed.
gzip -dc "${DATA_DIR}/${sample}.edr.gz" > "${DATA_DIR}/${sample}.edr"

say "Done. The pipeline renames the input to .done and writes .out next to it."
