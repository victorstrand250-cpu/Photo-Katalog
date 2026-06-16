-- lumberingGame.lua — Monetloader port

local rageMode = false -- true = мгновенный клик в центр (100%), false = расчётный тайминг

local started = false

-- Извлекаем числовые поля из JSON строкой без json-модуля
local function parseGameData(str)
    local function num(k)
        return tonumber(str:match('"' .. k .. '"%s*:%s*([%-?%d%.]+)'))
    end
    if num('isMyState') ~= 1       then return nil end
    if num('currentPosition') ~= -1 then return nil end
    local s, w, sp = num('start'), num('width'), num('speed')
    if not s or not w or not sp    then return nil end
    return { start = s, width = w, speed = sp }
end

local function sendClick(iid, text)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 63)
    raknetBitStreamWriteInt8(bs, iid)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt32(bs, #text)
    raknetBitStreamWriteString(bs, text)
    raknetSendBitStreamEx(bs, 1, 10, 1)
    raknetDeleteBitStream(bs)
end

addEventHandler('onReceivePacket', function(pid, bs)
    if pid ~= 220 then return end
    raknetBitStreamSetReadOffset(bs, 0)
    local ok0, _   = pcall(raknetBitStreamReadInt8, bs)
    local ok1, b1  = pcall(raknetBitStreamReadInt8, bs)
    if not ok0 or not ok1 or b1 ~= 84 then return end

    local oi, iid = pcall(raknetBitStreamReadInt8, bs)
    local os, sub = pcall(raknetBitStreamReadInt8, bs)
    if not oi or not os then return end

    local ol, len = pcall(raknetBitStreamReadInt32, bs)
    if not ol or len <= 0 or len > 8192 then return end

    local od, jsonStr = pcall(raknetBitStreamReadString, bs, len)
    if not od or not jsonStr then return end

    local gameData = parseGameData(jsonStr)
    if not gameData or started then return end

    thread.create(function()
        local pos = math.floor(gameData.start + gameData.width / 2 + 0.5)
        local pct = math.floor((pos - gameData.start) / gameData.width * 100 + 0.5)
        started = true
        sendClick(iid, 'lumbering-game.start')
        local w = math.floor(pos / gameData.speed + 0.5) * 75
        wait(rageMode and 50 or w)
        started = false
        sendClick(iid, ('lumbering-game.turnEnd|%d|%d'):format(pos, pct))
    end)
end)

function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage('{2ECC71}[LumberBot] Loaded. rageMode=' .. tostring(rageMode), -1)
    while true do wait(0) end
end
