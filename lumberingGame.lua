-- lumberingGame.lua — Monetloader port
-- Автоматизация мини-игры лесоповала на Arizona RP Mobile
--
-- /lumber        — запустить последовательность (если интерфейс уже открыт)
-- /ltiming N     — задать задержку мс (подбирается вручную)
-- /lscan         — включить/выключить умный сканер (работает если сервер шлёт JSON)
--
-- Как подобрать тайминг:
--   1. /lumber → смотри в чат УСПЕХ/ПРОМАХ
--   2. Если ПРОМАХ — попробуй /ltiming 800 или /ltiming 1200
--   3. Повторяй пока не будет УСПЕХ
--   4. Запомни это значение

local IID    = 8
local TIMING = 1000  -- задержка между START и STOP (мс)

local running    = false
local triggered  = false
local scanning   = false
local calcTiming = nil  -- nil = используем TIMING

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
--  РЕЗУЛЬТАТ МИНИ-ИГРЫ (success / fail)
--  Пакет: pid=220, b1=84, IID=8 → JSON [{"chance":N,"success":0|1}]
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if pid ~= 220 then return end
    raknetBitStreamSetReadOffset(bs, 0)
    pcall(raknetBitStreamReadInt8, bs)                   -- пропускаем byte pid
    local ok1, b1  = pcall(raknetBitStreamReadInt8, bs)
    if not ok1 or b1 ~= 84 then return end               -- b1=84 FM
    local ok2, iid = pcall(raknetBitStreamReadInt8, bs)
    if not ok2 or iid ~= IID then return end              -- наш IID

    local raw     = readRaw(bs, 150)
    local success = numField(raw, 'success')
    if success == nil then return end

    local chance  = numField(raw, 'chance') or 0
    local usedT   = calcTiming or TIMING

    if success == 1 then
        sampAddChatMessage(string.format(
            '{2ECC71}[LumberBot] УСПЕХ! chance=%d%% тайминг=%dмс',
            chance, usedT), -1)
    else
        sampAddChatMessage(string.format(
            '{FF4444}[LumberBot] ПРОМАХ! chance=%d%% тайминг=%dмс',
            chance, usedT), -1)
        sampAddChatMessage('{FFAA00}  Попробуй /ltiming ' .. math.floor(usedT * 0.85) ..
            ' или /ltiming ' .. math.floor(usedT * 1.15), -1)
    end
end)

-- ===================================================
--  УМНЫЙ СКАНЕР: ищем JSON с isMyState в любом пакете
--  Работает на ПК с arizona-events. На мобиле — запасной вариант.
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if not scanning or running then return end
    raknetBitStreamSetReadOffset(bs, 0)

    local raw = readRaw(bs, 256)
    if not raw:find('"isMyState"') then return end
    if numField(raw, 'isMyState') ~= 1 then return end
    if numField(raw, 'currentPosition') ~= -1 then return end

    local s  = numField(raw, 'start')
    local w  = numField(raw, 'width')
    local sp = numField(raw, 'speed')

    if not s or not w or not sp then
        sampAddChatMessage('{FFAA00}[LumberBot] Пакет найден, параметры не распознаны', -1)
        sampAddChatMessage('{AAAAAA}raw: ' .. raw:sub(1, 100), -1)
        return
    end

    local pos = math.floor(s + w / 2 + 0.5)
    calcTiming = math.floor(pos / sp + 0.5) * 75

    sampAddChatMessage(string.format(
        '{00FF80}[LumberBot] АВТО: start=%.1f w=%.1f sp=%.2f → %dмс',
        s, w, sp, calcTiming), -1)

    scanning  = false
    triggered = true
end)

-- ===================================================
--  АВТО-ТРИГГЕР через TOGGLE ON (b1=62) для IID=8
--  Срабатывает когда сервер открывает интерфейс лесоповала
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if pid ~= 220 or running or scanning then return end
    raknetBitStreamSetReadOffset(bs, 0)
    pcall(raknetBitStreamReadInt8, bs)                   -- skip pid byte
    local ok1, b1    = pcall(raknetBitStreamReadInt8, bs)
    if not ok1 or b1 ~= 62 then return end               -- b1=62 TOGGLE
    local ok2, iid   = pcall(raknetBitStreamReadInt8, bs)
    if not ok2 or iid ~= IID then return end
    local ok3, state = pcall(raknetBitStreamReadBool, bs)
    if not ok3 or not state then return end               -- state=true → ON

    calcTiming = nil
    triggered  = true
    sampAddChatMessage('{00FFCC}[LumberBot] Интерфейс открыт → старт через ' ..
        (calcTiming or TIMING) .. 'мс', -1)
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
            scanning and '{00FFCC}[LumberBot] Сканер ВКЛ — начни мини-игру!'
                      or '{AAAAAA}[LumberBot] Сканер ВЫКЛ', -1)
    end)

    sampRegisterChatCommand('lumber', function()
        if running then
            sampAddChatMessage('{FF4444}[LumberBot] Уже выполняется!', -1)
            return
        end
        calcTiming = nil
        triggered  = true
        sampAddChatMessage('{2ECC71}[LumberBot] Ручной старт! Тайминг=' .. TIMING .. 'мс', -1)
    end)

    sampRegisterChatCommand('ltiming', function(args)
        local n = tonumber(args)
        if not n or n < 50 then
            sampAddChatMessage('{FF4444}[LumberBot] Использование: /ltiming <мс>  (мин 50)', -1)
            sampAddChatMessage('{AAAAAA}  Текущий тайминг: ' .. TIMING .. 'мс', -1)
            return
        end
        TIMING = n
        sampAddChatMessage('{2ECC71}[LumberBot] Тайминг установлен: ' .. n .. 'мс', -1)
    end)

    sampAddChatMessage(
        '{2ECC71}[LumberBot]{FFFFFF} /lumber | /ltiming <мс> | /lscan', -1)
    sampAddChatMessage(
        '{AAAAAA}Авто-режим: подходи к бревну — бот сам нажмёт старт/стоп', -1)

    while true do
        if triggered and not running then
            triggered  = false
            running    = true
            local t    = calcTiming or TIMING

            sampAddChatMessage('{00FFCC}[LumberBot] Клик START...', -1)
            click(90)       -- START
            wait(t)
            click(91)       -- STOP
            wait(4000)      -- ждём анимацию результата
            click(92)       -- CLOSE
            wait(500)

            running    = false
            calcTiming = nil
        end
        wait(0)
    end
end
