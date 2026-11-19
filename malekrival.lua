--// Malek Script - Fixed & Improved Version
--// Features: Team Filter Fix, Full ESP, Smooth Aim, Better UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Config
local FILE = "MalekScript_Rivals_Fixed.json"

local Config = {
    MenuKey = Enum.KeyCode.RightControl,
    AimKey = Enum.KeyCode.Q,
    AimMode = "Hold", -- Hold or Toggle
    AimStyle = "Smooth",
    AimEnabled = false,
    Sticky = true,
    FOVRadius = 220,
    Smoothness = 6,
    Strength = 2157,
    TurnCap = 90,
    BulletSpeed = 300,
    Prediction = 0.85,
    MaxDistance = 500,
    HitPart = "Head",
    FireCone = 14,
    TeamCheck = true,
    MatchOnly = true,
    VisibleCheck = true,
    AutoShoot = false,
    AutoShootKey = Enum.KeyCode.E,
    ShootDelay = 0.06,
    FireMode = "Hold",
    FireToggleKey = Enum.KeyCode.F,
    AutoFarm = false,
    FarmRespawn = true,
    SniperMode = false,
    SniperRequireGun = true,
    SniperSpeed = 900,
    
    --// ESP Settings
    EspEnabled = false,
    EspBox = true,
    EspName = true,
    EspHealth = true,
    EspWeapon = true,
    EspDistance = true,
    EspTracer = false,
    EspHighlight = true,
    EspTeammates = false,
    EspMaxDistance = 600,
    EspColorName = "Red",
    EspTeamColor = Color3.fromRGB(90, 200, 255),
    
    --// UI Settings
    Crosshair = true,
    Hitmarker = true,
    CameraLock = false,
    FOVCircle = true,
    Watermark = true,
    Theme = "Purple"
}

--// Colors
local C_BG = Color3.fromRGB(109, 10, 16)
local C_PANEL = Color3.fromRGB(17, 17, 24)
local C_LINE = Color3.fromRGB(40, 49, 58)
local C_TEXT = Color3.fromRGB(234, 234, 244)
local C_SUB = Color3.fromRGB(138, 138, 164)
local C_ACCENT = Color3.fromRGB(124, 92, 255)
local C_ACCENT2 = Color3.fromRGB(0, 229, 255)
local C_OFF = Color3.fromRGB(42, 42, 58)

--// State
local LockedPlayer = nil
local fireToggle = false
local espFolder = Instance.new("Folder")
espFolder.Name = "MalekESP"
espFolder.Parent = CoreGui

local function get_gui_parent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and typeof(hui) == "Instance" then return hui end
    return CoreGui
end

--// Helper Functions
local function create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do 
        if not (k == "Parent" and parent) then
            inst[k] = v 
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function tween(obj, prop, val, time)
    local t = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {prop = val})
    t:Play()
    return t
end

--// Team Filtering Logic (Fixed)
local function is_teammate(player1, player2)
    if not Config.TeamCheck then return false end
    if not player1 or not player2 then return false end
    
    local team1 = player1.Team
    local team2 = player2.Team
    
    if not team1 or not team2 then return false end
    
    -- Compare Team Instances directly (more reliable than IDs)
    return team1 == team2
end

local function get_team_id(player)
    local team = player.Team
    if not team then return 0 end
    return team.TeamColor.Color -- Using color as a unique identifier proxy if needed, or just use Instance comparison
end

--// Load/Save Config
local function load_config()
    if not (isfile and isfile(FILE)) then return end
    local ok, raw = pcall(readfile, FILE)
    if not ok or type(raw) ~= "string" then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(data) ~= "table" then return end
    
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

local function save_config()
    local out = {}
    for k, v in pairs(Config) do
        if typeof(v) ~= "Instance" and typeof(v) ~= "Color3" then
            out[k] = typeof(v) == "EnumItem" and v.Name or v
        end
    end
    pcall(function() writefile(FILE, HttpService:JSONEncode(out)) end)
end

load_config()

--// UI Construction
local gui = create("ScreenGui", {
    Name = "MalekScript",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, get_gui_parent())

--// FOV Circle
local fovCircle = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(Config.FOVRadius * 2, Config.FOVRadius * 2),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = Config.FOVCircle,
    Parent = gui
})
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
    Text = "malek script • rivals",
    Visible = Config.Watermark,
    ZIndex = 2,
    Parent = gui
})
create("UIStroke", { Color = C_ACCENT, Thickness = 1, Transparency = 0.6 }, watermark)

--// Main Window
local main = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    Size = UDim2.fromOffset(340, 470),
    BackgroundColor3 = C_BG,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 5,
    Parent = gui
})
create("UICorner", { CornerRadius = UDim.new(0, 10) }, main)
local mainStroke = create("UIStroke", { Thickness = 1, Color = C_LINE }, main)
create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(30, 22, 56), Color3.fromRGB(12, 12, 20)), Rotation = 20 }, mainStroke)

--// Header
local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = C_PANEL,
    BorderSizePixel = 0,
    ZIndex = 6,
    Parent = main
})
create("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(30, 22, 56), Color3.fromRGB(12, 12, 20)),
    Rotation = 20,
}, header)

local title = create("TextLabel", {
    Position = UDim2.fromOffset(13, 12),
    Size = UDim2.fromOffset(200, 20),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C_TEXT,
    Text = "MALEK SCRIPT",
    ZIndex = 7,
    Parent = header
})
create("UIStroke", { Color = C_ACCENT, Thickness = 1, Transparency = 0.35 }, title)

create("TextLabel", {
    Position = UDim2.fromOffset(13, 25),
    Size = UDim2.fromOffset(220, 14),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C_SUB,
    Text = "RIVALS • FIXED • RIGHT CTRL",
    ZIndex = 7,
    Parent = header
})

--// Tabs System
local tabBar = create("Frame", {
    Position = UDim2.fromOffset(10, 54),
    Size = UDim2.new(1, -20, 0, 26),
    BackgroundTransparency = 1,
    ZIndex = 6,
    Parent = main
})

local contentHolder = create("Frame", {
    Position = UDim2.fromOffset(0, 88),
    Size = UDim2.new(1, 0, 1, -96),
    BackgroundTransparency = 1,
    ZIndex = 6,
    Parent = main
})

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
        Parent = contentHolder
    })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent = page
    })
    
    local function addToggle(text, configKey, infoText)
        local container = create("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            ZIndex = 7,
            Parent = page
        })
        
        local label = create("TextLabel", {
            Position = UDim2.fromOffset(0, 5),
            Size = UDim2.new(0.7, 0, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = C_TEXT,
            Text = text,
            Parent = container
        })
        
        local toggleBtn = create("TextButton", {
            Position = UDim2.new(1, -10, 0.5, -10),
            Size = UDim2.fromOffset(40, 20),
            BackgroundColor3 = Config[configKey] and C_ACCENT or C_OFF,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = C_TEXT,
            Text = "",
            Parent = container
        })
        create("UICorner", { CornerRadius = UDim.new(0, 4) }, toggleBtn)
        
        toggleBtn.MouseButton1Click:Connect(function()
            Config[configKey] = not Config[configKey]
            tween(toggleBtn, "BackgroundColor3", Config[configKey] and C_ACCENT or C_OFF, 0.2)
            save_config()
        end)
    end
    
    local function addSlider(text, configKey, min, max, step)
        local container = create("Frame", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            ZIndex = 7,
            Parent = page
        })
        
        local label = create("TextLabel", {
            Position = UDim2.fromOffset(0, 5),
            Size = UDim2.new(0.7, 0, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = C_TEXT,
            Text = string.format("%s (%d)", text, Config[configKey]),
            Parent = container
        })
        
        local sliderBg = create("Frame", {
            Position = UDim2.fromOffset(0, 25),
            Size = UDim2.new(1, 0, 0, 10),
            BackgroundColor3 = C_OFF,
            Parent = container
        })
        create("UICorner", { CornerRadius = UDim.new(0, 2) }, sliderBg)
        
        local sliderFill = create("Frame", {
            Size = UDim2.new((Config[configKey] - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = C_ACCENT,
            Parent = sliderBg
        })
        create("UICorner", { CornerRadius = UDim.new(0, 2) }, sliderFill)
        
        local mouseDown = false
        local updateSlider = function(input)
            local pos = input.Position.X
            local size = sliderBg.AbsoluteSize
            local percent = math.clamp((pos - sliderBg.AbsolutePosition.X) / size, 0, 1)
            local value = math.floor(min + (percent * (max - min)) / step) * step
            Config[configKey] = math.clamp(value, min, max)
            sliderFill.Size = UDim2.fromScale(percent, 1)
            label.Text = string.format("%s (%d)", text, Config[configKey])
            save_config()
        end
        
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                mouseDown = true
                updateSlider(input)
            end
        end)
        
        sliderBg.InputChanged:Connect(function(input)
            if mouseDown then
                updateSlider(input)
            end
        end)
        
        sliderBg.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                mouseDown = false
            end
        end)
    end

    return page
end

--// Build Tabs
local tabNames = {"Aimbot", "ESP", "Settings"}
for i, name in ipairs(tabNames) do
    local btn = create("TextButton", {
        Position = UDim2.fromOffset(i * 70, 0),
        Size = UDim2.fromOffset(60, 26),
        BackgroundColor3 = i == 1 and C_ACCENT or C_OFF,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = C_TEXT,
        Text = name,
        Parent = tabBar
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)
    
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        for _, b in pairs(tabButtons) do 
            b.BackgroundColor3 = C_OFF 
            b.TextColor3 = C_TEXT 
        end
        btn.BackgroundColor3 = C_ACCENT
        btn.TextColor3 = C_TEXT
        pages[i].Visible = true
    end)
    
    tabButtons[#tabButtons + 1] = btn
    pages[i] = buildPage(name, i, #tabNames)
end

--// Populate Pages
pages[1]:ClearAllChildren() -- Clear default padding frame to rebuild cleanly
local aimPage = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C_ACCENT,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = pages[1]
})
create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = aimPage })

addToggle("Enable Aimbot", "AimEnabled")
addToggle("Smooth Tracking", "AimStyle")
addSlider("Smoothness", "Smoothness", 1, 20, 1)
addSlider("FOV Radius", "FOVRadius", 50, 400, 10)
addToggle("Team Check", "TeamCheck")
addToggle("Visible Check", "VisibleCheck")
addToggle("Auto Shoot", "AutoShoot")

pages[2]:ClearAllChildren()
local espPage = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C_ACCENT,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = pages[2]
})
create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = espPage })

addToggle("Enable ESP", "EspEnabled")
addToggle("Show Boxes", "EspBox")
addToggle("Show Names", "EspName")
addToggle("Show Health", "EspHealth")
addToggle("Show Distance", "EspDistance")
addToggle("Show Teammates", "EspTeammates")

pages[3]:ClearAllChildren()
local settingsPage = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C_ACCENT,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = pages[3]
})
create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = settingsPage })

addToggle("Watermark", "Watermark")
addToggle("FOV Circle", "FOVCircle")

--// ESP Implementation
local espElements = {}

local function update_esp()
    if not Config.EspEnabled then
        for _, el in pairs(espElements) do
            el.Frame:Destroy()
        end
        table.clear(espElements)
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        -- Team Check Logic
        if Config.EspTeammates == false and is_teammate(LocalPlayer, player) then
            continue
        end

        local char = player.Character
        if not char or not char.Parent then continue end
        
        local head = char:FindFirstChild("Head")
        if not head then continue end

        local distance = (head.Position - Camera.CFrame.Position).Magnitude
        if distance > Config.EspMaxDistance then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end

        if not espElements[player] then
            local frame = create("Frame", {
                Position = UDim2.fromOffset(screenPos.X, screenPos.Y),
                Size = UDim2.fromOffset(20, 20),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = gui
            })
            
            if Config.EspBox then
                create("Frame", {
                    Position = UDim2.fromOffset(-20, -40),
                    Size = UDim2.fromOffset(40, 80),
                    BackgroundTransparency = 0.8,
                    BorderSizePixel = 0,
                    Parent = frame
                })
                create("UIStroke", { Color = C_ACCENT, Thickness = 1 }, frame)
            end
            
            if Config.EspName then
                create("TextLabel", {
                    Position = UDim2.fromOffset(-20, -50),
                    Size = UDim2.fromOffset(40, 10),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    TextColor3 = C_TEXT,
                    Text = player.Name,
                    Parent = frame
                })
            end
            
            espElements[player] = { Frame = frame }
        else
            espElements[player].Frame.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
        end
    end
end

RunService.RenderStepped:Connect(update_esp)

--// Aimbot Logic
local currentTarget = nil

local function get_nearest_target()
    local nearestDist = math.huge
    local nearestPlayer = nil
    local camCFrame = Camera.CFrame

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        -- Team Check
        if Config.TeamCheck and is_teammate(LocalPlayer, player) then continue end

        local char = player.Character
        if not char or not char.Parent then continue end

        local targetPart = char:FindFirstChild(Config.HitPart) or char:FindFirstChild("Head")
        if not targetPart then continue end

        local targetPos = targetPart.Position
        local dist = (targetPos - camCFrame.Position).Magnitude
        
        if dist > Config.MaxDistance then continue end

        -- Visible Check (Raycast)
        if Config.VisibleCheck then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local raycastResult = Workspace:Raycast(camCFrame.Position, (targetPos - camCFrame.Position).Unit * dist, rayParams)
            if raycastResult and raycastResult.Instance ~= targetPart then continue end
        end

        local diff = camCFrame.Position - targetPos
        local angle = camCFrame.UpVector:Dot(diff.Unit)
        
        if angle < nearestDist then
            nearestDist = angle
            nearestPlayer = player
        end
    end
    return nearestPlayer
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.MenuKey then
        main.Visible = not main.Visible
    end
    
    if input.KeyCode == Config.AimKey then
        Config.AimEnabled = true
    end
    
    if input.KeyCode == Config.FireToggleKey then
        fireToggle = not fireToggle
        Config.AutoShoot = fireToggle
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.AimKey then
        Config.AimEnabled = false
        currentTarget = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.AimEnabled and not main.Visible then
        local target = get_nearest_target()
        
        if target then
            local char = target.Character
            if char then
                local targetPart = char:FindFirstChild(Config.HitPart) or char:FindFirstChild("Head")
                if targetPart then
                    local goalCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                    
                    if Config.AimStyle == "Smooth" then
                        local currentRot = Camera.CFrame.Rotation
                        local goalRot = goalCFrame.Rotation
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * currentRot:Lerp(goalRot, 1 / Config.Smoothness)
                    else
                        Camera.CFrame = goalCFrame
                    end
                    
                    if Config.AutoShoot or fireToggle then
                        -- Simple click simulation
                        VirtualInputManager:SendMouseClickEvent(0, 0, true, game.Workspace.CurrentCamera)
                        task.wait(Config.ShootDelay)
                    end
                end
            end
        else
            -- Optional: Return camera slowly or stay locked? Usually best to stay locked until target lost
        end
    end
end)

--// Cleanup
game:BindToClose(function()
    save_config()
end)