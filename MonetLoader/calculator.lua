-- Калькулятор для MonetLoader / MoonLoader (SA-MP)
-- Пишешь выражение прямо в чат -> получаешь ответ. Без команд.
-- Поддержка форматов: 1к = 1 000, 1кк = 1 000 000, 1ккк = 1 000 000 000 и т.д.
-- Удобно фармилам считать большие суммы.
--
-- Примеры (просто напиши в чат и нажми отправить):
--   50к + 30к            -> 80 000 (80к)
--   1кк * 3              -> 3 000 000 (3кк)
--   (2ккк + 500кк) / 2   -> 1 250 000 000 (1.25ккк)
--   1.5кк - 250к         -> 1 250 000 (1.25кк)
--
-- Поддерживаются: + - * / % ^ ( ) , десятичные числа, суффиксы к/k (можно подряд).

script_name("Калькулятор сумм")
script_author("Photo-Katalog")
script_version("1.0")

local sampev = require("lib.samp.events")

-- ====================== Кодировка ======================
-- Чат SA-MP/Monet работает в Windows-1251, а исходник в UTF-8.
-- u2a переводит русский текст из UTF-8 в CP1251, чтобы в игре не было кракозябр.
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
            local cp = (b - 0xC0) * 64 + (b2 - 0x80) -- декод 2-байтного UTF-8
            local out
            if cp >= 0x410 and cp <= 0x44F then
                out = cp - 0x410 + 0xC0 -- А-я
            elseif cp == 0x401 then
                out = 0xA8 -- Ё
            elseif cp == 0x451 then
                out = 0xB8 -- ё
            else
                out = 0x3F -- '?'
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

-- CP1251-байт русской строчной 'к' (для компактного вывода 1кк/1ккк)
local K_CP1251 = string.char(234)

-- ====================== Парсер / вычислитель ======================

-- Рекурсивный спуск. Грамматика:
--   expr   := term  (('+' | '-') term)*
--   term   := factor (('*' | '/' | '%') factor)*
--   factor := ('+' | '-') factor | power
--   power  := primary ('^' factor)?
--   primary:= number | '(' expr ')'
--   number := digits['.'digits] ('k')*      (каждая 'k' = умножить на 1000)

local function evaluate(src)
    local expr = src
    -- кириллические к/К -> латинская k (UTF-8 байты)
    expr = expr:gsub("\208\186", "k"):gsub("\208\154", "k") -- UTF-8 к/К
    expr = expr:gsub("\234", "k"):gsub("\202", "k") -- CP1251 к/К (как приходит из чата)
    -- запятая как десятичный разделитель
    expr = expr:gsub(",", ".")
    -- убираем пробелы
    expr = expr:gsub("%s+", "")

    if expr == "" then return nil end

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

    local parseExpr -- forward

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
        -- суффиксы к/k подряд: каждая = *1000
        while peek() == "k" do
            advance()
            value = value * 1000
        end
        return value
    end

    local function parsePrimary()
        local c = peek()
        if c == "(" then
            advance()
            local v = parseExpr()
            if peek() ~= ")" then error("paren") end
            advance()
            return v
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
            return -parseFactor()
        elseif c == "+" then
            advance()
            return parseFactor()
        end
        local base = parsePrimary()
        if peek() == "^" then
            advance()
            local exp = parseFactor()
            return base ^ exp
        end
        return base
    end

    local function parseTerm()
        local v = parseFactor()
        while true do
            local c = peek()
            if c == "*" then
                advance()
                v = v * parseFactor()
            elseif c == "/" then
                advance()
                local d = parseFactor()
                if d == 0 then error("divzero") end
                v = v / d
            elseif c == "%" then
                advance()
                local d = parseFactor()
                if d == 0 then error("divzero") end
                v = v % d
            else
                break
            end
        end
        return v
    end

    parseExpr = function()
        local v = parseTerm()
        while true do
            local c = peek()
            if c == "+" then
                advance()
                v = v + parseTerm()
            elseif c == "-" then
                advance()
                v = v - parseTerm()
            else
                break
            end
        end
        return v
    end

    local ok, result = pcall(function()
        local v = parseExpr()
        if pos <= len then
            error("trailing")
        end
        return v
    end)

    if ok and type(result) == "number" and result == result then -- not NaN
        return result
    end
    return nil
end

-- ====================== Форматирование ======================

-- 1234567 -> "1 234 567"
local function formatThousands(n)
    local neg = n < 0
    n = math.abs(n)
    local intpart = math.floor(n + 1e-9)
    local frac = n - intpart
    local s = string.format("%.0f", intpart)
    -- расставляем пробелы по 3 разряда
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

-- 3000000 -> "3кк", 1250000000 -> "1.25ккк"
local function formatCompact(n)
    local neg = n < 0
    n = math.abs(n)
    if n < 1000 then
        local s = string.format("%.3f", n):gsub("0+$", ""):gsub("%.$", "")
        return (neg and "-" or "") .. s
    end
    local level = 0
    local v = n
    while v >= 1000 and level < 10 do
        v = v / 1000
        level = level + 1
    end
    local vs = string.format("%.3f", v):gsub("0+$", ""):gsub("%.$", "")
    return (neg and "-" or "") .. vs .. string.rep(K_CP1251, level)
end

-- ====================== Определение: это вычисление? ======================

local function looksLikeMath(text)
    -- нормализуем как в evaluate, чтобы проверить набор символов
    local e = text:gsub("\208\186", "k"):gsub("\208\154", "k") -- UTF-8 к/К
    e = e:gsub("\234", "k"):gsub("\202", "k") -- CP1251 к/К
    e = e:gsub(",", "."):gsub("%s+", "")
    if e == "" then
        return false
    end
    -- только разрешённые символы
    if not e:match("^[%d%.%+%-%*/%%%^%(%)k]+$") then
        return false
    end
    -- должна быть хотя бы одна цифра
    if not e:find("%d") then
        return false
    end
    -- и хотя бы оператор ИЛИ суффикс k (иначе обычное число типа "500" не трогаем)
    if e:find("[%+%-%*/%%%^]") or e:find("k") or e:find("[%(%)]") then
        return true
    end
    return false
end

-- ====================== Хук чата ======================

local COLOR = 0x00FF88

function sampev.onSendChat(text)
    if not looksLikeMath(text) then
        return -- обычное сообщение -> отправляем как есть
    end

    local result = evaluate(text)
    if result == nil then
        return -- не смогли посчитать -> не вмешиваемся
    end

    local full = formatThousands(result)
    local compact = formatCompact(result)

    local line
    if full == compact then
        line = string.format("{FFFFFF}%s {888888}= {00FF88}%s", text, full)
    else
        line = string.format("{FFFFFF}%s {888888}= {00FF88}%s {888888}(%s)", text, full, compact)
    end

    sampAddChatMessage(line, COLOR)

    -- кладём числовой результат в буфер обмена (удобно вставлять обратно)
    pcall(function()
        setClipboardText(string.format("%.0f", math.floor(result + 0.5)))
    end)

    return false -- не отправляем выражение на сервер
end

-- ====================== Точка входа ======================

function main()
    while not isSampAvailable() do
        wait(0)
    end
    wait(1500)
    sampAddChatMessage(
        u2a("{00FF88}[Калькулятор]{FFFFFF} загружен. Пиши пример прямо в чат: {00FF88}50к + 30к{FFFFFF}, поддержка 1к/1кк/1ккк."),
        COLOR
    )
    wait(-1)
end
