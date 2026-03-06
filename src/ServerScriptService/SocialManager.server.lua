-- ============================================================
-- SocialManager.server.lua
-- Riding clubs, friend rides, gifting, photo sharing,
-- and global leaderboards.
-- ============================================================

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function PDM() return require(script.Parent.PlayerDataManager) end

-- ── Remote helpers ────────────────────────────────────────
local Remote = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getRemote(name)
    local r = Remote:FindFirstChild(name)
    if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = Remote end
    return r
end
local function getFunction(name)
    local r = Remote:FindFirstChild(name)
    if not r then r = Instance.new("RemoteFunction"); r.Name = name; r.Parent = Remote end
    return r
end

-- ── Clubs DataStore ───────────────────────────────────────
local clubStore = DataStoreService:GetDataStore("v1_Clubs")

-- in-memory club cache [clubId] = clubData
local clubs = {}

local function loadClub(clubId)
    if clubs[clubId] then return clubs[clubId] end
    local ok, data = pcall(function() return clubStore:GetAsync(clubId) end)
    if ok and data then
        clubs[clubId] = data
        return data
    end
    return nil
end

local function saveClub(clubId)
    local data = clubs[clubId]
    if not data then return end
    pcall(function() clubStore:SetAsync(clubId, data) end)
end

-- ── Create Club ───────────────────────────────────────────
local RE_createClub = getRemote("CreateClub")
RE_createClub.OnServerEvent:Connect(function(player, clubName, emblem)
    local userId = player.UserId
    local pdm    = PDM()
    local data   = pdm.get(userId)
    if not data then return end

    if data.clubId then
        getRemote("ClubResult"):FireClient(player, { success=false, reason="You're already in a club." })
        return
    end

    -- Sanitize name length
    clubName = tostring(clubName):sub(1, 30)

    local clubId = "CLUB_"..userId.."_"..os.time()
    local club = {
        id          = clubId,
        name        = clubName,
        emblem      = emblem or "⭐",
        ownerId     = userId,
        ownerName   = player.DisplayName,
        members     = { [tostring(userId)] = { role="Owner", joined=os.time() } },
        memberCount = 1,
        founded     = os.time(),
        wins        = 0,
        description = "",
    }

    clubs[clubId] = club
    saveClub(clubId)
    data.clubId = clubId

    getRemote("ClubResult"):FireClient(player, { success=true, club=club })
    pdm.unlockAchievement(userId, "club_founder")
end)

-- ── Join Club ─────────────────────────────────────────────
local RE_joinClub = getRemote("JoinClub")
RE_joinClub.OnServerEvent:Connect(function(player, clubId)
    local userId = player.UserId
    local pdm    = PDM()
    local data   = pdm.get(userId)
    if not data or data.clubId then
        getRemote("ClubResult"):FireClient(player, { success=false, reason="Already in a club." })
        return
    end

    local club = loadClub(clubId)
    if not club then
        getRemote("ClubResult"):FireClient(player, { success=false, reason="Club not found." })
        return
    end

    club.members[tostring(userId)] = { role="Member", joined=os.time() }
    club.memberCount = club.memberCount + 1
    data.clubId = clubId
    saveClub(clubId)

    getRemote("ClubResult"):FireClient(player, { success=true, club=club })
end)

-- ── Leave Club ────────────────────────────────────────────
local RE_leaveClub = getRemote("LeaveClub")
RE_leaveClub.OnServerEvent:Connect(function(player)
    local userId = player.UserId
    local pdm    = PDM()
    local data   = pdm.get(userId)
    if not data or not data.clubId then return end

    local club = clubs[data.clubId]
    if club then
        club.members[tostring(userId)] = nil
        club.memberCount = math.max(0, club.memberCount - 1)
        saveClub(data.clubId)
    end

    data.clubId = nil
    getRemote("ClubResult"):FireClient(player, { success=true, left=true })
end)

-- ── Get Club Info ─────────────────────────────────────────
local RF_getClub = getFunction("GetClub")
RF_getClub.OnServerInvoke = function(player, clubId)
    return loadClub(clubId)
end

-- ── Friend Ride Request ───────────────────────────────────
local RE_rideWithFriend = getRemote("RideWithFriend")
RE_rideWithFriend.OnServerEvent:Connect(function(player, targetUserId)
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target then
        getRemote("RideWithFriendResult"):FireClient(player, { success=false, reason="Player not online." })
        return
    end

    -- Send invite to target
    getRemote("RideInviteReceived"):FireClient(target, {
        fromUserId  = player.UserId,
        fromName    = player.DisplayName,
    })
end)

local RE_acceptRide = getRemote("AcceptRideInvite")
RE_acceptRide.OnServerEvent:Connect(function(player, fromUserId)
    local fromPlayer = Players:GetPlayerByUserId(fromUserId)
    if not fromPlayer then return end

    -- Simple join: teleport both to same position (server authority)
    local fromChar = fromPlayer.Character
    local toChar   = player.Character
    if fromChar and toChar then
        local fromHRP = fromChar:FindFirstChild("HumanoidRootPart")
        local toHRP   = toChar:FindFirstChild("HumanoidRootPart")
        if fromHRP and toHRP then
            toHRP.CFrame = fromHRP.CFrame * CFrame.new(4, 0, 0)
        end
    end

    getRemote("RideWithFriendResult"):FireClient(fromPlayer, { success=true, partnerId=player.UserId, partnerName=player.DisplayName })
    getRemote("RideWithFriendResult"):FireClient(player, { success=true, partnerId=fromUserId, partnerName=fromPlayer.DisplayName })

    -- Track for achievement
    local pdm = PDM()
    local fromData = pdm.get(fromUserId)
    local toData   = pdm.get(player.UserId)
    if fromData then
        fromData.friendRideCount = (fromData.friendRideCount or 0) + 1
        if fromData.friendRideCount >= 10 then pdm.unlockAchievement(fromUserId, "best_friends") end
    end
    if toData then
        toData.friendRideCount = (toData.friendRideCount or 0) + 1
        if toData.friendRideCount >= 10 then pdm.unlockAchievement(player.UserId, "best_friends") end
    end
end)

-- ── Gift System ───────────────────────────────────────────
local GIFTABLE_ITEMS = { "flower_crown", "gem_necklace", "butterfly_clip", "braid_ribbons", "rainbow_scarf" }
local GIFT_COIN_COST = 50

local RE_sendGift = getRemote("SendGift")
RE_sendGift.OnServerEvent:Connect(function(player, targetUserId, itemId)
    local userId = player.UserId
    local pdm    = PDM()
    local data   = pdm.get(userId)
    if not data then return end

    -- Daily gift limit
    local today = os.date("%Y-%m-%d")
    if data.giftDayKey ~= today then
        data.giftDayKey    = today
        data.giftsSentToday = 0
    end
    if data.giftsSentToday >= 3 then
        getRemote("GiftResult"):FireClient(player, { success=false, reason="Daily gift limit reached (3/day)." })
        return
    end

    -- Validate item
    local valid = false
    for _, id in ipairs(GIFTABLE_ITEMS) do
        if id == itemId then valid = true; break end
    end
    if not valid then
        getRemote("GiftResult"):FireClient(player, { success=false, reason="Item not giftable." })
        return
    end

    -- Cost
    if data.coins < GIFT_COIN_COST then
        getRemote("GiftResult"):FireClient(player, { success=false, reason="Not enough coins." })
        return
    end

    pdm.addCoins(userId, -GIFT_COIN_COST)
    data.giftsSentToday = data.giftsSentToday + 1

    -- Deliver gift (online = immediate, offline = not supported in this version)
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer then
        local targetData = pdm.get(targetUserId)
        if targetData then
            -- Add item to their accessories list
            targetData.riderAccessories = targetData.riderAccessories or {}
            table.insert(targetData.riderAccessories, itemId)
            getRemote("GiftReceived"):FireClient(targetPlayer, {
                fromName = player.DisplayName,
                itemId   = itemId,
            })
        end
    end

    getRemote("GiftResult"):FireClient(player, { success=true })

    -- Achievement check
    local giftTotal = (data.giftsTotalSent or 0) + 1
    data.giftsTotalSent = giftTotal
    if giftTotal >= 5 then pdm.unlockAchievement(userId, "gift_giver") end
end)

-- ── Photo Booth ───────────────────────────────────────────
local RE_takePhoto = getRemote("TakePhoto")
RE_takePhoto.OnServerEvent:Connect(function(player)
    local userId = player.UserId
    local pdm    = PDM()
    local data   = pdm.get(userId)
    if not data then return end

    data.stats.totalPhotos = (data.stats.totalPhotos or 0) + 1
    pdm.addCoins(userId, 10)   -- small coin for each photo

    if data.stats.totalPhotos >= 20 then
        pdm.unlockAchievement(userId, "photo_star")
    end

    getRemote("PhotoTaken"):FireClient(player, { count = data.stats.totalPhotos })
end)

-- ── Global Leaderboard (top 10 by race wins) ─────────────
local leaderboardStore = DataStoreService:GetOrderedDataStore("v1_RaceWins")

local function updateLeaderboard(userId, wins)
    pcall(function()
        leaderboardStore:SetAsync(tostring(userId), wins)
    end)
end

local RF_getLeaderboard = getFunction("GetLeaderboard")
RF_getLeaderboard.OnServerInvoke = function(player)
    local ok, pages = pcall(function()
        return leaderboardStore:GetSortedAsync(false, 10)
    end)
    if not ok then return {} end

    local results = {}
    local page    = pages:GetCurrentPage()
    for rank, entry in ipairs(page) do
        local name = "Unknown"
        local ok2, info = pcall(function()
            return Players:GetNameFromUserIdAsync(tonumber(entry.key))
        end)
        if ok2 then name = info end
        table.insert(results, { rank=rank, userId=entry.key, name=name, wins=entry.value })
    end
    return results
end

-- ── Broadcast online player count periodically ────────────
task.spawn(function()
    while true do
        task.wait(30)
        local count = #Players:GetPlayers()
        for _, player in ipairs(Players:GetPlayers()) do
            getRemote("OnlineCount"):FireClient(player, { count = count })
        end
    end
end)

print("[SocialManager] Ready.")
