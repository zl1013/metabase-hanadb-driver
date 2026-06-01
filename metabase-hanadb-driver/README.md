# Metabase SAP HANA Driver

Community driver scaffold for connecting Metabase OSS to SAP HANA through the
SAP HANA JDBC driver.

This repository is intentionally small and public-safe:

- no database credentials
- no private environment files
- no generated JARs or Docker image archives
- no local Metabase source checkout
- no SAP `ngdbc.jar` binary

## Status

This is an early community-driver implementation. The current goal is to build
and load a Metabase plugin, show `SAP HANA` in the Metabase database list, and
validate basic JDBC connectivity with `SELECT 1 FROM DUMMY`.

## Repository Layout

- `driver/`: Metabase community driver source and plugin manifest
- `scripts/`: build, bootstrap, packaging, and smoke-test helpers
- `docs/`: deployment notes for existing Metabase Docker images
- `docker-compose.yml`: local Metabase plus Postgres application database
- `docker-compose.plugins.yml`: plugin mount override for existing stacks
- `.env.example`: safe local configuration template

Generated files are excluded from Git. Use `build/` and `dist/` locally.

## Prerequisites

- Git
- Docker and Docker Compose
- Java 21 or newer
- Clojure tooling required by the Metabase build
- A local checkout of Metabase source, created by `make bootstrap`
- SAP HANA JDBC driver `ngdbc.jar`, supplied by the user

`ngdbc.jar` is not included in this repository. Obtain it from SAP HANA Client
or another license-compliant SAP distribution channel.

## Quick Start

Create a local environment file:

```bash
cp .env.example .env
```

Edit `.env` for your machine. Do not commit `.env`.

Prepare Metabase source:

```bash
make bootstrap
```

Build the driver:

```bash
make driver-build
```

Copy the real SAP HANA JDBC driver next to the plugin:

```bash
mkdir -p build/plugins
cp /path/to/ngdbc.jar build/plugins/ngdbc.jar
```

Start the local Metabase stack:

```bash
make stack-up
```

Open Metabase at `http://localhost:3000` and add a database with type
`SAP HANA`.

## JDBC Smoke Test

Set connection values in your shell or `.env`:

```bash
export HANA_HOST=hana.example.com
export HANA_PORT=30015
export HANA_USER=example_user
read -rs HANA_PASS
export HANA_PASS
export HANA_NGDBC_JAR=/path/to/ngdbc.jar
```

Run:

```bash
make hana-jdbc-smoke
```

The script does not print the password. It prints the JDBC URL, query, and first
returned value for diagnosis.

## Packaging For Existing Metabase Images

After building `hanadb.metabase-driver.jar`, package the plugin files:

```bash
export HANA_NGDBC_JAR=/path/to/ngdbc.jar
make plugin-bundle
```

This creates `dist/metabase-hanadb-plugin-bundle.tar.gz`. See
`docs/EXISTING_IMAGE_INSTALL.md`.

## Local Stub

For UI-only plugin discovery smoke tests, you can build a local stub:

```bash
make ngdbc-stub
```

The stub only provides the JDBC driver class name. It cannot connect to SAP
HANA and must not be used for production, release artifacts, or real
connectivity testing.

## Security Notes

- Keep `.env` and all credential-bearing files out of Git.
- Do not commit SAP JDBC binaries unless their license explicitly permits it.
- Use non-admin HANA users for testing whenever possible.
- Avoid `validateCertificate=false` outside temporary troubleshooting.

## License

No license has been selected yet. Review the intended distribution model,
Metabase plugin compatibility, and SAP JDBC driver licensing before publishing
release artifacts.
