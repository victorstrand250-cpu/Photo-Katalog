#!/usr/bin/env bash
# Builds <name>.obfuscated.lua from a source Lua file using Prometheus.
#
# Requirements:
#   - lua5.1 (to run Prometheus)
#   - Prometheus checked out; set PROMETHEUS_DIR to its path
#     (default: ./Prometheus). Get it from:
#     https://github.com/prometheus-lua/Prometheus
#
# Usage:
#   PROMETHEUS_DIR=/path/to/Prometheus ./tools/build_obfuscated.sh <source.lua> [--globalize]
#
#   --globalize   run tools/globalize_for_obf.py first (needed only for
#                 ST_Mine.lua, whose main chunk sits at LuaJIT's 200-local
#                 limit). Other scripts obfuscate without it.
#
# Default (no args): builds ST_Mine.lua --globalize for backwards compat.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROM="${PROMETHEUS_DIR:-$ROOT/Prometheus}"

SRC="${1:-ST_Mine.lua}"
GLOBALIZE="${2:-}"
# Mine variants (ST_Mine.lua, serverST_Mine_stok.lua, ...) sit at LuaJIT's
# 200-local limit and need globalization; auto-enable it for them.
if [ -z "$GLOBALIZE" ]; then
    case "$(basename "$SRC")" in
        *Mine*) GLOBALIZE="--globalize" ;;
    esac
fi

case "$SRC" in
    /*) SRC_PATH="$SRC" ;;
    *)  SRC_PATH="$ROOT/$SRC" ;;
esac
BASE="$(basename "$SRC_PATH" .lua)"
OUT="$ROOT/$BASE.obfuscated.lua"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

INPUT="$SRC_PATH"
if [ "$GLOBALIZE" = "--globalize" ]; then
    python3 "$ROOT/tools/globalize_for_obf.py" "$SRC_PATH" "$TMP/src.lua"
    INPUT="$TMP/src.lua"
fi

( cd "$PROM" && lua5.1 cli.lua \
    --config "$ROOT/tools/prometheus_config.lua" \
    --Lua51 --nocolors \
    --out "$OUT" \
    "$INPUT" )

echo "Built $OUT"
