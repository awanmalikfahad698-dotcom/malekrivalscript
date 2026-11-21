--// Keybinds
local function panic()
    Config.AimEnabled, Config.AutoShoot = false, false
    Config.AutoFarm, Config.AutoFarmLevel, Config.TpChase = false, false, false
    Config.FlyEnabled, Config.StickMode = false, false
    if flyActive then setFly(false) end
    if farmLevelToggle then farmLevelToggle.Refresh() end
    if farmMatchToggle then farmMatchToggle.Refresh() end
    if farmStatus then farmStatus.Text = "stage: idle" end
    notify("PANIC - everything off")
end

bind(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if Binds.capturing then return end

    if input.KeyCode == Config.MenuKey then
        setMenuOpen(not main.Visible)
        return
    elseif input.KeyCode == Config.PanicKey then
        panic()
        return
    elseif input.KeyCode == Config.FarmKey then
        Config.AutoFarmLevel = not Config.AutoFarmLevel
        if farmLevelToggle then farmLevelToggle.Refresh() end
        notify("level farm " .. (Config.AutoFarmLevel and "ON" or "OFF"))
    elseif input.KeyCode == Config.FarmMatchKey then
        Config.AutoFarm = not Config.AutoFarm
        if farmMatchToggle then farmMatchToggle.Refresh() end
        notify("match farm " .. (Config.AutoFarm and "ON" or "OFF"))
    elseif input.KeyCode == Config.AimKey and Config.AimMode == "Toggle" then
        aimToggled = not aimToggled
    elseif input.KeyCode == Config.FireToggleKey then
        fireToggle = not fireToggle
        notify("auto fire " .. (fireToggle and "ON" or "OFF"))
    elseif input.KeyCode == Config.FlyKey then
        if Config.FlyMode == "Toggle" and Config.FlyEnabled then
            if flyActive then setFly(false) else setFly(true) end
        end
    end

    local list = Binds.index[input.KeyCode]
    if list then
        for _, id in ipairs(list) do
            local fn = Binds.actions[id]
            if fn then pcall(fn) end
        end
    end
end))

bind(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if Config.FlyMode == "Hold" and Config.FlyEnabled and input.KeyCode == Config.FlyKey then
        setFly(true)
    end
end))

bind(UserInputService.InputEnded:Connect(function(input)
    if Config.FlyMode == "Hold" and input.KeyCode == Config.FlyKey then
        setFly(false)
    end
end))

bind(LP.CharacterAdded:Connect(function()
    task.wait(1)
    flyActive = false
    flyBV = nil
    flyBG = nil
    savedWalk = nil
    if Config.FlyEnabled and Config.FlyMode == "Toggle" then setFly(true) end
end))

--// Auto execute
local REPO = "awanmalikfahad698-dotcom/malekrivalscript"
local URL_CACHE = "Flitch_autoexec_url.txt"

local function resolveUrl()
    return "https://raw.githubusercontent.com/" .. REPO .. "/main/malekrival.lua"
end

local function urlWorks(url)
    local ok, src = pcall(function() return game:HttpGet(url) end)
    return ok and type(src) == "string" and #src > 200
end

function setupAutoExecute()
    local url = resolveUrl()
    if not urlWorks(url) then return false end
    if Compat.writefile then pcall(Compat.writefile, URL_CACHE, url) end
    local loader = 'loadstring(game:HttpGet("' .. url .. '?v=" .. tostring(tick())))()'
    getgenv().FlitchSource = loader

    local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
    if q then pcall(q, loader) end

    if Compat.getworkspace and Compat.makefolder and Compat.writefile then
        pcall(function()
            local dir = Compat.getworkspace() .. "/autoexec"
            pcall(Compat.makefolder, dir)
            Compat.writefile(dir .. "/flitch.lua", loader)
        end)
    end
    return true
end
setupAutoExecute()

--// Startup sequence
rebuildIndex()

if Config.Theme ~= "Purple" then pcall(applyTheme, Config.Theme) end

getgenv().Flitch = { Unload = unload }

task.spawn(function()
    TweenService:Create(splash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.12 }):Play()
    task.wait(0.18)

    TweenService:Create(splashTitle, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, -6),
        TextTransparency = 0,
    }):Play()
    local titleStroke = splashTitle:FindFirstChildOfClass("UIStroke")
    if titleStroke then
        TweenService:Create(titleStroke, TweenInfo.new(0.55), { Transparency = 0.45 }):Play()
    end

    task.wait(0.16)
    TweenService:Create(splashSub, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 50),
        TextTransparency = 0,
    }):Play()

    TweenService:Create(splashFill, TweenInfo.new(0.95, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 1, 0),
    }):Play()

    task.wait(1.0)

    TweenService:Create(splash, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(splashTitle, TweenInfo.new(0.3), { TextTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -26) }):Play()
    TweenService:Create(splashSub, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
    if titleStroke then
        TweenService:Create(titleStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
    end

    task.wait(0.3)
    setMenuOpen(true)
    task.wait(0.35)
    if splash then splash:Destroy() end
    notify("flitch hub loaded")
end)