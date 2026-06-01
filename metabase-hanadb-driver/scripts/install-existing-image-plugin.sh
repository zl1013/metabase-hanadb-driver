#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_TARGET_DIR="${1:-/opt/metabase/plugins}"
NGDBC_SOURCE="${NGDBC_JAR:-${BUNDLE_DIR}/plugins/ngdbc.jar}"

if [[ ! -d "${BUNDLE_DIR}/plugins" ]]; then
  printf 'plugins directory not found next to %s\n' "${BASH_SOURCE[0]}" >&2
  exit 1
fi

if [[ ! -f "${BUNDLE_DIR}/plugins/hanadb.metabase-driver.jar" ]]; then
  printf 'hanadb.metabase-driver.jar not found in %s/plugins\n' "$BUNDLE_DIR" >&2
  exit 1
fi

if [[ ! -f "$NGDBC_SOURCE" ]]; then
  printf 'Real SAP HANA JDBC driver ngdbc.jar was not found.\n' >&2
  printf 'Put ngdbc.jar at %s/plugins/ngdbc.jar, or run with NGDBC_JAR=/path/to/ngdbc.jar.\n' "$BUNDLE_DIR" >&2
  exit 1
fi

mkdir -p "$PLUGIN_TARGET_DIR"
cp "${BUNDLE_DIR}/plugins/hanadb.metabase-driver.jar" "${PLUGIN_TARGET_DIR}/"
cp "$NGDBC_SOURCE" "${PLUGIN_TARGET_DIR}/ngdbc.jar"

chmod 644 "${PLUGIN_TARGET_DIR}/hanadb.metabase-driver.jar" "${PLUGIN_TARGET_DIR}/ngdbc.jar"

printf 'Installed plugin files into %s\n' "$PLUGIN_TARGET_DIR"
printf 'Restart Metabase with MB_PLUGINS_DIR=/plugins and bind-mount %s to /plugins\n' "$PLUGIN_TARGET_DIR"
printf 'If you use Docker Compose, merge docker-compose.plugins.yml into your existing stack.\n'
