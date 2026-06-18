-- Skin Changer for MonetLoader (MoonLoader-compatible)
-- Меняет скин ТОЛЬКО у тебя (локально, на клиенте).
-- Команды:
--   /myskin <id>  - поставить скин с номером id (0-311)
--   /skinrnd      - случайный скин
--
-- Важно: смену скина делаем в главном цикле main(), а не в колбэке команды,
-- т.к. внутри колбэка нельзя вызывать wait() (yield across C-call boundary).

script_name('Skin Changer')
script_author('you')
script_version('1.1')

local MIN_SKIN = 0
local MAX_SKIN = 311

-- Очередь: какой скин поставить на следующем кадре (nil = нечего делать)
local pendingSkin = nil

function main()
    -- Ждём пока загрузится SAMP
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('myskin', cmd_skin)
    sampRegisterChatCommand('skinrnd', cmd_skin_random)

    sampAddChatMessage('[Skin Changer] Загружен! Используй /myskin <id> или /skinrnd', 0x33FF33)

    while true do
        wait(0)
        -- Если есть запрос на смену скина - обрабатываем здесь (тут wait() разрешён)
        if pendingSkin ~= nil then
            local id = pendingSkin
            pendingSkin = nil
            applySkin(id)
        end
    end
end

-- /myskin <id> : только проверяем ввод и кладём в очередь
function cmd_skin(arg)
    local id = tonumber(arg)
    if not id then
        sampAddChatMessage('[Skin Changer] Использование: /myskin <id> (' .. MIN_SKIN .. '-' .. MAX_SKIN .. ')', 0xFFAA00)
        return
    end
    if id < MIN_SKIN or id > MAX_SKIN then
        sampAddChatMessage('[Skin Changer] ID скина должен быть от ' .. MIN_SKIN .. ' до ' .. MAX_SKIN, 0xFF3333)
        return
    end
    pendingSkin = id
end

-- /skinrnd : случайный скин в очередь
function cmd_skin_random()
    pendingSkin = math.random(MIN_SKIN, MAX_SKIN)
end

-- Реальная смена скина. Вызывается ТОЛЬКО из main() (wait() безопасен).
function applySkin(id)
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
