-- ============================================================
-- PlayerDataManager.server.lua
-- Handles loading, saving, and updating all persistent
-- player data using DataStoreService.
-- ============================================================

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig        = require(ReplicatedStorage.Modules.GameConfig)
local HorseData         = require(ReplicatedStorage.Modules.HorseData)

-- ── DataStore setup ────────────────────────────────────────
local STORE_VERSION  = "v1_"
local playerStore    = DataStoreService:GetDataStore(STORE_VERSION .. "PlayerData")
local AUTO_SAVE_INTERVAL = 120  -- seconds

-- ── In-memory session cache ────────────────────────────────
local sessionData = {}  -- [userId] = data table

-- ── Default player profile ────────────────────────────────
local function defaultProfile(userId)
    return {
        -- Identity
        userId          = userId,
        joinDate        = os.time(),

        -- Economy
        coins           = GameConfig.STARTING_COINS,
        gems            = GameConfig.STARTING_GEMS,
        totalCoinsEarned = GameConfig.STARTING_COINS,

        -- Progression
        level           = 1,
        xp              = 0,
        title           = "New Rider",

        -- Horses
        horses          = {
            {
                uid         = "horse_1",
                breedId     = "sunrise_pony",
                name        = "Sunny",
                level       = 1,
                xp          = 0,
                bond        = 0,
                energy      = 100,
                saddleId    = "basic_saddle",
                maneStyleId = "natural",
                accessories = {},
                stats       = { wins=0, races=0, trails=0, tricks=0 },
                lastFed     = os.time(),
                lastGroomed = os.time(),
            }
        },
        activeHorseUid  = "horse_1",
        stableSlots     = GameConfig.STARTER_STABLE_SLOTS,

        -- World
        currentWorld    = GameConfig.STARTING_WORLD,
        unlockedWorlds  = { GameConfig.STARTING_WORLD },

        -- Wardrobe
        outfits         = { "default_outfit" },
        activeOutfit    = "default_outfit",
        riderAccessories = { "basic_helmet" },

        -- Boosts (active)
        activeBoosts    = {},

        -- Social
        clubId          = nil,
        friends         = {},        -- [userId] = true
        giftsSentToday  = 0,
        lastGiftReset   = os.time(),

        -- Achievements & Quests
        achievements    = {},        -- [achievementId] = true
        dailyQuests     = {},        -- filled on first login of day
        dailyQuestProgress = {},
        lastQuestReset  = 0,

        -- Login streak
        lastLoginDate   = "",
        loginStreak     = 0,
        totalLogins     = 0,

        -- Stats
        stats = {
            totalRaces  = 0,
            totalWins   = 0,
            totalTrails = 0,
            totalTricks = 0,
            totalPhotos = 0,
        },

        -- Leaderboard snapshot (cached)
        leaderboard = {
            totalWins   = 0,
            totalRaces  = 0,
            highestBond = 0,
        },
    }
end

-- ── XP/Level helpers ──────────────────────────────────────
local function xpForLevel(level)
    if level <= 1 then return 0 end
    return math.floor(GameConfig.LEVEL_XP_BASE * (GameConfig.LEVEL_XP_MULTIPLIER ^ (level - 2)))
end

local function checkLevelUp(data)
    local leveled = false
    while data.level < GameConfig.MAX_PLAYER_LEVEL do
        local needed = xpForLevel(data.level + 1)
        if data.xp >= needed then
            data.xp   = data.xp - needed
            data.level = data.level + 1
            leveled   = true
        else
            break
        end
    end
    return leveled
end

-- ── Load / Save ───────────────────────────────────────────
local function loadData(userId)
    local success, result = pcall(function()
        return playerStore:GetAsync(tostring(userId))
    end)

    if success and result then
        -- Merge saved data over defaults (handles new keys added in updates)
        local defaults = defaultProfile(userId)
        for k, v in pairs(result) do
            defaults[k] = v
        end
        return defaults
    elseif not success then
        warn("[PlayerData] Failed to load data for", userId, ":", result)
    end

    return defaultProfile(userId)
end

local function saveData(userId)
    local data = sessionData[userId]
    if not data then return end

    local success, err = pcall(function()
        playerStore:SetAsync(tostring(userId), data)
    end)

    if not success then
        warn("[PlayerData] Failed to save data for", userId, ":", err)
    end
end

-- ── Daily login processing ────────────────────────────────
local function processDailyLogin(data)
    local today = os.date("%Y-%m-%d")
    if data.lastLoginDate == today then return end   -- already counted

    local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
    if data.lastLoginDate == yesterday then
        data.loginStreak = data.loginStreak + 1
    else
        data.loginStreak = 1
    end

    data.lastLoginDate = today
    data.totalLogins   = data.totalLogins + 1

    -- Daily reward
    data.coins = data.coins + GameConfig.DAILY_LOGIN_COINS
    data.gems  = data.gems  + GameConfig.DAILY_LOGIN_GEMS

    -- Streak bonus
    if data.loginStreak % 7 == 0 then
        data.gems = data.gems + 5   -- weekly streak bonus
    end
end

-- ── Remote Events setup ───────────────────────────────────
local Remote = ReplicatedStorage:WaitForChild("RemoteEvents")

local function getRemote(name)
    local r = Remote:FindFirstChild(name)
    if not r then
        r = Instance.new("RemoteEvent")
        r.Name = name
        r.Parent = Remote
    end
    return r
end

local function getFunction(name)
    local r = Remote:FindFirstChild(name)
    if not r then
        r = Instance.new("RemoteFunction")
        r.Name = name
        r.Parent = Remote
    end
    return r
end

-- ── Public API (called by other server scripts) ───────────
local PlayerDataManager = {}

function PlayerDataManager.get(userId)
    return sessionData[userId]
end

function PlayerDataManager.addCoins(userId, amount)
    local data = sessionData[userId]
    if not data then return end
    data.coins = math.max(0, data.coins + amount)
    if amount > 0 then
        data.totalCoinsEarned = data.totalCoinsEarned + amount
    end
    getRemote("UpdateCurrency"):FireClient(
        Players:GetPlayerByUserId(userId),
        { coins = data.coins, gems = data.gems }
    )
end

function PlayerDataManager.addGems(userId, amount)
    local data = sessionData[userId]
    if not data then return end
    data.gems = math.max(0, data.gems + amount)
    getRemote("UpdateCurrency"):FireClient(
        Players:GetPlayerByUserId(userId),
        { coins = data.coins, gems = data.gems }
    )
end

function PlayerDataManager.addXP(userId, amount)
    local data = sessionData[userId]
    if not data then return end

    -- Apply active XP boost
    for _, boost in ipairs(data.activeBoosts) do
        if boost.effect and boost.effect.xpMult and os.time() < boost.expiresAt then
            amount = math.floor(amount * boost.effect.xpMult)
        end
    end

    data.xp = data.xp + amount
    local leveled = checkLevelUp(data)

    if leveled then
        getRemote("PlayerLevelUp"):FireClient(
            Players:GetPlayerByUserId(userId),
            { level = data.level, xp = data.xp }
        )
    end
    getRemote("UpdateXP"):FireClient(
        Players:GetPlayerByUserId(userId),
        { level = data.level, xp = data.xp }
    )
end

function PlayerDataManager.unlockAchievement(userId, achievementId)
    local data = sessionData[userId]
    if not data or data.achievements[achievementId] then return false end

    local AchievementData = require(ReplicatedStorage.Modules.AchievementData)
    local ach = AchievementData.get(achievementId)
    if not ach then return false end

    data.achievements[achievementId] = true

    -- Grant rewards
    if ach.reward then
        if ach.reward.coins then PlayerDataManager.addCoins(userId, ach.reward.coins) end
        if ach.reward.gems  then PlayerDataManager.addGems(userId, ach.reward.gems) end
        if ach.reward.title then data.title = ach.reward.title end
    end

    getRemote("AchievementUnlocked"):FireClient(
        Players:GetPlayerByUserId(userId),
        ach
    )
    return true
end

-- ── Horse helpers ─────────────────────────────────────────
function PlayerDataManager.getActiveHorse(userId)
    local data = sessionData[userId]
    if not data then return nil end
    for _, horse in ipairs(data.horses) do
        if horse.uid == data.activeHorseUid then return horse end
    end
    return nil
end

function PlayerDataManager.addBond(userId, amount)
    local data = sessionData[userId]
    if not data then return end
    local horse = PlayerDataManager.getActiveHorse(userId)
    if not horse then return end

    -- Apply bond boost
    for _, boost in ipairs(data.activeBoosts) do
        if boost.effect and boost.effect.bondGainMult and os.time() < boost.expiresAt then
            amount = math.floor(amount * boost.effect.bondGainMult)
        end
    end

    horse.bond = math.min(GameConfig.MAX_HORSE_BOND, horse.bond + amount)
    getRemote("UpdateHorseBond"):FireClient(
        Players:GetPlayerByUserId(userId),
        { uid = horse.uid, bond = horse.bond }
    )

    -- Achievement check
    if horse.bond >= 100 then
        PlayerDataManager.unlockAchievement(userId, "horse_whisperer")
    end
end

function PlayerDataManager.drainEnergy(userId, amount)
    local data = sessionData[userId]
    if not data then return end
    local horse = PlayerDataManager.getActiveHorse(userId)
    if not horse then return end

    -- Stamina boost
    for _, boost in ipairs(data.activeBoosts) do
        if boost.effect and boost.effect.energyDrainMult and os.time() < boost.expiresAt then
            amount = math.floor(amount * boost.effect.energyDrainMult)
        end
    end

    horse.energy = math.max(0, horse.energy - amount)
    getRemote("UpdateHorseEnergy"):FireClient(
        Players:GetPlayerByUserId(userId),
        { uid = horse.uid, energy = horse.energy }
    )
end

-- ── Player joined / left ──────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    local userId = player.UserId
    local data   = loadData(userId)
    sessionData[userId] = data

    processDailyLogin(data)

    -- Send initial data to client
    getRemote("InitialPlayerData"):FireClient(player, data)

    print("[PlayerData] Loaded data for", player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
    local userId = player.UserId
    saveData(userId)
    sessionData[userId] = nil
    print("[PlayerData] Saved and unloaded data for", player.Name)
end)

-- ── Auto-save loop ────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(AUTO_SAVE_INTERVAL)
        for userId, _ in pairs(sessionData) do
            saveData(userId)
        end
        print("[PlayerData] Auto-save complete for", #sessionData, "players")
    end
end)

-- ── Server-close save ─────────────────────────────────────
game:BindToClose(function()
    for userId, _ in pairs(sessionData) do
        saveData(userId)
    end
end)

-- ── RemoteFunction: client requests its own data ──────────
local RF_getData = getFunction("GetPlayerData")
RF_getData.OnServerInvoke = function(player)
    return sessionData[player.UserId]
end

-- ── RemoteEvent: client purchases item ───────────────────
local RE_purchase = getRemote("PurchaseItem")
RE_purchase.OnServerEvent:Connect(function(player, itemType, itemId)
    local userId = player.UserId
    local data   = sessionData[userId]
    if not data then return end

    -- Validate and deduct cost (simplified – extend per item type)
    local ShopData = require(ReplicatedStorage.Modules.ShopData)
    -- Find item in relevant category
    local item = nil
    local catalog = ShopData[itemType] or {}
    for _, entry in ipairs(catalog) do
        if entry.id == itemId then item = entry; break end
    end

    if not item then
        getRemote("PurchaseResult"):FireClient(player, { success=false, reason="Item not found." })
        return
    end

    if item.gemPrice and data.gems >= item.gemPrice then
        PlayerDataManager.addGems(userId, -item.gemPrice)
    elseif item.price and data.coins >= item.price then
        PlayerDataManager.addCoins(userId, -item.price)
    else
        getRemote("PurchaseResult"):FireClient(player, { success=false, reason="Not enough currency." })
        return
    end

    -- Grant item (outfit example)
    if itemType == "RIDER_OUTFITS" then
        table.insert(data.outfits, itemId)
    end

    getRemote("PurchaseResult"):FireClient(player, { success=true, itemId=itemId })
end)

return PlayerDataManager
