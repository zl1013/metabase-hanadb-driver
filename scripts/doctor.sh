#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
status=0

have() {
  command -v "$1" >/dev/null 2>&1
}

java_major_version() {
  java -version 2>&1 | awk -F '[\".]' '/version/ {print $2; exit}'
}

note_ok() {
  printf '[OK] %s\n' "$1"
}

note_warn() {
  printf '[WARN] %s\n' "$1"
  status=1
}

printf 'Project root: %s\n' "$ROOT_DIR"
printf 'Host: %s\n' "$(uname -a)"

for cmd in git docker java clojure; do
  if have "$cmd"; then
    note_ok "Found command: $cmd"
  else
    note_warn "Missing command: $cmd"
  fi
done

if have docker; then
  if docker info >/dev/null 2>&1; then
    note_ok "Docker daemon is reachable"
  else
    note_warn "Docker CLI exists but the daemon is not running"
  fi
fi

if have java; then
  java_major="$(java_major_version || true)"
  if [[ "$java_major" =~ ^[0-9]+$ ]] && (( java_major >= 21 )); then
    note_ok "Java version is compatible with current Metabase builds ($java_major)"
  else
    note_warn "Java 21+ is required; active Java major version is ${java_major:-unknown}"
  fi
fi

if [[ -d "$ROOT_DIR/driver" ]]; then
  note_ok "Driver workspace exists"
else
  note_warn "Driver workspace is missing"
fi

if [[ -f "$ROOT_DIR/docker-compose.yml" ]]; then
  note_ok "docker-compose.yml present"
else
  note_warn "docker-compose.yml missing"
fi

if [[ -f "$ROOT_DIR/.env" ]]; then
  note_ok ".env present"
else
  note_warn ".env is missing; copy .env.example to .env for local runs"
fi

exit "$status"
