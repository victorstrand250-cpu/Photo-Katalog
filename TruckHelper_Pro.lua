script_name('Truck Helper PRO')
script_author('Victor Strand')
script_version('2.0')
script_version_number(3)
script_properties('work-in-pause')

local imgui  = require('mimgui')
local enc    = require('encoding')
local inicfg = require('inicfg')
local sampev = require('lib.samp.events')
local faR    = require('fAwesome6')
local fa     = require('fAwesome6_solid')
local ffi    = require('ffi')

enc.default = 'CP1251'
local u8  = enc.UTF8
local IS_MOBILE = MONET_VERSION ~= nil
local MDS = IS_MOBILE and MONET_DPI_SCALE or 1.0
local sw, sh = getScreenResolution()

-- some SAMP helpers do not exist on every (mobile/MonetLoader) build, so call
-- them safely and just report "not active" when they are missing
local function safeBool(fn)
    if type(fn) ~= 'function' then return false end
    local ok, r = pcall(fn)
    if ok and r then return true end
    return false
end
local function isChatActive()   return safeBool(sampIsChatInputActive) end
local function isDialogActive() return safeBool(sampIsDialogActive)   end

local _openLink = nil
pcall(function()
    local gta = ffi.load('GTASA')
    ffi.cdef[[ void _Z12AND_OpenLinkPKc(const char* link); ]]
    _openLink = function(url) gta._Z12AND_OpenLinkPKc(url) end
end)

local function openLink(url)
    if _openLink then
        pcall(_openLink, url)
    else
        sampAddChatMessage('{00B4FF}Link: {FFFFFF}' .. url, -1)
    end
end

local FOLDER     = getWorkingDirectory() .. '/TruckHelper'
local CFG_FILE   = 'TruckHelper.ini'
local SOUND_URL  = 'https://files.catbox.moe/52dk8h.mp3'
local SOUND_PATH = FOLDER .. '/menu.mp3'
local LOGO_URL   = 'https://files.catbox.moe/z8yu0x.png'
local LOGO_PATH  = FOLDER .. '/logo.png'
local NAV_URL    = 'https://files.catbox.moe/gafugm.json'
local NAV_PATH   = FOLDER .. '/navmesh.json'

local LIC_SHEET_URL = 'https://docs.google.com/spreadsheets/d/1P5Hjo_x1Ybp_S9tmyEPVlRub12QI7KdLzN3zo7guWR8/gviz/tq?tqx=out:json&sheet=Keys'

local ini

local licenseKey      = ''
local licenseOK       = true   -- license system disabled: all features unlocked
local licenseChecking = false
local licenseMsg      = ''
local licWinOpen      = imgui.new.bool(false)
local licInputBuf     = imgui.new.char[64]('')

local function bufToStr(buf, maxlen)
    local t = {}
    for i = 0, maxlen - 1 do
        local b = buf[i]
        if not b or b == 0 then break end
        t[#t+1] = string.char(b)
    end
    return table.concat(t)
end

local function checkLicenseAsync(key, silent, skipNickCheck)
    if licenseChecking then return end
    licenseChecking = true
    licenseMsg = silent and '' or u8('\xd0\xe5\xf1\xf2\xf0\xe8...')
    lua_thread.create(function()
        local ok, req = pcall(require, 'requests')
        if not ok or not req then
            licenseMsg = silent and '' or u8('\xce\xf8\xe8\xe1\xea\xe0: requests')
            licenseChecking = false; return
        end
        local rok, resp = pcall(req.get, LIC_SHEET_URL)
        if not rok or not resp or resp.status_code ~= 200 then
            licenseMsg = silent and '' or u8('\xce\xf8\xe8\xe1\xea\xe0 \xf1\xe5\xf2\xe8')
            licenseChecking = false; return
        end
        local body = resp.text or resp.content or ''
        local keyData = {}
        for row in body:gmatch('"c":%[(.-)%]') do
            local cols = {}
            for cell in row:gmatch('{[^}]*}') do
                local val = cell:match('"v":"([^"]*)"') or cell:match('"f":"([^"]*)"')
                cols[#cols+1] = val or ''
            end
            local k = cols[1] or ''
            if #k > 2 then
                local ey,em,ed = k:match('(%d%d%d%d)-(%d%d)-(%d%d)$')
                keyData[k] = { nick = cols[2] or '', expiry = (ey and ey..'-'..em..'-'..ed or '') }
            end
        end
        if keyData[key] ~= nil then
            local entry = keyData[key]
            local expiry = entry.expiry
            if expiry ~= '' then
                local ey,em,ed = expiry:match('(%d%d%d%d)-(%d%d)-(%d%d)')
                if ey then
                    local now = os.date('*t')
                    local expired = (tonumber(ey) < now.year)
                        or (tonumber(ey)==now.year and tonumber(em) < now.month)
                        or (tonumber(ey)==now.year and tonumber(em)==now.month and tonumber(ed) < now.day)
                    if expired then
                        licenseOK = false
                        if not silent then licenseMsg = u8('\xd1\xf0\xee\xea \xef\xee\xe4\xef\xe8\xf1\xea\xe8 \xe8\xf1\xf2\xb8\xea') end
                        licenseChecking = false; return
                    end
                end
            end
            local myNick = ''
            pcall(function()
                local _,pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                myNick = sampGetPlayerNickname(pid) or ''
            end)
            local boundNick = entry.nick
            if skipNickCheck or boundNick == '' or boundNick:lower() == myNick:lower() then
                licenseKey    = key
                licenseOK     = true
                licenseMsg    = ''
                licWinOpen[0] = false
                if ini and ini.cfg then
                    ini.cfg.license_key = key
                    inicfg.save(ini, CFG_FILE)
                end
                local expiryInfo = expiry ~= '' and (' {aaaaff}(\xc4\xee: '..expiry..')') or ''
                sampAddChatMessage('{FF4D4D}[Truck Helper PRO]: {00ff7f}\xcb\xe8\xf6\xe5\xed\xe7\xe8\xff \xe0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xed\xe0!'..expiryInfo, -1)
            else
                licenseOK = false
                if not silent then licenseMsg = u8('\xca\xeb\xfe\xf7 \xe7\xe0\xed\xff\xf2 \xe4\xf0\xf3\xe3\xe8\xec \xe8\xe3\xf0\xee\xea\xee\xec') end
            end
        else
            licenseOK = false
            if not silent then licenseMsg = u8('\xca\xeb\xfe\xf7 \xed\xe5 \xed\xe0\xe9\xe4\xe5\xed') end
        end
        licenseChecking = false
    end)
end

local function readBool(v, def)
    if v == true  or v == 'true'  then return true  end
    if v == false or v == 'false' then return false end
    return def
end

local function notify(msg)
    sampAddChatMessage('{FF4D4D}[Truck Helper]{FFFFFF} ' .. msg, -1)
end

local function toggleNotify(name, state)
    local s = state and '{00FF7F}ON{FFFFFF}' or '{FF4444}OFF{FFFFFF}'
    notify(name .. ': ' .. s)
end

ini = inicfg.load({
    cfg = {
        license_key  = '',
        anticarskill = 'false',
        autogruz     = 'false',
        gruz_index   = '0',
        autogate     = 'false',
        attach_btn   = 'false',
        atr_x        = tostring(math.floor(sw * 0.82)),
        atr_y        = tostring(math.floor(sh * 0.55)),
        stats_visible= 'false',
        zarp         = '0',
        larec        = '0',
        domkrat_btn  = 'false',
        dk_x         = tostring(math.floor(sw * 0.05)),
        dk_y         = tostring(math.floor(sh * 0.70)),
        gps_line     = 'false',
        autopilot    = 'false',
        ap_speed     = '60',
        ap_steer     = '50',
        ap_turn_speed= '35',
        antidetach   = 'false',
        nocollision  = 'false',
        domkrat_key  = '0',
    }
}, CFG_FILE)

anticarskill  = readBool(ini.cfg.anticarskill,  false)
autogruz      = readBool(ini.cfg.autogruz,      false)
gruz_index    = tonumber(ini.cfg.gruz_index)    or 0
autogate      = readBool(ini.cfg.autogate,      false)
attach_btn    = readBool(ini.cfg.attach_btn,    false)
stats_visible = readBool(ini.cfg.stats_visible, false)
zarp          = tonumber(ini.cfg.zarp)          or 0
larec         = tonumber(ini.cfg.larec)         or 0
domkrat_btn   = readBool(ini.cfg.domkrat_btn,   false)
gpsLine       = readBool(ini.cfg.gps_line,      false)
autopilot     = readBool(ini.cfg.autopilot,     false)
ap_speed      = tonumber(ini.cfg.ap_speed)      or 60
ap_steer      = tonumber(ini.cfg.ap_steer)      or 50
ap_turn_speed = tonumber(ini.cfg.ap_turn_speed) or 35
antiDetach    = readBool(ini.cfg.antidetach,    false)
nocollision   = readBool(ini.cfg.nocollision,   false)
domkrat_key   = tonumber(ini.cfg.domkrat_key)   or 0

licenseKey = (ini.cfg.license_key and ini.cfg.license_key ~= '') and ini.cfg.license_key or ''
do
    local k = licenseKey
    for i = 1, math.min(#k, 63) do licInputBuf[i-1] = string.byte(k,i) end
    licInputBuf[math.min(#k,63)] = 0
end

local atr_posX     = tonumber(ini.cfg.atr_x) or math.floor(sw * 0.82)
local atr_posY     = tonumber(ini.cfg.atr_y) or math.floor(sh * 0.55)
local domkrat_posX = tonumber(ini.cfg.dk_x)  or math.floor(sw * 0.05)
local domkrat_posY = tonumber(ini.cfg.dk_y)  or math.floor(sh * 0.70)

local function saveCfg()
    ini.cfg.license_key  = tostring(licenseKey or '')
    ini.cfg.anticarskill = tostring(anticarskill)
    ini.cfg.autogruz     = tostring(autogruz)
    ini.cfg.gruz_index   = tostring(gruz_index)
    ini.cfg.autogate     = tostring(autogate)
    ini.cfg.attach_btn   = tostring(attach_btn)
    ini.cfg.atr_x        = tostring(math.floor(atr_posX))
    ini.cfg.atr_y        = tostring(math.floor(atr_posY))
    ini.cfg.stats_visible= tostring(stats_visible)
    ini.cfg.zarp         = tostring(zarp)
    ini.cfg.larec        = tostring(larec)
    ini.cfg.domkrat_btn  = tostring(domkrat_btn)
    ini.cfg.dk_x         = tostring(math.floor(domkrat_posX))
    ini.cfg.dk_y         = tostring(math.floor(domkrat_posY))
    ini.cfg.gps_line     = tostring(gpsLine)
    ini.cfg.autopilot    = tostring(autopilot)
    ini.cfg.ap_speed     = tostring(ap_speed)
    ini.cfg.ap_steer     = tostring(ap_steer)
    ini.cfg.ap_turn_speed= tostring(ap_turn_speed)
    ini.cfg.antidetach   = tostring(antiDetach)
    ini.cfg.nocollision  = tostring(nocollision)
    ini.cfg.domkrat_key  = tostring(domkrat_key)
    inicfg.save(ini, CFG_FILE)
end

local bass   = nil
local stream = 0

pcall(function()
    bass = ffi.load('libbass.so')
    ffi.cdef[[
        int           BASS_Init(int device, unsigned long freq,
                                unsigned long flags, void* win, void* clsid);
        unsigned long BASS_StreamCreateFile(int mem, const char* file,
                                            unsigned long long offset,
                                            unsigned long long length,
                                            unsigned long flags);
        int           BASS_ChannelPlay(unsigned long handle, int restart);
        int           BASS_ChannelStop(unsigned long handle);
        int           BASS_StreamFree(unsigned long handle);
        int           BASS_ChannelSetAttribute(unsigned long handle,
                                               unsigned long attrib, float value);
    ]]
    bass.BASS_Init(-1, 44100, 0, nil, nil)
end)

local function playMenuSound()
    if not bass then return end
    if not doesFileExist(SOUND_PATH) then return end
    pcall(function()
        if stream ~= 0 then
            bass.BASS_ChannelStop(stream)
            bass.BASS_StreamFree(stream)
            stream = 0
        end
        stream = bass.BASS_StreamCreateFile(0, SOUND_PATH, 0, 0, 0)
        if stream ~= 0 then
            bass.BASS_ChannelSetAttribute(stream, 2, 0.75)
            bass.BASS_ChannelPlay(stream, 1)
        end
    end)
end

function sampev.onSendVehicleDamaged(...)
    if anticarskill then return false end
end

local BARRIER_MODELS = {
    [968]=true,[975]=true,[1374]=true,[19912]=true,
    [988]=true,[19313]=true,[11327]=true,[980]=true
}

local function doAutoGate()
    if not autogate then return end
    local inCar = isCharInAnyCar(PLAYER_PED)
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    for _, hObj in pairs(getAllObjects()) do
        if doesObjectExist(hObj) then
            local objModel = getObjectModel(hObj)
            if BARRIER_MODELS[objModel] then
                local res, ox, oy, oz = getObjectCoordinates(hObj)
                local dist = getDistanceBetweenCoords3d(px, py, pz, ox, oy, oz)
                if dist < (inCar and 12 or 5) then
                    local bs = raknetNewBitStream()
                    raknetBitStreamWriteInt8(bs, 220)
                    raknetBitStreamWriteInt8(bs, 63)
                    raknetBitStreamWriteInt8(bs, 8)
                    raknetBitStreamWriteInt32(bs, 7)
                    raknetBitStreamWriteInt32(bs, -1)
                    raknetBitStreamWriteInt32(bs, 0)
                    raknetBitStreamWriteString(bs, '')
                    raknetSendBitStreamEx(bs, 1, 7, 1)
                    raknetDeleteBitStream(bs)
                    return
                end
            end
        end
    end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
    if autogruz then
        local isGruz = false
        if title then
            isGruz = title:find('\xc2\xfb\xe1\xee\xf0 \xe3\xf0\xf3\xe7\xe0')
                  or title:find('\xc2\xfb\xe1\xee\xf0\20\xe3\xf0\xf3\xe7\xe0')
                  or title:lower():find('gruz')
                  or title:lower():find('cargo')
                  or title:lower():find('load')
        end
        if not isGruz and text then
            isGruz = text:find('\xe3\xf0\xf3\xe7') or text:lower():find('gruz')
        end
        if isGruz then
            local lines = {}
            if text then
                for line in (text .. '\n'):gmatch('([^\n]*)\n') do
                    if line ~= '' then lines[#lines + 1] = line end
                end
            end
            local lineCount = #lines
            local idx
            if gruz_index == 0 then
                idx = math.max(0, lineCount - 1)
            else
                idx = gruz_index - 1
                if lineCount > 0 and idx >= lineCount then idx = lineCount - 1 end
                if idx < 0 then idx = 0 end
            end
            sampSendDialogResponse(id, 1, idx, '')
            return false
        end
    end
end

local function checkLarecMessage(text)
    if not text then return end
    local hasLarec = text:find('\xeb\xe0\xf0\xe5\xf6')
                  or text:lower():find('larec')
                  or text:lower():find('chest')
    local hasGot   = text:find('\xef\xee\xeb\xf3\xf7\xe8\xeb')
                  or text:find('\xed\xe0\xf8\xeb\xe8')
    if hasLarec and hasGot then
        larec = larec + 1; saveCfg(); return
    end
    local hasAdded  = text:find('\xc4\xee\xe1\xe0\xe2\xeb\xe5\xed') or text:lower():find('added')
    local hasLarec2 = text:find('\xcb\xe0\xf0\xe5\xf6') or text:lower():find('larec')
    if hasAdded and hasLarec2 then
        larec = larec + 1; saveCfg()
    end
end

function sampev.onChatMessage(color, text)
    if not text then return end
    checkLarecMessage(text)
end

function sampev.onServerMessage(color, text)
    if not text then return end
    checkLarecMessage(text)

    local hasEarned = false
    if text:find('\xe4\xee\xf1\xf2\xe0\xe2\xeb\xe5\xed', 1, true) then hasEarned = true end
    if text:find('\xc4\xee\xf1\xf2\xe0\xe2\xeb\xe5\xed', 1, true) then hasEarned = true end
    if text:find('\xe7\xe0\xf0\xef\xeb\xe0\xf2\xe0',     1, true) then hasEarned = true end
    if text:find('\xe7\xe0\xf0\xe0\xe1\xee\xf2\xe0\xeb', 1, true) then hasEarned = true end
    if text:find('\xe2\xfb\xef\xeb\xe0\xf2\xe0',         1, true) then hasEarned = true end
    if text:find('\xf0\xe5\xe9\xf1',                     1, true) then hasEarned = true end
    if not hasEarned then return end

    local tail = text:match(':[^:]*$') or text
    tail = tail:gsub('[%.!]%s*$', '')

    local earned = 0
    local found  = false

    do
        local mm, rest = tail:match('KK%s*(%d+)%s+K%s*([%d%.]+)')
        if mm and rest then
            earned = (tonumber(mm) or 0) * 1000000 + (tonumber(rest:gsub('%.','')) or 0)
            found  = true
        end
    end

    if not found then
        local kval = tail:match('[%s:]K%s+(%d[%d%.]+)')
        if not kval then kval = tail:match('K%s+(%d[%d%.]+)') end
        if not kval then kval = tail:match('K(%d[%d%.]+)')    end
        if kval then
            earned = tonumber(kval:gsub('%.','')) or 0
            found  = true
        end
    end

    if not found then
        local mm, rest = tail:match('\xca\xca%s*(%d+)%s+\xca%s*([%d%.]+)')
        if mm and rest then
            earned = (tonumber(mm) or 0) * 1000000 + (tonumber(rest:gsub('%.','')) or 0)
            found  = true
        end
    end
    if not found then
        local kval = tail:match('[%s:]\xca%s+(%d[%d%.]+)')
        if not kval then kval = tail:match('\xca%s+(%d[%d%.]+)') end
        if kval then
            earned = tonumber(kval:gsub('%.','')) or 0
            found  = true
        end
    end

    if not found then
        local amount = text:match('%$(%d[%d,%.]*)')
        if not amount then amount = text:match('([%d]+)%s*%$') end
        if amount then
            earned = tonumber(amount:gsub('[,%.%s]','')) or 0
            found  = true
        end
    end

    if found and earned > 0 then
        zarp = zarp + earned
        saveCfg()
    end
end

local atr_selecting = false
local atr_trailer   = nil
local atr_autoMode  = false
local atr_moveMode  = false
local ATR_RADIUS    = 150
local ATR_STEP      = 8 * MDS

local function getNearestTrailer()
    local okC, myCar = pcall(getCarCharIsUsing, PLAYER_PED)
    if not okC or not myCar then return nil end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local best, bestV = 9999, nil
    local okV, vehs = pcall(getAllVehicles)
    if not okV or not vehs then return nil end
    for _, v in ipairs(vehs) do
        if v ~= myCar then
            local ok2, vx, vy, vz = pcall(getCarCoordinates, v)
            if ok2 then
                local d = getDistanceBetweenCoords3d(px, py, pz, vx, vy, vz)
                if d < best and d <= 30 then best = d; bestV = v end
            end
        end
    end
    return bestV
end

local function doAttach(veh)
    local okC, myCar = pcall(getCarCharIsUsing, PLAYER_PED)
    if not okC or not myCar then return end
    if not doesVehicleExist(veh) then return end
    local ok2, attached = pcall(isTrailerAttachedToCab, veh, myCar)
    if ok2 and attached then
        pcall(detachTrailerFromCab, veh, myCar)
        notify('\xcf\xf0\xe8\xf6\xe5\xef \xee\xf2\xf6\xe5\xef\xeb\xe5\xed')
    else
        pcall(attachTrailerToCab, veh, myCar)
        notify('\xcf\xf0\xe8\xf6\xe5\xef \xef\xf0\xe8\xf6\xe5\xef\xeb\xe5\xed!')
    end
end

local NOCOL_MODELS = {
    [1435]=true,[3335]=true,[997]=true, [1319]=true,[994]=true, [1425]=true,[968]=true,
    [19972]=true,[19975]=true,[19980]=true,[1290]=true,[1226]=true,[1294]=true,[717]=true,
    [669]=true,[768]=true,[673]=true,[737]=true,[738]=true,[792]=true,[1346]=true,
    [1283]=true,[3516]=true,[3855]=true,[1352]=true,[1256]=true,[1350]=true,[3459]=true,
    [1308]=true,[3875]=true,[3854]=true,[1307]=true,
}

local function bulkSetCollision(state)
    local ok, objs = pcall(getAllObjects)
    if not ok or not objs then return end
    local n = 0
    for _, obj in ipairs(objs) do
        if doesObjectExist(obj) then
            local m = getObjectModel(obj)
            if NOCOL_MODELS[m] then pcall(setObjectCollision, obj, state) end
        end
        n = n + 1
        if n % 30 == 0 then wait(0) end
    end
end

function sampev.onCreateObject(id, modelId)
    if not nocollision then return end
    if not NOCOL_MODELS[modelId] then return end
    lua_thread.create(function()
        wait(150)
        local ok, h = pcall(sampGetObjectHandleBySampId, id)
        if ok and h and doesObjectExist(h) then pcall(setObjectCollision, h, false) end
    end)
end

local nocol_prev = false
lua_thread.create(function()
    while not isSampAvailable() do wait(1000) end
    while not sampIsLocalPlayerSpawned() do wait(500) end
    while true do
        wait(500)
        local cur = nocollision
        if cur and not nocol_prev then bulkSetCollision(false)
        elseif not cur and nocol_prev then bulkSetCollision(true) end
        nocol_prev = cur
    end
end)

lua_thread.create(function()
    while not isSampAvailable() do wait(1000) end
    while not sampIsLocalPlayerSpawned() do wait(500) end
    while true do
        wait(2000)
        if nocollision then bulkSetCollision(false) end
    end
end)

local nav_nodes   = {}
local nav_grid    = {}
local nav_loaded  = false
local nav_loading = false
local nav_count   = 0
local GRID_CELL   = 150

local function gridKey(cx, cy) return cx..'_'..cy end

local function buildNavGrid()
    nav_grid = {}
    for id, node in pairs(nav_nodes) do
        local cx = math.floor(node.x/GRID_CELL)
        local cy = math.floor(node.y/GRID_CELL)
        local key = gridKey(cx,cy)
        if not nav_grid[key] then nav_grid[key] = {} end
        local cell = nav_grid[key]
        cell[#cell+1] = id
    end
end

local function findNearestNode(x, y)
    local cx = math.floor(x/GRID_CELL)
    local cy = math.floor(y/GRID_CELL)
    local bestDist = math.huge
    local bestId   = nil
    for dcx = -2, 2 do
        for dcy = -2, 2 do
            local cell = nav_grid[gridKey(cx+dcx, cy+dcy)]
            if cell then
                for _, id in ipairs(cell) do
                    local n = nav_nodes[id]
                    if n then
                        local dx = n.x-x; local dy = n.y-y
                        local d = dx*dx+dy*dy
                        if d < bestDist then bestDist=d; bestId=id end
                    end
                end
            end
        end
    end
    return bestId
end

local WAREHOUSES = {
    {x=2219.210, y=-2646.751, z=13.547},
    {x=1385.509, y=1152.220,  z=10.820},
    {x=-2257.675,y=272.934,   z=35.320},
}

local function getNearestWarehouse(px, py)
    local best, bestW = math.huge, nil
    for _, w in ipairs(WAREHOUSES) do
        local d = math.sqrt((w.x-px)^2+(w.y-py)^2)
        if d < best then best=d; bestW=w end
    end
    return bestW
end

local cpActive = false
local cpX, cpY, cpZ = 0, 0, 0
local ap_lastCmd      = 0
local AP_CMD_INTERVAL = 220
local ap_stuckLastMove  = 0
local ap_stuckTimeout   = 6000
local ap_unstucking     = false
local ap_unstuckUntil   = 0
local ap_path           = nil
local ap_path_idx       = 1
local ap_building       = false
local AP_DIRECT_DIST    = 70
local ap_useNavPath     = false
local ap_directFails    = 0
local ap_unstuck_phase  = 0
local ap_stableTargetX  = nil
local ap_stableTargetY  = nil
local ap_stableTargetZ  = nil
local ap_lastTargetUpdateDist = 0

local antiDetach_veh  = nil
local antiDetach_last = 0

local function rotateVec2(nx, ny, angleDeg)
    local a = math.rad(angleDeg)
    return nx*math.cos(a)-ny*math.sin(a), nx*math.sin(a)+ny*math.cos(a)
end

local function aStarAsync(start_id, goal_id, callback)
    if not nav_nodes[start_id] or not nav_nodes[goal_id] then callback(nil); return end
    if start_id == goal_id then local n=nav_nodes[goal_id]; callback({{x=n.x,y=n.y,z=n.z}}); return end
    local gn = nav_nodes[goal_id]
    local function h(id) local n=nav_nodes[id]; if not n then return 0 end; local dx=n.x-gn.x; local dy=n.y-gn.y; return math.sqrt(dx*dx+dy*dy) end
    local heap={}; local hsize=0
    local function hpush(id,f) hsize=hsize+1; heap[hsize]={id=id,f=f}; local i=hsize; while i>1 do local p=math.floor(i/2); if heap[p].f>heap[i].f then heap[p],heap[i]=heap[i],heap[p]; i=p else break end end end
    local function hpop() if hsize==0 then return nil end; local top=heap[1]; heap[1]=heap[hsize]; heap[hsize]=nil; hsize=hsize-1; local i=1; while true do local l,r,s=2*i,2*i+1,i; if l<=hsize and heap[l].f<heap[s].f then s=l end; if r<=hsize and heap[r].f<heap[s].f then s=r end; if s~=i then heap[i],heap[s]=heap[s],heap[i]; i=s else break end end; return top end
    local g_score={}; local came_from={}; local visited={}
    g_score[start_id]=0; hpush(start_id,h(start_id))
    local found=false; local iter=0
    while hsize>0 do
        iter=iter+1
        if iter%300==0 then wait(0) end
        if iter>15000 then break end
        local cur=hpop(); if not cur then break end; local cid=cur.id
        if cid==goal_id then found=true; break end
        if visited[cid] then goto cont end; visited[cid]=true
        local node=nav_nodes[cid]
        if node and node.edges then
            for _,e in ipairs(node.edges) do
                local nid=e[1]; local edist=e[2]
                if not visited[nid] and nav_nodes[nid] then
                    local ng=(g_score[cid] or 0)+edist
                    if not g_score[nid] or ng<g_score[nid] then
                        g_score[nid]=ng; came_from[nid]=cid; hpush(nid,ng+h(nid))
                    end
                end
            end
        end
        ::cont::
    end
    if found then
        local path={}; local id=goal_id
        while id do local n=nav_nodes[id]; if n then table.insert(path,1,{x=n.x,y=n.y,z=n.z}) end; id=came_from[id] end
        callback(path)
    else callback(nil) end
end

local function buildRoute(px, py, pz)
    if ap_building then return end
    if not nav_loaded then return end
    ap_building=true; ap_path=nil; ap_path_idx=1; ap_useNavPath=false
    lua_thread.create(function()
        local sid=findNearestNode(px,py); local gid=findNearestNode(cpX,cpY)
        if not sid or not gid then ap_building=false; return end
        aStarAsync(sid, gid, function(path)
            if path and #path>0 then
                path[#path+1]={x=cpX,y=cpY,z=cpZ}
                local pathLen=0
                for i=2,#path do local a,b=path[i-1],path[i]; pathLen=pathLen+math.sqrt((b.x-a.x)^2+(b.y-a.y)^2) end
                local directDist=math.sqrt((cpX-px)^2+(cpY-py)^2)
                -- reject the navmesh route if it is a noticeable detour vs. the
                -- straight-line distance -> fall back to the short direct path
                if pathLen>directDist*1.6 then ap_path=nil; ap_useNavPath=false
                else ap_path=path; ap_path_idx=1; ap_useNavPath=true end
            else ap_path=nil; ap_useNavPath=false end
            ap_building=false
        end)
    end)
end

local gps_path=nil; local gps_building=false; local gps_pending=false; local gps_draw_idx=1

local function buildGpsRoute(px, py)
    if gps_building then return end
    if not nav_loaded then gps_pending=true; return end
    gps_building=true; gps_path=nil; gps_pending=false; gps_draw_idx=1
    lua_thread.create(function()
        local sid=findNearestNode(px,py); local gid=findNearestNode(cpX,cpY)
        if not sid or not gid then gps_building=false; return end
        aStarAsync(sid, gid, function(path)
            if path and #path>0 then
                path[#path+1]={x=cpX,y=cpY,z=cpZ}
                -- mirror the autopilot's detour rejection so the drawn GPS line
                -- matches the route the truck will actually take (a straight
                -- line when the navmesh route would be a needless loop)
                local pathLen=0
                for i=2,#path do local a,b=path[i-1],path[i]; pathLen=pathLen+math.sqrt((b.x-a.x)^2+(b.y-a.y)^2) end
                local directDist=math.sqrt((cpX-px)^2+(cpY-py)^2)
                if pathLen>directDist*1.6 then gps_path=nil else gps_path=path end
            else gps_path=nil end
            gps_building=false
        end)
    end)
end

lua_thread.create(function()
    while true do
        wait(1000)
        if nav_loaded and gps_pending and cpActive then
            local okP,px,py=pcall(getCharCoordinates,PLAYER_PED)
            if okP and type(px)=='number' then buildGpsRoute(px,py) end
        end
    end
end)

local function doAntiDetach()
    if not antiDetach then return end
    if not isCharInAnyCar(PLAYER_PED) then antiDetach_veh=nil; return end
    local now=os.clock()*1000
    if (now-antiDetach_last)<500 then return end
    antiDetach_last=now
    local okC,myCar=pcall(storeCarCharIsInNoSave,PLAYER_PED)
    if not okC or not myCar or not doesVehicleExist(myCar) then return end
    if antiDetach_veh==nil or not doesVehicleExist(antiDetach_veh) then
        local okV,vehs=pcall(getAllVehicles)
        if not okV or not vehs then return end
        for _,v in ipairs(vehs) do
            if v~=myCar then
                local ok2,attached=pcall(isTrailerAttachedToCab,v,myCar)
                if ok2 and attached then antiDetach_veh=v; break end
            end
        end
        return
    end
    local ok3,attached=pcall(isTrailerAttachedToCab,antiDetach_veh,myCar)
    if ok3 and not attached and doesVehicleExist(antiDetach_veh) then
        pcall(attachTrailerToCab,antiDetach_veh,myCar)
        notify('\xc0\xed\xf2\xe8-\xee\xf2\xf6\xe5\xef: \xef\xf0\xe8\xf6\xe5\xef \xef\xe5\xf0\xe5\xef\xf0\xe8\xf6\xe5\xef\xeb\xe5\xed')
    end
end

local function enableAutopilot()
    autopilot=true; ap_stuckLastMove=os.clock()*1000; ap_unstucking=false
    ap_path=nil; ap_path_idx=1; ap_building=false; ap_useNavPath=false
    ap_directFails=0; ap_stableTargetX=nil
    if not cpActive then
        local ok,bx,by,bz=pcall(getTargetBlipCoordinates)
        if ok and bx and type(bx)=='number' then cpX,cpY,cpZ=bx,by,bz; cpActive=true end
    end
    if cpActive and nav_loaded then
        lua_thread.create(function()
            wait(200)
            local okP,px,py,pz2=pcall(getCharCoordinates,PLAYER_PED)
            if okP and type(px)=='number' then buildRoute(px,py,pz2) end
        end)
    end
    notify('\xc0\xe2\xf2\xee\xef\xe8\xeb\xee\xf2: {00FF7F}ON')
    saveCfg()
end

local function disableAutopilot()
    autopilot=false; ap_unstucking=false; ap_path=nil; ap_building=false
    ap_useNavPath=false; ap_directFails=0
    if isCharInAnyCar(PLAYER_PED) then
        local ok,car=pcall(storeCarCharIsInNoSave,PLAYER_PED)
        if ok and car and doesVehicleExist(car) then
            local px,py,pz=getCharCoordinates(PLAYER_PED)
            pcall(taskCarDriveToCoord,PLAYER_PED,car,px,py,pz,0,0,0,2)
            lua_thread.create(function() wait(150); pcall(clearCharTasks,PLAYER_PED) end)
        end
    end
    notify('\xc0\xe2\xf2\xee\xef\xe8\xeb\xee\xf2: {FF4444}OFF')
    saveCfg()
end

local function doAutopilot()
    if not autopilot then return end
    if not cpActive then return end
    if not isCharInAnyCar(PLAYER_PED) then return end
    local okC,car=pcall(storeCarCharIsInNoSave,PLAYER_PED)
    if not okC or not car or not doesVehicleExist(car) then return end
    local px,py,pz=getCharCoordinates(PLAYER_PED)
    if type(px)~='number' then return end
    local dist=getDistanceBetweenCoords2d(px,py,cpX,cpY)
    if dist>1000 then
        local w=getNearestWarehouse(px,py)
        if w then local wdist=math.sqrt((w.x-px)^2+(w.y-py)^2); if wdist<dist then pcall(taskCarDriveToCoord,PLAYER_PED,car,w.x,w.y,w.z,ap_speed/(3.6*0.78),0,0,2); return end end
    end
    if dist<=8.0 then ap_unstucking=false; ap_path=nil; ap_useNavPath=false; ap_directFails=0; pcall(taskCarDriveToCoord,PLAYER_PED,car,cpX,cpY,cpZ,5.0/(3.6*0.78),0,0,2); return end
    if dist<=AP_DIRECT_DIST then if ap_useNavPath then ap_path=nil; ap_useNavPath=false; ap_building=false; ap_stableTargetX=nil end end
    if ap_useNavPath and (not ap_path or ap_path_idx>#ap_path) then ap_path=nil; ap_useNavPath=false; ap_stableTargetX=nil end
    local now=os.clock()*1000
    local carSpeedKmh=0
    local okSpd,carSpd=pcall(getCarSpeed,car)
    if okSpd and carSpd then carSpeedKmh=carSpd*3.6*0.78 end
    if carSpeedKmh>3.0 then ap_stuckLastMove=now; ap_unstucking=false end
    if ap_unstucking then
        if now<ap_unstuckUntil then return end
        ap_unstucking=false; ap_stuckLastMove=now; ap_stableTargetX=nil
        if ap_unstuck_phase>=2 and nav_loaded then ap_directFails=ap_directFails+1; ap_unstuck_phase=0; buildRoute(px,py,pz) end
        return
    end
    if (now-ap_stuckLastMove)>ap_stuckTimeout then
        local okH2,carH2=pcall(getCarHeading,car)
        local isActuallyTurning=false
        if okH2 and carH2 then
            local hr=math.rad(carH2); local fx=-math.sin(hr); local fy=math.cos(hr)
            local tdx=cpX-px; local tdy=cpY-py; local tl=math.sqrt(tdx*tdx+tdy*tdy)
            if tl>0.1 then local dot=fx*(tdx/tl)+fy*(tdy/tl); if dot<0.5 and carSpeedKmh>1.0 then isActuallyTurning=true end end
        end
        if not isActuallyTurning then
            ap_unstucking=true; ap_stuckLastMove=now; ap_stableTargetX=nil
            local dx=cpX-px; local dy=cpY-py; local len=math.sqrt(dx*dx+dy*dy); if len<0.1 then len=1 end
            local fwdX=dx/len; local fwdY=dy/len
            local phase=ap_unstuck_phase%6; ap_unstuck_phase=ap_unstuck_phase+1
            local manX,manY,manDist,manDur
            if phase==0 then manDist=60;manDur=2500;manX,manY=px-fwdX*manDist,py-fwdY*manDist
            elseif phase==1 then manDist=55;manDur=2200;local rx,ry=rotateVec2(-fwdX,-fwdY,45);manX,manY=px+rx*manDist,py+ry*manDist
            elseif phase==2 then manDist=55;manDur=2200;local rx,ry=rotateVec2(-fwdX,-fwdY,-45);manX,manY=px+rx*manDist,py+ry*manDist
            elseif phase==3 then manDist=65;manDur=2800;local rx,ry=rotateVec2(-fwdX,-fwdY,70);manX,manY=px+rx*manDist,py+ry*manDist
            elseif phase==4 then manDist=65;manDur=2800;local rx,ry=rotateVec2(-fwdX,-fwdY,-70);manX,manY=px+rx*manDist,py+ry*manDist
            else manDist=80;manDur=3000;manX,manY=px-fwdX*manDist,py-fwdY*manDist end
            ap_unstuckUntil=now+manDur
            pcall(taskCarDriveToCoord,PLAYER_PED,car,manX,manY,pz,math.max(40,ap_speed*0.75)/(3.6*0.78),0,0,2)
            return
        else ap_stuckLastMove=now end
    end
    if (now-ap_lastCmd)<AP_CMD_INTERVAL then return end
    ap_lastCmd=now

    -- current speed in m/s (world units ~= meters)
    local v_ms = carSpeedKmh/3.6
    -- pure-pursuit lookahead: grows with speed, stays short in tight spots so
    -- the AI aims at a real point on the road instead of cutting the corner
    local Ld = math.max(8.0, math.min(34.0, 7.0 + v_ms*1.10))

    -- vehicle dynamics budget (tuned for a loaded truck). ap_steer raises how
    -- aggressively we are willing to corner; higher = faster through bends.
    local a_lat   = 1.8 + (ap_steer/100.0)*2.7   -- max lateral accel  1.8 .. 4.5 m/s^2
    local a_brake = 4.5                           -- comfortable braking accel  m/s^2

    local targetX,targetY,targetZ
    targetZ = pz
    local plannedKmh = ap_speed                   -- speed cap before curvature planning

    if ap_useNavPath and ap_path and ap_path[ap_path_idx] then
        -- drop waypoints we have effectively reached
        while ap_path_idx < #ap_path do
            local wp = ap_path[ap_path_idx]
            if getDistanceBetweenCoords2d(px,py,wp.x,wp.y) <= math.max(7.0, Ld*0.55) then
                ap_path_idx = ap_path_idx + 1
            else break end
        end
        if ap_path_idx > #ap_path then
            ap_path=nil; ap_useNavPath=false; ap_stableTargetX=nil
            targetX,targetY,targetZ = cpX,cpY,cpZ
        else
            -- (1) aim point: walk the path forward from the player for Ld meters
            local tx,ty = px,py
            local acc = 0
            local i = ap_path_idx
            while i<=#ap_path do
                local wp=ap_path[i]
                local seg=getDistanceBetweenCoords2d(tx,ty,wp.x,wp.y)
                if acc+seg>=Ld then
                    local rem=Ld-acc; local t=(seg>0) and (rem/seg) or 0
                    targetX=tx+(wp.x-tx)*t; targetY=ty+(wp.y-ty)*t
                    break
                end
                acc=acc+seg; tx,ty=wp.x,wp.y; i=i+1
            end
            if not targetX then targetX,targetY=cpX,cpY end

            -- (2) predictive braking: scan every bend within braking distance and
            -- compute the highest speed from which we can still slow down in time.
            local scanD  = math.max(25.0, (v_ms*v_ms)/(2*a_brake) + Ld + 10.0)
            local jx,jy  = px,py
            local kx,ky  = ap_path[ap_path_idx].x, ap_path[ap_path_idx].y
            local dToK   = getDistanceBetweenCoords2d(px,py,kx,ky)
            local ni     = ap_path_idx + 1
            local safeMs = plannedKmh/3.6
            while ni<=#ap_path and dToK<=scanD do
                local nx,ny = ap_path[ni].x, ap_path[ni].y
                local v1x,v1y = kx-jx, ky-jy
                local v2x,v2y = nx-kx, ny-ky
                local l1 = math.sqrt(v1x*v1x+v1y*v1y)
                local l2 = math.sqrt(v2x*v2x+v2y*v2y)
                if l1>0.5 and l2>0.5 then
                    local dot = (v1x*v2x+v1y*v2y)/(l1*l2)
                    if dot>1 then dot=1 elseif dot<-1 then dot=-1 end
                    local theta = math.acos(dot)               -- heading change at vertex k
                    if theta>0.10 then                          -- ignore < ~6 deg jitter
                        local R = ((l1+l2)*0.5)/(2*math.sin(theta*0.5))
                        if R<5 then R=5 end
                        local vCurve = math.sqrt(a_lat*R)                       -- safe speed inside the bend
                        local d = dToK; if d<0 then d=0 end
                        local vAllow = math.sqrt(vCurve*vCurve + 2*a_brake*d)   -- speed we may hold now
                        if vAllow<safeMs then safeMs=vAllow end
                    end
                end
                dToK = dToK + l2
                jx,jy = kx,ky
                kx,ky = nx,ny
                ni = ni + 1
            end
            plannedKmh = math.max(8.0, safeMs*3.6)
        end
    else
        -- direct mode (no usable road route): aim at a near rolling point straight
        -- toward the checkpoint instead of the checkpoint itself. Handing the game
        -- AI the far checkpoint makes it plan a long detour over road nodes (the
        -- "drives 500 m around for a 50 m goal" problem); a near aim point forces
        -- it to take the short, direct way while still avoiding local obstacles.
        local dx=cpX-px; local dy=cpY-py; local L=math.sqrt(dx*dx+dy*dy)
        if L>Ld then
            targetX=px+dx/L*Ld; targetY=py+dy/L*Ld; targetZ=pz
        else
            targetX=cpX; targetY=cpY; targetZ=cpZ
        end
    end

    -- final speed = min(user cap, curvature plan, approach taper, heading-error limit)
    local finalKmh = math.min(ap_speed, plannedKmh)

    -- ease off as we roll up to the checkpoint
    if dist<=25 then
        local t=math.max(0,math.min(1,(dist-5)/20))
        local appr=ap_speed*(0.80+0.20*t)
        if appr<finalKmh then finalKmh=appr end
    end

    -- if the truck is not yet pointed at the aim point, slow down so it can
    -- swing onto line instead of understeering off the road at speed
    local okH,carHeading=pcall(getCarHeading,car)
    if okH and carHeading and targetX then
        local dx=targetX-px; local dy=targetY-py; local tLen=math.sqrt(dx*dx+dy*dy)
        if tLen>1.0 then
            local headRad=math.rad(carHeading); local fwdX=-math.sin(headRad); local fwdY=math.cos(headRad)
            local tX,tY=dx/tLen,dy/tLen
            local dot=fwdX*tX+fwdY*tY; if dot>1 then dot=1 elseif dot<-1 then dot=-1 end
            local angleDeg=math.deg(math.acos(dot))
            if angleDeg>25 and dist>10 then
                local turnFactor=math.min(1,(angleDeg-25)/70)
                local hKmh=ap_turn_speed+(ap_speed-ap_turn_speed)*(1-turnFactor)
                if hKmh<finalKmh then finalKmh=hKmh end
            end
        end
    end

    if finalKmh<6 then finalKmh=6 end
    local finalSpeed=finalKmh/(3.6*0.78)
    if targetX then pcall(taskCarDriveToCoord,PLAYER_PED,car,targetX,targetY,targetZ,finalSpeed,0,0,2) end
end

function sampev.onSetCheckpoint(position, size)
    if position and type(position) == 'table' then
        local x,y,z = tonumber(position.x),tonumber(position.y),tonumber(position.z)
        if x and y and z then
            cpX,cpY,cpZ=x,y,z; cpActive=true
            ap_path=nil; ap_useNavPath=false; ap_directFails=0; ap_building=false
            gps_path=nil; gps_building=false; gps_pending=false; gps_draw_idx=1
            lua_thread.create(function()
                wait(300)
                local okP,px,py=pcall(getCharCoordinates,PLAYER_PED)
                if okP and type(px)=='number' then buildGpsRoute(px,py) end
            end)
            if autopilot and nav_loaded then
                lua_thread.create(function()
                    wait(300)
                    local px,py,pz=getCharCoordinates(PLAYER_PED)
                    if type(px)=='number' then buildRoute(px,py,pz) end
                end)
            end
        end
    end
end

function sampev.onSetRaceCheckpoint(cptype, position, nextPosition, size)
    local x,y,z
    if type(position)=='table' then x,y,z=tonumber(position.x),tonumber(position.y),tonumber(position.z)
    else x,y,z=tonumber(position),tonumber(nextPosition),tonumber(size) end
    if x and y and z then
        cpX,cpY,cpZ=x,y,z; cpActive=true
        ap_path=nil; ap_useNavPath=false; ap_directFails=0; ap_building=false
        gps_path=nil; gps_building=false; gps_pending=false
        lua_thread.create(function()
            wait(300)
            local okP,px,py=pcall(getCharCoordinates,PLAYER_PED)
            if okP and type(px)=='number' then buildGpsRoute(px,py) end
        end)
        if autopilot and nav_loaded then
            lua_thread.create(function()
                wait(300)
                local px,py,pz=getCharCoordinates(PLAYER_PED)
                if type(px)=='number' then buildRoute(px,py,pz) end
            end)
        end
    end
end

function sampev.onDisableCheckpoint()
    cpActive=false; ap_path=nil; ap_building=false; ap_useNavPath=false; ap_directFails=0
    gps_path=nil; gps_building=false; gps_pending=false
end

function sampev.onDisableRaceCheckpoint()
    cpActive=false; ap_path=nil; ap_building=false; ap_useNavPath=false; ap_directFails=0
    gps_path=nil; gps_building=false; gps_pending=false
end

local fontMain = nil
local fontBig  = nil

imgui.OnInitialize(function()
    imgui.SwitchContext()
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)

    local io2    = imgui.GetIO()
    local ranges = io2.Fonts:GetGlyphRangesCyrillic()
    local fpath  = getWorkingDirectory() .. '/../trebucbd.ttf'

    if doesFileExist(fpath) then
        fontMain = io2.Fonts:AddFontFromFileTTF(fpath, 14 * MDS, nil, ranges)
        fontBig  = io2.Fonts:AddFontFromFileTTF(fpath, 17 * MDS, nil, ranges)
    end

    local cfg2 = imgui.ImFontConfig()
    cfg2.MergeMode  = true
    cfg2.PixelSnapH = true
    local rng = imgui.new.ImWchar[3](faR.min_range, faR.max_range, 0)
    io2.Fonts:AddFontFromMemoryCompressedBase85TTF(
        faR.get_font_data_base85('solid'), 15 * MDS, cfg2, rng)

    local st = imgui.GetStyle()
    st.WindowRounding   = 8  * MDS
    st.FrameRounding    = 4  * MDS
    st.ItemSpacing      = imgui.ImVec2(8 * MDS, 6 * MDS)
    st.WindowBorderSize = 1.0 * MDS

    imgui.PushStyleColor(imgui.Col.WindowBg,        imgui.ImVec4(0.059, 0.059, 0.059, 0.97))
    imgui.PushStyleColor(imgui.Col.Border,          imgui.ImVec4(1.00,  0.30,  0.30,  0.25))
    imgui.PushStyleColor(imgui.Col.FrameBg,         imgui.ImVec4(0.10,  0.10,  0.10,  1.00))
    imgui.PushStyleColor(imgui.Col.FrameBgHovered,  imgui.ImVec4(0.14,  0.14,  0.14,  1.00))
    imgui.PushStyleColor(imgui.Col.TitleBg,         imgui.ImVec4(0.06,  0.06,  0.06,  1.00))
    imgui.PushStyleColor(imgui.Col.TitleBgActive,   imgui.ImVec4(0.06,  0.06,  0.06,  1.00))
    imgui.PushStyleColor(imgui.Col.Button,          imgui.ImVec4(0.14,  0.14,  0.14,  1.00))
    imgui.PushStyleColor(imgui.Col.ButtonHovered,   imgui.ImVec4(0.55,  0.10,  0.10,  1.00))
    imgui.PushStyleColor(imgui.Col.ButtonActive,    imgui.ImVec4(0.40,  0.06,  0.06,  1.00))
    imgui.PushStyleColor(imgui.Col.CheckMark,       imgui.ImVec4(1.00,  0.30,  0.30,  1.00))
    imgui.PushStyleColor(imgui.Col.Header,          imgui.ImVec4(0.55,  0.10,  0.10,  0.70))
    imgui.PushStyleColor(imgui.Col.HeaderHovered,   imgui.ImVec4(0.70,  0.12,  0.12,  0.90))
    imgui.PushStyleColor(imgui.Col.Separator,       imgui.ImVec4(1.00,  1.00,  1.00,  0.10))
    imgui.PushStyleColor(imgui.Col.Text,            imgui.ImVec4(0.90,  0.90,  0.90,  1.00))
    imgui.PushStyleColor(imgui.Col.TextDisabled,    imgui.ImVec4(0.45,  0.45,  0.45,  1.00))
    imgui.PushStyleColor(imgui.Col.ScrollbarBg,     imgui.ImVec4(0.05,  0.05,  0.05,  0.50))
    imgui.PushStyleColor(imgui.Col.ScrollbarGrab,   imgui.ImVec4(1.00,  0.30,  0.30,  0.60))
    imgui.PushStyleColor(imgui.Col.ScrollbarGrabHovered, imgui.ImVec4(1.00, 0.30, 0.30, 0.90))
end)

imgui.OnFrame(
    function() return gpsLine and cpActive end,
    function(self)
        self.HideCursor = true
        local dl = imgui.GetForegroundDrawList()
        local ok1, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
        if not ok1 or type(px) ~= 'number' then return end

        local function inFront(wx, wy, wz)
            local ok, cx, cy, cz, lx, ly, lz = pcall(getCameraMatrix)
            if not ok or not cx then return true end
            return (lx-cx)*(wx-cx) + (ly-cy)*(wy-cy) + (lz-cz)*(wz-cz) > 0
        end
        local function proj(wx, wy, wz)
            if not inFront(wx, wy, wz) then return nil end
            local ok, sx, sy = pcall(convert3DCoordsToScreen, wx, wy, wz)
            if not ok or type(sx) ~= 'number' or type(sy) ~= 'number' then return nil end
            if sx < -200 or sx > sw+200 or sy < -200 or sy > sh+200 then return nil end
            return sx, sy
        end

        local colLine  = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.30, 0.30, 0.85))
        local colRed   = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
        local colWhite = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
        local lw = 3.0 * MDS

        local originX, originY
        local okS, spx, spy = pcall(convert3DCoordsToScreen, px, py, pz + 0.5)
        if okS and type(spx) == 'number' then
            originX = spx; originY = spy
        else
            originX = sw * 0.5; originY = sh * 0.78
        end

        -- draw the actual A* route if one was built; otherwise fall back to a
        -- straight line toward the checkpoint
        local drewRoute = false
        if gps_path and #gps_path > 1 then
            local prevX, prevY = originX, originY
            local havePrev = true
            for _, wp in ipairs(gps_path) do
                local sxN, syN = proj(wp.x, wp.y, (wp.z or pz) + 1.0)
                if sxN and havePrev then
                    dl:AddLine(imgui.ImVec2(prevX, prevY), imgui.ImVec2(sxN, syN), colLine, lw)
                end
                if sxN then prevX, prevY = sxN, syN; havePrev = true
                else havePrev = false end
            end
            drewRoute = true
        end

        local sx2, sy2 = proj(cpX, cpY, cpZ + 1.5)
        if sx2 and not drewRoute then
            dl:AddLine(imgui.ImVec2(originX, originY), imgui.ImVec2(sx2, sy2), colLine, lw)
        end
        dl:AddCircle(imgui.ImVec2(originX, originY), 5*MDS, colRed, 16, lw)
        dl:AddCircleFilled(imgui.ImVec2(originX, originY), 2.5*MDS, colRed, 16)
        if sx2 then
            dl:AddCircle(imgui.ImVec2(sx2, sy2), 8*MDS, colWhite, 16, lw)
            dl:AddCircleFilled(imgui.ImVec2(sx2, sy2), 3*MDS, colWhite, 8)
        end
    end
)

imgui.OnFrame(
    function() return gpsLine and cpActive end,
    function(self)
        self.HideCursor = true
        if fontMain then imgui.PushFont(fontMain) end
        local HW = 88*MDS; local HH = 24*MDS
        imgui.SetNextWindowPos(imgui.ImVec2(6*MDS, sh * 0.73), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(HW, HH), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.03, 0.03, 0.88))
        imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(1.00, 0.30, 0.30, 0.55))
        imgui.Begin('##gpshud', nil,
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoMove     + imgui.WindowFlags.NoScrollbar)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
        imgui.Text('GPS')
        imgui.PopStyleColor()
        imgui.SameLine(0, 5*MDS)
        local ok1, px, py = pcall(getCharCoordinates, PLAYER_PED)
        if ok1 and type(px) == 'number' then
            local dist = math.floor(getDistanceBetweenCoords2d(px, py, cpX, cpY))
            local distStr = dist >= 1000 and string.format('%.1f km', dist/1000) or tostring(dist)..' m'
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 0.50, 1.00))
            imgui.Text(distStr)
            imgui.PopStyleColor()
        end
        imgui.End()
        imgui.PopStyleColor(2)
        if fontMain then imgui.PopFont() end
    end
)

imgui.OnFrame(
    function() return stats_visible end,
    function(self)
        self.HideCursor = true
        if fontMain then imgui.PushFont(fontMain) end
        local SW2 = 130*MDS; local SH2 = 46*MDS
        imgui.SetNextWindowPos(imgui.ImVec2(8*MDS, sh*0.58), imgui.Cond.Once)
        imgui.SetNextWindowSize(imgui.ImVec2(SW2, SH2), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.03, 0.03, 0.90))
        imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(1.00, 0.30, 0.30, 0.45))
        imgui.Begin('##statshud', nil,
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoMove)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
        imgui.Text(fa.MONEY_BILL_WAVE)
        imgui.PopStyleColor()
        imgui.SameLine(0, 4*MDS)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.20, 1.00, 0.40, 1.00))
        imgui.Text('$'..tostring(zarp))
        imgui.PopStyleColor()
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
        imgui.Text(fa.BOX)
        imgui.PopStyleColor()
        imgui.SameLine(0, 4*MDS)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.85, 0.20, 1.00))
        imgui.Text(u8('\xcb\xe0\xf0\xf6\xee\xe2: ')..tostring(larec))
        imgui.PopStyleColor()
        imgui.End()
        imgui.PopStyleColor(2)
        if fontMain then imgui.PopFont() end
    end
)

local VK_NAMES = {
    [0x30]='0',[0x31]='1',[0x32]='2',[0x33]='3',[0x34]='4',[0x35]='5',
    [0x36]='6',[0x37]='7',[0x38]='8',[0x39]='9',
    [0x41]='A',[0x42]='B',[0x43]='C',[0x44]='D',[0x45]='E',[0x46]='F',
    [0x47]='G',[0x48]='H',[0x49]='I',[0x4A]='J',[0x4B]='K',[0x4C]='L',
    [0x4D]='M',[0x4E]='N',[0x4F]='O',[0x50]='P',[0x51]='Q',[0x52]='R',
    [0x53]='S',[0x54]='T',[0x55]='U',[0x56]='V',[0x57]='W',[0x58]='X',
    [0x59]='Y',[0x5A]='Z',[0x70]='F1',[0x71]='F2',[0x72]='F3',[0x73]='F4',
    [0x74]='F5',[0x75]='F6',[0x76]='F7',[0x77]='F8',[0x78]='F9',
    [0x79]='F10',[0x7A]='F11',[0x7B]='F12',
    [0x60]='NUM0',[0x61]='NUM1',[0x62]='NUM2',[0x63]='NUM3',[0x64]='NUM4',
    [0x65]='NUM5',[0x66]='NUM6',[0x67]='NUM7',[0x68]='NUM8',[0x69]='NUM9',
}
local function vkName(vk) return VK_NAMES[vk] or string.format('0x%02X', vk) end
local waiting_for_key = false
local activeTab = 1
local logoTex   = nil
local logoReady = false

local ig_gruz_index    = imgui.new.int(gruz_index)
local ig_ap_speed      = imgui.new.int(ap_speed)
local ig_ap_steer      = imgui.new.int(ap_steer)
local ig_ap_turn_speed = imgui.new.int(ap_turn_speed)
local settingsOpen     = imgui.new.bool(false)
local menuOpen         = imgui.new.bool(false)

imgui.OnFrame(
    function() return waiting_for_key end,
    function(self)
        self.HideCursor = false
        if fontMain then imgui.PushFont(fontMain) end
        local W = 260*MDS; local H = 52*MDS
        imgui.SetNextWindowPos(imgui.ImVec2((sw-W)*0.5, sh*0.4), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(W, H), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06,0.03,0.03,0.96))
        imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(1.00,0.30,0.30,0.80))
        imgui.Begin('##waitkey', nil,
            imgui.WindowFlags.NoTitleBar+imgui.WindowFlags.NoResize+
            imgui.WindowFlags.NoMove+imgui.WindowFlags.NoScrollbar)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00,0.30,0.30,1.00))
        imgui.Text(fa.KEYBOARD)
        imgui.PopStyleColor()
        imgui.SameLine(0,6*MDS)
        imgui.Text(u8('\xcd\xe0\xe6\xec\xe8\xf2\xe5 \xea\xeb\xe0\xe2\xe8\xf8\xf3 \xe4\xeb\xff \xe4\xee\xec\xea\xf0\xe0\xf2\xe0... (ESC = \xee\xf2\xec\xe5\xed\xe0)'))
        imgui.End()
        imgui.PopStyleColor(2)
        if fontMain then imgui.PopFont() end
    end
)

imgui.OnFrame(
    function() return attach_btn and atr_selecting and not IS_MOBILE end,
    function(self)
        self.HideCursor = true
        local dl  = imgui.GetForegroundDrawList()
        local ox  = sw/2 - ATR_RADIUS/2
        local oy  = sh/3.3 - ATR_RADIUS/2
        local cc  = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00,1.00,1.00,0.85))
        local tk  = 2.0
        dl:AddLine(imgui.ImVec2(ox,            oy),            imgui.ImVec2(ox+ATR_RADIUS,oy),            cc,tk)
        dl:AddLine(imgui.ImVec2(ox,            oy),            imgui.ImVec2(ox,            oy+ATR_RADIUS), cc,tk)
        dl:AddLine(imgui.ImVec2(ox,            oy+ATR_RADIUS), imgui.ImVec2(ox+ATR_RADIUS,oy+ATR_RADIUS), cc,tk)
        dl:AddLine(imgui.ImVec2(ox+ATR_RADIUS, oy),            imgui.ImVec2(ox+ATR_RADIUS,oy+ATR_RADIUS), cc,tk)
        if atr_trailer and doesVehicleExist(atr_trailer) then
            local ok3,vx3,vy3,vz3 = pcall(getCarCoordinates, atr_trailer)
            if ok3 then
                local ok4,sx3,sy3 = pcall(convert3DCoordsToScreen,vx3,vy3,vz3)
                if ok4 and sx3 and sy3 then
                    local cy2 = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00,0.30,0.30,0.95))
                    dl:AddLine(imgui.ImVec2(sx3,sy3), imgui.ImVec2(ox+ATR_RADIUS/2,oy+ATR_RADIUS/2), cy2, 2.0)
                    dl:AddCircle(imgui.ImVec2(sx3,sy3), 9, cy2, 16, 2.0)
                end
            end
        end
    end
)

imgui.OnFrame(
    function() return licWinOpen[0] end,
    function(self)
        self.HideCursor = false
        local W = 370*MDS; local H = 190*MDS
        imgui.SetNextWindowSize(imgui.ImVec2(W,H), imgui.Cond.Always)
        imgui.SetNextWindowPos(imgui.ImVec2((sw-W)*0.5,(sh-H)*0.5), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.059,0.059,0.059,0.98))
        imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(1.00,1.00,1.00,0.10))
        imgui.Begin(u8('##LicWinTH'), licWinOpen,
            imgui.WindowFlags.NoTitleBar+imgui.WindowFlags.NoResize+
            imgui.WindowFlags.NoScrollbar+imgui.WindowFlags.NoMove)
        local DL = imgui.GetWindowDrawList()
        local WP = imgui.GetWindowPos()
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+W,WP.y+H),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.059,0.059,0.059,0.99)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.106,0.157,0.216,0.99)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.086,0.102,0.129,0.99)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.059,0.059,0.059,0.99)))
        DL:AddRectFilled(imgui.ImVec2(WP.x,WP.y),imgui.ImVec2(WP.x+W,WP.y+3*MDS),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00,0.30,0.30,1.00)))
        if fontMain then imgui.PushFont(fontMain) end
        local pad=14*MDS
        imgui.SetCursorPos(imgui.ImVec2(pad,12*MDS))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(1.00,0.30,0.30,1.00))
        imgui.Text(u8('\xca\xeb\xfe\xf7 \xeb\xe8\xf6\xe5\xed\xe7\xe8\xe8  Truck Helper PRO'))
        imgui.PopStyleColor()
        imgui.SetCursorPos(imgui.ImVec2(pad,32*MDS))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(0.60,0.60,0.60,1.00))
        imgui.Text(u8('\xcf\xee\xeb\xf3\xf7\xe8\xf2\xfc \xea\xeb\xfe\xf7: @victor_st0'))
        imgui.PopStyleColor()
        imgui.SetCursorPos(imgui.ImVec2(pad,54*MDS))
        imgui.PushItemWidth(W-pad*2)
        imgui.InputText(u8('##thkey'),licInputBuf,64)
        imgui.PopItemWidth()
        if licenseMsg~='' then
            imgui.SetCursorPos(imgui.ImVec2(pad,84*MDS))
            local mc = licenseChecking and imgui.ImVec4(0.90,0.85,0.25,1.00) or imgui.ImVec4(1.00,0.35,0.35,1.00)
            imgui.PushStyleColor(imgui.Col.Text,mc)
            imgui.Text(licenseMsg)
            imgui.PopStyleColor()
        end
        local bY=112*MDS; local bW1=(W-pad*2-6*MDS)*0.62; local bW2=W-pad*2-bW1-6*MDS; local bH=36*MDS
        imgui.SetCursorPos(imgui.ImVec2(pad,bY))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.04,0.35,0.07,1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.06,0.50,0.10,1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.02,0.22,0.05,1.0))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.78,1.00,0.80,1.0))
        if imgui.Button(u8('\xc0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xf2\xfc##thlic'),imgui.ImVec2(bW1,bH)) then
            local k=bufToStr(licInputBuf,64):match('^%s*(.-)%s*$')
            if #k>3 then checkLicenseAsync(k) else licenseMsg=u8('\xc2\xe2\xe5\xe4\xe8\xf2\xe5 \xea\xeb\xfe\xf7') end
        end
        imgui.PopStyleColor(4)
        imgui.SameLine(0,6*MDS)
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.25,0.06,0.06,1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.45,0.10,0.10,1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.18,0.03,0.03,1.0))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.00,0.55,0.55,1.0))
        if imgui.Button(u8('\xc7\xe0\xea\xf0\xfb\xf2\xfc##thlicclose'),imgui.ImVec2(bW2,bH)) then
            licWinOpen[0]=false
        end
        imgui.PopStyleColor(4)
        if fontMain then imgui.PopFont() end
        imgui.End()
        imgui.PopStyleColor(2)
    end
)

imgui.OnFrame(
    function() return settingsOpen[0] end,
    function(self)
        self.HideCursor=false
        if fontMain then imgui.PushFont(fontMain) end
        local SW=440*MDS; local SH=300*MDS
        imgui.SetNextWindowSize(imgui.ImVec2(SW,SH),imgui.Cond.Always)
        imgui.SetNextWindowPos(imgui.ImVec2((sw-SW)*0.5,(sh-SH)*0.5+60*MDS),imgui.Cond.Once)
        imgui.PushStyleColor(imgui.Col.WindowBg,imgui.ImVec4(0.059,0.059,0.059,0.98))
        imgui.PushStyleColor(imgui.Col.Border,  imgui.ImVec4(1.00,1.00,1.00,0.10))
        imgui.Begin(u8('##apset'),settingsOpen,
            imgui.WindowFlags.NoTitleBar+imgui.WindowFlags.NoScrollbar+imgui.WindowFlags.NoResize)
        local dls=imgui.GetWindowDrawList(); local wps=imgui.GetWindowPos()
        dls:AddRectFilledMultiColor(imgui.ImVec2(wps.x,wps.y),imgui.ImVec2(wps.x+SW,wps.y+36*MDS),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.106,0.157,0.220,1.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.545,0.176,0.176,1.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.545,0.176,0.176,1.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.106,0.157,0.220,1.0)))
        if fontBig then imgui.PushFont(fontBig) end
        local stT=fa.GEAR..'  '..u8('\xcd\xe0\xf1\xf2\xf0\xee\xe9\xea\xe8 \xe0\xe2\xf2\xee\xef\xe8\xeb\xee\xf2\xe0')
        local stSz=imgui.CalcTextSize(stT)
        imgui.SetCursorPos(imgui.ImVec2((SW-stSz.x)*0.5,(36*MDS-stSz.y)*0.5))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(1.00,1.00,1.00,1.00))
        imgui.Text(stT); imgui.PopStyleColor()
        if fontBig then imgui.PopFont() end
        imgui.SetCursorPos(imgui.ImVec2(SW-30*MDS,7*MDS))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(1.00,1.00,1.00,0.08))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00,0.30,0.30,1.00))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.70,0.10,0.10,1.00))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.00,1.00,1.00,0.60))
        if imgui.Button(fa.XMARK..'##st',imgui.ImVec2(22*MDS,22*MDS)) then settingsOpen[0]=false end
        imgui.PopStyleColor(4)
        imgui.SetCursorPos(imgui.ImVec2(10*MDS,44*MDS))
        local slW=SW-20*MDS
        local navStr=nav_loaded and ('  ['..tostring(nav_count)..' nodes]')
            or (nav_loading and u8('  [\xe7\xe0\xe3\xf0\xf3\xe7\xea\xe0...]') or u8('  [\xed\xe5\xf2 \xe4\xe0\xed\xed\xfb\xf5]'))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(0.65,0.65,0.65,1.0))
        imgui.Text(fa.GAUGE_HIGH..'  '..u8('\xd1\xea\xee\xf0\xee\xf1\xf2\xfc (\xea\xec/\xf7): ')..tostring(ap_speed)..navStr)
        imgui.PopStyleColor()
        imgui.PushItemWidth(slW)
        imgui.PushStyleColor(imgui.Col.FrameBg,          imgui.ImVec4(0.10,0.10,0.10,1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab,       imgui.ImVec4(1.00,0.30,0.30,1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.80,0.10,0.10,1.0))
        if imgui.SliderInt(u8('##apspeed'),ig_ap_speed,10,200) then ap_speed=ig_ap_speed[0]; saveCfg() end
        imgui.PopStyleColor(3); imgui.PopItemWidth()
        imgui.Spacing()
        local speeds={40,60,80,100,120}; local gap3=3*MDS; local bwS=(slW-gap3*(#speeds-1))/#speeds
        for i,s in ipairs(speeds) do
            if i>1 then imgui.SameLine(0,gap3) end
            local isSpd=(ap_speed==s)
            if isSpd then imgui.PushStyleColor(imgui.Col.Button,imgui.ImVec4(0.54,0.10,0.10,1.0))
                          imgui.PushStyleColor(imgui.Col.ButtonHovered,imgui.ImVec4(0.75,0.13,0.13,1.0))
                          imgui.PushStyleColor(imgui.Col.ButtonActive,imgui.ImVec4(0.38,0.06,0.06,1.0)) end
            if imgui.Button(tostring(s),imgui.ImVec2(bwS,30*MDS)) then ap_speed=s; ig_ap_speed[0]=s; saveCfg() end
            if isSpd then imgui.PopStyleColor(3) end
        end
        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col.Separator,imgui.ImVec4(1.0,1.0,1.0,0.08)); imgui.Separator(); imgui.PopStyleColor()
        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(0.65,0.65,0.65,1.0))
        imgui.Text(fa.ROTATE_RIGHT..'  '..u8('\xd3\xe3\xee\xeb \xef\xee\xe2\xee\xf0\xee\xf2\xe0: ')..tostring(ap_steer))
        imgui.PopStyleColor()
        imgui.PushItemWidth(slW)
        imgui.PushStyleColor(imgui.Col.FrameBg,          imgui.ImVec4(0.10,0.10,0.10,1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab,       imgui.ImVec4(1.00,0.30,0.30,1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.80,0.10,0.10,1.0))
        if imgui.SliderInt(u8('##apsteer'),ig_ap_steer,1,100) then ap_steer=ig_ap_steer[0]; saveCfg() end
        imgui.PopStyleColor(3); imgui.PopItemWidth()
        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(0.65,0.65,0.65,1.0))
        imgui.Text(fa.ROTATE_RIGHT..'  '..u8('\xd1\xea\xee\xf0\xee\xf1\xf2\xfc \xef\xe5\xf0\xe5\xe4 \xef\xee\xe2\xee\xf0\xee\xf2\xee\xec: ')..tostring(ap_turn_speed)..u8(' \xea\xec/\xf7'))
        imgui.PopStyleColor()
        imgui.PushItemWidth(slW)
        imgui.PushStyleColor(imgui.Col.FrameBg,          imgui.ImVec4(0.10,0.10,0.10,1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab,       imgui.ImVec4(1.00,0.30,0.30,1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.80,0.10,0.10,1.0))
        if imgui.SliderInt(u8('##apturn'),ig_ap_turn_speed,10,80) then
            ap_turn_speed=ig_ap_turn_speed[0]
            if ap_turn_speed>ap_speed then ap_turn_speed=ap_speed; ig_ap_turn_speed[0]=ap_speed end
            saveCfg()
        end
        imgui.PopStyleColor(3); imgui.PopItemWidth()
        imgui.End(); imgui.PopStyleColor(2)
        if fontMain then imgui.PopFont() end
    end
)

local editWinOpen = imgui.new.bool(false)
local ig_edit_atr_x = imgui.new.int(math.floor(atr_posX))
local ig_edit_atr_y = imgui.new.int(math.floor(atr_posY))
local ig_edit_dk_x  = imgui.new.int(math.floor(domkrat_posX))
local ig_edit_dk_y  = imgui.new.int(math.floor(domkrat_posY))

local function syncEditSliders()
    ig_edit_atr_x[0] = math.floor(atr_posX)
    ig_edit_atr_y[0] = math.floor(atr_posY)
    ig_edit_dk_x[0]  = math.floor(domkrat_posX)
    ig_edit_dk_y[0]  = math.floor(domkrat_posY)
end

local WIN_W    = 440 * MDS
local HEADER_H = 52  * MDS
local TAB_H    = 32  * MDS
local SEP_H    = 6   * MDS
local PADB     = 10  * MDS
local SCROLL_H = 390 * MDS

local function getWinH()
    if activeTab == 1 then
        return HEADER_H + TAB_H + SEP_H + SCROLL_H + PADB
    elseif activeTab == 2 then
        local sp = 7*MDS; local row = 34*MDS
        return HEADER_H + TAB_H + SEP_H + 4*22*MDS + 3*sp + 2*row + sp + PADB
    else
        local sp = 7*MDS; local row = 34*MDS
        return HEADER_H + TAB_H + SEP_H + 6*22*MDS + 4*sp + 3*row + sp + PADB
    end
end

local function toggleBtn(label, enabled, w, h)
    if enabled then
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.54, 0.10, 0.10, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.75, 0.13, 0.13, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.38, 0.06, 0.06, 1.0))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.00, 0.85, 0.85, 1.0))
    else
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.14, 0.14, 0.14, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.22, 0.22, 0.22, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.10, 0.10, 0.10, 1.0))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.65, 0.65, 0.65, 1.0))
    end
    local bW = w or ((WIN_W - 22*MDS) * 0.5)
    local bH = h or 34*MDS
    local clicked = imgui.Button(label, imgui.ImVec2(bW, bH))
    imgui.PopStyleColor(4)
    return clicked
end

local function editBtn(label, w, h)
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.12, 0.12, 0.12, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.54, 0.10, 0.10, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.38, 0.06, 0.06, 1.0))
    imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.75, 0.75, 0.75, 1.0))
    local clicked = imgui.Button(label, imgui.ImVec2(w, h))
    imgui.PopStyleColor(4)
    return clicked
end

local function tabBtn(label, idx, w)
    if activeTab == idx then
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.54, 0.10, 0.10, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.70, 0.13, 0.13, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.38, 0.06, 0.06, 1.0))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.00, 1.00, 1.00, 1.0))
    else
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.08, 0.08, 0.08, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.16, 0.16, 0.16, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.06, 0.06, 0.06, 1.0))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.44, 0.44, 0.44, 1.0))
    end
    local clicked = imgui.Button(label, imgui.ImVec2(w, 28*MDS))
    imgui.PopStyleColor(4)
    imgui.SameLine(0, 3*MDS)
    return clicked
end

imgui.OnFrame(
    function() return menuOpen[0] end,
    function(self)
        self.HideCursor = false
        if fontMain then imgui.PushFont(fontMain) end

        local wh = getWinH()
        imgui.SetNextWindowSize(imgui.ImVec2(WIN_W, wh), imgui.Cond.Always)
        imgui.SetNextWindowPos(
            imgui.ImVec2((sw - WIN_W) * 0.5, (sh - wh) * 0.5),
            imgui.Cond.Once)

        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.059, 0.059, 0.059, 0.98))
        imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(1.00,  1.00,  1.00,  0.08))

        imgui.Begin(u8('##TH_FREE'), menuOpen,
            imgui.WindowFlags.NoTitleBar  +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoResize)

        local dl = imgui.GetWindowDrawList()
        local wp = imgui.GetWindowPos()

        dl:AddRectFilledMultiColor(
            imgui.ImVec2(wp.x,       wp.y),
            imgui.ImVec2(wp.x+WIN_W, wp.y+HEADER_H),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.106, 0.157, 0.220, 1.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.545, 0.176, 0.176, 1.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.545, 0.176, 0.176, 1.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.106, 0.157, 0.220, 1.0)))
        dl:AddLine(
            imgui.ImVec2(wp.x,       wp.y+HEADER_H),
            imgui.ImVec2(wp.x+WIN_W, wp.y+HEADER_H),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 1.00, 1.00, 0.10)), 1.0*MDS)

        if fontBig then imgui.PushFont(fontBig) end
        local title1 = 'TRUCK HELPER'
        local title2 = '  |  FREE'
        local tsz1 = imgui.CalcTextSize(title1)
        local tsz2 = imgui.CalcTextSize(title2)
        local totalW = tsz1.x + tsz2.x
        local startX = (WIN_W - totalW) * 0.5
        local textY  = (HEADER_H - tsz1.y) * 0.5

        imgui.SetCursorPos(imgui.ImVec2(startX, textY))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
        imgui.Text(title1)
        imgui.PopStyleColor()
        if fontBig then imgui.PopFont() end

        imgui.SameLine(0, 0)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
        imgui.Text(title2)
        imgui.PopStyleColor()

        imgui.SetCursorPos(imgui.ImVec2(WIN_W - 34*MDS, (HEADER_H - 22*MDS) * 0.5))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(1.00, 1.00, 1.00, 0.08))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.70, 0.10, 0.10, 1.00))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.00, 1.00, 1.00, 0.60))
        if imgui.Button(fa.XMARK .. '##close', imgui.ImVec2(22*MDS, 22*MDS)) then
            menuOpen[0] = false
        end
        imgui.PopStyleColor(4)

        imgui.SetCursorPos(imgui.ImVec2(10*MDS, HEADER_H + 4*MDS))
        local tW = (WIN_W - 23*MDS) / 3
        if tabBtn(fa.SLIDERS     .. '  ' .. u8('\xd4\xf3\xed\xea\xf6\xe8\xe8'),             1, tW) then activeTab = 1 end
        if tabBtn(fa.CHART_BAR   .. '  ' .. u8('\xd1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xe0'), 2, tW) then activeTab = 2 end
        if tabBtn(fa.CIRCLE_INFO .. '  ' .. u8('\xce \xf1\xea\xf0\xe8\xef\xf2\xe5'),         3, tW) then activeTab = 3 end

        imgui.NewLine()
        imgui.SetCursorPos(imgui.ImVec2(10*MDS, HEADER_H + TAB_H + 2*MDS))
        imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(1.0, 1.0, 1.0, 0.08))
        imgui.Separator()
        imgui.PopStyleColor()

        imgui.SetCursorPos(imgui.ImVec2(10*MDS, HEADER_H + TAB_H + SEP_H + 2*MDS))
        local bW2 = (WIN_W - 22*MDS) * 0.5

        if activeTab == 1 then
            imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0,0,0,0))
            imgui.BeginChild('##tab1scroll', imgui.ImVec2(WIN_W - 10*MDS, SCROLL_H), false,
                imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)

            if toggleBtn(fa.SHIELD .. '  Anti CarSkill ' .. (anticarskill and '[ON]' or '[OFF]'), anticarskill, bW2) then
                anticarskill = not anticarskill
                toggleNotify('Anti CarSkill', anticarskill)
                saveCfg()
            end
            imgui.SameLine(0, 4*MDS)
            if toggleBtn(fa.BOX_OPEN .. '  ' .. u8('\xc0\xe2\xf2\xee-\xe3\xf0\xf3\xe7 ') .. (autogruz and '[ON]' or '[OFF]'), autogruz, bW2) then
                autogruz = not autogruz
                toggleNotify('\xc0\xe2\xf2\xee-\xe3\xf0\xf3\xe7', autogruz)
                saveCfg()
            end

            imgui.Spacing()

            if toggleBtn(fa.ROUTE .. '  GPS ' .. (gpsLine and '[ON]' or '[OFF]'), gpsLine, bW2) then
                gpsLine = not gpsLine
                toggleNotify('GPS', gpsLine)
                saveCfg()
            end
            imgui.SameLine(0, 4*MDS)
            if toggleBtn(fa.TRAFFIC_LIGHT .. '  ' .. u8('\xc0\xe2\xf2\xee-\xf8\xeb\xe0\xe3\xe1 ') .. (autogate and '[ON]' or '[OFF]'), autogate, bW2) then
                autogate = not autogate
                toggleNotify('\xc0\xe2\xf2\xee-\xf8\xeb\xe0\xe3\xe1\xe0\xf3\xec', autogate)
                saveCfg()
            end

            imgui.Spacing()

            if toggleBtn(fa.TRUCK .. '  ' .. u8('\xcf\xf0\xe8\xf6\xe5\xef ') .. (attach_btn and '[ON]' or '[OFF]'), attach_btn, bW2) then
                attach_btn = not attach_btn
                toggleNotify('\xca\xed\xee\xef\xea\xe0 \xef\xf0\xe8\xf6\xe5\xef\xe0', attach_btn)
                saveCfg()
            end
            imgui.SameLine(0, 4*MDS)
            if toggleBtn(fa.CAR_BURST .. '  ' .. u8('\xc4\xce\xcc\xca\xd0\xc0\xd2 ') .. (domkrat_btn and '[ON]' or '[OFF]'), domkrat_btn, bW2) then
                domkrat_btn = not domkrat_btn
                toggleNotify('\xca\xed. \xc4\xce\xcc\xca\xd0\xc0\xd2', domkrat_btn)
                saveCfg()
            end

            if not IS_MOBILE then
                imgui.Spacing()
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.65, 0.65, 0.65, 1.0))
                imgui.Text(fa.KEYBOARD .. '  ' .. u8('\xca\xeb\xe0\xe2\xe8\xf8\xe0 \xe4\xee\xec\xea\xf0\xe0\xf2\xe0:'))
                imgui.PopStyleColor()
                imgui.SameLine(0, 8*MDS)
                local keyLabel = domkrat_key > 0 and ('['..vkName(domkrat_key)..']') or u8('[\xed\xe5 \xe7\xe0\xe4\xe0\xed\xe0]')
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.14,0.14,0.14,1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.54,0.10,0.10,1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.38,0.06,0.06,1.0))
                imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.00,0.85,0.85,1.0))
                if imgui.Button(keyLabel..'##dkkey', imgui.ImVec2(80*MDS, 26*MDS)) then
                    waiting_for_key = true
                end
                imgui.PopStyleColor(4)
                imgui.SameLine(0,4*MDS)
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.50,0.50,0.50,1.0))
                imgui.Text(u8('(\xcb\xca\xcc/\xcf\xca\xcc = \xef\xf0\xe8\xf6\xe5\xef)'))
                imgui.PopStyleColor()
            end

            imgui.Spacing()

            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.65, 0.65, 0.65, 1.0))
            imgui.Text(fa.LIST_OL .. '  ' .. u8('\xc3\xf0\xf3\xe7 (#, 0=') .. u8('\xcf\xee\xf1\xeb\xe5\xe4\xed\xe8\xe9') .. '):')
            imgui.PopStyleColor()
            imgui.SameLine()
            imgui.PushItemWidth(80*MDS)
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.10, 0.10, 0.10, 1.0))
            if imgui.InputInt(u8('##gi'), ig_gruz_index) then
                if ig_gruz_index[0] < 0 then ig_gruz_index[0] = 0 end
                gruz_index = ig_gruz_index[0]
                saveCfg()
            end
            imgui.PopStyleColor()
            imgui.PopItemWidth()

            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(1.0, 1.0, 1.0, 0.08))
            imgui.Separator()
            imgui.PopStyleColor()
            imgui.Spacing()

            imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(1.0,1.0,1.0,0.08))
            imgui.Separator()
            imgui.PopStyleColor()
            imgui.Spacing()

            if toggleBtn(fa.ROUTE .. '  ' .. u8('\xc0\xe2\xf2\xee\xef\xe8\xeb\xee\xf2 ') .. (autopilot and '[ON]' or '[OFF]'), autopilot, bW2) then
                if licenseOK then
                    if autopilot then disableAutopilot() else enableAutopilot() end
                else
                    licWinOpen[0] = true
                end
            end
            imgui.SameLine(0, 4*MDS)
            if toggleBtn(fa.LINK .. '  ' .. u8('\xc0\xed\xf2\xe8-\xee\xf2\xf6\xe5\xef ') .. (antiDetach and '[ON]' or '[OFF]'), antiDetach, bW2) then
                if licenseOK then
                    antiDetach = not antiDetach
                    if antiDetach then antiDetach_veh = nil end
                    toggleNotify('\xc0\xed\xf2\xe8-\xee\xf2\xf6\xe5\xef', antiDetach)
                    saveCfg()
                else
                    licWinOpen[0] = true
                end
            end

            imgui.Spacing()
            if toggleBtn(fa.CAR_BURST .. '  ' .. u8('\xcd\xee\xea\xee\xeb. \xee\xe1\xfa\xe5\xea\xf2\xee\xe2 ') .. (nocollision and '[ON]' or '[OFF]'), nocollision, WIN_W - 20*MDS, 30*MDS) then
                if licenseOK then
                    nocollision = not nocollision
                    toggleNotify('\xcd\xee\xea\xee\xeb\xeb\xe8\xe7\xe8\xff', nocollision)
                    saveCfg()
                else
                    licWinOpen[0] = true
                end
            end

            imgui.Spacing()
            local navStr = nav_loaded
                and (u8('\xcd\xe0\xe2\xec\xe5\xf8: ') .. tostring(nav_count) .. u8(' \xf3\xe7\xeb\xee\xe2'))
                or (nav_loading and u8('\xcd\xe0\xe2\xec\xe5\xf8: \xe7\xe0\xe3\xf0\xf3\xe7\xea\xe0...')
                                 or u8('\xcd\xe0\xe2\xec\xe5\xf8: \xed\xe5\xf2 \xe4\xe0\xed\xed\xfb\xf5'))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.55,0.55,0.55,1.0))
            imgui.Text(fa.ROUTE .. '  ' .. navStr)
            imgui.PopStyleColor()

            imgui.Spacing()
            if editBtn(fa.GEAR .. '  ' .. u8('\xcd\xe0\xf1\xf2\xf1. \xe0\xe2\xf2\xee\xef\xe8\xeb\xee\xf2\xe0  \xd1\xea.: ')..tostring(ap_speed)..u8('  \xd3\xe3.: ')..tostring(ap_steer), WIN_W-20*MDS, 34*MDS) then
                settingsOpen[0] = not settingsOpen[0]
            end

            imgui.EndChild()
            imgui.PopStyleColor()
        end

        if activeTab == 2 then
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
            imgui.Text(fa.MONEY_BILL_WAVE)
            imgui.PopStyleColor()
            imgui.SameLine()
            imgui.Text(u8('\xc7\xe0\xf0\xe0\xe1\xee\xf2\xe0\xed\xee:'))
            imgui.SameLine()
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.20, 1.00, 0.40, 1.00))
            imgui.Text(string.format('$%d', zarp))
            imgui.PopStyleColor()

            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
            imgui.Text(fa.BOX)
            imgui.PopStyleColor()
            imgui.SameLine()
            imgui.Text(u8('\xcb\xe0\xf0\xf6\xee\xe2 \xef\xee\xeb\xf3\xf7\xe5\xed\xee:'))
            imgui.SameLine()
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.85, 0.20, 1.00))
            imgui.Text(tostring(larec))
            imgui.PopStyleColor()

            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(1.0, 1.0, 1.0, 0.08))
            imgui.Separator()
            imgui.PopStyleColor()
            imgui.Spacing()

            if toggleBtn(
                fa.TABLE_COLUMNS .. '  ' .. u8('\xcc\xe8\xed\xe8-\xee\xea\xed\xee \xf1\xf2\xe0\xf2. ') .. (stats_visible and '[ON]' or '[OFF]'),
                stats_visible, WIN_W - 26*MDS, 34*MDS) then
                stats_visible = not stats_visible
                saveCfg()
            end

            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.26, 0.06, 0.06, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.45, 0.08, 0.08, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.18, 0.03, 0.03, 1.0))
            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.00, 0.70, 0.70, 1.0))
            if imgui.Button(
                fa.TRASH .. '  ' .. u8('\xd1\xe1\xf0\xee\xf1\xe8\xf2\xfc \xf1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xf3'),
                imgui.ImVec2(WIN_W - 26*MDS, 34*MDS)) then
                zarp = 0; larec = 0; saveCfg()
                notify('\xd1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xe0 \xf1\xe1\xf0\xee\xf8\xe5\xed\xe0')
            end
            imgui.PopStyleColor(4)
        end

        if activeTab == 3 then
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.55, 0.55, 0.55, 1.0))
            imgui.Text(fa.USER .. '  ' .. u8('\xc0\xe2\xf2\xee\xf0:'))
            imgui.PopStyleColor()
            imgui.SameLine()
            imgui.Text('Victor Strand')
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.55, 0.55, 0.55, 1.0))
            imgui.Text(fa.CODE_BRANCH .. '  ' .. u8('\xc2\xe5\xf0\xf1\xe8\xff:'))
            imgui.PopStyleColor()
            imgui.SameLine()
            imgui.Text('2.0 PRO')
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Text, licenseOK and imgui.ImVec4(0.20,1.00,0.40,1.00) or imgui.ImVec4(1.00,0.30,0.30,1.00))
            imgui.Text(fa.KEY .. '  ' .. (licenseOK and u8('\xcb\xe8\xf6\xe5\xed\xe7\xe8\xff: \xe0\xea\xf2\xe8\xe2\xed\xe0') or u8('\xcb\xe8\xf6\xe5\xed\xe7\xe8\xff: \xed\xe5 \xe0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xed\xe0')))
            imgui.PopStyleColor()
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(1.0,1.0,1.0,0.08)); imgui.Separator(); imgui.PopStyleColor()
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.14,0.14,0.14,1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.54,0.10,0.10,1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.38,0.06,0.06,1.0))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00,1.00,1.00,1.00))
            if imgui.Button(fa.PAPER_PLANE..'  @victor_st0  ('..u8('\xcc\xee\xe9 \xe0\xea\xea\xe0\xf3\xed\xf2')..')', imgui.ImVec2(WIN_W-26*MDS,34*MDS)) then openLink('https://t.me/victor_st0') end
            imgui.PopStyleColor(4)
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.14,0.14,0.14,1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.54,0.10,0.10,1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.38,0.06,0.06,1.0))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00,1.00,1.00,1.00))
            if imgui.Button(fa.PAPER_PLANE..'  @strand_scripts  ('..u8('\xcc\xee\xe9 \xea\xe0\xed\xe0\xeb')..')', imgui.ImVec2(WIN_W-26*MDS,34*MDS)) then openLink('https://t.me/strand_scripts') end
            imgui.PopStyleColor(4)
            if not licenseOK then
                imgui.Spacing()
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.54,0.10,0.10,1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.75,0.13,0.13,1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.38,0.06,0.06,1.0))
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00,1.00,1.00,1.00))
                if imgui.Button(fa.KEY..'  '..u8('\xc0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xf2\xfc \xeb\xe8\xf6\xe5\xed\xe7\xe8\xfe'), imgui.ImVec2(WIN_W-26*MDS,34*MDS)) then licWinOpen[0]=true end
                imgui.PopStyleColor(4)
            end
        end

        imgui.End()
        imgui.PopStyleColor(2)
        if fontMain then imgui.PopFont() end
    end
)

imgui.OnFrame(
    function() return editWinOpen[0] end,
    function(self)
        self.HideCursor = false
        if fontMain then imgui.PushFont(fontMain) end

        local EW = 400*MDS; local EH = 280*MDS
        imgui.SetNextWindowSize(imgui.ImVec2(EW, EH), imgui.Cond.Always)
        imgui.SetNextWindowPos(
            imgui.ImVec2((sw-EW)*0.5, (sh-EH)*0.5), imgui.Cond.Once)

        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.059, 0.059, 0.059, 0.98))
        imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(1.00,  1.00,  1.00,  0.08))

        imgui.Begin(u8('##editpos'), editWinOpen,
            imgui.WindowFlags.NoTitleBar  +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoResize)

        local dl2 = imgui.GetWindowDrawList()
        local wp2 = imgui.GetWindowPos()
        dl2:AddRectFilledMultiColor(
            imgui.ImVec2(wp2.x, wp2.y),
            imgui.ImVec2(wp2.x+EW, wp2.y+36*MDS),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.106, 0.157, 0.220, 1.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.545, 0.176, 0.176, 1.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.545, 0.176, 0.176, 1.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.106, 0.157, 0.220, 1.0)))
        dl2:AddLine(
            imgui.ImVec2(wp2.x, wp2.y+36*MDS),
            imgui.ImVec2(wp2.x+EW, wp2.y+36*MDS),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 1.00, 1.00, 0.10)), 1.0*MDS)

        if fontBig then imgui.PushFont(fontBig) end
        local titleT = fa.UP_DOWN_LEFT_RIGHT .. '  ' .. u8('\xd0\xe5\xe4\xe0\xea\xf2\xee\xf0 \xef\xee\xe7\xe8\xf6\xe8\xe9')
        local titleSz = imgui.CalcTextSize(titleT)
        imgui.SetCursorPos(imgui.ImVec2((EW-titleSz.x)*0.5, (36*MDS-titleSz.y)*0.5))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
        imgui.Text(titleT)
        imgui.PopStyleColor()
        if fontBig then imgui.PopFont() end

        imgui.SetCursorPos(imgui.ImVec2(EW-30*MDS, 7*MDS))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(1.00, 1.00, 1.00, 0.08))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.70, 0.10, 0.10, 1.00))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.00, 1.00, 1.00, 0.60))
        if imgui.Button(fa.XMARK..'##ew', imgui.ImVec2(22*MDS, 22*MDS)) then
            editWinOpen[0] = false
        end
        imgui.PopStyleColor(4)

        imgui.SetCursorPos(imgui.ImVec2(12*MDS, 44*MDS))
        local slW = EW - 24*MDS

        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
        imgui.Text(fa.TRUCK .. '  ' .. u8('\xca\xed\xee\xef\xea\xe0 \xcf\xd0\xc8\xd6\xc5\xcf'))
        imgui.PopStyleColor()
        imgui.SetCursorPosX(12*MDS)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.55, 0.55, 0.55, 1.0))
        imgui.Text('X:')
        imgui.PopStyleColor()
        imgui.SameLine()
        imgui.PushItemWidth(slW - 20*MDS)
        imgui.PushStyleColor(imgui.Col.FrameBg,          imgui.ImVec4(0.10, 0.10, 0.10, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab,       imgui.ImVec4(1.00, 0.30, 0.30, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.80, 0.10, 0.10, 1.0))
        if imgui.SliderInt('##atrx', ig_edit_atr_x, 0, math.floor(sw-180*MDS)) then
            atr_posX = ig_edit_atr_x[0]; saveCfg()
        end
        imgui.PopStyleColor(3); imgui.PopItemWidth()
        imgui.SetCursorPosX(12*MDS)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.55, 0.55, 0.55, 1.0))
        imgui.Text('Y:')
        imgui.PopStyleColor()
        imgui.SameLine()
        imgui.PushItemWidth(slW - 20*MDS)
        imgui.PushStyleColor(imgui.Col.FrameBg,          imgui.ImVec4(0.10, 0.10, 0.10, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab,       imgui.ImVec4(1.00, 0.30, 0.30, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.80, 0.10, 0.10, 1.0))
        if imgui.SliderInt('##atry', ig_edit_atr_y, 0, math.floor(sh-60*MDS)) then
            atr_posY = ig_edit_atr_y[0]; saveCfg()
        end
        imgui.PopStyleColor(3); imgui.PopItemWidth()

        imgui.Spacing()
        imgui.SetCursorPosX(12*MDS)
        imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(1.0, 1.0, 1.0, 0.08))
        imgui.Separator()
        imgui.PopStyleColor()
        imgui.Spacing()
        imgui.SetCursorPosX(12*MDS)

        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.30, 0.30, 1.00))
        imgui.Text(fa.CAR_BURST .. '  ' .. u8('\xca\xed\xee\xef\xea\xe0 \xc4\xce\xcc\xca\xd0\xc0\xd2'))
        imgui.PopStyleColor()
        imgui.SetCursorPosX(12*MDS)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.55, 0.55, 0.55, 1.0))
        imgui.Text('X:')
        imgui.PopStyleColor()
        imgui.SameLine()
        imgui.PushItemWidth(slW - 20*MDS)
        imgui.PushStyleColor(imgui.Col.FrameBg,          imgui.ImVec4(0.10, 0.10, 0.10, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab,       imgui.ImVec4(1.00, 0.30, 0.30, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.80, 0.10, 0.10, 1.0))
        if imgui.SliderInt('##dkx', ig_edit_dk_x, 0, math.floor(sw-130*MDS)) then
            domkrat_posX = ig_edit_dk_x[0]; saveCfg()
        end
        imgui.PopStyleColor(3); imgui.PopItemWidth()
        imgui.SetCursorPosX(12*MDS)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.55, 0.55, 0.55, 1.0))
        imgui.Text('Y:')
        imgui.PopStyleColor()
        imgui.SameLine()
        imgui.PushItemWidth(slW - 20*MDS)
        imgui.PushStyleColor(imgui.Col.FrameBg,          imgui.ImVec4(0.10, 0.10, 0.10, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab,       imgui.ImVec4(1.00, 0.30, 0.30, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.80, 0.10, 0.10, 1.0))
        if imgui.SliderInt('##dky', ig_edit_dk_y, 0, math.floor(sh-60*MDS)) then
            domkrat_posY = ig_edit_dk_y[0]; saveCfg()
        end
        imgui.PopStyleColor(3); imgui.PopItemWidth()

        imgui.End()
        imgui.PopStyleColor(2)
        if fontMain then imgui.PopFont() end
    end
)

function main()
    pcall(function()
        local lfs = require('lfs')
        lfs.mkdir(FOLDER)
    end)

    lua_thread.create(function()
        if not doesFileExist(SOUND_PATH) then
            local ok, req = pcall(require, 'requests')
            if ok and req then
                local r, resp = pcall(req.get, SOUND_URL)
                if r and resp and resp.status_code == 200 then
                    local d = resp.content or resp.text
                    if d then
                        local f = io.open(SOUND_PATH, 'wb')
                        if f then f:write(d); f:close() end
                    end
                end
            end
        end
    end)

    lua_thread.create(function()
        if not doesFileExist(LOGO_PATH) then
            local ok2, req2 = pcall(require, 'requests')
            if ok2 and req2 then
                local r2, resp2 = pcall(req2.get, LOGO_URL)
                if r2 and resp2 and resp2.status_code == 200 then
                    local d2 = resp2.content or resp2.text
                    if d2 and d2:sub(1,4) == '\x89PNG' then
                        local f2 = io.open(LOGO_PATH, 'wb')
                        if f2 then f2:write(d2); f2:close() end
                    end
                end
            end
        end
        logoReady = true
    end)

    imgui.OnFrame(
        function() return logoReady and not logoTex end,
        function()
            if doesFileExist(LOGO_PATH) then
                logoTex = imgui.CreateTextureFromFile(LOGO_PATH)
            end
            logoReady = false
        end
    )

    while not isSampAvailable()          do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(100) end

    sampRegisterChatCommand('truck', function()
        menuOpen[0] = not menuOpen[0]
        if menuOpen[0] then playMenuSound() end
    end)

    sampRegisterChatCommand('atrmove', function()
        if not attach_btn then
            notify('\xca\xed\xee\xef\xea\xe0 \xef\xf0\xe8\xf6\xe5\xef\xe0 \xe2\xfb\xea\xeb\xfe\xf7\xe5\xed\xe0!')
            return
        end
        atr_moveMode = not atr_moveMode
        if atr_moveMode then
            notify('\xd0\xe5\xe6\xe8\xec \xef\xe5\xf0\xe5\xec\xe5\xf9\xe5\xed\xe8\xff \xc2\xcb\xae\xd7\xc5\xcd')
        else
            notify('\xcf\xee\xe7\xe8\xf6\xe8\xff \xf1\xee\xf5\xf0\xe0\xed\xe5\xed\xe0')
            saveCfg()
        end
    end)

    lua_thread.create(function()
        while true do
            wait(333)
            if autogate then pcall(doAutoGate) end
        end
    end)

    notify('v2.0 PRO \xe7\xe0\xe3\xf0\xf3\xe6\xe5\xed! /truck - \xec\xe5\xed\xfe')

    -- license system disabled: everything is unlocked, no key required
    licenseOK = true
    licWinOpen[0] = false

    lua_thread.create(function()
        while not doesFileExist(NAV_PATH) do
            nav_loading = true
            notify('\xcd\xe0\xe2\xec\xe5\xf8: \xf1\xea\xe0\xf7\xe8\xe2\xe0\xed\xe8\xe5...')
            local ok, req = pcall(require, 'requests')
            if ok and req then
                local rok, resp = pcall(req.get, NAV_URL)
                if rok and resp and resp.status_code == 200 then
                    local d = resp.content or resp.text
                    if d then
                        local f = io.open(NAV_PATH, 'wb'); if f then f:write(d); f:close() end
                        notify('\xcd\xe0\xe2\xec\xe5\xf8: \xf1\xee\xf5\xf0\xe0\xed\xb8\xed')
                    end
                else notify('\xcd\xe0\xe2\xec\xe5\xf8: \xee\xf8\xe8\xe1\xea\xe0') end
            end
            wait(0); break
        end
        if not doesFileExist(NAV_PATH) then nav_loading=false; return end
        nav_loading = true
        notify('\xcd\xe0\xe2\xec\xe5\xf8: \xf0\xe0\xe7\xe1\xee\xf0...')
        local f = io.open(NAV_PATH, 'r')
        if not f then nav_loading=false; return end
        local count = 0
        for line in f:lines() do
            local id = tonumber(line:match('"id"%s*:%s*(%d+)'))
            local x  = tonumber(line:match('"x"%s*:%s*([%-%.%d]+)'))
            local y  = tonumber(line:match('"y"%s*:%s*([%-%.%d]+)'))
            local z  = tonumber(line:match('"z"%s*:%s*([%-%.%d]+)'))
            if id and x and y then
                local edges = {}
                local es = line:match('"edges"%s*:%s*(%b[])')
                if es then
                    for eid, edist in es:gmatch('%[%s*(%d+)%s*,%s*(%d+)%s*%]') do
                        edges[#edges+1] = {tonumber(eid), tonumber(edist)}
                    end
                end
                nav_nodes[id] = {x=x, y=y, z=z or 0, edges=edges}
                count = count + 1
            end
            if count % 500 == 0 then wait(0) end
        end
        f:close()
        nav_count = count
        buildNavGrid()
        nav_loading = false
        nav_loaded  = true
        notify('\xcd\xe0\xe2\xec\xe5\xf8: '..tostring(count)..' \xf3\xe7\xeb\xee\xe2')
    end)

    lua_thread.create(function()
        while true do
            if licenseOK then doAutopilot() end
            wait(100)
        end
    end)

    lua_thread.create(function()
        while true do
            if licenseOK then doAntiDetach() end
            wait(500)
        end
    end)

    while true do
        local inChat   = isChatActive()
        local inDialog = isDialogActive()
        local inMenu   = menuOpen[0]
        local inCar    = isCharInAnyCar(PLAYER_PED)

        if waiting_for_key then
            if isKeyJustPressed(0x1B) then
                waiting_for_key = false
            else
                for vk = 0x30, 0x7B do
                    if isKeyJustPressed(vk) and VK_NAMES[vk] then
                        domkrat_key = vk
                        waiting_for_key = false
                        saveCfg()
                        notify('\xc4\xee\xec\xea\xf0\xe0\xf2: \xea\xeb\xe0\xe2\xe8\xf8\xe0 ' .. vkName(vk))
                        break
                    end
                end
            end
            wait(10)
            goto continue
        end

        if domkrat_btn and not IS_MOBILE and not inChat and not inDialog and not inMenu and inCar then
            if domkrat_key > 0 and isKeyJustPressed(domkrat_key) then
                local ok, car = pcall(storeCarCharIsInNoSave, PLAYER_PED)
                if ok and car and doesVehicleExist(car) then
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    pcall(setCarCoordinates, car, px, py, pz + 0.5)
                    notify('\xc4\xee\xec\xea\xf0\xe0\xf2!')
                end
            end
        end

        if attach_btn and not IS_MOBILE and not inChat and not inDialog and not inMenu and inCar then
            local rmb = isKeyDown(0x02)

            if isKeyJustPressed(0x01) then
                local t = getNearestTrailer()
                if t then doAttach(t)
                else notify('\xcd\xe5\xf2 \xef\xf0\xe8\xf6\xe5\xef\xe0 \xf0\xff\xe4\xee\xec!') end
            end

            if rmb then
                atr_selecting = true
                local ox = sw/2 - ATR_RADIUS/2
                local oy = sh/3.3 - ATR_RADIUS/2
                local okC2, myCar2 = pcall(getCarCharIsUsing, PLAYER_PED)
                if okC2 and myCar2 then
                    local okV2, vehs2 = pcall(getAllVehicles)
                    if okV2 and vehs2 then
                        local found2 = false
                        for _, v2 in ipairs(vehs2) do
                            if v2 ~= myCar2 then
                                local ok5,vx5,vy5,vz5 = pcall(getCarCoordinates, v2)
                                if ok5 then
                                    local px3,py3,pz3 = getCharCoordinates(PLAYER_PED)
                                    local d2 = getDistanceBetweenCoords3d(px3,py3,pz3,vx5,vy5,vz5)
                                    if d2 <= 25 then
                                        local ok6,sx5,sy5 = pcall(convert3DCoordsToScreen,vx5,vy5,vz5)
                                        if ok6 and sx5 and sy5 then
                                            local ok7,onS = pcall(isCarOnScreen, v2)
                                            if ok7 and onS then
                                                if sx5>=ox and sx5<=ox+ATR_RADIUS
                                                and sy5>=oy and sy5<=oy+ATR_RADIUS then
                                                    atr_trailer = v2
                                                    found2 = true
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if not found2 then atr_trailer = nil end
                    end
                end
            else
                if atr_selecting then
                    atr_selecting = false
                    if atr_trailer and doesVehicleExist(atr_trailer) then
                        doAttach(atr_trailer)
                    end
                    atr_trailer = nil
                end
            end
        elseif not IS_MOBILE then
            atr_selecting = false
            atr_trailer   = nil
        end

        if attach_btn and IS_MOBILE and atr_selecting and not atr_autoMode and not atr_moveMode then
            local okC2, myCar2 = pcall(getCarCharIsUsing, PLAYER_PED)
            if okC2 and myCar2 and isCharInAnyCar(PLAYER_PED) then
                local ox2 = sw/2 - ATR_RADIUS/2
                local oy2 = sh/3.3 - ATR_RADIUS/2
                local okV2, vehs2 = pcall(getAllVehicles)
                if okV2 and vehs2 then
                    local found2 = false
                    for _, v2 in ipairs(vehs2) do
                        if v2 ~= myCar2 then
                            local ok5,vx5,vy5,vz5 = pcall(getCarCoordinates, v2)
                            if ok5 then
                                local px3,py3,pz3 = getCharCoordinates(PLAYER_PED)
                                local d2 = getDistanceBetweenCoords3d(px3,py3,pz3,vx5,vy5,vz5)
                                if d2 <= 20 then
                                    local ok6,sx5,sy5 = pcall(convert3DCoordsToScreen,vx5,vy5,vz5)
                                    if ok6 and sx5 and sy5 then
                                        local ok7,onS = pcall(isCarOnScreen, v2)
                                        if ok7 and onS then
                                            if sx5>=ox2 and sx5<=ox2+ATR_RADIUS
                                            and sy5>=oy2 and sy5<=oy2+ATR_RADIUS then
                                                atr_trailer = v2
                                                found2 = true
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if not found2 then atr_trailer = nil end
                end
            else
                atr_selecting = false
                atr_trailer   = nil
            end
        end

        if IS_MOBILE and WIDGET_RADAR ~= nil and isWidgetSwipedLeft(WIDGET_RADAR) then
            menuOpen[0] = not menuOpen[0]
            if menuOpen[0] then playMenuSound() end
            wait(250)
        end

        ::continue::
        wait(10)
    end
end
