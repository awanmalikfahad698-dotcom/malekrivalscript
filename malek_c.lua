--=====================================================================
--  TARGETING
--=====================================================================
local function findTarget()
    local char = LP.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    local cam = getCam()
    if not myRoot or not cam then return nil end

    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local maxRange = math.min(Config.MaxDistance, HARD_RANGE)
    local walls = Config.WallShoot

    local best, bestScore = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            local bone = Config.SniperMode and "Head" or Config.HitPart
            local part = plr.Character:FindFirstChild(bone)
                or plr.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local dist = (part.Position - myRoot.Position).Magnitude
                if dist <= maxRange then
                    local pos = part.Position + part.AssemblyLinearVelocity * Config.Prediction
                    local sp, onScreen = cam:WorldToViewportPoint(pos)
                    if onScreen and sp.Z > 0 then
                        local screen = Vector2.new(sp.X, sp.Y)
                        local d = (screen - center).Magnitude
                        if d <= Config.FOVRadius and d < bestScore then
                            if walls or not Config.VisibleCheck or isVisible(part) then
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
    if (t.part.Position - myRoot.Position).Magnitude > math.min(Config.MaxDistance, HARD_RANGE) then return false end
    if Config.VisibleCheck and not Config.WallShoot and not isVisible(t.part) then return false end
    local sp, onScreen = cam:WorldToViewportPoint(t.part.Position)
    if not onScreen then return false end
    local vp = cam.ViewportSize
    local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(vp.X / 2, vp.Y / 2)).Magnitude
    return d <= Config.FOVRadius * 1.2
end

local function sniperEquipped()
    local tool = equippedTool()
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

    if Config.Humanize and not sniper then
        local wobble = math.sin(tick() * 11) * 0.55 + (math.random() - 0.5) * 0.8
        move = move + Vector2.new(wobble, wobble * 0.6)
        if math.random() < 0.04 then return end
    end

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
    if not (Config.AimEnabled or Config.AutoFarm or Config.AutoFarmLevel) then return end
    if not (aimActive() or Config.AutoFarm or Config.AutoFarmLevel) then return end

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

    if t and t.part and targetStillValid(t) then
        aimAt(t.part, dt)
    end
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
        local wait = Config.ShootDelay
        if Config.Humanize then wait = wait * (0.75 + math.random() * 0.6) end
        task.wait(wait)
        if not destroyed and (Config.AutoShoot or Config.AutoFarm or Config.AutoFarmLevel) then
            local allowed
            if Config.AutoFarm or Config.AutoFarmLevel or Config.FireMode == "Always" then
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
                        local sp, onScreen = cam.WorldToViewportPoint(t.part.Position)
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

--=====================================================================
--  FARM LOOPS
--=====================================================================
local function anyEnemyAlive()
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then return true end
    end
    return false
end

task.spawn(function()
    while not destroyed do
        task.wait(0.4)
        if not destroyed and Config.AutoFarmLevel then
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                if Config.FarmRespawn then
                    clickKeywords({ "respawn", "redeploy", "play again" }, 1.2)
                end
            else
                if Config.FarmRequireWeapon and not hasWeapon() then
                    buyWeapon()
                elseif Config.FarmChase then
                    local plr, dist = nearestEnemy()
                    local root = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if root and dist and dist > 10 then
                        if Config.FlyEnabled and flyActive then
                            local dir = (root.Position - char.HumanoidRootPart.Position).Unit
                            if flyBV then flyBV.Velocity = dir * Config.FlySpeed end
                        else
                            pcall(function() hum:MoveTo(root.Position) end)
                        end
                    elseif hum.MoveDirection.Magnitude > 0 and not Config.FlyEnabled then
                        pcall(function() hum:MoveTo(hum.RootPart.Position) end)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while not destroyed do
        task.wait(1)
        if not destroyed and Config.AutoFarm then
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                if Config.FarmRespawn then
                    clickKeywords({ "respawn", "redeploy", "play again" }, 1.2)
                end
            elseif not anyEnemyAlive() then
                clickKeywords({ "play again", "rematch", "requeue", "queue", "next", "ready" }, 1.2)
            end
        end
    end
end)

task.spawn(function()
    while not destroyed do
        task.wait(1.5)
        if not destroyed then
            if Config.AutoLoadout and not hasWeapon() then buyWeapon() end
            if Config.AutoInventory then openInventory() end
            if Config.AutoOpenAll then openAllInInventory() end
        end
    end
end)

--// Visuals
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
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local mate = plr ~= LP and sameTeam(plr)
        if hum and hum.Health > 0 and (isEnemy(plr) or (mate and Config.EspTeammates)) then
            local b = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundColor3 = (LockedPlayer == plr) and Color3.fromRGB(62, 50, 104) or Color3.fromRGB(28, 28, 40),
                AutoButtonColor = false,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = mate and Config.EspTeamColor or ENEMY_COL,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "  " .. (mate and "● " or "◆ ") .. plr.Name,
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
    elseif input.KeyCode == Config.FlyKey then
        if Config.FlyMode == "Toggle" and Config.FlyEnabled then
            if flyActive then setFly(false) else setFly(true) end
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

bind(Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    flyActive = false
    flyBV = nil
    flyBG = nil
    savedWalk = nil
    if Config.FlyEnabled and Config.FlyMode == "Toggle" then setFly(true) end
end))

--// Auto execute
local REPO = "awanmalikfahad698-dotcom/malekrivalscript"
local URL_CACHE = "Malek_autoexec_url.txt"

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