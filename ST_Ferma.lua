script_name('StrandFerma')
script_author('Victor Strand')
script_version('3.0-monet')
script_version_number(30)
script_properties('work-in-pause')

local imgui    = require('mimgui')
local ffi      = require('ffi')
local inicfg   = require('inicfg')
local sampev   = require('lib.samp.events')
local encoding = require('encoding')
local requests = require('requests')
local lfs      = require('lfs')
local hook     = require('monethook')

encoding.default = 'CP1251'
local u8  = encoding.UTF8
local MDS = MONET_DPI_SCALE

local gta = ffi.load('GTASA')
ffi.cdef[[
    void _Z12AND_OpenLinkPKc(const char* link);
    void* _ZN4CPad6GetPadEi(int num);
    uint8_t _ZN4CPad9GetSprintEi(void* thiz, int playerid);
]]
local function openLink(url) pcall(gta._Z12AND_OpenLinkPKc, url) end

local runActive = false
local collisionEnabled = false

local autoJump         = false
local autoJumpInterval = 5
local autoJumpThread   = nil
local autoJumpCount    = 0
local _ajLastJump      = 0

local _ajPrevX, _ajPrevY = nil, nil

local function doJumpToTarget(tox, toy)
    if not autoJump then return end
    if (os.clock() - _ajLastJump) < autoJumpInterval then return end

    local ok, cx, cy = pcall(getCharCoordinates, PLAYER_PED)
    if not ok or not cx then return end

    if not _ajPrevX then
        _ajPrevX, _ajPrevY = cx, cy
        return
    end

    local dx = cx - _ajPrevX
    local dy = cy - _ajPrevY
    local moved = math.sqrt(dx*dx + dy*dy)

    if moved < 0.05 then
        _ajPrevX, _ajPrevY = cx, cy
        return
    end

    local tx = tox - cx
    local ty = toy - cy
    local tdist = math.sqrt(tx*tx + ty*ty)
    if tdist < 0.001 then return end

    local dot = (dx * tx + dy * ty) / (moved * tdist)

    _ajPrevX, _ajPrevY = cx, cy

    if dot < 0.85 then return end

    _ajLastJump   = os.clock()
    autoJumpCount = autoJumpCount + 1
    pcall(taskJump, PLAYER_PED, true)
end

local function startAutoJump()
    _ajLastJump   = 0
    autoJumpCount = 0
    _ajPrevX, _ajPrevY = nil, nil
    if autoJumpInterval < 2 then autoJumpInterval = 2 end
end

local function stopAutoJump()
    autoJump = false
    autoJumpThread = nil
end

local function enableCollision()
    for k, v in ipairs(getAllChars()) do
        if doesCharExist(v) and v ~= PLAYER_PED then
            setCharCollision(v, not collisionEnabled)
        end
    end
    for k, v in ipairs(getAllVehicles()) do
        if doesVehicleExist(v) then
            setCarCollision(v, not collisionEnabled)
        end
    end
end

local function stopSprint()
    if not runActive then
        setGameKeyState(16, 0)
    end
end

local sfFolder   = getWorkingDirectory()..'/StrandFerma'
pcall(function() lfs.mkdir(sfFolder) end)

-- Anti-admin alert: sound + photo-flicker (ported from StrandShahta)
local S = {
    aaPath    = sfFolder .. '/sf_aa.mp3',
    imgPath   = sfFolder .. '/sf_aa.png',
    aaUrl     = 'https://files.catbox.moe/80dz1r.mp3',
    imgUrl    = 'https://files.catbox.moe/0m6bav.png',
    sndAA     = nil,
    img       = nil,
    imgUntil  = 0,
    soundLast = 0,
}

local function _ensureFile(path, url)
    if doesFileExist(path) then return true end
    local ok, req = pcall(require, 'requests')
    if not ok or not req then return false end
    local rok, resp = pcall(req.get, url)
    if rok and resp and resp.status_code == 200 then
        local body = resp.content or resp.text
        if body and #body > 100 then
            local f = io.open(path, 'wb')
            if f then f:write(body); f:close(); return doesFileExist(path) end
        end
    end
    return false
end

local function initSounds()
    lua_thread.create(function()
        _ensureFile(S.aaPath, S.aaUrl)
        _ensureFile(S.imgPath, S.imgUrl)
        if doesFileExist(S.aaPath) then
            S.sndAA = loadAudioStream(S.aaPath)
            if S.sndAA then pcall(setAudioStreamVolume, S.sndAA, 1.0) end
        end
    end)
end

local function _playOnce(h)
    if not h then return end
    pcall(setAudioStreamState, h, 0)
    pcall(setAudioStreamState, h, 1)
end

local function playAntiAdminSound()
    if os.clock() - S.soundLast < 8 then return end
    S.soundLast = os.clock()
    S.imgUntil  = os.clock() + 60
    if not S.sndAA then return end
    lua_thread.create(function()
        _playOnce(S.sndAA)
        wait(250)
        local guard = 0
        while guard < 100 do
            local ok, st = pcall(getAudioStreamState, S.sndAA)
            if not ok or st ~= 1 then break end
            wait(100); guard = guard + 1
        end
        _playOnce(S.sndAA)
    end)
end

local giflib    = nil
local gifLoaded = false
pcall(function()
    pcall(ffi.cdef, [[ int extractGif(const char* gif_path, const char* out_dir); ]])
    giflib    = ffi.load(getWorkingDirectory() .. '/lib/libGIF.so')
    gifLoaded = true
end)

local SF_GIF_URL      = 'https://files.catbox.moe/zstox3.gif'
local SF_GIF_DIR      = getWorkingDirectory() .. '/StrandFerma'
local SF_GIF_PATH     = SF_GIF_DIR .. '/sf_deco.gif'
local SF_GIF_FRAMES   = SF_GIF_DIR .. '/sf_deco_frames'

local sfGifFrames  = {}
local sfGifCurrent = 1
local sfGifLastTime = 0
local sfGifReady   = false
local sfGifSpeed   = 80

local function sfGifLoadFrames()
    sfGifFrames  = {}
    sfGifCurrent = 1
    sfGifReady   = false
    lua_thread.create(function()
        local i = 0
        while true do
            local path = SF_GIF_FRAMES .. '/' .. i .. '.bmp'
            if not doesFileExist(path) then break end
            local tex = imgui.CreateTextureFromFile(path)
            if tex and tex ~= 0 then
                sfGifFrames[#sfGifFrames + 1] = tex
            end
            i = i + 1
            wait(0)
        end
        if #sfGifFrames > 0 then
            sfGifReady    = true
            sfGifLastTime = getGameTimer()
        end
    end)
end

local function sfGifExtract()
    if not gifLoaded then return end
    lua_thread.create(function()
        if not doesDirectoryExist(SF_GIF_FRAMES) then
            createDirectory(SF_GIF_FRAMES)
        end
        local ok, result = pcall(function()
            return giflib.extractGif(SF_GIF_PATH, SF_GIF_FRAMES)
        end)
        if ok and (tonumber(result) or 0) > 0 then
            sfGifLoadFrames()
        end
    end)
end

local function sfGifTick()
    if not sfGifReady or #sfGifFrames == 0 then return end
    local now = getGameTimer()
    if now - sfGifLastTime >= sfGifSpeed then
        sfGifLastTime = now
        sfGifCurrent  = sfGifCurrent % #sfGifFrames + 1
    end
end

lua_thread.create(function()
    while not isSampAvailable() do wait(1000) end
    wait(4000)
    local libPath = getWorkingDirectory() .. '/lib/libGIF.so'
    if not doesFileExist(libPath) then
        local ok, resp = pcall(requests.get, 'https://files.catbox.moe/u7na9v.so')
        if ok and resp and resp.status_code == 200 and resp.content then
            local f = io.open(libPath, 'wb')
            if f then f:write(resp.content); f:close() end
            if not gifLoaded then
                pcall(function()
                    giflib    = ffi.load(libPath)
                    gifLoaded = true
                end)
            end
        end
    end
    if doesFileExist(SF_GIF_PATH) then
        if doesFileExist(SF_GIF_FRAMES .. '/0.bmp') then
            sfGifLoadFrames()
        else
            sfGifExtract()
        end
    else
        local ok2, resp2 = pcall(requests.get, SF_GIF_URL)
        if ok2 and resp2 and resp2.status_code == 200 and resp2.content then
            local f2 = io.open(SF_GIF_PATH, 'wb')
            if f2 then f2:write(resp2.content); f2:close() end
            sfGifExtract()
        end
    end
end)

local sprintActive = false
local resx, resy = getScreenResolution()

local farm = {
    running         = false,
    collect_cotton  = true,
    collect_linen   = true,
    sprint          = true,
    stop_on_dialog  = false,
    stop_on_tp      = false,
    stop_on_chat    = false,
    quit_on_stop    = false,
    goto_soonest      = false,
    res_counter     = { cotton = 0, linen = 0, rare = 0, coal = 0 },
    stats           = { start_time = 0 },
    target          = nil,
}

local calc = { price_cotton = 0, price_linen = 0, price_rare = 0, price_coal = 0 }

local antiAdminEnableTime = 0
local log_lines     = {}

local autoAnims  = false

-- Larek (food stall) run state — declared early so emergencyStop can reach them
local larekRunning   = false
local larekIsWalking = false
local testLarekMode  = false

-- ===== Anti-admin (ported from StrandShahta) =====
local aaState        = false
local aaAngry        = 0
local aaTimes        = os.clock()
local aaReplying     = false
local aaLastQuestion = nil
local aaLastTrigger  = 0
math.randomseed(os.time() % 2147483647)

local aaAdminTriggers = {
    '\xc0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0',
    '\xf2\xe5\xeb\xe5\xef\xee\xf0\xf2\xe8\xf0\xee\xe2\xe0\xeb \xe2\xe0\xf1 \xed\xe0 \xea\xee\xee\xf0\xe4\xe8\xed\xe0\xf2\xfb',
    '\xee\xf2\xe2\xe5\xf2\xe8\xeb \xe2\xe0\xec:',
}

local aaOtveti1 = {
    "/b \xf2\xf3\xf2 \xff \xf2\xf3\xf2", "/b \xe4\xe0 \xff \xf2\xf3\xf2", "/b \xed\xf3?",
    "/b \xe4\xe0 \xf9\xe0\xf1 \xe3\xeb\xff\xed\xf3", "/b \xed\xf3 \xf2\xf3\xf2 \xff", "/b \xff \xed\xe0 \xec\xe5\xf1\xf2\xe5",
    "/b \xe0 \xf7\xf2\xee \xf2\xe0\xea\xee\xe5", "/b \xe4\xe0, \xf2\xf3\xf2 \xff", "/b +++", "/b \xed\xe0 \xec\xe5\xf1\xf2\xe5",
    "/b \xf2\xf3\xf2", "/b \xed\xf3 \xe1\xeb\xe8\xed(", "/b \xe4\xe0,\xf2\xf3\xf2 \xff", "/b \xee\xef\xe0 \xf2\xf3\xf2, \xe0 \xf7\xf2\xee",
    "/b \xe4\xe0 \xf1\xeb\xf3\xf8\xe0\xfe, \xed\xf3", "/b \xff \xe2 \xe8\xe3\xf0\xe5", "/b \xe0\xe3\xe0", "/b tyt",
    "/b \xe0 \xff \xed\xe5 \xef\xee\xed\xff\xeb,\xf7\xf2\xee \xf2\xe0\xec", "/b \xe0\xf3\xf4", "/b \xef\xf0\xe8\xf1\xf3\xf2\xf1\xf2\xe2\xf3\xfe",
    "/b \xe0 \xf7\xf2\xee \xf2\xe0\xec?", "/b \xe0 \xf7\xf2\xee, \xf7\xf2\xee?", "/b \xe4\xe0 \xf2\xf3\xf2", "/b \xf1\xeb\xf3\xf8\xe0\xfe",
    "/b daaaa", "/b na meste", "/b ya tyt", "/b \xe4\xe0 \xf2\xf3\xf2 \xff \xed\xe8\xea\xf3\xe4\xe0",
    "/b \xed\xf3 \xf2\xf3\xf2, \xe0 \xf7\xf2\xee", "/b \xf2\xe0\xea \xf2\xf3\xf2 \xff \xea\xee\xf0\xee\xf7\xe5", "/b \xe4\xe0 \xff \xf2\xf3\xf2",
    "/b \xf2\xf3\xf2\xe0 \xff", "/b \xed\xf3 \xe4\xe0, \xe0 \xf7\xf2\xee", "/b \xf2\xf3\xf2, \xec\xe8\xed\xf3\xf2\xf3",
    "/b \xed\xf3 \xf2\xf3\xf2, \xf1\xe5\xea\xf3\xed\xe4\xf3", "/b  \xe4\xe0, \xe0 \xf7\xf2\xee", "/b da tyt", "/b na meste ya",
    "/b im tyta", "/b \xf2\xf3\xf2 \xff \xea\xee\xf0\xee\xf7\xe5", "/b \xed\xf3 \xe4\xe0, \xff \xf2\xf3\xf2 \xf1\xe8\xe6\xf3",
    "/b \xf2\xf3\xf2, \xf7\xf2\xee \xf5\xee\xf2\xe5\xeb", "/b \xe4\xe0 \xed\xe0 \xec\xe5\xf1\xf2\xe5, \xe0 \xf7\xf2\xee", "/b \xed\xf3 \xf2\xf3\xf2 \xff",
}

local aaOtveti2 = {
    "/b \xff \xed\xe5 \xe0\xf4\xea \xef\xf0\xee\xf1\xf2\xee \xe4\xf3\xec\xe0\xeb, \xed\xe5 \xee\xf2\xe2\xe5\xf7\xe0\xeb, \xe8\xe7\xe2\xe8\xed\xe8",
    "/b \xff \xee\xf2\xf5\xee\xe4\xe8\xeb \xed\xe0 15 \xf1\xe5\xea\xf3\xed\xe4, \xed\xf3",
    "/b \xed\xf3 \xff \xf2\xf3\xf2 \xe1\xfb\xeb \xe2\xf1\xb8 \xe2\xf0\xe5\xec\xff, \xed\xf3",
    "/b \xf1\xe2\xff\xe7\xfc \xe1\xe0\xf0\xe0\xf5\xeb\xe8\xf2, \xed\xe5 \xf1\xf0\xe0\xe7\xf3",
    "/b 1%, \xef\xf0\xee\xf1\xf2\xee \xeb\xe0\xe3",
    "/b \xef\xe8\xf8\xf3 \xf1 \xf2\xe5\xeb\xe5\xf4\xee\xed\xe0, \xed\xe5 \xf3\xf1\xef\xe5\xeb",
    "/b \xef\xf0\xee\xf1\xf2\xee \xe7\xe0\xe2\xe8\xf1 \xed\xe0 \xf7\xf3\xf2\xfc, \xed\xee \xff \xf2\xf3\xf2",
    "/b 2%, \xe4\xe0 \xed\xe5 \xe0\xf4\xea \xff \xed\xe8\xea\xe0\xea\xee\xe9",
    "/b \xef\xe8\xf1\xe0\xeb \xe4\xf0\xf3\xe3 \xe8 \xff \xee\xf2\xe2\xeb\xb8\xea\xf1\xff",
    "/b \xed\xe5 \xf1\xf0\xe0\xe7\xf3 \xe7\xe0\xec\xe5\xf2\xe8\xeb \xf1\xee\xee\xe1\xf9\xe5\xed\xe8\xe5",
    "/b \xe4\xe0 \xff \xf1\xec\xee\xf2\xf0\xe5\xeb \xe2\xe8\xe4\xe5\xee \xe2 \xe4\xf0\xf3\xe3\xee\xec \xee\xea\xed\xe5",
    "/b \xf2\xe5\xeb\xe5\xea \xed\xe0 \xf4\xee\xed\xe5 \xe1\xfb\xeb \xe8 \xee\xf2\xe2\xeb\xb8\xea\xf1\xff",
    "/b \xed\xf3 \xe4\xe0, \xf7\xf3\xf2\xfc \xf2\xee\xf0\xec\xee\xe7\xed\xf3\xeb, \xe1\xfb\xe2\xe0\xe5\xf2",
    "/b \xea\xee\xec\xef \xed\xe5\xec\xed\xee\xe3\xee \xe7\xe0\xe2\xe8\xf1 \xf3 \xec\xe5\xed\xff",
    "/b \xe2\xe0\xed\xed\xf3 \xed\xe0\xe1\xe8\xf0\xe0\xeb, \xee\xf2\xf5\xee\xe4\xe8\xeb \xf7\xf3\xf2\xfc",
    "/b \xf7\xf3\xf2\xfc \xf3\xe6\xe8\xed \xf0\xe0\xe7\xee\xe3\xf0\xe5\xeb \xed\xe0 \xea\xf3\xf5\xed\xe5 \xf2\xe0\xec",
}

local aaBroadcastWords = {
    'МП', 'Приз', 'приз', 'Уважаем', 'Объявлен', 'объявлен',
    'розыгрыш', 'рулетк', 'мероприят', 'Глобальн', 'глобальн',
    '/gotp', 'преми', 'ивент', 'event', 'акци', 'Конкурс', 'конкурс',
    'Принимаем', 'набор',
}

local function aaIsAdmin(text)
    for _, w in ipairs(aaAdminTriggers) do
        if text:find(w, 1, true) then return true end
    end
    return false
end

local function aaLooksDirected(text)
    local ok, utext = pcall(function() return u8(text) end)
    if not ok or not utext then utext = text end
    if utext:find('ответил вам', 1, true) or utext:find('телепортировал вас', 1, true) then
        return true
    end
    local myNick = ''
    pcall(function()
        local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
        myNick = sampGetPlayerNickname(pid) or ''
    end)
    if myNick ~= '' and #myNick >= 3 and text:lower():find(myNick:lower(), 1, true) then
        return true
    end
    for _, w in ipairs(aaBroadcastWords) do
        if utext:find(w, 1, true) then return false end
    end
    return true
end

local function aaSmartAnswer(q)
    if not q then return nil end
    if q:find('\xe2\xfb \xf2\xf3\xf2', 1, true) or q:find('\xf2\xfb \xf2\xf3\xf2', 1, true)
    or q:find('\xf2\xfb \xe7\xe4\xe5\xf1\xfc', 1, true) or q:find('\xe2\xfb \xe7\xe4\xe5\xf1\xfc', 1, true)
    or q:find('\xee\xed\xeb\xe0\xe9\xed', 1, true) or q:find('\xe7\xe4\xe5\xf1\xfc', 1, true) then
        local answers = {
            '\xc4\xe0', '\xc4\xe0, \xf2\xf3\xf2',
            '\xc4\xe0, \xe7\xe4\xe5\xf1\xfc',
            '\xca\xee\xed\xe5\xf7\xed\xee',
            '\xc4\xe0 \xea\xee\xed\xe5\xf7',
            '\xc4\xf3, \xe7\xe4\xe5\xf1\xfc',
        }
        return answers[math.random(#answers)]
    end
    local n1, op, n2 = q:match('(%d+)%s*([%+%-%*/])%s*(%d+)')
    if n1 and op and n2 then
        local a, b = tonumber(n1), tonumber(n2)
        local res
        if op == '+' then res = a + b
        elseif op == '-' then res = a - b
        elseif op == '*' then res = a * b
        elseif op == '/' and b ~= 0 then
            res = math.floor(a / b * 100 + 0.5) / 100
        end
        if res then return tostring(res) end
    end
    if q:find('\xeb\xe5\xf2', 1, true) or q:find('\xe2\xee\xe7\xf0\xe0\xf1\xf2', 1, true) then
        local ages = {'19', '21', '20', '22', '23'}
        return ages[math.random(#ages)]
    end
    if q:find('\xee\xf2\xea\xf3\xe4\xe0', 1, true) or q:find('\xe3\xee\xf0\xee\xe4', 1, true) then
        local cities = {'\xcc\xee\xf1\xea\xe2\xe0', '\xd1\xef\xe1', '\xca\xe0\xe7\xe0\xed\xfc', '\xc5\xea\xe1'}
        return cities[math.random(#cities)]
    end
    if q:find('\xe4\xe5\xeb\xe0\xe5\xf8\xfc', 1, true) or q:find('\xe7\xe0\xed\xe8\xec\xe0\xe5\xf8\xfc', 1, true)
    or q:find('\xe4\xe5\xeb\xe0\xe5\xf2\xe5', 1, true) then
        local acts = {
            '\xd0\xe0\xe1\xee\xf2\xe0\xfe',
            '\xca\xee\xef\xe0\xfe \xf0\xf3\xe4\xf3',
            '\xd8\xe0\xf5\xf2\xe0',
            '\xc4\xe5\xeb\xe0\xec \xf1\xe2\xee\xb8',
        }
        return acts[math.random(#acts)]
    end
    return nil
end

local function aaSendReply(questionText)
    if aaReplying or aaAngry >= 2 then return end
    aaReplying = true
    aaAngry = aaAngry + 1
    aaTimes = os.clock()
    wait(math.random(7000, 11000))
    local mesg
    local smart = aaSmartAnswer(questionText)
    if smart then
        mesg = '/b ' .. smart
    elseif aaAngry == 1 then
        mesg = aaOtveti1[math.random(#aaOtveti1)]
    else
        mesg = aaOtveti2[math.random(#aaOtveti2)]
    end
    sampSendChat(mesg)
    aaReplying = false
end

lua_thread.create(function()
    while true do
        wait(500)
        if aaState and farm.running and sampIsDialogActive() then
            if os.clock() - aaTimes > 15 and not aaReplying and aaAngry < 2 then
                local q = aaLastQuestion
                lua_thread.create(function() aaSendReply(q) end)
            end
        end
    end
end)
local movement      = { active = false }
local fabHidden     = true

local autoEat            = false
local autoEatFood        = 0
local autoEatMode        = 0
local autoEatMinSatiety  = 80
local autoEatSatiety     = -1
local autoEatWaitSat     = false
local autoEatWaitEat     = false
local autoEatSettingsOpen = false
local autoEatLastEat     = 0

local _runHookOrig
local function _sprintHook(thiz, playerid)
    if playerid == 0 and (runActive or sprintActive) then return 1 end
    return _runHookOrig(thiz, playerid)
end
_runHookOrig = hook.new(
    'uint8_t(*)(void*, int)',
    _sprintHook,
    ffi.cast('uintptr_t', ffi.cast('void*', gta._ZN4CPad9GetSprintEi))
)

local function applyRunTired()
    pcall(setPlayerNeverGetsTired, PLAYER_HANDLE,
        (farm.sprint and farm.running) or runActive)
end

local botTimerMinutes = 0
local botTimerStart   = 0
local botTotalSeconds = 0
local botSessionStart = 0
local quitOnTimer     = false

local goal = {
    mode      = 0,
    resType   = 0,
    resAmount = 0,
    resAmounts = {0, 0, 0, 0},
    money     = 0,
    reached   = false,
    sideTab   = 0,
}

local function getBotElapsed()
    return botTotalSeconds + (botSessionStart > 0 and (os.time() - botSessionStart) or 0)
end

-- License check (ported from StrandShahta)
local CHECK_URL = 'https://fragrant-waterfall-2a72.victorstrand250.workers.dev/'
local json = {
    parse = function(data)
        local ok, res = pcall(function() return decodeJson(data) end)
        if ok then return res else return nil end
    end
}
local function _keyExpired(ey, em, ed)
    local now = os.date('*t')
    return (tonumber(ey) < now.year)
        or (tonumber(ey) == now.year and tonumber(em) < now.month)
        or (tonumber(ey) == now.year and tonumber(em) == now.month and tonumber(ed) < now.day)
end

local licenseKey      = ''
local licenseOK       = false
local licenseChecking = false
local licenseMsg      = ''

local licWinOpen  = imgui.new.bool(false)
local licInputBuf = imgui.new.char[64]('')

local function bufToStr(buf, maxlen)
    local t = {}
    for i = 0, maxlen - 1 do
        local b = buf[i]
        if not b or b == 0 then break end
        t[#t + 1] = string.char(b)
    end
    return table.concat(t)
end

local ini

local function saveLicense()
    if ini and ini.cfg then
        ini.cfg.license_key = tostring(licenseKey or '')
        inicfg.save(ini, 'strand_ferma.ini')
    end
end

local function checkLicenseAsync(key, silent, skipNickCheck)
    if licenseChecking then return end
    licenseChecking = true
    licenseMsg = silent and '' or u8'\xcf\xf0\xee\xe2\xe5\xf0\xea\xe0...'
    lua_thread.create(function()
        local ok, req = pcall(require, 'requests')
        if not ok or not req then
            if not silent then licenseMsg = u8'\xce\xf8\xe8\xe1\xea\xe0: requests' end
            licenseChecking = false
            return
        end
        local rok, resp = pcall(req.get, CHECK_URL .. '?key=' .. key)
        if not rok or not resp or resp.status_code ~= 200 then
            if silent then
                local ey, em, ed = key:match('(%d%d%d%d)-(%d%d)-(%d%d)$')
                if ey and not _keyExpired(ey, em, ed) then
                    licenseOK = true
                    licWinOpen[0] = false
                end
            else
                licenseMsg = u8'\xce\xf8\xe8\xe1\xea\xe0 \xf1\xe5\xf2\xe8'
            end
            licenseChecking = false
            return
        end
        local body = resp.text or resp.content or ''
        local result = json.parse(body)
        if not result then
            if not silent then licenseMsg = u8'\xce\xf8\xe8\xe1\xea\xe0 \xf1\xe5\xf2\xe8' end
            licenseChecking = false
            return
        end
        if result.ok then
            local expiry = result.expiry or ''
            local nick   = result.nick   or ''
            local myNick = ''
            pcall(function()
                local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                myNick = sampGetPlayerNickname(pid) or ''
            end)
            if skipNickCheck or nick == '' or nick:lower() == myNick:lower() then
                licenseKey    = key
                licenseOK     = true
                licenseMsg    = ''
                licWinOpen[0] = false
                saveLicense()
                local info = (expiry ~= '') and (' {aaaaff}('..'\xc4\xee: '..expiry..')') or ''
                sampAddChatMessage('{4488ff}[StrandFerma]: {00ff7f}'..'\xcc\xf3\xeb\xfc\xf2 \xe0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xed!'..info, -1)
            else
                licenseOK = false
                if not silent then licenseMsg = u8'\xca\xeb\xfe\xf7 \xe7\xe0\xed\xff\xf2 \xe4\xf0\xf3\xe3\xe8\xec \xe8\xe3\xf0\xee\xea\xee\xec' end
            end
        else
            licenseOK = false
            if not silent then
                local reason = result.reason or ''
                if reason == 'expired' then
                    licenseMsg = u8'\xd1\xf0\xee\xea \xef\xee\xe4\xef\xe8\xf1\xea\xe8 \xe8\xf1\xf2\xb8\xea'
                else
                    licenseMsg = u8'\xca\xeb\xfe\xf7 \xed\xe5 \xed\xe0\xe9\xe4\xe5\xed'
                end
            end
        end
        licenseChecking = false
    end)
end

local CLR = {
    bg      = imgui.ImVec4(0.059, 0.059, 0.059, 0.97),
    bg2     = imgui.ImVec4(0.106, 0.157, 0.216, 1.00),
    bg3     = imgui.ImVec4(0.086, 0.102, 0.129, 1.00),
    bg4     = imgui.ImVec4(0.157, 0.118, 0.118, 1.00),

    accent  = imgui.ImVec4(1.000, 0.302, 0.302, 1.00),
    accentD = imgui.ImVec4(0.545, 0.176, 0.176, 1.00),
    accentH = imgui.ImVec4(1.000, 0.450, 0.450, 1.00),

    green   = imgui.ImVec4(0.200, 0.820, 0.400, 1.00),
    greenH  = imgui.ImVec4(0.280, 1.000, 0.500, 1.00),

    red     = imgui.ImVec4(1.000, 0.302, 0.302, 1.00),
    redH    = imgui.ImVec4(1.000, 0.450, 0.450, 1.00),

    orange  = imgui.ImVec4(0.980, 0.600, 0.050, 1.00),
    orangeH = imgui.ImVec4(1.000, 0.720, 0.150, 1.00),

    text    = imgui.ImVec4(1.000, 1.000, 1.000, 1.00),
    textDim = imgui.ImVec4(1.000, 1.000, 1.000, 0.50),

    border  = imgui.ImVec4(1.000, 1.000, 1.000, 0.10),

    tgBlue  = imgui.ImVec4(0.094, 0.459, 0.812, 1.00),
    tgH     = imgui.ImVec4(0.141, 0.596, 0.949, 1.00),

    coal    = imgui.ImVec4(0.720, 0.450, 0.200, 1.00),
}

local function applyTheme()
    local C  = imgui.GetStyle().Colors
    local cl = imgui.Col

    C[cl.WindowBg]             = CLR.bg
    C[cl.ChildBg]              = imgui.ImVec4(0.075, 0.075, 0.075, 1.00)
    C[cl.PopupBg]              = imgui.ImVec4(0.08, 0.08, 0.08, 0.98)
    C[cl.Border]               = CLR.border
    C[cl.BorderShadow]         = imgui.ImVec4(0,0,0,0)
    C[cl.FrameBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    C[cl.FrameBgHovered]       = imgui.ImVec4(0.18, 0.18, 0.18, 1.00)
    C[cl.FrameBgActive]        = imgui.ImVec4(0.22, 0.10, 0.10, 1.00)
    C[cl.TitleBg]              = imgui.ImVec4(0.106, 0.157, 0.216, 1.00)
    C[cl.TitleBgActive]        = imgui.ImVec4(0.086, 0.102, 0.129, 1.00)
    C[cl.TitleBgCollapsed]     = CLR.bg
    C[cl.ScrollbarBg]          = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    C[cl.ScrollbarGrab]        = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    C[cl.ScrollbarGrabHovered] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    C[cl.ScrollbarGrabActive]  = CLR.accent
    C[cl.CheckMark]            = CLR.accent
    C[cl.SliderGrab]           = CLR.accent
    C[cl.SliderGrabActive]     = CLR.accentH
    C[cl.Button]               = imgui.ImVec4(0.13, 0.13, 0.13, 1.00)
    C[cl.ButtonHovered]        = imgui.ImVec4(0.22, 0.10, 0.10, 1.00)
    C[cl.ButtonActive]         = imgui.ImVec4(0.35, 0.12, 0.12, 1.00)
    C[cl.Header]               = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    C[cl.HeaderHovered]        = imgui.ImVec4(0.22, 0.10, 0.10, 1.00)
    C[cl.HeaderActive]         = imgui.ImVec4(0.35, 0.12, 0.12, 1.00)
    C[cl.Separator]            = CLR.border
    C[cl.SeparatorHovered]     = imgui.ImVec4(1.00, 0.30, 0.30, 0.50)
    C[cl.SeparatorActive]      = CLR.accent
    C[cl.Text]                 = CLR.text
    C[cl.TextDisabled]         = CLR.textDim

    local st = imgui.GetStyle()
    st.WindowRounding    = 12*MDS
    st.ChildRounding     = 6*MDS
    st.FrameRounding     = 4*MDS
    st.PopupRounding     = 6*MDS
    st.ScrollbarRounding = 4*MDS
    st.GrabRounding      = 4*MDS
    st.WindowBorderSize  = 1
    st.FrameBorderSize   = 1
    st.WindowTitleAlign  = imgui.ImVec2(0.5,0.5)
    st.ButtonTextAlign   = imgui.ImVec2(0.5,0.5)
    st.ItemSpacing       = imgui.ImVec2(6*MDS,6*MDS)
    st.WindowPadding     = imgui.ImVec2(14*MDS,12*MDS)
    st.FramePadding      = imgui.ImVec2(10*MDS,6*MDS)
end

local _fnt = { main = nil, big = nil, small = nil, huge = nil }
local faR    = require('fAwesome6')
local fa     = require('fAwesome6_solid')

imgui.OnInitialize(function()
    imgui.SwitchContext()
    local io = imgui.GetIO()
    io.IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
    local ranges = io.Fonts:GetGlyphRangesCyrillic()
    local ttf    = getWorkingDirectory()..'/../trebucbd.ttf'
    _fnt.main  = io.Fonts:AddFontFromFileTTF(ttf, 15*MDS, nil, ranges)
    _fnt.big   = io.Fonts:AddFontFromFileTTF(ttf, 21*MDS, nil, ranges)
    _fnt.small = io.Fonts:AddFontFromFileTTF(ttf, 13*MDS, nil, ranges)
    _fnt.huge  = io.Fonts:AddFontFromFileTTF(ttf, 42*MDS, nil, ranges)
    local cfg2 = imgui.ImFontConfig()
    cfg2.MergeMode  = true
    cfg2.PixelSnapH = true
    local faRange = imgui.new.ImWchar[3](faR.min_range, faR.max_range, 0)
    io.Fonts:AddFontFromMemoryCompressedBase85TTF(
        faR.get_font_data_base85('solid'), 15*MDS, cfg2, faRange)
    applyTheme()
end)

local function b2s(v) return v and 'true' or 'false' end
local function s2b(v,d)
    if v=='true' then return true end
    if v=='false' then return false end
    return d
end

ini = inicfg.load({
    farm={
        collect_cotton='false', collect_linen='false',
        sprint='false',
        stop_dialog='false', stop_tp='false', stop_chat='false',
        quit_stop='false',
        price_cotton='0', price_linen='0', price_rare='0', price_coal='0',
        auto_jump='false', auto_jump_interval='5',
    auto_eat='false', auto_eat_food='0', auto_eat_mode='0', auto_eat_min_satiety='80',
    auto_reply='false',
    },
    ui={ hide_fab='true' },
    stats={ cotton='0', linen='0', rare='0', coal='0', start_time='0', bot_seconds='0' },
    cfg={ license_key='', bot_timer_minutes='0', quit_on_timer='false',
          goal_mode='0', goal_res_type='0', goal_res_amount='0', goal_money='0' },
}, 'strand_ferma.ini')

if not ini.farm then ini.farm = {} end
local _farmDef = {
    collect_cotton='false', collect_linen='false', sprint='false',
    stop_dialog='false', stop_tp='false', stop_chat='false',
    quit_stop='false',
    goto_soonest='false',
    price_cotton='0', price_linen='0', price_rare='0', price_coal='0',
    auto_jump='false', auto_jump_interval='5',
    auto_eat='false', auto_eat_food='0', auto_eat_mode='0', auto_eat_min_satiety='80',
    auto_reply='false',
}
for k,v in pairs(_farmDef) do
    if ini.farm[k] == nil then ini.farm[k] = v end
end
if not ini.ui       then ini.ui       = { hide_fab='true' } end
if not ini.stats    then ini.stats    = { cotton='0', linen='0', rare='0', coal='0', start_time='0' } end
if not ini.cfg      then ini.cfg      = { license_key='', bot_timer_minutes='0', quit_on_timer='false',
    goal_mode='0', goal_res_type='0', goal_res_amount='0', goal_money='0' } end
if ini.cfg.bot_timer_minutes == nil then ini.cfg.bot_timer_minutes = '0' end
if ini.cfg.quit_on_timer     == nil then ini.cfg.quit_on_timer     = 'false' end
if ini.cfg.goal_mode         == nil then ini.cfg.goal_mode         = '0' end
if ini.cfg.goal_res_type     == nil then ini.cfg.goal_res_type     = '0' end
if ini.cfg.goal_res_amount   == nil then ini.cfg.goal_res_amount   = '0' end
if ini.cfg.goal_money        == nil then ini.cfg.goal_money        = '0' end

licenseKey = (ini.cfg.license_key and ini.cfg.license_key ~= '') and ini.cfg.license_key or ''
do
    local k = licenseKey or ''
    for i = 1, math.min(#k, 63) do
        licInputBuf[i - 1] = string.byte(k, i)
    end
    licInputBuf[math.min(#k, 63)] = 0
end

local function loadCfg()
    local f = ini.farm
    farm.collect_cotton  = false
    farm.collect_linen   = false
    farm.sprint          = false
    farm.stop_on_dialog  = false
    farm.stop_on_tp      = false
    farm.stop_on_chat    = false
    farm.quit_on_stop    = false
    farm.goto_soonest    = false
    autoJump             = false
    autoEat              = false
    aaState              = false
    aaAngry              = 0
    aaReplying           = false
    calc.price_cotton    = tonumber(f.price_cotton) or 0
    calc.price_linen     = tonumber(f.price_linen)  or 0
    calc.price_rare      = tonumber(f.price_rare)   or 0
    calc.price_coal     = tonumber(f.price_coal)  or 0
    if f.sprint         ~= nil then farm.sprint         = (f.sprint         == true or f.sprint         == 'true') end
    if f.auto_jump      ~= nil then autoJump            = (f.auto_jump      == true or f.auto_jump      == 'true') end
    if f.auto_eat       ~= nil then autoEat             = (f.auto_eat       == true or f.auto_eat       == 'true') end
    if f.auto_reply     ~= nil then aaState             = (f.auto_reply     == true or f.auto_reply     == 'true') end
    autoJumpInterval     = math.max(2, tonumber(f.auto_jump_interval) or 5)
    autoEatFood          = tonumber(f.auto_eat_food) or 0
    autoEatMode          = tonumber(f.auto_eat_mode) or 0
    autoEatMinSatiety    = tonumber(f.auto_eat_min_satiety) or 80
    fabHidden   = s2b(ini.ui and ini.ui.hide_fab or 'true', true)
    autoAnims   = s2b(ini.ui and ini.ui.auto_anims or 'false', false)
    if ini.stats then
        farm.res_counter.cotton = tonumber(ini.stats.cotton) or 0
        farm.res_counter.linen  = tonumber(ini.stats.linen)  or 0
        farm.res_counter.rare   = tonumber(ini.stats.rare)   or 0
        farm.res_counter.coal  = tonumber(ini.stats.coal)  or 0
        farm.stats.start_time   = 0
        botTotalSeconds         = tonumber(ini.stats.bot_seconds) or 0
    end
    botTimerMinutes = tonumber(ini.cfg and ini.cfg.bot_timer_minutes) or 0
    quitOnTimer     = s2b(ini.cfg and ini.cfg.quit_on_timer or 'false', false)
    goal.mode      = tonumber(ini.cfg and ini.cfg.goal_mode) or 0
    goal.resType   = tonumber(ini.cfg and ini.cfg.goal_res_type) or 0
    local _ra = tonumber(ini.cfg and ini.cfg.goal_res_amount) or 0
    goal.resAmount = _ra
    goal.resAmounts = {
        tonumber(ini.cfg and ini.cfg.goal_res_amount_0) or 0,
        tonumber(ini.cfg and ini.cfg.goal_res_amount_1) or 0,
        tonumber(ini.cfg and ini.cfg.goal_res_amount_2) or 0,
        tonumber(ini.cfg and ini.cfg.goal_res_amount_3) or 0,
    }
    local _allZero = true
    for _, v in ipairs(goal.resAmounts) do if v > 0 then _allZero = false; break end end
    if _allZero and _ra > 0 then goal.resAmounts[goal.resType + 1] = _ra end
    goal.resAmount = goal.resAmounts[goal.resType + 1]
    goal.money     = tonumber(ini.cfg and ini.cfg.goal_money) or 0
    goal.reached   = false
end

local function saveCfg()
    local f = ini.farm
    f.price_cotton         = tostring(calc.price_cotton)
    f.price_linen          = tostring(calc.price_linen)
    f.price_rare           = tostring(calc.price_rare)
    f.price_coal          = tostring(calc.price_coal)
    f.auto_jump_interval   = tostring(autoJumpInterval)
    f.auto_eat_food        = tostring(autoEatFood)
    f.auto_eat_mode        = tostring(autoEatMode)
    f.auto_eat_min_satiety = tostring(autoEatMinSatiety)
    f.collect_cotton       = b2s(farm.collect_cotton)
    f.collect_linen        = b2s(farm.collect_linen)
    f.sprint               = b2s(farm.sprint)
    f.stop_dialog          = b2s(farm.stop_on_dialog)
    f.stop_tp              = b2s(farm.stop_on_tp)
    f.stop_chat            = b2s(farm.stop_on_chat)
    f.quit_stop            = b2s(farm.quit_on_stop)
    f.goto_soonest         = b2s(farm.goto_soonest)
    f.auto_reply           = b2s(aaState)
    if not ini.ui then ini.ui = {} end
    ini.ui.hide_fab   = b2s(fabHidden)
    ini.ui.auto_anims = b2s(autoAnims)
    if not ini.stats then ini.stats = {} end
    ini.stats.cotton      = tostring(farm.res_counter.cotton)
    ini.stats.linen       = tostring(farm.res_counter.linen)
    ini.stats.rare        = tostring(farm.res_counter.rare)
    ini.stats.coal       = tostring(farm.res_counter.coal)
    ini.stats.bot_seconds = tostring(botTotalSeconds)
    if not ini.cfg then ini.cfg = {} end
    ini.cfg.license_key       = tostring(licenseKey or '')
    ini.cfg.bot_timer_minutes = tostring(botTimerMinutes or 0)
    ini.cfg.quit_on_timer     = b2s(quitOnTimer)
    ini.cfg.goal_mode         = tostring(goal.mode)
    ini.cfg.goal_res_type     = tostring(goal.resType)
    ini.cfg.goal_res_amount   = tostring(goal.resAmount)
    ini.cfg.goal_res_amount_0 = tostring(goal.resAmounts[1])
    ini.cfg.goal_res_amount_1 = tostring(goal.resAmounts[2])
    ini.cfg.goal_res_amount_2 = tostring(goal.resAmounts[3])
    ini.cfg.goal_res_amount_3 = tostring(goal.resAmounts[4])
    ini.cfg.goal_money        = tostring(goal.money)
    inicfg.save(ini, 'strand_ferma.ini')
end

local function fmtNum(n)
    local s=string.format('%.0f',math.floor(n or 0))
    local r,l='',#s
    for i=1,l do
        r=r..s:sub(i,i)
        local rem=l-i
        if rem>0 and rem%3==0 then r=r..'.' end
    end
    return r
end

local function addLog(text)
    local clean=tostring(text):gsub('{.-}','')
    local entry='['..os.date('%H:%M:%S')..'] '..clean
    table.insert(log_lines,1,entry)
    if #log_lines>60 then table.remove(log_lines) end
end

local function emergencyStop()
    if botSessionStart > 0 then
        botTotalSeconds = botTotalSeconds + (os.time() - botSessionStart)
        botSessionStart = 0
    end
    farm.running=false; farm.target=nil; movement.active=false
    sprintActive=false
    larekRunning=false; larekIsWalking=false
    setGameKeyState(1,0); setGameKeyState(16,0); setGameKeyState(14,0)
    addLog('[Система] Аварийная остановка.')
    saveCfg()
end

local function quitGame()
    lua_thread.create(function()
        wait(2000)
        os.exit()
    end)
end

local function sendAlt()
    local bs=raknetNewBitStream()
    raknetBitStreamWriteInt8(bs,220);raknetBitStreamWriteInt8(bs,63)
    raknetBitStreamWriteInt8(bs,8);  raknetBitStreamWriteInt32(bs,7)
    raknetBitStreamWriteInt32(bs,-1);raknetBitStreamWriteInt32(bs,0)
    raknetBitStreamWriteString(bs,'')
    raknetSendBitStreamEx(bs,1,7,1);raknetDeleteBitStream(bs)
end

local function doHarvest() sendAlt(); wait(800); sendAlt() end

local function findBestBush()
    local mx, my = getCharCoordinates(PLAYER_PED)
    local best, bd = nil, 200

    for id = 0, 2048 do
        if id > 0 and id % 256 == 0 then wait(0) end
        if sampIs3dTextDefined(id) then
            local ok, txt, _, x, y, z = pcall(sampGet3dTextInfoById, id)
            if ok and txt then
                if txt:find('\xcc\xee\xe6\xed\xee \xf1\xee\xe1\xf0\xe0\xf2\xfc') then
                    local wC = farm.collect_cotton and txt:find('\xd5\xeb\xee\xef\xee\xea')
                    local wL = farm.collect_linen  and txt:find('\xb8\xed')
                    if wC or wL then
                        local qty = tonumber(txt:match('%((%d+)%s*\xe8\xe7'))
                                 or tonumber(txt:match('(%d+)')) or 0
                        if qty >= 1 then
                            local d = getDistanceBetweenCoords2d(mx, my, x, y)
                            if d < bd then bd = d; best = {x,y,z} end
                        end
                    end
                end
            end
        end
    end

    return best
end

local _smoothCamAngle = 0

local function calculateObstacleTurn()
    local ok, cx, cy, cz = pcall(getCharCoordinates, PLAYER_PED)
    if not ok or not cx then return 0 end
    local headRad = math.rad(getCharHeading(PLAYER_PED)) + math.pi / 2
    local probeDist = 4.5
    local angles = { 0, math.rad(35), math.rad(-35), math.rad(65), math.rad(-65) }
    for _, zOff in ipairs({ 0.4, 1.1 }) do
        for _, da in ipairs(angles) do
            local a = headRad + da
            local hit = processLineOfSight(
                cx, cy, cz + zOff,
                cx + probeDist * math.cos(a),
                cy + probeDist * math.sin(a),
                cz + zOff,
                true, false, false, true, true, false, false, false)
            if hit then
                if da > 0 then return -255
                elseif da < 0 then return 255
                else return (math.random() > 0.5) and 255 or -255
                end
            end
        end
    end
    return 0
end



local bushCache       = nil
local bushCacheTime   = 0
local BUSH_CACHE_TTL  = 0.3

local function findBestBushCached()
    if (os.clock() - bushCacheTime) < BUSH_CACHE_TTL then
        return bushCache
    end
    bushCache     = findBestBush()
    bushCacheTime = os.clock()
    return bushCache
end

local function invalidateBushCache()
    bushCacheTime = 0
end

local function runToPoint(tox,toy,toz,skipBushCheck)
    local lastX,lastY=getCharCoordinates(PLAYER_PED)
    local stuckSince=nil
    local sideDir=1
    local runStart=os.clock()
    local startDist = getDistanceBetweenCoords2d(lastX, lastY, tox, toy)
    local RUN_TIMEOUT = math.min(60, math.max(25, startDist / 5))
    do
        local ok, ch = pcall(getCharHeading, PLAYER_PED)
        if ok and ch then
            local okP, ix, iy = pcall(getCharCoordinates, PLAYER_PED)
            if okP and ix then
                local targetAng = getHeadingFromVector2d(tox - ix, toy - iy)
                local diff = math.abs(((targetAng - _smoothCamAngle + 180) % 360) - 180)
                if diff > 90 then
                    _smoothCamAngle = ch
                end
            end
        end
    end

    local function findNewTarget()
        local mx, my = getCharCoordinates(PLAYER_PED)
        local best, bd = nil, 200
        for id = 0, 2048 do
            if sampIs3dTextDefined(id) then
                local ok2, txt2, _, bx2, by2 = pcall(sampGet3dTextInfoById, id)
                if ok2 and txt2 and bx2 and by2 then
                    if txt2:find('\xcc\xee\xe6\xed\xee \xf1\xee\xe1\xf0\xe0\xf2\xfc') then
                        local wC = farm.collect_cotton and txt2:find('\xd5\xeb\xee\xef\xee\xea')
                        local wL = farm.collect_linen  and txt2:find('\xb8\xed')
                        if wC or wL then
                            local qty = tonumber(txt2:match('%((%d+)%s*\xe8\xe7'))
                                     or tonumber(txt2:match('(%d+)')) or 0
                            if qty >= 1 then
                                local d = getDistanceBetweenCoords2d(mx, my, bx2, by2)
                                if d < bd then bd = d; best = {bx2, by2, 0} end
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function bushStillHasRes()
        for id = 0, 2048 do
            if sampIs3dTextDefined(id) then
                local ok2, txt2, _, bx2, by2 = pcall(sampGet3dTextInfoById, id)
                if ok2 and txt2 and bx2 and by2 then
                    if getDistanceBetweenCoords2d(bx2, by2, tox, toy) < 1.5 then
                        if txt2:find('\xcc\xee\xe6\xed\xee \xf1\xee\xe1\xf0\xe0\xf2\xfc') then
                            local qty = tonumber(txt2:match('%((%d+)%s*\xe8\xe7'))
                                     or tonumber(txt2:match('(%d+)')) or 0
                            return qty >= 1
                        end
                        return false
                    end
                end
            end
        end
        return true
    end

    local lastRecheckTime = 0

    while farm.running and movement.active do
        local cx,cy=getCharCoordinates(PLAYER_PED)
        local dist=getDistanceBetweenCoords2d(cx,cy,tox,toy)

        if not skipBushCheck and dist < 10 and (os.clock() - lastRecheckTime) > 0.5 then
            lastRecheckTime = os.clock()
            if not bushStillHasRes() then
                local newT = findNewTarget()
                if newT then
                    tox, toy, toz = newT[1], newT[2], newT[3]
                    farm.target = newT
                else
                    setGameKeyState(1,0); setGameKeyState(0,0); stopSprint()
                    movement.active=false; sprintActive=false
                    return false
                end
            end
        end

        if (os.clock()-runStart) > RUN_TIMEOUT then
            setGameKeyState(1,0); setGameKeyState(0,0); stopSprint()
            movement.active=false; sprintActive=false
            return false
        end

        if dist<=2.5 then
            setGameKeyState(1,0)
            setGameKeyState(0,0)
            stopSprint()
            movement.active=false
            sprintActive=false
            return true
        end

        local toAng = getHeadingFromVector2d(tox-cx, toy-cy)

        local lerpK = dist < 8 and 0.07 or 0.04
        local angleDiff = ((toAng - _smoothCamAngle + 180) % 360) - 180
        _smoothCamAngle = (_smoothCamAngle + angleDiff * lerpK + 360) % 360
        pcall(setCameraPositionUnfixed, 0, math.rad(_smoothCamAngle - 90))

        sprintActive = farm.sprint and (dist > 3.5)
        setGameKeyState(1, -255)

        local obstTurn = dist >= 4.0 and calculateObstacleTurn() or 0
        if obstTurn ~= 0 then
            setGameKeyState(0, obstTurn)
        else
            setGameKeyState(0, 0)
        end

        if autoJump and dist > 5.0 then
            doJumpToTarget(tox, toy)
        end

        if getDistanceBetweenCoords2d(cx,cy,lastX,lastY)>=0.15 then
            lastX,lastY=cx,cy; stuckSince=nil
        elseif stuckSince==nil then
            stuckSince=os.clock()
        elseif (os.clock()-stuckSince)>2.2 then
            local sa = toAng + sideDir * 85
            _smoothCamAngle = (_smoothCamAngle + (((sa - _smoothCamAngle + 180) % 360) - 180) * 0.4 + 360) % 360
            setGameKeyState(1,-255)
            setGameKeyState(0, sideDir * 180)
            local sw=0; while farm.running and sw<300 do wait(1);sw=sw+1 end
            setGameKeyState(14,255); wait(90); setGameKeyState(14,0)
            setGameKeyState(0, 0)
            sideDir=-sideDir
            lastX,lastY=getCharCoordinates(PLAYER_PED); stuckSince=nil
        end

        wait(1)
    end
    setGameKeyState(1,0)
    setGameKeyState(0,0)
    stopSprint()
    sprintActive=false
    movement.active=false
    return false
end

local function sendLarekClick(subid)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 63)
    raknetBitStreamWriteInt8(bs, 55)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt32(bs, subid)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteString(bs, '')
    raknetSendBitStreamEx(bs, 1, 7, 1)
    raknetDeleteBitStream(bs)
end

-- New route to the food stall (larek)
local LAREK_WAYPOINTS = {
    {-246.710, -1378.470, 10.218},
    {-246.675, -1375.879, 10.291},
    {-246.700, -1373.313, 10.363},
    {-246.787, -1370.766, 10.365},
    {-246.484, -1368.153, 10.063},
    {-245.646, -1365.767, 9.831},
    {-245.053, -1363.305, 9.632},
}

local function walkToLarek(tox, toy)
    local lastX, lastY = getCharCoordinates(PLAYER_PED)
    local stuckSince   = nil
    local sideDir      = 1
    local startTime    = os.clock()
    local TIMEOUT      = 35

    do
        local ok0, ix, iy = pcall(getCharCoordinates, PLAYER_PED)
        if ok0 and ix then
            _smoothCamAngle = getHeadingFromVector2d(tox - ix, toy - iy)
        end
    end

    while larekRunning do
        local cx, cy = getCharCoordinates(PLAYER_PED)
        local dist   = getDistanceBetweenCoords2d(cx, cy, tox, toy)

        if dist <= 1.0 then
            setGameKeyState(1, 0)
            setGameKeyState(0, 0)
            sprintActive = false
            return true
        end

        if (os.clock() - startTime) > TIMEOUT then
            setGameKeyState(1, 0)
            setGameKeyState(0, 0)
            sprintActive = false
            return false
        end

        local toAng     = getHeadingFromVector2d(tox - cx, toy - cy)
        local lerpK     = dist < 8 and 0.07 or 0.04
        local angleDiff = ((toAng - _smoothCamAngle + 180) % 360) - 180
        _smoothCamAngle = (_smoothCamAngle + angleDiff * lerpK + 360) % 360
        pcall(setCameraPositionUnfixed, 0, math.rad(_smoothCamAngle - 90))

        sprintActive = (dist > 3.0)
        local moveSpeed = -255
        if dist < 3.0 then
            local t = math.max(0, math.min(1, (dist - 1.0) / 2.0))
            moveSpeed = math.floor(-80 - 175 * t)
        end
        setGameKeyState(1, moveSpeed)

        local obstTurn = dist >= 4.0 and calculateObstacleTurn() or 0
        setGameKeyState(0, obstTurn)

        if getDistanceBetweenCoords2d(cx, cy, lastX, lastY) >= 0.15 then
            lastX, lastY = cx, cy
            stuckSince   = nil
        elseif stuckSince == nil then
            stuckSince = os.clock()
        elseif (os.clock() - stuckSince) > 2.2 then
            local sa = toAng + sideDir * 85
            _smoothCamAngle = (_smoothCamAngle + (((sa - _smoothCamAngle + 180) % 360) - 180) * 0.4 + 360) % 360
            setGameKeyState(1, -255)
            setGameKeyState(0, sideDir * 180)
            local sw = 0
            while larekRunning and sw < 300 do wait(1); sw = sw + 1 end
            setGameKeyState(14, 255); wait(90); setGameKeyState(14, 0)
            setGameKeyState(0, 0)
            sideDir      = -sideDir
            lastX, lastY = getCharCoordinates(PLAYER_PED)
            stuckSince   = nil
        end

        wait(1)
    end

    setGameKeyState(1, 0)
    setGameKeyState(0, 0)
    sprintActive = false
    return false
end

local function walkWaypoints(wpList, forward)
    local list = forward and wpList or {}
    if not forward then
        for i = #wpList, 1, -1 do list[#list+1] = wpList[i] end
    end
    for _, wp in ipairs(list) do
        if not larekRunning then return false end
        farm.target = {wp[1], wp[2], wp[3]}
        local reached = walkToLarek(wp[1], wp[2])
        if not reached then
            farm.target = nil
            return false
        end
    end
    farm.target = nil
    return true
end

-- Run to the food stall, eat, and come back. Runs in its own thread so the
-- main bot loop is never blocked: the main loop simply idles while larekRunning
-- (same approach as StrandShahta).
local function goEatAtLarek()
    if larekRunning then return end
    larekRunning = true
    lua_thread.create(function()
        local wasSprint = farm.sprint

        addLog('[\xd1\xfb\xf2\xee\xf1\xf2\xfc] \xc8\xe4\xf3 \xea \xeb\xe0\xf0\xb8\xea\xf3...')

        -- interrupt whatever the bot is doing right now
        movement.active = false
        sprintActive    = false
        setGameKeyState(1, 0)
        setGameKeyState(16, 0)

        pcall(function()
            local ok_h, objHandle = pcall(sampGetObjectHandleBySampId, 12225)
            if ok_h and objHandle then
                pcall(setObjectCollision, objHandle, false)
            end
        end)

        larekIsWalking = true
        local wpOk = walkWaypoints(LAREK_WAYPOINTS, true)

        pcall(function()
            local ok_h2, objHandle2 = pcall(sampGetObjectHandleBySampId, 12225)
            if ok_h2 and objHandle2 then pcall(setObjectCollision, objHandle2, true) end
        end)
        larekIsWalking = false

        if not wpOk then
            addLog('[\xd1\xfb\xf2\xee\xf1\xf2\xfc] \xcd\xe5 \xe4\xee\xf8\xb8\xeb \xe4\xee \xeb\xe0\xf0\xb8\xea\xe0')
            larekRunning  = false
            testLarekMode = false
            return
        end

        addLog('[\xd1\xfb\xf2\xee\xf1\xf2\xfc] \xc1\xe5\xf0\xf3 \xe5\xe4\xf3...')
        wait(600)
        sendLarekClick(1)
        wait(700)
        sendLarekClick(1)
        wait(700)
        sendLarekClick(0)
        wait(400)

        addLog('[\xd1\xfb\xf2\xee\xf1\xf2\xfc] \xc5\xe4\xe0 \xe2\xe7\xff\xf2\xe0, \xe2\xee\xe7\xe2\xf0\xe0\xf9\xe0\xfe\xf1\xfc')

        larekIsWalking = true
        walkWaypoints(LAREK_WAYPOINTS, false)
        larekIsWalking = false

        farm.target  = nil
        farm.sprint  = wasSprint
        sprintActive = false
        setGameKeyState(1, 0)
        invalidateBushCache()
        larekRunning  = false
        testLarekMode = false
    end)
end

local function findSoonestStageTwoBush()
    local best, bestTime = nil, math.huge
    for id = 0, 2048 do
        if sampIs3dTextDefined(id) then
            local ok, txt, _, x, y, z = pcall(sampGet3dTextInfoById, id)
            if ok and txt then
                local wC = farm.collect_cotton and txt:find('\xd5\xeb\xee\xef\xee\xea')
                local wL = farm.collect_linen  and txt:find('\xb8\xed')
                if (wC or wL) and txt:find('\xfd\xf2\xe0\xef\x20\x32') then
                    local min_part = txt:match('\xce\xf1\xf2\xe0\xeb\xee\xf1\xfc\x20(%d+):')
                    local sec_part = txt:match('\xce\xf1\xf2\xe0\xeb\xee\xf1\xfc\x20%d+:(%d+)')
                    local m = tonumber(min_part) or 99
                    local s = tonumber(sec_part) or 99
                    local totalSec = m * 60 + s
                    if totalSec < bestTime then
                        bestTime = totalSec
                        best = {x, y, z}
                    end
                end
            end
        end
    end
    return best, bestTime
end

local watchdogLastTarget=0
local function botWatchdog()
    while true do
        wait(1000)
        if farm.running then
            if farm.target ~= nil or movement.active then
                watchdogLastTarget = os.clock()
            else
                if (os.clock()-watchdogLastTarget) > 8 then
                    setGameKeyState(1,0)
                    stopSprint()
                    sprintActive=false
                    movement.active=false
                end
            end
        else
            watchdogLastTarget = os.clock()
        end
    end
end

local function toARGB(r, g, b, a)
    return math.floor(a*255+.5)*0x1000000
         + math.floor(r*255+.5)*0x10000
         + math.floor(g*255+.5)*0x100
         + math.floor(b*255+.5)
end

local TR_LINE  = toARGB(1.000, 0.302, 0.302, 0.92)
local TR_GLOW  = toARGB(0.545, 0.176, 0.176, 0.30)

local function renderLoop()
    while true do
        if farm.running and farm.target then
            local tx, ty, tz = farm.target[1], farm.target[2], farm.target[3]
            local ok, ox, oy, oz = pcall(getCharCoordinates, PLAYER_PED)
            if ok and ox and isPointOnScreen(tx, ty, tz, 1) then
                local ok1, sx1, sy1 = pcall(convert3DCoordsToScreen, ox, oy, oz)
                local ok2, sx2, sy2 = pcall(convert3DCoordsToScreen, tx, ty, tz)
                if ok1 and ok2 and sx1 and sy1 and sx2 and sy2 then
                    renderDrawLine(sx1, sy1, sx2, sy2, 5, TR_GLOW)
                    renderDrawLine(sx1, sy1, sx2, sy2, 2, TR_LINE)
                end
                if ok2 and sx2 and sy2 then
                    renderDrawLine(sx2-4, sy2, sx2+4, sy2, 3, 0xFFFFFFFF)
                    renderDrawLine(sx2, sy2-4, sx2, sy2+4, 3, 0xFFFFFFFF)
                end
            end
        end
        wait(33)
    end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
    if id == 8252 and style == 0 then return end
    if title and title:find('\xd2\xee\xf0\xe3\xee\xe2\xeb\xff') then return end

    if title and (title:find('\xd1\xfb\xf2\xee\xf1\xf2\xfc') or (text and (text:find('\xf1\xfb\xf2\xee\xf1\xf2\xfc') or text:find('\xd1\xfb\xf2\xee\xf1\xf2\xfc')))) then
        local val = (text or ''):match('\xf1\xfb\xf2\xee\xf1\xf2\xfc%s*:%s*(%d+%.?%d*)')
                 or (text or ''):match('(%d+%.%d+)%s*/')
                 or (text or ''):match('(%d+)%s*/')
        if val then autoEatSatiety = tonumber(val) end
        autoEatWaitSat = false
        lua_thread.create(function() wait(100); sampSendDialogResponse(id, 1, -1, '') end)
        return false
    end

    if title and (title:find('\xca\xf3\xf8\xe0\xf2\xfc') or title:find('\xca\xf3\xf8')) then
        autoEatWaitEat = false
        if autoEat and (os.clock() - autoEatLastEat) > 10 then
            autoEatLastEat = os.clock()
            local row = autoEatFood
            local buyCount = (autoEatSatiety >= 0 and autoEatSatiety < 35) and 3 or 2
            lua_thread.create(function()
                for i = 1, buyCount do
                    wait(150)
                    sampSendDialogResponse(id, 1, row, '')
                    wait(350)
                end
                setGameKeyState(23, 255)
                wait(100)
                setGameKeyState(23, 0)
                wait(400)
                if sampIsDialogActive() then
                    sampSendDialogResponse(id, 0, -1, '')
                end
            end)
        else
            lua_thread.create(function()
                wait(150)
                setGameKeyState(23, 255)
                wait(100)
                setGameKeyState(23, 0)
            end)
        end
        return false
    end

    if farm.stop_on_dialog and farm.running then
        if (os.clock() - antiAdminEnableTime) < 5.0 then return end
        emergencyStop()
        addLog('[Защита] Стоп: диалог от сервера (id='..tostring(id)..')')
        playAntiAdminSound()
        if farm.quit_on_stop then quitGame() end
    end
    if aaState and farm.running then
        aaLastTrigger = os.clock()
        playAntiAdminSound()
        lua_thread.create(function()
            aaLastQuestion = text
            wait(3000)
            sampSendDialogResponse(id, 1, 0, '')
        end)
    end
end

function sampev.onSetPlayerPos(position)
    if farm.stop_on_tp and farm.running then
        if (os.clock() - antiAdminEnableTime) < 5.0 then return end
        local tpDist = 0
        pcall(function()
            local cx, cy, cz = getCharCoordinates(PLAYER_PED)
            local nx, ny, nz
            if type(position) == 'table' then
                nx = tonumber(position.x); ny = tonumber(position.y); nz = tonumber(position.z)
            end
            if cx and nx then
                tpDist = getDistanceBetweenCoords3d(cx, cy, cz, nx, ny, nz)
            end
        end)
        if tpDist < 15.0 then return end
        emergencyStop(); addLog('[Защита] Стоп: телепорт сервера ('..string.format('%.1f', tpDist)..'м)')
        playAntiAdminSound()
        if farm.quit_on_stop then quitGame() end
    end
end

function sampev.onServerMessage(color,txt)
    if not txt then return end

    lua_thread.create(function()
        local txtClean = txt:gsub('{%x%x%x%x%x%x}','')

        if txtClean:find('\xca\xf3\xf1\xee\xea') and txtClean:find('\xf2\xea\xe0\xed\xe8') then
            local amt = tonumber(txtClean:match('%((%d+)%s*\xf8\xf2%)')) or 1
            amt = math.min(amt, 10)
            farm.res_counter.rare = farm.res_counter.rare + amt
            addLog('[\xd2\xea\xe0\xed\xfc] +'..amt)
        end
        if txtClean:find('item1692') then
            local amt2 = tonumber(txtClean:match('item1692[^%d]*(%d+)'))
            if amt2 then
                farm.res_counter.rare = farm.res_counter.rare + math.min(amt2, 10)
            end
        end

        if txtClean:find('\xd3\xe3\xee\xeb\xfc') then
            local amt3 = tonumber(txtClean:match('%((%d+)%s*\xf8\xf2%)')) or 1
            amt3 = math.min(amt3, 10)
            farm.res_counter.coal = farm.res_counter.coal + amt3
            addLog('[\xd3\xe3\xee\xeb\xfc] +'..amt3)
        end

        if aaAngry > 0 and os.clock() - aaLastTrigger > 300 then
            aaAngry = 0
        end

        if farm.running then
            if farm.stop_on_chat then
                if (os.clock() - antiAdminEnableTime) >= 5.0 then
                    if txtClean:find('\xc2\xfb \xf2\xf3\xf2') or txtClean:find('\xc2\xfb \xe7\xe4\xe5\xf1\xfc')
                    or txtClean:find('\xe2\xfb \xf2\xf3\xf2') or txtClean:find('\xe2\xfb \xe7\xe4\xe5\xf1\xfc') then
                        emergencyStop(); addLog('[Защита] Стоп: проверка в чате')
                        playAntiAdminSound()
                        if farm.quit_on_stop then quitGame() end
                    end
                end
            end
        end

        if aaState and farm.running and aaIsAdmin(txtClean)
        and not aaReplying and aaAngry < 2 and aaLooksDirected(txtClean) then
            aaLastTrigger  = os.clock()
            playAntiAdminSound()
            aaLastQuestion = txtClean
            lua_thread.create(function() aaSendReply(txtClean) end)
        end
    end)
end

function sampev.onDisplayGameText(style,time,text)
    if not text then return end
    local l = text:match('linen%+%s*(%d+)') or text:match('linen%s*%+(%d+)')
    local c = text:match('cotton%+%s*(%d+)') or text:match('cotton%s*%+(%d+)')
    if l then farm.res_counter.linen  = farm.res_counter.linen  + tonumber(l) end
    if c then farm.res_counter.cotton = farm.res_counter.cotton + tonumber(c) end
end

function sampev.onConnectionClosed()
    emergencyStop()
end

function sampev.onQuit()
    emergencyStop()
end

local function pF(f)    if f then imgui.PushFont(f); return true end return false end
local function pFpop(p) if p then imgui.PopFont() end end

local function u32(c, a)
    local cc = imgui.ImVec4(c.x, c.y, c.z, a ~= nil and a or c.w)
    return imgui.ColorConvertFloat4ToU32(cc)
end

local function dlBtn(DL, x, y, w, h, bg, hov, label, lc, rnd)
    rnd = rnd or 8*MDS
    local mx, my = imgui.GetMousePos().x, imgui.GetMousePos().y
    local over = mx >= x and mx <= x+w and my >= y and my <= y+h
    local hit  = over and imgui.IsMouseClicked(0)
    DL:AddRectFilled(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
        u32(over and hov or bg), rnd)
    if over then
        DL:AddRect(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
            u32(lc, 0.35), rnd, 0, 1.2)
    end
    local ts = imgui.CalcTextSize(label)
    DL:AddText(imgui.ImVec2(x+(w-ts.x)*0.5, y+(h-ts.y)*0.5), u32(lc), label)
    return hit
end

local function toggleRow(DL, x, y, w, label, val)
    local th = 22*MDS; local tw = 44*MDS
    local tx = x + w - tw; local ty = y + 2*MDS
    local mx, my = imgui.GetMousePos().x, imgui.GetMousePos().y
    local over = mx >= tx and mx <= tx+tw and my >= ty and my <= ty+th
    local clicked = over and imgui.IsMouseClicked(0)
    if clicked then val = not val end

    local t   = val and 1.0 or 0.0
    local on  = CLR.accent
    local off = imgui.ImVec4(0.15, 0.15, 0.15, 1)
    local bg  = imgui.ImVec4(off.x+(on.x-off.x)*t, off.y+(on.y-off.y)*t, off.z+(on.z-off.z)*t, 1)
    local r   = th * 0.5
    DL:AddRectFilled(imgui.ImVec2(tx,ty), imgui.ImVec2(tx+tw,ty+th), u32(bg), r)
    DL:AddCircleFilled(imgui.ImVec2(tx+r+(tw-th)*t, ty+r), r-2.5*MDS, u32(imgui.ImVec4(1,1,1,0.96)))

    local ts = imgui.CalcTextSize(label)
    DL:AddText(imgui.ImVec2(x, y + (th - ts.y) * 0.5 + 2*MDS), u32(CLR.text), label)
    return val, clicked
end

local function drawStatCard(DL, x, y, w, h, topLabel, valStr, valColor)
    DL:AddRectFilled(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
        u32(imgui.ImVec4(0.08, 0.08, 0.08, 1)), 6*MDS)
    DL:AddRectFilled(imgui.ImVec2(x,y+5*MDS), imgui.ImVec2(x+2.5*MDS,y+h-5*MDS),
        u32(valColor or CLR.accent), 2*MDS)
    DL:AddRect(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
        u32(CLR.border), 6*MDS, 0, 1.0)
    local tl = imgui.CalcTextSize(topLabel)
    DL:AddText(imgui.ImVec2(x+10*MDS, y+5*MDS), u32(CLR.textDim), topLabel)
    local vl = imgui.CalcTextSize(valStr)
    DL:AddText(imgui.ImVec2(x+10*MDS, y+h-vl.y-5*MDS), u32(valColor or CLR.text), valStr)
end

local function sectionTitle(DL, x, y, w, label)
    local ts = imgui.CalcTextSize(label)
    DL:AddText(imgui.ImVec2(x, y), u32(CLR.accent), label)
    DL:AddLine(
        imgui.ImVec2(x + ts.x + 6*MDS, y + ts.y*0.5),
        imgui.ImVec2(x + w, y + ts.y*0.5),
        u32(CLR.border), 1)
end

local function rowBg(DL, x, y, w, h)
    DL:AddRectFilled(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
        u32(imgui.ImVec4(1,1,1,0.04)), 4*MDS)
end

local WinMain   = imgui.new.bool(false)
local WinStats  = imgui.new.bool(false)
local WinFab    = imgui.new.bool(true)
local curPage   = 1

local _buf = {
    cot     = imgui.new.float[1](0),
    lin     = imgui.new.float[1](0),
    rar     = imgui.new.float[1](0),
    wat     = imgui.new.float[1](0),
    timer   = imgui.new.int[1](0),
    goalRes = imgui.new.int[1](0),
    goalMon = imgui.new.int[1](0),
}

-- Anti-admin photo-flicker overlay (ported from StrandShahta)
imgui.OnFrame(
    function() return os.clock() < S.imgUntil end,
    function(self)
        self.HideCursor = true
        if S.img == nil then
            if doesFileExist(S.imgPath) then
                local ok, t = pcall(imgui.CreateTextureFromFile, S.imgPath)
                if ok then S.img = t end
            end
            if S.img == nil then return end
        end
        local sw, sh = getScreenResolution()
        local w, h = sw * 0.6, sh * 0.6
        imgui.SetNextWindowPos(imgui.ImVec2((sw - w) * 0.5, (sh - h) * 0.5), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(w, h), imgui.Cond.Always)
        imgui.SetNextWindowBgAlpha(0)
        imgui.Begin('##sf_aaimg', nil, bit.bor(
            imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
            imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoBackground,
            imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoBringToFrontOnFocus,
            imgui.WindowFlags.NoSavedSettings))
        local a = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(os.clock() * 2.0))
        imgui.SetCursorPos(imgui.ImVec2(0, 0))
        imgui.Image(S.img, imgui.ImVec2(w, h), imgui.ImVec2(0, 0), imgui.ImVec2(1, 1),
            imgui.ImVec4(1, 1, 1, a))
        imgui.End()
    end
)

imgui.OnFrame(
    function() return WinFab[0] and not fabHidden end,
    function(self)
        self.HideCursor = true

        local bw  = 130*MDS
        local msw = 34*MDS
        local bh  = 46*MDS
        local gap = 4*MDS
        local totalW = bw + gap + msw
        local px = 28*MDS
        local py = resy * 0.72 - bh * 0.5

        imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(totalW, bh), imgui.Cond.Always)
        local fl = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
                 + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
                 + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoMove
        imgui.Begin('##fab', WinFab, fl)

        local DL  = imgui.GetWindowDrawList()
        local WP  = imgui.GetWindowPos()
        local pm  = pF(_fnt.main)
        local rnd = 8*MDS

        local isRun = farm.running
        local mx2, my2 = imgui.GetMousePos().x, imgui.GetMousePos().y
        local over = mx2 >= WP.x and mx2 <= WP.x+bw and my2 >= WP.y and my2 <= WP.y+bh

        DL:AddRectFilled(
            imgui.ImVec2(WP.x+2*MDS, WP.y+4*MDS),
            imgui.ImVec2(WP.x+bw+2*MDS, WP.y+bh+4*MDS),
            u32(imgui.ImVec4(0,0,0,0.55)), rnd)

        local baseBg = over and imgui.ImVec4(0.14,0.14,0.14,1) or imgui.ImVec4(0.07,0.07,0.07,1)
        DL:AddRectFilled(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+bw,WP.y+bh), u32(baseBg), rnd)

        if isRun then
            DL:AddRectFilledMultiColor(
                imgui.ImVec2(WP.x,    WP.y),
                imgui.ImVec2(WP.x+bw, WP.y+bh),
                u32(imgui.ImVec4(0.55,0.08,0.08, over and 0.90 or 0.70)),
                u32(imgui.ImVec4(0.15,0.05,0.05, over and 0.60 or 0.40)),
                u32(imgui.ImVec4(0.15,0.05,0.05, over and 0.60 or 0.40)),
                u32(imgui.ImVec4(0.55,0.08,0.08, over and 0.90 or 0.70)))
        else
            DL:AddRectFilledMultiColor(
                imgui.ImVec2(WP.x,    WP.y),
                imgui.ImVec2(WP.x+bw, WP.y+bh),
                u32(imgui.ImVec4(0.08,0.20,0.40, over and 0.90 or 0.70)),
                u32(imgui.ImVec4(0.30,0.08,0.08, over and 0.70 or 0.50)),
                u32(imgui.ImVec4(0.30,0.08,0.08, over and 0.70 or 0.50)),
                u32(imgui.ImVec4(0.08,0.20,0.40, over and 0.90 or 0.70)))
        end

        local brdC, txtC
        if isRun then
            brdC = over and imgui.ImVec4(1,0.30,0.30,0.90) or imgui.ImVec4(1,0.30,0.30,0.55)
            txtC = imgui.ImVec4(1,1,1,1)
        else
            brdC = over and imgui.ImVec4(0.40,0.65,1,0.80) or imgui.ImVec4(0.40,0.65,1,0.40)
            txtC = over and CLR.text or imgui.ImVec4(1,1,1,0.85)
        end
        DL:AddRect(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+bw,WP.y+bh), u32(brdC), rnd, 0, 1.5)

        local icon = isRun and fa['STOP'] or fa['PLAY']
        local lbl  = isRun and (icon..' '..u8'\xd1\xd2\xce\xcf') or (icon..' '..u8'\xd1\xd2\xc0\xd0\xd2')
        local pB   = pF(_fnt.main)
        local ts   = imgui.CalcTextSize(lbl)
        DL:AddText(imgui.ImVec2(WP.x+(bw-ts.x)*0.5, WP.y+(bh-ts.y)*0.5), u32(txtC), lbl)
        pFpop(pB)

        imgui.SetCursorPos(imgui.ImVec2(0, 0))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
        if imgui.Button('##fabclick', imgui.ImVec2(bw, bh)) then
            if not licenseOK then
                licWinOpen[0] = true
            elseif isRun then
                emergencyStop()
                sampAddChatMessage('{44dd44}[StrandFerma]: {ff4444}\xd1\xd2\xce\xcf',-1)
                saveCfg()
            else
                farm.running=true
                botTimerStart   = os.time()
                botSessionStart = os.time()
                antiAdminEnableTime = os.clock()
                movement.active=false
                sprintActive=farm.sprint
                setGameKeyState(1,0); stopSprint()
                watchdogLastTarget=os.clock()
                sampAddChatMessage('{44dd44}[StrandFerma]: {44ff44}\xd1\xd2\xc0\xd0\xd2',-1)
            end
        end
        imgui.PopStyleColor(3)

        local mbX = WP.x + bw + gap
        local mbY = WP.y
        local menuOpen = WinMain[0]
        local mxM, myM = imgui.GetMousePos().x, imgui.GetMousePos().y
        local overM = mxM >= mbX and mxM <= mbX+msw and myM >= mbY and myM <= mbY+bh

        DL:AddRectFilled(
            imgui.ImVec2(mbX+2*MDS, mbY+4*MDS),
            imgui.ImVec2(mbX+msw+2*MDS, mbY+bh+4*MDS),
            u32(imgui.ImVec4(0,0,0,0.55)), rnd)

        local mBg = menuOpen
            and (overM and CLR.accentH or CLR.accent)
            or  (overM and imgui.ImVec4(0.18,0.18,0.18,1) or imgui.ImVec4(0.09,0.09,0.09,1))
        DL:AddRectFilled(imgui.ImVec2(mbX,mbY), imgui.ImVec2(mbX+msw,mbY+bh), u32(mBg), rnd)

        DL:AddRectFilledMultiColor(
            imgui.ImVec2(mbX,     mbY),
            imgui.ImVec2(mbX+msw, mbY+bh),
            u32(imgui.ImVec4(0.106,0.157,0.216, menuOpen and 0.0 or 0.60)),
            u32(imgui.ImVec4(0.545,0.176,0.176, menuOpen and 0.0 or 0.60)),
            u32(imgui.ImVec4(0.545,0.176,0.176, menuOpen and 0.0 or 0.60)),
            u32(imgui.ImVec4(0.106,0.157,0.216, menuOpen and 0.0 or 0.60)))

        local mBrd = menuOpen
            and u32(CLR.accent)
            or  u32(overM and imgui.ImVec4(1,1,1,0.30) or imgui.ImVec4(1,1,1,0.10))
        DL:AddRect(imgui.ImVec2(mbX,mbY), imgui.ImVec2(mbX+msw,mbY+bh), mBrd, rnd, 0, 1.2)

        local pBm  = pF(_fnt.main)
        local mIc  = fa['BARS']
        local mIS  = imgui.CalcTextSize(mIc)
        local mIcC = menuOpen
            and u32(imgui.ImVec4(1,1,1,1))
            or  u32(overM and CLR.text or CLR.textDim)
        DL:AddText(imgui.ImVec2(mbX+(msw-mIS.x)*0.5, mbY+(bh-mIS.y)*0.5), mIcC, mIc)
        pFpop(pBm)

        imgui.SetCursorPos(imgui.ImVec2(bw+gap, 0))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
        if imgui.Button('##fabmenu', imgui.ImVec2(msw, bh)) then
            if not licenseOK then
                licWinOpen[0] = true
            else
                WinMain[0] = not WinMain[0]
            end
        end
        imgui.PopStyleColor(3)

        pFpop(pm)
        imgui.End()
    end
)

local function _renderPage1(DL, WP, cntX, cntY, cntW)
    local cy = cntY

    local elapsed = getBotElapsed()
    local timeStr = string.format('%02d:%02d:%02d',
        math.floor(elapsed/3600), math.floor((elapsed%3600)/60), elapsed%60)

    sfGifTick()
    local cg = 5*MDS; local ch = 46*MDS
    local cw = (cntW - cg*2) / 3

    if sfGifReady and #sfGifFrames > 0 then
        local tex = sfGifFrames[sfGifCurrent]
        if tex and tex ~= 0 then
            local gifRnd = 6 * MDS
            local col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1))
            DL:AddImageRounded(
                tex,
                imgui.ImVec2(cntX, cy),
                imgui.ImVec2(cntX + cw, cy + ch),
                imgui.ImVec2(0, 0), imgui.ImVec2(1, 1),
                col, gifRnd, imgui.DrawCornerFlags.All)
        end
    end

    drawStatCard(DL, cntX+cw+cg,    cy, cw, ch, u8'\xd1\xd2\xc0\xd2\xd3\xd1',
        farm.running and u8'\xd0\xc0\xc1\xce\xd2\xc0' or u8'\xd1\xd2\xce\xc8\xd2',
        farm.running and CLR.green or CLR.textDim)
    drawStatCard(DL, cntX+cw*2+cg*2,cy, cw, ch, u8'\xc1\xee\xf2 \xf0\xe0\xe1\xee\xf2\xe0\xeb', timeStr, imgui.ImVec4(0.88,0.96,0.56,1))
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, ch+6*MDS))
    cy = cy + ch + 8*MDS

    local rc  = farm.res_counter
    local cg2 = 5*MDS; local cw2 = (cntW-cg2)*0.5; local ch2 = 44*MDS
    drawStatCard(DL, cntX,        cy, cw2, ch2, u8'\xd5\xcb\xce\xcf', fmtNum(rc.cotton), imgui.ImVec4(0.95,0.88,0.55,1))
    drawStatCard(DL, cntX+cw2+cg2,cy, cw2, ch2, u8'\xcb\xa8\xcd',    fmtNum(rc.linen),  imgui.ImVec4(0.55,0.95,0.68,1))
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, ch2+5*MDS))
    cy = cy + ch2 + 7*MDS
    drawStatCard(DL, cntX,        cy, cw2, ch2, u8'\xd2\xca\xc0\xcd\xdc', fmtNum(rc.rare),  imgui.ImVec4(0.75,0.52,0.95,1))
    drawStatCard(DL, cntX+cw2+cg2,cy, cw2, ch2, u8'\xd3\xc3\xce\xcb\xdc',     fmtNum(rc.coal), CLR.coal)
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, ch2+8*MDS))
    cy = cy + ch2 + 8*MDS

    do
        local rh_ae = 34*MDS
        rowBg(DL, cntX, cy, cntW, rh_ae)

        local curAe, chAe = toggleRow(DL, cntX+8*MDS, cy+(rh_ae-22*MDS)*0.5, cntW-8*MDS,
            u8'\xc0\xe2\xf2\xee \xc5\xe4\xe0', autoEat)
        if chAe then
            autoEat = curAe
            saveCfg()
            if autoEat then
                lua_thread.create(function()
                    autoEatWaitSat = true
                    sampSendChat('/satiety')
                    local t = 0
                    while autoEatWaitSat and t < 60 do wait(100); t = t+1 end
                    autoEatWaitSat = false
                end)
            end
        end

        local toggleW_ae = 44*MDS
        local geSz       = 26*MDS
        local geX_ae     = cntX + cntW - 8*MDS - toggleW_ae - 6*MDS - geSz
        local geY_ae     = cy + (rh_ae - geSz)*0.5
        local mxG, myG   = imgui.GetMousePos().x, imgui.GetMousePos().y
        local geHov      = mxG >= geX_ae and mxG <= geX_ae+geSz and myG >= geY_ae and myG <= geY_ae+geSz
        DL:AddRectFilled(
            imgui.ImVec2(geX_ae, geY_ae), imgui.ImVec2(geX_ae+geSz, geY_ae+geSz),
            u32(autoEatSettingsOpen and CLR.accent or (geHov and imgui.ImVec4(1,1,1,0.12) or imgui.ImVec4(1,1,1,0.06))),
            4*MDS)
        local geIc2  = fa['GEAR']
        local geIS2  = imgui.CalcTextSize(geIc2)
        DL:AddText(
            imgui.ImVec2(geX_ae+(geSz-geIS2.x)*0.5, geY_ae+(geSz-geIS2.y)*0.5),
            u32(autoEatSettingsOpen and imgui.ImVec4(0.05,0.05,0.05,1) or (geHov and CLR.text or CLR.textDim)),
            geIc2)

        imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
        imgui.Dummy(imgui.ImVec2(cntW, rh_ae))
        imgui.SetCursorPos(imgui.ImVec2(geX_ae-WP.x, geY_ae-WP.y))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
        if imgui.Button('##ae_gear', imgui.ImVec2(geSz, geSz)) then
            autoEatSettingsOpen = not autoEatSettingsOpen
        end
        imgui.PopStyleColor(3)

        cy = cy + rh_ae + 6*MDS
    end

    local fabLbl = fabHidden
        and (fa['EYE']..' '..u8'\xcf\xce\xca\xc0\xc7\xc0\xd2\xdc \xca\xcd\xce\xcf\xca\xd3')
         or (fa['EYE_SLASH']..' '..u8'\xd1\xca\xd0\xdb\xd2\xdc \xca\xcd\xce\xcf\xca\xd3')
    if dlBtn(DL, cntX, cy, cntW, 28*MDS,
        imgui.ImVec4(0.08,0.08,0.08,1), imgui.ImVec4(0.14,0.14,0.14,1),
        fabLbl, CLR.textDim, 4*MDS) then
        fabHidden = not fabHidden; saveCfg()
    end
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, 28*MDS))
    cy = cy + 28*MDS + 8*MDS

    local btnH = 38*MDS; local rnd_ = 6*MDS
    local tgW   = (cntW * 0.45 - 5*MDS) * 0.5
    local btnW  = cntW - tgW*2 - 10*MDS

    do
        local mx_, my_ = imgui.GetMousePos().x, imgui.GetMousePos().y
        local over_ = mx_>=cntX and mx_<=cntX+btnW and my_>=cy and my_<=cy+btnH
        local bgBtn, bgHov, brdBtn, lblBtn, txtColBtn
        if farm.running then
            bgBtn     = imgui.ImVec4(0.65,0.07,0.07,1)
            bgHov     = imgui.ImVec4(0.85,0.12,0.12,1)
            brdBtn    = imgui.ImVec4(1.00,0.30,0.30,0.75)
            lblBtn    = fa['STOP']..' '..u8'\xd1\xd2\xce\xcf'
            txtColBtn = imgui.ImVec4(1,1,1,1)
        else
            bgBtn     = imgui.ImVec4(0.08,0.35,0.15,1)
            bgHov     = imgui.ImVec4(0.12,0.50,0.22,1)
            brdBtn    = imgui.ImVec4(0.20,0.82,0.40,0.55)
            lblBtn    = fa['PLAY']..' '..u8'\xd1\xd2\xc0\xd0\xd2'
            txtColBtn = imgui.ImVec4(0.85,1.00,0.88,1)
        end
        DL:AddRectFilled(imgui.ImVec2(cntX,cy), imgui.ImVec2(cntX+btnW,cy+btnH),
            u32(over_ and bgHov or bgBtn), rnd_)
        DL:AddRect(imgui.ImVec2(cntX,cy), imgui.ImVec2(cntX+btnW,cy+btnH),
            u32(brdBtn), rnd_, 0, 1.2)
        local pBig = pF(_fnt.big)
        local tsBtn = imgui.CalcTextSize(lblBtn)
        DL:AddText(imgui.ImVec2(cntX+(btnW-tsBtn.x)*0.5, cy+(btnH-tsBtn.y)*0.5),
            u32(txtColBtn), lblBtn)
        pFpop(pBig)
        imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
        if imgui.Button('##mainbtn', imgui.ImVec2(btnW, btnH)) then
            if not licenseOK then
                licWinOpen[0] = true
            elseif farm.running then
                emergencyStop()
                sampAddChatMessage('{44dd44}[StrandFerma]: {ff4444}\xd1\xd2\xce\xcf', -1)
                saveCfg()
            else
                farm.running    = true
                botTimerStart   = os.time()
                botSessionStart = os.time()
                antiAdminEnableTime = os.clock()
                movement.active = false
                sprintActive    = farm.sprint
                setGameKeyState(1,0); stopSprint()
                watchdogLastTarget = os.clock()
                sampAddChatMessage('{44dd44}[StrandFerma]: {44ff44}\xd1\xd2\xc0\xd0\xd2', -1)
            end
        end
        imgui.PopStyleColor(3)
    end

    local tgX1 = cntX + btnW + 5*MDS
    local tgX2 = tgX1 + tgW + 5*MDS
    if dlBtn(DL, tgX1, cy, tgW, btnH, CLR.tgBlue, CLR.tgH,
        fa['PAPER_PLANE'], CLR.text, rnd_) then
        openLink('https://t.me/strand_scripts')
    end
    local pSm2 = pF(_fnt.small)
    local chlbl = u8'\xca\xe0\xed\xe0\xeb'
    local chlS  = imgui.CalcTextSize(chlbl)
    DL:AddText(imgui.ImVec2(tgX1+(tgW-chlS.x)*0.5, cy+btnH+1*MDS), u32(CLR.textDim), chlbl)
    if dlBtn(DL, tgX2, cy, tgW, btnH,
        imgui.ImVec4(0.10,0.25,0.40,1), imgui.ImVec4(0.14,0.36,0.56,1),
        fa['USER'], CLR.text, rnd_) then
        openLink('https://t.me/victor_st0')
    end
    local aclbl = '@victor_st0'
    local aclS  = imgui.CalcTextSize(aclbl)
    DL:AddText(imgui.ImVec2(tgX2+(tgW-aclS.x)*0.5, cy+btnH+1*MDS), u32(CLR.textDim), aclbl)
    pFpop(pSm2)

    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, btnH+12*MDS))
    cy = cy + btnH + 14*MDS

    DL:AddLine(imgui.ImVec2(cntX, cy), imgui.ImVec2(cntX+cntW, cy), u32(CLR.border), 1)
    cy = cy + 7*MDS
    local authorLbl = u8'\xc0\xe2\xf2\xee\xf0: Victor Strand'
    local authorSz  = imgui.CalcTextSize(authorLbl)
    DL:AddText(imgui.ImVec2(cntX + (cntW-authorSz.x)*0.5, cy), u32(CLR.textDim), authorLbl)

end

local function _renderPage2(DL, WP, cntX, cntY, cntW)
    local cy = cntY
    local rh = 34*MDS
    local nv, changed

    sectionTitle(DL, cntX, cy, cntW, u8'\xd7\xd2\xce \xd1\xce\xc1\xc8\xd0\xc0\xc5\xcc')
    cy = cy + 20*MDS

    rowBg(DL, cntX, cy, cntW, rh)
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, rh))
    nv, changed = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
        u8'\xd5\xeb\xee\xef\xee\xea', farm.collect_cotton)
    if changed then farm.collect_cotton = nv; saveCfg() end
    cy = cy + rh + 5*MDS

    rowBg(DL, cntX, cy, cntW, rh)
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, rh))
    nv, changed = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
        u8'\xcb\xb8\xed', farm.collect_linen)
    if changed then farm.collect_linen = nv; saveCfg() end
    cy = cy + rh + 16*MDS

    sectionTitle(DL, cntX, cy, cntW, u8'\xcd\xc0\xd1\xd2\xd0\xce\xc9\xca\xc8')
    cy = cy + 20*MDS

    rowBg(DL, cntX, cy, cntW, rh)
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, rh))
    nv, changed = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
        u8'\xc1\xe5\xe6\xe0\xf2\xfc \xea \xf1\xee\xe7\xf0\xe5\xe2\xe0\xfe\xf9\xe5\xec\xf3', farm.goto_soonest)
    if changed then farm.goto_soonest = nv; saveCfg() end
    cy = cy + rh + 5*MDS

    rowBg(DL, cntX, cy, cntW, rh)
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, rh))
    local curRun, chRun = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
        u8'\xc1\xe5\xe3 (Run)', runActive)
    if chRun then runActive = curRun; applyRunTired() end
    cy = cy + rh + 5*MDS

    rowBg(DL, cntX, cy, cntW, rh)
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, rh))
    local curCol, chCol = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
        u8'\xce\xf2\xea\xeb. \xea\xee\xeb\xeb\xe8\xe7\xe8\xfe', collisionEnabled)
    if chCol then
        collisionEnabled = curCol
        enableCollision()
    end
    cy = cy + rh + 5*MDS

    rowBg(DL, cntX, cy, cntW, rh)
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, rh))

    local ajLbl = u8'\xc0\xe2\xf2\xee-\xef\xf0\xfb\xe6\xee\xea'
    local ajLS  = imgui.CalcTextSize(ajLbl)
    DL:AddText(imgui.ImVec2(cntX+8*MDS, cy+(rh-ajLS.y)*0.5), u32(CLR.text), ajLbl)

    local toggleW = 44*MDS
    local inpJW   = 62*MDS
    local gap     = 6*MDS

    local curJump, chJump = toggleRow(DL,
        cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
        '', autoJump)
    if chJump then
        autoJump = curJump
        if autoJump then startAutoJump() else stopAutoJump() end
        saveCfg()
    end

    if not _ajBuf then _ajBuf = imgui.new.int[1](autoJumpInterval) end

    local btnSz  = 22*MDS
    local numW   = 28*MDS
    local secLbl = u8'\xf1\xe5\xea'
    local secLS  = imgui.CalcTextSize(secLbl)
    local numLbl = tostring(autoJumpInterval)
    local numLS  = imgui.CalcTextSize(numLbl)

    local blockR = cntX + cntW - 8*MDS - toggleW - gap
    local plusX  = blockR - btnSz
    local numX   = plusX - numW
    local minX   = numX - btnSz
    local secX   = minX - secLS.x - 6*MDS
    local midY   = cy + rh * 0.5

    DL:AddText(imgui.ImVec2(secX, midY - secLS.y*0.5), u32(CLR.textDim), secLbl)

    local mxM, myM = imgui.GetMousePos().x, imgui.GetMousePos().y
    local hovMin = mxM>=minX and mxM<=minX+btnSz and myM>=cy and myM<=cy+rh
    local hovPls = mxM>=plusX and mxM<=plusX+btnSz and myM>=cy and myM<=cy+rh
    DL:AddRectFilled(imgui.ImVec2(minX, midY-btnSz*0.5),
        imgui.ImVec2(minX+btnSz, midY+btnSz*0.5),
        u32(hovMin and CLR.accentH or imgui.ImVec4(0.18,0.18,0.18,1)), 4*MDS)
    local minIcon = imgui.CalcTextSize('-')
    DL:AddText(imgui.ImVec2(minX+(btnSz-minIcon.x)*0.5, midY-minIcon.y*0.5),
        u32(CLR.text), '-')

    DL:AddText(imgui.ImVec2(numX+(numW-numLS.x)*0.5, midY-numLS.y*0.5),
        u32(CLR.text), numLbl)

    DL:AddRectFilled(imgui.ImVec2(plusX, midY-btnSz*0.5),
        imgui.ImVec2(plusX+btnSz, midY+btnSz*0.5),
        u32(hovPls and CLR.accentH or imgui.ImVec4(0.18,0.18,0.18,1)), 4*MDS)
    local plusIcon = imgui.CalcTextSize('+')
    DL:AddText(imgui.ImVec2(plusX+(btnSz-plusIcon.x)*0.5, midY-plusIcon.y*0.5),
        u32(CLR.text), '+')

    imgui.SetCursorPos(imgui.ImVec2(minX-WP.x, midY-btnSz*0.5-WP.y))
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
    if imgui.Button('##ajm', imgui.ImVec2(btnSz, btnSz)) then
        autoJumpInterval = math.max(2, autoJumpInterval - 1)
        _ajBuf[0] = autoJumpInterval
        if autoJump then startAutoJump() end
        saveCfg()
    end
    imgui.SetCursorPos(imgui.ImVec2(plusX-WP.x, midY-btnSz*0.5-WP.y))
    if imgui.Button('##ajp', imgui.ImVec2(btnSz, btnSz)) then
        autoJumpInterval = math.min(180, autoJumpInterval + 1)
        _ajBuf[0] = autoJumpInterval
        if autoJump then startAutoJump() end
        saveCfg()
    end
    imgui.PopStyleColor(3)

    cy = cy + rh + 5*MDS

    if autoJump then
        local jcLbl = string.format(u8('\xcf\xf0\xfb\xe6\xea\xee\xe2: %d'), autoJumpCount)
        local jcS   = imgui.CalcTextSize(jcLbl)
        DL:AddText(imgui.ImVec2(cntX+8*MDS, cy), u32(CLR.green), jcLbl)
        cy = cy + jcS.y + 3*MDS
    end

end

local function _renderPage3(DL, WP, cntX, cntY, cntW)
    local cy = cntY
    local rh = 34*MDS
    local nv, changed

    sectionTitle(DL, cntX, cy, cntW, u8'\xc7\xc0\xd9\xc8\xd2\xc0')
    cy = cy + 20*MDS

    local guards = {
        { u8'\xd1\xf2\xee\xef \xef\xf0\xe8 \xe4\xe8\xe0\xeb\xee\xe3\xe5',         'stop_on_dialog' },
        { u8'\xd1\xf2\xee\xef \xef\xf0\xe8 \xf2\xe5\xeb\xe5\xef\xee\xf0\xf2\xe5', 'stop_on_tp'     },
        { u8'\xd1\xf2\xee\xef \xef\xf0\xe8 \xef\xf0\xee\xe2\xe5\xf0\xea\xe5',     'stop_on_chat'   },
        { u8'\xc2\xfb\xf5\xee\xe4 \xe8\xe7 \xe8\xe3\xf0\xfb',                     'quit_on_stop'   },
    }
    for _, g in ipairs(guards) do
        rowBg(DL, cntX, cy, cntW, rh)
        imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
        imgui.Dummy(imgui.ImVec2(cntW, rh))
        nv, changed = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
            g[1], farm[g[2]])
        if changed then
            farm[g[2]] = nv; saveCfg()
            if nv and g[2] ~= 'quit_on_stop' then
                antiAdminEnableTime = os.clock()
            end
        end
        cy = cy + rh + 5*MDS
    end

    rowBg(DL, cntX, cy, cntW, rh)
    imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
    imgui.Dummy(imgui.ImVec2(cntW, rh))
    local aaLbl = u8'\xc0\xe2\xf2\xee-\xee\xf2\xe2\xe5\xf2 \xe0\xe4\xec\xe8\xed\xf3'
    local nv_aa, ch_aa = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS, aaLbl, aaState)
    if ch_aa then aaState = nv_aa; saveCfg() end
    cy = cy + rh + 5*MDS

end

local function _renderPage4(DL, WP, cntX, cntY, cntW)
        local cy = cntY
        local rh3 = 34*MDS

        sectionTitle(DL, cntX, cy, cntW, u8'\xd6\xc5\xcd\xdb ($)')
        cy = cy + 20*MDS

        local labels = {
            u8'\xd5\xeb\xee\xef\xee\xea:',
            u8'\xcb\xb8\xed:',
            u8'\xd2\xea\xe0\xed\xfc:',
            u8'\xd3\xe3\xee\xeb\xfc:',
        }
        local bufs   = { _buf.cot, _buf.lin, _buf.rar, _buf.wat }
        local fields = { 'price_cotton','price_linen','price_rare','price_coal' }
        local fcolors = {
            imgui.ImVec4(0.95,0.88,0.55,1),
            imgui.ImVec4(0.55,0.95,0.68,1),
            imgui.ImVec4(0.75,0.52,0.95,1),
            CLR.coal,
        }
        for i = 1, 4 do
            rowBg(DL, cntX, cy, cntW, rh3)
            local lbl3 = imgui.CalcTextSize(labels[i])
            DL:AddText(imgui.ImVec2(cntX+8*MDS, cy+(rh3-lbl3.y)*0.5), u32(fcolors[i]), labels[i])
            imgui.SetCursorPos(imgui.ImVec2(cntX+cntW-80*MDS-WP.x, cy+(rh3-22*MDS)*0.5-WP.y))
            imgui.SetNextItemWidth(80*MDS)
            if imgui.InputFloat('##pf'..i, bufs[i], 0, 0, '%.0f') then
                calc[fields[i]] = bufs[i][0]
            end
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh3))
            cy = cy + rh3 + 5*MDS
        end

        cy = cy + 10*MDS

        rowBg(DL, cntX, cy, cntW, rh3)
        imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
        imgui.Dummy(imgui.ImVec2(cntW, rh3))
        local nv_an, ch_an = toggleRow(DL, cntX+8*MDS, cy+(rh3-22*MDS)*0.5, cntW-8*MDS,
            u8'/anims \xe2 \xf7\xe0\xf2 (\xea\xe0\xe6\xe4\xfb\xe5 5 \xec\xe8\xed)', autoAnims)
        if ch_an then autoAnims = nv_an; saveCfg() end
        cy = cy + rh3 + 5*MDS

        cy = cy + 4*MDS
        local bw5 = (cntW-6*MDS)*0.5
        if dlBtn(DL, cntX, cy, bw5, 34*MDS,
            imgui.ImVec4(0.08,0.08,0.08,1), imgui.ImVec4(0.15,0.15,0.15,1),
            fa['FLOPPY_DISK']..' '..u8'\xd1\xee\xf5\xf0\xe0\xed\xe8\xf2\xfc', CLR.accent, 4*MDS) then
            saveCfg()
        end
        if dlBtn(DL, cntX+bw5+6*MDS, cy, bw5, 34*MDS,
            imgui.ImVec4(0.20,0.05,0.05,1), imgui.ImVec4(0.40,0.09,0.09,1),
            fa['ROTATE_LEFT']..' '..u8'\xd1\xe1\xf0\xee\xf1', CLR.red, 4*MDS) then
            calc.price_cotton=0; calc.price_linen=0; calc.price_rare=0; calc.price_coal=0
            _buf.cot[0]=0; _buf.lin[0]=0; _buf.rar[0]=0; _buf.wat[0]=0
            saveCfg()
        end
        imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
        imgui.Dummy(imgui.ImVec2(cntW, 34*MDS))
    end

imgui.OnFrame(
    function() return WinMain[0] end,
    function(self)
        self.HideCursor = true

        local W = math.min(resx*0.88, 480*MDS)
        local H = math.min(resy*0.82, 510*MDS)

        imgui.SetNextWindowPos(imgui.ImVec2(resx*0.5, resy*0.5),
            imgui.Cond.FirstUseEver, imgui.ImVec2(0.5,0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(W,H), imgui.Cond.Always)

        local fl = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
                 + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
                 + imgui.WindowFlags.NoBackground
        imgui.PushStyleColor(imgui.Col.WindowBg,    imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border,       imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.BorderShadow, imgui.ImVec4(0,0,0,0))
        imgui.Begin('##na_main', WinMain, fl)

        local DL = imgui.GetWindowDrawList()
        local WP = imgui.GetWindowPos()
        _mainWinPos = WP
        local pm = pF(_fnt.main)
        local WND_RND = 0

        local CORNERS_ALL    = 0xF
        local CORNERS_TOP    = 0x3
        local CORNERS_BOTTOM = 0xC

        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+H),
            u32(imgui.ImVec4(0.059,0.059,0.059,0.98)))
        DL:AddRect(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+W,WP.y+H),
            u32(CLR.border), 0, 0, 1.0)

        local hdrH = 48*MDS
        DL:AddRectFilled(
            imgui.ImVec2(WP.x, WP.y),
            imgui.ImVec2(WP.x+W, WP.y+hdrH),
            u32(imgui.ImVec4(0.086,0.102,0.129,1.00)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x,       WP.y),
            imgui.ImVec2(WP.x+W*0.5, WP.y+hdrH),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.90)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.90)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x+W*0.5, WP.y),
            imgui.ImVec2(WP.x+W,     WP.y+hdrH),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.00)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.90)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.90)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.00)))
        DL:AddLine(
            imgui.ImVec2(WP.x, WP.y+hdrH),
            imgui.ImVec2(WP.x+W, WP.y+hdrH),
            u32(CLR.border), 1)

        local titleX = WP.x + 14*MDS
        local pB1 = pF(_fnt.big)
        local strandS  = 'STRAND'
        local fermaS   = ' FERMA'
        local strandSz = imgui.CalcTextSize(strandS)
        local fermaSz  = imgui.CalcTextSize(fermaS)
        local titleY   = WP.y + hdrH*0.5 - strandSz.y*0.5
        DL:AddText(imgui.ImVec2(titleX, titleY),                u32(CLR.accent), strandS)
        DL:AddText(imgui.ImVec2(titleX+strandSz.x, titleY),     u32(CLR.text),   fermaS)
        pFpop(pB1)
        local verS  = ' | v3.0'
        local verSz = imgui.CalcTextSize(verS)
        DL:AddText(imgui.ImVec2(titleX+strandSz.x+fermaSz.x, WP.y+hdrH*0.5-verSz.y*0.5+1*MDS),
            u32(CLR.textDim), verS)

        local stTxt = farm.running and u8'\xd0\xc0\xc1\xce\xd2\xc0' or u8'\xce\xc6\xc8\xc4\xc0\xcd\xc8\xc5'
        local stCol = farm.running and CLR.green or CLR.textDim
        local stSz  = imgui.CalcTextSize(stTxt)

        local clSz = 26*MDS
        local clX  = WP.x + W - clSz - 14*MDS
        local clY2 = WP.y + (hdrH - clSz)*0.5
        local mx0, my0 = imgui.GetMousePos().x, imgui.GetMousePos().y
        local clHov = mx0>=clX and mx0<=clX+clSz and my0>=clY2 and my0<=clY2+clSz
        DL:AddRectFilled(imgui.ImVec2(clX,clY2), imgui.ImVec2(clX+clSz,clY2+clSz),
            u32(clHov and CLR.accent or imgui.ImVec4(1,1,1,0.10)), 4*MDS)
        local xS = imgui.CalcTextSize('x')
        DL:AddText(imgui.ImVec2(clX+(clSz-xS.x)*0.5, clY2+(clSz-xS.y)*0.5),
            u32(clHov and CLR.text or imgui.ImVec4(1,1,1,0.60)), 'x')
        if clHov and imgui.IsMouseClicked(0) then WinMain[0] = false end

        local stX   = clX - stSz.x - 18*MDS
        local stY   = WP.y + hdrH*0.5 - stSz.y*0.5
        DL:AddCircleFilled(imgui.ImVec2(stX-7*MDS, WP.y+hdrH*0.5), 3.5*MDS, u32(stCol))
        DL:AddText(imgui.ImVec2(stX, stY), u32(stCol), stTxt)

        local sticSz = 26*MDS
        local sticX  = stX - sticSz - 10*MDS
        local sticY  = WP.y + (hdrH - sticSz)*0.5
        local mxSt, mySt = imgui.GetMousePos().x, imgui.GetMousePos().y
        local sticHov = mxSt>=sticX and mxSt<=sticX+sticSz and mySt>=sticY and mySt<=sticY+sticSz
        DL:AddRectFilled(imgui.ImVec2(sticX,sticY), imgui.ImVec2(sticX+sticSz,sticY+sticSz),
            u32(WinStats[0] and CLR.accent or (sticHov and imgui.ImVec4(1,1,1,0.12) or imgui.ImVec4(1,1,1,0.06))), 4*MDS)
        local sticIc = fa['CHART_BAR']
        local sticIS = imgui.CalcTextSize(sticIc)
        DL:AddText(imgui.ImVec2(sticX+(sticSz-sticIS.x)*0.5, sticY+(sticSz-sticIS.y)*0.5),
            u32(WinStats[0] and imgui.ImVec4(0.05,0.05,0.05,1) or CLR.textDim), sticIc)
        if sticHov and imgui.IsMouseClicked(0) then WinStats[0] = not WinStats[0] end

        local tabsH  = 42*MDS
        local tabsY  = WP.y + hdrH
        DL:AddRectFilled(imgui.ImVec2(WP.x, tabsY), imgui.ImVec2(WP.x+W, tabsY+tabsH),
            u32(imgui.ImVec4(0,0,0,0.30)))
        DL:AddLine(imgui.ImVec2(WP.x, tabsY+tabsH), imgui.ImVec2(WP.x+W, tabsY+tabsH),
            u32(CLR.border), 1)

        local TAB_LABELS = {
            u8'\xc3\xcb\xc0\xc2\xcd\xc0\xdf',
            u8'\xd1\xc1\xce\xd0',
            u8'\xc7\xc0\xd9\xc8\xd2\xc0',
            u8'\xce\xcf\xd6\xc8\xc8',
        }
        local tabPadX = 14*MDS
        local tabH2   = tabsH - 2*MDS
        local tabW = (W - tabPadX*2) / #TAB_LABELS
        for i, lbl in ipairs(TAB_LABELS) do
            local tx2 = WP.x + tabPadX + (i-1)*tabW
            local ty2 = tabsY + 2*MDS
            local isAT = (curPage == i)
            local mxT, myT = imgui.GetMousePos().x, imgui.GetMousePos().y
            local hovT = mxT>=tx2 and mxT<=tx2+tabW and myT>=ty2 and myT<=ty2+tabH2
            if isAT then
                DL:AddRectFilled(imgui.ImVec2(tx2+3*MDS, ty2), imgui.ImVec2(tx2+tabW-3*MDS, ty2+tabH2),
                    u32(imgui.ImVec4(1,1,1,1)), 4*MDS)
            elseif hovT then
                DL:AddRectFilled(imgui.ImVec2(tx2+3*MDS, ty2), imgui.ImVec2(tx2+tabW-3*MDS, ty2+tabH2),
                    u32(imgui.ImVec4(1,1,1,0.08)), 4*MDS)
            end
            local pSm = pF(_fnt.small)
            local tS3 = imgui.CalcTextSize(lbl)
            DL:AddText(
                imgui.ImVec2(tx2 + (tabW - tS3.x)*0.5, ty2 + (tabH2 - tS3.y)*0.5),
                u32(isAT and imgui.ImVec4(0.05,0.05,0.05,1) or (hovT and CLR.text or CLR.textDim)),
                lbl)
            pFpop(pSm)
            if hovT and imgui.IsMouseClicked(0) then curPage = i end
        end

        local bodyY  = tabsY + tabsH + 1
        local cntPad = 16*MDS
        local sideTabW = 44*MDS
        local sideTabX = WP.x
        local sideBodyY = bodyY
        local sideBodyH = H - (bodyY - WP.y)
        DL:AddRectFilled(imgui.ImVec2(sideTabX, sideBodyY),
            imgui.ImVec2(sideTabX+sideTabW, sideBodyY+sideBodyH),
            u32(imgui.ImVec4(0,0,0,0.20)))
        DL:AddLine(imgui.ImVec2(sideTabX+sideTabW, sideBodyY),
            imgui.ImVec2(sideTabX+sideTabW, sideBodyY+sideBodyH),
            u32(CLR.border), 1)
        local SIDE_TABS = {
            { fa['BULLSEYE'], u8'\xd6\xc5\xcb\xdc' },
        }
        local stBtnSz = 36*MDS
        local stBtnPad = 4*MDS
        for i, st in ipairs(SIDE_TABS) do
            local stY = sideBodyY + stBtnPad + (i-1)*(stBtnSz+stBtnPad)
            local stX = sideTabX + (sideTabW-stBtnSz)*0.5
            local isST = (goal.sideTab == i)
            local mxSB, mySB = imgui.GetMousePos().x, imgui.GetMousePos().y
            local hovST = mxSB>=stX and mxSB<=stX+stBtnSz and mySB>=stY and mySB<=stY+stBtnSz
            DL:AddRectFilled(imgui.ImVec2(stX,stY), imgui.ImVec2(stX+stBtnSz,stY+stBtnSz),
                u32(isST and CLR.accent or (hovST and imgui.ImVec4(1,1,1,0.10) or imgui.ImVec4(0,0,0,0))),
                6*MDS)
            local pSmS = pF(_fnt.small)
            local icS  = imgui.CalcTextSize(st[1])
            DL:AddText(imgui.ImVec2(stX+(stBtnSz-icS.x)*0.5, stY+(stBtnSz-icS.y)*0.5),
                u32(isST and imgui.ImVec4(0.05,0.05,0.05,1) or (hovST and CLR.text or CLR.textDim)),
                st[1])
            pFpop(pSmS)
            imgui.SetCursorPos(imgui.ImVec2(stX-WP.x, stY-WP.y))
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
            if imgui.Button('##stab'..i, imgui.ImVec2(stBtnSz, stBtnSz)) then
                goal.sideTab = (goal.sideTab == i) and 0 or i
            end
            imgui.PopStyleColor(3)
        end

        local cntX   = WP.x + sideTabW + cntPad
        local cntY   = bodyY + 10*MDS
        local cntW   = W - sideTabW - cntPad*2

        if goal.sideTab == 1 then
            local cy = cntY
            local rh = 34*MDS

            sectionTitle(DL, cntX, cy, cntW, u8'\xd6\xc5\xcb\xdc \xd1\xc1\xce\xd0\xc0')
            cy = cy + 20*MDS

            local modeLabels = {
                u8'\xce\xf2\xea\xeb\xfe\xf7\xe5\xed\xee',
                u8'\xcf\xee \xea\xee\xeb-\xf2\xe2\xf3 \xf0\xe5\xf1\xf3\xf0\xf1\xe0',
                u8'\xcf\xee \xf1\xf3\xec\xec\xe5 \xe4\xe5\xed\xe5\xe3',
            }
            local rdSz = 11*MDS
            for mi = 0, 2 do
                rowBg(DL, cntX, cy, cntW, rh)
                local midYm = cy + rh*0.5
                local selM  = (goal.mode == mi)
                local rdXm  = cntX + 8*MDS + rdSz*0.5
                if selM then
                    DL:AddCircleFilled(imgui.ImVec2(rdXm,midYm), rdSz*0.5, u32(CLR.accent))
                    DL:AddCircleFilled(imgui.ImVec2(rdXm,midYm), rdSz*0.5-2*MDS, u32(imgui.ImVec4(0.059,0.059,0.059,1)))
                    DL:AddCircleFilled(imgui.ImVec2(rdXm,midYm), rdSz*0.5-4*MDS, u32(CLR.accent))
                else
                    DL:AddCircle(imgui.ImVec2(rdXm,midYm), rdSz*0.5, u32(CLR.textDim), 24, 1.2)
                end
                local pmM2 = pF(_fnt.small)
                local fSM2 = imgui.CalcTextSize(modeLabels[mi+1])
                DL:AddText(imgui.ImVec2(cntX+8*MDS+rdSz+6*MDS, midYm-fSM2.y*0.5),
                    u32(selM and CLR.text or CLR.textDim), modeLabels[mi+1])
                pFpop(pmM2)
                imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
                imgui.Dummy(imgui.ImVec2(cntW, rh))
                imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
                if imgui.Button('##gmode'..mi, imgui.ImVec2(cntW, rh)) then
                    goal.mode = mi; goal.reached = false; saveCfg()
                end
                imgui.PopStyleColor(3)
                cy = cy + rh + 3*MDS
            end

            cy = cy + 6*MDS

            if goal.mode == 1 then
                sectionTitle(DL, cntX, cy, cntW, u8'\xd2\xc8\xcf \xd0\xc5\xd1\xd3\xd0\xd1\xc0')
                cy = cy + 18*MDS
                local resLabels = {
                    { u8'\xd5\xeb\xee\xef\xee\xea', imgui.ImVec4(0.95,0.88,0.55,1) },
                    { u8'\xcb\xb8\xed',              imgui.ImVec4(0.55,0.95,0.68,1) },
                    { u8'\xd2\xea\xe0\xed\xfc',      imgui.ImVec4(0.75,0.52,0.95,1) },
                    { u8'\xd3\xe3\xee\xeb\xfc',      CLR.coal },
                }
                local rbtnW = (cntW - 5*MDS*3) / 4
                for ri = 0, 3 do
                    local rbX = cntX + ri*(rbtnW+5*MDS)
                    local isR = (goal.resType == ri)
                    local col = resLabels[ri+1][2]
                    DL:AddRectFilled(imgui.ImVec2(rbX,cy), imgui.ImVec2(rbX+rbtnW,cy+28*MDS),
                        u32(isR and imgui.ImVec4(col.x,col.y,col.z,0.25) or imgui.ImVec4(0.10,0.10,0.10,1)),
                        4*MDS)
                    DL:AddRect(imgui.ImVec2(rbX,cy), imgui.ImVec2(rbX+rbtnW,cy+28*MDS),
                        u32(isR and col or imgui.ImVec4(1,1,1,0.12)), 4*MDS, 0, isR and 1.5 or 1.0)
                    local pmR = pF(_fnt.small)
                    local rsZ = imgui.CalcTextSize(resLabels[ri+1][1])
                    DL:AddText(imgui.ImVec2(rbX+(rbtnW-rsZ.x)*0.5, cy+(28*MDS-rsZ.y)*0.5),
                        u32(isR and col or CLR.textDim), resLabels[ri+1][1])
                    pFpop(pmR)
                    imgui.SetCursorPos(imgui.ImVec2(rbX-WP.x, cy-WP.y))
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
                    if imgui.Button('##grt'..ri, imgui.ImVec2(rbtnW, 28*MDS)) then
                        goal.resType = ri
                        goal.resAmount = goal.resAmounts[ri + 1]
                        _buf.goalRes[0] = goal.resAmount
                        goal.reached = false; saveCfg()
                    end
                    imgui.PopStyleColor(3)
                end
                cy = cy + 28*MDS + 10*MDS

                sectionTitle(DL, cntX, cy, cntW, u8'\xca\xce\xcb-\xd2\xc2\xce \xd0\xc5\xd1\xd3\xd0\xd1\xc0')
                cy = cy + 18*MDS
                rowBg(DL, cntX, cy, cntW, rh)
                local rc = farm.res_counter
                local curRes = rc.cotton
                if goal.resType==1 then curRes=rc.linen elseif goal.resType==2 then curRes=rc.rare elseif goal.resType==3 then curRes=rc.coal end
                local progLbl = string.format('%d / %d', curRes, math.max(1, goal.resAmount))
                local plS = imgui.CalcTextSize(progLbl)
                DL:AddText(imgui.ImVec2(cntX+8*MDS, cy+(rh-plS.y)*0.5), u32(CLR.textDim), progLbl)
                imgui.SetCursorPos(imgui.ImVec2(cntX+cntW-120*MDS-WP.x, cy+(rh-22*MDS)*0.5-WP.y))
                imgui.SetNextItemWidth(120*MDS)
                if imgui.InputInt('##gra', _buf.goalRes, 10, 100) then
                    if _buf.goalRes[0] < 0 then _buf.goalRes[0] = 0 end
                    goal.resAmount = _buf.goalRes[0]
                    goal.resAmounts[goal.resType + 1] = goal.resAmount
                    goal.reached = false
                end
                imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
                imgui.Dummy(imgui.ImVec2(cntW, rh))
                cy = cy + rh + 5*MDS

                if goal.resAmount > 0 then
                    local prog = math.min(1.0, curRes / goal.resAmount)
                    local pbH = 8*MDS
                    DL:AddRectFilled(imgui.ImVec2(cntX,cy), imgui.ImVec2(cntX+cntW,cy+pbH),
                        u32(imgui.ImVec4(0.15,0.15,0.15,1)), pbH*0.5)
                    DL:AddRectFilled(imgui.ImVec2(cntX,cy), imgui.ImVec2(cntX+cntW*prog,cy+pbH),
                        u32(CLR.green), pbH*0.5)
                    cy = cy + pbH + 8*MDS
                end

            elseif goal.mode == 2 then
                sectionTitle(DL, cntX, cy, cntW, u8'\xd1\xd3\xcc\xcc\xc0 ($)')
                cy = cy + 18*MDS
                rowBg(DL, cntX, cy, cntW, rh)
                local rc2 = farm.res_counter
                local totalM = rc2.cotton*calc.price_cotton + rc2.linen*calc.price_linen
                             + rc2.rare*calc.price_rare + rc2.coal*calc.price_coal
                local mprogLbl = fmtNum(totalM)..'$ / '..fmtNum(math.max(1,goal.money))..'$'
                local mpS = imgui.CalcTextSize(mprogLbl)
                DL:AddText(imgui.ImVec2(cntX+8*MDS, cy+(rh-mpS.y)*0.5), u32(CLR.green), mprogLbl)
                imgui.SetCursorPos(imgui.ImVec2(cntX+cntW-120*MDS-WP.x, cy+(rh-22*MDS)*0.5-WP.y))
                imgui.SetNextItemWidth(120*MDS)
                if imgui.InputInt('##gmon', _buf.goalMon, 40000, 200000) then
                    if _buf.goalMon[0] < 0 then _buf.goalMon[0] = 0 end
                    goal.money = _buf.goalMon[0]; goal.reached = false
                end
                imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
                imgui.Dummy(imgui.ImVec2(cntW, rh))
                cy = cy + rh + 5*MDS

                if goal.money > 0 then
                    local prog2 = math.min(1.0, totalM / goal.money)
                    local pbH2 = 8*MDS
                    DL:AddRectFilled(imgui.ImVec2(cntX,cy), imgui.ImVec2(cntX+cntW,cy+pbH2),
                        u32(imgui.ImVec4(0.15,0.15,0.15,1)), pbH2*0.5)
                    DL:AddRectFilled(imgui.ImVec2(cntX,cy), imgui.ImVec2(cntX+cntW*prog2,cy+pbH2),
                        u32(CLR.green), pbH2*0.5)
                    cy = cy + pbH2 + 8*MDS
                end
            end

            cy = cy + 6*MDS
            DL:AddLine(imgui.ImVec2(cntX,cy), imgui.ImVec2(cntX+cntW,cy), u32(CLR.border), 1)
            cy = cy + 10*MDS

            sectionTitle(DL, cntX, cy, cntW, u8'\xd2\xc0\xc9\xcc\xc5\xd0 \xce\xd1\xd2\xc0\xcd\xce\xc2\xca\xc8 (\xcc\xc8\xcd)')
            cy = cy + 18*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            local lblT2 = imgui.CalcTextSize(u8'\xd2\xe0\xe9\xec\xe5\xf0:')
            DL:AddText(imgui.ImVec2(cntX+8*MDS, cy+(rh-lblT2.y)*0.5), u32(CLR.textDim), u8'\xd2\xe0\xe9\xec\xe5\xf0:')
            local inpW2 = 110*MDS
            local inpX2 = cntX + cntW - inpW2 - 8*MDS
            local inpY2 = cy + (rh-22*MDS)*0.5
            imgui.SetCursorPos(imgui.ImVec2(inpX2-WP.x, inpY2-WP.y))
            imgui.SetNextItemWidth(inpW2)
            if imgui.InputInt('##btimer2', _buf.timer, 1, 10) then
                if _buf.timer[0] < 0 then _buf.timer[0] = 0 end
                botTimerMinutes = _buf.timer[0]
            end
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            cy = cy + rh + 3*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            local nv_qt2, ch_qt2 = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                u8'\xc2\xfb\xe9\xf2\xe8 \xe8\xe7 \xe8\xe3\xf0\xfb \xef\xee \xf1\xf0\xe0\xe1\xe0\xf2\xfb\xe2\xe0\xed\xe8\xfe', quitOnTimer)
            if ch_qt2 then quitOnTimer = nv_qt2; saveCfg() end
            cy = cy + rh + 5*MDS

            if farm.running and botTimerMinutes > 0 and botTimerStart > 0 then
                local elT2 = os.time() - botTimerStart
                local rem2 = math.max(0, botTimerMinutes*60 - elT2)
                local remS2 = string.format(u8('\xce\xf1\xf2\xe0\xeb\xee\xf1\xfc: %02d:%02d'),
                    math.floor(rem2/60), rem2%60)
                DL:AddText(imgui.ImVec2(cntX+8*MDS, cy), u32(CLR.orange), remS2)
                cy = cy + 24*MDS
            end

            cy = cy + 4*MDS
            local bwG = (cntW-6*MDS)*0.5
            if dlBtn(DL, cntX, cy, bwG, 34*MDS,
                imgui.ImVec4(0.08,0.08,0.08,1), imgui.ImVec4(0.15,0.15,0.15,1),
                fa['FLOPPY_DISK']..' '..u8'\xd1\xee\xf5\xf0\xe0\xed\xe8\xf2\xfc', CLR.accent, 4*MDS) then
                saveCfg()
                addLog(u8'[\xd6\xe5\xeb\xfc] \xd1\xee\xf5\xf0\xe0\xed\xe5\xed\xee')
            end
            if dlBtn(DL, cntX+bwG+6*MDS, cy, bwG, 34*MDS,
                imgui.ImVec4(0.20,0.05,0.05,1), imgui.ImVec4(0.40,0.09,0.09,1),
                fa['ROTATE_LEFT']..' '..u8'\xd1\xe1\xf0\xee\xf1 \xd6\xe5\xeb\xe8', CLR.red, 4*MDS) then
                goal.mode = 0; goal.resAmount = 0; goal.resAmounts = {0,0,0,0}; goal.money = 0; goal.reached = false
                _buf.goalRes[0] = 0; _buf.goalMon[0] = 0; saveCfg()
            end
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, 34*MDS))

        elseif goal.sideTab == nil then
        else
            if curPage == 1 then _renderPage1(DL, WP, cntX, cntY, cntW)
            elseif curPage == 2 then _renderPage2(DL, WP, cntX, cntY, cntW)
            elseif curPage == 3 then _renderPage3(DL, WP, cntX, cntY, cntW)
            elseif curPage == 4 then _renderPage4(DL, WP, cntX, cntY, cntW)
            end
        end

        pFpop(pm)
        imgui.End()
        imgui.PopStyleColor(3)
    end
)

imgui.OnFrame(
    function() return true end,
    function(self)
        self.HideCursor = true
        local fdl = imgui.GetForegroundDrawList()

        if farm.target then
            local tx, ty, tz = farm.target[1], farm.target[2], farm.target[3]
            local ok, ox, oy, oz = pcall(getCharCoordinates, PLAYER_PED)
            if ok and type(ox) == 'number' then
                if isPointOnScreen(tx, ty, tz, 1) then
                    local sx1, sy1 = convert3DCoordsToScreen(ox, oy, oz)
                    local sx2, sy2 = convert3DCoordsToScreen(tx, ty, tz)
                    if sx1 and sy1 and sx2 and sy2 then
                        if larekIsWalking then
                            fdl:AddLine(imgui.ImVec2(sx1,sy1), imgui.ImVec2(sx2,sy2), 0x44FF8800, 10)
                            fdl:AddLine(imgui.ImVec2(sx1,sy1), imgui.ImVec2(sx2,sy2), 0xEEFF8800, 4)
                            fdl:AddCircleFilled(imgui.ImVec2(sx2,sy2), 6*MDS, 0xFFFFFFFF)
                            fdl:AddCircleFilled(imgui.ImVec2(sx2,sy2), 4*MDS, 0xCCFF8800)
                        elseif farm.running then
                            fdl:AddLine(imgui.ImVec2(sx1,sy1), imgui.ImVec2(sx2,sy2), 0x44FF3333, 8)
                            fdl:AddLine(imgui.ImVec2(sx1,sy1), imgui.ImVec2(sx2,sy2), 0xEEFF3333, 4)
                            fdl:AddCircleFilled(imgui.ImVec2(sx2,sy2), 5*MDS, 0xFFFFFFFF)
                            fdl:AddCircleFilled(imgui.ImVec2(sx2,sy2), 3*MDS, 0xCCFF3333)
                        end
                    end
                end
            end
        end

        if larekIsWalking then
            local pm_eat = _fnt.huge
            if pm_eat then imgui.PushFont(pm_eat) end
            local lbl = u8('\xc1\xc5\xc3\xd3 \xca\xd3\xd8\xc0\xd2\xdc')
            local sz  = imgui.CalcTextSize(lbl)
            local bx  = resx * 0.5 - sz.x * 0.5
            local by  = resy - sz.y - 40*MDS
            fdl:AddText(imgui.ImVec2(bx-3, by-3), 0xDD000000, lbl)
            fdl:AddText(imgui.ImVec2(bx+3, by-3), 0xDD000000, lbl)
            fdl:AddText(imgui.ImVec2(bx-3, by+3), 0xDD000000, lbl)
            fdl:AddText(imgui.ImVec2(bx+3, by+3), 0xDD000000, lbl)
            fdl:AddText(imgui.ImVec2(bx, by), 0xFFFF2222, lbl)
            if pm_eat then imgui.PopFont() end
        end
    end
)

local _mainWinPos = nil

imgui.OnFrame(
    function() return WinMain[0] end,
    function(self)
        self.HideCursor = true
        if not _mainWinPos then return end
        local W2 = math.min(resx*0.88, 480*MDS)
        local H2 = math.min(resy*0.74, 450*MDS)
        local px2, py2 = _mainWinPos.x, _mainWinPos.y
        local fdl2 = imgui.GetForegroundDrawList()
        fdl2:AddRect(imgui.ImVec2(px2-1, py2-1), imgui.ImVec2(px2+W2+1, py2+H2+1),
            0x33000000, 0, 0, 4)
        fdl2:AddRect(imgui.ImVec2(px2, py2), imgui.ImVec2(px2+W2, py2+H2),
            0x55FF4D4D, 0, 0, 1.0)
    end
)

imgui.OnFrame(
    function() return WinStats[0] end,
    function(self)
        self.HideCursor = true
        local SW = math.min(resx*0.65, 260*MDS)
        local SH = (38+12+22+98+8+80+5+24+10)*MDS

        imgui.SetNextWindowPos(
            imgui.ImVec2(resx - SW - 18*MDS, resy - SH - 18*MDS),
            imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(SW, SH), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg,    imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border,       imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.BorderShadow, imgui.ImVec4(0,0,0,0))
        imgui.Begin('##winstats', WinStats,
            imgui.WindowFlags.NoTitleBar  +
            imgui.WindowFlags.NoResize    +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoScrollWithMouse +
            imgui.WindowFlags.NoBackground)

        local DL  = imgui.GetWindowDrawList()
        local WP  = imgui.GetWindowPos()
        local pm  = pF(_fnt.main)
        local pad = 12*MDS
        local IW  = SW - pad*2
        local rndS = 12*MDS

        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+SW, WP.y+SH),
            u32(imgui.ImVec4(0.059,0.059,0.059,0.98)), rndS)
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+SW, WP.y+SH*0.35),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.45)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.45)),
            u32(imgui.ImVec4(0,0,0,0)),
            u32(imgui.ImVec4(0,0,0,0)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x+SW*0.5, WP.y+SH*0.65), imgui.ImVec2(WP.x+SW, WP.y+SH),
            u32(imgui.ImVec4(0,0,0,0)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.40)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.40)),
            u32(imgui.ImVec4(0,0,0,0)))
        DL:AddRect(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+SW,WP.y+SH),
            u32(CLR.border), rndS, 0, 1.2)

        local sHdrH = 38*MDS
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+SW, WP.y+sHdrH),
            u32(imgui.ImVec4(0.086,0.102,0.129,1.00)), rndS, 0x3)
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y+rndS), imgui.ImVec2(WP.x+SW, WP.y+sHdrH),
            u32(imgui.ImVec4(0.086,0.102,0.129,1.00)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+SW*0.55, WP.y+sHdrH),
            u32(imgui.ImVec4(0.106,0.157,0.216,1.00)),
            u32(imgui.ImVec4(0.086,0.102,0.129,0.00)),
            u32(imgui.ImVec4(0.086,0.102,0.129,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,1.00)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x+SW*0.45, WP.y), imgui.ImVec2(WP.x+SW, WP.y+sHdrH),
            u32(imgui.ImVec4(0,0,0,0)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.85)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.85)),
            u32(imgui.ImVec4(0,0,0,0)))
        DL:AddLine(imgui.ImVec2(WP.x, WP.y+sHdrH), imgui.ImVec2(WP.x+SW, WP.y+sHdrH),
            u32(CLR.border), 1)

        local hdrLbl = u8'\xd1\xd2\xc0\xd2\xc8\xd1\xd2\xc8\xca\xc0'
        local hdrSz  = imgui.CalcTextSize(hdrLbl)
        DL:AddText(imgui.ImVec2(WP.x+pad, WP.y+sHdrH*0.5-hdrSz.y*0.5),
            u32(CLR.text), hdrLbl)

        local rstSz = 22*MDS
        local mx_s, my_s = imgui.GetMousePos().x, imgui.GetMousePos().y
        local rstX  = WP.x + SW - rstSz*2 - pad - 6*MDS
        local rstY2 = WP.y + (sHdrH - rstSz)*0.5
        local rstHov = mx_s>=rstX and mx_s<=rstX+rstSz and my_s>=rstY2 and my_s<=rstY2+rstSz
        local rstIc  = fa['ROTATE_LEFT']
        local rstIS  = imgui.CalcTextSize(rstIc)
        DL:AddRectFilled(imgui.ImVec2(rstX,rstY2), imgui.ImVec2(rstX+rstSz,rstY2+rstSz),
            u32(rstHov and imgui.ImVec4(1,1,1,0.15) or imgui.ImVec4(1,1,1,0.06)), 4*MDS)
        DL:AddText(imgui.ImVec2(rstX+(rstSz-rstIS.x)*0.5, rstY2+(rstSz-rstIS.y)*0.5),
            u32(rstHov and CLR.accent or CLR.textDim), rstIc)
        if rstHov and imgui.IsMouseClicked(0) then
            farm.res_counter = {cotton=0,linen=0,rare=0,coal=0}
            farm.stats.start_time = 0
            botTotalSeconds = 0
            if botSessionStart > 0 then botSessionStart = os.time() end
            saveCfg()
        end

        local clsSz = 22*MDS
        local clsX  = WP.x + SW - clsSz - pad
        local clsY  = WP.y + (sHdrH - clsSz)*0.5
        local clsHov = mx_s>=clsX and mx_s<=clsX+clsSz and my_s>=clsY and my_s<=clsY+clsSz
        DL:AddRectFilled(imgui.ImVec2(clsX,clsY), imgui.ImVec2(clsX+clsSz,clsY+clsSz),
            u32(clsHov and CLR.accent or imgui.ImVec4(1,1,1,0.10)), 4*MDS)
        local xSt = imgui.CalcTextSize('x')
        DL:AddText(imgui.ImVec2(clsX+(clsSz-xSt.x)*0.5, clsY+(clsSz-xSt.y)*0.5),
            u32(clsHov and CLR.text or imgui.ImVec4(1,1,1,0.55)), 'x')
        if clsHov and imgui.IsMouseClicked(0) then WinStats[0] = false end

        local cy2 = WP.y + sHdrH + pad

        local el3    = getBotElapsed()
        local timeS3 = string.format('%02d:%02d:%02d',
            math.floor(el3/3600), math.floor((el3%3600)/60), el3%60)
        local sesLbl = u8'\xc1\xee\xf2 \xf0\xe0\xe1\xee\xf2\xe0\xeb: '..timeS3
        DL:AddText(imgui.ImVec2(WP.x+pad, cy2), u32(CLR.textDim), sesLbl)
        cy2 = cy2 + imgui.CalcTextSize(sesLbl).y + 10*MDS

        local rc3  = farm.res_counter
        local cg3  = 5*MDS; local cw3 = (IW-cg3)*0.5; local ch3 = 42*MDS
        drawStatCard(DL, WP.x+pad,        cy2, cw3, ch3, u8'\xd5\xcb\xce\xcf', fmtNum(rc3.cotton), imgui.ImVec4(0.95,0.88,0.55,1))
        drawStatCard(DL, WP.x+pad+cw3+cg3,cy2, cw3, ch3, u8'\xcb\xa8\xcd',    fmtNum(rc3.linen),  imgui.ImVec4(0.55,0.95,0.68,1))
        imgui.SetCursorPos(imgui.ImVec2(pad, cy2-WP.y))
        imgui.Dummy(imgui.ImVec2(IW, ch3+5*MDS))
        cy2 = cy2 + ch3 + 7*MDS
        drawStatCard(DL, WP.x+pad,        cy2, cw3, ch3, u8'\xd2\xca\xc0\xcd\xdc', fmtNum(rc3.rare),  imgui.ImVec4(0.75,0.52,0.95,1))
        drawStatCard(DL, WP.x+pad+cw3+cg3,cy2, cw3, ch3, u8'\xd3\xc3\xce\xcb\xdc',     fmtNum(rc3.coal), CLR.coal)
        imgui.SetCursorPos(imgui.ImVec2(pad, cy2-WP.y))
        imgui.Dummy(imgui.ImVec2(IW, ch3+8*MDS))
        cy2 = cy2 + ch3 + 8*MDS

        DL:AddLine(imgui.ImVec2(WP.x+pad, cy2), imgui.ImVec2(WP.x+SW-pad, cy2), u32(CLR.border), 1)
        cy2 = cy2 + 8*MDS

        local pc3  = rc3.cotton * calc.price_cotton
        local pl3  = rc3.linen  * calc.price_linen
        local pr3  = rc3.rare   * calc.price_rare
        local pw3  = rc3.coal  * calc.price_coal
        local tot3 = pc3+pl3+pr3+pw3

        local incRows = {
            { u8'\xd5\xeb\xee\xef\xee\xea:', fmtNum(pc3)..'$', imgui.ImVec4(0.95,0.88,0.55,1) },
            { u8'\xcb\xb8\xed:',              fmtNum(pl3)..'$', imgui.ImVec4(0.55,0.95,0.68,1) },
            { u8'\xd2\xea\xe0\xed\xfc:',      fmtNum(pr3)..'$', imgui.ImVec4(0.75,0.52,0.95,1) },
            { u8'\xd3\xe3\xee\xeb\xfc:',          fmtNum(pw3)..'$', CLR.coal },
        }
        for _, row in ipairs(incRows) do
            local lS = imgui.CalcTextSize(row[1])
            local vS = imgui.CalcTextSize(row[2])
            DL:AddText(imgui.ImVec2(WP.x+pad, cy2), u32(CLR.textDim), row[1])
            DL:AddText(imgui.ImVec2(WP.x+SW-pad-vS.x, cy2), u32(row[3]), row[2])
            cy2 = cy2 + lS.y + 4*MDS
        end

        DL:AddLine(imgui.ImVec2(WP.x+pad, cy2), imgui.ImVec2(WP.x+SW-pad, cy2), u32(CLR.border), 1)
        cy2 = cy2 + 5*MDS
        local totLbl = u8'\xc8\xd2\xce\xc3\xce:'
        local totVal = fmtNum(tot3)..'$'
        local totLS  = imgui.CalcTextSize(totLbl)
        local totVS  = imgui.CalcTextSize(totVal)
        local pB2    = pF(_fnt.big)
        DL:AddText(imgui.ImVec2(WP.x+pad, cy2), u32(CLR.text), totLbl)
        DL:AddText(imgui.ImVec2(WP.x+SW-pad-totVS.x, cy2), u32(CLR.green), totVal)
        pFpop(pB2)
        cy2 = cy2 + math.max(totLS.y, totVS.y) + 8*MDS

        pFpop(pm)
        imgui.End()
        imgui.PopStyleColor(3)
    end
)

local WinAutoEatSettings = imgui.new.bool(false)
imgui.OnFrame(
    function() return autoEatSettingsOpen and WinMain[0] end,
    function(self)
        self.HideCursor = false

        local AW = 260*MDS
        local AH = 404*MDS

        imgui.SetNextWindowPos(imgui.ImVec2(resx*0.5 + 260*MDS, resy*0.5 - AH*0.5),
            imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(AW, AH), imgui.Cond.Always)

        local fl = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
                 + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
                 + imgui.WindowFlags.NoBackground
        imgui.PushStyleColor(imgui.Col.WindowBg,    imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border,       imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.BorderShadow, imgui.ImVec4(0,0,0,0))
        imgui.Begin('##ae_win', WinAutoEatSettings, fl)

        local DL  = imgui.GetWindowDrawList()
        local WP  = imgui.GetWindowPos()
        local pm  = pF(_fnt.main)
        local rnd = 12*MDS
        local pad = 14*MDS

        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+AW, WP.y+AH),
            u32(imgui.ImVec4(0.059,0.059,0.059,0.98)))
        DL:AddRect(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+AW,WP.y+AH),
            u32(CLR.border), 0, 0, 1.0)

        local hdrH = 44*MDS
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+AW, WP.y+hdrH),
            u32(imgui.ImVec4(0.086,0.102,0.129,1.00)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+AW*0.55, WP.y+hdrH),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.90)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.90)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x+AW*0.45, WP.y), imgui.ImVec2(WP.x+AW, WP.y+hdrH),
            u32(imgui.ImVec4(0.200,0.820,0.400,0.00)),
            u32(imgui.ImVec4(0.200,0.820,0.400,0.30)),
            u32(imgui.ImVec4(0.200,0.820,0.400,0.30)),
            u32(imgui.ImVec4(0.200,0.820,0.400,0.00)))
        DL:AddLine(imgui.ImVec2(WP.x, WP.y+hdrH), imgui.ImVec2(WP.x+AW, WP.y+hdrH),
            u32(CLR.border), 1)

        local pB3 = pF(_fnt.main)
        local aeHdrIc = fa['UTENSILS']
        local aeHdrS  = imgui.CalcTextSize(aeHdrIc)
        DL:AddText(imgui.ImVec2(WP.x+pad, WP.y+hdrH*0.5-aeHdrS.y*0.5),
            u32(CLR.green), aeHdrIc)
        local aeHdrLbl = u8' \xc0\xe2\xf2\xee \xc5\xe4\xe0'
        local aeHdrLS  = imgui.CalcTextSize(aeHdrLbl)
        DL:AddText(imgui.ImVec2(WP.x+pad+aeHdrS.x, WP.y+hdrH*0.5-aeHdrLS.y*0.5),
            u32(CLR.text), aeHdrLbl)
        pFpop(pB3)

        local clSz2 = 24*MDS
        local clX2  = WP.x + AW - clSz2 - pad*0.5
        local clY2  = WP.y + (hdrH - clSz2)*0.5
        local mxC, myC = imgui.GetMousePos().x, imgui.GetMousePos().y
        local clHov2 = mxC>=clX2 and mxC<=clX2+clSz2 and myC>=clY2 and myC<=clY2+clSz2
        DL:AddRectFilled(imgui.ImVec2(clX2,clY2), imgui.ImVec2(clX2+clSz2,clY2+clSz2),
            u32(clHov2 and CLR.accent or imgui.ImVec4(1,1,1,0.08)), 4*MDS)
        local xS2 = imgui.CalcTextSize('x')
        DL:AddText(imgui.ImVec2(clX2+(clSz2-xS2.x)*0.5, clY2+(clSz2-xS2.y)*0.5),
            u32(clHov2 and CLR.text or imgui.ImVec4(1,1,1,0.55)), 'x')
        if clHov2 and imgui.IsMouseClicked(0) then autoEatSettingsOpen = false end

        imgui.SetCursorPos(imgui.ImVec2(0, 0))
        imgui.InvisibleButton('##ae_drag', imgui.ImVec2(AW - clSz2 - pad, hdrH))
        imgui.IsItemActive()

        local bodyY = WP.y + hdrH
        local cX    = WP.x + pad
        local cW    = AW - pad*2
        local cy    = bodyY + 7*MDS
        local rh    = 26*MDS

        local satCurLbl2, satCurCol2
        if autoEatSatiety < 0 then
            satCurLbl2 = u8'\xd1\xfb\xf2\xee\xf1\xf2\xfc: ???'
            satCurCol2 = CLR.textDim
        else
            local sv = math.floor(autoEatSatiety)
            satCurLbl2 = string.format(u8'\xd1\xfb\xf2\xee\xf1\xf2\xfc: %d / 100', sv)
            satCurCol2 = sv < 30 and imgui.ImVec4(1,0.30,0.30,1)
                      or sv < 60 and imgui.ImVec4(0.95,0.70,0.10,1)
                      or CLR.green
        end
        local pSm4 = pF(_fnt.small)
        local satLS2 = imgui.CalcTextSize(satCurLbl2)
        DL:AddText(imgui.ImVec2(cX + (cW-satLS2.x)*0.5, cy), u32(satCurCol2), satCurLbl2)
        pFpop(pSm4)
        cy = cy + satLS2.y + 6*MDS

        DL:AddLine(imgui.ImVec2(cX, cy), imgui.ImVec2(cX+cW, cy), u32(CLR.border), 1)
        cy = cy + 7*MDS

        sectionTitle(DL, cX, cy, cW, u8'\xd0\xe5\xe6\xe8\xec \xe5\xe4\xfb')
        cy = cy + 16*MDS

        local modeNames = { u8'\xcb\xe0\xf0\xb8\xea', u8'/eat' }
        local rdSz0 = 11*MDS
        for i = 0, 1 do
            rowBg(DL, cX, cy, cW, rh)
            local midYm = cy + rh*0.5
            local selM  = (autoEatMode == i)
            local rdXm  = cX + 8*MDS + rdSz0*0.5
            if selM then
                DL:AddCircleFilled(imgui.ImVec2(rdXm, midYm), rdSz0*0.5, u32(CLR.accent))
                DL:AddCircleFilled(imgui.ImVec2(rdXm, midYm), rdSz0*0.5-2*MDS, u32(imgui.ImVec4(0.059,0.059,0.059,1)))
                DL:AddCircleFilled(imgui.ImVec2(rdXm, midYm), rdSz0*0.5-4*MDS, u32(CLR.accent))
            else
                DL:AddCircle(imgui.ImVec2(rdXm, midYm), rdSz0*0.5, u32(CLR.textDim), 24, 1.2)
            end
            local pmM = pF(_fnt.small)
            local fSM = imgui.CalcTextSize(modeNames[i+1])
            DL:AddText(imgui.ImVec2(cX+8*MDS+rdSz0+6*MDS, midYm-fSM.y*0.5),
                u32(selM and CLR.text or CLR.textDim), modeNames[i+1])
            pFpop(pmM)
            imgui.SetCursorPos(imgui.ImVec2(cX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cW, rh))
            imgui.SetCursorPos(imgui.ImVec2(cX-WP.x, cy-WP.y))
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
            if imgui.Button('##aemode_'..i, imgui.ImVec2(cW, rh)) then
                autoEatMode = i; saveCfg()
            end
            imgui.PopStyleColor(3)
            cy = cy + rh + 3*MDS
        end

        cy = cy + 3*MDS
        DL:AddLine(imgui.ImVec2(cX, cy), imgui.ImVec2(cX+cW, cy), u32(CLR.border), 1)
        cy = cy + 7*MDS

        sectionTitle(DL, cX, cy, cW, u8'\xc2\xfb\xe1\xee\xf0 \xe5\xe4\xfb')
        cy = cy + 16*MDS

        local foodLocked = (autoEatMode == 0)
        local foodDimAlpha = foodLocked and 0.35 or 1.0

        local foodNames2 = {
            u8'\xd7\xe8\xef\xf1\xfb',
            u8'\xd0\xfb\xe1\xe0',
            u8'\xce\xeb\xe5\xed\xe8\xed\xe0',
        }
        local rdSz2 = 11*MDS
        for i = 0, 2 do
            rowBg(DL, cX, cy, cW, rh)
            local midYf = cy + rh*0.5
            local selected2 = (autoEatFood == i) and not foodLocked

            local rdX2 = cX + 8*MDS + rdSz2*0.5
            local circCol = foodLocked and imgui.ImVec4(0.4,0.4,0.4,0.3) or CLR.textDim
            if selected2 then
                DL:AddCircleFilled(imgui.ImVec2(rdX2, midYf), rdSz2*0.5, u32(CLR.accent))
                DL:AddCircleFilled(imgui.ImVec2(rdX2, midYf), rdSz2*0.5-2*MDS, u32(imgui.ImVec4(0.059,0.059,0.059,1)))
                DL:AddCircleFilled(imgui.ImVec2(rdX2, midYf), rdSz2*0.5-4*MDS, u32(CLR.accent))
            else
                DL:AddCircle(imgui.ImVec2(rdX2, midYf), rdSz2*0.5, u32(circCol), 24, 1.2)
            end

            local pm5 = pF(_fnt.small)
            local fS2 = imgui.CalcTextSize(foodNames2[i+1])
            DL:AddText(imgui.ImVec2(cX+8*MDS+rdSz2+6*MDS, midYf-fS2.y*0.5),
                u32(foodLocked and imgui.ImVec4(0.5,0.5,0.5,0.35) or (autoEatFood==i and CLR.text or CLR.textDim)),
                foodNames2[i+1])
            pFpop(pm5)

            imgui.SetCursorPos(imgui.ImVec2(cX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cW, rh))
            imgui.SetCursorPos(imgui.ImVec2(cX-WP.x, cy-WP.y))
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
            if imgui.Button('##aef2_'..i, imgui.ImVec2(cW, rh)) then
                if not foodLocked then autoEatFood = i; saveCfg() end
            end
            imgui.PopStyleColor(3)
            cy = cy + rh + 3*MDS
        end

        cy = cy + 3*MDS
        DL:AddLine(imgui.ImVec2(cX, cy), imgui.ImVec2(cX+cW, cy), u32(CLR.border), 1)
        cy = cy + 7*MDS

        sectionTitle(DL, cX, cy, cW, u8'\xc5\xf1\xf2\xfc \xef\xf0\xe8 \xf1\xfb\xf2\xee\xf1\xf2\xe8 \xed\xe8\xe6\xe5:')
        cy = cy + 16*MDS

        rowBg(DL, cX, cy, cW, rh)

        local btnSz3 = 22*MDS
        local numW3  = 38*MDS
        local blkW   = btnSz3*2 + numW3 + 8*MDS
        local blkX   = cX + (cW - blkW)*0.5
        local midYs  = cy + rh*0.5

        local mxS2, myS2 = imgui.GetMousePos().x, imgui.GetMousePos().y
        local hovMn = not foodLocked and mxS2>=blkX and mxS2<=blkX+btnSz3 and myS2>=cy and myS2<=cy+rh
        local hovPl = not foodLocked and mxS2>=blkX+btnSz3+numW3+8*MDS and mxS2<=blkX+blkW and myS2>=cy and myS2<=cy+rh

        local btnAlpha = foodLocked and 0.25 or 1.0
        DL:AddRectFilled(imgui.ImVec2(blkX, midYs-btnSz3*0.5),
            imgui.ImVec2(blkX+btnSz3, midYs+btnSz3*0.5),
            u32(hovMn and CLR.accentH or imgui.ImVec4(0.15,0.15,0.15,btnAlpha)), 5*MDS)
        local mS = imgui.CalcTextSize('-')
        DL:AddText(imgui.ImVec2(blkX+(btnSz3-mS.x)*0.5, midYs-mS.y*0.5),
            u32(imgui.ImVec4(1,1,1,btnAlpha)), '-')

        local numLbl3 = foodLocked and '50' or tostring(autoEatMinSatiety)
        local numLS3  = imgui.CalcTextSize(numLbl3)
        DL:AddText(imgui.ImVec2(blkX+btnSz3+4*MDS+(numW3-numLS3.x)*0.5, midYs-numLS3.y*0.5),
            u32(imgui.ImVec4(1,1,1,btnAlpha)), numLbl3)

        DL:AddRectFilled(imgui.ImVec2(blkX+btnSz3+numW3+8*MDS, midYs-btnSz3*0.5),
            imgui.ImVec2(blkX+blkW, midYs+btnSz3*0.5),
            u32(hovPl and CLR.accentH or imgui.ImVec4(0.15,0.15,0.15,btnAlpha)), 5*MDS)
        local pS2 = imgui.CalcTextSize('+')
        DL:AddText(imgui.ImVec2(blkX+btnSz3+numW3+8*MDS+(btnSz3-pS2.x)*0.5, midYs-pS2.y*0.5),
            u32(imgui.ImVec4(1,1,1,btnAlpha)), '+')

        imgui.SetCursorPos(imgui.ImVec2(cX-WP.x, cy-WP.y))
        imgui.Dummy(imgui.ImVec2(cW, rh))
        imgui.SetCursorPos(imgui.ImVec2(blkX-WP.x, midYs-btnSz3*0.5-WP.y))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
        if imgui.Button('##ae_mn', imgui.ImVec2(btnSz3, btnSz3)) then
            if not foodLocked then autoEatMinSatiety = math.max(20, autoEatMinSatiety - 5); saveCfg() end
        end
        imgui.SetCursorPos(imgui.ImVec2(blkX+btnSz3+numW3+8*MDS-WP.x, midYs-btnSz3*0.5-WP.y))
        if imgui.Button('##ae_pl', imgui.ImVec2(btnSz3, btnSz3)) then
            if not foodLocked then autoEatMinSatiety = math.min(100, autoEatMinSatiety + 5); saveCfg() end
        end
        imgui.PopStyleColor(3)

        cy = cy + rh + 12*MDS
        DL:AddLine(imgui.ImVec2(cX, cy), imgui.ImVec2(cX+cW, cy), u32(CLR.border), 1)
        cy = cy + 8*MDS

        local tbH = 36*MDS
        local tbBg  = larekRunning and imgui.ImVec4(0.25,0.18,0.05,1) or imgui.ImVec4(0.08,0.35,0.15,1)
        local tbHov = larekRunning and imgui.ImVec4(0.25,0.18,0.05,1) or imgui.ImVec4(0.12,0.50,0.22,1)
        if dlBtn(DL, cX, cy, cW, tbH, tbBg, tbHov,
            fa['PLAY']..' '..u8'\xd2\xe5\xf1\xf2: \xea \xeb\xe0\xf0\xfc\xea\xf3 \xe8 \xea\xf3\xf8\xe0\xf2\xfc',
            larekRunning and CLR.textDim or CLR.green, 4*MDS) then
            if not larekRunning then
                testLarekMode = true
                goEatAtLarek()
            end
        end
        imgui.SetCursorPos(imgui.ImVec2(cX-WP.x, cy-WP.y))
        imgui.Dummy(imgui.ImVec2(cW, tbH))

        pFpop(pm)
        imgui.End()
        imgui.PopStyleColor(3)
    end
)

imgui.OnFrame(
    function() return licWinOpen[0] end,
    function(self)
        self.HideCursor = false
        local W = 370 * MDS
        local H = 180 * MDS
        imgui.SetNextWindowSize(imgui.ImVec2(W, H), imgui.Cond.Always)
        imgui.SetNextWindowPos(
            imgui.ImVec2((resx - W) * 0.5, (resy - H) * 0.5),
            imgui.Cond.Always)
        imgui.Begin(u8('##LicWinSF'), licWinOpen,
            imgui.WindowFlags.NoTitleBar  +
            imgui.WindowFlags.NoResize    +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoMove)

        local DL = imgui.GetWindowDrawList()
        local WP = imgui.GetWindowPos()
        local pu32 = imgui.ColorConvertFloat4ToU32

        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+H),
            pu32(imgui.ImVec4(0.059,0.059,0.059,0.99)),
            pu32(imgui.ImVec4(0.106,0.157,0.216,0.99)),
            pu32(imgui.ImVec4(0.086,0.102,0.129,0.99)),
            pu32(imgui.ImVec4(0.059,0.059,0.059,0.99)))
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+3*MDS), u32(CLR.accent))
        DL:AddRect(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+H), u32(CLR.border), 12*MDS, 0, 1.2)

        local pm = pF(_fnt.main)
        local pad = 14*MDS

        imgui.SetCursorPos(imgui.ImVec2(pad, 12*MDS))
        imgui.PushStyleColor(imgui.Col.Text, CLR.accent)
        imgui.Text(u8('\xca\xeb\xfe\xf7 \xeb\xe8\xf6\xe5\xed\xe7\xe8\xe8  StrandFerma'))
        imgui.PopStyleColor()

        imgui.SetCursorPos(imgui.ImVec2(pad, 32*MDS))
        imgui.PushStyleColor(imgui.Col.Text, CLR.textDim)
        imgui.Text(u8('\xcf\xee\xeb\xf3\xf7\xe8\xf2\xfc \xea\xeb\xfe\xf7: @victor_st0'))
        imgui.PopStyleColor()

        imgui.SetCursorPos(imgui.ImVec2(pad, 54*MDS))
        imgui.PushItemWidth(W - pad*2)
        imgui.InputText(u8('##sfkey'), licInputBuf, 64)
        imgui.PopItemWidth()

        if licenseMsg ~= '' then
            imgui.SetCursorPos(imgui.ImVec2(pad, 84*MDS))
            local mc = licenseChecking
                and imgui.ImVec4(0.90, 0.85, 0.25, 1.00)
                or  imgui.ImVec4(1.00, 0.35, 0.35, 1.00)
            imgui.PushStyleColor(imgui.Col.Text, mc)
            imgui.Text(licenseMsg)
            imgui.PopStyleColor()
        end

        local bY   = 112*MDS
        local bW1  = (W - pad*2 - 6*MDS) * 0.62
        local bW2  = W - pad*2 - bW1 - 6*MDS
        local bH   = 36*MDS
        local cpB  = imgui.ImVec2(WP.x+pad, WP.y+bY)

        if dlBtn(DL, cpB.x, cpB.y, bW1, bH,
            imgui.ImVec4(0.07,0.28,0.14,1), imgui.ImVec4(0.12,0.45,0.22,1),
            u8('\xc0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xf2\xfc'),
            imgui.ImVec4(0.70,1.00,0.76,1), 4*MDS) then
            local k = bufToStr(licInputBuf, 64):match('^%s*(.-)%s*$')
            if #k > 3 then
                checkLicenseAsync(k)
            else
                licenseMsg = u8('\xc2\xe2\xe5\xe4\xe8\xf2\xe5 \xea\xeb\xfe\xf7')
            end
        end
        if dlBtn(DL, cpB.x+bW1+6*MDS, cpB.y, bW2, bH,
            imgui.ImVec4(0.25,0.06,0.06,1), imgui.ImVec4(0.45,0.10,0.10,1),
            u8('\xc7\xe0\xea\xf0\xfb\xf2\xfc'),
            imgui.ImVec4(1.00,0.55,0.55,1), 4*MDS) then
            licWinOpen[0] = false
        end
        imgui.SetCursorPos(imgui.ImVec2(pad, bY+bH+2*MDS))
        imgui.Dummy(imgui.ImVec2(1, 1))

        pFpop(pm)
        imgui.End()
    end
)

function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(100) end

    wait(300)
    loadCfg()
    saveCfg()
    initSounds()
    if licenseKey ~= '' then
        checkLicenseAsync(licenseKey, true, true)
    else
        licWinOpen[0] = true
    end
    _buf.timer[0]   = botTimerMinutes
    _buf.goalRes[0] = goal.resAmount
    _buf.goalMon[0] = goal.money
    _ajBuf = imgui.new.int[1](autoJumpInterval)
    if autoJump then startAutoJump() end

    _buf.cot[0]=calc.price_cotton
    _buf.lin[0]=calc.price_linen
    _buf.rar[0]=calc.price_rare
    _buf.wat[0]=calc.price_coal

    if not _SF_INIT_DONE then
        _SF_INIT_DONE = true
        sampAddChatMessage('{33aaff}[StrandFerma] {ffffff}v3.0  {888888}|  {ffdd44}/sf \xe2\xea\xeb/\xe2\xfb\xea\xeb  {888888}|  {ffdd44}/sfhide \xea\xed\xee\xef\xea\xe0', -1)
        sampRegisterChatCommand('sf', function()
            if not licenseOK then
                licWinOpen[0] = true
            else
                WinMain[0]=not WinMain[0]
            end
        end)
        sampRegisterChatCommand('sfhide', function()
            fabHidden=not fabHidden; saveCfg()
            sampAddChatMessage('{33aaff}[StrandFerma] {aaaaaa}'
                ..(fabHidden
                    and '\xca\xed\xee\xef\xea\xe0 \xd1\xd2\xc0\xd0\xd2/\xd1\xd2\xce\xcf \xf1\xea\xf0\xfb\xf2\xe0'
                     or '\xca\xed\xee\xef\xea\xe0 \xd1\xd2\xc0\xd0\xd2/\xd1\xd2\xce\xcf \xef\xee\xea\xe0\xe7\xe0\xed\xe0'), -1)
        end)
    end

    if not _SF_THREADS_DONE then
        _SF_THREADS_DONE = true
        lua_thread.create(renderLoop)
        lua_thread.create(botWatchdog)
        lua_thread.create(function()
            local prevAnims = false
            while true do
                wait(0)
                if autoAnims and not prevAnims then
                    if sampIsLocalPlayerSpawned() then
                        sampSendChat('/anims 1')
                    end
                    prevAnims = true
                    wait(360000)
                elseif autoAnims then
                    if sampIsLocalPlayerSpawned() then
                        sampSendChat('/anims 1')
                    end
                    wait(360000)
                else
                    prevAnims = false
                    wait(500)
                end
            end
        end)
    end

    lua_thread.create(function()
        while not isSampAvailable() do wait(500) end
        while not sampIsLocalPlayerSpawned() do wait(500) end
        wait(4000)
        lua_thread.create(function()
            autoEatWaitSat = true
            sampSendChat('/satiety')
            local t = 0
            while autoEatWaitSat and t < 60 do wait(100); t = t+1 end
            autoEatWaitSat = false
        end)
        while true do
            wait(0)
            if autoEat then
                for i = 1, 300 do
                    wait(100)
                    if not autoEat then break end
                end
                if not autoEat then goto ae_continue end
                if sampIsLocalPlayerSpawned() then
                    lua_thread.create(function()
                        autoEatWaitSat = true
                        sampSendChat('/satiety')
                        local t = 0
                        while autoEatWaitSat and t < 60 do wait(100); t = t+1 end
                        autoEatWaitSat = false
                        wait(400)
                        if autoEatSatiety >= 0 and autoEatSatiety >= (autoEatMode == 0 and 40 or autoEatMinSatiety) then return end

                        if autoEatMode == 0 then
                            if not larekRunning and farm.running then
                                addLog('[\xd1\xfb\xf2\xee\xf1\xf2\xfc] < 40%, \xe8\xe4\xf3 \xea \xeb\xe0\xf0\xb8\xea\xf3')
                                goEatAtLarek()
                                local tw = 0
                                while larekRunning and farm.running and tw < 600 do wait(100); tw = tw+1 end
                                if not farm.running then
                                    larekRunning = false
                                    larekIsWalking = false
                                end
                            end
                        else
                            autoEatWaitEat = true
                            sampSendChat('/eat')
                            local t2 = 0
                            while autoEatWaitEat and t2 < 60 do wait(100); t2 = t2+1 end
                            autoEatWaitEat = false
                            wait(300)
                            if sampIsDialogActive() then
                                sampSendChat('/eat')
                            end
                        end
                    end)
                end
            end
            ::ae_continue::
        end
    end)

    lua_thread.create(function()
        while true do
            wait(5000)
            if farm.running and botTimerMinutes > 0 and botTimerStart > 0 then
                local elapsed_t = os.time() - botTimerStart
                if elapsed_t >= botTimerMinutes * 60 then
                    emergencyStop()
                    botTimerStart = 0
                    saveCfg()
                    local _mins = botTimerMinutes
                    local _quit = quitOnTimer
                    lua_thread.create(function()
                        sampAddChatMessage('{4488ff}[StrandFerma]: {ffaa00}'
                            ..'\xd2\xe0\xe9\xec\xe5\xf0 \xe8\xf1\xf2\xb8\xea \xe2 '
                            ..tostring(_mins)
                            ..' \xec\xe8\xed\xf3\xf2, \xe1\xee\xf2 \xee\xf1\xf2\xe0\xed\xee\xe2\xeb\xe5\xed', -1)
                        if _quit then
                            wait(2000)
                            os.exit()
                        end
                    end)
                end
            end
        end
    end)

    lua_thread.create(function()
        while true do
            wait(3000)
            if farm.running and not goal.reached and goal.mode > 0 then
                local rc = farm.res_counter
                local pc = rc.cotton * calc.price_cotton
                local pl = rc.linen  * calc.price_linen
                local pr = rc.rare   * calc.price_rare
                local pw = rc.coal   * calc.price_coal
                local totalMoney = pc + pl + pr + pw
                local hit = false
                if goal.mode == 1 then
                    local targetAmt = goal.resAmounts[goal.resType + 1] or 0
                    local cur = 0
                    if     goal.resType == 0 then cur = rc.cotton
                    elseif goal.resType == 1 then cur = rc.linen
                    elseif goal.resType == 2 then cur = rc.rare
                    elseif goal.resType == 3 then cur = rc.coal
                    end
                    if targetAmt > 0 and cur >= targetAmt then hit = true end
                elseif goal.mode == 2 and goal.money > 0 then
                    if totalMoney >= goal.money then hit = true end
                end
                if hit then
                    goal.reached = true
                    emergencyStop()
                    sampAddChatMessage('{44dd44}[StrandFerma]: {ffdd44}\xd6\xc5\xcb\xdc \xc4\xce\xd1\xd2\xc8\xc3\xcd\xd3\xd2\xc0! \xc1\xee\xf2 \xee\xf1\xf2\xe0\xed\xee\xe2\xeb\xe5\xed.', -1)
                    saveCfg()
                    if quitOnTimer then
                        wait(2000)
                        os.exit()
                    end
                end
            end
        end
    end)

    lua_thread.create(function()
        while true do
            wait(60*1000)
            saveCfg()
        end
    end)

    lua_thread.create(function()
        while true do
            wait(0)
            if collisionEnabled then enableCollision() end
        end
    end)

    lua_thread.create(function()
        while not isSampAvailable() do wait(500) end
        while not sampIsLocalPlayerSpawned() do wait(500) end
        wait(2000)
        while true do
            wait(5000)
            if autoEat and autoEatMode == 0 then
                pcall(function()
                    for _, obj in ipairs(getAllObjects()) do
                        if doesObjectExist(obj) then
                            local ok, model = pcall(getObjectModel, obj)
                            if ok and model == 1340 then
                                pcall(setObjectCollision, obj, false)
                            end
                        end
                    end
                end)
            else
                pcall(function()
                    for _, obj in ipairs(getAllObjects()) do
                        if doesObjectExist(obj) then
                            local ok, model = pcall(getObjectModel, obj)
                            if ok and model == 1340 then
                                pcall(setObjectCollision, obj, true)
                            end
                        end
                    end
                end)
            end
        end
    end)

    while true do
        applyRunTired()

        if WIDGET_RADAR~=nil and isWidgetSwipedLeft(WIDGET_RADAR) then
            if not licenseOK then
                licWinOpen[0] = true
            else
                WinMain[0]=not WinMain[0]
            end
            wait(250)
        end
        if WIDGET_RADAR~=nil and isWidgetSwipedRight(WIDGET_RADAR) then
            if not licenseOK then
                licWinOpen[0] = true
            elseif farm.running then
                emergencyStop()
                sampAddChatMessage('{4488ff}[StrandFerma]: {ff4444}\xd1\xd2\xce\xcf',-1)
            else
                farm.running    = true
                botTimerStart   = os.time()
                botSessionStart = os.time()
                antiAdminEnableTime = os.clock()
                movement.active = false
                sprintActive    = false
                setGameKeyState(1,0); stopSprint()
                watchdogLastTarget = os.clock()
                sampAddChatMessage('{4488ff}[StrandFerma]: {44ff44}\xd1\xd2\xc0\xd0\xd2',-1)
            end
            wait(300)
        end

        if larekRunning then
            -- larek thread owns movement while it runs; main loop just idles
            wait(0)
        elseif farm.running then
            local best = findBestBushCached()
            if best then
                farm.target = best
                watchdogLastTarget = os.clock()
                local tx, ty, tz = best[1], best[2], best[3]

                movement.active = true
                runToPoint(tx, ty, tz)
                movement.active = false

                if farm.running then
                    setGameKeyState(1, 0)
                    stopSprint()
                    sprintActive = false

                    local function checkBushQty()
                        for id = 0, 2048 do
                            if sampIs3dTextDefined(id) then
                                local ok2, txt2, _, bx, by = pcall(sampGet3dTextInfoById, id)
                                if ok2 and txt2 and bx and by then
                                    if getDistanceBetweenCoords2d(bx, by, tx, ty) < 1.5 then
                                        if txt2:find('\xcc\xee\xe6\xed\xee \xf1\xee\xe1\xf0\xe0\xf2\xfc') then
                                            return tonumber(txt2:match('%((%d+)%s*\xe8\xe7'))
                                                or tonumber(txt2:match('(%d+)')) or 0
                                        end
                                        return 0
                                    end
                                end
                            end
                        end
                        return 0
                    end

                    local bushDone = false
                    while farm.running and not bushDone and not larekRunning do

                        if checkBushQty() <= 0 then
                            addLog('[\xd4\xe5\xf0\xec\xe0] \xca\xf3\xf1\xf2 \xef\xf3\xf1\xf2 — \xf3\xf5\xee\xe6\xf3')
                            bushDone = true
                            break
                        end

                        local lastCotton = farm.res_counter.cotton
                        local lastLinen  = farm.res_counter.linen
                        local lastRare   = farm.res_counter.rare
                        local lastCoal   = farm.res_counter.coal

                        doHarvest()

                        local collected = false
                        local timerStart = os.clock()
                        while farm.running and not larekRunning and (os.clock() - timerStart) < 12 do
                            if farm.res_counter.cotton > lastCotton
                            or farm.res_counter.linen  > lastLinen
                            or farm.res_counter.rare   > lastRare
                            or farm.res_counter.coal   > lastCoal then
                                collected = true
                                break
                            end
                            local elapsed = os.clock() - timerStart
                            if elapsed > 0.6 and checkBushQty() <= 0 then
                                addLog('[\xd4\xe5\xf0\xec\xe0] \xca\xf3\xf1\xf2 \xee\xef\xf3\xf1\xf2\xe5\xeb — \xf3\xf5\xee\xe6\xf3')
                                bushDone = true
                                break
                            end
                            if elapsed > 3 and elapsed < 3.3 then doHarvest()
                            elseif elapsed > 6 and elapsed < 6.3 then doHarvest()
                            end
                            wait(200)
                        end

                        if not collected and not bushDone and farm.running and not larekRunning then
                            addLog('[\xd4\xe5\xf0\xec\xe0] \xd1\xe5\xf0\xe2\xe5\xf0\xed\xfb\xe9 \xeb\xe0\xe3, \xee\xf2\xf5\xee\xe6\xf3...')
                            setGameKeyState(1,0); stopSprint()
                            local cx_s, cy_s, cz_s = getCharCoordinates(PLAYER_PED)
                            local dx = cx_s - tx
                            local dy = cy_s - ty
                            local len = math.sqrt(dx*dx + dy*dy)
                            if len < 0.01 then len = 1 end
                            local stepX = tx + (dx / len) * 6
                            local stepY = ty + (dy / len) * 6
                            local savedSprint = farm.sprint
                            farm.sprint = false
                            sprintActive = false
                            movement.active = true
                            runToPoint(stepX, stepY, cz_s, true)
                            setGameKeyState(1,0); stopSprint()
                            wait(1000)
                            movement.active = true
                            runToPoint(tx, ty, tz, true)
                            movement.active = false
                            farm.sprint = savedSprint
                            sprintActive = false
                            setGameKeyState(1,0); stopSprint()
                            lastCotton = farm.res_counter.cotton
                            lastLinen  = farm.res_counter.linen
                            lastRare   = farm.res_counter.rare
                            lastCoal   = farm.res_counter.coal
                            doHarvest()
                        end

                        if bushDone then break end

                        if collected then
                            wait(300)
                            if checkBushQty() <= 0 then
                                addLog('[\xd4\xe5\xf0\xec\xe0] \xca\xf3\xf1\xf2 \xe8\xf1\xf7\xe5\xf0\xef\xe0\xed — \xe8\xf9\xf3 \xf1\xeb\xe5\xe4\xf3\xfe\xf9\xe8\xe9')
                                bushDone = true
                            end
                        end
                    end

                    setGameKeyState(1,0); stopSprint()
                    invalidateBushCache()
                end

            else
                farm.target = nil
                setGameKeyState(1, 0)
                stopSprint()
                sprintActive = false

                if farm.goto_soonest then
                    watchdogLastTarget = os.clock()
                    local soonBush, soonTime = findSoonestStageTwoBush()
                    if soonBush then
                        addLog(string.format(
                            '[\xd4\xe5\xf0\xec\xe0] \xcd\xe5\xf2 \xe7\xf0\xe5\xeb\xfb\xf5, \xe8\xe4\xf3 \xea \xea\xf3\xf1\xf2\xf3 2 \xfd\xf2\xe0\xef\xe0 (%d:%02d)',
                            math.floor(soonTime / 60), soonTime % 60))
                        farm.target = soonBush
                        watchdogLastTarget = os.clock()
                        movement.active = true
                        runToPoint(soonBush[1], soonBush[2], soonBush[3], true)
                        movement.active = false
                        while farm.running and not larekRunning do
                            watchdogLastTarget = os.clock()
                            farm.target = soonBush
                            invalidateBushCache()
                            local ripeNow = findBestBush()
                            if ripeNow then
                                addLog('[\xd4\xe5\xf0\xec\xe0] \xca\xf3\xf1\xf2 \xf1\xee\xe7\xf0\xe5\xeb, \xe8\xe4\xf3 \xf1\xee\xe1\xf0\xe0\xf2\xfc!')
                                break
                            end
                            wait(500)
                        end
                        farm.target = nil
                        invalidateBushCache()
                    else
                        wait(500)
                    end
                else
                    addLog('[\xd4\xe5\xf0\xec\xe0] \xcd\xe5\xf2 \xe7\xf0\xe5\xeb\xfb\xf5 \xea\xf3\xf1\xf2\xee\xe2, \xe6\xe4\xf3...')
                    wait(500)
                end
            end
        else
            farm.target=nil
            setGameKeyState(1,0)
            stopSprint()
            sprintActive=false
            wait(0)
        end
        wait(0)
    end
end
