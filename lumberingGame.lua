-- lumberingGame.lua — Monetloader port
-- Автоматизация мини-игры лесоповала на Arizona RP Mobile
--
-- /lumber        -- ручной старт (если интерфейс уже открыт)
-- /ltiming N     -- задать задержку мс
-- /lcalib        -- режим авто-калибровки (подбирает тайминг сам, за 4-6 попыток)
-- /lscan         -- умный режим (только если сервер шлёт JSON параметры)
--
-- ПРИМЕЧАНИЕ: тайминг подбирается вручную через /ltiming или авто через /lcalib.
-- Для полного автоматического режима нужно декодировать бинарный пакет
-- сервера. Используй gameBinaryScanner.lua для сбора данных.

local IID    = 8
local TIMING = 1000  -- базовая задержка мс

local running    = false
local triggered  = false
local scanning   = false
local calcTiming = nil

-- Режим авто-калибровки
local calibMode   = false
local calibStep   = 150  -- шаг подбора мс
local calibDir    = 1    -- +1 вверх, -1 вниз
local calibTries  = 0
local calibBest   = nil  -- лучший тайминг (если нашли успех)

-- ===================================================
--  ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
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
--  РЕЗУЛЬТАТ МИНИ-ИГРЫ
--  Пакет: pid=220, b1=84, IID=8 -> JSON [{"chance":N,"success":0|1}]
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if pid ~= 220 then return end
    raknetBitStreamSetReadOffset(bs, 0)
    pcall(raknetBitStreamReadInt8, bs)
    local ok1, b1  = pcall(raknetBitStreamReadInt8, bs)
    if not ok1 or b1 ~= 84 then return end
    local ok2, iid = pcall(raknetBitStreamReadInt8, bs)
    if not ok2 or iid ~= IID then return end

    local raw     = readRaw(bs, 150)
    local success = numField(raw, 'success')
    if success == nil then return end

    local chance = numField(raw, 'chance') or 0
    local usedT  = calcTiming or TIMING

    if success == 1 then
        sampAddChatMessage(string.format(
            '{2ECC71}[LumberBot] SUCCESS! chance=%d%% timing=%dms',
            chance, usedT), -1)
        -- Сохраняем удачный тайминг при калибровке
        if calibMode then
            calibBest  = usedT
            calibTries = 0
            calibDir   = 1
            calibStep  = 150
            sampAddChatMessage('{2ECC71}[LumberBot] Calibrated! Use /ltiming ' .. usedT, -1)
            calibMode = false
        end
    else
        sampAddChatMessage(string.format(
            '{FF4444}[LumberBot] MISS! chance=%d%% timing=%dms',
            chance, usedT), -1)
        -- Авто-калибровка: подсказываем следующий тайминг
        if calibMode and calibTries < 6 then
            calibTries = calibTries + 1
            -- Попеременно пробуем выше/ниже с нарастающим шагом
            if calibDir == 1 then
                TIMING  = usedT + calibStep
                calibDir = -1
            else
                TIMING  = usedT - calibStep * 2
                calibDir = 1
                calibStep = math.floor(calibStep * 1.3)
            end
            sampAddChatMessage(string.format(
                '{FFAA00}[LumberBot] Calib try %d/6 -> next timing=%dms',
                calibTries, TIMING), -1)
            sampAddChatMessage('{AAAAAA}Walk to log again to retry.', -1)
        elseif calibMode then
            sampAddChatMessage('{FF4444}[LumberBot] Calib failed after 6 tries.', -1)
            sampAddChatMessage('{FFAA00}Try /ltiming manually (500-2000ms range)', -1)
            calibMode  = false
            calibTries = 0
        else
            -- Подсказки для ручного режима
            sampAddChatMessage(string.format(
                '{FFAA00}Try /ltiming %d  or  /ltiming %d',
                math.floor(usedT * 0.80), math.floor(usedT * 1.20)), -1)
        end
    end
end)

-- ===================================================
--  УМНЫЙ СКАНЕР: ищем JSON isMyState (работает только на ПК)
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if not scanning or running then return end
    raknetBitStreamSetReadOffset(bs, 0)

    local raw = readRaw(bs, 256)
    if not raw:find('"isMyState"') then return end
    if numField(raw, 'isMyState') ~= 1 then return end
    if numField(raw, 'currentPosition') ~= -1 then return end

    local s, w, sp = numField(raw,'start'), numField(raw,'width'), numField(raw,'speed')
    if not s or not w or not sp then
        sampAddChatMessage('{FFAA00}[LumberBot] Found packet but params not parsed', -1)
        sampAddChatMessage('{AAAAAA}' .. raw:sub(1, 100), -1)
        return
    end

    local pos = math.floor(s + w / 2 + 0.5)
    calcTiming = math.floor(pos / sp + 0.5) * 75

    sampAddChatMessage(string.format(
        '{00FF80}[LumberBot] AUTO: start=%.1f w=%.1f sp=%.2f -> %dms',
        s, w, sp, calcTiming), -1)

    scanning  = false
    triggered = true
end)

-- ===================================================
--  АВТО-ТРИГГЕР: TOGGLE ON (b1=62) для IID=8
--  Срабатывает автоматически когда сервер открывает игру
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if pid ~= 220 or running or scanning then return end
    raknetBitStreamSetReadOffset(bs, 0)
    pcall(raknetBitStreamReadInt8, bs)
    local ok1, b1    = pcall(raknetBitStreamReadInt8, bs)
    if not ok1 or b1 ~= 62 then return end
    local ok2, iid   = pcall(raknetBitStreamReadInt8, bs)
    if not ok2 or iid ~= IID then return end
    local ok3, state = pcall(raknetBitStreamReadBool, bs)
    if not ok3 or not state then return end

    calcTiming = nil
    triggered  = true
    sampAddChatMessage(string.format(
        '{00FFCC}[LumberBot] Game opened! timing=%dms', TIMING), -1)
end)

-- ===================================================
--  ОТПРАВКА КЛИКА
-- ===================================================
local function click(bid)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs,  220)
    raknetBitStreamWriteInt8(bs,   63)
    raknetBitStreamWriteInt8(bs,  IID)
    raknetBitStreamWriteInt32(bs, bid)
    raknetBitStreamWriteInt32(bs, bid)
    raknetBitStreamWriteInt32(bs,   0)
    raknetSendBitStreamEx(bs, 1, 10, 1)
    raknetDeleteBitStream(bs)
end

-- ===================================================
--  MAIN
-- ===================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('lscan', function()
        scanning = not scanning
        calcTiming = nil
        sampAddChatMessage(
            scanning and '{00FFCC}[LumberBot] Scanner ON - start mini-game!'
                      or '{AAAAAA}[LumberBot] Scanner OFF', -1)
    end)

    sampRegisterChatCommand('lumber', function()
        if running then
            sampAddChatMessage('{FF4444}[LumberBot] Already running!', -1)
            return
        end
        calcTiming = nil
        triggered  = true
        sampAddChatMessage('{2ECC71}[LumberBot] Manual start! timing=' .. TIMING .. 'ms', -1)
    end)

    sampRegisterChatCommand('ltiming', function(args)
        local n = tonumber(args)
        if not n or n < 50 then
            sampAddChatMessage('{FF4444}[LumberBot] Usage: /ltiming <ms>  (min 50)', -1)
            sampAddChatMessage('{AAAAAA}  Current: ' .. TIMING .. 'ms', -1)
            return
        end
        TIMING     = n
        calibBest  = nil
        calibTries = 0
        sampAddChatMessage('{2ECC71}[LumberBot] Timing set: ' .. n .. 'ms', -1)
    end)

    sampRegisterChatCommand('lcalib', function()
        calibMode  = not calibMode
        calibTries = 0
        calibDir   = 1
        calibStep  = 150
        if calibMode then
            sampAddChatMessage('{00FFCC}[LumberBot] Calibration ON', -1)
            sampAddChatMessage('{AAAAAA}Walk to logs - bot will adjust timing each try', -1)
        else
            sampAddChatMessage('{AAAAAA}[LumberBot] Calibration OFF', -1)
        end
    end)

    sampAddChatMessage(
        '{2ECC71}[LumberBot]{FFFFFF} /lumber | /ltiming <ms> | /lcalib | /lscan', -1)

    while true do
        if triggered and not running then
            triggered  = false
            running    = true
            local t    = calcTiming or TIMING

            click(90)     -- START
            wait(t)
            click(91)     -- STOP
            wait(4000)    -- wait for result animation
            click(92)     -- CLOSE
            wait(500)

            running    = false
            calcTiming = nil
        end
        wait(0)
    end
end
