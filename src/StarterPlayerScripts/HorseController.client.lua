-- ============================================================
-- HorseController.client.lua
-- Handles client-side horse movement, mounting/dismounting,
-- trick inputs, and jump mechanics.
-- ============================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local GameConfig        = require(ReplicatedStorage.Modules.GameConfig)
local HorseData         = require(ReplicatedStorage.Modules.HorseData)

local player   = Players.LocalPlayer
local camera   = workspace.CurrentCamera
local Remote   = ReplicatedStorage:WaitForChild("RemoteEvents")

local function getRemote(name) return Remote:WaitForChild(name) end

-- ── State ─────────────────────────────────────────────────
local mounted       = false
local horseModel    = nil    -- current horse Model in workspace
local horseBreed    = nil    -- HorseData entry
local horseSave     = nil    -- save data from server
local moveDirection = Vector3.new()
local isGalloping   = false
local isJumping     = false
local trickCooldown = false
local currentSpeed  = 0

-- ── Speed tiers ───────────────────────────────────────────
local SPEED_WALK    = 8
local SPEED_TROT    = 16
local SPEED_CANTER  = 28
local SPEED_GALLOP  = 42   -- multiplied by horse.speed/10

-- ── Mount / Dismount ──────────────────────────────────────
local function mount()
    if mounted or not horseModel then return end
    mounted = true

    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return end

    -- Weld player to horse saddle position
    humanoid.PlatformStand = true

    local horseBody = horseModel:FindFirstChild("HorseBody")
    if horseBody then
        local weld = Instance.new("Weld")
        weld.Name   = "MountWeld"
        weld.Part0  = horseBody
        weld.Part1  = hrp
        weld.C0     = CFrame.new(0, 1.8, 0)   -- seat offset above body
        weld.Parent = horseBody

        -- Play mount animation
        getRemote("PlayTrickAnimation"):FireServer("Mount")
    end

    -- Hide default control indicators
    getRemote("ShowNotification"):FireServer(nil)   -- clear any tips
end

local function dismount()
    if not mounted then return end
    mounted = false

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end

    if horseModel then
        local horseBody = horseModel:FindFirstChild("HorseBody")
        if horseBody then
            local weld = horseBody:FindFirstChild("MountWeld")
            if weld then weld:Destroy() end
        end
    end

    currentSpeed = 0
    isGalloping  = false
end

-- ── Key bindings ──────────────────────────────────────────
-- WASD / arrow keys = movement (handled in heartbeat)
-- Space             = jump while mounted, mount/dismount while near horse
-- Shift             = toggle gallop
-- G                 = groom
-- F                 = feed
-- 1-6               = tricks

local TRICK_KEYS = {
    [Enum.KeyCode.One]   = "Rear",
    [Enum.KeyCode.Two]   = "Bow",
    [Enum.KeyCode.Three] = "Spin",
    [Enum.KeyCode.Four]  = "SideStep",
    [Enum.KeyCode.Five]  = "Wave",
    [Enum.KeyCode.Six]   = "Whinny",
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Mount / dismount (Space or E)
    if input.KeyCode == Enum.KeyCode.E or
       (input.KeyCode == Enum.KeyCode.Space and not mounted) then
        if not mounted then
            -- Check proximity to horse
            if horseModel then
                local char = player.Character
                local charHRP = char and char:FindFirstChild("HumanoidRootPart")
                local horseBody = horseModel:FindFirstChild("HorseBody")
                if charHRP and horseBody then
                    local dist = (charHRP.Position - horseBody.Position).Magnitude
                    if dist < 10 then
                        mount()
                    end
                end
            end
        else
            dismount()
        end
        return
    end

    -- Jump (Space while mounted)
    if input.KeyCode == Enum.KeyCode.Space and mounted and not isJumping then
        local horseBody = horseModel and horseModel:FindFirstChild("HorseBody")
        if horseBody and not horseBody.Anchored then
            isJumping = true
            local jumpVelocity = Instance.new("LinearVelocity")
            jumpVelocity.MaxForce = math.huge
            jumpVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
            jumpVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
            jumpVelocity.Velocity = Vector3.new(0, 35, 0)
            local att = Instance.new("Attachment", horseBody)
            jumpVelocity.Attachment0 = att
            jumpVelocity.Parent = horseBody

            task.delay(0.15, function()
                jumpVelocity:Destroy()
                att:Destroy()
            end)
            task.delay(0.8, function()
                isJumping = false
            end)
        end
        return
    end

    -- Toggle gallop (Shift)
    if input.KeyCode == Enum.KeyCode.LeftShift and mounted then
        isGalloping = not isGalloping
        return
    end

    -- Groom (G)
    if input.KeyCode == Enum.KeyCode.G and mounted then
        getRemote("GroomHorse"):FireServer()
        return
    end

    -- Feed (F)
    if input.KeyCode == Enum.KeyCode.F and mounted then
        getRemote("FeedHorse"):FireServer("hay")
        return
    end

    -- Tricks (1-6)
    if mounted and not trickCooldown then
        local trickName = TRICK_KEYS[input.KeyCode]
        if trickName then
            trickCooldown = true
            getRemote("PerformTrick"):FireServer(trickName)
            task.delay(2, function() trickCooldown = false end)
        end
    end
end)

-- ── Movement heartbeat ────────────────────────────────────
local function getMovementInput()
    local dir = Vector3.new()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)    then dir = dir + Vector3.new(0, 0, -1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)  then dir = dir + Vector3.new(0, 0,  1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)  then dir = dir + Vector3.new(-1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then dir = dir + Vector3.new( 1, 0, 0) end
    if dir.Magnitude > 0 then dir = dir.Unit end
    return dir
end

local ACCELERATION = 8    -- studs/s²
local DECELERATION = 12

RunService.Heartbeat:Connect(function(dt)
    if not mounted or not horseModel then return end

    local horseBody = horseModel:FindFirstChild("HorseBody")
    if not horseBody then return end

    -- Speed calculation
    local maxSpeed = isGalloping and
        (SPEED_GALLOP * ((horseBreed and horseBreed.speed or 5) / 10)) or
        SPEED_TROT

    local input   = getMovementInput()
    local moving  = input.Magnitude > 0

    if moving then
        currentSpeed = math.min(maxSpeed, currentSpeed + ACCELERATION * dt)
    else
        currentSpeed = math.max(0, currentSpeed - DECELERATION * dt)
    end

    if currentSpeed < 0.1 then return end

    -- Apply camera-relative direction
    local camCF     = camera.CFrame
    local flatCamLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
    local right      = flatCamLook:Cross(Vector3.new(0, 1, 0))

    local worldDir   = (flatCamLook * -input.Z) + (right * input.X)
    if worldDir.Magnitude > 0 then worldDir = worldDir.Unit end

    -- Rotate horse to face movement direction
    if worldDir.Magnitude > 0 then
        local targetCF = CFrame.new(horseBody.Position, horseBody.Position + worldDir)
        horseBody.CFrame = horseBody.CFrame:Lerp(targetCF, math.min(1, dt * 8))
    end

    -- Move
    local velocity = worldDir * currentSpeed
    horseBody.CFrame = horseBody.CFrame + velocity * dt

    -- Animate legs (simple oscillation)
    local t = tick()
    local legAnim = math.sin(t * currentSpeed * 0.5) * 0.4
    for i = 1, 4 do
        local leg = horseModel:FindFirstChild("Leg"..i)
        if leg then
            local weld = leg:FindFirstChildOfClass("Weld")
            if weld then
                local sign = (i % 2 == 0) and 1 or -1
                weld.C0 = weld.C0 * CFrame.Angles(legAnim * sign * 0.3, 0, 0)
            end
        end
    end
end)

-- ── React to server: horse spawned ───────────────────────
getRemote("HorseSpawned").OnClientEvent:Connect(function(info)
    -- Find the new horse model in workspace by name tag
    local found = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HorseBody") then
            -- Match by ownership (the server sets an attribute)
            if obj:GetAttribute("OwnerId") == player.UserId then
                found = obj
                break
            end
        end
    end
    -- Fallback: take any horse model just spawned
    if not found then
        task.wait(0.5)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name ~= "" and obj:FindFirstChild("HorseBody") then
                found = obj; break
            end
        end
    end
    horseModel = found

    -- Load breed data
    if info and info.breedId then
        horseBreed = HorseData.getBreed(info.breedId)
    end

    -- Show mount hint
    local SoundManager = require(script.Parent.SoundManager)
    SoundManager.play("horse_appear")
end)

-- ── React to trick animation from server ─────────────────
getRemote("PlayTrickAnimation").OnClientEvent:Connect(function(model, trickName)
    if model ~= horseModel then return end
    -- In a real project we'd use an AnimationController.
    -- Here we do a simple visual tweak as placeholder.
    local body = model:FindFirstChild("HorseBody")
    if not body then return end

    if trickName == "Rear" then
        local tween = TweenService:Create(body,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { CFrame = body.CFrame * CFrame.Angles(-0.6, 0, 0) }
        )
        tween:Play()
        task.delay(0.5, function()
            TweenService:Create(body,
                TweenInfo.new(0.3, Enum.EasingStyle.Sine),
                { CFrame = body.CFrame * CFrame.Angles(0.6, 0, 0) }
            ):Play()
        end)
    elseif trickName == "Spin" then
        local tween = TweenService:Create(body,
            TweenInfo.new(0.6, Enum.EasingStyle.Linear),
            { CFrame = body.CFrame * CFrame.Angles(0, math.pi * 2, 0) }
        )
        tween:Play()
    elseif trickName == "Bow" then
        local neck = model:FindFirstChild("Neck")
        if neck then
            TweenService:Create(neck,
                TweenInfo.new(0.4, Enum.EasingStyle.Sine),
                { CFrame = neck.CFrame * CFrame.Angles(0.8, 0, 0) }
            ):Play()
            task.delay(0.6, function()
                TweenService:Create(neck,
                    TweenInfo.new(0.4),
                    { CFrame = neck.CFrame * CFrame.Angles(-0.8, 0, 0) }
                ):Play()
            end)
        end
    end
end)

-- ── React to care FX ──────────────────────────────────────
getRemote("PlayCareFX").OnClientEvent:Connect(function(model, actionType)
    if not model then return end
    local body = model:FindFirstChild("HorseBody")
    if not body then return end

    -- Brief glow effect
    local origColor = body.Color
    local glowColor = actionType == "Groom" and
        Color3.fromRGB(255, 220, 255) or
        Color3.fromRGB(255, 240, 180)

    TweenService:Create(body,
        TweenInfo.new(0.3),
        { Color = glowColor }
    ):Play()
    task.delay(0.5, function()
        TweenService:Create(body,
            TweenInfo.new(0.3),
            { Color = origColor }
        ):Play()
    end)
end)

print("[HorseController] Ready.")
