script_name('Spotify')
script_author('Victor Strand')
script_version('3.0')

local imgui    = require('mimgui')
local fa       = require('fAwesome6_solid')
local ini      = require('inicfg')
local ffi      = require('ffi')
local requests = require('requests')
local encoding = require('encoding')
local lfs      = require('lfs')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local MDS = MONET_DPI_SCALE or 1
local sw, sh = getScreenResolution()
math.randomseed(os.time())

local folder       = getWorkingDirectory()..'/ST-Music'
local playlistsDir = folder..'/playlists'
local cacheDir     = folder..'/cache'
local localDir     = folder..'/local'
if not lfs.attributes(folder)       then lfs.mkdir(folder) end
if not lfs.attributes(playlistsDir) then lfs.mkdir(playlistsDir) end
if not lfs.attributes(cacheDir)     then lfs.mkdir(cacheDir) end
if not lfs.attributes(localDir)     then lfs.mkdir(localDir) end

local configPath  = folder..'/config.ini'
local likesPath   = folder..'/likes.ini'
local userPlPath  = folder..'/user_playlists.txt'
local logoPath    = folder..'/spotify_logo.png'
local discPath    = folder..'/disc.png'

local LOGO_URL    = 'https://raw.githubusercontent.com/victorstrand250-cpu/Logo-1/refs/heads/main/png-transparent-spotify-streaming-media-podcast-music-playlist-spotify-logo-logo-musician-music-download.png'
local DISC_URL    = 'https://raw.githubusercontent.com/victorstrand250-cpu/Logo-1/refs/heads/main/file_0000000054307243b612f8bd2ce41f46.png'
local TG_URL      = 'https://t.me/strand_scripts'
local TG_URL2     = 'https://t.me/victor_st0'
local TG_LABEL    = fa and (fa['PAPER_PLANE']..' @strand_scripts') or '@strand_scripts'
local TG_LABEL2   = fa and (fa['USER']..' @victor_st0') or '@victor_st0'

local config = ini.load({
    settings={volume=0.8,theme=1,shuffle=false,repeat_mode=0,cur_playlist='default',cur_track=1,
              mini_x=tostring(math.floor(sw/2-175)),mini_y='14'}
}, configPath)
ini.save(config, configPath)
local function saveConfig() ini.save(config, configPath) end

local THEMES = {
    { name='Dark',
      winBg={0.07,0.07,0.07,0.77}, topBg={0.04,0.04,0.04,0.82},
      frameBg={0.22,0.22,0.22,0.85}, accent={0.11,0.73,0.33,1.0},
      accentH={0.14,0.88,0.40,1.0}, text={1,1,1,1}, textDim={0.48,0.48,0.48,1},
      rowHov={0.18,0.18,0.18,0.85}, sep={0.15,0.15,0.15,1},
      pb={0.28,0.28,0.28,1}, tabAct={0.11,0.11,0.11,0.85}, liked={0.90,0.20,0.35,1} },
    { name='Green',
      winBg={0.06,0.28,0.14,0.67}, topBg={0.06,0.28,0.14,0.67},
      frameBg={0.10,0.38,0.20,0.70}, accent={0.05,0.90,0.38,1.0},
      accentH={0.10,1.00,0.45,1.0}, text={1,1,1,1}, textDim={0.75,0.95,0.80,1},
      rowHov={0.10,0.42,0.22,0.65}, sep={0.08,0.40,0.20,0.50},
      pb={0.08,0.40,0.18,0.70}, tabAct={0.08,0.36,0.18,0.80}, liked={0.90,0.20,0.35,1} },
    { name='Sunset',
      winBg={0.38,0.14,0.04,0.70}, topBg={0.44,0.16,0.04,0.75},
      frameBg={0.50,0.20,0.06,0.72}, accent={1.00,0.48,0.10,1.0},
      accentH={1.00,0.62,0.20,1.0}, text={1,1,1,1}, textDim={0.95,0.75,0.55,1},
      rowHov={0.55,0.22,0.06,0.65}, sep={0.60,0.25,0.08,0.55},
      pb={0.48,0.18,0.05,0.78}, tabAct={0.44,0.16,0.05,0.85}, liked={1.00,0.28,0.28,1} },
}
local curTheme = math.max(1,math.min(3, tonumber(config.settings.theme) or 1))
local function T() return THEMES[curTheme] end

local function rgba(r,g,b,a)
    a=a or 1.0
    return math.floor(r*255)+math.floor(g*255)*256
          +math.floor(b*255)*65536+math.floor(a*255)*16777216
end
local function rgbaT(c) return rgba(c[1],c[2],c[3],c[4] or 1.0) end
local function fmt(sec)
    sec=math.max(0,math.floor(sec))
    return string.format('%d:%02d',math.floor(sec/60),sec%60)
end
local function rotPt(px,py,cx,cy,a)
    local s,c=math.sin(a),math.cos(a)
    return cx+(px-cx)*c-(py-cy)*s, cy+(px-cx)*s+(py-cy)*c
end

local PLAYLISTS   = {}
local curPlaylist = config.settings.cur_playlist or 'default'
local PLAYLIST    = {}
local ALL_TRACKS  = {}
local USER_TRACKS = {}          -- user-created playlists (persisted): name -> {{title,url}}
local LOCAL_TRACKS= {}          -- mp3 files dropped into ST-Music/local
local LOCAL_NAME  = 'Local Files'
local curTrack    = 1           -- forward declaration (real init below)
local sheetsLoaded  = false
local sheetsLoading = false

local SHEETS_ID  = '1PGafi8_7IrvpmTSvJAVSPlzZZKSRkGJkF5_EStFoNR8'
local SHEETS_URL = 'https://docs.google.com/spreadsheets/d/'..SHEETS_ID..'/gviz/tq?tqx=out:json'
local cacheFile  = folder..'/sheets_cache.json'

-- ===== User playlists (your own music) ==========================
-- Stored as plain text:  [Playlist name]\n  title ||| url\n ...
local function isUserPlaylist(name) return USER_TRACKS[name]~=nil end

local function saveUserPlaylists()
    local f=io.open(userPlPath,'w'); if not f then return end
    f:write('; ST Music user playlists\n')
    for name,tracks in pairs(USER_TRACKS) do
        f:write('['..name..']\n')
        for _,t in ipairs(tracks) do
            f:write((t.title or 'Unknown')..' ||| '..(t.url or '')..'\n')
        end
    end
    f:close()
end

local function loadUserPlaylists()
    USER_TRACKS={}
    if not doesFileExist(userPlPath) then return end
    local f=io.open(userPlPath,'r'); if not f then return end
    local cur=nil
    for line in f:lines() do
        line=line:gsub('\r','')
        if line:sub(1,1)==';' then
            -- comment, skip
        else
            local name=line:match('^%[(.+)%]%s*$')
            if name then
                cur=name; USER_TRACKS[cur]=USER_TRACKS[cur] or {}
            elseif cur then
                local title,url=line:match('^(.-)%s*|||%s*(.+)$')
                if url and url~='' then
                    table.insert(USER_TRACKS[cur],{title=(title~='' and title or 'Unknown'),url=url})
                end
            end
        end
    end
    f:close()
end

-- ===== Local mp3 files ==========================================
local function scanLocalFiles()
    LOCAL_TRACKS={}
    local ok=pcall(function()
        for file in lfs.dir(localDir) do
            if file:lower():match('%.mp3$') or file:lower():match('%.ogg$')
               or file:lower():match('%.wav$') or file:lower():match('%.flac$') then
                local title=file:gsub('%.%w+$','')
                table.insert(LOCAL_TRACKS,{title=title,url='file://'..localDir..'/'..file})
            end
        end
    end)
    if not ok then LOCAL_TRACKS={} end
end

local function unescapeUnicode(s)
    return (s:gsub('\\u(%x%x%x%x)', function(h)
        local cp = tonumber(h, 16)
        if cp < 0x80 then
            return string.char(cp)
        elseif cp < 0x800 then
            return string.char(0xC0+math.floor(cp/64), 0x80+(cp%64))
        else
            return string.char(0xE0+math.floor(cp/4096), 0x80+math.floor((cp%4096)/64), 0x80+(cp%64))
        end
    end))
end

local function parseSheets(body)
    ALL_TRACKS={}
    ALL_TRACKS['default']={}
    for row in body:gmatch('"c":%[(.-)%]') do
        local cols={}
        for cell in row:gmatch('{[^}]*}') do
            local val=cell:match('"v":"([^"]*)"') or cell:match('"f":"([^"]*)"')
            cols[#cols+1]=val or ''
        end
        local title=unescapeUnicode((cols[1] or ''):match('^%s*(.-)%s*$'))
        local url  =(cols[2] or ''):match('^%s*(.-)%s*$')
        if url~='' then
            ALL_TRACKS['default'][#ALL_TRACKS['default']+1]={
                title=title~='' and title or 'Unknown', url=url}
        end
    end
end

local function rebuildPlaylists()
    -- merge the Google-Sheets playlist(s) with user playlists and local files
    for name,tracks in pairs(USER_TRACKS) do ALL_TRACKS[name]=tracks end
    if #LOCAL_TRACKS>0 then ALL_TRACKS[LOCAL_NAME]=LOCAL_TRACKS else ALL_TRACKS[LOCAL_NAME]=nil end
    PLAYLISTS={}
    for name in pairs(ALL_TRACKS) do PLAYLISTS[#PLAYLISTS+1]=name end
    table.sort(PLAYLISTS)
    if #PLAYLISTS==0 then PLAYLISTS[1]='default'; ALL_TRACKS['default']={{title='No tracks',url=''}} end
    -- keep the current playlist selected if it still exists (fixes reset-to-default bug)
    if not ALL_TRACKS[curPlaylist] then curPlaylist='default' end
end

local function scanPlaylists() rebuildPlaylists() end

local function loadPlaylist(name)
    PLAYLIST={}
    local tracks=ALL_TRACKS[name]
    if tracks and #tracks>0 then
        for _,t in ipairs(tracks) do PLAYLIST[#PLAYLIST+1]={title=t.title,url=t.url} end
    else
        PLAYLIST[1]={title='No tracks here yet',url=''}
    end
end

local function createPlaylist(name)
    name=(name or ''):gsub('^%s*(.-)%s*$','%1')
    if name=='' then return false end
    if name=='default' or name==LOCAL_NAME or ALL_TRACKS[name] or USER_TRACKS[name] then
        return false
    end
    USER_TRACKS[name]={}
    saveUserPlaylists()
    rebuildPlaylists()
    return true, name
end

local function fetchSheetsAsync()
    if sheetsLoading then return end
    sheetsLoading=true
    lua_thread.create(function()
        local ok,resp=pcall(requests.get,SHEETS_URL)
        if ok and resp and resp.status_code==200 and resp.text and #resp.text>10 then
            local body=resp.text
            local f=io.open(cacheFile,'wb'); if f then f:write(body); f:close() end
            parseSheets(body); rebuildPlaylists(); loadPlaylist(curPlaylist)
            if #PLAYLIST>0 then curTrack=math.max(1,math.min(#PLAYLIST,tonumber(curTrack) or 1)) end
            sheetsLoaded=true
            sampAddChatMessage('[Spotify] \xcf\xeb\xe5\xe9\xeb\xe8\xf1\xf2 \xee\xe1\xed\xee\xe2\xeb\xb8\xed',0x1DB954)
        else
            sampAddChatMessage('[Spotify] \xce\xf8\xe8\xe1\xea\xe0 \xe7\xe0\xe3\xf0\xf3\xe7\xea\xe8',0xFF4444)
        end
        sheetsLoading=false
    end)
end

loadUserPlaylists()
scanLocalFiles()
if doesFileExist(cacheFile) then
    local f=io.open(cacheFile,'r')
    if f then local body=f:read('*all'); f:close()
        if body and #body>10 then parseSheets(body); rebuildPlaylists(); sheetsLoaded=true end
    end
end
if not sheetsLoaded then
    ALL_TRACKS={default={{title='Loading from Google Sheets...',url=''}}}
    rebuildPlaylists()
end
loadPlaylist(curPlaylist)

local likes={}
local function loadLikes()
    likes={}
    if not doesFileExist(likesPath) then return end
    local f=io.open(likesPath,'r'); if not f then return end
    for line in f:lines() do
        line=line:match('^%s*(.-)%s*$') or ''
        if line~='' and line:sub(1,1)~=';' then likes[line]=true end
    end
    f:close()
end
local function saveLikes()
    local f=io.open(likesPath,'w'); if not f then return end
    f:write('; ST Music Likes\n')
    for url in pairs(likes) do f:write(url..'\n') end
    f:close()
end
local function toggleLike(url) if likes[url] then likes[url]=nil else likes[url]=true end; saveLikes() end
local function isLiked(url) return likes[url]==true end
loadLikes()

local bass=nil; local stream=0
pcall(function()
    bass=ffi.load('libbass.so')
    ffi.cdef[[
        int           BASS_Init(int device, unsigned long freq, unsigned long flags, void* win, void* clsid);
        unsigned long BASS_StreamCreateURL(const char* url, unsigned long offset, unsigned long flags, void* proc, void* user);
        unsigned long BASS_StreamCreateFile(int mem, const char* file, unsigned long long offset, unsigned long long length, unsigned long flags);
        int           BASS_ChannelPlay(unsigned long handle, int restart);
        int           BASS_ChannelPause(unsigned long handle);
        int           BASS_ChannelStop(unsigned long handle);
        int           BASS_ChannelSetAttribute(unsigned long handle, unsigned long attrib, float value);
        double        BASS_ChannelBytes2Seconds(unsigned long handle, unsigned long long pos);
        unsigned long BASS_ChannelGetPosition(unsigned long handle, unsigned long mode);
        unsigned long BASS_ChannelGetLength(unsigned long handle, unsigned long mode);
        unsigned long BASS_ChannelSeconds2Bytes(unsigned long handle, double seconds);
        int           BASS_ChannelSetPosition(unsigned long handle, unsigned long long pos, unsigned long mode);
        int           BASS_StreamFree(unsigned long handle);
        unsigned long BASS_ErrorGetCode();
        unsigned long BASS_ChannelIsActive(unsigned long handle);
        unsigned long BASS_ChannelGetData(unsigned long handle, void* buffer, unsigned long length);
    ]]
    bass.BASS_Init(-1,44100,0,nil,nil)
end)

local dlStatus  = {}
local dlQueue   = {}
local dlActive  = 0
local DL_MAX    = 2

local function urlToFilename(url)
    local name = url:match('([^/]+)$') or 'track'
    name = name:gsub('[?&=:%+%%]','_')
    if not name:match('%.mp3$') then name = name..'.mp3' end
    return name
end
local function cachePathFor(url)
    return cacheDir..'/'..urlToFilename(url)
end
local function isLocalUrl(url) return type(url)=='string' and url:sub(1,7)=='file://' end
local function localPath(url) return url:sub(8) end
local function isCached(url)
    if isLocalUrl(url) then return doesFileExist(localPath(url)) end
    local p = cachePathFor(url)
    local sz = doesFileExist(p) and (lfs.attributes(p,'size') or 0) or 0
    return sz > 4096
end

local function downloadTrack(url, onDone)
    if dlStatus[url] == 'downloading' then return end
    if isCached(url) then
        dlStatus[url] = 100
        if onDone then onDone(true) end
        return
    end
    dlStatus[url] = 0
    dlActive = dlActive + 1
    lua_thread.create(function()
        local path = cachePathFor(url)
        local ok, resp = pcall(requests.get, url, {timeout=60})
        if ok and resp and resp.status_code == 200 and resp.text and #resp.text > 4096 then
            local total = #resp.text
            local f = io.open(path, 'wb')
            if f then
                local chunkSize = 65536
                local written = 0
                local i = 1
                while i <= total do
                    local chunk = resp.text:sub(i, i + chunkSize - 1)
                    f:write(chunk)
                    written = written + #chunk
                    dlStatus[url] = math.floor(written / total * 100)
                    i = i + chunkSize
                    wait(0)
                end
                f:close()
                local sz = lfs.attributes(path, 'size') or 0
                if sz > 4096 then
                    dlStatus[url] = 100
                    if onDone then onDone(true) end
                else
                    os.remove(path)
                    dlStatus[url] = 'error'
                    if onDone then onDone(false) end
                end
            else
                dlStatus[url] = 'error'
                if onDone then onDone(false) end
            end
        else
            dlStatus[url] = 'error'
            if onDone then onDone(false) end
        end
        dlActive = dlActive - 1
        if dlActive < 0 then dlActive = 0 end
    end)
end

local showMenu     = imgui.new.bool(false)
local showMenuPrev = false
local isPlaying    = false
curTrack           = math.max(1,math.min(#PLAYLIST, tonumber(config.settings.cur_track) or 1))
local volume       = tonumber(config.settings.volume) or 0.8
local page         = 1

local ctxMenu = {
    open   = false,
    trackIdx = 0,
    x      = 0,
    y      = 0,
}
local volSlider    = imgui.new.float(volume)
local pbDragging   = false
local pbDragFrac   = 0.0
local listScroll   = 0.0
local likedScroll  = 0.0
local plScroll     = 0.0
local discAngle    = 0.0
local DISC_SPEED   = 0.008

-- add-your-own-track form
local addTitleBuf  = imgui.new.char[96](0)
local addUrlBuf    = imgui.new.char[256](0)
local showAddForm  = false
local hasHint      = (imgui.InputTextWithHint~=nil)
local function inputHint(id,hint,buf,sz)
    if hasHint then return imgui.InputTextWithHint(id,hint,buf,sz)
    else return imgui.InputText(id,buf,sz) end
end
local ICO_PLUS = fa.PLUS or fa.CIRCLE_PLUS or '+'
local ICO_X    = fa.XMARK or fa.CIRCLE_XMARK or 'x'
local ICO_MOON = fa.MOON or fa.CLOCK or ''
local ICO_INFO = fa.CIRCLE_INFO or fa.INFO or 'i'

-- audio spectrum visualizer (BASS FFT)
local VIZ_BARS     = 28
local vizSmooth    = {}
for i=1,VIZ_BARS do vizSmooth[i]=0 end
local fftBuf       = ffi.new('float[256]')

-- sleep timer (auto-pause) in minutes; 0 = off
local sleepMinutes = 0
local sleepDeadline= 0

local logoTex=nil; local discTex=nil
local texNeed={logo=false,disc=false}

local shuffleOn    = (config.settings.shuffle=='true' or config.settings.shuffle==true)
local shuffleQueue = {}
local shufflePos   = 0
local repeatMode   = tonumber(config.settings.repeat_mode) or 0

local searchBuf    = imgui.new.char[128](0)
local searchStr    = ''
local newPlBuf     = imgui.new.char[64](0)
local showNewPlForm= false

local showMini     = false
local miniAlpha    = 0.0
local miniScale    = 0.0
local miniPosX     = tonumber(config.settings.mini_x) or math.floor(sw/2 - 175*MDS)
local miniPosY     = tonumber(config.settings.mini_y) or math.floor(14*MDS)
local miniDragMode = false

local gta=nil
pcall(function()
    gta=ffi.load('GTASA')
    ffi.cdef[[ void _Z12AND_OpenLinkPKc(const char* link); ]]
end)
local function openLink(url) if gta then pcall(gta._Z12AND_OpenLinkPKc,url) end end

local function getRealDur()
    if not bass or stream==0 then return 0 end
    local dur=0
    pcall(function()
        local len=bass.BASS_ChannelGetLength(stream,0)
        local s=tonumber(bass.BASS_ChannelBytes2Seconds(stream,len))
        if s and s>0 then dur=s end
    end)
    return dur
end
local function getElapsed()
    if not bass or stream==0 then return 0 end
    local pos=0
    pcall(function()
        local bp=bass.BASS_ChannelGetPosition(stream,0)
        local s=tonumber(bass.BASS_ChannelBytes2Seconds(stream,bp))
        if s and s>=0 then pos=s end
    end)
    return pos
end
local function bassSetVol()
    if bass and stream~=0 then pcall(bass.BASS_ChannelSetAttribute,stream,2,volume) end
end

local function buildShuffleQueue(si)
    shuffleQueue={}
    for i=1,#PLAYLIST do shuffleQueue[i]=i end
    for i=#shuffleQueue,2,-1 do
        local j=math.random(i)
        shuffleQueue[i],shuffleQueue[j]=shuffleQueue[j],shuffleQueue[i]
    end
    for i=1,#shuffleQueue do
        if shuffleQueue[i]==si then shuffleQueue[1],shuffleQueue[i]=shuffleQueue[i],shuffleQueue[1]; break end
    end
    shufflePos=1
end
local function shuffleNext()
    if shufflePos<#shuffleQueue then shufflePos=shufflePos+1
    else buildShuffleQueue(1); shufflePos=1 end
    return shuffleQueue[shufflePos]
end
local function shufflePrev()
    if shufflePos>1 then shufflePos=shufflePos-1 end
    return shuffleQueue[shufflePos]
end

local function stopStream()
    if bass and stream~=0 then
        pcall(bass.BASS_ChannelStop,stream); pcall(bass.BASS_StreamFree,stream); stream=0
    end
    isPlaying=false
end
local function playTrack(idx)
    if idx<1 then idx=#PLAYLIST end; if idx>#PLAYLIST then idx=1 end
    curTrack=idx
    if not bass then return end
    local t=PLAYLIST[idx]
    if not t or t.url=='' then
        sampAddChatMessage('[Spotify] No URL '..idx, 0xFF4444); return
    end
    config.settings.cur_track=idx; saveConfig()
    local url=t.url
    local localFile = isLocalUrl(url)
    local cached = isCached(url)
    local filePath = localFile and localPath(url) or cachePathFor(url)
    isPlaying=false
    lua_thread.create(function()
        pcall(function()
            if stream~=0 then
                bass.BASS_ChannelStop(stream)
                bass.BASS_StreamFree(stream)
                stream=0
            end
            local s
            if localFile or cached then
                s = bass.BASS_StreamCreateFile(0, filePath, 0, 0, 0)
            else
                s = bass.BASS_StreamCreateURL(url, 0, 0x100, nil, nil)
            end
            if s~=0 then
                stream=s; bassSetVol(); bass.BASS_ChannelPlay(stream,1); isPlaying=true
            else
                sampAddChatMessage('[Spotify] BASS err='..tostring(tonumber(bass.BASS_ErrorGetCode())), 0xFF4444)
            end
        end)
    end)
end
local function pauseTrack()
    if not isPlaying or not bass or stream==0 then return end
    pcall(bass.BASS_ChannelPause,stream); isPlaying=false
end
local function resumeTrack()
    if isPlaying or not bass or stream==0 then return end
    pcall(bass.BASS_ChannelPlay,stream,0); isPlaying=true
end
local function seekTo(frac)
    if not bass or stream==0 then return end
    local dur=getRealDur(); if dur<=0 then return end
    pcall(function()
        local bp=bass.BASS_ChannelSeconds2Bytes(stream,math.max(0,math.min(1,frac))*dur)
        bass.BASS_ChannelSetPosition(stream,bp,0)
    end)
end
local function nextTrack()
    if repeatMode==1 then playTrack(curTrack); return end
    if shuffleOn then playTrack(shuffleNext()) else playTrack(curTrack%#PLAYLIST+1) end
end
local function prevTrack()
    if getElapsed()>3 then playTrack(curTrack); return end
    if shuffleOn then playTrack(shufflePrev())
    else local i=curTrack-1; if i<1 then i=#PLAYLIST end; playTrack(i) end
end
local function switchPlaylist(name)
    stopStream(); curPlaylist=name; loadPlaylist(name)
    curTrack=1; listScroll=0
    config.settings.cur_playlist=name; config.settings.cur_track=1; saveConfig()
    sampAddChatMessage('[Spotify] \xcf\xeb\xe5\xe9\xeb\xe8\xf1\xf2: '..name, 0x1DB954)
    if name=='default' then fetchSheetsAsync() end
end

local function deleteTrack(idx)
    if curPlaylist==LOCAL_NAME then
        sampAddChatMessage('[Spotify] Delete the file from ST-Music/local folder', 0xFFAA00); return
    end
    if not isUserPlaylist(curPlaylist) then
        sampAddChatMessage('[Spotify] Read-only: remove it in your Google Sheets', 0xFFAA00); return
    end
    local tracks=USER_TRACKS[curPlaylist]
    if tracks and tracks[idx] then
        table.remove(tracks, idx)
        saveUserPlaylists()
        loadPlaylist(curPlaylist)
        if curTrack>#PLAYLIST then curTrack=math.max(1,#PLAYLIST) end
        sampAddChatMessage('[Spotify] Track removed', 0x1DB954)
    end
end
local function addTrackToPlaylist(targetName, title, url)
    if not isUserPlaylist(targetName) then
        sampAddChatMessage('[Spotify] Pick one of YOUR playlists (Lists tab -> New)', 0xFFAA00); return
    end
    if not url or url=='' then return end
    table.insert(USER_TRACKS[targetName], {title=(title~='' and title~=nil and title or 'Unknown'), url=url})
    saveUserPlaylists()
    if curPlaylist==targetName then loadPlaylist(targetName) end
    sampAddChatMessage('[Spotify] Added to '..targetName, 0x1DB954)
end
-- add a brand new track (title+url) to the active user playlist
local function addCustomTrack(title, url)
    url=(url or ''):gsub('^%s*(.-)%s*$','%1')
    title=(title or ''):gsub('^%s*(.-)%s*$','%1')
    if url=='' then
        sampAddChatMessage('[Spotify] Paste a direct audio link (catbox/.mp3)', 0xFFAA00); return false
    end
    local target=curPlaylist
    if not isUserPlaylist(target) then
        -- auto-create a personal playlist so non-tech users always have a place
        if not USER_TRACKS['My Music'] then createPlaylist('My Music') end
        target='My Music'
        switchPlaylist(target)
    end
    addTrackToPlaylist(target, title, url)
    return true
end

local function applyStyle()
    local th=T(); local st=imgui.GetStyle()
    st.WindowRounding=18; st.ChildRounding=10; st.FrameRounding=8; st.GrabRounding=8
    st.WindowBorderSize=0; st.FrameBorderSize=0
    st.ItemSpacing=imgui.ImVec2(6*MDS,5*MDS); st.WindowPadding=imgui.ImVec2(0,0)
    st.FramePadding=imgui.ImVec2(6*MDS,4*MDS); st.GrabMinSize=10*MDS
    local C=st.Colors; local cl=imgui.Col; local V4=imgui.ImVec4
    C[cl.WindowBg]            =V4(th.winBg[1], th.winBg[2], th.winBg[3], th.winBg[4])
    C[cl.ChildBg]             =V4(0,0,0,0)
    C[cl.FrameBg]             =V4(th.frameBg[1],th.frameBg[2],th.frameBg[3],th.frameBg[4])
    C[cl.FrameBgHovered]      =V4(th.frameBg[1]+.06,th.frameBg[2]+.06,th.frameBg[3]+.06,1)
    C[cl.FrameBgActive]       =V4(th.frameBg[1]+.10,th.frameBg[2]+.10,th.frameBg[3]+.10,1)
    C[cl.SliderGrab]          =V4(th.accent[1],th.accent[2],th.accent[3],1)
    C[cl.SliderGrabActive]    =V4(th.accentH[1],th.accentH[2],th.accentH[3],1)
    C[cl.Text]                =V4(th.text[1],th.text[2],th.text[3],1)
    C[cl.TextDisabled]        =V4(th.textDim[1],th.textDim[2],th.textDim[3],1)
    C[cl.ScrollbarBg]         =V4(0,0,0,0)
    C[cl.ScrollbarGrab]       =V4(th.accent[1]*.6,th.accent[2]*.6,th.accent[3]*.6,1)
    C[cl.ScrollbarGrabHovered]=V4(th.accent[1]*.8,th.accent[2]*.8,th.accent[3]*.8,1)
    C[cl.ScrollbarGrabActive] =V4(th.accent[1],th.accent[2],th.accent[3],1)
    C[cl.Border]              =V4(0,0,0,0)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename=nil
    imgui.GetStyle():ScaleAllSizes(MDS)
    fa.Init(math.floor(16*MDS))
    applyStyle()
end)

local function downloadImage(url, path, key)
    local MAX_RETRIES = 3
    local MIN_SIZE    = 1024
    for attempt = 1, MAX_RETRIES do
        local ok, resp = pcall(requests.get, url, {timeout = 15})
        if ok and resp and resp.status_code == 200
                and resp.text and #resp.text >= MIN_SIZE then
            local f = io.open(path, 'wb')
            if f then
                f:write(resp.text); f:close()
                local written = lfs.attributes(path, 'size') or 0
                if written >= MIN_SIZE then
                    texNeed[key] = true
                    return true
                else
                    os.remove(path)
                end
            end
        end
        if attempt < MAX_RETRIES then wait(2000 * attempt) end
    end
    sampAddChatMessage('[Spotify] \xce\xf8\xe8\xe1\xea\xe0 \xe7\xe0\xe3\xf0\xf3\xe7\xea\xe8 \xf4\xee\xf2\xee: '..key, 0xFF4444)
    return false
end

lua_thread.create(function()
    while not isSampAvailable() do wait(1000) end
    wait(2000)
    local images = {
        {path=logoPath, url=LOGO_URL, key='logo'},
        {path=discPath,  url=DISC_URL,  key='disc'},
    }
    for _, d in ipairs(images) do
        local size = doesFileExist(d.path) and (lfs.attributes(d.path, 'size') or 0) or 0
        if size >= 1024 then
            texNeed[d.key] = true
        else
            if doesFileExist(d.path) then os.remove(d.path) end
            downloadImage(d.url, d.path, d.key)
        end
        wait(0)
    end
end)

local sbAnyDrag = false

-- Pull an FFT snapshot from the current stream and update the smoothed bars.
-- Returns the smoothed table (length VIZ_BARS) or nil when nothing is playing.
local function updateViz()
    if not bass or stream==0 or not isPlaying then
        for i=1,VIZ_BARS do vizSmooth[i]=vizSmooth[i]*0.80 end
        return vizSmooth
    end
    local ok=pcall(function()
        bass.BASS_ChannelGetData(stream, fftBuf, 0x80000001) -- BASS_DATA_FFT512 -> 256 bins
    end)
    if not ok then return vizSmooth end
    -- spread 256 bins (skip the very lowest DC bin) over VIZ_BARS, log-ish grouping
    local binStart=2
    for b=1,VIZ_BARS do
        local lo=binStart + math.floor((b-1)^1.65)
        local hi=binStart + math.floor(b^1.65)
        if hi<=lo then hi=lo+1 end
        if hi>255 then hi=255 end
        local sum=0; local n=0
        for k=lo,hi do sum=sum+(tonumber(fftBuf[k]) or 0); n=n+1 end
        local v=(n>0 and sum/n or 0)
        v=math.sqrt(v)*3.2
        if v>1 then v=1 end
        -- fast attack, slow release for a lively but smooth look
        if v>vizSmooth[b] then vizSmooth[b]=vizSmooth[b]+(v-vizSmooth[b])*0.6
        else vizSmooth[b]=vizSmooth[b]+(v-vizSmooth[b])*0.18 end
    end
    return vizSmooth
end

local function drawPlayer(cp,cdl,cw,cH,mp)
    local th=T()

    local artSz=math.min(cw-100*MDS, 130*MDS)
    local artX=cp.x+cw/2-artSz/2; local artY=cp.y+6*MDS
    local cx2=artX+artSz/2; local cy2=artY+artSz/2; local r2=artSz/2

    -- spectrum ring around the disc (interesting feature)
    local viz=updateViz()
    local ringR=r2+4*MDS
    local maxBar=22*MDS
    for b=1,VIZ_BARS do
        local ang=(b-1)/VIZ_BARS*math.pi*2 - math.pi/2 + discAngle*0.25
        local len=2*MDS + (viz[b] or 0)*maxBar
        local ca,sa=math.cos(ang),math.sin(ang)
        local x1=cx2+ca*ringR;        local y1=cy2+sa*ringR
        local x2=cx2+ca*(ringR+len);  local y2=cy2+sa*(ringR+len)
        local t=(viz[b] or 0)
        local cr=th.accent[1]+(th.accentH[1]-th.accent[1])*t
        local cg=th.accent[2]+(th.accentH[2]-th.accent[2])*t
        local cb=th.accent[3]+(th.accentH[3]-th.accent[3])*t
        cdl:AddLine(imgui.ImVec2(x1,y1),imgui.ImVec2(x2,y2),rgba(cr,cg,cb,0.45+0.55*t),2.4*MDS)
    end

    if discTex then
        local x1,y1=rotPt(cx2-r2,cy2-r2,cx2,cy2,discAngle)
        local x2,y2=rotPt(cx2+r2,cy2-r2,cx2,cy2,discAngle)
        local x3,y3=rotPt(cx2+r2,cy2+r2,cx2,cy2,discAngle)
        local x4,y4=rotPt(cx2-r2,cy2+r2,cx2,cy2,discAngle)
        cdl:AddImageQuad(discTex,
            imgui.ImVec2(x1,y1),imgui.ImVec2(x2,y2),
            imgui.ImVec2(x3,y3),imgui.ImVec2(x4,y4),
            imgui.ImVec2(0,0),imgui.ImVec2(1,0),imgui.ImVec2(1,1),imgui.ImVec2(0,1),
            rgba(1,1,1,1))
    else
        cdl:AddCircleFilled(imgui.ImVec2(cx2,cy2),r2,rgbaT(th.accent),32)
    end

    local track=PLAYLIST[curTrack]
    local liked=track and isLiked(track.url)
    local hrtAncX=artX+artSz+8*MDS+17*MDS
    local hrtAncY=artY+artSz/2
    local hrtScale=1.5
    local hrtIco=fa.HEART; local hrtIsz=imgui.CalcTextSize(hrtIco)
    local hrtDispW=hrtIsz.x*hrtScale; local hrtDispH=hrtIsz.y*hrtScale
    local hrtColV4=liked and imgui.ImVec4(th.liked[1],th.liked[2],th.liked[3],1)
                         or imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],0.6)
    local hrtColU=liked and rgba(th.liked[1],th.liked[2],th.liked[3],1)
                        or rgba(th.textDim[1],th.textDim[2],th.textDim[3],0.6)
    imgui.SetCursorScreenPos(imgui.ImVec2(hrtAncX-hrtDispW/2,hrtAncY-hrtDispH/2))
    imgui.PushStyleColor(imgui.Col.Text,hrtColV4)
    imgui.SetWindowFontScale(hrtScale)
    imgui.Text(hrtIco)
    imgui.SetWindowFontScale(1.0)
    imgui.PopStyleColor()
    
    local hrtBtnSz=36*MDS
    imgui.SetCursorScreenPos(imgui.ImVec2(hrtAncX-hrtBtnSz/2,hrtAncY-hrtBtnSz/2))
    if imgui.InvisibleButton('##like',imgui.ImVec2(hrtBtnSz,hrtBtnSz)) then
        if track then toggleLike(track.url) end
    end

    local pAddSz=28*MDS
    local pAddAncX = artX - 8*MDS - 17*MDS
    local pAddAncY = artY + artSz/2
    local pAddX = pAddAncX - pAddSz/2
    local pAddY = pAddAncY - pAddSz/2
    local hovPA = mp.x>=pAddX and mp.x<=pAddX+pAddSz and mp.y>=pAddY and mp.y<=pAddY+pAddSz
    cdl:AddRectFilled(imgui.ImVec2(pAddX,pAddY),imgui.ImVec2(pAddX+pAddSz,pAddY+pAddSz),
        hovPA and rgbaT(th.accentH) or rgba(.18,.18,.18,.9), 6*MDS)
    cdl:AddRect(imgui.ImVec2(pAddX,pAddY),imgui.ImVec2(pAddX+pAddSz,pAddY+pAddSz),rgbaT(th.accent),6*MDS,0,1.2)
    local pph=pAddSz*0.4
    cdl:AddLine(imgui.ImVec2(pAddX+pAddSz/2,pAddY+pAddSz/2-pph/2),imgui.ImVec2(pAddX+pAddSz/2,pAddY+pAddSz/2+pph/2),rgbaT(th.accent),2)
    cdl:AddLine(imgui.ImVec2(pAddX+pAddSz/2-pph/2,pAddY+pAddSz/2),imgui.ImVec2(pAddX+pAddSz/2+pph/2,pAddY+pAddSz/2),rgbaT(th.accent),2)
    imgui.SetCursorScreenPos(imgui.ImVec2(pAddX,pAddY))
    if imgui.InvisibleButton('##pladd',imgui.ImVec2(pAddSz,pAddSz)) then
        if track then
            ctxMenu.open=true; ctxMenu.trackIdx=curTrack
            ctxMenu.x=pAddX+pAddSz+6*MDS; ctxMenu.y=pAddY
            scanPlaylists()
        end
    end
    local infoY=artY+artSz+7*MDS
    local tit=track and track.title or '---'
    if imgui.CalcTextSize(tit).x>cw-24*MDS then tit=tit:sub(1,24)..'...' end
    local titsz=imgui.CalcTextSize(tit)
    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+cw/2-titsz.x/2,infoY))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
    imgui.Text(tit)
    imgui.PopStyleColor()

    local sub=curPlaylist..' · '..curTrack..'/'..#PLAYLIST
    local subsz=imgui.CalcTextSize(sub)
    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+cw/2-subsz.x/2,infoY+18*MDS))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
    imgui.Text(sub)
    imgui.PopStyleColor()

    local realDur=getRealDur()
    local pbY=infoY+36*MDS; local pbX=cp.x+14*MDS; local pbW=cw-28*MDS; local pbH=5*MDS
    local el=pbDragging and (pbDragFrac*(realDur>0 and realDur or 0)) or getElapsed()
    local frac=realDur>0 and math.max(0,math.min(1,el/realDur)) or 0
    cdl:AddRectFilled(imgui.ImVec2(pbX,pbY),imgui.ImVec2(pbX+pbW,pbY+pbH),rgbaT(th.pb),3*MDS)
    if frac>0.001 then
        cdl:AddRectFilled(imgui.ImVec2(pbX,pbY),imgui.ImVec2(pbX+pbW*frac,pbY+pbH),rgbaT(th.accent),3*MDS)
    end
    cdl:AddCircleFilled(imgui.ImVec2(pbX+pbW*frac,pbY+pbH/2),pbDragging and 9*MDS or 7*MDS,rgba(1,1,1,1))
    local pbTY=pbY-14*MDS; local pbTH=pbH+28*MDS
    local inPb=mp.x>=pbX and mp.x<=pbX+pbW and mp.y>=pbTY and mp.y<=pbTY+pbTH
    local mDn=imgui.IsMouseDown(0)
    if mDn and inPb and not pbDragging then pbDragging=true end
    if pbDragging then
        if mDn then pbDragFrac=math.max(0,math.min(1,(mp.x-pbX)/pbW))
        else seekTo(pbDragFrac); pbDragging=false end
    end
    imgui.SetCursorScreenPos(imgui.ImVec2(pbX,pbTY))
    imgui.InvisibleButton('##pb',imgui.ImVec2(pbW,pbTH))

    local tY2=pbY+pbH+5*MDS
    imgui.SetCursorScreenPos(imgui.ImVec2(pbX,tY2))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
    imgui.Text(fmt(el))
    imgui.PopStyleColor()
    local dstr=realDur>0 and fmt(realDur) or '--:--'
    local dsz=imgui.CalcTextSize(dstr)
    imgui.SetCursorScreenPos(imgui.ImVec2(pbX+pbW-dsz.x,tY2))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
    imgui.Text(dstr)
    imgui.PopStyleColor()

    local ctrlY=tY2+16*MDS
    local playR=24*MDS; local smR=17*MDS; local iconR=13*MDS
    local playX=cp.x+cw/2; local playY=ctrlY+playR

    local shX=cp.x+16*MDS+iconR; local shCol=shuffleOn and th.accent or th.textDim
    local hSh=(mp.x-shX)^2+(mp.y-playY)^2<(iconR+4*MDS)^2
    cdl:AddCircleFilled(imgui.ImVec2(shX,playY),iconR,hSh and rgba(.25,.25,.25,.8) or rgba(.14,.14,.14,.6))
    do
        local c=rgba(shCol[1],shCol[2],shCol[3],1)
        local shIco=fa['SHUFFLE']; local shIsz=imgui.CalcTextSize(shIco)
        cdl:AddText(imgui.ImVec2(shX-shIsz.x/2,playY-shIsz.y/2),c,shIco)
    end
    if shuffleOn then cdl:AddCircleFilled(imgui.ImVec2(shX,playY+iconR-3*MDS),2*MDS,rgbaT(th.accent)) end
    imgui.SetCursorScreenPos(imgui.ImVec2(shX-iconR,playY-iconR))
    if imgui.InvisibleButton('##shuf',imgui.ImVec2(iconR*2,iconR*2)) then
        shuffleOn=not shuffleOn
        if shuffleOn then buildShuffleQueue(curTrack) end
        config.settings.shuffle=shuffleOn; saveConfig()
    end

    local prevX=playX-68*MDS
    local hPr=(mp.x-prevX)^2+(mp.y-playY)^2<(smR+4*MDS)^2
    cdl:AddCircleFilled(imgui.ImVec2(prevX,playY),smR,hPr and rgba(.30,.30,.30,1) or rgba(.16,.16,.16,1))
    local prIco=fa['BACKWARD_STEP']; local prIsz=imgui.CalcTextSize(prIco)
    cdl:AddText(imgui.ImVec2(prevX-prIsz.x/2,playY-prIsz.y/2),rgba(1,1,1,1),prIco)
    imgui.SetCursorScreenPos(imgui.ImVec2(prevX-smR,playY-smR))
    if imgui.InvisibleButton('##prev',imgui.ImVec2(smR*2,smR*2)) then prevTrack() end

    local hPl=(mp.x-playX)^2+(mp.y-playY)^2<playR^2
    cdl:AddCircleFilled(imgui.ImVec2(playX,playY),playR,hPl and rgbaT(th.accentH) or rgbaT(th.accent))
    if isPlaying then
        local bw,bh=4*MDS,12*MDS
        cdl:AddRectFilled(imgui.ImVec2(playX-bw*1.5,playY-bh/2),imgui.ImVec2(playX-bw*.3,playY+bh/2),rgba(0,0,0,1))
        cdl:AddRectFilled(imgui.ImVec2(playX+bw*.3,playY-bh/2),imgui.ImVec2(playX+bw*1.5,playY+bh/2),rgba(0,0,0,1))
    else
        local ts=9*MDS
        cdl:AddTriangleFilled(imgui.ImVec2(playX-ts*.4,playY-ts),imgui.ImVec2(playX+ts*.9,playY),imgui.ImVec2(playX-ts*.4,playY+ts),rgba(0,0,0,1))
    end
    imgui.SetCursorScreenPos(imgui.ImVec2(playX-playR,playY-playR))
    if imgui.InvisibleButton('##play',imgui.ImVec2(playR*2,playR*2)) then
        if isPlaying then pauseTrack() else if stream~=0 then resumeTrack() else playTrack(curTrack) end end
    end

    local nextX=playX+68*MDS
    local hNx=(mp.x-nextX)^2+(mp.y-playY)^2<(smR+4*MDS)^2
    cdl:AddCircleFilled(imgui.ImVec2(nextX,playY),smR,hNx and rgba(.30,.30,.30,1) or rgba(.16,.16,.16,1))
    local nxIco2=fa['FORWARD_STEP']; local nxIsz2=imgui.CalcTextSize(nxIco2)
    cdl:AddText(imgui.ImVec2(nextX-nxIsz2.x/2,playY-nxIsz2.y/2),rgba(1,1,1,1),nxIco2)
    imgui.SetCursorScreenPos(imgui.ImVec2(nextX-smR,playY-smR))
    if imgui.InvisibleButton('##next',imgui.ImVec2(smR*2,smR*2)) then nextTrack() end

    local rpX=cp.x+cw-16*MDS-iconR
    local hRp=(mp.x-rpX)^2+(mp.y-playY)^2<(iconR+4*MDS)^2
    local rpCols={th.textDim,th.accent,th.accent}
    local rpCol=rpCols[repeatMode+1]
    cdl:AddCircleFilled(imgui.ImVec2(rpX,playY),iconR,hRp and rgba(.25,.25,.25,.8) or rgba(.14,.14,.14,.6))
    do
        local c=rgba(rpCol[1],rpCol[2],rpCol[3],1)
        local rpIco=fa['REPEAT']; local rpIsz=imgui.CalcTextSize(rpIco)
        cdl:AddText(imgui.ImVec2(rpX-rpIsz.x/2,playY-rpIsz.y/2),c,rpIco)
        if repeatMode==2 then
            local oneSz=imgui.CalcTextSize('1')
            imgui.SetCursorScreenPos(imgui.ImVec2(rpX-oneSz.x/2,playY-oneSz.y/2))
            imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(rpCol[1],rpCol[2],rpCol[3],1))
            imgui.Text('1'); imgui.PopStyleColor()
        end
    end
    if repeatMode>0 then cdl:AddCircleFilled(imgui.ImVec2(rpX,playY+iconR-3*MDS),2*MDS,rgbaT(th.accent)) end
    imgui.SetCursorScreenPos(imgui.ImVec2(rpX-iconR,playY-iconR))
    if imgui.InvisibleButton('##rep',imgui.ImVec2(iconR*2,iconR*2)) then
        repeatMode=(repeatMode+1)%3; config.settings.repeat_mode=repeatMode; saveConfig()
    end

    local volY=playY+playR+10*MDS
    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+14*MDS,volY+2*MDS))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
    imgui.Text(fa['VOLUME_LOW'])
    imgui.PopStyleColor()
    volSlider[0]=volume
    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+46*MDS,volY))
    imgui.SetNextItemWidth(cw-60*MDS)
    if imgui.SliderFloat('##vol',volSlider,0.0,1.0,'') then
        volume=volSlider[0]; bassSetVol()
        config.settings.volume=volume; saveConfig()
    end

    local bH=26*MDS; local bW=(cw-36*MDS)/2
    local bY=cp.y+cH-bH-6*MDS
    local lblH=imgui.CalcTextSize('X').y
    local tgY=bY-lblH-6*MDS

    local mnBH=28*MDS; local mnBW=cw-24*MDS
    local mnBX=cp.x+12*MDS; local mnBY=tgY-mnBH-8*MDS
    local hMn=mp.x>=mnBX and mp.x<=mnBX+mnBW and mp.y>=mnBY and mp.y<=mnBY+mnBH
    local mnBg = showMini and rgbaT(th.accent) or (hMn and rgba(.28,.28,.28,1) or rgba(.18,.18,.18,.85))
    cdl:AddRectFilled(imgui.ImVec2(mnBX,mnBY),imgui.ImVec2(mnBX+mnBW,mnBY+mnBH),mnBg,7*MDS)
    if not showMini then
        cdl:AddRect(imgui.ImVec2(mnBX,mnBY),imgui.ImVec2(mnBX+mnBW,mnBY+mnBH),rgbaT(th.accent),7*MDS,0,1.4)
    end
    local mnLbl = showMini
        and u8('\xc7\xe0\xea\xf0\xfb\xf2\xfc \xec\xe8\xed\xe8')
        or  u8('\xcc\xe8\xed\xe8-\xef\xeb\xe5\xe5\xf0')
    local mnSz=imgui.CalcTextSize(mnLbl)
    imgui.SetCursorScreenPos(imgui.ImVec2(mnBX+mnBW/2-mnSz.x/2, mnBY+mnBH/2-mnSz.y/2))
    imgui.PushStyleColor(imgui.Col.Text, showMini
        and imgui.ImVec4(0,0,0,1)
        or  imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1))
    imgui.Text(mnLbl); imgui.PopStyleColor()
    imgui.SetCursorScreenPos(imgui.ImVec2(mnBX,mnBY))
    if imgui.InvisibleButton('##mnpl',imgui.ImVec2(mnBW,mnBH)) then showMini=not showMini end

    local hdrS=u8('\xd1\xe2\xff\xe7\xfc \xf1 \xe0\xe2\xf2\xee\xf0\xee\xec')
    local hdrsz=imgui.CalcTextSize(hdrS)
    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+cw/2-hdrsz.x/2,tgY))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
    imgui.Text(hdrS)
    imgui.PopStyleColor()
    local b1X=cp.x+12*MDS; local b2X=b1X+bW+12*MDS
    local hv1=mp.x>=b1X and mp.x<=b1X+bW and mp.y>=bY and mp.y<=bY+bH
    cdl:AddRectFilled(imgui.ImVec2(b1X,bY),imgui.ImVec2(b1X+bW,bY+bH),hv1 and rgbaT(th.accentH) or rgbaT(th.accent),8*MDS)
    local l1sz=imgui.CalcTextSize(TG_LABEL)
    imgui.SetCursorScreenPos(imgui.ImVec2(b1X+bW/2-l1sz.x/2,bY+bH/2-l1sz.y/2))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(0,0,0,1))
    imgui.Text(TG_LABEL)
    imgui.PopStyleColor()
    imgui.SetCursorScreenPos(imgui.ImVec2(b1X,bY))
    if imgui.InvisibleButton('##tg1',imgui.ImVec2(bW,bH)) then openLink(TG_URL) end
    local hv2=mp.x>=b2X and mp.x<=b2X+bW and mp.y>=bY and mp.y<=bY+bH
    cdl:AddRectFilled(imgui.ImVec2(b2X,bY),imgui.ImVec2(b2X+bW,bY+bH),hv2 and rgba(.20,.20,.20,.95) or rgba(.15,.15,.15,.9),8*MDS)
    cdl:AddRect(imgui.ImVec2(b2X,bY),imgui.ImVec2(b2X+bW,bY+bH),rgbaT(th.accent),8*MDS,0,1.5)
    local l2sz=imgui.CalcTextSize(TG_LABEL2)
    imgui.SetCursorScreenPos(imgui.ImVec2(b2X+bW/2-l2sz.x/2,bY+bH/2-l2sz.y/2))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1))
    imgui.Text(TG_LABEL2)
    imgui.PopStyleColor()
    imgui.SetCursorScreenPos(imgui.ImVec2(b2X,bY))
    if imgui.InvisibleButton('##tg2',imgui.ImVec2(bW,bH)) then openLink(TG_URL2) end
end

local function drawPlaylistPage(cp,cdl,cw,cH,mp)
    local th=T(); local mp2=imgui.GetIO().MousePos
    local searchH=34*MDS
    local formH  = showAddForm and 96*MDS or 0
    local topH   = searchH + formH

    -- search bar (leaves room for the + button on the right)
    cdl:AddRectFilled(imgui.ImVec2(cp.x+10*MDS,cp.y+4*MDS),
        imgui.ImVec2(cp.x+cw-46*MDS,cp.y+4*MDS+searchH-4*MDS),rgba(.16,.16,.16,.9),8*MDS)
    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+14*MDS,cp.y+8*MDS))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
    imgui.Text(u8('\xcf\xee\xe8\xf1\xea:'))
    imgui.PopStyleColor()
    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+58*MDS,cp.y+6*MDS))
    imgui.SetNextItemWidth(cw-108*MDS)
    imgui.PushStyleColor(imgui.Col.FrameBg,imgui.ImVec4(0,0,0,0))
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
    if imgui.InputText('##search',searchBuf,128) then
        searchStr=ffi.string(searchBuf):lower()
    end
    imgui.PopStyleColor(2)

    -- "+" toggle button for the add-your-own-track form
    local pbS=30*MDS
    local pbX=cp.x+cw-10*MDS-pbS; local pbY2=cp.y+4*MDS
    local hovP=mp2.x>=pbX and mp2.x<=pbX+pbS and mp2.y>=pbY2 and mp2.y<=pbY2+pbS
    cdl:AddRectFilled(imgui.ImVec2(pbX,pbY2),imgui.ImVec2(pbX+pbS,pbY2+pbS),
        showAddForm and rgbaT(th.accent) or (hovP and rgbaT(th.accentH) or rgba(.18,.18,.18,.95)),7*MDS)
    if not showAddForm then cdl:AddRect(imgui.ImVec2(pbX,pbY2),imgui.ImVec2(pbX+pbS,pbY2+pbS),rgbaT(th.accent),7*MDS,0,1.3) end
    do
        local ico=showAddForm and ICO_X or ICO_PLUS
        local isz=imgui.CalcTextSize(ico)
        cdl:AddText(imgui.ImVec2(pbX+pbS/2-isz.x/2,pbY2+pbS/2-isz.y/2),
            showAddForm and rgba(0,0,0,1) or rgbaT(th.accent),ico)
    end
    imgui.SetCursorScreenPos(imgui.ImVec2(pbX,pbY2))
    if imgui.InvisibleButton('##addtoggle',imgui.ImVec2(pbS,pbS)) then showAddForm=not showAddForm end

    -- add-your-own-track form
    if showAddForm then
        local fy=cp.y+4*MDS+searchH
        cdl:AddRectFilled(imgui.ImVec2(cp.x+10*MDS,fy),imgui.ImVec2(cp.x+cw-10*MDS,fy+formH-4*MDS),rgba(.12,.12,.12,.96),8*MDS)
        cdl:AddRect(imgui.ImVec2(cp.x+10*MDS,fy),imgui.ImVec2(cp.x+cw-10*MDS,fy+formH-4*MDS),rgbaT(th.accent),8*MDS,0,1.2)
        imgui.PushStyleColor(imgui.Col.FrameBg,imgui.ImVec4(.22,.22,.22,.9))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+18*MDS,fy+8*MDS))
        imgui.SetNextItemWidth(cw-36*MDS)
        inputHint('##addtitle',u8('\xcd\xe0\xe7\xe2\xe0\xed\xe8\xe5 \xf2\xf0\xe5\xea\xe0'),addTitleBuf,96) -- "Название трека"
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+18*MDS,fy+38*MDS))
        imgui.SetNextItemWidth(cw-120*MDS)
        inputHint('##addurl',u8('\xcf\xf0\xff\xec\xe0\xff \xf1\xf1\xfb\xeb\xea\xe0 (.mp3)'),addUrlBuf,256) -- "Прямая ссылка (.mp3)"
        imgui.PopStyleColor(2)
        -- Add button
        local abW=70*MDS; local abH=26*MDS
        local abX=cp.x+cw-18*MDS-abW; local abY=fy+38*MDS
        local hovA=mp2.x>=abX and mp2.x<=abX+abW and mp2.y>=abY and mp2.y<=abY+abH
        cdl:AddRectFilled(imgui.ImVec2(abX,abY),imgui.ImVec2(abX+abW,abY+abH),hovA and rgbaT(th.accentH) or rgbaT(th.accent),6*MDS)
        local albl=ICO_PLUS..' Add'; local alsz=imgui.CalcTextSize(albl)
        imgui.SetCursorScreenPos(imgui.ImVec2(abX+abW/2-alsz.x/2,abY+abH/2-alsz.y/2))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(0,0,0,1)); imgui.Text(albl); imgui.PopStyleColor()
        imgui.SetCursorScreenPos(imgui.ImVec2(abX,abY))
        if imgui.InvisibleButton('##addtrackbtn',imgui.ImVec2(abW,abH)) then
            if addCustomTrack(ffi.string(addTitleBuf), ffi.string(addUrlBuf)) then
                ffi.copy(addTitleBuf,''); ffi.copy(addUrlBuf,''); showAddForm=false
            end
        end
    end

    local filtered={}
    for i,t in ipairs(PLAYLIST) do
        if searchStr=='' or t.title:lower():find(searchStr,1,true) then
            filtered[#filtered+1]={idx=i,t=t}
        end
    end

    local rowH  = 52*MDS
    local listH = cH - topH - 2*MDS

    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x, cp.y+topH+2*MDS))
    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0,0,0,0))
    if imgui.BeginChild('##plist', imgui.ImVec2(cw, listH), false,
            imgui.WindowFlags.NoScrollWithMouse) then

        local ldl  = imgui.GetWindowDrawList()
        local lp   = imgui.GetWindowPos()
        local lw   = imgui.GetWindowWidth()
        local sc   = imgui.GetScrollY()
        local sbSz = imgui.GetStyle().ScrollbarSize

        imgui.SetCursorPos(imgui.ImVec2(0, #filtered * rowH))

        local btnSz  = 20*MDS
        local delIdx = nil
        local first  = math.max(1, math.floor(sc/rowH)+1)
        local last   = math.min(#filtered, first + math.ceil(listH/rowH) + 1)

        ldl:PushClipRect(imgui.ImVec2(lp.x,lp.y), imgui.ImVec2(lp.x+lw,lp.y+listH), true)

        for ii=first,last do
            local e=filtered[ii]; if not e then break end
            local i=e.idx; local t=e.t
            local ry = lp.y + (ii-1)*rowH - sc

            local addX  = lp.x + 6*MDS
            local dlX   = lp.x + lw - sbSz - btnSz - 4*MDS
            local delX  = dlX - btnSz - 4*MDS
            local btnY2 = ry + rowH/2 - btnSz/2
            local playX = addX + btnSz + 4*MDS
            local playW = delX - playX - 4*MDS

            local hovDel = mp2.x>=delX and mp2.x<=delX+btnSz and mp2.y>=ry and mp2.y<=ry+rowH
            local hovAdd = mp2.x>=addX and mp2.x<=addX+btnSz and mp2.y>=ry and mp2.y<=ry+rowH
            local hovDl  = mp2.x>=dlX  and mp2.x<=dlX+btnSz  and mp2.y>=ry and mp2.y<=ry+rowH
            local hovRow = mp2.x>=playX and mp2.x<=playX+playW and mp2.y>=ry and mp2.y<=ry+rowH

            if hovRow then ldl:AddRectFilled(imgui.ImVec2(lp.x,ry),imgui.ImVec2(lp.x+lw,ry+rowH),rgbaT(th.rowHov)) end
            if i==curTrack then ldl:AddRectFilled(imgui.ImVec2(lp.x,ry+5*MDS),imgui.ImVec2(lp.x+3*MDS,ry+rowH-5*MDS),rgbaT(th.accent)) end

            ldl:AddRectFilled(imgui.ImVec2(addX,btnY2),imgui.ImVec2(addX+btnSz,btnY2+btnSz),
                hovAdd and rgbaT(th.accentH) or rgbaT(th.accent),4*MDS)
            local ph=btnSz*0.45
            ldl:AddLine(imgui.ImVec2(addX+btnSz/2,btnY2+btnSz/2-ph/2),imgui.ImVec2(addX+btnSz/2,btnY2+btnSz/2+ph/2),rgba(0,0,0,1),1.8)
            ldl:AddLine(imgui.ImVec2(addX+btnSz/2-ph/2,btnY2+btnSz/2),imgui.ImVec2(addX+btnSz/2+ph/2,btnY2+btnSz/2),rgba(0,0,0,1),1.8)
            imgui.SetCursorScreenPos(imgui.ImVec2(addX,btnY2))
            if imgui.InvisibleButton('##add'..ii,imgui.ImVec2(btnSz,btnSz)) then
                ctxMenu.open=true; ctxMenu.trackIdx=i
                ctxMenu.x=addX+btnSz+6*MDS; ctxMenu.y=ry; scanPlaylists()
            end

            imgui.SetCursorScreenPos(imgui.ImVec2(addX+btnSz+6*MDS, ry+rowH/2-7*MDS))
            imgui.PushStyleColor(imgui.Col.Text, i==curTrack
                and imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1)
                or  imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
            imgui.Text(tostring(i)); imgui.PopStyleColor()

            if isLiked(t.url) then
                local hI=fa.HEART; local hIsz=imgui.CalcTextSize(hI)
                ldl:AddText(imgui.ImVec2(delX-18*MDS, ry+rowH/2-hIsz.y/2),
                    rgba(th.liked[1],th.liked[2],th.liked[3],1), hI)
            end

            local titleX=addX+btnSz+24*MDS
            local maxTW=delX-titleX-22*MDS
            local ttl=t.title
            while imgui.CalcTextSize(ttl).x>maxTW and #ttl>1 do ttl=ttl:sub(1,-2) end
            if ttl~=t.title then ttl=ttl:sub(1,-2)..'..' end
            imgui.SetCursorScreenPos(imgui.ImVec2(titleX, ry+rowH/2-7*MDS))
            imgui.PushStyleColor(imgui.Col.Text, i==curTrack
                and imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1)
                or  imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
            imgui.Text(ttl); imgui.PopStyleColor()

            local dls = dlStatus[t.url]
            local cached2 = isCached(t.url)
            if type(dls)=='number' and dls < 100 and not cached2 then
                local pbW2 = btnSz; local pbH2 = 4*MDS
                local pbX2 = dlX; local pbY2 = btnY2 + btnSz/2 - pbH2/2
                ldl:AddRectFilled(imgui.ImVec2(pbX2,pbY2),imgui.ImVec2(pbX2+pbW2,pbY2+pbH2),rgba(.2,.2,.2,1),2*MDS)
                ldl:AddRectFilled(imgui.ImVec2(pbX2,pbY2),imgui.ImVec2(pbX2+pbW2*(dls/100),pbY2+pbH2),rgbaT(th.accent),2*MDS)
            else
                local dlIco, dlColU
                if cached2 or dls==100 then
                    dlIco  = fa['CIRCLE_CHECK']
                    dlColU = rgba(th.accent[1],th.accent[2],th.accent[3],1)
                elseif dls=='error' then
                    dlIco  = fa['CIRCLE_XMARK']
                    dlColU = rgba(.9,.2,.2,1)
                else
                    dlIco  = fa['DOWNLOAD']
                    dlColU = hovDl and rgba(1,1,1,1) or rgba(th.textDim[1],th.textDim[2],th.textDim[3],0.8)
                end
                local dIsz = imgui.CalcTextSize(dlIco)
                ldl:AddText(imgui.ImVec2(dlX+btnSz/2-dIsz.x/2, btnY2+btnSz/2-dIsz.y/2), dlColU, dlIco)
            end
            imgui.SetCursorScreenPos(imgui.ImVec2(dlX, btnY2))
            if imgui.InvisibleButton('##dl'..ii, imgui.ImVec2(btnSz, btnSz)) then
                if not cached2 and dls ~= 'downloading' then
                    downloadTrack(t.url)
                end
            end

            ldl:AddRectFilled(imgui.ImVec2(delX,btnY2),imgui.ImVec2(delX+btnSz,btnY2+btnSz),
                hovDel and rgba(.90,.10,.10,1) or rgba(.40,.12,.12,.80),4*MDS)
            local xp=5*MDS
            ldl:AddLine(imgui.ImVec2(delX+xp,btnY2+xp),imgui.ImVec2(delX+btnSz-xp,btnY2+btnSz-xp),rgba(1,1,1,1),1.6)
            ldl:AddLine(imgui.ImVec2(delX+btnSz-xp,btnY2+xp),imgui.ImVec2(delX+xp,btnY2+btnSz-xp),rgba(1,1,1,1),1.6)
            imgui.SetCursorScreenPos(imgui.ImVec2(delX,btnY2))
            if imgui.InvisibleButton('##del'..ii,imgui.ImVec2(btnSz,btnSz)) then delIdx=i end

            ldl:AddLine(imgui.ImVec2(lp.x+6*MDS,ry+rowH-1),imgui.ImVec2(lp.x+lw-6*MDS,ry+rowH-1),rgbaT(th.sep))

            imgui.SetCursorScreenPos(imgui.ImVec2(playX,ry))
            if imgui.InvisibleButton('##r'..ii,imgui.ImVec2(math.max(4*MDS,playW),rowH)) then playTrack(i) end
        end

        ldl:PopClipRect()
        imgui.EndChild()
        if delIdx then deleteTrack(delIdx) end
    end
    imgui.PopStyleColor()
end

local function drawLikedPage(cp,cw,cH)
    local th=T(); local mp2=imgui.GetIO().MousePos
    local rowH=52*MDS
    local likedList={}
    for i,t in ipairs(PLAYLIST) do
        if isLiked(t.url) then likedList[#likedList+1]={idx=i,t=t} end
    end
    if #likedList==0 then
        local cdl2=imgui.GetWindowDrawList()
        local msg=u8('\xcd\xe5\xf2 \xeb\xe0\xe9\xea\xed\xf3\xf2\xfb\xf5 \xf2\xf0\xe5\xea\xee\xe2')
        local msz=imgui.CalcTextSize(msg)
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+cw/2-msz.x/2,cp.y+cH/2-msz.y/2))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
        imgui.Text(msg); imgui.PopStyleColor(); return
    end

    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x, cp.y))
    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0,0,0,0))
    if imgui.BeginChild('##liked', imgui.ImVec2(cw, cH), false,
            imgui.WindowFlags.NoScrollWithMouse) then

        local ldl  = imgui.GetWindowDrawList()
        local lp   = imgui.GetWindowPos()
        local lw   = imgui.GetWindowWidth()
        local sc   = imgui.GetScrollY()
        local sbSz = imgui.GetStyle().ScrollbarSize
        local btnSz= 20*MDS

        imgui.SetCursorPos(imgui.ImVec2(0, #likedList * rowH))

        ldl:PushClipRect(imgui.ImVec2(lp.x,lp.y), imgui.ImVec2(lp.x+lw,lp.y+cH), true)
        local first=math.max(1,math.floor(sc/rowH)+1)
        local last =math.min(#likedList, first+math.ceil(cH/rowH)+1)

        for ii=first,last do
            local e=likedList[ii]; if not e then break end
            local i=e.idx; local t=e.t
            local ry=lp.y+(ii-1)*rowH-sc
            local addX=lp.x+6*MDS
            local rightEdge=lp.x+lw-sbSz-4*MDS
            local btnY2=ry+rowH/2-btnSz/2
            local hovAdd=mp2.x>=addX and mp2.x<=addX+btnSz and mp2.y>=ry and mp2.y<=ry+rowH
            local hovRow=mp2.x>=addX+btnSz+4*MDS and mp2.x<=rightEdge and mp2.y>=ry and mp2.y<=ry+rowH

            if hovRow then ldl:AddRectFilled(imgui.ImVec2(lp.x,ry),imgui.ImVec2(lp.x+lw,ry+rowH),rgbaT(th.rowHov)) end
            if i==curTrack then ldl:AddRectFilled(imgui.ImVec2(lp.x,ry+5*MDS),imgui.ImVec2(lp.x+3*MDS,ry+rowH-5*MDS),rgbaT(th.accent)) end

            ldl:AddRectFilled(imgui.ImVec2(addX,btnY2),imgui.ImVec2(addX+btnSz,btnY2+btnSz),
                hovAdd and rgbaT(th.accentH) or rgbaT(th.accent),4*MDS)
            local ph=btnSz*0.45
            ldl:AddLine(imgui.ImVec2(addX+btnSz/2,btnY2+btnSz/2-ph/2),imgui.ImVec2(addX+btnSz/2,btnY2+btnSz/2+ph/2),rgba(0,0,0,1),1.8)
            ldl:AddLine(imgui.ImVec2(addX+btnSz/2-ph/2,btnY2+btnSz/2),imgui.ImVec2(addX+btnSz/2+ph/2,btnY2+btnSz/2),rgba(0,0,0,1),1.8)
            imgui.SetCursorScreenPos(imgui.ImVec2(addX,btnY2))
            if imgui.InvisibleButton('##ladd'..ii,imgui.ImVec2(btnSz,btnSz)) then
                ctxMenu.open=true; ctxMenu.trackIdx=i
                ctxMenu.x=addX+btnSz+6*MDS; ctxMenu.y=ry; scanPlaylists()
            end

            do
                local hI=fa.HEART; local hIsz=imgui.CalcTextSize(hI)
                ldl:AddText(imgui.ImVec2(addX+btnSz+6*MDS,ry+rowH/2-hIsz.y/2),
                    rgba(th.liked[1],th.liked[2],th.liked[3],1), hI)
            end

            local titleX=addX+btnSz+24*MDS
            local maxTW=rightEdge-titleX-4*MDS
            local ttl=t.title
            while imgui.CalcTextSize(ttl).x>maxTW and #ttl>1 do ttl=ttl:sub(1,-2) end
            if ttl~=t.title then ttl=ttl:sub(1,-2)..'..' end
            imgui.SetCursorScreenPos(imgui.ImVec2(titleX,ry+rowH/2-7*MDS))
            imgui.PushStyleColor(imgui.Col.Text, i==curTrack
                and imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1)
                or  imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
            imgui.Text(ttl); imgui.PopStyleColor()

            ldl:AddLine(imgui.ImVec2(lp.x+6*MDS,ry+rowH-1),imgui.ImVec2(lp.x+lw-6*MDS,ry+rowH-1),rgbaT(th.sep))
            imgui.SetCursorScreenPos(imgui.ImVec2(addX+btnSz+4*MDS,ry))
            if imgui.InvisibleButton('##lr'..ii,imgui.ImVec2(math.max(4*MDS,rightEdge-addX-btnSz-8*MDS),rowH)) then playTrack(i) end
        end

        ldl:PopClipRect()
        imgui.EndChild()
    end
    imgui.PopStyleColor()
end

local function drawPlaylistsPage(cp,cdl,cw,cH,mp)
    local th=T(); local mp2=imgui.GetIO().MousePos

    local createH=36*MDS
    if showNewPlForm then
        cdl:AddRectFilled(imgui.ImVec2(cp.x+10*MDS,cp.y+4*MDS),
            imgui.ImVec2(cp.x+cw-10*MDS,cp.y+4*MDS+createH),rgba(.14,.14,.14,.95),8*MDS)
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+14*MDS,cp.y+8*MDS))
        imgui.SetNextItemWidth(cw-90*MDS)
        imgui.PushStyleColor(imgui.Col.FrameBg,imgui.ImVec4(.22,.22,.22,.9))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
        imgui.InputText('##newpl',newPlBuf,64)
        imgui.PopStyleColor(2)
        local okW=32*MDS; local okH=22*MDS
        local okX=cp.x+cw-10*MDS-okW; local okY=cp.y+4*MDS+(createH-okH)/2
        local hovOk=mp2.x>=okX and mp2.x<=okX+okW and mp2.y>=okY and mp2.y<=okY+okH
        cdl:AddRectFilled(imgui.ImVec2(okX,okY),imgui.ImVec2(okX+okW,okY+okH),
            hovOk and rgbaT(th.accentH) or rgbaT(th.accent),6*MDS)
        local oksz=imgui.CalcTextSize('OK')
        imgui.SetCursorScreenPos(imgui.ImVec2(okX+okW/2-oksz.x/2,okY+okH/2-oksz.y/2))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(0,0,0,1))
        imgui.Text('OK'); imgui.PopStyleColor()
        imgui.SetCursorScreenPos(imgui.ImVec2(okX,okY))
        if imgui.InvisibleButton('##plok',imgui.ImVec2(okW,okH)) then
            local nm=ffi.string(newPlBuf):match('^%s*(.-)%s*$')
            local ok2,created=createPlaylist(nm)
            if ok2 then
                scanPlaylists(); showNewPlForm=false; ffi.copy(newPlBuf,'')
                sampAddChatMessage('[Spotify] \xd1\xee\xe7\xe4\xe0\xed: '..created, 0x1DB954)
            else
                sampAddChatMessage('[Spotify] \xc8\xec\xff \xe7\xe0\xed\xff\xf2\xee', 0xFF4444)
            end
        end
    else
        local btnH2=30*MDS
        local hovN=mp2.x>=cp.x+10*MDS and mp2.x<=cp.x+cw-10*MDS and mp2.y>=cp.y+4*MDS and mp2.y<=cp.y+4*MDS+btnH2
        cdl:AddRectFilled(imgui.ImVec2(cp.x+10*MDS,cp.y+4*MDS),
            imgui.ImVec2(cp.x+cw-10*MDS,cp.y+4*MDS+btnH2),
            hovN and rgba(.18,.18,.18,1) or rgba(.14,.14,.14,.9),8*MDS)
        cdl:AddRect(imgui.ImVec2(cp.x+10*MDS,cp.y+4*MDS),
                               imgui.ImVec2(cp.x+cw-10*MDS,cp.y+4*MDS+btnH2),rgbaT(th.accent),8*MDS,0,1.5)
        local ns=fa['CIRCLE_PLUS']..'  '..u8('\xcd\xee\xe2\xfb\xe9 \xef\xeb\xe5\xe9\xeb\xe8\xf1\xf2')
        local nsz=imgui.CalcTextSize(ns)
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+cw/2-nsz.x/2,cp.y+4*MDS+btnH2/2-nsz.y/2))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1))
        imgui.Text(ns); imgui.PopStyleColor()
        imgui.SetCursorScreenPos(imgui.ImVec2(cp.x+10*MDS,cp.y+4*MDS))
        if imgui.InvisibleButton('##newplbtn',imgui.ImVec2(cw-20*MDS,btnH2)) then showNewPlForm=true end
        createH=btnH2
    end

    local rowH2=52*MDS
    local listH2=cH-createH-10*MDS

    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x, cp.y+createH+10*MDS))
    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0,0,0,0))
    if imgui.BeginChild('##pllist', imgui.ImVec2(cw, listH2), false,
            imgui.WindowFlags.NoScrollWithMouse) then

        local ldl  = imgui.GetWindowDrawList()
        local lp   = imgui.GetWindowPos()
        local lw   = imgui.GetWindowWidth()
        local sc   = imgui.GetScrollY()

        imgui.SetCursorPos(imgui.ImVec2(0, #PLAYLISTS * rowH2))

        ldl:PushClipRect(imgui.ImVec2(lp.x,lp.y), imgui.ImVec2(lp.x+lw,lp.y+listH2), true)
        local first=math.max(1,math.floor(sc/rowH2)+1)
        local last =math.min(#PLAYLISTS, first+math.ceil(listH2/rowH2)+1)

        for ii=first,last do
            local name=PLAYLISTS[ii]; if not name then break end
            local ry=lp.y+(ii-1)*rowH2-sc
            local isAct=(name==curPlaylist)
            local hovP=mp2.x>=lp.x and mp2.x<=lp.x+lw and mp2.y>=ry and mp2.y<=ry+rowH2
            if hovP then ldl:AddRectFilled(imgui.ImVec2(lp.x,ry),imgui.ImVec2(lp.x+lw,ry+rowH2),rgbaT(th.rowHov)) end
            if isAct then
                ldl:AddRectFilled(imgui.ImVec2(lp.x,ry+8*MDS),imgui.ImVec2(lp.x+3*MDS,ry+rowH2-8*MDS),rgbaT(th.accent))
                ldl:AddRectFilled(imgui.ImVec2(lp.x+4*MDS,ry+4*MDS),imgui.ImVec2(lp.x+lw-4*MDS,ry+rowH2-4*MDS),rgba(.11,.73,.33,.10),8*MDS)
            end
            do local dI=fa['COMPACT_DISC']; local dIsz=imgui.CalcTextSize(dI)
               ldl:AddText(imgui.ImVec2(lp.x+10*MDS,ry+rowH2/2-dIsz.y/2),
                   isAct and rgbaT(th.accent) or rgba(th.textDim[1],th.textDim[2],th.textDim[3],0.8),dI) end
            imgui.SetCursorScreenPos(imgui.ImVec2(lp.x+44*MDS,ry+rowH2/2-16*MDS))
            imgui.PushStyleColor(imgui.Col.Text, isAct
                and imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1)
                or  imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
            imgui.Text(name:sub(1,22)); imgui.PopStyleColor()
            if isAct then
                imgui.SetCursorScreenPos(imgui.ImVec2(lp.x+44*MDS,ry+rowH2/2+2*MDS))
                imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
                imgui.Text(tostring(#PLAYLIST)..' tracks'); imgui.PopStyleColor()
            end
            ldl:AddLine(imgui.ImVec2(lp.x+6*MDS,ry+rowH2-1),imgui.ImVec2(lp.x+lw-6*MDS,ry+rowH2-1),rgbaT(th.sep))
            imgui.SetCursorScreenPos(imgui.ImVec2(lp.x,ry))
            if imgui.InvisibleButton('##pl'..ii,imgui.ImVec2(lw,rowH2)) then
                if name~=curPlaylist then switchPlaylist(name) end
            end
        end

        ldl:PopClipRect()
        imgui.EndChild()
    end
    imgui.PopStyleColor()
end

-- Russian guide text (UTF-8 literals; the font already renders Cyrillic)
local INFO_LINES = {
    "Как добавить свою музыку:",
    "1) Скачайте трек на телефон (mp3).",
    "2) Загрузите файл на catbox.moe (или любой хостинг,",
    "   который даёт ПРЯМУЮ ссылку на .mp3).",
    "3) Скопируйте прямую ссылку.",
    "4) Вкладка \"List\" -> кнопка + -> вставьте название и",
    "   ссылку -> Add. Трек попадёт в ваш плейлист \"My Music\".",
    "",
    "Локальные файлы (без интернета):",
    "Положите .mp3 в папку ST-Music/local рядом со скриптом —",
    "они появятся в плейлисте \"Local Files\".",
    "",
    "Почему нельзя брать ссылки прямо из Spotify:",
    "Стриминги отдают защищённый (DRM) поток, прямой ссылки",
    "на файл нет. Поэтому используется хостинг прямых ссылок",
    "(catbox и т.п.) — это нормальный и рабочий способ.",
    "",
    "Установка скрипта:",
    "1) Нужен MoonLoader (Android) + mimgui, fAwesome6,",
    "   inicfg, requests, lfs и libbass.so.",
    "2) Киньте этот .lua в папку moonloader.",
    "3) Зайдите в игру, команда: /spotify",
    "",
    "Подсказки: + создаёт свой плейлист, сердечко — лайк,",
    "стрелка вниз — кэш трека в память, Mini — мини-плеер.",
}

local function drawInfoPage(cp,cdl,cw,cH,mp)
    local th=T()
    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x, cp.y))
    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0,0,0,0))
    if imgui.BeginChild('##info', imgui.ImVec2(cw, cH), false) then
        imgui.Dummy(imgui.ImVec2(0,2*MDS))

        -- sleep timer
        imgui.SetCursorPosX(12*MDS)
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1))
        imgui.Text(ICO_MOON..'  '..u8('\xd2\xe0\xe9\xec\xe5\xf0 \xf1\xed\xe0')) -- "Таймер сна"
        imgui.PopStyleColor()

        local opts={0,15,30,60}
        imgui.SetCursorPosX(12*MDS)
        for i,m in ipairs(opts) do
            if i>1 then imgui.SameLine() end
            local sel=(sleepMinutes==m)
            if sel then
                imgui.PushStyleColor(imgui.Col.Button,imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1))
                imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(0,0,0,1))
            end
            local lbl=(m==0) and 'Off' or (m..'m')
            if imgui.Button(lbl..'##sl'..m, imgui.ImVec2(52*MDS,26*MDS)) then
                sleepMinutes=m
                sleepDeadline=(m>0) and (os.time()+m*60) or 0
            end
            if sel then imgui.PopStyleColor(2) end
        end
        if sleepMinutes>0 then
            local left=math.max(0, sleepDeadline-os.time())
            imgui.SetCursorPosX(12*MDS)
            imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
            imgui.Text(u8('\xce\xf1\xf2\xe0\xeb\xee\xf1\xfc: ')..fmt(left)) -- "Осталось: "
            imgui.PopStyleColor()
        end

        imgui.Dummy(imgui.ImVec2(0,6*MDS))
        imgui.SetCursorPosX(12*MDS)
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.sep[1],th.sep[2],th.sep[3],1))
        imgui.Text('--------------------------------')
        imgui.PopStyleColor()
        imgui.Dummy(imgui.ImVec2(0,4*MDS))

        imgui.PushTextWrapPos(cw-14*MDS)
        for _,line in ipairs(INFO_LINES) do
            imgui.SetCursorPosX(12*MDS)
            if line=='' then
                imgui.Dummy(imgui.ImVec2(0,4*MDS))
            elseif line:match(':$') then
                imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1))
                imgui.TextWrapped(line); imgui.PopStyleColor()
            else
                imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
                imgui.TextWrapped(line); imgui.PopStyleColor()
            end
        end
        imgui.PopTextWrapPos()
        imgui.Dummy(imgui.ImVec2(0,8*MDS))
        imgui.EndChild()
    end
    imgui.PopStyleColor()
end

imgui.OnFrame(
    function() return ctxMenu.open and showMenu[0] end,
    function(self)
        self.HideCursor = false
        local th = T()
        local mp = imgui.GetIO().MousePos
        local mDown = imgui.GetIO().MouseDown[0]

        local itemH = 34*MDS
        local targets = {}
        for _,n in ipairs(PLAYLISTS) do
            if n ~= 'default' and n ~= LOCAL_NAME then targets[#targets+1] = n end
        end

        local popW = 160*MDS
        local popH = #targets * itemH + 36*MDS

        local px = math.max(4*MDS, math.min(sw - popW - 4*MDS, ctxMenu.x))
        local py = math.max(4*MDS, math.min(sh - popH - 4*MDS, ctxMenu.y))

        local st = imgui.GetStyle()
        st.WindowRounding = 10; st.WindowBorderSize = 0; st.WindowPadding = imgui.ImVec2(0,0)
        local C = st.Colors; local cl = imgui.Col
        C[cl.WindowBg] = imgui.ImVec4(0.10,0.10,0.10,0.97)

        imgui.SetNextWindowSize(imgui.ImVec2(popW, popH), imgui.Cond.Always)
        imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Always)
        local wf = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
                 + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
                 + imgui.WindowFlags.NoMove
        if not imgui.Begin('##ctx', nil, wf) then imgui.End(); return end

        local dl  = imgui.GetWindowDrawList()
        local wp  = imgui.GetWindowPos()
        local ww2 = imgui.GetWindowWidth()

        dl:AddRect(wp, imgui.ImVec2(wp.x+ww2, wp.y+popH), rgbaT(th.accent), 10*MDS, 0, 1.2)

        local hdrH = 28*MDS
        dl:AddRectFilled(wp, imgui.ImVec2(wp.x+ww2, wp.y+hdrH), rgba(.05,.05,.05,1), 10*MDS, 3)
        dl:AddRectFilled(imgui.ImVec2(wp.x,wp.y+hdrH-8*MDS),
                         imgui.ImVec2(wp.x+ww2,wp.y+hdrH), rgba(.05,.05,.05,1))
        local hdrTxt = u8('\xc4\xee\xe1\xe0\xe2\xe8\xf2\xfc \xe2:')
        local htsz = imgui.CalcTextSize(hdrTxt)
        imgui.SetCursorScreenPos(imgui.ImVec2(wp.x+ww2/2-htsz.x/2, wp.y+hdrH/2-htsz.y/2))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
        imgui.Text(hdrTxt)
        imgui.PopStyleColor()

        if #targets == 0 then
            local noTxt = u8('\xcd\xe5\xf2 \xef\xeb\xe5\xe9\xeb\xe8\xf1\xf2\xee\xe2')
            local ntsz = imgui.CalcTextSize(noTxt)
            imgui.SetCursorScreenPos(imgui.ImVec2(wp.x+ww2/2-ntsz.x/2, wp.y+hdrH+itemH/2-ntsz.y/2))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
            imgui.Text(noTxt)
            imgui.PopStyleColor()
        else
            for ki, name in ipairs(targets) do
                local iy = wp.y + hdrH + (ki-1)*itemH
                local hovI = mp.x>=wp.x and mp.x<=wp.x+ww2 and mp.y>=iy and mp.y<=iy+itemH
                if hovI then
                    dl:AddRectFilled(imgui.ImVec2(wp.x,iy), imgui.ImVec2(wp.x+ww2,iy+itemH),
                        rgba(.18,.18,.18,1))
                end
                do local dI2=fa['COMPACT_DISC']; local dIsz2=imgui.CalcTextSize(dI2)
                   dl:AddText(imgui.ImVec2(wp.x+8*MDS,iy+itemH/2-dIsz2.y/2),rgbaT(th.accent),dI2) end
                local nsz2 = imgui.CalcTextSize(name:sub(1,14))
                imgui.SetCursorScreenPos(imgui.ImVec2(wp.x+32*MDS, iy+itemH/2-nsz2.y/2))
                imgui.PushStyleColor(imgui.Col.Text,
                    hovI and imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1)
                          or imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
                imgui.Text(name:sub(1,14))
                imgui.PopStyleColor()
                if ki < #targets then
                    dl:AddLine(imgui.ImVec2(wp.x+8*MDS, iy+itemH),
                               imgui.ImVec2(wp.x+ww2-8*MDS, iy+itemH),
                               rgbaT(th.sep))
                end
                imgui.SetCursorScreenPos(imgui.ImVec2(wp.x, iy))
                if imgui.InvisibleButton('##ctx'..ki, imgui.ImVec2(ww2, itemH)) then
                    local track = PLAYLIST[ctxMenu.trackIdx]
                    if track then
                        addTrackToPlaylist(name, track.title, track.url)
                    end
                    ctxMenu.open = false
                end
            end
        end

        imgui.End()

        if mDown then
            local inPop = mp.x>=px and mp.x<=px+popW and mp.y>=py and mp.y<=py+popH
            if not inPop then ctxMenu.open = false end
        end
    end
)

local miniW=350*MDS; local miniH=72*MDS

imgui.OnFrame(
    function() return (showMini or miniAlpha>0.01) and not showMenu[0] end,
    function(self)
        self.HideCursor = miniDragMode

        local aTarget=showMini and 1.0 or 0.0
        if showMini then
            miniAlpha=miniAlpha+(aTarget-miniAlpha)*0.14
            miniScale=miniScale+(aTarget-miniScale)*0.11
        else
            miniAlpha=miniAlpha+(aTarget-miniAlpha)*0.20
            miniScale=miniScale+(aTarget-miniScale)*0.22
        end
        if math.abs(miniAlpha-aTarget)<0.004 then miniAlpha=aTarget end
        if math.abs(miniScale-aTarget)<0.004 then miniScale=aTarget end
        if miniAlpha<=0.01 then return end

        if texNeed.disc and doesFileExist(discPath) and not discTex then
            discTex=imgui.CreateTextureFromFile(discPath); texNeed.disc=false end

        if isPlaying then
            discAngle=discAngle+DISC_SPEED
            if discAngle>math.pi*2 then discAngle=discAngle-math.pi*2 end
        end

        local io2  = imgui.GetIO()
        local mx   = io2.MousePos.x
        local my   = io2.MousePos.y
        local mDown= io2.MouseDown[0]

        if miniDragMode then
            if mDown then
                miniPosX = math.max(0, math.min(sw-miniW, math.floor(mx)))
                miniPosY = math.max(0, math.min(sh-miniH, math.floor(my)))
            end
            local dl2 = imgui.GetForegroundDrawList()
            local th2 = T()
            local pulse = 0.55 + 0.45*math.abs(math.sin(os.clock()*3.5))
            dl2:AddRect(
                imgui.ImVec2(miniPosX, miniPosY),
                imgui.ImVec2(miniPosX+miniW, miniPosY+miniH),
                rgba(th2.accent[1], th2.accent[2], th2.accent[3], pulse),
                0, 0, 2.5*MDS
            )
            local hint = u8('\xd2\xe0\xef \xe4\xeb\xff \xf4\xe8\xea\xf1\xe0\xf6\xe8\xe8')
            local hsz  = imgui.CalcTextSize(hint)
            local hx   = miniPosX + miniW/2 - hsz.x/2
            local hy   = miniPosY + miniH + 6*MDS
            dl2:AddRectFilled(
                imgui.ImVec2(hx-6*MDS, hy),
                imgui.ImVec2(hx+hsz.x+6*MDS, hy+hsz.y+4*MDS),
                rgba(0,0,0,0.82), 4*MDS
            )
            dl2:AddText(imgui.ImVec2(hx, hy+2*MDS), rgba(1,1,1,1), hint)

            if io2.MouseReleased[0] then
                miniDragMode = false
                config.settings.mini_x = tostring(math.floor(miniPosX))
                config.settings.mini_y = tostring(math.floor(miniPosY))
                saveConfig()
                sampAddChatMessage('[Spotify] \xcc\xe8\xed\xe8-\xef\xeb\xe5\xe5\xf0 \xf1\xee\xf5\xf0\xe0\xed\xb8\xed: '..math.floor(miniPosX)..', '..math.floor(miniPosY), 0x1DB954)
            end
        end

        local th=T()
        local st=imgui.GetStyle()
        st.WindowRounding=0; st.WindowBorderSize=0; st.WindowPadding=imgui.ImVec2(0,0)
        st.Colors[imgui.Col.WindowBg]=imgui.ImVec4(th.winBg[1],th.winBg[2],th.winBg[3],th.winBg[4]*miniAlpha)

        imgui.SetNextWindowSize(imgui.ImVec2(miniW,miniH),imgui.Cond.Always)
        imgui.SetNextWindowPos(imgui.ImVec2(miniPosX,miniPosY),imgui.Cond.Always)
        local wf=imgui.WindowFlags.NoTitleBar+imgui.WindowFlags.NoResize
                +imgui.WindowFlags.NoScrollbar+imgui.WindowFlags.NoScrollWithMouse
                +imgui.WindowFlags.NoMove
        if not imgui.Begin('##mini',nil,wf) then imgui.End(); return end

        local dl=imgui.GetWindowDrawList()
        local wp=imgui.GetWindowPos()
        local mw=miniW; local mh=miniH
        local mp=io2.MousePos

        local mA=miniAlpha
        dl:PushClipRect(imgui.ImVec2(wp.x,wp.y),imgui.ImVec2(wp.x+mw,wp.y+mh),true)
        dl:AddRectFilled(wp,imgui.ImVec2(wp.x+mw,wp.y+mh),rgba(th.winBg[1],th.winBg[2],th.winBg[3],th.winBg[4]*mA),0)
        local realDur=getRealDur(); local el=getElapsed()
        local frac2=realDur>0 and math.max(0,math.min(1,el/realDur)) or 0
        dl:AddRectFilled(imgui.ImVec2(wp.x,wp.y+mh-3*MDS),imgui.ImVec2(wp.x+mw,wp.y+mh),rgbaT(th.pb),0)
        if frac2>0.001 then
            dl:AddRectFilled(imgui.ImVec2(wp.x,wp.y+mh-3*MDS),imgui.ImVec2(wp.x+mw*frac2,wp.y+mh),rgbaT(th.accent),0)
        end

        local dSz=78*MDS; local dPad=6*MDS
        local dCx=wp.x+dPad+dSz/2; local dCy=wp.y+mh/2-1*MDS
        if discTex then
            local dr=dSz/2
            local x1,y1=rotPt(dCx-dr,dCy-dr,dCx,dCy,discAngle)
            local x2,y2=rotPt(dCx+dr,dCy-dr,dCx,dCy,discAngle)
            local x3,y3=rotPt(dCx+dr,dCy+dr,dCx,dCy,discAngle)
            local x4,y4=rotPt(dCx-dr,dCy+dr,dCx,dCy,discAngle)
            dl:AddImageQuad(discTex,
                imgui.ImVec2(x1,y1),imgui.ImVec2(x2,y2),
                imgui.ImVec2(x3,y3),imgui.ImVec2(x4,y4),
                imgui.ImVec2(0,0),imgui.ImVec2(1,0),imgui.ImVec2(1,1),imgui.ImVec2(0,1),rgba(1,1,1,1))
        else
            dl:AddCircleFilled(imgui.ImVec2(dCx,dCy),dSz/2,rgbaT(th.accent),32)
        end

        local track=PLAYLIST[curTrack]
        local infoX=wp.x+dSz+dPad*2
        local btnR=14*MDS; local playR2=18*MDS
        local rightEdge=wp.x+mw-10*MDS
        local nxX=rightEdge-btnR
        local plX=nxX-btnR-8*MDS-playR2
        local pvX=plX-playR2-8*MDS-btnR
        local maxTW=pvX-btnR-8*MDS-infoX
        local tit=track and track.title or '---'
        while imgui.CalcTextSize(tit).x>maxTW and #tit>1 do tit=tit:sub(1,-2) end
        if tit~=(track and track.title or '---') then tit=tit:sub(1,-2)..'..' end
        local btnY=wp.y+mh/2-2*MDS
        imgui.SetCursorScreenPos(imgui.ImVec2(infoX,wp.y+mh/2-12*MDS))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
        imgui.Text(tit)
        imgui.PopStyleColor()
        local timeStr=fmt(el)..(realDur>0 and ' / '..fmt(realDur) or '')
        imgui.SetCursorScreenPos(imgui.ImVec2(infoX,wp.y+mh/2+2*MDS))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
        imgui.Text(timeStr)
        imgui.PopStyleColor()

        local hNx2=(mp.x-nxX)^2+(mp.y-btnY)^2<(btnR+3)^2
        dl:AddCircleFilled(imgui.ImVec2(nxX,btnY),btnR,hNx2 and rgba(.30,.30,.30,1) or rgba(.16,.16,.16,1))
        local nxIco3=fa['FORWARD_STEP']; local nxIsz3=imgui.CalcTextSize(nxIco3)
        dl:AddText(imgui.ImVec2(nxX-nxIsz3.x/2,btnY-nxIsz3.y/2),rgba(1,1,1,1),nxIco3)
        imgui.SetCursorScreenPos(imgui.ImVec2(nxX-btnR,btnY-btnR))
        if imgui.InvisibleButton('##mnx',imgui.ImVec2(btnR*2,btnR*2)) then nextTrack() end

        local hPl2=(mp.x-plX)^2+(mp.y-btnY)^2<playR2^2
        dl:AddCircleFilled(imgui.ImVec2(plX,btnY),playR2,hPl2 and rgbaT(th.accentH) or rgbaT(th.accent))
        if isPlaying then
            local bw2,bh2=3*MDS,9*MDS
            dl:AddRectFilled(imgui.ImVec2(plX-bw2*1.5,btnY-bh2/2),imgui.ImVec2(plX-bw2*.3,btnY+bh2/2),rgba(0,0,0,1))
            dl:AddRectFilled(imgui.ImVec2(plX+bw2*.3,btnY-bh2/2),imgui.ImVec2(plX+bw2*1.5,btnY+bh2/2),rgba(0,0,0,1))
        else
            local ts2=7*MDS
            dl:AddTriangleFilled(imgui.ImVec2(plX-ts2*.4,btnY-ts2),imgui.ImVec2(plX+ts2*.9,btnY),imgui.ImVec2(plX-ts2*.4,btnY+ts2),rgba(0,0,0,1))
        end
        imgui.SetCursorScreenPos(imgui.ImVec2(plX-playR2,btnY-playR2))
        if imgui.InvisibleButton('##mpl',imgui.ImVec2(playR2*2,playR2*2)) then
            if isPlaying then pauseTrack() else if stream~=0 then resumeTrack() else playTrack(curTrack) end end
        end

        local hPv2=(mp.x-pvX)^2+(mp.y-btnY)^2<(btnR+3)^2
        dl:AddCircleFilled(imgui.ImVec2(pvX,btnY),btnR,hPv2 and rgba(.30,.30,.30,1) or rgba(.16,.16,.16,1))
        local pvIco2=fa['BACKWARD_STEP']; local pvIsz2=imgui.CalcTextSize(pvIco2)
        dl:AddText(imgui.ImVec2(pvX-pvIsz2.x/2,btnY-pvIsz2.y/2),rgba(1,1,1,1),pvIco2)
        imgui.SetCursorScreenPos(imgui.ImVec2(pvX-btnR,btnY-btnR))
        if imgui.InvisibleButton('##mpv',imgui.ImVec2(btnR*2,btnR*2)) then prevTrack() end

        local dragZoneW=dSz+dPad*2+4*MDS
        local dIco = fa['UP_DOWN_LEFT_RIGHT']
        local dIsz = imgui.CalcTextSize(dIco)
        local dIconX = wp.x + dragZoneW/2 - dIsz.x/2
        local dIconY = wp.y + mh/2 - dIsz.y/2
        local hovDrag = mp.x>=wp.x and mp.x<=wp.x+dragZoneW and mp.y>=wp.y and mp.y<=wp.y+mh
        if miniDragMode then
            dl:AddText(imgui.ImVec2(dIconX,dIconY), rgba(th.accent[1],th.accent[2],th.accent[3],0.9), dIco)
        elseif hovDrag then
            dl:AddText(imgui.ImVec2(dIconX,dIconY), rgba(1,1,1,0.35), dIco)
        end
        imgui.SetCursorScreenPos(imgui.ImVec2(wp.x, wp.y))
        if imgui.InvisibleButton('##mdrag', imgui.ImVec2(dragZoneW, mh)) then
            miniDragMode = not miniDragMode
            if miniDragMode then
                sampAddChatMessage('[Spotify] \xd2\xe0\xf9\xe8 \xec\xe8\xed\xe8-\xef\xeb\xe5\xe5\xf0. \xd2\xe0\xef \xe4\xeb\xff \xf4\xe8\xea\xf1\xe0\xf6\xe8\xe8.', 0x1DB954)
            end
        end

        imgui.SetCursorScreenPos(imgui.ImVec2(wp.x+dragZoneW,wp.y))
        local tapW=math.max(4*MDS, pvX-btnR-8*MDS-(wp.x+dragZoneW))
        if imgui.InvisibleButton('##mopen',imgui.ImVec2(tapW,mh-4*MDS)) then
            if not miniDragMode then showMenu[0]=true end
        end

        dl:PopClipRect()
        imgui.End()
    end
)

local wW=360*MDS; local wH=490*MDS

imgui.OnFrame(
    function() return showMenu[0] end,
    function(self)
        self.HideCursor=false
        applyStyle()

        if texNeed.logo and doesFileExist(logoPath) and not logoTex then
            logoTex=imgui.CreateTextureFromFile(logoPath); texNeed.logo=false end
        if texNeed.disc and doesFileExist(discPath) and not discTex then
            discTex=imgui.CreateTextureFromFile(discPath); texNeed.disc=false end

        if isPlaying then
            discAngle=discAngle+DISC_SPEED
            if discAngle>math.pi*2 then discAngle=discAngle-math.pi*2 end
        end

        if showMenu[0] and not showMenuPrev then
            loadLikes()
            loadUserPlaylists(); scanLocalFiles(); rebuildPlaylists(); loadPlaylist(curPlaylist)
            curTrack=math.max(1,math.min(#PLAYLIST,curTrack))
            listScroll=0; likedScroll=0; plScroll=0
            ffi.copy(searchBuf,''); searchStr=''; showNewPlForm=false; showAddForm=false; ctxMenu.open=false
            fetchSheetsAsync()
        end
        showMenuPrev=showMenu[0]

        local th=T()
        imgui.SetNextWindowSize(imgui.ImVec2(wW,wH),imgui.Cond.Always)
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2-wW/2,sh/2-wH/2),imgui.Cond.FirstUseEver)
        local wf=imgui.WindowFlags.NoTitleBar+imgui.WindowFlags.NoResize
                +imgui.WindowFlags.NoScrollbar+imgui.WindowFlags.NoScrollWithMouse
                +(sbAnyDrag and imgui.WindowFlags.NoMove or 0)
        if not imgui.Begin('##sp',showMenu,wf) then imgui.End(); return end

        local dl=imgui.GetWindowDrawList()
        local wp=imgui.GetWindowPos(); local ww=imgui.GetWindowWidth(); local wh_=imgui.GetWindowHeight()
        local mp=imgui.GetIO().MousePos

        dl:AddRectFilled(wp,imgui.ImVec2(wp.x+ww,wp.y+wh_),rgbaT(th.winBg),18*MDS)

        local topH=48*MDS
        dl:AddRectFilled(wp,imgui.ImVec2(wp.x+ww,wp.y+topH),rgbaT(th.topBg),18*MDS,3)
        dl:AddRectFilled(imgui.ImVec2(wp.x,wp.y+topH-18*MDS),imgui.ImVec2(wp.x+ww,wp.y+topH),rgbaT(th.topBg))

        local lsz=28*MDS; local lszW=36*MDS; local lx=wp.x+12*MDS; local ly=wp.y+(topH-lsz)/2
        if logoTex then
            imgui.SetCursorScreenPos(imgui.ImVec2(lx,ly)); imgui.Image(logoTex,imgui.ImVec2(lszW,lsz))
        else
            dl:AddCircleFilled(imgui.ImVec2(lx+lsz/2,ly+lsz/2),lsz/2,rgbaT(th.accent))
        end
        imgui.SetCursorScreenPos(imgui.ImVec2(lx+lszW+7*MDS,ly+lsz/2-7*MDS))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(th.text[1],th.text[2],th.text[3],1))
        imgui.Text('Spotify')
        imgui.PopStyleColor()

        local bsz=28*MDS; local bx=wp.x+ww-bsz-10*MDS; local by_=wp.y+(topH-bsz)/2
        local hX=mp.x>=bx and mp.x<=bx+bsz and mp.y>=by_ and mp.y<=by_+bsz
        dl:AddRectFilled(imgui.ImVec2(bx,by_),imgui.ImVec2(bx+bsz,by_+bsz),hX and rgba(.85,.10,.10,1) or rgba(.25,.25,.25,.8),6*MDS)
        local xp=7*MDS
        dl:AddLine(imgui.ImVec2(bx+xp,by_+xp),imgui.ImVec2(bx+bsz-xp,by_+bsz-xp),rgba(1,1,1,1),2)
        dl:AddLine(imgui.ImVec2(bx+bsz-xp,by_+xp),imgui.ImVec2(bx+xp,by_+bsz-xp),rgba(1,1,1,1),2)
        imgui.SetCursorScreenPos(imgui.ImVec2(bx,by_))
        if imgui.InvisibleButton('##cl',imgui.ImVec2(bsz,bsz)) then showMenu[0]=false end

        local mnBW=38*MDS; local mnBH=20*MDS
        local mnBX=bx-mnBW-6*MDS; local mnBY=wp.y+(topH-mnBH)/2
        local hMn=mp.x>=mnBX and mp.x<=mnBX+mnBW and mp.y>=mnBY and mp.y<=mnBY+mnBH
        dl:AddRectFilled(imgui.ImVec2(mnBX,mnBY),imgui.ImVec2(mnBX+mnBW,mnBY+mnBH),
            showMini and rgbaT(th.accent) or (hMn and rgba(.28,.28,.28,1) or rgba(.18,.18,.18,.9)), 6*MDS)
        if not showMini then
            dl:AddRect(imgui.ImVec2(mnBX,mnBY),imgui.ImVec2(mnBX+mnBW,mnBY+mnBH),rgbaT(th.accent),6*MDS,0,1.2)
        end
        local mnL='Mini'; local mnLsz=imgui.CalcTextSize(mnL)
        imgui.SetCursorScreenPos(imgui.ImVec2(mnBX+mnBW/2-mnLsz.x/2,mnBY+mnBH/2-mnLsz.y/2))
        imgui.PushStyleColor(imgui.Col.Text, showMini
            and imgui.ImVec4(0,0,0,1)
            or  imgui.ImVec4(th.accent[1],th.accent[2],th.accent[3],1))
        imgui.Text(mnL)
        imgui.PopStyleColor()
        imgui.SetCursorScreenPos(imgui.ImVec2(mnBX,mnBY))
        if imgui.InvisibleButton('##mn',imgui.ImVec2(mnBW,mnBH)) then showMini=not showMini end

        local thBW=42*MDS; local thBH=20*MDS
        local thBX=mnBX-thBW-6*MDS; local thBY=wp.y+(topH-thBH)/2
        local hTh=mp.x>=thBX and mp.x<=thBX+thBW and mp.y>=thBY and mp.y<=thBY+thBH
        dl:AddRectFilled(imgui.ImVec2(thBX,thBY),imgui.ImVec2(thBX+thBW,thBY+thBH),
            hTh and rgbaT(th.accentH) or rgbaT(th.accent),5*MDS)
        local nextTh=(curTheme % #THEMES)+1
        local tnm=THEMES[nextTh].name; local tnsz=imgui.CalcTextSize(tnm)
        imgui.SetCursorScreenPos(imgui.ImVec2(thBX+thBW/2-tnsz.x/2,thBY+thBH/2-tnsz.y/2))
        imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(0,0,0,1))
        imgui.Text(tnm); imgui.PopStyleColor()
        imgui.SetCursorScreenPos(imgui.ImVec2(thBX,thBY))
        if imgui.InvisibleButton('##th',imgui.ImVec2(thBW,thBH)) then
            curTheme=nextTh; config.settings.theme=curTheme; saveConfig()
        end

        local tabY=wp.y+topH+2*MDS; local tabH=28*MDS
        local tabs={fa['PLAY'],fa['LIST_UL']..' List',fa['HEART'],fa['RECORD_VINYL']..' Lists',ICO_INFO}
        local tabW=ww/#tabs
        for i,name in ipairs(tabs) do
            local tx=wp.x+(i-1)*tabW; local act=(page==i)
            dl:AddRectFilled(imgui.ImVec2(tx,tabY),imgui.ImVec2(tx+tabW,tabY+tabH),act and rgbaT(th.tabAct) or rgba(0,0,0,0))
            if act then dl:AddRectFilled(imgui.ImVec2(tx+4*MDS,tabY+tabH-3*MDS),imgui.ImVec2(tx+tabW-4*MDS,tabY+tabH),rgbaT(th.accent),2*MDS) end
            imgui.SetCursorScreenPos(imgui.ImVec2(tx,tabY))
            if imgui.InvisibleButton('##t'..i,imgui.ImVec2(tabW,tabH)) then page=i end
            local tsz=imgui.CalcTextSize(name)
            imgui.SetCursorScreenPos(imgui.ImVec2(tx+tabW/2-tsz.x/2,tabY+tabH/2-tsz.y/2))
            imgui.PushStyleColor(imgui.Col.Text, act
                and imgui.ImVec4(th.text[1],th.text[2],th.text[3],1)
                or  imgui.ImVec4(th.textDim[1],th.textDim[2],th.textDim[3],1))
            imgui.Text(name)
            imgui.PopStyleColor()
        end

        local cY=tabY+tabH+4*MDS; local cH=wh_-(cY-wp.y)-4*MDS
        local cp2=imgui.ImVec2(wp.x, cY)
        local cw2=ww
        if     page==1 then drawPlayer(cp2,dl,cw2,cH,mp)
        elseif page==2 then drawPlaylistPage(cp2,dl,cw2,cH,mp)
        elseif page==3 then drawLikedPage(cp2,cw2,cH)
        elseif page==4 then drawPlaylistsPage(cp2,dl,cw2,cH,mp)
        else                drawInfoPage(cp2,dl,cw2,cH,mp) end
        imgui.End()
    end
)

function main()
    while not isSampAvailable() do wait(100) end
    sampRegisterChatCommand('spotify', function() showMenu[0]=not showMenu[0] end)
    while not sampIsLocalPlayerSpawned() do wait(100) end
    wait(300)
    fetchSheetsAsync()
    sampAddChatMessage('[Spotify] \xc7\xe0\xe3\xf0\xf3\xe7\xe8\xeb\xf1\xff | /spotify', 0x1DB954)
    while true do
        wait(500)
        if isPlaying and bass and stream~=0 then
            local act=0
            pcall(function() act=tonumber(bass.BASS_ChannelIsActive(stream)) end)
            if act==0 then
                if repeatMode==1 then playTrack(curTrack) else nextTrack() end
            end
        end
        -- sleep timer: auto-pause when the deadline passes
        if sleepMinutes>0 and sleepDeadline>0 and os.time()>=sleepDeadline then
            sleepMinutes=0; sleepDeadline=0
            if isPlaying then pauseTrack() end
            sampAddChatMessage('[Spotify] Sleep timer: paused', 0x1DB954)
        end
    end
end
