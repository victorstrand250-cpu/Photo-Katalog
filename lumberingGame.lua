-- lumberingGame.lua — Monetloader port
-- Умный режим: /lscan → играй мини-игру → бот находит пакет с параметрами → считает тайминг сам
-- Ручной режим: /lumber (с текущим TIMING)
--
-- /lscan         -- включить/выключить сканер пакетов (вкл перед игрой)
-- /lumber        -- ручной старт последовательности
-- /ltiming N     -- задать фиксированную задержку (мс)

local IID    = 8
local TIMING = 1000  -- фиксированная задержка (мс), используется если сканер не нашёл данные

local running   = false
local triggered = false
local scanning  = false

-- Параметры игры (если нашли через сканер)
local calcTiming = nil  -- nil = использовать TIMING

-- ===================================================
--  ОТПРАВКА КЛИКА
-- ===================================================
local function click(bid)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs,  220)
    raknetBitStreamWriteInt8(bs,  63)
    raknetBitStreamWriteInt8(bs,  IID)
    raknetBitStreamWriteInt32(bs, bid)
    raknetBitStreamWriteInt32(bs, bid)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStreamEx(bs, 1, 10, 1)
    raknetDeleteBitStream(bs)
end

-- ===================================================
--  ЧТЕНИЕ СЫРЫХ БАЙТ ИЗ БИТСТРИМА
-- ===================================================
local function readRaw(bs, maxBytes)
    local t = {}
    for i = 1, maxBytes do
        local ok, b = pcall(raknetBitStreamReadInt8, bs)
        if not ok then break end
        t[i] = string.char(b >= 0 and b or b + 256)
    end
    return table.concat(t)
end

local function numField(str, key)
    return tonumber(str:match('"' .. key .. '"%s*:%s*([%-?%d%.]+)'))
end

-- ===================================================
--  СКАНЕР: ищем пакет с isMyState в ЛЮБОМ пакете
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if not scanning or running then return end
    raknetBitStreamSetReadOffset(bs, 0)

    local raw = readRaw(bs, 256)
    if not raw:find('"isMyState"') then return end

    -- Нашли! Проверяем что это наш ход и начало игры
    if numField(raw, 'isMyState') ~= 1 then return end
    if numField(raw, 'currentPosition') ~= -1 then return end

    local s  = numField(raw, 'start')
    local w  = numField(raw, 'width')
    local sp = numField(raw, 'speed')

    if not s or not w or not sp then
        -- Данные есть но не распарсились — логируем для отладки
        sampAddChatMessage('{FFAA00}[LumberBot] Found packet pid=' .. pid
            .. ' but could not parse. Raw: ' .. raw:sub(1, 120), -1)
        return
    end

    -- Считаем тайминг как оригинальный PC скрипт
    local pos  = math.floor(s + w / 2 + 0.5)
    local pct  = math.floor((pos - s) / w * 100 + 0.5)
    calcTiming = math.floor(pos / sp + 0.5) * 75

    sampAddChatMessage(string.format(
        '{00FF80}[LumberBot] FOUND pid=%d  start=%.1f width=%.1f speed=%.2f  timing=%dms pos=%d(%d%%)',
        pid, s, w, sp, calcTiming, pos, pct), -1)

    scanning  = false
    triggered = true  -- сразу запускаем
end)

-- ===================================================
--  АВТО-ТРИГГЕР: TOGGLE ON (b1=62) на IID=8
-- (запасной, если сканер не поймал пакет до старта)
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if pid ~= 220 or running or scanning then return end
    raknetBitStreamSetReadOffset(bs, 0)
    local ok0, _    = pcall(raknetBitStreamReadInt8, bs)
    local ok1, b1   = pcall(raknetBitStreamReadInt8, bs)
    if not ok0 or not ok1 or b1 ~= 62 then return end

    local oi, iid   = pcall(raknetBitStreamReadInt8, bs)
    local ob, state = pcall(raknetBitStreamReadBool, bs)
    if not oi or iid ~= IID then return end
    if not ob or not state then return end

    calcTiming = nil  -- сброс: использовать фиксированный TIMING
    triggered  = true
end)

-- ===================================================
--  MAIN
-- ===================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('lscan', function()
        scanning = not scanning
        calcTiming = nil
        if scanning then
            sampAddChatMessage('{00FFCC}[LumberBot] Scanner ON — начинай мини-игру!', -1)
        else
            sampAddChatMessage('{AAAAAA}[LumberBot] Scanner OFF', -1)
        end
    end)

    sampRegisterChatCommand('lumber', function()
        if running then
            sampAddChatMessage('{FF4444}[LumberBot] Already running!', -1)
            return
        end
        calcTiming = nil
        triggered  = true
        sampAddChatMessage('{2ECC71}[LumberBot] Manual start (timing=' .. TIMING .. 'ms)', -1)
    end)

    sampRegisterChatCommand('ltiming', function(args)
        local n = tonumber(args)
        if not n or n < 50 then
            sampAddChatMessage('{FF4444}[LumberBot] /ltiming <ms>', -1)
            return
        end
        TIMING = n
        sampAddChatMessage('{2ECC71}[LumberBot] Fixed timing = ' .. n .. ' ms', -1)
    end)

    sampAddChatMessage(
        '{2ECC71}[LumberBot]{FFFFFF} /lscan — умный режим | /lumber — ручной | /ltiming <мс>',
        -1)

    while true do
        if triggered and not running then
            triggered  = false
            running    = true
            local t    = calcTiming or TIMING
            click(90)
            wait(t)
            click(91)
            wait(4000)
            click(92)
            wait(500)
            running    = false
            calcTiming = nil
        end
        wait(0)
    end
end
