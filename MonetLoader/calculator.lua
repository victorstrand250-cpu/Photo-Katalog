script_name("Калькулятор сумм")
script_author("Victor Strand")
script_version("2.0")

local sampev = require("lib.samp.events")

local function u2a(s)
    local res = {}
    local i, n = 1, #s
    while i <= n do
        local b = s:byte(i)
        if b < 0x80 then
            res[#res + 1] = string.char(b)
            i = i + 1
        elseif b == 0xD0 or b == 0xD1 then
            local b2 = s:byte(i + 1) or 0
            local cp = (b - 0xC0) * 64 + (b2 - 0x80)
            local out
            if cp >= 0x410 and cp <= 0x44F then
                out = cp - 0x410 + 0xC0
            elseif cp == 0x401 then
                out = 0xA8
            elseif cp == 0x451 then
                out = 0xB8
            else
                out = 0x3F
            end
            res[#res + 1] = string.char(out)
            i = i + 2
        else
            res[#res + 1] = string.char(b)
            i = i + 1
        end
    end
    return table.concat(res)
end

local K_CP1251 = string.char(234)

local function normalize(s)
    s = s:gsub("\208\186", "k"):gsub("\208\154", "k")
    s = s:gsub("\234", "k"):gsub("\202", "k")
    s = s:gsub("K", "k")
    s = s:gsub("\208\188", "kk"):gsub("\208\156", "kk")
    s = s:gsub("\236", "kk"):gsub("\204", "kk")
    s = s:gsub("[mM]", "kk")
    s = s:gsub("\208\177", "kkk"):gsub("\208\145", "kkk")
    s = s:gsub("\225", "kkk"):gsub("\193", "kkk")
    s = s:gsub("[bB]", "kkk")
    s = s:gsub(",", "."):gsub("%s+", "")
    return s
end

local function evaluate(src)
    local expr = normalize(src)
    if expr == "" then
        return nil
    end

    local pos = 1
    local len = #expr

    local function peek()
        return expr:sub(pos, pos)
    end
    local function advance()
        pos = pos + 1
    end
    local function isDigit(c)
        return c >= "0" and c <= "9"
    end

    local parseExpr

    local function readNumber()
        local start = pos
        while isDigit(peek()) do advance() end
        if peek() == "." then
            advance()
            while isDigit(peek()) do advance() end
        end
        local numstr = expr:sub(start, pos - 1)
        if numstr == "" or numstr == "." then
            error("number")
        end
        local value = tonumber(numstr)
        if not value then error("number") end
        while peek() == "k" do
            advance()
            value = value * 1000
        end
        local pct = false
        if peek() == "%" then
            advance()
            pct = true
        end
        return value, pct
    end

    local function parsePrimary()
        local c = peek()
        if c == "(" then
            advance()
            local v = parseExpr()
            if peek() ~= ")" then error("paren") end
            advance()
            local pct = false
            if peek() == "%" then
                advance()
                pct = true
            end
            return v, pct
        elseif isDigit(c) or c == "." then
            return readNumber()
        else
            error("primary")
        end
    end

    local function parseFactor()
        local c = peek()
        if c == "-" then
            advance()
            local v, p = parseFactor()
            return -v, p
        elseif c == "+" then
            advance()
            return parseFactor()
        end
        local base, pct = parsePrimary()
        if peek() == "^" then
            advance()
            local exp = parseFactor()
            return base ^ exp, false
        end
        return base, pct
    end

    local function parseTerm()
        local v, pct = parseFactor()
        while true do
            local c = peek()
            if c == "*" then
                advance()
                local r, rp = parseFactor()
                v = rp and (v * r / 100) or (v * r)
                pct = false
            elseif c == "/" then
                advance()
                local r, rp = parseFactor()
                local d = rp and (r / 100) or r
                if d == 0 then error("divzero") end
                v = v / d
                pct = false
            else
                break
            end
        end
        return v, pct
    end

    parseExpr = function()
        local v, pct = parseTerm()
        while true do
            local c = peek()
            if c == "+" then
                advance()
                local r, rp = parseTerm()
                v = rp and (v + v * r / 100) or (v + r)
                pct = false
            elseif c == "-" then
                advance()
                local r, rp = parseTerm()
                v = rp and (v - v * r / 100) or (v - r)
                pct = false
            else
                break
            end
        end
        return v, pct
    end

    local ok, result = pcall(function()
        local v, p = parseExpr()
        if pos <= len then
            error("trailing")
        end
        if p then
            v = v / 100
        end
        return v
    end)

    if ok and type(result) == "number" and result == result then
        return result
    end
    return nil
end

local function formatThousands(n)
    local neg = n < 0
    n = math.abs(n)
    local intpart = math.floor(n + 1e-9)
    local frac = n - intpart
    local s = string.format("%.0f", intpart)
    local out = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    out = out:gsub("^%s+", "")
    if frac > 1e-9 then
        local fracstr = string.format("%.4f", frac):sub(3):gsub("0+$", "")
        if #fracstr > 0 then
            out = out .. "." .. fracstr
        end
    end
    if neg then
        out = "-" .. out
    end
    return out
end

local function formatCompact(n)
    local neg = n < 0
    n = math.abs(n)
    if n < 1000 then
        local s = string.format("%.2f", n):gsub("0+$", ""):gsub("%.$", "")
        return (neg and "-" or "") .. s
    end
    local level = 0
    local v = n
    while v >= 1000 and level < 10 do
        v = v / 1000
        level = level + 1
    end
    local vs = string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
    return (neg and "-" or "") .. vs .. string.rep(K_CP1251, level)
end

local function looksLikeMath(text)
    local e = normalize(text)
    if e == "" then
        return false
    end
    if not e:match("^[%d%.%+%-%*/%%%^%(%)k]+$") then
        return false
    end
    if not e:find("%d") then
        return false
    end
    if e:find("[%+%-%*/%%%^]") or e:find("k") or e:find("[%(%)]") then
        return true
    end
    return false
end

local COLOR = 0x00FF88
local enabled = true
local memory = 0

local function chat(s)
    sampAddChatMessage(u2a(s), COLOR)
end

function sampev.onSendChat(text)
    if not enabled then
        return
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")

    if trimmed:sub(1, 1) == "#" then
        if #trimmed == 1 then
            chat(string.format("{00FF88}[Память]{FFFFFF} сейчас: {FFD700}%s {888888}(%s)",
                formatThousands(memory), formatCompact(memory)))
        else
            memory = 0
            chat("{00FF88}[Память]{FFFFFF} сброшена: {FFD700}0")
        end
        return false
    end

    local addMem = false
    local exprText = trimmed
    if exprText:sub(-1) == "#" then
        addMem = true
        exprText = exprText:sub(1, -2):gsub("%s+$", "")
    end

    if not addMem and not looksLikeMath(exprText) then
        return
    end

    local result = evaluate(exprText)
    if result == nil then
        return
    end

    local full = formatThousands(result)
    local compact = formatCompact(result)

    local line
    if full == compact then
        line = string.format("{FFFFFF}%s {888888}= {00FF88}%s", exprText, full)
    else
        line = string.format("{FFFFFF}%s {888888}= {00FF88}%s {888888}(%s)", exprText, full, compact)
    end

    local norm = normalize(exprText)
    if norm:find("/") and result > 0 and math.abs(result - math.floor(result)) > 1e-9 then
        line = line .. string.format(" {888888}целых: {00FF88}%s", formatThousands(math.floor(result)))
    end

    if addMem then
        memory = memory + result
        line = line .. string.format("  {888888}>> в памяти: {FFD700}%s", formatThousands(memory))
    end

    chat(line)

    pcall(function()
        setClipboardText(string.format("%.0f", math.floor(result + 0.5)))
    end)

    return false
end

function main()
    while not isSampAvailable() do
        wait(0)
    end

    sampRegisterChatCommand("calc", function()
        enabled = not enabled
        if enabled then
            chat("{00FF88}[Калькулятор]{FFFFFF} включён. Пиши примеры в чат.")
        else
            chat("{FF5555}[Калькулятор]{FFFFFF} выключен. Напиши /calc чтобы включить снова.")
        end
    end)

    wait(1500)
    chat("{00FF88}[Калькулятор]{FFFFFF} загружен. Автор: {00FF88}Victor Strand")
    chat("{FFFFFF}Примеры: {00FF88}50к+30к{FFFFFF}, {00FF88}1кк+15%{FFFFFF}. Память: {00FF88}#{FFFFFF}. Вкл/выкл: {00FF88}/calc")
    wait(-1)
end
