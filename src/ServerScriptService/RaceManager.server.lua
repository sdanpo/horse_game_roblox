-- ============================================================
-- RaceManager.server.lua
-- Manages race lobbies, countdown, live race state,
-- checkpoint tracking, and post-race rewards.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- ── Race state ────────────────────────────────────────────
-- status: "lobby" | "countdown" | "racing" | "finished"
local races = {}       -- [trackId] = raceInstance
local playerRace = {}  -- [userId] = trackId

local function newRace(trackId, worldId)
    return {
        trackId        = trackId,
        worldId        = worldId,
        status         = "lobby",
        players        = {},    -- [userId] = { name, position, checkpoints, startTime, finishTime }
        startTime      = nil,
        leaderboard    = {},
        lobbyTimer     = nil,
    }
end

-- ── Broadcast to all race participants ───────────────────
local function broadcast(race, eventName, payload)
    for userId, _ in pairs(race.players) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            getRemote(eventName):FireClient(player, payload)
        end
    end
end

-- ── Start countdown → race ────────────────────────────────
local function beginCountdown(race)
    race.status = "countdown"
    broadcast(race, "RaceCountdown", { seconds = GameConfig.RACE_COUNTDOWN_SECS })

    task.delay(GameConfig.RACE_COUNTDOWN_SECS, function()
        if race.status ~= "countdown" then return end
        race.status    = "racing"
        race.startTime = os.time()
        broadcast(race, "RaceStarted", { startTime = race.startTime })

        -- Timeout watchdog
        task.delay(GameConfig.RACE_TIMEOUT_SECS, function()
            if race.status == "racing" then
                race.status = "finished"
                broadcast(race, "RaceTimeout", {})
                task.wait(10)
                -- clean up
                if races[race.trackId] == race then
                    races[race.trackId] = nil
                end
            end
        end)
    end)
end

-- ── Request to join a race ────────────────────────────────
local RE_joinRace = getRemote("JoinRace")
RE_joinRace.OnServerEvent:Connect(function(player, trackId)
    local userId = player.UserId
    if playerRace[userId] then return end   -- already in a race

    -- Find or create race
    local race = races[trackId]
    if not race then
        -- Identify which world this track belongs to
        local worldId = nil
        for _, world in ipairs(WorldData.WORLDS) do
            for _, track in ipairs(world.raceTracks or {}) do
                if track.id == trackId then worldId = world.id; break end
            end
            if worldId then break end
        end
        if not worldId then return end
        race = newRace(trackId, worldId)
        races[trackId] = race
    end

    if race.status ~= "lobby" then
        getRemote("JoinRaceFail"):FireClient(player, { reason = "Race already in progress." })
        return
    end

    if #race.players >= GameConfig.MAX_RACE_PLAYERS then
        getRemote("JoinRaceFail"):FireClient(player, { reason = "Race is full." })
        return
    end

    race.players[userId] = {
        name        = player.Name,
        displayName = player.DisplayName,
        position    = #race.players + 1,
        checkpoint  = 0,
        startTime   = nil,
        finishTime  = nil,
        lapsDone    = 0,
    }
    playerRace[userId] = trackId

    -- Notify player they joined
    getRemote("JoinRaceSuccess"):FireClient(player, {
        trackId     = trackId,
        playerCount = 0,  -- will update below
    })

    -- Notify all participants of new roster
    local roster = {}
    for uid, pdata in pairs(race.players) do
        table.insert(roster, { userId=uid, name=pdata.name, displayName=pdata.displayName })
    end
    broadcast(race, "RaceRosterUpdate", { players = roster })

    -- Auto-start when lobby fills or after wait
    if not race.lobbyTimer then
        race.lobbyTimer = task.delay(GameConfig.RACE_LOBBY_WAIT_SECS, function()
            if race.status == "lobby" and next(race.players) then
                if #race.players >= GameConfig.MIN_RACE_PLAYERS then
                    beginCountdown(race)
                else
                    -- Not enough players – dissolve lobby
                    broadcast(race, "RaceLobbyDissolved", { reason = "Not enough riders." })
                    for uid, _ in pairs(race.players) do playerRace[uid] = nil end
                    races[race.trackId] = nil
                end
            end
        end)
    end

    -- Early start if max players reached
    if #race.players >= GameConfig.MAX_RACE_PLAYERS and race.status == "lobby" then
        task.cancel(race.lobbyTimer)
        race.lobbyTimer = nil
        beginCountdown(race)
    end
end)

-- ── Leave race ────────────────────────────────────────────
local RE_leaveRace = getRemote("LeaveRace")
RE_leaveRace.OnServerEvent:Connect(function(player)
    local userId  = player.UserId
    local trackId = playerRace[userId]
    if not trackId then return end
    local race = races[trackId]
    if race then
        race.players[userId] = nil
        if not next(race.players) then
            races[trackId] = nil
        end
    end
    playerRace[userId] = nil
    getRemote("LeftRace"):FireClient(player, {})
end)

-- ── Checkpoint reached ────────────────────────────────────
local RE_checkpoint = getRemote("CheckpointReached")
RE_checkpoint.OnServerEvent:Connect(function(player, checkpointIndex, trackId)
    local userId  = player.UserId
    local race    = races[trackId]
    if not race or race.status ~= "racing" then return end

    local pdata = race.players[userId]
    if not pdata then return end

    -- Validate checkpoint order (must be sequential)
    if checkpointIndex ~= pdata.checkpoint + 1 then return end
    pdata.checkpoint = checkpointIndex

    -- Award trail coins for checkpoint
    PDM().addCoins(userId, GameConfig.COINS_PER_TRAIL_RIDE)

    -- Broadcast position update to all racers
    local leaderboard = {}
    for uid, pd in pairs(race.players) do
        table.insert(leaderboard, { userId=uid, name=pd.name, checkpoint=pd.checkpoint })
    end
    table.sort(leaderboard, function(a, b) return a.checkpoint > b.checkpoint end)
    broadcast(race, "RaceLeaderboardUpdate", { leaderboard = leaderboard })
end)

-- ── Player finishes race ──────────────────────────────────
local RE_finish = getRemote("RaceFinished")
RE_finish.OnServerEvent:Connect(function(player, trackId)
    local userId = player.UserId
    local race   = races[trackId]
    if not race or race.status ~= "racing" then return end

    local pdata = race.players[userId]
    if not pdata or pdata.finishTime then return end   -- already finished

    pdata.finishTime = os.time()
    pdata.raceTime   = pdata.finishTime - race.startTime

    -- Determine finish position
    local place = 1
    for _, pd in pairs(race.players) do
        if pd.finishTime and pd.raceTime < pdata.raceTime then
            place = place + 1
        end
    end
    pdata.finishPlace = place

    -- Rewards
    local pdm = PDM()
    local coinReward = 0
    if place == 1 then
        coinReward = GameConfig.COINS_PER_RACE_WIN
        pdm.addXP(userId, GameConfig.XP_PER_RACE_WIN)
        pdm.addBond(userId, GameConfig.BOND_GAIN_RACE_WIN)
        -- Stats
        local pSave = pdm.get(userId)
        if pSave then
            pSave.stats.totalWins = (pSave.stats.totalWins or 0) + 1
            pSave.leaderboard.totalWins = pSave.stats.totalWins
            -- Achievement checks
            if pSave.stats.totalWins >= 1  then pdm.unlockAchievement(userId, "speed_demon") end
            if pSave.stats.totalWins >= 50 then pdm.unlockAchievement(userId, "champion_rider") end
        end
    elseif place <= 3 then
        coinReward = GameConfig.COINS_PER_RACE_TOP3
        pdm.addXP(userId, math.floor(GameConfig.XP_PER_RACE_WIN * 0.6))
    end
    pdm.addCoins(userId, coinReward)

    local pSave = pdm.get(userId)
    if pSave then
        pSave.stats.totalRaces = (pSave.stats.totalRaces or 0) + 1
        pSave.leaderboard.totalRaces = pSave.stats.totalRaces
    end

    getRemote("RaceResult"):FireClient(player, {
        place      = place,
        raceTime   = pdata.raceTime,
        coinsEarned = coinReward,
    })

    -- Check if everyone finished or timeout
    local allDone = true
    for _, pd in pairs(race.players) do
        if not pd.finishTime then allDone = false; break end
    end
    if allDone then
        race.status = "finished"
        local finalBoard = {}
        for uid, pd in pairs(race.players) do
            table.insert(finalBoard, { userId=uid, name=pd.name, place=pd.finishPlace, raceTime=pd.raceTime })
        end
        table.sort(finalBoard, function(a, b) return (a.place or 999) < (b.place or 999) end)
        broadcast(race, "RaceFinalResults", { leaderboard = finalBoard })

        -- Cleanup after delay
        task.delay(15, function()
            for uid, _ in pairs(race.players) do
                playerRace[uid] = nil
            end
            races[trackId] = nil
        end)
    end
end)

-- ── Cleanup on player disconnect ─────────────────────────
Players.PlayerRemoving:Connect(function(player)
    local userId = player.UserId
    local trackId = playerRace[userId]
    if trackId then
        local race = races[trackId]
        if race then
            race.players[userId] = nil
            if not next(race.players) then
                races[trackId] = nil
            end
        end
        playerRace[userId] = nil
    end
end)

print("[RaceManager] Ready.")
