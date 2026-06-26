# Obfuscation tooling

`ST_Mine.obfuscated.lua` is produced from the readable `ST_Mine.lua` with
the [Prometheus](https://github.com/prometheus-lua/Prometheus) Lua obfuscator.

## How it was built

```
PROMETHEUS_DIR=/path/to/Prometheus ./tools/build_obfuscated.sh
```

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
