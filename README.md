OpenRateSimple
==============

The simplest non-trivial [OpenRate](https://github.com/isparkes/OpenRate)
application: a pipeline that reads call detail records from a file, enriches
each one with a destination description based on a longest-prefix match, and
writes the result out again.

It needs no database and no external services, which makes it the right place
to start.

Requires OpenRate 1.5.2.6 or later, and JDK 17.

Quick start
-----------

```bash
./demo.sh
```

That builds the application, starts the framework, pushes a 10 record sample
through it, shows you what came out, and shuts down again.

If OpenRate itself is not installed yet, `demo.sh` stops and tells you how.
OpenRate is not published to Maven Central, so the framework has to be built
locally first — once, before any application will resolve it:

```bash
git clone https://github.com/isparkes/OpenRate.git
cd OpenRate
./bootstrap.sh
```

Running it yourself
-------------------

`demo.sh` just chains the other scripts together. To drive it by hand:

| Script | Does |
|---|---|
| `./build.sh` | Build the application |
| `./run.sh` | Start the framework in the foreground; runs until stopped |
| `./feed.sh` | Feed it the small sample (10 records) |
| `./feed.sh large` | Feed it the large sample (327k records, ~47MB) |
| `./stop.sh` | Shut it down cleanly |

OpenRate runs here as a **daemon**: it starts, watches `Data/Simple` for input
files, and keeps running until told to stop. So `run.sh` occupies a terminal,
and you drive it from a second one:

```bash
./run.sh                 # terminal 1 - wait for "Running..."
./feed.sh                # terminal 2
./stop.sh                # terminal 2
```

The pipeline picks up any file matching `testpipeline*.edr` in `Data/Simple`.
Dropping a file in is what triggers processing; there is nothing else to press.

What comes out
--------------

For an input file `testpipeline_simple_12.edr` you get, in the same directory:

| File | Contents |
|---|---|
| `.done` | The original input, renamed once it has been consumed |
| `.out` | The enriched detail records |
| `.dump` | A human readable dump of each record's processing |
| `.err` | Records that failed processing (empty on a clean run) |

The sample contains a header, four detail records with their sub-records, and a
trailer. Only the four detail records come out the far side.

The admin console
-----------------

OpenRate exposes a control interface on port 8086:

```bash
telnet localhost 8086
```

`Help` lists the available commands. `stop.sh` uses this to issue:

```
Framework:shutdown=true
```

> The console is unauthenticated. It is fine on a development machine; do not
> expose the port on a shared or public network.

How it works
------------

This is a very simple pipeline. It enriches each input record with a zone
destination based on a longest prefix match.

The prefix table is read from `ConfigData/Simple/prefixdesc.dat` at startup
into an in-memory cache. It can be reloaded while the framework is running,
from the admin console, or configured to refresh periodically.

Try this: start the framework, edit `ConfigData/Simple/prefixdesc.dat`, reload
the cache from the console, then `./feed.sh` again. The output changes without
restarting anything — which is the point of the cache and resource model.

The moving parts:

| File | Role |
|---|---|
| `src/main/resources/Simple.properties.xml` | The whole pipeline definition: input adapter, processing module, output adapter, resources |
| `src/main/java/Simple/SimpleInputAdapter.java` | Reads flat file records |
| `src/main/java/Simple/SimpleRecord.java` | The record travelling through the pipeline |
| `src/main/java/Simple/DestLookup.java` | The processing module doing the prefix match |
| `src/main/java/Simple/SimpleSTOutputAdapter.java` | Writes the records out |
| `ConfigData/Simple/prefixdesc.dat` | The prefix lookup data |

Building a distribution
-----------------------

```bash
mvn clean package
```

also produces `target/OpenRateSimple-1.0.0-bin.zip`: a self-contained
distribution that runs anywhere with a JDK 17, with no Maven and no source
checkout.

```
unzip OpenRateSimple-1.0.0-bin.zip -d openratesimple
cd openratesimple
bin/run.sh
```

It carries its own `README.md`, the framework and dependency jars, the
configuration, the sample data, and `bin/run.sh`, `bin/feed.sh`, `bin/stop.sh`.
Those distribution scripts launch Java directly; the scripts in the project
root drive Maven, so each set only works in its own context. The distribution
sources live in `src/main/bin` and `src/main/dist`.

Where to go next
----------------

Read `Simple.properties.xml` alongside the architecture section of the
[OpenRate README](https://github.com/isparkes/OpenRate) — the configuration
maps directly onto the pipeline diagram there.

Then try changing something: add a prefix to the lookup data, add a field to
`SimpleRecord`, or extend `DestLookup`.

More involved examples: [ORPixip](https://github.com/isparkes/ORPixip)
(multiple data sources), [ORTyfon](https://github.com/isparkes/ORTyfon)
(rating and fraud detection).

License
-------

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

Copyright 2006-2026 Ian Sparkes.
