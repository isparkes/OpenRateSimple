#!/usr/bin/env bash
#
# Shared helpers for the OpenRateSimple distribution scripts.
# Not meant to be run directly.

REQUIRED_JAVA=17
ECI_HOST="${OPENRATE_ECI_HOST:-localhost}"
ECI_PORT="${OPENRATE_ECI_PORT:-8086}"

say()  { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Absolute path of the installation root (the parent of bin/).
openrate_home() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  dirname "$here"
}

# Locate a JDK of at least REQUIRED_JAVA, honouring JAVA_HOME if it is set.
resolve_java() {
  local candidate
  if [ -n "${JAVA_HOME:-}" ] && [ -x "${JAVA_HOME}/bin/java" ]; then
    candidate="${JAVA_HOME}/bin/java"
  elif command -v java >/dev/null 2>&1; then
    candidate="$(command -v java)"
  else
    fail "No Java found. OpenRate needs JDK ${REQUIRED_JAVA} or later.
       Set JAVA_HOME, or install one:
         macOS:  brew install --cask temurin@${REQUIRED_JAVA}
         Linux:  apt install openjdk-${REQUIRED_JAVA}-jdk"
  fi

  local raw major
  raw=$("$candidate" -version 2>&1 | head -1 | sed -n 's/.*version "\([^"]*\)".*/\1/p')
  case "$raw" in
    1.*) major=$(printf '%s' "$raw" | cut -d. -f2) ;;
    *)   major=$(printf '%s' "$raw" | cut -d. -f1) ;;
  esac
  if [ -z "$major" ] || [ "$major" -lt "$REQUIRED_JAVA" ]; then
    fail "Found Java ${raw:-unknown} at ${candidate}, but ${REQUIRED_JAVA} or later is needed.
       Point JAVA_HOME at a newer JDK, for example:
         export JAVA_HOME=\$(/usr/libexec/java_home -v ${REQUIRED_JAVA})   # macOS"
  fi
  printf '%s' "$candidate"
}

# The classpath for the unpacked distribution.
#   properties  holds the configuration, which OpenRate loads from the classpath
#   dist        this application
#   ORlib       the OpenRate framework
#   lib         third party dependencies
openrate_classpath() {
  printf '%s' "properties:dist/*:ORlib/*:lib/*"
}

framework_running() {
  if command -v nc >/dev/null 2>&1; then
    nc -z "$ECI_HOST" "$ECI_PORT" >/dev/null 2>&1
  else
    (exec 3<>"/dev/tcp/${ECI_HOST}/${ECI_PORT}") >/dev/null 2>&1
  fi
}

# Send one command to the admin console and echo the reply.
eci() {
  local cmd="$1"
  command -v nc >/dev/null 2>&1 || fail \
    "'nc' is not available, so this script cannot reach the admin console.
       Connect by hand instead:  telnet ${ECI_HOST} ${ECI_PORT}"
  { printf '%s\n' "$cmd"; sleep 2; } | nc "$ECI_HOST" "$ECI_PORT" 2>/dev/null
}
