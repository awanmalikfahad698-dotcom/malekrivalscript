--[[
    ███████╗██╗     ██╗████████╗ ██████╗██╗  ██╗
    ██╔════╝██║     ██║╚══██╔══╝██╔════╝██║  ██║
    █████╗  ██║     ██║   ██║   ██║     ███████║
    ██╔══╝  ██║     ██║   ██║   ██║     ██╔══██║
    ██║     ███████╗██║   ██║   ╚██████╗██║  ██║
    ╚═╝     ╚══════╝╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝
            H U B   •   R I V A L S   •   X E N O
    Menu: RIGHT CTRL    Panic: P            (part A1 / core)
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

local unpack = unpack or table.unpack
local LP = Players.LocalPlayer

--// Re-exec guard
if getgenv().Flitch and getgenv().Flitch.Unload then
    pcall(getgenv().Flitch.Unload)
end

local destroyed = false
local connections = {}
local function bind(conn)
    table.insert(connections, conn)
    return conn
end

--// Executor compatibility
local Compat = {
    getconnections = (typeof(getconnections) == "function") and getconnections or nil,
    firesignal     = (typeof(firesignal) == "function") and firesignal or nil,
    keypress       = (typeof(keypress) == "function") and keypress or nil,
    mouseMove      = (typeof(mousemoverel) == "function") and mousemoverel or nil,
    mouse1click    = (typeof(mouse1click) == "function") and mouse1click or nil,
    writefile      = (typeof(writefile) == "function") and writefile or nil,
    readfile       = (typeof(readfile) == "function") and readfile or nil,
    isfile         = (typeof(isfile) == "function") and isfile or nil,
    delfile        = (typeof(delfile) == "function") and delfile or nil,
    makefolder     = (typeof(makefolder) == "function") and makefolder or nil,
    getworkspace   = (typeof(getworkspace) == "function") and getworkspace or nil,
    setclipboard   = (typeof(setclipboard) == "function") and setclipboard or nil,
}

local CLICK_PRIORITY = { "Activated", "MouseButton1Click", "MouseButton1Up", "MouseButton1Down" }
local signalWorks = false

-- every click event gets real coordinates; handlers expect (x, y) on all of them
local function fireConnections(sig, args)
    if not Compat.getconnections then return false end
    local okc, conns = pcall(Compat.getconnections, sig)
    if not okc or type(conns) ~= "table" or #conns == 0 then return false end
    local fired = false
    for _, c in ipairs(conns) do
        if c then
            local ok = pcall(function()
                if c.Fire then
                    c:Fire(unpack(args))
                elseif c.fire then
                    c.fire(unpack(args))
                end
            end)
            if ok then fired = true end
        end
    end
    return fired
end

-- synthetic click: move to the point, click, stay there (no snap-back)
local function vimClickAt(pos)
    local before = UserInputService:GetMouseLocation()
    local delta = pos - before
    if Compat.mouseMove and delta.Magnitude > 1 then
        pcall(Compat.mouseMove, delta.X, delta.Y)
        task.wait(0.02)
    end
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
    end)
end

local function fireOn(inst)
    local ax, ay = inst.AbsolutePosition.X, inst.AbsolutePosition.Y
    for _, ev in ipairs(CLICK_PRIORITY) do
        local sig = inst[ev]
        if sig then
            if fireConnections(sig, { ax, ay }) then
                signalWorks = true
                return true
            end
            if Compat.firesignal then
                if pcall(Compat.firesignal, sig) then
                    signalWorks = true
                    return true
                end
            end
        end
    end
    return false
end

function Compat.click(btn)
    if not btn then return false end
    if fireOn(btn) then return true end
    local parent = btn.Parent
    if parent and parent:IsA("GuiButton") and fireOn(parent) then return true end
    pcall(vimClickAt, btn.AbsolutePosition + btn.AbsoluteSize / 2)
    return true
end

function Compat.pressKey(kc)
    if Compat.keypress then
        if pcall(Compat.keypress, kc) then return true end
    end
    return pcall(function()
        VirtualInputManager:SendKeyEvent(true, kc, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, kc, false, game)
    end)
end

--// Config
local FILE = "FlitchHub_Rivals.json"

local SLOT_KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three }

local Config = {
    MenuKey          = Enum.KeyCode.RightControl,
    PanicKey         = Enum.KeyCode.P,
    FarmKey          = Enum.KeyCode.K,
    FarmMatchKey     = Enum.KeyCode.L,
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
    FarmForceAim     = true,
    FarmDebug        = false,
    AutoMode         = true,
    FarmMode         = "Auto",
    PickMap          = true,
    MapName          = "",
    QueueDelay       = 2,
    RoundGate        = true,
    RoundGrace       = 5,
    WeaponCycle      = true,
    AutoReload       = true,
    MinAmmo          = 1,
    SwapAfterShots   = 8,
    TpChase          = true,
    TpStep           = 6,
    TpRate           = 0.12,
    TpStop           = 8,
    TpFace           = true,
    TpVertical       = true,
    AutoLoadout      = false,
    LoadoutWeapon    = "Rifle",
    LoadoutSlot      = "0",
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
    WallWalk         = false,
    Retreat          = true,
    RetreatHealth    = 30,
    RetreatDistance  = 80,
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
    MouseFallback    = false,
    AimPauseMenu     = true,
    Theme            = "Purple",
    Binds            = {},
}

local LockedPlayer = nil
local fireToggle = false
local espGui
local setupAutoExecute

local function loadConfig()
    if not (Compat.isfile and Compat.readfile) then return end
    local exists = pcall(Compat.isfile, FILE)
    if not exists then return end
    local ok, raw = pcall(Compat.readfile, FILE)
    if not ok or type(raw) ~= "string" then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return end
    for k, v in pairs(data) do
        local default = Config[k]
        if default ~= nil and k ~= "Binds" then
            if typeof(default) == "EnumItem" and type(v) == "string" then
                Config[k] = Enum.KeyCode[v] or default
            elseif type(v) == type(default) then
                Config[k] = v
            end
        end
    end
    if type(data.Binds) == "table" then
        for k, v in pairs(data.Binds) do
            if type(k) == "string" and type(v) == "string" and Enum.KeyCode[v] then
                Config.Binds[k] = v
            end
        end
    end
end

local saveQueued = false
local function save()
    if not Compat.writefile then return end
    if saveQueued then return end
    saveQueued = true
    task.delay(1, function()
        saveQueued = false
        local out = {}
        for k, v in pairs(Config) do
            if k ~= "Binds" and typeof(v) ~= "Instance" and typeof(v) ~= "Color3" then
                out[k] = typeof(v) == "EnumItem" and v.Name or v
            end
        end
        local binds = {}
        for k, v in pairs(Config.Binds) do binds[k] = v end
        out.Binds = binds
        pcall(Compat.writefile, FILE, HttpService:JSONEncode(out))
    end)
end

loadConfig()

--// Colors
local C_BG      = Color3.fromRGB(9, 9, 13)
local C_PANEL   = Color3.fromRGB(17, 17, 24)
local C_LINE    = Color3.fromRGB(44, 41, 54)
local C_TEXT    = Color3.fromRGB(236, 233, 241)
local C_SUB     = Color3.fromRGB(140, 136, 158)
local C_ACCENT  = Color3.fromRGB(255, 74, 110)
local C_ACCENT2 = Color3.fromRGB(255, 170, 80)
local C_OFF     = Color3.fromRGB(42, 42, 56)

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

local function create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function makeRoot(name, order)
    local candidates = {}
    local ok, hui = pcall(function() return gethui() end)
    if ok and typeof(hui) == "Instance" then table.insert(candidates, hui) end
    table.insert(candidates, CoreGui)
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then table.insert(candidates, pg) end

    for _, parent in ipairs(candidates) do
        local okc, inst = pcall(function()
            return create("ScreenGui", {
                Name = name,
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                DisplayOrder = order,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            }, parent)
        end)
        if okc and inst then return inst end
    end
end

--// Root
local gui = makeRoot("FlitchHub", 999)

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
    Text = "flitch hub  •  rivals",
    Visible = Config.Watermark,
    ZIndex = 2,
}, gui)
create("UIStroke", { Color = C_ACCENT, Thickness = 1, Transparency = 0.6 }, watermark)

--// Window
local main = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    Size = UDim2.fromOffset(360, 480),
    BackgroundColor3 = C_BG,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false,
    ZIndex = 5,
}, gui)
create("UICorner", { CornerRadius = UDim.new(0, 10) }, main)
local mainStroke = create("UIStroke", { Thickness = 1, Color = C_LINE }, main)
create("UIGradient", { Color = ColorSequence.new(C_ACCENT, C_ACCENT2) }, mainStroke)
local mainScale = create("UIScale", { Scale = 1 }, main)

--// Startup splash
local splash = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(5, 5, 8),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 60,
}, gui)

local splashTitle = create("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 26),
    Size = UDim2.fromOffset(320, 44),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    TextSize = 40,
    TextColor3 = C_TEXT,
    Text = "FLITCH",
    TextTransparency = 1,
    ZIndex = 61,
}, splash)
create("UIStroke", { Color = C_ACCENT, Thickness = 1, Transparency = 1 }, splashTitle)

local splashSub = create("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 54),
    Size = UDim2.fromOffset(320, 18),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = C_ACCENT2,
    Text = "H U B   •   R I V A L S",
    TextTransparency = 1,
    ZIndex = 61,
}, splash)

local splashBar = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 82),
    Size = UDim2.fromOffset(190, 3),
    BackgroundColor3 = Color3.fromRGB(34, 32, 44),
    BorderSizePixel = 0,
    ZIndex = 61,
}, splash)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, splashBar)

local splashFill = create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C_ACCENT,
    BorderSizePixel = 0,
    ZIndex = 62,
}, splashBar)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, splashFill)
create("UIGradient", { Color = ColorSequence.new(C_ACCENT, C_ACCENT2) }, splashFill)

--// Minimized icon
local miniIcon = create("TextButton", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    Size = UDim2.fromOffset(46, 46),
    BackgroundColor3 = C_BG,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBlack,
    TextSize = 19,
    TextColor3 = C_ACCENT,
    Text = "F",
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
    Color = ColorSequence.new(Color3.fromRGB(48, 20, 30), Color3.fromRGB(12, 12, 18)),
    Rotation = 20,
}, header)

local title = create("TextLabel", {
    Position = UDim2.fromOffset(12, 6),
    Size = UDim2.fromOffset(220, 20),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C_TEXT,
    Text = "FLITCH HUB",
    ZIndex = 7,
}, header)
create("UIStroke", { Color = C_ACCENT, Thickness = 1, Transparency = 0.35 }, title)

create("TextLabel", {
    Position = UDim2.fromOffset(13, 25),
    Size = UDim2.fromOffset(230, 14),
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