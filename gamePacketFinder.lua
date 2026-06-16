-- gamePacketFinder.lua
-- Сканирует ВСЕ входящие пакеты, ищет данные мини-игры лесоповала
-- /gpf   -- запустить сканирование (30 сек, затем пишет дамп в файл)
--
-- Инструкция:
-- 1. Подойди к бревну
-- 2. /gpf
-- 3. Начни мини-игру ВРУЧНУЮ (нажми старт в игре, остановись, закрой)
-- 4. Файл gpf_dump.txt → скинь сюда

script_name('GamePacketFinder')
script_version('1.0')

local active   = false
local endClock = 0
local dump     = {}   -- все пакеты за период
local MAX_DUMP = 500  -- максимум записей

-- Паттерны поиска (без кавычек, ловим любой вид JSON/JS)
local PATS = {
    'isMyState', 'lumberingGame', 'lumbering%-game',
    'updateGameState', 'turnEnd', 'infoUser', 'currentPosition'
}

local function byteToChar(b)
    local ub = b >= 0 and b or b + 256
    return ub, string.format('%02X', ub), (ub >= 32 and ub < 127) and string.char(ub) or '.'
end

-- Читаем сырые байты из битстрима, возвращаем hex-строку и ASCII-строку
local function readRaw(bs, maxB)
    local hex = {}
    local asc = {}
    for i = 1, maxB do
        local ok, b = pcall(raknetBitStreamReadInt8, bs)
        if not ok then break end
        local _, h, c = byteToChar(b)
        hex[#hex+1] = h
        asc[#asc+1] = c
    end
    return table.concat(hex, ' '), table.concat(asc)
end

addEventHandler('onReceivePacket', function(pid, bs)
    if not active then return end
    if #dump >= MAX_DUMP then return end

    raknetBitStreamSetReadOffset(bs, 0)
    local hexStr, ascStr = readRaw(bs, 512)

    -- Ищем паттерны
    local found = nil
    for _, pat in ipairs(PATS) do
        if ascStr:find(pat) then
            found = pat
            break
        end
    end

    -- Сохраняем: найденные совпадения + ВСЕ пакеты > 30 байт (возможно игровые)
    local ascLen = #ascStr:gsub('%.', '')  -- non-dot count (printable chars)
    if found or ascLen > 15 then
        local tag = found and ('[!!!MATCH=' .. found .. '] ') or ''
        table.insert(dump, string.format(
            'pid=%-3d %s\nHEX: %s\nASC: %s\n', pid, tag,
            hexStr:sub(1, 240), ascStr:sub(1, 80)))
    end

    -- Оповещение в чат при совпадении
    if found then
        sampAddChatMessage(
            '{00FF80}[GPF] НАЙДЕНО! pid=' .. pid .. '  pattern=' .. found, -1)
        sampAddChatMessage(
            '{FFFFFF}ASCII: ' .. ascStr:sub(1, 80), -1)
    end
end)

function main()
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('gpf', function()
        if active then
            sampAddChatMessage('{FFAA00}[GPF] Сканирование уже идёт...', -1)
            return
        end
        dump     = {}
        active   = true
        endClock = os.clock() + 30

        sampAddChatMessage('{00FFCC}[GPF] Сканирование 30 сек!', -1)
        sampAddChatMessage('{FFFFFF}Начни мини-игру прямо сейчас.', -1)
    end)

    sampAddChatMessage('{00FFCC}[GamePacketFinder] /gpf -> играй мини-игру', -1)

    while true do
        -- Автостоп + сохранение дампа
        if active and os.clock() >= endClock then
            active = false

            local path = getWorkingDirectory() .. '/gpf_dump.txt'
            local f = io.open(path, 'w')
            if f then
                f:write('=== GamePacketFinder dump (' .. #dump .. ' records) ===\n\n')
                for _, line in ipairs(dump) do
                    f:write(line)
                    f:write('\n')
                end
                f:close()
                sampAddChatMessage('{2ECC71}[GPF] Готово! ' .. #dump .. ' пакетов записано.', -1)
                sampAddChatMessage('{FFFFFF}Файл: monetloader/gpf_dump.txt', -1)
                sampAddChatMessage('{FFAA00}[GPF] Скинь этот файл сюда!', -1)
            else
                sampAddChatMessage('{FF4444}[GPF] Ошибка сохранения файла!', -1)
            end
        end
        wait(100)
    end
end
