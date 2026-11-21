--============================================================
-- FLITCH HUB  ::  malek_b.lua  ::  combat / movement
--============================================================
local F = getgenv().FlitchHub
if not F then return end
if F.Game then return F end
F.Game = true

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Compat = F.Compat
local Util = F.Util
local CFG = F.Config

local function teamOf(plr)
	if plr.Team then return "t:" .. plr.Team.Name end
	local a = plr:GetAttribute("Team") or plr:GetAttribute("team") or plr:GetAttribute("TeamName")
	if a ~= nil then return "a:" .. tostring(a) end
	local ch = plr.Character
	local shirt = ch and ch:FindFirstChildOfClass("Shirt")
	if shirt and shirt.ShirtTemplate ~= "" then return "s:" .. shirt.ShirtTemplate end
	return nil
end

local ffaCache, ffaAt = false, 0
function F.isFFA()
	if tick() - ffaAt < 2 then return ffaCache end
	ffaAt = tick()
	local mine = teamOf(LP)
	if not mine then ffaCache = true return true end
	local same = 0
	local total = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and p.Character then
			total = total + 1
			if teamOf(p) == mine then same = same + 1 end
		end
	end
	ffaCache = total > 0 and same >= total
	return ffaCache
end

function F.isEnemy(plr)
	if plr == LP then return false end
	local ch = plr.Character
	if not ch then return false end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	if F.isFFA() then return true end
	local a, b = teamOf(plr), teamOf(LP)
	if not a or not b then return true end
	return a ~= b
end

function F.visible(ch)
	local cam = workspace.CurrentCamera
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { LP.Character, cam }
	local hit = workspace:Raycast(cam.CFrame.Position, hrp.Position - cam.CFrame.Position, params)
	return hit == nil or hit.Instance:IsDescendantOf(ch)
end

function F.getTarget(maxDist)
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local myHrp = Util.hrp()
	local center = cam.ViewportSize / 2
	local best, bestScore = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if F.isEnemy(plr) then
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = myHrp and (hrp.Position - myHrp.Position).Magnitude or 0
				if dist <= (maxDist or CFG.FarmRange) then
					local sp, on = cam:WorldToViewportPoint(hrp.Position)
					if on then
						local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
						if d <= CFG.AimFOV and d < bestScore and F.visible(plr.Character) then
							best, bestScore = plr, d
						end
					end
				end
			end
		end
	end
	return best
end

local aimTarget = nil
RS.RenderStepped:Connect(function()
	if not CFG.Enabled or not CFG.Aimbot then aimTarget = nil return end
	if not F.Round or not F.Round.Open then aimTarget = nil return end
	if not Util.alive() then aimTarget = nil return end
	local holding = CFG.AimAlways or UIS:IsKeyDown(F.Keybinds.Aimbot)
	if not holding then aimTarget = nil return end

	local plr = F.getTarget()
	if not plr then aimTarget = nil return end
	local ch = plr.Character
	local part = ch:FindFirstChild(CFG.AimPart) or ch:FindFirstChild("HumanoidRootPart")
	if not part then return end
	aimTarget = plr

	local cam = workspace.CurrentCamera
	local sp, on = cam:WorldToViewportPoint(part.Position)
	if not on then return end
	local center = cam.ViewportSize / 2
	local delta = Vector2.new(sp.X, sp.Y) - center
	if Compat.mousemoverel then
		local s = math.clamp(CFG.AimSmooth, 0.05, 1)
		pcall(Compat.mousemoverel, delta.X * s, delta.Y * s)
	end
end)
F.aimTarget = function() return aimTarget end

task.spawn(function()
	while true do
		task.wait(CFG.FireDelay)
		if CFG.Enabled and CFG.AutoFire and F.Round and F.Round.Open and Util.alive() then
			local live = F.getTarget()
			if live and (CFG.AutoFarm or CFG.AimAlways or UIS:IsKeyDown(F.Keybinds.Aimbot)) then
				if Compat.mouse1click then pcall(Compat.mouse1click) end
			end
		end
	end
end)

-- hitmarker
local function flash()
	local ch = F.crosshair
	if not ch then return end
	ch.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
	task.delay(0.09, function()
		if ch then ch.BackgroundColor3 = Color3.fromRGB(120, 220, 160) end
	end)
end
F.hitmarkers = {}

local function hookHum(plr)
	local ch = plr.Character
	if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum.HealthChanged:Connect(function(new, old)
		if not CFG.Hitmarker then return end
		if new < old and F.isEnemy(plr) then flash() end
	end)
end
for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LP then
		p.CharacterAdded:Connect(function() task.wait(0.5) hookHum(p) end)
		if p.Character then hookHum(p) end
	end
end
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function() task.wait(0.5) hookHum(p) end)
end)

-- crosshair visibility
task.spawn(function()
	while true do
		task.wait(0.2)
		if F.crosshair then F.crosshair.Visible = CFG.Crosshair end
	end
end)

-- ESP
local esp = {}
local function clearESP()
	for plr, d in pairs(esp) do
		if d.hl then d.hl:Destroy() end
		if d.bg then d.bg:Destroy() end
		esp[plr] = nil
	end
end

task.spawn(function()
	while true do
		task.wait(0.3)
		if not CFG.Enabled or not CFG.ESP then
			if next(esp) then clearESP() end
		else
			local seen = {}
			for _, plr in ipairs(Players:GetPlayers()) do
				local ch = plr.Character
				local show = ch and (F.isEnemy(plr) or (CFG.ESPTeam and plr ~= LP))
				if show then
					seen[plr] = true
					local d = esp[plr]
					if not d then
						local hl = Instance.new("Highlight")
						hl.FillColor = Color3.fromRGB(230, 70, 70)
						hl.OutlineColor = Color3.fromRGB(255, 150, 150)
						hl.FillTransparency = 0.72
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Adornee = ch
						hl.Parent = ch

						local bg = Instance.new("BillboardGui")
						bg.Size = UDim2.fromOffset(140, 34)
						bg.StudsOffset = Vector3.new(0, 3.2, 0)
						bg.AlwaysOnTop = true
						bg.Parent = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart") or ch

						local name = Instance.new("TextLabel")
						name.Size = UDim2.new(1, 0, 0, 14)
						name.BackgroundTransparency = 1
						name.Font = Enum.Font.GothamBold
						name.TextSize = 11
						name.TextColor3 = Color3.fromRGB(255, 235, 235)
						name.TextStrokeTransparency = 0.4
						name.Text = plr.Name
						name.Visible = CFG.ESPName
						name.Parent = bg

						local bar = Instance.new("Frame")
						bar.Position = UDim2.new(0, 20, 0, 18)
						bar.Size = UDim2.new(1, -40, 0, 4)
						bar.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
						bar.BorderSizePixel = 0
						bar.Visible = CFG.ESPHealth
						bar.Parent = bg

						local fill = Instance.new("Frame")
						fill.Size = UDim2.fromScale(1, 1)
						fill.BackgroundColor3 = Color3.fromRGB(90, 220, 120)
						fill.BorderSizePixel = 0
						fill.Parent = bar

						esp[plr] = { hl = hl, bg = bg, fill = fill, name = name, bar = bar }
					else
						local hum = ch:FindFirstChildOfClass("Humanoid")
						if hum and d.fill then
							local r = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
							d.fill.Size = UDim2.fromScale(r, 1)
							d.fill.BackgroundColor3 = Color3.fromRGB(220, 60, 60):Lerp(Color3.fromRGB(90, 220, 120), r)
						end
						if d.name then d.name.Visible = CFG.ESPName end
						if d.bar then d.bar.Visible = CFG.ESPHealth end
						if d.hl then d.hl.Adornee = ch end
					end
				end
			end
			for plr, d in pairs(esp) do
				if not seen[plr] then
					if d.hl then d.hl:Destroy() end
					if d.bg then d.bg:Destroy() end
					esp[plr] = nil
				end
			end
		end
	end
end)

-- wall walk / noclip
RS.Stepped:Connect(function()
	if not CFG.Enabled or not CFG.WallWalk then return end
	local ch = LP.Character
	if not ch then return end
	for _, p in ipairs(ch:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
	end
end)

-- teleport chase
task.spawn(function()
	while true do
		task.wait(CFG.TPRate)
		if CFG.Enabled and (CFG.TPChase or CFG.Stick) and F.Round and F.Round.Open and Util.alive() then
			local plr = F.getTarget()
			local hrp = Util.hrp()
			local dest = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if dest and hrp then
				local behind = dest.CFrame * CFrame.new(0, 0, CFG.TPStep)
				if CFG.Stick then
					hrp.CFrame = behind
				else
					local flat = Vector3.new(dest.Position.X, hrp.Position.Y, dest.Position.Z)
					if (hrp.Position - flat).Magnitude > CFG.TPStep then
						hrp.CFrame = behind
					end
				end
			end
		end
	end
end)

-- retreat on low health
task.spawn(function()
	while true do
		task.wait(0.15)
		if CFG.Enabled and CFG.Retreat and Util.alive() then
			local hum = Util.hum()
			local hrp = Util.hrp()
			if hum and hrp and hum.Health <= CFG.RetreatHealth then
				local nearest, dist = nil, math.huge
				for _, plr in ipairs(Players:GetPlayers()) do
					if F.isEnemy(plr) then
						local e = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
						if e then
							local d = (e.Position - hrp.Position).Magnitude
							if d < dist then nearest, dist = e, d end
						end
					end
				end
				if nearest then
					local away = (hrp.Position - nearest.Position)
					if away.Magnitude < 0.1 then away = Vector3.new(0, 0, 1) end
					local spot = hrp.Position + away.Unit * CFG.RetreatRange
					hrp.CFrame = CFrame.new(spot + Vector3.new(0, 3, 0))
					task.wait(0.35)
				end
			end
		end
	end
end)

-- fly
local bv, bg2
local function stopFly()
	if bv then bv:Destroy() bv = nil end
	if bg2 then bg2:Destroy() bg2 = nil end
end
task.spawn(function()
	while true do
		task.wait(0.2)
		local hrp = Util.hrp()
		if CFG.Enabled and CFG.Fly and hrp then
			if not bv then
				bv = Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				bv.Parent = hrp
				bg2 = Instance.new("BodyGyro")
				bg2.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
				bg2.P = 3000
				bg2.Parent = hrp
			end
			local cam = workspace.CurrentCamera
			local dir = Vector3.zero
			local mv = UIS:GetFocusedTextBox()
			if mv == nil then
				if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
			end
			bv.Velocity = dir * 60
			bg2.CFrame = cam.CFrame
		elseif bv and not CFG.Fly then
			stopFly()
		end
	end
end)

return F