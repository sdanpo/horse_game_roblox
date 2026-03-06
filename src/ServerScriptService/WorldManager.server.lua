-- ============================================================
-- WorldManager.server.lua
-- Handles world travel, decoration spawning, ambient
-- weather/particles, and world-specific events.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local TweenService      = game:GetService("TweenService")

local GameConfig        = require(ReplicatedStorage.Modules.GameConfig)
local WorldData         = require(ReplicatedStorage.Modules.WorldData)

local function PDM() return require(script.Parent.PlayerDataManager) end

-- ── Remote helpers ────────────────────────────────────────
local Remote = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getRemote(name)
    local r = Remote:FindFirstChild(name)
    if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = Remote end
    return r
end

-- ── Per-player world state ────────────────────────────────
-- In a Roblox game you'd use TeleportService for separate places.
-- Here we handle it in one place with visual transitions.
local playerWorld = {}  -- [userId] = worldId

-- ── Apply world atmosphere (server→client broadcast) ──────
local function applyAtmosphere(player, world)
    getRemote("SetWorldAtmosphere"):FireClient(player, {
        worldId      = world.id,
        skyColor     = world.skyColor,
        fogColor     = world.fogColor,
        fogEnd       = world.fogEnd,
        ambientColor = world.ambientColor,
        timeOfDay    = world.timeOfDay,
        music        = world.music,
        particles    = world.particles,
        weatherEffect = world.weatherEffect,
    })
end

-- ── Travel to world ───────────────────────────────────────
local RE_travel = getRemote("TravelToWorld")
RE_travel.OnServerEvent:Connect(function(player, worldId)
    local userId = player.UserId
    local pdm    = PDM()
    local data   = pdm.get(userId)
    if not data then return end

    local world = WorldData.getWorld(worldId)
    if not world then
        getRemote("TravelResult"):FireClient(player, { success=false, reason="World not found." })
        return
    end

    -- Level check
    if data.level < world.unlockLevel then
        getRemote("TravelResult"):FireClient(player, {
            success = false,
            reason  = "You need to be level "..world.unlockLevel.." to visit "..world.name..".",
        })
        return
    end

    -- Premium world: check gem unlock or already owned
    if world.isPremium then
        local owned = false
        for _, wid in ipairs(data.unlockedWorlds or {}) do
            if wid == worldId then owned = true; break end
        end
        if not owned then
            if data.gems >= (world.unlockGems or 50) then
                pdm.addGems(userId, -(world.unlockGems or 50))
                table.insert(data.unlockedWorlds, worldId)
                owned = true
            else
                getRemote("TravelResult"):FireClient(player, {
                    success = false,
                    reason  = "This world costs "..(world.unlockGems or 50).." gems to unlock.",
                    needsGems = world.unlockGems or 50,
                })
                return
            end
        end

    -- Paid world (coins)
    elseif world.unlockCost > 0 then
        local owned = false
        for _, wid in ipairs(data.unlockedWorlds or {}) do
            if wid == worldId then owned = true; break end
        end
        if not owned then
            if data.coins >= world.unlockCost then
                pdm.addCoins(userId, -world.unlockCost)
                table.insert(data.unlockedWorlds, worldId)
            else
                getRemote("TravelResult"):FireClient(player, {
                    success = false,
                    reason  = "You need "..world.unlockCost.." coins to visit "..world.name..".",
                })
                return
            end
        end
    end

    -- Teleport player character to a world spawn point
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local spawnName = "WorldSpawn_"..worldId
        local spawnPart = workspace:FindFirstChild(spawnName)
        if hrp and spawnPart then
            hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 5, 0)
        else
            -- Fallback: move to a generic position
            if hrp then hrp.CFrame = CFrame.new(0, 10, 0) end
        end
    end

    data.currentWorld = worldId
    playerWorld[userId] = worldId

    -- Achievement
    local allVisited = true
    for _, w in ipairs(WorldData.WORLDS) do
        local found = false
        for _, wid in ipairs(data.unlockedWorlds or {}) do
            if wid == w.id then found = true; break end
        end
        if not found and w.unlockLevel <= data.level then
            allVisited = false; break
        end
    end
    if allVisited then pdm.unlockAchievement(userId, "world_explorer") end

    applyAtmosphere(player, world)
    getRemote("TravelResult"):FireClient(player, { success=true, worldId=worldId, world=world })

    -- Tell HorseManager to respawn horse at new location
    local HorseManager = require(script.Parent.HorseManager)
    task.wait(1)
    HorseManager.respawnHorse(player)
end)

-- ── Decoration spawning ───────────────────────────────────
-- Decorations are spawned as simple BrickColor parts with
-- descriptive names so artists can later swap in real meshes.
local function spawnDecoration(decType, position, color)
    local part = Instance.new("Part")
    part.Name     = "Deco_"..decType
    part.Anchored = true
    part.CanCollide = false
    part.Color    = color or Color3.fromRGB(100, 180, 80)
    part.Material = Enum.Material.SmoothPlastic

    -- Size by type
    local sizes = {
        Tree    = Vector3.new(2, 6, 2),
        Flower  = Vector3.new(0.5, 1, 0.5),
        Mushroom= Vector3.new(1, 1.5, 1),
        Rock    = Vector3.new(3, 2, 3),
        Fountain= Vector3.new(4, 3, 4),
        Barn    = Vector3.new(12, 8, 16),
    }
    part.Size = sizes[decType] or Vector3.new(2, 3, 2)
    part.Position = position
    part.Parent = workspace

    -- Neon glow for magical items
    if decType == "GlowingOrbs" or decType == "GlowingCrystal" then
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(180, 100, 255)
        local light = Instance.new("PointLight", part)
        light.Brightness = 2
        light.Range      = 15
        light.Color      = Color3.fromRGB(200, 150, 255)
    end

    return part
end

-- ── World terrain generator (flat placeholder) ────────────
-- In production, terrain is built in Roblox Studio directly.
-- This script creates a simple ground plane per world.
local worldContainers = {}   -- [worldId] = Folder

local WORLD_SIZE = 800       -- studs each side

local function generateWorld(world)
    if worldContainers[world.id] then return end

    local folder = Instance.new("Folder")
    folder.Name  = "World_"..world.id
    folder.Parent = workspace

    -- Ground
    local ground = Instance.new("Part")
    ground.Name     = "Ground"
    ground.Anchored = true
    ground.CanCollide = true
    ground.Size     = Vector3.new(WORLD_SIZE, 2, WORLD_SIZE)
    ground.Position = Vector3.new(0, -1, 0)
    ground.Color    = world.grassColor or Color3.fromRGB(100, 190, 80)
    ground.Material = Enum.Material.Grass
    ground.Parent   = folder

    -- Spawn marker
    local spawn = Instance.new("Part")
    spawn.Name     = "WorldSpawn_"..world.id
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Size     = Vector3.new(4, 0.5, 4)
    spawn.Color    = Color3.fromRGB(255, 215, 0)
    spawn.Material = Enum.Material.Neon
    spawn.Transparency = 0.5
    spawn.Position = Vector3.new(0, 0.25, 0)
    spawn.Parent   = folder

    -- Scatter decorations
    local rng = Random.new()
    for _, deco in ipairs(world.decorations or {}) do
        local count = deco.count
        if not count and deco.density then
            count = math.floor(deco.density * 30)
        end
        count = count or 5

        for _ = 1, count do
            local x = rng:NextNumber(-WORLD_SIZE/2 + 20, WORLD_SIZE/2 - 20)
            local z = rng:NextNumber(-WORLD_SIZE/2 + 20, WORLD_SIZE/2 - 20)
            local part = spawnDecoration(deco.type or deco.variant or "Tree", Vector3.new(x, 1, z))
            part.Parent = folder
        end
    end

    worldContainers[world.id] = folder
    print("[WorldManager] Generated world:", world.id)
end

-- ── Initialise all worlds on server start ─────────────────
for _, world in ipairs(WorldData.WORLDS) do
    task.spawn(generateWorld, world)
    task.wait(0.1)   -- stagger to avoid frame spikes
end

-- ── Send atmosphere to new players ───────────────────────
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(2)
        local pdm  = PDM()
        local data = pdm.get(player.UserId)
        if data then
            local world = WorldData.getWorld(data.currentWorld or GameConfig.STARTING_WORLD)
            if world then
                applyAtmosphere(player, world)
                playerWorld[player.UserId] = world.id
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerWorld[player.UserId] = nil
end)

-- ── Periodic ambient events (fireflies, rain, etc.) ───────
task.spawn(function()
    local EVENT_INTERVAL = 300   -- every 5 minutes
    while true do
        task.wait(EVENT_INTERVAL)
        for userId, worldId in pairs(playerWorld) do
            local world = WorldData.getWorld(worldId)
            if world and world.particles then
                local player = Players:GetPlayerByUserId(userId)
                if player then
                    getRemote("AmbientEvent"):FireClient(player, {
                        worldId  = worldId,
                        eventType = "ParticleBurst",
                        particles = world.particles,
                    })
                end
            end
        end
    end
end)

print("[WorldManager] Ready.")
