-- gameBinaryScanner.lua
-- Собирает бинарные пакеты игрового состояния (pid=220, b1=84, IID=8)
-- с РАЗНЫХ деревьев, чтобы найти какие байты = start/width/speed
--
-- Инструкция:
--   1. /gbs  -- включить
--   2. Подойди к дереву #1 -- появится дамп байт
--   3. Пройди мини-игру до конца (START -> STOP -> CLOSE)
--   4. Подойди к дереву #2 -- появится ещё дамп
--   5. Повтори 4-5 раз на РАЗНЫХ деревьях
--   6. /gbssave -- сохранить в файл и скинь сюда
--
-- Чем больше разных деревьев -- тем точнее декодируем формат!

script_name('GameBinaryScanner')
script_version('1.0')

local IID     = 8
local active  = false
local rounds  = {}  -- {time, hexStr, ascStr, isResult, resultJson}

local function readRaw(bs, maxBytes)
    local t = {}
    for i = 1, maxBytes do
        local ok, b = pcall(raknetBitStreamReadInt8, bs)
        if not ok then break end
        t[i] = b >= 0 and b or b + 256
    end
    return t
end

local function toHex(bytes)
    local h = {}
    for _, b in ipairs(bytes) do h[#h+1] = string.format('%02X', b) end
    return table.concat(h, ' ')
end

local function toAsc(bytes)
    local a = {}
    for _, b in ipairs(bytes) do
        a[#a+1] = (b >= 32 and b < 127) and string.char(b) or '.'
    end
    return table.concat(a)
end

addEventHandler('onReceivePacket', function(pid, bs)
    if not active or pid ~= 220 then return end
    raknetBitStreamSetReadOffset(bs, 0)

    local raw = readRaw(bs, 200)
    if #raw < 3 then return end

    -- byte[0]=220 byte[1]=b1 byte[2]=iid
    local b1  = raw[2]
    local iid = raw[3]
    if iid ~= IID then return end
    if b1 ~= 84 then return end  -- только FM пакеты

    local hexStr = toHex(raw)
    local ascStr = toAsc(raw)

    -- Определяем: это результат (JSON) или игровое состояние (бинарный)?
    local isJson = ascStr:find('success') ~= nil
                or ascStr:find('chance')  ~= nil
                or ascStr:find('type')    ~= nil

    if isJson then
        -- Результат игры
        local jsonStart = ascStr:find('%[') or ascStr:find('{')
        local jsonPart  = jsonStart and ascStr:sub(jsonStart) or ascStr
        table.insert(rounds, {
            time     = os.date('%H:%M:%S'),
            isResult = true,
            json     = jsonPart:sub(1, 80),
            hex      = hexStr,
        })
        sampAddChatMessage('{AAAAAA}[GBS] Result: ' .. jsonPart:sub(1, 60), -1)
    else
        -- Бинарный пакет игрового состояния
        table.insert(rounds, {
            time     = os.date('%H:%M:%S'),
            isResult = false,
            hex      = hexStr,
            asc      = ascStr,
        })

        -- Показываем в чат байты 4-12 (после DC 54 08 SEQ -- это и есть параметры)
        local paramBytes = {}
        for i = 5, math.min(20, #raw) do
            paramBytes[#paramBytes+1] = string.format('%02X', raw[i])
        end
        sampAddChatMessage('{00FFCC}[GBS] #' .. #rounds .. ' GameState bytes[4..20]:', -1)
        sampAddChatMessage('{FFFFFF}' .. table.concat(paramBytes, ' '), -1)
    end
end)

function main()
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('gbs', function()
        active = not active
        rounds = {}
        if active then
            sampAddChatMessage('{00FFCC}[GBS] ON -- подходи к деревьям!', -1)
        else
            sampAddChatMessage('{AAAAAA}[GBS] OFF', -1)
        end
    end)

    sampRegisterChatCommand('gbssave', function()
        if #rounds == 0 then
            sampAddChatMessage('{FF4444}[GBS] Нет данных', -1)
            return
        end
        local dir  = getWorkingDirectory() .. '/logs'
        if not doesDirectoryExist(dir) then createDirectory(dir) end
        local path = dir .. '/gbs_' .. os.date('%Y%m%d_%H%M%S') .. '.txt'
        local f    = io.open(path, 'w')
        if not f then
            sampAddChatMessage('{FF4444}[GBS] Ошибка файла', -1)
            return
        end
        f:write('=== GameBinaryScanner dump (' .. #rounds .. ' packets) ===\n\n')
        for i, r in ipairs(rounds) do
            if r.isResult then
                f:write(string.format('[%s] #%-3d RESULT: %s\n', r.time, i, r.json))
                f:write('  HEX: ' .. r.hex .. '\n\n')
            else
                f:write(string.format('[%s] #%-3d GAME_STATE:\n', r.time, i))
                f:write('  HEX: ' .. r.hex .. '\n')
                f:write('  ASC: ' .. r.asc .. '\n\n')
            end
        end
        f:close()
        sampAddChatMessage('{2ECC71}[GBS] Saved ' .. #rounds .. ' records', -1)
        sampAddChatMessage('{FFFFFF}' .. path, -1)
    end)

    sampAddChatMessage('{00FFCC}[GBS] /gbs -- ON/OFF  |  /gbssave -- save file', -1)
    while true do wait(500) end
end
