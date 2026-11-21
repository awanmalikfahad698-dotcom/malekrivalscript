--============================================================
-- FLITCH HUB  ::  malekrival.lua  ::  loader
--============================================================
if getgenv().FlitchHub and getgenv().FlitchHub.Loading then
	return warn("[Flitch Hub] already loading")
end
getgenv().FlitchHub = getgenv().FlitchHub or {}
getgenv().FlitchHub.Loading = true

local BASE = "https://raw.githubusercontent.com/awanmalikfahad698-dotcom/malekrivalscript/main/"
local PARTS = { "malek_a.lua", "malek_b.lua", "malek_c.lua" }

local function pick(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if v ~= nil then return v end
	end
end

local httpget = pick(httpget, syn and syn.httpget)
local request = pick(request, syn and syn.request, http and http.request)

local function fetch(url)
	if httpget then
		local ok, body = pcall(httpget, url)
		if ok and type(body) == "string" and #body > 0 then return body end
	end
	if request then
		local ok, res = pcall(request, { Url = url, Method = "GET" })
		if ok and type(res) == "table" and res.Body and #res.Body > 0 then return res.Body end
	end
	return nil
end

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local LP = Players.LocalPlayer

local function splash()
	local root = (gethui and gethui()) or LP:WaitForChild("PlayerGui")
	local sg = Instance.new("ScreenGui")
	sg.Name = "FlitchSplash"
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 99999
	sg.ResetOnSpawn = false
	sg.Parent = root

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(7, 8, 12)
	bg.BorderSizePixel = 0
	bg.BackgroundTransparency = 1
	bg.Parent = sg

	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromOffset(320, 96)
	box.BackgroundTransparency = 1
	box.Parent = bg

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 44)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = "FLITCH HUB"
	title.TextSize = 38
	title.TextColor3 = Color3.fromRGB(240, 244, 255)
	title.TextTransparency = 1
	title.Parent = box

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 130, 255)),
	})
	grad.Parent = title

	local sub = Instance.new("TextLabel")
	sub.Position = UDim2.new(0, 0, 0, 48)
	sub.Size = UDim2.new(1, 0, 0, 18)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.Text = "rivals  ::  loading modules"
	sub.TextSize = 12
	sub.TextColor3 = Color3.fromRGB(140, 150, 175)
	sub.TextTransparency = 1
	sub.Parent = box

	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.new(0, 0, 0, 78)
	barBg.Size = UDim2.new(1, 0, 0, 3)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 33, 44)
	barBg.BorderSizePixel = 0
	barBg.Parent = box

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
	bar.BorderSizePixel = 0
	bar.Parent = barBg

	TS:Create(bg, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
	TS:Create(title, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	TS:Create(sub, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	TS:Create(bar, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 1, 0) }):Play()
	task.wait(1.25)
	TS:Create(bg, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	TS:Create(title, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
	TS:Create(sub, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
	task.wait(0.32)
	sg:Destroy()
end

task.spawn(splash)

for _, name in ipairs(PARTS) do
	local src = fetch(BASE .. name)
	if not src then
		getgenv().FlitchHub.Loading = nil
		return error("[Flitch Hub] could not fetch " .. name)
	end
	local fn, err = loadstring(src, name)
	if not fn then
		getgenv().FlitchHub.Loading = nil
		return error("[Flitch Hub] syntax error in " .. name .. ": " .. tostring(err))
	end
	local ok, res = pcall(fn)
	if not ok then
		getgenv().FlitchHub.Loading = nil
		return error("[Flitch Hub] runtime error in " .. name .. ": " .. tostring(res))
	end
end

local F = getgenv().FlitchHub
F.Loading = nil
F.Booted = true
if F.Main then F.Main() end