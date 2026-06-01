#!/usr/bin/env bash
set -euo pipefail

NGDBC_JAR="${NGDBC_JAR:-${HANA_NGDBC_JAR:-}}"
TMP_DIR="$(mktemp -d)"
JAVA_FILE="${TMP_DIR}/HanaJdbcSmoke.java"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    printf 'Set %s before running the JDBC HANA smoke test\n' "$name" >&2
    exit 1
  fi
}

if ! command -v java >/dev/null 2>&1; then
  printf 'java is required for the JDBC HANA smoke test\n' >&2
  exit 1
fi

if [[ -z "$NGDBC_JAR" ]]; then
  printf 'Set NGDBC_JAR or HANA_NGDBC_JAR to the path of ngdbc.jar\n' >&2
  exit 1
fi

if [[ ! -f "$NGDBC_JAR" ]]; then
  printf 'ngdbc.jar not found at %s\n' "$NGDBC_JAR" >&2
  exit 1
fi

require_env HANA_HOST
require_env HANA_USER
require_env HANA_PASS

export HANA_PORT="${HANA_PORT:-30015}"
export HANA_TEST_QUERY="${HANA_TEST_QUERY:-SELECT 1 AS HEALTHCHECK FROM DUMMY}"

cat >"$JAVA_FILE" <<'JAVA'
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class HanaJdbcSmoke {
  private static String buildUrl() {
    String host = System.getenv("HANA_HOST");
    String port = System.getenv().getOrDefault("HANA_PORT", "30015");
    List<String> params = new ArrayList<>();

    String database = System.getenv("HANA_DATABASE");
    if (database != null && !database.isBlank()) {
      params.add("databaseName=" + database);
    }

    String schema = System.getenv("HANA_SCHEMA");
    if (schema != null && !schema.isBlank()) {
      params.add("currentSchema=" + schema);
    }

    String ssl = System.getenv("HANA_SSL");
    if ("true".equalsIgnoreCase(ssl)) {
      params.add("encrypt=true");
    }

    StringBuilder url = new StringBuilder("jdbc:sap://" + host + ":" + port + "/");
    if (!params.isEmpty()) {
      url.append('?');
      url.append(String.join("&", params));
    }
    return url.toString();
  }

  public static void main(String[] args) throws Exception {
    Class.forName("com.sap.db.jdbc.Driver");

    String url = buildUrl();
    String query = System.getenv().getOrDefault("HANA_TEST_QUERY", "SELECT 1 AS HEALTHCHECK FROM DUMMY");

    Properties props = new Properties();
    props.setProperty("user", System.getenv("HANA_USER"));
    props.setProperty("password", System.getenv("HANA_PASS"));

    try (Connection conn = DriverManager.getConnection(url, props);
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery(query)) {
      if (!rs.next()) {
        throw new IllegalStateException("Query returned no rows");
      }

      Object firstValue = rs.getObject(1);
      System.out.println("JDBC HANA smoke test passed");
      System.out.println("JDBC URL: " + url);
      System.out.println("Query: " + query);
      System.out.println("First value: " + firstValue);
    }
  }
}
JAVA

java --class-path "$NGDBC_JAR" "$JAVA_FILE"
