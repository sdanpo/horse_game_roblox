-- ============================================================
-- SoundManager.client.lua
-- Manages all game audio: music playlists per world,
-- horse SFX, UI sounds, and ambient nature sounds.
-- ============================================================

local Players           = game:GetService("Players")
local SoundService      = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Remote  = ReplicatedStorage:WaitForChild("RemoteEvents")
local player  = Players.LocalPlayer

-- ── Sound registry ────────────────────────────────────────
-- In a real Roblox project these asset IDs would be replaced
-- with your published audio asset IDs.
local SOUNDS = {
    -- UI
    ui_click          = "rbxassetid://6026984224",
    ui_purchase       = "rbxassetid://4590662766",
    ui_achievement    = "rbxassetid://4590662766",
    ui_error          = "rbxassetid://9118026501",
    ui_notification   = "rbxassetid://4590657035",
    ui_level_up       = "rbxassetid://3527525378",
    ui_quest_done     = "rbxassetid://4590662766",

    -- Horse
    horse_appear      = "rbxassetid://2767090532",
    horse_whinny_1    = "rbxassetid://2767090532",
    horse_whinny_2    = "rbxassetid://2767090532",
    horse_whinny_soft = "rbxassetid://2767090532",
    horse_gallop_soft = "rbxassetid://0",
    horse_gallop_med  = "rbxassetid://0",
    horse_gallop_hard = "rbxassetid://0",
    horse_jump        = "rbxassetid://0",
    horse_land        = "rbxassetid://0",
    horse_eat         = "rbxassetid://0",

    -- World ambient
    ambient_meadow    = "rbxassetid://0",
    ambient_ocean     = "rbxassetid://0",
    ambient_forest    = "rbxassetid://0",
    ambient_winter    = "rbxassetid://0",
    ambient_cosmic    = "rbxassetid://0",

    -- Race
    race_countdown    = "rbxassetid://0",
    race_start        = "rbxassetid://0",
    race_finish       = "rbxassetid://0",
    race_win          = "rbxassetid://0",

    -- Effects
    sparkle           = "rbxassetid://0",
    magic_chime       = "rbxassetid://0",
    bond_up           = "rbxassetid://0",
}

-- ── Music per world ───────────────────────────────────────
local WORLD_MUSIC = {
    EnchantedMeadow   = { "rbxassetid://0", "rbxassetid://0" },
    CrystalCove       = { "rbxassetid://0", "rbxassetid://0" },
    MysticForest      = { "rbxassetid://0", "rbxassetid://0" },
    WinterWonderland  = { "rbxassetid://0", "rbxassetid://0" },
    StarlightKingdom  = { "rbxassetid://0", "rbxassetid://0" },
    SakuraValley      = { "rbxassetid://0", "rbxassetid://0" },
}

-- ── Sound pool ────────────────────────────────────────────
local soundFolder = Instance.new("Folder")
soundFolder.Name  = "GameSounds"
soundFolder.Parent = SoundService

local soundInstances = {}

local function createSound(id, name)
    local s = Instance.new("Sound")
    s.Name    = name
    s.SoundId = id
    s.Volume  = 0.5
    s.Parent  = soundFolder
    return s
end

-- Pre-load sounds
for name, id in pairs(SOUNDS) do
    soundInstances[name] = createSound(id, name)
end

-- ── Music player ──────────────────────────────────────────
local musicPlayer = Instance.new("Sound")
musicPlayer.Name   = "MusicPlayer"
musicPlayer.Volume = 0.3
musicPlayer.Parent = SoundService

local currentTrackIndex = 1
local currentPlaylist   = {}
local musicConnected    = nil

local function playNextTrack()
    if #currentPlaylist == 0 then return end
    currentTrackIndex = (currentTrackIndex % #currentPlaylist) + 1
    musicPlayer.SoundId = currentPlaylist[currentTrackIndex]
    musicPlayer:Play()
end

local function setPlaylist(playlist)
    if #playlist == 0 then return end
    currentPlaylist   = playlist
    currentTrackIndex = 1
    musicPlayer.SoundId = playlist[1]

    -- Fade in
    musicPlayer.Volume = 0
    musicPlayer:Play()
    TweenService:Create(musicPlayer, TweenInfo.new(2), { Volume = 0.3 }):Play()

    if musicConnected then musicConnected:Disconnect() end
    musicConnected = musicPlayer.Ended:Connect(playNextTrack)
end

local function crossfadeToPlaylist(newPlaylist)
    if musicPlayer.IsPlaying then
        TweenService:Create(musicPlayer, TweenInfo.new(1.5), { Volume = 0 }):Play()
        task.delay(1.5, function()
            musicPlayer:Stop()
            setPlaylist(newPlaylist)
        end)
    else
        setPlaylist(newPlaylist)
    end
end

-- ── Public API ────────────────────────────────────────────
local SoundManager = {}

function SoundManager.play(name, volume, pitch)
    local s = soundInstances[name]
    if not s then return end
    if volume then s.Volume = volume end
    if pitch  then s.PlaybackSpeed = pitch end
    s:Play()
end

function SoundManager.playPitched(name, pitchMult)
    SoundManager.play(name, nil, pitchMult)
end

function SoundManager.stopAll()
    for _, s in pairs(soundInstances) do
        s:Stop()
    end
end

function SoundManager.setMusicVolume(vol)
    musicPlayer.Volume = math.clamp(vol, 0, 1)
end

function SoundManager.setSFXVolume(vol)
    for _, s in pairs(soundInstances) do
        s.Volume = math.clamp(vol, 0, 1)
    end
end

-- ── React to world change ────────────────────────────────
Remote:WaitForChild("SetWorldAtmosphere").OnClientEvent:Connect(function(data)
    local playlist = WORLD_MUSIC[data.worldId]
    if playlist then
        crossfadeToPlaylist(playlist)
    end
end)

-- ── React to race events ──────────────────────────────────
Remote:WaitForChild("RaceCountdown").OnClientEvent:Connect(function(data)
    SoundManager.play("race_countdown")
end)

Remote:WaitForChild("RaceStarted").OnClientEvent:Connect(function()
    SoundManager.play("race_start")
end)

Remote:WaitForChild("RaceResult").OnClientEvent:Connect(function(data)
    if data.place == 1 then
        SoundManager.play("race_win")
    else
        SoundManager.play("race_finish")
    end
end)

-- ── React to level up ─────────────────────────────────────
Remote:WaitForChild("PlayerLevelUp").OnClientEvent:Connect(function()
    SoundManager.play("ui_level_up")
end)

-- ── React to achievement ──────────────────────────────────
Remote:WaitForChild("AchievementUnlocked").OnClientEvent:Connect(function()
    SoundManager.play("ui_achievement")
end)

-- ── React to bond gain ────────────────────────────────────
Remote:WaitForChild("UpdateHorseBond").OnClientEvent:Connect(function()
    SoundManager.play("bond_up", 0.4)
end)

-- ── UI sound helper (called from UI scripts) ──────────────
Remote:WaitForChild("PlaySound").OnClientEvent:Connect(function(name)
    SoundManager.play(name)
end)

-- ── Start with meadow music ───────────────────────────────
task.delay(1, function()
    setPlaylist(WORLD_MUSIC.EnchantedMeadow)
end)

-- Return module-style for require()
return SoundManager
