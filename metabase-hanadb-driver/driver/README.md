# Driver Workspace

This directory contains the Metabase community driver implementation.

Current structure:

- `deps.edn`
- `resources/metabase-plugin.yaml`
- `src/metabase/driver/hanadb.clj`

## Runtime Model

- Metabase runtime: community driver JAR
- Database client: SAP HANA JDBC driver `ngdbc.jar`
- External dependency handling: place `ngdbc.jar` in the Metabase `plugins/`
  directory next to `hanadb.metabase-driver.jar`

Metabase loads plain JARs in `plugins/` onto the classpath before initializing
plugin JARs with a manifest, which is why this external-JAR pattern works for
drivers with proprietary JDBC dependencies.

## Non-Goals

- A Python connector or proxy is not the Metabase runtime driver.
- A Python proxy server is not the primary implementation path.
