-- interface_logger_v4.lua
-- /il          -- окно вкл/выкл
-- /ilclear     -- очистить лог
-- /ilsend <iid> <bid> <sub> [data]  -- ручная отправка клика

script_name('InterfaceLogger')
script_author('Victor Strand')
script_version('4.0')

local imgui = require('mimgui')
local enc   = require('encoding')
enc.default = 'CP1251'
local u8  = enc.UTF8
local new = imgui.new
local MDS = MONET_DPI_SCALE
local sw, sh = getScreenResolution()

-- ===================================================
--  СОСТОЯНИЕ
-- ===================================================
local recording = true  -- запись включена сразу
local entries   = {}    -- { time, dir, iid, data, isGame }
local iidInfo   = {}    -- iid -> { count, isGame }
local MAX_ENT   = 300

local mainWindow = new.bool(false)
local filterIID  = new.int(-1)
local autoScroll = new.bool(true)

-- Пакет помечается как игровой если содержит признаки мини-игры
local function isGameData(str)
    return str:find('"isMyState"') ~= nil
        or str:find('lumbering') ~= nil
        or str:find('mini%-game') ~= nil
        or str:find('miniGame')  ~= nil
end

local function addEntry(dir, iid, data)
    local isGame = isGameData(data or '')
    if not iidInfo[iid] then iidInfo[iid] = { count = 0, isGame = false } end
    iidInfo[iid].count  = iidInfo[iid].count + 1
    if isGame then iidInfo[iid].isGame = true end

    if #entries >= MAX_ENT then table.remove(entries, 1) end
    table.insert(entries, {
        time   = os.date('%H:%M:%S'),
        dir    = dir,
        iid    = iid,
        data   = data or '',
        isGame = isGame,
    })
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
        fTitle = io.Fonts:AddFontFromFileTTF(ttf, 16*MDS, nil, r)
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
    s.WindowBorderSize= 1
    s.ChildBorderSize = 1

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
--  ЦВЕТА UI
-- ===================================================
local C_IN    = imgui.ImVec4(0.35, 0.75, 1.00, 1.0)   -- входящий
local C_OUT   = imgui.ImVec4(1.00, 0.58, 0.28, 1.0)   -- исходящий
local C_GAME  = imgui.ImVec4(0.18, 1.00, 0.50, 1.0)   -- игровой пакет
local C_DATA  = imgui.ImVec4(0.55, 0.88, 0.68, 0.90)  -- данные
local C_MUTED = imgui.ImVec4(0.40, 0.40, 0.50, 1.0)   -- вторичный текст
local C_IID   = imgui.ImVec4(0.85, 0.90, 1.00, 1.0)   -- IID

-- ===================================================
--  UI
-- ===================================================
imgui.OnFrame(
    function() return mainWindow[0] end,
    function(self)
        self.HideCursor = false
        if fMain then imgui.PushFont(fMain) end

        imgui.SetNextWindowSize(imgui.ImVec2(720*MDS, 530*MDS), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(
            imgui.ImVec2(sw/2, sh/2),
            imgui.Cond.FirstUseEver,
            imgui.ImVec2(0.5, 0.5))

        local wFlags = imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
        if fTitle then imgui.PushFont(fTitle) end
        imgui.Begin(u8('Interface Logger v4'), mainWindow, wFlags)
        if fTitle then imgui.PopFont() end

        -- ------------------------------------------------
        -- Шапка: кнопки управления
        -- ------------------------------------------------
        local bH = 28 * MDS

        -- Кнопка запись
        if recording then
            imgui.PushStyleColor(imgui.Col.Button,
                imgui.ImVec4(0.06, 0.44, 0.22, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered,
                imgui.ImVec4(0.08, 0.56, 0.28, 1))
        else
            imgui.PushStyleColor(imgui.Col.Button,
                imgui.ImVec4(0.30, 0.08, 0.08, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered,
                imgui.ImVec4(0.44, 0.12, 0.12, 1))
        end
        imgui.PushStyleColor(imgui.Col.ButtonActive,
            imgui.ImVec4(0.05, 0.05, 0.08, 1))
        if imgui.Button(
            recording and u8('  ЗАПИСЬ ВКЛ  ') or u8('  ЗАПИСЬ ВЫКЛ  '),
            imgui.ImVec2(130*MDS, bH)) then
            recording = not recording
        end
        imgui.PopStyleColor(3)

        imgui.SameLine()
        if imgui.Button(u8('Очистить'), imgui.ImVec2(90*MDS, bH)) then
            entries  = {}
            iidInfo  = {}
            filterIID[0] = -1
        end

        imgui.SameLine()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 4*MDS)
        imgui.Checkbox(u8('Автоскролл'), autoScroll)

        imgui.SameLine()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 4*MDS)
        imgui.PushStyleColor(imgui.Col.Text, C_MUTED)
        imgui.Text(#entries .. ' / ' .. MAX_ENT)
        imgui.PopStyleColor()

        imgui.Separator()

        -- ------------------------------------------------
        -- Тело: левая колонка (IID список) + правая (пакеты)
        -- ------------------------------------------------
        local avail  = imgui.GetContentRegionAvail()
        local leftW  = 185 * MDS
        local rightW = avail.x - leftW - 8*MDS
        local bodyH  = avail.y

        -- ЛЕВАЯ ПАНЕЛЬ — список IID
        imgui.BeginChild('##left', imgui.ImVec2(leftW, bodyH), true)

        imgui.PushStyleColor(imgui.Col.Text, C_GAME)
        imgui.Text(u8('Список IID'))
        imgui.PopStyleColor()
        imgui.Spacing()

        -- Кнопка "Все"
        local allSel = (filterIID[0] == -1)
        imgui.PushStyleColor(imgui.Col.Button,
            allSel and imgui.ImVec4(0.14, 0.46, 0.26, 1)
                   or  imgui.ImVec4(0.10, 0.10, 0.16, 1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered,
            imgui.ImVec4(0.18, 0.56, 0.32, 1))
        if imgui.Button(u8('[ Все IID ]'), imgui.ImVec2(-1, 26*MDS)) then
            filterIID[0] = -1
        end
        imgui.PopStyleColor(2)
        imgui.Spacing()

        -- IID кнопки, сортированные
        local sorted = {}
        for iid in pairs(iidInfo) do sorted[#sorted+1] = iid end
        table.sort(sorted)

        for _, iid in ipairs(sorted) do
            local info = iidInfo[iid]
            local sel  = (filterIID[0] == iid)

            if info.isGame then
                -- Игровой IID — зелёный
                imgui.PushStyleColor(imgui.Col.Button,
                    sel and imgui.ImVec4(0.08, 0.38, 0.18, 1)
                        or  imgui.ImVec4(0.06, 0.22, 0.12, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered,
                    imgui.ImVec4(0.10, 0.48, 0.22, 1))
            else
                imgui.PushStyleColor(imgui.Col.Button,
                    sel and imgui.ImVec4(0.16, 0.16, 0.28, 1)
                        or  imgui.ImVec4(0.10, 0.10, 0.16, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered,
                    imgui.ImVec4(0.20, 0.20, 0.32, 1))
            end

            local label = (info.isGame and '[GAME] ' or '       ')
                .. 'IID ' .. iid
            if imgui.Button(label, imgui.ImVec2(-1, 26*MDS)) then
                filterIID[0] = (filterIID[0] == iid) and -1 or iid
            end
            imgui.PopStyleColor(2)

            -- Счётчик пакетов под кнопкой
            if fMono then imgui.PushFont(fMono) end
            imgui.PushStyleColor(imgui.Col.Text, C_MUTED)
            imgui.Text(string.format('  %d пакет(ов)', info.count))
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

                -- Игровой пакет — яркий заголовок
                if e.isGame then
                    local dl = imgui.GetWindowDrawList()
                    local cp = imgui.GetCursorScreenPos()
                    local cw = imgui.GetContentRegionAvail().x
                    local hh = 20 * MDS
                    dl:AddRectFilled(
                        imgui.ImVec2(cp.x,      cp.y),
                        imgui.ImVec2(cp.x + cw, cp.y + hh),
                        0xFF0F3518, 3*MDS)
                    dl:AddRectFilled(
                        imgui.ImVec2(cp.x,           cp.y),
                        imgui.ImVec2(cp.x + 3*MDS,   cp.y + hh),
                        0xFF40E060, 2*MDS)
                    imgui.Dummy(imgui.ImVec2(cw, hh))
                    imgui.SetCursorScreenPos(
                        imgui.ImVec2(cp.x + 8*MDS, cp.y + (hh - 12*MDS)/2))

                    imgui.PushStyleColor(imgui.Col.Text, C_GAME)
                    imgui.Text('[GAME]')
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
                imgui.Text(e.dir == 'IN' and '[IN ]' or '[OUT]')
                imgui.PopStyleColor()
                imgui.SameLine()

                -- IID
                imgui.PushStyleColor(imgui.Col.Text, C_IID)
                imgui.Text('IID=' .. e.iid)
                imgui.PopStyleColor()

                -- Данные
                if e.data ~= '' then
                    imgui.PushStyleColor(imgui.Col.Text, C_DATA)
                    imgui.PushTextWrapPos(imgui.GetCursorPosX() + rightW - 16*MDS)
                    imgui.Text('  ' .. e.data:sub(1, 300))
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
    if not ok0 or not ok1 or b1 ~= 84 then return end

    local oi, iid = pcall(raknetBitStreamReadInt8, bs)
    local os, sub = pcall(raknetBitStreamReadInt8, bs)
    if not oi or not os then return end

    local ol, len = pcall(raknetBitStreamReadInt32, bs)
    if not ol or len <= 0 or len > 8192 then return end

    local od, data = pcall(raknetBitStreamReadString, bs, len)
    if not od or not data then return end

    addEntry('IN', iid, data)
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
        entries  = {}
        iidInfo  = {}
        filterIID[0] = -1
        sampAddChatMessage('{00FFCC}[IL] Лог очищен.', -1)
    end)

    sampRegisterChatCommand('ilsend', function(args)
        local iid, bid, sub, data = args:match('^(%d+)%s+(%d+)%s+(%d+)%s*(.*)')
        if not iid then
            sampAddChatMessage('{FF4444}[IL] /ilsend <iid> <bid> <sub> [data]', -1)
            return
        end
        sendClick(tonumber(iid), tonumber(bid), tonumber(sub),
            data ~= '' and data or nil)
        sampAddChatMessage('{CC44FF}[IL] Отправлено IID=' .. iid
            .. ' bid=' .. bid .. ' sub=' .. sub, -1)
    end)

    sampAddChatMessage(
        '{00FFCC}[IL v4]{FFFFFF} /il — окно | /ilclear — очистить | /ilsend <iid> <bid> <sub> [data]',
        -1)

    while true do wait(0) end
end
