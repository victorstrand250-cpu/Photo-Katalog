# Obfuscation tooling

The `*.obfuscated.lua` files are produced from their readable sources with the
[Prometheus](https://github.com/prometheus-lua/Prometheus) Lua obfuscator:

| source | obfuscated |
| --- | --- |
| `ST_Mine.lua` | `ST_Mine.obfuscated.lua` |
| `ST_Ferma.lua` | `ST_Ferma.obfuscated.lua` |
| `server_ST_Ferma.lua` | `server_ST_Ferma.obfuscated.lua` |
| `serverST_Mine_stok.lua` | `serverST_Mine_stok.obfuscated.lua` |

## How it was built

```
PROMETHEUS_DIR=/path/to/Prometheus ./tools/build_obfuscated.sh ST_Mine.lua
PROMETHEUS_DIR=/path/to/Prometheus ./tools/build_obfuscated.sh ST_Ferma.lua
PROMETHEUS_DIR=/path/to/Prometheus ./tools/build_obfuscated.sh server_ST_Ferma.lua
PROMETHEUS_DIR=/path/to/Prometheus ./tools/build_obfuscated.sh serverST_Mine_stok.lua
```

Mine variants (`*Mine*`) are built with `--globalize` (applied automatically)
because their main chunk sits at LuaJIT's 200-local limit; the Ferma scripts
need no globalization.

Steps performed:

1. `tools/globalize_for_obf.py` moves ~35 private top-level scalar state
   variables from `local` to global. The main chunk sits right at LuaJIT's
   limit of 200 simultaneously-live locals, so any Prometheus step that adds
   its own top-level locals would otherwise overflow it. Behaviour is
   unchanged (each MoonLoader script has its own Lua state — no global
   collisions).
2. Prometheus runs with `tools/prometheus_config.lua`:
   - **EncryptStrings** — hides chat lines, URLs, API endpoints, the system
     prompt, etc.
   - **ConstantArray** (strings, shuffled + rotated) — pulls string literals
     into one obfuscated array.
   - **MangledShuffled** local-name renaming.

Deliberately **not** used, to avoid breaking a MoonLoader/LuaJIT script:
`Vmify` and `AntiTamper` (break ffi callbacks / coroutines / per-frame
performance) and `NumbersToExpressions` (could perturb route float
coordinates).

## Notes

- The obfuscator targets Lua 5.1; the source must contain no `goto`/labels
  (LuaJIT extension) — they have been refactored away.
- `\xHH` string escapes are preserved byte-exactly (emitted as `\ddd`).
