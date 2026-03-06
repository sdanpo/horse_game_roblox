-- ============================================================
-- WorldSetup.lua  (runs as a Script inside Workspace)
-- Places all static world props: spawn pads, checkpoints,
-- jump obstacles, photo booth stands, and decoration anchors.
-- NOTE: In a production project these would be Studio-built
-- models; this script builds placeholder geometry.
-- ============================================================

-- ── Checkpoint builder ────────────────────────────────────
local function buildCheckpoint(name, position, color)
    local folder = Instance.new("Folder")
    folder.Name  = name

    local gate = Instance.new("Part")
    gate.Name     = "Gate"
    gate.Anchored = true
    gate.CanCollide = false
    gate.Size     = Vector3.new(10, 8, 0.5)
    gate.Position = position
    gate.Color    = color or Color3.fromRGB(255, 215, 0)
    gate.Material = Enum.Material.Neon
    gate.Transparency = 0.4
    gate.Parent   = folder

    -- Banner
    local banner = Instance.new("Part")
    banner.Name  = "Banner"
    banner.Anchored = true
    banner.CanCollide = false
    banner.Size  = Vector3.new(10, 1, 0.2)
    banner.Position = position + Vector3.new(0, 4.5, 0)
    banner.Color = Color3.fromRGB(230, 100, 200)
    banner.Material = Enum.Material.Neon
    banner.Parent = folder

    -- Touch detection (server handles this via server script)
    local touch = Instance.new("Part")
    touch.Name   = "TouchPart"
    touch.Anchored = true
    touch.CanCollide = false
    touch.Transparency = 1
    touch.Size   = Vector3.new(12, 10, 2)
    touch.Position = position
    touch.Parent = folder

    -- Value for track identification
    local trackVal = Instance.new("StringValue")
    trackVal.Name  = "TrackId"
    trackVal.Parent = folder

    return folder, touch
end

-- ── Jump obstacle builder ─────────────────────────────────
local function buildJumpObstacle(name, position, height, color)
    local folder = Instance.new("Folder")
    folder.Name  = name

    -- Left post
    local postL = Instance.new("Part")
    postL.Name = "PostL"; postL.Anchored = true; postL.CanCollide = true
    postL.Size = Vector3.new(0.5, height, 0.5)
    postL.Position = position + Vector3.new(-4, height/2, 0)
    postL.Color = Color3.fromRGB(255,255,255); postL.Material = Enum.Material.Wood
    postL.Parent = folder

    -- Right post
    local postR = postL:Clone(); postR.Name = "PostR"
    postR.Position = position + Vector3.new(4, height/2, 0)
    postR.Parent = folder

    -- Pole (the jump bar)
    local pole = Instance.new("Part")
    pole.Name = "Pole"; pole.Anchored = true; pole.CanCollide = true
    pole.Size = Vector3.new(8, 0.3, 0.3)
    pole.Position = position + Vector3.new(0, height, 0)
    pole.Color = color or Color3.fromRGB(255, 100, 100)
    pole.Material = Enum.Material.SmoothPlastic
    pole.Parent = folder

    return folder
end

-- ── Photo booth ───────────────────────────────────────────
local function buildPhotoBooth(position)
    local folder = Instance.new("Folder")
    folder.Name  = "PhotoBooth"

    local base = Instance.new("Part")
    base.Name = "Base"; base.Anchored = true; base.CanCollide = true
    base.Size = Vector3.new(12, 0.5, 10)
    base.Position = position; base.Color = Color3.fromRGB(255, 220, 240)
    base.Material = Enum.Material.SmoothPlastic; base.Parent = folder

    -- Backdrop frame
    local backdrop = Instance.new("Part")
    backdrop.Name = "Backdrop"; backdrop.Anchored = true; backdrop.CanCollide = false
    backdrop.Size = Vector3.new(10, 8, 0.5)
    backdrop.Position = position + Vector3.new(0, 4.25, -4.5)
    backdrop.Color = Color3.fromRGB(200, 150, 255)
    backdrop.Material = Enum.Material.Neon
    backdrop.Transparency = 0.2; backdrop.Parent = folder

    -- Stars decoration on backdrop
    for _ = 1, 8 do
        local star = Instance.new("Part")
        star.Name = "Star"; star.Anchored = true; star.CanCollide = false
        star.Size = Vector3.new(0.5, 0.5, 0.1)
        star.Position = position + Vector3.new(
            math.random(-4, 4), math.random(1, 7), -4.4
        )
        star.Color = Color3.fromRGB(255, 215, 0)
        star.Material = Enum.Material.Neon; star.Parent = folder
    end

    -- Sign
    local sign = Instance.new("Part")
    sign.Name = "Sign"; sign.Anchored = true; sign.CanCollide = false
    sign.Size = Vector3.new(6, 1.5, 0.3)
    sign.Position = position + Vector3.new(0, 9, -4.5)
    sign.Color = Color3.fromRGB(230, 100, 200)
    sign.Material = Enum.Material.SmoothPlastic; sign.Parent = folder

    local gui = Instance.new("SurfaceGui", sign)
    gui.Face = Enum.NormalId.Front; gui.StudsPerPixelX = 0.02
    local lbl = Instance.new("TextLabel", gui)
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = "📸  PHOTO BOOTH  📸"
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true

    return folder
end

-- ── Stable building ───────────────────────────────────────
local function buildStable(position)
    local folder = Instance.new("Folder")
    folder.Name  = "Stable"

    -- Main building
    local walls = {
        { size=Vector3.new(20,8,1),  offset=Vector3.new(0,4,10)  },   -- back
        { size=Vector3.new(20,8,1),  offset=Vector3.new(0,4,-10) },   -- front (with gap)
        { size=Vector3.new(1,8,20),  offset=Vector3.new(-10,4,0) },   -- left
        { size=Vector3.new(1,8,20),  offset=Vector3.new( 10,4,0) },   -- right
    }
    for _, w in ipairs(walls) do
        local part = Instance.new("Part")
        part.Name = "Wall"; part.Anchored = true; part.CanCollide = true
        part.Size = w.size; part.Position = position + w.offset
        part.Color = Color3.fromRGB(210, 180, 140)
        part.Material = Enum.Material.Wood; part.Parent = folder
    end

    -- Roof
    local roof = Instance.new("Part")
    roof.Name = "Roof"; roof.Anchored = true; roof.CanCollide = true
    roof.Size = Vector3.new(22, 0.5, 22)
    roof.Position = position + Vector3.new(0, 8, 0)
    roof.Color = Color3.fromRGB(180, 100, 60)
    roof.Material = Enum.Material.Wood; roof.Parent = folder

    -- Stall dividers
    for i = -2, 2 do
        local divider = Instance.new("Part")
        divider.Name = "Stall"..i
        divider.Anchored = true; divider.CanCollide = true
        divider.Size = Vector3.new(0.3, 5, 8)
        divider.Position = position + Vector3.new(i * 4, 2.5, 1)
        divider.Color = Color3.fromRGB(160, 110, 60)
        divider.Material = Enum.Material.Wood; divider.Parent = folder
    end

    -- Flower boxes
    for _, side in ipairs({-9, 9}) do
        local box = Instance.new("Part")
        box.Name = "FlowerBox"; box.Anchored = true; box.CanCollide = true
        box.Size = Vector3.new(4, 0.8, 1)
        box.Position = position + Vector3.new(side, 0.4, -9.5)
        box.Color = Color3.fromRGB(120, 60, 30)
        box.Material = Enum.Material.Wood; box.Parent = folder

        for f = -1, 1 do
            local flower = Instance.new("Part")
            flower.Name = "Flower"; flower.Anchored = true; flower.CanCollide = false
            flower.Shape = Enum.PartType.Ball
            flower.Size = Vector3.new(0.8, 0.8, 0.8)
            flower.Position = position + Vector3.new(side + f, 1.2, -9.5)
            flower.Color = ({
                Color3.fromRGB(255,100,150),
                Color3.fromRGB(255,200,100),
                Color3.fromRGB(200,100,255),
            })[f+2]
            flower.Material = Enum.Material.SmoothPlastic
            flower.Parent = folder
        end
    end

    -- Sign above door
    local sign = Instance.new("Part")
    sign.Name = "Sign"; sign.Anchored = true; sign.CanCollide = false
    sign.Size = Vector3.new(8, 1.5, 0.3)
    sign.Position = position + Vector3.new(0, 9, -10)
    sign.Color = Color3.fromRGB(230,180,100)
    sign.Material = Enum.Material.SmoothPlastic; sign.Parent = folder

    local gui = Instance.new("SurfaceGui", sign)
    gui.Face = Enum.NormalId.Front; gui.StudsPerPixelX = 0.02
    local lbl = Instance.new("TextLabel", gui)
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = "🐴  STARLIGHT STABLES  🌟"
    lbl.TextColor3 = Color3.fromRGB(80,40,10)
    lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true

    return folder
end

-- ── Leaderboard stand ─────────────────────────────────────
local function buildLeaderboard(position)
    local folder = Instance.new("Folder")
    folder.Name  = "LeaderboardStand"

    local post = Instance.new("Part")
    post.Name = "Post"; post.Anchored = true; post.CanCollide = true
    post.Size = Vector3.new(0.5, 5, 0.5); post.Position = position + Vector3.new(0, 2.5, 0)
    post.Color = Color3.fromRGB(120, 80, 40); post.Material = Enum.Material.Wood
    post.Parent = folder

    local board = Instance.new("Part")
    board.Name = "Board"; board.Anchored = true; board.CanCollide = false
    board.Size = Vector3.new(6, 4, 0.3); board.Position = position + Vector3.new(0, 7, 0)
    board.Color = Color3.fromRGB(30, 20, 60); board.Material = Enum.Material.Neon
    board.Transparency = 0.1; board.Parent = folder

    local sg = Instance.new("SurfaceGui", board)
    sg.Face = Enum.NormalId.Front
    local title = Instance.new("TextLabel", sg)
    title.Size = UDim2.new(1,0,0.3,0); title.BackgroundTransparency = 1
    title.Text = "🏆 TOP RIDERS 🏆"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.Font = Enum.Font.GothamBold; title.TextScaled = true

    local body = Instance.new("TextLabel", sg)
    body.Size = UDim2.new(1,0,0.7,0); body.Position = UDim2.new(0,0,0.3,0)
    body.BackgroundTransparency = 1; body.TextColor3 = Color3.fromRGB(220, 210, 255)
    body.Font = Enum.Font.Gotham; body.TextScaled = true
    body.Text = "1. Loading…\n2. …\n3. …"

    return folder
end

-- ── Spawning in Workspace ─────────────────────────────────
local worldFolder = Instance.new("Folder")
worldFolder.Name  = "WorldProps"
worldFolder.Parent = workspace

-- Stable at centre
local stable = buildStable(Vector3.new(0, 0, 0))
stable.Parent = worldFolder

-- Photo booth
local photoBooth = buildPhotoBooth(Vector3.new(30, 0, 20))
photoBooth.Parent = worldFolder

-- Leaderboard stand
local lb = buildLeaderboard(Vector3.new(-25, 0, -15))
lb.Parent = worldFolder

-- Sample race checkpoints (Meadow Sprint track)
local checkpointColors = {
    Color3.fromRGB(255,215,0),   -- gold start/finish
    Color3.fromRGB(100,220,255), -- cyan
    Color3.fromRGB(200,100,255), -- purple
    Color3.fromRGB(100,255,150), -- green
    Color3.fromRGB(255,150,100), -- orange
}

local meadowCheckpoints = {
    Vector3.new(60,  1, 0),
    Vector3.new(120, 1, 30),
    Vector3.new(160, 1, 80),
    Vector3.new(120, 1, 140),
    Vector3.new(60,  1, 160),
}
for i, pos in ipairs(meadowCheckpoints) do
    local cpFolder, touch = buildCheckpoint("CP_meadow_sprint_"..i, pos, checkpointColors[i])
    cpFolder.Parent = worldFolder

    local trackVal = cpFolder:FindFirstChild("TrackId")
    if trackVal then trackVal.Value = "meadow_sprint" end

    local cpNum = Instance.new("IntValue", cpFolder)
    cpNum.Name = "CheckpointIndex"; cpNum.Value = i

    -- Server-side touch handler will reference these by name
    touch.Touched:Connect(function(hit)
        local char = hit.Parent
        local player = game:GetService("Players"):GetPlayerFromCharacter(char)
        if player then
            game:GetService("ReplicatedStorage")
                :WaitForChild("RemoteEvents")
                :WaitForChild("CheckpointReached")
                :FireClient(player, i, "meadow_sprint")
        end
    end)
end

-- Sample jump course obstacles
local jumpPositions = {
    Vector3.new(80,  1, 50),
    Vector3.new(100, 1, 70),
    Vector3.new(120, 1, 90),
    Vector3.new(100, 1, 110),
    Vector3.new(80,  1, 130),
    Vector3.new(60,  1, 110),
}
local jumpColors = {
    Color3.fromRGB(255,100,100),
    Color3.fromRGB(100,150,255),
    Color3.fromRGB(255,220,80),
    Color3.fromRGB(100,220,120),
    Color3.fromRGB(220,100,255),
    Color3.fromRGB(255,160,80),
}
for i, pos in ipairs(jumpPositions) do
    local jump = buildJumpObstacle("Jump_"..i, pos, 1.5 + i * 0.3, jumpColors[i])
    jump.Parent = worldFolder
end

print("[WorldSetup] World props created. ✨")
