#!/usr/bin/env bash
#
# Start the OpenRateSimple framework in the foreground.
#
# It runs as a daemon: it starts, waits for input files to appear, and keeps
# running until told to stop. Use ./feed.sh and ./stop.sh from another shell.

set -euo pipefail
cd "$(dirname "$0")"
. ./common.sh

check_toolchain
check_openrate_installed

if framework_running; then
  fail "Something is already listening on ${ECI_HOST}:${ECI_PORT}.
       The framework may already be running - try ./stop.sh first."
fi

cat <<BANNER

--------------------------------------------------------------
 Starting OpenRateSimple
--------------------------------------------------------------
 The framework runs until you stop it. Once you see "Running...",
 open a second terminal in this directory and:

     ./feed.sh      give it a small sample file to process
     ./stop.sh      shut it down cleanly

 Admin console:  telnet ${ECI_HOST} ${ECI_PORT}   ('Help' for commands)
--------------------------------------------------------------

BANNER

# Relative paths in Simple.properties.xml resolve against the project root,
# so this must run from here.
exec mvn -B exec:java
