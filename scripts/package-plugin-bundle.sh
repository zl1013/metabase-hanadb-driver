#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist/plugin-bundle"
PLUGIN_JAR="${PLUGIN_JAR:-${ROOT_DIR}/build/plugins/hanadb.metabase-driver.jar}"
HANA_NGDBC_JAR="${HANA_NGDBC_JAR:-}"

require_file() {
  local path="$1"
  local label="$2"
  if [[ ! -f "$path" ]]; then
    printf '%s not found: %s\n' "$label" "$path" >&2
    exit 1
  fi
}

require_file "$PLUGIN_JAR" "Built driver jar"

# 注释掉对 HANA_NGDBC_JAR 的强制检查
# if [[ -z "$HANA_NGDBC_JAR" ]]; then
#   printf 'Set HANA_NGDBC_JAR to the path of ngdbc.jar before packaging the plugin bundle\n' >&2
#   exit 1
# fi

# 修改后续的复制逻辑，让它在 HANA_NGDBC_JAR 为空时跳过复制
if [[ -n "$HANA_NGDBC_JAR" ]]; then
  require_file "$HANA_NGDBC_JAR" "SAP HANA JDBC jar"
  cp "$HANA_NGDBC_JAR" "$DIST_DIR/plugins/ngdbc.jar"
else
  printf 'Warning: HANA_NGDBC_JAR not set, ngdbc.jar will not be included in the bundle\n' >&2
fi

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/plugins"

cp "$PLUGIN_JAR" "$DIST_DIR/plugins/"
# 移除了原来强制复制 ngdbc.jar 的行
cp "${ROOT_DIR}/docker-compose.plugins.yml" "$DIST_DIR/"
cp "${ROOT_DIR}/scripts/install-existing-image-plugin.sh" "$DIST_DIR/"
cp "${ROOT_DIR}/docs/EXISTING_IMAGE_INSTALL.md" "$DIST_DIR/"

(
  cd "${ROOT_DIR}/dist"
  tar -czf "metabase-hanadb-plugin-bundle.tar.gz" "plugin-bundle"
)

printf 'Plugin bundle ready at %s\n' "$DIST_DIR"
printf 'Archive ready at %s/dist/metabase-hanadb-plugin-bundle.tar.gz\n' "$ROOT_DIR"
printf 'Copy the archive to the offline server, unpack it, and run ./install-existing-image-plugin.sh there.\n'
