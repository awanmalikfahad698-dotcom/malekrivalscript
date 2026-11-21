--// Themes
local THEMES = {
    Purple = { accent = Color3.fromRGB(255, 74, 110), accent2 = Color3.fromRGB(255, 170, 80), bg = Color3.fromRGB(9, 9, 13), panel = Color3.fromRGB(17, 17, 24), line = Color3.fromRGB(44, 41, 54), text = Color3.fromRGB(236, 233, 241), sub = Color3.fromRGB(140, 136, 158), off = Color3.fromRGB(42, 42, 56), header = Color3.fromRGB(48, 20, 30), tabOn = Color3.fromRGB(62, 26, 38) },
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
        for k, v in pairs(THEMES.Purple) do
            if c == v then return to[k] end
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
                kps[#kps + 1] = ColorSequenceKeypoint.new(kp.Time, map(kp.Value))
            end
            if #kps >= 2 then o.Color = ColorSequence.new(kps) end
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

--// Menu open / close
local function setMenuOpen(state)
    if state then
        miniIcon.Visible = false
        main.Visible = true
        main.BackgroundTransparency = 1
        mainScale.Scale = 0.94
        TweenService:Create(main, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.04 }):Play()
        TweenService:Create(mainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    else
        TweenService:Create(mainScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.94 }):Play()
        local t = TweenService:Create(main, TweenInfo.new(0.16), { BackgroundTransparency = 1 })
        t:Play()
        t.Completed:Connect(function()
            if mainScale.Scale < 0.96 then main.Visible = false end
        end)
    end
end

--// Keybind registry
local Binds = { actions = {}, index = {}, chips = {}, capturing = nil }

local function rebuildIndex()
    Binds.index = {}
    for id, name in pairs(Config.Binds) do
        local kc = Enum.KeyCode[name]
        if kc and Binds.actions[id] then
            Binds.index[kc] = Binds.index[kc] or {}
            table.insert(Binds.index[kc], id)
        end
    end
end

local function setBind(id, kc)
    if kc then Config.Binds[id] = kc.Name else Config.Binds[id] = nil end
    local chip = Binds.chips[id]
    if chip then
        chip.Text = kc and kc.Name or "—"
        chip.TextColor3 = kc and C_ACCENT2 or C_SUB
    end
    rebuildIndex()
    save()
end

local function keyChip(parent, id, pos, size)
    local chip = create("TextButton", {
        Position = pos or UDim2.new(1, -104, 0.5, -9),
        Size = size or UDim2.fromOffset(34, 18),
        BackgroundColor3 = Color3.fromRGB(30, 30, 42),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Config.Binds[id] and C_ACCENT2 or C_SUB,
        Text = Config.Binds[id] or "—",
        ZIndex = 8,
    }, parent)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, chip)
    Binds.chips[id] = chip
    chip.MouseButton1Click:Connect(function()
        if Binds.capturing == id then
            Binds.capturing = nil
            chip.Text = Config.Binds[id] or "—"
            return
        end
        if Binds.capturing then return end
        Binds.capturing = id
        chip.Text = "…"
    end)
    return chip
end

bind(UserInputService.InputBegan:Connect(function(input)
    if not Binds.capturing then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local id = Binds.capturing
    Binds.capturing = nil
    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
        setBind(id, nil)
    else
        setBind(id, input.KeyCode)
    end
end))

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

local function hint(parent, text)
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = C_SUB,
        Text = text,
    }, parent)
end

local function addToggle(parent, text, key, onChange)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
    create("TextLabel", {
        Size = UDim2.new(1, -116, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_TEXT,
        Text = text,
    }, row)

    local id = "t:" .. key
    keyChip(row, id)

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

    local function apply(v)
        Config[key] = v
        refresh()
        if onChange then onChange(v) end
        save()
    end

    btn.MouseButton1Click:Connect(function() apply(not Config[key]) end)

    Binds.actions[id] = function()
        apply(not Config[key])
        notify(text .. (Config[key] and "  ON" or "  OFF"))
    end

    refresh()
    return { Refresh = refresh }
end

local function addSlider(parent, text, key, min, max, step, onChange)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, parent)
    local label = create("TextLabel", {
        Size = UDim2.new(1, -44, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_TEXT,
        Text = text .. "  [" .. tostring(Config[key]) .. "]",
    }, row)

    local chip = keyChip(row, "s:" .. key, UDim2.new(1, -40, 0, 0), UDim2.fromOffset(34, 16))

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
        rel = math.clamp(rel, 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        local val = min + (max - min) * rel
        val = math.floor(val / step + 0.5) * step
        Config[key] = val
        label.Text = text .. "  [" .. string.format("%.2f", val) .. "]"
        if onChange then onChange(val) end
        save()
    end

    local function fromX(x)
        paint((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1))
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            fromX(input.Position.X)
            local move
            move = UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
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

    Binds.actions["s:" .. key] = function()
        local nextVal = Config[key] + step
        if nextVal > max + 0.0001 then
            paint(0)
        else
            paint((nextVal - min) / (max - min))
        end
    end

    paint((Config[key] - min) / (max - min))
    return { Refresh = function() paint((Config[key] - min) / (max - min)) end, Chip = chip }
end

local function addCycle(parent, text, key, options)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
    create("TextLabel", {
        Size = UDim2.new(1, -136, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_TEXT,
        Text = text,
    }, row)

    local id = "c:" .. key
    keyChip(row, id, UDim2.new(1, -130, 0.5, -9))

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

    local function next_()
        local idx = 1
        for i, v in ipairs(options) do
            if v == Config[key] then idx = i break end
        end
        idx = (idx % #options) + 1
        Config[key] = options[idx]
        btn.Text = options[idx]
        save()
    end

    btn.MouseButton1Click:Connect(next_)
    Binds.actions[id] = next_
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
    return btn
end

local function addTextBox(parent, text, key, placeholder)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, parent)
    create("TextLabel", {
        Size = UDim2.new(1, -140, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C_TEXT,
        Text = text,
    }, row)
    local box = create("TextBox", {
        Position = UDim2.new(1, -134, 0.5, -11),
        Size = UDim2.fromOffset(134, 22),
        BackgroundColor3 = Color3.fromRGB(30, 30, 46),
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C_TEXT,
        PlaceholderText = placeholder or "",
        Text = tostring(Config[key]),
        ClearTextOnFocus = false,
    }, row)
    create("UICorner", { CornerRadius = UDim.new(0, 5) }, box)
    box.FocusLost:Connect(function()
        Config[key] = box.Text
        save()
    end)
    return box
end

local function smallButton(parent, text, cb)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, parent)
    local b = create("TextButton", {
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundColor3 = Color3.fromRGB(28, 28, 42),
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C_TEXT,
        Text = text,
    }, row)
    create("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
    b.MouseButton1Click:Connect(cb)
    local id = "b:" .. text
    keyChip(row, id, UDim2.new(1, -34, 0.5, -9))
    Binds.actions[id] = cb
    return b
end

--// Watermark tap
local wmBtn = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, watermark)
wmBtn.MouseButton1Click:Connect(function()
    setMenuOpen(not main.Visible)
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
hint(aimPage, "Adds micro drift to the crosshair and jitters fire timing so input is not perfectly uniform.")

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
addToggle(miscPage, "Mouse Click Fallback", "MouseFallback")
addToggle(miscPage, "Pause Aim In Menu", "AimPauseMenu")

section(miscPage, "Hotkeys")
addKeybind(miscPage, "Panic (all off)", "PanicKey")
addKeybind(miscPage, "Toggle Level Farm", "FarmKey")
addKeybind(miscPage, "Toggle Match Farm", "FarmMatchKey")
hint(miscPage, "Every row has a key chip. Tap the chip, press a key. Escape or Backspace clears it. Slider chips step the value up.")

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

smallButton(miscPage, "Dump Visible Buttons", function()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return notify("no PlayerGui") end
    local n = 0
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("GuiButton") and d.Visible and d.AbsoluteSize.Magnitude > 0 then
            print(d.Name .. " :: " .. ((d.Text ~= "" and d.Text) or ""))
            n = n + 1
            if n >= 40 then break end
        end
    end
    notify(n .. " buttons printed")
end)

smallButton(miscPage, "Reset Settings", function()
    if Compat.delfile and Compat.isfile then pcall(Compat.delfile, FILE) end
    Config.Binds = {}
    for _, chip in pairs(Binds.chips) do
        chip.Text = "—"
        chip.TextColor3 = C_SUB
    end
    rebuildIndex()
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
    Config.TpChase, Config.TpFace, Config.TpVertical = true, true, true
    Config.TpStep, Config.TpRate, Config.TpStop = 6, 0.12, 8
    Config.AutoMode, Config.FarmMode, Config.FarmForceAim = true, "Auto", true
    Config.PickMap, Config.RoundGate, Config.WeaponCycle = true, true, true
    Config.RoundGrace, Config.MinAmmo, Config.AutoReload = 5, 1, true
    Config.SwapAfterShots, Config.MapName = 8, ""
    Config.WallWalk, Config.Retreat, Config.LoadoutSlot = false, true, "0"
    Config.RetreatHealth, Config.RetreatDistance = 30, 80
    Config.FarmDebug, Config.QueueDelay = false, 2
    Config.EspColorName = "Red"
    fovCircle.Size = UDim2.fromOffset(440, 440)
    applyTheme("Purple")
    save()
    notify("settings reset")
end)

smallButton(miscPage, "Unload Script", function()
    if getgenv().Flitch and getgenv().Flitch.Unload then getgenv().Flitch.Unload() end
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
                if not iconMoved then setMenuOpen(true) end
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
local function setMinimized()
    miniIcon.Position = UDim2.new(
        main.Position.X.Scale, main.Position.X.Offset,
        main.Position.Y.Scale, main.Position.Y.Offset
    )
    main.Visible = false
    miniIcon.Visible = true
end
minimizeBtn.MouseButton1Click:Connect(setMinimized)

--// Unload
local function unload()
    destroyed = true
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    if gui then gui:Destroy() end
    if espGui then espGui:Destroy() end
    getgenv().Flitch = nil
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