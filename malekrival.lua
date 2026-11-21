local REPO = "awanmalikfahad698-dotcom/malekrivalscript"
local BASE = "https://raw.githubusercontent.com/" .. REPO .. "/main/"
local PARTS = { "malek_a.lua", "malek_a2.lua", "malek_b.lua", "malek_c.lua", "malek_d.lua" }
local V = tostring(math.floor(tick()))

-- strip top-level locals so all parts share one global scope;
-- a single chunk only has 200 registers and the parts blow past that
local function flatten(src)
    src = src:gsub("\r", "")
    local out = {}
    for line in (src .. "\n"):gmatch("(.-)\n") do
        local names = line:match("^local%s+([%a_][%w_,%s]*)$")
        if names then
            local list = {}
            for n in names:gmatch("[%a_][%w_]*") do list[#list + 1] = n end
            out[#out + 1] = table.concat(list, ", ") .. " = nil"
        elseif line:sub(1, 6) == "local " then
            out[#out + 1] = line:sub(7)
        else
            out[#out + 1] = line
        end
    end
    return table.concat(out, "\n")
end

for _, name in ipairs(PARTS) do
    local ok, src = pcall(function() return game:HttpGet(BASE .. name .. "?v=" .. V) end)
    if not ok or type(src) ~= "string" or #src < 200 then
        return print("[flitch] failed to fetch " .. name .. " (" .. #tostring(src) .. " bytes)")
    end

    local fn, err = loadstring(flatten(src), "=" .. name)
    if not fn then return print("[flitch] compile error: " .. tostring(err)) end

    local ran, rerr = pcall(fn)
    if not ran then print("[flitch] runtime error: " .. tostring(rerr)) end
end
