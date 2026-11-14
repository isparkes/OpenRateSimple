#!/usr/bin/env bash
#
# Shared helpers for the OpenRateSimple scripts. Not meant to be run directly.

REQUIRED_JAVA=17
ECI_HOST=localhost
ECI_PORT=8086

say()  { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

step() {
  printf '\n\033[1m==> %s\033[0m\n' "$*"
}

# Exit unless java >= REQUIRED_JAVA and maven are both available.
check_toolchain() {
  command -v java >/dev/null 2>&1 || fail \
    "No 'java' on the PATH. This needs JDK ${REQUIRED_JAVA} or later.
       macOS:  brew install --cask temurin@${REQUIRED_JAVA}"
  command -v mvn >/dev/null 2>&1 || fail \
    "No 'mvn' on the PATH.
       macOS:  brew install maven"

  local raw major
  raw=$(java -version 2>&1 | head -1 | sed -n 's/.*version "\([^"]*\)".*/\1/p')
  case "$raw" in
    1.*) major=$(printf '%s' "$raw" | cut -d. -f2) ;;
    *)   major=$(printf '%s' "$raw" | cut -d. -f1) ;;
  esac
  if [ -z "$major" ] || [ "$major" -lt "$REQUIRED_JAVA" ]; then
    fail "Java ${raw:-unknown} found, but ${REQUIRED_JAVA} or later is needed.
       macOS:  brew install --cask temurin@${REQUIRED_JAVA}
       then:   export JAVA_HOME=\$(/usr/libexec/java_home -v ${REQUIRED_JAVA})"
  fi
}

# The OpenRate version this application depends on, read from the pom.
openrate_version() {
  sed -n '/<artifactId>OpenRate<\/artifactId>/,/<\/dependency>/p' pom.xml \
    | sed -n 's|.*<version>\(.*\)</version>.*|\1|p' | head -1
}

# Exit unless the OpenRate framework jar is in the local Maven repository.
check_openrate_installed() {
  local v repo
  v=$(openrate_version)
  [ -n "$v" ] || fail "Could not read the OpenRate version from pom.xml"
  repo="${HOME}/.m2/repository/OpenRate/OpenRate/${v}/OpenRate-${v}.jar"

  if [ ! -f "$repo" ]; then
    fail "OpenRate ${v} is not installed in your local Maven repository.

OpenRate is not published to Maven Central, so the framework has to be
built and installed before this application can resolve it:

    git clone https://github.com/isparkes/OpenRate.git
    cd OpenRate
    ./bootstrap.sh"
  fi
}

# True while the framework's admin port is accepting connections.
framework_running() {
  if command -v nc >/dev/null 2>&1; then
    nc -z "$ECI_HOST" "$ECI_PORT" >/dev/null 2>&1
  else
    (exec 3<>"/dev/tcp/${ECI_HOST}/${ECI_PORT}") >/dev/null 2>&1
  fi
}

# Send one command to the ECI admin console and echo the reply.
eci() {
  local cmd="$1"
  if command -v nc >/dev/null 2>&1; then
    { printf '%s\n' "$cmd"; sleep 2; } | nc "$ECI_HOST" "$ECI_PORT" 2>/dev/null
  else
    exec 3<>"/dev/tcp/${ECI_HOST}/${ECI_PORT}" || return 1
    printf '%s\n' "$cmd" >&3
    sleep 2
    cat <&3 &
    local pid=$!
    sleep 1; kill "$pid" 2>/dev/null || true
    exec 3<&-; exec 3>&-
  fi
}
