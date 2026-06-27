script_name('mineTOOL | Mobile')
script_author('MineTool Team')
script_version('1.1')

local imgui    = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8    = encoding.UTF8
local new   = imgui.new
local sampev = require("lib.samp.events")
local ffi   = require 'ffi'
local lfs   = require 'lfs'
local inicfg = require 'inicfg'

local WinState   = new.bool(false)
-- ===== KEEP: CJ run + infinite run =====
local cj         = new.bool(false)
local beskbeg    = new.bool(false)
-- ===== ADDED FROM Mine Tools (per screenshots) =====
local renderOre        = new.bool(false)   -- \xcf\xee\xe8\xf1\xea \xf0\xf3\xe4\xfb
local autoDig          = new.bool(false)   -- \xc0\xe2\xf2\xee \xe2\xfb\xea\xe0\xef\xfb\xe2\xe0\xed\xe8\xe5 \xf0\xf3\xe4\xfb
local showOreLine      = new.bool(false)   -- \xcf\xee\xea\xe0\xe7\xfb\xe2\xe0\xf2\xfc \xeb\xe8\xed\xe8\xfe
local showOreDistance  = new.bool(false)   -- \xcf\xee\xea\xe0\xe7\xfb\xe2\xe0\xf2\xfc \xe4\xe8\xf1\xf2\xe0\xed\xf6\xe8\xfe
local oreTimer         = new.bool(false)   -- \xd2\xe0\xe9\xec\xe5\xf0 \xf0\xf3\xe4\xfb
local oreTimerDistance = new.bool(false)   -- \xcf\xee\xea\xe0\xe7. \xe4\xe8\xf1\xf2\xe0\xed\xf6\xe8\xfe \xe4\xee \xf0\xf3\xe4\xfb
local oreTimerLine     = new.bool(false)   -- \xcf\xee\xea\xe0\xe7. \xeb\xe8\xed\xe8\xfe \xe4\xee \xf2\xe0\xe9\xec\xe5\xf0\xe0
local renderRadius      = new.int(600)     -- \xd0\xe0\xe4\xe8\xf3\xf1 \xef\xee\xe8\xf1\xea\xe0
local renderSize        = new.int(12)      -- \xd0\xe0\xe7\xec\xe5\xf0 \xf8\xf0\xe8\xf4\xf2\xe0
local renderOreTimerSize= new.int(14)      -- \xd0\xe0\xe7\xec\xe5\xf0 \xf8\xf0\xe8\xf4\xf2\xe0 \xf2\xe0\xe9\xec\xe5\xf0\xe0
local colorOreTimer     = 0xFFFF00FF       -- ARGB, default magenta

-- ore detection state (ported from Mine Tools)
local ore3dCache  = {}   -- list of {x,y,z} of "\xcc\xe5\xf1\xf2\xee\xf0\xee\xe6\xe4\xe5\xed\xe8\xe5 \xf0\xe5\xf1\xf3\xf0\xf1\xee\xe2" texts
local textsTable  = {}   -- id -> {x,y,z} for "\xcc\xe5\xf1\xf2\xee\xf0\xee\xe6\xe4\xe5\xed\xe8\xe5" texts (autoDig)
local oreTimerList= {}   -- list of {x,y,z, expireTime}
local digCounter  = 0

local font = {}  -- imgui fonts indexed by pixel size (10..27)
local btnVisible  = true

local bass        = nil
local photoStream = 0
local SOUND_URL   = 'https://files.catbox.moe/9b8v8d.mp3'
local SOUND_FILE  = nil

pcall(function()
    bass = ffi.load('libbass.so')
    ffi.cdef[[
        int           BASS_Init(int device, unsigned long freq, unsigned long flags, void* win, void* clsid);
        unsigned long BASS_StreamCreateFile(int mem, const char* file, unsigned long long offset, unsigned long long length, unsigned long flags);
        unsigned long BASS_StreamCreateURL(const char* url, unsigned long offset, unsigned long flags, void* proc, void* user);
        int           BASS_ChannelPlay(unsigned long handle, int restart);
        int           BASS_ChannelStop(unsigned long handle);
        int           BASS_ChannelSetAttribute(unsigned long handle, unsigned long attrib, float value);
        int           BASS_StreamFree(unsigned long handle);
    ]]
    bass.BASS_Init(-1, 44100, 0, nil, nil)
end)

local function playPhotoSound()
    if not bass then return end
    pcall(function()
        if photoStream ~= 0 then
            bass.BASS_ChannelStop(photoStream)
            bass.BASS_StreamFree(photoStream)
            photoStream = 0
        end
        if SOUND_FILE and doesFileExist(SOUND_FILE) then
            photoStream = bass.BASS_StreamCreateFile(0, SOUND_FILE, 0, 0, 0)
        else
            photoStream = bass.BASS_StreamCreateURL(SOUND_URL, 0, 0, nil, nil)
        end
        if photoStream ~= 0 then
            bass.BASS_ChannelSetAttribute(photoStream, 2, 0.8)
            bass.BASS_ChannelPlay(photoStream, 1)
        end
    end)
end

local session_start_time = os.time()

local sw, sh = getScreenResolution()
local MDS = MONET_DPI_SCALE or 1

local FOLDER    = getWorkingDirectory()..'/MineTool'
local LOGO_FILE = FOLDER..'/miner.png'
local LOGO_URL  = 'https://i.ibb.co/Gv1sQwW9/images-1.png'
local CFG_FILE  = FOLDER..'/config.ini'

pcall(function() if not lfs.attributes(FOLDER) then lfs.mkdir(FOLDER) end end)

SOUND_FILE = FOLDER..'/photo_click.mp3'

local cfg = inicfg.load({
    settings = {
        cj               = false,
        beskbeg          = false,
        renderOre        = false,
        autoDig          = false,
        showOreLine      = false,
        showOreDistance  = false,
        oreTimer         = false,
        oreTimerDistance = false,
        oreTimerLine     = false,
        renderRadius     = 600,
        renderSize       = 12,
        renderOreTimerSize = 14,
        colorOreTimer    = 0xFFFF00FF,
        btnVisible       = true,
    }
}, CFG_FILE)

cj[0]               = cfg.settings.cj
beskbeg[0]          = cfg.settings.beskbeg
renderOre[0]        = cfg.settings.renderOre
autoDig[0]          = cfg.settings.autoDig
showOreLine[0]      = cfg.settings.showOreLine
showOreDistance[0]  = cfg.settings.showOreDistance
oreTimer[0]         = cfg.settings.oreTimer
oreTimerDistance[0] = cfg.settings.oreTimerDistance
oreTimerLine[0]     = cfg.settings.oreTimerLine
renderRadius[0]     = tonumber(cfg.settings.renderRadius) or 600
renderSize[0]       = tonumber(cfg.settings.renderSize) or 12
renderOreTimerSize[0] = tonumber(cfg.settings.renderOreTimerSize) or 14
colorOreTimer       = tonumber(cfg.settings.colorOreTimer) or 0xFFFF00FF
btnVisible          = cfg.settings.btnVisible

local function saveConfig()
    cfg.settings.cj               = cj[0]
    cfg.settings.beskbeg          = beskbeg[0]
    cfg.settings.renderOre        = renderOre[0]
    cfg.settings.autoDig          = autoDig[0]
    cfg.settings.showOreLine      = showOreLine[0]
    cfg.settings.showOreDistance  = showOreDistance[0]
    cfg.settings.oreTimer         = oreTimer[0]
    cfg.settings.oreTimerDistance = oreTimerDistance[0]
    cfg.settings.oreTimerLine     = oreTimerLine[0]
    cfg.settings.renderRadius     = renderRadius[0]
    cfg.settings.renderSize       = renderSize[0]
    cfg.settings.renderOreTimerSize = renderOreTimerSize[0]
    cfg.settings.colorOreTimer    = colorOreTimer
    cfg.settings.btnVisible       = btnVisible
    inicfg.save(cfg, CFG_FILE)
end

lua_thread.create(function()
    wait(3000)
    if not doesFileExist(SOUND_FILE) then
        local ok, resp = pcall(require('requests').get, SOUND_URL)
        if ok and resp and resp.status_code == 200 then
            local data = resp.content or resp.text
            if data then
                local f = io.open(SOUND_FILE, 'wb')
                if f then f:write(data); f:close() end
            end
        end
    end
end)

local gta_lib = nil
pcall(function()
    gta_lib = ffi.load('GTASA')
    ffi.cdef[[ void _Z12AND_OpenLinkPKc(const char* link); ]]
end)
local function openLink(url)
    if gta_lib then pcall(gta_lib._Z12AND_OpenLinkPKc, url) end
end

lua_thread.create(function()
    wait(2000)
    if not doesFileExist(LOGO_FILE) then
        local ok, resp = pcall(require('requests').get, LOGO_URL)
        if ok and resp and resp.status_code == 200 then
            local data = resp.content or resp.text
            if data and data:sub(1,4) == '\x89PNG' then
                local f = io.open(LOGO_FILE, 'wb')
                if f then f:write(data); f:close() end
            end
        end
    end
end)

local fa      = require('fAwesome6_solid')
local faicons = require('fAwesome6')

local activeTab = 1
local winX, winY = sw/2 - 208*MDS, sh/2 - 184*MDS
local drag, dox, doy = false, 0, 0
local logoTex   = nil
local logoTried = false

local sysLog = { u8('\xd1\xe8\xf1\xf2\xe5\xec\xe0 \xe3\xee\xf2\xee\xe2\xe0') }
local function pushLog(msg)
    table.insert(sysLog, 1, msg)
    if #sysLog > 4 then table.remove(sysLog) end
end

local fMain, fSmall, fLarge

-- ===== math helpers (from Mine Tools) =====
local function safeDist3d(x1,y1,z1,x2,y2,z2)
    x1=tonumber(x1) or 0; y1=tonumber(y1) or 0; z1=tonumber(z1) or 0
    x2=tonumber(x2) or 0; y2=tonumber(y2) or 0; z2=tonumber(z2) or 0
    local dx,dy,dz = x1-x2, y1-y2, z1-z2
    return math.sqrt(dx*dx+dy*dy+dz*dz)
end
local function join_argb(a, r, g, b)
    local argb = b
    argb = bit.bor(argb, bit.lshift(g,  8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end
local function argbToVec4(argb)
    argb = tonumber(argb) or 0xFFFFFFFF
    return imgui.ImVec4(
        bit.band(bit.rshift(argb,16),0xFF)/255,
        bit.band(bit.rshift(argb, 8),0xFF)/255,
        bit.band(argb,0xFF)/255,
        bit.band(bit.rshift(argb,24),0xFF)/255)
end

imgui.OnInitialize(function()
    local io = imgui.GetIO()
    io.IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)

    local ranges = io.Fonts:GetGlyphRangesCyrillic()
    local fd = getWorkingDirectory() .. '/../'

    fSmall = io.Fonts:AddFontFromFileTTF(fd..'trebucbd.ttf', 12*MDS, nil, ranges)
    fMain  = io.Fonts:AddFontFromFileTTF(fd..'trebucbd.ttf', 14*MDS, nil, ranges)
    fLarge = io.Fonts:AddFontFromFileTTF(fd..'trebucbd.ttf', 17*MDS, nil, ranges)

    -- world-render font sizes used by ore search / timer sliders (10..27)
    for size = 10, 27 do
        font[size] = io.Fonts:AddFontFromFileTTF(fd..'trebucbd.ttf', size*MDS, nil, ranges)
    end

    local function addFA(size)
        local cfg2 = imgui.ImFontConfig()
        cfg2.MergeMode  = true
        cfg2.PixelSnapH = true
        local faRange = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
        io.Fonts:AddFontFromMemoryCompressedBase85TTF(
            faicons.get_font_data_base85('solid'), size, cfg2, faRange)
    end
    addFA(12*MDS); addFA(14*MDS); addFA(17*MDS)
end)

local function V4(r,g,b,a) return imgui.ImVec4(r,g,b,a or 1) end
local function U32(r,g,b,a)
    return imgui.ColorConvertFloat4ToU32(V4(r,g,b,a or 1))
end
local V2 = imgui.ImVec2

local COL = {
    BG          = V4(0.05, 0.05, 0.04, 0.98),
    BG2         = V4(0.08, 0.08, 0.06, 1.00),
    BG3         = V4(0.11, 0.10, 0.08, 1.00),
    PANEL       = V4(0.07, 0.07, 0.05, 1.00),
    BORDER      = V4(0.22, 0.20, 0.14, 0.80),
    BORDER2     = V4(0.30, 0.28, 0.18, 0.60),
    YELLOW      = V4(0.78, 0.68, 0.12, 1.00),
    YELLOW_DIM  = V4(0.50, 0.44, 0.08, 1.00),
    GREEN       = V4(0.25, 0.62, 0.18, 1.00),
    GREEN_DIM   = V4(0.16, 0.40, 0.11, 1.00),
    GREEN_GLOW  = V4(0.30, 0.75, 0.22, 1.00),
    RED         = V4(0.72, 0.14, 0.10, 1.00),
    RED_DIM     = V4(0.45, 0.08, 0.06, 1.00),
    TEXT        = V4(0.82, 0.78, 0.60, 1.00),
    TEXT_DIM    = V4(0.48, 0.45, 0.32, 1.00),
    TEXT_GREEN  = V4(0.35, 0.85, 0.25, 1.00),
    TEXT_YELLOW = V4(0.88, 0.76, 0.20, 1.00),
    TEXT_RED    = V4(0.90, 0.28, 0.20, 1.00),
    TAB_ACT     = V4(0.16, 0.16, 0.10, 1.00),
    TAB_HOV     = V4(0.12, 0.12, 0.08, 1.00),
    BTN         = V4(0.10, 0.10, 0.07, 1.00),
    BTN_HOV     = V4(0.18, 0.17, 0.10, 1.00),
}

local function applyTheme()
    imgui.SwitchContext()
    local st = imgui.GetStyle()
    local C  = st.Colors
    st.WindowPadding    = V2(0, 0)
    st.FramePadding     = V2(7*MDS, 4*MDS)
    st.ItemSpacing      = V2(6*MDS, 5*MDS)
    st.ScrollbarSize    = 6*MDS
    st.WindowBorderSize = 1
    st.ChildBorderSize  = 0
    st.FrameBorderSize  = 1
    st.WindowRounding   = 2*MDS
    st.ChildRounding    = 2*MDS
    st.FrameRounding    = 2*MDS
    st.GrabRounding     = 1*MDS
    st.ButtonTextAlign  = V2(0.5, 0.5)
    st.WindowTitleAlign = V2(0.5, 0.5)

    C[imgui.Col.Text]             = COL.TEXT
    C[imgui.Col.TextDisabled]     = COL.TEXT_DIM
    C[imgui.Col.WindowBg]         = COL.BG
    C[imgui.Col.ChildBg]          = COL.BG2
    C[imgui.Col.PopupBg]          = COL.BG2
    C[imgui.Col.Border]           = COL.BORDER
    C[imgui.Col.FrameBg]          = V4(0.08,0.08,0.06,0.90)
    C[imgui.Col.FrameBgHovered]   = V4(0.14,0.13,0.09,1.00)
    C[imgui.Col.FrameBgActive]    = V4(0.18,0.17,0.11,1.00)
    C[imgui.Col.TitleBg]          = V4(0.04,0.04,0.03,1.00)
    C[imgui.Col.TitleBgActive]    = V4(0.06,0.06,0.04,1.00)
    C[imgui.Col.Button]           = COL.BTN
    C[imgui.Col.ButtonHovered]    = COL.BTN_HOV
    C[imgui.Col.ButtonActive]     = V4(0.25,0.22,0.12,1.00)
    C[imgui.Col.Header]           = V4(0.15,0.14,0.08,0.70)
    C[imgui.Col.HeaderHovered]    = V4(0.22,0.20,0.12,0.80)
    C[imgui.Col.HeaderActive]     = V4(0.28,0.26,0.14,1.00)
    C[imgui.Col.CheckMark]        = COL.YELLOW
    C[imgui.Col.SliderGrab]       = COL.GREEN
    C[imgui.Col.SliderGrabActive] = COL.GREEN_GLOW
    C[imgui.Col.Separator]        = V4(0.22,0.20,0.12,0.60)
    C[imgui.Col.ScrollbarBg]      = V4(0.04,0.04,0.03,1.00)
    C[imgui.Col.ScrollbarGrab]    = V4(0.18,0.17,0.10,0.85)
end

local function warnStripe(dl, x, y, w, h)
    h = h or 6*MDS
    local sw2 = 12*MDS
    local i = 0
    while x + i*sw2 < x+w do
        local x1 = x + i*sw2
        local x2 = math.min(x1+sw2/2, x+w)
        dl:AddRectFilled(V2(x1,y), V2(x2, y+h), U32(0.60,0.52,0.05, 0.75))
        i = i + 1
        x1 = x + i*sw2 - sw2/2
        x2 = math.min(x1+sw2/2, x+w)
        dl:AddRectFilled(V2(x1,y), V2(x2, y+h), U32(0.06,0.06,0.04, 0.75))
        i = i + 1
    end
end

local function statusDot(dl, cx, cy, r, col_on, on)
    local c = on and col_on or U32(0.20,0.18,0.12,0.8)
    dl:AddCircleFilled(V2(cx,cy), r, c, 16)
    if on then
        dl:AddCircleFilled(V2(cx,cy), r+3*MDS, U32(0,0.5,0.1, 0.25), 16)
    end
    dl:AddCircle(V2(cx,cy), r+0.5, U32(0.30,0.28,0.16,0.6), 16, 1)
end

local function sectionHeader(label)
    imgui.Dummy(V2(0,4*MDS))
    imgui.SetCursorPosX(8*MDS)
    imgui.TextColored(COL.TEXT_YELLOW, label)
    imgui.Separator()
    imgui.Dummy(V2(0,2*MDS))
end

imgui.OnFrame(function()
    return btnVisible and not isPauseMenuActive()
end, function()
    applyTheme()
    local buttonSize = 60*MDS
    imgui.SetNextWindowPos(V2(12*MDS, sh/2 + 80*MDS), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(V2(buttonSize, buttonSize), imgui.Cond.Always)

    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, V2(0,0))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 4*MDS)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 1)
    imgui.PushStyleColor(imgui.Col.WindowBg,       V4(0.07,0.07,0.05,0.94))
    imgui.PushStyleColor(imgui.Col.Border,         COL.BORDER)
    imgui.PushStyleColor(imgui.Col.Button,         V4(0,0,0,0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered,  V4(0.20,0.18,0.08,0.6))
    imgui.PushStyleColor(imgui.Col.ButtonActive,   V4(0.30,0.26,0.10,0.8))
    imgui.PushStyleColor(imgui.Col.Text,           COL.TEXT_YELLOW)

    imgui.Begin('MineBtnWin', nil,
        imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar)

    imgui.SetWindowFontScale(1.4)
    if imgui.Button(fa.HELMET_SAFETY, V2(buttonSize, buttonSize)) then
        WinState[0] = not WinState[0]
    end

    imgui.End()
    imgui.PopStyleColor(6)
    imgui.PopStyleVar(3)
end)

imgui.OnFrame(
    function() return WinState[0] and not isPauseMenuActive() end,
    function(self)
        self.HideCursor = false
        applyTheme()

        if not logoTried and doesFileExist(LOGO_FILE) then
            logoTried = true
            local t = imgui.CreateTextureFromFile(LOGO_FILE)
            if t then logoTex = t end
        end

        local mp = imgui.GetIO().MousePos
        local md = imgui.IsMouseDown(0)
        if drag then
            if md then
                winX = math.max(0, math.min(sw-416*MDS, mp.x-dox))
                winY = math.max(0, math.min(sh-368*MDS, mp.y-doy))
            else drag = false end
        end

        local W, H = 416*MDS, 368*MDS

        imgui.SetNextWindowPos(V2(winX, winY), imgui.Cond.Always)
        imgui.SetNextWindowSize(V2(W, H), imgui.Cond.Always)

        local title = fa.HELMET_SAFETY..' mineTOOL TERMINAL  v1.1  ##mt'
        imgui.Begin(title, WinState,
            imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar)

        local dl = imgui.GetWindowDrawList()
        local wp = imgui.GetWindowPos()

        if imgui.IsMouseHoveringRect(wp, V2(wp.x+W, wp.y+H))
            and md and not drag
            and not imgui.IsAnyItemActive()
            and not imgui.IsAnyItemHovered() then
            drag=true; dox=mp.x-winX; doy=mp.y-winY
        end

        warnStripe(dl, wp.x, wp.y+28*MDS, W, 5*MDS)

        local indicators = {
            {renderOre[0], U32(0.30,0.75,0.22,1),  u8('\xd0\xd3\xc4\xc0')},
            {oreTimer[0],  U32(0.78,0.68,0.12,1),  u8('\xd2\xc0\xc9\xcc')},
            {cj[0],        U32(0.35,0.85,0.25,1),  u8('\xc1\xc5\xc3')},
            {beskbeg[0],   U32(0.72,0.14,0.10,1),  u8('\xc1\xc5\xd1\xca')},
        }
        local dotX = wp.x + W - 10*MDS
        for i = #indicators, 1, -1 do
            local ind = indicators[i]
            local labelSz = imgui.CalcTextSize(ind[3])
            dotX = dotX - labelSz.x - 14*MDS
            local dotCy = wp.y + 17*MDS
            statusDot(dl, dotX, dotCy, 4*MDS, ind[2], ind[1])
            imgui.SetCursorScreenPos(V2(dotX+6*MDS, dotCy-7*MDS))
            imgui.TextColored(ind[1] and COL.TEXT_GREEN or COL.TEXT_DIM, ind[3])
            dotX = dotX - 4*MDS
        end

        local BODY_Y  = 34*MDS
        local SIDE_W  = 46*MDS
        local PHOTO_W = 96*MDS
        local CONT_W  = W - SIDE_W - PHOTO_W - 4*MDS

        imgui.SetCursorPos(V2(0, BODY_Y))
        imgui.PushStyleColor(imgui.Col.ChildBg, COL.PANEL)
        if imgui.BeginChild('##side', V2(SIDE_W, H-BODY_Y-28*MDS), false) then
            local sideWP = imgui.GetWindowPos()
            local sideDL = imgui.GetWindowDrawList()

            sideDL:AddLine(
                V2(sideWP.x+SIDE_W-1, sideWP.y),
                V2(sideWP.x+SIDE_W-1, sideWP.y+H),
                U32(0.22,0.20,0.12,0.8), 1)

            imgui.Dummy(V2(0,8*MDS))
            local tabDefs = {
                {fa.SLIDERS,   1},
                {fa.USER,      3},
            }
            for _,t in ipairs(tabDefs) do
                local isAct = (activeTab == t[2])
                imgui.SetCursorPosX(4*MDS)
                if isAct then
                    imgui.PushStyleColor(imgui.Col.Button, V4(0.20,0.18,0.08,1))
                    imgui.PushStyleColor(imgui.Col.Text, COL.TEXT_YELLOW)
                    local bp = imgui.GetCursorScreenPos()
                    sideDL:AddRectFilled(
                        V2(bp.x-4,bp.y),
                        V2(bp.x-1, bp.y+38*MDS),
                        U32(0.78,0.68,0.12,0.9))
                else
                    imgui.PushStyleColor(imgui.Col.Button, V4(0,0,0,0))
                    imgui.PushStyleColor(imgui.Col.Text, COL.TEXT_DIM)
                end
                imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.15,0.14,0.08,0.8))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.22,0.20,0.10,1))
                if imgui.Button(t[1], V2(SIDE_W-8*MDS, 38*MDS)) then
                    activeTab = t[2]
                end
                imgui.PopStyleColor(4)
                imgui.Dummy(V2(0,4*MDS))
            end

            imgui.EndChild()
        end
        imgui.PopStyleColor()

        imgui.SetCursorPos(V2(SIDE_W+2*MDS, BODY_Y))
        if imgui.BeginChild('##content', V2(CONT_W, H-BODY_Y-28*MDS), false) then
            if fMain then imgui.PushFont(fMain) end
            imgui.SetCursorPos(V2(6*MDS, 8*MDS))

            if activeTab == 1 then

                -- ===== \xce\xd1\xcd\xce\xc2\xcd\xdb\xc5 \xcc\xce\xc4\xdb (CJ run + infinite run) =====
                imgui.SetCursorPosX(8*MDS)
                imgui.TextColored(COL.TEXT_YELLOW, u8('\xce\xd1\xcd\xce\xc2\xcd\xdb\xc5 \xcc\xce\xc4\xdb'))
                imgui.Separator()
                imgui.Dummy(V2(0,2*MDS))

                imgui.SetCursorPosX(10*MDS)
                local cb_cj = new.bool(cj[0])
                if imgui.Checkbox(fa.PERSON_RUNNING..'  '..u8('\xc1\xe5\xe3 \xd1\xe6'), cb_cj) then
                    cj[0] = cb_cj[0]
                    enableCj()
                    saveConfig()
                end

                imgui.SetCursorPosX(10*MDS)
                local cb_bk = new.bool(beskbeg[0])
                if imgui.Checkbox(fa.BOLT..'  '..u8('\xc1\xe5\xf1\xea \xc1\xe5\xe3'), cb_bk) then
                    beskbeg[0] = cb_bk[0]
                    enableBesk()
                    saveConfig()
                end

                -- ===== \xcf\xce\xc8\xd1\xca \xd0\xd3\xc4\xdb (from Mine Tools) =====
                sectionHeader(u8('\xcf\xce\xc8\xd1\xca \xd0\xd3\xc4\xdb'))

                imgui.SetCursorPosX(10*MDS)
                local cb_ro = new.bool(renderOre[0])
                if imgui.Checkbox(fa.GEM..'  '..u8('\xcf\xee\xe8\xf1\xea \xf0\xf3\xe4\xfb'), cb_ro) then
                    renderOre[0] = cb_ro[0]; saveConfig()
                end

                imgui.SetCursorPosX(10*MDS)
                local cb_ad = new.bool(autoDig[0])
                if imgui.Checkbox(fa.HAMMER..'  '..u8('\xc0\xe2\xf2\xee \xe2\xfb\xea\xe0\xef\xfb\xe2\xe0\xed\xe8\xe5 \xf0\xf3\xe4\xfb'), cb_ad) then
                    autoDig[0] = cb_ad[0]; saveConfig()
                end

                imgui.SetCursorPosX(10*MDS)
                local cb_sl = new.bool(showOreLine[0])
                if imgui.Checkbox(fa.SHARE_NODES..'  '..u8('\xcf\xee\xea\xe0\xe7\xfb\xe2\xe0\xf2\xfc \xeb\xe8\xed\xe8\xfe'), cb_sl) then
                    showOreLine[0] = cb_sl[0]; saveConfig()
                end

                imgui.SetCursorPosX(10*MDS)
                local cb_sd = new.bool(showOreDistance[0])
                if imgui.Checkbox(fa.RULER_HORIZONTAL..'  '..u8('\xcf\xee\xea\xe0\xe7\xfb\xe2\xe0\xf2\xfc \xe4\xe8\xf1\xf2\xe0\xed\xf6\xe8\xfe'), cb_sd) then
                    showOreDistance[0] = cb_sd[0]; saveConfig()
                end

                imgui.Dummy(V2(0,2*MDS))
                imgui.SetCursorPosX(10*MDS)
                imgui.PushItemWidth(CONT_W - 30*MDS)
                if imgui.SliderInt(u8('\xd0\xe0\xe4\xe8\xf3\xf1 \xef\xee\xe8\xf1\xea\xe0'), renderRadius, 1, 600) then
                    saveConfig()
                end
                imgui.SetCursorPosX(10*MDS)
                if imgui.SliderInt(u8('\xd0\xe0\xe7\xec\xe5\xf0 \xf8\xf0\xe8\xf4\xf2\xe0'), renderSize, 10, 27) then
                    saveConfig()
                end
                imgui.PopItemWidth()

                -- ===== \xd2\xc0\xc9\xcc\xc5\xd0 \xd0\xd3\xc4\xdb (from Mine Tools) =====
                sectionHeader(u8('\xd2\xc0\xc9\xcc\xc5\xd0 \xd0\xd3\xc4\xdb'))

                do
                    local argb = colorOreTimer
                    local ct = new.float[4](
                        bit.band(bit.rshift(argb,16),0xFF)/255,
                        bit.band(bit.rshift(argb, 8),0xFF)/255,
                        bit.band(argb,0xFF)/255,
                        bit.band(bit.rshift(argb,24),0xFF)/255)
                    imgui.SetCursorPosX(10*MDS)
                    if imgui.ColorEdit4('##ct', ct, imgui.ColorEditFlags.NoInputs) then
                        colorOreTimer = join_argb(
                            math.floor(ct[3]*255), math.floor(ct[0]*255),
                            math.floor(ct[1]*255), math.floor(ct[2]*255))
                        saveConfig()
                    end
                    imgui.SameLine()
                    local cb_tm = new.bool(oreTimer[0])
                    if imgui.Checkbox(u8('\xd2\xe0\xe9\xec\xe5\xf0 \xf0\xf3\xe4\xfb'), cb_tm) then
                        oreTimer[0] = cb_tm[0]; saveConfig()
                    end
                end

                imgui.SetCursorPosX(10*MDS)
                local cb_td = new.bool(oreTimerDistance[0])
                if imgui.Checkbox(u8('\xcf\xee\xea\xe0\xe7. \xe4\xe8\xf1\xf2\xe0\xed\xf6\xe8\xfe \xe4\xee \xf0\xf3\xe4\xfb'), cb_td) then
                    oreTimerDistance[0] = cb_td[0]; saveConfig()
                end

                imgui.SetCursorPosX(10*MDS)
                local cb_tl = new.bool(oreTimerLine[0])
                if imgui.Checkbox(u8('\xcf\xee\xea\xe0\xe7. \xeb\xe8\xed\xe8\xfe \xe4\xee \xf2\xe0\xe9\xec\xe5\xf0\xe0'), cb_tl) then
                    oreTimerLine[0] = cb_tl[0]; saveConfig()
                end

                imgui.Dummy(V2(0,2*MDS))
                imgui.SetCursorPosX(10*MDS)
                imgui.PushItemWidth(CONT_W - 30*MDS)
                if imgui.SliderInt(u8('\xd0\xe0\xe7\xec\xe5\xf0 \xf8\xf0\xe8\xf4\xf2\xe0 \xf2\xe0\xe9\xec\xe5\xf0\xe0'), renderOreTimerSize, 10, 27) then
                    saveConfig()
                end
                imgui.PopItemWidth()

                imgui.Dummy(V2(0,6*MDS))
                imgui.SetCursorPosX(10*MDS)
                local cb_btn = new.bool(btnVisible)
                if imgui.Checkbox(fa.CIRCLE_DOT..'  '..u8('\xca\xed\xee\xef\xea\xe0 \xec\xe5\xed\xfe'), cb_btn) then
                    btnVisible = cb_btn[0]
                    saveConfig()
                end

            elseif activeTab == 3 then

                local cdl = imgui.GetWindowDrawList()
                local cp  = imgui.GetCursorScreenPos()
                cdl:AddRect(V2(cp.x+4,cp.y), V2(cp.x+CONT_W-16, cp.y+80*MDS),
                    U32(0.22,0.20,0.12,0.5), 2, 0, 1)
                imgui.SetCursorScreenPos(V2(cp.x+12, cp.y+1*MDS))
                imgui.TextColored(COL.TEXT_YELLOW, 'INFO')
                imgui.Dummy(V2(0,13*MDS))

                imgui.SetCursorPosX(10*MDS)
                imgui.TextColored(COL.TEXT_DIM, 'mineTOOL v1.1')
                imgui.SetCursorPosX(10*MDS)
                imgui.TextColored(COL.TEXT_DIM, u8('\xcc\xee\xe1\xe8\xeb\xfc\xed\xfb\xe9 \xf1\xea\xf0\xe8\xef\xf2'))

                imgui.Dummy(V2(0,20*MDS))

                imgui.SetCursorPosX(10*MDS)
                imgui.PushStyleColor(imgui.Col.Button,        V4(0.08,0.18,0.25,1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.12,0.26,0.38,1))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.06,0.14,0.20,1))
                imgui.PushStyleColor(imgui.Col.Text,          V4(0.55,0.80,1.00,1))
                if imgui.Button(fa.PAPER_PLANE..' Telegram', V2(CONT_W-20*MDS, 28*MDS)) then
                    openLink('https://t.me/WiNSTON_na_GAvA1')
                end
                imgui.PopStyleColor(4)
            end

            if fMain then imgui.PopFont() end
            imgui.EndChild()
        end

        imgui.SetCursorPos(V2(SIDE_W+CONT_W+4*MDS, BODY_Y))
        imgui.PushStyleColor(imgui.Col.ChildBg, V4(0.06,0.06,0.04,1))
        if imgui.BeginChild('##photo', V2(PHOTO_W, H-BODY_Y-28*MDS), false) then
            local pDL = imgui.GetWindowDrawList()
            local pWP = imgui.GetWindowPos()
            local pW  = PHOTO_W

            pDL:AddLine(V2(pWP.x, pWP.y), V2(pWP.x, pWP.y+H),
                U32(0.22,0.20,0.12,0.7), 1)

            imgui.Dummy(V2(0,8*MDS))

            local photoW = pW - 12*MDS
            local photoH = 88*MDS
            local pp = imgui.GetCursorScreenPos()
            pDL:AddRect(V2(pp.x+4,pp.y), V2(pp.x+pW-8,pp.y+photoH),
                U32(0.30,0.26,0.10,0.8), 1, 0, 1.5)
            if logoTex then
                imgui.SetCursorPosX(6*MDS)
                imgui.Image(logoTex, V2(photoW, photoH))
                pDL:AddRectFilled(
                    V2(pp.x+5, pp.y+1),
                    V2(pp.x+pW-9, pp.y+photoH-1),
                    U32(0.05,0.18,0.05, 0.22))
                imgui.SetCursorScreenPos(V2(pp.x+6, pp.y))
                imgui.InvisibleButton('##photobtn', V2(photoW, photoH))
                if imgui.IsItemClicked() then playPhotoSound() end
                if imgui.IsItemHovered() then
                    pDL:AddRectFilled(
                        V2(pp.x+5, pp.y+1),
                        V2(pp.x+pW-9, pp.y+photoH-1),
                        U32(0.78,0.68,0.12, 0.08))
                    imgui.SetCursorScreenPos(V2(pp.x+8, pp.y+photoH-22*MDS))
                    if fSmall then imgui.PushFont(fSmall) end
                    imgui.TextColored(V4(0.88,0.76,0.20,0.9), fa.VOLUME_HIGH)
                    if fSmall then imgui.PopFont() end
                end
            else
                pDL:AddRectFilled(V2(pp.x+5,pp.y+1),
                    V2(pp.x+pW-9,pp.y+photoH-1), U32(0.08,0.09,0.06,1))
                imgui.SetCursorScreenPos(V2(pp.x+pW/2-20,pp.y+photoH/2-7))
                imgui.TextColored(COL.TEXT_DIM, fa.PERSON)
                imgui.Dummy(V2(0,photoH))
            end

            pDL:AddRectFilled(
                V2(pp.x+5, pp.y+photoH-14*MDS),
                V2(pp.x+pW-9, pp.y+photoH-1),
                U32(0.55,0.45,0.05, 0.82))
            imgui.SetCursorScreenPos(V2(pp.x+8, pp.y+photoH-12*MDS))
            if fSmall then imgui.PushFont(fSmall) end
            imgui.TextColored(V4(0.05,0.04,0.02,1), 'ID: MINER-01')
            if fSmall then imgui.PopFont() end

            imgui.Dummy(V2(0,8*MDS))

            if fSmall then imgui.PushFont(fSmall) end
            local dossier = {
                {u8('\xd0\xd3\xc4\xc0:'), renderOre[0] and 'ON' or 'OFF',
                    renderOre[0] and COL.TEXT_GREEN or COL.TEXT_DIM},
                {u8('\xd2\xc0\xc9\xcc:'), oreTimer[0] and 'ON' or 'OFF',
                    oreTimer[0] and COL.TEXT_GREEN or COL.TEXT_YELLOW},
                {u8('\xc1\xc5\xc3:'),  cj[0] and 'ON' or 'OFF',
                    cj[0] and COL.TEXT_GREEN or COL.TEXT_DIM},
                {u8('\xc1\xd1\xca:'),  beskbeg[0] and 'ON' or 'OFF',
                    beskbeg[0] and COL.TEXT_GREEN or COL.TEXT_DIM},
            }
            for _,d in ipairs(dossier) do
                imgui.SetCursorPosX(5*MDS)
                imgui.TextColored(COL.TEXT_DIM, d[1])
                imgui.SameLine(0,3*MDS)
                imgui.TextColored(d[3], d[2])
            end
            if fSmall then imgui.PopFont() end

            imgui.Dummy(V2(0,6*MDS))
            local wp2 = imgui.GetCursorScreenPos()
            local warnH = 26*MDS
            pDL:AddRectFilled(V2(wp2.x+4,wp2.y), V2(wp2.x+pW-8,wp2.y+warnH),
                U32(0.22,0.18,0.04, 0.40))
            pDL:AddRect(V2(wp2.x+4,wp2.y), V2(wp2.x+pW-8,wp2.y+warnH),
                U32(0.50,0.42,0.08, 0.60), 1)
            if fSmall then imgui.PushFont(fSmall) end
            local shahtaLabel = fa.RADIATION..'  '..u8('\xd8\xc0\xd5\xd2\xc0')
            local shahtaSz = imgui.CalcTextSize(shahtaLabel)
            imgui.SetCursorScreenPos(V2(
                wp2.x + (pW - shahtaSz.x) / 2,
                wp2.y + (warnH - shahtaSz.y) / 2))
            imgui.TextColored(COL.TEXT_YELLOW, shahtaLabel)
            if fSmall then imgui.PopFont() end

            imgui.Dummy(V2(0,6*MDS))
            imgui.SetCursorPosX(5*MDS)
            imgui.PushStyleColor(imgui.Col.Button,        V4(0.28,0.06,0.04,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.40,0.08,0.06,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.20,0.04,0.03,1))
            imgui.PushStyleColor(imgui.Col.Text,          COL.TEXT_RED)
            if fSmall then imgui.PushFont(fSmall) end
            if imgui.Button(fa.XMARK..'  '..u8('\xc7\xe0\xea\xf0\xfb\xf2\xfc'),
                V2(pW-10*MDS, 26*MDS)) then
                WinState[0] = false
            end
            if fSmall then imgui.PopFont() end
            imgui.PopStyleColor(4)

            imgui.EndChild()
        end
        imgui.PopStyleColor()

        local logY = H - 26*MDS
        dl:AddRectFilled(V2(wp.x,wp.y+logY), V2(wp.x+W,wp.y+H), U32(0.04,0.04,0.03,1))
        dl:AddLine(V2(wp.x,wp.y+logY), V2(wp.x+W,wp.y+logY), U32(0.22,0.20,0.12,0.6), 1)
        if fSmall then imgui.PushFont(fSmall) end
        imgui.SetCursorPos(V2(SIDE_W+8*MDS, logY+4*MDS))
        imgui.TextColored(COL.TEXT_DIM, fa.TERMINAL..'  ')
        imgui.SameLine()
        imgui.TextColored(COL.TEXT_GREEN, sysLog[1] or '')
        if #sysLog > 1 then
            imgui.SameLine()
            imgui.TextColored(COL.TEXT_DIM, '  |  ')
            imgui.SameLine()
            imgui.TextColored(COL.TEXT_DIM, sysLog[2] or '')
        end
        if fSmall then imgui.PopFont() end

        imgui.End()
    end
)

-- ===== world render: ore search lines/distance + ore timer (from Mine Tools) =====
local ORE_LABEL  = u8('\xd0\xf3\xe4\xe0')
local ORE_REMAIN = u8('\xce\xf1\xf2\xe0\xeb\xee\xf1\xfc ')

imgui.OnFrame(
    function() return not isPauseMenuActive() end,
    function(self)
        self.HideCursor = true
        local DL = imgui.GetBackgroundDrawList()

        if renderOre[0] and (showOreLine[0] or showOreDistance[0]) then
            local ok_p, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
            if ok_p and px and #ore3dCache > 0 then
                local cx, cy  = convert3DCoordsToScreen(px, py, pz)
                local radius  = renderRadius[0]
                local col3d   = imgui.GetColorU32Vec4(V4(0.45,0.72,0.30,0.95))
                local lineShadow = U32(0,0,0,0.35)
                for _, entry in ipairs(ore3dCache) do
                    local ox,oy,oz = entry[1],entry[2],entry[3]
                    local dist = safeDist3d(ox,oy,oz,px,py,pz)
                    if dist <= radius and isPointOnScreen(ox, oy, oz, 0) then
                        local ok_s, sx, sy = pcall(convert3DCoordsToScreen, ox, oy, oz)
                        if ok_s and sx and sy then
                            if showOreLine[0] then
                                DL:AddLine(V2(cx,cy), V2(sx,sy), lineShadow, 3.5*MDS)
                                DL:AddLine(V2(cx,cy), V2(sx,sy), col3d, 1.8*MDS)
                            end
                            local lbl = ORE_LABEL
                            if showOreDistance[0] then lbl = lbl..' ['..math.floor(dist)..']' end
                            local fnt = font[renderSize[0]]
                            local fsz = renderSize[0] * MDS
                            local tsz = imgui.CalcTextSize(lbl)
                            local lx = sx - tsz.x*.5
                            local ly = sy - fsz - 2*MDS
                            if fnt then
                                DL:AddTextFontPtr(fnt, fsz, V2(lx,ly), col3d, lbl)
                            else
                                DL:AddText(V2(lx,ly), col3d, lbl)
                            end
                        end
                    end
                end
            end
        end

        if oreTimer[0] then
            local ok0, mx, my, mz = pcall(getCharCoordinates, PLAYER_PED)
            if ok0 and mx then
                local cx, cy = convert3DCoordsToScreen(mx, my, mz)
                for k = #oreTimerList, 1, -1 do
                    local v    = oreTimerList[k]
                    local diff = v[4] - os.time()
                    if diff < 0 then
                        table.remove(oreTimerList, k)
                    else
                        local ok_s, tx, ty = pcall(convert3DCoordsToScreen, v[1], v[2], v[3])
                        if ok_s and tx and ty then
                            local dist    = math.floor(safeDist3d(v[1],v[2],v[3],mx,my,mz))
                            local timeStr = os.date('%M:%S', diff)
                            local text
                            if diff < 60 then
                                text = ORE_REMAIN..timeStr..'!'
                                    ..(oreTimerDistance[0] and (' ['..dist..']') or '')
                            else
                                text = timeStr..(oreTimerDistance[0] and (' ['..dist..']') or '')
                            end
                            if isPointOnScreen(v[1], v[2], v[3], 0) then
                                local fnt = font[renderOreTimerSize[0]]
                                local fsz = renderOreTimerSize[0] * MDS
                                local tsz = imgui.CalcTextSize(text)
                                local lx  = tx - tsz.x*.5
                                local ly  = ty - fsz - 2*MDS
                                local tcol = imgui.GetColorU32Vec4(argbToVec4(colorOreTimer))
                                if fnt then
                                    DL:AddTextFontPtr(fnt, fsz, V2(lx,ly), tcol, text)
                                else
                                    DL:AddText(V2(lx,ly), tcol, text)
                                end
                                if oreTimerLine[0] then
                                    DL:AddLine(V2(tx,ty), V2(cx,cy), tcol, 1.8*MDS)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
)

-- ===== KEEP: CJ run + infinite run =====
function enableCj()
    if cj[0] then
        setAnimGroupForChar(PLAYER_PED, "PLAYER")
    else
        setAnimGroupForChar(PLAYER_PED, isCharMale(PLAYER_PED) and "MAN" or "WOMAN")
    end
end

function enableBesk()
    if beskbeg[0] then
        setPlayerNeverGetsTired(PLAYER_HANDLE, true)
    else
        setPlayerNeverGetsTired(PLAYER_HANDLE, false)
    end
end

-- ===== ore 3d-text detection (from Mine Tools) =====
function sampev.onCreate3DText(id, color, position, dist, testLOS, player, vehicle, text)
    if type(text) ~= 'string' then return end
    if text:find('\xcc\xe5\xf1\xf2\xee\xf0\xee\xe6\xe4\xe5\xed\xe8\xe5') then
        local px = tonumber(type(position)=='table' and position.x or nil)
        local py = tonumber(type(position)=='table' and position.y or nil)
        local pz = tonumber(type(position)=='table' and position.z or nil)
        if px and py and pz then
            textsTable[id] = {x=px, y=py, z=pz}
        end
    end
    if text:find('\xcc\xe5\xf1\xf2\xee\xf0\xee\xe6\xe4\xe5\xed\xe8\xe5 \xf0\xe5\xf1\xf3\xf0\xf1\xee\xe2') then
        local px = tonumber(type(position)=='table' and position.x or nil)
        local py = tonumber(type(position)=='table' and position.y or nil)
        local pz = tonumber(type(position)=='table' and position.z or nil)
        if not (px and py and pz) then return end
        for k, v in ipairs(oreTimerList) do
            if v[1]==px and v[2]==py and v[3]==pz then
                table.remove(oreTimerList, k); break
            end
        end
    end
end

function sampev.onRemove3DTextLabel(id)
    if textsTable[id] then
        local info = textsTable[id]
        local ok, text2 = pcall(function()
            local t = sampGet3dTextInfoById(id)
            return t
        end)
        if ok and text2 and text2:find('\xcc\xe5\xf1\xf2\xee\xf0\xee\xe6\xe4\xe5\xed\xe8\xe5 \xf0\xe5\xf1\xf3\xf0\xf1\xee\xe2') then
            if info.x and info.y and info.z then
                table.insert(oreTimerList, {info.x, info.y, info.z, os.time()+375})
            end
        end
        textsTable[id] = nil
    end
end

-- ===== auto dig (from Mine Tools) =====
function sampev.onSendPlayerSync(data)
    if autoDig[0] then
        digCounter = digCounter + 1
        if digCounter >= 3 then
            digCounter = 0
            local px = tonumber(data.position and data.position.x) or 0
            local py = tonumber(data.position and data.position.y) or 0
            local pz = tonumber(data.position and data.position.z) or 0
            local near = false
            for _, v in pairs(textsTable) do
                if safeDist3d(px,py,pz, v.x,v.y,v.z) < 3.0 then near = true; break end
            end
            if not near then
                for _, v in ipairs(ore3dCache) do
                    if safeDist3d(px,py,pz, v[1],v[2],v[3]) < 3.0 then near = true; break end
                end
            end
            if near then data.keysData = 1024 end
        end
    end
end

function main()
    while not isSampAvailable() do wait(0) end

    sampRegisterChatCommand('minetik', function()
        WinState[0] = not WinState[0]
    end)
    sampRegisterChatCommand('mtore', function()
        renderOre[0] = not renderOre[0]; saveConfig()
    end)
    sampRegisterChatCommand('mttimer', function()
        oreTimer[0] = not oreTimer[0]; saveConfig()
    end)

    -- background scan: collect "\xcc\xe5\xf1\xf2\xee\xf0\xee\xe6\xe4\xe5\xed\xe8\xe5 \xf0\xe5\xf1\xf3\xf0\xf1\xee\xe2" 3d-texts for ore search
    lua_thread.create(function()
        while true do
            wait(1500)
            if not (renderOre[0] and (showOreLine[0] or showOreDistance[0])) and not autoDig[0] then
                ore3dCache = {}
            else
                local tmp = {}
                for tid = 0, 2048 do
                    if tid % 256 == 0 then wait(0) end
                    local ok_t, defined = pcall(sampIs3dTextDefined, tid)
                    if ok_t and defined then
                        local ok_i, ttext, _, ox, oy, oz = pcall(function()
                            local t,c,x,y,z = sampGet3dTextInfoById(tid)
                            return t,c,x,y,z
                        end)
                        if ok_i and ttext and ttext:find('\xcc\xe5\xf1\xf2\xee\xf0\xee\xe6\xe4\xe5\xed\xe8\xe5') then
                            local nx2,ny2,nz2 = tonumber(ox),tonumber(oy),tonumber(oz)
                            if nx2 and ny2 and nz2 then
                                table.insert(tmp, {nx2, ny2, nz2})
                            end
                        end
                    end
                end
                ore3dCache = tmp
            end
        end
    end)

    pushLog(u8('\xc7\xe0\xe3\xf0\xf3\xe6\xe5\xed: mineTOOL v1.1'))

    while true do
        wait(0)
    end
end
