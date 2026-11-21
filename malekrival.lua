local REPO = "awanmalikfahad698-dotcom/malekrivalscript"
local BASE = "https://raw.githubusercontent.com/" .. REPO .. "/main/"
local PARTS = { "malek_a.lua", "malek_b.lua", "malek_c.lua" }
local V = tostring(math.floor(tick()))

local buf = {}
for _, name in ipairs(PARTS) do
    local ok, src = pcall(function() return game:HttpGet(BASE .. name .. "?v=" .. V) end)
    if not ok or type(src) ~= "string" or #src < 200 then
        return print("[flitch] failed to fetch " .. name)
    end
    buf[#buf + 1] = src
end

local fn, err = loadstring(table.concat(buf, "\n"))
if not fn then return print("[flitch] compile error: " .. tostring(err)) end
fn()