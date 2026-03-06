-- ============================================================
-- AtmosphereController.client.lua
-- Applies world atmospheres on the client: sky colours,
-- fog, ambient lighting, particle emitters, and weather.
-- ============================================================

local Lighting          = game:GetService("Lighting")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Remote = ReplicatedStorage:WaitForChild("RemoteEvents")
local player = Players.LocalPlayer

-- ── Lighting instances ────────────────────────────────────
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
    atmosphere = Instance.new("Atmosphere", Lighting)
end

local sky = Lighting:FindFirstChildOfClass("Sky")
if not sky then
    sky = Instance.new("Sky", Lighting)
end

-- ── Particle folder for ambient effects ───────────────────
local particleFolder = Instance.new("Folder")
particleFolder.Name   = "WorldParticles"
particleFolder.Parent = workspace

-- ── World atmosphere presets ─────────────────────────────
local ATMOSPHERES = {
    EnchantedMeadow = {
        ambient     = Color3.fromRGB(180, 200, 160),
        outAmbient  = Color3.fromRGB(200, 220, 180),
        brightness  = 1.2,
        fogColor    = Color3.fromRGB(200, 230, 200),
        fogStart    = 300,
        fogEnd      = 800,
        shadow      = Color3.fromRGB(80, 100, 60),
        atmo = {
            Density    = 0.3,
            Offset     = 0,
            Color      = Color3.fromRGB(160, 200, 120),
            Decay      = Color3.fromRGB(100, 140, 80),
            Glare      = 0.2,
            Haze       = 0.4,
        },
    },
    CrystalCove = {
        ambient     = Color3.fromRGB(170, 200, 230),
        outAmbient  = Color3.fromRGB(180, 210, 240),
        brightness  = 1.3,
        fogColor    = Color3.fromRGB(150, 220, 255),
        fogStart    = 400,
        fogEnd      = 1000,
        shadow      = Color3.fromRGB(60, 100, 140),
        atmo = {
            Density    = 0.2,
            Offset     = 0.1,
            Color      = Color3.fromRGB(120, 180, 230),
            Decay      = Color3.fromRGB(60, 120, 180),
            Glare      = 0.4,
            Haze       = 0.2,
        },
    },
    MysticForest = {
        ambient     = Color3.fromRGB(80, 120, 60),
        outAmbient  = Color3.fromRGB(60, 100, 50),
        brightness  = 0.7,
        fogColor    = Color3.fromRGB(80, 120, 80),
        fogStart    = 100,
        fogEnd      = 600,
        shadow      = Color3.fromRGB(30, 60, 30),
        atmo = {
            Density    = 0.5,
            Offset     = 0,
            Color      = Color3.fromRGB(60, 120, 60),
            Decay      = Color3.fromRGB(30, 80, 30),
            Glare      = 0.1,
            Haze       = 0.8,
        },
    },
    WinterWonderland = {
        ambient     = Color3.fromRGB(180, 200, 240),
        outAmbient  = Color3.fromRGB(200, 220, 255),
        brightness  = 1.4,
        fogColor    = Color3.fromRGB(220, 230, 255),
        fogStart    = 200,
        fogEnd      = 700,
        shadow      = Color3.fromRGB(100, 120, 180),
        atmo = {
            Density    = 0.4,
            Offset     = 0.2,
            Color      = Color3.fromRGB(180, 200, 240),
            Decay      = Color3.fromRGB(140, 170, 220),
            Glare      = 0.6,
            Haze       = 0.5,
        },
        weather = "Snowfall",
    },
    StarlightKingdom = {
        ambient     = Color3.fromRGB(60, 40, 120),
        outAmbient  = Color3.fromRGB(40, 20, 80),
        brightness  = 0.4,
        fogColor    = Color3.fromRGB(40, 20, 80),
        fogStart    = 200,
        fogEnd      = 1200,
        shadow      = Color3.fromRGB(10, 5, 30),
        atmo = {
            Density    = 0.6,
            Offset     = 0,
            Color      = Color3.fromRGB(60, 30, 120),
            Decay      = Color3.fromRGB(20, 10, 60),
            Glare      = 0.8,
            Haze       = 0.9,
        },
    },
    SakuraValley = {
        ambient     = Color3.fromRGB(240, 190, 210),
        outAmbient  = Color3.fromRGB(255, 200, 220),
        brightness  = 1.2,
        fogColor    = Color3.fromRGB(255, 210, 230),
        fogStart    = 300,
        fogEnd      = 900,
        shadow      = Color3.fromRGB(180, 120, 150),
        atmo = {
            Density    = 0.3,
            Offset     = 0,
            Color      = Color3.fromRGB(220, 170, 200),
            Decay      = Color3.fromRGB(180, 130, 160),
            Glare      = 0.3,
            Haze       = 0.3,
        },
    },
}

-- ── Weather systems ───────────────────────────────────────
local activeWeather = nil

local function clearWeather()
    for _, p in ipairs(particleFolder:GetChildren()) do
        if p.Name:find("Weather") then p:Destroy() end
    end
    activeWeather = nil
end

local function startSnowfall()
    clearWeather()
    local snowEmitter = Instance.new("Part")
    snowEmitter.Name        = "WeatherSnow"
    snowEmitter.Anchored    = true
    snowEmitter.Transparency = 1
    snowEmitter.CanCollide  = false
    snowEmitter.Size        = Vector3.new(500, 1, 500)
    snowEmitter.Position    = Vector3.new(0, 100, 0)
    snowEmitter.Parent      = particleFolder

    local att = Instance.new("Attachment", snowEmitter)
    local pe  = Instance.new("ParticleEmitter", att)
    pe.Texture        = "rbxassetid://PARTICLE_SNOWFLAKE"
    pe.Color          = ColorSequence.new(Color3.fromRGB(230, 240, 255))
    pe.LightEmission  = 0.5
    pe.Size           = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.1) })
    pe.Transparency   = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1) })
    pe.Lifetime       = NumberRange.new(8, 15)
    pe.Rate           = 60
    pe.SpreadAngle    = Vector2.new(20, 20)
    pe.Speed          = NumberRange.new(5, 12)
    pe.Rotation       = NumberRange.new(-180, 180)
    pe.RotSpeed       = NumberRange.new(-30, 30)
    pe.VelocitySpread = 10

    activeWeather = "Snowfall"
end

local WEATHER_FN = { Snowfall = startSnowfall }

-- ── Apply atmosphere (with tween transition) ──────────────
local function applyAtmosphere(worldId)
    local preset = ATMOSPHERES[worldId]
    if not preset then return end

    local TWEEN_TIME = 2
    local tweenInfo  = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine)

    -- Lighting
    TweenService:Create(Lighting, tweenInfo, {
        Ambient              = preset.ambient,
        OutdoorAmbient       = preset.outAmbient,
        Brightness           = preset.brightness,
        FogColor             = preset.fogColor,
        FogStart             = preset.fogStart or 100,
        FogEnd               = preset.fogEnd   or 800,
        ShadowColor          = preset.shadow   or Color3.fromRGB(60,60,60),
    }):Play()

    -- Atmosphere
    if preset.atmo then
        for prop, value in pairs(preset.atmo) do
            TweenService:Create(atmosphere, tweenInfo, { [prop] = value }):Play()
        end
    end

    -- Weather
    if preset.weather then
        local fn = WEATHER_FN[preset.weather]
        if fn then fn() end
    else
        clearWeather()
    end
end

-- ── Ambient particle effects ──────────────────────────────
local ambientParticles = {}

local function spawnAmbientParticles(particleNames)
    -- Clear old ambient particles
    for _, p in ipairs(ambientParticles) do
        if p.Parent then p:Destroy() end
    end
    ambientParticles = {}

    local char = player.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, pName in ipairs(particleNames or {}) do
        local part = Instance.new("Part")
        part.Anchored    = true
        part.Transparency = 1
        part.CanCollide  = false
        part.Size        = Vector3.new(50, 5, 50)
        part.Parent      = particleFolder

        local att = Instance.new("Attachment", part)
        local pe  = Instance.new("ParticleEmitter", att)
        pe.Name   = "Ambient_"..pName

        -- Simple effect per particle type
        if pName == "FloatingPetals" or pName == "CherryBlossomPetals" then
            pe.Color       = ColorSequence.new(Color3.fromRGB(255, 180, 210))
            pe.Size        = NumberSequence.new(0.25)
            pe.Lifetime    = NumberRange.new(5, 8)
            pe.Rate        = 6
            pe.Speed       = NumberRange.new(2, 5)
            pe.SpreadAngle = Vector2.new(60, 60)
        elseif pName == "GoldenDust" or pName == "StarDust" then
            pe.Color          = ColorSequence.new(Color3.fromRGB(255, 210, 100))
            pe.LightEmission  = 0.8
            pe.Size           = NumberSequence.new(0.15)
            pe.Lifetime       = NumberRange.new(2, 4)
            pe.Rate           = 12
            pe.Speed          = NumberRange.new(1, 3)
        elseif pName == "Snowflakes" then
            pe.Color       = ColorSequence.new(Color3.fromRGB(230, 240, 255))
            pe.Size        = NumberSequence.new(0.3)
            pe.Lifetime    = NumberRange.new(6, 12)
            pe.Rate        = 30
            pe.Speed       = NumberRange.new(4, 10)
        elseif pName == "FirefliesSwarm" then
            pe.Color          = ColorSequence.new(Color3.fromRGB(200, 255, 150))
            pe.LightEmission  = 1
            pe.Size           = NumberSequence.new(0.2)
            pe.Lifetime       = NumberRange.new(3, 6)
            pe.Rate           = 4
            pe.Speed          = NumberRange.new(1, 2)
        elseif pName == "MeteorShower" then
            pe.Color          = ColorSequence.new(Color3.fromRGB(200, 150, 255))
            pe.LightEmission  = 0.9
            pe.Size           = NumberSequence.new(0.5)
            pe.Lifetime       = NumberRange.new(1, 3)
            pe.Rate           = 3
            pe.Speed          = NumberRange.new(20, 40)
            pe.SpreadAngle    = Vector2.new(5, 5)
        end

        table.insert(ambientParticles, part)

        -- Keep particles near player
        task.spawn(function()
            while part.Parent do
                if player.Character then
                    local charHRP = player.Character:FindFirstChild("HumanoidRootPart")
                    if charHRP then
                        part.Position = charHRP.Position + Vector3.new(0, 10, 0)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end

-- ── Listen for world changes ──────────────────────────────
Remote:WaitForChild("SetWorldAtmosphere").OnClientEvent:Connect(function(data)
    applyAtmosphere(data.worldId)
    if data.particles then
        spawnAmbientParticles(data.particles)
    end
end)

Remote:WaitForChild("AmbientEvent").OnClientEvent:Connect(function(data)
    if data.eventType == "ParticleBurst" and data.particles then
        -- Momentary burst
        spawnAmbientParticles(data.particles)
        task.delay(5, function()
            -- Restore normal ambient
        end)
    end
end)

-- ── Default atmosphere on load ────────────────────────────
task.delay(3, function()
    applyAtmosphere("EnchantedMeadow")
    spawnAmbientParticles({ "FloatingPetals", "GoldenDust" })
end)

print("[AtmosphereController] Ready.")
