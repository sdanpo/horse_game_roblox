-- ============================================================
-- CameraController.client.lua
-- Third-person orbit camera that follows the horse when
-- mounted, switches to free-roam when dismounted, and
-- supports photo-mode (dolly + free rotate).
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local camera  = workspace.CurrentCamera
local Remote  = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ── Camera state ──────────────────────────────────────────
local CAM_MODE_RIDE      = "ride"      -- follows horse, orbit around it
local CAM_MODE_FREE      = "free"      -- follows character, standard third-person
local CAM_MODE_PHOTO     = "photo"     -- free-fly, no character lock
local CAM_MODE_CINEMATIC = "cinematic" -- locked path for world transitions

local camMode    = CAM_MODE_FREE

-- Orbit angles
local yaw        = 0
local pitch      = math.rad(-20)   -- slight downward tilt
local PITCH_MIN  = math.rad(-70)
local PITCH_MAX  = math.rad(30)

-- Zoom
local zoom       = 18    -- stud distance from subject
local ZOOM_MIN   = 5
local ZOOM_MAX   = 80
local ZOOM_SPEED = 3

-- Sensitivity
local MOUSE_SENS = 0.3   -- degrees per pixel
local TOUCH_SENS = 0.25

-- Target
local subjectModel = nil   -- horse model when mounted, character otherwise

-- Photo mode
local photoActive      = false
local photoCamCFrame   = CFrame.new()

-- ── Utility ───────────────────────────────────────────────
local function getSubjectPosition()
    if subjectModel then
        local body = subjectModel:FindFirstChild("HorseBody") or
                     subjectModel:FindFirstChild("HumanoidRootPart")
        if body then return body.Position + Vector3.new(0, 2, 0) end
    end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position + Vector3.new(0, 1.5, 0) end
    return Vector3.new(0, 5, 0)
end

-- ── Input: mouse delta ────────────────────────────────────
local lastMousePos = nil
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or
           camMode == CAM_MODE_RIDE or
           camMode == CAM_MODE_PHOTO then
            local dx = input.Delta.X * MOUSE_SENS * 0.017   -- to radians
            local dy = input.Delta.Y * MOUSE_SENS * 0.017
            yaw   = yaw   - dx
            pitch = math.clamp(pitch - dy, PITCH_MIN, PITCH_MAX)
        end
    elseif input.UserInputType == Enum.UserInputType.MouseWheel then
        zoom = math.clamp(zoom - input.Position.Z * ZOOM_SPEED, ZOOM_MIN, ZOOM_MAX)
    end
end)

-- ── Input: zoom / mode keys ───────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Photo mode toggle (P)
    if input.KeyCode == Enum.KeyCode.P then
        photoActive = not photoActive
        if photoActive then
            camMode       = CAM_MODE_PHOTO
            photoCamCFrame = camera.CFrame
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        else
            camMode = CAM_MODE_RIDE
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end

    -- Zoom in / out with - / = keys
    if input.KeyCode == Enum.KeyCode.Minus then
        zoom = math.clamp(zoom + 4, ZOOM_MIN, ZOOM_MAX)
    end
    if input.KeyCode == Enum.KeyCode.Equals then
        zoom = math.clamp(zoom - 4, ZOOM_MIN, ZOOM_MAX)
    end
end)

-- ── Photo mode: fly camera with WASD ─────────────────────
local PHOTO_SPEED = 20
local function updatePhotoCam(dt)
    local move = Vector3.new()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0,  1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new( 1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move + Vector3.new(0, -1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0,  1, 0) end

    if move.Magnitude > 0 then
        move = move.Unit
    end

    local worldMove = photoCamCFrame:VectorToWorldSpace(move) * PHOTO_SPEED * dt
    photoCamCFrame  = photoCamCFrame + worldMove
    camera.CFrame   = photoCamCFrame * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
end

-- ── Main camera update ────────────────────────────────────
local prevSubjectPos = Vector3.new()

RunService.RenderStepped:Connect(function(dt)
    if camMode == CAM_MODE_PHOTO then
        updatePhotoCam(dt)
        return
    end

    if camMode == CAM_MODE_CINEMATIC then return end

    -- Smoothly track subject
    local targetPos = getSubjectPosition()
    prevSubjectPos  = prevSubjectPos:Lerp(targetPos, math.min(1, dt * 10))

    -- Orbit offset
    local orbitCF = CFrame.new(prevSubjectPos)
        * CFrame.Angles(0, yaw, 0)
        * CFrame.Angles(pitch, 0, 0)
        * CFrame.new(0, 0, zoom)

    -- Check for walls (simple raycast)
    local rayOrigin  = prevSubjectPos
    local rayDir     = (orbitCF.Position - prevSubjectPos)
    local rayLen     = rayDir.Magnitude
    local raycastResult = workspace:Raycast(rayOrigin, rayDir.Unit * rayLen,
        RaycastParams.new()   -- default params; exclude character in full build
    )
    if raycastResult then
        local safeDist = (raycastResult.Position - rayOrigin).Magnitude - 0.5
        local clampedCF = CFrame.new(prevSubjectPos)
            * CFrame.Angles(0, yaw, 0)
            * CFrame.Angles(pitch, 0, 0)
            * CFrame.new(0, 0, safeDist)
        camera.CFrame = clampedCF
    else
        camera.CFrame = orbitCF
    end

    camera.CameraType = Enum.CameraType.Scriptable
end)

-- ── React to horse spawned: switch subject ────────────────
Remote:WaitForChild("HorseSpawned").OnClientEvent:Connect(function(info)
    task.wait(0.5)
    -- Find the horse model
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HorseBody") then
            subjectModel = obj
            camMode = CAM_MODE_RIDE
            break
        end
    end
end)

-- ── Cinematic intro tween ─────────────────────────────────
Remote:WaitForChild("SetWorldAtmosphere").OnClientEvent:Connect(function(data)
    -- Smooth transition: briefly go to cinematic mode
    camMode = CAM_MODE_CINEMATIC

    local startCF = camera.CFrame
    local targetCF = CFrame.new(getSubjectPosition() + Vector3.new(20, 15, 20),
                                 getSubjectPosition())

    local tween = TweenService:Create(
        camera,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { CFrame = targetCF }
    )
    tween:Play()
    tween.Completed:Connect(function()
        task.wait(1)
        camMode = CAM_MODE_RIDE
    end)
end)

print("[CameraController] Ready.")
