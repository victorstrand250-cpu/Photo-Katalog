#!/usr/bin/env bash
# Builds ST_Mine.obfuscated.lua from ST_Mine.lua using Prometheus.
#
# Requirements:
#   - lua5.1 (to run Prometheus)
#   - Prometheus checked out; set PROMETHEUS_DIR to its path
#     (default: ./Prometheus). Get it from:
#     https://github.com/prometheus-lua/Prometheus
#
# Usage:  PROMETHEUS_DIR=/path/to/Prometheus ./tools/build_obfuscated.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROM="${PROMETHEUS_DIR:-$ROOT/Prometheus}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 "$ROOT/tools/globalize_for_obf.py" "$ROOT/ST_Mine.lua" "$TMP/src.lua"

( cd "$PROM" && lua5.1 cli.lua \
    --config "$ROOT/tools/prometheus_config.lua" \
    --Lua51 --nocolors \
    --out "$ROOT/ST_Mine.obfuscated.lua" \
    "$TMP/src.lua" )

echo "Built $ROOT/ST_Mine.obfuscated.lua"
