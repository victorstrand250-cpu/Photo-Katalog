-- lumberingGame.lua — Monetloader port

local rageMode = false -- true = клик в центр без задержки (100%), false = расчётный тайминг

local started = false

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

    local ok, data = pcall(json.decode, jsonStr)
    if not ok or type(data) ~= 'table' then return end

    local gameData = data[1]
    if type(gameData) ~= 'table' then return end
    if gameData.isMyState ~= 1 then return end
    if type(gameData.infoUser) ~= 'table' then return end
    if gameData.infoUser[1].currentPosition ~= -1 then return end
    if not gameData.start or not gameData.width or not gameData.speed then return end
    if started then return end

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
