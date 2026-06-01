#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METABASE_SRC_DIR="${METABASE_SRC_DIR:-$ROOT_DIR/.worktrees/metabase}"
DRIVER_SRC_DIR="$ROOT_DIR/driver"
DRIVER_NAME="${DRIVER_NAME:-hanadb}"
DEFAULT_JAVA_21_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"

java_major_version_for() {
  local java_bin="$1"
  "$java_bin" -version 2>&1 | awk -F '[\".]' '/version/ {print $2; exit}'
}

select_java_home() {
  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]]; then
    local current_major
    current_major="$(java_major_version_for "${JAVA_HOME}/bin/java")"
    if [[ "$current_major" =~ ^[0-9]+$ ]] && (( current_major >= 21 )); then
      return 0
    fi
  fi

  if [[ -x "$DEFAULT_JAVA_21_HOME/bin/java" ]]; then
    export JAVA_HOME="$DEFAULT_JAVA_21_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    return 0
  fi

  if [[ "$(uname -s)" == "Darwin" ]] && [[ -x /usr/libexec/java_home ]]; then
    local detected_java_home
    detected_java_home="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
    if [[ -n "$detected_java_home" && -x "$detected_java_home/bin/java" ]]; then
      export JAVA_HOME="$detected_java_home"
      export PATH="$JAVA_HOME/bin:$PATH"
      return 0
    fi
  fi

  return 1
}

java_major_version() {
  java_major_version_for "${JAVA_HOME}/bin/java"
}

ensure_java_21() {
  if ! select_java_home; then
    printf 'Java 21 is required to build current Metabase drivers. Install openjdk@21 or set JAVA_HOME accordingly.\n' >&2
    exit 1
  fi

  local java_major
  java_major="$(java_major_version)"
  if [[ ! "$java_major" =~ ^[0-9]+$ ]] || (( java_major < 21 )); then
    printf 'Java 21 or newer is required. Active Java reports major version: %s\n' "${java_major:-unknown}" >&2
    exit 1
  fi

  printf 'Using JAVA_HOME=%s\n' "$JAVA_HOME"
}

ensure_driver_module_registered() {
  local modules_deps_file="$METABASE_SRC_DIR/modules/drivers/deps.edn"

  if [[ ! -f "$modules_deps_file" ]]; then
    printf 'Expected Metabase driver deps file at %s\n' "$modules_deps_file" >&2
    exit 1
  fi

  if grep -q "metabase/${DRIVER_NAME}" "$modules_deps_file"; then
    return 0
  fi

  perl -0pi -e 's/\}\}\}\s*\z/}\n  metabase\/'"$DRIVER_NAME"' {:local\/root "'"$DRIVER_NAME"'"}\}\}\n/s' "$modules_deps_file"
  printf 'Registered %s in %s\n' "$DRIVER_NAME" "$modules_deps_file"
}

if [[ ! -d "$METABASE_SRC_DIR/.git" ]]; then
  printf 'Metabase source not found. Run ./scripts/bootstrap-metabase.sh first.\n' >&2
  exit 1
fi

if [[ ! -f "$DRIVER_SRC_DIR/README.md" ]]; then
  printf 'Driver scaffold not found at %s.\n' "$DRIVER_SRC_DIR" >&2
  exit 1
fi

if [[ ! -f "$DRIVER_SRC_DIR/src/metabase/driver/${DRIVER_NAME}.clj" ]]; then
  printf 'Driver source %s/src/metabase/driver/%s.clj does not exist yet.\n' "$DRIVER_SRC_DIR" "$DRIVER_NAME" >&2
  printf 'This scaffold is ready for the implementation phase, but no buildable driver has been added yet.\n' >&2
  exit 1
fi

ensure_java_21

TARGET_DIR="$METABASE_SRC_DIR/modules/drivers/$DRIVER_NAME"
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cp -R "$DRIVER_SRC_DIR"/. "$TARGET_DIR"/
ensure_driver_module_registered

(
  cd "$METABASE_SRC_DIR"
  ./bin/build-driver.sh "$DRIVER_NAME"
)

mkdir -p "$ROOT_DIR/build/plugins"
find "$METABASE_SRC_DIR" -name "${DRIVER_NAME}.metabase-driver.jar" -exec cp {} "$ROOT_DIR/build/plugins/" \;

printf 'Driver build completed. Output copied to %s/build/plugins\n' "$ROOT_DIR"
