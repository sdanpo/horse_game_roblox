-- ============================================================
-- HorseManager.server.lua
-- Spawns horse models, handles server-side horse logic,
-- care actions (feed/groom), trick validation, etc.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local GameConfig        = require(ReplicatedStorage.Modules.GameConfig)
local HorseData         = require(ReplicatedStorage.Modules.HorseData)

-- lazy-require to avoid circular deps
local function PDM()
    return require(script.Parent.PlayerDataManager)
end

-- ── Remote helpers ────────────────────────────────────────
local Remote = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getRemote(name)
    local r = Remote:FindFirstChild(name)
    if not r then
        r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = Remote
    end
    return r
end

-- ── Active horse instances ────────────────────────────────
-- [userId] = { model = Model, horse = horseDataTable }
local activeHorses = {}

-- ── Build a horse model from data ─────────────────────────
-- In a real project, we'd load the asset from a model store.
-- Here we build a clean placeholder that can be skinned by
-- a custom character rig once real assets are added.
local function buildHorseModel(horseEntry, horseSaveData)
    local model = Instance.new("Model")
    model.Name  = horseSaveData.name or horseEntry.name

    -- Body
    local body = Instance.new("Part")
    body.Name         = "HorseBody"
    body.Size         = Vector3.new(4, 2.5, 7)
    body.BrickColor   = BrickColor.new("White")
    body.Color        = horseEntry.bodyColor or Color3.fromRGB(200,180,160)
    body.Material     = Enum.Material.SmoothPlastic
    body.Anchored     = false
    body.CanCollide   = true
    body.Parent       = model

    -- Neck
    local neck = Instance.new("Part")
    neck.Name = "Neck"; neck.Size = Vector3.new(1.5, 2.5, 1.5)
    neck.Color = horseEntry.bodyColor or body.Color
    neck.Material = Enum.Material.SmoothPlastic
    neck.Anchored = false; neck.CanCollide = false
    neck.Parent = model
    local nw = Instance.new("Weld", neck)
    nw.Part0 = body; nw.Part1 = neck
    nw.C0 = CFrame.new(0, 0.5, -3) * CFrame.Angles(0.4, 0, 0)

    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"; head.Size = Vector3.new(1.2, 1.5, 2)
    head.Color = horseEntry.bodyColor or body.Color
    head.Material = Enum.Material.SmoothPlastic
    head.Anchored = false; head.CanCollide = false
    head.Parent = model
    local hw = Instance.new("Weld", head)
    hw.Part0 = neck; hw.Part1 = head
    hw.C0 = CFrame.new(0, 1.2, -0.6) * CFrame.Angles(0.3, 0, 0)

    -- Eyes
    for _, side in ipairs({-0.55, 0.55}) do
        local eye = Instance.new("Part")
        eye.Name = "Eye"; eye.Size = Vector3.new(0.1, 0.4, 0.4)
        eye.Color = horseEntry.eyeColor or Color3.fromRGB(60,40,20)
        eye.Material = Enum.Material.Neon
        eye.Anchored = false; eye.CanCollide = false; eye.Parent = model
        local ew = Instance.new("Weld", eye)
        ew.Part0 = head; ew.Part1 = eye
        ew.C0 = CFrame.new(side, 0.1, -0.8)
    end

    -- Mane (decorative part)
    local mane = Instance.new("Part")
    mane.Name = "Mane"; mane.Size = Vector3.new(0.8, 2, 2.5)
    mane.Color = horseEntry.maneColor or Color3.fromRGB(120,80,40)
    mane.Material = Enum.Material.Fabric
    mane.Anchored = false; mane.CanCollide = false; mane.Parent = model
    local mnw = Instance.new("Weld", mane)
    mnw.Part0 = neck; mnw.Part1 = mane
    mnw.C0 = CFrame.new(0, 1, 0)

    -- Legs (4)
    local legOffsets = {
        Vector3.new(-1.3, -1.2, 2),   -- front left
        Vector3.new( 1.3, -1.2, 2),   -- front right
        Vector3.new(-1.3, -1.2,-2),   -- back left
        Vector3.new( 1.3, -1.2,-2),   -- back right
    }
    for i, offset in ipairs(legOffsets) do
        local leg = Instance.new("Part")
        leg.Name = "Leg"..i; leg.Size = Vector3.new(0.8, 2.5, 0.8)
        leg.Color = horseEntry.bodyColor or body.Color
        leg.Material = Enum.Material.SmoothPlastic
        leg.Anchored = false; leg.CanCollide = false; leg.Parent = model
        local lw = Instance.new("Weld", leg)
        lw.Part0 = body; lw.Part1 = leg
        lw.C0 = CFrame.new(offset)
    end

    -- Tail
    local tail = Instance.new("Part")
    tail.Name = "Tail"; tail.Size = Vector3.new(0.6, 2.5, 0.6)
    tail.Color = horseEntry.tailColor or Color3.fromRGB(120,80,40)
    tail.Material = Enum.Material.Fabric
    tail.Anchored = false; tail.CanCollide = false; tail.Parent = model
    local tw = Instance.new("Weld", tail)
    tw.Part0 = body; tw.Part1 = tail
    tw.C0 = CFrame.new(0, 0.5, 3.8) * CFrame.Angles(0.5, 0, 0)

    -- Unicorn horn
    if horseEntry.isUnicorn then
        local horn = Instance.new("SpecialMesh")
        horn.MeshType = Enum.MeshType.Wedge
        local hornPart = Instance.new("Part")
        hornPart.Name = "Horn"; hornPart.Size = Vector3.new(0.3, 1.2, 0.3)
        hornPart.Color = horseEntry.hornColor or Color3.fromRGB(255, 215, 0)
        hornPart.Material = Enum.Material.Neon
        hornPart.Anchored = false; hornPart.CanCollide = false
        hornPart.Parent = model
        horn.Parent = hornPart
        local hnw = Instance.new("Weld", hornPart)
        hnw.Part0 = head; hnw.Part1 = hornPart
        hnw.C0 = CFrame.new(0, 0.9, -0.6) * CFrame.Angles(-0.3, 0, 0)
    end

    -- Sparkle particle if breed has a particle effect
    if horseEntry.particleEffect then
        local attachment = Instance.new("Attachment", body)
        attachment.Name = "ParticleAttachment"
        local particle = Instance.new("ParticleEmitter", attachment)
        particle.Name = "BreedParticle"
        -- Particle settings by effect type
        if horseEntry.particleEffect == "StardustTrail" then
            particle.Texture    = "rbxassetid://PARTICLE_STARDUST"
            particle.Color      = ColorSequence.new(Color3.fromRGB(255,215,0))
            particle.LightEmission = 1
            particle.Size       = NumberSequence.new(0.3)
            particle.Lifetime   = NumberRange.new(0.8, 1.5)
            particle.Rate       = 15
        elseif horseEntry.particleEffect == "RainbowAura" then
            particle.Texture    = "rbxassetid://PARTICLE_GLOW"
            particle.Color      = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(0,255,0)),
                ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,0,255)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255,0,255)),
                ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,255,0)),
            })
            particle.LightEmission = 0.8
            particle.Size       = NumberSequence.new(0.5)
            particle.Lifetime   = NumberRange.new(1, 2)
            particle.Rate       = 20
        else
            particle.Texture    = "rbxassetid://PARTICLE_SPARKLE"
            particle.Color      = ColorSequence.new(Color3.fromRGB(255,255,200))
            particle.LightEmission = 0.6
            particle.Size       = NumberSequence.new(0.2)
            particle.Lifetime   = NumberRange.new(0.5, 1)
            particle.Rate       = 8
        end
    end

    -- Humanoid root for movement
    local hrp = Instance.new("Part")
    hrp.Name      = "HumanoidRootPart"
    hrp.Size      = Vector3.new(2, 2, 2)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Parent    = model
    local hrpW = Instance.new("Weld", hrp)
    hrpW.Part0 = body; hrpW.Part1 = hrp

    local humanoid = Instance.new("Humanoid", model)
    humanoid.WalkSpeed = 0   -- controlled by scripts
    humanoid.JumpPower = 0

    model.PrimaryPart = body
    return model
end

-- ── Spawn a player's active horse ─────────────────────────
local function spawnHorse(player)
    local pdm   = PDM()
    local data  = pdm.get(player.UserId)
    if not data then return end

    local horseData  = pdm.getActiveHorse(player.UserId)
    if not horseData then return end

    local breedEntry = HorseData.getBreed(horseData.breedId)
    if not breedEntry then return end

    -- Despawn previous horse
    if activeHorses[player.UserId] then
        local prev = activeHorses[player.UserId].model
        if prev and prev.Parent then prev:Destroy() end
    end

    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local model = buildHorseModel(breedEntry, horseData)
    local spawnPos = hrp.CFrame * CFrame.new(0, 0, -6)
    model:SetPrimaryPartCFrame(spawnPos)
    model.Parent = workspace

    activeHorses[player.UserId] = { model = model, horse = horseData }
    getRemote("HorseSpawned"):FireClient(player, { uid = horseData.uid, breedId = horseData.breedId })
end

-- ── Care actions ──────────────────────────────────────────
local GROOM_COOLDOWN = 300   -- 5 minutes between grooming sessions
local FEED_COOLDOWN  = 600   -- 10 minutes

local RE_groomHorse = getRemote("GroomHorse")
RE_groomHorse.OnServerEvent:Connect(function(player)
    local pdm   = PDM()
    local horse = pdm.getActiveHorse(player.UserId)
    if not horse then return end

    local now = os.time()
    if now - (horse.lastGroomed or 0) < GROOM_COOLDOWN then
        local remaining = GROOM_COOLDOWN - (now - (horse.lastGroomed or 0))
        getRemote("CareFeedback"):FireClient(player, { success=false, reason="Wait "..math.ceil(remaining/60).." more min." })
        return
    end

    horse.lastGroomed = now
    pdm.addBond(player.UserId, GameConfig.BOND_GAIN_GROOM)
    pdm.addXP(player.UserId, GameConfig.XP_PER_CARE_ACTION)

    -- Sparkle effect on horse
    if activeHorses[player.UserId] then
        local model = activeHorses[player.UserId].model
        getRemote("PlayCareFX"):FireAllClients(model, "Groom")
    end

    -- Stats
    local data = pdm.get(player.UserId)
    if data then data.stats.totalTricks = data.stats.totalTricks end  -- just touch data to mark dirty

    getRemote("CareFeedback"):FireClient(player, { success=true, action="groom", bondGain=GameConfig.BOND_GAIN_GROOM })

    -- Achievement progress
    local groomCount = (pdm.get(player.UserId) or {}).groomCount or 0
    groomCount = groomCount + 1
    if pdm.get(player.UserId) then pdm.get(player.UserId).groomCount = groomCount end
    if groomCount >= 30 then pdm.unlockAchievement(player.UserId, "perfect_groom") end
end)

local RE_feedHorse = getRemote("FeedHorse")
RE_feedHorse.OnServerEvent:Connect(function(player, foodId)
    local pdm   = PDM()
    local horse = pdm.getActiveHorse(player.UserId)
    if not horse then return end

    local now = os.time()
    if now - (horse.lastFed or 0) < FEED_COOLDOWN then
        local remaining = FEED_COOLDOWN - (now - (horse.lastFed or 0))
        getRemote("CareFeedback"):FireClient(player, { success=false, reason="Wait "..math.ceil(remaining/60).." more min." })
        return
    end

    horse.lastFed   = now
    horse.energy    = math.min(GameConfig.MAX_HORSE_ENERGY, horse.energy + GameConfig.ENERGY_REGEN_FEED)
    pdm.addBond(player.UserId, GameConfig.BOND_GAIN_FEED)
    pdm.addXP(player.UserId, GameConfig.XP_PER_CARE_ACTION)

    if activeHorses[player.UserId] then
        local model = activeHorses[player.UserId].model
        getRemote("PlayCareFX"):FireAllClients(model, "Feed")
    end

    getRemote("CareFeedback"):FireClient(player, {
        success    = true,
        action     = "feed",
        newEnergy  = horse.energy,
        bondGain   = GameConfig.BOND_GAIN_FEED,
    })
end)

-- ── Tricks ────────────────────────────────────────────────
local VALID_TRICKS = { "Rear", "Bow", "Spin", "SideStep", "Wave", "Whinny" }
local function isValidTrick(name)
    for _, t in ipairs(VALID_TRICKS) do
        if t == name then return true end
    end
    return false
end

local RE_performTrick = getRemote("PerformTrick")
RE_performTrick.OnServerEvent:Connect(function(player, trickName)
    if not isValidTrick(trickName) then return end

    local pdm  = PDM()
    local data = pdm.get(player.UserId)
    if not data then return end

    -- Energy check
    local horse = pdm.getActiveHorse(player.UserId)
    if not horse or horse.energy < 5 then
        getRemote("TrickFeedback"):FireClient(player, { success=false, reason="Horse is too tired!" })
        return
    end

    horse.energy = math.max(0, horse.energy - 5)
    pdm.addXP(player.UserId, GameConfig.XP_PER_TRICK)
    pdm.addBond(player.UserId, 1)
    data.stats.totalTricks = (data.stats.totalTricks or 0) + 1

    -- Broadcast trick animation to nearby clients
    if activeHorses[player.UserId] then
        local horseModel = activeHorses[player.UserId].model
        getRemote("PlayTrickAnimation"):FireAllClients(horseModel, trickName)
    end

    getRemote("TrickFeedback"):FireClient(player, { success=true, trickName=trickName })
end)

-- ── Switch active horse ───────────────────────────────────
local RE_switchHorse = getRemote("SwitchHorse")
RE_switchHorse.OnServerEvent:Connect(function(player, horseUid)
    local pdm  = PDM()
    local data = pdm.get(player.UserId)
    if not data then return end

    local found = false
    for _, h in ipairs(data.horses) do
        if h.uid == horseUid then found = true; break end
    end
    if not found then return end

    data.activeHorseUid = horseUid
    spawnHorse(player)
end)

-- ── Equip / unequip accessory ────────────────────────────
local RE_equipAccessory = getRemote("EquipAccessory")
RE_equipAccessory.OnServerEvent:Connect(function(player, accessoryId, slot)
    local pdm  = PDM()
    local data = pdm.get(player.UserId)
    if not data then return end
    local horse = pdm.getActiveHorse(player.UserId)
    if not horse then return end

    -- Remove existing in same slot
    for i = #horse.accessories, 1, -1 do
        if horse.accessories[i].slot == slot then
            table.remove(horse.accessories, i)
        end
    end
    if accessoryId ~= "none" then
        table.insert(horse.accessories, { id=accessoryId, slot=slot })
    end

    -- Update visual on all clients
    if activeHorses[player.UserId] then
        local model = activeHorses[player.UserId].model
        getRemote("UpdateHorseAccessories"):FireAllClients(model, horse.accessories)
    end
end)

-- ── Player character loaded → spawn horse ─────────────────
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(2)   -- let character fully load
        spawnHorse(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if activeHorses[player.UserId] then
        local m = activeHorses[player.UserId].model
        if m and m.Parent then m:Destroy() end
        activeHorses[player.UserId] = nil
    end
end)

-- ── Expose for other server modules ──────────────────────
local HorseManager = {}
function HorseManager.getActiveModel(userId)
    local info = activeHorses[userId]
    return info and info.model
end
function HorseManager.respawnHorse(player)
    spawnHorse(player)
end
return HorseManager
