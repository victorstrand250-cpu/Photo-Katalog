script_author = "Gorskin"
script_name = "[GameFixer]"
script_version = "2.1-monet"
-- Thanks to Black Jesus for cleo GameFixer 2.0
--
-- ============================================================================
--  MonetLoader port (mechanical 1:1 conversion of the original MoonLoader script)
-- ============================================================================
--  What was changed vs. the original MoonLoader version:
--    * Resource/config base paths "moonloader/..." -> "monetloader/..."
--      (sound, image and font directories).
--    * script_version tagged "-monet".
--    * Everything else (logic, library requires, imgui flow, SA-MP events) is
--      kept identical, since MonetLoader targets MoonLoader API compatibility.
--
--  IMPORTANT PLATFORM CAVEATS (intentionally left as-is per a 1:1 port):
--    * MonetLoader runs on Android (GTA SA Mobile / SA-MP Mobile, ARM). All the
--      hardcoded x86 memory addresses, opcode patches (memory.fill/hex2bin),
--      sampGetBase()+offset patches and callFunction() calls below are PC
--      addresses. They will NOT take effect on Android and may crash the game.
--    * The ffi WinAPI block (GetActiveWindow / ClipCursor) and the Windows
--      message handler (lib.windows.message / onWindowMessage) are Windows-only
--      and have no effect on Android; they were left unchanged.
--    Use those features at your own risk; they require Android-specific
--    addresses/handlers to actually work.
-- ============================================================================

local imgui = require 'imgui'
local encoding = require 'encoding'
local lfs = require 'lfs'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local memory = require 'memory'
local ev = require "lib.samp.events"
local rkeys = require 'rkeys'
imgui.HotKey = require('imgui_addons').HotKey
local fa = require 'fAwesome5'
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
local ffi = require "ffi"

local weaponSoundDelay = {[9] = 200, [37] = 900} -- ugenrl
local soundsDir = 'monetloader/gamefixer/genrl/' -- ugenrl

------------------------[ cfg ] -------------------
local inicfg = require "inicfg"
local directIni = "gamefixer.ini"
local ini = inicfg.load(inicfg.load({
    settings = {
        theme = "6",
        shownicks = false,
        showhp = false,
        noradio = false,
        showchat = true,
        showhud = true,
        bighpbar = false,
        weather = "1",
        hours = "17",
        min = "0",
        drawdist = "250.0",
        drawdistair = "1000.0",
        fog = "1.0",
        lod = "280.0",
        blockweather = true,
        blocktime = true,
        givemedist = true,
        targetblip = true,
        antiblockedplayer = true,
        chatt = true,
        unlimitfps = true,
        postfx = true,
        nobirds = false,
        nocloudbig = false,
        nocloudsmall = false,
        sensfix = true,
        nosounds = true,
        intmusic = false,
        audiostream = false,
        fixblackroads = false,
        nodust = true,
        effects = false,
        longarmfix = true,
        noshadows = true,
        waterfixquadro = true,
        intrun = true,
        shadowedit = true,
        mapzoom = true,
        mapzoomvalue = "260.0",
        shadowcp = "0",
        shadowlight = "0",
        vehlods = false,
        animmoney = "3",
        fixcrosshair = true,
        crosshairX = "64",
        crosshairY = "64",
        blockkeys = true,
        noplaneline = true,
        sunfix = false,
        vsync = false,
        radarfix = false,
        radarWidth = "94",
        radarHeight = "76",
        radarPosX = "40",
        radarPosY = "104",
        fixtaxilight = true,
        forceaniso = false,
        mapzoomfixer = true,
        dual_monitor_fix = false,
        radar_color_fix = false,
        adkfix = false,
        anticrasher = true,
    },
    cleaner = {
        autoclean = true,
        cleaninfo = true,
        limit = "1000",
    },
    ugenrl_main = {
        enable = true,
        weapon = true,
        enemyWeapon = true,
        enemyWeaponDist = 70,
        hit = true,
        pain = true,
        informers = true,
        autonosounds = true,
        fastactive = "[18,85]",
    },
    ugenrl_volume = {
        weapon = 1.00,
        hit = 1.00,
        pain = 1.00,
    },
    ugenrl_sounds = {
        [22] = '9mm.mp3',
        [23] = 'Silecent-Pistol.mp3',
        [24] = 'Deagle1.wav',
        [25] = 'Shotgun.1.wav',
        [26] = 'Sawnoff-Shotgun.mp3',
        [27] = 'Combat-Shotgun.mp3',
        [28] = 'Uzi.mp3',
        [29] = 'MP5.mp3',
        [30] = 'AK-47.mp3',
        [31] = 'M4.1.wav',
        [32] = 'TEC-9.mp3',
        [33] = 'Rifle.mp3',
        [34] = 'Sniper.mp3',
        hit = 'Bell1.mp3',
        pain = 'Painmale1.mp3',
    },
    fixtimecyc = {
        active = false,
        allambient = "0.800",
        objambient = "0.800",
        worldambientR = "0.800",
        worldambientG = "0.800",
        worldambientB = "0.800",
    },
    commands = {
        openmenu = "/gmenu",
        settime = "/st",
        setweather = "/sw",
        blockservertime = "/bt",
        blockserverweather = "/bw",
        givemedist = "/givemedist",
        drawdistance = "/dd",
        drawdistanceair = "/ddair",
        fogdistance = "/fd",
        loddistance = "/ld",
        shownicks = "/sname",
        showhp = "/shp",
        offradio = "/gameradio",
        clearchat = "/cc",
        showchat = "/showchat",
        showhud = "/showhud",
        bighpbar = "/160hp",
        fpslock = "/fpslock",
        postfx = "/postfx",
        antiblockedplayer = "/abplayer",
        animmoney = "/animmoney",
        chatopenfix = "/chatfix",
        hpstyle = "/hpstyle",
        hppos = "/hppos",
        hptext = "/hpt",
        autocleaner = "/accl",
        cleanmemory = "/ccl",
        cleaninfo = "/cclinfo",
        setmbforautocleaner = "/setccl",
        nobirds = "/nobirds",
        nodust = "/nodust",
        fixtimecyc = "/fixtimecyc",
        editcrosshair = "/ech",
        effects = "/effects",
        shadowedit = "/shadowedit",
        nocloudbig = "/nocloudbig",
        nocloudsmall = "/nocloudsmall",
        noshadows = "/noshadows",
        vehlods = "/vehlods",
        fixcrosshair = "/fixcrosshair",
        intrun = "/interiorrun",
        waterfixquadro = "/waterquadrofix",
        longarmfix = "/longarmfix",
        fixblackroads = "/fixblackroads",
        sensfix = "/sensfix",
        audiostream = "/audiostream",
        intmusic = "/intmusic",
        nosounds = "/nosounds",
        noplaneline = "/noplaneline",
        blockkeys = "/blockkeys",
        sunfix = "/sunfix",
        targetblip = "/targetblip",
        vsync = "/vsync",
        radarfix = "/radarfix",
        fixtaxilight = "/fixtaxilight",
        radarWidth = "/radarw",
        radarHeight = "/radarh",
        radarx = "/radarx",
        radary = "/radary",
        ugenrl = "/ugenrl",
        autonosounds = "/autonosounds",
        uds = "/uds",
        uss = "/uss",
        ums = "/ums",
        urs = "/urs",
        uuzi = "/uuzi",
        ump5 = "/ump5",
        ubs = "/ubs",
        ups = "/ups",
        ugd = "/ugd",
        ugvw = "/ugvw",
        ugvh = "/ugvh",
        ugvp = "/ugvp",
        forceaniso = "/forceaniso",
        mapzoomfixer = "/mapzoomfixer",
        shadowcp = "/shadowcp",
        shadowlight = "/shadowlight",
        dual_monitor_fix = "/dualfix",
        radar_color_fix = "/radarcolorfix",
        adkfix = "/adkfix",
        aamb = "/aamb",
        oamb = "/oamb",
        wamb = "/wamb",
        anticrasher = "/anticrasher",
    },
}, directIni))
inicfg.save(ini, directIni)

function save()
    inicfg.save(ini, directIni)
end
---------------------------------------------------------
local sw, sh = getScreenResolution()

-------------------------------- [window] ------------------------
local main_menu = imgui.ImBool(false)

-------------------------- [sliders] --------------------------
local sliders = {
    weather = imgui.ImInt(ini.settings.weather),
    hours = imgui.ImInt(ini.settings.hours),
    min = imgui.ImInt(ini.settings.min),
    drawdist = imgui.ImFloat(ini.settings.drawdist),
    drawdistair = imgui.ImFloat(ini.settings.drawdistair),
    fog = imgui.ImFloat(ini.settings.fog),
    lod = imgui.ImFloat(ini.settings.lod),
    shadowcp = imgui.ImInt(ini.settings.shadowcp),
    shadowlight = imgui.ImInt(ini.settings.shadowlight),
    limitmem = imgui.ImInt(ini.cleaner.limit),
    mapzoomvalue = imgui.ImFloat(ini.settings.mapzoomvalue),
    allambient = imgui.ImFloat(ini.fixtimecyc.allambient),
    objambient = imgui.ImFloat(ini.fixtimecyc.objambient),
    worldambientR = imgui.ImFloat(ini.fixtimecyc.worldambientR),
    worldambientG = imgui.ImFloat(ini.fixtimecyc.worldambientG),
    worldambientB = imgui.ImFloat(ini.fixtimecyc.worldambientB),
    radarw = imgui.ImInt(ini.settings.radarWidth),
    radarh = imgui.ImInt(ini.settings.radarHeight),
    radarposx = imgui.ImInt(ini.settings.radarPosX),
    radarposy = imgui.ImInt(ini.settings.radarPosY),
    ------------------------- [ugenrl] ---------------------------------
    weapon_volume_slider = imgui.ImFloat(ini.ugenrl_volume.weapon),
    hit_volume_slider = imgui.ImFloat(ini.ugenrl_volume.hit),
    pain_volume_slider = imgui.ImFloat(ini.ugenrl_volume.pain),
    enemyweapon_dist = imgui.ImInt(ini.ugenrl_main.enemyWeaponDist),
    --------------------------------------------------------------------
}
--------------------------- [checkboxes] ---------------------------
local checkboxes = {
    blockweather = imgui.ImBool(ini.settings.blockweather),
    blocktime = imgui.ImBool(ini.settings.blocktime),
    antiblockedplayer = imgui.ImBool(ini.settings.antiblockedplayer),
    chatt = imgui.ImBool(ini.settings.chatt),
    sensfix = imgui.ImBool(ini.settings.sensfix),
    fixblackroads = imgui.ImBool(ini.settings.fixblackroads),
    longarmfix = imgui.ImBool(ini.settings.longarmfix),
    waterfixquadro = imgui.ImBool(ini.settings.waterfixquadro),
    intrun = imgui.ImBool(ini.settings.intrun),
    cleaninfo = imgui.ImBool(ini.cleaner.cleaninfo),
    fixcrosshair = imgui.ImBool(ini.settings.fixcrosshair),
    mapzoom = imgui.ImBool(ini.settings.mapzoom),
    sunfix = imgui.ImBool(ini.settings.sunfix),
    radarfix = imgui.ImBool(ini.settings.radarfix),
    fixtaxilight = imgui.ImBool(ini.settings.fixtaxilight),
    forceaniso = imgui.ImBool(ini.settings.forceaniso),
    mapzoomfixer = imgui.ImBool(ini.settings.mapzoomfixer),
    dual_monitor_fix = imgui.ImBool(ini.settings.dual_monitor_fix),
    radar_color_fix = imgui.ImBool(ini.settings.radar_color_fix),
    adkfix = imgui.ImBool(ini.settings.adkfix),
    ----------------- [ugenrl] ----------------------------
    ugenrl_enable = imgui.ImBool(ini.ugenrl_main.enable),
    weapon_checkbox = imgui.ImBool(ini.ugenrl_main.weapon),
    enemyweapon_checkbox = imgui.ImBool(ini.ugenrl_main.enemyWeapon),
    hit_checkbox = imgui.ImBool(ini.ugenrl_main.hit),
    pain_checkbox = imgui.ImBool(ini.ugenrl_main.pain),
    autonosounds = imgui.ImBool(ini.ugenrl_main.autonosounds),
    ---------------------------------------------------------
}
------------------------- [BUFFER] ----------------------
local buffers = {
    cmd_openmenu = imgui.ImBuffer(''..ini.commands.openmenu, 32),
    cmd_settime = imgui.ImBuffer(''..ini.commands.settime, 32),
    cmd_setweather = imgui.ImBuffer(''..ini.commands.setweather, 32),
    cmd_blockservertime = imgui.ImBuffer(''..ini.commands.blockservertime, 32),
    cmd_blockserverweather = imgui.ImBuffer(''..ini.commands.blockserverweather, 32),
    cmd_givemedist = imgui.ImBuffer(''..ini.commands.givemedist, 32),
    cmd_drawdistance = imgui.ImBuffer(''..ini.commands.drawdistance, 32),
    cmd_drawdistanceair = imgui.ImBuffer(''..ini.commands.drawdistanceair, 32),
    cmd_fogdistance = imgui.ImBuffer(''..ini.commands.fogdistance, 32),
    cmd_loddistance = imgui.ImBuffer(''..ini.commands.loddistance, 32),
    cmd_shownicks = imgui.ImBuffer(''..ini.commands.shownicks, 32),
    cmd_showhp = imgui.ImBuffer(''..ini.commands.showhp, 32),
    cmd_offradio = imgui.ImBuffer(''..ini.commands.offradio, 32),
    cmd_clearchat = imgui.ImBuffer(''..ini.commands.clearchat, 32),
    cmd_showchat = imgui.ImBuffer(''..ini.commands.showchat, 32),
    cmd_showhud = imgui.ImBuffer(''..ini.commands.showhud, 32),
    cmd_bighpbar = imgui.ImBuffer(''..ini.commands.bighpbar, 32),
    cmd_fpslock= imgui.ImBuffer(''..ini.commands.fpslock, 32),
    cmd_postfx = imgui.ImBuffer(''..ini.commands.postfx, 32),
    cmd_antiblockedplayer = imgui.ImBuffer(''..ini.commands.antiblockedplayer, 32),
    cmd_animmoney = imgui.ImBuffer(''..ini.commands.animmoney, 32),
    cmd_chatopenfix = imgui.ImBuffer(''..ini.commands.chatopenfix, 32),
    cmd_hpstyle = imgui.ImBuffer(''..ini.commands.hpstyle, 32),
    cmd_hppos = imgui.ImBuffer(''..ini.commands.hppos, 32),
    cmd_hptext = imgui.ImBuffer(''..ini.commands.hptext, 32),
    cmd_autocleaner = imgui.ImBuffer(''..ini.commands.autocleaner, 32),
    cmd_cleanmemory = imgui.ImBuffer(''..ini.commands.cleanmemory, 32),
    cmd_cleaninfo = imgui.ImBuffer(''..ini.commands.cleaninfo, 32),
    cmd_setmbforautocleaner = imgui.ImBuffer(''..ini.commands.setmbforautocleaner, 32),
    cmd_nobirds = imgui.ImBuffer(''..ini.commands.nobirds, 32),
    cmd_nodust = imgui.ImBuffer(''..ini.commands.nodust, 32),
    cmd_fixtimecyc = imgui.ImBuffer(''..ini.commands.fixtimecyc, 32),
    cmd_aamb = imgui.ImBuffer(''..ini.commands.aamb, 32),
    cmd_oamb = imgui.ImBuffer(''..ini.commands.oamb, 32),
    cmd_wamb = imgui.ImBuffer(''..ini.commands.wamb, 32),
    cmd_effects = imgui.ImBuffer(''..ini.commands.effects, 32),
    cmd_editcrosshair = imgui.ImBuffer(''..ini.commands.editcrosshair, 32),
    cmd_shadowedit = imgui.ImBuffer(''..ini.commands.shadowedit, 32),
    cmd_nocloudbig = imgui.ImBuffer(''..ini.commands.nocloudbig, 32),
    cmd_nocloudsmall = imgui.ImBuffer(''..ini.commands.nocloudsmall, 32),
    cmd_noshadows = imgui.ImBuffer(''..ini.commands.noshadows, 32),
    cmd_vehlods = imgui.ImBuffer(''..ini.commands.vehlods, 32),
    cmd_fixcrosshair = imgui.ImBuffer(''..ini.commands.fixcrosshair, 32),
    cmd_intrun = imgui.ImBuffer(''..ini.commands.intrun, 32),
    cmd_waterfixquadro = imgui.ImBuffer(''..ini.commands.waterfixquadro, 32),
    cmd_longarmfix = imgui.ImBuffer(''..ini.commands.longarmfix, 32),
    cmd_fixblackroads = imgui.ImBuffer(''..ini.commands.fixblackroads, 32),
    cmd_fixsens = imgui.ImBuffer(''..ini.commands.sensfix, 32),
    cmd_audiostream = imgui.ImBuffer(''..ini.commands.audiostream, 32),
    cmd_intmusic = imgui.ImBuffer(''..ini.commands.intmusic, 32),
    cmd_nosounds = imgui.ImBuffer(''..ini.commands.nosounds, 32),
    cmd_noplaneline = imgui.ImBuffer(''..ini.commands.noplaneline, 32),
    cmd_blocksampkeys = imgui.ImBuffer(''..ini.commands.blockkeys, 32),
    cmd_sunfix = imgui.ImBuffer(''..ini.commands.sunfix, 32),
    cmd_targetblip = imgui.ImBuffer(''..ini.commands.targetblip, 32),
    vmenu_crx = imgui.ImInt(ini.settings.crosshairX),
    vmenu_cry = imgui.ImInt(ini.settings.crosshairY),
    cmd_vsync = imgui.ImBuffer(''..ini.commands.vsync, 32),
    cmd_radarfix = imgui.ImBuffer(''..ini.commands.radarfix, 32),
    cmd_fixtaxilight = imgui.ImBuffer(''..ini.commands.fixtaxilight, 32),
    cmd_radarwidth = imgui.ImBuffer(''..ini.commands.radarWidth, 32),
    cmd_radarheight = imgui.ImBuffer(''..ini.commands.radarHeight, 32),
    cmd_radarx = imgui.ImBuffer(''..ini.commands.radarx, 32),
    cmd_radary = imgui.ImBuffer(''..ini.commands.radary, 32),
    cmd_ugenrl = imgui.ImBuffer(''..ini.commands.ugenrl, 32),
    cmd_autonosounds = imgui.ImBuffer(''..ini.commands.autonosounds, 32),
    cmd_uds = imgui.ImBuffer(''..ini.commands.uds, 32),
    cmd_uss = imgui.ImBuffer(''..ini.commands.uss, 32),
    cmd_ums = imgui.ImBuffer(''..ini.commands.ums, 32),
    cmd_urs = imgui.ImBuffer(''..ini.commands.urs, 32),
    cmd_ubs = imgui.ImBuffer(''..ini.commands.ubs, 32),
    cmd_uuzi = imgui.ImBuffer(''..ini.commands.uuzi, 32),
    cmd_ump5 = imgui.ImBuffer(''..ini.commands.ump5, 32),
    cmd_ups = imgui.ImBuffer(''..ini.commands.ups, 32),
    cmd_ugd = imgui.ImBuffer(''..ini.commands.ugd, 32),
    cmd_ugvw = imgui.ImBuffer(''..ini.commands.ugvw, 32),
    cmd_ugvh = imgui.ImBuffer(''..ini.commands.ugvh, 32),
    cmd_ugvp = imgui.ImBuffer(''..ini.commands.ugvp, 32),
    cmd_forceaniso = imgui.ImBuffer(''..ini.commands.forceaniso, 32),
    cmd_mapzoomfixer = imgui.ImBuffer(''..ini.commands.mapzoomfixer, 32),
    cmd_shadowcp = imgui.ImBuffer(''..ini.commands.shadowcp, 32),
    cmd_shadowlight = imgui.ImBuffer(''..ini.commands.shadowlight, 32),
    cmd_dual_monitor_fix = imgui.ImBuffer(''..ini.commands.dual_monitor_fix, 32),
    cmd_radarfix = imgui.ImBuffer(''..ini.commands.radarfix, 32),
    cmd_radar_color_fix = imgui.ImBuffer(''..ini.commands.radar_color_fix, 32),
    cmd_adkfix = imgui.ImBuffer(''..ini.commands.adkfix, 32),
    cmd_anticrasher = imgui.ImBuffer(''..ini.commands.anticrasher, 32),
}

local arr_animmoney = {
    u8"�������",
    u8"��� ��������",
    u8"�����������",
}
local radio_animmoney = imgui.ImInt(ini.settings.animmoney)

local images = {
    one = imgui.CreateTextureFromFile("monetloader/gamefixer/images/one.png"),
    two = imgui.CreateTextureFromFile("monetloader/gamefixer/images/two.png"),
    three = imgui.CreateTextureFromFile("monetloader/gamefixer/images/three.png"),
    four = imgui.CreateTextureFromFile("monetloader/gamefixer/images/four.png"),
    five = imgui.CreateTextureFromFile("monetloader/gamefixer/images/five.png"),
    six = imgui.CreateTextureFromFile("monetloader/gamefixer/images/six.png"),
}

-----------------------------------------------------------------------------------------------------------------------------
------------------------------------------ [Dual Monitor fix] ---------------------------
ffi.cdef [[
	typedef unsigned long HANDLE;
	typedef HANDLE HWND;
	typedef struct _RECT {
		long left;
		long top;
		long right;
		long bottom;
	} RECT, *PRECT;

	HWND GetActiveWindow(void);

	bool GetWindowRect(
		HWND   hWnd,
		PRECT lpRect
	);

	bool ClipCursor(const RECT *lpRect);

	bool GetClipCursor(PRECT lpRect);
]]

local rcClip, rcOldClip = ffi.new('RECT'), ffi.new('RECT')
----------------------------------------------------------------------------------------

local tLastKeys = {} -- ���������� ������ ���������

local FastUgenrlKey = {
	v = decodeJson(ini.ugenrl_main.fastactive)
}

local tStyle = {
    u8"�����",
    u8"�������",
    u8"����������",
    u8"����",
    u8"������",
    u8"����������",
    u8"�����-���������",
    u8"�����",
    u8"��������",
    u8"�������",
    u8"���������",
    u8"�����-�������",
    u8"���������",
}

local iStyle = imgui.ImInt(ini.settings.theme-1)

------------------------------------ [cleaner] --------------------------------------------
local function round(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function get_memory()
    return round(memory.read(0x8E4CB4, 4, true) / 1048576, 1)
end
-------------------------------------------------------------------------------------------------

function main()
    --------------------- [ dual monitor fix] --------------
    ffi.C.GetWindowRect(ffi.C.GetActiveWindow(), rcClip);
    ffi.C.ClipCursor(rcClip);
    --------------------------------------------------------
    repeat wait(0) until isSampAvailable()
    sampAddChatMessage(script_name.."{FFFFFF} ��������. ������� ����: {dc4747}"..ini.commands.openmenu..". {FFFFFF}�����: {dc4747}"..script_author, 0x73b461)
    sampRegisterChatCommand("q", fastquit)
    sampRegisterChatCommand("quit", fastquit)
    loadSounds()--ugenrl
    gotofunc("all")--load all func

    bindFastActiveUgenrl = rkeys.registerHotKey(FastUgenrlKey.v, true, function()
        if not sampIsCursorActive() then
            ini.ugenrl_main.enable = not ini.ugenrl_main.enable
            checkboxes.ugenrl_enable.v = ini.ugenrl_main.enable
            if ini.ugenrl_main.autonosounds then
                if ini.ugenrl_main.enable then
                    ini.settings.nosounds = false
                else
                    ini.settings.nosounds = true
                end
                save()
                gotofunc("NoSounds")
            end
            sampAddChatMessage(ini.ugenrl_main.enable and script_name.." {FFFFFF}Ultimate Genrl {73b461}�������" or script_name.." {FFFFFF}Ultimate Genrl {dc4747}��������", 0x73b461)
        end
    end)
    
    while true do
        wait(0)
        if ini.settings.adkfix then
            if isCharInAnyCar(PLAYER_PED) and getCharHealth(PLAYER_PED) >= 1 then -- By DarkP1xel
                if isCharPlayingAnim(PLAYER_PED, "CAR_fallout_LHS") then		
                    local fX, fY, fZ = getOffsetFromCharInWorldCoords(PLAYER_PED, 0, 0, 2.5)
                    warpCharFromCarToCoord(PLAYER_PED, fX, fY, fZ)	
                elseif isCharPlayingAnim(PLAYER_PED, "CAR_rollout_LHS") then
                    wait(1610)
                    clearCharTasksImmediately(PLAYER_PED)
                end
            end
        end

        if ini.cleaner.autoclean then
            if tonumber(get_memory()) > tonumber(ini.cleaner.limit) then
                gotofunc("CleanMemory")
            end
        end

        if ini.settings.blockweather == true and ini.settings.weather ~= memory.read(0xC81320, 2, false) then gotofunc("SetWeather") end
        if ini.settings.blocktime == true and ini.settings.hours ~= memory.read(0xB70153, 1, false) then gotofunc("SetTime") end
        --------------------------------------------------- [ugenrl] ----------------------------
        if ini.ugenrl_main.enable then
            if ini.ugenrl_main.weapon then
                if isCharShooting(PLAYER_PED) then
                    playSound(ini.ugenrl_sounds[getCurrentCharWeapon(PLAYER_PED)], ini.ugenrl_volume.weapon)
                end
                if ini.ugenrl_main.enemyWeapon then
                    local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                    repeat
                        local hasFoundChars, randomCharHandle = findAllRandomCharsInSphere(myX, myY, myZ, ini.ugenrl_main.enemyWeaponDist, true, true)			
                        if hasFoundChars and isCharShooting(randomCharHandle) then
                            playSound(ini.ugenrl_sounds[getCurrentCharWeapon(randomCharHandle)], ini.ugenrl_volume.weapon, randomCharHandle)
                        end
                    until not hasFoundChars
                end
            end
            if playPain then
                playSound(ini.ugenrl_sounds.pain, ini.ugenrl_volume.pain)
                playPain = false
                if weaponSoundDelay[dmgWeaponId] then wait(weaponSoundDelay[dmgWeaponId]) end
            end
            if playHit then
                playSound(ini.ugenrl_sounds.hit, ini.ugenrl_volume.hit)
                playHit = false
                if weaponSoundDelay[dmgWeaponId] then wait(weaponSoundDelay[dmgWeaponId]) end
            end
        end
        --------------------------------------------------------------------------------------

        if not sampIsCursorActive() then
            if ini.settings.chatt and isKeyJustPressed(84) then
                sampSetChatInputEnabled(true)
            end
        end

        if ini.settings.antiblockedplayer and not isCharInAnyCar(PLAYER_PED) then
            for i = 0, sampGetMaxPlayerId(true) do
                if sampIsPlayerConnected(i) then
                    local result, id = sampGetCharHandleBySampPlayerId(i)
                    if result then
                        if doesCharExist(id) then
                            local x, y, z = getCharCoordinates(id)
                            local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
                            if 0.7 > getDistanceBetweenCoords3d(x, y, z, mX, mY, mZ) then
                                setCharCollision(id, false)
                            end
                        end
                    end
                end
            end
        end

        if ini.settings.givemedist then
            if isCharInAnyPlane(PLAYER_PED) or isCharInAnyHeli(PLAYER_PED) then --airveh dist
                if memory.getfloat(12044272, false) ~= ini.settings.drawdistair then
                    memory.setfloat(12044272, ini.settings.drawdistair, false)
                    memory.setfloat(13210352, ini.settings.fog, false)
                    memory.setfloat(0x858FD8, ini.settings.lod, false)
                end
            else
                if memory.getfloat(12044272, false) ~= ini.settings.drawdist then
                    memory.setfloat(12044272, ini.settings.drawdist, false)
                    memory.setfloat(13210352, ini.settings.fog, false)
                    memory.setfloat(0x858FD8, ini.settings.lod, false)
                end
            end

            if memory.getfloat(13210352, false) >= memory.getfloat(12044272, false) then --fix bug dist
                memory.setfloat(13210352, ini.settings.drawdist - 1.0, false)
                ini.settings.fog = ini.settings.drawdist - 1.0
                save()
            end
        end

    end
end

function ev.onSendCommand(cmd)
    if cmd:find("^"..ini.commands.openmenu.."$") then
        gotofunc("OpenMenu")
        return false
    elseif cmd:find("^"..ini.commands.settime.." .+") or cmd:find("^"..ini.commands.settime.."$") then
        local hours = cmd:match(ini.commands.settime.." (%d+)")
        local min = cmd:match(ini.commands.settime.." %d+%s(%d+)")
        if min == nil then min = 0 end
        hours = tonumber(hours)
        min = tonumber(min)
        if ini.settings.blocktime then
            if type(hours) ~= 'number' or hours < 0 or hours > 23 or type(min) ~= 'number' or min < 0 or min > 59 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.settime.." [0-23 - ����] [0-59 - ������]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.hours..":"..ini.settings.min, 0x73b461)
            else
                ini.settings.hours = hours
                ini.settings.min = min
                save()
                gotofunc("SetTime")
                sampAddChatMessage(script_name.." {FFFFFF}����������� �����: {dc4747}"..ini.settings.hours..":"..ini.settings.min, 0x73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ����� ������ �� ��������� �������, �������: {dc4747}"..ini.commands.blockservertime, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.setweather.." .+") or cmd:find("^"..ini.commands.setweather.."$") then
        local weather = cmd:match(ini.commands.setweather.."(.+)")
        weather = tonumber(weather)
        if ini.settings.blockweather then
            if type(weather) ~= 'number' or weather < 0 or weather > 45 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.setweather.." [0-45]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.weather, 0x73b461)
            else
                ini.settings.weather = weather
                save()
                gotofunc("SetWeather")
                sampAddChatMessage(script_name.." {FFFFFF}����������� ������: {dc4747}"..ini.settings.weather, 0x73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ����� ������ �� ��������� ������, �������: {dc4747}"..ini.commands.blockserverweather, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.blockservertime.."$") then
        ini.settings.blocktime = not ini.settings.blocktime
        save()
        sampAddChatMessage(ini.settings.blocktime and script_name..' {FFFFFF}������ ������ {dc4747}�� ����� {FFFFFF} ������ ��� �����' or script_name..' {FFFFFF}������ ������ {73b461}����� {FFFFFF} ������ ��� �����', 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.blockserverweather.."$") then
        ini.settings.blockweather = not ini.settings.blockweather
        save()
        sampAddChatMessage(ini.settings.blockweather and script_name..' {FFFFFF}������ ������ {dc4747}�� ����� {FFFFFF} ������ ��� ������' or script_name..' {FFFFFF}������ ������ {73b461}����� {FFFFFF} ������ ��� ������', 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.givemedist.."$") then
        ini.settings.givemedist = not ini.settings.givemedist
        sampAddChatMessage(ini.settings.givemedist and script_name..' {FFFFFF}����������� ������ ���������� {73b461}��������' or script_name..' {FFFFFF}����������� ������ ���������� {dc4747}���������', 0x73b461)
        save()
        gotofunc("GivemeDist")
        return false
    elseif cmd:find("^"..ini.commands.drawdistance.." .+") or cmd:find("^"..ini.commands.drawdistance.."$") then
        local drawdist = cmd:match(ini.commands.drawdistance.." (.+)")
        drawdist = tonumber(drawdist)
        if ini.settings.givemedist then
            if type(drawdist) ~= 'number' or drawdist > 3600 or drawdist < 35 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.drawdistance.." [35-3600]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.drawdist, 0x73b461)
            else
                ini.settings.drawdist = ("%.1f"):format(drawdist)
                save()
                sliders.drawdist.v = ini.settings.drawdist
                memory.setfloat(12044272, ini.settings.drawdist, false)
                sampAddChatMessage(script_name.." {FFFFFF}����������� ��������� ����������: {dc4747}"..ini.settings.drawdist, 0x73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ��������� ����������� ������ ����������, �������� �: {dc4747}"..ini.commands.givemedist, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.drawdistanceair.." .+") or cmd:find("^"..ini.commands.drawdistanceair.."$") then
        local drawdistair = cmd:match(ini.commands.drawdistanceair.." (.+)")
        drawdistair = tonumber(drawdistair)
        if ini.settings.givemedist then
            if type(drawdistair) ~= 'number' or drawdistair > 3600 or drawdistair < 35 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.drawdistanceair.." [35-3600]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.drawdistair, 0x73b461)
            else
                ini.settings.drawdistair = ("%.1f"):format(drawdistair)
                save()
                sliders.drawdistair.v = ini.settings.drawdistair
                memory.setfloat(12044272, ini.settings.drawdistair, false)
                sampAddChatMessage(script_name.." {FFFFFF}��������� ���������� � ��������� ���������� ����������� ��: {dc4747}"..ini.settings.drawdistair, 0x73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ��������� ����������� ������ ����������, �������� �: {dc4747}"..ini.commands.givemedist, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.fogdistance.." .+") or cmd:find("^"..ini.commands.fogdistance.."$") then
        local fogdist = cmd:match(ini.commands.fogdistance.." (.+)")
        fogdist = tonumber(fogdist)
        if ini.settings.givemedist then
            if type(fogdist) ~= 'number' or fogdist > 500 or fogdist < -100 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.fogdistance.." [-100-500]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.fog, 0x73b461)
            else
                ini.settings.fog = ("%.1f"):format(fogdist)
                save()
                sliders.fog.v = ini.settings.fog
                memory.setfloat(13210352, ini.settings.fog, false)
                sampAddChatMessage(script_name.." {FFFFFF}����������� ��������� ������: {dc4747}"..ini.settings.fog, 0x73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ��������� ����������� ������ ����������, �������� �: {dc4747}"..ini.commands.givemedist, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.loddistance.." .+") or cmd:find("^"..ini.commands.loddistance.."$") then
        local loddist = cmd:match(ini.commands.loddistance.." (.+)")
        loddist = tonumber(loddist)
        if ini.settings.givemedist then
            if type(loddist) ~= 'number' or loddist > 300 or loddist < 0 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.loddistance.." [0-300]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.lod, 0x73b461)
            else
                ini.settings.lod = ("%.1f"):format(loddist)
                save()
                sliders.lod.v = ini.settings.lod
                memory.setfloat(0x858FD8, ini.settings.lod, false)
                sampAddChatMessage(script_name.." {FFFFFF}����������� ��������� �����: {dc4747}"..ini.settings.lod, 0x73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ��������� ����������� ������ ����������, �������� �: {dc4747}"..ini.commands.givemedist, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.shownicks.."$") then
        ini.settings.shownicks = not ini.settings.shownicks
        gotofunc("ShowNICKS")
        save()
        sampAddChatMessage(ini.settings.shownicks and script_name..' {FFFFFF}���� ������� {dc4747}���������' or script_name..' {FFFFFF}���� ������� {73b461}��������', 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.showhp.."$") then
        ini.settings.showhp = not ini.settings.showhp
        save()
        sampAddChatMessage(ini.settings.showhp and script_name..' {FFFFFF}������� �� ������� {dc4747}���������' or script_name..' {FFFFFF}������� �� ������� {73b461}��������', 0x73b461)
        gotofunc("ShowHP")
        return false
    elseif cmd:find("^"..ini.commands.offradio.."$") then
        ini.settings.noradio = not ini.settings.noradio
        save()
        sampAddChatMessage(ini.settings.noradio and script_name..' {FFFFFF}����� � ���������� {73b461}��������' or script_name..' {FFFFFF}����� � ���������� {dc4747}���������', 0x73b461)
        gotofunc("NoRadio")
        return false
    elseif cmd:find("^"..ini.commands.clearchat.."$") then
        gotofunc("ClearChat")
        return false
    elseif cmd:find("^"..ini.commands.showchat.."$") then
        ini.settings.showchat = not ini.settings.showchat
        sampAddChatMessage(ini.settings.showchat and script_name..' {FFFFFF}��� {73b461}�������' or script_name..' {FFFFFF}��� {dc4747}��������', 0x73b461)
        save()
        gotofunc("ShowCHAT")
        return false
    elseif cmd:find("^"..ini.commands.showhud.."$") then
        ini.settings.showhud = not ini.settings.showhud
        sampAddChatMessage(ini.settings.showhud and script_name..' {FFFFFF}HUD {73b461}�������' or script_name..' {FFFFFF}HUD {dc4747}��������', 0x73b461)
        save()
        gotofunc("ShowHUD")
        return false
    elseif cmd:find("^"..ini.commands.animmoney.." .+") or cmd:find("^"..ini.commands.animmoney.."$") then
        local param = cmd:match(ini.commands.animmoney.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param > 3 or param < 1 then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {DC4747}"..ini.commands.animmoney.." [1-3]", 0x73b461)
        else
            ini.settings.animmoney = param
            save()
            radio_animmoney = imgui.ImInt(ini.settings.animmoney)
            if ini.settings.animmoney == 1 then
                sampAddChatMessage(script_name.." {FFFFFF}�������� ��������� ���-�� ����� �������� ��: {DC4747}�������", 0x73b461)
            elseif ini.settings.animmoney == 2 then
                sampAddChatMessage(script_name.." {FFFFFF}�������� ��������� ���-�� ����� �������� ��: {DC4747}��� ��������", 0x73b461)
            elseif ini.settings.animmoney == 3 then
                sampAddChatMessage(script_name.." {FFFFFF}�������� ��������� ���-�� ����� �������� ��: {DC4747}�����������", 0x73b461)
            end
        end
        return false
    elseif cmd:find("^"..ini.commands.bighpbar.."$") then
        ini.settings.bighpbar = not ini.settings.bighpbar
        sampAddChatMessage(ini.settings.bighpbar and script_name..' {FFFFFF}160hp bar {73b461}�������' or script_name..' {FFFFFF}160hp bar {dc4747}��������', 0x73b461)
        save()
        gotofunc("BigHPBar")
        return false
    elseif cmd:find("^"..ini.commands.anticrasher.."$") then
        ini.settings.anticrasher = not ini.settings.anticrasher
        sampAddChatMessage(ini.settings.anticrasher and script_name..' {FFFFFF}���������� {73b461}�������' or script_name..' {FFFFFF}���������� {dc4747}��������', 0x73b461)
        save()
        return false
    elseif cmd:find("^"..ini.commands.fpslock.."$") then
        ini.settings.unlimitfps = not ini.settings.unlimitfps
        sampAddChatMessage(ini.settings.unlimitfps and script_name..' {FFFFFF}FPS unlock {73b461}�������' or script_name..' {FFFFFF}FPS unlock {dc4747}��������', 0x73b461)
        save()
        gotofunc("FPSUnlock")
        return false
    elseif cmd:find("^"..ini.commands.postfx.."$") then
        ini.settings.postfx = not ini.settings.postfx
        sampAddChatMessage(ini.settings.postfx and script_name..' {FFFFFF}����-��������� {73b461}��������' or script_name..' {FFFFFF}����-��������� {dc4747}���������', 0x73b461)
        save()
        gotofunc("NoPostfx")
        return false
    elseif cmd:find("^"..ini.commands.antiblockedplayer.."$") then
        ini.settings.antiblockedplayer = not ini.settings.antiblockedplayer
        checkboxes.antiblockedplayer.v = ini.settings.antiblockedplayer
        save()
        sampAddChatMessage(ini.settings.antiblockedplayer and script_name..' {FFFFFF}����������� ����������� � ������ ������� ��� ������ {73b461}��������' or script_name..' {FFFFFF}����������� ����������� � ������ ������� ��� ������ {dc4747}���������', 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.chatopenfix.."$") then
        ini.settings.chatt = not ini.settings.chatt
        checkboxes.chatt.v = ini.settings.chatt
        save()
        sampAddChatMessage(ini.settings.chatt and script_name..' {FFFFFF}�������� ���� �� � {73b461}��������' or script_name..' {FFFFFF}�������� ���� �� � {dc4747}���������', 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.autocleaner.."$") then
        ini.cleaner.autoclean = not ini.cleaner.autoclean
        save()
        sampAddChatMessage((script_name.."{FFFFFF} �������������� ������� ������ %s"):format(ini.cleaner.autoclean and "{73b461}��������" or "{dc4747}���������"), 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.cleanmemory.."$") then
        gotofunc("CleanMemory")
        return false
    elseif cmd:find("^"..ini.commands.cleaninfo.."$") then
        ini.cleaner.cleaninfo = not ini.cleaner.cleaninfo
        save()
        checkboxes.cleaninfo.v = ini.cleaner.cleaninfo
        sampAddChatMessage(ini.cleaner.cleaninfo and script_name..' {FFFFFF}��������� �� ������� ������ {73b461}��������' or script_name..' {FFFFFF}��������� �� ������� ������ {dc4747}���������', 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.setmbforautocleaner.." .+") or cmd:find("^"..ini.commands.setmbforautocleaner.."$") then
        local setccl = cmd:match(ini.commands.setmbforautocleaner.." (.+)")
        setccl = tonumber(setccl)
        if type(setccl) ~= 'number' or setccl > 2000 or setccl < 0 then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.setmbforautocleaner.." [0-2000 ��]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.cleaner.limit.." ��", 0x73b461)
        else
            ini.cleaner.limit = setccl
            save()
            sampAddChatMessage(script_name.." {FFFFFF}����-������� ������ ����������� ��: {dc4747}"..ini.cleaner.limit.." ��", 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.nobirds.."$") then
        ini.settings.nobirds = not ini.settings.nobirds
        save()
        sampAddChatMessage(ini.settings.nobirds and script_name..' {FFFFFF}����� {73b461}��������' or script_name..' {FFFFFF}����� {dc4747}���������', 0x73b461)
        gotofunc("NoBirds")
        return false
    elseif cmd:find("^"..ini.commands.nodust.."$") then
        ini.settings.nodust = not ini.settings.nodust
        save()
        sampAddChatMessage(ini.settings.nodust and script_name..' {FFFFFF}���� �� ����� � ��� �� ����� {73b461}�������' or script_name..' {FFFFFF}���� �� ����� � ��� �� ����� {dc4747}��������', 0x73b461)
        gotofunc("NoDust")
        return false
    elseif cmd:find("^"..ini.commands.fixtimecyc.."$") then
        ini.fixtimecyc.active = not ini.fixtimecyc.active
        sampAddChatMessage(ini.fixtimecyc.active and script_name..' {FFFFFF}����������� ������� ��������� ��� ����������� ����-��������� {73b461}��������' or script_name..' {FFFFFF}����������� ������� ��������� ��� ����������� ����-��������� {dc4747}���������', 0x73b461)
        save()
        gotofunc("FixTimecyc")
        return false
    elseif cmd:find("^"..ini.commands.aamb.." .+") or cmd:find("^"..ini.commands.aamb.."$") then
        local param = cmd:match(ini.commands.aamb.." (.+)")
        param = tonumber(param)
        if ini.fixtimecyc.active then
            if type(param) ~= 'number' or param < -1.000 or param > 1.000 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.aamb.." [�� -1.000 �� 1.000]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.fixtimecyc.allambient, 0xd73b461)
            else
                ini.fixtimecyc.allambient = param
                save()
                sliders.allambient.v = ini.fixtimecyc.allambient
                gotofunc("FixTimecyc")
                sampAddChatMessage(script_name.." {FFFFFF}����� ��������� ����������� ��: {dc4747}"..ini.fixtimecyc.allambient, 0xd73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ��������� ����������� ���������, �������� ���: {dc4747}"..ini.commands.fixtimecyc, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.oamb.." .+") or cmd:find("^"..ini.commands.oamb.."$") then
        local param = cmd:match(ini.commands.oamb.." (.+)")
        param = tonumber(param)
        if ini.fixtimecyc.active then
            if type(param) ~= 'number' or param < -1.000 or param > 1.000 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.oamb.." [�� -1.000 �� 1.000]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.fixtimecyc.objambient, 0xd73b461)
            else
                ini.fixtimecyc.objambient = param
                save()
                sliders.objambient.v = ini.fixtimecyc.objambient
                gotofunc("FixTimecyc")
                sampAddChatMessage(script_name.." {FFFFFF}��������� �������� � ����� ����������� ��: {dc4747}"..ini.fixtimecyc.objambient, 0xd73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ��������� ����������� ���������, �������� ���: {dc4747}"..ini.commands.fixtimecyc, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.wamb.." .+") or cmd:find("^"..ini.commands.wamb.."$") then
        local R = cmd:match(ini.commands.wamb.." (.+)%s.+%s.+")
        local G = cmd:match(ini.commands.wamb.." .+%s(.+)%s.+")
        local B = cmd:match(ini.commands.wamb..".+%s.+%s(.+)")
        R = tonumber(R)
        G = tonumber(G)
        B = tonumber(B)
        if ini.fixtimecyc.active then
            if type(R) ~= 'number' or type(G) ~= 'number' or type(B) ~= 'number' or R > 1.000 or R < -1.000 or G > 1.000 or G < -1.000 or B > 1.000 or B < -1.000 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.wamb.." [R �� -1.000 �� 1.000] [G �� -1.000 �� 1.000] [B �� -1.000 �� 1.000]", 0xd73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ���������: {dc4747}R: "..ini.fixtimecyc.worldambientR.." G: "..ini.fixtimecyc.worldambientG.." B: "..ini.fixtimecyc.worldambientB, 0xd73b461)
            else
                ini.fixtimecyc.worldambientR = R
                ini.fixtimecyc.worldambientG = G
                ini.fixtimecyc.worldambientB = B
                save()
                sliders.worldambientR.v = ini.fixtimecyc.worldambientR
                sliders.worldambientG.v = ini.fixtimecyc.worldambientG
                sliders.worldambientB.v = ini.fixtimecyc.worldambientB
                gotofunc("FixTimecyc")
                sampAddChatMessage(script_name.." {FFFFFF}��������� ���� ����������� ��: {dc4747}R: "..ini.fixtimecyc.worldambientR.." G: "..ini.fixtimecyc.worldambientG.." B: "..ini.fixtimecyc.worldambientB, 0xd73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ��������� ����������� ���������, �������� ���: {dc4747}"..ini.commands.fixtimecyc, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.effects.."$") then
        ini.settings.effects = not ini.settings.effects
        save()
        sampAddChatMessage(ini.settings.effects and script_name..' {FFFFFF}������� {73b461}��������' or script_name..' {FFFFFF}������� {dc4747}���������', 0x73b461)
        gotofunc("NoEffects")
        return false
    elseif cmd:find("^"..ini.commands.editcrosshair.." .+%s.+") or cmd:find("^"..ini.commands.editcrosshair.."$") then
        local crX1 = cmd:match(ini.commands.editcrosshair.." (.+)%s.+")
        local crY1 = cmd:match(ini.commands.editcrosshair.." .+%s(.+)")
        crX1 = tonumber(crX1)
        crY1 = tonumber(crY1)
        if type(crY1) ~= 'number' or type(crX1) ~= 'number' or crX1 > 100 or crX1 < 0 or crY1 > 100 or crY1 < 0 then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.editcrosshair.." [X: 0-100] [Y: 0-100]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ���������: {dc4747}X: "..ini.settings.crosshairX.." Y: "..ini.settings.crosshairY, 0x73b461)
        else
            ini.settings.crosshairX = crX1
            ini.settings.crosshairY = crY1
            buffers.vmenu_crx.v = crX1
            buffers.vmenu_cry.v = crY1
            save()
            memory.setfloat(8755780, ini.settings.crosshairX, false)
            memory.setfloat(8755804, ini.settings.crosshairY, false)
            sampAddChatMessage(script_name.." {FFFFFF}���������� ������ �������: {dc4747}X: "..ini.settings.crosshairX.." Y: "..ini.settings.crosshairY, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.shadowedit.."$") then
        ini.settings.shadowedit = not ini.settings.shadowedit
        save()
        sampAddChatMessage(ini.settings.shadowedit and script_name..' {FFFFFF}����������� ������ ���� {73b461}��������' or script_name..' {FFFFFF}����������� ������ ���� {dc4747}���������', 0x73b461)
        gotofunc("ShadowEdit")
        return false
    elseif cmd:find("^"..ini.commands.nocloudbig.."$") then
        ini.settings.nocloudbig = not ini.settings.nocloudbig
        save()
        sampAddChatMessage(ini.settings.nocloudbig and script_name..' {FFFFFF}������� ������ {73b461}��������' or script_name..' {FFFFFF}������� ������ {dc4747}���������', 0x73b461)
        gotofunc("NoCloudBig")
        return false
    elseif cmd:find("^"..ini.commands.nocloudsmall.."$") then
        ini.settings.nocloudsmall = not ini.settings.nocloudsmall
        save()
        sampAddChatMessage(ini.settings.nocloudsmall and script_name..' {FFFFFF}������ ������ {73b461}��������' or script_name..' {FFFFFF}������ ������ {dc4747}���������', 0x73b461)
        gotofunc("NoCloudSmall")
        return false
    elseif cmd:find("^"..ini.commands.noshadows.."$") then
        ini.settings.noshadows = not ini.settings.noshadows
        save()
        sampAddChatMessage(ini.settings.noshadows and script_name..' {FFFFFF}���� {73b461}��������' or script_name..' {FFFFFF}���� {dc4747}���������', 0x73b461)
        gotofunc("NoShadows")
        return false
    elseif cmd:find("^"..ini.commands.vehlods.."$") then
        ini.settings.vehlods = not ini.settings.vehlods
        save()
        sampAddChatMessage(ini.settings.vehlods and script_name..' {FFFFFF}����������� ����� ���������� {73b461}��������' or script_name..' {FFFFFF}����������� ����� ���������� {dc4747}���������', 0x73b461)
        gotofunc("VehLods")
        return false
    elseif cmd:find("^"..ini.commands.fixcrosshair.."$") then
        ini.settings.fixcrosshair = not ini.settings.fixcrosshair
        save()
        sampAddChatMessage(ini.settings.fixcrosshair and script_name..' {FFFFFF}����������� ����� ����� �� ������� {73b461}��������' or script_name..' {FFFFFF}����������� ����� ����� �� ������� {dc4747}���������', 0x73b461)
        gotofunc("FixCrosshair")
        return false
    elseif cmd:find("^"..ini.commands.intrun.."$") then
        ini.settings.intrun = not ini.settings.intrun
        save()
        sampAddChatMessage(ini.settings.intrun and script_name..' {FFFFFF}����������� ���� � ���������� {73b461}��������' or script_name..' {FFFFFF}����������� ���� � ���������� {dc4747}���������', 0x73b461)
        gotofunc("InteriorRun")
        return false
    elseif cmd:find("^"..ini.commands.waterfixquadro.."$") then
        ini.settings.waterfixquadro = not ini.settings.waterfixquadro
        save()
        sampAddChatMessage(ini.settings.waterfixquadro and script_name..' {FFFFFF}����������� ���������� ���� {73b461}��������' or script_name..' {FFFFFF}����������� ���������� ���� {dc4747}���������', 0x73b461)
        gotofunc("FixWaterQuadro")
        return false
    elseif cmd:find("^"..ini.commands.longarmfix.."$") then
        ini.settings.longarmfix = not ini.settings.longarmfix
        save()
        sampAddChatMessage(ini.settings.longarmfix and script_name..' {FFFFFF}����������� ������� ��� {73b461}��������' or script_name..' {FFFFFF}����������� ������� ��� {dc4747}���������', 0x73b461)
        gotofunc("FixLongArm")
        return false
    elseif cmd:find("^"..ini.commands.fixblackroads.."$") then
        ini.settings.fixblackroads = not ini.settings.fixblackroads
        save()
        sampAddChatMessage(ini.settings.fixblackroads and script_name..' {FFFFFF}����������� ������ ����� {73b461}��������' or script_name..' {FFFFFF}����������� ������ ����� {dc4747}���������', 0x73b461)
        gotofunc("FixBlackRoads")
        return false
    elseif cmd:find("^"..ini.commands.sensfix.."$") then
        ini.settings.sensfix = not ini.settings.sensfix
        save()
        sampAddChatMessage(ini.settings.sensfix and script_name..' {FFFFFF}����������� ���������������� ����� �� ���� X � Y {73b461}��������' or script_name..' {FFFFFF}����������� ���������������� ����� �� ���� X � Y {dc4747}���������', 0x73b461)
        gotofunc("FixSensitivity")
        return false
    elseif cmd:find("^"..ini.commands.audiostream.."$") then
        ini.settings.audiostream = not ini.settings.audiostream
        save()
        sampAddChatMessage(ini.settings.audiostream and script_name..' {FFFFFF}AudioStream {73b461}�������' or script_name..' {FFFFFF}AudioStream {dc4747}��������', 0x73b461)
        gotofunc("AudioStream")
        return false
    elseif cmd:find("^"..ini.commands.intmusic.."$") then
        ini.settings.intmusic = not ini.settings.intmusic
        save()
        sampAddChatMessage(ini.settings.intmusic and script_name..' {FFFFFF}������ � ���������� {73b461}��������' or script_name..' {FFFFFF}������ � ���������� {dc4747}���������', 0x73b461)
        gotofunc("InteriorMusic")
        return false
    elseif cmd:find("^"..ini.commands.nosounds.."$") then
        ini.settings.nosounds = not ini.settings.nosounds
        save()
        sampAddChatMessage(ini.settings.nosounds and script_name..' {FFFFFF}����� ���� {73b461}��������' or script_name..' {FFFFFF}����� ���� {dc4747}���������', 0x73b461)
        gotofunc("NoSounds")
        return false
    elseif cmd:find("^"..ini.commands.noplaneline.."$") then
        ini.settings.noplaneline = not ini.settings.noplaneline
        save()
        sampAddChatMessage(ini.settings.noplaneline and script_name..' {FFFFFF}������ �� ��������� �� ���� {73b461}��������' or script_name..' {FFFFFF}������ �� ��������� �� ���� {dc4747}���������', 0x73b461)
        gotofunc("NoPlaneLine")
        return false
    elseif cmd:find("^"..ini.commands.blockkeys.."$") then
        ini.settings.blockkeys = not ini.settings.blockkeys
        save()
        sampAddChatMessage(ini.settings.blockkeys and script_name..' {FFFFFF}���������� ������ samp ������� {73b461}��������' or script_name..' {FFFFFF}���������� ������ samp ������� {dc4747}���������', 0x73b461)
        gotofunc("BlockSampKeys")
        return false
    elseif cmd:find("^"..ini.commands.sunfix.."$") then
        ini.settings.sunfix = not ini.settings.sunfix
        save()
        sampAddChatMessage(ini.settings.sunfix and script_name..' {FFFFFF}������ {73b461}��������' or script_name..' {FFFFFF}������ {dc4747}���������', 0x73b461)
        gotofunc("SunFix")
        return false
    elseif cmd:find("^"..ini.commands.targetblip.."$") then
        ini.settings.targetblip = not ini.settings.targetblip
        save()
        sampAddChatMessage(ini.settings.targetblip and script_name..' {FFFFFF}������ �� ������� {73b461}�������' or script_name..' {FFFFFF}������ �� ������� {dc4747}��������', 0x73b461)
        gotofunc("TargetBlip")
        return false
    elseif cmd:find("^"..ini.commands.vsync.."$") then
        ini.settings.vsync = not ini.settings.vsync
        save()
        sampAddChatMessage(ini.settings.vsync and script_name..' {FFFFFF}������������ ������������� {73b461}��������' or script_name..' {FFFFFF}������������ ������������� {dc4747}���������', 0x73b461)
        gotofunc("Vsync")
        return false
    elseif cmd:find("^"..ini.commands.radarfix.."$")then
        ini.settings.radarfix = not ini.settings.radarfix
        save()
        sampAddChatMessage(ini.settings.radarfix and script_name..' {FFFFFF}����������� ������ {73b461}��������' or script_name..' {FFFFFF}����������� ������ {dc4747}���������', 0x73b461)
        gotofunc("Radarfix")
        return false
    elseif cmd:find("^"..ini.commands.radar_color_fix.."$")then
        ini.settings.radar_color_fix = not ini.settings.radar_color_fix
        save()
        checkboxes.radar_color_fix.v = ini.settings.radar_color_fix
        sampAddChatMessage(ini.settings.radar_color_fix and script_name..' {FFFFFF}����������� ����� ������� ������ {73b461}��������' or script_name..' {FFFFFF}����������� ����� ������� ������ {dc4747}���������', 0x73b461)
        gotofunc("RadarColorFix")
        return false
    elseif cmd:find("^"..ini.commands.dual_monitor_fix.."$")then
        ini.settings.dual_monitor_fix = not ini.settings.dual_monitor_fix
        save()
        checkboxes.dual_monitor_fix.v = ini.settings.dual_monitor_fix
        sampAddChatMessage(ini.settings.dual_monitor_fix and script_name..' {FFFFFF}����������� ������ ����� �� ������ ������� {73b461}��������' or script_name..' {FFFFFF}����������� ������ ����� �� ������ ������� {dc4747}���������', 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.adkfix.."$")then
        ini.settings.adkfix = not ini.settings.adkfix
        save()
        checkboxes.adkfix.v = ini.settings.adkfix
        sampAddChatMessage(ini.settings.adkfix and script_name..' {FFFFFF}����������� ���� �������� �������� � ������������� ����� {73b461}��������' or script_name..' {FFFFFF}����������� ���� �������� �������� � ������������� ����� {dc4747}���������', 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.fixtaxilight.."$")then
        ini.settings.fixtaxilight = not ini.settings.fixtaxilight
        save()
        checkboxes.fixtaxilight.v = ini.settings.fixtaxilight
        sampAddChatMessage(ini.settings.fixtaxilight and script_name..' {FFFFFF}����������� �������� ����� � ����� {73b461}��������' or script_name..' {FFFFFF}����������� �������� ����� � ����� {dc4747}���������', 0x73b461)
        gotofunc("FixTaxiLight")
        return false
    elseif cmd:find("^"..ini.commands.radarWidth.." .+") or cmd:find("^"..ini.commands.radarWidth.."$")then
        local param = cmd:match(ini.commands.radarWidth.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.radarWidth.." [�����]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.radarWidth, 0x73b461)
        else
            ini.settings.radarWidth = param
            save()
            sliders.radarw.v = ini.settings.radarWidth
            gotofunc("Radarfix")
            sampAddChatMessage(script_name.." {FFFFFF}������ ������ ����������� ��: {dc4747}"..ini.settings.radarWidth, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.radarHeight.." .+") or cmd:find("^"..ini.commands.radarHeight.."$")then
        local param = cmd:match(ini.commands.radarHeight.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.radarHeight.." [�����]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.radarHeight, 0x73b461)
        else
            ini.settings.radarHeight = param
            save()
            sliders.radarh.v = ini.settings.radarHeight
            gotofunc("Radarfix")
            sampAddChatMessage(script_name.." {FFFFFF}������ ������ ����������� ��: {dc4747}"..ini.settings.radarHeight, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.radarx.." .+") or cmd:find("^"..ini.commands.radarx.."$")then
        local param = cmd:match(ini.commands.radarx.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.radarx.." [�����]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.radarPosX, 0x73b461)
        else
            ini.settings.radarPosX = param
            save()
            sliders.radarposx.v = ini.settings.radarPosX
            gotofunc("Radarfix")
            sampAddChatMessage(script_name.." {FFFFFF}������� ������ �� X ����������� ��: {dc4747}"..ini.settings.radarPosX, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.radary.." .+") or cmd:find("^"..ini.commands.radary.."$")then
        local param = cmd:match(ini.commands.radary.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.radary.." [�����]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.radarPosY, 0x73b461)
        else
            ini.settings.radarPosY = param
            save()
            sliders.radarposy.v = ini.settings.radarPosY
            gotofunc("Radarfix")
            sampAddChatMessage(script_name.." {FFFFFF}������� ������ �� Y ����������� ��: {dc4747}"..ini.settings.radarPosY, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.ugenrl.."$")then
        ini.ugenrl_main.enable = not ini.ugenrl_main.enable
        checkboxes.ugenrl_enable.v = ini.ugenrl_main.enable
        if ini.ugenrl_main.autonosounds then
            if ini.ugenrl_main.enable then
                ini.settings.nosounds = false
            else
                ini.settings.nosounds = true
            end
            save()
            gotofunc("NoSounds")
        end
        sampAddChatMessage(ini.ugenrl_main.enable and script_name.." {FFFFFF}Ultimate Genrl {73b461}�������" or script_name.." {FFFFFF}Ultimate Genrl {dc4747}��������", 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.autonosounds.."$")then
        ini.ugenrl_main.autonosounds = not ini.ugenrl_main.autonosounds
        checkboxes.autonosounds.v = ini.ugenrl_main.autonosounds
        save()
        sampAddChatMessage(ini.ugenrl_main.autonosounds and script_name.." {FFFFFF}�������������� ���������� ������ ��� ��������� Ultimate Genrl {73b461}��������" or script_name.." {FFFFFF}�������������� ���������� ������ ��� ��������� Ultimate Genrl {dc4747}���������", 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.uds.." .+") or cmd:find("^"..ini.commands.uds.."$")then
        local param = cmd:match(ini.commands.uds.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 1 or param > tonumber(#deagleSounds) then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.uds.." [1-"..#deagleSounds.."]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..getNumberSounds(24, deagleSounds), 0x73b461)
        else
            changeSound(24, deagleSounds[param])
            save()
            sampAddChatMessage(script_name.." {FFFFFF}���� deagle ���������� ��: {dc4747}"..param, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.uss.." .+") or cmd:find("^"..ini.commands.uss.."$")then
        local param = cmd:match(ini.commands.uss.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 1 or param > tonumber(#shotgunSounds) then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.uss.." [1-"..#shotgunSounds.."]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..getNumberSounds(25, shotgunSounds), 0x73b461)
        else
            changeSound(25, shotgunSounds[param])
            save()
            sampAddChatMessage(script_name.." {FFFFFF}���� shotgun ���������� ��: {dc4747}"..param, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.ums.." .+") or cmd:find("^"..ini.commands.ums.."$")then
        local param = cmd:match(ini.commands.ums.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 1 or param > tonumber(#m4Sounds) then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.ums.." [1-"..#m4Sounds.."]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..getNumberSounds(31, m4Sounds), 0x73b461)
        else
            changeSound(31, m4Sounds[param])
            save()
            sampAddChatMessage(script_name.." {FFFFFF}���� m4 ���������� ��: {dc4747}"..param, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.urs.." .+") or cmd:find("^"..ini.commands.urs.."$")then
        local param = cmd:match(ini.commands.urs.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 1 or param > tonumber(#rifleSounds) then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.urs.." [1-"..#rifleSounds.."]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..getNumberSounds(33, rifleSounds), 0x73b461)
        else
            changeSound(33, rifleSounds[param])
            save()
            sampAddChatMessage(script_name.." {FFFFFF}���� rifle ���������� ��: {dc4747}"..param, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.uuzi.." .+") or cmd:find("^"..ini.commands.uuzi.."$")then
        local param = cmd:match(ini.commands.uuzi.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 1 or param > tonumber(#uziSounds) then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.uuzi.." [1-"..#uziSounds.."]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..getNumberSounds(28, uziSounds), 0x73b461)
        else
            changeSound(28, uziSounds[param])
            save()
            sampAddChatMessage(script_name.." {FFFFFF}���� uzi ���������� ��: {dc4747}"..param, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.ump5.." .+") or cmd:find("^"..ini.commands.ump5.."$")then
        local param = cmd:match(ini.commands.ump5.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 1 or param > tonumber(#mp5Sounds) then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.ump5.." [1-"..#mp5Sounds.."]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..getNumberSounds(29, mp5Sounds), 0x73b461)
        else
            changeSound(29, mp5Sounds[param])
            save()
            sampAddChatMessage(script_name.." {FFFFFF}���� mp5 ���������� ��: {dc4747}"..param, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.ubs.." .+") or cmd:find("^"..ini.commands.ubs.."$")then
        local param = cmd:match(ini.commands.ubs.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 1 or param > tonumber(#hitSounds) then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.ubs.." [1-"..#hitSounds.."]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..getNumberSounds("hit", hitSounds), 0x73b461)
        else
            changeSound("hit", hitSounds[param])
            save()
            sampAddChatMessage(script_name.." {FFFFFF}���� ��������� ���������� ��: {dc4747}"..param, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.ups.." .+") or cmd:find("^"..ini.commands.ups.."$")then
        local param = cmd:match(ini.commands.ups.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 1 or param > tonumber(#painSounds) then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.ups.." [1-"..#painSounds.."]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..getNumberSounds("pain", painSounds), 0x73b461)
        else
            changeSound("pain", painSounds[param])
            save()
            sampAddChatMessage(script_name.." {FFFFFF}���� ��������� ���������� ��: {dc4747}"..param, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.ugd.." .+") or cmd:find("^"..ini.commands.ugd.."$")then
        local param = cmd:match(ini.commands.ugd.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 0 or param > 100 then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.ugd.." [0-100]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.ugenrl_main.enemyWeaponDist, 0x73b461)
        else
            ini.ugenrl_main.enemyWeaponDist = param
            save()
            sampAddChatMessage(script_name.." {FFFFFF}��������� ������ ��������� ������� ����������� ��: {dc4747}"..ini.ugenrl_main.enemyWeaponDist, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.ugvw.." .+") or cmd:find("^"..ini.commands.ugvw.."$")then
        local param = cmd:match(ini.commands.ugvw.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 0.00 or param > 1.00 then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.ugvw.." [0.0-1.00]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.ugenrl_volume.weapon, 0x73b461)
        else
            ini.ugenrl_volume.weapon = param
            save()
            sampAddChatMessage(script_name.." {FFFFFF}��������� ����� ��������� ����������� ��: {dc4747}"..ini.ugenrl_volume.weapon, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.ugvh.." .+") or cmd:find("^"..ini.commands.ugvh.."$")then
        local param = cmd:match(ini.commands.ugvh.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 0.00 or param > 1.00 then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.ugvh.." [0.0-1.00]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.ugenrl_volume.hit, 0x73b461)
        else
            ini.ugenrl_volume.hit = param
            save()
            sampAddChatMessage(script_name.." {FFFFFF}��������� ����� ��������� ����������� ��: {dc4747}"..ini.ugenrl_volume.hit, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.ugvp.." .+") or cmd:find("^"..ini.commands.ugvp.."$")then
        local param = cmd:match(ini.commands.ugvp.." (.+)")
        param = tonumber(param)
        if type(param) ~= 'number' or param < 0.00 or param > 1.00 then
            sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.ugvp.." [0.0-1.00]", 0x73b461)
            sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.ugenrl_volume.pain, 0x73b461)
        else
            ini.ugenrl_volume.pain = param
            save()
            sampAddChatMessage(script_name.." {FFFFFF}��������� ����� ���� ����������� ��: {dc4747}"..ini.ugenrl_volume.pain, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.forceaniso.."$")then
        ini.settings.forceaniso = not ini.settings.forceaniso
        save()
        sampAddChatMessage(ini.settings.forceaniso and script_name..' {FFFFFF}������������ ���������� ������� {73b461}��������' or script_name..' {FFFFFF}������������ ���������� ������� {dc4747}���������', 0x73b461)
        gotofunc("ForceAniso")
        return false
    elseif cmd:find("^"..ini.commands.mapzoomfixer.."$")then
        ini.settings.mapzoomfixer = not ini.settings.mapzoomfixer
        checkboxes.mapzoomfixer.v = ini.settings.mapzoomfixer
        save()
        sampAddChatMessage(ini.settings.mapzoomfixer and script_name..' {FFFFFF}����������� ������ ���������������� ��� ���� ����� {73b461}��������' or script_name..' {FFFFFF}����������� ������ ���������������� ��� ���� ����� {dc4747}���������', 0x73b461)
        return false
    elseif cmd:find("^"..ini.commands.shadowcp.." .+") or cmd:find("^"..ini.commands.shadowcp.."$")then
        local param = cmd:match(ini.commands.shadowcp.." (.+)")
        param = tonumber(param)
        if ini.settings.shadowedit then
            if type(param) ~= 'number' or param < 0 or param > 255 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.shadowcp.." [0-255]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.shadowcp, 0x73b461)
            else
                ini.settings.shadowcp = param
                save()
                sliders.shadowcp.v = ini.settings.shadowcp
                gotofunc("ShadowEdit")
                sampAddChatMessage(script_name.." {FFFFFF}�������� ���� ����������� ��: {dc4747}"..ini.settings.shadowcp, 0x73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ��������� ����������� ������ ����, �������� �: {dc4747}"..ini.commands.shadowedit, 0x73b461)
        end
        return false
    elseif cmd:find("^"..ini.commands.shadowlight.." .+") or cmd:find("^"..ini.commands.shadowlight.."$")then
        local param = cmd:match(ini.commands.shadowlight.." (.+)")
        param = tonumber(param)
        if ini.settings.shadowedit then
            if type(param) ~= 'number' or param < 0 or param > 255 then
                sampAddChatMessage(script_name.." {FFFFFF}�����������: {dc4747}"..ini.commands.shadowlight.." [0-255]", 0x73b461)
                sampAddChatMessage(script_name.." {FFFFFF}������� ��������: {dc4747}"..ini.settings.shadowlight, 0x73b461)
            else
                ini.settings.shadowlight = param
                save()
                sliders.shadowlight.v = ini.settings.shadowlight
                gotofunc("ShadowEdit")
                sampAddChatMessage(script_name.." {FFFFFF}���� ������� ����������� ��: {dc4747}"..ini.settings.shadowlight, 0x73b461)
            end
        else
            sampAddChatMessage(script_name.." {FFFFFF}� ��� ��������� ����������� ������ ����, �������� �: {dc4747}"..ini.commands.shadowedit, 0x73b461)
        end
        return false
    end
end

function fastquit()
    sendEmptyPacket(PACKET_DISCONNECTION_NOTIFICATION)
    local adr = getModuleProcAddress("Kernel32.DLL", "ExitProcess")
    callFunction(adr, 1, 0, 0)
end

----------------------------------- [ugenrl] ------------------------------------------------------------
function getListOfSounds(name)
    local soundFiles = {}
	for line in lfs.dir(soundsDir) do
		if line:match(name) then
			soundFiles[#soundFiles+1] = line
		end
	end
	return soundFiles
end

function loadSounds()
	deagleSounds = getListOfSounds('Deagle')
	shotgunSounds = getListOfSounds('Shotgun')
    rifleSounds = getListOfSounds('Rifle')
	m4Sounds = getListOfSounds('M4')
    mp5Sounds = getListOfSounds('MP5')
    uziSounds = getListOfSounds('Uzi')
	hitSounds = getListOfSounds('Bell')
	painSounds = getListOfSounds('Pain')
end

function changeSound(id, name)
	playSound(name, ini.ugenrl_volume.weapon)
	ini.ugenrl_sounds[id] = name
	save()
end

function getNumberSounds(id, name)
    for i, v in ipairs(name) do
        if v == ini.ugenrl_sounds[id] then
            n = i
        end
    end
    return n
end

function playSound(soundFile, soundVol, charHandle)
	if not soundFile or not doesFileExist(soundsDir..soundFile) then return false end
    if audio then collectgarbage() end
	if charHandle == nil then
		audio = loadAudioStream(soundsDir..soundFile)
	else
		audio = load3dAudioStream(soundsDir..soundFile)
		setPlay3dAudioStreamAtChar(audio, charHandle)
	end
	setAudioStreamVolume(audio, soundVol)
	setAudioStreamState(audio, 1)
	clearSound(audio)
end

function clearSound(audio)
	lua_thread.create(function()
		while getAudioStreamState(audio) == 1 do wait(50) end
		collectgarbage()
	end)
end

function onSendRpc(id, bs, priority, reliability, orderingChannel, shiftTs)
	if ini.ugenrl_main.enable then
		if id == 115 then
			local act = raknetBitStreamReadBool(bs)
			dmgId = raknetBitStreamReadInt16(bs)
			dmgValue = raknetBitStreamReadFloat(bs)
			dmgWeaponId = raknetBitStreamReadInt32(bs)
			dmgBodypart = raknetBitStreamReadInt32(bs)
			if ini.ugenrl_main.pain and act then 
				playPain = true 
			end
			if ini.ugenrl_main.hit and not act then 
				playHit = true 
			end
		end
	end
end
-----------------------------------------------------------------------------------------
function sampGetVersion()
	local ver = getModuleHandle("samp.dll")
	if ( ver == 0x0 ) then return false end
	local cmp =  memory.tohex( ver + 0xBABE, 10, true )
	if ( cmp == "F8036A004050518D4C24" ) then
		version = "0.3.7-R1"
    end
    if ( cmp == "E86D9A0A0083C41C85C0" ) then
        version = "0.3.7-R3"
    end
    return version
end

function onReceiveRpc(id, bs)
	if id == 29 and ini.settings.blocktime then
		return false
	end
    if id == 152 and ini.settings.blockweather then
        return false
    end
end

function onSystemInitialized()
    writeMemory(0x5B8E55, 4, 90000, false)--flickr
    writeMemory(0x5B8EB0, 4, 90000, false)--flickr
    memory.setfloat(11926728, 1.0, false)--AudioFix, fixes a bug due to which the sounds of the audio stream were not heard if the user had the radio turned off in the game settings and after changing the sound settings there was still no sound, it was necessary to re-enter the game.
end

function onScriptTerminate(script, quitGame)
	if quitGame then
        sendEmptyPacket(PACKET_DISCONNECTION_NOTIFICATION)
		local adr = getModuleProcAddress("Kernel32.DLL", "ExitProcess")
        callFunction(adr, 1, 0, 0)
	end
end

function sendEmptyPacket(id)
	local bs = raknetNewBitStream()
	raknetBitStreamWriteInt8(bs, id)
	raknetSendBitStream(bs)
	raknetDeleteBitStream(bs)
end

local leftmenu = nil

function imgui.BeforeDrawFrame()
    if leftmenu == nil then
        leftmenu = imgui.GetIO().Fonts:AddFontFromFileTTF('monetloader//gamefixer//fonts//pricedown_rus.ttf', 20.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end

local tab = imgui.ImInt(1)
local tabs = {
    u8'\t\t��������',
    u8'\t\t�����������',
    u8'\t\tBoost FPS',
    u8'\t\tUGenrl',
    u8'\t\t�������',
    u8'\t\t���������',
}

function imgui.OnDrawFrame()
    if not main_menu.v and imgui.Process then imgui.Process = false end
    if main_menu.v then
        imgui.SetNextWindowSize(imgui.ImVec2(860, 540), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin(u8"GameFixer", main_menu, imgui.WindowFlags.NoCollapse)
            imgui.PushFont(leftmenu)
                imgui.CustomMenu(tabs, tab, imgui.ImVec2(130, 48))
                imgui.SetCursorPos(imgui.ImVec2(10, 38))
                imgui.Image(images.one, imgui.ImVec2(45, 45))
                imgui.SetCursorPos(imgui.ImVec2(10, 88))
                imgui.Image(images.two, imgui.ImVec2(45, 45))
                imgui.SetCursorPos(imgui.ImVec2(10, 138))
                imgui.Image(images.three, imgui.ImVec2(45, 45))
                imgui.SetCursorPos(imgui.ImVec2(10, 186))
                imgui.Image(images.four, imgui.ImVec2(45, 45))
                imgui.SetCursorPos(imgui.ImVec2(10, 234))
                imgui.Image(images.five, imgui.ImVec2(45, 45))
                imgui.SetCursorPos(imgui.ImVec2(10, 280))
                imgui.Image(images.six, imgui.ImVec2(45, 45))
            imgui.PopFont()
            imgui.SetCursorPos(imgui.ImVec2(160, 39))
            if tab.v == nil or tab.v == 1 then
                imgui.BeginChild("##��������", imgui.ImVec2(-1, -1), true)
                    if imgui.Checkbox(u8"�������������� ��������������� �����", checkboxes.mapzoom) then
                        ini.settings.mapzoom = checkboxes.mapzoom.v
                        save()
                        gotofunc("MapZoom")
                    end
                    imgui.Text(u8"������� ��������� �����:")
                    imgui.PushItemWidth(625)
                    if imgui.SliderFloat(u8"##mapzoomvalue", sliders.mapzoomvalue, 260.0, 1000.0, "%.1f") then
                        if ini.settings.mapzoom then
                            ini.settings.mapzoomvalue = ("%.1f"):format(sliders.mapzoomvalue.v)
                            save()
                            memory.setfloat(5719357, ini.settings.mapzoomvalue, false)
                        else
                            memory.setfloat(5719357, 1000.0, false)
                        end
                    end
                    imgui.PopItemWidth()
                    imgui.Text(u8"�������� ����������� / ��������� �����:")
                    for i, value in ipairs(arr_animmoney) do
                        if imgui.RadioButton(value, radio_animmoney, i) then
                            ini.settings.animmoney = i
                            save()
                            gotofunc("AnimationMoney")
                        end
                        imgui.SameLine()
                    end
                    imgui.SetCursorPosX(15)
                    imgui.SetCursorPosY(160)
                    imgui.Text(u8"������ ������� �� X:")
                    imgui.SameLine()
                    imgui.PushItemWidth(110)
                    if imgui.InputInt(u8"##crxvmenu", buffers.vmenu_crx) then
                        if buffers.vmenu_crx.v > 100 then
                            buffers.vmenu_crx.v = 100
                        elseif buffers.vmenu_crx.v < 0 then
                            buffers.vmenu_crx.v = 0
                        end
                        ini.settings.crosshairX = buffers.vmenu_crx.v
                        save()
                        memory.setfloat(8755780, ini.settings.crosshairX, false)
                    end
                    imgui.PopItemWidth()
                    imgui.Text(u8"������ ������� �� Y:")
                    imgui.SameLine()
                    imgui.PushItemWidth(110)
                    if imgui.InputInt(u8"##cryvmenu", buffers.vmenu_cry) then
                        if buffers.vmenu_cry.v > 100 then
                            buffers.vmenu_cry.v = 100
                        elseif buffers.vmenu_cry.v < 0 then
                            buffers.vmenu_cry.v = 0
                        end
                        ini.settings.crosshairY = buffers.vmenu_cry.v
                        save()
                        memory.setfloat(8755804, ini.settings.crosshairY, false)
                    end
                    imgui.PopItemWidth()
                    if imgui.CollapsingHeader(u8"�������� ������ � �������", true, imgui.TreeNodeFlags.DefaultOpen) then
                        imgui.Text(u8"������:")
                        imgui.PushItemWidth(625)
                        if imgui.SliderInt(u8"##Weather", sliders.weather, 0, 45) then
                            ini.settings.weather = sliders.weather.v
                            save()
                        end
                        imgui.PopItemWidth()
                        imgui.Text(u8"����:")
                        imgui.PushItemWidth(625)
                        if imgui.SliderInt(u8"##hours", sliders.hours, 0, 23) then
                            ini.settings.hours = sliders.hours.v
                            save()
                            gotofunc("SetTime")
                        end
                        imgui.PopItemWidth()
                        imgui.Text(u8"������:")
                        imgui.PushItemWidth(625)
                        if imgui.SliderInt(u8"##min", sliders.min, 0, 59) then
                            ini.settings.min = sliders.min.v
                            save()
                            gotofunc("SetTime")
                        end
                        imgui.PopItemWidth()
                        if imgui.Checkbox(u8"����������� ��������� ������ ��������", checkboxes.blockweather) then
                            ini.settings.blockweather = checkboxes.blockweather.v
                            save()
                        end
                        if imgui.Checkbox(u8"����������� ��������� ������� ��������", checkboxes.blocktime) then
                            ini.settings.blocktime = checkboxes.blocktime.v
                            save()
                        end
                    end
                    if imgui.Button(u8(ini.settings.bighpbar and '���������' or '��������')..u8" ������� 160 hp", imgui.ImVec2(200, 25)) then
                        ini.settings.bighpbar = not ini.settings.bighpbar
                        sampAddChatMessage(ini.settings.bighpbar and script_name..' {FFFFFF}160hp bar {73b461}�������' or script_name..' {FFFFFF}160hp bar {dc4747}��������', 0x73b461)
                        save()
                        gotofunc("BigHPBar")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.noradio and '���������' or '��������')..u8" ����� � ����������", imgui.ImVec2(200, 25)) then
                        ini.settings.noradio = not ini.settings.noradio
                        sampAddChatMessage(ini.settings.noradio and script_name..' {FFFFFF}����� � ���������� {73b461}��������' or script_name..' {FFFFFF}����� � ���������� {dc4747}���������', 0x73b461)
                        save()
                        gotofunc("NoRadio")
                    end
                    if imgui.Button(u8(ini.settings.nosounds and '���������' or '��������')..u8" ��� ����� � ����", imgui.ImVec2(200, 25)) then
                        ini.settings.nosounds = not ini.settings.nosounds
                        sampAddChatMessage(ini.settings.nosounds and script_name..' {FFFFFF}��� ����� � ���� {73b461}��������' or script_name..' {FFFFFF}��� ����� � ���� {dc4747}���������', 0x73b461)
                        save()
                        gotofunc("NoSounds")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.intmusic and '���������' or '��������')..u8" ������ � ����������", imgui.ImVec2(200, 25)) then
                        ini.settings.intmusic = not ini.settings.intmusic
                        sampAddChatMessage(ini.settings.intmusic and script_name..' {FFFFFF}������ � ���������� {73b461}��������' or script_name..' {FFFFFF}������ � ���������� {dc4747}���������', 0x73b461)
                        save()
                        gotofunc("InteriorMusic")
                    end
                    if imgui.Button(u8(ini.settings.audiostream and '���������' or '��������')..u8" audiostream", imgui.ImVec2(200, 25)) then
                        ini.settings.audiostream = not ini.settings.audiostream
                        sampAddChatMessage(ini.settings.audiostream and script_name..' {FFFFFF}Audiostream {73b461}�������' or script_name..' {FFFFFF}Audiostream {dc4747}��������', 0x73b461)
                        save()
                        gotofunc("AudioStream")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8"�������� ���", imgui.ImVec2(200, 25)) then
                        gotofunc("ClearChat")
                    end
                    if imgui.Button(u8(ini.settings.targetblip and '���������' or '��������')..u8" ������ �� �������", imgui.ImVec2(413, 25)) then
                        ini.settings.targetblip = not ini.settings.targetblip
                        sampAddChatMessage(ini.settings.targetblip and script_name..' {FFFFFF}������ �� ������� {73b461}�������' or script_name..' {FFFFFF}������ �� ������� {dc4747}��������', 0x73b461)
                        save()
                        gotofunc("TargetBlip")
                    end
                    if imgui.Button(u8(ini.settings.blockkeys and '���������' or '��������')..u8" ���������� ������ samp �������", imgui.ImVec2(413, 25)) then
                        ini.settings.blockkeys = not ini.settings.blockkeys
                        sampAddChatMessage(ini.settings.blockkeys and script_name..' {FFFFFF}���������� ������ samp ������� {73b461}��������' or script_name..' {FFFFFF}���������� ������ samp ������� {dc4747}���������', 0x73b461)
                        save()
                        gotofunc("BlockSampKeys")
                    end
                    if imgui.Button(u8(ini.settings.vsync and '���������' or '��������')..u8" ������������ �������������", imgui.ImVec2(413, 25)) then
                        ini.settings.vsync = not ini.settings.vsync
                        sampAddChatMessage(ini.settings.vsync and script_name..' {FFFFFF}������������ ������������� {73b461}��������' or script_name..' {FFFFFF}������������ ������������� {dc4747}���������', 0x73b461)
                        save()
                        gotofunc("Vsync")
                    end
                    if imgui.Button(u8(ini.settings.anticrasher and '���������' or '��������')..u8" ����������", imgui.ImVec2(413, 25)) then
                        ini.settings.anticrasher = not ini.settings.anticrasher
                        sampAddChatMessage(ini.settings.anticrasher and script_name..' {FFFFFF}���������� {73b461}�������' or script_name..' {FFFFFF}���������� {dc4747}��������', 0x73b461)
                        save()
                    end
                imgui.EndChild()
            elseif tab.v == 2 then
                imgui.BeginChild("##�����", imgui.ImVec2(-1, -1), true)
                    if imgui.Checkbox(u8"����������� ����������� � ������ ������� ��� ������", checkboxes.antiblockedplayer) then
                        ini.settings.antiblockedplayer = checkboxes.antiblockedplayer.v
                        save()
                    end
                    if imgui.Checkbox(u8"��������� ��� �� �", checkboxes.chatt) then
                        ini.settings.chatt = checkboxes.chatt.v
                        save()
                    end
                    if imgui.Checkbox(u8"����������� ���������������� ����� �� ���� X � Y", checkboxes.sensfix) then
                        ini.settings.sensfix = checkboxes.sensfix.v
                        save()
                        gotofunc("FixSensitivity")
                    end
                    if imgui.Checkbox(u8"����������� ������ �����", checkboxes.fixblackroads) then
                        ini.settings.fixblackroads = checkboxes.fixblackroads.v
                        save()
                        gotofunc("FixBlackRoads")
                    end
                    if imgui.Checkbox(u8"����������� ���� �������� �������� � ������������� �����", checkboxes.adkfix) then
                        ini.settings.adkfix = checkboxes.adkfix.v
                        save()
                    end
                    if imgui.Checkbox(u8"����������� ������� ���", checkboxes.longarmfix) then
                        ini.settings.longarmfix = checkboxes.longarmfix.v
                        save()
                        gotofunc("FixLongArm")
                    end
                    if imgui.Checkbox(u8"����������� ���������� ����", checkboxes.waterfixquadro) then
                        ini.settings.waterfixquadro = checkboxes.waterfixquadro.v
                        save()
                        gotofunc("FixWaterQuadro")
                    end
                    if imgui.Checkbox(u8"����������� ���� � ����������", checkboxes.intrun) then
                        ini.settings.intrun = checkboxes.intrun.v
                        save()
                        gotofunc("InteriorRun")
                    end
                    if imgui.Checkbox(u8"����������� ����� ����� �� �������", checkboxes.fixcrosshair) then
                        ini.settings.fixcrosshair = checkboxes.fixcrosshair.v
                        save()
                        gotofunc("FixCrosshair")
                    end
                    if imgui.Checkbox(u8"������� ������", checkboxes.sunfix) then
                        ini.settings.sunfix = checkboxes.sunfix.v
                        save()
                        gotofunc("SunFix")
                    end
                    if imgui.Checkbox(u8"����������� �������� ����� �����", checkboxes.fixtaxilight) then
                        ini.settings.fixtaxilight = checkboxes.fixtaxilight.v
                        save()
                        gotofunc("FixTaxiLight")
                    end
                    if imgui.Checkbox(u8"����������� ������ ����� �� ������ �������", checkboxes.dual_monitor_fix) then
                        ini.settings.dual_monitor_fix = checkboxes.dual_monitor_fix.v
                        save()
                    end
                    if imgui.Checkbox(u8"����������� ���� �� ���������", checkboxes.forceaniso) then
                        ini.settings.forceaniso = checkboxes.forceaniso.v
                        save()
                        gotofunc("ForceAniso")
                    end
                    if imgui.Checkbox(u8"����������� ������ ���������������� ��� ���� �����", checkboxes.mapzoomfixer) then
                        ini.settings.mapzoomfixer = checkboxes.mapzoomfixer.v
                        save()
                    end
                    if imgui.Checkbox(u8"����������� ����� ������� ������", checkboxes.radar_color_fix) then
                        ini.settings.radar_color_fix = checkboxes.radar_color_fix.v
                        save()
                        gotofunc("RadarColorFix")
                    end
                    if imgui.Checkbox(u8"����������� ������", checkboxes.radarfix) then
                        ini.settings.radarfix = checkboxes.radarfix.v
                        save()
                        gotofunc("Radarfix")
                    end
                    if checkboxes.radarfix.v then
                        imgui.PushItemWidth(430)
                            if imgui.SliderInt(u8"������ ������", sliders.radarw, 50, 150) then
                                ini.settings.radarWidth = sliders.radarw.v
                                save()
                                gotofunc("Radarfix")
                            end
                            if imgui.SliderInt(u8"������ ������", sliders.radarh, 50, 150) then
                                ini.settings.radarHeight = sliders.radarh.v
                                save()
                                gotofunc("Radarfix")
                            end
                            if imgui.SliderInt(u8"��������� ������ �� X", sliders.radarposx, 20, 555) then
                                ini.settings.radarPosX = sliders.radarposx.v
                                save()
                                gotofunc("Radarfix")
                            end
                            if imgui.SliderInt(u8"��������� ������ �� Y", sliders.radarposy, 20, 555) then
                                ini.settings.radarPosY = sliders.radarposy.v
                                save()
                                gotofunc("Radarfix")
                            end
                        imgui.PopItemWidth()
                    end
                imgui.EndChild()
            elseif tab.v == 3 then
                imgui.BeginChild("##FPSup", imgui.ImVec2(-1, -1), true)
                    if imgui.Button(u8(ini.settings.shownicks and '��������' or '������')..u8" ���� �������", imgui.ImVec2(200, 25)) then
                        ini.settings.shownicks = not ini.settings.shownicks
                        sampAddChatMessage(ini.settings.shownicks and script_name..' {FFFFFF}���� ������� {dc4747}���������' or script_name..' {FFFFFF}���� ������� {73b461}��������', 0x73b461)
                        save()
                        gotofunc("ShowNICKS")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.showhp and '��������' or '������')..u8" �� �������", imgui.ImVec2(200, 25)) then
                        ini.settings.showhp = not ini.settings.showhp
                        sampAddChatMessage(ini.settings.showhp and script_name..' {FFFFFF}������� �� ������� {dc4747}���������' or script_name..' {FFFFFF}������� �� ������� {73b461}��������', 0x73b461)
                        save()
                        gotofunc("ShowHP")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.showchat and '������' or '��������')..u8" ���", imgui.ImVec2(200, 25)) then
                        ini.settings.showchat = not ini.settings.showchat
                        sampAddChatMessage(ini.settings.showchat and script_name..' {FFFFFF}��� {73b461}�������' or script_name..' {FFFFFF}��� {dc4747}��������', 0x73b461)
                        save()
                        gotofunc("ShowCHAT")
                    end
                    if imgui.Button(u8(ini.settings.showhud and '������' or '��������')..u8" HUD", imgui.ImVec2(200, 25)) then
                        ini.settings.showhud = not ini.settings.showhud
                        sampAddChatMessage(ini.settings.showhud and script_name..' {FFFFFF}HUD {73b461}�������' or script_name..' {FFFFFF}HUD {dc4747}��������', 0x73b461)
                        save()
                        gotofunc("ShowHUD")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.unlimitfps and '���������' or '��������')..u8" FPS unlock", imgui.ImVec2(200, 25)) then
                        ini.settings.unlimitfps = not ini.settings.unlimitfps
                        sampAddChatMessage(ini.settings.unlimitfps and script_name..' {FFFFFF}FPS unlock {73b461}�������' or script_name..' {FFFFFF}FPS unlock {dc4747}��������', 0x73b461)
                        save()
                        gotofunc("FPSUnlock")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.postfx and '���������' or '��������')..u8" ����-���������", imgui.ImVec2(200, 25)) then
                        ini.settings.postfx = not ini.settings.postfx
                        sampAddChatMessage(ini.settings.postfx and script_name..' {FFFFFF}����-��������� {73b461}��������' or script_name..' {FFFFFF}����-��������� {dc4747}���������', 0x73b461)
                        save()
                        gotofunc("NoPostfx")
                    end
                    if imgui.Button(u8(ini.settings.nocloudsmall and '���������' or '��������')..u8" ������ ������", imgui.ImVec2(200, 25)) then
                        ini.settings.nocloudsmall = not ini.settings.nocloudsmall
                        save()
                        sampAddChatMessage(ini.settings.nocloudsmall and script_name..' {FFFFFF}������ ������ {73b461}��������' or script_name..' {FFFFFF}������ ������ {dc4747}���������', 0x73b461)
                        gotofunc("NoCloudSmall")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.nocloudbig and '���������' or '��������')..u8" ������� ������", imgui.ImVec2(200, 25)) then
                        ini.settings.nocloudbig = not ini.settings.nocloudbig
                        save()
                        sampAddChatMessage(ini.settings.nocloudbig and script_name..' {FFFFFF}������� ������ {73b461}��������' or script_name..' {FFFFFF}������� ������ {dc4747}���������', 0x73b461)
                        gotofunc("NoCloudBig")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.nobirds and '���������' or '��������')..u8" ����", imgui.ImVec2(200, 25)) then
                        ini.settings.nobirds = not ini.settings.nobirds
                        save()
                        sampAddChatMessage(ini.settings.nobirds and script_name..' {FFFFFF}����� {73b461}��������' or script_name..' {FFFFFF}����� {dc4747}���������', 0x73b461)
                        gotofunc("NoBirds")
                    end
                    if imgui.Button(u8(ini.settings.effects and '���������' or '��������')..u8" �������", imgui.ImVec2(200, 25)) then
                        ini.settings.effects = not ini.settings.effects
                        save()
                        sampAddChatMessage(ini.settings.effects and script_name..' {FFFFFF}������� {73b461}��������' or script_name..' {FFFFFF}������� {dc4747}���������', 0x73b461)
                        gotofunc("NoEffects")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.vehlods and '���������' or '��������')..u8" ���� ����������", imgui.ImVec2(200, 25)) then
                        ini.settings.vehlods = not ini.settings.vehlods
                        save()
                        sampAddChatMessage(ini.settings.vehlods and script_name..' {FFFFFF}���� ���������� {73b461}��������' or script_name..' {FFFFFF}���� ���������� {dc4747}���������', 0x73b461)
                        gotofunc("VehLods")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.noshadows and '���������' or '��������')..u8" ����", imgui.ImVec2(200, 25)) then
                        ini.settings.noshadows = not ini.settings.noshadows
                        save()
                        sampAddChatMessage(ini.settings.noshadows and script_name..' {FFFFFF}���� {73b461}��������' or script_name..' {FFFFFF}���� {dc4747}���������', 0x73b461)
                        gotofunc("NoShadows")
                    end
                    if imgui.Button(u8(ini.settings.nodust and '���������' or '��������')..u8" ���� �� ����� � ��� �� �����", imgui.ImVec2(300, 25)) then
                        ini.settings.nodust = not ini.settings.nodust
                        save()
                        sampAddChatMessage(ini.settings.nodust and script_name..' {FFFFFF}���� �� ����� � ��� �� ����� {73b461}�������' or script_name..' {FFFFFF}���� �� ����� � ��� �� ����� {dc4747}��������', 0x73b461)
                        gotofunc("NoDust")
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(ini.settings.noplaneline and '���������' or '��������')..u8" ������ �� ��������� �� ����", imgui.ImVec2(300, 25)) then
                        ini.settings.noplaneline = not ini.settings.noplaneline
                        save()
                        sampAddChatMessage(ini.settings.noplaneline and script_name..' {FFFFFF}������ �� ��������� �� ���� {73b461}��������' or script_name..' {FFFFFF}������ �� ��������� �� ����  {dc4747}���������', 0x73b461)
                        gotofunc("NoPlaneLine")
                    end
                    if imgui.CollapsingHeader(u8"�������� ����������") then
                        if imgui.Button(u8(ini.settings.givemedist and '���������' or '��������')..u8" ����������� ������ ����������", imgui.ImVec2(300, 25)) then
                            ini.settings.givemedist = not ini.settings.givemedist
                            sampAddChatMessage(ini.settings.givemedist and script_name..' {FFFFFF}����������� ������ ���������� {73b461}��������' or script_name..' {FFFFFF}����������� ������ ���������� {dc4747}���������', 0x73b461)
                            save()
                            gotofunc("GivemeDist")
                        end
                        if ini.settings.givemedist then
                            imgui.Text(u8"��������� ����������:")
                            imgui.PushItemWidth(625)
                                if imgui.SliderFloat(u8"##Drawdist", sliders.drawdist, 35, 3600, "%.1f") then
                                    ini.settings.drawdist = ("%.1f"):format(sliders.drawdist.v)
                                    save()
                                    memory.setfloat(12044272, ini.settings.drawdist, false)
                                end
                                imgui.Text(u8"��������� ���������� � ��������� ����������:")
                                if imgui.SliderFloat(u8"##drawdistair", sliders.drawdistair, 35, 3600, "%.1f") then
                                    ini.settings.drawdistair = ("%.1f"):format(sliders.drawdistair.v)
                                    save()
                                    if isCharInAnyPlane(PLAYER_PED) or isCharInAnyHeli(PLAYER_PED) then
                                        if memory.getfloat(12044272, false) ~= ini.settings.drawdistair then
                                            memory.setfloat(12044272, ini.settings.drawdistair, false)
                                        end
                                    end
                                end
                                imgui.Text(u8"��������� ������:")
                                if imgui.SliderFloat(u8"##fog", sliders.fog, -100, 500, "%.1f") then
                                    ini.settings.fog = ("%.1f"):format(sliders.fog.v)
                                    save()
                                    memory.setfloat(13210352, ini.settings.fog, false)
                                end
                                imgui.Text(u8"��������� �����:")
                                if imgui.SliderFloat(u8"##lod", sliders.lod, 0, 300, "%.1f") then
                                    ini.settings.lod = ("%.1f"):format(sliders.lod.v)
                                    save()
                                    memory.setfloat(0x858FD8, ini.settings.lod, false)
                                end
                            imgui.PopItemWidth()
                        end
                    end
                    if imgui.CollapsingHeader(u8"�������� �����") then
                        if imgui.Button(u8(ini.settings.shadowedit and '���������' or '��������')..u8" ����������� ������ ����", imgui.ImVec2(300, 25)) then
                            ini.settings.shadowedit = not ini.settings.shadowedit
                            sampAddChatMessage(ini.settings.shadowedit and script_name..' {FFFFFF}����������� ������ ���� {73b461}��������' or script_name..' {FFFFFF}����������� ������ ���� {dc4747}���������', 0x73b461)
                            save()
                            gotofunc("ShadowEdit")
                        end
                        if ini.settings.shadowedit then
                            imgui.Text(u8"�������� ����:")
                            imgui.PushItemWidth(625)
                                if imgui.SliderInt(u8"##shadowcp", sliders.shadowcp, 0, 255) then
                                    ini.settings.shadowcp = sliders.shadowcp.v
                                    save()
                                    memory.setint32(12043496, ini.settings.shadowcp, false)
                                end
                                imgui.Text(u8"���� �������:")
                                if imgui.SliderInt(u8"##shadowlight", sliders.shadowlight, 0, 255) then
                                    ini.settings.shadowlight = sliders.shadowlight.v
                                    save()
                                    memory.setint32(12043500, ini.settings.shadowlight, false)
                                end
                            imgui.PopItemWidth()
                        end
                    end
                    if imgui.CollapsingHeader(u8"����������� ������� ��������� ��� ����������� ����-���������") then
                        if imgui.Button(u8(ini.fixtimecyc.active and '���������' or '��������')..u8" ����������� ���������", imgui.ImVec2(300, 25)) then
                            ini.fixtimecyc.active = not ini.fixtimecyc.active
                            sampAddChatMessage(ini.fixtimecyc.active and script_name..' {FFFFFF}����������� ������� ��������� ��� ����������� ����-��������� {73b461}��������' or script_name..' {FFFFFF}����������� ������� ��������� ��� ����������� ����-��������� {dc4747}���������', 0x73b461)
                            save()
                            gotofunc("FixTimecyc")
                        end
                        if ini.fixtimecyc.active then
                            imgui.Text(u8"All Ambient:")
                            imgui.PushItemWidth(625)
                                if imgui.SliderFloat(u8"##AllAmbient", sliders.allambient, 0.000, 1.000, "%.3f") then
                                    if ini.fixtimecyc.active then
                                        ini.fixtimecyc.allambient = ("%.3f"):format(sliders.allambient.v)
                                        save()
                                        memory.setfloat(9228384, ini.fixtimecyc.allambient, false)
                                    end
                                end
                                imgui.Text(u8"Object Ambient:")
                                if imgui.SliderFloat(u8"##ObjAmbient", sliders.objambient, 0.000, 1.000, "%.3f") then
                                    if ini.fixtimecyc.active then
                                        ini.fixtimecyc.objambient = ("%.3f"):format(sliders.objambient.v)
                                        save()
                                        memory.setfloat(12044024, ini.fixtimecyc.objambient, false)
                                    end
                                end
                                imgui.Text(u8"World Ambient_R:")
                                if imgui.SliderFloat(u8"##WorldAmbientR", sliders.worldambientR, 0.000, 1.000, "%.3f") then
                                    if ini.fixtimecyc.active then
                                        ini.fixtimecyc.worldambientR = ("%.3f"):format(sliders.worldambientR.v)
                                        save()
                                        memory.setfloat(12044048, ini.fixtimecyc.worldambientR, false)
                                    end
                                end
                                imgui.Text(u8"World Ambient_G:")
                                if imgui.SliderFloat(u8"##WorldAmbientG", sliders.worldambientG, 0.000, 1.000, "%.3f") then
                                    if ini.fixtimecyc.active then
                                        ini.fixtimecyc.worldambientG = ("%.3f"):format(sliders.worldambientG.v)
                                        save()
                                        memory.setfloat(12044072, ini.fixtimecyc.worldambientG, false)
                                    end
                                end
                                imgui.Text(u8"World Ambient_B:")
                                if imgui.SliderFloat(u8"##WorldAmbientB", sliders.worldambientB, 0.000, 1.000, "%.3f") then
                                    if ini.fixtimecyc.active then
                                        ini.fixtimecyc.worldambientB = ("%.3f"):format(sliders.worldambientB.v)
                                        save()
                                        memory.setfloat(12044096, ini.fixtimecyc.worldambientB, false)
                                    end
                                end
                            imgui.PopItemWidth()
                        end
                    end
                    if imgui.CollapsingHeader(u8"������� ������") then
                        if imgui.Checkbox(u8"���������� ��������� �� ������� ������", checkboxes.cleaninfo) then
                            ini.cleaner.cleaninfo = checkboxes.cleaninfo.v
                            save()
                        end
                        if imgui.Button(u8(ini.cleaner.autoclean and '���������' or '��������')..u8" ����-������� ������", imgui.ImVec2(300, 25)) then
                            ini.cleaner.autoclean = not ini.cleaner.autoclean
                            save()
                            sampAddChatMessage((script_name.."{FFFFFF} �������������� ������� ������ %s"):format(ini.cleaner.autoclean and "{73b461}��������" or "{dc4747}���������"), 0x73b461)
                        end
                        imgui.Text(u8"����� ��� ����-������� ������:")
                        imgui.PushItemWidth(625)
                        if imgui.SliderInt(u8"##memlimit", sliders.limitmem, 80, 2000) then
                            ini.cleaner.limit = sliders.limitmem.v
                            save()
                        end
                        imgui.PopItemWidth()
                        if imgui.Button(u8"�������� ������", imgui.ImVec2(300, 25)) then
                            gotofunc("CleanMemory")
                        end
                    end
                imgui.EndChild()
            elseif tab.v == 4 then
                imgui.BeginChild("##Ugenrl", imgui.ImVec2(-1, -1), true)
                    if imgui.Checkbox(u8"�������� Ultimate Genrl", checkboxes.ugenrl_enable) then
                        ini.ugenrl_main.enable = checkboxes.ugenrl_enable.v
                        checkboxes.ugenrl_enable.v = ini.ugenrl_main.enable
                        if ini.ugenrl_main.autonosounds then
                            if ini.ugenrl_main.enable then
                                ini.settings.nosounds = false
                            else
                                ini.settings.nosounds = true
                            end
                            save()
                            gotofunc("NoSounds")
                        end
                    end
                    if checkboxes.ugenrl_enable.v then
                        imgui.SameLine()
                        imgui.SetCursorPosX(221)
                        if imgui.Checkbox(u8"��������� ����� ���� ��� ��������� Ultimate Genrl", checkboxes.autonosounds) then
                            ini.ugenrl_main.autonosounds = checkboxes.autonosounds.v
                            save()
                        end
                        if imgui.Checkbox(u8"����� ���������", checkboxes.weapon_checkbox) then
                            ini.ugenrl_main.weapon = checkboxes.weapon_checkbox.v
                            save()
                        end
                        imgui.SameLine()
                        imgui.SetCursorPosX(221)
                        if checkboxes.weapon_checkbox.v then
                            if imgui.Checkbox(u8"����� ��������� �������", checkboxes.enemyweapon_checkbox) then
                                ini.ugenrl_main.enemyWeapon = checkboxes.enemyweapon_checkbox.v
                                save()
                            end
                        end
                        if imgui.Checkbox(u8"���� ��������� �� �������", checkboxes.hit_checkbox) then
                            ini.ugenrl_main.hit = checkboxes.hit_checkbox.v
                            save()
                        end
                        imgui.SameLine()
                        if imgui.Checkbox(u8"����� ����", checkboxes.pain_checkbox) then
                            ini.ugenrl_main.pain = checkboxes.pain_checkbox.v
                            save()
                        end
                        imgui.Text(u8"������� ��������� / ����������� Ultimate Genrl:")
                        imgui.SameLine()
                        imgui.SetCursorPosY(106)
                        if imgui.HotKey(u8"##ugkey", FastUgenrlKey, tLastKeys, 70) then
                            rkeys.changeHotKey(bindFastActiveUgenrl, FastUgenrlKey.v)
                            sampAddChatMessage(script_name.." {FFFFFF}������ ��������: {dc4747}" .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. "{ffffff} | �����: {dc4747}" .. table.concat(rkeys.getKeysName(FastUgenrlKey.v), " + "), 0x73b461)
                            ini.ugenrl_main.fastactive = encodeJson(FastUgenrlKey.v)
                            save()
                        end
                        imgui.Separator()

                        imgui.SetCursorPos(imgui.ImVec2(15, 175))
                        imgui.Text(u8"���� Deagle:")
                        imgui.SetCursorPos(imgui.ImVec2(15, 197))
                        imgui.BeginChild("##����� ������, ����", imgui.ImVec2(140, 207), true)
                            for i, v in ipairs(deagleSounds) do
                                if selected ~= getNumberSounds(24, deagleSounds) then
                                    selected = getNumberSounds(24, deagleSounds)
                                end
                                if imgui.Selectable(tostring(i)..". "..v, selected == i) then
                                    changeSound(24, deagleSounds[i])
                                end
                            end
                        imgui.EndChild()

                        imgui.SetCursorPos(imgui.ImVec2(160, 175))
                        imgui.Text(u8"���� Shotgun:")
                        imgui.SetCursorPos(imgui.ImVec2(160, 197))
                        imgui.BeginChild("##����� ������, ���", imgui.ImVec2(140, 207), true)
                            for i, v in ipairs(shotgunSounds) do
                                if selected ~= getNumberSounds(25, shotgunSounds) then
                                    selected = getNumberSounds(25, shotgunSounds)
                                end
                                if imgui.Selectable(tostring(i)..". "..v, selected == i) then
                                    changeSound(25, shotgunSounds[i])
                                end
                            end
                        imgui.EndChild()

                        imgui.SetCursorPos(imgui.ImVec2(305, 175))
                        imgui.Text(u8"���� M4:")
                        imgui.SetCursorPos(imgui.ImVec2(305, 197))
                        imgui.BeginChild("##����� ������, �4", imgui.ImVec2(140, 207), true)
                            for i, v in ipairs(m4Sounds) do
                                if selected ~= getNumberSounds(31, m4Sounds) then
                                    selected = getNumberSounds(31, m4Sounds)
                                end
                                if imgui.Selectable(tostring(i)..". "..v, selected == i) then
                                    changeSound(31, m4Sounds[i])
                                end
                            end
                        imgui.EndChild()

                        imgui.SetCursorPos(imgui.ImVec2(450, 175))
                        imgui.Text(u8"���� Rifle:")
                        imgui.SetCursorPos(imgui.ImVec2(450, 197))
                        imgui.BeginChild("##����� ������, �����", imgui.ImVec2(140, 207), true)
                            for i, v in ipairs(rifleSounds) do
                                if selected ~= getNumberSounds(33, rifleSounds) then
                                    selected = getNumberSounds(33, rifleSounds)
                                end
                                if imgui.Selectable(tostring(i)..". "..v, selected == i) then
                                    changeSound(33, rifleSounds[i])
                                end
                            end
                        imgui.EndChild()

                        imgui.SetCursorPos(imgui.ImVec2(15, 413))
                        imgui.Text(u8"���� MP5:")
                        imgui.SetCursorPos(imgui.ImVec2(15, 434))
                        imgui.BeginChild("##����� ������, mp5", imgui.ImVec2(140, 207), true)
                            for i, v in ipairs(mp5Sounds) do
                                if selected ~= getNumberSounds(29, mp5Sounds) then
                                    selected = getNumberSounds(29, mp5Sounds)
                                end
                                if imgui.Selectable(tostring(i)..". "..v, selected == i) then
                                    changeSound(29, mp5Sounds[i])
                                end
                            end
                        imgui.EndChild()

                        imgui.SetCursorPos(imgui.ImVec2(160, 413))
                        imgui.Text(u8"���� Uzi:")
                        imgui.SetCursorPos(imgui.ImVec2(160, 434))
                        imgui.BeginChild("##����� ������, uzi", imgui.ImVec2(140, 207), true)
                            for i, v in ipairs(uziSounds) do
                                if selected ~= getNumberSounds(28, uziSounds) then
                                    selected = getNumberSounds(28, uziSounds)
                                end
                                if imgui.Selectable(tostring(i)..". "..v, selected == i) then
                                    changeSound(28, uziSounds[i])
                                end
                            end
                        imgui.EndChild()
                        
                        imgui.SetCursorPos(imgui.ImVec2(305, 413))
                        imgui.Text(u8"���� ���������:")
                        imgui.SetCursorPos(imgui.ImVec2(305, 434))
                        imgui.BeginChild("##���� ��������� �� �������##c", imgui.ImVec2(140, 207), true)
                            for i, v in ipairs(hitSounds) do
                                if selected ~= getNumberSounds("hit", hitSounds) then
                                    selected = getNumberSounds("hit", hitSounds)
                                end
                                if imgui.Selectable(tostring(i)..". "..v, selected == i) then
                                    changeSound("hit", hitSounds[i])
                                end
                            end
                        imgui.EndChild()

                        imgui.SetCursorPos(imgui.ImVec2(450, 413))
                        imgui.Text(u8"���� ����:")
                        imgui.SetCursorPos(imgui.ImVec2(450, 434))
                        imgui.BeginChild("##���� ����##c", imgui.ImVec2(140, 207), true)
                            for i, v in ipairs(painSounds) do
                                if selected ~= getNumberSounds("pain", painSounds) then
                                    selected = getNumberSounds("pain", painSounds)
                                end
                                if imgui.Selectable(tostring(i)..". "..v, selected == i) then
                                    changeSound("pain", painSounds[i])
                                end
                            end
                        imgui.EndChild()
                        imgui.PushItemWidth(220)
                        imgui.SetCursorPos(imgui.ImVec2(15, 647))
                        imgui.Text(u8"��������� ������:")
                        imgui.SetCursorPos(imgui.ImVec2(15, 667))
                        if imgui.SliderFloat(u8"��������� ���������##1", sliders.weapon_volume_slider, 0.00, 1.00, "%.2f") then
                            ini.ugenrl_volume.weapon = ("%.2f"):format(sliders.weapon_volume_slider.v)
                            save()
                        end
                        imgui.SetCursorPos(imgui.ImVec2(15, 704))
                        if imgui.SliderFloat(u8"��������� ���������##1", sliders.hit_volume_slider, 0.00, 1.00, "%.2f") then
                            ini.ugenrl_volume.hit = ("%.2f"):format(sliders.hit_volume_slider.v)
                            save()
                        end
                        imgui.SetCursorPos(imgui.ImVec2(15, 742))
                        if imgui.SliderFloat(u8"��������� ����##1", sliders.pain_volume_slider, 0.00, 1.00, "%.2f") then
                            ini.ugenrl_volume.pain = ("%.2f"):format(sliders.pain_volume_slider.v) 
                            save()
                        end
                        imgui.SetCursorPos(imgui.ImVec2(15, 774))
                        imgui.Text(u8"��������� ������ ��������� �������:")
                        imgui.SetCursorPos(imgui.ImVec2(15, 794))
                        if imgui.SliderInt("##enemydist", sliders.enemyweapon_dist, 0, 100) then
                            ini.ugenrl_main.enemyWeaponDist = sliders.enemyweapon_dist.v
                            save()
                        end
                        imgui.PopItemWidth()
                    end
                imgui.EndChild()
            elseif tab.v == 5 then
                imgui.BeginChild("##�������", imgui.ImVec2(-1, -1), true)
                    imgui.PushItemWidth(130)
                    if imgui.InputText(u8"�������� ������� �������� ���� �������", buffers.cmd_openmenu) then
                        ini.commands.openmenu = buffers.cmd_openmenu.v
                        save()
                    end
                    if imgui.InputText(u8"�������� �����", buffers.cmd_settime) then
                        ini.commands.settime = buffers.cmd_settime.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ������", buffers.cmd_setweather) then
                        ini.commands.setweather = buffers.cmd_setweather.v
                        save()
                    end
                    if imgui.InputText(u8"����������� ��������� ������� ��������", buffers.cmd_blockservertime) then
                        ini.commands.blockservertime = buffers.cmd_blockservertime.v
                        save()
                    end
                    if imgui.InputText(u8"����������� ��������� ������ ��������", buffers.cmd_blockserverweather) then
                        ini.commands.blockserverweather = buffers.cmd_blockserverweather.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ������ ����������", buffers.cmd_givemedist) then
                        ini.commands.givemedist = buffers.cmd_givemedist.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ��������� ����������", buffers.cmd_drawdistance) then
                        ini.commands.drawdistance = buffers.cmd_drawdistance.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ��������� ���������� ��� ���������� ����������", buffers.cmd_drawdistanceair) then
                        ini.commands.drawdistanceair = buffers.cmd_drawdistanceair.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ��������� ������", buffers.cmd_fogdistance) then
                        ini.commands.fogdistance = buffers.cmd_fogdistance.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ��������� �����", buffers.cmd_loddistance) then
                        ini.commands.loddistance = buffers.cmd_loddistance.v
                        save()
                    end
                    if imgui.InputText(u8"��������/������ ���� �������", buffers.cmd_shownicks) then
                        ini.commands.shownicks = buffers.cmd_shownicks.v
                        save()
                    end
                    if imgui.InputText(u8"��������/������ �� �������", buffers.cmd_showhp) then
                        ini.commands.showhp = buffers.cmd_showhp.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����� � ����������", buffers.cmd_offradio) then
                        ini.commands.offradio = buffers.cmd_offradio.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���", buffers.cmd_clearchat) then
                        ini.commands.clearchat = buffers.cmd_clearchat.v
                        save()
                    end
                    if imgui.InputText(u8"������ ���", buffers.cmd_showchat) then
                        ini.commands.showchat = buffers.cmd_showchat.v
                        save()
                    end
                    if imgui.InputText(u8"������ HUD", buffers.cmd_showhud) then
                        ini.commands.showhud = buffers.cmd_showhud.v
                        save()
                    end
                    if imgui.InputText(u8"�������� �������� �������� ��������� ���-�� �����", buffers.cmd_animmoney) then
                        ini.commands.animmoney = buffers.cmd_animmoney.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������� 160hp", buffers.cmd_bighpbar) then
                        ini.commands.bighpbar = buffers.cmd_bighpbar.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������������ ���", buffers.cmd_fpslock) then
                        ini.commands.fpslock = buffers.cmd_fpslock.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����-���������", buffers.cmd_postfx) then
                        ini.commands.postfx = buffers.cmd_postfx.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ����������� � ������ ������� ��� ������", buffers.cmd_antiblockedplayer) then
                        ini.commands.antiblockedplayer = buffers.cmd_antiblockedplayer.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� �������� ���� �� ������� \"�\"", buffers.cmd_chatopenfix) then
                        ini.commands.chatopenfix = buffers.cmd_chatopenfix.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����-������� ������", buffers.cmd_autocleaner) then
                        ini.commands.autocleaner = buffers.cmd_autocleaner.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ������", buffers.cmd_cleanmemory) then
                        ini.commands.cleanmemory = buffers.cmd_cleanmemory.v
                        save()
                    end
                    if imgui.InputText(u8"��������  / ��������� ��������� �� ������� ������", buffers.cmd_cleaninfo) then
                        ini.commands.cleaninfo = buffers.cmd_cleaninfo.v
                        save()
                    end
                    if imgui.InputText(u8"���������� ����� � ���������� ��� ����-������� ������", buffers.cmd_setmbforautocleaner) then
                        ini.commands.setmbforautocleaner = buffers.cmd_setmbforautocleaner.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����", buffers.cmd_nobirds) then
                        ini.commands.nobirds = buffers.cmd_nobirds.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ���� �� ����� � ��� �� �����", buffers.cmd_nodust) then
                        ini.commands.nodust = buffers.cmd_nodust.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ��������� ��� nopostfx", buffers.cmd_fixtimecyc) then
                        ini.commands.fixtimecyc = buffers.cmd_fixtimecyc.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ����� ��������� ��������� ����", buffers.cmd_aamb) then
                        ini.commands.aamb = buffers.cmd_aamb.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ��������� �������� � �����", buffers.cmd_oamb) then
                        ini.commands.oamb = buffers.cmd_oamb.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� ��������� � ������� RGB", buffers.cmd_wamb) then
                        ini.commands.wamb = buffers.cmd_wamb.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������� ����", buffers.cmd_effects) then
                        ini.commands.effects = buffers.cmd_effects.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ������ �������", buffers.cmd_editcrosshair) then
                        ini.commands.editcrosshair = buffers.cmd_editcrosshair.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ���������� ������ ����", buffers.cmd_shadowedit) then
                        ini.commands.shadowedit = buffers.cmd_shadowedit.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������� ������", buffers.cmd_nocloudbig) then
                        ini.commands.nocloudbig = buffers.cmd_nocloudbig.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������ ������", buffers.cmd_nocloudsmall) then
                        ini.commands.nocloudsmall = buffers.cmd_nocloudsmall.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����", buffers.cmd_noshadows) then
                        ini.commands.noshadows = buffers.cmd_noshadows.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ����� ����������", buffers.cmd_vehlods) then
                        ini.commands.vehlods = buffers.cmd_vehlods.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ����� ����� �� �������", buffers.cmd_fixcrosshair) then
                        ini.commands.fixcrosshair = buffers.cmd_fixcrosshair.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ���� � ����������", buffers.cmd_intrun) then
                        ini.commands.intrun = buffers.cmd_intrun.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ���� �������� �������� � ������������� �����", buffers.cmd_adkfix) then
                        ini.commands.adr = buffers.cmd_adkfix.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ���������� ����", buffers.cmd_waterfixquadro) then
                        ini.commands.waterfixquadro = buffers.cmd_waterfixquadro.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ������� ���", buffers.cmd_longarmfix) then
                        ini.commands.longarmfix = buffers.cmd_longarmfix.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ������ �����", buffers.cmd_fixblackroads) then
                        ini.commands.fixblackroads = buffers.cmd_fixblackroads.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ���������������� ����� �� ���� X � Y", buffers.cmd_fixsens) then
                        ini.commands.sensfix = buffers.cmd_fixsens.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� audiostream", buffers.cmd_audiostream) then
                        ini.commands.audiostream = buffers.cmd_audiostream.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������ � ����������", buffers.cmd_intmusic) then
                        ini.commands.intmusic = buffers.cmd_intmusic.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����� ����", buffers.cmd_nosounds) then
                        ini.commands.nosounds = buffers.cmd_nosounds.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ���������� ������ samp �������", buffers.cmd_blocksampkeys) then
                        ini.commands.blockkeys = buffers.cmd_blocksampkeys.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������ �� ��������� �� ����", buffers.cmd_noplaneline) then
                        ini.commands.noplaneline = buffers.cmd_noplaneline.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������", buffers.cmd_sunfix) then
                        ini.commands.sunfix = buffers.cmd_sunfix.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������ �� �������", buffers.cmd_targetblip) then
                        ini.commands.targetblip = buffers.cmd_targetblip.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������������ �������������", buffers.cmd_vsync) then
                        ini.commands.vsync = buffers.cmd_vsync.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ����� ������� ������", buffers.cmd_radar_color_fix) then
                        ini.commands.radar_color_fix = buffers.cmd_radar_color_fix.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ������", buffers.cmd_radarfix) then
                        ini.commands.radarfix = buffers.cmd_radarfix.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ������ ����� �� ������ �������", buffers.cmd_dual_monitor_fix) then
                        ini.commands.dual_monitor_fix = buffers.cmd_dual_monitor_fix.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� �������� ����� � �����", buffers.cmd_fixtaxilight) then
                        ini.commands.fixtaxilight = buffers.cmd_fixtaxilight.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ������ ������", buffers.cmd_radarwidth) then
                        ini.commands.radarWidth = buffers.cmd_radarwidth.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ������ ������", buffers.cmd_radarheight) then
                        ini.commands.radarHeight = buffers.cmd_radarheight.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ������� ������ �� X", buffers.cmd_radarx) then
                        ini.commands.radarx = buffers.cmd_radarx.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ������� ������ �� Y", buffers.cmd_radary) then
                        ini.commands.radarx = buffers.cmd_radary.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� Ultimate Genrl", buffers.cmd_ugenrl) then
                        ini.commands.ugenrl = buffers.cmd_ugenrl.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� �������������� ���������� ������ ��� ���. Ultimate Genrl", buffers.cmd_autonosounds) then
                        ini.commands.autonosounds = buffers.cmd_autonosounds.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� deagle", buffers.cmd_uds) then
                        ini.commands.uds = buffers.cmd_uds.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� shotgun", buffers.cmd_uss) then
                        ini.commands.uss = buffers.cmd_uss.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� m4", buffers.cmd_ums) then
                        ini.commands.ums = buffers.cmd_ums.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� rifle", buffers.cmd_urs) then
                        ini.commands.urs = buffers.cmd_urs.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� uzi", buffers.cmd_uuzi) then
                        ini.commands.uuzi = buffers.cmd_uuzi.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� mp5", buffers.cmd_ump5) then
                        ini.commands.ump5 = buffers.cmd_ump5.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� ���������", buffers.cmd_ubs) then
                        ini.commands.ubs = buffers.cmd_ubs.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� ����", buffers.cmd_ups) then
                        ini.commands.ups = buffers.cmd_ups.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ��������� ������ ������ �������", buffers.cmd_ugd) then
                        ini.commands.ugd = buffers.cmd_ugd.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ��������� ����� ���������", buffers.cmd_ugvw) then
                        ini.commands.ugvw = buffers.cmd_ugvw.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ��������� ����� ���������", buffers.cmd_ugvh) then
                        ini.commands.ugvh = buffers.cmd_ugvh.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ��������� ����� ����", buffers.cmd_ugvp) then
                        ini.commands.ugvp = buffers.cmd_ugvp.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ������������ ���������� �������", buffers.cmd_forceaniso) then
                        ini.commands.forceaniso = buffers.cmd_forceaniso.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������� ������ ���������������� ��� ���� �����", buffers.cmd_mapzoomfixer) then
                        ini.commands.mapzoomfixer = buffers.cmd_mapzoomfixer.v
                        save()
                    end
                    if imgui.InputText(u8"�������� �������� ����", buffers.cmd_shadowcp) then
                        ini.commands.shadowcp = buffers.cmd_shadowcp.v
                        save()
                    end
                    if imgui.InputText(u8"�������� ���� �������", buffers.cmd_shadowlight) then
                        ini.commands.shadowlight = buffers.cmd_shadowlight.v
                        save()
                    end
                    if imgui.InputText(u8"�������� / ��������� ����������", buffers.cmd_anticrasher) then
                        ini.commands.anticrasher = buffers.cmd_anticrasher.v
                        save()
                    end
                    imgui.PopItemWidth()
                imgui.EndChild()
            elseif tab.v == 6 then
                imgui.BeginChild("##���������", imgui.ImVec2(-1, -1), true)
                    imgui.Text(u8"��������� ����:")
                    imgui.PushItemWidth(150)
                    if imgui.Combo(u8"##thgm", iStyle, tStyle, #tStyle) then
                        ini.settings.theme = iStyle.v+1
                        save()
                        SwitchTheStyle(ini.settings.theme)
                    end
                    imgui.PopItemWidth()
                imgui.EndChild()
            end
        imgui.End()
    end
end

local wm = require 'lib.windows.message'

function onWindowMessage(msg, wparam, lparam)
    if (msg == 256 or msg == 257) and wparam == 27 and imgui.Process then
        consumeWindowMessage(true, true)
        if msg == 257 then
            main_menu = imgui.ImBool(false)
        end
    end
    if ini.settings.mapzoomfixer then
        if (msg == 522 and readMemory(0xBA68A5, 1, false) == 5) then
            if wparam == 7864320 and memory.getfloat(0xBA67AC, false) < 1000.0 then
                memory.setfloat(0xBA67AC, memory.getfloat(0xBA67AC, false) + 50.0, false)
            elseif wparam == 4287102976 and memory.getfloat(0xBA67AC, false) > 301.5 then
                memory.setfloat(0xBA67AC, memory.getfloat(0xBA67AC, false) - 50.0, false)
            end
        end
        if readMemory(0xBA68A5, 1, false) == 5 then -- mapzoom -+
            if isKeyDown(187) and memory.getfloat(0xBA67AC, false) < 1000.0 then
                memory.setfloat(0xBA67AC, memory.getfloat(0xBA67AC, false) + 50.0, false)
            elseif isKeyDown(189) and memory.getfloat(0xBA67AC, false) > 301.5 then
                memory.setfloat(0xBA67AC, memory.getfloat(0xBA67AC, false) - 50.0, false)
            end
        end
    end
    if ini.settings.dual_monitor_fix then
        if msg == wm.WM_KILLFOCUS then
            ffi.C.GetClipCursor(rcOldClip);
            ffi.C.ClipCursor(rcOldClip);
        elseif msg == wm.WM_SETFOCUS then
            ffi.C.GetWindowRect(ffi.C.GetActiveWindow(), rcClip);
            ffi.C.ClipCursor(rcClip);
        end
    end
    if msg == 261 and wparam == 13 then --������ �� alt+enter
        consumeWindowMessage(true, true)
    end
end


----------------------------------------------------- [Functions] ----------------------------------------------------------
function gotofunc(fnc)
    ------------------------------------fixes and other-----------------------------
    if fnc == "all" then
        SwitchTheStyle(ini.settings.theme)

        memory.write(0x736F88, 0, 4, false) --�������� �� ���������� ����� ���
        memory.write(0x53E94C, 0, 1, false) --del fps delay 14 ms
        memory.fill(0x555854, 0x90, 5, false) --InterioRreflections
        memory.write(0x745BC9, 0x9090, 2, false) --SADisplayResolutions(1920x1080// 16:9)
        memory.fill(0x460773, 0x90, 7, false) --CJFix
        memory.write(12761548, 1051965045, 4, false) --car speed fps fix
        memory.fill(0x5557CF, 0x90, 7, true) --binthesky_by_DK
        callFunction(7629216, 0, 0)--mousefix in pause
        writeMemory(4436208, 1, 195, false)-- saPedsTalk2U

        if sampGetVersion() == "0.3.7-R1" then
            memory.write(sampGetBase() + 0x64C8C, 1, 1, true)--Min FPS
            memory.write(sampGetBase() + 0x64C91, 200, 1, true)--Max FPS
            memory.write(sampGetBase() + 0xD7B79, 0x2D393939, 4, true)--FPS StringInfo
            memory.write(sampGetBase() + 0xD7B78, 0x31, 1, true)--FPS StringInfo
            memory.write(sampGetBase() + 0x64ACA, 0xFB, 1, true)--Min FontSize -5
            memory.write(sampGetBase() + 0x64ACF, 0x07, 1, true)--Max FontSize 7
            memory.write(sampGetBase() + 0xD7B00, 1948267821, 4, true)--FontSize StringInfo
            memory.write(sampGetBase() + 0xD7B04, 3612783, 4, true)--FontSize StringInfo
            memory.write(sampGetBase() + 0x64A51, 0x32, 1, true)--PageSize MAX
            memory.write(sampGetBase() + 0xD7AD5, 0x35, 1, true)--PageSize StringInfo
            -------------------------- [AntiCrasher] --------------------------------
            if ini.settings.anticrasher then
                memory.write(sampGetBase() + 0x5CF2C, 0x90909090, 4, true)
                memory.write(sampGetBase() + 0x5CF2C + 4, 0x90, 1, true)
                memory.write(sampGetBase() + 0x5CF2C + 4 + 9, 0x90909090, 4, true)
                memory.write(sampGetBase() + 0x5CF2C + 4 + 9 + 4, 0x90, 1, true)
            else
                memory.write(sampGetBase() + 0x5CF2C, 7729128, 4, true)
                memory.write(sampGetBase() + 0x5CF2C + 4, 0, 1, true)
                memory.write(sampGetBase() + 0x5CF2C + 4 + 9, 2097870979, 4, true)
                memory.write(sampGetBase() + 0x5CF2C + 4 + 9 + 4, 14, 1, true)
            end
            -------------------------------------------------------------------------
        end
        ----------------------------------------------------------------------------
        memory.setfloat(8755780, ini.settings.crosshairX, false)
        memory.setfloat(8755804, ini.settings.crosshairY, false)
        memory.write(5825313, 8755804, 4, false)--���������� ���
        -----------------------------------------------------------------------------
    end
    -----------------------------------------------------------------------
    if fnc == "OpenMenu" then
        main_menu.v = not main_menu.v
        imgui.Process = main_menu.v
	end
    if fnc == "ClearChat" then
        memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
        memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
        memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
	end
    if fnc == "SetTime" or fnc == "all" then
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, ini.settings.hours)
        raknetBitStreamWriteInt8(bs, ini.settings.min)
        raknetEmulRpcReceiveBitStream(29, bs)
        raknetDeleteBitStream(bs)
	end
    if fnc == "SetWeather" or fnc == "all" then
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, ini.settings.weather)
        raknetEmulRpcReceiveBitStream(152, bs)
        raknetDeleteBitStream(bs)
	end
    if fnc == "FixTimecyc" or fnc == "all" then
        if ini.fixtimecyc.active then
            memory.write(6359759, 144, 1, false)-- ���
            memory.write(6359760, 144, 1, false)-- ���
            memory.write(6359761, 144, 1, false)-- ���
            memory.write(6359762, 144, 1, false)-- ���
            memory.write(6359763, 144, 1, false)-- ���
            memory.write(6359764, 144, 1, false)-- ���
            memory.write(6359778, 144, 1, false)-- ���
            memory.write(6359779, 144, 1, false)-- ���
            memory.write(6359780, 144, 1, false)-- ���
            memory.write(6359781, 144, 1, false)-- ���
            memory.write(6359782, 144, 1, false)-- ���
            memory.write(6359783, 144, 1, false)-- ���
            memory.write(6359784, 144, 1, false)-- ���
            memory.write(6359785, 144, 1, false)-- ���
            memory.write(6359786, 144, 1, false)-- ���
            memory.write(6359787, 144, 1, false)-- ���
            memory.write(5637016, 12044024, 4, false)-- ���
            memory.write(5637032, 12044024, 4, false)-- ���
            memory.write(5637048, 12044024, 4, false)-- ���
            memory.write(5636920, 12044048, 4, false)-- ���
            memory.write(5636936, 12044072, 4, false)-- ���
            memory.write(5636952, 12044096, 4, false)-- ���
    
            memory.setfloat(9228384, ini.fixtimecyc.allambient, false)
            memory.setfloat(12044024, ini.fixtimecyc.objambient, false)
            memory.setfloat(12044048, ini.fixtimecyc.worldambientR, false)
            memory.setfloat(12044072, ini.fixtimecyc.worldambientG, false)
            memory.setfloat(12044096, ini.fixtimecyc.worldambientB, false)
        else
            memory.write(6359759, 217, 1, false)-- ����
            memory.write(6359760, 21, 1, false)-- ����
            memory.write(6359761, 96, 1, false)-- ����
            memory.write(6359762, 208, 1, false)-- ����
            memory.write(6359763, 140, 1, false)-- ����
            memory.write(6359764, 0, 1, false)-- ����
            memory.write(6359778, 199, 1, false)-- ����
            memory.write(6359779, 5, 1, false)-- ����
            memory.write(6359780, 96, 1, false)-- ����
            memory.write(6359781, 208, 1, false)-- ����
            memory.write(6359782, 140, 1, false)-- ����
            memory.write(6359783, 0, 1, false)-- ����
            memory.write(6359784, 0, 1, false)-- ����
            memory.write(6359785, 0, 1, false)-- ����
            memory.write(6359786, 128, 1, false)-- ����
            memory.write(6359787, 63, 1, false)-- ����
            memory.write(5637016, 12043448, 4, false)-- ����
            memory.write(5637032, 12043452, 4, false)-- ����
            memory.write(5637048, 12043456, 4, false)-- ����
            memory.write(5636920, 12043424, 4, false)-- ����
            memory.write(5636936, 12043428, 4, false)-- ����
            memory.write(5636952, 12043432, 4, false)-- ����
        end
	end
    if fnc == "GivemeDist" or fnc == "all" then
        if sampGetVersion() == "0.3.7-R1" then
            if ini.settings.givemedist then
                memory.write(5499541, 12044272, 4, false)-- ���
                memory.write(8381985, 13213544, 4, false)-- ���
            else
                memory.write(5499541, 12043504, 4, false)-- ����
                memory.write(8381985, 13210352, 4, false)-- ����
            end
        end
	end
    if fnc == "NoBirds" or fnc == "all" then
        if ini.settings.nobirds then
            memory.write(5497200, 232, 1, false)--birds on
            memory.write(5497201, 1918619, 4, false)-- birds on
        else
            memory.fill(5497200, 144, 5, false)-- nobirds
        end
	end
    if fnc == "NoDust" or fnc == "all" then
        if ini.settings.nodust then
            memory.write(7205311, 1056964608, 4, false)
            memory.write(7205316, 1065353216, 4, false)
            memory.write(7205321, 1065353216, 4, false)
            memory.write(7205389, 1056964608, 4, false)
            memory.write(7204123, 1050253722, 4, false)
            memory.write(7204128, 1065353216, 4, false)
            memory.write(7204133, 1060320051, 4, false)
            memory.write(5527777, 1036831949, 4, false)
            memory.write(4846974, 1053609165, 4, false)
            memory.write(4846757, 1053609165, 4, false)
        else
            memory.write(7205311, 0, 4, false)
            memory.write(7205316, 0, 4, false)
            memory.write(7205321, 0, 4, false)
            memory.write(7205389, 0, 4, false)
            memory.write(7204123, 0, 4, false)
            memory.write(7204128, 0, 4, false)
            memory.write(7204133, 0, 4, false)
            memory.write(5527777, -1, 4, false)
            memory.write(4846974, -1, 4, false)
            memory.write(4846757, -1, 4, false)
        end
	end
    if fnc == "ShadowEdit" or fnc == "all" then
        if ini.settings.shadowedit then
            memory.write(5635169, 0, 1, false)
            memory.write(5635259, 0, 1, false)
            memory.setint32(12043496, ini.settings.shadowcp, false)
            memory.setint32(12043500, ini.settings.shadowlight, false)
        else
            memory.write(5635169, 72, 1, false)
            memory.write(5635259, 76, 1, false)
        end
	end
    if fnc == "NoCloudBig" or fnc == "all" then
        if ini.settings.nocloudbig then
            memory.write(5497268, 495044584, 4, false)--������� ������ ������ ���
            memory.write(5497272, 0, 1, false)--������� ������ ������ ���
        else
            memory.write(5497268, -1869574000, 4, false)--������� ������ ������ ����
            memory.write(5497272, 144, 1, false)--������� ������ ������ ����
        end
	end
    if fnc == "NoCloudSmall" or fnc == "all" then
        if ini.settings.nocloudsmall then
            memory.write(5497121, 494111464, 4, false)--������ ������ ���
            memory.write(5497125, 0, 1, false)--������ ������ ���
        else
            memory.fill(5497121, 144, 5, false)--������ ������ ����
        end
	end
    if fnc == "NoShadows" or fnc == "all" then
        if ini.settings.noshadows then
            memory.write(5497177, 233, 1, false)
            memory.write(5489067, 492560616, 4, false)
            memory.write(5489071, 0, 1, false)
            memory.write(6186889, 33807, 2, false)
            memory.write(7388587, 111379727, 4, false)
            memory.write(7388591, 0, 2, false)
            memory.write(7391066, 32081167, 4, false)
            memory.write(7391070, -1869611008, 4, false)
        else
            memory.write(5497177, 195, 1, false)
            memory.fill(5489067, 144, 5, false)
            memory.write(6186889, 59792, 2, false)
            memory.fill(7388587, 144, 6, false)
            memory.fill(7391066, 144, 9, false)
        end
	end
    if fnc == "VehLods" or fnc == "all" then
        if ini.settings.vehlods then
            memory.write(5425646, 1, 1, false)
        else
            memory.write(5425646, 0, 1, false)
        end
	end
    if fnc == "NoPostfx" or fnc == "all" then
        if ini.settings.postfx then
            memory.write(7358318, 1448280247, 4, false)--postfx on
            memory.write(7358314, -988281383, 4, false)--postfx on
            --writeMemory(0x53E227, 1, 233, false)
        else
            --writeMemory(0x53E227, 1, 0xC3, false)
            memory.write(7358318, 2866, 4, false)--postfx off
            memory.write(7358314, -380152237, 4, false)--postfx off
        end
	end
    if fnc == "FPSUnlock" or fnc == "all" then
        if sampGetVersion() == "0.3.7-R1" then
            if ini.settings.unlimitfps then
                memory.write(sampGetBase() + 0x9D9D0, 1347550997, 4, true)
            else
                memory.write(sampGetBase() + 0x9D9D0, -549912, 4, true)
            end
        end
	end
    if fnc == "NoEffects" or fnc == "all" then
        if ini.settings.effects then
            memory.write(4891712, 1443425411, 4, false)
        else
            memory.write(4891712, 8386, 4, false)
        end
	end
    if fnc == "ShowHUD" or fnc == "all" then
        if ini.settings.showhud then
            displayHud(true)
            memory.setint8(0xBA676C, 0)
        else
            displayHud(false)
            memory.setint8(0xBA676C, 2)
        end
	end
    if fnc == "ShowCHAT" or fnc == "all" then
        if sampGetVersion() == "0.3.7-R1" then
            if ini.settings.showchat then
                memory.write(sampGetBase() + 0x7140F, 0, 1, true)
                sampSetChatDisplayMode(2)
            else
                memory.write(sampGetBase() + 0x7140F, 1, 1, true)
                sampSetChatDisplayMode(0)
            end
        end
	end
    if fnc == "ShowHP" or fnc == "all" then
        if sampGetVersion() == "0.3.7-R1" then
            if ini.settings.showhp then
                memory.setint16(sampGetBase() + 0x6FC30, 0xC390, true)
            else
                memory.setint16(sampGetBase() + 0x6FC30, 0x8B55, true)
            end
        end
	end
    if fnc == "ShowNICKS" or fnc == "all" then
        if sampGetVersion() == "0.3.7-R1" then
            if ini.settings.shownicks then
                memory.setint16(sampGetBase() + 0x70D40, 0xC390, true)
            else
                memory.setint16(sampGetBase() + 0x70D40, 0x8B55, true)
            end
        end
	end
    if fnc == "FixCrosshair" or fnc == "all" then
        if ini.settings.fixcrosshair then
            memory.write(0x058E280, 0xEB, 1, true)
        else
            memory.write(0x058E280, 0x7A, 1, true)
        end
        checkboxes.fixcrosshair.v = ini.settings.fixcrosshair
	end
    if fnc == "InteriorRun" or fnc == "all" then
        if ini.settings.intrun then
            memory.write(5630064, -1027591322, 4, false)
            memory.write(5630068, 4, 2, false)
        else
            memory.write(5630064, 69485707, 4, false)
            memory.write(5630068, 1165, 2, false)
        end
        checkboxes.intrun.v = ini.settings.intrun
	end
    if fnc == "FixWaterQuadro" or fnc == "all" then
        if ini.settings.waterfixquadro then
            memory.setfloat(13101856, 0.0, false)
            memory.write(7249056, 13101856, 4, false)
            memory.write(7249115, 13101856, 4, false)
            memory.write(7249175, 13101856, 4, false)
            memory.write(7249235, 13101856, 4, false)
        else
            memory.write(7249056, 8752012, 4, false)
            memory.write(7249115, 8752012, 4, false)
            memory.write(7249175, 8752012, 4, false)
            memory.write(7249235, 8752012, 4, false)
        end
        checkboxes.waterfixquadro.v = ini.settings.waterfixquadro
	end
    if fnc == "FixLongArm" or fnc == "all" then
        if ini.settings.longarmfix then
            memory.write(7045634, 33807, 2, false)
            memory.write(7046489, 33807, 2, false)
        else
            memory.write(7045634, 59792, 2, false)
            memory.write(7046489, 59792, 2, false)
        end
        checkboxes.longarmfix.v = ini.settings.longarmfix
	end
    if fnc == "FixBlackRoads" or fnc == "all" then
        if ini.settings.fixblackroads then
            memory.write(8931716, 0, 4, false)
        else
            memory.write(8931716, 2, 4, false)
        end
        checkboxes.fixblackroads.v = ini.settings.fixblackroads
	end
    if fnc == "FixSensitivity" or fnc == "all" then
        if ini.settings.sensfix then
            memory.write(5382798, 11987996, 4, false)
            memory.write(5311528, 11987996, 4, false)
            memory.write(5316106, 11987996, 4, false)
        else
            memory.write(5382798, 11987992, 4, false)
            memory.write(5311528, 11987992, 4, false)
            memory.write(5316106, 11987992, 4, false)
        end
        checkboxes.sensfix.v = ini.settings.sensfix
	end
    if fnc == "AudioStream" or fnc == "all" then
        if sampGetVersion() == "0.3.7-R1" then
            if ini.settings.audiostream then
                memory.write(sampGetBase() + 104848, 9449, 2, true)-- �������� ����������
            else
                memory.write(sampGetBase() + 104848, 50064, 2, true)-- ��������� ����������
            end
        end
	end
    if fnc == "InteriorMusic" or fnc == "all" then
        if ini.settings.intmusic then
            memory.write(5276752, -591647351, 4, false)
            memory.write(5276756, 182, 2, false)
            memory.write(5277719, -591647351, 4, false)
            memory.write(5277723, 182, 2, false)
        else
            memory.fill(5276752, 144, 6, false)
            memory.fill(5277719, 144, 6, false)
        end
	end
    if fnc == "NoSounds" or fnc == "all" then
        if ini.settings.nosounds then
            callFunction(0x507440, 0, 0)
            writeMemory(5081563, 4, 1233978347, false)
        else
            callFunction(0x507430, 0, 0)
            writeMemory(5081563, 4, 242153, false)
            local bs = raknetNewBitStream()
            raknetEmulRpcReceiveBitStream(42, bs)
            raknetDeleteBitStream(bs)
        end
	end
    if fnc == "NoRadio" or fnc == "all" then
        if ini.settings.noradio then
            memory.write(5159328, -1947628715, 4, false)
        else
            memory.write(5159328, -1962933054, 4, false)
        end
	end
    if fnc == "BigHPBar" or fnc == "all" then
        if ini.settings.bighpbar then
            memory.setfloat(12030944, 910.4, true)
            save()
        else
            memory.setfloat(12030944, 569.0, true)
            save()
        end
	end
    if fnc == "MapZoom" or fnc == "all" then
        if ini.settings.mapzoom then
            memory.setfloat(5719357, ini.settings.mapzoomvalue, false)
        else
            memory.setfloat(5719357, 1000.0, false)
        end
	end
    if fnc == "AnimationMoney" or fnc == "all" then
        if ini.settings.animmoney == 1 then
            memory.write(5707667, 138, 1, false)
        elseif ini.settings.animmoney == 2 then
            memory.write(5707667, 137, 1, false)
        elseif ini.settings.animmoney == 3 then
            memory.write(5707667, 139, 1, false)
        end
	end
    if fnc == "BlockSampKeys" or fnc == "all" then
        if sampGetVersion() == "0.3.7-R1" then
            if ini.settings.blockkeys then
                memory.fill(sampGetBase() + 31102, 0, 1, true)-- F4
                memory.fill(sampGetBase() + 463840, 0, 1, true)--f1
                memory.write(sampGetBase() + 383732, -1869574000, 4, true)--chat T
            else
                memory.fill(sampGetBase() + 31102, 115, 1, true)--F4
                memory.fill(sampGetBase() + 463840, 112, 1, true)--f1
                memory.write(sampGetBase() + 383732, 69489803, 4, true)--chat T
            end
        end
	end
    if fnc == "NoPlaneLine" or fnc == "all" then
        if ini.settings.noplaneline then
            memory.hex2bin('E9ABFAFFFF', 0x7178F0, 5)
        else
            memory.fill(0x7178F0, 0x90, 5, false)
        end
	end
    if fnc == "SunFix" or fnc == "all" then
        if ini.settings.sunfix then
            memory.hex2bin("E865041C00", 0x53C136, 5)
        else
            memory.fill(0x53C136, 0x90, 5, true)
        end
        checkboxes.sunfix.v = ini.settings.sunfix
    end
    if fnc == "TargetBlip" or fnc == "all" then
        if ini.settings.targetblip then
            memory.write(5497324, 116, 1, false)
        else
            memory.write(5497324, 235, 1, false)
        end
    end
    if fnc == "CleanMemory" then
        local oldram = ("%d"):format(tonumber(get_memory()))
        callFunction(0x53C500, 2, 2, true, true)
        callFunction(0x53C810, 1, 1, true)
        callFunction(0x40CF80, 0, 0)
        callFunction(0x4090A0, 0, 0)
        callFunction(0x5A18B0, 0, 0)
        callFunction(0x707770, 0, 0)
        local newram = ("%d"):format(tonumber(get_memory()))
        if ini.cleaner.cleaninfo then
            sampAddChatMessage(script_name.."{FFFFFF} ������ ��: {dc4747}"..oldram.." ��. {FFFFFF}������ �����: {dc4747}"..newram.." ��. {FFFFFF}�������: {dc4747}"..oldram - newram.." ��.", 0x73b461)
        end
    end
    if fnc == "Vsync" or fnc == "all" then
        if ini.settings.vsync then
            memory.write(12216212, 1, 1, true)
        else
            memory.write(12216212, 0, 1, true)
        end
    end
    if fnc == "RadarColorFix" or fnc == "all" then
        if ini.settings.radar_color_fix then
            memory.write(0x58A798, 255, 1, false)
            memory.write(0x58A790, 255, 1, false)
            memory.write(0x58A78E, 255, 1, false)
            memory.write(0x58A89A, 255, 1, false)
            memory.write(0x58A896, 255, 1, false)
            memory.write(0x58A894, 255, 1, false)
            memory.write(0x58A8EE, 255, 1, false)
            memory.write(0x58A8E6, 255, 1, false)
            memory.write(0x58A8DE, 255, 1, false)
            memory.write(0x58A9A2, 255, 1, false)
            memory.write(0x58A99A, 255, 1, false)
            memory.write(0x58A996, 255, 1, false)
        else
            memory.write(0x58A798, 0, 1, false)
            memory.write(0x58A790, 0, 1, false)
            memory.write(0x58A78E, 0, 1, false)
            memory.write(0x58A89A, 0, 1, false)
            memory.write(0x58A896, 0, 1, false)
            memory.write(0x58A894, 0, 1, false)
            memory.write(0x58A8EE, 0, 1, false)
            memory.write(0x58A8E6, 0, 1, false)
            memory.write(0x58A8DE, 0, 1, false)
            memory.write(0x58A9A2, 0, 1, false)
            memory.write(0x58A99A, 0, 1, false)
            memory.write(0x58A996, 0, 1, false)
        end
    end
    if fnc == "Radarfix" or fnc == "all" then
        if ini.settings.radarfix then
            memory.setfloat(8809336, ini.settings.radarHeight, false)--������ ������ X
            memory.setfloat(8809332, ini.settings.radarWidth, false)--������ ������ Y
            memory.setfloat(8751632, ini.settings.radarPosX, false)--������� ������ �� X
            memory.setfloat(8809328, ini.settings.radarPosY, false)--������� ������ �� Y
            ---------------- [fix bug edit pos elements] ----------------
            memory.write(5828441, 9263116, 4, false)
            memory.write(5828895, 9263116, 4, false)
            memory.write(7422387, 5108644, 4, false)
            memory.write(7422456, 5108644, 4, false)
            memory.write(7441684, 5108644, 4, false)
            -------------------------------------------------------------
        else
            memory.setfloat(8809336, 94.0, false)--������ ������ X
            memory.setfloat(8809332, 76.0, false)--������ ������ Y
            memory.setfloat(8751632, 40.0, false)--������� ������ �� X
            memory.setfloat(8809328, 104.0, false)--������� ������ �� Y
        end
        checkboxes.radarfix.v = ini.settings.radarfix
    end
    if fnc == "FixTaxiLight" or fnc == "all" then
        if ini.settings.fixtaxilight then
            memory.write(12697552, 1, 1, false)--�������� �������� ����� �����
        else
            memory.write(12697552, 0, 1, false)--��������� �������� ����� �����
        end
        checkboxes.fixtaxilight.v = ini.settings.fixtaxilight
    end
    if fnc == "ForceAniso" or fnc == "all" then
        if ini.settings.forceaniso then
            if readMemory(0x730F9C, 1, false) ~= 0 then
                memory.write(0x730F9C, 0, 1, false)-- force aniso
                loadScene(1337, 1337, 1337)
                callFunction(0x40D7C0, 1, 1, -1)
            end
        else
            if readMemory(0x730F9C, 1, false) ~= 1 then
                memory.write(0x730F9C, 1, 1, false)-- force aniso
                loadScene(1337, 1337, 1337)
                callFunction(0x40D7C0, 1, 1, -1)
            end
        end
        checkboxes.forceaniso.v = ini.settings.forceaniso
    end
end


---------------------------------------------- [imgui func] ----------------------------------------------------
-- labels - Array - �������� ��������� ����
-- selected - imgui.ImInt() - ��������� ����� ����
-- size - imgui.ImVec2() - ������ ���������
-- speed - float - �������� �������� ������ �������� (�������������, �� ��������� - 0.2)
-- centering - bool - ������������� ������ � �������� (�������������, �� ��������� - false)
function imgui.CustomMenu(labels, selected, size, speed, centering)
    local bool = false
    speed = speed and speed or 0.2
    local radius = size.y * 0.50
    local draw_list = imgui.GetWindowDrawList()
    if LastActiveTime == nil then LastActiveTime = {} end
    if LastActive == nil then LastActive = {} end
    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end
    for i, v in ipairs(labels) do
        local c = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()
        if imgui.InvisibleButton(v..'##'..i, size) then
            selected.v = i
            LastActiveTime[v] = os.clock()
            LastActive[v] = true
            bool = true
        end
        imgui.SetCursorPos(c)
        local t = selected.v == i and 1.0 or 0.0
        if LastActive[v] then
            local time = os.clock() - LastActiveTime[v]
            if time <= 0.3 then
                local t_anim = ImSaturate(time / speed)
                t = selected.v == i and t_anim or 1.0 - t_anim
            else
                LastActive[v] = false
            end
        end
        local col_bg = imgui.GetColorU32(selected.v == i and imgui.ImVec4(0.40, 0.40, 0.40, 0.80) or imgui.ImVec4(0,0,0,0))
        local col_box = imgui.GetColorU32(selected.v == i and imgui.GetStyle().Colors[imgui.Col.Button] or imgui.ImVec4(0,0,0,0))
        local col_hovered = imgui.GetStyle().Colors[imgui.Col.ButtonHovered]
        local col_hovered = imgui.GetColorU32(imgui.ImVec4(col_hovered.x, col_hovered.y, col_hovered.z, (imgui.IsItemHovered() and 0.2 or 0)))
        draw_list:AddRectFilled(imgui.ImVec2(p.x-size.x/6, p.y), imgui.ImVec2(p.x + (radius * 0.65) + t * size.x, p.y + size.y), col_bg, 0.0)
        draw_list:AddRectFilled(imgui.ImVec2(p.x-size.x/6, p.y), imgui.ImVec2(p.x + (radius * 0.65) + size.x, p.y + size.y), col_hovered, 0.0)
        --draw_list:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x+5, p.y + size.y), col_box)
        imgui.SetCursorPos(imgui.ImVec2(c.x+(centering and (size.x-imgui.CalcTextSize(v).x)/2 or 15), c.y+(size.y-imgui.CalcTextSize(v).y)/2))
        imgui.Text(v)
        imgui.SetCursorPos(imgui.ImVec2(c.x, c.y+size.y))
    end
    return bool
end
------------------------------------------------------------------------------------------------------------------------------------

------------------------------------ [theme] ----------------------------------
function SwitchTheStyle(theme)
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = ImVec2(15, 15)
    style.WindowRounding = 0.0
    style.FramePadding = ImVec2(5, 5)
    style.ItemSpacing = ImVec2(12, 8)
    style.ItemInnerSpacing = ImVec2(8, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 0.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 0.0
    style.ChildWindowRounding = 0.0
    style.FrameRounding = 0.0
    style.WindowTitleAlign = ImVec2(0.5, 0.5)
    style.ButtonTextAlign = ImVec2(0.5, 0.5)

    if theme == 1 or theme == nil then
        colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
        colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
        colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
        colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
        colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
        colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
        colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
        colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.ComboBg]                = colors[clr.PopupBg]
        colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
        colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
    elseif theme == 2 then
        colors[clr.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
        colors[clr.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
        colors[clr.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
        colors[clr.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
        colors[clr.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
        colors[clr.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
        colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
        colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
        colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.ComboBg]                = colors[clr.PopupBg]
        colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
        colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
    elseif theme == 3 then
        colors[clr.FrameBg]                = ImVec4(0.48, 0.23, 0.16, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.43, 0.26, 0.40)
        colors[clr.FrameBgActive]          = ImVec4(0.98, 0.43, 0.26, 0.67)
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.48, 0.23, 0.16, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark]              = ImVec4(0.98, 0.43, 0.26, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.88, 0.39, 0.24, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.43, 0.26, 1.00)
        colors[clr.Button]                 = ImVec4(0.98, 0.43, 0.26, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.98, 0.43, 0.26, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.98, 0.28, 0.06, 1.00)
        colors[clr.Header]                 = ImVec4(0.98, 0.43, 0.26, 0.31)
        colors[clr.HeaderHovered]          = ImVec4(0.98, 0.43, 0.26, 0.80)
        colors[clr.HeaderActive]           = ImVec4(0.98, 0.43, 0.26, 1.00)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.25, 0.10, 0.78)
        colors[clr.SeparatorActive]        = ImVec4(0.75, 0.25, 0.10, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.98, 0.43, 0.26, 0.25)
        colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.43, 0.26, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.43, 0.26, 0.95)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.50, 0.35, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.43, 0.26, 0.35)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.ComboBg]                = colors[clr.PopupBg]
        colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
        colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
    elseif theme == 4 then  
        colors[clr.FrameBg]                = ImVec4(0.16, 0.48, 0.42, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.98, 0.85, 0.40)
        colors[clr.FrameBgActive]          = ImVec4(0.26, 0.98, 0.85, 0.67)
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.16, 0.48, 0.42, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark]              = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.24, 0.88, 0.77, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.Button]                 = ImVec4(0.26, 0.98, 0.85, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.06, 0.98, 0.82, 1.00)
        colors[clr.Header]                 = ImVec4(0.26, 0.98, 0.85, 0.31)
        colors[clr.HeaderHovered]          = ImVec4(0.26, 0.98, 0.85, 0.80)
        colors[clr.HeaderActive]           = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(0.10, 0.75, 0.63, 0.78)
        colors[clr.SeparatorActive]        = ImVec4(0.10, 0.75, 0.63, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.26, 0.98, 0.85, 0.25)
        colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.98, 0.85, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.98, 0.85, 0.95)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.81, 0.35, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.98, 0.85, 0.35)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.ComboBg]                = colors[clr.PopupBg]
        colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
        colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
    elseif theme == 5 then
        colors[clr.Text]                   = ImVec4(0.80, 0.80, 0.83, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(0.07, 0.07, 0.09, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.07, 0.07, 0.09, 1.00)
        colors[clr.Border]                 = ImVec4(0.80, 0.80, 0.83, 0.88)
        colors[clr.BorderShadow]           = ImVec4(0.92, 0.91, 0.88, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.FrameBgHovered]         = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(1.00, 0.98, 0.95, 0.75)
        colors[clr.TitleBgActive]          = ImVec4(0.07, 0.07, 0.09, 1.00)
        colors[clr.MenuBarBg]              = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarGrab]          = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ComboBg]                = ImVec4(0.19, 0.18, 0.21, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.SliderGrab]             = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.SliderGrabActive]       = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.Button]                 = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.Header]                 = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.HeaderActive]           = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.ResizeGripHovered]      = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ResizeGripActive]       = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16)
        colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39)
        colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotLinesHovered]       = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotHistogramHovered]   = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.25, 1.00, 0.00, 0.43)
        colors[clr.ModalWindowDarkening]   = ImVec4(1.00, 0.98, 0.95, 0.73)
    elseif theme == 6 then
        colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]         = ImVec4(0.60, 0.60, 0.60, 1.00)
        colors[clr.WindowBg]             = ImVec4(0.09, 0.09, 0.09, 1.00)
        colors[clr.ChildWindowBg]        = ImVec4(9.90, 9.99, 9.99, 0.00)
        colors[clr.PopupBg]              = ImVec4(0.09, 0.09, 0.09, 1.00)
        colors[clr.Border]               = ImVec4(0.71, 0.71, 0.71, 0.40)
        colors[clr.BorderShadow]         = ImVec4(9.90, 9.99, 9.99, 0.00)
        colors[clr.FrameBg]              = ImVec4(0.34, 0.30, 0.34, 0.30)
        colors[clr.FrameBgHovered]       = ImVec4(0.22, 0.21, 0.21, 0.40)
        colors[clr.FrameBgActive]        = ImVec4(0.20, 0.20, 0.20, 0.44)
        colors[clr.TitleBg]              = ImVec4(0.52, 0.27, 0.77, 0.82)
        colors[clr.TitleBgActive]        = ImVec4(0.55, 0.28, 0.75, 0.87)
        colors[clr.TitleBgCollapsed]     = ImVec4(9.99, 9.99, 9.90, 0.20)
        colors[clr.MenuBarBg]            = ImVec4(0.27, 0.27, 0.29, 0.80)
        colors[clr.ScrollbarBg]          = ImVec4(0.30, 0.20, 0.39, 1.00)
        colors[clr.ScrollbarGrab]        = ImVec4(0.41, 0.19, 0.63, 0.31)
        colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.19, 0.63, 0.78)
        colors[clr.ScrollbarGrabActive]  = ImVec4(0.41, 0.19, 0.63, 1.00)
        colors[clr.ComboBg]              = ImVec4(0.20, 0.20, 0.20, 0.99)
        colors[clr.CheckMark]            = ImVec4(0.89, 0.89, 0.89, 0.50)
        colors[clr.SliderGrab]           = ImVec4(1.00, 1.00, 1.00, 0.30)
        colors[clr.SliderGrabActive]     = ImVec4(0.80, 0.50, 0.50, 1.00)
        colors[clr.Button]               = ImVec4(0.41, 0.19, 0.63, 0.44)
        colors[clr.ButtonHovered]        = ImVec4(0.41, 0.19, 0.63, 0.86)
        colors[clr.ButtonActive]         = ImVec4(0.64, 0.33, 0.94, 1.00)
        colors[clr.Header]               = ImVec4(0.56, 0.27, 0.73, 0.44)
        colors[clr.HeaderHovered]        = ImVec4(0.78, 0.44, 0.89, 0.80)
        colors[clr.HeaderActive]         = ImVec4(0.81, 0.52, 0.87, 0.80)
        colors[clr.Separator]            = ImVec4(0.42, 0.42, 0.42, 1.00)
        colors[clr.SeparatorHovered]     = ImVec4(0.57, 0.24, 0.73, 1.00)
        colors[clr.SeparatorActive]      = ImVec4(0.69, 0.69, 0.89, 1.00)
        colors[clr.ResizeGrip]           = ImVec4(1.00, 1.00, 1.00, 0.30)
        colors[clr.ResizeGripHovered]    = ImVec4(1.00, 1.00, 1.00, 0.60)
        colors[clr.ResizeGripActive]     = ImVec4(1.00, 1.00, 1.00, 0.89)
        colors[clr.CloseButton]          = ImVec4(0.33, 0.14, 0.46, 0.50)
        colors[clr.CloseButtonHovered]   = ImVec4(0.69, 0.69, 0.89, 0.60)
        colors[clr.CloseButtonActive]    = ImVec4(0.69, 0.69, 0.69, 1.00)
        colors[clr.PlotLines]            = ImVec4(1.00, 0.99, 0.99, 1.00)
        colors[clr.PlotLinesHovered]     = ImVec4(0.49, 0.00, 0.89, 1.00)
        colors[clr.PlotHistogram]        = ImVec4(9.99, 9.99, 9.90, 1.00)
        colors[clr.PlotHistogramHovered] = ImVec4(9.99, 9.99, 9.90, 1.00)
        colors[clr.TextSelectedBg]       = ImVec4(0.54, 0.00, 1.00, 0.34)
        colors[clr.ModalWindowDarkening] = ImVec4(0.20, 0.20, 0.20, 0.34)
    elseif theme == 7 then
        colors[clr.Text]                   = ImVec4(0.80, 0.80, 0.83, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(0.07, 0.07, 0.09, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.07, 0.07, 0.09, 1.00)
        colors[clr.Border]                 = ImVec4(0.80, 0.80, 0.83, 0.88)
        colors[clr.BorderShadow]           = ImVec4(0.92, 0.91, 0.88, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.FrameBgHovered]         = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.76, 0.31, 0.00, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(1.00, 0.98, 0.95, 0.75)
        colors[clr.TitleBgActive]          = ImVec4(0.80, 0.33, 0.00, 1.00)
        colors[clr.MenuBarBg]              = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarGrab]          = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ComboBg]                = ImVec4(0.19, 0.18, 0.21, 1.00)
        colors[clr.CheckMark]              = ImVec4(1.00, 0.42, 0.00, 0.53)
        colors[clr.SliderGrab]             = ImVec4(1.00, 0.42, 0.00, 0.53)
        colors[clr.SliderGrabActive]       = ImVec4(1.00, 0.42, 0.00, 1.00)
        colors[clr.Button]                 = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.Header]                 = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.HeaderActive]           = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.ResizeGripHovered]      = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ResizeGripActive]       = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16)
        colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39)
        colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotLinesHovered]       = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotHistogramHovered]   = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.25, 1.00, 0.00, 0.43)
        colors[clr.ModalWindowDarkening]   = ImVec4(1.00, 0.98, 0.95, 0.73)
    elseif theme == 8 then
        colors[clr.Text]                   = ImVec4(0.95, 0.96, 0.98, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.36, 0.42, 0.47, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.11, 0.15, 0.17, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(0.15, 0.18, 0.22, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.FrameBgHovered]         = ImVec4(0.12, 0.20, 0.28, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.09, 0.12, 0.14, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.09, 0.12, 0.14, 0.65)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.TitleBgActive]          = ImVec4(0.08, 0.10, 0.12, 1.00)
        colors[clr.MenuBarBg]              = ImVec4(0.15, 0.18, 0.22, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.39)
        colors[clr.ScrollbarGrab]          = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.09, 0.21, 0.31, 1.00)
        colors[clr.ComboBg]                = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.28, 0.56, 1.00, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.28, 0.56, 1.00, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.37, 0.61, 1.00, 1.00)
        colors[clr.Button]                 = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.28, 0.56, 1.00, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
        colors[clr.Header]                 = ImVec4(0.20, 0.25, 0.29, 0.55)
        colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
        colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
        colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16)
        colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39)
        colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.25, 1.00, 0.00, 0.43)
        colors[clr.ModalWindowDarkening]   = ImVec4(1.00, 0.98, 0.95, 0.73)
    elseif theme == 9 then
        colors[clr.Text]                   = ImVec4(0.860, 0.930, 0.890, 0.78)
        colors[clr.TextDisabled]           = ImVec4(0.860, 0.930, 0.890, 0.28)
        colors[clr.WindowBg]               = ImVec4(0.13, 0.14, 0.17, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(0.200, 0.220, 0.270, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.200, 0.220, 0.270, 0.9)
        colors[clr.Border]                 = ImVec4(0.200, 0.220, 0.270, 0.88)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.200, 0.220, 0.270, 1.00)
        colors[clr.FrameBgHovered]         = ImVec4(0.455, 0.198, 0.301, 0.78)
        colors[clr.FrameBgActive]          = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.232, 0.201, 0.271, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.502, 0.075, 0.256, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.200, 0.220, 0.270, 0.75)
        colors[clr.MenuBarBg]              = ImVec4(0.200, 0.220, 0.270, 0.47)
        colors[clr.ScrollbarBg]            = ImVec4(0.200, 0.220, 0.270, 1.00)
        colors[clr.ScrollbarGrab]          = ImVec4(0.09, 0.15, 0.1, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.455, 0.198, 0.301, 0.78)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.71, 0.22, 0.27, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.47, 0.77, 0.83, 0.14)
        colors[clr.SliderGrabActive]       = ImVec4(0.71, 0.22, 0.27, 1.00)
        colors[clr.Button]                 = ImVec4(0.47, 0.77, 0.83, 0.14)
        colors[clr.ButtonHovered]          = ImVec4(0.455, 0.198, 0.301, 0.86)
        colors[clr.ButtonActive]           = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.Header]                 = ImVec4(0.455, 0.198, 0.301, 0.76)
        colors[clr.HeaderHovered]          = ImVec4(0.455, 0.198, 0.301, 0.86)
        colors[clr.HeaderActive]           = ImVec4(0.502, 0.075, 0.256, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.47, 0.77, 0.83, 0.04)
        colors[clr.ResizeGripHovered]      = ImVec4(0.455, 0.198, 0.301, 0.78)
        colors[clr.ResizeGripActive]       = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.860, 0.930, 0.890, 0.63)
        colors[clr.PlotLinesHovered]       = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.860, 0.930, 0.890, 0.63)
        colors[clr.PlotHistogramHovered]   = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.455, 0.198, 0.301, 0.43)
        colors[clr.ModalWindowDarkening]   = ImVec4(0.200, 0.220, 0.270, 0.73)
    elseif theme == 10 then
        colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(0.10, 0.10, 0.10, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 1.00)
        colors[clr.Border]                 = ImVec4(0.70, 0.70, 0.70, 0.40)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.15, 0.15, 0.15, 1.00)
        colors[clr.FrameBgHovered]         = ImVec4(0.19, 0.19, 0.19, 0.71)
        colors[clr.FrameBgActive]          = ImVec4(0.34, 0.34, 0.34, 0.79)
        colors[clr.TitleBg]                = ImVec4(0.00, 0.69, 0.33, 0.80)
        colors[clr.TitleBgActive]          = ImVec4(0.00, 0.74, 0.36, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.69, 0.33, 0.50)
        colors[clr.MenuBarBg]              = ImVec4(0.00, 0.80, 0.38, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.16, 0.16, 0.16, 1.00)
        colors[clr.ScrollbarGrab]          = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.00, 1.00, 0.48, 1.00)
        colors[clr.ComboBg]                = ImVec4(0.20, 0.20, 0.20, 0.99)
        colors[clr.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.77, 0.37, 1.00)
        colors[clr.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00)
        colors[clr.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57)
        colors[clr.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89)
        colors[clr.Separator]              = ImVec4(1.00, 1.00, 1.00, 0.40)
        colors[clr.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
        colors[clr.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 0.80)
        colors[clr.ResizeGrip]             = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.ResizeGripHovered]      = ImVec4(0.00, 0.76, 0.37, 1.00)
        colors[clr.ResizeGripActive]       = ImVec4(0.00, 0.86, 0.41, 1.00)
        colors[clr.CloseButton]            = ImVec4(0.00, 0.82, 0.39, 1.00)
        colors[clr.CloseButtonHovered]     = ImVec4(0.00, 0.88, 0.42, 1.00)
        colors[clr.CloseButtonActive]      = ImVec4(0.00, 1.00, 0.48, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(0.00, 0.74, 0.36, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.00, 0.69, 0.33, 0.72)
        colors[clr.ModalWindowDarkening]   = ImVec4(0.17, 0.17, 0.17, 0.48)
    elseif theme == 11 then
        colors[clr.FrameBg]                = ImVec4(0.46, 0.11, 0.29, 1.00)
        colors[clr.FrameBgHovered]         = ImVec4(0.69, 0.16, 0.43, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.58, 0.10, 0.35, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.61, 0.16, 0.39, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark]              = ImVec4(0.94, 0.30, 0.63, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.85, 0.11, 0.49, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.89, 0.24, 0.58, 1.00)
        colors[clr.Button]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.69, 0.17, 0.43, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.59, 0.10, 0.35, 1.00)
        colors[clr.Header]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.69, 0.16, 0.43, 1.00)
        colors[clr.HeaderActive]           = ImVec4(0.58, 0.10, 0.35, 1.00)
        colors[clr.Separator]              = ImVec4(0.69, 0.16, 0.43, 1.00)
        colors[clr.SeparatorHovered]       = ImVec4(0.58, 0.10, 0.35, 1.00)
        colors[clr.SeparatorActive]        = ImVec4(0.58, 0.10, 0.35, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.46, 0.11, 0.29, 0.70)
        colors[clr.ResizeGripHovered]      = ImVec4(0.69, 0.16, 0.43, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.70, 0.13, 0.42, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.78, 0.90, 0.35)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.60, 0.19, 0.40, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.ComboBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border]                 = ImVec4(0.49, 0.14, 0.31, 1.00)
        colors[clr.BorderShadow]           = ImVec4(0.49, 0.14, 0.31, 0.00)
        colors[clr.MenuBarBg]              = ImVec4(0.15, 0.15, 0.15, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
        colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
        colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
    elseif theme == 12 then
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
        colors[clr.ChildWindowBg]          = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.44, 0.44, 0.44, 0.60)
        colors[clr.FrameBgHovered]         = ImVec4(0.57, 0.57, 0.57, 0.70)
        colors[clr.FrameBgActive]          = ImVec4(0.76, 0.76, 0.76, 0.80)
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.16, 0.16, 0.16, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.60)
        colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.13, 0.75, 0.55, 0.80)
        colors[clr.SliderGrab]             = ImVec4(0.13, 0.75, 0.75, 0.80)
        colors[clr.SliderGrabActive]       = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.Button]                 = ImVec4(0.13, 0.75, 0.55, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.13, 0.75, 0.75, 0.60)
        colors[clr.ButtonActive]           = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.Header]                 = ImVec4(0.13, 0.75, 0.55, 0.40)
        colors[clr.HeaderHovered]          = ImVec4(0.13, 0.75, 0.75, 0.60)
        colors[clr.HeaderActive]           = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.Separator]              = ImVec4(0.13, 0.75, 0.55, 0.40)
        colors[clr.SeparatorHovered]       = ImVec4(0.13, 0.75, 0.75, 0.60)
        colors[clr.SeparatorActive]        = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.ResizeGrip]             = ImVec4(0.13, 0.75, 0.55, 0.40)
        colors[clr.ResizeGripHovered]      = ImVec4(0.13, 0.75, 0.75, 0.60)
        colors[clr.ResizeGripActive]       = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
        colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
    elseif theme == 13 then
        colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.96)
        colors[clr.Border]                 = ImVec4(0.73, 0.36, 0.00, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.49, 0.24, 0.00, 1.00)
        colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.FrameBgHovered]         = ImVec4(0.65, 0.32, 0.00, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.73, 0.36, 0.00, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.15, 0.11, 0.09, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.73, 0.36, 0.00, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.15, 0.11, 0.09, 0.51)
        colors[clr.MenuBarBg]              = ImVec4(0.62, 0.31, 0.00, 1.00)
        colors[clr.CheckMark]              = ImVec4(1.00, 0.49, 0.00, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.84, 0.41, 0.00, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.49, 0.00, 1.00)
        colors[clr.Button]                 = ImVec4(0.73, 0.36, 0.00, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.73, 0.36, 0.00, 1.00)
        colors[clr.ButtonActive]           = ImVec4(1.00, 0.50, 0.00, 1.00)
        colors[clr.Header]                 = ImVec4(0.49, 0.24, 0.00, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.70, 0.35, 0.01, 1.00)
        colors[clr.HeaderActive]           = ImVec4(1.00, 0.49, 0.00, 1.00)
        colors[clr.SeparatorHovered]       = ImVec4(0.49, 0.24, 0.00, 0.78)
        colors[clr.SeparatorActive]        = ImVec4(0.49, 0.24, 0.00, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.48, 0.23, 0.00, 1.00)
        colors[clr.ResizeGripHovered]      = ImVec4(0.78, 0.38, 0.00, 1.00)
        colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.49, 0.00, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.83, 0.41, 0.00, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.99, 0.00, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.93, 0.46, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.00, 0.00, 0.00, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.33, 0.33, 0.33, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.39, 0.39, 0.39, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.48, 0.48, 0.48, 1.00)
        colors[clr.CloseButton]            = colors[clr.FrameBg]
        colors[clr.CloseButtonHovered]     = colors[clr.FrameBgHovered]
        colors[clr.CloseButtonActive]      = colors[clr.FrameBgActive]
    end
end