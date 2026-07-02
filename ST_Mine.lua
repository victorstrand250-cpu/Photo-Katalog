do
script_author('Victor Strand')
script_name('ST Mine')
local imgui = require('mimgui')
require('lib.moonloader')
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local sampev = require("lib.samp.events")
local ffi = require('ffi')

local SCRIPT_VERSION = '1.0'
local function msg(text) sampAddChatMessage("{FFFF00}[ST Mine]{FFFFFF} " .. text, -1) end
local json = {
    parse = function(data)
        local ok, res = pcall(function() return decodeJson(data) end)
        if ok then return res else return nil end
    end
}
local inicfg = require('inicfg')
local beskbeg = false

local tgbot = imgui.new.bool()
local beskk = false
local jumpp = imgui.new.bool()

local hook = require('monethook')
local otvet_1 = {
       "/b \xf2\xf3\xf2 \xff \xf2\xf3\xf2",
       "/b \xe4\xe0 \xff \xf2\xf3\xf2",
       "/b \xed\xf3?",
       "/b \xe4\xe0 \xf9\xe0\xf1 \xe3\xeb\xff\xed\xf3",
       "/b \xed\xf3 \xf2\xf3\xf2 \xff",
       "/b \xff \xed\xe0 \xec\xe5\xf1\xf2\xe5",
       "/b \xe0 \xf7\xf2\xee \xf2\xe0\xea\xee\xe5",
       "/b \xe4\xe0, \xf2\xf3\xf2 \xff",
       "/b +++",
       "/b \xed\xe0 \xec\xe5\xf1\xf2\xe5",
       "/b \xf2\xf3\xf2",
       "/b \xed\xf3 \xe1\xeb\xe8\xed(",
       "/b \xe4\xe0,\xf2\xf3\xf2 \xff",
       "/b \xee\xef\xe0 \xf2\xf3\xf2, \xe0 \xf7\xf2\xee",
       "/b \xe4\xe0 \xf1\xeb\xf3\xf8\xe0\xfe, \xed\xf3",
       "/b \xff \xe2 \xe8\xe3\xf0\xe5",
       "/b \xe0\xe3\xe0",
       "/b tyt",
       "/b \xe0 \xff \xed\xe5 \xef\xee\xed\xff\xeb,\xf7\xf2\xee \xf2\xe0\xec",
       "/b \xe0\xf3\xf4",
       "/b \xef\xf0\xe8\xf1\xf3\xf2\xf1\xf2\xe2\xf3\xfe",
       "/b \xe0 \xf7\xf2\xee \xf2\xe0\xec?",
       "/b \xe0 \xf7\xf2\xee, \xf7\xf2\xee?",
       "/b \xe4\xe0 \xf2\xf3\xf2",
       "/b \xf1\xeb\xf3\xf8\xe0\xfe",
       "/b daaaa",
       "/b na meste",
       "/b ya tyt",
       "/b \xe4\xe0 \xf2\xf3\xf2 \xff \xed\xe8\xea\xf3\xe4\xe0",
       "/b \xed\xf3 \xf2\xf3\xf2, \xe0 \xf7\xf2\xee",
       "/b \xf2\xe0\xea \xf2\xf3\xf2 \xff \xea\xee\xf0\xee\xf7\xe5",
       "/b \xe4\xe0 \xff \xf2\xf3\xf2",
       "/b \xf2\xf3\xf2\xe0 \xff",
       "/b \xed\xf3 \xe4\xe0, \xe0 \xf7\xf2\xee",
       "/b \xf2\xf3\xf2, \xec\xe8\xed\xf3\xf2\xf3",
       "/b \xed\xf3 \xf2\xf3\xf2, \xf1\xe5\xea\xf3\xed\xe4\xf3",
       "/b  \xe4\xe0, \xe0 \xf7\xf2\xee",
       "/b \xe4\xe0 \xff \xf2\xf3\xf2 \xef\xf0\xee\xf1\xf2\xee \xee\xf2\xee\xf8\xb8\xeb \xed\xe5\xec\xed\xee\xe3\xee, \xe0 \xf7\xf2\xee",
       "/b \xff \xf2\xf3\xf2 \xf3\xe6\xe5, \xf7\xf2\xee \xf2\xe0\xea\xee\xe5",
       "/b da tyt",
       "/b na meste ya",
       "/b im tyta",
       "/b \xf2\xf3\xf2 \xff \xea\xee\xf0\xee\xf7\xe5",
       "/b \xed\xf3 \xe4\xe0, \xff \xf2\xf3\xf2 \xf1\xe8\xe6\xf3",
       "/b \xf2\xf3\xf2, \xf7\xf2\xee \xf5\xee\xf2\xe5\xeb",
       "/b \xe4\xe0 \xed\xe0 \xec\xe5\xf1\xf2\xe5, \xe0 \xf7\xf2\xee",
       "/b \xed\xf3 \xf2\xf3\xf2 \xff \xf1\xe8\xe6\xf3, \xe6\xe4\xf3",
       "/b \xed\xf3 \xf2\xf3\xf2 \xff"
    }

local otvet_2 = {
       "/b \xff \xed\xe5 \xe0\xf4\xea \xef\xf0\xee\xf1\xf2\xee \xe4\xf3\xec\xe0\xeb, \xed\xe5 \xee\xf2\xe2\xe5\xf7\xe0\xeb, \xe8\xe7\xe2\xe8\xed\xe8",
       "/b \xff \xee\xf2\xf5\xee\xe4\xe8\xeb \xed\xe0 15 \xf1\xe5\xea\xf3\xed\xe4, \xed\xf3",
       "/b \xed\xf3 \xff \xf2\xf3\xf2 \xe1\xfb\xeb \xe2\xf1\xb8 \xe2\xf0\xe5\xec\xff, \xed\xf3",
       "/b \xf1\xe2\xff\xe7\xfc \xe1\xe0\xf0\xe0\xf5\xeb\xe8\xf2, \xed\xe5 \xf1\xf0\xe0\xe7\xf3",
       "/b 1%, \xef\xf0\xee\xf1\xf2\xee \xeb\xe0\xe3",
       "/b \xef\xe8\xf8\xf3 \xf1 \xf2\xe5\xeb\xe5\xf4\xee\xed\xe0, \xed\xe5 \xf3\xf1\xef\xe5\xeb",
       "/b \xef\xe8\xed\xe3 5 \xf2\xfb\xf1\xff\xf7 \xf3 \xec\xe5\xed\xff, \xe8 \xe8\xe3\xf0\xe0 \xf2\xe0\xea \xeb\xe0\xe3\xe0\xe5\xf2",
       "/b \xef\xf0\xee\xf1\xf2\xee \xe7\xe0\xe2\xe8\xf1 \xed\xe0 \xf7\xf3\xf2\xfc, \xed\xee \xff \xf2\xf3\xf2",
       "/b 2%, \xe4\xe0 \xed\xe5 \xe0\xf4\xea \xff \xed\xe8\xea\xe0\xea\xee\xe9",
       "/b \xe4\xe0 \xf2\xf3\xf2 \xff \xf1\xec\xee\xf2\xf0\xe5\xeb \xf7\xf3\xf2\xfc \xed\xe5 \xf2\xf3\xe4\xe0",
       "/b \xef\xe8\xf1\xe0\xeb \xe4\xf0\xf3\xe3 \xe8 \xff \xee\xf2\xe2\xeb\xb8\xea\xf1\xff",
       "/b \xed\xe5 \xf1\xf0\xe0\xe7\xf3 \xe7\xe0\xec\xe5\xf2\xe8\xeb \xf1\xee\xee\xe1\xf9\xe5\xed\xe8\xe5",
       "/b \xed\xf3 \xef\xf0\xee\xf1\xf2\xe8, \xe4\xee\xeb\xe3\xee \xef\xe8\xf1\xe0\xeb \xee\xf2\xe2\xe5\xf2 \xf2\xe5\xe1\xe5",
       "/b \xe4\xe0 \xff \xf1\xec\xee\xf2\xf0\xe5\xeb \xe2\xe8\xe4\xe5\xee \xe2 \xe4\xf0\xf3\xe3\xee\xec \xee\xea\xed\xe5",
       "/b \xf2\xe5\xeb\xe5\xf4\xee\xed \xe2 \xe4\xf0\xf3\xe3\xee\xe9 \xf0\xf3\xea\xe5 \xe4\xe5\xf0\xe6\xe0\xeb, \xe8\xe7\xe2\xe8\xed\xe8",
       "/b \xf2\xe5\xeb\xe5\xea \xed\xe0 \xf4\xee\xed\xe5 \xe1\xfb\xeb \xe8 \xee\xf2\xe2\xeb\xb8\xea\xf1\xff",
       "/b \xe8\xe7\xe2\xe8\xed\xe8, \xe7\xe0\xf1\xec\xee\xf2\xf0\xe5\xeb\xf1\xff \xf1\xeb\xe5\xe3\xea\xe0 \xe2 \xee\xea\xed\xee",
       "/b \xed\xf3 \xe4\xe0, \xf7\xf3\xf2\xfc \xf2\xee\xf0\xec\xee\xe7\xed\xf3\xeb, \xe1\xfb\xe2\xe0\xe5\xf2",
       "/b \xf2\xe0\xec \xe7\xe0 \xee\xea\xed\xee \xf7\xf2\xee-\xf2\xee \xe3\xeb\xff\xed\xf3\xeb, \xe4\xf3\xec\xe0\xeb \xea\xf2\xee \xe8\xe4\xb8\xf2 \xec\xe8\xec\xee",
       "/b \xf0\xf3\xea\xf3 \xee\xf2\xeb\xe5\xe6\xe0\xeb \xf1\xeb\xe5\xe3\xea\xe0, \xef\xee\xf2\xee\xec \xef\xe8\xf1\xe0\xeb",
       "/b \xea\xee\xec\xef \xed\xe5\xec\xed\xee\xe3\xee \xe7\xe0\xe2\xe8\xf1 \xf3 \xec\xe5\xed\xff",
       "/b \xe8\xe7\xe2\xe8\xed\xe8, \xee\xf2\xee\xf8\xb8\xeb \xef\xee\xef\xe8\xf2\xfc \xe2\xee\xe4\xfb \xed\xe0 \xea\xf3\xf5\xed\xfe",
       "/b \xe2\xe0\xed\xed\xf3 \xed\xe0\xe1\xe8\xf0\xe0\xeb, \xee\xf2\xf5\xee\xe4\xe8\xeb \xf7\xf3\xf2\xfc",
       "/b \xf1\xf3\xf8\xe8\xeb \xf0\xf3\xea\xe8, \xef\xee\xf2\xee\xec \xef\xe8\xf1\xe0\xeb \xf2\xe5\xe1\xe5",
       "/b \xf2\xe5\xeb\xe5\xf4\xee\xed \xe7\xe0\xf0\xff\xe6\xe0\xeb \xed\xe0 \xe4\xf0\xf3\xe3\xee\xec",
       "/b \xf7\xf3\xf2\xfc \xf3\xe6\xe8\xed \xf0\xe0\xe7\xee\xe3\xf0\xe5\xeb \xed\xe0 \xea\xf3\xf5\xed\xe5 \xf2\xe0\xec"
    }
local otvet_3 = {
       "\xe4\xe0 \xf2\xf3\xf2, \xff \xf1\xec\xee\xf2\xf0\xe5\xeb \xed\xe5 \xf2\xf3\xe4\xe0",
       "\xf2\xf3\xf2 \xff, \xed\xe5 \xf1\xf0\xe0\xe7\xf3",
       "\xed\xf3 \xf2\xf3\xf2",
       "\xe0\xe3\xe0, \xe0 \xf7\xf2\xee?",
       "xd, tyt",
       "\xe4\xe0",
       "da tyt"
    }

local gta = ffi.load('GTASA')
ffi.cdef[[
    void* _ZN4CPad6GetPadEi(int num);
    int8_t _ZN4CPad12JumpJustDownEv(void* thiz);
    uint8_t _ZN4CPad9GetSprintEi(void* thiz, int playerid);
    void _Z12AND_OpenLinkPKc(const char* link);
]]
local function openLink(url) pcall(gta._Z12AND_OpenLinkPKc, url) end

local jumping = false
local original_jump = nil

local nextJumpTime = 0
local doJumpThisFrame = false

local totalStone = 0
local totalMetal = 0
local totalSilver = 0
local totalBronze = 0
local totalGold = 0
local totalWorkTime = 0
local sessionWorkTime = 0

local PRICE_STONE  = 20000
local PRICE_METAL  = 45000
local PRICE_SILVER = 25000
local PRICE_BRONZE = 70000
local PRICE_GOLD   = 50000
local function getTotalEarned()
    return totalStone*PRICE_STONE + totalMetal*PRICE_METAL
         + totalSilver*PRICE_SILVER + totalBronze*PRICE_BRONZE
         + totalGold*PRICE_GOLD
end
local function formatMoney(n)
    local s = tostring(math.floor(n))
    local result = ''
    local len = #s
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then result = result .. '.' end
        result = result .. s:sub(i,i)
    end
    return '$' .. result
end
local isRunning = false
local original_sprint = nil
local resources = {}
local mainIni = inicfg.load({
    main = {
        currentConfig = "default",
        license_key = ""
    },
    food = {
        auto_eat = "false",
        mode = "0",
        food_row = "0",
        min_satiety = "80"
    },
    goal = {
        mode = "0",
        ore_amount = "1000",
        money = "1000000",
        minutes = "60",
        quit = "false"
    },
    protect = {
        auto_reply = "false",
        stop_dialog = "false",
        stop_tp = "false",
        stop_chat = "false",
        quit_on_stop = "false"
    },
    stats = {
        stone = "0", metal = "0", silver = "0", bronze = "0", gold = "0", work_time = "0"
    },
    prices = {
        stone = "20000", metal = "45000", silver = "25000", bronze = "70000", gold = "50000"
    },
    ui = {
        hide_fab = "true"
    },
    mask = {
        auto = "false"
    },
    sound = {
        eat = "true",
        aa = "true"
    },
    ai = {
        enabled = "false",
        provider = "0",
        key_claude = "",
        key_openai = "",
        key_gemini = "",
        key_groq = "",
        model = "",
        system = ""
    }
}, 'mbot.ini')
if not doesFileExist('moonloader/config/mbot.ini') then
    inicfg.save(mainIni, 'mbot.ini')
end

totalStone  = tonumber(mainIni.stats and mainIni.stats.stone)  or 0
totalMetal  = tonumber(mainIni.stats and mainIni.stats.metal)  or 0
totalSilver = tonumber(mainIni.stats and mainIni.stats.silver) or 0
totalBronze = tonumber(mainIni.stats and mainIni.stats.bronze) or 0
totalGold   = tonumber(mainIni.stats and mainIni.stats.gold)   or 0
totalWorkTime = tonumber(mainIni.stats and mainIni.stats.work_time) or 0
PRICE_STONE  = tonumber(mainIni.prices and mainIni.prices.stone)  or PRICE_STONE
PRICE_METAL  = tonumber(mainIni.prices and mainIni.prices.metal)  or PRICE_METAL
PRICE_SILVER = tonumber(mainIni.prices and mainIni.prices.silver) or PRICE_SILVER
PRICE_BRONZE = tonumber(mainIni.prices and mainIni.prices.bronze) or PRICE_BRONZE
PRICE_GOLD   = tonumber(mainIni.prices and mainIni.prices.gold)   or PRICE_GOLD

local function fmtTime(sec)
    sec = math.floor(sec)
    return string.format('%02d:%02d:%02d', math.floor(sec/3600), math.floor((sec%3600)/60), sec%60)
end

local _statsDirty = false
local function saveStats()
    mainIni.stats.stone  = tostring(totalStone)
    mainIni.stats.metal  = tostring(totalMetal)
    mainIni.stats.silver = tostring(totalSilver)
    mainIni.stats.bronze = tostring(totalBronze)
    mainIni.stats.gold   = tostring(totalGold)
    mainIni.stats.work_time = tostring(math.floor(totalWorkTime))
    inicfg.save(mainIni, 'mbot.ini')
    _statsDirty = false
end

local CHECK_URL = 'https://fragrant-waterfall-2a72.victorstrand250.workers.dev/'
local licenseKey      = (mainIni.main and mainIni.main.license_key) or ''
local licenseOK       = false
local licenseChecking = false
local licenseMsg      = ''
local licWinOpen  = imgui.new.bool(false)
local licInputBuf = imgui.new.char[64](licenseKey)

local function saveLicense()
    mainIni.main.license_key = tostring(licenseKey or '')
    inicfg.save(mainIni, 'mbot.ini')
end

local function bufToStr(buf, maxlen)
    local t = {}
    for i = 0, maxlen - 1 do
        local b = buf[i]
        if not b or b == 0 then break end
        t[#t + 1] = string.char(b)
    end
    return table.concat(t)
end

local function _keyExpired(ey, em, ed)
    local now = os.date('*t')
    return (tonumber(ey) < now.year)
        or (tonumber(ey) == now.year and tonumber(em) < now.month)
        or (tonumber(ey) == now.year and tonumber(em) == now.month and tonumber(ed) < now.day)
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
                sampAddChatMessage('{FFFF00}[ST Mine]{FFFFFF}: {00ff7f}'..'\xca\xeb\xfe\xf7 \xe0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xed!'..info, -1)
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

local autoEat           = (mainIni.food and tostring(mainIni.food.auto_eat) == 'true')
local autoEatMode       = tonumber(mainIni.food and mainIni.food.mode) or 0
local autoEatFood       = tonumber(mainIni.food and mainIni.food.food_row) or 0
local autoEatMinSatiety = tonumber(mainIni.food and mainIni.food.min_satiety) or 80
local autoEatSatiety    = -1
local autoEatWaitSat    = false
local autoEatWaitEat    = false
local autoEatLastEat    = 0
local larekRunning      = false

local goalMode      = tonumber(mainIni.goal and mainIni.goal.mode) or 0
local goalOreAmount = tonumber(mainIni.goal and mainIni.goal.ore_amount) or 1000
local goalMoney     = tonumber(mainIni.goal and mainIni.goal.money) or 1000000
local goalMinutes   = tonumber(mainIni.goal and mainIni.goal.minutes) or 60
local goalQuit      = (mainIni.goal and tostring(mainIni.goal.quit) == 'true')
local goalReached   = false

local aaState      = (mainIni.protect and tostring(mainIni.protect.auto_reply) == 'true')
local stopOnDialog = (mainIni.protect and tostring(mainIni.protect.stop_dialog) == 'true')
local stopOnTp     = (mainIni.protect and tostring(mainIni.protect.stop_tp) == 'true')
local stopOnChat   = (mainIni.protect and tostring(mainIni.protect.stop_chat) == 'true')
local quitOnStop   = (mainIni.protect and tostring(mainIni.protect.quit_on_stop) == 'true')
local antiAdminEnableTime = 0
local aaAngry       = 0
local aaTimes       = os.clock()
local aaReplying    = false
local aaLastQuestion = nil
local aaLastTrigger = 0

local fabHidden     = not (mainIni.ui and tostring(mainIni.ui.hide_fab) == 'false')

autoMask      = (mainIni.mask and tostring(mainIni.mask.auto) == 'true')
maskNextTime  = 0
maskConfirmed = false

local soundEatEnabled = not (mainIni.sound and tostring(mainIni.sound.eat) == 'false')
local soundAAEnabled  = not (mainIni.sound and tostring(mainIni.sound.aa)  == 'false')

ai = {
    DEFAULT_SYSTEM = "Ты — обычный живой игрок на русском SAMP RP сервере, прямо сейчас добываешь руду в шахте. Иногда администратор пишет тебе в чат, чтобы проверить, что ты не бот/не используешь читы. Твоя задача: ответить максимально естественно, коротко и по-человечески, как настоящий игрок, чтобы развеять подозрения. Пиши простым разговорным языком, маленькими буквами, обычно без знаков препинания в конце, допускаются лёгкие опечатки и сленг. НЕ используй кавычки, НЕ пиши пояснений и НЕ описывай ситуацию — выдавай ТОЛЬКО сам текст ответа одной короткой фразой (до 100 символов). Если админ задаёт конкретный вопрос (математика, возраст, город, что делаешь) — отвечай правдоподобно и кратко.",
    CLASSIFY_SYSTEM = "Ты — фильтр сообщений на русском SAMP RP сервере. Тебе приходит одно сообщение от администратора из игрового чата. Реши, обращается ли админ ЛИЧНО к этому игроку и требует ли это сообщение ответа. Личное обращение — это когда админ проверяет именно тебя: спрашивает 'ты тут?', 'ответь', обращается по нику, телепортировал лично тебя, ответил лично тебе на твой вопрос. Массовое объявление — это глобальные события и мероприятия (МП, рулетка, розыгрыш), реклама, премии, набор на работу, 'Уважаемые игроки', объявления для всех — такие сообщения НЕ требуют ответа. Ответь СТРОГО одним английским словом без знаков препинания и пояснений: YES — если это личное обращение к игроку, требующее ответа; NO — если это массовое объявление/событие и отвечать не нужно.",
    enabled   = true,
    provider  = 3,
    keyClaude = (mainIni.ai and mainIni.ai.key_claude) or '',
    keyOpenAI = (mainIni.ai and mainIni.ai.key_openai) or '',
    keyGemini = (mainIni.ai and mainIni.ai.key_gemini) or '',
    keyGroq   = (mainIni.ai and mainIni.ai.key_groq) or '',
    model     = (mainIni.ai and mainIni.ai.model) or '',
    testAnswer = '',
    testBusy   = false,
    testLog   = {},
    lastAdminName = '',
}
ai.system = (mainIni.ai and mainIni.ai.system ~= nil and mainIni.ai.system ~= '' and mainIni.ai.system) or ai.DEFAULT_SYSTEM

ai.keyClaudeBuf = imgui.new.char[257](ai.keyClaude)
ai.keyOpenAIBuf = imgui.new.char[257](ai.keyOpenAI)
ai.keyGeminiBuf = imgui.new.char[257](ai.keyGemini)
ai.keyGroqBuf   = imgui.new.char[257](ai.keyGroq)
ai.modelBuf     = imgui.new.char[64](ai.model)
ai.systemBuf    = imgui.new.char[2049](ai.system)

function ai.save()
    mainIni.ai = mainIni.ai or {}
    mainIni.ai.enabled    = tostring(ai.enabled)
    mainIni.ai.provider   = tostring(ai.provider)
    mainIni.ai.key_claude = ai.keyClaude
    mainIni.ai.key_openai = ai.keyOpenAI
    mainIni.ai.key_gemini = ai.keyGemini
    mainIni.ai.key_groq   = ai.keyGroq
    mainIni.ai.model      = ai.model
    mainIni.ai.system     = ai.system
    inicfg.save(mainIni, 'mbot.ini')
end

function ai.activeKey()
    if ai.provider == 0 then return ai.keyClaude
    elseif ai.provider == 1 then return ai.keyOpenAI
    elseif ai.provider == 2 then return ai.keyGemini
    else return ai.keyGroq end
end
math.randomseed(os.time() % 2147483647)

local function saveCfg()
    mainIni.food.auto_eat    = tostring(autoEat)
    mainIni.food.mode        = tostring(autoEatMode)
    mainIni.food.food_row    = tostring(autoEatFood)
    mainIni.food.min_satiety = tostring(autoEatMinSatiety)
    mainIni.goal.mode        = tostring(goalMode)
    mainIni.goal.ore_amount  = tostring(goalOreAmount)
    mainIni.goal.money       = tostring(goalMoney)
    mainIni.goal.minutes     = tostring(goalMinutes)
    mainIni.goal.quit        = tostring(goalQuit)
    mainIni.ui.hide_fab          = tostring(fabHidden)
    mainIni.mask = mainIni.mask or {}
    mainIni.mask.auto            = tostring(autoMask)
    mainIni.protect.auto_reply   = tostring(aaState)
    mainIni.protect.stop_dialog  = tostring(stopOnDialog)
    mainIni.protect.stop_tp      = tostring(stopOnTp)
    mainIni.protect.stop_chat    = tostring(stopOnChat)
    mainIni.protect.quit_on_stop = tostring(quitOnStop)
    mainIni.sound = mainIni.sound or {}
    mainIni.sound.eat = tostring(soundEatEnabled)
    mainIni.sound.aa  = tostring(soundAAEnabled)
    inicfg.save(mainIni, 'mbot.ini')
end

lua_thread.create(function()
    while true do
        wait(1000)
        if autoMask and isSampAvailable() and os.time() >= maskNextTime then
            maskConfirmed = false
            sampSendChat('/mask')
            wait(2000)
            if not maskConfirmed then
                sampSendChat('/mask')
            end
            maskNextTime = os.time() + 20 * 60
        end
    end
end)

local function sprint_hook(thiz, playerid)
    if isRunning and playerid == 0 then
        return 1
    end
    return original_sprint(thiz, playerid)
end

local localPad = gta._ZN4CPad6GetPadEi(0)

local function jump_hook(thiz)
    if doJumpThisFrame and thiz == localPad then
        return true
    end

    if original_jump == nil then
        return false
    end

    return original_jump(thiz)
end

original_sprint = hook.new('uint8_t(*)(void*, int)', sprint_hook,
                           ffi.cast('uintptr_t', ffi.cast('void*', gta._ZN4CPad9GetSprintEi)))
original_jump = hook.new(
    "int8_t(*)(void*)",
    jump_hook,
    ffi.cast("uintptr_t", gta._ZN4CPad12JumpJustDownEv)
)

function toggleJump()
    jumping = not jumping
    if jumping then
        sampAddChatMessage("[ST Mine]: \xcf\xf0\xfb\xe6\xea\xe8 \xe2\xea\xeb\xfe\xf7\xe5\xed\xfb!", -1)
        nextJumpTime = os.clock() + math.random(20, 40)
    else
        sampAddChatMessage("[ST Mine]: \xcf\xf0\xfb\xe6\xea\xe8 \xee\xf2\xea\xeb\xfe\xf7\xe5\xed\xfb!", -1)
    end
end

function autoJumpThread()
    while true do
        wait(0)

        doJumpThisFrame = false
        if jumping then
            local t = os.clock()
            if t >= nextJumpTime then
                doJumpThisFrame = true
                nextJumpTime = t + math.random(20, 30)
            end
        end
    end
end

function toggleRun()
    isRunning = not isRunning
    if isRunning then
        sampAddChatMessage("[ST Mine] \xc1\xe5\xe3 \xe2\xea\xeb\xfe\xf7\xe5\xed!", 0xFFFFFFFF)
    else
        sampAddChatMessage("[ST Mine] \xc1\xe5\xe3 \xee\xf2\xea\xeb\xfe\xf7\xe5\xed!", 0xFFFFFFFF)
    end
end

local recordedRoute = {
    {x = 489.339, y = 884.829, z = -30.905, action = "FORWARD"},
    {x = 487.838, y = 886.883, z = -30.888, action = "FORWARD"},
    {x = 486.008, y = 888.752, z = -30.772, action = "FORWARD"},
    {x = 483.489, y = 889.431, z = -30.618, action = "FORWARD"},
    {x = 481.596, y = 887.658, z = -30.511, action = "FORWARD"},
    {x = 480.047, y = 885.489, z = -30.426, action = "FORWARD"},
    {x = 478.962, y = 883.162, z = -30.369, action = "FORWARD"},
    {x = 477.682, y = 880.862, z = -30.301, action = "FORWARD"},
    {x = 475.496, y = 879.622, z = -30.034, action = "FORWARD"},
    {x = 472.919, y = 879.796, z = -29.668, action = "FORWARD"},
    {x = 471.004, y = 881.548, z = -29.390, action = "FORWARD"},
    {x = 469.695, y = 883.687, z = -29.140, action = "FORWARD"},
    {x = 469.164, y = 886.199, z = -29.017, action = "FORWARD"},
    {x = 467.233, y = 887.912, z = -28.709, action = "FORWARD"},
    {x = 464.682, y = 887.985, z = -28.322, action = "FORWARD"},
    {x = 462.262, y = 887.366, z = -28.007, action = "FORWARD"},
    {x = 461.687, y = 884.899, z = -28.013, action = "FORWARD"},
    {x = 461.477, y = 882.324, z = -28.072, action = "FORWARD"},
    {x = 461.418, y = 879.707, z = -27.989, action = "FORWARD"},
    {x = 461.588, y = 877.130, z = -27.842, action = "FORWARD"},
    {x = 462.707, y = 874.773, z = -27.862, action = "FORWARD"},
    {x = 463.981, y = 872.513, z = -27.912, action = "FORWARD"},
    {x = 466.337, y = 871.486, z = -28.220, action = "FORWARD"},
    {x = 468.873, y = 870.894, z = -28.585, action = "FORWARD"},
    {x = 471.100, y = 869.626, z = -28.855, action = "FORWARD"},
    {x = 473.716, y = 869.387, z = -29.257, action = "FORWARD"},
    {x = 476.118, y = 870.013, z = -29.683, action = "FORWARD"},
    {x = 478.385, y = 871.060, z = -30.070, action = "FORWARD"},
    {x = 480.549, y = 872.335, z = -30.373, action = "FORWARD"},
    {x = 482.677, y = 873.656, z = -30.597, action = "FORWARD"},
    {x = 485.181, y = 873.541, z = -30.816, action = "FORWARD"},
    {x = 487.488, y = 872.591, z = -30.994, action = "FORWARD"},
    {x = 489.408, y = 870.930, z = -31.279, action = "FORWARD"},
    {x = 491.158, y = 869.166, z = -31.578, action = "FORWARD"},
    {x = 493.109, y = 867.435, z = -31.465, action = "FORWARD"},
    {x = 494.194, y = 865.078, z = -31.095, action = "FORWARD"},
    {x = 493.901, y = 862.644, z = -30.575, action = "FORWARD"},
    {x = 493.169, y = 860.286, z = -30.027, action = "FORWARD"},
    {x = 492.483, y = 857.787, z = -29.898, action = "FORWARD"},
    {x = 493.770, y = 855.592, z = -29.833, action = "FORWARD"},
    {x = 495.187, y = 853.467, z = -29.839, action = "FORWARD"},
    {x = 496.449, y = 851.158, z = -29.889, action = "FORWARD"},
    {x = 497.780, y = 848.894, z = -29.723, action = "FORWARD"},
    {x = 499.321, y = 846.821, z = -29.410, action = "FORWARD"},
    {x = 501.095, y = 844.846, z = -29.194, action = "FORWARD"},
    {x = 502.918, y = 842.969, z = -29.054, action = "FORWARD"},
    {x = 504.793, y = 841.197, z = -28.611, action = "FORWARD"},
    {x = 506.707, y = 839.452, z = -28.167, action = "FORWARD"},
    {x = 508.691, y = 837.812, z = -27.711, action = "FORWARD"},
    {x = 510.595, y = 836.158, z = -26.992, action = "FORWARD"},
    {x = 512.422, y = 834.330, z = -26.497, action = "FORWARD"},
    {x = 513.737, y = 832.153, z = -25.880, action = "FORWARD"},
    {x = 514.823, y = 829.753, z = -25.489, action = "FORWARD"},
    {x = 515.650, y = 827.312, z = -25.279, action = "FORWARD"},
    {x = 516.178, y = 824.730, z = -25.082, action = "FORWARD"},
    {x = 516.240, y = 822.182, z = -24.834, action = "FORWARD"},
    {x = 516.048, y = 819.538, z = -24.547, action = "FORWARD"},
    {x = 516.068, y = 816.948, z = -24.259, action = "FORWARD"},
    {x = 516.080, y = 814.446, z = -24.133, action = "FORWARD"},
    {x = 515.923, y = 812.006, z = -23.551, action = "FORWARD"},
    {x = 514.190, y = 810.152, z = -23.164, action = "FORWARD"},
    {x = 511.709, y = 809.443, z = -22.811, action = "FORWARD"},
    {x = 509.495, y = 808.083, z = -22.442, action = "FORWARD"},
    {x = 507.648, y = 806.269, z = -22.071, action = "FORWARD"},
    {x = 505.540, y = 804.781, z = -21.945, action = "FORWARD"},
    {x = 503.512, y = 803.135, z = -21.945, action = "FORWARD"},
    {x = 502.024, y = 800.968, z = -21.951, action = "FORWARD"},
    {x = 500.769, y = 798.676, z = -21.959, action = "FORWARD"},
    {x = 500.471, y = 796.083, z = -21.965, action = "FORWARD"},
    {x = 499.832, y = 793.557, z = -22.004, action = "FORWARD"},
    {x = 499.187, y = 791.015, z = -22.057, action = "FORWARD"},
    {x = 501.392, y = 789.667, z = -22.081, action = "FORWARD"},
    {x = 503.716, y = 790.813, z = -22.055, action = "FORWARD"},
    {x = 506.214, y = 791.611, z = -22.042, action = "FORWARD"},
    {x = 508.784, y = 791.413, z = -22.055, action = "FORWARD"},
    {x = 511.301, y = 790.629, z = -22.050, action = "FORWARD"},
    {x = 513.928, y = 790.300, z = -21.879, action = "FORWARD"},
    {x = 516.528, y = 790.077, z = -21.708, action = "FORWARD"},
    {x = 519.138, y = 790.004, z = -21.532, action = "FORWARD"},
    {x = 521.749, y = 790.019, z = -21.354, action = "FORWARD"},
    {x = 524.351, y = 790.060, z = -21.175, action = "FORWARD"},
    {x = 527.006, y = 790.039, z = -20.995, action = "FORWARD"},
    {x = 529.531, y = 789.518, z = -20.801, action = "FORWARD"},
    {x = 532.074, y = 788.854, z = -20.540, action = "FORWARD"},
    {x = 534.546, y = 788.201, z = -20.259, action = "FORWARD"},
    {x = 536.772, y = 787.013, z = -19.988, action = "FORWARD"},
    {x = 539.018, y = 785.805, z = -19.713, action = "FORWARD"},
    {x = 541.346, y = 784.925, z = -19.441, action = "FORWARD"},
    {x = 543.785, y = 784.133, z = -19.159, action = "FORWARD"},
    {x = 546.262, y = 783.218, z = -18.877, action = "FORWARD"},
    {x = 548.568, y = 782.126, z = -18.643, action = "FORWARD"},
    {x = 550.897, y = 781.192, z = -18.410, action = "FORWARD"},
    {x = 553.371, y = 780.577, z = -18.178, action = "FORWARD"},
    {x = 555.916, y = 779.699, z = -17.939, action = "FORWARD"},
    {x = 557.636, y = 777.854, z = -17.777, action = "FORWARD"},
    {x = 559.091, y = 775.690, z = -17.623, action = "FORWARD"},
    {x = 560.884, y = 773.819, z = -17.374, action = "FORWARD"},
    {x = 562.859, y = 772.143, z = -17.114, action = "FORWARD"},
    {x = 564.792, y = 770.396, z = -16.855, action = "FORWARD"},
    {x = 566.785, y = 768.767, z = -16.595, action = "FORWARD"},
    {x = 568.036, y = 766.565, z = -16.524, action = "FORWARD"},
    {x = 566.103, y = 764.799, z = -16.585, action = "FORWARD"},
    {x = 563.577, y = 764.582, z = -16.787, action = "FORWARD"},
    {x = 561.550, y = 766.191, z = -17.051, action = "FORWARD"},
    {x = 559.891, y = 768.056, z = -17.285, action = "FORWARD"},
    {x = 557.737, y = 769.543, z = -17.558, action = "FORWARD"},
    {x = 555.523, y = 770.836, z = -17.831, action = "FORWARD"},
    {x = 553.206, y = 772.101, z = -18.114, action = "FORWARD"},
    {x = 550.953, y = 773.284, z = -18.387, action = "FORWARD"},
    {x = 548.744, y = 774.457, z = -18.605, action = "FORWARD"},
    {x = 546.488, y = 775.652, z = -18.817, action = "FORWARD"},
    {x = 544.033, y = 776.662, z = -19.065, action = "FORWARD"},
    {x = 541.629, y = 777.443, z = -19.307, action = "FORWARD"},
    {x = 539.168, y = 778.161, z = -19.555, action = "FORWARD"},
    {x = 536.720, y = 778.782, z = -19.801, action = "FORWARD"},
    {x = 534.277, y = 779.355, z = -20.046, action = "FORWARD"},
    {x = 531.968, y = 780.400, z = -20.295, action = "FORWARD"},
    {x = 529.702, y = 781.442, z = -20.567, action = "FORWARD"},
    {x = 527.608, y = 782.858, z = -20.831, action = "FORWARD"},
    {x = 525.840, y = 784.632, z = -21.052, action = "FORWARD"},
    {x = 523.998, y = 786.391, z = -21.237, action = "FORWARD"},
    {x = 522.158, y = 788.086, z = -21.376, action = "FORWARD"},
    {x = 520.356, y = 789.941, z = -21.451, action = "FORWARD"},
    {x = 518.664, y = 791.827, z = -21.516, action = "FORWARD"},
    {x = 517.876, y = 794.246, z = -21.507, action = "FORWARD"},
    {x = 517.453, y = 796.854, z = -21.820, action = "FORWARD"},
    {x = 517.396, y = 799.325, z = -22.319, action = "FORWARD"},
    {x = 517.700, y = 801.788, z = -22.762, action = "FORWARD"},
    {x = 518.122, y = 804.278, z = -23.038, action = "FORWARD"},
    {x = 518.465, y = 806.790, z = -23.309, action = "FORWARD"},
    {x = 518.171, y = 809.300, z = -23.526, action = "FORWARD"},
    {x = 517.739, y = 811.737, z = -23.991, action = "FORWARD"},
    {x = 517.332, y = 814.203, z = -24.294, action = "FORWARD"},
    {x = 517.351, y = 816.854, z = -24.429, action = "FORWARD"},
    {x = 519.548, y = 818.193, z = -24.819, action = "FORWARD"},
    {x = 521.610, y = 819.685, z = -25.207, action = "FORWARD"},
    {x = 523.431, y = 821.577, z = -25.608, action = "FORWARD"},
    {x = 525.708, y = 822.594, z = -25.974, action = "FORWARD"},
    {x = 527.792, y = 821.138, z = -26.248, action = "FORWARD"},
    {x = 529.240, y = 818.977, z = -26.422, action = "FORWARD"},
    {x = 530.154, y = 816.538, z = -26.470, action = "FORWARD"},
    {x = 530.667, y = 813.968, z = -26.442, action = "FORWARD"},
    {x = 531.352, y = 811.444, z = -26.416, action = "FORWARD"},
    {x = 531.860, y = 808.902, z = -26.130, action = "FORWARD"},
    {x = 533.604, y = 807.110, z = -25.627, action = "FORWARD"},
    {x = 536.013, y = 806.209, z = -25.430, action = "FORWARD"},
    {x = 538.574, y = 805.565, z = -25.320, action = "FORWARD"},
    {x = 540.935, y = 804.538, z = -25.082, action = "FORWARD"},
    {x = 543.394, y = 803.586, z = -24.871, action = "FORWARD"},
    {x = 545.875, y = 802.863, z = -24.851, action = "FORWARD"},
    {x = 548.465, y = 802.417, z = -25.185, action = "FORWARD"},
    {x = 550.885, y = 801.802, z = -25.780, action = "FORWARD"},
    {x = 553.191, y = 801.014, z = -26.342, action = "FORWARD"},
    {x = 555.666, y = 800.532, z = -26.955, action = "FORWARD"},
    {x = 558.225, y = 800.378, z = -27.597, action = "FORWARD"},
    {x = 560.674, y = 799.887, z = -28.204, action = "FORWARD"},
    {x = 563.281, y = 799.918, z = -28.291, action = "FORWARD"},
    {x = 565.838, y = 800.369, z = -28.289, action = "FORWARD"},
    {x = 568.370, y = 800.906, z = -28.388, action = "FORWARD"},
    {x = 570.949, y = 800.702, z = -28.590, action = "FORWARD"},
    {x = 573.247, y = 799.544, z = -28.795, action = "FORWARD"},
    {x = 575.199, y = 797.809, z = -28.988, action = "FORWARD"},
    {x = 576.797, y = 795.770, z = -29.162, action = "FORWARD"},
    {x = 579.022, y = 794.466, z = -29.511, action = "FORWARD"},
    {x = 581.232, y = 793.153, z = -29.799, action = "FORWARD"},
    {x = 583.087, y = 791.345, z = -30.025, action = "FORWARD"},
    {x = 585.569, y = 791.070, z = -30.313, action = "FORWARD"},
    {x = 588.089, y = 791.743, z = -30.600, action = "FORWARD"},
    {x = 590.615, y = 791.695, z = -30.892, action = "FORWARD"},
    {x = 593.150, y = 791.344, z = -31.187, action = "FORWARD"},
    {x = 595.657, y = 790.539, z = -31.482, action = "FORWARD"},
    {x = 598.224, y = 790.169, z = -31.781, action = "FORWARD"},
    {x = 600.846, y = 789.766, z = -32.075, action = "FORWARD"},
    {x = 603.107, y = 788.623, z = -32.078, action = "FORWARD"},
    {x = 604.920, y = 786.847, z = -32.084, action = "FORWARD"},
    {x = 606.741, y = 785.076, z = -32.087, action = "FORWARD"},
    {x = 608.566, y = 783.311, z = -32.091, action = "FORWARD"},
    {x = 610.476, y = 781.650, z = -32.093, action = "FORWARD"},
    {x = 612.476, y = 780.098, z = -32.096, action = "FORWARD"},
    {x = 614.487, y = 778.550, z = -32.098, action = "FORWARD"},
    {x = 616.471, y = 776.987, z = -32.100, action = "FORWARD"},
    {x = 618.902, y = 776.103, z = -32.100, action = "FORWARD"},
    {x = 621.418, y = 776.460, z = -31.950, action = "FORWARD"},
    {x = 623.947, y = 776.774, z = -31.739, action = "FORWARD"},
    {x = 626.588, y = 777.105, z = -31.532, action = "FORWARD"},
    {x = 629.185, y = 777.639, z = -31.326, action = "FORWARD"},
    {x = 631.768, y = 777.966, z = -31.124, action = "FORWARD"},
    {x = 634.349, y = 777.911, z = -30.928, action = "FORWARD"},
    {x = 636.929, y = 777.554, z = -30.737, action = "FORWARD"},
    {x = 639.398, y = 777.193, z = -30.555, action = "FORWARD"},
    {x = 642.009, y = 777.054, z = -30.358, action = "FORWARD"},
    {x = 644.626, y = 776.928, z = -30.243, action = "FORWARD"},
    {x = 647.272, y = 776.919, z = -30.244, action = "FORWARD"},
    {x = 649.884, y = 776.975, z = -30.245, action = "FORWARD"},
    {x = 652.164, y = 778.119, z = -30.242, action = "FORWARD"},
    {x = 653.987, y = 780.052, z = -30.236, action = "FORWARD"},
    {x = 655.829, y = 781.902, z = -30.231, action = "FORWARD"},
    {x = 657.947, y = 783.474, z = -30.226, action = "FORWARD"},
    {x = 659.968, y = 785.086, z = -30.222, action = "FORWARD"},
    {x = 661.845, y = 786.951, z = -30.217, action = "FORWARD"},
    {x = 663.727, y = 788.701, z = -30.213, action = "FORWARD"},
    {x = 666.039, y = 789.837, z = -30.212, action = "FORWARD"},
    {x = 668.578, y = 789.511, z = -30.216, action = "FORWARD"},
    {x = 671.084, y = 789.139, z = -30.221, action = "FORWARD"},
    {x = 673.631, y = 788.931, z = -30.228, action = "FORWARD"},
    {x = 676.188, y = 788.742, z = -30.235, action = "FORWARD"},
    {x = 678.701, y = 788.287, z = -30.239, action = "FORWARD"},
    {x = 681.331, y = 788.042, z = -30.242, action = "FORWARD"},
    {x = 683.966, y = 788.063, z = -30.245, action = "FORWARD"},
    {x = 686.446, y = 788.394, z = -30.246, action = "FORWARD"},
    {x = 688.463, y = 789.991, z = -30.244, action = "FORWARD"},
    {x = 689.739, y = 792.250, z = -30.242, action = "FORWARD"},
    {x = 690.968, y = 794.547, z = -30.239, action = "FORWARD"},
    {x = 692.300, y = 796.809, z = -30.235, action = "FORWARD"},
    {x = 693.300, y = 799.227, z = -30.231, action = "FORWARD"},
    {x = 694.444, y = 801.579, z = -30.059, action = "FORWARD"},
    {x = 695.331, y = 804.037, z = -29.905, action = "FORWARD"},
    {x = 697.012, y = 805.923, z = -29.853, action = "FORWARD"},
    {x = 699.588, y = 806.441, z = -30.022, action = "FORWARD"},
    {x = 702.213, y = 806.778, z = -30.206, action = "FORWARD"},
    {x = 704.757, y = 807.669, z = -30.237, action = "FORWARD"},
    {x = 706.937, y = 809.085, z = -30.240, action = "FORWARD"},
    {x = 709.038, y = 810.676, z = -30.242, action = "FORWARD"},
    {x = 711.075, y = 812.275, z = -30.245, action = "FORWARD"},
    {x = 713.164, y = 813.896, z = -30.249, action = "FORWARD"},
    {x = 715.034, y = 815.734, z = -30.252, action = "FORWARD"},
    {x = 716.399, y = 817.880, z = -30.026, action = "FORWARD"},
    {x = 717.281, y = 820.209, z = -30.253, action = "FORWARD"},
    {x = 716.941, y = 822.784, z = -30.250, action = "FORWARD"},
    {x = 716.362, y = 825.232, z = -30.246, action = "FORWARD"},
    {x = 715.261, y = 827.549, z = -30.242, action = "FORWARD"},
    {x = 714.152, y = 829.963, z = -30.237, action = "FORWARD"},
    {x = 713.353, y = 832.388, z = -30.234, action = "FORWARD"},
    {x = 713.062, y = 834.978, z = -29.900, action = "FORWARD"},
    {x = 713.485, y = 837.431, z = -30.230, action = "FORWARD"},
    {x = 714.591, y = 839.773, z = -30.231, action = "FORWARD"},
    {x = 716.096, y = 841.931, z = -30.234, action = "FORWARD"},
    {x = 717.150, y = 844.313, z = -30.237, action = "FORWARD"},
    {x = 718.355, y = 846.616, z = -30.241, action = "FORWARD"},
    {x = 719.597, y = 848.924, z = -30.070, action = "FORWARD"},
    {x = 720.267, y = 851.343, z = -30.246, action = "FORWARD"},
    {x = 720.734, y = 853.918, z = -30.246, action = "FORWARD"},
    {x = 721.201, y = 856.495, z = -30.172, action = "FORWARD"},
    {x = 721.482, y = 859.064, z = -29.644, action = "FORWARD"},
    {x = 721.538, y = 861.633, z = -29.125, action = "FORWARD"},
    {x = 721.507, y = 864.207, z = -28.609, action = "FORWARD"},
    {x = 721.306, y = 866.778, z = -28.101, action = "FORWARD"},
    {x = 721.027, y = 869.319, z = -27.602, action = "FORWARD"},
    {x = 720.585, y = 871.877, z = -27.106, action = "FORWARD"},
    {x = 720.018, y = 874.389, z = -26.983, action = "FORWARD"},
    {x = 719.271, y = 876.951, z = -27.006, action = "FORWARD"},
    {x = 718.366, y = 879.376, z = -26.911, action = "FORWARD"},
    {x = 717.349, y = 881.676, z = -26.864, action = "FORWARD"},
    {x = 716.198, y = 883.971, z = -26.922, action = "FORWARD"},
    {x = 714.973, y = 886.189, z = -27.004, action = "FORWARD"},
    {x = 713.726, y = 888.428, z = -27.122, action = "FORWARD"},
    {x = 712.552, y = 890.809, z = -27.246, action = "FORWARD"},
    {x = 711.581, y = 893.168, z = -27.384, action = "FORWARD"},
    {x = 710.612, y = 895.461, z = -27.644, action = "FORWARD"},
    {x = 709.617, y = 897.763, z = -28.211, action = "FORWARD"},
    {x = 708.664, y = 899.974, z = -28.959, action = "FORWARD"},
    {x = 707.731, y = 902.224, z = -29.751, action = "FORWARD"},
    {x = 706.829, y = 904.439, z = -30.531, action = "FORWARD"},
    {x = 705.885, y = 906.812, z = -30.484, action = "FORWARD"},
    {x = 704.947, y = 909.180, z = -30.443, action = "FORWARD"},
    {x = 703.984, y = 911.595, z = -30.406, action = "FORWARD"},
    {x = 703.057, y = 913.918, z = -30.371, action = "FORWARD"},
    {x = 702.126, y = 916.300, z = -30.361, action = "FORWARD"},
    {x = 701.218, y = 918.672, z = -30.276, action = "FORWARD"},
    {x = 700.316, y = 921.067, z = -30.247, action = "FORWARD"},
    {x = 699.368, y = 923.418, z = -30.244, action = "FORWARD"},
    {x = 697.878, y = 925.591, z = -30.237, action = "FORWARD"},
    {x = 696.432, y = 927.660, z = -30.230, action = "FORWARD"},
    {x = 695.078, y = 929.834, z = -30.231, action = "FORWARD"},
    {x = 693.873, y = 932.039, z = -30.234, action = "FORWARD"},
    {x = 692.788, y = 934.349, z = -30.237, action = "FORWARD"},
    {x = 691.668, y = 936.593, z = -30.241, action = "FORWARD"},
    {x = 690.379, y = 938.803, z = -30.243, action = "FORWARD"},
    {x = 688.856, y = 940.878, z = -30.367, action = "FORWARD"},
    {x = 687.048, y = 942.668, z = -30.706, action = "FORWARD"},
    {x = 685.048, y = 944.168, z = -31.034, action = "FORWARD"},
    {x = 682.983, y = 945.651, z = -31.440, action = "FORWARD"},
    {x = 680.814, y = 946.835, z = -31.842, action = "FORWARD"},
    {x = 678.527, y = 947.808, z = -32.153, action = "FORWARD"},
    {x = 676.130, y = 948.898, z = -32.487, action = "FORWARD"},
    {x = 673.890, y = 950.089, z = -32.840, action = "FORWARD"},
    {x = 671.678, y = 951.233, z = -33.089, action = "FORWARD"},
    {x = 669.403, y = 952.422, z = -33.327, action = "FORWARD"},
    {x = 667.158, y = 953.538, z = -33.630, action = "FORWARD"},
    {x = 664.856, y = 954.592, z = -33.967, action = "FORWARD"},
    {x = 662.309, y = 955.031, z = -34.299, action = "FORWARD"},
    {x = 659.740, y = 954.869, z = -34.340, action = "FORWARD"},
    {x = 657.271, y = 954.338, z = -34.412, action = "FORWARD"},
    {x = 654.865, y = 953.406, z = -34.519, action = "FORWARD"},
    {x = 652.470, y = 952.634, z = -34.602, action = "FORWARD"},
    {x = 650.405, y = 951.090, z = -34.734, action = "FORWARD"},
    {x = 648.485, y = 949.372, z = -34.862, action = "FORWARD"},
    {x = 647.518, y = 946.922, z = -35.048, action = "FORWARD"},
    {x = 646.689, y = 944.474, z = -35.233, action = "FORWARD"},
    {x = 646.549, y = 941.930, z = -35.641, action = "FORWARD"},
    {x = 647.617, y = 939.611, z = -35.851, action = "FORWARD"},
    {x = 649.149, y = 937.830, z = -36.720, action = "FORWARD"},
    {x = 651.545, y = 936.817, z = -37.025, action = "FORWARD"},
    {x = 654.138, y = 936.632, z = -37.126, action = "FORWARD"},
    {x = 656.744, y = 936.597, z = -37.216, action = "FORWARD"},
    {x = 659.277, y = 936.290, z = -37.797, action = "FORWARD"},
    {x = 661.261, y = 934.771, z = -38.628, action = "FORWARD"},
    {x = 662.597, y = 932.774, z = -39.475, action = "FORWARD"},
    {x = 661.372, y = 930.458, z = -39.922, action = "FORWARD"},
    {x = 659.124, y = 929.347, z = -39.815, action = "FORWARD"},
    {x = 656.654, y = 929.421, z = -39.316, action = "FORWARD"},
    {x = 654.214, y = 929.918, z = -38.804, action = "FORWARD"},
    {x = 651.841, y = 930.745, z = -38.547, action = "FORWARD"},
    {x = 649.703, y = 932.014, z = -38.184, action = "FORWARD"},
    {x = 648.321, y = 934.041, z = -37.649, action = "FORWARD"},
    {x = 647.665, y = 936.399, z = -37.046, action = "FORWARD"},
    {x = 647.698, y = 938.846, z = -36.436, action = "FORWARD"},
    {x = 647.920, y = 941.206, z = -35.448, action = "FORWARD"},
    {x = 647.479, y = 943.811, z = -35.268, action = "FORWARD"},
    {x = 646.654, y = 946.300, z = -35.092, action = "FORWARD"},
    {x = 646.372, y = 948.880, z = -34.891, action = "FORWARD"},
    {x = 646.291, y = 951.507, z = -34.685, action = "FORWARD"},
    {x = 645.694, y = 954.033, z = -34.463, action = "FORWARD"},
    {x = 644.092, y = 956.096, z = -34.131, action = "FORWARD"},
    {x = 641.564, y = 956.498, z = -34.327, action = "FORWARD"},
    {x = 638.932, y = 956.059, z = -34.413, action = "FORWARD"},
    {x = 636.439, y = 955.430, z = -34.513, action = "FORWARD"},
    {x = 633.917, y = 954.567, z = -34.645, action = "FORWARD"},
    {x = 632.009, y = 952.812, z = -34.571, action = "FORWARD"},
    {x = 630.735, y = 950.617, z = -35.195, action = "FORWARD"},
    {x = 630.088, y = 948.075, z = -35.444, action = "FORWARD"},
    {x = 629.263, y = 945.592, z = -35.674, action = "FORWARD"},
    {x = 628.099, y = 943.371, z = -36.367, action = "FORWARD"},
    {x = 626.435, y = 941.496, z = -36.996, action = "FORWARD"},
    {x = 624.435, y = 939.847, z = -37.264, action = "FORWARD"},
    {x = 622.011, y = 939.086, z = -37.592, action = "FORWARD"},
    {x = 619.874, y = 940.477, z = -37.545, action = "FORWARD"},
    {x = 621.725, y = 942.129, z = -36.974, action = "FORWARD"},
    {x = 624.260, y = 941.864, z = -36.821, action = "FORWARD"},
    {x = 626.763, y = 942.346, z = -36.743, action = "FORWARD"},
    {x = 629.104, y = 943.390, z = -36.292, action = "FORWARD"},
    {x = 630.196, y = 945.697, z = -35.614, action = "FORWARD"},
    {x = 629.504, y = 948.121, z = -35.318, action = "FORWARD"},
    {x = 628.260, y = 950.433, z = -35.235, action = "FORWARD"},
    {x = 626.383, y = 952.118, z = -35.020, action = "FORWARD"},
    {x = 623.871, y = 952.428, z = -34.886, action = "FORWARD"},
    {x = 621.402, y = 952.044, z = -34.532, action = "FORWARD"},
    {x = 618.898, y = 951.697, z = -34.168, action = "FORWARD"},
    {x = 616.435, y = 951.458, z = -33.793, action = "FORWARD"},
    {x = 613.935, y = 951.084, z = -33.433, action = "FORWARD"},
    {x = 611.462, y = 950.739, z = -33.278, action = "FORWARD"},
    {x = 608.915, y = 950.417, z = -33.172, action = "FORWARD"},
    {x = 606.328, y = 950.278, z = -32.820, action = "FORWARD"},
    {x = 603.741, y = 950.379, z = -32.978, action = "FORWARD"},
    {x = 601.163, y = 950.595, z = -32.832, action = "FORWARD"},
    {x = 598.564, y = 950.737, z = -32.501, action = "FORWARD"},
    {x = 595.996, y = 950.684, z = -32.207, action = "FORWARD"},
    {x = 593.397, y = 950.464, z = -31.901, action = "FORWARD"},
    {x = 590.795, y = 950.229, z = -31.594, action = "FORWARD"},
    {x = 588.215, y = 950.013, z = -31.291, action = "FORWARD"},
    {x = 585.625, y = 949.829, z = -30.988, action = "FORWARD"},
    {x = 583.112, y = 949.500, z = -30.782, action = "FORWARD"},
    {x = 580.691, y = 948.486, z = -30.777, action = "FORWARD"},
    {x = 578.455, y = 947.285, z = -30.693, action = "FORWARD"},
    {x = 576.031, y = 946.488, z = -30.594, action = "FORWARD"},
    {x = 573.548, y = 946.027, z = -30.501, action = "FORWARD"},
    {x = 571.055, y = 945.625, z = -30.409, action = "FORWARD"},
    {x = 568.546, y = 945.162, z = -30.315, action = "FORWARD"},
    {x = 566.053, y = 944.783, z = -30.224, action = "FORWARD"},
    {x = 563.623, y = 944.366, z = -29.325, action = "FORWARD"},
    {x = 561.338, y = 943.080, z = -29.069, action = "FORWARD"},
    {x = 559.388, y = 941.420, z = -28.482, action = "FORWARD"},
    {x = 557.319, y = 940.108, z = -27.906, action = "FORWARD"},
    {x = 555.080, y = 938.869, z = -27.303, action = "FORWARD"},
    {x = 552.797, y = 937.793, z = -26.707, action = "FORWARD"},
    {x = 550.335, y = 937.088, z = -26.114, action = "FORWARD"},
    {x = 547.969, y = 936.190, z = -25.520, action = "FORWARD"},
    {x = 545.398, y = 935.817, z = -24.927, action = "FORWARD"},
    {x = 542.913, y = 935.502, z = -24.349, action = "FORWARD"},
    {x = 540.401, y = 934.790, z = -24.000, action = "FORWARD"},
    {x = 538.032, y = 933.854, z = -24.002, action = "FORWARD"},
    {x = 535.532, y = 933.874, z = -24.010, action = "FORWARD"},
    {x = 532.973, y = 933.864, z = -24.065, action = "FORWARD"},
    {x = 530.490, y = 933.667, z = -24.303, action = "FORWARD"},
    {x = 527.968, y = 933.918, z = -24.565, action = "FORWARD"},
    {x = 525.494, y = 934.807, z = -24.849, action = "FORWARD"},
    {x = 522.950, y = 934.941, z = -25.123, action = "FORWARD"},
    {x = 520.844, y = 936.374, z = -25.483, action = "FORWARD"},
    {x = 519.085, y = 938.261, z = -25.768, action = "FORWARD"},
    {x = 518.254, y = 940.625, z = -25.755, action = "FORWARD"},
    {x = 518.317, y = 943.229, z = -25.498, action = "FORWARD"},
    {x = 518.288, y = 945.810, z = -25.261, action = "FORWARD"},
    {x = 519.073, y = 948.267, z = -24.863, action = "FORWARD"},
    {x = 520.654, y = 950.236, z = -24.334, action = "FORWARD"},
    {x = 522.482, y = 952.014, z = -23.773, action = "FORWARD"},
    {x = 523.988, y = 954.128, z = -23.375, action = "FORWARD"},
    {x = 525.491, y = 956.226, z = -23.069, action = "FORWARD"},
    {x = 527.392, y = 957.972, z = -22.699, action = "FORWARD"},
    {x = 529.175, y = 959.873, z = -22.407, action = "FORWARD"},
    {x = 530.878, y = 961.875, z = -22.185, action = "FORWARD"},
    {x = 532.628, y = 963.817, z = -21.956, action = "FORWARD"},
    {x = 534.318, y = 965.842, z = -21.736, action = "FORWARD"},
    {x = 534.188, y = 968.487, z = -21.767, action = "FORWARD"},
    {x = 531.912, y = 969.721, z = -22.084, action = "FORWARD"},
    {x = 529.536, y = 968.702, z = -22.404, action = "FORWARD"},
    {x = 526.969, y = 968.655, z = -22.754, action = "FORWARD"},
    {x = 524.435, y = 969.263, z = -23.103, action = "FORWARD"},
    {x = 522.193, y = 970.552, z = -23.416, action = "FORWARD"},
    {x = 519.624, y = 970.714, z = -23.821, action = "FORWARD"},
    {x = 517.901, y = 968.853, z = -24.162, action = "FORWARD"},
    {x = 518.828, y = 966.520, z = -24.044, action = "FORWARD"},
    {x = 519.825, y = 964.152, z = -23.914, action = "FORWARD"},
    {x = 520.635, y = 961.616, z = -23.821, action = "FORWARD"},
    {x = 521.126, y = 959.104, z = -23.784, action = "FORWARD"},
    {x = 520.658, y = 956.622, z = -23.915, action = "FORWARD"},
    {x = 519.890, y = 954.196, z = -24.103, action = "FORWARD"},
    {x = 519.622, y = 951.728, z = -24.404, action = "FORWARD"},
    {x = 519.501, y = 949.168, z = -24.683, action = "FORWARD"},
    {x = 519.077, y = 946.587, z = -25.028, action = "FORWARD"},
    {x = 518.242, y = 944.172, z = -25.423, action = "FORWARD"},
    {x = 517.015, y = 941.960, z = -25.859, action = "FORWARD"},
    {x = 514.485, y = 941.535, z = -26.369, action = "FORWARD"},
    {x = 511.969, y = 941.187, z = -26.869, action = "FORWARD"},
    {x = 509.598, y = 940.155, z = -27.406, action = "FORWARD"},
    {x = 507.396, y = 938.903, z = -27.924, action = "FORWARD"},
    {x = 506.710, y = 936.494, z = -28.118, action = "FORWARD"},
    {x = 507.356, y = 933.986, z = -28.211, action = "FORWARD"},
    {x = 508.211, y = 931.531, z = -28.254, action = "FORWARD"},
    {x = 508.695, y = 928.936, z = -28.391, action = "FORWARD"},
    {x = 508.877, y = 926.350, z = -28.594, action = "FORWARD"},
    {x = 508.341, y = 923.921, z = -28.940, action = "FORWARD"},
    {x = 505.850, y = 924.151, z = -29.466, action = "FORWARD"},
    {x = 503.669, y = 925.411, z = -29.445, action = "FORWARD"},
    {x = 501.337, y = 926.342, z = -29.249, action = "FORWARD"},
    {x = 500.371, y = 923.950, z = -29.237, action = "FORWARD"},
    {x = 500.253, y = 921.333, z = -29.429, action = "FORWARD"},
    {x = 498.535, y = 919.560, z = -30.009, action = "FORWARD"},
    {x = 496.797, y = 917.770, z = -30.252, action = "FORWARD"},
    {x = 494.866, y = 916.031, z = -30.404, action = "FORWARD"},
    {x = 493.218, y = 913.967, z = -30.630, action = "FORWARD"},
    {x = 491.865, y = 911.723, z = -30.571, action = "FORWARD"},
    {x = 490.746, y = 909.356, z = -30.507, action = "FORWARD"},
    {x = 489.621, y = 906.971, z = -30.494, action = "FORWARD"},
    {x = 488.674, y = 904.541, z = -30.545, action = "FORWARD"},
    {x = 488.751, y = 901.963, z = -30.697, action = "FORWARD"},
    {x = 488.961, y = 899.344, z = -30.863, action = "FORWARD"},
    {x = 488.608, y = 896.775, z = -30.976, action = "FORWARD"},
    {x = 488.016, y = 894.188, z = -30.935, action = "FORWARD"},
    {x = 486.718, y = 891.973, z = -30.814, action = "FORWARD"},
    {x = 485.186, y = 889.824, z = -30.719, action = "FORWARD"},
    {x = 484.606, y = 887.338, z = -30.693, action = "FORWARD"},
    {x = 484.078, y = 884.890, z = -30.670, action = "FORWARD"},
}

local mode = false
local sprint = imgui.new.bool(false)
local oreEsp = imgui.new.bool(false)

local collisionEnabled = false
local _collisionTimer = nil
local objCollisionEnabled = false
local _objCollisionTimer = nil

local currentRoutePoint = 1
local routeCheckDistance = 5.0
local routeOreRadius = 15.0

local currentCameraAngle = 0
local targetCameraAngle = 0
local lastMiningAttempt = 0
local miningTimeout = 10
local _miningStuckRetry = false
local _miningStuckOrePos = nil
local _miningRetryThread = nil
local currentMiningTarget = nil
local xz = false
local nearestOrePos = nil
local _nextTarget = nil
local nearestOreType = nil
local WinState = imgui.new.bool()
local WinStats = imgui.new.bool()

local S = {
    eatPath = getWorkingDirectory() .. '/resource/stmine_eat.mp3',
    aaPath  = getWorkingDirectory() .. '/resource/stmine_aa.mp3',
    imgPath = getWorkingDirectory() .. '/resource/stmine_aa.png',
    eatUrl  = 'https://files.catbox.moe/gdxsdb.mp3',
    aaUrl   = 'https://files.catbox.moe/80dz1r.mp3',
    imgUrl  = 'https://files.catbox.moe/0m6bav.png',
    sndEat = nil, sndAA = nil, img = nil,
    imgUntil = 0, soundLast = 0,
    minerPath = getWorkingDirectory() .. '/resource/stmine_miner.png',
    minerUrl  = 'https://raw.githubusercontent.com/victorstrand250-cpu/Photo-Katalog/refs/heads/main/file_0000000006a072469a5546e802e46eb5.png',
    miner = nil,
}

function _u8icon(cp)
    return string.char(0xE0 + math.floor(cp / 0x1000),
                       0x80 + math.floor(cp / 0x40) % 0x40,
                       0x80 + cp % 0x40)
end
IC = {
    house  = _u8icon(0xf015), shield = _u8icon(0xf3ed), food  = _u8icon(0xf2e7),
    chart  = _u8icon(0xf201), info   = _u8icon(0xf05a), play  = _u8icon(0xf04b),
    stop   = _u8icon(0xf04d), bars   = _u8icon(0xf0c9), xmark = _u8icon(0xf00d),
    gem    = _u8icon(0xf3a5), bolt   = _u8icon(0xf0e7), route = _u8icon(0xf4d7),
    coins  = _u8icon(0xf51e), gear   = _u8icon(0xf013), helmet= _u8icon(0xf807),
    pick   = _u8icon(0xf6e3), trash  = _u8icon(0xf1f8),
    lock   = _u8icon(0xf023), lockopen = _u8icon(0xf3c1),
}
_faOK = false

function drawIcon(dl, glyph, x, y, col, big)
    if not _faOK then return 0 end
    local f = big and iconFontBig or iconFont
    if not f then return 0 end
    imgui.PushFont(f)
    local w = imgui.CalcTextSize(glyph).x
    dl:AddText(imgui.ImVec2(x, y), col, glyph)
    imgui.PopFont()
    return w
end

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

local _jonesObjects = {}

local JONES_OBJECTS = {
    {model=972,  x=573.8333740234375, y=936.5120849609375, z=-31.659555435180664,
     rx=0,  ry=360, rz=107.19999694824219, scale=0.7900000214576721},
    {model=972,  x=559.1886596679688, y=932.5510864257813, z=-29.0437068939209,
     rx=11, ry=0,   rz=101.19999694824219, scale=1.0},
    {model=971,  x=583.2261352539063, y=942.6759033203125, z=-32.99993896484375,
     rx=0,  ry=0,   rz=12.399999618530273,  scale=1.0},
    {model=971,  x=591.9005126953125, y=943.7757568359375, z=-33.19993591308594,
     rx=0,  ry=0,   rz=2.299999952316284,   scale=1.0},
}

local function spawnJonesObjects()
    for _, obj in ipairs(JONES_OBJECTS) do
        local handle = nil
        pcall(function()
            handle = createObject(obj.model, obj.x, obj.y, obj.z)
        end)
        if handle and doesObjectExist(handle) then
            pcall(setObjectRotation, handle, obj.rx, obj.ry, obj.rz)
            if obj.scale and math.abs(obj.scale - 1.0) > 0.001 then
                pcall(setObjectScale, handle, obj.scale)
            end
            pcall(setObjectCollision, handle, true)
            _jonesObjects[#_jonesObjects + 1] = handle
        end
    end
    msg('Jones: ' .. #_jonesObjects .. ' ' .. '\xee\xe1\xfa\xe5\xea\xf2\xee\xe2 \xf1\xef\xe0\xf2\xed\xf5')
end

local function removeJonesObjects()
    for _, h in ipairs(_jonesObjects) do
        if doesObjectExist(h) then
            pcall(destroyObject, h)
        end
    end
    _jonesObjects = {}
end

local function initSounds()
    lua_thread.create(function()
        _ensureFile(S.eatPath, S.eatUrl)
        _ensureFile(S.aaPath,  S.aaUrl)
        _ensureFile(S.imgPath, S.imgUrl)
        _ensureFile(S.minerPath, S.minerUrl)
        if doesFileExist(S.eatPath) then S.sndEat = loadAudioStream(S.eatPath) end
        if doesFileExist(S.aaPath)  then
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

local function playEatSound()
    if not soundEatEnabled then return end
    _playOnce(S.sndEat)
end

local function playAntiAdminSound()
    if not soundAAEnabled then return end
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

function main()
    while not isSampAvailable() do wait(0) end
    wait(200)

    msg('v' .. SCRIPT_VERSION .. ' \xe7\xe0\xe3\xf0\xf3\xe6\xe5\xed. /mbot - \xec\xe5\xed\xfe')

    initSounds()
    spawnJonesObjects()

    if licenseKey ~= '' then
        checkLicenseAsync(licenseKey, true, true)
    else
        licWinOpen[0] = true
    end

    sampRegisterChatCommand('mbot', function()
        if not licenseOK then
            licWinOpen[0] = true
        else
            WinState[0] = not WinState[0]
        end
    end)
    sampRegisterChatCommand('mbotkey', function() licWinOpen[0] = true end)

    lua_thread.create(autoEatThread)

    lua_thread.create(function()
        local prev = false
        while true do
            wait(1000)
            if mode and not prev then sessionWorkTime = 0 end
            if mode then
                totalWorkTime = totalWorkTime + 1
                sessionWorkTime = sessionWorkTime + 1
                _statsDirty = true
            end
            prev = mode
        end
    end)

    lua_thread.create(function()
        local prevMode = mode
        while true do
            wait(1000)
            if prevMode and not mode and _statsDirty then
                pcall(saveStats)
            end
            prevMode = mode
        end
    end)
    lua_thread.create(function()
        while true do
            wait(3000)
            if mode and not goalReached and goalMode > 0 then
                local totalMined = totalStone + totalMetal + totalSilver + totalBronze + totalGold
                local hit = false
                if goalMode == 1 then
                    hit = goalOreAmount > 0 and totalMined >= goalOreAmount
                elseif goalMode == 2 then
                    hit = goalMoney > 0 and getTotalEarned() >= goalMoney
                elseif goalMode == 3 then
                    hit = goalMinutes > 0 and sessionWorkTime >= goalMinutes * 60
                end
                if hit then
                    goalReached = true
                    mode = false
                    setGameKeyState(1, 0)
                    setGameKeyState(16, 0)
                    msg('\xd6\xc5\xcb\xdc \xc4\xce\xd1\xd2\xc8\xc3\xcd\xd3\xd2\xc0! \xc1\xee\xf2 \xee\xf1\xf2\xe0\xed\xee\xe2\xeb\xe5\xed.')
                    if goalQuit then
                        wait(2000)
                        os.exit(1)
                    end
                end
            end
        end
    end)
    lua_thread.create(autoJumpThread)
    lua_thread.create(oreScanThread)

    lua_thread.create(function()
        local wasActive = false
        while true do
            if mode and not licenseOK then mode = false end
            if mode then
                followRecordedRoute()
                wasActive = true
            elseif wasActive then

                wasActive = false
                if not _miningStuckRetry and not larekRunning then
                    setGameKeyState(1, 0)
                    setGameKeyState(16, 0)
                end
                jumping   = jumpp[0]
                isRunning = sprint[0]
            end
            wait(1)
        end
    end)
    while true do
        wait(0)

        if beskbeg then
            enableBesk()
        end
        if collisionEnabled then

            enableCollision()
        end
        if objCollisionEnabled then
            if not _objCollisionTimer or os.clock() - _objCollisionTimer >= 2.0 then
                _objCollisionTimer = os.clock()
                enableObjectCollision()
            end
        end

    end
end

function isPlayerNearPosition(x, y, z, radius)
    for i = 0, sampGetMaxPlayerId() do
        if sampIsPlayerConnected(i) then
            local result, ped = sampGetCharHandleBySampPlayerId(i)
            if result and doesCharExist(ped) and ped ~= PLAYER_PED then
                local px, py, pz = getCharCoordinates(ped)
                local dist = getDistanceBetweenCoords3d(px, py, pz, x, y, z)
                if dist <= radius then
                    return true
                end
            end
        end
    end
    return false
end

function enableCollision()
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

function enableObjectCollision()
    local ok, objs = pcall(getAllObjects)
    if not ok or not objs then return end
    local protected = {}
    for _, h in ipairs(_jonesObjects) do protected[h] = true end
    for k, v in ipairs(objs) do
        if doesObjectExist(v) and not protected[v] then
            pcall(setObjectCollision, v, not objCollisionEnabled)
        end
    end
end

function enableBesk()
    if beskbeg then
        setPlayerNeverGetsTired(PLAYER_HANDLE, true)
    else
        setPlayerNeverGetsTired(PLAYER_HANDLE, false)
    end
end

function smoothCameraRotation(dist)
    local angleDiff = ((targetCameraAngle - currentCameraAngle + 180) % 360) - 180
    local lerpK = (dist and dist < 8) and 0.12 or 0.10
    local step = angleDiff * lerpK

    local ad = angleDiff < 0 and -angleDiff or angleDiff
    local MAX_STEP = 4.5
    if ad > 90 then MAX_STEP = 14.0
    elseif ad > 45 then MAX_STEP = 9.0 end
    if step > MAX_STEP then step = MAX_STEP
    elseif step < -MAX_STEP then step = -MAX_STEP end
    currentCameraAngle = (currentCameraAngle + step + 360) % 360
    pcall(setCameraPositionUnfixed, 0, math.rad(currentCameraAngle - 90))
end

function setTargetAngle(angle)
    targetCameraAngle = angle
    while targetCameraAngle > 360 do targetCameraAngle = targetCameraAngle - 360 end
    while targetCameraAngle < 0 do targetCameraAngle = targetCameraAngle + 360 end
end

local currentTracerOre = nil
local allOres = {}

local DANGER_ZONE = {
    {x=500.3507, y=870.0658},
    {x=499.7851, y=867.7452},
    {x=499.2010, y=864.7122},
    {x=498.8240, y=862.2119},
    {x=498.4181, y=859.6770},
    {x=498.5468, y=856.3925},
    {x=501.2025, y=852.3644},
    {x=502.9306, y=850.2516},
    {x=504.4241, y=848.2823},
    {x=506.7178, y=846.3766},
    {x=508.6208, y=844.7634},
    {x=510.3641, y=843.3670},
    {x=512.5022, y=841.7054},
    {x=514.5761, y=840.9650},
    {x=517.1990, y=840.4729},
    {x=520.1426, y=839.8427},
    {x=521.9838, y=839.4938},
    {x=524.8517, y=839.0273},
    {x=526.6746, y=837.5928},
    {x=528.5430, y=836.1089},
    {x=530.6310, y=834.6213},
    {x=532.7401, y=833.2308},
    {x=535.0414, y=831.5632},
    {x=538.1442, y=829.7003},
    {x=541.7902, y=827.2825},
    {x=545.7527, y=823.5402},
    {x=549.4918, y=820.4007},
    {x=551.7247, y=817.7843},
    {x=554.9396, y=815.7159},
    {x=562.3743, y=812.6978},
    {x=569.0607, y=810.8814},
    {x=574.4111, y=809.7688},
    {x=578.4485, y=809.0795},
    {x=582.4214, y=808.0280},
    {x=587.0408, y=807.0633},
    {x=592.1613, y=806.1550},
    {x=596.7582, y=805.1279},
    {x=603.4515, y=803.8113},
    {x=609.5889, y=802.5823},
    {x=615.2679, y=801.4971},
    {x=620.4069, y=800.4441},
    {x=624.8215, y=799.4533},
    {x=628.1563, y=799.4277},
    {x=632.2632, y=799.1230},
    {x=637.5684, y=798.8057},
    {x=643.2648, y=798.7986},
    {x=648.9642, y=799.3540},
    {x=654.3533, y=799.9415},
    {x=659.4462, y=800.5244},
    {x=664.7859, y=802.5970},
    {x=668.6309, y=806.0526},
    {x=672.1387, y=809.0319},
    {x=675.2805, y=811.0827},
    {x=678.8058, y=812.4645},
    {x=682.2122, y=812.3206},
    {x=686.4359, y=811.5969},
    {x=690.3862, y=810.3596},
    {x=692.6607, y=813.4553},
    {x=694.3364, y=817.1770},
    {x=697.0159, y=821.7444},
    {x=699.9967, y=827.2474},
    {x=701.9459, y=830.7332},
    {x=706.1729, y=838.3746},
    {x=708.1258, y=845.6064},
    {x=708.7232, y=851.4858},
    {x=708.9969, y=859.7510},
    {x=709.2137, y=866.0380},
    {x=709.5037, y=873.4849},
    {x=709.3234, y=880.3176},
    {x=708.0240, y=886.7946},
    {x=704.8053, y=893.3329},
    {x=701.8792, y=899.8605},
    {x=698.5677, y=905.7874},
    {x=695.4151, y=911.3313},
    {x=692.9498, y=915.8694},
    {x=690.9269, y=920.5218},
    {x=688.4786, y=924.5200},
    {x=685.0459, y=929.1041},
    {x=681.0376, y=932.9477},
    {x=677.0211, y=936.0696},
    {x=674.7009, y=938.6814},
    {x=670.4490, y=939.9116},
    {x=666.7072, y=942.1370},
    {x=664.2978, y=941.6111},
    {x=664.8405, y=938.8085},
    {x=665.8479, y=934.3762},
    {x=665.4482, y=931.4841},
    {x=662.0927, y=929.5228},
    {x=659.4241, y=927.6584},
    {x=655.0687, y=925.5437},
    {x=650.4030, y=925.9169},
    {x=645.9520, y=926.0142},
    {x=641.5468, y=926.2736},
    {x=638.0507, y=927.1830},
    {x=632.1355, y=930.8853},
    {x=631.4327, y=934.8443},
    {x=631.9499, y=938.6104},
    {x=632.6763, y=944.5096},
    {x=630.7314, y=943.4589},
    {x=627.2954, y=941.0172},
    {x=622.3438, y=937.8461},
    {x=619.4299, y=937.4508},
    {x=616.3286, y=938.7840},
    {x=615.3059, y=941.7274},
    {x=616.2765, y=943.0121},
    {x=619.4764, y=944.8433},
    {x=622.4008, y=947.3232},
    {x=618.0667, y=947.1390},
    {x=613.1500, y=946.6218},
    {x=607.8198, y=945.8857},
    {x=602.5887, y=945.0044},
    {x=596.6345, y=944.4555},
    {x=591.2482, y=944.2739},
    {x=585.5879, y=943.8601},
    {x=580.4071, y=942.5714},
    {x=574.8706, y=940.9377},
    {x=568.4769, y=938.8285},
    {x=563.8558, y=937.5121},
    {x=558.3541, y=936.1713},
    {x=552.3177, y=935.0065},
    {x=547.2926, y=933.8491},
    {x=539.8451, y=932.1014},
    {x=534.5165, y=929.6177},
    {x=529.3251, y=927.2225},
    {x=523.1183, y=924.4758},
    {x=517.7228, y=922.3704},
    {x=512.6141, y=920.0891},
    {x=507.6363, y=917.2488},
    {x=503.1656, y=912.8289},
    {x=500.0782, y=908.5750},
    {x=500.1821, y=903.8398},
    {x=500.4356, y=898.1721},
    {x=500.4207, y=894.3566},
    {x=500.6017, y=890.2700},
    {x=500.6369, y=886.4221},
    {x=500.6708, y=882.1539},
    {x=500.6274, y=878.0717}
}

local function isPointInZone(px, py, zone)
    local inside = false
    local n = #zone
    local j = n
    for i = 1, n do
        local xi, yi = zone[i].x, zone[i].y
        local xj, yj = zone[j].x, zone[j].y
        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local ORE_PLAYER_RADIUS = 4.0

local function dist3(x1, y1, z1, x2, y2, z2)
    local dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local _charPosCache = {}
local _charCacheTime = 0
local function refreshCharCache()
    local now = os.clock()
    if now - _charCacheTime < 0.25 then return end
    _charCacheTime = now
    _charPosCache = {}
    local ok, chars = pcall(getAllChars)
    if not ok or not chars then return end
    for _, ped in ipairs(chars) do
        if ped ~= PLAYER_PED then
            local ok3, cpx, cpy, cpz = pcall(getCharCoordinates, ped)
            if ok3 and cpx then
                _charPosCache[#_charPosCache + 1] = {cpx, cpy, cpz}
            end
        end
    end
end

local function isOreOccupied(ox, oy, oz)
    refreshCharCache()
    for _, p in ipairs(_charPosCache) do
        if dist3(p[1], p[2], p[3], ox, oy, oz) <= ORE_PLAYER_RADIUS then
            return true
        end
    end
    return false
end

local function nearestRivalDist(ox, oy, oz)
    refreshCharCache()
    local best = math.huge
    for _, p in ipairs(_charPosCache) do
        local d = dist3(p[1], p[2], p[3], ox, oy, oz)
        if d < best then best = d end
    end
    return best
end
local _occScans = 0

local ORE_SPAWNS = {
    {508.4472,938.8561,-28.1039},{518.5640,969.0382,-24.4307},
    {490.1925,908.1881,-30.8502},{476.3735,880.0000,-30.5258},
    {518.0413,790.5797,-21.9119},{496.7886,850.6080,-30.2301},
    {511.4584,834.8192,-26.9533},{500.0222,792.1309,-22.4025},
    {565.3883,770.1097,-17.1307},{525.4928,822.1473,-26.2727},
    {584.2816,791.0622,-30.5229},{601.1553,789.5864,-32.4833},
    {616.1552,777.2164,-32.4833},{663.9422,788.6303,-30.6033},
    {648.7612,777.3120,-30.6033},{484.9393,888.3535,-31.0572},
    {686.0633,788.6151,-30.6033},{716.3998,817.9641,-30.6033},
    {712.8651,834.7143,-30.6325},{470.2134,870.7208,-29.1958},
    {693.5343,800.5518,-30.6033},{467.0036,886.7202,-29.0758},
    {719.1073,847.8416,-30.6325},{518.5251,944.8240,-25.6777},
    {488.2173,896.6282,-31.2929},{508.4426,924.8705,-29.1563},
    {496.7857,917.6792,-30.7066},{494.2072,866.2725,-31.7276},
    {515.3755,821.8129,-25.0388},{505.8671,804.9512,-22.2930},
    {562.1116,799.9377,-28.7624},{532.4681,808.6583,-26.4573},
    {554.4883,780.0895,-18.4607},{518.1339,808.8135,-23.8042},
    {528.5587,959.2208,-22.8474},{532.0861,969.0079,-22.3969},
    {564.0416,944.4025,-30.1136},{647.3600,941.3135,-36.2511},
    {618.9689,941.3399,-38.0076},{644.4290,955.7799,-34.7976},
    {584.6170,949.8271,-31.2773},{629.6487,947.0833,-35.9744},
    {606.4080,950.3010,-33.4497},{632.3217,953.8739,-35.1285},
    {662.1433,936.8993,-38.5028},
}

local SPAWN_SNAP_RADIUS = 4.0
local function snapToSpawn(ox, oy, oz)
    local bestDist, bestSpawn = math.huge, nil
    for _, sp in ipairs(ORE_SPAWNS) do
        local d = dist3(ox, oy, oz, sp[1], sp[2], sp[3])
        if d < bestDist then bestDist = d; bestSpawn = sp end
    end
    if bestDist <= SPAWN_SNAP_RADIUS then
        return {bestSpawn[1], bestSpawn[2], bestSpawn[3]}
    end
    return {ox, oy, oz}
end

local _oreBlacklist     = {}
local _oreLastSeenFree  = 0
local _miningFailKey    = nil
local _miningFailCount  = 0
local _lastMiningClick  = 0
local _occCheckTime     = 0

local function oreKey(x, y, z)
    local p = snapToSpawn(x, y, z)
    return math.floor(p[1] * 2 + 0.5) .. '_' .. math.floor(p[2] * 2 + 0.5)
end

local function blacklistOre(x, y, z, secs)
    _oreBlacklist[oreKey(x, y, z)] = os.clock() + (secs or 90)
end

local function isOreBlacklisted(x, y, z)
    local k = oreKey(x, y, z)
    local t = _oreBlacklist[k]
    if t == nil then return false end
    if os.clock() < t then return true end
    _oreBlacklist[k] = nil
    return false
end

function oreScanThread()
    while true do
        wait(600)
        if not mode then

            if #allOres > 0 then allOres = {} end
            nearestOrePos = nil
            currentTracerOre = nil
        else
        local ok2, myX, myY, myZ = pcall(getCharCoordinates, PLAYER_PED)
        if ok2 then
        local nearbyOres = {}
        for i = 0, 2048 do
            if i > 0 and i % 160 == 0 then wait(0) end
            if sampIs3dTextDefined(i) then
                local ok, txt, color, ox, oy, oz = pcall(sampGet3dTextInfoById, i)
                if ok and txt and txt:find('\xcc\xe5\xf1\xf2\xee\xf0\xee\xe6\xe4\xe5\xed\xe8\xe5') then
                    local dist = dist3(myX, myY, myZ, ox, oy, oz)
                    if not isPointInZone(ox, oy, DANGER_ZONE) and not isOreBlacklisted(ox, oy, oz) then
                        local occupied = isOreOccupied(ox, oy, oz)
                        table.insert(nearbyOres, {pos = {ox, oy, oz}, dist = dist, occupied = occupied})
                    end
                end
            end
        end
        table.sort(nearbyOres, function(a, b) return a.dist < b.dist end)
        allOres = nearbyOres
        if mode then

            local LOCK_RADIUS      = 12.0
            local SWITCH_ADVANTAGE = 40.0
            local RACE_MARGIN      = 3.5
            local OCC_CONFIRM      = 1

            local function sameSpawn(a, b)
                return math.abs(a[1]-b[1]) < 0.5 and math.abs(a[2]-b[2]) < 0.5
            end

            local function winnable(ore)
                return ore.dist <= nearestRivalDist(ore.pos[1], ore.pos[2], ore.pos[3]) + RACE_MARGIN
            end

            local function pickTarget()
                local nearestFree = nil
                for _, ore in ipairs(nearbyOres) do
                    if not ore.occupied then
                        if nearestFree == nil then nearestFree = ore.pos end
                        if winnable(ore) then return ore.pos end
                    end
                end
                return nearestFree
            end

            local currentRealDist = math.huge
            if nearestOrePos then
                currentRealDist = dist3(myX, myY, myZ,
                    nearestOrePos[1], nearestOrePos[2], nearestOrePos[3])
            end

            local currentValid    = false
            local currentOccupied = false
            local currentDist     = math.huge
            local currentSnapped  = nil
            if nearestOrePos then
                currentSnapped = snapToSpawn(nearestOrePos[1], nearestOrePos[2], nearestOrePos[3])
                for _, ore in ipairs(nearbyOres) do
                    if sameSpawn(snapToSpawn(ore.pos[1], ore.pos[2], ore.pos[3]), currentSnapped) then
                        if not ore.occupied then
                            currentValid     = true
                            currentDist      = ore.dist
                            _oreLastSeenFree = os.clock()
                        else
                            currentOccupied = true
                        end
                        break
                    end
                end
            end

            if nearestOrePos == nil then

                nearestOrePos = pickTarget()
                _occScans = 0
            elseif currentOccupied then

                if currentRealDist > 6.0 then
                    _occScans = _occScans + 1
                    if _occScans >= OCC_CONFIRM then
                        nearestOrePos = pickTarget()
                        _cachedOrePos = nil
                        _occScans = 0
                    end
                else
                    _occScans = 0
                end
            elseif currentValid then
                _occScans = 0

                if currentDist > LOCK_RADIUS then
                    for _, ore in ipairs(nearbyOres) do
                        if not ore.occupied then
                            if ore.dist < currentDist - SWITCH_ADVANTAGE and winnable(ore)
                                and not sameSpawn(snapToSpawn(ore.pos[1], ore.pos[2], ore.pos[3]), currentSnapped) then
                                nearestOrePos = ore.pos
                                _cachedOrePos = nil
                            end
                            break
                        end
                    end
                end
            else

                _occScans = 0
                if not (currentRealDist <= LOCK_RADIUS and os.clock() - _oreLastSeenFree < 6.0) then
                    local chosen = pickTarget()
                    if chosen == nil then
                        nearestOrePos = nil
                        _cachedOrePos = nil
                    elseif currentSnapped == nil
                        or not sameSpawn(snapToSpawn(chosen[1], chosen[2], chosen[3]), currentSnapped) then
                        nearestOrePos = chosen
                        _cachedOrePos = nil
                    end
                end
            end

            _nextTarget = nil
            do
                local curSnap = nearestOrePos
                    and snapToSpawn(nearestOrePos[1], nearestOrePos[2], nearestOrePos[3]) or nil
                local fallback = nil
                for _, ore in ipairs(nearbyOres) do
                    if not ore.occupied then
                        local sp = snapToSpawn(ore.pos[1], ore.pos[2], ore.pos[3])
                        if not (curSnap and sameSpawn(sp, curSnap)) then
                            if fallback == nil then fallback = ore.pos end
                            if winnable(ore) then _nextTarget = ore.pos; break end
                        end
                    end
                end
                if _nextTarget == nil then _nextTarget = fallback end
            end
        else
            nearestOrePos = nil
            currentTracerOre = nil
            _nextTarget = nil
        end
        end
        end
    end
end

local function findNearestRoutePoint(px, py, pz)
    local best, bestDist = 1, math.huge
    for i, pt in ipairs(recordedRoute) do
        local d = dist3(px, py, pz, pt.x, pt.y, pt.z)
        if d < bestDist then bestDist = d; best = i end
    end
    return best
end

local _safeRouteIndices = nil
local _safeAdj = nil
local _navBuilding = false

local function buildSafeIndices()
    if _navBuilding or _safeRouteIndices then return end
    _navBuilding = true

    local indices = {}
    local DEDUP_DIST = 2.0
    local prevPt = nil
    for i, pt in ipairs(recordedRoute) do
        if not isPointInZone(pt.x, pt.y, DANGER_ZONE) then
            if not (prevPt and dist3(pt.x, pt.y, pt.z, prevPt.x, prevPt.y, prevPt.z) < DEDUP_DIST) then
                indices[#indices + 1] = i
                prevPt = pt
            end
        end
    end

    local CELL = 4.0
    local grid = {}
    local function gkey(cx, cy) return cx * 100000 + cy end
    for _, pt in ipairs(recordedRoute) do
        local key = gkey(math.floor(pt.x / CELL), math.floor(pt.y / CELL))
        local b = grid[key]
        if b then b[#b + 1] = pt else grid[key] = {pt} end
    end
    local CORR2 = 4.0 * 4.0
    local function nearRoute(x, y)
        local cx, cy = math.floor(x / CELL), math.floor(y / CELL)
        for ix = cx - 1, cx + 1 do
            for iy = cy - 1, cy + 1 do
                local b = grid[gkey(ix, iy)]
                if b then
                    for _, pt in ipairs(b) do
                        local dx, dy = pt.x - x, pt.y - y
                        if dx * dx + dy * dy <= CORR2 then return true end
                    end
                end
            end
        end
        return false
    end

    local n = #indices
    local adj = {}
    for k = 1, n do adj[k] = {} end
    local function addEdge(a, b, w)
        adj[a][#adj[a] + 1] = {b, w}
        adj[b][#adj[b] + 1] = {a, w}
    end
    for k = 1, n do
        local a = recordedRoute[indices[k]]
        local nk = k % n + 1
        local b = recordedRoute[indices[nk]]
        local d = dist3(a.x, a.y, a.z, b.x, b.y, b.z)
        addEdge(k, nk, d <= 6.0 and d or d * 3.0)
    end

    local SHORTCUT_DIST   = 14.0
    local SHORTCUT_MAX_DZ = 2.0
    local SAMPLE_STEP     = 2.0
    local function cutIsSafe(a, b, d)
        local steps = math.floor(d / SAMPLE_STEP)
        for s = 1, steps do
            local t = s / (steps + 1)
            local x, y = a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t
            if isPointInZone(x, y, DANGER_ZONE) then return false end
            if not nearRoute(x, y) then return false end
        end
        return true
    end
    for k = 1, n - 1 do
        local a = recordedRoute[indices[k]]
        for j = k + 2, n do
            if not (k == 1 and j == n) then
                local b = recordedRoute[indices[j]]
                if math.abs(a.z - b.z) <= SHORTCUT_MAX_DZ then
                    local d = dist3(a.x, a.y, a.z, b.x, b.y, b.z)
                    if d <= SHORTCUT_DIST and cutIsSafe(a, b, d) then
                        addEdge(k, j, d)
                    end
                end
            end
        end
        if k % 16 == 0 then wait(0) end
    end

    _safeAdj = adj
    _safeRouteIndices = indices
    _navBuilding = false
end
lua_thread.create(buildSafeIndices)

local _heapNode, _heapDist = {}, {}
local function findPath(startPos, goalPos)
    if not _safeAdj then return nil end
    local n = #_safeRouteIndices
    if n == 0 then return nil end
    if startPos == goalPos then return {startPos} end
    local dist, prev = {}, {}
    for k = 1, n do dist[k] = math.huge end
    dist[startPos] = 0

    local hn, hd = _heapNode, _heapDist
    local hsize = 0
    local function push(node, d)
        hsize = hsize + 1
        hn[hsize] = node; hd[hsize] = d
        local i = hsize
        while i > 1 do
            local p = (i - i % 2) / 2
            if hd[p] <= hd[i] then break end
            hn[p], hn[i] = hn[i], hn[p]
            hd[p], hd[i] = hd[i], hd[p]
            i = p
        end
    end
    local function pop()
        local node = hn[1]
        hn[1] = hn[hsize]; hd[1] = hd[hsize]
        hn[hsize] = nil;   hd[hsize] = nil
        hsize = hsize - 1
        local i = 1
        while true do
            local l, r = 2*i, 2*i+1
            local sm = i
            if l <= hsize and hd[l] < hd[sm] then sm = l end
            if r <= hsize and hd[r] < hd[sm] then sm = r end
            if sm == i then break end
            hn[sm], hn[i] = hn[i], hn[sm]
            hd[sm], hd[i] = hd[i], hd[sm]
            i = sm
        end
        return node
    end
    push(startPos, 0)
    while hsize > 0 do
        local topd = hd[1]
        local u = pop()
        if topd <= dist[u] then
            if u == goalPos then break end
            local adj = _safeAdj[u]
            for a = 1, #adj do
                local e = adj[a]
                local v = e[1]
                local nd = dist[u] + e[2]
                if nd < dist[v] then
                    dist[v] = nd
                    prev[v] = u
                    push(v, nd)
                end
            end
        end
    end
    if dist[goalPos] == math.huge then return nil end
    local path = {}
    local cur = goalPos
    while cur do
        table.insert(path, 1, cur)
        cur = prev[cur]
    end
    return path
end

local _cachedOrePos     = nil

local _cachedBestOreIdx = nil

local _navPath, _navStep, _navGoal = nil, nil, nil

local _visitedRoutePoints = {}

local _stuckTimer   = 0
local _stuckLastPos = nil
local _stuckCount   = 0
local STUCK_TIMEOUT = 15.0
local STUCK_MIN_MOVE = 2.5

local _bumpPos     = nil
local _bumpTimer   = 0
local _bumpJumping = false

local function resetNavState()
    _cachedOrePos         = nil
    _cachedBestOreIdx     = nil
    _navPath, _navStep, _navGoal = nil, nil, nil
    _visitedRoutePoints   = {}
    _stuckTimer           = os.clock()
    _stuckLastPos         = nil
    _stuckCount           = 0
    _bumpPos              = nil
end

local function isStuck(px, py, pz)
    local now = os.clock()
    if _stuckLastPos == nil then
        _stuckLastPos = {px, py, pz}
        _stuckTimer   = now
        return false
    end
    local moved = dist3(px, py, pz,
        _stuckLastPos[1], _stuckLastPos[2], _stuckLastPos[3])
    if moved >= STUCK_MIN_MOVE then
        _stuckLastPos = {px, py, pz}
        _stuckTimer   = now
        return false
    end
    return (now - _stuckTimer) >= STUCK_TIMEOUT
end

local BUMP_SPOTS = {
    {617.691, 944.844},
}
local function antiBumpJump(px, py, pz)
    if _bumpJumping then return end
    local atSpot = false
    for _, s in ipairs(BUMP_SPOTS) do
        local dx, dy = px - s[1], py - s[2]
        if dx * dx + dy * dy <= 81 then atSpot = true; break end
    end
    if not atSpot then
        _bumpPos = nil
        return
    end
    local now = os.clock()
    if _bumpPos == nil then
        _bumpPos = {px, py, pz}; _bumpTimer = now; return
    end
    if dist3(px, py, pz, _bumpPos[1], _bumpPos[2], _bumpPos[3]) >= 0.6 then
        _bumpPos = {px, py, pz}; _bumpTimer = now; return
    end
    if now - _bumpTimer >= 0.7 then
        _bumpJumping = true
        _bumpPos = {px, py, pz}; _bumpTimer = now
        lua_thread.create(function()
            for _ = 1, 6 do
                doJumpThisFrame = true
                setGameKeyState(14, 255)
                wait(0)
            end
            setGameKeyState(14, 0)
            wait(250)
            _bumpJumping = false
        end)
    end
end

local function runTowards(tx, ty, px, py, dist, brake)
    local angle = getHeadingFromVector2d(tx - px, ty - py)
    setTargetAngle(angle)
    smoothCameraRotation(dist)
    local speed = -255
    if brake and dist and dist < 4.5 then
        local t = (dist - 1.2) / 3.3
        if t < 0 then t = 0 elseif t > 1 then t = 1 end
        speed = math.floor(-40 - 215 * t)
    end
    setGameKeyState(1, speed)
end

local function moveToRoutePoint(px, py, pz, idx)
    local pt = recordedRoute[idx]
    local d = dist3(px, py, pz, pt.x, pt.y, pt.z)
    runTowards(pt.x, pt.y, px, py, d)
    local action = pt.action
    if     action == "JUMP"  then setGameKeyState(14, 1)
    elseif action == "LEFT"  then setGameKeyState(0, -255)
    elseif action == "RIGHT" then setGameKeyState(0, 255)
    end
end

local function isHeightSafeStep(idx)
    if not _safeRouteIndices then return true end
    local pt = recordedRoute[idx]

    local nextPt = nil
    for _, i in ipairs(_safeRouteIndices) do
        if i > idx then
            nextPt = recordedRoute[i]
            break
        end
    end
    if not nextPt then return true end
    return math.abs(nextPt.z - pt.z) <= 1.5
end

function followRecordedRoute()

    if _miningStuckRetry or larekRunning then return end
    if currentRoutePoint > #recordedRoute then currentRoutePoint = 1 end

    local ok0, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
    if not ok0 then return end

    if _needRouteSnap then
        _needRouteSnap = false
        currentRoutePoint = findNearestRoutePoint(px, py, pz)
    end

    if not _safeRouteIndices then
        if not _navBuilding then lua_thread.create(buildSafeIndices) end
        return
    end

    local orePos  = nearestOrePos
    local oreDist = orePos
        and dist3(px, py, pz, orePos[1], orePos[2], orePos[3])
        or math.huge

    if orePos and oreDist <= 2.0 and os.clock() - _lastMiningClick >= 1.0 then
        _lastMiningClick = os.clock()
        sendFrontendClick(8, 7, -1, "{}")
        sendFrontendClick(8, 7, -1, "{}")
    end

    if oreDist <= 1.5 then

        if nearestRivalDist(orePos[1], orePos[2], orePos[3]) < oreDist - 0.7 then
            nearestOrePos = nil
            currentMiningTarget = nil
            lastMiningAttempt   = 0
            resetNavState()
            jumping   = jumpp[0]
            isRunning = sprint[0]
            return
        end
        jumping   = false
        isRunning = false
        setGameKeyState(1, 0)
        setGameKeyState(16, 0)
        if currentMiningTarget == nil then
            currentMiningTarget = {orePos[1], orePos[2], orePos[3]}
            lastMiningAttempt   = os.clock()
        end
        if os.clock() - lastMiningAttempt > miningTimeout then

            currentMiningTarget = nil
            lastMiningAttempt   = 0
            local k = oreKey(orePos[1], orePos[2], orePos[3])
            if _miningFailKey == k then
                _miningFailCount = _miningFailCount + 1
            else
                _miningFailKey   = k
                _miningFailCount = 1
            end
            if _miningFailCount >= 3 then

                blacklistOre(orePos[1], orePos[2], orePos[3], 120)
                nearestOrePos = nil
                resetNavState()
                jumping   = jumpp[0]
                isRunning = sprint[0]
                return
            end

            if not _miningStuckRetry and (_miningRetryThread == nil or _miningRetryThread.dead) then
                _miningStuckRetry  = true
                _miningStuckOrePos = {orePos[1], orePos[2], orePos[3]}
                _miningRetryThread = lua_thread.create(function()
                    local ox, oy = _miningStuckOrePos[1], _miningStuckOrePos[2]
                    local okb, bx, by = pcall(getCharCoordinates, PLAYER_PED)
                    if okb then
                        local dx, dy = bx - ox, by - oy
                        local dlen = math.sqrt(dx*dx + dy*dy)
                        if dlen < 0.01 then dx, dy = 1, 0 else dx, dy = dx/dlen, dy/dlen end
                        setTargetAngle(getHeadingFromVector2d(dx, dy))
                        local t0 = os.clock()
                        while os.clock() - t0 < 0.9 do
                            smoothCameraRotation(5)
                            setGameKeyState(1, -255)
                            wait(0)
                        end
                        setGameKeyState(1, 0)
                        wait(200)
                    end
                    nearestOrePos = _miningStuckOrePos
                    _cachedOrePos = nil
                    _miningStuckRetry = false
                end)
            end
            return
        end

        if os.clock() - _lastMiningClick >= 1.0 then
            _lastMiningClick = os.clock()
            sendFrontendClick(8, 7, -1, "{}")
            sendFrontendClick(8, 7, -1, "{}")
        end
        return
    end

    if oreDist <= 4.5 then
        jumping   = false
        isRunning = false
        setGameKeyState(1, 0)
        setGameKeyState(16, 0)
    else
        jumping   = jumpp[0]
        isRunning = sprint[0]
    end
    if oreDist > 2.0 then antiBumpJump(px, py, pz) end

    if orePos then
        currentTracerOre = {orePos[1], orePos[2], orePos[3]}

        local snapped = snapToSpawn(orePos[1], orePos[2], orePos[3])

        if oreDist <= 3.5 then
            if isStuck(px, py, pz) then
                blacklistOre(snapped[1], snapped[2], snapped[3], 60)
                nearestOrePos = nil
                resetNavState()
                setGameKeyState(1, 0)
                return
            end
            runTowards(snapped[1], snapped[2], px, py, oreDist, true)
            return
        end

        local oreChanged = (_cachedOrePos == nil)
            or (math.abs(_cachedOrePos[1] - snapped[1]) > 0.5)
            or (math.abs(_cachedOrePos[2] - snapped[2]) > 0.5)

        if oreChanged then
            resetNavState()
            _cachedOrePos = snapped

            local sN = #_safeRouteIndices
            if sN == 0 then return end

            local startPos, startDist = nil, math.huge
            local goalPos,  goalDist  = nil, math.huge
            for k = 1, sN do
                local pt = recordedRoute[_safeRouteIndices[k]]
                local dP = dist3(px, py, pz, pt.x, pt.y, pt.z)
                if dP < startDist then startDist = dP; startPos = k end
                local dO = dist3(snapped[1], snapped[2], snapped[3], pt.x, pt.y, pt.z)
                if dO < goalDist then goalDist = dO; goalPos = k end
            end

            _navGoal = goalPos
            _cachedBestOreIdx = _safeRouteIndices[goalPos]

            _navPath = findPath(startPos, goalPos)
            _navStep = 1
            if _navPath then
                currentRoutePoint = _safeRouteIndices[_navPath[_navStep]]
            else
                currentRoutePoint = _safeRouteIndices[startPos]
            end
        end

        if _cachedBestOreIdx ~= nil and isStuck(px, py, pz) then
            _stuckCount = _stuckCount + 1
            if _stuckCount >= 3 then

                blacklistOre(snapped[1], snapped[2], snapped[3], 120)
                nearestOrePos = nil
                resetNavState()
                setGameKeyState(1, 0)
                return
            end

            local sN = #_safeRouteIndices
            local nearestPos, nearestDist = nil, math.huge
            for k = 1, sN do
                local pt = recordedRoute[_safeRouteIndices[k]]
                local d  = dist3(px, py, pz, pt.x, pt.y, pt.z)
                if d < nearestDist then nearestDist = d; nearestPos = k end
            end
            if nearestPos and _navGoal then

                _navPath = findPath(nearestPos, _navGoal)
                _navStep = 1
                if _navPath then
                    currentRoutePoint = _safeRouteIndices[_navPath[_navStep]]
                end
            end
            _stuckTimer   = os.clock()
            _stuckLastPos = {px, py, pz}
            return
        end

        if _cachedBestOreIdx == nil then
            moveToRoutePoint(px, py, pz, currentRoutePoint)
            return
        end

        local bestPt     = recordedRoute[_cachedBestOreIdx]
        local distToBest = dist3(px, py, pz, bestPt.x, bestPt.y, bestPt.z)

        if oreDist <= 5.0 then
            runTowards(snapped[1], snapped[2], px, py, oreDist, true)
            return
        end

        if currentRoutePoint == _cachedBestOreIdx and distToBest <= routeCheckDistance then

            if oreDist <= 12.0 then
                runTowards(snapped[1], snapped[2], px, py, oreDist, true)
            else

                blacklistOre(snapped[1], snapped[2], snapped[3], 120)
                nearestOrePos = nil
                resetNavState()
                setGameKeyState(1, 0)
            end
            return
        end

        if _navPath and _navStep and _navStep < #_navPath then
            local pt   = recordedRoute[_safeRouteIndices[_navPath[_navStep]]]
            local dCur = dist3(px, py, pz, pt.x, pt.y, pt.z)

            local guard = 0
            while _navStep < #_navPath and guard < 6 do
                local npt   = recordedRoute[_safeRouteIndices[_navPath[_navStep + 1]]]
                local dNext = dist3(px, py, pz, npt.x, npt.y, npt.z)
                if dCur <= routeCheckDistance or dNext < dCur then
                    _navStep = _navStep + 1
                    dCur     = dNext
                    guard    = guard + 1
                else
                    break
                end
            end
            currentRoutePoint = _safeRouteIndices[_navPath[_navStep]]
        end

        if oreDist <= 8.0 then
            local cpt = recordedRoute[currentRoutePoint]
            if dist3(cpt.x, cpt.y, cpt.z, snapped[1], snapped[2], snapped[3]) > oreDist then
                runTowards(snapped[1], snapped[2], px, py, oreDist, true)
                return
            end
        end

        moveToRoutePoint(px, py, pz, currentRoutePoint)

    else
        currentTracerOre    = nil
        currentMiningTarget = nil
        lastMiningAttempt   = 0

        if _cachedOrePos ~= nil then
            resetNavState()
        end

        if isStuck(px, py, pz) then
            currentRoutePoint = findNearestRoutePoint(px, py, pz) % #recordedRoute + 1
            _stuckTimer   = os.clock()
            _stuckLastPos = {px, py, pz}
        end

        local point = recordedRoute[currentRoutePoint]
        local dist  = dist3(px, py, pz, point.x, point.y, point.z)
        if dist <= routeCheckDistance then
            local nextIdx = currentRoutePoint + 1
            if nextIdx > #recordedRoute then nextIdx = 1 end
            local safety = 0
            while isPointInZone(
                recordedRoute[nextIdx].x,
                recordedRoute[nextIdx].y,
                DANGER_ZONE)
            do
                nextIdx = nextIdx + 1
                if nextIdx > #recordedRoute then nextIdx = 1 end
                safety  = safety + 1
                if safety > #recordedRoute then break end
            end
            currentRoutePoint = nextIdx
        end

        moveToRoutePoint(px, py, pz, currentRoutePoint)
    end
end

local FOOD_ROUTE = {
    {x = 492.466, y = 880.220, z = -31.260},
    {x = 494.341, y = 878.606, z = -31.682},
    {x = 496.456, y = 877.080, z = -32.055},
    {x = 498.525, y = 875.520, z = -32.395},
    {x = 500.710, y = 874.101, z = -32.746},
    {x = 502.899, y = 872.858, z = -33.400},
    {x = 505.081, y = 871.826, z = -34.429},
    {x = 507.163, y = 871.000, z = -35.820},
    {x = 509.288, y = 870.362, z = -36.991},
    {x = 511.469, y = 869.942, z = -38.388},
    {x = 513.775, y = 869.708, z = -39.606},
    {x = 516.252, y = 869.710, z = -40.463},
    {x = 518.799, y = 869.841, z = -40.920},
    {x = 521.278, y = 869.829, z = -41.348},
    {x = 523.833, y = 869.437, z = -41.472},
    {x = 526.438, y = 869.025, z = -41.574},
    {x = 529.020, y = 868.535, z = -41.696},
    {x = 531.610, y = 867.938, z = -41.751},
    {x = 534.120, y = 867.311, z = -41.776},
    {x = 536.551, y = 866.723, z = -41.961},
    {x = 539.029, y = 866.083, z = -42.155},
    {x = 541.540, y = 865.296, z = -42.369},
    {x = 543.989, y = 864.406, z = -42.592},
    {x = 546.307, y = 863.492, z = -42.813},
    {x = 548.592, y = 862.303, z = -42.915},
    {x = 550.995, y = 861.531, z = -42.978},
    {x = 553.480, y = 860.848, z = -43.046},
    {x = 556.065, y = 860.790, z = -43.067},
    {x = 558.316, y = 862.090, z = -43.091},
    {x = 560.325, y = 863.590, z = -43.139},
}

function sendLarekClick(subid)
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

local function walkDirect(tox, toy, acceptDist, timeout, stopAtEnd, brake)
    local startTime = os.clock()
    local lastX, lastY = nil, nil
    local stuckSince, sideDir = nil, 1
    while larekRunning do
        local okc, cx, cy = pcall(getCharCoordinates, PLAYER_PED)
        if not okc then break end
        local dx, dy = tox - cx, toy - cy
        local d = math.sqrt(dx*dx + dy*dy)
        if d <= acceptDist then
            if stopAtEnd then
                setGameKeyState(1, 0)
                setGameKeyState(0, 0)
            end
            return true
        end
        if os.clock() - startTime > timeout then
            setGameKeyState(0, 0)
            return false
        end
        setTargetAngle(getHeadingFromVector2d(dx, dy))
        smoothCameraRotation(d)
        local moveSpeed = -255
        if brake and d < 4.5 then

            local t = (d - acceptDist) / (4.5 - acceptDist)
            if t < 0 then t = 0 elseif t > 1 then t = 1 end
            moveSpeed = math.floor(-60 - 195 * t)
        end
        setGameKeyState(1, moveSpeed)
        if lastX then
            local mdx, mdy = cx - lastX, cy - lastY
            if math.sqrt(mdx*mdx + mdy*mdy) >= 0.15 then
                lastX, lastY = cx, cy
                stuckSince = nil
            elseif stuckSince == nil then
                stuckSince = os.clock()
            elseif os.clock() - stuckSince > 2.2 then

                setGameKeyState(1, -255)
                setGameKeyState(0, sideDir * 180)
                local sw = 0
                while larekRunning and sw < 300 do wait(1); sw = sw + 1 end
                setGameKeyState(14, 255); wait(90); setGameKeyState(14, 0)
                setGameKeyState(0, 0)
                sideDir = -sideDir
                local okr, rx, ry = pcall(getCharCoordinates, PLAYER_PED)
                if okr then lastX, lastY = rx, ry end
                stuckSince = nil
            end
        else
            lastX, lastY = cx, cy
        end
        wait(1)
    end
    return false
end

local function walkChainToward(tx, ty, tz)
    if not _safeRouteIndices then
        if not _navBuilding then lua_thread.create(buildSafeIndices) end
        return
    end
    local okc, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
    if not okc then return end
    if dist3(px, py, pz, tx, ty, tz) <= 10.0 then return end
    local sN = #_safeRouteIndices
    if sN == 0 then return end
    local sPos, sD, gPos, gD = nil, math.huge, nil, math.huge
    for k = 1, sN do
        local pt = recordedRoute[_safeRouteIndices[k]]
        local d1 = dist3(px, py, pz, pt.x, pt.y, pt.z)
        if d1 < sD then sD = d1; sPos = k end
        local d2 = dist3(tx, ty, tz, pt.x, pt.y, pt.z)
        if d2 < gD then gD = d2; gPos = k end
    end
    local path = findPath(sPos, gPos)
    if not path then return end
    for _, k in ipairs(path) do
        if not larekRunning then return end
        local pt = recordedRoute[_safeRouteIndices[k]]
        walkDirect(pt.x, pt.y, 3.5, 25, false)
    end
end

function goEatAtLarek()
    if larekRunning then return end
    larekRunning = true
    lua_thread.create(function()
        msg('\xd1\xfb\xf2\xee\xf1\xf2\xfc \xed\xe8\xe7\xea\xe0\xff, \xe1\xe5\xe3\xf3 \xea \xeb\xe0\xf0\xfc\xea\xf3')
        local wasRun = isRunning
        isRunning = true

        local entry = FOOD_ROUTE[1]
        walkChainToward(entry.x, entry.y, entry.z)

        local okAll = true
        for i = 1, #FOOD_ROUTE do
            if not larekRunning then okAll = false; break end
            local p = FOOD_ROUTE[i]
            local last = (i == #FOOD_ROUTE)
            if not walkDirect(p.x, p.y, last and 1.0 or 2.5, 35, last, last) then
                okAll = false
                break
            end
        end

        if okAll then
            playEatSound()
            wait(600)
            sendLarekClick(1)
            wait(700)
            sendLarekClick(1)
            wait(700)
            sendLarekClick(1)
            wait(700)
            sendLarekClick(0)
            wait(400)
            msg('\xc5\xe4\xe0 \xe2\xe7\xff\xf2\xe0, \xe2\xee\xe7\xe2\xf0\xe0\xf9\xe0\xfe\xf1\xfc')
        end

        for i = #FOOD_ROUTE - 1, 1, -1 do
            if not larekRunning then break end
            local p = FOOD_ROUTE[i]
            walkDirect(p.x, p.y, 2.5, 35, false)
        end

        resetNavState()
        _needRouteSnap = true
        isRunning = wasRun or sprint[0]
        nearestOrePos = nil
        for _, ore in ipairs(allOres) do
            local p = ore.pos
            if not ore.occupied and not isOreBlacklisted(p[1], p[2], p[3]) then
                nearestOrePos = {p[1], p[2], p[3]}
                break
            end
        end
        setGameKeyState(1, -255)
        larekRunning = false
    end)
end

function autoEatThread()
    while not isSampAvailable() do wait(500) end
    wait(4000)
    if autoEat then
        autoEatWaitSat = true
        sampSendChat('/satiety')
        local t = 0
        while autoEatWaitSat and t < 60 do wait(100); t = t + 1 end
        autoEatWaitSat = false
    end
    while true do
        wait(100)
        if autoEat then

            for i = 1, 300 do
                wait(100)
                if not autoEat then break end
            end

            if autoEat and mode and sampIsLocalPlayerSpawned() then
                autoEatWaitSat = true
                sampSendChat('/satiety')
                local t = 0
                while autoEatWaitSat and t < 60 do wait(100); t = t + 1 end
                autoEatWaitSat = false
                local threshold = (autoEatMode == 0) and 40 or autoEatMinSatiety
                if autoEatSatiety >= 0 and autoEatSatiety < threshold then
                    if autoEatMode == 0 then
                        if not larekRunning then
                            goEatAtLarek()
                            local tw = 0
                            while larekRunning and tw < 1200 do wait(100); tw = tw + 1 end
                        end
                    else
                        autoEatWaitEat = true
                        sampSendChat('/eat')
                        local t2 = 0
                        while autoEatWaitEat and t2 < 60 do wait(100); t2 = t2 + 1 end
                        autoEatWaitEat = false
                        wait(300)
                        if sampIsDialogActive() then
                            sampSendChat('/eat')
                        end
                    end
                end
            end
        end
    end
end

local aaAdminTriggers = {
    '\xc0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0',
    '\xf2\xe5\xeb\xe5\xef\xee\xf0\xf2\xe8\xf0\xee\xe2\xe0\xeb \xe2\xe0\xf1 \xed\xe0 \xea\xee\xee\xf0\xe4\xe8\xed\xe0\xf2\xfb',
    '\xee\xf2\xe2\xe5\xf2\xe8\xeb \xe2\xe0\xec:',
}

local function aaIsAdmin(text)
    for _, w in ipairs(aaAdminTriggers) do
        if text:find(w, 1, true) then return true end
    end
    return false
end

local aaBroadcastWords = {
    'МП', 'Приз', 'приз', 'Уважаем', 'Объявлен', 'объявлен',
    'розыгрыш', 'рулетк', 'мероприят', 'Глобальн', 'глобальн',
    '/gotp', 'преми', 'ивент', 'event', 'акци', 'Конкурс', 'конкурс',
    'Принимаем', 'набор',
}

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

function ai.jsonEscape(s)
    s = tostring(s or '')
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"', '\\"')
    s = s:gsub('\n', '\\n')
    s = s:gsub('\r', '\\r')
    s = s:gsub('\t', '\\t')
    s = s:gsub('[%z\1-\8\11\12\14-\31]', function(c)
        return string.format('\\u%04x', string.byte(c))
    end)
    return s
end

function ai.fromU8(s)
    local ok, r = pcall(function() return u8:decode(s) end)
    return (ok and r) or s
end

function ai.request(prompt, system, cb)
    lua_thread.create(function()
        local ok, req = pcall(require, 'requests')
        if not ok or not req then cb(false, 'no requests lib') return end

        local provider = ai.provider
        local model = ai.model
        local esc = ai.jsonEscape
        local url, headers, body

        if provider == 0 then
            if model == '' then model = 'claude-haiku-4-5' end
            url = 'https://api.anthropic.com/v1/messages'
            headers = {
                ['Content-Type']      = 'application/json',
                ['x-api-key']         = ai.keyClaude,
                ['anthropic-version'] = '2023-06-01',
            }
            body = '{"model":"'..esc(model)..'","max_tokens":150,'
                .. '"system":"'..esc(system)..'",'
                .. '"messages":[{"role":"user","content":"'..esc(prompt)..'"}]}'
        elseif provider == 1 then
            if model == '' then model = 'gpt-4o-mini' end
            url = 'https://api.openai.com/v1/chat/completions'
            headers = {
                ['Content-Type']  = 'application/json',
                ['Authorization'] = 'Bearer ' .. ai.keyOpenAI,
            }
            body = '{"model":"'..esc(model)..'","max_tokens":150,'
                .. '"messages":[{"role":"system","content":"'..esc(system)..'"},'
                .. '{"role":"user","content":"'..esc(prompt)..'"}]}'
        elseif provider == 2 then
            if model == '' then model = 'gemini-2.0-flash' end
            url = 'https://generativelanguage.googleapis.com/v1beta/models/'
                .. model .. ':generateContent?key=' .. ai.keyGemini
            headers = { ['Content-Type'] = 'application/json' }
            body = '{"system_instruction":{"parts":[{"text":"'..esc(system)..'"}]},'
                .. '"contents":[{"role":"user","parts":[{"text":"'..esc(prompt)..'"}]}],'
                .. '"generationConfig":{"maxOutputTokens":150}}'
        else
            if model == '' then model = 'llama-3.3-70b-versatile' end
            url = 'https://api.groq.com/openai/v1/chat/completions'
            headers = {
                ['Content-Type']  = 'application/json',
                ['Authorization'] = 'Bearer ' .. ai.keyGroq,
            }
            body = '{"model":"'..esc(model)..'","max_tokens":150,'
                .. '"messages":[{"role":"system","content":"'..esc(system)..'"},'
                .. '{"role":"user","content":"'..esc(prompt)..'"}]}'
        end

        local rok, resp = pcall(req.post, url, { headers = headers, data = body })
        if not rok or not resp then cb(false, 'no response') return end
        local bodyText = resp.text or resp.content or ''
        if resp.status_code ~= 200 then
            cb(false, 'HTTP ' .. tostring(resp.status_code) .. ': ' .. tostring(bodyText):sub(1, 160))
            return
        end

        local data = json.parse(bodyText)
        if not data then cb(false, 'json parse error') return end

        local text
        if provider == 0 then
            text = data.content and data.content[1] and data.content[1].text
        elseif provider == 2 then
            text = data.candidates and data.candidates[1] and data.candidates[1].content
                and data.candidates[1].content.parts and data.candidates[1].content.parts[1]
                and data.candidates[1].content.parts[1].text
        else
            text = data.choices and data.choices[1] and data.choices[1].message
                and data.choices[1].message.content
        end

        if not text or text == '' then cb(false, 'empty answer') return end
        text = text:gsub('^%s+', ''):gsub('%s+$', '')
        cb(true, text)
    end)
end

function ai.requestChat(msgs, system, cb)
    lua_thread.create(function()
        local ok, req = pcall(require, 'requests')
        if not ok or not req then cb(false, 'no requests lib') return end
        local esc = ai.jsonEscape
        local provider = ai.provider
        local model = ai.model
        local url, headers, body

        if provider == 0 then
            if model == '' then model = 'claude-haiku-4-5' end
            local parts = {}
            for _, m in ipairs(msgs) do
                parts[#parts+1] = '{"role":"'..(m.role == 'assistant' and 'assistant' or 'user')
                    ..'","content":"'..esc(m.text)..'"}'
            end
            url = 'https://api.anthropic.com/v1/messages'
            headers = {
                ['Content-Type']      = 'application/json',
                ['x-api-key']         = ai.keyClaude,
                ['anthropic-version'] = '2023-06-01',
            }
            body = '{"model":"'..esc(model)..'","max_tokens":400,"system":"'..esc(system)
                ..'","messages":['..table.concat(parts, ',')..']}'
        elseif provider == 1 then
            if model == '' then model = 'gpt-4o-mini' end
            local parts = { '{"role":"system","content":"'..esc(system)..'"}' }
            for _, m in ipairs(msgs) do
                parts[#parts+1] = '{"role":"'..(m.role == 'assistant' and 'assistant' or 'user')
                    ..'","content":"'..esc(m.text)..'"}'
            end
            url = 'https://api.openai.com/v1/chat/completions'
            headers = {
                ['Content-Type']  = 'application/json',
                ['Authorization'] = 'Bearer ' .. ai.keyOpenAI,
            }
            body = '{"model":"'..esc(model)..'","max_tokens":400,"messages":['..table.concat(parts, ',')..']}'
        elseif provider == 2 then
            if model == '' then model = 'gemini-2.0-flash' end
            local parts = {}
            for _, m in ipairs(msgs) do
                parts[#parts+1] = '{"role":"'..(m.role == 'assistant' and 'model' or 'user')
                    ..'","parts":[{"text":"'..esc(m.text)..'"}]}'
            end
            url = 'https://generativelanguage.googleapis.com/v1beta/models/'
                .. model .. ':generateContent?key=' .. ai.keyGemini
            headers = { ['Content-Type'] = 'application/json' }
            body = '{"system_instruction":{"parts":[{"text":"'..esc(system)..'"}]},'
                .. '"contents":['..table.concat(parts, ',')..'],'
                .. '"generationConfig":{"maxOutputTokens":400}}'
        else
            if model == '' then model = 'llama-3.3-70b-versatile' end
            local parts = { '{"role":"system","content":"'..esc(system)..'"}' }
            for _, m in ipairs(msgs) do
                parts[#parts+1] = '{"role":"'..(m.role == 'assistant' and 'assistant' or 'user')
                    ..'","content":"'..esc(m.text)..'"}'
            end
            url = 'https://api.groq.com/openai/v1/chat/completions'
            headers = {
                ['Content-Type']  = 'application/json',
                ['Authorization'] = 'Bearer ' .. ai.keyGroq,
            }
            body = '{"model":"'..esc(model)..'","max_tokens":400,"messages":['..table.concat(parts, ',')..']}'
        end

        local rok, resp = pcall(req.post, url, { headers = headers, data = body })
        if not rok or not resp then cb(false, 'no response') return end
        local bodyText = resp.text or resp.content or ''
        if resp.status_code ~= 200 then
            cb(false, 'HTTP ' .. tostring(resp.status_code) .. ': ' .. tostring(bodyText):sub(1, 200))
            return
        end
        local data = json.parse(bodyText)
        if not data then cb(false, 'json parse error') return end

        local text
        if provider == 0 then
            text = data.content and data.content[1] and data.content[1].text
        elseif provider == 2 then
            text = data.candidates and data.candidates[1] and data.candidates[1].content
                and data.candidates[1].content.parts and data.candidates[1].content.parts[1]
                and data.candidates[1].content.parts[1].text
        else
            text = data.choices and data.choices[1] and data.choices[1].message
                and data.choices[1].message.content
        end
        if not text or text == '' then cb(false, 'empty answer') return end
        text = text:gsub('^%s+', ''):gsub('%s+$', '')
        cb(true, text)
    end)
end

function ai.buildPrompt(qUtf8, adminName)
    local head
    if adminName and adminName ~= '' then
        head = u8('\xc0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0 ') .. adminName
            .. u8(' \xef\xe8\xf8\xe5\xf2 \xf2\xe5\xe1\xe5 \xe2 \xf7\xe0\xf2: ')
    else
        head = u8('\xc0\xe4\xec\xe8\xed \xef\xe8\xf8\xe5\xf2 \xf2\xe5\xe1\xe5 \xe2 \xf7\xe0\xf2: ')
    end
    return head .. qUtf8
        .. u8('\n\xce\xf2\xe2\xe5\xf2\xfc \xea\xee\xf0\xee\xf2\xea\xee \xe8 \xe5\xf1\xf2\xe5\xf1\xf2\xe2\xe5\xed\xed\xee, \xea\xe0\xea \xe6\xe8\xe2\xee\xe9 \xe8\xe3\xf0\xee\xea.')
end

function ai.extractAdminName(text)
    if not text then return '' end
    local n = text:match('\xc0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0%s+([%w_%[%]%(%)]+)')
    if not n then n = text:match('([%w_%[%]]+)%s+\xee\xf2\xe2\xe5\xf2\xe8\xeb') end
    if n then
        n = n:gsub('%[%d+%]', ''):gsub('[%(%)%[%]]', '')
        if #n >= 3 then return n end
    end
    return ''
end

function ai.classifyAdmin(qUtf8, cb)
    if not (ai.enabled and ai.activeKey() ~= '') then cb(nil) return end
    ai.request(qUtf8, ai.CLASSIFY_SYSTEM, function(ok, text)
        if not ok or not text then cb(nil) return end
        local up = tostring(text):upper()
        if up:find('YES') then cb(true)
        elseif up:find('NO') then cb(false)
        else cb(nil) end
    end)
end

local function aaSendReply(questionText)
    if aaReplying or aaAngry >= 2 then return end
    aaReplying = true
    aaAngry = aaAngry + 1
    aaTimes = os.clock()

    if ai.enabled and ai.activeKey() ~= '' and questionText then
        ai.request(ai.buildPrompt(u8(questionText), u8(ai.lastAdminName or '')), ai.system, function(ok, text)
            local mesg
            if ok and text and text ~= '' then
                local cp = ai.fromU8(text)
                cp = cp:gsub('[\r\n]+', ' ')
                cp = cp:gsub('^["\'\xab%s]+', ''):gsub('["\'\xbb%s]+$', '')
                if cp:sub(1, 3) == '/b ' then cp = cp:sub(4) end
                if #cp > 100 then cp = cp:sub(1, 100) end
                if cp ~= '' then mesg = '/b ' .. cp end
            end
            if not mesg then
                local smart = aaSmartAnswer(questionText)
                if smart then mesg = '/b ' .. smart
                elseif aaAngry == 1 then mesg = otvet_1[math.random(#otvet_1)]
                else mesg = otvet_2[math.random(#otvet_2)] end
            end
            wait(math.random(3500, 7000))
            sampSendChat(mesg)
            aaReplying = false
        end)
        return
    end

    wait(math.random(7000, 11000))
    local mesg
    local smart = aaSmartAnswer(questionText)
    if smart then
        mesg = '/b ' .. smart
    elseif aaAngry == 1 then
        mesg = otvet_1[math.random(#otvet_1)]
    else
        mesg = otvet_2[math.random(#otvet_2)]
    end
    sampSendChat(mesg)
    aaReplying = false
end

local function emergencyStop(reason)
    mode = false
    larekRunning = false
    _miningStuckRetry = false
    nearestOrePos = nil
    currentMiningTarget = nil
    jumping = false
    isRunning = false
    setGameKeyState(1, 0)
    setGameKeyState(16, 0)
    setGameKeyState(14, 0)
    setGameKeyState(0, 0)
    msg(reason)
    playAntiAdminSound()
    if quitOnStop then
        lua_thread.create(function()
            wait(2000)
            os.exit(1)
        end)
    end
end

lua_thread.create(function()
    while true do
        wait(500)
        if aaState and mode and sampIsDialogActive() then
            if os.clock() - aaTimes > 15 and not aaReplying and aaAngry < 2 then
                local q = aaLastQuestion
                lua_thread.create(function() aaSendReply(q) end)
            end
        end
    end
end)

function sampev.onServerMessage(color, text)
    if not text then return end
    local txtClean = text:gsub('{%x%x%x%x%x%x}', '')

    if txtClean:find('\xc2\xf0\xe5\xec\xff \xe4\xe5\xe9\xf1\xf2\xe2\xe8\xff \xec\xe0\xf1\xea\xe8', 1, true) then
        maskConfirmed = true
    end

    if aaAngry > 0 and os.clock() - aaLastTrigger > 300 then
        aaAngry = 0
    end

    if mode and stopOnChat and (os.clock() - antiAdminEnableTime) >= 5.0 then
        if txtClean:find('\xc2\xfb \xf2\xf3\xf2', 1, true) or txtClean:find('\xc2\xfb \xe7\xe4\xe5\xf1\xfc', 1, true)
        or txtClean:find('\xe2\xfb \xf2\xf3\xf2', 1, true) or txtClean:find('\xe2\xfb \xe7\xe4\xe5\xf1\xfc', 1, true) then
            emergencyStop('\xd1\xf2\xee\xef: \xef\xf0\xee\xe2\xe5\xf0\xea\xe0 \xe2 \xf7\xe0\xf2\xe5')
            return
        end
    end

    if aaState and mode and aaIsAdmin(txtClean) then
        if not aaReplying and aaAngry < 2 then
            local q = txtClean
            ai.classifyAdmin(u8(q), function(directed)
                if directed == nil then directed = aaLooksDirected(q) end
                if not directed then return end
                if aaReplying or aaAngry >= 2 then return end
                aaLastTrigger = os.clock()
                playAntiAdminSound()
                ai.lastAdminName = ai.extractAdminName(q)
                aaLastQuestion = q
                lua_thread.create(function() aaSendReply(q) end)
            end)
        end
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)

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
            playEatSound()
            local row = autoEatFood
            local buyCount = 3
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

    if stopOnDialog and mode then
        if (os.clock() - antiAdminEnableTime) >= 5.0 then
            emergencyStop('\xd1\xf2\xee\xef: \xe4\xe8\xe0\xeb\xee\xe3 \xee\xf2 \xf1\xe5\xf0\xe2\xe5\xf0\xe0')
            return
        end
    end
    if aaState and mode then
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
    if stopOnTp and mode then
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
        emergencyStop('\xd1\xf2\xee\xef: \xf2\xe5\xeb\xe5\xef\xee\xf0\xf2 \xf1\xe5\xf0\xe2\xe5\xf0\xe0')
    end
end

local _MDS = MONET_DPI_SCALE or 1

imgui.OnFrame(
    function() return not fabHidden end,
    function(self)
        self.HideCursor = true
        local sw, sh = getScreenResolution()
        local bw  = 101 * _MDS
        local msw = 36 * _MDS
        local gap = 6 * _MDS
        local bh  = 37 * _MDS
        local totalW = bw + gap + msw
        local px = 28 * _MDS
        local py = sh * 0.72 - bh * 0.5

        imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(totalW, bh), imgui.Cond.Always)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        imgui.Begin('##mbot_fab', nil, bit.bor(
            imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize,
            imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoBackground,
            imgui.WindowFlags.NoMove, imgui.WindowFlags.NoBringToFrontOnFocus))

        local DL = imgui.GetWindowDrawList()
        local WP = imgui.GetWindowPos()
        local u32 = imgui.ColorConvertFloat4ToU32
        local mx, my = imgui.GetIO().MousePos.x, imgui.GetIO().MousePos.y
        local isRun = mode

        if headerFont then imgui.PushFont(headerFont) end

        local AMBER  = imgui.ImVec4(1.00, 0.72, 0.22, 1.00)
        local EMBER  = imgui.ImVec4(0.90, 0.34, 0.22, 1.00)
        local COPPER = imgui.ImVec4(0.72, 0.42, 0.20, 1.00)
        local BORDER = imgui.ImVec4(0.34, 0.27, 0.16, 1.00)
        local accent = isRun and EMBER or AMBER

        local over = mx >= WP.x and mx <= WP.x+bw and my >= WP.y and my <= WP.y+bh
        local baseBg = over and imgui.ImVec4(0.205,0.180,0.140,1.00) or imgui.ImVec4(0.150,0.135,0.110,1.00)
        DL:AddRectFilled(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+bw,WP.y+bh), u32(baseBg))
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+5*_MDS, WP.y+bh), u32(accent))
        local lbl   = isRun and u8'\xd1\xd2\xce\xcf' or u8'\xd1\xd2\xc0\xd0\xd2'
        local glyph = isRun and IC.stop or IC.play
        local lblColU  = u32(imgui.ImVec4(0.95,0.92,0.84,1))
        local iconColU = u32(accent)
        local midY  = WP.y + bh / 2
        local iw, ih = 0, 0
        if _faOK and iconFontBig then
            imgui.PushFont(iconFontBig)
            local s = imgui.CalcTextSize(glyph); iw, ih = s.x, s.y
            imgui.PopFont()
        end
        local lf = headerFont or mainFont
        imgui.PushFont(lf)
        local ls = imgui.CalcTextSize(lbl)
        imgui.PopFont()
        local gp   = (iw > 0) and 7*_MDS or 0
        local zoneL = WP.x + 5*_MDS
        local grpL = zoneL + ((WP.x + bw) - zoneL - (iw + gp + ls.x)) / 2
        if iw > 0 then
            imgui.PushFont(iconFontBig)
            DL:AddText(imgui.ImVec2(grpL, midY - ih/2), iconColU, glyph)
            imgui.PopFont()
        end
        imgui.PushFont(lf)
        DL:AddText(imgui.ImVec2(grpL + iw + gp, midY - ls.y/2), lblColU, lbl)
        imgui.PopFont()
        local brdC = over and accent or BORDER
        DL:AddRect(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+bw,WP.y+bh), u32(brdC), 0, 0, 1.5)

        imgui.SetCursorPos(imgui.ImVec2(0,0))
        if imgui.InvisibleButton('##fabstart', imgui.ImVec2(bw, bh)) then
            if not licenseOK then
                licWinOpen[0] = true
            else
                mode = not mode
                if mode then
                    goalReached = false
                    antiAdminEnableTime = os.clock()
                    _needRouteSnap = true
                end
            end
        end

        local mbX = WP.x + bw + gap
        local overM = mx >= mbX and mx <= mbX+msw and my >= WP.y and my <= WP.y+bh
        local menuOpen = WinState[0]
        local mBg = (menuOpen or overM) and imgui.ImVec4(0.205,0.180,0.140,1.00) or imgui.ImVec4(0.150,0.135,0.110,1.00)
        DL:AddRectFilled(imgui.ImVec2(mbX,WP.y), imgui.ImVec2(mbX+msw,WP.y+bh), u32(mBg))
        local mBrd = menuOpen and AMBER or (overM and COPPER or BORDER)
        DL:AddRect(imgui.ImVec2(mbX,WP.y), imgui.ImVec2(mbX+msw,WP.y+bh), u32(mBrd), 0, 0, 1.5)
        local hcol = u32((menuOpen or overM) and AMBER or imgui.ImVec4(0.70,0.62,0.46,1.00))
        if _faOK and iconFontBig then
            imgui.PushFont(iconFontBig)
            local gs = imgui.CalcTextSize(IC.bars)
            DL:AddText(imgui.ImVec2(mbX + (msw-gs.x)*0.5, WP.y + (bh-gs.y)*0.5), hcol, IC.bars)
            imgui.PopFont()
        else
            local hx1, hx2 = mbX+10*_MDS, mbX+msw-10*_MDS
            for k = -1, 1 do
                local hy = WP.y + bh*0.5 + k*5*_MDS
                DL:AddLine(imgui.ImVec2(hx1, hy), imgui.ImVec2(hx2, hy), hcol, 2*_MDS)
            end
        end
        imgui.SetCursorPos(imgui.ImVec2(bw+gap, 0))
        if imgui.InvisibleButton('##fabmenu', imgui.ImVec2(msw, bh)) then
            if not licenseOK then
                licWinOpen[0] = true
            else
                WinState[0] = not WinState[0]
            end
        end

        if headerFont then imgui.PopFont() end
        imgui.End()
        imgui.PopStyleVar()
    end
)

imgui.OnFrame(
    function() return licWinOpen[0] end,
    function(self)
        self.HideCursor = false
        local sw, sh = getScreenResolution()
        local W = 380 * _MDS
        local H = 200 * _MDS
        imgui.SetNextWindowSize(imgui.ImVec2(W, H), imgui.Cond.Always)
        imgui.SetNextWindowPos(imgui.ImVec2((sw - W) * 0.5, (sh - H) * 0.5), imgui.Cond.Always)
        imgui.Begin('##stmine_lic', licWinOpen, bit.bor(
            imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize,
            imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoMove))

        local DL  = imgui.GetWindowDrawList()
        local WP  = imgui.GetWindowPos()
        local u32 = imgui.ColorConvertFloat4ToU32

        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+H),
            u32(imgui.ImVec4(0.105, 0.095, 0.080, 0.99)))
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+4*_MDS),
            u32(imgui.ImVec4(1.00, 0.72, 0.22, 1.00)))
        DL:AddRect(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+H),
            u32(imgui.ImVec4(0.85, 0.55, 0.20, 1.00)), 0, 0, 2)
        DL:AddRect(imgui.ImVec2(WP.x+3*_MDS, WP.y+3*_MDS), imgui.ImVec2(WP.x+W-3*_MDS, WP.y+H-3*_MDS),
            u32(imgui.ImVec4(0.34, 0.27, 0.16, 0.85)), 0, 0, 1)

        local pad = 16 * _MDS

        if titleFont then imgui.PushFont(titleFont) end
        imgui.SetCursorPos(imgui.ImVec2(pad, 16*_MDS))
        imgui.TextColored(imgui.ImVec4(1.00, 0.72, 0.22, 1.00), u8'ST MINE - \xc0\xea\xf2\xe8\xe2\xe0\xf6\xe8\xff')
        if titleFont then imgui.PopFont() end

        if mainFont then imgui.PushFont(mainFont) end
        imgui.SetCursorPos(imgui.ImVec2(pad, 46*_MDS))
        imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8'\xcf\xee\xeb\xf3\xf7\xe8\xf2\xfc \xea\xeb\xfe\xf7: @victor_st0')

        imgui.SetCursorPos(imgui.ImVec2(pad, 72*_MDS))
        imgui.PushItemWidth(W - pad*2)
        imgui.InputText('##stmine_lickey', licInputBuf, 64)
        imgui.PopItemWidth()

        if licenseMsg ~= '' then
            imgui.SetCursorPos(imgui.ImVec2(pad, 106*_MDS))
            local mc = licenseChecking and imgui.ImVec4(0.95,0.80,0.20,1) or imgui.ImVec4(1.00,0.35,0.35,1)
            imgui.TextColored(mc, licenseMsg)
        end

        local bH  = 38 * _MDS
        local bW1 = (W - pad*2) * 0.64
        local bW2 = (W - pad*2) - bW1 - 8*_MDS
        imgui.SetCursorPos(imgui.ImVec2(pad, H - bH - 16*_MDS))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.85,0.55,0.18,1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00,0.72,0.22,1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.72,0.46,0.16,1))
        if imgui.Button(u8'\xc0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xf2\xfc', imgui.ImVec2(bW1, bH)) then
            local k = bufToStr(licInputBuf, 64):match('^%s*(.-)%s*$')
            if #k > 3 then checkLicenseAsync(k) else licenseMsg = u8'\xc2\xe2\xe5\xe4\xe8\xf2\xe5 \xea\xeb\xfe\xf7' end
        end
        imgui.PopStyleColor(3)
        imgui.SameLine(0, 8*_MDS)
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.20,0.17,0.13,1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.28,0.23,0.17,1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.16,0.13,0.10,1))
        if imgui.Button(u8'\xc7\xe0\xea\xf0\xfb\xf2\xfc', imgui.ImVec2(bW2, bH)) then
            licWinOpen[0] = false
        end
        imgui.PopStyleColor(3)

        if mainFont then imgui.PopFont() end
        imgui.End()
    end
)

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
        imgui.Begin('##stmine_aaimg', nil, bit.bor(
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
    function() return mode end,
    function(self)
        self.HideCursor = true
        local target = currentTracerOre
        if not target and not oreEsp[0] then return end
        local ok, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
        if not ok or type(px) ~= 'number' then return end
        local ok2, cx, cy, cz = pcall(getActiveCameraCoordinates)
        local ok3, lx, ly, lz = pcall(getActiveCameraPointAt)
        if not (ok2 and ok3) then return end
        local fdx, fdy, fdz = lx - cx, ly - cy, lz - cz
        local fl = math.sqrt(fdx*fdx + fdy*fdy + fdz*fdz)
        if fl < 0.001 then return end
        fdx, fdy, fdz = fdx/fl, fdy/fl, fdz/fl
        local sx1, sy1 = convert3DCoordsToScreen(px, py, pz)
        if not (sx1 and sy1) then return end
        local fdl = imgui.GetForegroundDrawList()

        local function projVisible(wx, wy, wz)
            local vx, vy, vz = wx - cx, wy - cy, wz - cz
            local vl = math.sqrt(vx*vx + vy*vy + vz*vz)
            if vl < 0.001 or (vx*fdx + vy*fdy + vz*fdz)/vl <= 0.1 then return nil end
            return convert3DCoordsToScreen(wx, wy, wz)
        end

        if target then
            local tsx, tsy = projVisible(target[1], target[2], target[3])
            if tsx and tsy then
                fdl:AddLine(imgui.ImVec2(sx1, sy1), imgui.ImVec2(tsx, tsy), 0x4400FF00, 8)
                fdl:AddLine(imgui.ImVec2(sx1, sy1), imgui.ImVec2(tsx, tsy), 0xEE00FF00, 4)
                fdl:AddCircleFilled(imgui.ImVec2(tsx, tsy), 5 * _MDS, 0xFFFFFFFF)
                fdl:AddCircleFilled(imgui.ImVec2(tsx, tsy), 3 * _MDS, 0xCC00FF00)
            end
        end

        if oreEsp[0] then
            for _, ore in ipairs(allOres) do
                local s2x, s2y = projVisible(ore.pos[1], ore.pos[2], ore.pos[3])
                if s2x and s2y then
                    fdl:AddCircleFilled(imgui.ImVec2(s2x, s2y), 4 * _MDS, 0xBB888888)
                end
            end
        end

        fdl:AddCircleFilled(imgui.ImVec2(sx1, sy1), 6 * _MDS, 0xFFFFFFFF)
        fdl:AddCircleFilled(imgui.ImVec2(sx1, sy1), 5 * _MDS, 0xCCFFAA00)
    end
)

function sampev.onDestroyObject(id) end

function sampev.onDisplayGameText(style, time, text)
    local lower = text:lower()
    local oreType = nil
    if     lower:find('^stone')  then oreType = 'stone'
    elseif lower:find('^metal')  then oreType = 'metal'
    elseif lower:find('^bronze') then oreType = 'bronze'
    elseif lower:find('^silver') then oreType = 'silver'
    elseif lower:find('^gold')   then oreType = 'gold'
    end
    if oreType then
        local num = tonumber(text:match('%+%s*(%d+)'))
        if num and num >= 1 and num <= 10 then
            if     oreType == 'stone'  then totalStone  = totalStone  + num
            elseif oreType == 'metal'  then totalMetal  = totalMetal  + num
            elseif oreType == 'bronze' then totalBronze = totalBronze + num
            elseif oreType == 'silver' then totalSilver = totalSilver + num
            elseif oreType == 'gold'   then totalGold   = totalGold   + num
            end
            _statsDirty = true

            if mode then
                local cx, cy
                if currentMiningTarget then
                    cx, cy = currentMiningTarget[1], currentMiningTarget[2]
                end
                nearestOrePos       = nil
                currentMiningTarget = nil
                lastMiningAttempt   = 0
                _miningFailKey      = nil
                _miningFailCount    = 0
                _miningStuckRetry   = false
                _miningStuckOrePos  = nil
                resetNavState()
                jumping   = jumpp[0]
                isRunning = sprint[0]

                local nt = _nextTarget
                if nt and not isOreBlacklisted(nt[1], nt[2], nt[3])
                    and not isOreOccupied(nt[1], nt[2], nt[3])
                    and not (cx and math.abs(nt[1] - cx) < 2.0 and math.abs(nt[2] - cy) < 2.0) then
                    nearestOrePos = {nt[1], nt[2], nt[3]}
                else
                    for _, ore in ipairs(allOres) do
                        local p = ore.pos
                        if not ore.occupied
                            and not isOreBlacklisted(p[1], p[2], p[3])
                            and not (cx and math.abs(p[1] - cx) < 2.0 and math.abs(p[2] - cy) < 2.0) then
                            nearestOrePos = {p[1], p[2], p[3]}
                            break
                        end
                    end
                end
                _nextTarget = nil
            end
        end
    end
end

local function theme()
    imgui.SwitchContext()
    local ImVec4 = imgui.ImVec4
    local st = imgui.GetStyle()
    st.WindowPadding     = imgui.ImVec2(14, 14)
    st.FramePadding      = imgui.ImVec2(11, 8)
    st.ItemSpacing       = imgui.ImVec2(8, 10)
    st.ItemInnerSpacing  = imgui.ImVec2(6, 6)
    st.IndentSpacing     = 0
    st.ScrollbarSize     = 26
    st.GrabMinSize       = 32
    st.WindowBorderSize  = 0
    st.ChildBorderSize   = 0
    st.PopupBorderSize   = 0
    st.FrameBorderSize   = 1
    st.WindowRounding    = 0
    st.ChildRounding     = 0
    st.FrameRounding     = 0
    st.PopupRounding     = 0
    st.ScrollbarRounding = 0
    st.GrabRounding      = 0
    st.TabRounding       = 0
    st.Colors[imgui.Col.Text]                 = ImVec4(0.91, 0.88, 0.80, 1.00)
    st.Colors[imgui.Col.TextDisabled]         = ImVec4(0.56, 0.52, 0.45, 1.00)
    st.Colors[imgui.Col.WindowBg]             = ImVec4(0.105, 0.095, 0.080, 0.99)
    st.Colors[imgui.Col.ChildBg]              = ImVec4(0.000, 0.000, 0.000, 0.00)
    st.Colors[imgui.Col.PopupBg]              = ImVec4(0.135, 0.120, 0.098, 0.99)
    st.Colors[imgui.Col.Border]               = ImVec4(0.34, 0.27, 0.16, 0.80)
    st.Colors[imgui.Col.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
    st.Colors[imgui.Col.FrameBg]              = ImVec4(0.165, 0.148, 0.120, 1.00)
    st.Colors[imgui.Col.FrameBgHovered]       = ImVec4(0.215, 0.190, 0.150, 1.00)
    st.Colors[imgui.Col.FrameBgActive]        = ImVec4(0.255, 0.220, 0.165, 1.00)
    st.Colors[imgui.Col.TitleBg]              = ImVec4(0.09, 0.08, 0.065, 1.00)
    st.Colors[imgui.Col.TitleBgActive]        = ImVec4(0.11, 0.10, 0.080, 1.00)
    st.Colors[imgui.Col.TitleBgCollapsed]     = ImVec4(0.09, 0.08, 0.065, 1.00)
    st.Colors[imgui.Col.MenuBarBg]            = ImVec4(0.11, 0.10, 0.080, 1.00)
    st.Colors[imgui.Col.ScrollbarBg]          = ImVec4(0.00, 0.00, 0.00, 0.00)
    st.Colors[imgui.Col.ScrollbarGrab]        = ImVec4(0.32, 0.26, 0.16, 0.95)
    st.Colors[imgui.Col.ScrollbarGrabHovered] = ImVec4(0.85, 0.55, 0.20, 0.85)
    st.Colors[imgui.Col.ScrollbarGrabActive]  = ImVec4(1.00, 0.72, 0.22, 1.00)
    st.Colors[imgui.Col.CheckMark]            = ImVec4(1.00, 0.72, 0.22, 1.00)
    st.Colors[imgui.Col.SliderGrab]           = ImVec4(0.95, 0.66, 0.22, 1.00)
    st.Colors[imgui.Col.SliderGrabActive]     = ImVec4(1.00, 0.78, 0.30, 1.00)
    st.Colors[imgui.Col.Button]               = ImVec4(0.205, 0.180, 0.140, 1.00)
    st.Colors[imgui.Col.ButtonHovered]        = ImVec4(0.95, 0.62, 0.20, 0.92)
    st.Colors[imgui.Col.ButtonActive]         = ImVec4(0.80, 0.50, 0.16, 1.00)
    st.Colors[imgui.Col.Header]               = ImVec4(1.00, 0.72, 0.22, 0.26)
    st.Colors[imgui.Col.HeaderHovered]        = ImVec4(1.00, 0.72, 0.22, 0.42)
    st.Colors[imgui.Col.HeaderActive]         = ImVec4(1.00, 0.72, 0.22, 0.60)
    st.Colors[imgui.Col.Separator]            = ImVec4(0.34, 0.27, 0.16, 0.70)
    st.Colors[imgui.Col.SeparatorHovered]     = ImVec4(0.85, 0.55, 0.20, 0.70)
    st.Colors[imgui.Col.SeparatorActive]      = ImVec4(1.00, 0.72, 0.22, 1.00)
end

imgui.OnInitialize(function()
    theme()
    local io = imgui.GetIO()
    local glyph_ranges = io.Fonts:GetGlyphRangesCyrillic()

    _faMerged = false
    pcall(function()
        pcall(function() _fa = require('fAwesome6') end)
        if not _fa then pcall(function() _fa = require('fAwesome6_solid') end) end
        if _fa then
            _faCfg = imgui.ImFontConfig()
            _faCfg.MergeMode  = true
            _faCfg.PixelSnapH = true
            _faRange = imgui.new.ImWchar[3](_fa.min_range, _fa.max_range, 0)
        end
    end)

    local function _faData()
        local d
        if pcall(function() d = _fa.get_font_data_base85('solid') end) and d then return d end
        if pcall(function() d = _fa.get_font_data_base85() end) and d then return d end
        return nil
    end

    local function addFont(px)
        local f = io.Fonts:AddFontFromFileTTF('resource/Trebucbd.ttf', px, nil, glyph_ranges)
        if _fa and _faRange then
            local data = _faData()
            if data then
                local ok = pcall(function()
                    io.Fonts:AddFontFromMemoryCompressedBase85TTF(data, px, _faCfg, _faRange)
                end)
                if ok then _faMerged = true end
            end
        end
        return f
    end

    mainFont   = addFont(14.0)
    titleFont  = addFont(18.0)
    headerFont = addFont(16.0)
    iconFont   = headerFont

    iconFontBig = nil
    if _fa and _faRange then
        local data = _faData()
        if data then
            pcall(function()
                _faCfg2 = imgui.ImFontConfig()
                _faCfg2.PixelSnapH = true
                iconFontBig = io.Fonts:AddFontFromMemoryCompressedBase85TTF(data, 30.0, _faCfg2, _faRange)
            end)
        end
    end
    if not iconFontBig then iconFontBig = titleFont end
    _faOK = _faMerged
end)

local function renderSectionHeader(text)
    imgui.Dummy(imgui.ImVec2(0, 4))

    local mp = imgui.GetCursorScreenPos()
    local mdl = imgui.GetWindowDrawList()
    imgui.PushFont(headerFont)
    local th = imgui.GetTextLineHeight()
    local amber  = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.72, 0.22, 1.00))
    local amberD = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.85, 0.55, 0.20, 1.00))
    mdl:AddRectFilled(imgui.ImVec2(mp.x, mp.y + 2), imgui.ImVec2(mp.x + 5, mp.y + th), amber)
    mdl:AddRectFilled(imgui.ImVec2(mp.x + 8, mp.y + 4), imgui.ImVec2(mp.x + 12, mp.y + th - 2), amberD)
    imgui.SetCursorPosX(imgui.GetCursorPosX() + 20)
    imgui.TextColored(imgui.ImVec4(0.95, 0.92, 0.84, 1.00), text)
    imgui.PopFont()

    local p = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()
    local width = imgui.GetContentRegionAvail().x

    dl:AddRectFilledMultiColor(
        imgui.ImVec2(p.x, p.y + 4),
        imgui.ImVec2(p.x + width, p.y + 6),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.72, 0.22, 0.60)),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.72, 0.22, 0.00)),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.72, 0.22, 0.00)),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.72, 0.22, 0.60))
    )

    imgui.Dummy(imgui.ImVec2(0, 14))
end

local function renderMainTab()
    imgui.SetCursorPos(imgui.ImVec2(20, 10))

    local _avail  = imgui.GetContentRegionAvail()
    local _minerW = math.floor(_avail.x * 0.24)
    if _minerW < 170 then _minerW = 170 end
    local _leftW  = _avail.x - _minerW - 18

    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(10, 10))
    imgui.BeginChild("##mtab_left", imgui.ImVec2(_leftW, 0), false)
    imgui.BeginGroup()

    renderSectionHeader(u8"\xc3\xeb\xe0\xe2\xed\xe0\xff")

    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xc0\xe2\xf2\xee\xec\xe0\xf2\xe8\xf7\xe5\xf1\xea\xe0\xff \xe4\xee\xe1\xfb\xf7\xe0")
    imgui.Dummy(imgui.ImVec2(0, 4))
    if imgui.Checkbox(u8"\xc0\xea\xf2\xe8\xe2\xed\xee\xf1\xf2\xfc \xe1\xee\xf2\xe0", imgui.new.bool(mode)) then
        if not licenseOK then
            licWinOpen[0] = true
        else
            mode = not mode
            if mode then
                goalReached = false
                antiAdminEnableTime = os.clock()
                local ok_p, px_s, py_s, pz_s = pcall(getCharCoordinates, PLAYER_PED)
                if ok_p then
                    currentRoutePoint = findNearestRoutePoint(px_s, py_s, pz_s)
                end
            end
        end
    end

    imgui.Dummy(imgui.ImVec2(0, 10))
    do
        local sp = imgui.GetCursorScreenPos()
        local cw = imgui.GetContentRegionAvail().x
        imgui.GetWindowDrawList():AddLine(imgui.ImVec2(sp.x, sp.y), imgui.ImVec2(sp.x+cw, sp.y), 0x22FFFFFF, 1)
        imgui.Dummy(imgui.ImVec2(0, 10))
    end

    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xd3\xef\xf0\xe0\xe2\xeb\xe5\xed\xe8\xe5")
    imgui.Dummy(imgui.ImVec2(0, 4))
    if imgui.Checkbox(u8"\xc1\xe5\xe3", sprint) then
        toggleRun()
    end
    imgui.SameLine()
    if imgui.Checkbox(u8"\xcf\xf0\xfb\xe6\xea\xe8", jumpp) then
        toggleJump()
    end
    imgui.SameLine()
    if imgui.Checkbox(u8"\xca\xed\xee\xef\xea\xe0 \xed\xe0 \xfd\xea\xf0\xe0\xed\xe5", imgui.new.bool(not fabHidden)) then
        fabHidden = not fabHidden
        saveCfg()
    end
    imgui.SameLine()
    imgui.Checkbox(u8"ESP \xf0\xf3\xe4\xe0", oreEsp)

    imgui.Dummy(imgui.ImVec2(0, 10))
    do
        local sp = imgui.GetCursorScreenPos()
        local cw = imgui.GetContentRegionAvail().x
        imgui.GetWindowDrawList():AddLine(imgui.ImVec2(sp.x, sp.y), imgui.ImVec2(sp.x+cw, sp.y), 0x22FFFFFF, 1)
        imgui.Dummy(imgui.ImVec2(0, 10))
    end

    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xd6\xe5\xeb\xfc (\xf1\xf2\xee\xef \xef\xee \xe4\xee\xf1\xf2\xe8\xe6\xe5\xed\xe8\xe8)")
    imgui.Dummy(imgui.ImVec2(0, 4))
    if imgui.Checkbox(u8"\xc2\xfb\xea\xeb##g", imgui.new.bool(goalMode == 0)) then
        goalMode = 0; goalReached = false; saveCfg()
    end
    imgui.SameLine()
    if imgui.Checkbox(u8"\xd0\xf3\xe4\xe0##g", imgui.new.bool(goalMode == 1)) then
        goalMode = 1; goalReached = false; saveCfg()
    end
    imgui.SameLine()
    if imgui.Checkbox(u8"\xc4\xe5\xed\xfc\xe3\xe8##g", imgui.new.bool(goalMode == 2)) then
        goalMode = 2; goalReached = false; saveCfg()
    end
    imgui.SameLine()
    if imgui.Checkbox(u8"\xc2\xf0\xe5\xec\xff##g", imgui.new.bool(goalMode == 3)) then
        goalMode = 3; goalReached = false; saveCfg()
    end
    if goalMode == 1 then
        local ga = imgui.new.int(goalOreAmount)
        imgui.SetNextItemWidth(-1)
        if imgui.InputInt('##goalore', ga, 100) then
            if ga[0] < 1 then ga[0] = 1 end
            goalOreAmount = ga[0]; goalReached = false; saveCfg()
        end
    elseif goalMode == 2 then
        local gm = imgui.new.int(goalMoney)
        imgui.SetNextItemWidth(-1)
        if imgui.InputInt('##goalmoney', gm, 10000) then
            if gm[0] < 1 then gm[0] = 1 end
            goalMoney = gm[0]; goalReached = false; saveCfg()
        end
    elseif goalMode == 3 then
        imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xcc\xe8\xed\xf3\xf2\xfb:")
        local gt = imgui.new.int(goalMinutes)
        imgui.SetNextItemWidth(-1)
        if imgui.InputInt('##goaltime', gt, 5) then
            if gt[0] < 1 then gt[0] = 1 end
            goalMinutes = gt[0]; goalReached = false; saveCfg()
        end
    end
    if goalMode > 0 then
        if imgui.Checkbox(u8"\xc2\xfb\xe9\xf2\xe8 \xe8\xe7 \xe8\xe3\xf0\xfb \xef\xee \xf6\xe5\xeb\xe8", imgui.new.bool(goalQuit)) then
            goalQuit = not goalQuit; saveCfg()
        end
    end

    imgui.Dummy(imgui.ImVec2(0, 10))
    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1),
        u8"\xd2\xee\xf7\xea\xe0: " .. tostring(currentRoutePoint) .. u8" / " .. tostring(#recordedRoute))
    imgui.Dummy(imgui.ImVec2(0, 4))
    if imgui.Button(u8"\xd1\xe1\xf0\xee\xf1\xe8\xf2\xfc \xec\xe0\xf0\xf8\xf0\xf3\xf2", imgui.ImVec2(-1, 44)) then
        currentRoutePoint = 1
        sampAddChatMessage('[ST Mine]: {ffffff}\xcc\xe0\xf0\xf8\xf0\xf3\xf2 \xf1\xe1\xf0\xee\xf8\xe5\xed!', -1)
    end

    imgui.EndGroup()
    imgui.EndChild()

    imgui.SameLine(0, 18)

    imgui.BeginChild("##mtab_right", imgui.ImVec2(_minerW, 0), false)
    do
        local rdl = imgui.GetWindowDrawList()
        local u32 = imgui.ColorConvertFloat4ToU32
        local c0  = imgui.GetCursorPos()
        local o   = imgui.GetCursorScreenPos()
        local cw  = imgui.GetContentRegionAvail().x
        local ch  = imgui.GetContentRegionAvail().y

        if S.miner == nil and doesFileExist(S.minerPath) then
            local ok, tex = pcall(imgui.CreateTextureFromFile, S.minerPath)
            S.miner = ok and tex or false
        end

        local u0v, v0v, u1v, v1v = 0.0518, 0.0244, 0.9766, 0.999
        local fw = cw
        local fh = math.floor(fw * (v1v - v0v) / (u1v - u0v))
        if fh > ch then fh = ch; fw = math.floor(fh * (u1v - u0v) / (v1v - v0v)) end
        local fx = o.x + math.floor((cw - fw) / 2)
        local fy = o.y

        rdl:AddRectFilled(imgui.ImVec2(fx, fy), imgui.ImVec2(fx+fw, fy+fh), u32(imgui.ImVec4(0.105,0.094,0.078,1)))
        rdl:AddRect(imgui.ImVec2(fx, fy), imgui.ImVec2(fx+fw, fy+fh), u32(imgui.ImVec4(0.34,0.27,0.16,0.90)), 0, 0, 1.5)

        if S.miner then
            imgui.SetCursorPos(imgui.ImVec2(c0.x + (fx - o.x), c0.y + (fy - o.y)))
            imgui.Image(S.miner, imgui.ImVec2(fw, fh), imgui.ImVec2(u0v, v0v), imgui.ImVec2(u1v, v1v),
                imgui.ImVec4(1, 1, 1, 1))
        else
            if mainFont then imgui.PushFont(mainFont) end
            local ld  = u8'\xc7\xe0\xe3\xf0\xf3\xe7\xea\xe0...'
            local lds = imgui.CalcTextSize(ld)
            rdl:AddText(imgui.ImVec2(fx + (fw-lds.x)/2, fy + fh/2 - 8),
                u32(imgui.ImVec4(0.60,0.55,0.46,1)), ld)
            if mainFont then imgui.PopFont() end
        end

        imgui.SetCursorPos(imgui.ImVec2(c0.x, c0.y + fh + 12))
        if imgui.Checkbox(u8"\xc0\xe2\xf2\xee-\xec\xe0\xf1\xea\xe0", imgui.new.bool(autoMask)) then
            autoMask = not autoMask
            saveCfg()
            if autoMask then maskNextTime = 0 end
        end
    end
    imgui.EndChild()
    imgui.PopStyleVar()
end

local function renderAboutTab()
    imgui.SetCursorPos(imgui.ImVec2(20, 10))
    imgui.BeginGroup()

    renderSectionHeader(u8"\xce\xe1 \xe0\xe2\xf2\xee\xf0\xe5")

    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xc0\xe2\xf2\xee\xf0 \xf1\xea\xf0\xe8\xef\xf2\xe0")
    imgui.Dummy(imgui.ImVec2(0, 2))
    imgui.PushFont(headerFont)
    imgui.TextColored(imgui.ImVec4(1.00, 0.72, 0.22, 1.00), u8"Victor Strand")
    imgui.PopFont()

    imgui.Dummy(imgui.ImVec2(0, 12))
    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xca\xe0\xed\xe0\xeb\xfb Telegram")
    imgui.Dummy(imgui.ImVec2(0, 4))
    if imgui.Button(u8"\xca\xe0\xed\xe0\xeb: @strand_scripts", imgui.ImVec2(-1, 42)) then
        openLink('https://t.me/strand_scripts')
    end
    imgui.Dummy(imgui.ImVec2(0, 6))
    if imgui.Button(u8"\xc0\xe2\xf2\xee\xf0: @victor_st0", imgui.ImVec2(-1, 42)) then
        openLink('https://t.me/victor_st0')
    end

    imgui.EndGroup()
end

local function renderFoodTab()
    imgui.SetCursorPos(imgui.ImVec2(20, 10))
    imgui.BeginGroup()

    renderSectionHeader(u8"\xc0\xe2\xf2\xee-\xe5\xe4\xe0")

    local satTxt = autoEatSatiety >= 0 and (tostring(math.floor(autoEatSatiety)) .. '%') or '?'
    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xd1\xfb\xf2\xee\xf1\xf2\xfc: " .. satTxt)
    imgui.Dummy(imgui.ImVec2(0, 4))

    if imgui.Checkbox(u8"\xc0\xe2\xf2\xee-\xe5\xe4\xe0 \xe2\xea\xeb\xfe\xf7\xe5\xed\xe0", imgui.new.bool(autoEat)) then
        autoEat = not autoEat
        saveCfg()
        if autoEat then
            lua_thread.create(function()
                autoEatWaitSat = true
                sampSendChat('/satiety')
                local t = 0
                while autoEatWaitSat and t < 60 do wait(100); t = t + 1 end
                autoEatWaitSat = false
            end)
        end
    end

    if imgui.Checkbox(u8"\xc7\xe2\xf3\xea \xe5\xe4\xfb", imgui.new.bool(soundEatEnabled)) then
        soundEatEnabled = not soundEatEnabled
        saveCfg()
    end

    imgui.Dummy(imgui.ImVec2(0, 8))
    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xd0\xe5\xe6\xe8\xec")
    if imgui.Checkbox(u8"\xcb\xe0\xf0\xb8\xea (< 50%)", imgui.new.bool(autoEatMode == 0)) then
        autoEatMode = 0; saveCfg()
    end
    imgui.SameLine()
    if imgui.Checkbox(u8"\xcf\xf0\xee\xe4\xf3\xea\xf2\xfb (/eat)", imgui.new.bool(autoEatMode == 1)) then
        autoEatMode = 1; saveCfg()
    end

    if autoEatMode == 1 then
        imgui.Dummy(imgui.ImVec2(0, 8))
        imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xcc\xe8\xed. \xf1\xfb\xf2\xee\xf1\xf2\xfc")
        local minSat = imgui.new.int(autoEatMinSatiety)
        imgui.SetNextItemWidth(-1)
        if imgui.SliderInt('##minsat', minSat, 20, 100) then
            autoEatMinSatiety = minSat[0]; saveCfg()
        end
        imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xc2\xfb\xe1\xee\xf0 \xe5\xe4\xfb")
        if imgui.Checkbox(u8"\xd7\xe8\xef\xf1\xfb", imgui.new.bool(autoEatFood == 0)) then
            autoEatFood = 0; saveCfg()
        end
        imgui.SameLine()
        if imgui.Checkbox(u8"\xd0\xfb\xe1\xe0", imgui.new.bool(autoEatFood == 1)) then
            autoEatFood = 1; saveCfg()
        end
        imgui.SameLine()
        if imgui.Checkbox(u8"\xce\xeb\xe5\xed\xe8\xed\xe0", imgui.new.bool(autoEatFood == 2)) then
            autoEatFood = 2; saveCfg()
        end
    end

    imgui.Dummy(imgui.ImVec2(0, 8))
    if imgui.Button(u8"\xc8\xe4\xf2\xe8 \xea \xeb\xe0\xf0\xfc\xea\xf3 \xf1\xe5\xe9\xf7\xe0\xf1", imgui.ImVec2(-1, 40)) then
        if not larekRunning then goEatAtLarek() end
    end

    imgui.EndGroup()
end

local function renderCollisionTab()
    imgui.SetCursorPos(imgui.ImVec2(20, 5))
    imgui.BeginGroup()

    renderSectionHeader(u8"\xca\xee\xeb\xeb\xe8\xe7\xe8\xff")

    if imgui.Checkbox(u8"\xce\xf2\xea\xeb. \xea\xee\xeb\xeb\xe8\xe7\xe8\xfe \xed\xe0 \xe8\xe3\xf0\xee\xea\xee\xe2", imgui.new.bool(collisionEnabled)) then
        collisionEnabled = not collisionEnabled
        enableCollision()
        if collisionEnabled then
            sampAddChatMessage('[ST Mine]: {ffffff}\xca\xee\xeb\xeb\xe8\xe7\xe8\xff \xe8\xe3\xf0\xee\xea\xee\xe2 \xee\xf2\xea\xeb\xfe\xf7\xe5\xed\xe0', -1)
        else
            sampAddChatMessage('[ST Mine]: {ffffff}\xca\xee\xeb\xeb\xe8\xe7\xe8\xff \xe8\xe3\xf0\xee\xea\xee\xe2 \xe2\xea\xeb\xfe\xf7\xe5\xed\xe0', -1)
        end
    end
    if imgui.Checkbox(u8"\xce\xf2\xea\xeb. \xea\xee\xeb\xeb\xe8\xe7\xe8\xfe \xee\xe1\xfa\xe5\xea\xf2\xee\xe2 SAMP", imgui.new.bool(objCollisionEnabled)) then
        objCollisionEnabled = not objCollisionEnabled
        enableObjectCollision()
        if objCollisionEnabled then
            sampAddChatMessage('[ST Mine]: {ffffff}\xca\xee\xeb\xeb\xe8\xe7\xe8\xff \xee\xe1\xfa\xe5\xea\xf2\xee\xe2 \xee\xf2\xea\xeb\xfe\xf7\xe5\xed\xe0', -1)
        else
            sampAddChatMessage('[ST Mine]: {ffffff}\xca\xee\xeb\xeb\xe8\xe7\xe8\xff \xee\xe1\xfa\xe5\xea\xf2\xee\xe2 \xe2\xea\xeb\xfe\xf7\xe5\xed\xe0', -1)
        end
    end
    local _beskBuf = imgui.new.bool(beskbeg)
    if imgui.Checkbox(u8"\xc1\xe5\xf1\xea\xee\xed\xe5\xf7\xed\xe0\xff \xe2\xfb\xed\xee\xf1\xeb\xe8\xe2\xee\xf1\xf2\xfc", _beskBuf) then
        beskbeg = _beskBuf[0]
        enableBesk()
        if beskbeg then
            sampAddChatMessage('[ST Mine]: {ffffff}\xc1\xe5\xf1\xea \xed\xee\xe3 \xe2\xea\xeb\xfe\xf7\xe5\xed', -1)
        else
            sampAddChatMessage('[ST Mine]: {ffffff}\xc1\xe5\xf1\xea \xed\xee\xe3 \xee\xf2\xea\xeb\xfe\xf7\xe5\xed', -1)
        end
    end
    imgui.Dummy(imgui.ImVec2(0, 10))
    renderSectionHeader(u8"\xc0\xed\xf2\xe8-\xe0\xe4\xec\xe8\xed")
    if imgui.Checkbox(u8"\xc0\xe2\xf2\xee\xee\xf2\xe2\xe5\xf2 \xe0\xe4\xec\xe8\xed\xf3", imgui.new.bool(aaState)) then
        aaState = not aaState
        if aaState then antiAdminEnableTime = os.clock(); aaAngry = 0 end
        saveCfg()
    end
    if imgui.Checkbox(u8"\xd1\xf2\xee\xef \xef\xf0\xe8 \xe4\xe8\xe0\xeb\xee\xe3\xe5", imgui.new.bool(stopOnDialog)) then
        stopOnDialog = not stopOnDialog
        if stopOnDialog then antiAdminEnableTime = os.clock() end
        saveCfg()
    end
    imgui.SameLine()
    if imgui.Checkbox(u8"\xd1\xf2\xee\xef \xef\xf0\xe8 \xd2\xcf", imgui.new.bool(stopOnTp)) then
        stopOnTp = not stopOnTp
        if stopOnTp then antiAdminEnableTime = os.clock() end
        saveCfg()
    end
    if imgui.Checkbox(u8"\xd1\xf2\xee\xef \xef\xf0\xe8 \xab\xc2\xfb \xf2\xf3\xf2?\xbb \xe2 \xf7\xe0\xf2\xe5", imgui.new.bool(stopOnChat)) then
        stopOnChat = not stopOnChat
        if stopOnChat then antiAdminEnableTime = os.clock() end
        saveCfg()
    end
    if imgui.Checkbox(u8"\xc2\xfb\xf5\xee\xe4 \xe8\xe7 \xe8\xe3\xf0\xfb \xef\xf0\xe8 \xf1\xf2\xee\xef\xe5", imgui.new.bool(quitOnStop)) then
        quitOnStop = not quitOnStop
        saveCfg()
    end
    if imgui.Checkbox(u8"\xce\xef\xee\xe2\xe5\xf9\xe5\xed\xe8\xe5 \xe0\xed\xf2\xe8-\xe0\xe4\xec\xe8\xed", imgui.new.bool(soundAAEnabled)) then
        soundAAEnabled = not soundAAEnabled
        saveCfg()
    end

    imgui.Dummy(imgui.ImVec2(0, 10))
    renderSectionHeader(u8"\xc8\xc8 \xee\xf2\xe2\xe5\xf2\xfb \xe0\xe4\xec\xe8\xed\xf3 (Groq)")

    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"API \xea\xeb\xfe\xf7 Groq (console.groq.com/keys):")
    imgui.PushItemWidth(-1)
    if imgui.InputText('##aikey', ai.keyGroqBuf, 257, imgui.InputTextFlags.Password) then
        ai.keyGroq = bufToStr(ai.keyGroqBuf, 257)
        ai.save()
    end
    imgui.PopItemWidth()
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.28,0.16,0.12,1))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.90,0.34,0.22,0.92))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.70,0.24,0.16,1))
    if imgui.Button(u8"\xd1\xf2\xe5\xf0\xe5\xf2\xfc \xea\xeb\xfe\xf7", imgui.ImVec2(224, 0)) then
        ai.keyGroqBuf[0] = 0
        ai.keyGroq = ''
        ai.save()
    end
    imgui.PopStyleColor(3)

    imgui.Dummy(imgui.ImVec2(0, 6))
    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8"\xcf\xf0\xee\xec\xef\xf2 \xe4\xeb\xff \xee\xf2\xe2\xe5\xf2\xee\xe2 \xe0\xe4\xec\xe8\xed\xf3:")
    imgui.PushItemWidth(-1)
    if imgui.InputTextMultiline('##aisystem', ai.systemBuf, 2049, imgui.ImVec2(-1, 96)) then
        ai.system = bufToStr(ai.systemBuf, 2049):gsub('[\r\n]+', ' ')
        ai.save()
    end
    imgui.PopItemWidth()
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.28,0.16,0.12,1))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.90,0.34,0.22,0.92))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.70,0.24,0.16,1))
    if imgui.Button(u8"\xd1\xf2\xe5\xf0\xe5\xf2\xfc \xef\xf0\xee\xec\xef\xf2", imgui.ImVec2(231, 0)) then
        ai.systemBuf[0] = 0
        ai.system = ''
        ai.save()
    end
    imgui.PopStyleColor(3)

    imgui.EndGroup()
end

local priceStoneInput  = imgui.new.int(PRICE_STONE)
local priceMetalInput  = imgui.new.int(PRICE_METAL)
local priceSilverInput = imgui.new.int(PRICE_SILVER)
local priceBronzeInput = imgui.new.int(PRICE_BRONZE)
local priceGoldInput   = imgui.new.int(PRICE_GOLD)

local function renderStatsTab()
    imgui.SetCursorPos(imgui.ImVec2(20, 10))
    imgui.BeginGroup()

    renderSectionHeader(u8"\xd1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xe0 \xe4\xee\xe1\xfb\xf7\xe8")

    if imgui.Button(u8"\xcf\xee\xe4\xf0\xee\xe1\xed\xe0\xff \xf1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xe0", imgui.ImVec2(-1, 44)) then
        WinStats[0] = not WinStats[0]
    end

    imgui.Dummy(imgui.ImVec2(0, 6))

    local function miniStat(label, count, color, pricePtr, priceKey)
        local cp = imgui.GetCursorScreenPos()
        local dl = imgui.GetWindowDrawList()
        local cw = imgui.GetContentRegionAvail().x
        local rh = 21 * _MDS
        dl:AddRectFilled(imgui.ImVec2(cp.x, cp.y), imgui.ImVec2(cp.x+cw, cp.y+rh-2*_MDS), 0x18FFFFFF, 4*_MDS)
        dl:AddRectFilled(imgui.ImVec2(cp.x, cp.y+4*_MDS), imgui.ImVec2(cp.x+3*_MDS, cp.y+rh-6*_MDS), color, 2*_MDS)
        imgui.SetCursorPosX(imgui.GetCursorPosX() + 10*_MDS)
        imgui.SetCursorPosY(imgui.GetCursorPosY() + (rh-imgui.GetTextLineHeight())/2 - 1)
        imgui.TextColored(imgui.ImVec4(0.80,0.80,0.80,1), label)
        local cntStr = tostring(count)
        local cntSz  = imgui.CalcTextSize(cntStr)
        local earnStr = formatMoney(count * pricePtr[0])
        local earnSz = imgui.CalcTextSize(earnStr)
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x + cw/2 - cntSz.x/2, cp.y+(rh-imgui.GetTextLineHeight())/2-1))
        local cc = count > 0 and imgui.ImVec4(0.90,0.93,0.90,1) or imgui.ImVec4(0.40,0.40,0.40,1)
        imgui.TextColored(cc, cntStr)
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x + cw - earnSz.x - 4*_MDS, cp.y+(rh-imgui.GetTextLineHeight())/2-1))
        local ec = count > 0 and imgui.ImVec4(0.45,0.85,0.40,1) or imgui.ImVec4(0.35,0.35,0.35,1)
        imgui.TextColored(ec, earnStr)
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x, cp.y + rh))
        imgui.SetCursorPosX(imgui.GetCursorPosX() + 10*_MDS)
        imgui.SetNextItemWidth(cw - 10*_MDS)
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.10,0.10,0.10,0.70))
        if imgui.InputInt('##pi_'..priceKey, pricePtr, 0) then
            if pricePtr[0] < 1 then pricePtr[0] = 1 end
            PRICE_STONE  = priceStoneInput[0]
            PRICE_METAL  = priceMetalInput[0]
            PRICE_SILVER = priceSilverInput[0]
            PRICE_BRONZE = priceBronzeInput[0]
            PRICE_GOLD   = priceGoldInput[0]
            mainIni.prices = mainIni.prices or {}
            mainIni.prices.stone  = tostring(PRICE_STONE)
            mainIni.prices.metal  = tostring(PRICE_METAL)
            mainIni.prices.silver = tostring(PRICE_SILVER)
            mainIni.prices.bronze = tostring(PRICE_BRONZE)
            mainIni.prices.gold   = tostring(PRICE_GOLD)
            inicfg.save(mainIni, 'mbot.ini')
        end
        imgui.PopStyleColor(1)
    end

    miniStat(u8('\xca\xe0\xec\xe5\xed\xfc'),  totalStone,  imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.75,0.75,0.75,1)), priceStoneInput,  'stone')
    miniStat(u8('\xcc\xe5\xf2\xe0\xeb\xeb'),  totalMetal,  imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.60,0.60,0.65,1)), priceMetalInput,  'metal')
    miniStat(u8('\xd1\xe5\xf0\xe5\xe1\xf0\xee'), totalSilver, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.55,0.75,0.95,1)), priceSilverInput, 'silver')
    miniStat(u8('\xc1\xf0\xee\xed\xe7\xe0'),  totalBronze, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.80,0.50,0.25,1)), priceBronzeInput, 'bronze')
    miniStat(u8('\xc7\xee\xeb\xee\xf2\xee'),  totalGold,   imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.95,0.80,0.15,1)), priceGoldInput,   'gold')

    imgui.Spacing()
    local dl2 = imgui.GetWindowDrawList()
    local sp2 = imgui.GetCursorScreenPos()
    local cw2 = imgui.GetContentRegionAvail().x
    dl2:AddLine(imgui.ImVec2(sp2.x, sp2.y), imgui.ImVec2(sp2.x+cw2, sp2.y), 0x33FFFFFF, 1)
    imgui.Dummy(imgui.ImVec2(0, 4*_MDS))

    local totalMined  = totalStone + totalMetal + totalSilver + totalBronze + totalGold
    local totalEarned = getTotalEarned()
    imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), u8('\xc2\xf1\xe5\xe3\xee: ') .. tostring(totalMined)
        .. u8('  \xc7\xe0\xf0\xe0\xe1\xee\xf2\xe0\xed\xee: ') .. formatMoney(totalEarned))

    imgui.EndGroup()
end

local selectedTab = 1

imgui.OnFrame(function() return WinState[0] and licenseOK end, function(player)
        local ImVec2 = imgui.ImVec2
        local ImVec4 = imgui.ImVec4
        local u32    = imgui.ColorConvertFloat4ToU32
        local screenW, screenH = getScreenResolution()
        local W, H = 1120, 720
        imgui.SetNextWindowPos(ImVec2(screenW / 2, screenH / 2), imgui.Cond.FirstUseEver, ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(ImVec2(W, H), imgui.Cond.Always)

        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, ImVec2(0, 0))
        local _mflags = imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollbar
        if S.menuLocked then _mflags = _mflags + imgui.WindowFlags.NoMove end
        imgui.Begin("##main", WinState, _mflags)
        imgui.PopStyleVar()

        local wp = imgui.GetWindowPos()
        local ws = imgui.GetWindowSize()
        local dl = imgui.GetWindowDrawList()
        local mx = imgui.GetIO().MousePos.x
        local my = imgui.GetIO().MousePos.y

        local AMBER  = ImVec4(1.00, 0.72, 0.22, 1.00)
        local AMBERD = ImVec4(0.85, 0.55, 0.20, 1.00)
        local COPPER = ImVec4(0.72, 0.42, 0.20, 1.00)
        local EMBER  = ImVec4(0.90, 0.34, 0.22, 1.00)
        local ORE    = ImVec4(0.46, 0.82, 0.42, 1.00)
        local TEXT   = ImVec4(0.91, 0.88, 0.80, 1.00)
        local DIM    = ImVec4(0.58, 0.54, 0.46, 1.00)
        local STONE  = ImVec4(0.150, 0.135, 0.110, 1.00)
        local STONE2 = ImVec4(0.120, 0.108, 0.088, 1.00)
        local PANEL  = ImVec4(0.135, 0.122, 0.100, 1.00)
        local BORDER = ImVec4(0.34, 0.27, 0.16, 0.85)
        local headerH, tabsH = 78, 54

        dl:AddRectFilled(ImVec2(wp.x, wp.y), ImVec2(wp.x + ws.x, wp.y + headerH), u32(STONE))
        dl:AddRectFilled(ImVec2(wp.x, wp.y + headerH), ImVec2(wp.x + ws.x, wp.y + headerH + tabsH), u32(STONE2))
        local cardX0   = 14
        local contentW = ws.x - cardX0 * 2
        local cardTop  = headerH + tabsH + 14
        local cardBot  = ws.y - 14
        dl:AddRectFilled(ImVec2(wp.x + cardX0, wp.y + cardTop),
            ImVec2(wp.x + cardX0 + contentW, wp.y + cardBot), u32(PANEL))
        dl:AddRectFilled(ImVec2(wp.x + cardX0, wp.y + cardTop),
            ImVec2(wp.x + cardX0 + contentW, wp.y + cardTop + 2), u32(AMBERD))
        dl:AddRect(ImVec2(wp.x + cardX0, wp.y + cardTop),
            ImVec2(wp.x + cardX0 + contentW, wp.y + cardBot), u32(BORDER), 0, 0, 1)
        dl:AddRectFilled(ImVec2(wp.x, wp.y + headerH - 3), ImVec2(wp.x + ws.x, wp.y + headerH), u32(AMBER))
        dl:AddLine(ImVec2(wp.x, wp.y + headerH + tabsH), ImVec2(wp.x + ws.x, wp.y + headerH + tabsH),
            u32(BORDER), 1)
        dl:AddRect(ImVec2(wp.x, wp.y), ImVec2(wp.x + ws.x, wp.y + ws.y), u32(AMBERD), 0, 0, 2)
        dl:AddRect(ImVec2(wp.x + 3, wp.y + 3), ImVec2(wp.x + ws.x - 3, wp.y + ws.y - 3), u32(BORDER), 0, 0, 1)
        for _, rv in ipairs({{10,10},{ws.x-16,10},{10,ws.y-16},{ws.x-16,ws.y-16}}) do
            dl:AddRectFilled(ImVec2(wp.x+rv[1], wp.y+rv[2]), ImVec2(wp.x+rv[1]+6, wp.y+rv[2]+6), u32(COPPER))
        end

        local lsz = 42
        local lx, ly = wp.x + 24, wp.y + (headerH - lsz) / 2
        local facet = u32(ImVec4(0.45, 0.28, 0.10, 1))
        dl:AddRectFilled(ImVec2(lx, ly), ImVec2(lx + lsz, ly + lsz), u32(AMBER))
        dl:AddRectFilled(ImVec2(lx, ly), ImVec2(lx + lsz, ly + lsz * 0.42), u32(ImVec4(1.0, 0.82, 0.40, 1.0)))
        dl:AddRect(ImVec2(lx, ly), ImVec2(lx + lsz, ly + lsz), facet, 0, 0, 1.5)
        if _faOK then
            imgui.PushFont(iconFontBig)
            local hg = imgui.CalcTextSize(IC.helmet)
            dl:AddText(ImVec2(lx + (lsz-hg.x)/2, ly + (lsz-hg.y)/2), u32(ImVec4(0.20,0.13,0.05,1)), IC.helmet)
            imgui.PopFont()
        end

        local subTxt = u8'v' .. SCRIPT_VERSION .. u8'  \xb7  \xf8\xe0\xf5\xf2\xb8\xf0-\xe1\xee\xf2'
        local th1, th2 = 18, 14
        if titleFont then imgui.PushFont(titleFont); th1 = imgui.CalcTextSize("ST MINE").y; imgui.PopFont() end
        if mainFont  then imgui.PushFont(mainFont);  th2 = imgui.CalcTextSize(subTxt).y;   imgui.PopFont() end
        local blockTop = wp.y + (headerH - (th1 + 5 + th2)) / 2
        local txX = lx + lsz + 16
        if titleFont then imgui.PushFont(titleFont) end
        dl:AddText(ImVec2(txX, blockTop), u32(TEXT), "ST MINE")
        if titleFont then imgui.PopFont() end
        if mainFont then imgui.PushFont(mainFont) end
        dl:AddText(ImVec2(txX, blockTop + th1 + 5), u32(DIM), subTxt)
        if mainFont then imgui.PopFont() end

        local cbSz = 42
        local cbX  = wp.x + ws.x - cbSz - 16
        local cbY  = wp.y + (headerH - cbSz) / 2

        local lkSz = cbSz
        local lkX  = cbX - lkSz - 8
        local lkY  = cbY
        local locked = S.menuLocked and true or false
        local lkHov = mx >= lkX and mx <= lkX + lkSz and my >= lkY and my <= lkY + lkSz
        dl:AddRectFilled(ImVec2(lkX, lkY), ImVec2(lkX + lkSz, lkY + lkSz),
            u32(locked and ImVec4(0.85,0.55,0.18,1) or (lkHov and ImVec4(0.40,0.34,0.22,1) or ImVec4(0.20,0.17,0.13,1))))
        dl:AddRect(ImVec2(lkX, lkY), ImVec2(lkX + lkSz, lkY + lkSz),
            u32((locked or lkHov) and AMBER or BORDER), 0, 0, 1.5)
        local lkc = locked and u32(ImVec4(0.12,0.09,0.05,1)) or u32(ImVec4(0.80,0.74,0.62,1))
        if _faOK then
            imgui.PushFont(iconFontBig)
            local g  = locked and IC.lock or IC.lockopen
            local gs = imgui.CalcTextSize(g)
            dl:AddText(ImVec2(lkX + (lkSz-gs.x)/2, lkY + (lkSz-gs.y)/2), lkc, g)
            imgui.PopFont()
        else
            local cx0, cy0 = lkX + lkSz/2, lkY + lkSz/2
            dl:AddRectFilled(ImVec2(cx0-8, cy0-1), ImVec2(cx0+8, cy0+10), lkc, 2)
            dl:AddRect(ImVec2(cx0-5, cy0-9), ImVec2(cx0+5, cy0-1), lkc, 0, 0, 2)
        end
        if lkHov and imgui.GetIO().MouseClicked[0] then S.menuLocked = not locked end

        if headerFont then imgui.PushFont(headerFont) end
        local _an  = u8"Victor Strand"
        local _ans = imgui.CalcTextSize(_an)
        dl:AddText(ImVec2(lkX - 14 - _ans.x, wp.y + (headerH - _ans.y) / 2), u32(AMBER), _an)
        if headerFont then imgui.PopFont() end

        local cbHov = mx >= cbX and mx <= cbX + cbSz and my >= cbY and my <= cbY + cbSz
        dl:AddRectFilled(ImVec2(cbX, cbY), ImVec2(cbX + cbSz, cbY + cbSz),
            u32(cbHov and EMBER or ImVec4(0.20, 0.17, 0.13, 1.0)))
        dl:AddRect(ImVec2(cbX, cbY), ImVec2(cbX + cbSz, cbY + cbSz), u32(cbHov and EMBER or BORDER), 0, 0, 1.5)
        local xc = cbHov and u32(ImVec4(1, 1, 1, 1)) or u32(ImVec4(0.80,0.74,0.62,1))
        if _faOK then
            imgui.PushFont(iconFontBig)
            local xs = imgui.CalcTextSize(IC.xmark)
            dl:AddText(ImVec2(cbX + (cbSz-xs.x)/2, cbY + (cbSz-xs.y)/2), xc, IC.xmark)
            imgui.PopFont()
        else
            dl:AddLine(ImVec2(cbX + 14, cbY + 14), ImVec2(cbX + cbSz - 14, cbY + cbSz - 14), xc, 2.5)
            dl:AddLine(ImVec2(cbX + cbSz - 14, cbY + 14), ImVec2(cbX + 14, cbY + cbSz - 14), xc, 2.5)
        end
        if cbHov and imgui.GetIO().MouseClicked[0] then WinState[0] = false end

        local tabs = {
            {id = 1, label = u8"\xc3\xcb\xc0\xc2\xcd\xc0\xdf",       icon = IC.house},
            {id = 2, label = u8"\xc7\xc0\xd9\xc8\xd2\xc0",          icon = IC.shield},
            {id = 3, label = u8"\xc0\xc2\xd2\xce-\xc5\xc4\xc0",     icon = IC.food},
            {id = 4, label = u8"\xd1\xd2\xc0\xd2\xc8\xd1\xd2\xc8\xca\xc0", icon = IC.chart},
            {id = 5, label = u8"\xce\xc1 \xc0\xc2\xd2\xce\xd0\xc5",  icon = IC.info}
        }
        local nTabs = #tabs
        local tabW  = ws.x / nTabs
        local lblFont = headerFont or mainFont
        for i, tab in ipairs(tabs) do
            local isActive = (selectedTab == tab.id)
            local tx0 = wp.x + (i-1) * tabW
            local ty0 = wp.y + headerH
            imgui.SetCursorPos(ImVec2((i-1) * tabW, headerH))
            local clicked = imgui.InvisibleButton("##tab" .. tab.id, ImVec2(tabW, tabsH))
            local hovered = imgui.IsItemHovered()
            if clicked then selectedTab = tab.id end

            if isActive then
                dl:AddRectFilled(ImVec2(tx0, ty0), ImVec2(tx0 + tabW, ty0 + tabsH), u32(PANEL))
                dl:AddRectFilled(ImVec2(tx0, ty0), ImVec2(tx0 + tabW, ty0 + 3), u32(AMBER))
            elseif hovered then
                dl:AddRectFilled(ImVec2(tx0, ty0), ImVec2(tx0 + tabW, ty0 + tabsH), u32(ImVec4(0.20,0.175,0.135,1)))
            end
            if i > 1 then
                dl:AddLine(ImVec2(tx0, ty0 + 12), ImVec2(tx0, ty0 + tabsH - 12), u32(BORDER), 1)
            end
            local colU = u32(isActive and AMBER or (hovered and TEXT or DIM))
            local midY = ty0 + tabsH / 2

            local iw, ih = 0, 0
            if _faOK and iconFontBig then
                imgui.PushFont(iconFontBig)
                local s = imgui.CalcTextSize(tab.icon)
                iw, ih = s.x, s.y
                imgui.PopFont()
            end
            imgui.PushFont(lblFont)
            local ls = imgui.CalcTextSize(tab.label)
            imgui.PopFont()
            local gapI  = (iw > 0) and 10 or 0
            local startX = tx0 + (tabW - (iw + gapI + ls.x)) / 2
            if iw > 0 then
                imgui.PushFont(iconFontBig)
                dl:AddText(ImVec2(startX, midY - ih / 2), colU, tab.icon)
                imgui.PopFont()
            end
            imgui.PushFont(lblFont)
            dl:AddText(ImVec2(startX + iw + gapI, midY - ls.y / 2), colU, tab.label)
            imgui.PopFont()
        end

        imgui.SetCursorPos(ImVec2(cardX0, cardTop + 6))
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, ImVec2(26, 16))
        imgui.BeginChild("##content", ImVec2(contentW, cardBot - cardTop - 12), false)
        imgui.PushFont(mainFont)

        if selectedTab == 1 then
            renderMainTab()
        elseif selectedTab == 2 then
            renderCollisionTab()
        elseif selectedTab == 3 then
            renderFoodTab()
        elseif selectedTab == 4 then
            renderStatsTab()
        elseif selectedTab == 5 then
            renderAboutTab()
        end

        imgui.PopFont()
        imgui.EndChild()
        imgui.PopStyleVar()
        imgui.End()

    end)

imgui.OnFrame(function() return WinStats[0] end, function(self)
    self.HideCursor = false
    local sw, sh = getScreenResolution()
    local winW, winH = 248 * _MDS, 312 * _MDS
    imgui.SetNextWindowPos(imgui.ImVec2(sw/2, sh/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.Always)

    imgui.PushStyleColor(imgui.Col.WindowBg,      imgui.ImVec4(0.105, 0.095, 0.080, 0.99))
    imgui.PushStyleColor(imgui.Col.Border,        imgui.ImVec4(0.34, 0.27, 0.16, 1.00))
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.205, 0.180, 0.140, 1.00))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.95, 0.62, 0.20, 0.92))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.80, 0.50, 0.16, 1.00))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding,  0)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(14*_MDS, 12*_MDS))

    imgui.Begin('##mbot_stats', WinStats, bit.bor(
        imgui.WindowFlags.NoTitleBar,
        imgui.WindowFlags.NoResize,
        imgui.WindowFlags.NoScrollbar
    ))

    local DL  = imgui.GetWindowDrawList()
    local wp  = imgui.GetWindowPos()
    local wps = imgui.GetWindowSize()
    local pad = 11 * _MDS

    DL:AddRectFilled(imgui.ImVec2(wp.x, wp.y), imgui.ImVec2(wp.x+wps.x, wp.y+3*_MDS),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00,0.72,0.22,1.00)))
    DL:AddRect(imgui.ImVec2(wp.x, wp.y), imgui.ImVec2(wp.x+wps.x, wp.y+wps.y),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.85,0.55,0.20,1.00)), 0, 0, 1.5)

    imgui.PushFont(titleFont)
    local titleTxt = u8('\xd1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xe0')
    if _faOK then imgui.PushFont(iconFont) end
    local icW = _faOK and (imgui.CalcTextSize(IC.chart).x + 6) or 0
    if _faOK then imgui.PopFont() end
    local tsz = imgui.CalcTextSize(titleTxt)
    imgui.SetCursorPosX((wps.x - tsz.x - icW) / 2)
    if _faOK then
        imgui.PushFont(iconFont)
        imgui.TextColored(imgui.ImVec4(1.00,0.72,0.22,1.00), IC.chart)
        imgui.PopFont()
        imgui.SameLine(0, 6)
    end
    imgui.TextColored(imgui.ImVec4(1.00, 0.72, 0.22, 1.00), titleTxt)
    imgui.PopFont()

    local _u32 = imgui.ColorConvertFloat4ToU32
    local _ember  = _u32(imgui.ImVec4(0.90, 0.34, 0.22, 1.0))
    local _border = _u32(imgui.ImVec4(0.34, 0.27, 0.16, 1.0))
    local _btnSz = 22 * _MDS
    local _btnX  = wp.x + wps.x - _btnSz - pad
    local _btnY  = wp.y + 10 * _MDS
    local _hov   = imgui.IsMouseHoveringRect(imgui.ImVec2(_btnX,_btnY), imgui.ImVec2(_btnX+_btnSz,_btnY+_btnSz))
    DL:AddRectFilled(imgui.ImVec2(_btnX,_btnY), imgui.ImVec2(_btnX+_btnSz,_btnY+_btnSz),
        _hov and _ember or _u32(imgui.ImVec4(0.20, 0.17, 0.13, 1.0)))
    DL:AddRect(imgui.ImVec2(_btnX,_btnY), imgui.ImVec2(_btnX+_btnSz,_btnY+_btnSz),
        _hov and _ember or _border, 0, 0, 1.5)
    local _col = _hov and _u32(imgui.ImVec4(1,1,1,1)) or _u32(imgui.ImVec4(0.80,0.74,0.62,1))
    if _faOK and iconFontBig then
        imgui.PushFont(iconFontBig)
        local xs = imgui.CalcTextSize(IC.xmark)
        DL:AddText(imgui.ImVec2(_btnX+(_btnSz-xs.x)/2, _btnY+(_btnSz-xs.y)/2), _col, IC.xmark)
        imgui.PopFont()
    else
        DL:AddLine(imgui.ImVec2(_btnX+6*_MDS,_btnY+6*_MDS), imgui.ImVec2(_btnX+_btnSz-6*_MDS,_btnY+_btnSz-6*_MDS), _col, 2.5)
        DL:AddLine(imgui.ImVec2(_btnX+_btnSz-6*_MDS,_btnY+6*_MDS), imgui.ImVec2(_btnX+6*_MDS,_btnY+_btnSz-6*_MDS), _col, 2.5)
    end
    if _hov and imgui.GetIO().MouseClicked[0] then WinStats[0] = false end

    imgui.Spacing()

    local ores = {
        { name = u8('\xca\xe0\xec\xe5\xed\xfc'),  count = totalStone,  price = PRICE_STONE,  col = imgui.ImVec4(0.75,0.75,0.75,1) },
        { name = u8('\xcc\xe5\xf2\xe0\xeb\xeb'),  count = totalMetal,  price = PRICE_METAL,  col = imgui.ImVec4(0.60,0.60,0.65,1) },
        { name = u8('\xd1\xe5\xf0\xe5\xe1\xf0\xee'), count = totalSilver, price = PRICE_SILVER, col = imgui.ImVec4(0.55,0.75,0.95,1) },
        { name = u8('\xc1\xf0\xee\xed\xe7\xe0'),  count = totalBronze, price = PRICE_BRONZE,  col = imgui.ImVec4(0.80,0.50,0.25,1) },
        { name = u8('\xc7\xee\xeb\xee\xf2\xee'),  count = totalGold,   price = PRICE_GOLD,    col = imgui.ImVec4(0.95,0.80,0.15,1) },
    }

    local rowH = 26 * _MDS
    local cw   = imgui.GetContentRegionAvail()
    for _, ore in ipairs(ores) do
        local earned = ore.count * ore.price
        local cp = imgui.GetCursorScreenPos()

        DL:AddRectFilled(
            imgui.ImVec2(cp.x, cp.y),
            imgui.ImVec2(cp.x + cw.x, cp.y + rowH - 2*_MDS),
            0x18FFFFFF, 4*_MDS)

        DL:AddRectFilled(
            imgui.ImVec2(cp.x, cp.y + 4*_MDS),
            imgui.ImVec2(cp.x + 3*_MDS, cp.y + rowH - 6*_MDS),
            imgui.ColorConvertFloat4ToU32(ore.col), 2*_MDS)

        imgui.SetCursorPosX(imgui.GetCursorPosX() + 10*_MDS)
        imgui.SetCursorPosY(imgui.GetCursorPosY() + (rowH - imgui.GetTextLineHeight()) / 2 - 1)

        imgui.TextColored(ore.col, ore.name)

        local cntTxt = tostring(ore.count)
        local cntSz  = imgui.CalcTextSize(cntTxt)
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x + cw.x/2 - cntSz.x/2, cp.y + (rowH-imgui.GetTextLineHeight())/2 - 1))
        local cntCol = ore.count > 0 and imgui.ImVec4(0.90,0.93,0.90,1) or imgui.ImVec4(0.40,0.40,0.40,1)
        imgui.TextColored(cntCol, cntTxt)

        local earnTxt = formatMoney(earned)
        local earnSz  = imgui.CalcTextSize(earnTxt)
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x + cw.x - earnSz.x - 4*_MDS, cp.y + (rowH-imgui.GetTextLineHeight())/2 - 1))
        local earnCol = earned > 0 and imgui.ImVec4(0.45,0.85,0.40,1) or imgui.ImVec4(0.35,0.35,0.35,1)
        imgui.TextColored(earnCol, earnTxt)

        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x, cp.y + rowH))
    end

    imgui.Spacing()

    local sp = imgui.GetCursorScreenPos()
    DL:AddLine(imgui.ImVec2(sp.x, sp.y), imgui.ImVec2(sp.x + cw.x, sp.y), 0x33FFFFFF, 1)
    imgui.Dummy(imgui.ImVec2(0, 4*_MDS))

    local totalMined  = totalStone + totalMetal + totalSilver + totalBronze + totalGold
    local totalEarned = getTotalEarned()

    local function statRow(label, value, valCol)
        local rcp = imgui.GetCursorScreenPos()
        local vsz = imgui.CalcTextSize(value)
        imgui.TextColored(imgui.ImVec4(0.62,0.57,0.48,1), label)
        imgui.SetCursorScreenPos(imgui.ImVec2(rcp.x + cw.x - vsz.x, rcp.y))
        imgui.TextColored(valCol, value)
    end

    statRow(u8('\xc2\xf1\xe5\xe3\xee \xf0\xf3\xe4\xfb:'), tostring(totalMined),
        imgui.ImVec4(0.90,0.90,0.93,1))
    statRow(u8('\xc7\xe0\xf0\xe0\xe1\xee\xf2\xe0\xed\xee:'), formatMoney(totalEarned),
        imgui.ImVec4(0.45,0.85,0.40,1))
    statRow(u8('\xc2\xf0\xe5\xec\xff \xf0\xe0\xe1\xee\xf2\xfb:'), fmtTime(totalWorkTime),
        imgui.ImVec4(0.85,0.85,0.55,1))
    statRow(u8('\xd1 \xe7\xe0\xef\xf3\xf1\xea\xe0:'), fmtTime(sessionWorkTime),
        imgui.ImVec4(0.85,0.85,0.55,1))

    imgui.Spacing()

    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.205,0.180,0.140,1))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.90,0.34,0.22,0.92))
    if imgui.Button(u8('\xd1\xe1\xf0\xee\xf1\xe8\xf2\xfc \xf1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xf3'), imgui.ImVec2(cw.x, 26*_MDS)) then
        totalStone, totalMetal, totalSilver, totalBronze, totalGold = 0, 0, 0, 0, 0
        totalWorkTime = 0
        saveStats()
        sampAddChatMessage('[ST Mine]: {ffffff}\xd1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xe0 \xf1\xe1\xf0\xee\xf8\xe5\xed\xe0!', -1)
    end
    imgui.PopStyleColor(2)

    imgui.End()
    imgui.PopStyleVar(3)
    imgui.PopStyleColor(5)
end)

end

addEventHandler('onScriptTerminate', function(scr)
    if scr == thisScript() then
        if _statsDirty then
            pcall(saveStats)
        end
        removeJonesObjects()
    end
end)

addEventHandler('onReceivePacket', function(id, bs, ...)
  if id == 220 then
    raknetBitStreamIgnoreBits(bs, 8)
    local packetType = raknetBitStreamReadInt8(bs)
    if packetType == 84 then
      local interfaceid = raknetBitStreamReadInt8(bs)
      local len = raknetBitStreamReadInt16(bs)
      local encoded = raknetBitStreamReadInt8(bs)

      if tonumber(interfaceid) == 25 then
        lua_thread.create(function()
          sendFrontendClick(25, 0, -1, "{}")
          sendFrontendClick(25, 0, -1, "{}")
          sendFrontendClick(25, 0, -1, "{}")
          sendFrontendClick(25, 0, -1, "{}")
        end)
      end
    end
    if packetType == 62 then
      local interfaceid = raknetBitStreamReadInt8(bs)

      if tonumber(interfaceid) == 25 then
        lua_thread.create(function()
          sendFrontendClick(25, 0, -1, "{}")
          sendFrontendClick(25, 0, -1, "{}")
          sendFrontendClick(25, 0, -1, "{}")
          sendFrontendClick(25, 0, -1, "{}")
        end)
      end
    end
  end
end)

function sendFrontendClick(interfaceid, id, subid, json_str)
  local bs = raknetNewBitStream()
  raknetBitStreamWriteInt8(bs, 220)
  raknetBitStreamWriteInt8(bs, 63)
  raknetBitStreamWriteInt8(bs, interfaceid)
  raknetBitStreamWriteInt32(bs, id)
  raknetBitStreamWriteInt32(bs, subid)
  raknetBitStreamWriteInt16(bs, #json_str)
  raknetBitStreamWriteString(bs, json_str)
  raknetSendBitStreamEx(bs, 1, 10, 1)
  raknetDeleteBitStream(bs)
end
