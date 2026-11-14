OpenRateSimple
==============

A ready-to-run [OpenRate](https://github.com/isparkes/OpenRate) application.
It reads call detail records from a file, enriches each one with a destination
description based on a longest-prefix match, and writes the result out again.

No database, no external services. Everything needed to run is in this
directory.

Requirements
------------

**JDK 17 or later.** Nothing else — the framework and all its dependencies are
included here.

```bash
java -version
```

If that reports an older version, point `JAVA_HOME` at a newer JDK:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)    # macOS
```

Quick start
-----------

From this directory:

```bash
bin/run.sh            # terminal 1 - wait for "Running..."
bin/feed.sh           # terminal 2 - process a 10 record sample
bin/stop.sh           # terminal 2 - shut down
```

`bin/run.sh` occupies its terminal: OpenRate runs as a daemon, watching
`Data/Simple` for input and processing whatever appears until told to stop.

What you should see
-------------------

After `bin/feed.sh`, three files appear in `Data/Simple`:

| File | Contents |
|---|---|
| `testpipeline_simple_12.done` | The input, renamed once consumed |
| `testpipeline_simple_12.out` | The enriched detail records |
| `testpipeline_simple_12.dump` | A readable dump of each record's processing |

A record on the way in:

```
020  2  0  ...  0049171235292              00  0  00495764985304  ...
```

and on the way out, with the destination filled in:

```
020  2  0  ...  0049171235292  Deutschland  00  0  00495764985304  ...
```

The sample holds a header, four detail records with their sub-records, and a
trailer. Only the four detail records come out the far side — the rest are
consumed by the pipeline.

Scripts
-------

| Command | Does |
|---|---|
| `bin/run.sh` | Start the framework |
| `bin/run.sh Other.properties.xml` | Start with a different configuration |
| `bin/feed.sh` | Feed the small sample (10 records) |
| `bin/feed.sh large` | Feed the large sample (327k records, ~47MB) |
| `bin/feed.sh my-data.edr.gz` | Feed a gzipped file of your own |
| `bin/stop.sh` | Shut down cleanly |

Environment variables honoured by the scripts:

| Variable | Purpose |
|---|---|
| `JAVA_HOME` | Which JDK to use |
| `JAVA_OPTS` | Extra JVM options, e.g. `-Xmx2g` for the large sample |
| `OPENRATE_ECI_PORT` | Admin console port, default 8086 |

The admin console
-----------------

OpenRate exposes a control interface while it runs:

```bash
telnet localhost 8086
```

`Help` lists the commands. `bin/stop.sh` uses this to send
`Framework:shutdown=true`. You can also inspect module state and reload caches
without restarting.

> The console is **unauthenticated**. Fine on a development machine; do not
> expose the port on a shared or public network.

Layout
------

```
bin/          scripts: run, feed, stop
dist/         this application
ORlib/        the OpenRate framework jar
lib/          third party dependencies
properties/   configuration - on the classpath at startup
ConfigData/   reference data loaded into caches
Data/Simple/  input and output files
samples/      gzipped sample input
log/          log output
Semaphore/    file-based control interface
```

Configuration
-------------

`properties/Simple.properties.xml` defines the whole pipeline: the input
adapter, the processing module, the output adapter, and the shared resources.
It is loaded from the classpath, which is why `properties/` is on it.

`ConfigData/Simple/prefixdesc.dat` holds the prefix lookup table. It is read
into an in-memory cache at startup.

Try this
--------

With the framework running, edit `ConfigData/Simple/prefixdesc.dat`, reload the
cache from the admin console, and feed the sample again. The output changes
without restarting anything. That is the point of OpenRate's cache and resource
model: reference data can be refreshed under a running pipeline.

Running your own data
---------------------

The input adapter picks up any file matching `testpipeline*.edr` in
`Data/Simple`. To process your own records, either name them to match, or
change `InputFilePrefix` / `InputFileSuffix` in
`properties/Simple.properties.xml`.

Troubleshooting
---------------

**"Something is already listening on localhost:8086"** — an OpenRate instance
is still running. `bin/stop.sh`, or change `OPENRATE_ECI_PORT`.

**Nothing happens after feeding a file** — check that the file landed in
`Data/Simple` and matches `testpipeline*.edr`. Check `log/` for errors.

**`OutOfMemoryError` on the large sample** — `JAVA_OPTS=-Xmx2g bin/run.sh`.

License
-------

Licensed under the Apache License, Version 2.0. See `LICENSE` in this
directory.

Copyright 2006-2026 Ian Sparkes.

More
----

The framework, its architecture, and how to write your own modules:
[github.com/isparkes/OpenRate](https://github.com/isparkes/OpenRate)
