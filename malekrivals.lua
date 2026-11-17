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

--// Services
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui            = game:GetService("CoreGui")
local Workspace          = game:GetService("Workspace")

local LP = Players.LocalPlayer

--// Re-exec guard
if getgenv().Malek and getgenv().Malek.Unload then
    pcall(getgenv().Malek.Unload)
end

local destroyed = false
local connections = {}
local function bind(conn) table.insert(connections, conn) return conn end

--// Config
local FILE = "MalekScript_Rivals.json"

local Config = {
    MenuKey      = Enum.KeyCode.RightControl,
    AimKey       = Enum.KeyCode.Q,
    AimMode      = "Hold",           -- Hold / Toggle / Always
    FOVRadius    = 170,
    Smoothness   = 11,
    Strength     = 1,
    Prediction   = 0.12,
    MaxDistance  = 400,
    HitPart      = "Head",
    TeamCheck    = true,
    VisibleCheck = true,
    AutoShoot    = false,
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
        if Config[k] ~= nil and type(v) == type(Config[k]) or (typeof(Config[k]) == "EnumItem" and type(v) == "string") then
            if typeof(Config[k]) == "EnumItem" then
                Config[k] = Enum.KeyCode[v] or Config[k]
            else
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

--// GUI
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
    create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4) }, page)
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
    local l = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_ACCENT2,
        Text = string.upper(text),
    }, parent)
    return l
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
                    move:Disconnect(); release:Disconnect()
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
    local row = create("Frame", { Size = U
