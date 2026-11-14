#!/usr/bin/env bash
#
# Give a running OpenRateSimple a sample file to process.
#
#   bin/feed.sh            the small sample, 10 records
#   bin/feed.sh large      the large sample, 327k records (~47MB)
#   bin/feed.sh <file.gz>  any gzipped input file of your own

set -euo pipefail

. "$(cd "$(dirname "$0")" && pwd)/common.sh"
cd "$(openrate_home)"

DATA_DIR="Data/Simple"

case "${1:-small}" in
  small) source_file="samples/testpipeline_simple_12.edr.gz" ;;
  large) source_file="samples/testpipeline_simple_11.edr.gz" ;;
  *)     source_file="$1" ;;
esac

[ -f "$source_file" ] || fail "No such sample: ${source_file}
       Shipped samples:
$(ls samples/*.gz 2>/dev/null | sed 's|^|         |' || echo '         (none)')"

framework_running || say \
  "Note: nothing is listening on ${ECI_HOST}:${ECI_PORT}, so OpenRate does not
      look like it is running. The file will be picked up when you start it."

target="${DATA_DIR}/$(basename "${source_file%.gz}")"
mkdir -p "$DATA_DIR"
gzip -dc "$source_file" > "$target"

say "Fed ${target}"
say "Watch ${DATA_DIR} for the .done, .out and .dump files."
