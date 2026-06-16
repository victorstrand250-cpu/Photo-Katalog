-- lumberingGame.lua — Monetloader port
-- IID=8: bid=90=старт, bid=91=стоп, bid=92=закрыть результат
--
-- /lumber       -- запустить вручную (встать у бревна)
-- /ltiming N    -- сменить задержку (мс, по умолчанию 1000)

local IID    = 8     -- Interface ID мини-игры лесоповала
local TIMING = 1000  -- задержка между bid=90 и bid=91 (мс)

local running  = false
local triggered = false

local function click(bid)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs,  220)
    raknetBitStreamWriteInt8(bs,  63)
    raknetBitStreamWriteInt8(bs,  IID)
    raknetBitStreamWriteInt32(bs, bid)
    raknetBitStreamWriteInt32(bs, bid)  -- sub = bid
    raknetBitStreamWriteInt32(bs, 0)    -- данных нет
    raknetSendBitStreamEx(bs, 1, 10, 1)
    raknetDeleteBitStream(bs)
end

-- Авто-триггер: TOGGLE ON (b1=62) на IID=8
addEventHandler('onReceivePacket', function(pid, bs)
    if pid ~= 220 or running then return end
    raknetBitStreamSetReadOffset(bs, 0)
    local ok0, _   = pcall(raknetBitStreamReadInt8, bs)
    local ok1, b1  = pcall(raknetBitStreamReadInt8, bs)
    if not ok0 or not ok1 or b1 ~= 62 then return end

    local oi, iid   = pcall(raknetBitStreamReadInt8, bs)
    local ob, state = pcall(raknetBitStreamReadBool, bs)
    if not oi or iid ~= IID then return end
    if not ob or not state then return end  -- только TOGGLE ON

    triggered = true
end)

function main()
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('lumber', function()
        if running then
            sampAddChatMessage('{FF4444}[LumberBot] Already running!', -1)
            return
        end
        triggered = true
        sampAddChatMessage('{2ECC71}[LumberBot] Manual trigger.', -1)
    end)

    sampRegisterChatCommand('ltiming', function(args)
        local n = tonumber(args)
        if not n or n < 100 then
            sampAddChatMessage('{FF4444}[LumberBot] /ltiming <ms>', -1)
            return
        end
        TIMING = n
        sampAddChatMessage('{2ECC71}[LumberBot] Timing = ' .. n .. ' ms', -1)
    end)

    sampAddChatMessage('{2ECC71}[LumberBot]{FFFFFF} IID=8 timing=' .. TIMING .. 'ms | /lumber | /ltiming <ms>', -1)

    while true do
        if triggered and not running then
            triggered = false
            running   = true
            click(90)           -- Старт
            wait(TIMING)        -- ждём пока топор у нужной точки
            click(91)           -- Стоп
            wait(4000)          -- ждём окно результата
            click(92)           -- Закрыть
            wait(500)
            running = false
        end
        wait(0)
    end
end
