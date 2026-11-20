--[[
    ███╗   ███╗ █████╗ ██╗     ███████╗██╗  ██╗
    ████╗ ████║██╔══██╗██║     ██╔════╝██║ ██╔╝
    ██╔████╔██║███████║██║     █████╗  █████╔╝
    ██║╚██╔╝██║██╔══██║██║     ██╔══╝  ██╔═██╗
    ██║ ╚═╝ ██║██║  ██║███████╗███████╗██║  ██╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝

    MALEK SCRIPT  •  RIVALS  •  XENO
    Menu key: RIGHT CTRL
--]]

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
    MenuKey          = Enum.KeyCode.RightControl,
    AimKey           = Enum.KeyCode.Q,
    AimMode          = "Hold",
    AimStyle         = "Smooth",
    AimEnabled       = false,
    Sticky           = true,
    FOVRadius        = 220,
    Smoothness       = 6,
    Strength         = 1.7,
    TurnCap          = 90,
    BulletSpeed      = 300,
    Prediction       = 0.85,
    MaxDistance      = 500,
    HitPart          = "Head",
    FireCone         = 14,
    TeamCheck        = true,
    MatchOnly        = true,
    VisibleCheck     = true,
    WallShoot        = false,
    Humanize         = false,
    ManualMode       = false,
    AutoShoot        = false,
    AutoShootKey     = Enum.KeyCode.E,
    ShootDelay       = 0.06,
    FireMode         = "Hold",
    FireToggleKey    = Enum.KeyCode.F,
    AutoFarm         = false,
    FarmRespawn      = true,
    AutoFarmLevel    = false,
    FarmChase        = true,
    FarmRequireWeapon = true,
    AutoLoadout      = false,
    LoadoutWeapon    = "Rifle",
    AutoInventory    = false,
    AutoOpenAll      = false,
    AntiAfk          = true,
    AntiAfkInterval  = 40,
    FlyEnabled       = false,
    FlyMode          = "Toggle",
    FlyKey           = Enum.KeyCode.G,
    FlySpeed         = 70,
    FlySmooth        = 0.35,
    StickMode        = false,
    StickOffset      = 2.5,
    WalkSpeedEnabled = false,
    WalkSpeed        = 24,
    JumpPower        = 50,
    InfJump          = false,
    SniperMode       = false,
    SniperRequireGun = true,
    SniperSpeed      = 900,
    EspEnabled       = false,
    EspBox           = true,
    EspName          = true,
    EspHealth        = true,
    EspWeapon        = true,
    EspDistance      = true,
    EspTracer        = false,
    EspHighlight     = true,
    EspTeammates     = false,
    EspMaxDistance   = 600,
    EspColorName     = "Red",
    EspTeamColor     = Color3.fromRGB(90, 200, 255),
    Crosshair        = true,
    Hitmarker        = true,
    CameraLock       = false,
    FOVCircle        = true,
    Watermark        = true,
    Theme            = "Purple",
}

local LockedPlayer = nil
local fireToggle = false
local espGui
local setupAutoExecute

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
            if typeof(v) ~= "Instance" and typeof(v) ~= "Color3" then
                out[k] = typeof(v) == "EnumItem" and v.Name or v
            end
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

--// Root
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
    Size = UDim2.fromOffset(220, 22),
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

--// Window
local main = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    Size = UDim2.fromOffset(340, 470),
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
    Size = UDim2.fromOffset(220, 14),
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

local function buildPage(name, index, total)
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
        Position = UDim2.new((index - 1) / total, 0, 0, 0),
        Size = UDim2.new(1 / total, -3, 1, 0),
        BackgroundColor3 = Color3.fromRGB(22, 22, 34),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
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
            tabButtons[n].BackgroundColor3 = (n == name) and C_ACCENT or Color3.fromRGB(22, 22, 34)
        end
    end)
end

buildPage("AIM", 1, 6)
buildPage("TEAM", 2, 6)
buildPage("FARM", 3, 6)
buildPage("MOVE", 4, 6)
buildPage("VISUAL", 5, 6)
buildPage("MISC", 6, 6)
tabButtons["AIM"].TextColor3 = C_TEXT
tabButtons["AIM"].BackgroundColor3 = C_ACCENT

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

--// Themes
local THEMES = {
    Purple = { accent = Color3.fromRGB(124, 92, 255), accent2 = Color3.fromRGB(0, 229, 255), bg = Color3.fromRGB(10, 10, 16), panel = Color3.fromRGB(17, 17, 27), line = Color3.fromRGB(40, 40, 58), text = Color3.fromRGB(234, 234, 244), sub = Color3.fromRGB(138, 138, 164), off = Color3.fromRGB(42, 42, 58), header = Color3.fromRGB(30, 22, 56), tabOn = Color3.fromRGB(38, 30, 66) },
    Blue   = { accent = Color3.fromRGB(64, 140, 255), accent2 = Color3.fromRGB(0, 214, 255), bg = Color3.fromRGB(8, 12, 20), panel = Color3.fromRGB(14, 20, 32), line = Color3.fromRGB(34, 52, 76), text = Color3.fromRGB(228, 238, 250), sub = Color3.fromRGB(132, 152, 176), off = Color3.fromRGB(30, 42, 58), header = Color3.fromRGB(18, 32, 56), tabOn = Color3.fromRGB(24, 44, 74) },
    Red    = { accent = Color3.fromRGB(255, 74, 92), accent2 = Color3.fromRGB(255, 152, 72), bg = Color3.fromRGB(16, 9, 11), panel = Color3.fromRGB(26, 15, 18), line = Color3.fromRGB(64, 32, 38), text = Color3.fromRGB(250, 230, 232), sub = Color3.fromRGB(170, 130, 136), off = Color3.fromRGB(52, 30, 34), header = Color3.fromRGB(48, 18, 24), tabOn = Color3.fromRGB(74, 28, 36) },
    Yellow = { accent = Color3.fromRGB(255, 202, 60), accent2 = Color3.fromRGB(255, 236, 150), bg = Color3.fromRGB(16, 14, 8), panel = Color3.fromRGB(26, 23, 12), line = Color3.fromRGB(66, 58, 28), text = Color3.fromRGB(250, 246, 228), sub = Color3.fromRGB(170, 160, 130), off = Color3.fromRGB(52, 46, 24), header = Color3.fromRGB(46, 38, 14), tabOn = Color3.fromRGB(74, 62, 22) },
    White  = { accent = Color3.fromRGB(236, 236, 246), accent2 = Color3.fromRGB(170, 186, 210), bg = Color3.fromRGB(12, 12, 14), panel = Color3.fromRGB(22, 22, 26), line = Color3.fromRGB(62, 62, 72), text = Color3.fromRGB(245, 245, 250), sub = Color3.fromRGB(150, 150, 162), off = Color3.fromRGB(44, 44, 52), header = Color3.fromRGB(38, 38, 46), tabOn = Color3.fromRGB(58, 58, 70) },
    Pink   = { accent = Color3.fromRGB(255, 112, 202), accent2 = Color3.fromRGB(184, 124, 255), bg = Color3.fromRGB(16, 9, 15), panel = Color3.fromRGB(26, 15, 24), line = Color3.fromRGB(64, 30, 56), text = Color3.fromRGB(250, 232, 244), sub = Color3.fromRGB(170, 132, 156), off = Color3.fromRGB(52, 30, 46), header = Color3.fromRGB(48, 18, 42), tabOn = Color3.fromRGB(74, 28, 62) },
}
local currentTheme = "Purple"
local refreshSwatches = function() end

local function applyThemeTo(root)
    if not root then return end
    local from = THEMES[currentTheme]
    local to = THEMES[Config.Theme] or THEMES.Purple
    if not from or not to then return end

    local function map(c)
        for k, v in pairs(from) do
            if c == v then return to[k] end
        end
        if from ~= THEMES.Purple then
            for k, v in pairs(THEMES.Purple) do
                if c == v then return to[k] end
            end
        end
        return c
    end

    for _, o in ipairs(root:GetDescendants()) do
        if o:IsA("Frame") or o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("ScrollingFrame") then
            if o.BackgroundColor3 then o.BackgroundColor3 = map(o.BackgroundColor3) end
            if o:IsA("TextLabel") or o:IsA("TextButton") then
                if o.TextColor3 then o.TextColor3 = map(o.TextColor3) end
            end
        end
        if o:IsA("UIStroke") then o.Color = map(o.Color) end
        if o:IsA("UIGradient") then
            local kps = {}
            for _, kp in ipairs(o.Color.Keypoints) do
                kps[#kps + 1] = ColorSequenceKeypoint(kp.Time, map(kp.Value))
            end
            o.Color = ColorSequence.new(kps)
        end
    end
end

local function applyTheme(name)
    if not THEMES[name] then return end
    Config.Theme = name
    applyThemeTo(gui)
    applyThemeTo(espGui)
    currentTheme = name
    refreshSwatches()
    save()
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
    applyThemeTo(n)
    TweenService:Create(n, TweenInfo.new(2), { BackgroundTransparency = 1 }):Play()
    task.delay(2.4, function()
        if n then n:Destroy() end
    end)
end

--// Watermark tap
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
addCycle(aimPage, "Aim Style", "AimStyle", { "Smooth", "Snap", "Assist" })
addKeybind(aimPage, "Aim Key", "AimKey")
addToggle(aimPage, "Sticky Target", "Sticky")
addCycle(aimPage, "Target Bone", "HitPart", { "Head", "UpperTorso", "Torso", "HumanoidRootPart" })
addToggle(aimPage, "Team Check", "TeamCheck")
addToggle(aimPage, "Match Only", "MatchOnly")

section(aimPage, "Walls")
addToggle(aimPage, "Visible Check", "VisibleCheck")
addToggle(aimPage, "Shoot Through Walls", "WallShoot")

section(aimPage, "Humanize")
addToggle(aimPage, "Humanize Aim", "Humanize")
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = C_SUB,
    Text = "Adds micro drift to the crosshair and jitters fire timing so input is not perfectly uniform.",
}, aimPage)

addSlider(aimPage, "FOV", "FOVRadius", 20, 600, 5, function(v)
    fovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
end)
addSlider(aimPage, "Smoothness", "Smoothness", 1, 30, 1)
addSlider(aimPage, "Strength", "Strength", 0.2, 3, 0.1)
addSlider(aimPage, "Turn Cap", "TurnCap", 20, 300, 5)
addSlider(aimPage, "Bullet Speed", "BulletSpeed", 60, 1200, 10)
addSlider(aimPage, "Prediction", "Prediction", 0, 2, 0.05)
addSlider(aimPage, "Max Distance", "MaxDistance", 50, 1000, 10)

section(aimPage, "Sniper")
addToggle(aimPage, "Sniper Aimbot", "SniperMode")
addToggle(aimPage, "Only With Sniper", "SniperRequireGun")
addSlider(aimPage, "Sniper Velocity", "SniperSpeed", 200, 2000, 25)

section(aimPage, "Trigger")
addToggle(aimPage, "Auto Fire", "AutoShoot")
addCycle(aimPage, "Fire Mode", "FireMode", { "Hold", "Toggle", "Always" })
addKeybind(aimPage, "Fire Key", "AutoShootKey")
addKeybind(aimPage, "Fire Toggle Key", "FireToggleKey")
addSlider(aimPage, "Shoot Delay", "ShootDelay", 0.02, 0.4, 0.01)
addSlider(aimPage, "Fire Cone", "FireCone", 2, 80, 1)

--// MISC page
local dumpTeamData
local miscPage = pages["MISC"]
section(miscPage, "Interface")
addKeybind(miscPage, "Menu Key", "MenuKey")
addToggle(miscPage, "FOV Circle", "FOVCircle", function(v)
    fovCircle.Visible = v
end)
addToggle(miscPage, "Watermark", "Watermark", function(v)
    watermark.Visible = v
end)

section(miscPage, "Theme")
local swatchRow = create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 }, miscPage)
create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, swatchRow)

local swatches = {}
for _, name in ipairs({ "Purple", "Blue", "Red", "Yellow", "White", "Pink" }) do
    local t = THEMES[name]
    local b = create("TextButton", {
        Size = UDim2.new(1 / 6, -4, 1, 0),
        BackgroundColor3 = t.accent,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = t.bg,
        Text = name,
    }, swatchRow)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
    b.MouseButton1Click:Connect(function() applyTheme(name) end)
    swatches[name] = b
end

refreshSwatches = function()
    for n, b in pairs(swatches) do
        b.BackgroundColor3 = THEMES[n].accent
        b.TextColor3 = THEMES[n].bg
    end
end

section(miscPage, "Script")
smallButton(miscPage, "Save Settings", function()
    save()
    notify("settings saved")
end)

smallButton(miscPage, "Repair Auto-Exec", function()
    if setupAutoExecute and setupAutoExecute() then
        notify("auto-exec re-armed")
    else
        notify("auto-exec failed")
    end
end)

smallButton(miscPage, "Dump Team Data", function()
    dumpTeamData()
end)

smallButton(miscPage, "Reset Settings", function()
    if isfile and isfile(FILE) then pcall(delfile, FILE) end
    Config.AimEnabled, Config.AutoShoot, Config.AutoFarm = false, false, false
    Config.AutoFarmLevel, Config.FlyEnabled, Config.StickMode = false, false, false
    Config.FOVRadius, Config.Smoothness, Config.Strength = 220, 6, 1.7
    Config.Prediction, Config.MaxDistance, Config.ShootDelay = 0.85, 500, 0.06
    Config.HitPart, Config.AimMode, Config.AimStyle = "Head", "Hold", "Smooth"
    Config.TeamCheck, Config.MatchOnly, Config.VisibleCheck = true, true, true
    Config.WallShoot, Config.Humanize, Config.ManualMode = false, false, false
    Config.TurnCap, Config.BulletSpeed, Config.FireCone = 90, 300, 14
    Config.FireMode, Config.SniperMode, Config.EspEnabled = "Hold", false, false
    Config.WalkSpeedEnabled, Config.InfJump = false, false
    Config.EspColorName = "Red"
    fovCircle.Size = UDim2.fromOffset(440, 440)
    applyTheme("Purple")
    save()
    notify("settings reset")
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

--// Minimize
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
    if espGui then espGui:Destroy() end
    getgenv().Malek = nil
end
closeBtn.MouseButton1Click:Connect(unload)

--// Raycast
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

--=====================================================================
--  TEAM IDENTITY
--=====================================================================

local HARD_RANGE = 1500

local ENV_ATTRS   = { "EnvironmentID", "EnvironmentId", "environmentId", "MatchID", "MatchId", "matchId", "ServerID", "ServerId" }
local TEAM_ATTRS  = { "TeamID", "TeamId", "teamId", "Team", "team", "TeamName", "teamName", "TeamColor", "teamColor" }

local LOBBY_WORDS = { "lobby", "spectat", "waiting", "queue", "intermission" }

local GENERIC_PARENTS = {
    players = true, characters = true, entities = true, actors = true,
    spawns = true, folder = true, game = true, workspace = true,
}

local DEFAULT_COLORS = {
    ["Medium stone grey"] = true,
    ["Institutional white"] = true,
    ["White"] = true,
    ["Dark stone grey"] = true,
    ["Really black"] = true,
    ["Black"] = true,
}

local function hasLobbyWord(txt)
    if not txt then return false end
    txt = tostring(txt):lower()
    for _, w in ipairs(LOBBY_WORDS) do
        if txt:find(w, 1, true) then return true end
    end
    return false
end

local function readAttr(inst, name)
    if not inst then return nil end
    local ok, v = pcall(function() return inst:GetAttribute(name) end)
    if ok and v ~= nil and v ~= "" then return tostring(v) end
    return nil
end

local function envOf(plr)
    local char = plr.Character
    for _, a in ipairs(ENV_ATTRS) do
        local v = readAttr(plr, a) or readAttr(char, a)
        if v then return v end
    end
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("StringValue") or v:IsA("IntValue") or v:IsA("NumberValue") then
                local n = v.Name:lower()
                if n:find("environment", 1, true) or n:find("matchid", 1, true) then
                    return tostring(v.Value)
                end
            end
        end
    end
    return nil
end

local function teamSignals(plr)
    local out = {}
    local char = plr.Character
    local function add(k, tier)
        if k then out[#out + 1] = { key = k, tier = tier } end
    end

    for _, a in ipairs(TEAM_ATTRS) do
        local v = readAttr(plr, a)
        if v then add("A:" .. a .. "=" .. v, 1) end
    end
    for _, a in ipairs(TEAM_ATTRS) do
        local v = readAttr(char, a)
        if v then add("CA:" .. a .. "=" .. v, 1) end
    end

    if char then
        for _, v in ipairs(char:GetChildren()) do
            if (v:IsA("StringValue") or v:IsA("IntValue") or v:IsA("NumberValue"))
                and v.Name:lower():find("team", 1, true) then
                add("V:" .. v.Name .. "=" .. tostring(v.Value), 2)
            end
        end
        local shirt = char:FindFirstChildOfClass("Shirt")
        if shirt and shirt.ShirtTemplate ~= "" then add("S:" .. shirt.ShirtTemplate, 3) end
        local pn = char.Parent and char.Parent ~= Workspace and char.Parent.Name
        if pn and not GENERIC_PARENTS[pn:lower()] and not hasLobbyWord(pn) then add("P:" .. pn, 4) end
    end

    if plr.Team then add("T:" .. plr.Team.Name, 1) end
    if plr.TeamColor and not DEFAULT_COLORS[plr.TeamColor.Name] then add("C:" .. plr.TeamColor.Name, 3) end

    table.sort(out, function(a, b) return a.tier < b.tier end)
    return out
end

local sigCache = {}
local function signalsOf(plr)
    local c = sigCache[plr]
    local now = tick()
    if c and now - c.stamp < 0.2 then return c.sig, c.env end
    local sig = teamSignals(plr)
    local env = envOf(plr)
    sigCache[plr] = { stamp = now, sig = sig, env = env }
    return sig, env
end

bind(Players.PlayerRemoving:Connect(function(p)
    sigCache[p] = nil
end))

local function autoSameTeam(plr)
    local a = signalsOf(plr)
    local b = signalsOf(LP)
    if #a == 0 or #b == 0 then return false end
    local tier = math.min(a[1].tier, b[1].tier)
    for _, x in ipairs(a) do
        if x.tier == tier then
            for _, y in ipairs(b) do
                if y.tier == tier and x.key == y.key then return true end
            end
        end
    end
    return false
end

local ffa, ffaStamp = false, 0
local function isFfa()
    if tick() - ffaStamp < 1 then return ffa end
    ffaStamp = tick()
    local mine = signalsOf(LP)
    if #mine == 0 then ffa = true return true end
    local seen, distinct = {}, 0
    for _, plr in ipairs(Players:GetPlayers()) do
        local sig = signalsOf(plr)
        if #sig > 0 then
            local k = sig[1].key
            if not seen[k] then seen[k] = true distinct += 1 end
        end
    end
    ffa = distinct <= 1
    return ffa
end

--// Manual team overrides
local MANUAL_FILE = "MalekScript_teams.json"
local Manual = {}

local function loadManual()
    if not (isfile and isfile(MANUAL_FILE)) then return end
    local ok, raw = pcall(readfile, MANUAL_FILE)
    if not ok or type(raw) ~= "string" then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return end
    for k, v in pairs(data) do
        if v == "mate" or v == "enemy" then Manual[tostring(k)] = v end
    end
end
loadManual()

local function saveManual()
    pcall(function() writefile(MANUAL_FILE, HttpService:JSONEncode(Manual)) end)
end

local function manualOf(plr)
    return Manual[tostring(plr.UserId)]
end

local function setManual(plr, val)
    local k = tostring(plr.UserId)
    if val then Manual[k] = val else Manual[k] = nil end
    saveManual()
end

local function sameTeam(plr)
    if plr == LP then return true end
    local m = manualOf(plr)
    if m then return m == "mate" end
    if Config.ManualMode then return false end
    if isFfa() then return false end
    return autoSameTeam(plr)
end

local function isEnemy(plr)
    if plr == LP then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    if char.Parent and char.Parent ~= Workspace and hasLobbyWord(char.Parent.Name) then return false end

    local m = manualOf(plr)
    if m then return m == "enemy" end
    if Config.ManualMode then return true end

    if Config.TeamCheck then
        local _, myEnv = signalsOf(LP)
        local _, theirEnv = signalsOf(plr)
        local sameEnv = (myEnv == nil or theirEnv == nil or myEnv == theirEnv)
        if sameEnv and not isFfa() and autoSameTeam(plr) then return false end
    end

    if Config.MatchOnly and hasLobbyWord(plr.Team and plr.Team.Name) then return false end
    return true
end

dumpTeamData = function()
    print("=== SELF " .. LP.Name .. " | env=" .. tostring(select(2, signalsOf(LP))))
    for _, s in ipairs((signalsOf(LP))) do
        print("   self sig T" .. s.tier .. "  " .. s.key)
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local tag = sameTeam(plr) and "MATE" or "ENEMY"
            if manualOf(plr) then tag = tag .. " (MANUAL)" end
            print(plr.Name .. " [" .. tag .. "] env=" .. tostring(select(2, signalsOf(plr))))
            for _, s in ipairs((signalsOf(plr))) do
                print("   sig T" .. s.tier .. "  " .. s.key)
            end
        end
    end
    notify("team data dumped")
end

--=====================================================================
--  TEAM PAGE
--=====================================================================
local teamPage = pages["TEAM"]
section(teamPage, "Manual Team Select")
addToggle(teamPage, "Manual Mode (unassigned = enemy)", "ManualMode")
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = C_SUB,
    Text = "Tap a row to cycle: A = auto, M = teammate, E = enemy. Manual picks always win over automatic detection.",
}, teamPage)

local quickRow = create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, teamPage)
create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, quickRow)

local function quickBtn(text, cb)
    local b = create("TextButton", {
        Size = UDim2.new(0.25, -3, 1, 0),
        BackgroundColor3 = Color3.fromRGB(28, 28, 42),
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = C_TEXT,
        Text = text,
    }, quickRow)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
    b.MouseButton1Click:Connect(cb)
end

local teamList = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 170),
    BackgroundColor3 = Color3.fromRGB(20, 20, 30),
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, teamPage)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, teamList)
create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4) }, teamList)
create("UIListLayout", { Padding = UDim.new(0, 3) }, teamList)

local function refreshTeamList()
    for _, c in ipairs(teamList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local state = manualOf(plr)
            local autoMate = autoSameTeam(plr)
            local row = create("Frame", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Color3.fromRGB(26, 26, 38),
                BorderSizePixel = 0,
            }, teamList)
            create("UICorner", { CornerRadius = UDim.new(0, 4) }, row)

            create("TextLabel", {
                Position = UDim2.fromOffset(6, 0),
                Size = UDim2.new(1, -44, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = (state == "enemy") and ENEMY_COL or ((state == "mate") and Config.EspTeamColor or C_SUB),
                Text = plr.Name .. (state and "" or ("  · auto:" .. (autoMate and "mate" or "enemy"))),
            }, row)

            local chip = create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -5, 0.5, 0),
                Size = UDim2.fromOffset(28, 16),
                BackgroundColor3 = (state == "mate" and Config.EspTeamColor) or (state == "enemy" and ENEMY_COL) or Color3.fromRGB(48, 48, 64),
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = C_BG,
                Text = state == "mate" and "M" or (state == "enemy" and "E" or "A"),
            }, row)
            create("UICorner", { CornerRadius = UDim.new(0, 4) }, chip)

            local function hit()
                local cur = manualOf(plr)
                if cur == nil then setManual(plr, "mate")
                elseif cur == "mate" then setManual(plr, "enemy")
                else setManual(plr, nil) end
                refreshTeamList()
            end
            chip.MouseButton1Click:Connect(hit)
            row.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then hit() end
            end)
        end
    end
end

quickBtn("All Mate", function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then setManual(plr, "mate") end
    end
    refreshTeamList()
end)

quickBtn("All Enemy", function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then setManual(plr, "enemy") end
    end
    refreshTeamList()
end)

quickBtn("Invert", function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local cur = manualOf(plr)
            if cur == "mate" then setManual(plr, "enemy")
            elseif cur == "enemy" then setManual(plr, "mate")
            elseif autoSameTeam(plr) then setManual(plr, "enemy")
            else setManual(plr, "mate") end
        end
    end
    refreshTeamList()
end)

quickBtn("Clear", function()
    for k in pairs(Manual) do Manual[k] = nil end
    saveManual()
    refreshTeamList()
end)

section(teamPage, "Debug")
smallButton(teamPage, "Dump Team Data", function() dumpTeamData() end)

refreshTeamList()
bind(Players.PlayerAdded:Connect(function() task.wait(1) refreshTeamList() end))
bind(Players.PlayerRemoving:Connect(function() task.wait(0.5) refreshTeamList() end))

task.spawn(function()
    while not destroyed do
        task.wait(1.5)
        if teamPage.Visible and main.Visible then refreshTeamList() end
    end
end)

--=====================================================================
--  LOADOUT / INVENTORY / ANTI-AFK
--=====================================================================

local uiCooldown = 0

local WEAPON_ALIASES = {
    Rifle   = { "rifle", "ak", "m4", "carbine", "ar" },
    SMG     = { "smg", "uzi", "mp5", "mac", "p90", "vector" },
    Shotgun = { "shotgun", "pump", "spas", "judge", "sawn" },
    Sniper  = { "sniper", "awp", "railgun", "marksman", "kar", "barrett" },
    Pistol  = { "pistol", "deagle", "revolver", "glock", "magnum" },
}

local function visibleButtons()
    local out = {}
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return out end
    for _, d in ipairs(pg:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton"))
            and d.Visible and d.AbsoluteSize.Magnitude > 0 then
            out[#out + 1] = d
        end
    end
    return out
end

local function pressButton(btn)
    uiCooldown = tick()
    if firesignal then
        pcall(firesignal, btn.M