-- interface_logger_v4.lua
-- /il          -- окно вкл/выкл
-- /ilclear     -- очистить лог
-- /ilsave      -- сохранить лог в файл
-- /ilsend <iid> <bid> <sub> [data]  -- ручная отправка клика

script_name('InterfaceLogger')
script_author('Victor Strand')
script_version('4.1')

local imgui = require('mimgui')
local enc   = require('encoding')
enc.default = 'CP1251'
local u8  = enc.UTF8
local new = imgui.new
local MDS = MONET_DPI_SCALE
local sw, sh = getScreenResolution()

-- ===================================================
--  СТРОКИ (CP1251 hex -> u8() -> UTF-8 для imgui)
-- ===================================================
local S = {
    -- imgui заголовки (CP1251 байты через u8())
    title      = u8('\xc8\xed\xf2\xe5\xf0\xf4\xe5\xe9\xf1 \xcb\xee\xe3\xe3\xe5\xf0 v4'),
    rec_on     = u8('\xc7\xc0\xcf\xc8\xd1\xdc  \xc2\xca\xcb'),
    rec_off    = u8('\xc7\xc0\xcf\xc8\xd1\xdc  \xc2\xdb\xca\xcb'),
    clear      = u8('\xce\xf7\xe8\xf1\xf2\xe8\xf2\xfc'),
    save_btn   = u8('\xd1\xee\xf5\xf0\xe0\xed\xe8\xf2\xfc \xeb\xee\xe3'),
    autoscroll = u8('\xc0\xe2\xf2\xee\xf1\xea\xf0\xee\xeb\xeb'),
    iid_list   = u8('\xd1\xef\xe8\xf1\xee\xea IID'),
    all_iids   = u8('[ \xc2\xf1\xe5 IID ]'),
    game_tag   = '[GAME]',
    pkt_in     = '[IN ]',
    pkt_out    = '[OUT]',
}

-- ===================================================
--  СОСТОЯНИЕ
-- ===================================================
local recording = true
local entries   = {}
local iidInfo   = {}   -- iid -> { count, isGame }
local MAX_ENT   = 300

local mainWindow = new.bool(false)
local filterIID  = new.int(-1)
local autoScroll = new.bool(true)

local function isGameData(str)
    return str:find('"isMyState"') ~= nil
        or str:find('lumbering')   ~= nil
        or str:find('mini%-game')  ~= nil
        or str:find('miniGame')    ~= nil
end

local function addEntry(dir, iid, data)
    local g = isGameData(data or '')
    if not iidInfo[iid] then iidInfo[iid] = {count = 0, isGame = false} end
    iidInfo[iid].count = iidInfo[iid].count + 1
    if g then iidInfo[iid].isGame = true end
    if #entries >= MAX_ENT then table.remove(entries, 1) end
    table.insert(entries, {
        time   = os.date('%H:%M:%S'),
        dir    = dir,
        iid    = iid,
        data   = data or '',
        isGame = g,
    })
end

-- ===================================================
--  СОХРАНЕНИЕ ЛОГА В ФАЙЛ
-- ===================================================
local function saveLog()
    local dir = getWorkingDirectory() .. '/logs'
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    local fname  = 'ilog_' .. os.date('%Y%m%d_%H%M%S') .. '.txt'
    local fpath  = dir .. '/' .. fname
    local f = io.open(fpath, 'w')
    if not f then
        sampAddChatMessage('{FF4444}[IL] Save failed: cannot create file', -1)
        return
    end
    local fi = filterIID[0]
    local n  = 0
    for _, e in ipairs(entries) do
        if fi == -1 or e.iid == fi then
            f:write(string.format('[%s] [%s] IID=%-3d  %s\n',
                e.time, e.dir, e.iid, e.data))
            n = n + 1
        end
    end
    f:close()
    sampAddChatMessage('{2ECC71}[IL] Saved ' .. n .. ' lines:', -1)
    sampAddChatMessage('{FFFFFF}' .. fpath, -1)
end

-- ===================================================
--  ШРИФТЫ И СТИЛЬ
-- ===================================================
local fMain, fMono, fTitle

imgui.OnInitialize(function()
    imgui.SwitchContext()
    local io = imgui.GetIO()
    io.IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)

    local ttf = getWorkingDirectory() .. '/lib/mimgui/trebucbd.ttf'
    if doesFileExist(ttf) then
        local r = io.Fonts:GetGlyphRangesCyrillic()
        fTitle = io.Fonts:AddFontFromFileTTF(ttf, 17*MDS, nil, r)
        fMain  = io.Fonts:AddFontFromFileTTF(ttf, 14*MDS, nil, r)
        fMono  = io.Fonts:AddFontFromFileTTF(ttf, 12*MDS, nil, r)
    end

    local s = imgui.GetStyle()
    s.WindowPadding   = imgui.ImVec2(10*MDS, 10*MDS)
    s.FramePadding    = imgui.ImVec2(7*MDS,  5*MDS)
    s.ItemSpacing     = imgui.ImVec2(6*MDS,  4*MDS)
    s.WindowRounding  = 8*MDS
    s.FrameRounding   = 5*MDS
    s.ChildRounding   = 5*MDS
    s.ScrollbarSize   = 10*MDS
    s.WindowBorderSize = 1
    s.ChildBorderSize  = 1

    local c = s.Colors
    local I = imgui.Col
    c[I.WindowBg]          = imgui.ImVec4(0.06, 0.06, 0.09, 0.97)
    c[I.ChildBg]           = imgui.ImVec4(0.04, 0.04, 0.07, 1.00)
    c[I.Border]            = imgui.ImVec4(0.16, 0.16, 0.24, 1.00)
    c[I.FrameBg]           = imgui.ImVec4(0.10, 0.10, 0.15, 1.00)
    c[I.FrameBgHovered]    = imgui.ImVec4(0.16, 0.16, 0.22, 1.00)
    c[I.Button]            = imgui.ImVec4(0.12, 0.12, 0.18, 1.00)
    c[I.ButtonHovered]     = imgui.ImVec4(0.19, 0.19, 0.28, 1.00)
    c[I.ButtonActive]      = imgui.ImVec4(0.08, 0.08, 0.12, 1.00)
    c[I.Header]            = imgui.ImVec4(0.12, 0.12, 0.18, 1.00)
    c[I.HeaderHovered]     = imgui.ImVec4(0.19, 0.19, 0.28, 1.00)
    c[I.CheckMark]         = imgui.ImVec4(0.18, 0.85, 0.45, 1.00)
    c[I.Text]              = imgui.ImVec4(0.88, 0.88, 0.92, 1.00)
    c[I.TextDisabled]      = imgui.ImVec4(0.38, 0.38, 0.46, 1.00)
    c[I.ScrollbarBg]       = imgui.ImVec4(0.03, 0.03, 0.05, 1.00)
    c[I.ScrollbarGrab]     = imgui.ImVec4(0.18, 0.85, 0.45, 0.70)
    c[I.ScrollbarGrabHovered] = imgui.ImVec4(0.18, 0.85, 0.45, 1.00)
    c[I.Separator]         = imgui.ImVec4(0.16, 0.16, 0.26, 1.00)
    c[I.TitleBg]           = imgui.ImVec4(0.04, 0.04, 0.07, 1.00)
    c[I.TitleBgActive]     = imgui.ImVec4(0.05, 0.05, 0.09, 1.00)
end)

-- ===================================================
--  ЦВЕТА
-- ===================================================
local C_IN   = imgui.ImVec4(0.35, 0.75, 1.00, 1.0)
local C_OUT  = imgui.ImVec4(1.00, 0.58, 0.28, 1.0)
local C_GAME = imgui.ImVec4(0.18, 1.00, 0.50, 1.0)
local C_DATA = imgui.ImVec4(0.55, 0.88, 0.68, 0.90)
local C_MUTED= imgui.ImVec4(0.40, 0.40, 0.50, 1.0)
local C_IID  = imgui.ImVec4(0.85, 0.90, 1.00, 1.0)

-- ===================================================
--  UI
-- ===================================================
imgui.OnFrame(
    function() return mainWindow[0] end,
    function(self)
        self.HideCursor = false
        if fMain then imgui.PushFont(fMain) end

        -- Окно ~половина экрана
        imgui.SetNextWindowSize(
            imgui.ImVec2(sw * 0.5, sh * 0.5),
            imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(
            imgui.ImVec2(sw/2, sh/2),
            imgui.Cond.FirstUseEver,
            imgui.ImVec2(0.5, 0.5))

        local wF = imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
        if fTitle then imgui.PushFont(fTitle) end
        imgui.Begin(S.title, mainWindow, wF)
        if fTitle then imgui.PopFont() end

        -- ------------------------------------------------
        -- Шапка
        -- ------------------------------------------------
        local bH = 32 * MDS

        -- Кнопка записи
        if recording then
            imgui.PushStyleColor(imgui.Col.Button,
                imgui.ImVec4(0.06, 0.44, 0.22, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered,
                imgui.ImVec4(0.08, 0.56, 0.28, 1))
        else
            imgui.PushStyleColor(imgui.Col.Button,
                imgui.ImVec4(0.32, 0.08, 0.08, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered,
                imgui.ImVec4(0.46, 0.12, 0.12, 1))
        end
        imgui.PushStyleColor(imgui.Col.ButtonActive,
            imgui.ImVec4(0.04, 0.04, 0.07, 1))
        if imgui.Button(recording and S.rec_on or S.rec_off,
                imgui.ImVec2(160*MDS, bH)) then
            recording = not recording
            sampAddChatMessage(
                recording and '{2ECC71}[IL] Recording ON'
                           or '{E74C3C}[IL] Recording OFF', -1)
        end
        imgui.PopStyleColor(3)

        imgui.SameLine()
        if imgui.Button(S.clear, imgui.ImVec2(100*MDS, bH)) then
            entries = {}
            iidInfo = {}
            filterIID[0] = -1
            sampAddChatMessage('{AAAAAA}[IL] Log cleared.', -1)
        end

        imgui.SameLine()
        imgui.PushStyleColor(imgui.Col.Button,
            imgui.ImVec4(0.08, 0.22, 0.14, 1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered,
            imgui.ImVec4(0.12, 0.32, 0.20, 1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,
            imgui.ImVec4(0.04, 0.04, 0.07, 1))
        if imgui.Button(S.save_btn, imgui.ImVec2(160*MDS, bH)) then
            saveLog()
        end
        imgui.PopStyleColor(3)

        imgui.SameLine()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5*MDS)
        imgui.Checkbox(S.autoscroll, autoScroll)

        imgui.SameLine()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5*MDS)
        imgui.PushStyleColor(imgui.Col.Text, C_MUTED)
        imgui.Text(#entries .. ' / ' .. MAX_ENT)
        imgui.PopStyleColor()

        imgui.Separator()

        -- ------------------------------------------------
        -- Тело: левая панель (IID) + правая (пакеты)
        -- ------------------------------------------------
        local avail  = imgui.GetContentRegionAvail()
        local leftW  = 210 * MDS
        local rightW = avail.x - leftW - 8*MDS
        local bodyH  = avail.y

        -- ЛЕВАЯ ПАНЕЛЬ
        imgui.BeginChild('##left', imgui.ImVec2(leftW, bodyH), true)

        imgui.PushStyleColor(imgui.Col.Text, C_GAME)
        if fMain then imgui.PushFont(fMain) end
        imgui.Text(S.iid_list)
        if fMain then imgui.PopFont() end
        imgui.PopStyleColor()
        imgui.Spacing()

        -- Кнопка "Все IID"
        local allSel = (filterIID[0] == -1)
        imgui.PushStyleColor(imgui.Col.Button,
            allSel and imgui.ImVec4(0.14, 0.46, 0.26, 1)
                   or  imgui.ImVec4(0.10, 0.10, 0.16, 1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered,
            imgui.ImVec4(0.18, 0.56, 0.32, 1))
        if imgui.Button(S.all_iids, imgui.ImVec2(-1, 30*MDS)) then
            filterIID[0] = -1
        end
        imgui.PopStyleColor(2)
        imgui.Spacing()

        -- Кнопки IID
        local sorted = {}
        for iid in pairs(iidInfo) do sorted[#sorted+1] = iid end
        table.sort(sorted)

        for _, iid in ipairs(sorted) do
            local info = iidInfo[iid]
            local sel  = (filterIID[0] == iid)

            if info.isGame then
                imgui.PushStyleColor(imgui.Col.Button,
                    sel and imgui.ImVec4(0.08, 0.40, 0.18, 1)
                        or  imgui.ImVec4(0.06, 0.24, 0.12, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered,
                    imgui.ImVec4(0.10, 0.50, 0.22, 1))
            else
                imgui.PushStyleColor(imgui.Col.Button,
                    sel and imgui.ImVec4(0.16, 0.16, 0.28, 1)
                        or  imgui.ImVec4(0.10, 0.10, 0.16, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered,
                    imgui.ImVec4(0.20, 0.20, 0.32, 1))
            end

            local lbl = (info.isGame and '[G] ' or '     ') .. 'IID ' .. iid
            if imgui.Button(lbl, imgui.ImVec2(-1, 30*MDS)) then
                filterIID[0] = (filterIID[0] == iid) and -1 or iid
            end
            imgui.PopStyleColor(2)

            if fMono then imgui.PushFont(fMono) end
            imgui.PushStyleColor(imgui.Col.Text, C_MUTED)
            imgui.Text('  x' .. info.count
                .. (info.isGame and '  <-- GAME' or ''))
            imgui.PopStyleColor()
            if fMono then imgui.PopFont() end
            imgui.Spacing()
        end

        imgui.EndChild()
        imgui.SameLine()

        -- ПРАВАЯ ПАНЕЛЬ — поток пакетов
        imgui.BeginChild('##right', imgui.ImVec2(rightW, bodyH), true)
        if fMono then imgui.PushFont(fMono) end

        local fi = filterIID[0]
        for _, e in ipairs(entries) do
            if fi == -1 or e.iid == fi then

                -- Зелёная полоска для игровых пакетов
                if e.isGame then
                    local dl = imgui.GetWindowDrawList()
                    local cp = imgui.GetCursorScreenPos()
                    local cw = imgui.GetContentRegionAvail().x
                    local hh = 20 * MDS
                    dl:AddRectFilled(
                        imgui.ImVec2(cp.x,      cp.y),
                        imgui.ImVec2(cp.x + cw, cp.y + hh),
                        0xFF0D3014, 3*MDS)
                    dl:AddRectFilled(
                        imgui.ImVec2(cp.x,          cp.y),
                        imgui.ImVec2(cp.x + 3*MDS,  cp.y + hh),
                        0xFF40E060, 2*MDS)
                    imgui.Dummy(imgui.ImVec2(cw, hh))
                    imgui.SetCursorScreenPos(
                        imgui.ImVec2(cp.x + 8*MDS, cp.y + (hh - 12*MDS)/2))
                    imgui.PushStyleColor(imgui.Col.Text, C_GAME)
                    imgui.Text(S.game_tag)
                    imgui.PopStyleColor()
                    imgui.SameLine()
                end

                -- Время
                imgui.PushStyleColor(imgui.Col.Text, C_MUTED)
                imgui.Text('[' .. e.time .. ']')
                imgui.PopStyleColor()
                imgui.SameLine()

                -- Направление
                imgui.PushStyleColor(imgui.Col.Text,
                    e.dir == 'IN' and C_IN or C_OUT)
                imgui.Text(e.dir == 'IN' and S.pkt_in or S.pkt_out)
                imgui.PopStyleColor()
                imgui.SameLine()

                -- IID
                imgui.PushStyleColor(imgui.Col.Text, C_IID)
                imgui.Text('IID=' .. e.iid)
                imgui.PopStyleColor()

                -- Данные
                if e.data ~= '' then
                    imgui.PushStyleColor(imgui.Col.Text, C_DATA)
                    imgui.PushTextWrapPos(
                        imgui.GetCursorPosX() + rightW - 14*MDS)
                    imgui.Text('  ' .. e.data:sub(1, 500))
                    imgui.PopTextWrapPos()
                    imgui.PopStyleColor()
                end

                imgui.Separator()
            end
        end

        if fMono then imgui.PopFont() end
        if autoScroll[0] then imgui.SetScrollHereY(1.0) end
        imgui.EndChild()

        if fMain then imgui.PopFont() end
        imgui.End()
    end
)

-- ===================================================
--  ПЕРЕХВАТ ПАКЕТОВ
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if pid ~= 220 or not recording then return end
    raknetBitStreamSetReadOffset(bs, 0)
    local ok0, _  = pcall(raknetBitStreamReadInt8, bs)
    local ok1, b1 = pcall(raknetBitStreamReadInt8, bs)
    if not ok0 or not ok1 then return end

    local oi, iid = pcall(raknetBitStreamReadInt8, bs)
    if not oi then return end

    if b1 == 84 then
        -- FM: sub + JSON data
        local os, sub = pcall(raknetBitStreamReadInt8, bs)
        if not os then return end
        local ol, len = pcall(raknetBitStreamReadInt32, bs)
        local data = 'FM sub=' .. sub
        if ol and len and len > 0 and len < 8192 then
            local od, s = pcall(raknetBitStreamReadString, bs, len)
            if od and s and #s > 0 then data = data .. ' | ' .. s:sub(1, 500) end
        end
        addEntry('IN', iid, data)

    elseif b1 == 62 then
        -- TOGGLE: ON/OFF
        local ob, state = pcall(raknetBitStreamReadBool, bs)
        addEntry('IN', iid, 'TOGGLE ' .. (ob and (state and 'ON' or 'OFF') or '?'))
    end
end)

addEventHandler('onSendPacket', function(pid, bs)
    if pid ~= 220 or not recording then return end
    raknetBitStreamSetReadOffset(bs, 0)
    local ok0, _  = pcall(raknetBitStreamReadInt8, bs)
    local ok1, b1 = pcall(raknetBitStreamReadInt8, bs)
    if not ok0 or not ok1 or b1 ~= 63 then return end

    local oi, iid = pcall(raknetBitStreamReadInt8, bs)
    if not oi then return end
    local ob, bid = pcall(raknetBitStreamReadInt32, bs)
    local os, sub = pcall(raknetBitStreamReadInt32, bs)
    local ol, len = pcall(raknetBitStreamReadInt32, bs)
    local extra = 'bid=' .. (ob and tostring(bid) or '?')
        .. ' sub=' .. (os and tostring(sub) or '?')
    if ol and len and len > 0 and len < 8192 then
        local od, d = pcall(raknetBitStreamReadString, bs, len)
        if od and d and #d > 0 then
            extra = extra .. ' | ' .. d:sub(1, 200)
        end
    end
    addEntry('OUT', iid, extra)
end)

-- ===================================================
--  РУЧНАЯ ОТПРАВКА КЛИКА
-- ===================================================
local function sendClick(iid, bid, sub, data)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 63)
    raknetBitStreamWriteInt8(bs, iid)
    raknetBitStreamWriteInt32(bs, bid)
    raknetBitStreamWriteInt32(bs, sub)
    local d = data or ''
    raknetBitStreamWriteInt32(bs, #d)
    if #d > 0 then raknetBitStreamWriteString(bs, d) end
    raknetSendBitStreamEx(bs, 1, 10, 1)
    raknetDeleteBitStream(bs)
end

-- ===================================================
--  MAIN
-- ===================================================
function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(500) end

    sampRegisterChatCommand('il', function()
        mainWindow[0] = not mainWindow[0]
    end)

    sampRegisterChatCommand('ilclear', function()
        entries = {}
        iidInfo = {}
        filterIID[0] = -1
        sampAddChatMessage('{AAAAAA}[IL] Log cleared.', -1)
    end)

    sampRegisterChatCommand('ilsave', function()
        saveLog()
    end)

    sampRegisterChatCommand('ilsend', function(args)
        local iid, bid, sub, data = args:match('^(%d+)%s+(%d+)%s+(%d+)%s*(.*)')
        if not iid then
            sampAddChatMessage('{FF4444}[IL] /ilsend <iid> <bid> <sub> [data]', -1)
            return
        end
        sendClick(tonumber(iid), tonumber(bid), tonumber(sub),
            data ~= '' and data or nil)
        sampAddChatMessage('{CC44FF}[IL] Sent IID=' .. iid
            .. ' bid=' .. bid .. ' sub=' .. sub, -1)
    end)

    sampAddChatMessage(
        '{00FFCC}[IL v4]{FFFFFF} /il | /ilclear | /ilsave | /ilsend <iid> <bid> <sub> [data]',
        -1)

    while true do wait(0) end
end
