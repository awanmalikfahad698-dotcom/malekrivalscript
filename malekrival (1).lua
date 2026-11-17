--[[
    ███╗   ███╗ █████╗ ██╗     ███████╗██╗  ██╗
    ████╗ ████║██╔══██╗██║     ██╔════╝██║ ██╔╝
    ██╔████╔██║███████║██║     █████╗  █████╔╝
    ██║╚██╔╝██║██╔══██║██║     ██╔══╝  ██╔═██╗
    ██║ ╚═╝ ██║██║  ██║███████╗███████╗██║  ██╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝

    MALEK SCRIPT  •  RIVALS  •  XENO
    Menu key: RIGHT CTRL
    Settings auto-save and auto-reload.
--]]

getgenv().MalekSource = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/awanmalikfahad698-dotcom/malekrivalscript/main/malekrival.lua"))()'

--// Services
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local HttpService         = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui             = game:GetService("CoreGui")
local Workspace           = game:GetService("Workspace")

local LP = Players.LocalPlayer

--// Re-exec guard
if getgenv().Malek and getgenv().Malek.Unload then
    pcall(getgenv().Malek.Unload)
end

local destroyed = false
local connections = {}
local function bind(conn)
    table.insert(connections, conn)
    return conn
end

--// Config
local FILE = "MalekScript_Rivals.json"

local Config = {
    MenuKey      = Enum.KeyCode.RightControl,
    AimKey       = Enum.KeyCode.Q,
    AimMode      = "Hold",            -- Hold / Toggle / Always
    AimEnabled   = false,
    FOVRadius    = 170,
    Smoothness   = 11,
    Strength     = 1,
    Prediction   = 0.12,
    MaxDistance  = 400,
    HitPart      = "Head",
    TeamCheck    = true,
    MatchOnly    = true,
    VisibleCheck = true,
    AutoShoot    = false,
    AutoShootKey = Enum.KeyCode.E,
    ShootDelay   = 0.06,
    AutoFarm     = false,
    FarmRespawn  = true,
    FOVCircle    = true,
    Watermark    = true,
}

local function loadConfig()
    if not (isfile and isfile(FILE)) then return end
    local ok, raw = pcall(readfile, FILE)
    if not ok or type(raw) ~= "string" then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return end
    for k, v in pairs(data) do
        local default = Config[k]
        if default ~= nil then
            if typeof(default) == "EnumItem" and type(v) == "string" then
                Config[k] = Enum.KeyCode[v] or default
            elseif type(v) == type(default) then
                Config[k] = v
            end
        end
    end
end

local saveQueued = false
local function save()
    if saveQueued then return end
    saveQueued = true
    task.delay(1, function()
        saveQueued = false
        local out = {}
        for k, v in pairs(Config) do
            out[k] = typeof(v) == "EnumItem" and v.Name or v
        end
        pcall(function() writefile(FILE, HttpService:JSONEncode(out)) end)
    end)
end

loadConfig()

--// Colors
local C_BG      = Color3.fromRGB(10, 10, 16)
local C_PANEL   = Color3.fromRGB(17, 17, 27)
local C_LINE    = Color3.fromRGB(40, 40, 58)
local C_TEXT    = Color3.fromRGB(234, 234, 244)
local C_SUB     = Color3.fromRGB(138, 138, 164)
local C_ACCENT  = Color3.fromRGB(124, 92, 255)
local C_ACCENT2 = Color3.fromRGB(0, 229, 255)
local C_OFF     = Color3.fromRGB(42, 42, 58)

local function create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function getGuiParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and typeof(hui) == "Instance" then return hui end
    return CoreGui
end

--// GUI root
local gui = create("ScreenGui", {
    Name = "MalekScript",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, getGuiParent())

--// FOV circle
local fovCircle = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(Config.FOVRadius * 2, Config.FOVRadius * 2),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = Config.FOVCircle,
    ZIndex = 1,
}, gui)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, fovCircle)
local fovStroke = create("UIStroke", { Thickness = 1, Color = C_ACCENT, Transparency = 0.45 }, fovCircle)
create("UIGradient", { Color = ColorSequence.new(C_ACCENT, C_ACCENT2) }, fovStroke)

--// Watermark
local watermark = create("TextLabel", {
    Position = UDim2.new(0, 14, 0, 12),
    Size = UDim2.fromOffset(200, 22),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C_TEXT,
    Text = "malek script  •  rivals",
    Visible = Config.Watermark,
    ZIndex = 2,
}, gui)
create("UIStroke", { Color = C_ACCENT, Thickness = 1, Transparency = 0.6 }, watermark)

--// Main window
local main = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    Size = UDim2.fromOffset(336, 452),
    BackgroundColor3 = C_BG,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 5,
}, gui)
create("UICorner", { CornerRadius = UDim.new(0, 10) }, main)
local mainStroke = create("UIStroke", { Thickness = 1, Color = C_LINE }, main)
create("UIGradient", { Color = ColorSequence.new(C_ACCENT, C_ACCENT2) }, mainStroke)

--// Minimized icon
local miniIcon = create("TextButton", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    Size = UDim2.fromOffset(46, 46),
    BackgroundColor3 = C_BG,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    TextColor3 = C_ACCENT,
    Text = "M",
    Visible = false,
    ZIndex = 9,
}, gui)
create("UICorner", { CornerRadius = UDim.new(0, 12) }, miniIcon)
local miniStroke = create("UIStroke", { Thickness = 1.5, Color = C_ACCENT }, miniIcon)
create("UIGradient", { Color = ColorSequence.new(C_ACCENT, C_ACCENT2) }, miniStroke)

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = C_PANEL,
    BorderSizePixel = 0,
    ZIndex = 6,
}, main)
create("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(30, 22, 56), Color3.fromRGB(12, 12, 20)),
    Rotation = 20,
}, header)

local title = create("TextLabel", {
    Position = UDim2.fromOffset(12, 7),
    Size = UDim2.fromOffset(200, 20),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C_TEXT,
    Text = "MALEK SCRIPT",
    ZIndex = 7,
}, header)
create("UIStroke", { Color = C_ACCENT, Thickness = 1, Transparency = 0.35 }, title)

create("TextLabel", {
    Position = UDim2.fromOffset(13, 25),
    Size = UDim2.fromOffset(200, 14),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C_SUB,
    Text = "RIVALS  •  XENO  •  RIGHT CTRL",
    ZIndex = 7,
}, header)

local function headerButton(text, xOffset, color)
    local b = create("TextButton", {
        Position = UDim2.new(1, xOffset, 0, 10),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = Color3.fromRGB(28, 28, 42),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = color or C_TEXT,
        Text = text,
        ZIndex = 8,
    }, header)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    return b
end

local minimizeBtn = headerButton("–", -66)
local closeBtn    = headerButton("✕", -34, Color3.fromRGB(255, 110, 130))

--// Tabs
local tabBar = create("Frame", {
    Position = UDim2.fromOffset(10, 54),
    Size = UDim2.new(1, -20, 0, 26),
    BackgroundTransparency = 1,
    ZIndex = 6,
}, main)

local contentHolder = create("Frame", {
    Position = UDim2.fromOffset(0, 88),
    Size = UDim2.new(1, 0, 1, -96),
    BackgroundTransparency = 1,
    ZIndex = 6,
}, main)

local pages = {}
local tabButtons = {}

local function buildPage(name, index)
    local page = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C_ACCENT,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = index == 1,
    }, contentHolder)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 4),
    }, page)
    create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    pages[name] = page

    local tb = create("TextButton", {
        Position = UDim2.new((index - 1) / 3, 0, 0, 0),
        Size = UDim2.new(1 / 3, -4, 1, 0),
        BackgroundColor3 = Color3.fromRGB(22, 22, 34),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C_SUB,
        Text = name,
        ZIndex = 7,
    }, tabBar)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, tb)
    tabButtons[name] = tb

    tb.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do
            p.Visible = (n == name)
            tabButtons[n].TextColor3 = (n == name) and C_TEXT or C_SUB
            tabButtons[n].BackgroundColor3 = (n == name) and Color3.fromRGB(38, 30, 66) or Color3.fromRGB(22, 22, 34)
        end
    end)
end

buildPage("AIM", 1)
buildPage("FARM", 2)
buildPage("MISC", 3)
tabButtons["AIM"].TextColor3 = C_TEXT
tabButtons["AIM"].BackgroundColor3 = Color3.fromRGB(38, 30, 66)

--// Control builders
local function section(parent, text)
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_ACCENT2,
        Text = string.upper(text),
    }, parent)
end

local function addToggle(parent, text, key, onChange)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
    create("TextLabel", {
        Size = UDim2.new(1, -46, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_TEXT,
        Text = text,
    }, row)

    local sw = create("Frame", {
        Position = UDim2.new(1, -36, 0.5, -9),
        Size = UDim2.fromOffset(36, 18),
        BackgroundColor3 = C_OFF,
        BorderSizePixel = 0,
    }, row)
    create("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)

    local knob = create("Frame", {
        Position = UDim2.new(0, 2, 0.5, -7),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.fromRGB(210, 210, 226),
        BorderSizePixel = 0,
    }, sw)
    create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local btn = create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, sw)

    local function refresh()
        local on = Config[key]
        TweenService:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = on and C_ACCENT or C_OFF }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
        }):Play()
    end

    btn.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        refresh()
        if onChange then onChange(Config[key]) end
        save()
    end)
    refresh()
    return { Refresh = refresh }
end

local function addSlider(parent, text, key, min, max, step, onChange)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, parent)
    local label = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_TEXT,
        Text = text .. "  [" .. tostring(Config[key]) .. "]",
    }, row)

    local bar = create("Frame", {
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 5),
        BackgroundColor3 = Color3.fromRGB(32, 32, 46),
        BorderSizePixel = 0,
    }, row)
    create("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)

    local fill = create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C_ACCENT, BorderSizePixel = 0 }, bar)
    create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
    create("UIGradient", { Color = ColorSequence.new(C_ACCENT, C_ACCENT2) }, fill)

    local hit = create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, bar)

    local function paint(rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        local val = min + (max - min) * rel
        val = math.floor(val / step + 0.5) * step
        Config[key] = val
        label.Text = text .. "  [" .. string.format("%.2f", val) .. "]"
        if onChange then onChange(val) end
        save()
    end

    local function fromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        paint(rel)
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            fromX(input.Position.X)
            local move
            move = UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    fromX(i.Position.X)
                end
            end)
            local release
            release = UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    move:Disconnect()
                    release:Disconnect()
                end
            end)
        end
    end)

    paint((Config[key] - min) / (max - min))
    return { Refresh = function() paint((Config[key] - min) / (max - min)) end }
end

local function addCycle(parent, text, key, options)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
    create("TextLabel", {
        Size = UDim2.new(1, -96, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_TEXT,
        Text = text,
    }, row)

    local btn = create("TextButton", {
        Position = UDim2.new(1, -90, 0.5, -10),
        Size = UDim2.fromOffset(90, 20),
        BackgroundColor3 = Color3.fromRGB(30, 30, 46),
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C_TEXT,
        Text = tostring(Config[key]),
    }, row)
    create("UICorner", { CornerRadius = UDim.new(0, 5) }, btn)

    btn.MouseButton1Click:Connect(function()
        local idx = 1
        for i, v in ipairs(options) do
            if v == Config[key] then idx = i break end
        end
        idx = (idx % #options) + 1
        Config[key] = options[idx]
        btn.Text = options[idx]
        save()
    end)
    return btn
end

local function addKeybind(parent, text, key)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
    create("TextLabel", {
        Size = UDim2.new(1, -96, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_TEXT,
        Text = text,
    }, row)

    local btn = create("TextButton", {
        Position = UDim2.new(1, -90, 0.5, -10),
        Size = UDim2.fromOffset(90, 20),
        BackgroundColor3 = Color3.fromRGB(30, 30, 46),
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C_TEXT,
        Text = Config[key].Name,
    }, row)
    create("UICorner", { CornerRadius = UDim.new(0, 5) }, btn)

    btn.MouseButton1Click:Connect(function()
        btn.Text = "press key..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Config[key] = input.KeyCode
                btn.Text = input.KeyCode.Name
                conn:Disconnect()
                save()
            end
        end)
    end)
end

--// Notify
local function notify(text)
    local n = create("Frame", {
        Position = UDim2.new(1, -240, 0, 44),
        Size = UDim2.fromOffset(220, 32),
        BackgroundColor3 = C_PANEL,
        BackgroundTransparency = 0.05,
        ZIndex = 20,
    }, gui)
    create("UICorner", { CornerRadius = UDim.new(0, 7) }, n)
    create("UIStroke", { Color = C_ACCENT, Transparency = 0.35 }, n)
    create("TextLabel", {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -16, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_TEXT,
        Text = text,
    }, n)
    TweenService:Create(n, TweenInfo.new(2), { BackgroundTransparency = 1 }):Play()
    task.delay(2.4, function()
        TweenService:Create(n, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        task.delay(0.3, function()
            if n then n:Destroy() end
        end)
    end)
end

--// Tap watermark to open menu (mobile / if the key fails)
local wmBtn = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, watermark)
wmBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
    miniIcon.Visible = false
end)

--// AIM page
local aimPage = pages["AIM"]
section(aimPage, "Aim Assist")
addToggle(aimPage, "Enable Aimbot", "AimEnabled")
addCycle(aimPage, "Aim Mode", "AimMode", { "Hold", "Toggle", "Always" })
addKeybind(aimPage, "Aim Key", "AimKey")
addCycle(aimPage, "Target Bone", "HitPart", { "Head", "UpperTorso", "Torso", "HumanoidRootPart" })
addToggle(aimPage, "Team Check", "TeamCheck")
addToggle(aimPage, "Match Only", "MatchOnly")
addToggle(aimPage, "Visible Check", "VisibleCheck")
addSlider(aimPage, "FOV", "FOVRadius", 20, 600, 5, function(v)
    fovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
end)
addSlider(aimPage, "Smoothness", "Smoothness", 1, 30, 1)
addSlider(aimPage, "Strength", "Strength", 0.2, 3, 0.1)
addSlider(aimPage, "Prediction", "Prediction", 0, 0.3, 0.01)
addSlider(aimPage, "Max Distance", "MaxDistance", 50, 1000, 10)

section(aimPage, "Trigger")
addToggle(aimPage, "Auto Fire", "AutoShoot")
addKeybind(aimPage, "Fire Key", "AutoShootKey")
addSlider(aimPage, "Shoot Delay", "ShootDelay", 0.02, 0.4, 0.01)
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = C_SUB,
    Text = "Auto Fire only shoots while the Fire Key is held. Auto Farm ignores the key and fires on its own.",
}, aimPage)

--// FARM page
local farmPage = pages["FARM"]
section(farmPage, "Match Farm")
addToggle(farmPage, "Auto Farm Match", "AutoFarm")
addToggle(farmPage, "Auto Respawn", "FarmRespawn")
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = C_SUB,
    Text = "Auto Farm force-enables aim + trigger and hunts the nearest enemy, then clicks respawn / rematch / queue buttons for you.",
}, farmPage)

--// MISC page
local miscPage = pages["MISC"]
section(miscPage, "Interface")
addKeybind(miscPage, "Menu Key", "MenuKey")
addToggle(miscPage, "FOV Circle", "FOVCircle", function(v)
    fovCircle.Visible = v
end)
addToggle(miscPage, "Watermark", "Watermark", function(v)
    watermark.Visible = v
end)

section(miscPage, "Script")
local function smallButton(parent, text, cb)
    local b = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Color3.fromRGB(28, 28, 42),
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C_TEXT,
        Text = text,
    }, parent)
    create("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
    b.MouseButton1Click:Connect(cb)
    return b
end

smallButton(miscPage, "Save Settings", function()
    save()
    notify("settings saved")
end)

smallButton(miscPage, "Reset Settings", function()
    if isfile and isfile(FILE) then pcall(delfile, FILE) end
    Config.AimEnabled, Config.AutoShoot, Config.AutoFarm = false, false, false
    Config.FOVRadius, Config.Smoothness, Config.Strength = 170, 11, 1
    Config.Prediction, Config.MaxDistance, Config.ShootDelay = 0.12, 400, 0.06
    Config.HitPart, Config.AimMode, Config.TeamCheck, Config.VisibleCheck = "Head", "Hold", true, true
    Config.MatchOnly, Config.AutoShootKey = true, Enum.KeyCode.E
    fovCircle.Size = UDim2.fromOffset(340, 340)
    save()
    notify("settings reset - re-execute to apply")
end)

smallButton(miscPage, "Unload Script", function()
    if getgenv().Malek and getgenv().Malek.Unload then getgenv().Malek.Unload() end
end)

--// Dragging
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

--// Icon dragging
local iconDragging, iconDragStart, iconStartPos, iconMoved
miniIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging = true
        iconMoved = false
        iconDragStart = input.Position
        iconStartPos = miniIcon.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                iconDragging = false
                if not iconMoved then
                    main.Visible = true
                    miniIcon.Visible = false
                end
            end
        end)
    end
end)

bind(UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if dragging then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    elseif iconDragging then
        local d = input.Position - iconDragStart
        if d.Magnitude > 4 then iconMoved = true end
        miniIcon.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + d.X, iconStartPos.Y.Scale, iconStartPos.Y.Offset + d.Y)
    end
end))

--// Minimize to icon
local minimized = false
local function setMinimized(state)
    minimized = state
    if state then
        main.Visible = false
        miniIcon.Visible = true
        miniIcon.Position = UDim2.new(
            main.Position.X.Scale, main.Position.X.Offset,
            main.Position.Y.Scale, main.Position.Y.Offset
        )
    else
        main.Visible = true
        miniIcon.Visible = false
    end
end
minimizeBtn.MouseButton1Click:Connect(function() setMinimized(true) end)

--// Unload
local function unload()
    destroyed = true
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    if gui then gui:Destroy() end
    getgenv().Malek = nil
end
closeBtn.MouseButton1Click:Connect(unload)

--// Raycast setup
local rayParams = RaycastParams.new()
do
    local ok = pcall(function() rayParams.FilterType = Enum.RaycastFilterType.Exclude end)
    if not ok then pcall(function() rayParams.FilterType = Enum.RaycastFilterType.Blacklist end) end
end

local function getCam()
    return Workspace.CurrentCamera
end

local function isVisible(part)
    local cam = getCam()
    local char = LP.Character
    if not cam or not char then return false end
    rayParams.FilterDescendantsInstances = { char, cam }
    local origin = cam.CFrame.Position
    local hit = Workspace:Raycast(origin, part.Position - origin, rayParams)
    return hit ~= nil and hit.Instance:IsDescendantOf(part.Parent)
end

--// Enemy validation (teammates + lobby filtered out)
local LOBBY_WORDS = { "lobby", "spectat", "waiting", "queue", "intermission" }

local function hasLobbyWord(txt)
    if not txt then return false end
    txt = txt:lower()
    for _, w in ipairs(LOBBY_WORDS) do
        if txt:find(w, 1, true) then return true end
    end
    return false
end

local function isEnemy(plr)
    if plr == LP then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    -- must actually be in the world, not parked in a lobby container
    if char.Parent and char.Parent ~= Workspace and hasLobbyWord(char.Parent.Name) then return false end

    if Config.TeamCheck and LP.Team ~= nil and plr.Team == LP.Team then return false end

    if Config.MatchOnly then
        if hasLobbyWord(plr.Team and plr.Team.Name) then return false end
        if hasLobbyWord(LP.Team and LP.Team.Name) then return false end
        if LP.Team and not plr.Team then return false end
    end
    return true
end

local function findTarget()
    local char = LP.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    local cam = getCam()
    if not myRoot or not cam then return nil end

    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)

    local best, bestScore = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            local part = plr.Character:FindFirstChild(Config.HitPart)
                or plr.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local dist = (part.Position - myRoot.Position).Magnitude
                if dist <= Config.MaxDistance then
                    local pos = part.Position + part.AssemblyLinearVelocity * Config.Prediction
                    local sp, onScreen = cam:WorldToViewportPoint(pos)
                    if onScreen and sp.Z > 0 then
                        local screen = Vector2.new(sp.X, sp.Y)
                        local d = (screen - center).Magnitude
                        if d <= Config.FOVRadius and d < bestScore then
                            if not Config.VisibleCheck or isVisible(part) then
                                bestScore = d
                                best = { part = part, pos = pos, screen = screen }
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

--// Aim
local aimToggled = false
local lastTarget = nil

local function aimActive()
    if Config.AimMode == "Always" then return true end
    if Config.AimMode == "Toggle" then return aimToggled end
    return UserInputService:IsKeyDown(Config.AimKey)
end

local function aimAt(target)
    local cam = getCam()
    if not cam then return end
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local sp, onScreen = cam:WorldToViewportPoint(target.pos)
    if not onScreen then return end
    local delta = (Vector2.new(sp.X, sp.Y) - center) / math.max(Config.Smoothness, 1) * Config.Strength
    if delta.Magnitude < 0.4 then return end

    if mousemoverel then
        pcall(mousemoverel, delta.X, delta.Y)
    else
        local goal = CFrame.new(cam.CFrame.Position, target.pos)
        cam.CFrame = cam.CFrame:Lerp(goal, math.clamp(Config.Strength / math.max(Config.Smoothness, 1), 0, 1))
    end
end

bind(RunService.RenderStepped:Connect(function()
    if destroyed then return end
    if not (Config.AimEnabled or Config.AutoFarm) then return end
    if not (aimActive() or Config.AutoFarm) then return end
    local t = findTarget()
    lastTarget = t
    if t then aimAt(t) end
end))

--// Trigger
local function clickMouse()
    local cam = getCam()
    local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
    local x, y = vp.X / 2, vp.Y / 2
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
    elseif mouse1click then
        pcall(mouse1click)
    end
end

task.spawn(function()
    while not destroyed do
        task.wait(Config.ShootDelay)
        if not destroyed and (Config.AutoShoot or Config.AutoFarm) then
            local allowed = Config.AutoFarm or UserInputService:IsKeyDown(Config.AutoShootKey)
            if allowed then
                local t = findTarget()
                if t then clickMouse() end
            end
        end
    end
end)

--// Auto farm
local clickCooldown = 0
local function clickGuiButton(keywords)
    if tick() - clickCooldown < 1.2 then return end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, d in ipairs(pg:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible and d.AbsoluteSize.Magnitude > 0 then
            local txt = d:IsA("TextButton") and d.Text:lower() or ""
            for _, kw in ipairs(keywords) do
                if txt:find(kw, 1, true) then
                    clickCooldown = tick()
                    if firesignal then
                        pcall(firesignal, d.MouseButton1Click)
                    else
                        local p = d.AbsolutePosition + d.AbsoluteSize / 2
                        pcall(function()
                            VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 1)
                            task.wait(0.04)
                            VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 1)
                        end)
                    end
                    return
                end
            end
        end
    end
end

local function anyEnemyAlive()
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then return true end
    end
    return false
end

task.spawn(function()
    while not destroyed do
        task.wait(1)
        if not destroyed and Config.AutoFarm then
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                if Config.FarmRespawn then
                    clickGuiButton({ "respawn", "redeploy", "play again" })
                end
            elseif not anyEnemyAlive() then
                clickGuiButton({ "play again", "rematch", "requeue", "queue", "next", "ready" })
            end
        end
    end
end)

--// Keybinds
bind(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.MenuKey then
        if main.Visible then
            main.Visible = false
            miniIcon.Visible = false
        else
            main.Visible = true
            miniIcon.Visible = false
        end
    elseif input.KeyCode == Config.AimKey and Config.AimMode == "Toggle" then
        aimToggled = not aimToggled
    end
end))

--// Auto execute on rejoin
local function setupAutoExecute()
    local src = getgenv().MalekSource
    if not src then
        local ok, info = pcall(debug.getinfo, 1, "s")
        if ok and info and info.source then
            local s = info.source
            if s:sub(1, 1) == "@" or s:sub(1, 1) == "=" then
                local ok2, contents = pcall(readfile, s:sub(2))
                if ok2 and type(contents) == "string" and #contents > 100 then src = contents end
            end
        end
    end
    if src then
        getgenv().MalekSource = src
        local queued = false
        if queue_on_teleport then
            queued = pcall(queue_on_teleport, src)
        end
        if not queued and queueonteleport then
            pcall(queueonteleport, src)
        end
    end
end
setupAutoExecute()

getgenv().Malek = { Unload = unload }
notify("malek script loaded")