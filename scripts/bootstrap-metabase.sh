#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METABASE_SRC_DIR="${METABASE_SRC_DIR:-$ROOT_DIR/.worktrees/metabase}"
METABASE_REF="${METABASE_REF:-master}"

mkdir -p "$(dirname "$METABASE_SRC_DIR")" "$ROOT_DIR/build/plugins" "$ROOT_DIR/driver"

if [[ -d "$METABASE_SRC_DIR/.git" ]]; then
  printf 'Metabase source already exists at %s\n' "$METABASE_SRC_DIR"
  (
    cd "$METABASE_SRC_DIR"
    git fetch --all --tags
    git checkout "$METABASE_REF"
    git pull --ff-only origin "$METABASE_REF"
  )
else
  git clone https://github.com/metabase/metabase "$METABASE_SRC_DIR"
  (
    cd "$METABASE_SRC_DIR"
    git checkout "$METABASE_REF"
  )
fi

printf 'Metabase source ready at %s\n' "$METABASE_SRC_DIR"
