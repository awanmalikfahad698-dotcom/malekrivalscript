--============================================================
-- FLITCH HUB  ::  malek_c.lua  ::  weapons / loadout / queue / round
--============================================================
local F = getgenv().FlitchHub
if not F then return end
if F.Parts then return F end
F.Parts = true

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Compat = F.Compat
local Util = F.Util
local CFG = F.Config

--====================== round gate ======================
local Round = { Open = false, Left = 0 }
F.Round = Round
local token = 0

function Round.arm(seconds)
	token = token + 1
	local my = token
	Round.Open = false
	Round.Left = seconds
	task.spawn(function()
		while Round.Left > 0 and my == token do
			task.wait(0.1)
			Round.Left = math.max(0, Round.Left - 0.1)
			F.updateStatus()
		end
		if my == token then
			Round.Open = true
			F.updateStatus()
		end
	end)
end
function Round.close()
	token = token + 1
	Round.Open = false
	Round.Left = 0
	F.updateStatus()
end

LP.CharacterAdded:Connect(function()
	Round.close()
	task.wait(1)
	Round.arm(CFG.RoundGrace)
end)
if LP.Character then Round.arm(CFG.RoundGrace) end

--====================== weapons ======================
local Weapon = { Slot = 1, Dry = {} }
F.Weapon = Weapon

function Weapon.ammo(tool)
	if not tool then return nil end
	for _, n in ipairs({ "Ammo", "CurrentAmmo", "Mag", "Clip", "AmmoCount", "Bullets" }) do
		local v = tool:FindFirstChild(n, true)
		if v and v:IsA("ValueBase") and type(v.Value) == "number" then return v.Value end
	end
	for _, a in ipairs({ "Ammo", "CurrentAmmo", "Mag", "Clip" }) do
		local ok, v = pcall(function() return tool:GetAttribute(a) end)
		if ok and type(v) == "number" then return v end
	end
	return nil
end

function Weapon.equip(slot)
	Weapon.Slot = slot
	Compat.press(tostring(slot))
end

function Weapon.cycle()
	for i = 1, 3 do
		local nxt = ((Weapon.Slot + i - 1) % 3) + 1
		if not Weapon.Dry[nxt] then
			Weapon.equip(nxt)
			return true
		end
	end
	Weapon.Dry = {}
	Compat.press("R")
	return false
end

task.spawn(function()
	while true do
		task.wait(CFG.CycleDelay)
		if CFG.Enabled and CFG.AutoFarm and Round.Open and Util.alive() then
			local ch = LP.Character
			local tool = ch and ch:FindFirstChildOfClass("Tool")
			if tool then
				local ammo = Weapon.ammo(tool)
				if ammo and ammo <= CFG.MinAmmo then
					Weapon.Dry[Weapon.Slot] = true
					Weapon.cycle()
				end
			else
				Weapon.equip(Weapon.Slot)
			end
		end
	end
end)

LP.CharacterAdded:Connect(function()
	Weapon.Slot = 1
	Weapon.Dry = {}
end)

--====================== gui scanning ======================
function F.isMine(obj)
	if not F.Gui then return false end
	local p = obj
	while p do
		if p == F.Gui then return true end
		p = p.Parent
	end
	return false
end

function F.buttons()
	local out = {}
	local ok, list = pcall(function() return Compat.makeRoot():GetDescendants() end)
	if not ok then return out end
	for _, g in ipairs(list) do
		if g:IsA("TextButton") and g.Visible and not F.isMine(g) then
			local sz = g.AbsoluteSize
			if sz.X > 4 and sz.Y > 4 then
				out[#out + 1] = g
			end
		end
	end
	return out
end

local function textOf(btn)
	return string.lower(btn.Text or btn.Name or "")
end

local function findKeyword(kws)
	for _, b in ipairs(F.buttons()) do
		local t = textOf(b)
		for _, k in ipairs(kws) do
			if t:find(k, 1, true) then return b end
		end
	end
	return nil
end

--====================== loadout ======================
function F.openLoadout()
	local opener = findKeyword({ "loadout", "loadouts", "classes", "class", "weapons", "kit" })
	if opener then
		Compat.click(opener, true)
		task.wait(0.4)
	end
	local slot = tonumber(CFG.Loadout) or 0
	if slot <= 0 then return end
	local pick
	for _, b in ipairs(F.buttons()) do
		local t = textOf(b)
		if t == tostring(slot) or t == "slot " .. slot or t:find("^" .. slot .. "[^%d]") then
			pick = b
			break
		end
	end
	if not pick then
		local list = F.buttons()
		local ordered = {}
		for _, b in ipairs(list) do
			local t = textOf(b)
			if t:match("^%d$") then ordered[#ordered + 1] = b end
		end
		pick = ordered[slot]
	end
	if pick then Compat.click(pick, true) end
end

--====================== queue ======================
function F.queueMatch()
	local modeKw = string.lower(CFG.ModeKeyword or "")
	if modeKw ~= "" then
		local mode = findKeyword({ modeKw })
		if mode then
			Compat.click(mode, true)
			task.wait(0.45)
		end
	end
	local play = findKeyword({ "play", "queue", "matchmake", "find match", "start", "ready", "join" })
	if play then
		Compat.click(play, true)
		return true
	end
	return false
end

task.spawn(function()
	while true do
		task.wait(1)
		if not CFG.Enabled or not CFG.AutoQueue then continue end
		if Round.Open then continue end
		if F.queueMatch() then
			task.wait(CFG.QueueDelay)
		end
	end
end)

--====================== config ======================
local FILE = "FlitchHub_Rivals.json"

local function serialize(tbl)
	local out = { "{" }
	for k, v in pairs(tbl) do
		local tk = type(v)
		if tk == "number" or tk == "boolean" or tk == "string" then
			out[#out + 1] = string.format("%q:", k) .. (tk == "string" and string.format("%q", v) or tostring(v)) .. ","
		end
	end
	out[#out + 1] = "}"
	return table.concat(out)
end

function F.saveConfig()
	if not (Compat.writefile and Compat.isfile) then return end
	pcall(function()
		if Compat.makefolder then Compat.makefolder("FlitchHub") end
		Compat.writefile(FILE, serialize(CFG))
	end)
end

function F.loadConfig()
	if not (Compat.readfile and Compat.isfile) then return end
	local ok, raw = pcall(function()
		if Compat.isfile(FILE) then return Compat.readfile(FILE) end
	end)
	if not ok or not raw then return end
	for k, v in string.gmatch(raw, "\"([^\"]+)\":([^,}]+)") do
		local cur = CFG[k]
		if type(cur) == "number" then
			local n = tonumber(v)
			if n then CFG[k] = n end
		elseif type(cur) == "boolean" then
			CFG[k] = (v == "true")
		elseif type(cur) == "string" then
			CFG[k] = v:gsub("^\"", ""):gsub("\"$", "")
		end
	end
end

--====================== queue on teleport ======================
task.spawn(function()
	while true do
		task.wait(15)
		local q = Compat.queue_on_teleport
		if q and F.Booted and Compat.httpget then
			pcall(q, string.format('loadstring(game:HttpGet("%smalekrival.lua"))()', "https://raw.githubusercontent.com/awanmalikfahad698-dotcom/malekrivalscript/main/"))
		end
	end
end)

--====================== main ======================
function F.Main()
	F.buildGui()
	F.loadConfig()
	for k, v in pairs(CFG) do
		local row = F.Rows[k]
		if row then row(v) end
	end
	F.refreshChips()
	F.updateStatus()

	if CFG.AutoLoadout and tonumber(CFG.Loadout) > 0 then
		task.delay(2, F.openLoadout)
	end

	task.spawn(function()
		while F.Booted do
			task.wait(1)
			if CFG.Enabled and CFG.AutoFarm and Round.Open and Util.alive() then
				local plr = F.getTarget()
				local hrp = Util.hrp()
				local dest = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if dest and hrp and (dest.Position - hrp.Position).Magnitude > CFG.FarmRange * 0.8 then
					hrp.CFrame = dest.CFrame * CFrame.new(0, 0, CFG.TPStep)
				end
			end
		end
	end)

	task.spawn(function()
		while F.Booted do
			task.wait(5)
			F.saveConfig()
		end
	end)
end

return F