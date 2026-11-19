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
    AutoShoot        = false,
    AutoShootKey     = Enum.KeyCode.E,
    ShootDelay       = 0.06,
    FireMode         = "Hold",
    FireToggleKey    = Enum.KeyCode.F,
    AutoFarm         = false,
    FarmRespawn      = true,
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
        Size = UDim2.new(1 / total, -4, 1, 0),
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
            tabButtons[n].BackgroundColor3 = (n == name) and C_ACCENT or Color3.fromRGB(22, 22, 34)
        end
    end)
end

buildPage("AIM", 1, 4)
buildPage("FARM", 2, 4)
buildPage("VISUAL", 3, 4)
buildPage("MISC", 4, 4)
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
addToggle(aimPage, "Visible Check", "VisibleCheck")
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
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = C_SUB,
    Text = "Hold = fires while Fire Key held. Toggle = tap Fire Toggle Key to latch. Always = fires on sight.",
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
    Text = "Force-enables aim and trigger, hunts the nearest enemy, then clicks respawn / rematch / queue buttons.",
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

smallButton(miscPage, "Repair Auto-Exec", function()
    if setupAutoExecute and setupAutoExecute() then
        notify("auto-exec re-armed")
    else
        notify("auto-exec failed")
    end
end)

smallButton(miscPage, "Dump Team Data", function()
    for _, plr in ipairs(Players:GetPlayers()) do
        local keys = teamKeys(plr)
        print(plr.Name .. " -> " .. (#keys > 0 and table.concat(keys, " | ") or "NO SIGNALS"))
    end
    notify("team data dumped")
end)

smallButton(miscPage, "Reset Settings", function()
    if isfile and isfile(FILE) then pcall(delfile, FILE) end
    Config.AimEnabled, Config.AutoShoot, Config.AutoFarm = false, false, false
    Config.FOVRadius, Config.Smoothness, Config.Strength = 220, 6, 1.7
    Config.Prediction, Config.MaxDistance, Config.ShootDelay = 0.85, 500, 0.06
    Config.HitPart, Config.AimMode, Config.AimStyle = "Head", "Hold", "Smooth"
    Config.TeamCheck, Config.MatchOnly, Config.VisibleCheck = true, true, true
    Config.TurnCap, Config.BulletSpeed, Config.FireCone = 90, 300, 14
    Config.FireMode, Config.SniperMode, Config.EspEnabled = "Hold", false, false
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

--// Enemy validation
local LOBBY_WORDS = { "lobby", "spectat", "waiting", "queue", "intermission" }

local function hasLobbyWord(txt)
    if not txt then return false end
    txt = txt:lower()
    for _, w in ipairs(LOBBY_WORDS) do
        if txt:find(w, 1, true) then return true end
    end
    return false
end

local TEAM_ATTRS = { "Team", "team", "TeamName", "teamName", "TeamId", "teamId", "TeamColor", "teamColor" }

local function teamKeys(plr)
    local keys = {}
    if plr.Team then keys[#keys + 1] = "team:" .. plr.Team.Name end
    if plr.TeamColor and plr.TeamColor ~= BrickColor.new("Medium stone grey") then
        keys[#keys + 1] = "color:" .. plr.TeamColor.Name
    end
    for _, a in ipairs(TEAM_ATTRS) do
        local ok, v = pcall(function() return plr:GetAttribute(a) end)
        if ok and v ~= nil then keys[#keys + 1] = "attr:" .. a .. "=" .. tostring(v) end
    end

    local char = plr.Character
    if char then
        for _, a in ipairs(TEAM_ATTRS) do
            local ok, v = pcall(function() return char:GetAttribute(a) end)
            if ok and v ~= nil then keys[#keys + 1] = "cattr:" .. a .. "=" .. tostring(v) end
        end
        for _, v in ipairs(char:GetChildren()) do
            if (v:IsA("StringValue") or v:IsA("IntValue") or v:IsA("NumberValue")) and v.Name:lower():find("team", 1, true) then
                keys[#keys + 1] = "val:" .. v.Name .. "=" .. tostring(v.Value)
            end
        end
        local shirt = char:FindFirstChildOfClass("Shirt")
        if shirt and shirt.ShirtTemplate ~= "" then keys[#keys + 1] = "shirt:" .. shirt.ShirtTemplate end
        if char.Parent and char.Parent ~= Workspace then keys[#keys + 1] = "parent:" .. char.Parent.Name end
    end
    return keys
end

local function sameTeam(plr)
    local a = teamKeys(plr)
    local b = teamKeys(LP)
    if #a == 0 or #b == 0 then return false end
    for _, x in ipairs(a) do
        for _, y in ipairs(b) do
            if x == y then return true end
        end
    end
    return false
end

local function isEnemy(plr)
    if plr == LP then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    if char.Parent and char.Parent ~= Workspace and hasLobbyWord(char.Parent.Name) then return false end
    if Config.TeamCheck and sameTeam(plr) then return false end

    if Config.MatchOnly then
        if hasLobbyWord(plr.Team and plr.Team.Name) then return false end
        if hasLobbyWord(LP.Team and LP.Team.Name) then return false end
        if Config.TeamCheck and #teamKeys(LP) > 0 and #teamKeys(plr) == 0 then return false end
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
            local bone = Config.SniperMode and "Head" or Config.HitPart
            local part = plr.Character:FindFirstChild(bone)
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
local lockUntil = 0

local function aimActive()
    if Config.AimMode == "Always" then return true end
    if Config.AimMode == "Toggle" then return aimToggled end
    return UserInputService:IsKeyDown(Config.AimKey)
end

local function spherePoint(center, radius, ray)
    local oc = center - ray.Origin
    local t = oc:Dot(ray.Direction)
    local closest = ray.Origin + ray.Direction * math.max(t, 0)
    local d = (center - closest).Magnitude
    if d <= radius then return closest end
    return center - (center - closest).Unit * radius
end

local function targetStillValid(t)
    if not t or not t.part or not t.part.Parent then return false end
    local char = t.part.Parent
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local plr = Players:GetPlayerFromCharacter(char)
    if not plr or not isEnemy(plr) then return false end
    local cam = getCam()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not cam or not myRoot then return false end
    if (t.part.Position - myRoot.Position).Magnitude > Config.MaxDistance then return false end
    local sp, onScreen = cam:WorldToViewportPoint(t.part.Position)
    if not onScreen then return false end
    local vp = cam.ViewportSize
    local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(vp.X / 2, vp.Y / 2)).Magnitude
    return d <= Config.FOVRadius * 1.2
end

local function sniperEquipped()
    local char = LP.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = tool.Name:lower()
    for _, w in ipairs({ "sniper", "railgun", "awp", "hunting", "kar98", "barrett", "intervention", "dragunov", "marksman" }) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

local function sniperActive()
    if not Config.SniperMode then return false end
    if Config.SniperRequireGun and not sniperEquipped() then return false end
    return true
end

local function aimAt(part, dt)
    local cam = getCam()
    if not cam then return end
    local sniper = sniperActive()
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local ray = cam:ScreenPointToRay(center.X, center.Y)

    local dist = (part.Position - cam.CFrame.Position).Magnitude
    local speed = sniper and Config.SniperSpeed or Config.BulletSpeed
    local pred = sniper and 1 or Config.Prediction
    local lead = (dist / math.max(speed, 1)) * pred
    local predicted = part.Position + part.AssemblyLinearVelocity * lead

    local radius = math.max(part.Size.X, part.Size.Y, part.Size.Z) * 0.5
    local aimPoint = spherePoint(predicted, radius, ray)

    local sp, onScreen = cam:WorldToViewportPoint(aimPoint)
    if not onScreen then return end

    local delta = Vector2.new(sp.X, sp.Y) - center
    if delta.Magnitude < 0.3 then return end

    local alpha
    if sniper or Config.AimStyle == "Snap" then
        alpha = 1
    else
        local rate = Config.Smoothness
        if Config.AimStyle == "Assist" then rate = rate * 0.45 end
        alpha = 1 - math.exp(-rate * dt)
    end

    local strength = sniper and 1 or Config.Strength
    local move = delta * alpha * strength
    local cap = sniper and 400 or Config.TurnCap
    if move.Magnitude > cap then move = move.Unit * cap end

    if mousemoverel and not Config.CameraLock then
        pcall(mousemoverel, move.X, move.Y)
    else
        local goal = CFrame.new(cam.CFrame.Position, aimPoint)
        cam.CFrame = cam.CFrame:Lerp(goal, math.clamp(alpha * strength, 0, 1))
    end
end

bind(RunService.RenderStepped:Connect(function(dt)
    if destroyed then return end
    if not (Config.AimEnabled or Config.AutoFarm) then return end
    if not (aimActive() or Config.AutoFarm) then return end

    local t
    if LockedPlayer and LockedPlayer.Character then
        local p = LockedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if p and targetStillValid({ part = p }) then t = { part = p } end
    end

    if not t then
        if Config.Sticky and lastTarget and tick() < lockUntil and targetStillValid(lastTarget) then
            t = lastTarget
        else
            t = findTarget()
            if t then
                lastTarget = t
                lockUntil = tick() + 0.75
            end
        end
    end

    if t and t.part then aimAt(t.part, dt) end
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
            local allowed
            if Config.AutoFarm or Config.FireMode == "Always" then
                allowed = true
            elseif Config.FireMode == "Toggle" then
                allowed = fireToggle
            else
                allowed = UserInputService:IsKeyDown(Config.AutoShootKey)
            end
            if allowed then
                local t = lastTarget
                if t and targetStillValid(t) then
                    local cam = getCam()
                    if cam then
                        local vp = cam.ViewportSize
                        local sp, onScreen = cam:WorldToViewportPoint(t.part.Position)
                        if onScreen then
                            local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(vp.X / 2, vp.Y / 2)).Magnitude
                            if d <= Config.FireCone then clickMouse() end
                        end
                    end
                end
            end
        end
    end
end)

--// Farm
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

--// Visuals
local COLOR_MAP = {
    Red = Color3.fromRGB(255, 70, 90),
    Orange = Color3.fromRGB(255, 145, 45),
    Yellow = Color3.fromRGB(255, 220, 60),
    Green = Color3.fromRGB(90, 255, 140),
    Blue = Color3.fromRGB(90, 200, 255),
    Purple = Color3.fromRGB(200, 120, 255),
}

local ENEMY_COL = Color3.fromRGB(255, 70, 90)

local function enemyColor()
    if Config.EspColorName == "Red" then return ENEMY_COL end
    return COLOR_MAP[Config.EspColorName] or ENEMY_COL
end

espGui = create("ScreenGui", {
    Name = "MalekVisuals",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 997,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, getGuiParent())

local crossWrap = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(14, 14),
    BackgroundTransparency = 1,
    Visible = Config.Crosshair,
    ZIndex = 40,
}, espGui)
create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(2, 14), BackgroundColor3 = C_ACCENT2, BorderSizePixel = 0 }, crossWrap)
create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 2), BackgroundColor3 = C_ACCENT2, BorderSizePixel = 0 }, crossWrap)

local hitmark = create("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(40, 40),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 26,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Text = "✕",
    Visible = false,
    ZIndex = 41,
}, espGui)

local hitSound
pcall(function()
    hitSound = Instance.new("Sound")
    hitSound.SoundId = "rbxassetid://131961136"
    hitSound.Volume = 0.45
    hitSound.Parent = espGui
end)

local ESP = { pool = {} }

local function killEsp(plr)
    local d = ESP.pool[plr]
    if not d then return end
    for _, v in pairs(d) do
        if typeof(v) == "Instance" then pcall(function() v:Destroy() end) end
    end
    ESP.pool[plr] = nil
end

local function buildEsp(plr)
    local d = {}
    local col = COLOR_MAP[Config.EspColorName] or ENEMY_COL

    d.tracer = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = col,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 11,
    }, espGui)

    d.box = create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 12 }, espGui)
    d.fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = col, BackgroundTransparency = 0.85, BorderSizePixel = 0 }, d.box)
    d.stroke = create("UIStroke", { Thickness = 1, Color = col }, d.box)
    d.name = create("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, -4, 0), Size = UDim2.fromOffset(160, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = col, ZIndex = 13 }, d.box)
    d.info = create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(190, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C_TEXT, ZIndex = 13 }, d.box)
    d.hpBg = create("Frame", { Position = UDim2.new(-6, 0, 0, 0), Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = Color3.fromRGB(25, 25, 35), BorderSizePixel = 0, ZIndex = 13 }, d.box)
    d.hpFill = create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(90, 255, 140), BorderSizePixel = 0, ZIndex = 14 }, d.hpBg)

    if Config.EspHighlight and plr.Character then
        d.hl = create("Highlight", {
            Adornee = plr.Character,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
            FillTransparency = 0.65,
            OutlineTransparency = 0.1,
            FillColor = col,
            OutlineColor = col,
        }, espGui)
    end

    ESP.pool[plr] = d
    return d
end

bind(RunService.RenderStepped:Connect(function()
    if destroyed then return end
    if not Config.EspEnabled then
        for plr in pairs(ESP.pool) do killEsp(plr) end
        return
    end
    local cam = getCam()
    if not cam then return end
    local vp = cam.ViewportSize
    local seen = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        local isMate = sameTeam(plr)
        local hum0 = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if isEnemy(plr) or (Config.EspTeammates and isMate and plr ~= LP and hum0 and hum0.Health > 0) then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            if hum and root and head then
                local d = ESP.pool[plr] or buildEsp(plr)
                seen[plr] = true

                local col
                if LockedPlayer == plr then
                    col = Color3.fromRGB(255, 220, 60)
                elseif isMate then
                    col = Config.EspTeamColor
                else
                    col = enemyColor()
                end
                d.stroke.Color = col
                d.fill.BackgroundColor3 = col
                d.name.TextColor3 = col
                d.tracer.BackgroundColor3 = col
                if d.hl then
                    d.hl.FillColor = col
                    d.hl.OutlineColor = col
                end

                if d.lastHealth and hum.Health < d.lastHealth and Config.Hitmarker then
                    hitmark.Visible = true
                    if hitSound then pcall(function() hitSound:Play() end) end
                    task.delay(0.12, function()
                        if hitmark and hitmark.Parent then hitmark.Visible = false end
                    end)
                end
                d.lastHealth = hum.Health

                local feet = root.Position - Vector3.new(0, 2.6, 0)
                local top = head.Position + Vector3.new(0, 0.45, 0)
                local a, onA = cam:WorldToViewportPoint(top)
                local b, onB = cam:WorldToViewportPoint(feet)
                local dist = (root.Position - cam.CFrame.Position).Magnitude

                if onA and onB and dist <= Config.EspMaxDistance then
                    local h = math.abs(b.Y - a.Y)
                    local w = h * 0.55
                    d.box.Visible = true
                    d.box.Position = UDim2.fromOffset(a.X - w / 2, a.Y)
                    d.box.Size = UDim2.fromOffset(w, h)
                    d.fill.Visible = Config.EspBox
                    d.stroke.Enabled = Config.EspBox
                    d.name.Visible = Config.EspName
                    d.name.Text = (isMate and "● " or "◆ ") .. plr.Name
                    d.hpBg.Visible = Config.EspHealth
                    local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    d.hpFill.Size = UDim2.new(1, 0, ratio, 0)
                    if isMate then
                        d.hpFill.BackgroundColor3 = Config.EspTeamColor
                    else
                        d.hpFill.BackgroundColor3 = ENEMY_COL:Lerp(Color3.fromRGB(90, 255, 140), ratio)
                    end

                    local tool = char:FindFirstChildOfClass("Tool")
                    local bits = {}
                    if Config.EspWeapon and tool then table.insert(bits, tool.Name) end
                    if Config.EspDistance then table.insert(bits, math.floor(dist) .. "m") end
                    d.info.Visible = #bits > 0
                    d.info.Text = table.concat(bits, "  •  ")

                    if Config.EspTracer then
                        local from = Vector2.new(vp.X / 2, vp.Y)
                        local to = Vector2.new(a.X + w / 2, a.Y + h / 2)
                        local vec = to - from
                        d.tracer.Visible = true
                        d.tracer.Position = UDim2.fromOffset(from.X, from.Y)
                        d.tracer.Size = UDim2.fromOffset(vec.Magnitude, 1)
                        d.tracer.Rotation = math.deg(math.atan2(vec.Y, vec.X))
                    else
                        d.tracer.Visible = false
                    end
                else
                    d.box.Visible = false
                    d.tracer.Visible = false
                end
            end
        end
    end

    for plr in pairs(ESP.pool) do
        if not seen[plr] then killEsp(plr) end
    end
end))

bind(RunService.RenderStepped:Connect(function(dt)
    if destroyed or not Config.CameraLock then return end
    local cam = getCam()
    local root = LockedPlayer and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not cam or not root then return end
    cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, root.Position), math.clamp(dt * 8, 0, 1))
end))

--// VISUAL page
local visPage = pages["VISUAL"]
section(visPage, "Players")
addToggle(visPage, "Enable ESP", "EspEnabled")
addToggle(visPage, "Boxes", "EspBox")
addToggle(visPage, "Highlight Glow", "EspHighlight")
addToggle(visPage, "Names", "EspName")
addToggle(visPage, "Health", "EspHealth")
addToggle(visPage, "Weapon", "EspWeapon")
addToggle(visPage, "Distance", "EspDistance")
addToggle(visPage, "Tracers", "EspTracer")
addToggle(visPage, "ESP Teammates", "EspTeammates")
addCycle(visPage, "Enemy Color", "EspColorName", { "Red", "Orange", "Yellow", "Green", "Blue", "Purple" })
addSlider(visPage, "ESP Distance", "EspMaxDistance", 50, 2000, 25)

section(visPage, "Overlay")
addToggle(visPage, "Crosshair", "Crosshair", function(v) crossWrap.Visible = v end)
addToggle(visPage, "Hitmarker", "Hitmarker")
addToggle(visPage, "Camera Lock", "CameraLock")

section(visPage, "Lock On")
local listHolder = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 116),
    BackgroundColor3 = Color3.fromRGB(20, 20, 30),
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, visPage)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, listHolder)
create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4) }, listHolder)
create("UIListLayout", { Padding = UDim.new(0, 3) }, listHolder)

local function refreshList()
    for _, c in ipairs(listHolder:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            local b = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundColor3 = (LockedPlayer == plr) and Color3.fromRGB(62, 50, 104) or Color3.fromRGB(28, 28, 40),
                AutoButtonColor = false,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = sameTeam(plr) and Config.EspTeamColor or ENEMY_COL,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "  " .. (sameTeam(plr) and "● " or "◆ ") .. plr.Name,
            }, listHolder)
            create("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
            b.MouseButton1Click:Connect(function()
                LockedPlayer = (LockedPlayer == plr) and nil or plr
                refreshList()
            end)
        end
    end
end
refreshList()

task.spawn(function()
    while not destroyed do
        task.wait(1.5)
        if visPage.Visible and main.Visible then refreshList() end
    end
end)

--// Keybinds
bind(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.MenuKey then
        main.Visible = not main.Visible
        miniIcon.Visible = false
    elseif input.KeyCode == Config.AimKey and Config.AimMode == "Toggle" then
        aimToggled = not aimToggled
    elseif input.KeyCode == Config.FireToggleKey then
        fireToggle = not fireToggle
        notify("auto fire " .. (fireToggle and "ON" or "OFF"))
    end
end))

--// Auto execute
local REPO = "awanmalikfahad698-dotcom/malekrivalscript"
local URL_CACHE = "Malek_autoexec_url.txt"

local function apiResolve()
    local ok, body = pcall(function()
        return game:HttpGet("https://api.github.com/repos/" .. REPO .. "/contents/")
    end)
    if not ok or type(body) ~= "string" then return nil end
    local ok2, list = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok2 or type(list) ~= "table" then return nil end
    for _, item in ipairs(list) do
        if type(item) == "table" and type(item.name) == "string" and item.name:sub(-4):lower() == ".lua" then
            return "https://raw.githubusercontent.com/" .. REPO .. "/main/" .. item.name:gsub(" ", "%%20")
        end
    end
    return nil
end

local function urlWorks(url)
    local ok, src = pcall(function() return game:HttpGet(url) end)
    return ok and type(src) == "string" and #src > 500
end

local function resolveUrl()
    local url = apiResolve()
    if not url and isfile and readfile and isfile(URL_CACHE) then
        local ok, cached = pcall(readfile, URL_CACHE)
        if ok and type(cached) == "string" and #cached > 20 then
            url = cached:gsub("%s+$", "")
        end
    end
    if not url then
        url = "https://raw.githubusercontent.com/" .. REPO .. "/main/malekrival.lua"
    end
    return url
end

function setupAutoExecute()
    local url = resolveUrl()
    if not urlWorks(url) then return false end
    if writefile then pcall(writefile, URL_CACHE, url) end
    local loader = 'loadstring(game:HttpGet("' .. url .. '"))()'
    getgenv().MalekSource = loader

    local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
    if q then pcall(q, loader) end

    if getworkspace and makefolder and writefile then
        pcall(function()
            local dir = getworkspace() .. "/autoexec"
            pcall(makefolder, dir)
            writefile(dir .. "/malek.lua", loader)
        end)
    end
    return true
end
setupAutoExecute()

if Config.Theme ~= "Purple" then applyTheme(Config.Theme) end

getgenv().Malek = { Unload = unload }
notify("malek script loaded")