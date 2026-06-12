-- Skin Changer for MonetLoader (MoonLoader-compatible)
-- Меняет скин ТОЛЬКО у тебя (локально, на клиенте).
-- Команды:
--   /skin <id>  - поставить скин с номером id (0-311)
--   /skinrnd    - случайный скин

script_name('Skin Changer')
script_author('you')
script_version('1.0')

local MIN_SKIN = 0
local MAX_SKIN = 311

function main()
    -- Ждём пока загрузится SAMP
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('skin', cmd_skin)
    sampRegisterChatCommand('skinrnd', cmd_skin_random)

    sampAddChatMessage('[Skin Changer] Загружен! Используй /skin <id> или /skinrnd', 0x33FF33)

    wait(-1)
end

-- /skin <id>
function cmd_skin(arg)
    local id = tonumber(arg)
    if not id then
        sampAddChatMessage('[Skin Changer] Использование: /skin <id> (' .. MIN_SKIN .. '-' .. MAX_SKIN .. ')', 0xFFAA00)
        return
    end
    setMySkin(id)
end

-- /skinrnd
function cmd_skin_random()
    setMySkin(math.random(MIN_SKIN, MAX_SKIN))
end

-- Меняет скин локального игрока на указанный id
function setMySkin(id)
    if id < MIN_SKIN or id > MAX_SKIN then
        sampAddChatMessage('[Skin Changer] ID скина должен быть от ' .. MIN_SKIN .. ' до ' .. MAX_SKIN, 0xFF3333)
        return
    end

    local ped = PLAYER_PED

    -- Загружаем модель скина
    requestModel(id)
    while not hasModelLoaded(id) do
        loadAllModelsNow()
        wait(0)
    end

    setCharSkin(ped, id)
    markModelAsNoLongerNeeded(id)

    sampAddChatMessage('[Skin Changer] Скин изменён на: ' .. id, 0x33FF33)
end
