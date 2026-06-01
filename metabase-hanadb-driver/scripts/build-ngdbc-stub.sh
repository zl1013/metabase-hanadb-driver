#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_JAR="${TARGET_JAR:-$ROOT_DIR/build/plugins/ngdbc.jar}"
DEFAULT_JAVA_21_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
WORK_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$WORK_DIR"
}

trap cleanup EXIT

select_java_home() {
  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/javac" ]]; then
    local current_major
    current_major="$("${JAVA_HOME}/bin/java" -version 2>&1 | awk -F '[\".]' '/version/ {print $2; exit}')"
    if [[ "$current_major" =~ ^[0-9]+$ ]] && (( current_major >= 21 )); then
      return 0
    fi
  fi

  if [[ -x "$DEFAULT_JAVA_21_HOME/bin/javac" ]]; then
    export JAVA_HOME="$DEFAULT_JAVA_21_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    return 0
  fi

  if [[ "$(uname -s)" == "Darwin" ]] && [[ -x /usr/libexec/java_home ]]; then
    local detected_java_home
    detected_java_home="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
    if [[ -n "$detected_java_home" && -x "$detected_java_home/bin/javac" ]]; then
      export JAVA_HOME="$detected_java_home"
      export PATH="$JAVA_HOME/bin:$PATH"
      return 0
    fi
  fi

  return 1
}

if ! select_java_home; then
  printf 'Java 21 is required to build the local ngdbc stub. Install openjdk@21 or set JAVA_HOME accordingly.\n' >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/build/plugins" "$WORK_DIR/src/com/sap/db/jdbc" "$WORK_DIR/classes"

cat >"$WORK_DIR/src/com/sap/db/jdbc/Driver.java" <<'EOF'
package com.sap.db.jdbc;

import java.sql.Connection;
import java.sql.DriverPropertyInfo;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.Properties;
import java.util.logging.Logger;

public final class Driver implements java.sql.Driver {
  public Driver() {}

  @Override
  public boolean acceptsURL(String url) {
    return url != null && url.startsWith("jdbc:sap:");
  }

  @Override
  public Connection connect(String url, Properties info) throws SQLException {
    throw new SQLFeatureNotSupportedException("Local ngdbc stub cannot open SAP HANA connections");
  }

  @Override
  public int getMajorVersion() {
    return 0;
  }

  @Override
  public int getMinorVersion() {
    return 0;
  }

  @Override
  public DriverPropertyInfo[] getPropertyInfo(String url, Properties info) {
    return new DriverPropertyInfo[0];
  }

  @Override
  public boolean jdbcCompliant() {
    return false;
  }

  @Override
  public Logger getParentLogger() {
    return Logger.getLogger("com.sap.db.jdbc.Driver");
  }
}
EOF

"$JAVA_HOME/bin/javac" -d "$WORK_DIR/classes" "$WORK_DIR/src/com/sap/db/jdbc/Driver.java"
"$JAVA_HOME/bin/jar" --create --file "$TARGET_JAR" -C "$WORK_DIR/classes" .

printf 'Built local-only ngdbc stub at %s\n' "$TARGET_JAR"
