script_name("NexaArizona v1.5.5")
script_author("NexaCFG")
script_version("1.5.5")
script_properties("work-in-pause")

slot0 = require("mimgui")
slot1 = require("vkeys")
slot2 = require("lib.samp.events")
slot3 = require("encoding")
slot4 = require("dkjson")
slot5 = require("memory")
slot6 = require("ffi")
slot7 = require("fAwesome5")
slot8 = require("lib.samp.events.bitstream_io")
slot9 = require("effil")
slot10 = require("RenderScreenBuffer")

slot6.cdef([[
    long D3DXSaveTextureToFileA(
        const char* pDestFile,
        int DestFormat,
        void* pSrcTexture,
        const void* pSrcPalette
    );
]])

slot11 = slot6.load(("%s\\d3dx9_25.dll"):format(getFolderPath(37)))
slot12, slot13 = pcall(require, "navmesh.navmesh")

if not slot12 then
	slot13 = nil
end

slot14, slot15 = pcall(require, "navmesh.render")

if not slot14 then
	slot15 = nil
end

slot3.default = "CP1251"
slot16 = slot3.UTF8
slot18 = getWorkingDirectory() .. "\\config\\NexaArizona\\" .. "NexaArizona.json"
slot19 = getWorkingDirectory() .. "\\resource\\NexaArizona\\"
slot20 = {}
slot21 = slot0.new
slot22 = slot0.new.bool(true)
slot23 = 0
slot24 = false
slot25 = ""
slot26 = false
slot27, slot28 = nil
slot29 = false
slot30 = renderCreateFont("Arial", 10, 5)
slot31 = false
slot32 = "1.5.5"
slot33 = slot16("\\xd1\\xf2\\xe0\\xf2\\xf3\\xf1: \\xcf\\xf0\\xee\\xe2\\xe5\\xf0\\xea\\xe0...")
slot34 = false
slot35 = ""
slot36 = "https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/main/versions.txt"
slot37 = "https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/main/NexaArizona_v1_5_5.luac"
slot38 = 0
slot39 = {
	path_building = false,
	min_radius = 8,
	update_tick = 0,
	cam_angle = 0,
	full_idx = 1,
	last_pz = 0,
	segment_size = 12,
	stuck_ticks = 0,
	extend_dist = 5,
	CHECK_INTERVAL = 2,
	smart_filter = true,
	last_check = 0,
	last_stuck_action = 0,
	last_px = 0,
	path_index = 1,
	last_py = 0,
	max_radius = 18,
	MIN_MOVE_DIST = 0.5,
	full_path = {},
	turn_state = {
		intensity = 0,
		lastChange = 0,
		dir = 0,
		untilTime = 0
	}
}
slot40 = slot9.channel()

function slot41(slot0, slot1, slot2)
	slot6, slot7 = pcall(require("ssl.https").request, "https://api.telegram.org/bot" .. slot0 .. "/sendMessage", "chat_id=" .. slot1 .. "&text=" .. slot2:gsub("([^%w %-%_%.%~])", function (slot0)
		return string.format("%%%02X", string.byte(slot0))
	end):gsub(" ", "+"))

	if slot6 then
		return {
			true,
			slot7
		}
	else
		return {
			false,
			slot7
		}
	end
end

function slot42(slot0, slot1)
	slot4, slot5 = pcall(require("ssl.https").request, "https://api.telegram.org/bot" .. slot0 .. "/getUpdates?timeout=5&offset=" .. tostring(slot1 or 0))

	if slot4 then
		return {
			true,
			slot5
		}
	else
		return {
			false,
			slot5
		}
	end
end

slot43 = {
	timeout = 5,
	active = false,
	start_time = 0
}
slot44 = {
	enabled = false,
	list = {}
}
slot45 = {
	nick = "",
	eating_in_progress = false
}
slot46 = false
slot47 = false
slot48 = false
slot49 = {
	value = 0,
	frames = 0,
	last_tick = os.clock()
}
slot50 = {
	wait_start = 0,
	waiting_at_target = false,
	last_scan = 0,
	last_roam_stop = 0,
	wp_idx = 1,
	start_time = 0,
	scan_interval = 0.5,
	active = false,
	roam_waypoints = {}
}
slot51 = {
	slot16("\\xd7\\xe8\\xef\\xf1\\xfb"),
	slot16("\\xd0\\xfb\\xe1\\xe0"),
	slot16("\\xce\\xeb\\xe5\\xed\\xe8\\xed\\xe0"),
	slot16("\\xcc\\xe5\\xf8\\xee\\xea \\xf1 \\xec\\xff\\xf1\\xee\\xec")
}

for slot56 = 0, #slot51 - 1 do
	slot0.new("const char*[?]", #slot51)[slot56] = slot51[slot56 + 1]
end

slot53 = {
	target_z = 0,
	stuck_count = 0,
	target_y = 0,
	offset_y = 0,
	offset_x = 0,
	stuck_check_time = 0,
	target_x = 0,
	waiting_for_grow = false,
	sync_enabled = false,
	path_node_index = 1,
	active = false,
	wait_start_time = 0
}
slot54 = {
	"?",
	"\\xfd\\xec",
	"\\xfd\\xec\\xec",
	"\\xf5\\xec",
	"\\xfd\\xec?",
	"??",
	"\\xe0?",
	"\\xe0\\xe0\\xe0",
	"\\xee",
	"\\xee\\xea",
	"\\xf1\\xe5\\xea\\xf3\\xed\\xe4\\xf3",
	"\\xfd",
	"\\xf7\\xb8",
	"\\xe4\\xe0"
}
slot55 = false

function slot56()
end

function slot57(slot0)
	return uv0.encode(slot0)
end

function send_delay_chat_message(slot0)
	if uv0 then
		return
	end

	uv0 = true

	lua_thread.create(function ()
		wait(math.random(3000, 8000))

		slot0 = uv0 or uv1[math.random(#uv1)]

		sampSendChat(slot0)
		add_log("{FFCC00}[\\xc0\\xe2\\xf2\\xee-\\xf7\\xe0\\xf2] \\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xeb\\xe5\\xed\\xee: " .. slot0)
		wait(15000)

		uv2 = false
	end)
end

({
	active_tab = "Dashboard",
	window_open = slot21.bool(false),
	stats_window = slot21.bool(false),
	ignore_protection = slot21.bool(false),
	pause_bot = slot21.bool(false),
	farm = {
		last_skin_time = 0,
		last_jump_time = 0,
		target_timer = 0,
		status_bar = "\\xce\\xe6\\xe8\\xe4\\xe0\\xed\\xe8\\xe5",
		running = slot21.bool(false),
		collect_cotton = slot21.bool(true),
		collect_linen = slot21.bool(true),
		real_run = slot21.bool(true),
		anti_afk = slot21.bool(true),
		auto_eat = slot21.bool(false),
		eat_method = slot21.int(0),
		eat_percent = slot21.int(20),
		smart_pause = slot21.bool(true),
		anti_slap = slot21.bool(true),
		telegram_logs = slot21.bool(true),
		anti_freeze = slot21.bool(true),
		auto_answer = slot21.bool(false),
		antadmin_autooff = slot21.bool(true),
		antadmin_stop_on_tp = slot21.bool(true),
		antadmin_tg = slot21.bool(true),
		antadmin_tg_all = slot21.bool(false),
		antadmin_safeexit = slot21.bool(false),
		antadmin_skipdialog = slot21.bool(false),
		res_counter = {
			cotton = 0,
			rare = 0,
			linen = 0
		},
		stats = {
			start_time = 0
		},
		anti_stuck_jump = slot21.bool(true),
		auto_jump = slot21.bool(false),
		auto_skin = slot21.bool(false),
		auto_skin_interval = slot21.int(5),
		delay_chat_on_tp = slot21.bool(true),
		cj_run = slot21.bool(false),
		inf_run = slot21.bool(false),
		anti_hunger_sprint = slot21.bool(false),
		chat_filter = slot21.bool(true),
		alarm_enabled = slot21.bool(false),
		alarm_url = slot21.char[256](""),
		alarm_volume = slot21.float(0.5),
		navmesh_render_mesh = slot21.bool(false),
		navmesh_render_path = slot21.bool(true),
		prot_teleport = slot21.bool(true),
		prot_admin_msg = slot21.bool(true),
		prot_dialog = slot21.bool(true),
		prot_spawn = slot21.bool(true),
		prot_anti_slap = slot21.bool(true),
		ai_window = slot21.bool(false),
		prot_fake_roam = slot21.bool(true),
		prot_skip_busy_bush = slot21.bool(true),
		prot_veh_check = slot21.bool(true),
		prot_admin_3d = slot21.bool(false),
		disable_splash = slot21.bool(false),
		menu_bind_key = slot21.int(78)
	},
	ai = {
		enabled = slot21.bool(false),
		api_key = slot21.char[256](""),
		base_url = slot21.char[256]("https://api.openai.com/v1/chat/completions"),
		model_id = slot21.char[128]("gpt-3.5-turbo"),
		user_query = slot21.char[512]("")
	},
	telegram = {
		last_update_id = 0,
		enabled = slot21.bool(false),
		token = slot21.char[128](""),
		chat_id = slot21.char[64]("")
	},
	options = {
		screen_timer_enabled = slot21.bool(false),
		screen_interval = slot21.int(10),
		last_screen_time = os.time()
	},
	calc = {
		price_cotton = slot21.float(0),
		price_linen = slot21.float(0),
		price_rare = slot21.float(0),
		price_coal = slot21.float(0)
	},
	theme = {
		accent = slot21.float[4](0.2, 0.55, 1, 0.75),
		global_alpha = slot21.float(0.95),
		bot_bind_key = slot21.int(78)
	},
	log_lines = {},
	ma = {
		enabled = slot21.bool(false),
		new_nick_buf = slot21.char[64]("")
	},
	timer = {
		startTime = 0,
		enabled = slot21.bool(false),
		hours = slot21.float(0),
		minutes = slot21.float(0)
	},
	donators_open = slot21.bool(false),
	cleaner = {
		enabled = slot21.bool(false),
		limit = slot21.int(512),
		notificationsEnabled = slot21.bool(true)
	}
}).farm.status_messages = {
	IDLE = {
		text = "\\xce\\xe6\\xe8\\xe4\\xe0\\xed\\xe8\\xe5",
		color = slot0.ImVec4(0.7, 0.7, 0.7, 1)
	},
	RUNNING = {
		text = "\\xd0\\xe0\\xe1\\xee\\xf2\\xe0\\xe5\\xf2",
		color = slot0.ImVec4(0.1, 0.8, 0.1, 1)
	},
	PAUSED = {
		text = "\\xcd\\xe0 \\xef\\xe0\\xf3\\xe7\\xe5",
		color = slot0.ImVec4(1, 0.6, 0, 1)
	},
	COLLECTING = {
		text = "\\xd1\\xee\\xe1\\xe8\\xf0\\xe0\\xe5\\xf2 \\xf0\\xe5\\xf1\\xf3\\xf0\\xf1",
		color = slot0.ImVec4(0.2, 0.7, 1, 1)
	},
	STUCK = {
		text = "\\xc7\\xe0\\xf1\\xf2\\xf0\\xff\\xeb",
		color = slot0.ImVec4(1, 0.2, 0.2, 1)
	},
	ERROR = {
		text = "\\xce\\xf8\\xe8\\xe1\\xea\\xe0",
		color = slot0.ImVec4(1, 0.1, 0.1, 1)
	},
	ROAMING = {
		text = "\\xc8\\xf9\\xe5\\xf2 \\xeb\\xf3\\xf7\\xf8\\xe8\\xe9 \\xea\\xf3\\xf1\\xf2",
		color = slot0.ImVec4(0.9, 0.8, 0.1, 1)
	},
	IN_VEHICLE = {
		text = "\\xc2 \\xf2\\xf0\\xe0\\xed\\xf1\\xef\\xee\\xf0\\xf2\\xe5",
		color = slot0.ImVec4(1, 0.3, 0.3, 1)
	}
}

function slot59()
	if uv0.GetCurrentContext() == nil then
		return
	end

	slot0 = uv0.GetStyle()
	slot1 = slot0.Colors
	slot4 = uv0.ImVec4(uv1.theme.accent[0], uv1.theme.accent[1], uv1.theme.accent[2], 1)
	slot1[uv0.Col.WindowBg] = uv0.ImVec4(0.07, 0.07, 0.08, 0.96)
	slot1[uv0.Col.ChildBg] = uv0.ImVec4(0.12, 0.12, 0.14, 0.5)
	slot1[uv0.Col.Text] = uv0.ImVec4(1, 1, 1, 1)
	slot1[uv0.Col.FrameBg] = uv0.ImVec4(0.14, 0.14, 0.16, 1)
	slot1[uv0.Col.FrameBgHovered] = uv0.ImVec4(0.18, 0.18, 0.2, 1)
	slot1[uv0.Col.Button] = uv0.ImVec4(0.14, 0.14, 0.16, 1)
	slot1[uv0.Col.ButtonHovered] = uv0.ImVec4(0.2, 0.2, 0.23, 1)
	slot1[uv0.Col.CheckMark] = slot4
	slot1[uv0.Col.SliderGrab] = slot4
	slot1[uv0.Col.SliderGrabActive] = slot4
	slot1[uv0.Col.Header] = uv0.ImVec4(slot4.x, slot4.y, slot4.z, 0.3)
	slot1[uv0.Col.Border] = uv0.ImVec4(0.15, 0.15, 0.15, 0.5)
	slot1[uv0.Col.Separator] = slot1[uv0.Col.Border]
	slot0.WindowRounding = 8
	slot0.ChildRounding = 6
	slot0.FrameRounding = 5
end

slot0.OnInitialize(function ()
	slot0 = uv0.ImFontConfig()
	slot0.GlyphExtraSpacing.x = 0.5
	slot1 = uv0.GetIO().Fonts:GetGlyphRangesCyrillic()
	slot3 = getFolderPath(20) .. "\\"

	uv0.GetIO().Fonts:AddFontFromFileTTF(slot3 .. "arialbd.ttf", 16, slot0, slot1)

	slot4 = uv0.ImFontConfig()
	slot4.MergeMode = true
	icons_font = uv0.GetIO().Fonts:AddFontFromFileTTF("moonloader/resource/fonts/fa-solid-900.ttf", 14, slot4, uv0.new.ImWchar[3](uv1.min_range, uv1.max_range, 0))
	font24 = uv0.GetIO().Fonts:AddFontFromFileTTF(slot3 .. "arialbd.ttf", 26, slot0, slot1)
	font20 = uv0.GetIO().Fonts:AddFontFromFileTTF(slot3 .. "arialbd.ttf", 22, slot0, slot1)
	font18 = uv0.GetIO().Fonts:AddFontFromFileTTF(slot3 .. "arialbd.ttf", 19, slot0, slot1)

	uv2()
end)

function slot60(slot0)
	return slot0:gsub("{%x%x%x%x%x%x}", "")
end

function slot61(slot0)
	if not slot0 then
		return ""
	end

	return slot0:gsub("\n", "\r\n"):gsub("([^%w %-%_%.%~])", function (slot0)
		return string.format("%%%02X", string.byte(slot0))
	end):gsub(" ", "+")
end

function slot62(slot0)
	for slot7 = 1, #string.format("%.0f", math.floor(slot0)) do
		if slot3 - slot7 > 0 and slot8 % 3 == 0 then
			slot2 = "" .. slot1:sub(slot7, slot7) .. "."
		end
	end

	return slot2
end

function slot63(slot0, slot1, slot2, slot3, slot4, slot5)
	if not slot0 or not slot1 or not slot2 or not slot3 or not slot4 or not slot5 then
		return 9999
	end

	slot6 = slot0 - slot3
	slot7 = slot1 - slot4
	slot8 = slot2 - slot5

	return math.sqrt(slot6 * slot6 + slot7 * slot7 + slot8 * slot8)
end

function slot64(slot0, slot1, slot2, slot3)
	slot4 = slot2 - slot0
	slot5 = slot3 - slot1

	return math.sqrt(slot4 * slot4 + slot5 * slot5)
end

function fix(slot0)
	while math.pi < slot0 do
		slot0 = slot0 - math.pi * 2
	end

	while slot0 < -math.pi do
		slot0 = slot0 + math.pi * 2
	end

	return slot0
end

function slot65(slot0)
	if slot0:find("\\xd5\\xeb\\xee\\xef\\xee\\xea") then
		return "cotton"
	end

	if slot0:find("˸\\xed") then
		return "linen"
	end

	return nil
end

function slot66()
	if uv0.pause_bot[0] then
		return uv0.farm.status_messages.PAUSED
	end

	if isCharInAnyCar(uv1.ped) then
		return uv0.farm.status_messages.IN_VEHICLE
	end

	if not uv0.farm.running[0] then
		return uv0.farm.status_messages.IDLE
	end

	if uv2.active then
		return uv0.farm.status_messages.ROAMING
	end

	if uv3 then
		return uv0.farm.status_messages.COLLECTING
	end

	if uv4.stuck_count >= 3 then
		return uv0.farm.status_messages.STUCK
	end

	if uv4.active then
		return uv0.farm.status_messages.RUNNING
	end

	return uv0.farm.status_messages.IDLE
end

function slot67()
	if uv0.farm.stats.start_time > 0 and uv0.farm.running[0] then
		slot0 = os.time() - uv0.farm.stats.start_time

		return string.format("%02d:%02d:%02d", math.floor(slot0 / 3600), math.floor(slot0 % 3600 / 60), slot0 % 60)
	end

	return "00:00:00"
end

function slot68(slot0)
	for slot5, slot6 in ipairs({
		"\\xce\\xe1\\xed\\xe0\\xf0\\xf3\\xe6\\xe5\\xed\\xee",
		"\\xe0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0",
		"\\xc7\\xe0\\xe2\\xe5\\xf0\\xf8\\xe5\\xed\\xee",
		"\\xc2\\xcd\\xc8\\xcc\\xc0\\xcd\\xc8\\xc5",
		"\\xce\\xf8\\xe8\\xe1\\xea\\xe0",
		"\\xc7\\xc0\\xd9\\xc8\\xd2\\xc0",
		"\\xcf\\xe0\\xf3\\xe7\\xe0",
		"\\xcf\\xe5\\xf0\\xe5\\xf0\\xfb\\xe2",
		"\\xcc\\xc8\\xd0",
		"FENCE"
	}) do
		if slot0:find(slot6) then
			return true
		end
	end

	return false
end

function checkUpdate(slot0)
	if slot0 then
		uv0 = uv1("\\xd1\\xf2\\xe0\\xf2\\xf3\\xf1: \\xcf\\xf0\\xee\\xe2\\xe5\\xf0\\xea\\xe0...")
	end

	downloadUrlToFile(uv2, os.getenv("TEMP") .. "\\nexa_version.txt", function (slot0, slot1)
		if slot1 == 6 then
			if io.open(os.getenv("TEMP") .. "\\nexa_version.txt", "r") then
				slot2:close()
				os.remove(os.getenv("TEMP") .. "\\nexa_version.txt")

				if slot2:read("*a"):gsub("%s+", "") ~= uv0 then
					uv1 = true
					uv2 = slot3
					uv3 = uv4("\\xc4\\xee\\xf1\\xf2\\xf3\\xef\\xed\\xee: ") .. slot3

					add_log("{33CCFF}[Update] \\xcd\\xe0\\xe9\\xe4\\xe5\\xed\\xee \\xee\\xe1\\xed\\xee\\xe2\\xeb\\xe5\\xed\\xe8\\xe5: " .. slot3)
				else
					uv1 = false
					uv3 = uv4("\\xd3 \\xe2\\xe0\\xf1 \\xe0\\xea\\xf2\\xf3\\xe0\\xeb\\xfc\\xed\\xe0\\xff \\xe2\\xe5\\xf0\\xf1\\xe8\\xff")
				end
			end
		elseif slot1 == -1 then
			uv3 = uv4("\\xce\\xf8\\xe8\\xe1\\xea\\xe0 \\xf1\\xe2\\xff\\xe7\\xe8 \\xf1 GitHub")
		end
	end)
end

function startUpdate()
	if uv0 == "" then
		uv1 = uv2("\\xce\\xf8\\xe8\\xe1\\xea\\xe0: \\xf1\\xf1\\xfb\\xeb\\xea\\xe0 \\xef\\xf3\\xf1\\xf2\\xe0")

		return
	end

	uv1 = uv2("\\xc7\\xe0\\xe3\\xf0\\xf3\\xe7\\xea\\xe0..")

	downloadUrlToFile(uv0, thisScript().path:gsub("%.lua$", ".luac"), function (slot0, slot1)
		if slot1 == 6 then
			add_log("{33FF33}[Update] \\xd1\\xea\\xee\\xec\\xef\\xe8\\xeb\\xe8\\xf0\\xee\\xe2\\xe0\\xed\\xed\\xfb\\xe9 \\xf1\\xea\\xf0\\xe8\\xef\\xf2 \\xe7\\xe0\\xe3\\xf0\\xf3\\xe6\\xe5\\xed!")

			if uv0:find("%.lua$") and uv1:find("%.luac$") then
				os.remove(uv0)
			end

			add_log("{33FF33}[Update] \\xcf\\xe5\\xf0\\xe5\\xe7\\xe0\\xe3\\xf0\\xf3\\xe7\\xea\\xe0...")
			thisScript():reload()
		elseif slot1 == -1 then
			uv2 = uv3("\\xce\\xf8\\xe8\\xe1\\xea\\xe0 \\xf1\\xea\\xe0\\xf7\\xe8\\xe2\\xe0\\xed\\xe8\\xff")
		end
	end)
end

lua_thread.create(function ()
	while not isSampAvailable() do
		wait(100)
	end

	checkUpdate(false)
	wait(500)

	slot0 = getWorkingDirectory() .. "\\lib\\"
	slot2 = slot0 .. "RenderScreenBuffer\\"

	if not doesDirectoryExist(slot0 .. "navmesh\\") then
		createDirectory(slot1)
	end

	if not doesDirectoryExist(slot2) then
		createDirectory(slot2)
	end

	if not doesDirectoryExist(uv0) then
		createDirectory(uv0)
	end

	for slot7, slot8 in ipairs({
		{
			url = "https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/main/moonloader/lib/multipart-post.lua",
			path = slot0 .. "multipart-post.lua"
		},
		{
			url = "https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/main/moonloader/lib/navmesh/navmesh.lua",
			path = slot1 .. "navmesh.lua"
		},
		{
			url = "https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/main/moonloader/lib/navmesh/render.lua",
			path = slot1 .. "render.lua"
		},
		{
			url = "https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/main/moonloader/system_prompt.txt",
			path = uv0 .. "system_prompt.txt"
		},
		{
			url = "https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/main/moonloader/lib/RenderScreenBuffer/RenderScreenBuffer.dll",
			path = slot2 .. "RenderScreenBuffer.dll"
		},
		{
			url = "https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/main/moonloader/lib/RenderScreenBuffer/init.lua",
			path = slot2 .. "init.lua"
		}
	}) do
		if not doesFileExist(slot8.path) then
			downloadUrlToFile(slot8.url, slot8.path, function (slot0, slot1)
			end)
		end
	end

	if not doesFileExist(uv0 .. "menu_bg.png") then
		downloadUrlToFile("https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/refs/heads/main/privetmenu.png", slot4, function (slot0, slot1)
			if slot1 == 6 then
				uv0 = uv1.CreateTextureFromFile(uv2)
			end
		end)
	else
		uv1 = uv2.CreateTextureFromFile(slot4)
	end
end)

slot70 = "https://api.telegram.org" .. "/bot%s/%s"
slot71 = {
	timeout = 5,
	next_update_id = -1
}

function sendPhoto()
	if not uv0 then
		return
	end

	slot0 = uv1 .. "tg_screen.png"
	slot1 = uv0:get()

	lua_thread.create(function ()
		uv0.D3DXSaveTextureToFileA(uv1, 3, uv2, nil)
		wait(600)

		if not doesFileExist(uv1) then
			add_log("{FF3333}[\\xd1\\xea\\xf0\\xe8\\xed\\xf8\\xee\\xf2] \\xd4\\xe0\\xe9\\xeb \\xed\\xe5 \\xf1\\xee\\xe7\\xe4\\xe0\\xeb\\xf1\\xff.")

			return
		end

		if not uv3.telegram.enabled[0] then
			os.remove(uv1)

			return
		end

		slot1 = uv4.string(uv3.telegram.chat_id)

		if uv4.string(uv3.telegram.token) == "" or slot1 == "" then
			os.remove(uv1)

			return
		end

		slot2 = uv3.farm.stats.start_time > 0 and os.time() - uv3.farm.stats.start_time or 0
		slot4 = uv3.farm.res_counter

		telegramRequest(slot0, "sendPhoto", {
			parse_mode = "Markdown",
			disable_notification = "true",
			chat_id = slot1,
			caption = uv7(string.format("*\\xce\\xf2\\xf7\\xe5\\xf2 NexaArizona*\n\n" .. "*\\xcd\\xe8\\xea:* %s\n" .. "*\\xd5\\xeb\\xee\\xef\\xee\\xea:* %d\n" .. "*˸\\xed:* %d\n" .. "*\\xd0\\xe5\\xe4\\xea\\xe0\\xff \\xf2\\xea\\xe0\\xed\\xfc:* %d\n" .. "*\\xd3\\xe3\\xee\\xeb\\xfc:* %d\n\n" .. "*\\xcf\\xf0\\xe8\\xe1\\xfb\\xeb\\xfc:* %s $\n" .. "*\\xc2\\xf0\\xe5\\xec\\xff \\xf0\\xe0\\xe1\\xee\\xf2\\xfb:* %s", (uv5.nick or ""):gsub("_", " "), slot4.cotton, slot4.linen, slot4.rare, slot4.coal or 0, uv6(slot4.cotton * uv3.calc.price_cotton[0] + slot4.linen * uv3.calc.price_linen[0] + slot4.rare * uv3.calc.price_rare[0] + (slot4.coal or 0) * uv3.calc.price_coal[0]), string.format("%02d:%02d:%02d", math.floor(slot2 / 3600), math.floor(slot2 % 3600 / 60), slot2 % 60)))
		}, {
			photo = uv1
		})
		wait(2000)

		if doesFileExist(uv1) then
			os.remove(uv1)
		end
	end)
end

function cleanAPText(slot0)
	return tostring(slot0 or ""):gsub("{.-}", ""):gsub("\r", " "):gsub("\n", " "):gsub("%s+", " ")
end

function RequestAI(slot0, slot1)
	if not uv0.ai.enabled[0] or tostring(slot0 or "") == "" or uv1 or uv2.string(uv0.ai.api_key) == "" then
		return
	end

	uv1 = true

	add_log("{FFFF00}[\\xc8\\xc8] \\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xea\\xe0 \\xe7\\xe0\\xef\\xf0\\xee\\xf1\\xe0...")

	if not uv2.string(uv0.ai.base_url):gsub("/$", ""):find("/chat/completions") then
		slot2 = slot2 .. "/chat/completions"
	end

	slot3 = uv2.string(uv0.ai.api_key)
	slot4 = uv2.string(uv0.ai.model_id)
	slot6 = "You are a helpful assistant."

	if io.open(uv3 .. "system_prompt.txt", "r") then
		slot6 = slot7:read("*a")

		slot7:close()
	end

	slot9 = uv4.thread(function (slot0, slot1, slot2, slot3, slot4)
		slot5 = require("ssl.https")
		slot6 = require("ltn12")
		slot9 = require("dkjson").encode({
			temperature = 0.85,
			max_tokens = 64,
			model = slot2,
			messages = {
				{
					role = "system",
					content = slot3
				},
				{
					role = "user",
					content = slot4
				}
			}
		})
		slot11, slot12, slot13 = pcall(function ()
			return uv0.request({
				timeout = 10,
				verify = "none",
				method = "POST",
				url = uv1,
				headers = {
					["Content-Type"] = "application/json",
					Authorization = "Bearer " .. uv2,
					["Content-Length"] = tostring(#uv3)
				},
				source = uv4.source.string(uv3),
				sink = uv4.sink.table(uv5)
			})
		end)
		slot14 = table.concat({})

		if not slot11 then
			return false, tostring(slot12 or "request failed")
		end

		if tonumber(slot13) ~= 200 then
			return false, "HTTP " .. tostring(slot13 or "unknown")
		end

		if type(slot7.decode(slot14)) ~= "table" or not slot15.choices or not slot15.choices[1] then
			return false, "bad response"
		end

		return true, slot15.choices[1].message.content or slot15.choices[1].text
	end)(slot2, slot3, slot4, uv5:encode(slot6), uv5:encode(slot0:gsub("{.-}", "")))

	lua_thread.create(function ()
		slot0 = nil

		while true do
			if uv0:status() == "completed" then
				slot0 = {
					uv0:get()
				}

				break
			elseif slot1 == "failed" then
				slot0 = {
					false,
					"thread crashed"
				}

				break
			end

			wait(100)
		end

		if slot0 and slot0[1] then
			if uv2 then
				sampAddChatMessage("{00FF00}[Nexa AI]: {FFFFFF}" .. uv1:decode(slot0[2]):gsub("^/b%s+", ""):gsub("[%\"'`]", ""):trim(), -1)
			elseif uv3:lower():find("\\xe4\\xe8\\xe0\\xeb\\xee\\xe3") or uv3:lower():find("/b") then
				sampSendChat("/b " .. slot1)
			else
				sampSendChat(slot1)
			end

			if uv4.telegram.enabled[0] then
				send_telegram("\\xc8\\xc8 \\xee\\xf2\\xe2\\xe5\\xf2\\xe8\\xeb\n\\xce\\xf2\\xe2\\xe5\\xf2: " .. slot1)
			end
		else
			add_log("{FF3333}[AI] \\xce\\xf8\\xe8\\xe1\\xea\\xe0: " .. tostring(slot0[2]))
		end

		uv5 = false
	end)
end

function string.trim(slot0)
	return slot0:gsub("^%s*(.-)%s*$", "%1")
end

function piskaadminzabor()
	if not uv0.farm.prot_admin_3d[0] or not uv0.farm.running[0] or uv0.pause_bot[0] then
		return
	end

	slot0, slot1, slot2 = getCharCoordinates(uv1.ped)

	for slot6 = 0, 2048 do
		if sampIs3dTextDefined(slot6) then
			slot7, slot8, slot9, slot10, slot11, slot12, slot13, slot14, slot15 = sampGet3dTextInfoById(slot6)

			if getDistanceBetweenCoords3d(slot0, slot1, slot2, slot9, slot10, slot11) < 15 and (slot7:gsub("{%x+}", ""):find("\\xcf\\xee\\xf1\\xf2\\xe0\\xe2\\xe8\\xeb:") or slot17:find("Admin")) then
				uv0.pause_bot[0] = true
				uv2.active = false

				setGameKeyState(1, 0)

				if resetNavPath then
					resetNavPath()
				end

				add_log("{FF0000}[\\xc7\\xc0\\xd9\\xc8\\xd2\\xc0] \\xc7\\xe0\\xec\\xe5\\xf7\\xe5\\xed \\xe0\\xe4\\xec\\xe8\\xed-\\xf2\\xe5\\xea\\xf1\\xf2! \\xcf\\xe0\\xf3\\xe7\\xe0.")

				if uv0.telegram.enabled[0] then
					slot19 = uv3.string(uv0.telegram.chat_id)

					if #uv3.string(uv0.telegram.token) > 0 and #slot19 > 0 then
						uv4:push(slot18, slot19, string.format("[%s] \\xce\\xe1\\xed\\xe0\\xf0\\xf3\\xe6\\xe5\\xed \\xe0\\xe4\\xec\\xe8\\xed-\\xee\\xe1\\xfa\\xe5\\xea\\xf2!\n\\xd2\\xe5\\xea\\xf1\\xf2: %s\n\\xc4\\xe8\\xf1\\xf2\\xe0\\xed\\xf6\\xe8\\xff: %.1f\\xec", uv1.nick or "Bot", slot17, slot16))
					end
				end

				break
			end
		end
	end
end

function slot0.CustomButton(slot0, slot1, slot2, slot3, slot4)
	slot5 = uv0.Col

	uv0.PushStyleColor(slot5.Button, slot1)
	uv0.PushStyleColor(slot5.ButtonHovered, slot2)
	uv0.PushStyleColor(slot5.ButtonActive, slot3)
	uv0.PopStyleColor(3)

	return uv0.Button(slot0, slot4 or uv0.ImVec2(0, 0))
end

function slot72(slot0)
	return tostring(slot0 or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function slot73()
	if io.popen("dir \"" .. (os.getenv("USERPROFILE") .. "\\Documents\\GTA San Andreas User Files\\SAMP\\screens\\") .. "sa-mp-*.png\" /B /O-D") then
		slot1:close()

		if slot1:read("*l") then
			return slot0 .. slot2
		end
	end

	return nil
end

function sampTakeScreenshot()
	if getModuleHandle("samp.dll") == 0 then
		return
	end

	if ({
		[13356013.0] = 480752,
		[13389107.0] = 478432,
		[3268371.0] = 462784,
		[11529535.0] = 496688,
		[3249629.0] = 462912
	})[uv0.cast("unsigned int*", uv0.cast("intptr_t", slot0) + uv0.cast("int*", uv0.cast("intptr_t", slot0) + 60)[0] + 40)[0]] then
		uv0.cast("void (__cdecl *)(void)", slot0 + slot3[slot2])()
	else
		setGameKeyState(16, 255)
		lua_thread.create(function ()
			wait(50)
			setGameKeyState(16, 0)
		end)
	end
end

function slot0.CustomSliderFloat(slot0, slot1, slot2, slot3, slot4)
	function slot5()
		if uv0 and uv0.theme and uv0.theme.accent then
			return uv1.ImVec4(uv0.theme.accent[0], uv0.theme.accent[1], uv0.theme.accent[2], 1)
		end

		return uv1.ImVec4(0.2, 0.4, 0.8, 1)
	end

	slot6 = uv1.GetStyle()
	slot7 = uv1.GetWindowDrawList()
	slot8 = uv1.GetCursorScreenPos()
	slot9 = uv1.CalcTextSize(slot0)
	slot12 = uv1.ImVec2(200, 8)
	slot13 = 10
	slot14 = uv1.ImVec2(slot8.x + slot9.x + slot13, slot8.y + slot9.y / 2 - slot12.y / 2)
	slot15 = uv1.ImVec2(slot14.x + slot12.x, slot14.y + slot12.y)

	uv1.SetCursorScreenPos(slot8)
	uv1.InvisibleButton("##slider_" .. slot0, uv1.ImVec2(slot9.x + slot13 + slot12.x + uv1.CalcTextSize(string.format(slot4 or "%.0f", slot1[0])).x + 20, slot9.y))

	if uv1.IsItemActive() then
		slot1[0] = math.max(slot2, math.min(slot3, slot2 + (uv1.GetIO().MousePos.x - slot14.x) / slot12.x * (slot3 - slot2)))
	end

	slot18 = slot14.x + (slot1[0] - slot2) / (slot3 - slot2) * slot12.x
	slot19 = slot5()

	slot7:AddRectFilled(slot14, slot15, uv1.GetColorU32Vec4(uv1.ImVec4(0.12, 0.14, 0.18, 1)), 4)
	slot7:AddRectFilled(slot14, uv1.ImVec2(slot18, slot15.y), uv1.GetColorU32Vec4(uv1.ImVec4(slot19.x, slot19.y, slot19.z, 0.8)), 4)
	slot7:AddCircleFilled(uv1.ImVec2(slot18, slot14.y + slot12.y / 2), 6, uv1.GetColorU32Vec4(uv1.ImVec4(1, 1, 1, 1)))
	uv1.SetCursorScreenPos(slot8)
	uv1.Text(slot0)
	uv1.SetCursorScreenPos(uv1.ImVec2(slot15.x + 10, slot8.y))
	uv1.TextDisabled(slot10)

	return slot16
end

slot74 = {}

function slot75()
	lua_thread.create(function ()
		downloadUrlToFile("https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/refs/heads/main/donators.txt", getWorkingDirectory() .. "\\resource\\donators_temp.txt", function (slot0, slot1, slot2, slot3)
			if slot1 == 6 then
				if io.open(uv0, "r") then
					uv1 = {}

					for slot8 in slot4:lines() do
						if slot8:gsub("^%s*(.-)%s*$", "%1") ~= "" then
							table.insert(uv1, uv2:decode(slot9))
						end
					end

					slot4:close()
					os.remove(uv0)
					add_log("{33FF33}[\\xd1\\xe8\\xf1\\xf2\\xe5\\xec\\xe0] \\xd1\\xef\\xe8\\xf1\\xee\\xea \\xec\\xe5\\xf6\\xe5\\xed\\xe0\\xf2\\xee\\xe2 \\xee\\xe1\\xed\\xee\\xe2\\xeb\\xe5\\xed!")
				end
			elseif slot1 == 5 then
				add_log("{FF3333}[\\xd1\\xe8\\xf1\\xf2\\xe5\\xec\\xe0] \\xce\\xf8\\xe8\\xe1\\xea\\xe0 \\xe7\\xe0\\xe3\\xf0\\xf3\\xe7\\xea\\xe8 \\xf1\\xef\\xe8\\xf1\\xea\\xe0 \\xe4\\xee\\xed\\xe0\\xf2\\xe5\\xf0\\xee\\xe2.")
			end
		end)
	end)
end

function slot0.CustomCheckbox(slot0, slot1, slot2)
	slot3 = uv0.GetCursorScreenPos()
	slot4 = uv0.GetWindowDrawList()
	slot5 = slot0:gsub("##.+", "") or ""
	slot6 = uv0.GetTextLineHeightWithSpacing() + 2
	slot7 = slot2 or 0.2

	function slot8(slot0, slot1, slot2, slot3)
		if os.clock() - slot2 >= 0 and slot4 <= slot3 then
			slot5 = slot4 / (slot3 / 100)

			return uv0.ImVec2(slot0.x + slot5 * (slot1.x - slot0.x) / 100, slot0.y + slot5 * (slot1.y - slot0.y) / 100), true
		end

		return slot3 < slot4 and slot1 or slot0, false
	end

	function slot9(slot0, slot1, slot2, slot3)
		if os.clock() - slot2 >= 0 and slot4 <= slot3 then
			slot5 = slot4 / (slot3 / 100)

			return uv0.ImVec4(slot0.x + slot5 * (slot1.x - slot0.x) / 100, slot0.y + slot5 * (slot1.y - slot0.y) / 100, slot0.z + slot5 * (slot1.z - slot0.z) / 100, slot0.w + slot5 * (slot1.w - slot0.w) / 100), true
		end

		return slot3 < slot4 and slot1 or slot0, false
	end

	slot10 = {
		{
			0.185,
			0.428
		},
		{
			0.441,
			0.7
		},
		{
			0.388,
			0.7
		},
		{
			0.812,
			0.282
		}
	}

	if uv1[slot0] == nil then
		uv1[slot0] = {
			h_start = 0,
			hovered = false,
			lines = {
				{
					start = 0,
					anim = false,
					from = uv0.ImVec2(0, 0),
					to = uv0.ImVec2(slot6 * slot10[1][1], slot6 * slot10[1][2])
				},
				{
					start = 0,
					anim = false,
					from = uv0.ImVec2(0, 0),
					to = slot1[0] and uv0.ImVec2(slot6 * slot10[2][1], slot6 * slot10[2][2]) or uv0.ImVec2(slot6 * slot10[1][1], slot6 * slot10[1][2])
				},
				{
					start = 0,
					anim = false,
					from = uv0.ImVec2(0, 0),
					to = uv0.ImVec2(slot6 * slot10[3][1], slot6 * slot10[3][2])
				},
				{
					start = 0,
					anim = false,
					from = uv0.ImVec2(0, 0),
					to = slot1[0] and uv0.ImVec2(slot6 * slot10[4][1], slot6 * slot10[4][2]) or uv0.ImVec2(slot6 * slot10[3][1], slot6 * slot10[3][2])
				}
			}
		}
	end

	uv0.BeginGroup()
	uv0.InvisibleButton(slot0, uv0.ImVec2(slot6, slot6))
	uv0.SameLine()

	slot12 = uv0.GetCursorPos()

	uv0.SetCursorPos(uv0.ImVec2(slot12.x, slot12.y + slot6 / 2 - uv0.CalcTextSize(slot5).y / 2))
	uv0.Text(slot5)
	uv0.EndGroup()

	slot13 = uv0.IsItemClicked()

	if uv1[slot0].hovered ~= uv0.IsItemHovered() then
		slot11.hovered = uv0.IsItemHovered()
		slot11.h_start = slot7 >= os.clock() - slot11.h_start and slot14 >= 0 and os.clock() - (slot7 - slot14) or os.clock()
	end

	if slot13 then
		slot14 = false

		for slot18 = 1, 4 do
			if slot11.lines[slot18].anim then
				slot14 = true
			end
		end

		if not slot14 then
			slot1[0] = not slot1[0]
			slot11.lines[1].from = uv0.ImVec2(slot6 * slot10[1][1], slot6 * slot10[1][2])
			slot11.lines[1].to = slot1[0] and uv0.ImVec2(slot6 * slot10[1][1], slot6 * slot10[1][2]) or uv0.ImVec2(slot6 * slot10[2][1], slot6 * slot10[2][2])
			slot11.lines[1].start = slot1[0] and 0 or os.clock()
			slot11.lines[2].from = slot1[0] and uv0.ImVec2(slot6 * slot10[1][1], slot6 * slot10[1][2]) or uv0.ImVec2(slot6 * slot10[2][1], slot6 * slot10[2][2])
			slot11.lines[2].to = uv0.ImVec2(slot6 * slot10[2][1], slot6 * slot10[2][2])
			slot11.lines[2].start = slot1[0] and os.clock() or 0
			slot11.lines[3].from = uv0.ImVec2(slot6 * slot10[3][1], slot6 * slot10[3][2])
			slot11.lines[3].to = slot1[0] and uv0.ImVec2(slot6 * slot10[3][1], slot6 * slot10[3][2]) or uv0.ImVec2(slot6 * slot10[4][1], slot6 * slot10[4][2])
			slot11.lines[3].start = slot1[0] and 0 or os.clock() + slot7
			slot11.lines[4].from = slot1[0] and uv0.ImVec2(slot6 * slot10[3][1], slot6 * slot10[3][2]) or uv0.ImVec2(slot6 * slot10[4][1], slot6 * slot10[4][2])
			slot11.lines[4].to = uv0.ImVec2(slot6 * slot10[4][1], slot6 * slot10[4][2])
			slot11.lines[4].start = slot1[0] and os.clock() + slot7 or 0
		end
	end

	slot14 = {
		[slot18] = slot8(uv0.ImVec2(slot3.x + slot11.lines[slot18].from.x, slot3.y + slot11.lines[slot18].from.y), uv0.ImVec2(slot3.x + slot11.lines[slot18].to.x, slot3.y + slot11.lines[slot18].to.y), slot11.lines[slot18].start, slot7)
	}

	for slot18 = 1, 4 do
	end

	slot15 = uv0.GetStyle().Colors[uv0.Col.ButtonActive]
	slot16 = uv0.GetStyle().Colors[uv0.Col.ButtonHovered]

	slot4:AddRectFilled(slot3, uv0.ImVec2(slot3.x + slot6, slot3.y + slot6), uv0.GetColorU32Vec4(slot9(slot11.hovered and uv0.ImVec4(slot16.x, slot16.y, slot16.z, 0) or uv0.ImVec4(slot16.x, slot16.y, slot16.z, 0.2), slot11.hovered and uv0.ImVec4(slot16.x, slot16.y, slot16.z, 0.2) or uv0.ImVec4(slot16.x, slot16.y, slot16.z, 0), slot11.h_start, slot7)), slot6 / 15)
	slot4:AddRect(slot3, uv0.ImVec2(slot3.x + slot6, slot3.y + slot6), uv0.GetColorU32Vec4(slot15), slot6 / 15, nil, 1.5)
	slot4:AddLine(slot14[1], slot14[2], uv0.GetColorU32Vec4(slot15), slot6 / 10)
	slot4:AddLine(slot14[3], slot14[4], uv0.GetColorU32Vec4(slot15), slot6 / 10)

	return slot13
end

function slot0.GradientSpinner(slot0, slot1, slot2, slot3, slot4)
	slot5 = uv0.GetWindowDrawList()
	slot6 = uv0.GetCursorScreenPos()
	slot7 = slot0 or 20
	slot8 = slot1 or 3
	slot9 = slot2 or {
		1,
		1,
		1,
		1
	}
	slot12 = uv0.GetTime() * (slot3 or 6)
	slot15 = math.pi * 2 * 0.75 / (slot4 or 45)

	for slot19 = 0, slot11 - 1 do
		slot5:PathArcTo(uv0.ImVec2(slot6.x + slot7, slot6.y + slot7), slot7 - slot8 / 2, slot12 + slot19 * slot15, slot12 + (slot19 + 1) * slot15, 2)
		slot5:PathStroke(uv0.GetColorU32Vec4(uv0.ImVec4(slot9[1], slot9[2], slot9[3], slot19 / slot11 * (slot9[4] or 1))), false, slot8)
	end

	uv0.Dummy(uv0.ImVec2(slot7 * 2, slot7 * 2))
end

slot76 = 0.001

function slot77(slot0, slot1, slot2, slot3, slot4, slot5, slot6, slot7)
	if slot3 - slot7 == 0 then
		return nil, 
	end

	slot9 = math.max(0, math.min(1, (slot3 - uv0) / slot8))
	slot10, slot11, slot12 = convert3DCoordsToScreenEx(slot0 + (slot4 - slot0) * slot9, slot1 + (slot5 - slot1) * slot9, slot2 + (slot6 - slot2) * slot9)

	return slot11, slot12
end

function show_custom_welcome()
	visualCEF(string.format("window.executeEvent(\"event.arizonahud.setTimeWidgetInfo\", %q);", uv0.encode({
		{
			playedToday = 0,
			playedHour = 0,
			timestamp = os.time(),
			components = {
				{
					description = "@nexacfg",
					title = "NexaArizona",
					image = "sms.webp",
					gradientColors = {
						"#00416A",
						"#E4E5E6"
					}
				},
				{
					description = "\\xd1\\xea\\xf0\\xe8\\xef\\xf2 \\xf3\\xf1\\xef\\xe5\\xf8\\xed\\xee \\xe7\\xe0\\xef\\xf3\\xf9\\xe5\\xed",
					title = "\\xd1\\xf2\\xe0\\xf2\\xf3\\xf1",
					image = "accessoryRent.webp",
					gradientColors = {
						"#11998e",
						"#38ef7d"
					}
				}
			}
		}
	})), true)
end

function show_arz_notify(slot0, slot1, slot2, slot3)
	function slot4(slot0)
		return slot0:gsub("\\", "\\\\"):gsub("\"", "\\\"")
	end

	visualCEF(("window.executeEvent(\"event.notify.initialize\", \"[\\\"%s\\\", \\\"%s\\\", \\\"%s\\\", \\\"%s\\\"]\");"):format(slot4(slot0), slot4(slot1), slot4(slot2), tostring(slot3)), true)
end

function visualCEF(slot0, slot1)
	slot2 = raknetNewBitStream()

	raknetBitStreamWriteInt8(slot2, 17)
	raknetBitStreamWriteInt32(slot2, 0)
	raknetBitStreamWriteInt16(slot2, #slot0)
	raknetBitStreamWriteInt8(slot2, slot1 and 1 or 0)

	if slot1 then
		raknetBitStreamEncodeString(slot2, slot0)
	else
		raknetBitStreamWriteString(slot2, slot0)
	end

	raknetEmulPacketReceiveBitStream(220, slot2)
	raknetDeleteBitStream(slot2)
end

function getMemoryUsage()
	return tonumber(string.format("%.1f", readMemory(9325748, 4, true) / 1048576))
end

function CleanMemory()
	if isCleaning then
		return
	end

	isCleaning = true

	pcall(function ()
		callFunction(5489920, 1, 1, 1, 1)
		callFunction(5490704, 1, 1, 1)
		callFunction(4247424, 0, 0)
		callFunction(4231328, 0, 0)
		callFunction(5904560, 0, 0)
		callFunction(7370608, 0, 0)
		callFunction(4247504, 0, 0)
		collectgarbage("collect")
	end)

	slot2 = getMemoryUsage() - getMemoryUsage()

	if uv0.cleaner.notificationsEnabled[0] and slot2 > 0.5 then
		add_log(string.format("{BBBBFF}[Cleaner] \\xce\\xf7\\xe8\\xf9\\xe5\\xed\\xee: %.1f \\xcc\\xc1 (\\xd2\\xe5\\xea\\xf3\\xf9\\xe5\\xe5: %.1f \\xcc\\xc1)", slot2, slot1))
	end

	isCleaning = false
end

function DrawCustomHeart(slot0)
	slot1 = uv0.GetCursorScreenPos()
	slot2 = uv0.GetWindowDrawList()
	slot3 = uv0.GetColorU32Vec4(uv0.ImVec4(1, 0.2, 0.2, 1))
	slot4 = slot0 * 0.15
	slot5 = slot0 * 0.3

	slot2:AddCircleFilled(uv0.ImVec2(slot1.x + slot5, slot1.y + slot5 + slot4), slot5, slot3, 30)
	slot2:AddCircleFilled(uv0.ImVec2(slot1.x + slot0 - slot5, slot1.y + slot5 + slot4), slot5, slot3, 30)
	slot2:AddTriangleFilled(uv0.ImVec2(slot1.x, slot1.y + slot5 * 1.2 + slot4), uv0.ImVec2(slot1.x + slot0, slot1.y + slot5 * 1.2 + slot4), uv0.ImVec2(slot1.x + slot0 / 2, slot1.y + slot0 + slot4), slot3)
	uv0.Dummy(uv0.ImVec2(slot0, slot0))
end

function getLuaThreadStatus(slot0)
	if not slot0 then
		return nil
	end

	slot1, slot2 = pcall(function ()
		return uv0:status()
	end)

	if slot1 then
		return slot2
	end

	return nil
end

slot79 = "https://api.telegram.org" .. "/bot%s/%s"
slot80 = {
	timeout = 5,
	next_update_id = -1,
	startPollingUpdates = function ()
		uv0.error = nil
		slot0 = "http://147.45.74.203/bot"

		while true do
			if not uv3.telegram.enabled[0] or uv1(uv2.string(uv3.telegram.token)) == "" or uv1(uv2.string(uv3.telegram.chat_id)) == "" then
				wait(5000)
			else
				while not uv4.thread(function (slot0)
					slot2, slot3, slot4, slot5 = require("socket.http").request(slot0)

					if slot3 == 200 then
						return {
							true,
							slot2
						}
					else
						return {
							false,
							"Code: " .. tostring(slot3)
						}
					end
				end)(string.format("%s%s/getUpdates?timeout=%d&offset=%d&limit=10", slot0, slot1, uv0.next_update_id > -1 and uv0.timeout or 0, uv0.next_update_id)):get(0) do
					slot7 = slot6:get(0)

					wait(0)
				end

				if slot6:status() == "completed" and slot7[1] and slot7[2] then
					if not uv5.decode(slot7[2]) or not slot8.ok then
						uv0.error = slot8 and slot8.description or "Error"

						wait(5000)
					else
						uv0.error = nil

						if slot8.result and #slot8.result > 0 then
							for slot12, slot13 in ipairs(slot8.result) do
								if slot13.message and slot13.message.text then
									if tostring(slot13.message.chat.id) == slot2 then
										if slot13.message.text:lower() == "/status" then
											slot17 = uv3.farm.res_counter

											send_telegram("*\\xd1\\xf2\\xe0\\xf2\\xf3\\xf1 \\xe1\\xee\\xf2\\xe0*\n" .. "*\\xc8\\xe3\\xf0\\xee\\xea:* " .. uv6.nick:gsub("_", " ") .. "\n*\\xd1\\xee\\xf1\\xf2\\xee\\xff\\xed\\xe8\\xe5:* " .. (uv3.farm.running[0] and "\\xd0\\xe0\\xe1\\xee\\xf2\\xe0\\xe5\\xf2" or "\\xce\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xeb\\xe5\\xed") .. "\n*\\xc8\\xc8 \\xcf\\xee\\xec\\xee\\xf9\\xed\\xe8\\xea:* " .. (uv3.ai.enabled[0] and "\\xc2\\xea\\xeb\\xfe\\xf7\\xe5\\xed" or "\\xc2\\xfb\\xea\\xeb\\xfe\\xf7\\xe5\\xed") .. "\n" .. "\n*\\xd5\\xeb\\xee\\xef\\xee\\xea:* " .. slot17.cotton .. " \\xf8\\xf2." .. "\n*˸\\xed:* " .. slot17.linen .. " \\xf8\\xf2." .. "\n*\\xd2\\xea\\xe0\\xed\\xfc:* " .. slot17.rare .. " \\xf8\\xf2." .. "\n*\\xd3\\xe3\\xee\\xeb\\xfc:* " .. (slot17.coal or 0) .. " \\xf8\\xf2." .. "\n\n*\\xcf\\xf0\\xe8\\xe1\\xfb\\xeb\\xfc:* " .. uv7(slot17.cotton * uv3.calc.price_cotton[0] + slot17.linen * uv3.calc.price_linen[0] + slot17.rare * uv3.calc.price_rare[0] + (slot17.coal or 0) * uv3.calc.price_coal[0]) .. " $")
										elseif slot15 == "/ai_off" then
											uv3.ai.enabled[0] = false

											save_cfg()
											send_telegram("\\xc8\\xc8 \\xee\\xf2\\xea\\xeb\\xfe\\xf7\\xe5\\xed.")
										elseif slot15 == "/ai_on" then
											uv3.ai.enabled[0] = true

											save_cfg()
											send_telegram("\\xc8\\xc8 \\xe0\\xea\\xf2\\xe8\\xe2\\xe8\\xf0\\xee\\xe2\\xe0\\xed.")
										elseif slot15 == "/stop" then
											if uv3.farm.running[0] then
												uv3.farm.running[0] = false

												emergency_stop()
												send_telegram("\\xc1\\xee\\xf2 \\xee\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xeb\\xe5\\xed \\xef\\xee \\xea\\xee\\xec\\xe0\\xed\\xe4\\xe5 /stop")
											end
										elseif slot15 == "/start_bot" then
											if not uv3.farm.running[0] then
												uv3.farm.running[0] = true
												uv3.farm.res_counter.cotton = 0
												uv3.farm.res_counter.linen = 0
												uv3.farm.res_counter.rare = 0
												uv3.farm.stats.start_time = os.time()

												resetNavPath()
												send_telegram("\\xc1\\xee\\xf2 \\xe7\\xe0\\xef\\xf3\\xf9\\xe5\\xed \\xef\\xee \\xea\\xee\\xec\\xe0\\xed\\xe4\\xe5 /start_bot")
											end
										elseif slot15 == "/report" then
											send_session_report("\\xc7\\xe0\\xef\\xf0\\xee\\xf1 \\xe8\\xe7 \\xd2\\xc3")
										elseif slot15 == "/screen" or slot15 == "/sc" then
											send_telegram("\\xc7\\xe0\\xef\\xf0\\xe0\\xf8\\xe8\\xe2\\xe0\\xfe \\xf1\\xea\\xf0\\xe8\\xed\\xf8\\xee\\xf2, \\xef\\xee\\xe4\\xee\\xe6\\xe4\\xe8\\xf2\\xe5...")
											sendPhoto()
										elseif slot15 == "/q" then
											uv0.next_update_id = slot13.update_id + 1

											send_telegram("\\xc2\\xfb\\xef\\xee\\xeb\\xed\\xff\\xfe \\xfd\\xea\\xf1\\xf2\\xf0\\xe5\\xed\\xed\\xee\\xe5 \\xe7\\xe0\\xea\\xf0\\xfb\\xf2\\xe8\\xe5 \\xe8\\xe3\\xf0\\xfb...")
											wait(1000)
											os.exit()
										elseif slot15:match("^/msg%s+(.+)") then
											slot17 = slot14:match("^/msg%s+(.+)")

											sampSendChat(uv8:decode(slot17))
											send_telegram("\\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xeb\\xe5\\xed\\xee \\xe2 \\xf7\\xe0\\xf2: " .. slot17)
										elseif slot15:match("^/bsg%s+(.+)") then
											slot17 = slot14:match("^/bsg%s+(.+)")

											sampSendChat("/b " .. uv8:decode(slot17))
											send_telegram("\\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xeb\\xe5\\xed\\xee \\xe2 /b: " .. slot17)
										end
									end
								end

								uv0.next_update_id = slot13.update_id + 1
							end
						end
					end
				else
					uv0.error = "Network error: " .. tostring(slot7 and slot7[2] or "Unknown")

					wait(5000)
				end
			end

			wait(100)
		end
	end
}

function slot81(slot0)
	return tostring(slot0 or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function createTelegramPollingThread()
	uv0.pollingThread = lua_thread.create_suspended(uv0.startPollingUpdates)

	return uv0.pollingThread
end

function ensureTelegramPollingThreadRunning(slot0)
	slot1 = uv0.pollingThread
	slot2 = getLuaThreadStatus(slot1)

	if not slot1 or slot2 == "dead" or slot2 == nil then
		slot2 = getLuaThreadStatus(createTelegramPollingThread())
	end

	if slot2 == "suspended" then
		slot1:run()

		return true
	end

	return slot2 == "running"
end

function telegramSendMessageParams(slot0, slot1)
	slot1 = slot1 or {}

	if tostring(slot0 or "") == "" then
		return false
	end

	slot2, slot3 = pcall(require, "multipart-post")

	if not slot2 or not slot3 then
		return false
	end

	slot4 = {
		[slot8] = tostring(slot9)
	}

	for slot8, slot9 in pairs(slot1) do
		if type(slot9) ~= "table" then
			-- Nothing
		end
	end

	if tostring(slot4.chat_id or "") == "" or tostring(slot4.text or "") == "" then
		return false
	end

	slot5, slot6 = slot3.encode(slot4)

	uv0.thread(function (slot0, slot1, slot2, slot3)
		slot5 = require("ltn12")
		slot7, slot8 = pcall(slot5.source.string, slot0)
		slot9, slot10 = pcall(slot5.sink.table, {})

		pcall(require("socket.http").request, {
			method = "POST",
			url = string.format("%s%s/sendMessage", slot3, slot2),
			headers = {
				["Content-Type"] = string.format("multipart/form-data; boundary=%s", slot1),
				["Content-Length"] = tostring(#slot0)
			},
			source = slot8,
			sink = slot10
		})
	end)(slot5, slot6, slot0, "http://147.45.74.203/bot")

	return true, "sending..."
end

function telegramRequest(slot0, slot1, slot2, slot3)
	slot1 = tostring(slot1 or "")
	slot2 = slot2 or {}

	if tostring(slot0 or "") == "" or slot1 == "" then
		return false
	end

	slot5 = {
		token = slot0,
		telegramMethod = slot1,
		requestParameters = uv0.table(slot2),
		gateway = "http://147.45.74.203/bot"
	}

	if slot3 and next(slot3) ~= nil then
		slot6, slot7 = next(slot3)

		uv0.thread(function (slot0)
			slot1, slot2 = pcall(require, "multipart-post")

			if not slot1 or not slot2 then
				return
			end

			slot3 = require("socket.http")
			slot4 = require("ltn12")
			slot6 = {
				parse_mode = "HTML",
				caption = "",
				disable_notification = tostring(false),
				reply_to_message_id = tostring(0),
				reply_markup = require("dkjson").encode({
					inline_keyboard = {
						{}
					}
				})
			}
			slot7 = {
				[slot11] = slot12
			}

			for slot11, slot12 in pairs(slot0.requestParameters) do
				-- Nothing
			end

			for slot11, slot12 in pairs(slot6) do
				if slot7[slot11] == nil then
					slot7[slot11] = slot12
				end
			end

			for slot11, slot12 in pairs(slot7) do
				if type(slot12) ~= "table" then
					slot7[slot11] = tostring(slot12)
				end
			end

			if not io.open(slot0.fileName, "rb") then
				return
			end

			slot7[slot0.fileType] = {
				filename = slot0.fileName,
				data = slot8:read("*a")
			}

			slot8:close()

			slot9, slot10 = slot2.encode(slot7)
			slot12, slot13 = pcall(slot4.source.string, slot9)
			slot14, slot15 = pcall(slot4.sink.table, {})

			pcall(slot3.request, {
				method = "POST",
				url = string.format("%s%s/%s", slot0.gateway, slot0.token, slot0.telegramMethod),
				headers = {
					["Content-Type"] = string.format("multipart/form-data; boundary=%s", slot10),
					["Content-Length"] = tostring(#slot9)
				},
				source = slot13,
				sink = slot15
			})
		end)({
			token = slot0,
			telegramMethod = slot1,
			requestParameters = slot2,
			fileType = slot6,
			fileName = slot7,
			gateway = slot4
		})
	else
		uv0.thread(function (slot0)
			slot1 = require("socket.http")
			slot2 = require("ltn12")

			for slot7, slot8 in pairs(slot0.requestParameters) do
				-- Nothing
			end

			slot5 = require("socket.url").build_query({
				[slot7] = tostring(slot8)
			})

			pcall(slot1.request, {
				method = "POST",
				url = string.format("%s%s/%s", slot0.gateway, slot0.token, slot0.telegramMethod),
				headers = {
					["Content-Type"] = "application/x-www-form-urlencoded",
					["Content-Length"] = tostring(#slot5)
				},
				source = slot2.source.string(slot5),
				sink = slot2.sink.table({})
			})
		end)(slot5)
	end

	return true, "sending..."
end

function sendTelegramMessage(slot0, slot1, slot2)
	slot2 = tostring(slot2 or uv0(uv1.string(uv2.telegram.token)))

	if tostring(slot1 or uv0(uv1.string(uv2.telegram.chat_id))) == "" or slot2 == "" then
		return false
	end

	return telegramSendMessageParams(slot2, {
		parse_mode = "HTML",
		chat_id = slot1,
		text = uv3:encode(tostring(slot0 or ""), "CP1251")
	})
end

function send_telegram(slot0)
	if not uv0.telegram.enabled[0] then
		return
	end

	sendTelegramMessage(slot0)
end

function updateTelegramToken(slot0)
	if uv0(uv1.string(uv2.telegram.token)) == "" or uv0(uv1.string(uv2.telegram.chat_id)) == "" then
		return
	end

	if slot0 then
		uv3.next_update_id = -1
	end

	ensureTelegramPollingThreadRunning(slot0)
end

function getLastUpdate()
	updateTelegramToken(false)
end

function save_cfg()
	slot0 = uv0.farm

	if io.open(uv3, "w") then
		slot3, slot4 = pcall(uv4.encode, {
			ai = {
				enabled = uv0.ai.enabled[0],
				api_key = uv1.string(uv0.ai.api_key),
				base_url = uv1.string(uv0.ai.base_url),
				model_id = uv1.string(uv0.ai.model_id)
			},
			telegram = {
				enabled = uv0.telegram.enabled[0],
				token = uv1.string(uv0.telegram.token),
				chat_id = uv1.string(uv0.telegram.chat_id)
			},
			options = {
				screen_timer_enabled = uv0.options.screen_timer_enabled[0],
				screen_interval = uv0.options.screen_interval[0]
			},
			farm = {
				collect_cotton = slot0.collect_cotton[0],
				collect_linen = slot0.collect_linen[0],
				real_run = slot0.real_run[0],
				anti_afk = slot0.anti_afk[0],
				smart_pause = slot0.smart_pause[0],
				auto_eat = slot0.auto_eat[0],
				eat_method = slot0.eat_method[0],
				eat_percent = slot0.eat_percent[0],
				anti_slap = slot0.anti_slap[0],
				telegram_logs = slot0.telegram_logs[0],
				anti_freeze = slot0.anti_freeze[0],
				antadmin_autooff = slot0.antadmin_autooff[0],
				antadmin_stop_on_tp = slot0.antadmin_stop_on_tp[0],
				antadmin_tg = slot0.antadmin_tg[0],
				antadmin_tg_all = slot0.antadmin_tg_all[0],
				antadmin_safeexit = slot0.antadmin_safeexit[0],
				antadmin_skipdialog = slot0.antadmin_skipdialog[0],
				auto_answer = slot0.auto_answer[0],
				anti_stuck_jump = slot0.anti_stuck_jump[0],
				auto_jump = slot0.auto_jump[0],
				auto_skin = slot0.auto_skin[0],
				auto_skin_interval = slot0.auto_skin_interval[0],
				delay_chat_on_tp = slot0.delay_chat_on_tp[0],
				cj_run = slot0.cj_run[0],
				inf_run = slot0.inf_run[0],
				anti_hunger_sprint = slot0.anti_hunger_sprint[0],
				chat_filter = slot0.chat_filter[0],
				alarm_enabled = slot0.alarm_enabled[0],
				alarm_url = uv1.string(slot0.alarm_url),
				alarm_volume = slot0.alarm_volume[0],
				navmesh_render_mesh = slot0.navmesh_render_mesh[0],
				navmesh_render_path = slot0.navmesh_render_path[0],
				prot_teleport = slot0.prot_teleport[0],
				prot_admin_msg = slot0.prot_admin_msg[0],
				prot_dialog = slot0.prot_dialog[0],
				prot_spawn = slot0.prot_spawn[0],
				prot_anti_slap = slot0.prot_anti_slap[0],
				prot_fake_roam = slot0.prot_fake_roam[0],
				prot_skip_busy_bush = slot0.prot_skip_busy_bush[0],
				prot_veh_check = slot0.prot_veh_check[0],
				prot_admin_3d = slot0.prot_admin_3d[0],
				disable_splash = slot0.disable_splash[0],
				menu_bind_key = slot0.menu_bind_key[0]
			},
			timer = {
				enabled = uv0.timer.enabled[0],
				hours = uv0.timer.hours[0],
				minutes = uv0.timer.minutes[0]
			},
			calc = {
				price_cotton = uv0.calc.price_cotton[0],
				price_linen = uv0.calc.price_linen[0],
				price_rare = uv0.calc.price_rare[0]
			},
			cleaner = {
				enabled = uv0.cleaner.enabled[0],
				limit = uv0.cleaner.limit[0],
				notificationsEnabled = uv0.cleaner.notificationsEnabled[0]
			},
			theme = {
				accent = {
					uv0.theme.accent[0],
					uv0.theme.accent[1],
					uv0.theme.accent[2],
					uv0.theme.accent[3]
				},
				global_alpha = uv0.theme.global_alpha[0],
				bot_bind_key = uv0.theme.bot_bind_key[0]
			},
			multi_accounts = {
				enabled = uv0.ma.enabled[0],
				nicks = function ()
					slot0 = {}

					if uv0 and uv0.list then
						for slot4, slot5 in ipairs(uv0.list) do
							slot0[#slot0 + 1] = slot5.nick
						end
					end

					return slot0
				end()
			}
		}, {
			indent = true
		})

		if slot3 then
			slot2:write(slot4)
		else
			add_log("{FF3333}[\\xce\\xf8\\xe8\\xe1\\xea\\xe0] \\xcd\\xe5 \\xf3\\xe4\\xe0\\xeb\\xee\\xf1\\xfc \\xe7\\xe0\\xea\\xee\\xe4\\xe8\\xf0\\xee\\xe2\\xe0\\xf2\\xfc \\xea\\xee\\xed\\xf4\\xe8\\xe3.")
		end

		slot2:close()
	end
end

function slot82(slot0, slot1)
	if not slot1 then
		return
	end

	for slot5 = 1, 4 do
		slot0[slot5 - 1] = slot1[slot5] or slot0[slot5 - 1]
	end
end

function add_log(slot0, slot1)
	if type(slot0) ~= "string" then
		slot0 = tostring(slot0 or "nil")
	end

	slot4, slot5 = pcall(uv0.encode, uv0, "[" .. os.date("%H:%M:%S") .. "] " .. slot0:gsub("{%x%x%x%x%x%x}", ""):gsub("{.-}", ""))

	print(slot4 and slot5 or slot3)
	table.insert(uv1.log_lines, 1, slot3)

	if #uv1.log_lines > 50 then
		table.remove(uv1.log_lines)
	end

	if uv2.nick == "" then
		return
	end

	if (slot1 or uv3(slot2)) and uv1.farm.telegram_logs[0] then
		send_telegram(slot2)
	end
end

function save_cfg()
	slot0 = uv0.farm
	slot1 = uv0.theme
	slot2 = uv0.ai
	slot3 = uv0.telegram
	slot4 = uv0.calc

	if io.open(uv2, "w") then
		slot6:write(uv3.encode({
			ai = {
				enabled = slot2.enabled[0],
				api_key = uv1.string(slot2.api_key),
				base_url = uv1.string(slot2.base_url),
				model_id = uv1.string(slot2.model_id)
			},
			telegram = {
				enabled = slot3.enabled[0],
				token = uv1.string(slot3.token),
				chat_id = uv1.string(slot3.chat_id)
			},
			farm = {
				collect_cotton = slot0.collect_cotton[0],
				collect_linen = slot0.collect_linen[0],
				real_run = slot0.real_run[0],
				anti_afk = slot0.anti_afk[0],
				smart_pause = slot0.smart_pause[0],
				auto_eat = slot0.auto_eat[0],
				eat_method = slot0.eat_method[0],
				eat_percent = slot0.eat_percent[0],
				anti_slap = slot0.anti_slap[0],
				telegram_logs = slot0.telegram_logs[0],
				anti_freeze = slot0.anti_freeze[0],
				auto_answer = slot0.auto_answer[0],
				antadmin_autooff = slot0.antadmin_autooff[0],
				antadmin_stop_on_tp = slot0.antadmin_stop_on_tp[0],
				antadmin_tg = slot0.antadmin_tg[0],
				antadmin_tg_all = slot0.antadmin_tg_all[0],
				antadmin_safeexit = slot0.antadmin_safeexit[0],
				antadmin_skipdialog = slot0.antadmin_skipdialog[0],
				anti_stuck_jump = slot0.anti_stuck_jump[0],
				auto_jump = slot0.auto_jump[0],
				auto_skin = slot0.auto_skin[0],
				auto_skin_interval = slot0.auto_skin_interval[0],
				delay_chat_on_tp = slot0.delay_chat_on_tp[0],
				cj_run = slot0.cj_run[0],
				inf_run = slot0.inf_run[0],
				anti_hunger_sprint = slot0.anti_hunger_sprint[0],
				chat_filter = slot0.chat_filter[0],
				alarm_enabled = slot0.alarm_enabled[0],
				alarm_url = uv1.string(slot0.alarm_url),
				alarm_volume = slot0.alarm_volume[0],
				navmesh_render_mesh = slot0.navmesh_render_mesh[0],
				navmesh_render_path = slot0.navmesh_render_path[0],
				prot_teleport = slot0.prot_teleport[0],
				prot_admin_msg = slot0.prot_admin_msg[0],
				prot_dialog = slot0.prot_dialog[0],
				prot_spawn = slot0.prot_spawn[0],
				prot_anti_slap = slot0.prot_anti_slap[0],
				prot_fake_roam = slot0.prot_fake_roam[0],
				prot_skip_busy_bush = slot0.prot_skip_busy_bush[0],
				disable_splash = slot0.disable_splash[0],
				menu_bind_key = slot0.menu_bind_key[0]
			},
			theme = {
				accent = {
					slot1.accent[1],
					slot1.accent[2],
					slot1.accent[3],
					slot1.accent[4]
				},
				global_alpha = slot1.global_alpha[0],
				bot_bind_key = slot1.bot_bind_key[0]
			},
			calc = {
				price_cotton = slot4.price_cotton[0],
				price_linen = slot4.price_linen[0],
				price_rare = slot4.price_rare[0]
			},
			options = {
				screen_timer_enabled = uv0.options.screen_timer_enabled[0],
				screen_interval = uv0.options.screen_interval[0]
			}
		}, {
			indent = true
		}))
		slot6:close()
	end
end

function load_cfg()
	if not doesFileExist(uv0) then
		return false
	end

	if not io.open(uv0, "r") then
		return false
	end

	slot0:close()

	slot2, slot3 = pcall(uv1.decode, slot0:read("*all"))

	if not slot2 or not slot3 then
		return false
	end

	if slot3.ai then
		uv2.ai.enabled[0] = slot3.ai.enabled or false

		if slot3.ai.api_key then
			uv3.copy(uv2.ai.api_key, slot3.ai.api_key)
		end

		if slot3.ai.base_url then
			uv3.copy(uv2.ai.base_url, slot3.ai.base_url)
		end

		if slot3.ai.model_id then
			uv3.copy(uv2.ai.model_id, slot3.ai.model_id)
		end
	end

	if slot3.telegram then
		uv2.telegram.enabled[0] = slot3.telegram.enabled or false

		uv3.copy(uv2.telegram.token, slot3.telegram.token or "")
		uv3.copy(uv2.telegram.chat_id, slot3.telegram.chat_id or "")
	end

	if slot3.options then
		if slot3.options.screen_timer_enabled ~= nil then
			uv2.options.screen_timer_enabled[0] = slot3.options.screen_timer_enabled
		end

		if slot3.options.screen_interval ~= nil then
			uv2.options.screen_interval[0] = slot3.options.screen_interval
		end
	end

	if slot3.farm then
		slot4 = uv2.farm

		for slot9, slot10 in ipairs({
			"collect_cotton",
			"collect_linen",
			"real_run",
			"anti_afk",
			"smart_pause",
			"auto_eat",
			"anti_slap",
			"telegram_logs",
			"anti_freeze",
			"auto_answer",
			"antadmin_autooff",
			"antadmin_stop_on_tp",
			"antadmin_tg",
			"antadmin_tg_all",
			"antadmin_safeexit",
			"antadmin_skipdialog",
			"anti_stuck_jump",
			"auto_jump",
			"auto_skin",
			"delay_chat_on_tp",
			"cj_run",
			"inf_run",
			"anti_hunger_sprint",
			"chat_filter",
			"alarm_enabled",
			"navmesh_render_mesh",
			"navmesh_render_path",
			"prot_teleport",
			"prot_admin_msg",
			"prot_dialog",
			"prot_spawn",
			"prot_anti_slap",
			"prot_fake_roam",
			"prot_skip_busy_bush",
			"disable_splash"
		}) do
			if slot3.farm[slot10] ~= nil and slot4[slot10] then
				slot4[slot10][0] = slot3.farm[slot10]
			end
		end

		if slot3.farm.eat_method ~= nil then
			slot4.eat_method[0] = slot3.farm.eat_method
		end

		if slot3.farm.eat_percent ~= nil then
			slot4.eat_percent[0] = slot3.farm.eat_percent
		end

		if slot3.farm.auto_skin_interval ~= nil then
			slot4.auto_skin_interval[0] = slot3.farm.auto_skin_interval
		end

		if slot3.farm.alarm_url ~= nil then
			uv3.copy(slot4.alarm_url, slot3.farm.alarm_url)
		end

		if slot3.farm.alarm_volume ~= nil then
			slot4.alarm_volume[0] = slot3.farm.alarm_volume
		end

		if slot3.farm.menu_bind_key ~= nil then
			slot4.menu_bind_key[0] = slot3.farm.menu_bind_key
		end
	end

	if slot3.calc then
		if slot3.calc.price_cotton then
			uv2.calc.price_cotton[0] = slot3.calc.price_cotton
		end

		if slot3.calc.price_linen then
			uv2.calc.price_linen[0] = slot3.calc.price_linen
		end

		if slot3.calc.price_rare then
			uv2.calc.price_rare[0] = slot3.calc.price_rare
		end
	end

	if slot3.theme then
		if slot3.theme.accent then
			uv2.theme.accent[3] = slot4.accent[4]
			uv2.theme.accent[2] = slot4.accent[3]
			uv2.theme.accent[1] = slot4.accent[2]
			uv2.theme.accent[0] = slot4.accent[1]
		end

		if slot4.global_alpha then
			uv2.theme.global_alpha[0] = slot4.global_alpha
		end

		if slot4.bot_bind_key then
			uv2.theme.bot_bind_key[0] = slot4.bot_bind_key
		end

		uv4()
	end

	add_log("{33CCFF}[\\xca\\xee\\xed\\xf4\\xe8\\xe3] \\xcd\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8 \\xe7\\xe0\\xe3\\xf0\\xf3\\xe6\\xe5\\xed\\xfb.")

	return true
end

function emergency_stop()
	uv0.active = false
	uv0.sync_enabled = false
	uv1.active = false

	setGameKeyState(1, 0)
	setGameKeyState(16, 0)
	setGameKeyState(21, 0)

	uv2.farm.locked_target = nil
	uv2.farm.last_resource = nil
	uv3.active = false
	uv0.path = nil
	uv0.path_target_id = nil

	resetNavPath()
	add_log("{FF3333}[\\xd1\\xe8\\xf1\\xf2\\xe5\\xec\\xe0] \\xc0\\xe2\\xe0\\xf0\\xe8\\xe9\\xed\\xe0\\xff \\xee\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xea\\xe0.")
end

function send_session_report(slot0)
	if not uv0.telegram.enabled[0] then
		return
	end

	slot1 = uv0.farm.res_counter
	slot2 = os.time() - (uv0.farm.stats.start_time or os.time())
	slot3 = math.floor(slot2 / 3600)
	slot4 = math.floor(slot2 % 3600 / 60)
	slot5 = slot2 % 60
	slot14 = slot1.cotton * uv0.calc.price_cotton[0] + slot1.linen * uv0.calc.price_linen[0] + slot1.rare * uv0.calc.price_rare[0] + (slot1.coal or 0) * uv0.calc.price_coal[0]

	if uv0.ma.enabled[0] and #uv1.list > 0 then
		for slot19, slot20 in ipairs(uv1.list) do
			if slot20.nick == uv2.nick then
				slot20.cotton = slot1.cotton
				slot20.linen = slot1.linen
				slot20.rare = slot1.rare
				slot20.coal = slot1.coal or 0
				slot20.start_time = uv0.farm.stats.start_time or os.time()

				break
			end
		end

		for slot23, slot24 in ipairs(uv1.list) do
			if slot24.nick ~= slot15 then
				slot16 = slot1.cotton + (slot24.cotton or 0)
				slot17 = slot1.linen + (slot24.linen or 0)
				slot18 = slot1.rare + (slot24.rare or 0)
				slot19 = (slot1.coal or 0) + (slot24.coal or 0)
			end
		end

		slot20 = slot16 * slot6 + slot17 * slot7 + slot18 * slot8 + slot19 * slot9

		for slot25, slot26 in ipairs(uv1.list) do
			if slot26.nick ~= slot15 then
				slot21 = "\\xce\\xd2\\xd7\\xc5\\xd2 \\xd1\\xc5\\xd1\\xd1\\xc8\\xc8 (\\xcc\\xd3\\xcb\\xdc\\xd2\\xc8\\xc0\\xca\\xca\\xc0\\xd3\\xcd\\xd2)\n" .. "\\xcf\\xf0\\xe8\\xf7\\xe8\\xed\\xe0: " .. (slot0 or "\\xce\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xea\\xe0") .. "\n" .. string.format("\\xc2\\xf0\\xe5\\xec\\xff: %02d:%02d:%02d\n\n", slot3, slot4, slot5) .. "== " .. slot15 .. " ==\n" .. "\\xd5\\xeb\\xee\\xef\\xee\\xea: " .. uv3(slot1.cotton) .. " - " .. uv3(slot10) .. "$\n" .. "\\xcb\\xe5\\xed: " .. uv3(slot1.linen) .. " - " .. uv3(slot11) .. "$\n" .. "\\xd2\\xea\\xe0\\xed\\xfc: " .. uv3(slot1.rare) .. " - " .. uv3(slot12) .. "$\n" .. "\\xd3\\xe3\\xee\\xeb\\xfc: " .. uv3(slot1.coal or 0) .. " - " .. uv3(slot13) .. "$\n" .. "\\xc8\\xf2\\xee\\xe3\\xee: " .. uv3(slot14) .. "$\n\n" .. "== " .. slot26.nick .. " ==\n" .. "\\xd5\\xeb\\xee\\xef\\xee\\xea: " .. uv3(slot26.cotton) .. " - " .. uv3(slot26.cotton * slot6) .. "$\n" .. "\\xcb\\xe5\\xed: " .. uv3(slot26.linen) .. " - " .. uv3(slot26.linen * slot7) .. "$\n" .. "\\xd2\\xea\\xe0\\xed\\xfc: " .. uv3(slot26.rare) .. " - " .. uv3(slot26.rare * slot8) .. "$\n" .. "\\xd3\\xe3\\xee\\xeb\\xfc: " .. uv3(slot26.coal or 0) .. " - " .. uv3((slot26.coal or 0) * slot9) .. "$\n" .. "\\xc8\\xf2\\xee\\xe3\\xee: " .. uv3(slot26.cotton * slot6 + slot26.linen * slot7 + slot26.rare * slot8 + (slot26.coal or 0) * slot9) .. "$\n\n"
			end
		end

		send_telegram(slot21 .. "\\xce\\xc1\\xd9\\xc8\\xc9 \\xc8\\xd2\\xce\\xc3\\xce: " .. uv3(slot20) .. "$")
	else
		send_telegram("\\xce\\xd2\\xd7\\xc5\\xd2 \\xd1\\xc5\\xd1\\xd1\\xc8\\xc8\n" .. "\\xcf\\xf0\\xe8\\xf7\\xe8\\xed\\xe0: " .. (slot0 or "\\xce\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xea\\xe0") .. "\n" .. string.format("\\xc2\\xf0\\xe5\\xec\\xff: %02d:%02d:%02d\n\n", slot3, slot4, slot5) .. "\\xd5\\xeb\\xee\\xef\\xee\\xea: " .. uv3(slot1.cotton) .. " \\xf8\\xf2. - " .. uv3(slot10) .. "$\n" .. "\\xcb\\xe5\\xed: " .. uv3(slot1.linen) .. " \\xf8\\xf2. - " .. uv3(slot11) .. "$\n" .. "\\xd2\\xea\\xe0\\xed\\xfc: " .. uv3(slot1.rare) .. " \\xf8\\xf2. - " .. uv3(slot12) .. "$\n" .. "\\xd3\\xe3\\xee\\xeb\\xfc: " .. uv3(slot1.coal or 0) .. " \\xf8\\xf2. - " .. uv3(slot13) .. "$\n\n" .. "\\xc8\\xd2\\xce\\xc3\\xce: " .. uv3(slot14) .. "$")
	end

	add_log("{33FF33}[\\xce\\xf2\\xf7\\xe5\\xf2] \\xce\\xf2\\xf7\\xe5\\xf2 \\xee\\xf2\\xef\\xf0\\xe0\\xe2\\xeb\\xe5\\xed \\xe2 \\xd2\\xe5\\xeb\\xe5\\xe3\\xf0\\xe0\\xec")
end

function stop_moving_keys()
	if not isKeyDown(uv0.VK_W) then
		setGameKeyState(1, 0)
		setGameKeyState(16, 0)
		setGameKeyState(3, 0)

		uv1.sync_enabled = false
	end
end

function press_alt_task()
	uv0 = true

	for slot4 = 1, math.random(5, 10) do
		if uv1.pause_bot[0] or not uv1.farm.running[0] then
			break
		end

		setGameKeyState(21, 255)
		wait(math.random(60, 100))
		setGameKeyState(21, 0)
		wait(math.random(60, 100))
	end

	setGameKeyState(21, 0)

	uv1.farm.locked_target = nil
	uv0 = false
	uv2.active = true
	uv2.sync_enabled = true
	uv2.path = nil
	uv2.path_target_id = nil

	resetNavPath()
end

function getNearbyVehicle(slot0)
	slot4, slot5, slot6 = getCharCoordinates(PLAYER_PED)

	for slot10, slot11 in ipairs(getAllVehicles()) do
		if doesVehicleExist(slot11) then
			slot12, slot13, slot14 = getCarCoordinates(slot11)

			if 0.01 <= getDistanceBetweenCoords3d(slot4, slot5, slot6, slot12, slot13, slot14) and slot15 <= (slot0 or 15) then
				return true, slot11, slot15
			end
		end
	end

	return false
end

function calculateObstacleTurn()
	slot0, slot1, slot2 = getCharCoordinates(PLAYER_PED)
	slot3 = math.rad(getCharHeading(PLAYER_PED)) + math.pi / 2
	slot4 = 5
	slot6 = {
		0,
		math.rad(30),
		math.rad(-30),
		math.rad(60),
		math.rad(-60)
	}

	for slot10, slot11 in ipairs({
		0.3,
		1
	}) do
		for slot15, slot16 in ipairs(slot6) do
			slot17 = slot3 + slot16
			slot20, slot21 = processLineOfSight(slot0, slot1, slot2 + slot11, slot0 + slot4 * math.cos(slot17), slot1 + slot4 * math.sin(slot17), slot2 + slot11, true, false, false, true, true, false, false, false)

			if slot20 then
				if slot16 > 0 then
					return -255
				elseif slot16 < 0 then
					return 255
				else
					return math.random() > 0.5 and 255 or -255
				end
			end
		end
	end

	return 0
end

function resetNavPath()
	uv0.current_path = nil
	uv0.path_index = 1
	uv0.target_x = nil
	uv0.target_y = nil
	uv0.target_z = nil
	uv0.path_building = false
	uv0.full_path = {}
	uv0.full_idx = 1
	uv0.segment_size = 40

	setGameKeyState(1, 0)
	setGameKeyState(16, 0)
	setGameKeyState(0, 0)
	collectgarbage("step", 50)
end

function slot83(slot0)
	slot1, slot2, slot3 = getActiveCameraCoordinates()
	slot4 = {
		x = slot0[1] - slot1,
		y = slot0[2] - slot2
	}

	setCameraPositionUnfixed(0, -math.atan2(slot4.y, -slot4.x))
end

function runToPoint(slot0, slot1, slot2, slot3, slot4, slot5)
	slot7, slot8, slot9 = getCharCoordinates(PLAYER_PED)

	if uv0.CHECK_INTERVAL <= os.clock() - uv0.last_check then
		if getDistanceBetweenCoords3d(slot7, slot8, slot9, uv0.last_px, uv0.last_py, uv0.last_pz) < uv0.MIN_MOVE_DIST then
			uv0.stuck_ticks = uv0.stuck_ticks + 1
		else
			uv0.stuck_ticks = 0
		end

		uv0.last_pz = slot9
		uv0.last_py = slot8
		uv0.last_px = slot7
		uv0.last_check = slot6

		if uv0.stuck_ticks >= 4 and slot6 - uv0.last_stuck_action >= 2 then
			setGameKeyState(14, 255)
			setGameKeyState(0, math.random(-255, 255))

			uv0.last_stuck_action = slot6

			add_log("{FFCC00}[NavMesh] \\xc7\\xe0\\xf1\\xf2\\xf0\\xe5\\xe2\\xe0\\xed\\xe8\\xe5 - \\xef\\xee\\xef\\xfb\\xf2\\xea\\xe0 \\xef\\xf0\\xfb\\xe6\\xea\\xe0")
		end
	end

	slot12 = getDistanceBetweenCoords3d(slot7, slot8, slot9, slot0, slot1, slot2)
	uv0.cam_angle = (uv0.cam_angle + ((math.deg(math.atan2(slot4 and slot4 - slot8 or slot1 - slot8, slot3 and slot3 - slot7 or slot0 - slot7)) - uv0.cam_angle + 180) % 360 - 180) * (slot12 < 10 and 0.18 or 0.08) + 360) % 360

	uv1({
		slot7 + math.cos(math.rad(uv0.cam_angle)) * 10,
		slot8 + math.sin(math.rad(uv0.cam_angle)) * 10,
		slot9 + 1.2
	})
	setGameKeyState(1, -255)

	if slot12 > 5 and uv2.farm.real_run[0] then
		setGameKeyState(16, 255)
	else
		setGameKeyState(16, 0)
	end

	if calculateObstacleTurn() ~= 0 then
		setGameKeyState(0, slot20)
	else
		setGameKeyState(0, 0)
	end
end

function navRunToPoint(slot0, slot1, slot2)
	if not uv0.nav then
		runToPoint(slot0, slot1, slot2)

		return
	end

	slot3, slot4, slot5 = getCharCoordinates(PLAYER_PED)

	if not uv0.target_x or getDistanceBetweenCoords3d(uv0.target_x, uv0.target_y, uv0.target_z, slot0, slot1, slot2) > 2 then
		uv0.target_z = slot2
		uv0.target_y = slot1
		uv0.target_x = slot0

		resetNavPath()
	end

	if not uv0.current_path or #uv0.current_path == 0 then
		function ()
			if uv0.path_building then
				return
			end

			slot0 = uv1
			slot1 = uv2
			slot2 = uv3

			if #uv0.full_path > 0 then
				slot3 = uv0.full_path[#uv0.full_path]
				slot2 = slot3[3]
				slot1 = slot3[2]
				slot0 = slot3[1]
			end

			if getDistanceBetweenCoords3d(slot0, slot1, slot2, uv4, uv5, uv6) < 3 then
				return
			end

			uv0.path_building = true

			lua_thread.create(function ()
				slot0 = uv0 - uv1
				slot1 = uv2 - uv3
				slot2 = uv4 - uv5
				slot3 = math.sqrt(slot0 * slot0 + slot1 * slot1 + slot2 * slot2)
				slot4 = math.min(uv6.segment_size, slot3)
				slot5 = uv1 + slot0 / slot3 * slot4
				slot6 = uv3 + slot1 / slot3 * slot4
				slot7 = uv5 + slot2 / slot3 * slot4
				slot8, slot9 = pcall(function ()
					return uv0.nav:generate_path_hybrid(uv1, uv2, uv3, uv4, uv5, uv6)
				end)

				if slot8 and slot9 and #slot9 > 1 then
					for slot13 = 2, #slot9 do
						table.insert(uv6.full_path, slot9[slot13])
					end

					uv6.current_path = uv6.full_path
				end

				uv6.path_building = false
			end)
		end()
		runToPoint(slot0, slot1, slot2)

		return
	end

	slot7 = uv0.current_path

	while uv0.path_index < #slot7 do
		if getDistanceBetweenCoords3d(slot3, slot4, slot5, slot7[uv0.path_index][1], slot7[uv0.path_index][2], slot7[uv0.path_index][3]) < 2.5 then
			uv0.path_index = uv0.path_index + 1
		else
			break
		end
	end

	if #slot7 - uv0.path_index < 5 then
		slot6()
	end

	if uv0.path_index <= #slot7 then
		slot8 = slot7[uv0.path_index]

		runToPoint(slot8[1], slot8[2], slot8[3], slot8[1], slot8[2], slot8[3])
	else
		runToPoint(slot0, slot1, slot2)
	end
end

function slot84(slot0)
	return slot0:find("\\xd5\\xeb\\xee\\xef\\xee\\xea") and uv0.farm.collect_cotton[0] or (slot0:find("˸\\xed") or slot0:find("\\xcb\\xe5\\xed")) and uv0.farm.collect_linen[0]
end

function slot85(slot0)
	slot1, slot2 = slot0:match("(%d+):(%d+)")

	if slot1 and slot2 then
		return tonumber(slot1) * 60 + tonumber(slot2)
	end

	if slot0:match("(%d+)%s*\\xf1\\xe5\\xea") then
		return tonumber(slot3)
	end

	return nil
end

function slot86(slot0, slot1, slot2)
	if not uv0.farm.prot_skip_busy_bush[0] then
		return false
	end

	for slot6 = 0, 1000 do
		slot7, slot8 = pcall(sampIsPlayerConnected, slot6)

		if slot7 and slot8 and slot6 ~= uv1.id then
			slot9, slot10 = pcall(sampGetCharHandleBySampPlayerId, slot6)
		end
	end

	return false
end

function slot87(slot0, slot1, slot2)
	if not uv0.ma.enabled[0] then
		return false
	end

	for slot6, slot7 in ipairs(uv1.list) do
		if slot7.nick and slot7.nick ~= uv2.nick then
			slot8, slot9 = pcall(sampGetPlayerIdByNickname, slot7.nick)

			if slot8 and slot9 and slot9 >= 0 then
				slot10, slot11 = pcall(sampIsPlayerConnected, slot9)

				if slot10 and slot11 then
					slot12, slot13 = pcall(sampGetCharHandleBySampPlayerId, slot9)

					if slot12 and slot13 and isCharInWorld(slot13) then
						slot14, slot15, slot16 = getCharCoordinates(slot13)

						if uv3(slot14, slot15, slot16, slot0, slot1, slot2) < 3 then
							return true, slot7.nick
						end
					end
				end
			end
		end
	end

	return false
end

function slot88()
	slot0, slot1, slot2 = getCharCoordinates(PLAYER_PED)

	if uv0.farm.locked_target then
		if sampIs3dTextDefined(uv0.farm.locked_target.id) then
			slot6, slot7, slot8, slot9, slot10 = sampGet3dTextInfoById(slot5.id)

			if slot6 then
				if slot6:find("\\xfd\\xf2\\xe0\\xef 1") then
					uv0.farm.locked_target = nil
				else
					if slot6:find("\\xc4\\xeb\\xff \\xf1\\xe1\\xee\\xf0\\xe0") or slot6:find("\\xcc\\xee\\xe6\\xed\\xee \\xf1\\xee\\xe1\\xf0\\xe0\\xf2\\xfc") then
						return {
							status = "READY",
							id = slot5.id,
							distance = getDistanceBetweenCoords3d(slot0, slot1, slot2, slot8, slot9, slot10),
							position = {
								x = slot8,
								y = slot9,
								z = slot10
							},
							text = slot6,
							color = slot7
						}
					end

					slot12, slot13 = slot6:match("(%d+):(%d+)")

					if (slot12 and tonumber(slot12) * 60 + tonumber(slot13) or math.huge) < 3 then
						if (slot6:find("\\xd5\\xeb\\xee\\xef\\xee\\xea") and uv0.farm.collect_cotton[0] or (slot6:find("\\xcb\\xe5\\xed") or slot6:find("˸\\xed")) and uv0.farm.collect_linen[0]) and not uv1(slot8, slot9, slot10) then
							return {
								status = "GROWING",
								id = slot5.id,
								distance = getDistanceBetweenCoords3d(slot0, slot1, slot2, slot8, slot9, slot10),
								position = {
									x = slot8,
									y = slot9,
									z = slot10
								},
								timeLeft = slot14,
								text = slot6,
								color = slot7
							}
						end
					end
				end
			end
		end

		uv0.farm.locked_target = nil
	end

	slot5, slot6 = nil
	slot8 = math.huge

	for slot12 = 0, 2047 do
		if slot3(slot12) then
			slot13, slot14, slot15, slot16, slot17 = slot4(slot12)

			if slot13 and getDistanceBetweenCoords3d(slot0, slot1, slot2, slot15, slot16, slot17) < 300 and not slot13:find("\\xfd\\xf2\\xe0\\xef 1") then
				if (slot13:find("\\xd5\\xeb\\xee\\xef\\xee\\xea") and uv0.farm.collect_cotton[0] or (slot13:find("\\xcb\\xe5\\xed") or slot13:find("˸\\xed")) and uv0.farm.collect_linen[0]) and not uv1(slot15, slot16, slot17) then
					if slot13:find("\\xcc\\xee\\xe6\\xed\\xee \\xf1\\xee\\xe1\\xf0\\xe0\\xf2\\xfc") or slot13:find("\\xc4\\xeb\\xff \\xf1\\xe1\\xee\\xf0\\xe0") then
						if slot18 < math.huge then
							slot7 = slot18
							slot5 = {
								status = "READY",
								id = slot12,
								distance = slot18,
								position = {
									x = slot15,
									y = slot16,
									z = slot17
								},
								text = slot13,
								color = slot14
							}
						end
					else
						slot21, slot22 = slot13:match("(%d+):(%d+)")

						if slot21 and slot22 and slot8 > tonumber(slot21) * 60 + tonumber(slot22) and slot18 < 150 then
							slot8 = slot23
							slot6 = {
								status = "GROWING",
								id = slot12,
								distance = slot18,
								timeLeft = slot23,
								position = {
									x = slot15,
									y = slot16,
									z = slot17
								},
								text = slot13,
								color = slot14
							}
						end
					end
				end
			end
		end
	end

	if slot5 then
		uv0.farm.locked_target = {
			id = slot5.id,
			position = slot5.position
		}

		return slot5
	elseif slot6 then
		uv0.farm.locked_target = {
			id = slot6.id,
			position = slot6.position
		}

		return slot6
	end

	return {
		distance = 999,
		status = "NONE"
	}
end

function slot89()
	slot0, slot1, slot2 = getCharCoordinates(uv0.ped)
	slot3 = nil

	for slot8 = 0, 2047 do
		if sampIs3dTextDefined(slot8) then
			slot9, slot10, slot11, slot12, slot13 = sampGet3dTextInfoById(slot8)

			if slot9 and slot11 and slot12 and slot13 then
				if (slot9:find("\\xd5\\xeb\\xee\\xef\\xee\\xea") and uv1.farm.collect_cotton[0] or (slot9:find("\\xcb\\xe5\\xed") or slot9:find("˸\\xed")) and uv1.farm.collect_linen[0]) and uv2(slot0, slot1, slot2, slot11, slot12, slot13) < 200 then
					slot17, slot18 = slot9:match("(%d+):(%d+)")

					if slot17 and slot18 and tonumber(slot17) * 60 + tonumber(slot18) <= 10 and slot19 < 11 then
						slot4 = slot19
						slot3 = {
							id = slot8,
							x = slot11,
							y = slot12,
							z = slot13,
							timeLeft = slot19
						}
					end
				end
			end
		end
	end

	return slot3
end

function slot90()
	slot0, slot1, slot2 = getCharCoordinates(uv0.ped)
	slot3 = nil

	for slot8 = 0, 2047 do
		if sampIs3dTextDefined(slot8) then
			slot9, slot10, slot11, slot12, slot13 = sampGet3dTextInfoById(slot8)

			if slot9 and slot11 and slot12 and slot13 then
				if (slot9:find("\\xd5\\xeb\\xee\\xef\\xee\\xea") and uv1.farm.collect_cotton[0] or (slot9:find("\\xcb\\xe5\\xed") or slot9:find("˸\\xed")) and uv1.farm.collect_linen[0]) and uv2(slot0, slot1, slot2, slot11, slot12, slot13) < 200 then
					slot17, slot18 = slot9:match("(%d+):(%d+)")

					if slot17 and slot18 and tonumber(slot17) * 60 + tonumber(slot18) <= 10 and slot19 < 11 then
						slot4 = slot19
						slot3 = {
							id = slot8,
							x = slot11,
							y = slot12,
							z = slot13,
							timeLeft = slot19
						}
					end
				end
			end
		end
	end

	return slot3
end

function slot91()
	slot0, slot1, slot2 = getCharCoordinates(uv0.ped)
	uv1.roam_waypoints = {}
	uv1.wp_idx = 1
	slot3 = {}

	for slot7 = 0, 2047 do
		if sampIs3dTextDefined(slot7) then
			slot8, slot9, slot10, slot11, slot12 = sampGet3dTextInfoById(slot7)

			if slot8 and slot10 and slot11 and slot12 and (not uv1.priority_id or slot7 ~= uv1.priority_id) then
				if (slot8:find("\\xd5\\xeb\\xee\\xef\\xee\\xea") and uv2.farm.collect_cotton[0] or (slot8:find("\\xcb\\xe5\\xed") or slot8:find("˸\\xed")) and uv2.farm.collect_linen[0]) and uv3(slot0, slot1, slot2, slot10, slot11, slot12) < 300 and slot15 > 10 then
					table.insert(slot3, {
						x = slot10,
						y = slot11,
						z = slot12
					})
				end
			end
		end
	end

	if #slot3 == 0 then
		for slot8 = 1, math.random(2, 4) do
			slot9 = math.random() * math.pi * 2
			slot10 = math.random(15, 50)

			table.insert(uv1.roam_waypoints, {
				x = slot0 + math.cos(slot9) * slot10,
				y = slot1 + math.sin(slot9) * slot10,
				z = slot2
			})
		end
	else
		slot4 = math.min(#slot3, math.random(2, 5))

		for slot9 = 1, #slot3 do
		end

		for slot9 = #{
			[slot9] = slot9
		}, 2, -1 do
			slot10 = math.random(slot9)
			slot5[slot10] = slot5[slot9]
			slot5[slot9] = slot5[slot10]
		end

		for slot9 = 1, slot4 do
			table.insert(uv1.roam_waypoints, slot3[slot5[slot9]])
		end
	end

	uv1.last_roam_stop = os.clock()
end

function slot92()
	if uv0.active or not uv1.farm.prot_fake_roam[0] then
		return
	end

	uv0.active = true
	uv0.start_time = os.clock()
	uv0.priority_target = nil
	uv0.priority_id = nil
	uv0.waiting_at_target = false

	uv2()
	add_log("{BBBBFF}[\\xcf\\xee\\xe8\\xf1\\xea] \\xcd\\xe0\\xf7\\xe8\\xed\\xe0\\xfe \\xef\\xee\\xe8\\xf1\\xea \\xe1\\xeb\\xe8\\xe6\\xe0\\xe9\\xf8\\xe5\\xe3\\xee \\xf1\\xee\\xe7\\xf0\\xe5\\xe2\\xe0\\xfe\\xf9\\xe5\\xe3\\xee \\xea\\xf3\\xf1\\xf2\\xe0")
end

function slot93()
	if not uv0.active then
		return false
	end

	if uv0.scan_interval <= os.clock() - uv0.last_scan then
		uv0.last_scan = slot0

		if uv0.priority_id then
			if sampIs3dTextDefined(uv0.priority_id) then
				slot1, slot2, slot3, slot4, slot5 = sampGet3dTextInfoById(uv0.priority_id)

				if slot1 and slot3 and slot4 and slot5 then
					if slot1:find("\\xcc\\xee\\xe6\\xed\\xee \\xf1\\xee\\xe1\\xf0\\xe0\\xf2\\xfc") or slot1:find("\\xc4\\xeb\\xff \\xf1\\xe1\\xee\\xf0\\xe0") then
						uv0.waiting_at_target = false

						navRunToPoint(slot3, slot4, slot5)

						uv1.sync_enabled = true
						slot6, slot7, slot8 = getCharCoordinates(uv2.ped)

						if uv3(slot6, slot7, slot8, slot3, slot4, slot5) < 1.3 then
							uv0.active = false

							stop_moving_keys()
							resetNavPath()

							return false
						end

						uv0.roam_waypoints = {}

						return true
					else
						slot6, slot7 = slot1:match("(%d+):(%d+)")

						if slot6 and slot7 then
							if tonumber(slot6) * 60 + tonumber(slot7) > 10 then
								uv0.priority_target = nil
								uv0.priority_id = nil
								uv0.waiting_at_target = false

								if #uv0.roam_waypoints == 0 then
									uv4()
								end
							elseif slot8 <= 10 then
								if not uv0.waiting_at_target then
									slot9, slot10, slot11 = getCharCoordinates(uv2.ped)

									if uv5(slot9, slot10, slot3, slot4) < 2.5 then
										uv0.waiting_at_target = true
										uv0.roam_waypoints = {}

										stop_moving_keys()
										resetNavPath()
										add_log("{BBBBFF}[\\xcf\\xee\\xe8\\xf1\\xea] \\xc6\\xe4\\xf3 \\xea\\xf3\\xf1\\xf2 ~" .. slot8 .. "\\xf1\\xe5\\xea")
									else
										navRunToPoint(slot3, slot4, slot5)

										uv1.sync_enabled = true

										return true
									end
								end

								return true
							end
						end
					end
				else
					uv0.priority_target = nil
					uv0.priority_id = nil
					uv0.waiting_at_target = false
				end
			else
				uv0.priority_target = nil
				uv0.priority_id = nil
				uv0.waiting_at_target = false
			end
		end

		if not uv0.priority_target and uv6() then
			uv0.priority_target = slot1
			uv0.priority_id = slot1.id
			uv0.roam_waypoints = {}

			add_log(string.format("{BBBBFF}[\\xcf\\xee\\xe8\\xf1\\xea] \\xca\\xf3\\xf1\\xf2 \\xf1\\xee\\xe7\\xf0\\xe5\\xe2\\xe0\\xe5\\xf2 (%d\\xf1\\xe5\\xea), \\xe1\\xe5\\xe3\\xf3 \\xea \\xed\\xe5\\xec\\xf3", slot1.timeLeft))
		end
	end

	if uv0.waiting_at_target or uv0.priority_id then
		return true
	end

	if #uv0.roam_waypoints == 0 then
		uv0.active = false

		stop_moving_keys()
		resetNavPath()

		return false
	end

	if not uv0.roam_waypoints[uv0.wp_idx] then
		uv0.active = false

		stop_moving_keys()
		resetNavPath()

		return false
	end

	slot2, slot3, slot4 = getCharCoordinates(uv2.ped)

	if uv5(slot2, slot3, slot1.x, slot1.y) < 2 then
		uv0.wp_idx = uv0.wp_idx + 1

		if uv0.wp_idx > #uv0.roam_waypoints then
			uv4()
		end
	end

	if uv0.wp_idx <= #uv0.roam_waypoints then
		slot1 = uv0.roam_waypoints[uv0.wp_idx]

		navRunToPoint(slot1.x, slot1.y, slot1.z)

		uv1.sync_enabled = true
	end

	return true
end

function slot94(slot0)
	slot1, slot2 = pcall(sampGetPlayerIdByNickname, slot0)

	if not slot1 or not slot2 or slot2 < 0 then
		return false
	end

	slot3, slot4 = pcall(sampIsPlayerConnected, slot2)

	return slot3 and slot4
end

function slot95()
	return uv0 or uv1.active and uv2.farm.locked_target ~= nil
end

function update_movement()
	if uv0.pause_bot[0] then
		uv1.active = false

		stop_moving_keys()

		if not isCharSittingInAnyCar(uv2.ped) then
			clearCharTasksImmediately(uv2.ped)
		end

		return
	end

	if isCharInAnyCar(uv2.ped) then
		uv1.active = false

		stop_moving_keys()

		uv0.farm.current_status = "IN VEHICLE"

		return
	end

	if uv0.farm.auto_eat[0] and uv2.satiety and uv0.farm.eat_percent and uv2.satiety <= uv0.farm.eat_percent[0] and not uv2.eating_in_progress then
		lua_thread.create(function ()
			uv0.eating_in_progress = true

			add_log("{FFFF00}[\\xc0\\xe2\\xf2\\xee-\\xe5\\xe4\\xe0] \\xd1\\xfb\\xf2\\xee\\xf1\\xf2\\xfc: " .. uv0.satiety .. "%. \\xc8\\xf1\\xef\\xee\\xeb\\xfc\\xe7\\xf3\\xfe \\xe5\\xe4\\xf3...")

			if ({
				"/cheeps",
				"/jfish",
				"/jmeat",
				"/meatbag"
			})[uv1.farm.eat_method[0] + 1] then
				sampSendChat(slot2)
				wait(3500)
			end

			uv0.eating_in_progress = false
		end)
	end

	if uv3() then
		uv0.farm.current_status = "ROAMING"

		return
	end

	slot0, slot1, slot2 = getCharCoordinates(uv2.ped)

	if not uv4() or not slot3.position then
		uv1.active = false

		stop_moving_keys()

		uv0.farm.current_status = "IDLE"

		if not isCharSittingInAnyCar(uv2.ped) then
			clearCharTasksImmediately(uv2.ped)
		end

		return
	end

	if slot3.status == "READY" then
		uv0.farm.current_status = "RUNNING"

		if uv5(slot0, slot1, slot3.position.x, slot3.position.y) < 1.3 then
			uv1.active = false

			stop_moving_keys()
			clearCharTasksImmediately(uv2.ped)

			uv0.farm.current_status = "COLLECTING"

			if not uv6.active then
				uv6.active = true
				uv6.start_time = os.time()
			end

			press_alt_task()

			return
		end
	elseif slot3.status == "GROWING" then
		if slot4 < 2.5 then
			uv1.active = false

			stop_moving_keys()
			clearCharTasksImmediately(uv2.ped)
			uv7()

			if uv8.active then
				uv0.farm.current_status = "ROAMING"
			end

			return
		end

		uv0.farm.current_status = "RUNNING"
	end

	uv1.target_z = slot3.position.z
	uv1.target_y = slot3.position.y
	uv1.target_x = slot3.position.x
	uv1.active = true

	navRunToPoint(uv1.target_x, uv1.target_y, uv1.target_z)
end

slot96 = {}

function slot97(slot0, slot1, slot2, slot3)
	slot4 = uv0.GetWindowDrawList()
	slot5 = uv0.GetCursorScreenPos()
	slot6 = uv0.GetIO()
	slot2 = slot2 or 36
	slot7 = (slot3 or 18) / 2

	if not uv1[tostring(slot1)] then
		uv1[slot8] = slot1[0] and 1 or 0
	end

	if uv0.IsMouseHoveringRect(slot5, uv0.ImVec2(slot5.x + slot2, slot5.y + slot3)) and uv0.IsMouseClicked(0) then
		slot1[0] = not slot1[0]
	end

	if slot1[0] then
		uv1[slot8] = math.min(uv1[slot8] + slot6.DeltaTime * 10, 1)
	else
		uv1[slot8] = math.max(uv1[slot8] - slot6.DeltaTime * slot10, 0)
	end

	slot11 = uv1[slot8]
	slot12 = uv0.ImVec4(0.3, 0.3, 0.3, 1)
	slot13 = uv0.ImVec4(uv2.theme.accent[0], uv2.theme.accent[1], uv2.theme.accent[2], 1)

	slot4:AddRectFilled(slot5, uv0.ImVec2(slot5.x + slot2, slot5.y + slot3), uv0.ColorConvertFloat4ToU32(uv0.ImVec4(slot12.x + (slot13.x - slot12.x) * slot11, slot12.y + (slot13.y - slot12.y) * slot11, slot12.z + (slot13.z - slot12.z) * slot11, 1)), slot7)
	slot4:AddCircleFilled(uv0.ImVec2(slot5.x + slot7 + (slot2 - slot3) * slot11, slot5.y + slot7), slot7 - 2, uv0.GetColorU32(uv0.Col.Text))
	uv0.Dummy(uv0.ImVec2(slot2, slot3))
	uv0.SameLine()
	uv0.SetCursorPosY(uv0.GetCursorPosY() + 1)
	uv0.Text(slot0)
end

slot98 = {}

function HeaderButton(slot0, slot1, slot2)
	slot3 = require("mimgui")
	slot4 = slot3.GetWindowDrawList()
	slot5 = slot3.ColorConvertFloat4ToU32
	slot6 = false
	slot7 = slot1:gsub("##.*$", "")
	slot8 = {
		0.5,
		0.3
	}
	slot9 = slot3.GetStyle().Colors
	slot10 = {
		idle = slot9[slot3.Col.TextDisabled],
		hovr = slot9[slot3.Col.Text],
		slct = slot3.ImVec4(uv0.theme.accent[0], uv0.theme.accent[1], uv0.theme.accent[2], 1)
	}

	if not uv1[slot1] then
		uv1[slot1] = {
			color = slot0 and slot10.slct or slot10.idle,
			clock = os.clock(),
			h = {
				state = slot0,
				alpha = slot0 and 1 or 0,
				clock = os.clock()
			}
		}
	end

	slot11 = uv1[slot1]

	function slot12(slot0, slot1, slot2, slot3)
		return os.clock() - slot2 >= 0 and slot0 + (slot1 - slot0) / slot3 * slot4 or slot0
	end

	function slot13(slot0, slot1)
		return uv0.ImVec4(slot0.x, slot0.y, slot0.z, slot1 or 1)
	end

	slot3.BeginGroup()

	if slot2 then
		slot3.PushFont(icons_font)
		slot3.TextColored(slot11.color, slot2)
		slot3.PopFont()
		slot3.SameLine(0, 5)
	end

	slot14 = slot3.GetCursorScreenPos()

	slot3.PushFont(font18)
	slot3.TextColored(slot11.color, slot7)
	slot3.PopFont()

	slot15 = slot3.GetItemRectSize()
	slot17 = slot3.IsItemClicked()

	if slot11.h.state ~= slot3.IsItemHovered() and not slot0 then
		slot11.h.state = slot16
		slot11.h.clock = os.clock()
	end

	if slot17 then
		slot11.clock = os.clock()
		slot6 = true
	end

	if os.clock() - slot11.clock <= slot8[1] then
		slot18 = os.clock() - slot11.clock
		slot19 = slot8[1]
		slot20 = slot0 and slot10.slct or slot16 and slot10.hovr or slot10.idle
		slot11.color = slot3.ImVec4(slot11.color.x + (slot20.x - slot11.color.x) * slot18 / slot19, slot11.color.y + (slot20.y - slot11.color.y) * slot18 / slot19, slot11.color.z + (slot20.z - slot11.color.z) * slot18 / slot19, slot11.color.w + (slot20.w - slot11.color.w) * slot18 / slot19)
	else
		slot11.color = slot0 and slot10.slct or slot16 and slot10.hovr or slot10.idle
	end

	if slot11.h.clock then
		if os.clock() - slot11.h.clock <= slot8[2] then
			slot11.h.alpha = slot12(slot11.h.alpha, slot11.h.state and 1 or 0, slot11.h.clock, slot8[2])
		else
			slot11.h.alpha = slot11.h.state and 1 or 0

			if not slot11.h.state then
				slot11.h.clock = nil
			end
		end

		slot18 = slot14.x + slot15.x / 2
		slot19 = slot14.y + slot15.y + 3
		slot20 = slot15.x / 2

		slot4:AddLine(slot3.ImVec2(slot18 - slot20 * slot11.h.alpha, slot19), slot3.ImVec2(slot18 + slot20 * slot11.h.alpha, slot19), slot5(slot13(slot11.color, slot11.h.alpha)), 3)
	end

	slot3.EndGroup()

	return slot6
end

function slot99()
	return uv0.ImVec4(1, 1, 1, 1)
end

function slot100(slot0)
	if not slot0 or slot0 <= 0 then
		return uv0("\\xed\\xe5 \\xe7\\xe0\\xe4\\xe0\\xed")
	end

	for slot5 = 1, 12 do
	end

	if ({
		[186.0] = ";",
		[91.0] = "LWin",
		[109.0] = "Num -",
		[39.0] = "Right",
		[173.0] = "Mute",
		[20.0] = "CapsLock",
		[174.0] = "Vol-",
		[220.0] = "\\",
		[175.0] = "Vol+",
		[33.0] = "PgUp",
		[17.0] = "Ctrl",
		[221.0] = "]",
		[192.0] = "~",
		[36.0] = "Home",
		[44.0] = "PrtSc",
		[107.0] = "Num +",
		[35.0] = "End",
		[37.0] = "Left",
		[106.0] = "Num *",
		[45.0] = "Ins",
		[219.0] = "[",
		[187.0] = "=",
		[34.0] = "PgDown",
		[38.0] = "Up",
		[189.0] = "-",
		[222.0] = "'",
		[188.0] = ",",
		[191.0] = "/",
		[111.0] = "Num /",
		[190.0] = ".",
		[144.0] = "NumLock",
		[177.0] = "Prev",
		[110.0] = "Num .",
		[176.0] = "Next",
		[179.0] = "Play",
		[32.0] = "Space",
		[92.0] = "RWin",
		[40.0] = "Down",
		[93.0] = "Apps",
		[19.0] = "Pause",
		[9.0] = "Tab",
		[13.0] = "Enter",
		[111 + slot5] = "F" .. slot5
	})[slot0] then
		return slot1[slot0]
	end

	if slot0 >= 48 and slot0 <= 57 then
		return string.char(slot0)
	end

	if slot0 >= 65 and slot0 <= 90 then
		return (string.char(slot0) == "W" or slot2 == "A" or slot2 == "S" or slot2 == "D") and string.format("VK_%d", slot0) or slot2
	end

	if slot0 >= 96 and slot0 <= 105 then
		return "Num " .. slot0 - 96
	end

	return string.format("VK_%d", slot0)
end

slot101 = false
slot102 = false
slot103 = {
	current = "Dashboard",
	list = {
		{
			id = "Dashboard",
			icon = "",
			name = slot16("\\xce \\xf1\\xea\\xf0\\xe8\\xef\\xf2\\xe5")
		},
		{
			id = "AutoFarm",
			icon = "",
			name = slot16("\\xd4\\xe5\\xf0\\xec\\xe0")
		},
		{
			id = "Telegram",
			icon = "",
			name = slot16("\\xd2\\xe5\\xeb\\xe5\\xe3\\xf0\\xe0\\xec")
		},
		{
			id = "Settings",
			icon = "",
			name = slot16("\\xce\\xef\\xf6\\xe8\\xe8")
		},
		{
			id = "Other",
			icon = "",
			name = slot16("\\xcf\\xf0\\xee\\xf7\\xe5\\xe5")
		},
		{
			id = "Logging",
			icon = "",
			name = slot16("\\xcb\\xee\\xe3\\xe8")
		}
	}
}

slot0.OnFrame(function ()
	return uv0[0] and not uv1.farm.disable_splash[0]
end, function (slot0)
	if uv0 < 1 then
		uv0 = uv0 + 0.02
	end

	slot1 = os.clock() * 2
	slot5 = uv1.ImVec4(math.sin(slot1) * 0.5 + 0.5, math.sin(slot1 + 2) * 0.5 + 0.5, math.sin(slot1 + 4) * 0.5 + 0.5, uv0)
	slot6, slot7 = getScreenResolution()

	uv1.SetNextWindowPos(uv1.ImVec2(slot6 / 2, slot7 / 2), uv1.Cond.Always, uv1.ImVec2(0.5, 0.5))
	uv1.SetNextWindowSize(uv1.ImVec2(600, 320))
	uv1.PushStyleColor(uv1.Col.WindowBg, uv1.ImVec4(0, 0, 0, uv0))
	uv1.PushStyleColor(uv1.Col.Border, slot5)
	uv1.PushStyleColor(uv1.Col.Button, uv1.ImVec4(0.05, 0.05, 0.05, uv0))
	uv1.PushStyleColor(uv1.Col.ButtonHovered, slot5)
	uv1.PushStyleVarFloat(uv1.StyleVar.WindowRounding, 15)
	uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)
	uv1.PushStyleVarFloat(uv1.StyleVar.WindowBorderSize, 2)
	uv1.PushStyleVarFloat(uv1.StyleVar.Alpha, uv0)

	if uv1.Begin("##Splash", uv2, uv1.WindowFlags.NoTitleBar + uv1.WindowFlags.NoResize + uv1.WindowFlags.NoMove) then
		if uv3 then
			uv1.SetCursorPos(uv1.ImVec2(25, 40))
			uv1.Image(uv3, uv1.ImVec2(550, 185))
		end

		if not uv4 then
			slot8 = uv5("\\xc4\\xee\\xe1\\xf0\\xee \\xef\\xee\\xe6\\xe0\\xeb\\xee\\xe2\\xe0\\xf2\\xfc")

			uv1.PushFont(font24)
			uv1.SetCursorPos(uv1.ImVec2((600 - uv1.CalcTextSize(slot8).x) / 2, 215))
			uv1.TextColored(slot5, slot8)
			uv1.PopFont()
			uv1.SetCursorPos(uv1.ImVec2(250, 260))
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameBorderSize, 1)

			if uv1.Button(uv5("\\xc2\\xee\\xe9\\xf2\\xe8"), uv1.ImVec2(100, 35)) then
				uv4 = true
				uv6 = os.clock()
			end

			uv1.PopStyleVar()
		else
			if os.clock() - uv6 >= 3 then
				uv2[0] = false
				uv7.window_open[0] = true
				uv4 = false
			end

			uv1.SetCursorPos(uv1.ImVec2(275, 240))
			uv1.GradientSpinner(25, 3, {
				slot5.x,
				slot5.y,
				slot5.z,
				slot5.w
			}, 6, 45)

			slot9 = uv5("\\xc7\\xe0\\xe3\\xf0\\xf3\\xe7\\xea\\xe0...")

			uv1.SetCursorPos(uv1.ImVec2((600 - uv1.CalcTextSize(slot9).x) / 2, 295))
			uv1.TextDisabled(slot9)
		end

		uv1.End()
	end

	uv1.PopStyleVar(4)
	uv1.PopStyleColor(4)
end)
slot0.OnFrame(function ()
	return uv0.window_open[0]
end, function ()
	uv0()

	slot0, slot1 = getScreenResolution()

	uv1.SetNextWindowPos(uv1.ImVec2(slot0 / 2, slot1 / 2), uv1.Cond.FirstUseEver, uv1.ImVec2(0.5, 0.5))
	uv1.SetNextWindowSize(uv1.ImVec2(960, 720), uv1.Cond.Always)
	uv1.SetNextWindowBgAlpha(uv2.theme.global_alpha[0])

	if not uv1.Begin(uv3("NexaArizona v1.5.5##main"), uv2.window_open, uv1.WindowFlags.NoCollapse + uv1.WindowFlags.NoResize + uv1.WindowFlags.NoTitleBar) then
		uv1.End()

		return
	end

	uv1.SetCursorPos(uv1.ImVec2(20, 15))
	uv1.Text(uv3("NexaArizona v1.5.5 | ") .. uv3(tostring(uv2.active_tab)))
	uv1.SameLine(uv1.GetWindowWidth() - 40)

	if uv1.Button("X", uv1.ImVec2(25, 25)) then
		uv2.window_open[0] = false
	end

	uv1.Separator()
	uv1.SetCursorPosX(215)

	for slot6, slot7 in ipairs(uv4.list) do
		if HeaderButton(uv4.current == slot7.id, slot7.name .. "##" .. slot7.id, slot7.icon) then
			uv4.current = slot7.id
			uv2.active_tab = slot7.id
		end

		if slot6 ~= #uv4.list then
			uv1.SameLine(nil, 12)
		end
	end

	if uv1.BeginChild("##left_panel", uv1.ImVec2(200, 0), true) then
		slot3 = uv1.GetContentRegionAvail().x

		uv1.Spacing()
		uv1.PushFont(font18)
		uv1.TextColored(uv5(), "NexaArizona")
		uv1.PopFont()
		uv1.TextDisabled("v1.5.5")
		uv1.Spacing()
		uv1.Separator()
		uv1.Spacing()
		uv1.TextColored(uv5(), uv3("\\xce \\xf1\\xea\\xf0\\xe8\\xef\\xf2\\xe5"))
		uv1.Spacing()
		uv1.TextWrapped(uv3("\\xd1\\xea\\xf0\\xe8\\xef\\xf2 \\xed\\xe0 \\xeb\\xb8\\xed \\xe8 \\xf5\\xeb\\xee\\xef\\xee\\xea. \\xc1\\xcb\\xdf\\xd2\\xdc \\xdf \\xd3\\xc6\\xc5 \\xcd\\xc5 \\xcc\\xce\\xc3\\xd3 \\xdf \\xd3\\xc6\\xc5 \\xca\\xd0\\xc0\\xd1\\xcd\\xdb\\xc9 \\xdf \\xc7\\xc0\\xc5\\xc1\\xc0\\xcb\\xd1\\xdfv1.5.5."))
		uv1.Spacing()
		uv1.Separator()
		uv1.Spacing()
		uv1.SetCursorPosY(uv1.GetWindowHeight() - 70)

		slot4, slot5, slot6, slot7 = nil

		if uv2.pause_bot[0] then
			slot4 = uv3("\\xd0\\xc0\\xc7\\xc1\\xcb\\xce\\xca\\xc8\\xd0\\xce\\xc2\\xc0\\xd2\\xdc")
			slot5 = uv1.ImVec4(1, 0.6, 0, 0.6)
			slot6 = uv1.ImVec4(1, 0.7, 0.1, 0.8)
			slot7 = uv1.ImVec4(0.8, 0.5, 0, 1)
		elseif uv2.farm.running[0] then
			slot4 = uv3("\\xce\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xe8\\xf2\\xfc")
			slot5 = uv1.ImVec4(0.85, 0.25, 0.25, 0.6)
			slot6 = uv1.ImVec4(1, 0.3, 0.3, 0.8)
			slot7 = uv1.ImVec4(0.6, 0.1, 0.1, 1)
		else
			slot4 = uv3("\\xc7\\xe0\\xef\\xf3\\xf1\\xf2\\xe8\\xf2\\xfc")
			slot5 = uv1.ImVec4(0.15, 0.7, 0.25, 0.6)
			slot6 = uv1.ImVec4(0.2, 0.85, 0.3, 0.8)
			slot7 = uv1.ImVec4(0.1, 0.5, 0.1, 1)
		end

		uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

		if uv1.CustomButton(slot4, slot5, slot6, slot7, uv1.ImVec2(slot3, 45)) then
			if uv2.pause_bot[0] then
				uv2.pause_bot[0] = false
			elseif uv2.farm.running[0] then
				uv2.farm.running[0] = false

				emergency_stop()
				send_session_report("\\xd0\\xf3\\xf7\\xed\\xe0\\xff \\xee\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xea\\xe0")
			else
				uv2.farm.running[0] = true
				uv2.farm.res_counter.cotton = 0
				uv2.farm.res_counter.linen = 0
				uv2.farm.res_counter.rare = 0
				uv2.farm.stats.start_time = os.time()

				resetNavPath()

				if uv2.ma.enabled[0] and #uv6.list > 0 then
					for slot12, slot13 in ipairs(uv6.list) do
						if uv8(slot13.nick) then
							slot13.cotton = 0
							slot13.linen = 0
							slot13.rare = 0
							slot13.start_time = os.time()
							slot8 = uv7.nick .. ", " .. slot13.nick
						else
							add_log("{FF9933}[\\xcc\\xf3\\xeb\\xfc\\xf2\\xe8] " .. slot13.nick .. " \\xed\\xe5 \\xed\\xe0\\xe9\\xe4\\xe5\\xed \\xed\\xe0 \\xf1\\xe5\\xf0\\xe2\\xe5\\xf0\\xe5!")
						end
					end

					add_log("{33CCFF}[\\xcc\\xf3\\xeb\\xfc\\xf2\\xe8] \\xd3\\xf7\\xb8\\xf2 \\xe0\\xea\\xea\\xe0\\xf3\\xed\\xf2\\xee\\xe2: " .. slot8)
				end

				send_telegram("\\xc1\\xee\\xf2 \\xe7\\xe0\\xef\\xf3\\xf9\\xe5\\xed!\n\\xc8\\xe3\\xf0\\xee\\xea: " .. uv7.nick)
			end
		end

		uv1.PopStyleVar()
		uv1.EndChild()
	end

	uv1.SameLine()

	if uv1.BeginChild("##content", uv1.ImVec2(0, -30), true) then
		if uv2.active_tab == "Dashboard" then
			slot6 = uv1.GetStyle().Colors[uv1.Col.Text]
			slot7 = uv1.GetStyle().Colors[uv1.Col.TextDisabled]
			slot8 = uv1.GetWindowDrawList()

			uv1.PushFont(font20)
			uv1.TextColored(uv5(), uv3("\\xc3\\xeb\\xe0\\xe2\\xed\\xe0\\xff \\xef\\xe0\\xed\\xe5\\xeb\\xfc"))
			uv1.PopFont()
			uv1.TextDisabled(uv3("\\xc4\\xee\\xe1\\xf0\\xee \\xef\\xee\\xe6\\xe0\\xeb\\xee\\xe2\\xe0\\xf2\\xfc, ") .. (uv7.nick ~= "" and uv7.nick or uv3("\\xcf\\xee\\xeb\\xfc\\xe7\\xee\\xe2\\xe0\\xf2\\xe5\\xeb\\xfc")))
			uv1.SetCursorPos(uv1.ImVec2(uv1.GetContentRegionAvail().x - 190, uv1.GetCursorPosY()))
			uv1.BeginGroup()
			uv1.TextDisabled(uv3("\\xc2\\xe5\\xf0\\xf1\\xe8\\xff: ") .. uv9)

			if uv10 then
				uv1.PushStyleColor(uv1.Col.Button, uv1.ImVec4(0.2, 0.6, 0.2, 0.7))
				uv1.PushStyleColor(uv1.Col.ButtonHovered, uv1.ImVec4(0.3, 0.7, 0.3, 1))

				if uv1.Button(uv3("\\xce\\xe1\\xed\\xee\\xe2\\xe8\\xf2\\xfc \\xe4\\xee ") .. uv11, uv1.ImVec2(190, 26)) then
					startUpdate()
				end

				uv1.PopStyleColor(2)
			elseif uv1.Button(uv3("\\xcf\\xf0\\xee\\xe2\\xe5\\xf0\\xe8\\xf2\\xfc \\xee\\xe1\\xed\\xee\\xe2\\xeb\\xe5\\xed\\xe8\\xe5"), uv1.ImVec2(190, 26)) then
				checkUpdate(true)
			end

			uv1.TextDisabled(uv12)
			uv1.EndGroup()
			uv1.SetCursorPosY(slot9 + 55)
			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()

			slot10 = (slot4 - 30) / 4
			slot11 = 56

			function slot12(slot0, slot1, slot2)
				slot3 = uv0.GetCursorScreenPos()

				uv1:AddRectFilled(slot3, uv0.ImVec2(slot3.x + uv2, slot3.y + uv3), uv0.ColorConvertFloat4ToU32(uv0.GetStyle().Colors[uv0.Col.ChildBg]), 6)
				uv1:AddText(uv0.ImVec2(slot3.x + 10, slot3.y + 6), uv0.ColorConvertFloat4ToU32(uv4), slot0)
				uv1:AddText(uv0.ImVec2(slot3.x + 10, slot3.y + 28), uv0.ColorConvertFloat4ToU32(slot2 or uv5), slot1)
				uv0.Dummy(uv0.ImVec2(uv2, uv3))
			end

			slot13 = uv13()

			slot12(uv3("\\xd1\\xf2\\xe0\\xf2\\xf3\\xf1"), uv3(slot13.text), slot13.color)
			uv1.SameLine(nil, 10)
			slot12(uv3("FPS"), tostring(uv14.value), uv14.value > 30 and uv1.ImVec4(0.4, 0.85, 0.4, 1) or uv1.ImVec4(0.9, 0.4, 0.4, 1))
			uv1.SameLine(nil, 10)
			slot12(uv3("NavMesh"), uv15.nav and uv3("\\xc3\\xee\\xf2\\xee\\xe2") or uv3("\\xc7\\xe0\\xe3\\xf0\\xf3\\xe7\\xea\\xe0"), uv15.nav and uv1.ImVec4(0.4, 0.7, 0.9, 1) or uv1.ImVec4(0.9, 0.6, 0.2, 1))
			uv1.SameLine(nil, 10)
			slot12(uv3("\\xd1\\xe5\\xf1\\xf1\\xe8\\xff"), uv2.farm.running[0] and uv3("\\xc0\\xea\\xf2\\xe8\\xe2\\xed\\xe0") or uv3("\\xce\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xeb\\xe5\\xed\\xe0"), uv2.farm.running[0] and uv1.ImVec4(0.4, 0.85, 0.4, 1) or slot7)
			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()

			slot14 = uv2.farm.running[0] and os.time() - uv2.farm.stats.start_time or 0

			uv1.TextColored(slot5, uv3("\\xc8\\xed\\xf4\\xee\\xf0\\xec\\xe0\\xf6\\xe8\\xff"))
			uv1.Spacing()

			function slot18(slot0, slot1)
				uv0.Text(slot0)
				uv0.SameLine(uv1 * 0.35)
				uv0.TextDisabled(tostring(slot1))
				uv0.Spacing()
			end

			slot18(uv3("\\xc0\\xea\\xea\\xe0\\xf3\\xed\\xf2:"), uv7.nick)
			slot18(uv3("\\xc2\\xf0\\xe5\\xec\\xff \\xf0\\xe0\\xe1\\xee\\xf2\\xfb:"), string.format("%02d:%02d:%02d", math.floor(slot14 / 3600), math.floor(slot14 % 3600 / 60), slot14 % 60))
			slot18(uv3("\\xd1\\xee\\xe1\\xf0\\xe0\\xed\\xee:"), string.format(uv3("\\xd5\\xeb\\xee\\xef\\xee\\xea: %s | ˸\\xed: %s | \\xd2\\xea\\xe0\\xed\\xfc: %s"), uv16(uv2.farm.res_counter.cotton), uv16(uv2.farm.res_counter.linen), uv16(uv2.farm.res_counter.rare)))
			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(slot5, uv3("\\xcf\\xee\\xe4\\xe4\\xe5\\xf0\\xe6\\xea\\xe0 \\xf0\\xe0\\xe7\\xf0\\xe0\\xe1\\xee\\xf2\\xea\\xe8"))
			uv1.TextWrapped(uv3("\\xc4\\xee\\xed\\xe0\\xf2 \\xf1\\xf3\\xe3\\xf3\\xe1\\xee \\xe4\\xee\\xe1\\xf0\\xee\\xe2\\xee\\xeb\\xfc\\xed\\xee \\xe8 \\xef\\xee \\xe6\\xe5\\xeb\\xe0\\xed\\xe8\\xfe."))
			uv1.Spacing()
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

			if uv1.CustomButton("Dalink", uv1.ImVec4(0.2, 0.55, 1, 0.6), uv1.ImVec4(0.25, 0.6, 1, 0.8), uv1.ImVec4(0.15, 0.45, 0.9, 1), uv1.ImVec2((slot4 - 10) / 2, 32)) then
				os.execute("start https://dalink.to/nexaowner")
			end

			uv1.SameLine(nil, 10)

			if uv1.CustomButton("PressF", uv1.ImVec4(0.2, 0.6, 1, 0.6), uv1.ImVec4(0.3, 0.7, 1, 0.8), uv1.ImVec4(0.1, 0.4, 0.8, 1), uv1.ImVec2(slot19, 32)) then
				os.execute("start https://pressf.com/u_5f03639d/donate")
			end

			uv1.PopStyleVar()
			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(slot5, uv3("\\xcf\\xee\\xeb\\xe5\\xe7\\xed\\xfb\\xe5 \\xf1\\xf1\\xfb\\xeb\\xea\\xe8"))
			uv1.Spacing()

			if uv1.CustomButton(uv3("BlastHack"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(slot4 / 2 - 5, 32)) then
				os.execute("start https://www.blast.hk/members/586122/")
			end

			uv1.SameLine(nil, 10)

			if uv1.CustomButton(uv3("Telegram \\xca\\xe0\\xed\\xe0\\xeb"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(slot4 / 2 - 5, 32)) then
				os.execute("start https://t.me/nexacfg")
			end

			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(slot5, uv3("\\xcf\\xee\\xf1\\xeb\\xe5\\xe4\\xed\\xe8\\xe5 \\xf1\\xee\\xe1\\xfb\\xf2\\xe8\\xff"))

			if uv1.BeginChild("##mini_log", uv1.ImVec2(slot4, 170), true) then
				if #uv2.log_lines > 0 then
					slot23 = #uv2.log_lines

					for slot23 = 1, math.min(8, slot23) do
						uv1.TextDisabled(uv3(uv2.log_lines[slot23]))
					end
				else
					uv1.TextDisabled(uv3("\\xc6\\xf3\\xf0\\xed\\xe0\\xeb \\xef\\xf3\\xf1\\xf2"))
				end

				uv1.EndChild()
			end
		elseif slot3 == "Logging" then
			slot4 = uv1.GetContentRegionAvail().x

			uv1.TextColored(uv5(), uv3("\\xc6\\xf3\\xf0\\xed\\xe0\\xeb \\xf1\\xee\\xe1\\xfb\\xf2\\xe8\\xe9"))
			uv1.Separator()
			uv1.Spacing()
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

			if uv1.CustomButton(uv2.donators_open[0] and uv3("\\xc7\\xe0\\xea\\xf0\\xfb\\xf2\\xfc \\xf1\\xef\\xe8\\xf1\\xee\\xea") or uv3("\\xc4\\xee\\xed\\xe0\\xf2\\xe5\\xf0\\xfb"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(120, 25)) then
				uv2.donators_open[0] = not uv2.donators_open[0]

				if uv2.donators_open[0] then
					uv17()
				end
			end

			uv1.PopStyleVar()
			uv1.Spacing()

			if uv2.donators_open[0] then
				uv1.SetNextWindowSize(uv1.ImVec2(300, 400), uv1.Cond.FirstUseEver)

				if uv1.Begin(uv3("\\xc1\\xeb\\xe0\\xe3\\xee\\xe4\\xe0\\xf0\\xed\\xee\\xf1\\xf2\\xfc \\xec\\xe5\\xf6\\xe5\\xed\\xe0\\xf2\\xe0\\xec"), uv2.donators_open, uv1.WindowFlags.NoCollapse) then
					if #uv18 == 0 then
						uv1.TextDisabled(uv3("\\xc7\\xe0\\xe3\\xf0\\xf3\\xe7\\xea\\xe0 \\xf1\\xef\\xe8\\xf1\\xea\\xe0..."))
					else
						uv1.TextColored(uv5(), uv3("\\xdd\\xf2\\xe8 \\xeb\\xfe\\xe4\\xe8 \\xef\\xee\\xe4\\xe4\\xe5\\xf0\\xe6\\xe0\\xeb\\xe8 \\xef\\xf0\\xee\\xe5\\xea\\xf2:"))
						uv1.Separator()

						if uv1.BeginChild("##donators_scroll", uv1.ImVec2(-1, -1), true) then
							for slot8, slot9 in ipairs(uv18) do
								uv1.SetCursorPosX(uv1.GetCursorPosX() + 5)
								DrawCustomHeart(16)
								uv1.SameLine(nil, 8)
								uv1.Text(string.format("%d. %s", slot8, uv3(slot9)))
								uv1.Spacing()
							end

							uv1.EndChild()
						end
					end

					uv1.End()
				end
			end

			if uv1.BeginChild("##log", uv1.ImVec2(0, -40), true) then
				if #uv2.log_lines > 0 then
					for slot8, slot9 in ipairs(uv2.log_lines) do
						uv1.TextWrapped(uv3(slot9))
					end
				else
					uv1.TextDisabled(uv3("\\xc6\\xf3\\xf0\\xed\\xe0\\xeb \\xef\\xf3\\xf1\\xf2..."))
				end

				uv1.EndChild()
			end

			uv1.Spacing()
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

			if uv1.CustomButton(uv3("\\xce\\xf7\\xe8\\xf1\\xf2\\xe8\\xf2\\xfc \\xe6\\xf3\\xf0\\xed\\xe0\\xeb"), uv1.ImVec4(0.85, 0.25, 0.25, 0.6), uv1.ImVec4(1, 0.3, 0.3, 0.8), uv1.ImVec4(0.6, 0.1, 0.1, 1), uv1.ImVec2(slot4, 30)) then
				uv2.log_lines = {}
			end

			uv1.PopStyleVar()
		elseif slot3 == "AutoFarm" then
			uv1.TextColored(uv5(), uv3("\\xd3\\xef\\xf0\\xe0\\xe2\\xeb\\xe5\\xed\\xe8\\xe5 \\xe0\\xe2\\xf2\\xee\\xec\\xe0\\xf2\\xe8\\xe7\\xe0\\xf6\\xe8\\xe5\\xe9"))
			uv1.Separator()
			uv1.Spacing()

			if uv1.BeginChild("##farm_settings", uv1.ImVec2(0, 160), true) then
				uv1.Columns(2, "##cols", false)
				uv1.SetColumnWidth(0, uv1.GetContentRegionAvail().x / 2 - 10)
				uv1.TextColored(uv5(), uv3("\\xd1\\xe1\\xee\\xf0 \\xf0\\xe5\\xf1\\xf3\\xf0\\xf1\\xee\\xe2:"))

				if uv1.CustomCheckbox(uv3("\\xd1\\xee\\xe1\\xe8\\xf0\\xe0\\xf2\\xfc \\xd5\\xeb\\xee\\xef\\xee\\xea"), uv2.farm.collect_cotton) then
					save_cfg()
				end

				if uv1.CustomCheckbox(uv3("\\xd1\\xee\\xe1\\xe8\\xf0\\xe0\\xf2\\xfc ˸\\xed"), uv2.farm.collect_linen) then
					save_cfg()
				end

				uv1.NextColumn()
				uv1.TextColored(uv5(), uv3("\\xcf\\xe5\\xf0\\xf1\\xee\\xed\\xe0\\xe6:"))

				if uv1.CustomCheckbox(uv3("\\xc1\\xe5\\xe3"), uv2.farm.real_run) then
					save_cfg()
				end

				if uv1.CustomCheckbox(uv3("\\xc0\\xe2\\xf2\\xee-\\xe5\\xe4\\xe0"), uv2.farm.auto_eat) then
					save_cfg()
				end

				if uv2.farm.auto_eat[0] then
					uv1.PushItemWidth(slot4 - 20)

					if uv1.Combo("##eatmethod", uv2.farm.eat_method, uv19, #uv20) then
						save_cfg()
					end

					if uv1.CustomSliderFloat(uv3("\\xcf\\xee\\xf0\\xee\\xe3 \\xe5\\xe4\\xfb"), uv2.farm.eat_percent, 1, 99, "%d%%") then
						save_cfg()
					end

					uv1.PopItemWidth()
				end

				uv1.NextColumn()

				if uv1.CustomCheckbox(uv3("\\xc0\\xe2\\xf2\\xee-\\xea\\xeb\\xee\\xed"), uv2.farm.auto_skin) then
					save_cfg()
				end

				if uv2.farm.auto_skin[0] then
					uv1.SetCursorPosX(uv1.GetCursorPosX() + 20)
					uv1.PushItemWidth(slot4 - 40)

					if uv1.CustomSliderFloat(uv3("\\xc8\\xed\\xf2\\xe5\\xf0\\xe2\\xe0\\xeb \\xf1\\xec\\xe5\\xed\\xfb"), uv2.farm.auto_skin_interval, 1, 10, uv3("%d \\xec\\xe8\\xed")) then
						save_cfg()
					end

					uv1.PopItemWidth()
					uv1.SetCursorPosX(uv1.GetCursorPosX() + 20)
					uv1.Text(uv3("\\xd3\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xeb\\xe5\\xed\\xee: ") .. string.format("%d", uv2.farm.auto_skin_interval[0]) .. uv3(" \\xec\\xe8\\xed."))
				end

				uv1.Columns(1)
				uv1.EndChild()
			end

			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("\\xc7\\xe0\\xf9\\xe8\\xf2\\xe0 \\xe8 \\xef\\xee\\xe2\\xe5\\xe4\\xe5\\xed\\xe8\\xe5:"))
			uv1.Spacing()

			if uv1.BeginChild("##protection", uv1.ImVec2(0, 310), true) then
				uv1.Columns(2, "##prot_cols", false)
				uv1.SetColumnWidth(0, slot4 + 20)
				uv1.TextDisabled(uv3("\\xc4\\xe5\\xe9\\xf1\\xf2\\xe2\\xe8\\xff:"))

				for slot9, slot10 in ipairs({
					{
						uv3("\\xc2\\xfb\\xea\\xeb\\xfe\\xf7\\xe0\\xf2\\xfc \\xef\\xf0\\xe8 \\xf1\\xee\\xee\\xe1\\xf9\\xe5\\xed\\xe8\\xe8 \\xe0\\xe4\\xec\\xe8\\xed\\xe0"),
						uv2.farm.antadmin_autooff
					},
					{
						uv3("\\xd1\\xf2\\xee\\xef \\xef\\xf0\\xe8 \\xf2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2\\xe5"),
						uv2.farm.antadmin_stop_on_tp
					},
					{
						uv3("\\xc0\\xe2\\xf2\\xee-\\xe2\\xfb\\xf5\\xee\\xe4 (20 \\xf1\\xe5\\xea)"),
						uv2.farm.antadmin_safeexit
					},
					{
						uv3("\\xc0\\xe2\\xf2\\xee-\\xee\\xf2\\xe2\\xe5\\xf2 \\xed\\xe0 \\xf7\\xe5\\xea"),
						uv2.farm.auto_answer
					},
					{
						uv3("\\xcf\\xf0\\xfb\\xe6\\xee\\xea \\xef\\xf0\\xe8 \\xe7\\xe0\\xf1\\xf2\\xf0\\xe5\\xe2\\xe0\\xed\\xe8\\xe8"),
						uv2.farm.anti_stuck_jump
					},
					{
						uv3("\\xd7\\xe0\\xf2 \\xef\\xf0\\xe8 \\xf2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2\\xe0\\xf6\\xe8\\xe8"),
						uv2.farm.delay_chat_on_tp
					},
					{
						uv3("\\xc0\\xe2\\xf2\\xee-\\xef\\xf0\\xfb\\xe6\\xee\\xea \\xef\\xf0\\xe8 \\xe1\\xe5\\xe3\\xe5"),
						uv2.farm.auto_jump
					}
				}) do
					if uv1.CustomCheckbox(slot10[1], slot10[2]) then
						save_cfg()
					end
				end

				uv1.NextColumn()
				uv1.TextDisabled(uv3("\\xc7\\xe0\\xf9\\xe8\\xf2\\xed\\xfb\\xe5 \\xec\\xee\\xe4\\xf3\\xeb\\xe8:"))

				for slot10, slot11 in ipairs({
					{
						uv3("\\xc7\\xe0\\xf9\\xe8\\xf2\\xe0 \\xee\\xf2 \\xf2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2\\xe0"),
						uv2.farm.prot_teleport
					},
					{
						uv3("\\xc7\\xe0\\xf9\\xe8\\xf2\\xe0 \\xee\\xf2 \\xf1\\xee\\xee\\xe1\\xf9\\xe5\\xed\\xe8\\xe9"),
						uv2.farm.prot_admin_msg
					},
					{
						uv3("\\xc7\\xe0\\xf9\\xe8\\xf2\\xe0 \\xee\\xf2 \\xe4\\xe8\\xe0\\xeb\\xee\\xe3\\xee\\xe2"),
						uv2.farm.prot_dialog
					},
					{
						uv3("\\xc7\\xe0\\xf9\\xe8\\xf2\\xe0 \\xee\\xf2 \\xf1\\xef\\xe0\\xe2\\xed\\xe0"),
						uv2.farm.prot_spawn
					},
					{
						uv3("\\xc0\\xed\\xf2\\xe8\\xf1\\xeb\\xfd\\xef"),
						uv2.farm.prot_anti_slap
					},
					{
						uv3("\\xc8\\xec\\xe8\\xf2\\xe0\\xf6\\xe8\\xff \\xef\\xee\\xe8\\xf1\\xea\\xe0 \\xea\\xf3\\xf1\\xf2\\xe0"),
						uv2.farm.prot_fake_roam
					},
					{
						uv3("\\xcf\\xf0\\xee\\xef\\xf3\\xf1\\xea \\xe7\\xe0\\xed\\xff\\xf2\\xfb\\xf5 \\xea\\xf3\\xf1\\xf2\\xee\\xe2"),
						uv2.farm.prot_skip_busy_bush
					},
					{
						uv3("\\xd7\\xe5\\xea\\xe5\\xf0 \\xec\\xe0\\xf8\\xe8\\xed \\xf0\\xff\\xe4\\xee\\xec"),
						uv2.farm.prot_veh_check
					},
					{
						uv3("\\xc7\\xe0\\xf9\\xe8\\xf2\\xe0 \\xee\\xf2 \\xe7\\xe0\\xe1\\xee\\xf0\\xee\\xe2"),
						uv2.farm.prot_admin_3d
					}
				}) do
					if uv1.CustomCheckbox(slot11[1], slot11[2]) then
						save_cfg()
					end
				end

				uv1.Spacing()
				uv1.TextDisabled(uv3("\\xd3\\xe2\\xe5\\xe4\\xee\\xec\\xeb\\xe5\\xed\\xe8\\xff:"))

				if uv1.CustomCheckbox(uv3("\\xc2 \\xf2\\xe3 \\xef\\xf0\\xe8 \\xee\\xe1\\xed\\xe0\\xf0\\xf3\\xe6\\xe5\\xed\\xe8\\xe8"), uv2.farm.antadmin_tg) then
					save_cfg()
				end

				if uv1.CustomCheckbox(uv3("\\xcf\\xe5\\xf0\\xe5\\xf1\\xfb\\xeb\\xe0\\xf2\\xfc \\xe2\\xe5\\xf1\\xfc \\xf7\\xe0\\xf2"), uv2.farm.antadmin_tg_all) then
					save_cfg()
				end

				if uv1.CustomCheckbox(uv3("\\xcb\\xee\\xe3\\xe8 \\xe2 \\xf2\\xe3"), uv2.farm.telegram_logs) then
					save_cfg()
				end

				uv1.Columns(1)
				uv1.EndChild()
			end

			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)
			uv1.Columns(2, "##btn_cols", false)

			if uv1.CustomButton(uv3("\\xd1\\xf2\\xe0\\xf2\\xe8\\xf1\\xf2\\xe8\\xea\\xe0"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(-1, 40)) then
				uv2.stats_window[0] = true
			end

			uv1.NextColumn()

			if uv1.CustomButton(uv3("\\xcd\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8 \\xc8\\xc8"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(-1, 40)) then
				uv2.farm.ai_window[0] = not uv2.farm.ai_window[0]
			end

			uv1.Columns(1)
			uv1.PopStyleVar()
			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("\\xd2\\xf0\\xe5\\xe2\\xee\\xe3\\xe0 (\\xc7\\xe2\\xf3\\xea)"))
			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xc2\\xea\\xeb\\xfe\\xf7\\xe8\\xf2\\xfc \\xe7\\xe2\\xf3\\xea \\xef\\xf0\\xe8 \\xe0\\xe4\\xec\\xe8\\xed\\xe5"), uv2.farm.alarm_enabled) then
				save_cfg()
			end

			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)
			uv1.PushItemWidth(uv1.GetContentRegionAvail().x - 110)

			if uv1.InputText("##alarm_url", uv2.farm.alarm_url, 256) then
				save_cfg()
			end

			uv1.PopItemWidth()
			uv1.SameLine()

			if uv1.CustomButton(uv3("\\xd2\\xe5\\xf1\\xf2"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(100, 25)) and uv21.string(uv2.farm.alarm_url) ~= "" then
				os.execute("start " .. slot5)
			end

			uv1.PopStyleVar()
		elseif slot3 == "Telegram" then
			slot4 = uv1.GetContentRegionAvail().x

			uv1.TextColored(uv5(), uv3("Telegram \\xf3\\xe2\\xe5\\xe4\\xee\\xec\\xeb\\xe5\\xed\\xe8\\xff"))
			uv1.Separator()
			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xc2\\xea\\xeb\\xfe\\xf7\\xe8\\xf2\\xfc Telegram"), uv2.telegram.enabled) then
				save_cfg()
			end

			uv1.Spacing()
			uv1.Text(uv3("\\xd2\\xee\\xea\\xe5\\xed \\xe1\\xee\\xf2\\xe0 (@BotFather):"))
			uv1.PushItemWidth(slot4)

			if uv1.InputText("##tg_token", uv2.telegram.token, 128) then
				save_cfg()
			end

			uv1.Spacing()
			uv1.Text(uv3("Chat ID (\\xe2\\xe0\\xf8 ID \\xe8\\xeb\\xe8 ID \\xe3\\xf0\\xf3\\xef\\xef\\xfb):"))

			if uv1.InputText("##tg_chatid", uv2.telegram.chat_id, 64) then
				save_cfg()
			end

			uv1.PopItemWidth()
			uv1.Spacing()
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

			if uv1.CustomButton(uv3("\\xd2\\xe5\\xf1\\xf2 \\xee\\xf2\\xef\\xf0\\xe0\\xe2\\xe8\\xf2\\xfc \\xf1\\xee\\xee\\xe1\\xf9\\xe5\\xed\\xe8\\xe5"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(slot4 / 2 - 3, 36)) then
				send_telegram("\\xd2\\xe5\\xf1\\xf2 NexaArizona\n\\xc8\\xe3\\xf0\\xee\\xea: " .. uv7.nick .. "\n\n" .. "\\xd1\\xef\\xe8\\xf1\\xee\\xea \\xea\\xee\\xec\\xe0\\xed\\xe4 \\xe1\\xee\\xf2\\xe0:\n" .. "/status - \\xd1\\xf2\\xe0\\xf2\\xf3\\xf1 \\xe8 \\xf0\\xe5\\xf1\\xf3\\xf0\\xf1\\xfb\n" .. "/screen - \\xd1\\xe4\\xe5\\xeb\\xe0\\xf2\\xfc \\xf1\\xea\\xf0\\xe8\\xed\\xf8\\xee\\xf2\n" .. "/stop - \\xce\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xe8\\xf2\\xfc \\xe1\\xee\\xf2\\xe0\n" .. "/start_bot - \\xc7\\xe0\\xef\\xf3\\xf1\\xf2\\xe8\\xf2\\xfc \\xe1\\xee\\xf2\\xe0\n" .. "/ai_on - \\xc2\\xea\\xeb\\xfe\\xf7\\xe8\\xf2\\xfc \\xc8\\xc8\n" .. "/ai_off - \\xc2\\xfb\\xea\\xeb\\xfe\\xf7\\xe8\\xf2\\xfc \\xc8\\xc8\n" .. "/report - \\xd1\\xe5\\xf1\\xf1\\xe8\\xee\\xed\\xed\\xfb\\xe9 \\xee\\xf2\\xf7\\xb8\\xf2\n" .. "/msg [\\xf2\\xe5\\xea\\xf1\\xf2] - \\xd1\\xea\\xe0\\xe7\\xe0\\xf2\\xfc \\xe2 \\xf7\\xe0\\xf2\n" .. "/bsg [\\xf2\\xe5\\xea\\xf1\\xf2] - \\xd1\\xea\\xe0\\xe7\\xe0\\xf2\\xfc \\xe2 /b\n" .. "/q - \\xc7\\xe0\\xea\\xf0\\xfb\\xf2\\xfc \\xe8\\xe3\\xf0\\xf3")
				add_log("{33CCFF}[\\xd2\\xe5\\xeb\\xe5\\xe3\\xf0\\xe0\\xec] \\xd2\\xe5\\xf1\\xf2-\\xf1\\xee\\xee\\xe1\\xf9\\xe5\\xed\\xe8\\xe5 \\xee\\xf2\\xef\\xf0\\xe0\\xe2\\xeb\\xe5\\xed\\xee")
			end

			uv1.SameLine(nil, 6)

			if uv1.CustomButton(uv3("\\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xe8\\xf2\\xfc \\xee\\xf2\\xf7\\xb8\\xf2"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(-1, 36)) then
				send_session_report("\\xd0\\xf3\\xf7\\xed\\xee\\xe9 \\xe7\\xe0\\xef\\xf0\\xee\\xf1")
			end

			uv1.PopStyleVar()
			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("\\xca\\xee\\xec\\xe0\\xed\\xe4\\xfb \\xe1\\xee\\xf2\\xe0 (\\xe2 \\xf2\\xe3 \\xe1\\xee\\xf2\\xe0):"))
			uv1.Spacing()

			for slot9, slot10 in ipairs({
				"/status - \\xf2\\xe5\\xea\\xf3\\xf9\\xe8\\xe9 \\xf1\\xf2\\xe0\\xf2\\xf3\\xf1",
				"/screen - \\xf1\\xe4\\xe5\\xeb\\xe0\\xf2\\xfc \\xf1\\xea\\xf0\\xe8\\xed\\xf8\\xee\\xf2",
				"/stop - \\xee\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xe8\\xf2\\xfc \\xe1\\xee\\xf2\\xe0",
				"/start_bot - \\xe7\\xe0\\xef\\xf3\\xf1\\xf2\\xe8\\xf2\\xfc \\xe1\\xee\\xf2\\xe0",
				"/ai_on / /ai_off - \\xe2\\xea\\xeb/\\xe2\\xfb\\xea\\xeb \\xc8\\xc8",
				"/report - \\xef\\xee\\xeb\\xf3\\xf7\\xe8\\xf2\\xfc \\xee\\xf2\\xf7\\xb8\\xf2",
				"/q - \\xe2\\xfb\\xeb\\xe5\\xf2 \\xf1 \\xe8\\xe3\\xf0\\xfb",
				"/msg [\\xf2\\xe5\\xea\\xf1\\xf2] - \\xe2 \\xee\\xe1\\xfb\\xf7\\xed\\xfb\\xe9 \\xf7\\xe0\\xf2",
				"/bsg [\\xf2\\xe5\\xea\\xf1\\xf2] - \\xe2 \\xed\\xee\\xed\\xd0\\xcf \\xf7\\xe0\\xf2"
			}) do
				uv1.TextDisabled(uv3(slot10))
			end

			uv1.Spacing()
			uv1.PushStyleColor(uv1.Col.Text, uv1.ImVec4(1, 0.8, 0.2, 1))
			uv1.TextWrapped(uv3("\\xca\\xee\\xec\\xe0\\xed\\xe4\\xfb \\xf0\\xe0\\xe1\\xee\\xf2\\xe0\\xfe\\xf2 \\xf2\\xee\\xeb\\xfc\\xea\\xee \\xe8\\xe7 \\xe2\\xe0\\xf8\\xe5\\xe3\\xee chat_id. \\xce\\xef\\xf0\\xee\\xf1 \\xea\\xe0\\xe6\\xe4\\xfb\\xe5 5 \\xf1\\xe5\\xea\\xf3\\xed\\xe4."))
			uv1.PopStyleColor()
		elseif slot3 == "Other" then
			uv1.TextColored(uv5(), uv3("\\xd0\\xe0\\xe7\\xed\\xfb\\xe5 \\xf4\\xf3\\xed\\xea\\xf6\\xe8\\xe8"))
			uv1.Separator()
			uv1.Spacing()
			uv1.Text(uv3("\\xc1\\xe8\\xed\\xe4 1 - \\xe2\\xea\\xeb\\xfe\\xf7\\xe8\\xf2\\xfc/\\xe2\\xfb\\xea\\xeb\\xfe\\xf7\\xe8\\xf2\\xfc \\xe1\\xee\\xf2\\xe0"))
			uv1.Spacing()
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

			if uv1.CustomButton(uv3("\\xd2\\xe5\\xea\\xf3\\xf9\\xe8\\xe9 \\xe1\\xe8\\xed\\xe4: [" .. uv22(uv2.theme.bot_bind_key[0]) .. "]  [\\xcd\\xe0\\xe6\\xec\\xe8\\xf2\\xe5 \\xe4\\xeb\\xff \\xf1\\xec\\xe5\\xed\\xfb]##b1"), uv1.ImVec4(0.12, 0.12, 0.14, 1), uv5(), uv1.ImVec4(0.08, 0.08, 0.1, 1), uv1.ImVec2(-1, 34)) then
				uv24 = false
				uv23 = true

				add_log("{33CCFF}[\\xc1\\xe8\\xed\\xe4] \\xce\\xe6\\xe8\\xe4\\xe0\\xed\\xe8\\xe5 \\xed\\xe0\\xe6\\xe0\\xf2\\xe8\\xff \\xea\\xeb\\xe0\\xe2\\xe8\\xf8\\xe8 \\xe4\\xeb\\xff \\xe1\\xe8\\xed\\xe4\\xe0 \\xe1\\xee\\xf2\\xe0...")
			end

			if uv23 then
				slot8 = "\\xcd\\xe0\\xe6\\xec\\xe8\\xf2\\xe5 \\xeb\\xfe\\xe1\\xf3\\xfe \\xea\\xeb\\xe0\\xe2\\xe8\\xf8\\xf3... (ESC - \\xee\\xf2\\xec\\xe5\\xed\\xe0)"

				uv1.TextColored(uv1.ImVec4(1, 0.8, 0.1, 1), uv3(slot8))

				for slot8 = 3, 254 do
					if uv1.IsKeyPressed(slot8) then
						if slot8 == 27 then
							uv23 = false

							add_log("{FFAA00}[\\xc1\\xe8\\xed\\xe4] \\xcd\\xe0\\xe7\\xed\\xe0\\xf7\\xe5\\xed\\xe8\\xe5 \\xee\\xf2\\xec\\xe5\\xed\\xe5\\xed\\xee.")

							break
						end

						uv2.theme.bot_bind_key[0] = slot8
						uv23 = false

						save_cfg()
						add_log(string.format("{33FF33}[\\xc1\\xe8\\xed\\xe4] \\xc1\\xe8\\xed\\xe4 \\xe1\\xee\\xf2\\xe0: [%s]", uv22(slot8)))

						break
					end
				end
			end

			uv1.TextDisabled(uv3("\\xd0\\xe0\\xe1\\xee\\xf2\\xe0\\xe5\\xf2 \\xe3\\xeb\\xee\\xe1\\xe0\\xeb\\xfc\\xed\\xee (\\xe2\\xed\\xe5 \\xec\\xe5\\xed\\xfe)."))
			uv1.Spacing()
			uv1.Text(uv3("\\xc1\\xe8\\xed\\xe4 2 - \\xee\\xf2\\xea\\xf0\\xfb\\xf2\\xfc/\\xe7\\xe0\\xea\\xf0\\xfb\\xf2\\xfc \\xec\\xe5\\xed\\xfe"))
			uv1.Spacing()

			if uv1.CustomButton(uv3("\\xc4\\xee\\xef. \\xe1\\xe8\\xed\\xe4 \\xec\\xe5\\xed\\xfe: [" .. (uv2.farm.menu_bind_key[0] > 0 and uv22(slot5) or uv3("\\xed\\xe5 \\xe7\\xe0\\xe4\\xe0\\xed")) .. "]  [\\xcd\\xe0\\xe6\\xec\\xe8\\xf2\\xe5 \\xe4\\xeb\\xff \\xf1\\xec\\xe5\\xed\\xfb]##b2"), uv1.ImVec4(0.12, 0.12, 0.14, 1), uv5(), uv1.ImVec4(0.08, 0.08, 0.1, 1), uv1.ImVec2(-1, 34)) then
				uv23 = false
				uv24 = true

				add_log("{33CCFF}[\\xc1\\xe8\\xed\\xe4] \\xce\\xe6\\xe8\\xe4\\xe0\\xed\\xe8\\xe5 \\xed\\xe0\\xe6\\xe0\\xf2\\xe8\\xff \\xea\\xeb\\xe0\\xe2\\xe8\\xf8\\xe8 \\xe4\\xeb\\xff \\xe1\\xe8\\xed\\xe4\\xe0 \\xec\\xe5\\xed\\xfe...")
			end

			if uv24 then
				slot10 = "\\xcd\\xe0\\xe6\\xec\\xe8\\xf2\\xe5 \\xeb\\xfe\\xe1\\xf3\\xfe \\xea\\xeb\\xe0\\xe2\\xe8\\xf8\\xf3... (ESC - \\xee\\xf2\\xec\\xe5\\xed\\xe0, DEL - \\xf1\\xe1\\xf0\\xee\\xf1\\xe8\\xf2\\xfc \\xe1\\xe8\\xed\\xe4)"

				uv1.TextColored(uv1.ImVec4(1, 0.8, 0.1, 1), uv3(slot10))

				for slot10 = 3, 254 do
					if uv1.IsKeyPressed(slot10) then
						if slot10 == 27 then
							uv24 = false

							add_log("{FFAA00}[\\xc1\\xe8\\xed\\xe4] \\xcd\\xe0\\xe7\\xed\\xe0\\xf7\\xe5\\xed\\xe8\\xe5 \\xec\\xe5\\xed\\xfe \\xee\\xf2\\xec\\xe5\\xed\\xe5\\xed\\xee.")

							break
						end

						if slot10 == 46 then
							uv2.farm.menu_bind_key[0] = 0
							uv24 = false

							save_cfg()
							add_log("{FFAA00}[\\xc1\\xe8\\xed\\xe4] \\xc4\\xee\\xef. \\xe1\\xe8\\xed\\xe4 \\xec\\xe5\\xed\\xfe \\xf1\\xe1\\xf0\\xee\\xf8\\xe5\\xed.")

							break
						end

						uv2.farm.menu_bind_key[0] = slot10
						uv24 = false

						save_cfg()
						add_log(string.format("{33FF33}[\\xc1\\xe8\\xed\\xe4] \\xc1\\xe8\\xed\\xe4 \\xec\\xe5\\xed\\xfe: [%s]", uv22(slot10)))

						break
					end
				end
			end

			uv1.PopStyleVar()
			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("\\xd0\\xe0\\xe7\\xed\\xee\\xe5"))
		elseif slot3 == "Settings" then
			slot4 = uv1.GetContentRegionAvail().x

			uv1.TextColored(uv5(), uv3("\\xc4\\xee\\xef\\xee\\xeb\\xed\\xe8\\xf2\\xe5\\xeb\\xfc\\xed\\xfb\\xe5 \\xed\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8"))
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("\\xc0\\xe2\\xf2\\xee-\\xf1\\xea\\xf0\\xe8\\xed\\xf8\\xee\\xf2\\xfb \\xe2 Telegram"))
			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xeb\\xff\\xf2\\xfc \\xf1\\xea\\xf0\\xe8\\xed\\xf8\\xee\\xf2 \\xef\\xee \\xf2\\xe0\\xe9\\xec\\xe5\\xf0\\xf3"), uv2.options.screen_timer_enabled) then
				uv2.options.last_screen_time = os.time()

				save_cfg()
			end

			uv1.Spacing()
			uv1.Text(uv3("\\xc8\\xed\\xf2\\xe5\\xf0\\xe2\\xe0\\xeb \\xee\\xf2\\xef\\xf0\\xe0\\xe2\\xea\\xe8 (\\xec\\xe8\\xed\\xf3\\xf2\\xfb):"))

			if uv1.Button("-##screen", uv1.ImVec2(30, 25)) and uv2.options.screen_interval[0] > 1 then
				uv2.options.screen_interval[0] = uv2.options.screen_interval[0] - 1

				save_cfg()
			end

			uv1.SameLine()
			uv1.PushItemWidth(100)

			if uv1.InputInt("##screen_int", uv2.options.screen_interval, 0, 0) then
				if uv2.options.screen_interval[0] < 1 then
					uv2.options.screen_interval[0] = 1
				end

				save_cfg()
			end

			uv1.PopItemWidth()
			uv1.SameLine()

			if uv1.Button("+##screen", uv1.ImVec2(30, 25)) then
				uv2.options.screen_interval[0] = uv2.options.screen_interval[0] + 1

				save_cfg()
			end

			uv1.Spacing()
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

			if uv1.CustomButton(uv3("\\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xe8\\xf2\\xfc \\xf1\\xea\\xf0\\xe8\\xed\\xf8\\xee\\xf2 \\xf1\\xe5\\xe9\\xf7\\xe0\\xf1"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(-1, 30)) then
				sendPhoto()
			end

			uv1.PopStyleVar()
			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("\\xd2\\xe0\\xe9\\xec\\xe5\\xf0 \\xf0\\xe0\\xe1\\xee\\xf2\\xfb"))
			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xc2\\xea\\xeb\\xfe\\xf7\\xe8\\xf2\\xfc \\xf2\\xe0\\xe9\\xec\\xe5\\xf0 \\xe7\\xe0\\xe2\\xe5\\xf0\\xf8\\xe5\\xed\\xe8\\xff"), uv2.timer.enabled) then
				uv2.timer.startTime = uv2.timer.enabled[0] and os.time() or 0

				save_cfg()
			end

			uv1.Spacing()
			uv1.PushItemWidth(180)

			if uv1.CustomSliderFloat(uv3("\\xd7\\xe0\\xf1\\xfb"), uv2.timer.hours, 0, 360, uv3(string.format("%.0f \\xf7", uv2.timer.hours[0]))) then
				save_cfg()
			end

			if uv1.CustomSliderFloat(uv3("\\xcc\\xe8\\xed\\xf3\\xf2\\xfb"), uv2.timer.minutes, 0, 59, uv3(string.format("%.0f \\xec\\xe8\\xed", uv2.timer.minutes[0]))) then
				save_cfg()
			end

			uv1.PopItemWidth()

			if uv2.timer.enabled[0] and uv2.timer.startTime > 0 then
				if math.floor(uv2.timer.hours[0] + 0.5) * 3600 + math.floor(uv2.timer.minutes[0] + 0.5) * 60 - (os.time() - uv2.timer.startTime) > 0 then
					uv1.TextColored(uv1.ImVec4(0.3, 0.8, 1, 1), uv3(string.format("\\xc4\\xee \\xe2\\xfb\\xe3\\xf0\\xf3\\xe7\\xea\\xe8: %02d:%02d:%02d", math.floor(slot7 / 3600), math.floor(slot7 % 3600 / 60), slot7 % 60)))
				else
					uv1.TextColored(uv1.ImVec4(1, 0.3, 0.3, 1), uv3("\\xc2\\xf0\\xe5\\xec\\xff \\xe8\\xf1\\xf2\\xe5\\xea\\xeb\\xee!"))
				end
			end

			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("NavMesh \\xed\\xe0\\xe2\\xe8\\xe3\\xe0\\xf6\\xe8\\xff"))
			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xce\\xf2\\xee\\xe1\\xf0\\xe0\\xe6\\xe0\\xf2\\xfc NavMesh \\xf1\\xe5\\xf2\\xea\\xf3"), uv2.farm.navmesh_render_mesh) then
				save_cfg()
			end

			uv1.Spacing()
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

			if uv1.CustomButton(uv3("\\xd1\\xe1\\xf0\\xee\\xf1\\xe8\\xf2\\xfc NavMesh \\xef\\xf3\\xf2\\xfc"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(-1, 30)) then
				resetNavPath()
				add_log("{33CCFF}[NavMesh] \\xcf\\xf3\\xf2\\xfc \\xf1\\xe1\\xf0\\xee\\xf8\\xe5\\xed \\xe2\\xf0\\xf3\\xf7\\xed\\xf3\\xfe.")
			end

			uv1.PopStyleVar()
			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("\\xce\\xef\\xf2\\xe8\\xec\\xe8\\xe7\\xe0\\xf6\\xe8\\xff \\xef\\xe0\\xec\\xff\\xf2\\xe8"))
			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xc0\\xe2\\xf2\\xee\\xec\\xe0\\xf2\\xe8\\xf7\\xe5\\xf1\\xea\\xe0\\xff \\xee\\xf7\\xe8\\xf1\\xf2\\xea\\xe0"), uv2.cleaner.enabled) then
				save_cfg()
			end

			uv1.SameLine(nil, 20)

			if uv1.CustomCheckbox(uv3("\\xd3\\xe2\\xe5\\xe4\\xee\\xec\\xeb\\xe5\\xed\\xe8\\xff \\xe2 \\xeb\\xee\\xe3"), uv2.cleaner.notificationsEnabled) then
				save_cfg()
			end

			uv1.Spacing()
			uv1.PushItemWidth(180)

			if uv1.CustomSliderFloat(uv3("\\xcb\\xe8\\xec\\xe8\\xf2 \\xef\\xe0\\xec\\xff\\xf2\\xe8"), uv2.cleaner.limit, 256, 1024, "%d MB") then
				save_cfg()
			end

			uv1.PopItemWidth()
			uv1.Spacing()
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

			if uv1.CustomButton(uv3("\\xce\\xf7\\xe8\\xf1\\xf2\\xe8\\xf2\\xfc \\xef\\xe0\\xec\\xff\\xf2\\xfc \\xf1\\xe5\\xe9\\xf7\\xe0\\xf1"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(-1, 30)) then
				CleanMemory()
			end

			uv1.PopStyleVar()
			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("\\xcc\\xf3\\xeb\\xfc\\xf2\\xe8\\xe0\\xea\\xea\\xe0\\xf3\\xed\\xf2"))
			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xc2\\xea\\xeb\\xfe\\xf7\\xe8\\xf2\\xfc \\xf3\\xf7\\xb8\\xf2 \\xed\\xe5\\xf1\\xea\\xee\\xeb\\xfc\\xea\\xe8\\xf5 \\xe0\\xea\\xea\\xe0\\xf3\\xed\\xf2\\xee\\xe2"), uv2.ma.enabled) then
				uv6.enabled = uv2.ma.enabled[0]

				save_cfg()
			end

			if uv2.ma.enabled[0] then
				uv1.TextWrapped(uv3("\\xc4\\xee\\xe1\\xe0\\xe2\\xfc\\xf2\\xe5 \\xed\\xe8\\xea\\xe8 \\xe4\\xf0\\xf3\\xe3\\xe8\\xf5 \\xe0\\xea\\xea\\xe0\\xf3\\xed\\xf2\\xee\\xe2. \\xd1\\xea\\xf0\\xe8\\xef\\xf2 \\xef\\xf0\\xee\\xe2\\xe5\\xf0\\xff\\xe5\\xf2: \\xee\\xed\\xeb\\xe0\\xe9\\xed \\xeb\\xe8 \\xee\\xed\\xe8, \\xe8 \\xed\\xe5 \\xe8\\xe4\\xf3\\xf2 \\xeb\\xe8 \\xea \\xf2\\xee\\xec\\xf3 \\xe6\\xe5 \\xea\\xf3\\xf1\\xf2\\xf3."))
				uv1.Spacing()
				uv1.Text(uv3("\\xcd\\xe8\\xea \\xe0\\xea\\xea\\xe0\\xf3\\xed\\xf2\\xe0:"))
				uv1.PushItemWidth(slot4 - 90)
				uv1.InputText(uv3("##ma_nick"), uv2.ma.new_nick_buf, 64)
				uv1.PopItemWidth()
				uv1.SameLine(nil, 6)
				uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

				if uv1.CustomButton(uv3("\\xc4\\xee\\xe1\\xe0\\xe2\\xe8\\xf2\\xfc"), uv1.ImVec4(0.12, 0.15, 0.2, 0.9), uv1.ImVec4(0.18, 0.22, 0.3, 1), uv1.ImVec4(0.1, 0.12, 0.15, 1), uv1.ImVec2(80, 25)) and uv21.string(uv2.ma.new_nick_buf):match("^%s*(.-)%s*$") ~= "" then
					slot6 = false

					for slot10, slot11 in ipairs(uv6.list) do
						if slot11.nick == slot5 then
							slot6 = true

							break
						end
					end

					if not slot6 then
						table.insert(uv6.list, {
							linen = 0,
							cotton = 0,
							rare = 0,
							start_time = 0,
							nick = slot5,
							online = uv8(slot5)
						})
						uv21.copy(uv2.ma.new_nick_buf, "")
						save_cfg()
					end
				end

				uv1.PopStyleVar()
				uv1.Spacing()

				if #uv6.list > 0 then
					slot5 = nil

					for slot9, slot10 in ipairs(uv6.list) do
						uv1.TextColored(uv8(slot10.nick) and uv1.ImVec4(0.3, 0.9, 0.3, 1) or uv1.ImVec4(0.8, 0.4, 0.4, 1), uv3(slot9 .. ". " .. slot10.nick .. (uv8(slot10.nick) and uv3(" [\\xee\\xed\\xeb\\xe0\\xe9\\xed]") or uv3(" [\\xee\\xf4\\xeb\\xe0\\xe9\\xed]"))))
						uv1.SameLine()

						if uv1.SmallButton(uv3("\\xd3\\xe4\\xe0\\xeb\\xe8\\xf2\\xfc##ma_") .. slot9) then
							slot5 = slot9
						end
					end

					if slot5 then
						table.remove(uv6.list, slot5)
						save_cfg()
					end
				else
					uv1.TextDisabled(uv3("\\xd1\\xef\\xe8\\xf1\\xee\\xea \\xef\\xf3\\xf1\\xf2."))
				end
			end

			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.TextColored(uv5(), uv3("\\xd4\\xe8\\xe7\\xe8\\xea\\xe0 \\xe1\\xe5\\xe3\\xe0"))
			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xd1\\xf2\\xe8\\xeb\\xfc \\xe1\\xe5\\xe3\\xe0 CJ"), uv2.farm.cj_run) then
				save_cfg()
			end

			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xc1\\xe5\\xf1\\xea\\xee\\xed\\xe5\\xf7\\xed\\xfb\\xe9 \\xe1\\xe5\\xe3"), uv2.farm.inf_run) then
				save_cfg()
			end

			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xd1\\xef\\xf0\\xe8\\xed\\xf2 \\xef\\xf0\\xe8 \\xec\\xe0\\xeb\\xee\\xec \\xe3\\xee\\xeb\\xee\\xe4\\xe5"), uv2.farm.anti_hunger_sprint) then
				save_cfg()
			end

			uv1.Spacing()

			if uv1.CustomCheckbox(uv3("\\xce\\xf2\\xea\\xeb\\xfe\\xf7\\xe8\\xf2\\xfc \\xe7\\xe0\\xf1\\xf2\\xe0\\xe2\\xea\\xf3 \\xef\\xf0\\xe8 \\xe7\\xe0\\xef\\xf3\\xf1\\xea\\xe5"), uv2.farm.disable_splash) then
				save_cfg()
			end

			uv1.Spacing()
			uv1.Separator()
			uv1.Spacing()
			uv1.PushStyleVarFloat(uv1.StyleVar.FrameRounding, 8)

			if uv1.CustomButton(uv3("\\xd1\\xee\\xf5\\xf0\\xe0\\xed\\xe8\\xf2\\xfc \\xed\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8"), uv1.ImVec4(0.12, 0.55, 0.18, 0.6), uv1.ImVec4(0.15, 0.7, 0.22, 0.8), uv1.ImVec4(0.1, 0.4, 0.14, 1), uv1.ImVec2(slot4 / 2 - 4, 36)) then
				save_cfg()
				add_log("{33FF33}[\\xca\\xee\\xed\\xf4\\xe8\\xe3] \\xcd\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8 \\xf1\\xee\\xf5\\xf0\\xe0\\xed\\xe5\\xed\\xfb \\xe2\\xf0\\xf3\\xf7\\xed\\xf3\\xfe.")
			end

			uv1.SameLine(nil, 8)

			if uv1.CustomButton(uv3("\\xd1\\xe1\\xf0\\xee\\xf1\\xe8\\xf2\\xfc \\xed\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8"), uv1.ImVec4(0.55, 0.12, 0.12, 0.6), uv1.ImVec4(0.7, 0.15, 0.15, 0.8), uv1.ImVec4(0.4, 0.1, 0.1, 1), uv1.ImVec2(slot4 / 2 - 4, 36)) then
				slot5 = uv2.farm
				slot5.anti_afk[0] = true
				slot5.real_run[0] = true
				slot5.collect_linen[0] = true
				slot5.collect_cotton[0] = true
				slot5.smart_pause[0] = true
				slot5.eat_percent[0] = 20
				slot5.eat_method[0] = 0
				slot5.auto_eat[0] = false
				slot5.anti_freeze[0] = true
				slot5.telegram_logs[0] = true
				slot5.anti_slap[0] = true
				slot5.antadmin_stop_on_tp[0] = true
				slot5.antadmin_autooff[0] = true
				slot5.auto_answer[0] = false
				slot5.antadmin_safeexit[0] = false
				slot5.antadmin_tg_all[0] = false
				slot5.antadmin_tg[0] = true
				slot5.auto_jump[0] = false
				slot5.anti_stuck_jump[0] = true
				slot5.antadmin_skipdialog[0] = false
				slot5.delay_chat_on_tp[0] = true
				slot5.auto_skin_interval[0] = 5
				slot5.auto_skin[0] = false
				slot5.chat_filter[0] = true
				slot5.anti_hunger_sprint[0] = false
				slot5.inf_run[0] = false
				slot5.cj_run[0] = false
				slot5.navmesh_render_path[0] = false
				slot5.navmesh_render_mesh[0] = false
				slot5.prot_spawn[0] = true
				slot5.prot_dialog[0] = true
				slot5.prot_admin_msg[0] = true
				slot5.prot_teleport[0] = true
				slot5.prot_skip_busy_bush[0] = true
				slot5.prot_fake_roam[0] = true
				slot5.prot_anti_slap[0] = true
				slot5.menu_bind_key[0] = 0
				slot5.disable_splash[0] = false
				uv2.ai.enabled[0] = false

				uv21.copy(uv2.ai.api_key, "")
				uv21.copy(uv2.ai.base_url, "https://api.openai.com/v1/chat/completions")
				uv21.copy(uv2.ai.model_id, "gpt-3.5-turbo")

				slot5.ai_window[0] = false
				uv2.options.screen_timer_enabled[0] = false
				uv2.options.screen_interval[0] = 10

				save_cfg()
				add_log("{FFAA00}[\\xca\\xee\\xed\\xf4\\xe8\\xe3] \\xc2\\xf1\\xe5 \\xed\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8 \\xf1\\xe1\\xf0\\xee\\xf8\\xe5\\xed\\xfb.")
			end

			uv1.PopStyleVar()
		end

		uv1.EndChild()
	end

	uv1.End()
end)
slot0.OnFrame(function ()
	return uv0.stats_window[0]
end, function ()
	slot0, slot1 = getScreenResolution()

	uv0.SetNextWindowPos(uv0.ImVec2(slot0 / 2, slot1 / 2), uv0.Cond.FirstUseEver, uv0.ImVec2(0.5, 0.5))
	uv0.SetNextWindowSize(uv0.ImVec2(360, 720), uv0.Cond.Always)
	uv0.SetNextWindowBgAlpha(uv1.theme.global_alpha[0])
	uv0.PushStyleVarFloat(uv0.StyleVar.FrameRounding, 8)
	uv0.PushStyleVarFloat(uv0.StyleVar.ChildRounding, 8)
	uv0.PushStyleVarVec2(uv0.StyleVar.WindowPadding, uv0.ImVec2(15, 15))

	if not uv0.Begin(uv2("\\xd1\\xf2\\xe0\\xf2\\xe8\\xf1\\xf2\\xe8\\xea\\xe0##stats"), uv1.stats_window, uv0.WindowFlags.NoCollapse + uv0.WindowFlags.NoResize + uv0.WindowFlags.NoTitleBar) then
		uv0.End()
		uv0.PopStyleVar(3)

		return
	end

	uv0.PushFont(font24 or font18)
	uv0.TextColored(uv3(), uv2("\\xd1\\xf2\\xe0\\xf2\\xe8\\xf1\\xf2\\xe8\\xea\\xe0 \\xf1\\xe5\\xf1\\xf1\\xe8\\xe8"))
	uv0.PopFont()
	uv0.Spacing()

	if uv0.BeginChild("##general_info", uv0.ImVec2(uv0.GetContentRegionAvail().x, 95), true) then
		uv0.SetCursorPosX(10)
		uv0.SetCursorPosY(10)

		slot4 = uv1.farm.running[0] and os.time() - (uv1.farm.stats.start_time or os.time()) or 0

		uv0.TextDisabled(uv2("\\xc2\\xf0\\xe5\\xec\\xff \\xf0\\xe0\\xe1\\xee\\xf2\\xfb:"))
		uv0.SameLine(130)
		uv0.Text(string.format("%02d:%02d:%02d", math.floor(slot4 / 3600), math.floor(slot4 % 3600 / 60), slot4 % 60))
		uv0.SetCursorPosX(10)
		uv0.TextDisabled(uv2("\\xc4\\xee \\xef\\xf0\\xfb\\xe6\\xea\\xe0:"))
		uv0.SameLine(130)
		uv0.Text(string.format(uv2("%d \\xf1\\xe5\\xea"), math.max(0, uv4.timeout - (os.time() - (uv4.start_time or os.time())))))
		uv0.SetCursorPosX(10)
		uv0.TextDisabled(uv2("NavMesh:"))
		uv0.SameLine(130)
		uv0.Text(string.format(uv2("\\xef\\xf3\\xf2\\xfc %d \\xf2\\xee\\xf7\\xe5\\xea"), uv5.current_path and #uv5.current_path or 0))
		uv0.EndChild()
	end

	uv0.Spacing()
	uv0.PushFont(font18)
	uv0.TextColored(uv3(), uv2("\\xd0\\xe5\\xf1\\xf3\\xf0\\xf1\\xfb \\xe8 \\xef\\xf0\\xe8\\xe1\\xfb\\xeb\\xfc"))
	uv0.PopFont()

	if uv0.BeginChild("##mining_stats", uv0.ImVec2(slot3, 320), true) then
		slot4 = uv1.farm.res_counter

		uv0.SetCursorPos(uv0.ImVec2(10, 10))
		uv0.TextDisabled(uv2("\\xd6\\xe5\\xed\\xfb (\\xd5\\xeb\\xee\\xef\\xee\\xea / ˸\\xed / \\xd2\\xea\\xe0\\xed\\xfc / \\xd3\\xe3\\xee\\xeb\\xfc):"))
		uv0.SetCursorPosX(10)
		uv0.PushItemWidth((slot3 - 30) / 4 - 5)

		if uv0.InputFloat("##pc", uv1.calc.price_cotton, 0, 0, "%.0f") then
			save_cfg()
		end

		uv0.SameLine()

		if uv0.InputFloat("##pl", uv1.calc.price_linen, 0, 0, "%.0f") then
			save_cfg()
		end

		uv0.SameLine()

		if uv0.InputFloat("##pr", uv1.calc.price_rare, 0, 0, "%.0f") then
			save_cfg()
		end

		uv0.SameLine()

		if uv0.InputFloat("##pcoal", uv1.calc.price_coal, 0, 0, "%.0f") then
			save_cfg()
		end

		uv0.PopItemWidth()
		uv0.Spacing()
		uv0.Separator()
		uv0.Spacing()

		function slot6(slot0, slot1, slot2)
			uv0.SetCursorPosX(10)
			uv0.TextDisabled(slot0 .. ":")
			uv0.SameLine(80)
			uv0.Text(string.format("%s x %s$", uv1(slot1), uv1(slot2[0])))
			uv0.SameLine(uv2 - 100)
			uv0.TextColored(uv0.ImVec4(1, 1, 1, 0.6), "= " .. uv1(slot1 * slot2[0]) .. "$")
		end

		slot6(uv2("\\xd5\\xeb\\xee\\xef\\xee\\xea"), slot4.cotton, uv1.calc.price_cotton)
		slot6(uv2("˸\\xed"), slot4.linen, uv1.calc.price_linen)
		slot6(uv2("\\xd2\\xea\\xe0\\xed\\xfc"), slot4.rare, uv1.calc.price_rare)
		slot6(uv2("\\xd3\\xe3\\xee\\xeb\\xfc"), slot4.coal or 0, uv1.calc.price_coal)
		uv0.Spacing()
		uv0.Separator()
		uv0.Spacing()
		uv0.SetCursorPosX(10)
		uv0.Text(uv2("\\xc2\\xf1\\xe5\\xe3\\xee \\xef\\xf0\\xe5\\xe4\\xec\\xe5\\xf2\\xee\\xe2:"))
		uv0.SameLine(slot3 - 50)
		uv0.Text(uv6(slot4.linen + slot4.cotton + slot4.rare + (slot4.coal or 0)))
		uv0.SetCursorPosX(10)
		uv0.TextColored(uv3(), uv2("\\xce\\xe1\\xf9\\xe0\\xff \\xef\\xf0\\xe8\\xe1\\xfb\\xeb\\xfc:"))
		uv0.SameLine(slot3 - 120)
		uv0.TextColored(uv0.ImVec4(0.2, 1, 0.3, 1), uv6(slot4.cotton * uv1.calc.price_cotton[0] + slot4.linen * uv1.calc.price_linen[0] + slot4.rare * uv1.calc.price_rare[0] + (slot4.coal or 0) * uv1.calc.price_coal[0]) .. " $")
		uv0.EndChild()
	end

	uv0.Spacing()

	if uv0.BeginChild("##status_box", uv0.ImVec2(slot3, 70), true) then
		uv0.SetCursorPos(uv0.ImVec2(10, 10))
		uv0.TextDisabled(uv2("\\xc4\\xe5\\xe9\\xf1\\xf2\\xe2\\xe8\\xe5:"))
		uv0.SameLine()
		uv0.TextColored(uv7().color, uv2(uv1.farm.status_bar or "\\xce\\xe6\\xe8\\xe4\\xe0\\xed\\xe8\\xe5"))
		uv0.SetCursorPosX(10)
		uv0.TextDisabled(uv2("\\xc4\\xe2\\xe8\\xe6\\xe5\\xed\\xe8\\xe5:"))
		uv0.SameLine()
		uv0.Text(uv8.active and uv2("\\xc0\\xea\\xf2\\xe8\\xe2\\xed\\xee") or uv2("\\xcf\\xe0\\xf3\\xe7\\xe0"))
		uv0.EndChild()
	end

	uv0.Spacing()

	if uv0.CustomButton(uv2("\\xce\\xf2\\xf7\\xe5\\xf2 \\xe2 \\xf2\\xe5\\xeb\\xe5\\xe3\\xf0\\xe0\\xec"), uv0.ImVec4(0.12, 0.5, 0.8, 0.4), uv3(), uv0.ImVec4(0.1, 0.3, 0.5, 1), uv0.ImVec2(slot3, 35)) then
		send_session_report("\\xd0\\xf3\\xf7\\xed\\xee\\xe9 \\xe7\\xe0\\xef\\xf0\\xee\\xf1")
	end

	uv0.Spacing()

	if uv0.CustomButton(uv2("\\xc7\\xe0\\xea\\xf0\\xfb\\xf2\\xfc"), uv0.ImVec4(0.6, 0.2, 0.2, 0.8), uv0.ImVec4(0.8, 0.2, 0.2, 1), uv0.ImVec4(0.4, 0.1, 0.1, 1), uv0.ImVec2(slot3, 35)) then
		uv1.stats_window[0] = false
	end

	uv0.End()
	uv0.PopStyleVar(3)
end)
slot0.OnFrame(function ()
	return uv0.farm.ai_window[0]
end, function ()
	slot0, slot1 = getScreenResolution()

	uv0.SetNextWindowPos(uv0.ImVec2(slot0 / 2, slot1 / 2), uv0.Cond.FirstUseEver, uv0.ImVec2(0.5, 0.5))
	uv0.SetNextWindowSize(uv0.ImVec2(460, 560), uv0.Cond.Always)
	uv0.PushStyleVarFloat(uv0.StyleVar.WindowRounding, 12)
	uv0.PushStyleVarFloat(uv0.StyleVar.ChildRounding, 8)
	uv0.PushStyleVarFloat(uv0.StyleVar.FrameRounding, 8)
	uv0.PushStyleVarVec2(uv0.StyleVar.WindowPadding, uv0.ImVec2(15, 15))
	uv0.SetNextWindowBgAlpha(uv1.theme.global_alpha[0])

	if uv0.Begin(uv2("\\xcd\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8 \\xc8\\xc8 \\xcf\\xee\\xec\\xee\\xf9\\xed\\xe8\\xea\\xe0##ai_menu"), uv1.farm.ai_window, uv0.WindowFlags.NoCollapse + uv0.WindowFlags.NoResize + uv0.WindowFlags.NoTitleBar) then
		uv0.PushFont(font24 or font18)
		uv0.TextColored(uv3(), uv2("\\xcd\\xe5\\xe9\\xf0\\xee\\xf1\\xe5\\xf2\\xe5\\xe2\\xee\\xe9 \\xef\\xee\\xec\\xee\\xf9\\xed\\xe8\\xea"))
		uv0.PopFont()
		uv0.Spacing()
		uv0.TextDisabled(uv2("\\xca\\xee\\xed\\xf4\\xe8\\xe3\\xf3\\xf0\\xe0\\xf6\\xe8\\xff API:"))

		if uv0.BeginChild("##ai_config", uv0.ImVec2(uv0.GetContentRegionAvail().x, 205), true) then
			uv0.SetCursorPos(uv0.ImVec2(10, 10))
			uv0.PushItemWidth(slot3 - 35)
			uv0.TextDisabled(uv2("API \\xca\\xeb\\xfe\\xf7:"))

			if uv0.InputText("##ai_key", uv1.ai.api_key, 256, uv0.InputTextFlags.Password) then
				save_cfg()
			end

			uv0.Spacing()
			uv0.SetCursorPosX(10)
			uv0.TextDisabled(uv2("Base URL:"))

			if uv0.InputText("##ai_url", uv1.ai.base_url, 256) then
				save_cfg()
			end

			uv0.Spacing()
			uv0.SetCursorPosX(10)
			uv0.TextDisabled(uv2("\\xcc\\xee\\xe4\\xe5\\xeb\\xfc (Model ID):"))

			if uv0.InputText("##ai_model", uv1.ai.model_id, 128) then
				save_cfg()
			end

			uv0.PopItemWidth()
			uv0.EndChild()
		end

		uv0.Spacing()

		if uv0.BeginChild("##ai_switches", uv0.ImVec2(slot3, 50), true) then
			uv0.SetCursorPos(uv0.ImVec2(10, 12))

			if uv0.CustomCheckbox(uv2("\\xc0\\xea\\xf2\\xe8\\xe2\\xe5\\xed (\\xc0\\xe2\\xf2\\xee\\xec\\xe0\\xf2\\xe8\\xf7\\xe5\\xf1\\xea\\xe8\\xe5 \\xee\\xf2\\xe2\\xe5\\xf2\\xfb)"), uv1.ai.enabled) then
				save_cfg()
			end

			uv0.EndChild()
		end

		uv0.Spacing()
		uv0.TextDisabled(uv2("\\xd0\\xf3\\xf7\\xed\\xee\\xe9 \\xe7\\xe0\\xef\\xf0\\xee\\xf1:"))

		if uv0.BeginChild("##ai_manual", uv0.ImVec2(slot3, 55), true) then
			uv0.SetCursorPos(uv0.ImVec2(10, 15))
			uv0.PushItemWidth(slot3 - 115)
			uv0.InputText("##user_query", uv1.ai.user_query, 512)
			uv0.PopItemWidth()
			uv0.SameLine()

			if uv0.Button(uv2("\\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xe8\\xf2\\xfc"), uv0.ImVec2(90, 25)) and uv4.string(uv1.ai.user_query) ~= "" then
				RequestAI(slot4, true)
				uv4.fill(uv1.ai.user_query, 512, 0)
			end

			uv0.EndChild()
		end

		uv0.Spacing()
		uv0.Separator()
		uv0.Spacing()

		if uv0.CustomButton(uv2("\\xd1\\xee\\xf5\\xf0\\xe0\\xed\\xe8\\xf2\\xfc \\xed\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8"), uv0.ImVec4(0.15, 0.5, 0.2, 0.6), uv0.ImVec4(0.2, 0.7, 0.3, 0.8), uv0.ImVec4(0.1, 0.4, 0.1, 1), uv0.ImVec2(slot3, 35)) then
			save_cfg()
			add_log("{33FF33}[\\xc8\\xc8] \\xcd\\xe0\\xf1\\xf2\\xf0\\xee\\xe9\\xea\\xe8 \\xee\\xe1\\xed\\xee\\xe2\\xeb\\xe5\\xed\\xfb")
			sampAddChatMessage("{00FF00}[Nexa AI]: {FFFFFF}\\xca\\xee\\xed\\xf4\\xe8\\xe3\\xf3\\xf0\\xe0\\xf6\\xe8\\xff \\xf1\\xee\\xf5\\xf0\\xe0\\xed\\xe5\\xed\\xe0!", -1)
		end

		uv0.Spacing()

		if uv0.CustomButton(uv2("\\xcf\\xf0\\xee\\xe2\\xe5\\xf0\\xe8\\xf2\\xfc \\xf1\\xee\\xe5\\xe4\\xe8\\xed\\xe5\\xed\\xe8\\xe5"), uv0.ImVec4(0.12, 0.15, 0.2, 0.9), uv0.ImVec4(0.18, 0.22, 0.3, 1), uv0.ImVec4(0.08, 0.1, 0.12, 1), uv0.ImVec2(slot3, 35)) and RequestAI then
			add_log("{33CCFF}[\\xc8\\xc8] \\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xea\\xe0 \\xf2\\xe5\\xf1\\xf2\\xee\\xe2\\xee\\xe3\\xee \\xe7\\xe0\\xef\\xf0\\xee\\xf1\\xe0...")
			RequestAI("\\xcf\\xf0\\xe8\\xe2\\xe5\\xf2! \\xc5\\xf1\\xeb\\xe8 \\xf2\\xfb \\xec\\xe5\\xed\\xff \\xf1\\xeb\\xfb\\xf8\\xe8\\xf8\\xfc, \\xee\\xf2\\xe2\\xe5\\xf2\\xfc '\\xd2\\xe3\\xea @NexaCFG'.", true)
		end

		uv0.Spacing()

		if uv0.CustomButton(uv2("\\xc7\\xc0\\xca\\xd0\\xdb\\xd2\\xdc"), uv0.ImVec4(0.85, 0.25, 0.25, 0.4), uv0.ImVec4(1, 0.3, 0.3, 0.6), uv0.ImVec4(0.6, 0.1, 0.1, 1), uv0.ImVec2(slot3, 30)) then
			uv1.farm.ai_window[0] = false
		end

		uv0.End()
	end

	uv0.PopStyleVar(4)
end)

slot104 = {
	"\\xe2\\xfb \\xf2\\xf3\\xf2?",
	"\\xf2\\xfb \\xf2\\xf3\\xf2?",
	"\\xf2\\xf3\\xf2?",
	"\\xf2\\xf3\\xf2 \\xeb\\xe8?",
	"\\xe6\\xe8\\xe2\\xee\\xe9?",
	"\\xf2\\xfb \\xe6\\xe8\\xe2\\xee\\xe9?",
	"\\xf2\\xfb \\xe7\\xe4\\xe5\\xf1\\xfc?",
	"\\xe1\\xee\\xf2?",
	"\\xe1\\xee\\xf2"
}
slot105 = {
	"\\xe3\\xee\\xe2\\xee\\xf0\\xe8\\xf2",
	"vip",
	"forever",
	"admin",
	"premium"
}

function slot2.onSendPlayerSync(slot0)
	if uv0.sync_enabled then
		slot0.upDownKeys = 65408
	end
end

function onReceivePacket(slot0, slot1)
	if slot0 ~= 220 or not uv0.farm.auto_eat[0] then
		return
	end

	raknetBitStreamIgnoreBits(slot1, 8)

	if raknetBitStreamReadInt8(slot1) ~= 17 then
		return
	end

	raknetBitStreamIgnoreBits(slot1, 32)

	slot2 = raknetBitStreamReadInt16(slot1)

	if (raknetBitStreamReadInt8(slot1) ~= 0 and raknetBitStreamDecodeString(slot1, slot2 + slot3) or raknetBitStreamReadString(slot1, slot2)):find("event%.arizonahud%.playerSatiety', `%[(%d+)%]`") then
		uv1.satiety = tonumber(slot4:match("(%d+)"))
	end
end

function slot2.onShowDialog(slot0, slot1, slot2, slot3, slot4, slot5)
	if not uv0.farm.prot_dialog[0] then
		return
	end

	slot7 = slot5:gsub("%{.-%}", "")

	if slot1 == 0 and slot7:find("A: .+ \\xee\\xf2\\xe2\\xe5\\xf2\\xe8\\xeb \\xe2\\xe0\\xec") then
		uv0.pause_bot[0] = true

		stop_moving_keys()

		if not isCharInAnyCar(uv1.ped) then
			clearCharTasksImmediately(uv1.ped)
		end

		slot8 = slot7:match("\\xee\\xf2\\xe2\\xe5\\xf2\\xe8\\xeb \\xe2\\xe0\\xec:%s*(.*)") or slot7:match("\\xee\\xf2\\xe2\\xe5\\xf2\\xe8\\xeb \\xe2\\xe0\\xec%s*(.*)") or "\\xc2\\xfb \\xf2\\xf3\\xf2?"

		add_log("{FF0000}\\xc1\\xc5\\xc7\\xce\\xcf\\xc0\\xd1\\xcd\\xce\\xd1\\xd2\\xdc: \\xc0\\xe4\\xec\\xe8\\xed \\xee\\xf2\\xef\\xf0\\xe0\\xe2\\xe8\\xeb \\xe4\\xe8\\xe0\\xeb\\xee\\xe3!")

		if slot6.antadmin_tg[0] then
			send_telegram("\\xc0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0 \\xee\\xf2\\xef\\xf0\\xe0\\xe2\\xe8\\xeb \\xe4\\xe8\\xe0\\xeb\\xee\\xe3:\n" .. slot7)
		end

		lua_thread.create(function ()
			wait(math.random(4000, 7500))
			sampCloseCurrentDialogWithButton(1)

			if uv0.ai.enabled[0] then
				wait(math.random(2500, 5000))
				RequestAI("\\xc0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0 \\xef\\xf0\\xe8\\xf1\\xeb\\xe0\\xeb \\xe4\\xe8\\xe0\\xeb\\xee\\xe3: " .. uv1, false)
				add_log("{33FF33}[\\xc1\\xe5\\xe7\\xee\\xef\\xe0\\xf1\\xed\\xee\\xf1\\xf2\\xfc] \\xc7\\xe0\\xef\\xf0\\xee\\xf1 \\xea \\xc8\\xc8 \\xee\\xf2\\xef\\xf0\\xe0\\xe2\\xeb\\xe5\\xed.")
			end
		end)
	end
end

function slot2.onSetPlayerPos(slot0)
	if not uv0.farm.running[0] or not uv0.farm.prot_spawn[0] then
		return
	end

	slot1, slot2, slot3 = getCharCoordinates(PLAYER_PED)

	if getDistanceBetweenCoords3d(slot1, slot2, slot3, slot0.x, slot0.y, slot0.z) > 5 then
		uv0.pause_bot[0] = true

		add_log("{FF0000}\\xc1\\xc5\\xc7\\xce\\xcf\\xc0\\xd1\\xcd\\xce\\xd1\\xd2\\xdc: \\xd0\\xe5\\xe7\\xea\\xee\\xe5 \\xe8\\xe7\\xec\\xe5\\xed\\xe5\\xed\\xe8\\xe5 \\xef\\xee\\xe7\\xe8\\xf6\\xe8\\xe8 \\xed\\xe0 " .. math.floor(slot4) .. "\\xec!")
		lua_thread.create(function ()
			wait(math.random(3000, 6000))

			if #presence_answers > 0 then
				sampSendChat(presence_answers[math.random(1, #presence_answers)])
				add_log("{33FF33}[\\xc0\\xe2\\xf2\\xee-\\xee\\xf2\\xe2\\xe5\\xf2] \\xce\\xf2\\xef\\xf0\\xe0\\xe2\\xeb\\xe5\\xed\\xe0 \\xf0\\xe5\\xe0\\xea\\xf6\\xe8\\xff \\xed\\xe0 \\xf2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2.")
			end

			wait(2000)

			uv0.pause_bot[0] = false
		end)

		if uv0.farm.antadmin_tg[0] then
			send_telegram("\\xd1\\xe5\\xf0\\xe2\\xe5\\xf0 \\xef\\xe5\\xf0\\xe5\\xec\\xe5\\xf1\\xf2\\xe8\\xeb \\xe2\\xe0\\xf1 \\xed\\xe0 " .. math.floor(slot4) .. " \\xec\\xe5\\xf2\\xf0\\xee\\xe2!")
		end
	end
end

function slot106(slot0)
	for slot4, slot5 in ipairs(uv0) do
		if slot0:find(slot5) then
			return true
		end
	end

	return false
end

function slot107(slot0)
	for slot4, slot5 in ipairs(uv0) do
		if slot0:find(slot5:lower()) then
			return true
		end
	end

	return false
end

function slot108(slot0, slot1)
	add_log("{FF0000}\\xc7\\xc0\\xd9\\xc8\\xd2\\xc0: " .. (slot1 and "\\xcf\\xf0\\xe8\\xed\\xf3\\xe4\\xe8\\xf2\\xe5\\xeb\\xfc\\xed\\xe0\\xff \\xf2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2\\xe0\\xf6\\xe8\\xff!" or "\\xd1\\xee\\xee\\xe1\\xf9\\xe5\\xed\\xe8\\xe5 \\xee\\xf2 \\xe0\\xe4\\xec\\xe8\\xed\\xe0!"))

	uv0.pause_bot[0] = true

	if uv0.farm.antadmin_autooff[0] then
		slot2.running[0] = false

		emergency_stop()
		add_log("{FF0000}\\xc1\\xee\\xf2 \\xee\\xf2\\xea\\xeb\\xfe\\xf7\\xb8\\xed \\xe0\\xe2\\xf2\\xee\\xec\\xe0\\xf2\\xe8\\xf7\\xe5\\xf1\\xea\\xe8.")
		send_session_report(slot3)
	end

	if slot1 and slot2.antadmin_stop_on_tp[0] and slot2.prot_teleport[0] then
		slot2.running[0] = false

		emergency_stop()
		add_log("{FF0000}\\xd1\\xf2\\xee\\xef \\xef\\xee \\xf2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2\\xf3.")
		send_session_report("\\xd2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2\\xe0\\xf6\\xe8\\xff \\xe0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0\\xee\\xec")
	end

	if slot2.antadmin_tg[0] then
		send_telegram("\\xc2\\xcd\\xc8\\xcc\\xc0\\xcd\\xc8\\xc5: \\xe4\\xe5\\xe9\\xf1\\xf2\\xe2\\xe8\\xe5 \\xe0\\xe4\\xec\\xe8\\xed\\xe0!\n\\xd2\\xe8\\xef: " .. slot3 .. "\n\\xd2\\xe5\\xea\\xf1\\xf2: " .. slot0)
	end

	if slot2.alarm_enabled[0] and uv1.string(slot2.alarm_url) ~= "" then
		os.execute("start " .. slot4)
		add_log("{FF3333}[\\xd2\\xf0\\xe5\\xe2\\xee\\xe3\\xe0] \\xd1\\xf0\\xe0\\xe1\\xee\\xf2\\xe0\\xeb\\xe0 \\xf2\\xf0\\xe5\\xe2\\xee\\xe3\\xe0!")
	end

	if slot1 and slot2.delay_chat_on_tp[0] then
		send_delay_chat_message()
	end

	if slot2.antadmin_safeexit[0] then
		lua_thread.create(function ()
			wait(20000)

			if uv0.pause_bot[0] then
				sampProcessChatInput("/q")
				send_telegram("\\xc0\\xe2\\xf2\\xee\\xe2\\xfb\\xf5\\xee\\xe4 \\xe2\\xfb\\xef\\xee\\xeb\\xed\\xe5\\xed (\\xef\\xf0\\xee\\xf8\\xeb\\xee 20 \\xf1\\xe5\\xea)")
			end
		end)
	end
end

function slot2.onServerMessage(slot0, slot1)
	slot2 = uv0.farm

	if not uv0.ai.enabled[0] then
		return
	end

	for slot9, slot10 in ipairs({
		"\\xf0\\xe5\\xef\\xee\\xf0\\xf2",
		"\\xef\\xf0\\xe8\\xed\\xff\\xeb\\xf1\\xff",
		"\\xe6\\xe0\\xeb\\xee\\xe1\\xf3",
		"\\xe1\\xeb\\xe0\\xe3\\xee\\xe4\\xe0\\xf0\\xed\\xee\\xf1\\xf2\\xfc"
	}) do
		if slot1:gsub("%{.-%}", ""):lower():find(slot10, 1, true) then
			return
		end
	end

	if slot1:find("item1692") or slot1:find("\\xca\\xf3\\xf1\\xee\\xea \\xf0\\xe5\\xe4\\xea\\xee\\xe9 \\xf2\\xea\\xe0\\xed\\xe8") then
		slot2.res_counter.rare = slot2.res_counter.rare + tonumber(slot1:match("%((%d+)%s*\\xf8\\xf2%)") or 1)
	elseif slot1:find("\\xd3\\xe3\\xee\\xeb\\xfc") then
		slot2.res_counter.coal = slot2.res_counter.coal + tonumber(slot1:match("%((%d+)%s*\\xf8\\xf2%)") or 1)
	end

	if slot1:find("\\xe3\\xee\\xe2\\xee\\xf0\\xe8\\xf2") and slot2.antadmin_tg_all[0] then
		send_telegram("\\xcf\\xee\\xe4\\xee\\xe7\\xf0\\xe5\\xed\\xe8\\xe5 \\xed\\xe0 \\xef\\xf0\\xee\\xe2\\xe5\\xf0\\xea\\xf3 \\xe3\\xee\\xeb\\xee\\xf1\\xee\\xec\n" .. slot3)
	end

	if not slot2.prot_teleport[0] and not slot2.prot_admin_msg[0] then
		return
	end

	if (slot2.prot_teleport[0] or uv0.farm.antadmin_stop_on_tp[0]) and (slot3:find("\\xc2\\xfb \\xe1\\xfb\\xeb\\xe8 \\xf2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2\\xe8\\xf0\\xee\\xe2\\xe0\\xed\\xfb \\xe0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0\\xee\\xec .+") or slot3:find("A: .+%[ID: %d+%] \\xf2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2\\xe8\\xf0\\xee\\xe2\\xe0\\xeb \\xe2\\xe0\\xf1 \\xed\\xe0 \\xea\\xee\\xee\\xf0\\xe4\\xe8\\xed\\xe0\\xf2\\xfb: .+")) then
		if uv0.pause_bot[0] then
			return
		end

		uv0.pause_bot[0] = true

		stop_moving_keys()

		if not isCharInAnyCar(uv1.ped) then
			clearCharTasksImmediately(uv1.ped)
		end

		uv2(slot3, true)

		if slot2.antadmin_tg[0] then
			send_telegram("\\xd2\\xc5\\xcb\\xc5\\xcf\\xce\\xd0\\xd2: " .. slot3)
		end

		lua_thread.create(function ()
			wait(math.random(4000, 7000))
			RequestAI("\\xcc\\xe5\\xed\\xff \\xf2\\xe5\\xeb\\xe5\\xef\\xee\\xf0\\xf2\\xe8\\xf0\\xee\\xe2\\xe0\\xeb \\xe0\\xe4\\xec\\xe8\\xed. \\xce\\xf2\\xe2\\xe5\\xf2\\xfc \\xea\\xee\\xf0\\xee\\xf2\\xea\\xee \\xe2 /b \\xf7\\xe0\\xf2.", false)
		end)

		return
	end

	if slot2.prot_admin_msg[0] then
		if slot3:find("^\\xc0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0 .-%[%d+%]: .*") then
			if uv0.pause_bot[0] then
				return
			end

			slot6, slot7, slot8 = slot3:match("\\xc0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0 (.-)%[(%d+)%]: (.*)")

			if slot6 and slot8 then
				uv0.pause_bot[0] = true

				stop_moving_keys()

				if not isCharInAnyCar(uv1.ped) then
					clearCharTasksImmediately(uv1.ped)
				end

				uv2("\\xc0\\xe4\\xec\\xe8\\xed \\xf0\\xff\\xe4\\xee\\xec " .. slot6 .. ": " .. slot8, false)

				if slot2.antadmin_tg[0] then
					send_telegram("\\xc0\\xc4\\xcc\\xc8\\xcd \\xd0\\xdf\\xc4\\xce\\xcc: " .. slot6 .. "[" .. slot7 .. "]: " .. slot8)
				end

				lua_thread.create(function ()
					wait(math.random(6000, 10000))
					RequestAI("\\xc0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0 " .. uv0 .. " \\xed\\xe0\\xef\\xe8\\xf1\\xe0\\xeb \\xe2 \\xf7\\xe0\\xf2: " .. uv1, false)
				end)

				return
			end
		end

		if slot3:find("%(%( \\xc0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0 (.+)%[(%d+)%]: (.+) %)%)") then
			if uv0.pause_bot[0] then
				return
			end

			slot6, slot7, slot8 = slot3:match("%(%( \\xc0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0 (.+)%[(%d+)%]: (.+) %)%)")
			uv0.pause_bot[0] = true

			stop_moving_keys()
			uv2("\\xc0\\xe4\\xec\\xe8\\xed " .. slot6 .. ": " .. slot8, false)

			if slot2.antadmin_tg[0] then
				send_telegram("\\xc0\\xc4\\xcc\\xc8\\xcd \\xcf\\xc8\\xd8\\xc5\\xd2: " .. slot6 .. "[" .. slot7 .. "]: " .. slot8)
			end

			lua_thread.create(function ()
				wait(math.random(5000, 9000))
				RequestAI("\\xc0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0 " .. uv0 .. " \\xed\\xe0\\xef\\xe8\\xf1\\xe0\\xeb \\xec\\xed\\xe5 \\xe2 /b \\xf7\\xe0\\xf2: " .. uv1, false)
			end)

			return
		end

		if slot3:find("A: (.+) \\xee\\xf2\\xe2\\xe5\\xf2\\xe8\\xeb \\xe2\\xe0\\xec: (.+)") then
			if uv0.pause_bot[0] then
				return
			end

			slot6, slot7 = slot3:match("A: (.+) \\xee\\xf2\\xe2\\xe5\\xf2\\xe8\\xeb \\xe2\\xe0\\xec: (.+)")
			uv0.pause_bot[0] = true

			stop_moving_keys()
			uv2("\\xce\\xf2\\xe2\\xe5\\xf2 \\xee\\xf2 " .. slot6 .. ": " .. slot7, false)

			if slot2.antadmin_tg[0] then
				send_telegram("\\xce\\xd2\\xc2\\xc5\\xd2 \\xc0\\xc4\\xcc\\xc8\\xcd\\xc0 (" .. slot6 .. "): " .. slot7)
			end

			lua_thread.create(function ()
				wait(math.random(4000, 8000))
				RequestAI("\\xc0\\xe4\\xec\\xe8\\xed\\xe8\\xf1\\xf2\\xf0\\xe0\\xf2\\xee\\xf0 " .. uv0 .. " \\xee\\xf2\\xe2\\xe5\\xf2\\xe8\\xeb \\xec\\xed\\xe5 \\xe2 \\xe4\\xe8\\xe0\\xeb\\xee\\xe3\\xe5 \\xe8\\xeb\\xe8 \\xf7\\xe0\\xf2\\xe5: " .. uv1, false)
			end)

			return
		end

		if slot3:find("A: (.+)%[(%d+)%] \\xe2\\xe0\\xf1 \\xe7\\xe0\\xf1\\xef\\xe0\\xe2\\xed\\xe8\\xeb") then
			if uv0.pause_bot[0] then
				return
			end

			uv2(slot3, false)

			if slot2.antadmin_tg[0] then
				send_telegram("\\xc7\\xc0\\xd1\\xcf\\xc0\\xc2\\xcd\\xc8\\xcb\\xc8: " .. slot3)
			end

			return
		end
	end

	if slot2.auto_answer[0] and not uv3 and (slot4:find(uv1.nick:lower()) or slot4:find("\\xf0\\xe0\\xe1\\xee\\xf2\\xff\\xe3\\xe0")) and not slot4:find("forever") then
		uv3 = true

		if slot2.antadmin_tg_all[0] then
			send_telegram("\\xce\\xc1\\xd0\\xc0\\xd9\\xc5\\xcd\\xc8\\xc5 \\xce\\xd2 \\xc8\\xc3\\xd0\\xce\\xca\\xc0: " .. slot3)
		end

		lua_thread.create(function ()
			wait(math.random(5000, 10000))
			RequestAI("\\xc8\\xe3\\xf0\\xee\\xea \\xe2 \\xf7\\xe0\\xf2\\xe5 \\xee\\xe1\\xf0\\xe0\\xf2\\xe8\\xeb\\xf1\\xff \\xea\\xee \\xec\\xed\\xe5: " .. uv0 .. ". \\xce\\xf2\\xe2\\xe5\\xf2\\xfc \\xe4\\xf0\\xf3\\xe6\\xe5\\xeb\\xfe\\xe1\\xed\\xee \\xe8 \\xea\\xee\\xf0\\xee\\xf2\\xea\\xee.", false)
			wait(20000)

			uv1 = false
		end)
	end
end

function slot2.onDisplayGameText(slot0, slot1, slot2)
	slot3 = slot2:lower()
	slot5 = slot3:match("cotton%s+%+(%d+)")

	if slot3:match("linen%s+%+(%d+)") then
		uv0.farm.res_counter.linen = uv0.farm.res_counter.linen + tonumber(slot4)
		uv1.active = false
	elseif slot5 then
		uv0.farm.res_counter.cotton = uv0.farm.res_counter.cotton + tonumber(slot5)
		uv1.active = false
	end
end

slot109 = slot6.cast("uintptr_t*", 11990512)
slot110 = false

function main()
	while not isSampAvailable() do
		wait(100)
	end

	if not doesDirectoryExist(config_root) then
		createDirectory(config_root)
	end

	if not doesDirectoryExist(resource_root) then
		createDirectory(resource_root)
	end

	if not doesDirectoryExist(uv0) then
		createDirectory(uv0)
	end

	if not doesDirectoryExist(uv1) then
		createDirectory(uv1)
	end

	lua_thread.create(function ()
		while not isSampAvailable() do
			wait(100)
		end

		wait(2000)
		show_arz_notify("success", "NexaArizona", "\\xc4\\xee\\xe1\\xf0\\xee \\xef\\xee\\xe6\\xe0\\xeb\\xee\\xe2\\xe0\\xf2\\xfc, \\xf1 \\xf3\\xe2\\xe0\\xe6\\xe5\\xed\\xe8\\xe5\\xec NexaArizona", 8000)
		visualCEF(string.format("window.executeEvent(\"event.arizonahud.setTimeWidgetInfo\", %q);", uv0.encode({
			{
				playedToday = 0,
				playedHour = 0,
				timestamp = os.time(),
				components = {
					{
						description = "@nexacfg",
						title = "NexaArizona",
						image = "sms.webp",
						gradientColors = {
							"#00416A",
							"#E4E5E6"
						}
					},
					{
						description = "\\xd1\\xea\\xf0\\xe8\\xef\\xf2 \\xf3\\xf1\\xef\\xe5\\xf8\\xed\\xee \\xe7\\xe0\\xef\\xf3\\xf9\\xe5\\xed",
						title = "\\xd1\\xf2\\xe0\\xf2\\xf3\\xf1",
						image = "accessoryRent.webp",
						gradientColors = {
							"#11998e",
							"#38ef7d"
						}
					}
				}
			}
		})), true)
		wait(10000)
		visualCEF("window.executeEvent(\"event.arizonahud.setTimeWidgetHide\", \"[ null ]\");", true)
	end)
	uv3()
	uv4()
	wait(1000)
	writeMemory(8381985, 4, 13213544, true)

	slot0 = 0

	while not isSampAvailable() do
		wait(500)

		if slot0 + 500 > 60000 then
			print("[NexaArizona] SAMP \\xed\\xe5 \\xed\\xe0\\xe9\\xe4\\xe5\\xed, \\xe7\\xe0\\xe2\\xe5\\xf0\\xf8\\xe5\\xed\\xe8\\xe5 \\xf0\\xe0\\xe1\\xee\\xf2\\xfb.")

			return
		end
	end

	wait(2000)

	slot1, slot2 = pcall(function ()
		return playerPed
	end)

	if not slot1 or not slot2 then
		print("[NexaArizona] \\xce\\xf8\\xe8\\xe1\\xea\\xe0: playerPed \\xed\\xe5\\xe4\\xee\\xf1\\xf2\\xf3\\xef\\xe5\\xed. \\xc2\\xfb\\xf5\\xee\\xe4.")

		return
	end

	uv5.ped = slot2
	slot3, slot4, slot5 = pcall(sampGetPlayerIdByCharHandle, uv5.ped)

	if not slot3 then
		print("[NexaArizona] \\xce\\xf8\\xe8\\xe1\\xea\\xe0: \\xcd\\xe5 \\xf3\\xe4\\xe0\\xeb\\xee\\xf1\\xfc \\xef\\xee\\xeb\\xf3\\xf7\\xe8\\xf2\\xfc ID \\xe8\\xe3\\xf0\\xee\\xea\\xe0. \\xc2\\xfb\\xf5\\xee\\xe4.")

		return
	end

	uv5.id = slot5
	uv5.nick = sampGetPlayerNickname(uv5.id) or ""
	PLAYER_PED = uv5.ped
	myPlayerId = uv5.id
	myNick = uv5.nick
	slot6, slot7 = pcall(function ()
		if uv0 then
			uv1.nav = uv0.new()

			uv1.nav:init()

			if uv1.nav.config then
				uv1.nav.config.max_size = 40
				uv1.nav.config.render_dist = 15
			end
		end
	end)

	if slot6 then
		add_log("{33FF33}[NavMesh] \\xc8\\xed\\xe8\\xf6\\xe8\\xe0\\xeb\\xe8\\xe7\\xe8\\xf0\\xee\\xe2\\xe0\\xed \\xf3\\xf1\\xef\\xe5\\xf8\\xed\\xee.")
	else
		add_log("{FF3333}[NavMesh] \\xce\\xf8\\xe8\\xe1\\xea\\xe0 \\xe8\\xed\\xe8\\xf6\\xe8\\xe0\\xeb\\xe8\\xe7\\xe0\\xf6\\xe8\\xe8: " .. tostring(slot7))

		uv7.nav = nil
	end

	uv8 = uv9:new(0, 0, getScreenResolution())

	sampAddChatMessage("{33CCFF}[NexaArizona v1.5.5]{FFFFFF} \\xc7\\xe0\\xe3\\xf0\\xf3\\xe6\\xe5\\xed!", -1)
	sampAddChatMessage("{33CCFF}[NexaArizona]{FFFFFF} \\xcc\\xe5\\xed\\xfe: /cotton \\xe8\\xeb\\xe8 ALT+N", -1)

	if not load_cfg() then
		print("[NexaArizona] \\xca\\xee\\xed\\xf4\\xe8\\xe3 \\xed\\xe5 \\xed\\xe0\\xe9\\xe4\\xe5\\xed, \\xf1\\xee\\xe7\\xe4\\xe0\\xb8\\xf2\\xf1\\xff \\xed\\xee\\xe2\\xfb\\xe9.")
		save_cfg()
	end

	lua_thread.create(uv10.startPollingUpdates)
	getLastUpdate()
	sampRegisterChatCommand("cotton", function ()
		uv0.window_open[0] = not uv0.window_open[0]
	end)

	slot8 = renderCreateFont("Arial", 9, 5)
	slot9 = 0

	while true do
		wait(0)

		uv12.frames = uv12.frames + 1

		if os.clock() - uv12.last_tick >= 1 then
			uv12.value = uv12.frames
			uv12.frames = 0
			uv12.last_tick = slot10
		end

		slot11 = os.time()

		if uv11.timer.enabled[0] then
			if uv11.timer.startTime == 0 then
				uv11.timer.startTime = os.time()
			end

			if math.floor(uv11.timer.hours[0] + 0.5) * 3600 + math.floor(uv11.timer.minutes[0] + 0.5) * 60 > 0 and slot14 <= os.time() - uv11.timer.startTime then
				add_log("{FF3333}[\\xd2\\xe0\\xe9\\xec\\xe5\\xf0] \\xc2\\xf0\\xe5\\xec\\xff \\xe2\\xfb\\xf8\\xeb\\xee. \\xd1\\xea\\xf0\\xe8\\xef\\xf2 \\xe2\\xfb\\xe3\\xf0\\xf3\\xe6\\xe0\\xe5\\xf2\\xf1\\xff.")
				thisScript():unload()
			end
		elseif uv11.timer.startTime ~= 0 then
			uv11.timer.startTime = 0
		end

		if uv11.options.screen_timer_enabled[0] and uv11.options.screen_interval[0] > 0 and slot11 - uv11.options.last_screen_time >= uv11.options.screen_interval[0] * 60 then
			uv11.options.last_screen_time = slot11

			sendPhoto()
		end

		if uv11.farm.disable_splash[0] then
			uv13[0] = false
		end

		if uv11.cleaner.enabled[0] and uv11.cleaner.limit[0] <= getMemoryUsage() then
			CleanMemory()
		end

		slot12 = os.clock()

		if uv11.farm.running[0] and not uv11.pause_bot[0] and slot12 - slot9 > 5 then
			slot13, slot14, slot15 = getNearbyVehicle(15)

			if slot13 then
				slot17 = string.format("\\xd0\\xff\\xe4\\xee\\xec \\xee\\xe1\\xed\\xe0\\xf0\\xf3\\xe6\\xe5\\xed\\xe0 \\xec\\xe0\\xf8\\xe8\\xed\\xe0! \\xcc\\xee\\xe4\\xe5\\xeb\\xfc: %d, \\xc4\\xe8\\xf1\\xf2\\xe0\\xed\\xf6\\xe8\\xff: %.1f\\xec", getCarModel(slot14), slot15)

				add_log("{FFCC00}[\\xc2\\xed\\xe8\\xec\\xe0\\xed\\xe8\\xe5] " .. slot17)
				send_telegram("" .. slot17)

				slot9 = slot12 + 25
			else
				slot9 = slot12
			end
		end

		if uv7.nav and uv11.farm.navmesh_render_mesh[0] then
			slot13 = {
				getCharVelocity(uv5.ped)
			}

			if math.sqrt(slot13[1]^2 + slot13[2]^2) > 0.1 then
				uv7.segment_size = uv7.max_radius
			else
				uv7.segment_size = uv7.min_radius
			end

			if os.clock() - uv7.update_tick >= 0.5 then
				uv7.update_tick = os.clock()

				if uv7.nav.config then
					uv7.nav.config.max_size = uv7.segment_size
				end

				pcall(function ()
					uv0.nav:update_mesh(true)
				end)

				if uv7.smart_filter then
					pcall(function ()
						uv0.nav:set_filter_objects(true)
					end)
				end
			end

			if uv14 and type(uv14.renderNavMesh) == "function" then
				uv14.renderNavMesh(uv7.nav)
			end
		end

		if uv15.active and uv11.farm.running[0] and uv11.farm.anti_stuck_jump[0] then
			slot13 = uv16()

			if uv15.timeout <= os.time() - uv15.start_time and (not slot13 or slot13.status ~= "GROWING") then
				lua_thread.create(function ()
					uv0.is_jumping = true

					setGameKeyState(14, 255)
					wait(120)
					setGameKeyState(14, 0)

					uv0.is_jumping = false
				end)

				uv15.active = false
			end
		end

		if uv11.farm.auto_skin[0] and uv11.farm.running[0] and not uv11.pause_bot[0] and uv11.farm.auto_skin_interval[0] * 60 <= os.time() - uv11.farm.last_skin_time then
			uv11.farm.last_skin_time = os.time()

			lua_thread.create(function ()
				uv0.active = false

				stop_moving_keys()
				add_log("{33CCFF}[\\xc0\\xe2\\xf2\\xee-\\xea\\xeb\\xee\\xed] \\xce\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xea\\xe0 \\xe4\\xeb\\xff \\xe8\\xf1\\xef\\xee\\xeb\\xfc\\xe7\\xee\\xe2\\xe0\\xed\\xe8\\xff \\xea\\xee\\xec\\xe0\\xed\\xe4\\xfb...")
				wait(math.random(800, 1500))
				collectgarbage("step", 100)
				sampSendChat("/anim 1")
				add_log(string.format("{33CCFF}[\\xc0\\xe2\\xf2\\xee-\\xea\\xeb\\xee\\xed] \\xca\\xee\\xec\\xe0\\xed\\xe4\\xe0 \\xee\\xf2\\xef\\xf0\\xe0\\xe2\\xeb\\xe5\\xed\\xe0 (\\xe8\\xed\\xf2\\xe5\\xf0\\xe2\\xe0\\xeb %d \\xec\\xe8\\xed)", uv1.farm.auto_skin_interval[0]))
				wait(math.random(1000, 2000))

				uv0.active = true

				add_log("{33CCFF}[\\xc0\\xe2\\xf2\\xee-\\xea\\xeb\\xee\\xed] \\xcf\\xf0\\xee\\xe4\\xee\\xeb\\xe6\\xe0\\xfe \\xf4\\xe0\\xf0\\xec.")
			end)
		end

		if (tonumber(uv5.satiety) or 100) <= uv11.farm.eat_percent[0] and not uv5.eating_in_progress and uv11.farm.auto_eat[0] and uv11.farm.running[0] then
			uv5.eating_in_progress = true

			lua_thread.create(function ()
				if uv0.farm.eat_method[0] ~= 4 then
					uv1.active = false

					stop_moving_keys()
					wait(math.random(800, 1500))

					if ({
						"/cheeps",
						"/jfish",
						"/jmeat",
						"/meatbag"
					})[uv0.farm.eat_method[0] + 1] then
						sampSendChat(slot1)
						wait(math.random(3500, 5000))
					end

					uv1.active = true
				end

				uv2.eating_in_progress = false
			end)
		end

		if isKeyDown(uv18.VK_MENU) and isKeyJustPressed(uv18.VK_N) then
			uv11.window_open[0] = not uv11.window_open[0]
		end

		slot13 = uv11.farm.menu_bind_key[0]

		if not uv19 and not uv20 and slot13 > 0 and isKeyJustPressed(slot13) then
			uv11.window_open[0] = not uv11.window_open[0]
		end

		slot14 = uv11.theme.bot_bind_key[0]

		if not uv20 and not uv19 and slot14 > 0 and not uv11.window_open[0] and isKeyJustPressed(slot14) then
			if uv11.farm.running[0] then
				uv11.farm.running[0] = false

				emergency_stop()
				add_log("{FF3333}[\\xc1\\xe8\\xed\\xe4] \\xc1\\xee\\xf2 \\xee\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xeb\\xe5\\xed. \\xca\\xed\\xee\\xef\\xea\\xe0: [" .. uv21(slot14) .. "]")
				send_session_report("\\xce\\xf1\\xf2\\xe0\\xed\\xee\\xe2\\xea\\xe0 \\xef\\xee \\xe1\\xe8\\xed\\xe4\\xf3 [" .. uv21(slot14) .. "]")
			else
				uv11.farm.running[0] = true
				uv11.farm.res_counter.cotton = 0
				uv11.farm.res_counter.linen = 0
				uv11.farm.res_counter.rare = 0
				uv11.farm.stats.start_time = os.time()

				resetNavPath()
				add_log("{33FF33}[\\xc1\\xe8\\xed\\xe4] \\xc1\\xee\\xf2 \\xe7\\xe0\\xef\\xf3\\xf9\\xe5\\xed. \\xca\\xed\\xee\\xef\\xea\\xe0: [" .. uv21(slot14) .. "]")
				send_telegram("\\xc1\\xee\\xf2 \\xe7\\xe0\\xef\\xf3\\xf9\\xe5\\xed!\n\\xc8\\xe3\\xf0\\xee\\xea: " .. uv5.nick .. "\n\\xca\\xed\\xee\\xef\\xea\\xe0: [" .. uv21(slot14) .. "]")
			end
		end

		if uv11.farm.running[0] and not uv11.pause_bot[0] and not isCharInAnyCar(uv5.ped) then
			piskaadminzabor()
			update_movement()
		elseif uv11.farm.running[0] and uv11.pause_bot[0] then
			stop_moving_keys()

			if not isCharInAnyCar(uv5.ped) then
				clearCharTasksImmediately(uv5.ped)
			end
		end

		if uv11.farm.disable_splash[0] then
			uv13[0] = false
		end

		if uv11.farm.cj_run[0] ~= uv22 then
			setAnimGroupForChar(uv5.ped, uv11.farm.cj_run[0] and "player" or "man")

			uv22 = uv11.farm.cj_run[0]
		end

		if uv11.farm.inf_run[0] then
			uv23.setint8(12046052, 1)
		else
			uv23.setint8(12046052, 0)
		end

		if uv11.farm.anti_hunger_sprint[0] and isButtonPressed(PLAYER_HANDLE, 16) and not isCharSittingInAnyCar(uv5.ped) then
			slot15, slot16 = pcall(function ()
				return uv0.cast("float*", uv0.cast("uintptr_t*", uv1[0] + 1152)[0] + 28)
			end)

			if slot15 and slot16[0] < 1 then
				slot16[0] = 1
			end
		end

		if uv11.farm.auto_jump[0] and uv11.farm.running[0] and not uv11.pause_bot[0] and uv17.active and not uv26 and os.clock() - uv11.farm.last_jump_time >= 1.8 + math.random() * 1.2 then
			uv11.farm.last_jump_time = slot15

			lua_thread.create(function ()
				uv0.is_jumping = true

				setGameKeyState(14, 255)
				wait(100)
				setGameKeyState(14, 0)

				uv0.is_jumping = false
			end)
		end
	end
end
