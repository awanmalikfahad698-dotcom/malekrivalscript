--============================================================
-- FLITCH HUB  ::  malek_a.lua  ::  core / compat / ui
--============================================================
local F = getgenv().FlitchHub
if not F then F = {}; getgenv().FlitchHub = F end
if F.Core then return F end
F.Core = true

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local GS = game:GetService("GuiService")
local VIM = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

local function pick(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if v ~= nil then return v end
	end
end

local Compat = {}
F.Compat = Compat
Compat.getconnections = pick(getconnections, syn and syn.getconnections, fluxus and fluxus.getconnections)
Compat.firesignal = pick(firesignal, syn and syn.firesignal, fluxus and fluxus.firesignal)
Compat.gethui = pick(gethui, syn and syn.gethui, fluxus and fluxus.gethui)
Compat.keypress = pick(keypress, syn and syn.keypress, fluxus and fluxus.keypress)
Compat.keyclick = pick(keyclick, syn and syn.keyclick)
Compat.mousemoverel = pick(mousemoverel, syn and syn.mousemoverel, fluxus and fluxus.mousemoverel)
Compat.mouse1click = pick(mouse1click, syn and syn.mouse1click, fluxus and fluxus.mouse1click)
Compat.queue_on_teleport = pick(queue_on_teleport, queueonteleport, syn and syn.queue_on_teleport)
Compat.setclipboard = pick(setclipboard, syn and syn.setclipboard)
Compat.readfile = pick(readfile, syn and syn.readfile, fluxus and fluxus.readfile)
Compat.writefile = pick(writefile, syn and syn.writefile, fluxus and fluxus.writefile)
Compat.isfile = pick(isfile, syn and syn.isfile, fluxus and fluxus.isfile)
Compat.delfile = pick(delfile, syn and syn.delfile, fluxus and fluxus.delfile)
Compat.makefolder = pick(makefolder, syn and syn.makefolder, fluxus and fluxus.makefolder)
Compat.executor = pick(identifyexecutor, getexecutorname)
F.Executor = (Compat.executor and select(1, pcall(Compat.executor)) and "unknown") or "unknown"
if Compat.executor then
	local ok, n = pcall(Compat.executor)
	if ok and type(n) == "string" then F.Executor = n end
end

function Compat.makeRoot()
	if Compat.gethui then
		local ok, h = pcall(Compat.gethui)
		if ok and h then return h end
	end
	return LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui")
end

function Compat.press(key)
	local kc = typeof(key) == "EnumItem" and key or Enum.KeyCode[key]
	if not kc then return false end
	if Compat.keypress then
		return (pcall(Compat.keypress, kc))
	end
	local ok = pcall(function()
		VIM:SendKeyEvent(true, kc, false, game)
		task.wait(0.03)
		VIM:SendKeyEvent(false, kc, false, game)
	end)
	return ok
end

function Compat.virtualClick(btn)
	if not Compat.mousemoverel or not Compat.mouse1click then return false end
	if not btn then return false end
	local inset = GS:GetGuiInset()
	local target = btn.AbsolutePosition + (btn.AbsoluteSize / 2) + inset
	local cur = UIS:GetMouseLocation()
	local delta = target - cur
	pcall(Compat.mousemoverel, delta.X, delta.Y)
	task.wait(0.03)
	local ok = pcall(Compat.mouse1click)
	task.wait(0.03)
	pcall(Compat.mousemoverel, -delta.X, -delta.Y)
	return ok
end

function Compat.click(btn, allowFallback)
	if not btn then return false end
	local done = false
	if Compat.getconnections then
		local ok, conns = pcall(Compat.getconnections, btn.MouseButton1Click)
		if ok and conns then
			for _, c in ipairs(conns) do
				if c.Fire then
					if pcall(c.Fire, c) then done = true end
				end
			end
		end
	end
	if not done and Compat.firesignal then
		if pcall(Compat.firesignal, btn.MouseButton1Click) then done = true end
	end
	if not done and (allowFallback or F.Config.MouseFallback) then
		done = Compat.virtualClick(btn)
	end
	return done
end

local Util = {}
F.Util = Util
function Util.tween(obj, props, time, style, dir)
	local t = TS:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end
function Util.char() return LP.Character end
function Util.hum()
	local c = LP.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
function Util.hrp()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
function Util.alive()
	local h = Util.hum()
	return h ~= nil and h.Health > 0
end

function F.new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

F.Config = {
	Enabled = true,
	Aimbot = true, AimSmooth = 0.22, AimFOV = 240, AimPart = "Head", AimAlways = false,
	AutoFire = true, FireDelay = 0.05,
	ESP = true, ESPTeam = false, ESPHealth = true, ESPName = true,
	AutoFarm = false, FarmRange = 600, MinAmmo = 3, CycleDelay = 0.12,
	AutoQueue = false, QueueDelay = 2, ModeKeyword = "1v1",
	Loadout = 0, AutoLoadout = false,
	WallWalk = false,
	Retreat = true, RetreatHealth = 25, RetreatRange = 90,
	TPChase = false, TPStep = 8, TPRate = 0.15,
	Stick = false, Fly = false,
	RoundGrace = 5, MouseFallback = false,
	Crosshair = true, Hitmarker = true,
}
local CFG = F.Config

F.Keybinds = {
	Gui = Enum.KeyCode.RightControl,
	Panic = Enum.KeyCode.Delete,
	Enabled = Enum.KeyCode.RightShift,
	Aimbot = Enum.KeyCode.Q,
	AutoFire = Enum.KeyCode.E,
	ESP = Enum.KeyCode.V,
	AutoFarm = Enum.KeyCode.Z,
	AutoQueue = Enum.KeyCode.H,
	Loadout = Enum.KeyCode.L,
	WallWalk = Enum.KeyCode.X,
	Retreat = Enum.KeyCode.T,
	TPChase = Enum.KeyCode.G,
	Stick = Enum.KeyCode.C,
	Fly = Enum.KeyCode.F,
}

F.ChipMap = {}
function F.refreshChips()
	for action, chip in pairs(F.ChipMap) do
		local key = F.Keybinds[action]
		chip.Text = key and key.Name or "NONE"
		chip.TextColor3 = key and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(120, 128, 148)
	end
end

function F.set(key, value)
	CFG[key] = value
	local row = F.Rows and F.Rows[key]
	if row then row(value) end
end
function F.flip(key)
	F.set(key, not CFG[key])
end

local awaiting = nil
UIS.InputBegan:Connect(function(input, gp)
	if awaiting then
		local action = awaiting
		awaiting = nil
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
			F.Keybinds[action] = nil
		else
			F.Keybinds[action] = input.KeyCode
		end
		F.refreshChips()
		return
	end
	if gp and not F.Focus then return end
	local kc = input.KeyCode
	if kc == F.Keybinds.Gui then F.toggleGui() return end
	if kc == F.Keybinds.Panic then F.unload() return end
	for action, key in pairs(F.Keybinds) do
		if key == kc and action ~= "Gui" and action ~= "Panic" then
			F.flip(action)
			if action == "Loadout" and F.openLoadout then F.openLoadout() end
		end
	end
end)

F.Rows = {}

function F.addToggle(tab, label, key)
	local row = F.new("Frame", {
		Size = UDim2.new(1, -12, 0, 34),
		BackgroundColor3 = Color3.fromRGB(22, 24, 32),
		BorderSizePixel = 0,
	}, tab)
	F.new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)

	F.new("TextLabel", {
		Size = UDim2.new(1, -168, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(220, 226, 240),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = label,
	}, row)

	local chip = F.new("TextButton", {
		Size = UDim2.new(0, 56, 0, 22),
		Position = UDim2.new(1, -100, 0.5, -11),
		BackgroundColor3 = Color3.fromRGB(34, 38, 52),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(120, 128, 148),
		Text = "NONE",
		AutoButtonColor = false,
	}, row)
	F.new("UICorner", { CornerRadius = UDim.new(0, 5) }, chip)
	chip.MouseButton1Click:Connect(function()
		awaiting = key
		chip.Text = "..."
	end)
	F.ChipMap[key] = chip

	local sw = F.new("Frame", {
		Size = UDim2.new(0, 34, 0, 18),
		Position = UDim2.new(1, -38, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(34, 38, 52),
		BorderSizePixel = 0,
	}, row)
	F.new("UICorner", { CornerRadius = UDim.new(0, 9) }, sw)
	local knob = F.new("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(0, 2, 0.5, -7),
		BackgroundColor3 = Color3.fromRGB(150, 156, 172),
		BorderSizePixel = 0,
	}, sw)
	F.new("UICorner", { CornerRadius = UDim.new(0, 7) }, knob)

	local btn = F.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
	}, row)

	local function paint(v)
		if v then
			Util.tween(sw, { BackgroundColor3 = Color3.fromRGB(56, 122, 220) }, 0.15)
			Util.tween(knob, { Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.fromRGB(240, 246, 255) }, 0.15)
		else
			Util.tween(sw, { BackgroundColor3 = Color3.fromRGB(34, 38, 52) }, 0.15)
			Util.tween(knob, { Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(150, 156, 172) }, 0.15)
		end
	end
	btn.MouseButton1Click:Connect(function()
		F.flip(key)
	end)
	F.Rows[key] = paint
	paint(CFG[key])
	return row
end

function F.addSlider(tab, label, key, min, max, step)
	local row = F.new("Frame", {
		Size = UDim2.new(1, -12, 0, 44),
		BackgroundColor3 = Color3.fromRGB(22, 24, 32),
		BorderSizePixel = 0,
	}, tab)
	F.new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)

	local lbl = F.new("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18),
		Position = UDim2.fromOffset(10, 4),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(200, 208, 224),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = label,
	}, row)

	local track = F.new("Frame", {
		Size = UDim2.new(1, -20, 0, 5),
		Position = UDim2.new(0, 10, 0, 29),
		BackgroundColor3 = Color3.fromRGB(34, 38, 52),
		BorderSizePixel = 0,
	}, row)
	F.new("UICorner", { CornerRadius = UDim.new(0, 3) }, track)
	local fill = F.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(90, 160, 240), BorderSizePixel = 0 }, track)
	F.new("UICorner", { CornerRadius = UDim.new(0, 3) }, fill)
	local hit = F.new("TextButton", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 20), BackgroundTransparency = 1, Text = "" }, row)

	local function apply(v)
		v = math.clamp(v, min, max)
		CFG[key] = v
		fill.Size = UDim2.fromScale((v - min) / (max - min), 1)
		lbl.Text = label .. "  ·  " .. (step >= 1 and tostring(math.floor(v)) or string.format("%.2f", v))
	end
	hit.MouseButton1Down:Connect(function()
		local dragging = true
		local function upd()
			local mx = UIS:GetMouseLocation().X
			local abs = track.AbsolutePosition.X
			local w = track.AbsoluteSize.X
			local a = math.clamp((mx - abs) / w, 0, 1)
			apply(min + a * (max - min))
		end
		upd()
		local conn
		conn = RS.RenderStepped:Connect(function()
			if not dragging then conn:Disconnect() return end
			upd()
		end)
		UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	end)
	apply(CFG[key])
end

function F.addText(tab, label, key)
	local row = F.new("Frame", { Size = UDim2.new(1, -12, 0, 34), BackgroundColor3 = Color3.fromRGB(22, 24, 32), BorderSizePixel = 0 }, tab)
	F.new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
	F.new("TextLabel", {
		Size = UDim2.new(0, 120, 1, 0), Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
		TextColor3 = Color3.fromRGB(220, 226, 240), TextXAlignment = Enum.TextXAlignment.Left, Text = label,
	}, row)
	local box = F.new("TextBox", {
		Size = UDim2.new(1, -142, 0, 22), Position = UDim2.new(1, -130, 0.5, -11),
		BackgroundColor3 = Color3.fromRGB(34, 38, 52), BorderSizePixel = 0,
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(210, 218, 235),
		Text = tostring(CFG[key]), PlaceholderText = "...", ClearTextOnFocus = false,
	}, row)
	F.new("UICorner", { CornerRadius = UDim.new(0, 5) }, box)
	box.Focused:Connect(function() F.Focus = true end)
	box.FocusLost:Connect(function()
		F.Focus = false
		CFG[key] = box.Text
	end)
end

function F.addLabel(parent, text, size, color)
	return F.new("TextLabel", {
		Size = UDim2.new(1, -12, 0, size or 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color or Color3.fromRGB(130, 138, 158),
		Text = text,
	}, parent)
end

function F.buildGui()
	if F.Gui then return end
	local sg = F.new("ScreenGui", {
		Name = "FlitchHub",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
	}, Compat.makeRoot())
	F.Gui = sg

	local win = F.new("Frame", {
		Size = UDim2.fromOffset(430, 480),
		Position = UDim2.new(0, 40, 0, 90),
		BackgroundColor3 = Color3.fromRGB(14, 16, 22),
		BorderSizePixel = 0,
	}, sg)
	F.new("UICorner", { CornerRadius = UDim.new(0, 10) }, win)
	local stroke = F.new("UIStroke", { Color = Color3.fromRGB(40, 46, 62), Thickness = 1 }, win)
	F.Win = win

	local top = F.new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Color3.fromRGB(20, 23, 31), BorderSizePixel = 0 }, win)
	F.new("UICorner", { CornerRadius = UDim.new(0, 10) }, top)
	local brand = F.new("TextLabel", {
		Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(14, 0),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 17,
		TextColor3 = Color3.fromRGB(235, 240, 255), TextXAlignment = Enum.TextXAlignment.Left, Text = "FLITCH HUB",
	}, top)
	local g = F.new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(185, 135, 255)),
		}),
	}, brand)

	local status = F.new("TextLabel", {
		Size = UDim2.new(1, -20, 0, 16), Position = UDim2.new(0, 14, 1, 2),
		BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
		TextColor3 = Color3.fromRGB(120, 130, 150), TextXAlignment = Enum.TextXAlignment.Left, Text = "idle",
	}, win)
	F.Status = status

	local close = F.new("TextButton", {
		Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -34, 0, 9),
		BackgroundColor3 = Color3.fromRGB(38, 42, 56), BorderSizePixel = 0,
		Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(200, 208, 224), Text = "x",
	}, top)
	F.new("UICorner", { CornerRadius = UDim.new(0, 6) }, close)
	close.MouseButton1Click:Connect(function() F.toggleGui(false) end)

	local dragging, dragStart, startPos
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = i.Position
			startPos = win.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - dragStart
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	local tabBar = F.new("Frame", { Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(10, 50), BackgroundTransparency = 1 }, win)
	local list = F.new("ScrollingFrame", {
		Size = UDim2.new(1, -20, 1, -140), Position = UDim2.fromOffset(10, 86),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 4, CanvasSize = UDim2.new(),
	}, win)
	F.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	F.List = list

	local tabs, pages = {}, {}
	local order = 0
	local function tab(name)
		order = order + 1
		local b = F.new("TextButton", {
			Size = UDim2.fromOffset(92, 28), Position = UDim2.fromOffset((order - 1) * 98, 0),
			BackgroundColor3 = Color3.fromRGB(24, 27, 36), BorderSizePixel = 0,
			Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(150, 158, 178), Text = name,
		}, tabBar)
		F.new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
		local page = F.new("Frame", { Size = UDim2.fromScale(1, 0), BackgroundTransparency = 1, Visible = false }, list)
		F.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
		tabs[name] = b
		pages[name] = page
		b.MouseButton1Click:Connect(function()
			for n, p in pairs(pages) do
				p.Visible = (n == name)
				Util.tween(tabs[n], { BackgroundColor3 = n == name and Color3.fromRGB(50, 60, 84) or Color3.fromRGB(24, 27, 36) }, 0.12)
				tabs[n].TextColor3 = n == name and Color3.fromRGB(230, 238, 255) or Color3.fromRGB(150, 158, 178)
			end
		end)
		return page
	end

	local aim = tab("AIM")
	F.addToggle(aim, "Aimbot", "Aimbot")
	F.addToggle(aim, "Hold to aim (else always)", "AimAlways")
	F.addSlider(aim, "Smoothness", "AimSmooth", 0.05, 1, 0.01)
	F.addSlider(aim, "FOV", "AimFOV", 40, 600, 5)
	F.addToggle(aim, "Autofire", "AutoFire")
	F.addSlider(aim, "Fire delay", "FireDelay", 0.01, 0.4, 0.01)
	F.addToggle(aim, "Crosshair", "Crosshair")
	F.addToggle(aim, "Hitmarker", "Hitmarker")

	local farm = tab("FARM")
	F.addToggle(farm, "Auto farm", "AutoFarm")
	F.addSlider(farm, "Farm range", "FarmRange", 40, 1200, 10)
	F.addSlider(farm, "Swap at ammo", "MinAmmo", 1, 12, 1)
	F.addSlider(farm, "Cycle delay", "CycleDelay", 0.05, 1, 0.01)
	F.addToggle(farm, "Teleport chase", "TPChase")
	F.addSlider(farm, "TP distance", "TPStep", 2, 20, 1)
	F.addToggle(farm, "Stick to target", "Stick")
	F.addToggle(farm, "Through walls", "WallWalk")
	F.addToggle(farm, "Retreat on low HP", "Retreat")
	F.addSlider(farm, "Retreat at HP", "RetreatHealth", 5, 100, 1)
	F.addSlider(farm, "Retreat distance", "RetreatRange", 20, 300, 5)
	F.addToggle(farm, "Fly", "Fly")
	F.addToggle(farm, "Auto pick loadout", "AutoLoadout")
	F.addSlider(farm, "Loadout slot", "Loadout", 0, 5, 1)

	local q = tab("QUEUE")
	F.addToggle(q, "Auto queue", "AutoQueue")
	F.addSlider(q, "Queue delay", "QueueDelay", 0.5, 8, 0.5)
	F.addText(q, "Mode keyword", "ModeKeyword")

	local vis = tab("VISUAL")
	F.addToggle(vis, "ESP", "ESP")
	F.addToggle(vis, "Show teammates", "ESPTeam")
	F.addToggle(vis, "Show health", "ESPHealth")
	F.addToggle(vis, "Show names", "ESPName")

	local misc = tab("MISC")
	F.addSlider(misc, "Round grace (s)", "RoundGrace", 0, 20, 1)
	F.addToggle(misc, "Mouse click fallback", "MouseFallback")
	F.addToggle(misc, "Master switch", "Enabled")
	F.addLabel(misc, "Executor: " .. tostring(F.Executor))
	F.addLabel(misc, "Clicks: " .. (Compat.getconnections and "getconnections" or Compat.firesignal and "firesignal" or "virtual") .. " · Container: " .. (Compat.gethui and "gethui" or "PlayerGui"))

	tabs.AIM.MouseButton1Click:Fire()
	tabs.AIM.BackgroundColor3 = Color3.fromRGB(50, 60, 84)
	tabs.AIM.TextColor3 = Color3.fromRGB(230, 238, 255)
	pages.AIM.Visible = true

	task.spawn(function()
		while F.Gui do
			task.wait(0.25)
			local total = 0
			for _, p in pairs(pages) do
				if p.Visible then
					total = total + (p.AbsoluteSize.Y + 6)
				end
			end
			list.CanvasSize = UDim2.fromOffset(0, total + 8)
		end
	end)

	F.crosshair = F.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.fromRGB(120, 220, 160),
		BorderSizePixel = 0, Visible = CFG.Crosshair,
	}, sg)
	F.new("UICorner", { CornerRadius = UDim.new(1, 0) }, F.crosshair)
	F.new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Transparency = 0.5 }, F.crosshair)
end

function F.toggleGui(force)
	if not F.Gui then F.buildGui() end
	local open = force
	if open == nil then open = not F.Gui.Enabled end
	F.Gui.Enabled = open
end

function F.updateStatus()
	if not F.Status then return end
	local r = F.Round
	local txt = "idle"
	if r then
		if r.Open then
			txt = "round live"
		elseif r.Left > 0 then
			txt = string.format("grace %.1fs", r.Left)
		end
	end
	if CFG.AutoFarm then txt = txt .. "  ·  farm" end
	if F.Weapon and F.Weapon.Slot then txt = txt .. "  ·  slot " .. F.Weapon.Slot end
	F.Status.Text = txt
end

function F.unload()
	if F.Booted then
		local q = Compat.queue_on_teleport
		if q then
			pcall(q, "")
		end
	end
	F.Booted = false
	if F.Gui then F.Gui:Destroy() F.Gui = nil end
	F.Core = nil
	F.Game = nil
	F.Parts = nil
	getgenv().FlitchHub = nil
end

return F