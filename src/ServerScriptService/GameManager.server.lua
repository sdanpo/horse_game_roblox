-- ============================================================
-- GameManager.server.lua
-- Top-level server bootstrap: initialises RemoteEvents
-- folder, wires up daily-quest refresh, runs the
-- achievement watcher, and handles Gamepass perks.
-- ============================================================

local Players              = game:GetService("Players")
local MarketplaceService   = game:GetService("MarketplaceService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local RunService           = game:GetService("RunService")

local GameConfig           = require(ReplicatedStorage.Modules.GameConfig)
local AchievementData      = require(ReplicatedStorage.Modules.AchievementData)
local ShopData             = require(ReplicatedStorage.Modules.ShopData)

-- ── Ensure RemoteEvents folder exists ────────────────────
local Remote = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not Remote then
    Remote = Instance.new("Folder")
    Remote.Name   = "RemoteEvents"
    Remote.Parent = ReplicatedStorage
end

-- ── Ensure Modules folder exists ─────────────────────────
local Modules = ReplicatedStorage:FindFirstChild("Modules")
if not Modules then
    Modules = Instance.new("Folder")
    Modules.Name   = "Modules"
    Modules.Parent = ReplicatedStorage
end

-- ── Helper ────────────────────────────────────────────────
local function getRemote(name)
    local r = Remote:FindFirstChild(name)
    if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = Remote end
    return r
end

-- ── Pre-create all RemoteEvents used across scripts ───────
local ALL_EVENTS = {
    -- Player data
    "InitialPlayerData", "UpdateCurrency", "UpdateXP", "PlayerLevelUp",
    "GetPlayerData",

    -- Horse
    "HorseSpawned", "UpdateHorseBond", "UpdateHorseEnergy",
    "GroomHorse", "FeedHorse", "CareFeedback", "PlayCareFX",
    "PerformTrick", "TrickFeedback", "PlayTrickAnimation",
    "SwitchHorse", "EquipAccessory", "UpdateHorseAccessories",

    -- World / travel
    "TravelToWorld", "TravelResult", "SetWorldAtmosphere", "AmbientEvent",

    -- Race
    "JoinRace", "LeaveRace", "JoinRaceFail", "JoinRaceSuccess",
    "RaceRosterUpdate", "RaceCountdown", "RaceStarted", "RaceTimeout",
    "CheckpointReached", "RaceLeaderboardUpdate",
    "RaceFinished", "RaceResult", "RaceFinalResults",

    -- Shop / economy
    "PurchaseItem", "PurchaseResult",

    -- Social
    "CreateClub", "JoinClub", "LeaveClub", "ClubResult",
    "RideWithFriend", "AcceptRideInvite", "RideInviteReceived", "RideWithFriendResult",
    "SendGift", "GiftResult", "GiftReceived",
    "TakePhoto", "PhotoTaken",
    "GetLeaderboard", "OnlineCount",

    -- Achievements
    "AchievementUnlocked",

    -- UI helpers
    "ShowNotification", "PlaySound",
}

for _, name in ipairs(ALL_EVENTS) do
    if not Remote:FindFirstChild(name) then
        local re = Instance.new("RemoteEvent")
        re.Name   = name
        re.Parent = Remote
    end
end

-- Remote Functions (need different Instance type)
local ALL_FUNCTIONS = { "GetPlayerData", "GetClub", "GetLeaderboard" }
for _, name in ipairs(ALL_FUNCTIONS) do
    if not Remote:FindFirstChild(name) then
        local rf = Instance.new("RemoteFunction")
        rf.Name   = name
        rf.Parent = Remote
    end
end

-- ── Gamepass perk application ────────────────────────────
local GAMEPASS_IDS = {
    vip_pass          = 0,   -- replace 0 with real Roblox gamepass IDs
    unlimited_stalls  = 0,
    auto_care         = 0,
}

local function applyGamepassPerks(player)
    local pdm = require(script.Parent.PlayerDataManager)
    local data = pdm.get(player.UserId)
    if not data then return end

    for gpKey, gpId in pairs(GAMEPASS_IDS) do
        if gpId > 0 then
            local ok, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gpId)
            end)
            if ok and owns then
                local gp = nil
                for _, entry in ipairs(ShopData.GAMEPASSES) do
                    if entry.id == gpKey then gp = entry; break end
                end
                if gp and gp.perks then
                    if gp.perks.stableSlots then
                        data.stableSlots = gp.perks.stableSlots
                    end
                    if gp.perks.autoGroom then
                        data.autoGroom = true
                    end
                    if gp.perks.coinMult then
                        -- store multiplier for economy checks
                        data.vipCoinMult = gp.perks.coinMult
                    end
                    if gp.perks.exclusiveOutfit then
                        local alreadyOwned = false
                        for _, oid in ipairs(data.outfits) do
                            if oid == gp.perks.exclusiveOutfit then alreadyOwned = true; break end
                        end
                        if not alreadyOwned then
                            table.insert(data.outfits, gp.perks.exclusiveOutfit)
                        end
                    end
                end
            end
        end
    end
end

-- ── Daily quest refresh ───────────────────────────────────
local function shuffleQuests(t)
    local n = #t
    local arr = {table.unpack(t)}
    for i = n, 2, -1 do
        local j = math.random(i)
        arr[i], arr[j] = arr[j], arr[i]
    end
    return arr
end

local function refreshDailyQuests(data)
    local todayKey = os.date("%Y-%m-%d")
    if data.dailyQuestKey == todayKey then return end

    data.dailyQuestKey      = todayKey
    data.dailyQuestProgress = {}

    local allQuests = AchievementData.DAILY_QUESTS
    local shuffled  = shuffleQuests(allQuests)
    data.dailyQuests = {}
    for i = 1, math.min(3, #shuffled) do
        table.insert(data.dailyQuests, shuffled[i].id)
        data.dailyQuestProgress[shuffled[i].id] = 0
    end
end

-- ── Process daily quest progress ─────────────────────────
local RE_questProgress = getRemote("QuestProgress")
RE_questProgress.OnServerEvent:Connect(function(player, questId, increment)
    local pdm  = require(script.Parent.PlayerDataManager)
    local data = pdm.get(player.UserId)
    if not data then return end

    -- Validate quest is active today
    local isActive = false
    for _, qid in ipairs(data.dailyQuests or {}) do
        if qid == questId then isActive = true; break end
    end
    if not isActive then return end

    local prev = data.dailyQuestProgress[questId] or 0
    local quest = nil
    for _, q in ipairs(AchievementData.DAILY_QUESTS) do
        if q.id == questId then quest = q; break end
    end
    if not quest then return end

    -- Determine goal from description (simplified: all goals = 1 unless named count)
    local goal = 1
    if questId == "dq_trail" then goal = 2
    elseif questId == "dq_groom" then goal = 3
    elseif questId == "dq_feed"  then goal = 3
    elseif questId == "dq_trick" then goal = 3
    end

    if prev >= goal then return end  -- already complete

    local newVal = math.min(goal, prev + (increment or 1))
    data.dailyQuestProgress[questId] = newVal

    if newVal >= goal then
        -- Grant reward
        if quest.reward then
            if quest.reward.coins then pdm.addCoins(player.UserId, quest.reward.coins) end
            if quest.reward.gems  then pdm.addGems(player.UserId, quest.reward.gems)  end
        end
        getRemote("QuestComplete"):FireClient(player, { questId=questId, reward=quest.reward })
    else
        getRemote("QuestUpdate"):FireClient(player, { questId=questId, progress=newVal, goal=goal })
    end
end)

-- ── Player joined: apply perks, refresh quests ───────────
Players.PlayerAdded:Connect(function(player)
    -- Wait for PlayerDataManager to populate session
    task.wait(3)

    local pdm  = require(script.Parent.PlayerDataManager)
    local data = pdm.get(player.UserId)
    if not data then return end

    applyGamepassPerks(player)
    refreshDailyQuests(data)

    -- Send quest info
    getRemote("DailyQuests"):FireClient(player, {
        quests   = data.dailyQuests,
        progress = data.dailyQuestProgress,
    })

    -- Welcome notification
    getRemote("ShowNotification"):FireClient(player, {
        title   = "Welcome back, "..player.DisplayName.."! 🌟",
        message = "Your horse misses you! Check the stable.",
        icon    = "rbxassetid://ICON_HEART",
        duration = 5,
    })
end)

-- ── Server telemetry (print) ──────────────────────────────
RunService.Heartbeat:Connect(function()
    -- Intentionally empty: heartbeat hook for future profiling
end)

print("[GameManager] Starlight Stables server ready! ⭐")
