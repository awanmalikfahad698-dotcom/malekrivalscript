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
--  UI SCANNER  (signal firing, no cursor movement)
--=====================================================================

local uiCooldown = 0
local nearestEnemy
local farmStatus
local flyBV, flyBG, flyActive
local farmLevelToggle, farmMatchToggle

local function isShown(inst)
    local cur = inst
    while cur and cur ~= game do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("ScreenGui") and cur.Enabled == false then return false end
        cur = cur.Parent
    end
    if inst.AbsoluteSize.X < 4 or inst.AbsoluteSize.Y < 4 then return false end
    return true
end

local function buttonText(btn)
    local bits = {}
    if btn:IsA("TextButton") and btn.Text ~= "" then bits[#bits + 1] = btn.Text end
    for _, d in ipairs(btn:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then bits[#bits + 1] = d.Text end
    end
    return table.concat(bits, " "):lower()
end

local function collectButtons()
    local out = {}
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return out end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextButton") or d:IsA("ImageButton") then
            if isShown(d) then out[#out + 1] = d end
        end
    end
    return out
end

local CLICK_EVENTS = { "MouseButton1Down", "MouseButton1Click", "MouseButton1Up", "Activated" }

local function fireSignal(btn)
    local fired = false

    if getconnections then
        for _, ev in ipairs(CLICK_EVENTS) do
            local sig = btn[ev]
            if sig then
                local ok, conns = pcall(getconnections, sig)
                if ok and type(conns) == "table" then
                    for _, c in ipairs(conns) do
                        if c and c.Fire then
                            local args = (ev == "Activated")
                                and { btn.AbsolutePosition.X, btn.AbsolutePosition.Y }
                                or {}
                            pcall(function() c:Fire(unpack(args)) end)
                            fired = true
                        end
                    end
                end
            end
        end
    end

    if not fired and firesignal then
        for _, ev in ipairs({ "MouseButton1Click", "Activated" }) do
            if btn[ev] then
                pcall(firesignal, btn[ev])
                fired = true
            end
        end
    end

    return fired
end

local function pressButton(btn)
    uiCooldown = tick()
    if fireSignal(btn) then return true end

    local wasOpen = main.Visible
    if wasOpen then main.Visible = false end
    local p = btn.AbsolutePosition + btn.AbsoluteSize / 2
    local ok = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 1)
        task.wait(0.04)
        VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 1)
    end)
    task.delay(0.12, function()
        if wasOpen and main then main.Visible = true end
    end)
    return ok
end

local function clickKeywords(keywords, gap)
    if tick() - uiCooldown < (gap or 0.6) then return false end
    for _, d in ipairs(collectButtons()) do
        local txt = buttonText(d)
        for _, kw in ipairs(keywords) do
            if kw ~= "" and txt:find(kw, 1, true) then
                return pressButton(d)
            end
        end
    end
    return false
end

local function pressInNamed(namePart, pool)
    local hits = {}
    for _, d in ipairs(pool or collectButtons()) do
        local cur = d
        while cur and cur ~= game do
            if cur.Name:lower():find(namePart, 1, true) then
                hits[#hits + 1] = d
                break
            end
            cur = cur.Parent
        end
    end
    if #hits == 0 then return false end
    return pressButton(hits[math.random(1, #hits)])
end

local function equippedTool()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Tool")
end

local WEAPON_ALIASES = {
    Rifle   = { "rifle", "ak", "m4", "carbine", "ar" },
    SMG     = { "smg", "uzi", "mp5", "mac", "p90", "vector" },
    Shotgun = { "shotgun", "pump", "spas", "judge", "sawn" },
    Sniper  = { "sniper", "awp", "railgun", "marksman", "kar", "barrett" },
    Pistol  = { "pistol", "deagle", "revolver", "glock", "magnum" },
}

local function hasWeapon()
    local tool = equippedTool()
    if not tool then return false end
    local n = tool.Name:lower()
    for _, list in pairs(WEAPON_ALIASES) do
        for _, w in ipairs(list) do
            if n:find(w, 1, true) then return true end
        end
    end
    return true
end

local function buyWeapon()
    if hasWeapon() then return true end
    local aliases = WEAPON_ALIASES[Config.LoadoutWeapon] or WEAPON_ALIASES.Rifle
    local keys = { "buy", "purchase", "equip", "select" }
    for _, w in ipairs(aliases) do
        keys[#keys + 1] = w
    end
    return clickKeywords(keys, 0.5)
end

local function openInventory()
    clickKeywords({ "inventory", "loadout", "backpack", "bag", "shop", "store" }, 1.2)
end

local function openAllInInventory()
    if tick() - uiCooldown < 0.4 then return end
    for _, d in ipairs(collectButtons()) do
        local txt = buttonText(d)
        if txt:find("open", 1, true) or txt:find("claim", 1, true)
            or txt:find("collect", 1, true) or txt:find("case", 1, true)
            or txt:find("crate", 1, true) then
            pressButton(d)
            return
        end
    end
end

--// matchmaking
local MODE_KEYS = {
    ["1v1"] = { "1v1", "1 v 1", "solo", "duel" },
    ["2v2"] = { "2v2", "2 v 2", "duo" },
    ["3v3"] = { "3v3", "3 v 3", "trio" },
}
local PLAY_KEYS = { "play", "queue", "join", "find match", "start", "battle", "ready", "search", "match", "deploy" }

local function pickMode()
    if Config.FarmMode ~= "Auto" then return Config.FarmMode end
    return "1v1"
end

local function queueMatch()
    if tick() - uiCooldown < Config.QueueDelay then return false end
    local mode = pickMode()
    local mkeys = MODE_KEYS[mode]
    local buttons = collectButtons()

    if mkeys then
        for _, d in ipairs(buttons) do
            local txt = buttonText(d)
            for _, kw in ipairs(mkeys) do
                if txt:find(kw, 1, true) then
                    pressButton(d)
                    break
                end
            end
        end
    end

    if Config.PickMap then
        task.delay(0.12, function()
            if not destroyed then pressInNamed("map", buttons) end
        end)
    end

    task.delay(0.3, function()
        if destroyed then return end
        for _, d in ipairs(collectButtons()) do
            local txt = buttonText(d)
            for _, kw in ipairs(PLAY_KEYS) do
                if txt:find(kw, 1, true) then
                    pressButton(d)
                    return
                end
            end
        end
    end)

    return true
end

bind(LP.Idled:Connect(function()
    if not Config.AntiAfk then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

task.spawn(function()
    while not destroyed do
        local base = math.max(Config.AntiAfkInterval, 10)
        task.wait(base + math.random() * 8)
        if not destroyed and Config.AntiAfk then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                task.wait(0.08)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            end)
        end
    end
end)

--=====================================================================
--  TELEPORT ENGINE
--=====================================================================
local function tpToEnemy()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local plr = nearestEnemy()
    local root = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not root then return false end
    local behind = root.CFrame.LookVector * -(Config.TpStop * 0.6)
    hrp.CFrame = CFrame.lookAt(root.Position + behind + Vector3.new(0, 2, 0), root.Position)
    return true
end

task.spawn(function()
    while not destroyed do
        task.wait(Config.TpRate)
        if not destroyed and Config.TpChase and (Config.AutoFarm or Config.AutoFarmLevel) and not flyActive then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local plr, dist = nearestEnemy()
                local root = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if root and dist and dist > Config.TpStop then
                    local goal = Config.TpVertical
                        and Vector3.new(root.Position.X, root.Position.Y + 2, root.Position.Z)
                        or Vector3.new(root.Position.X, hrp.Position.Y, root.Position.Z)
                    local delta = goal - hrp.Position
                    if delta.Magnitude > 0.05 then
                        local step = math.min(Config.TpStep, dist - Config.TpStop)
                        local nextPos = hrp.Position + delta.Unit * step
                        hrp.CFrame = Config.TpFace
                            and CFrame.lookAt(nextPos, root.Position)
                            or CFrame.new(nextPos)
                    end
                end
            end
        end
    end
end)

--=====================================================================
--  FARM PAGE
--=====================================================================
local farmPage = pages["FARM"]
section(farmPage, "Match Farm")
farmMatchToggle = addToggle(farmPage, "Auto Farm Match", "AutoFarm")
addToggle(farmPage, "Auto Respawn", "FarmRespawn")

section(farmPage, "Level Farm")
farmLevelToggle = addToggle(farmPage, "Auto Farm Level", "AutoFarmLevel")
addToggle(farmPage, "Walk Chase (TP off)", "FarmChase")
addToggle(farmPage, "Need Weapon First", "FarmRequireWeapon")
addToggle(farmPage, "Force Aim On Target", "FarmForceAim")
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = C_SUB,
    Text = "Queues a match, buys a gun, hops to the nearest enemy, snaps the camera onto them, fires, respawns, repeats.",
}, farmPage)

section(farmPage, "Matchmaking")
addToggle(farmPage, "Auto Queue", "AutoMode")
addCycle(farmPage, "Game Mode", "FarmMode", { "Auto", "1v1", "2v2", "3v3" })
addToggle(farmPage, "Pick A Map", "PickMap")
smallButton(farmPage, "Queue Now", function()
    if queueMatch() then notify("queueing " .. pickMode()) else notify("no queue button") end
end)

section(farmPage, "Teleport Chase")
addToggle(farmPage, "Teleport To Enemy", "TpChase")
addSlider(farmPage, "Step Size", "TpStep", 2, 40, 1)
addSlider(farmPage, "Hop Interval", "TpRate", 0.05, 0.6, 0.01)
addSlider(farmPage, "Stop Distance", "TpStop", 3, 40, 1)
addToggle(farmPage, "Face Target", "TpFace")
addToggle(farmPage, "Match Height", "TpVertical")
smallButton(farmPage, "Teleport To Enemy Now", function()
    if tpToEnemy() then notify("teleported") else notify("no enemy") end
end)
farmStatus = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C_ACCENT2,
    Text = "stage: idle",
}, farmPage)

section(farmPage, "Loadout")
addToggle(farmPage, "Auto Buy Weapon", "AutoLoadout")
addCycle(farmPage, "Weapon Priority", "LoadoutWeapon", { "Rifle", "SMG", "Shotgun", "Sniper", "Pistol" })
smallButton(farmPage, "Buy Weapon Now", function()
    if buyWeapon() then notify("weapon handled") else notify("no weapon button found") end
end)

section(farmPage, "Inventory")
addToggle(farmPage, "Auto Open Inventory", "AutoInventory")
addToggle(farmPage, "Auto Open / Claim All", "AutoOpenAll")
smallButton(farmPage, "Open Everything Now", function()
    openInventory()
    task.delay(0.5, openAllInInventory)
    notify("opening inventory")
end)

section(farmPage, "Anti AFK")
addToggle(farmPage, "Anti AFK", "AntiAfk")
addSlider(farmPage, "Interval", "AntiAfkInterval", 10, 120, 5)

--=====================================================================
--  MOVEMENT ENGINE
--=====================================================================
flyBV, flyBG, flyActive = nil, nil, false
local savedWalk, savedJump, savedStand

local function restoreHumanoid()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum.PlatformStand = savedStand or false
            hum.WalkSpeed = savedWalk or 16
            hum.UseJumpPower = true
            hum.JumpPower = savedJump or 50
        end)
    end
end

local function stopFly()
    if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
    restoreHumanoid()
    flyActive = false
end

local function startFly()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    savedWalk, savedJump, savedStand = hum.WalkSpeed, hum.JumpPower, hum.PlatformStand

    if not flyBV then
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "MalekFly"
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.P = 1250
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
    end
    if not flyBG then
        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "MalekFlyGyro"
        flyBG.MaxTorque = Vector3.new(4e4, 4e4, 4e4)
        flyBG.P = 3000
        flyBG.D = 200
        flyBG.CFrame = hrp.CFrame
        flyBG.Parent = hrp
    end
    hum.PlatformStand = true
    flyActive = true
end

local function setFly(state)
    if state and not flyActive then
        startFly()
    elseif not state and flyActive then
        stopFly()
    end
end

local stickTarget = nil

function nearestEnemy()
    local char = LP.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = plr
                end
            end
        end
    end
    return best, bestDist
end

bind(RunService.RenderStepped:Connect(function(dt)
    if destroyed then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local cam = getCam()

    if hum then
        if Config.WalkSpeedEnabled and not flyActive then
            if hum.WalkSpeed ~= Config.WalkSpeed then hum.WalkSpeed = Config.WalkSpeed end
        elseif not flyActive and savedWalk and hum.WalkSpeed == Config.WalkSpeed and not Config.WalkSpeedEnabled then
            hum.WalkSpeed = savedWalk
        end
        if Config.InfJump then
            hum.UseJumpPower = true
            if hum.JumpPower ~= Config.JumpPower then hum.JumpPower = Config.JumpPower end
        end
    end

    if flyActive and flyBV and hrp and cam then
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end

        local goal = Vector3.zero
        if dir.Magnitude > 0 then goal = dir.Unit * Config.FlySpeed end
        flyBV.Velocity = flyBV.Velocity:Lerp(goal, math.clamp(Config.FlySmooth * 60 * dt, 0, 1))
        flyBG.CFrame = CFrame.new(hrp.Position) * (cam.CFrame - cam.CFrame.Position)
    elseif flyActive and not flyBV then
        stopFly()
    end

    if Config.StickMode then
        local plr = stickTarget
        if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            stickTarget = nearestEnemy()
            plr = stickTarget
        end
        local root = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        local head = plr and plr.Character and plr.Character:FindFirstChild("Head")
        if root and hrp and hum then
            if not hum.PlatformStand then hum.PlatformStand = true end
            local behind = root.CFrame.LookVector * -Config.StickOffset
            hrp.CFrame = CFrame.lookAt(root.Position + behind + Vector3.new(0, 1.2, 0), root.Position)
            if cam and head then
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, head.Position)
            end
        end
    elseif stickTarget and hum and not flyActive then
        hum.PlatformStand = false
        stickTarget = nil
    end
end))

bind(UserInputService.JumpRequest:Connect(function()
    if not Config.InfJump then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end))

--=====================================================================
--  MOVE PAGE
--=====================================================================
local movePage = pages["MOVE"]
section(movePage, "Fly")
addToggle(movePage, "Enable Fly", "FlyEnabled", function(v)
    if not v then setFly(false) end
end)
addCycle(movePage, "Fly Mode", "FlyMode", { "Toggle", "Hold" })
addKeybind(movePage, "Fly Key", "FlyKey")
addSlider(movePage, "Fly Speed", "FlySpeed", 10, 300, 5)
addSlider(movePage, "Fly Smoothing", "FlySmooth", 0.05, 1, 0.05)
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = C_SUB,
    Text = "WASD to move, Space up, Left Shift down. Toggle mode latches, Hold mode flies only while the key is down.",
}, movePage)

section(movePage, "Stick To Target")
addToggle(movePage, "Stick Mode", "StickMode", function(v)
    if v and Config.FlyEnabled then setFly(false) end
end)
addSlider(movePage, "Stick Distance", "StickOffset", 0.5, 12, 0.5)

section(movePage, "Speed")
addToggle(movePage, "Custom WalkSpeed", "WalkSpeedEnabled", function(v)
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        savedWalk = savedWalk or 16
        hum.WalkSpeed = v and Config.WalkSpeed or savedWalk
    end
end)
addSlider(movePage, "WalkSpeed", "WalkSpeed", 8, 200, 1, function(v)
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and Config.WalkSpeedEnabled then hum.WalkSpeed = v end
end)
addSlider(movePage, "Jump Power", "JumpPower", 20, 250, 5, function(v)
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and Config.InfJump then hum.JumpPower = v end
end)
addToggle(movePage, "Infinite Jump", "InfJump")