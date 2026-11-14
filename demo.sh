#!/usr/bin/env bash
#
# Zero to running: build OpenRateSimple, start it, push a small sample
# through it, show what came out, and shut it down again.
#
# Everything this does by hand is in build.sh / run.sh / feed.sh / stop.sh.

set -euo pipefail
cd "$(dirname "$0")"
. ./common.sh

DATA_DIR=Data/Simple
SAMPLE=testpipeline_simple_12          # 10 records
RUN_LOG=$(mktemp -t openratesimple)
FRAMEWORK_PID=""

cleanup() {
  if [ -n "$FRAMEWORK_PID" ] && kill -0 "$FRAMEWORK_PID" 2>/dev/null; then
    say ""
    step "Shutting the framework down"
    eci 'Framework:shutdown=true' >/dev/null 2>&1 || true
    for _ in $(seq 1 20); do
      framework_running || break
      sleep 1
    done
    kill "$FRAMEWORK_PID" 2>/dev/null || true
    wait "$FRAMEWORK_PID" 2>/dev/null || true
    say "Stopped."
  fi
  rm -f "$RUN_LOG"
}
trap cleanup EXIT INT TERM

check_toolchain
check_openrate_installed

if framework_running; then
  fail "Something is already listening on ${ECI_HOST}:${ECI_PORT}.
       Run ./stop.sh first, then try again."
fi

# ------------------------------------------------------------------ 1. build
step "1/5  Building against OpenRate $(openrate_version)"
mvn -B -q clean package
say "    Built."

# ------------------------------------------------------------------ 2. clean
step "2/5  Clearing output from any previous run"
rm -f "${DATA_DIR}"/*.edr "${DATA_DIR}"/*.done "${DATA_DIR}"/*.out \
      "${DATA_DIR}"/*.dump "${DATA_DIR}"/*.err
say "    ${DATA_DIR} now holds only the compressed samples."

# ------------------------------------------------------------------ 3. start
step "3/5  Starting the framework"
mvn -B exec:java > "$RUN_LOG" 2>&1 &
FRAMEWORK_PID=$!

for _ in $(seq 1 90); do
  grep -q 'Running\.\.\.' "$RUN_LOG" 2>/dev/null && break
  kill -0 "$FRAMEWORK_PID" 2>/dev/null || { sed 's/^/    /' "$RUN_LOG" | tail -20; fail "The framework exited during startup."; }
  sleep 1
done
grep -q 'Running\.\.\.' "$RUN_LOG" || { sed 's/^/    /' "$RUN_LOG" | tail -20; fail "The framework did not reach 'Running...' in 90s."; }

sed -n '/OpenRate V/,/Running\.\.\./p' "$RUN_LOG" | sed 's/^/    /'

# ------------------------------------------------------------------- 4. feed
step "4/5  Feeding ${SAMPLE} (10 records) into ${DATA_DIR}"
gzip -dc "${DATA_DIR}/${SAMPLE}.edr.gz" > "${DATA_DIR}/${SAMPLE}.edr"

for _ in $(seq 1 60); do
  [ -f "${DATA_DIR}/${SAMPLE}.out" ] && [ -f "${DATA_DIR}/${SAMPLE}.done" ] && break
  sleep 1
done
[ -f "${DATA_DIR}/${SAMPLE}.out" ] || fail "No output appeared within 60s. Framework log:
$(tail -20 "$RUN_LOG")"

say "    Processed. The input was renamed to .done and .out was written."

# ----------------------------------------------------------------- 5. result
step "5/5  What the pipeline did"
cat <<EXPLAIN

    The pipeline looks up each record's destination number against the
    prefix table in ConfigData/Simple/prefixdesc.dat, and writes the
    matching description into the record.

    The sample holds a header, four detail records with their
    sub-records, and a trailer. Only the detail records come out the
    far side, so here is detail record 020 before and after.

    IN (truncated):

EXPLAIN
gzip -dc "${DATA_DIR}/${SAMPLE}.edr.gz" \
  | awk -F'\t' '$1=="020"{print; exit}' | cut -c1-108 | sed 's/^/      /'
cat <<EXPLAIN

    OUT - the destination description has been filled in:

EXPLAIN
awk -F'\t' '$1=="020"{print; exit}' "${DATA_DIR}/${SAMPLE}.out" \
  | cut -c1-108 | sed 's/^/      /'
cat <<EXPLAIN

    10 records went in, $(wc -l < "${DATA_DIR}/${SAMPLE}.out" | tr -d ' ') detail records came out. The header,
    trailer and sub-records are consumed by the pipeline.
EXPLAIN

cat <<SUMMARY

    Files now in ${DATA_DIR}:
SUMMARY
ls -1 "${DATA_DIR}" | sed 's/^/      /'

cat <<NEXT

--------------------------------------------------------------
 Next steps
--------------------------------------------------------------
  ./run.sh              start it and leave it running
  ./feed.sh             feed it the small sample again
  ./feed.sh large       feed it 327k records instead
  ./stop.sh             shut it down

  telnet ${ECI_HOST} ${ECI_PORT}    admin console, 'Help' for commands

  Try editing ConfigData/Simple/prefixdesc.dat while it runs, then
  reload the cache from the admin console and feed it again - the
  output changes without restarting the framework.
--------------------------------------------------------------
NEXT
