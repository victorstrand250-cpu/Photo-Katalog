#!/usr/bin/env python3
# Moves a fixed set of private top-level scalar state variables from `local`
# to global. The main chunk of ST_Mine.lua sits right at LuaJIT's 200
# simultaneously-live-local limit, so any Prometheus step that injects its own
# top-level locals (string decryptor, constant array) would overflow it.
# Globalizing these few state vars frees the slots. Behaviour is identical:
# each MoonLoader script runs in its own Lua state, so there are no global
# collisions, and these vars were module-level state anyway.
import re, sys

NAMES = """
totalStone totalMetal totalSilver totalBronze totalGold totalWorkTime sessionWorkTime
PRICE_STONE PRICE_METAL PRICE_SILVER PRICE_BRONZE PRICE_GOLD
autoEat autoEatMode autoEatFood autoEatMinSatiety autoEatSatiety autoEatWaitSat
autoEatWaitEat autoEatLastEat larekRunning
goalMode goalOreAmount goalMoney goalMinutes goalQuit goalReached
isRunning _statsDirty jumping doJumpThisFrame nextJumpTime
licenseOK licenseChecking licenseMsg
""".split()

src, dst = sys.argv[1], sys.argv[2]
lines = open(src, encoding='latin-1').read().split('\n')
count = 0
for i, l in enumerate(lines):
    m = re.match(r'^local ([A-Za-z_][A-Za-z0-9_]*)( *=.*)$', l)
    if m and m.group(1) in NAMES:
        lines[i] = m.group(1) + m.group(2)
        count += 1
open(dst, 'w', encoding='latin-1').write('\n'.join(lines))
print("globalized %d locals" % count)
