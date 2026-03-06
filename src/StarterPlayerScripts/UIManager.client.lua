-- ============================================================
-- UIManager.client.lua
-- Master UI controller: creates all ScreenGuis, routes
-- between menu screens, handles notifications & transitions.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local HorseData  = require(ReplicatedStorage.Modules.HorseData)
local WorldData  = require(ReplicatedStorage.Modules.WorldData)
local ShopData   = require(ReplicatedStorage.Modules.ShopData)
local AchData    = require(ReplicatedStorage.Modules.AchievementData)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remote    = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ── Colour aliases ────────────────────────────────────────
local C = GameConfig
local PRIMARY    = C.COLOR_PRIMARY
local SECONDARY  = C.COLOR_SECONDARY
local ACCENT     = C.COLOR_ACCENT
local BG         = C.COLOR_BACKGROUND
local DARK       = C.COLOR_TEXT_DARK
local WHITE      = C.COLOR_TEXT_LIGHT
local SUCCESS    = C.COLOR_SUCCESS
local DANGER     = C.COLOR_DANGER

-- ── Helper: Create a Frame ────────────────────────────────
local function Frame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3   = props.bg    or Color3.fromRGB(255,255,255)
    f.BackgroundTransparency = props.trans or 0
    f.Size               = props.size  or UDim2.new(1,0,1,0)
    f.Position           = props.pos   or UDim2.new(0,0,0,0)
    f.BorderSizePixel    = 0
    f.ClipsDescendants   = props.clip  or false
    if props.name then f.Name = props.name end
    f.Parent = parent
    if props.corner then
        local uic = Instance.new("UICorner", f)
        uic.CornerRadius = UDim.new(0, props.corner)
    end
    return f
end

-- ── Helper: Create a TextLabel ────────────────────────────
local function Label(parent, text, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text       = text
    l.TextColor3 = props.color  or DARK
    l.Font       = props.font   or C.FONT_BODY
    l.TextSize   = props.size   or 16
    l.Size       = props.frame  or UDim2.new(1,0,0,30)
    l.Position   = props.pos    or UDim2.new(0,0,0,0)
    l.TextXAlignment = props.xalign or Enum.TextXAlignment.Left
    l.TextYAlignment = props.yalign or Enum.TextYAlignment.Center
    l.TextWrapped    = props.wrap or false
    if props.name then l.Name = props.name end
    l.Parent = parent
    return l
end

-- ── Helper: Create a TextButton ───────────────────────────
local function Button(parent, text, props, callback)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = props.bg    or PRIMARY
    b.Size             = props.size  or UDim2.new(0, 160, 0, 44)
    b.Position         = props.pos   or UDim2.new(0, 0, 0, 0)
    b.Text             = text
    b.TextColor3       = props.color or WHITE
    b.Font             = props.font  or C.FONT_TITLE
    b.TextSize         = props.tsize or 16
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    if props.name then b.Name = props.name end
    b.Parent = parent
    local uic = Instance.new("UICorner", b)
    uic.CornerRadius = UDim.new(0, props.corner or 10)

    -- Hover / press animations
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = props.hoverBg or SECONDARY
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = props.bg or PRIMARY
        }):Play()
    end)
    if callback then
        b.Activated:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.07), { Size = b.Size - UDim2.new(0,4,0,4) }):Play()
            task.delay(0.1, function()
                TweenService:Create(b, TweenInfo.new(0.07), { Size = props.size or UDim2.new(0,160,0,44) }):Play()
            end)
            callback()
        end)
    end
    return b
end

-- ── Helper: UIGradient ────────────────────────────────────
local function Gradient(parent, c1, c2, rotation)
    local g = Instance.new("UIGradient", parent)
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rotation or 90
end

-- ── Session state ─────────────────────────────────────────
local sessionPlayerData = nil   -- populated once server sends it
local activeMenu        = nil   -- currently open sub-menu name

-- ── ScreenGui roots ───────────────────────────────────────
local function makeScreenGui(name, displayOrder)
    local sg = Instance.new("ScreenGui")
    sg.Name            = name
    sg.ResetOnSpawn    = false
    sg.DisplayOrder    = displayOrder or 10
    sg.IgnoreGuiInset  = false
    sg.Parent          = playerGui
    return sg
end

local HUDGui      = makeScreenGui("HUD",       10)
local MenuGui     = makeScreenGui("Menus",     20)
local NotifGui    = makeScreenGui("Notifs",    30)
local LoadingGui  = makeScreenGui("Loading",   40)

-- ══════════════════════════════════════════════════════════
-- LOADING SCREEN
-- ══════════════════════════════════════════════════════════
local loadFrame = Frame(LoadingGui, { bg=Color3.fromRGB(20,10,40), size=UDim2.new(1,0,1,0), name="LoadFrame" })
Gradient(loadFrame, Color3.fromRGB(20,10,60), Color3.fromRGB(60,20,100))

local loadTitle = Label(loadFrame, "✨ Starlight Stables ✨", {
    color = ACCENT, font = C.FONT_TITLE, size = 42,
    frame = UDim2.new(1,0,0,60), pos = UDim2.new(0,0,0.35,0),
    xalign = Enum.TextXAlignment.Center
})

local loadSub = Label(loadFrame, "Loading your adventure…", {
    color = WHITE, font = C.FONT_BODY, size = 20,
    frame = UDim2.new(1,0,0,30), pos = UDim2.new(0,0,0.48,0),
    xalign = Enum.TextXAlignment.Center
})

local loadBar = Frame(loadFrame, {
    bg = Color3.fromRGB(40,30,70),
    size = UDim2.new(0.5,0,0,10),
    pos  = UDim2.new(0.25,0,0.56,0),
    corner = 5
})
local loadFill = Frame(loadBar, { bg = ACCENT, size = UDim2.new(0,0,1,0), corner=5 })
Gradient(loadFill, ACCENT, PRIMARY)

-- Animate fill
task.spawn(function()
    TweenService:Create(loadFill, TweenInfo.new(2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(1,0,1,0)
    }):Play()
    task.wait(2.5)
    TweenService:Create(loadFrame, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
    task.wait(0.8)
    LoadingGui.Enabled = false
end)

-- ══════════════════════════════════════════════════════════
-- MAIN HUD
-- ══════════════════════════════════════════════════════════
-- ── Top bar: currency & player level ─────────────────────
local topBar = Frame(HUDGui, {
    bg   = Color3.fromRGB(30, 20, 50),
    trans = 0.2,
    size = UDim2.new(1,0,0,50),
    name = "TopBar"
})
Gradient(topBar, Color3.fromRGB(60,20,100), Color3.fromRGB(20,10,50))
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0,0)

-- Coin display
local coinFrame = Frame(topBar, { bg=Color3.fromRGB(255,200,0), trans=0, size=UDim2.new(0,120,0,34), pos=UDim2.new(0,10,0,8), corner=17 })
local coinIcon  = Label(coinFrame, "🪙", { color=DARK, size=20, frame=UDim2.new(0,34,1,0), xalign=Enum.TextXAlignment.Center })
local coinLabel = Label(coinFrame, "0", { color=DARK, font=C.FONT_TITLE, size=15, frame=UDim2.new(1,-38,1,0), pos=UDim2.new(0,34,0,0), name="CoinCount" })

-- Gem display
local gemFrame  = Frame(topBar, { bg=Color3.fromRGB(180,100,255), trans=0, size=UDim2.new(0,100,0,34), pos=UDim2.new(0,140,0,8), corner=17 })
local gemIcon   = Label(gemFrame, "💎", { color=WHITE, size=18, frame=UDim2.new(0,30,1,0), xalign=Enum.TextXAlignment.Center })
local gemLabel  = Label(gemFrame, "0", { color=WHITE, font=C.FONT_TITLE, size=15, frame=UDim2.new(1,-34,1,0), pos=UDim2.new(0,32,0,0), name="GemCount" })

-- Player level badge
local lvlFrame  = Frame(topBar, { bg=SECONDARY, trans=0, size=UDim2.new(0,90,0,34), pos=UDim2.new(1,-100,0,8), corner=17 })
local lvlLabel  = Label(lvlFrame, "Lv. 1", { color=WHITE, font=C.FONT_TITLE, size=15, frame=UDim2.new(1,0,1,0), xalign=Enum.TextXAlignment.Center, name="LevelLabel" })

-- XP bar
local xpBar  = Frame(HUDGui, { bg=Color3.fromRGB(40,30,70), trans=0.3, size=UDim2.new(0.4,0,0,6), pos=UDim2.new(0.3,0,0,50), corner=3 })
local xpFill = Frame(xpBar,  { bg=SECONDARY, size=UDim2.new(0,0,1,0), corner=3, name="XPFill" })
Gradient(xpFill, SECONDARY, PRIMARY)

-- ── Bottom action bar ─────────────────────────────────────
local bottomBar = Frame(HUDGui, {
    bg    = Color3.fromRGB(30,20,50),
    trans = 0.2,
    size  = UDim2.new(0, 420, 0, 64),
    pos   = UDim2.new(0.5, -210, 1, -74),
    corner = 16,
    name  = "BottomBar"
})
Gradient(bottomBar, Color3.fromRGB(60,20,100), Color3.fromRGB(20,10,50))

local NAV_ITEMS = {
    { icon="🏠", label="Home",   menu="home"   },
    { icon="🐴", label="Stable", menu="stable" },
    { icon="🌍", label="Worlds", menu="worlds" },
    { icon="🏆", label="Race",   menu="race"   },
    { icon="👥", label="Social", menu="social" },
    { icon="🛒", label="Shop",   menu="shop"   },
}

for i, item in ipairs(NAV_ITEMS) do
    local btn = Button(bottomBar, item.icon.."\n"..item.label, {
        bg     = Color3.fromRGB(0,0,0,0),
        color  = WHITE,
        size   = UDim2.new(0, 60, 0, 56),
        pos    = UDim2.new(0, (i-1)*68 + 8, 0, 4),
        tsize  = 11,
        corner = 10,
        hoverBg = Color3.fromRGB(80,50,120),
    }, function()
        UIManager.openMenu(item.menu)
    end)
    btn.TextScaled = true
end

-- ── Horse status bar (bottom-left) ────────────────────────
local horseStatus = Frame(HUDGui, {
    bg    = Color3.fromRGB(30,20,50),
    trans = 0.2,
    size  = UDim2.new(0, 220, 0, 90),
    pos   = UDim2.new(0, 10, 1, -100),
    corner = 12,
    name  = "HorseStatus"
})
Gradient(horseStatus, Color3.fromRGB(60,20,80), Color3.fromRGB(20,10,40))

Label(horseStatus, "🐴 My Horse", { color=ACCENT, font=C.FONT_TITLE, size=13, frame=UDim2.new(1,-10,0,22), pos=UDim2.new(0,10,0,4) })

-- Bond bar
local bondBg   = Frame(horseStatus, { bg=Color3.fromRGB(40,20,60), size=UDim2.new(1,-20,0,10), pos=UDim2.new(0,10,0,30), corner=5 })
local bondFill = Frame(bondBg,     { bg=Color3.fromRGB(255,100,180), size=UDim2.new(0,0,1,0), corner=5, name="BondFill" })
Gradient(bondFill, Color3.fromRGB(255,100,180), Color3.fromRGB(255,180,220))
Label(horseStatus, "❤️ Bond", { color=Color3.fromRGB(255,150,200), size=10, frame=UDim2.new(0,60,0,10), pos=UDim2.new(0,10,0,20) })

-- Energy bar
local energyBg   = Frame(horseStatus, { bg=Color3.fromRGB(40,20,60), size=UDim2.new(1,-20,0,10), pos=UDim2.new(0,10,0,56), corner=5 })
local energyFill = Frame(energyBg,   { bg=Color3.fromRGB(100,220,100), size=UDim2.new(1,0,1,0), corner=5, name="EnergyFill" })
Gradient(energyFill, Color3.fromRGB(80,200,100), Color3.fromRGB(180,255,150))
Label(horseStatus, "⚡ Energy", { color=Color3.fromRGB(150,255,150), size=10, frame=UDim2.new(0,60,0,10), pos=UDim2.new(0,10,0,46) })

-- ── Mini-map placeholder (top right) ─────────────────────
local minimap = Frame(HUDGui, {
    bg = Color3.fromRGB(20,10,40),
    trans = 0.2,
    size = UDim2.new(0,100,0,100),
    pos  = UDim2.new(1,-110,0,60),
    corner = 12,
    name = "Minimap"
})
Label(minimap, "🗺️ Map", { color=Color3.fromRGB(200,180,255), size=12, frame=UDim2.new(1,0,1,0), xalign=Enum.TextXAlignment.Center, yalign=Enum.TextYAlignment.Center })

-- ── Controls hint (press E to mount) ────────────────────
local ctrlHint = Label(HUDGui, "[E] Mount / Dismount  |  [Shift] Gallop  |  [P] Photo  |  [1-6] Tricks", {
    color = Color3.fromRGB(200,200,200),
    font  = C.FONT_BODY,
    size  = 13,
    frame = UDim2.new(0, 500, 0, 24),
    pos   = UDim2.new(0.5, -250, 1, -26),
    xalign = Enum.TextXAlignment.Center,
    name  = "CtrlHint"
})
ctrlHint.BackgroundTransparency = 1

-- ══════════════════════════════════════════════════════════
-- MENU PANEL (shared slide-in container)
-- ══════════════════════════════════════════════════════════
local menuPanel = Frame(MenuGui, {
    bg     = BG,
    size   = UDim2.new(0, 700, 1, -100),
    pos    = UDim2.new(0.5, -350, 0, 50),
    corner = 20,
    name   = "MenuPanel"
})
menuPanel.Visible = false

-- Close button
local closeBtn = Button(menuPanel, "✕", {
    bg     = DANGER,
    size   = UDim2.new(0, 40, 0, 40),
    pos    = UDim2.new(1, -48, 0, 8),
    tsize  = 20,
    corner = 20,
}, function() UIManager.closeMenu() end)

-- Scrolling content area
local menuScroll = Instance.new("ScrollingFrame")
menuScroll.Name              = "MenuScroll"
menuScroll.Size              = UDim2.new(1, -20, 1, -60)
menuScroll.Position          = UDim2.new(0, 10, 0, 55)
menuScroll.BackgroundTransparency = 1
menuScroll.ScrollBarThickness = 6
menuScroll.ScrollBarImageColor3 = SECONDARY
menuScroll.BorderSizePixel   = 0
menuScroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
menuScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
menuScroll.Parent            = menuPanel

local UIListLayout = Instance.new("UIListLayout", menuScroll)
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ── Menu builder helpers ──────────────────────────────────
local menuBuilders = {}

local function clearMenuContent()
    for _, c in ipairs(menuScroll:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function sectionHeader(title, color)
    local hdr = Label(menuScroll, title, {
        color  = color or DARK,
        font   = C.FONT_TITLE,
        size   = 22,
        frame  = UDim2.new(1,0,0,36),
        xalign = Enum.TextXAlignment.Center
    })
    hdr.LayoutOrder = 1
    return hdr
end

-- ── Card component ────────────────────────────────────────
local function Card(parent, props)
    local card = Frame(parent, {
        bg = props.bg or WHITE,
        size = props.size or UDim2.new(1,-20,0,80),
        corner = 14,
        name = props.name or "Card"
    })
    card.LayoutOrder = props.order or 10
    if props.shadow then
        local sh = Instance.new("UIStroke", card)
        sh.Color = Color3.fromRGB(180,150,220)
        sh.Thickness = 1
    end
    return card
end

-- ══════════════════════════════════════════════════════════
-- STABLE MENU
-- ══════════════════════════════════════════════════════════
menuBuilders["stable"] = function(data)
    clearMenuContent()
    sectionHeader("🐴 My Stable", DARK)

    if not data then
        Label(menuScroll, "Loading stable…", { frame=UDim2.new(1,0,0,40) })
        return
    end

    for idx, horse in ipairs(data.horses or {}) do
        local breed = HorseData.getBreed(horse.breedId) or {}
        local rarityInfo = HorseData.RARITY[breed.rarity or "COMMON"] or {}

        local card = Card(menuScroll, { size=UDim2.new(1,-20,0,90), bg=Color3.fromRGB(250,245,255), order=idx+1, shadow=true })

        -- Horse name & breed
        Label(card, horse.name or breed.name or "Unknown", {
            color=DARK, font=C.FONT_TITLE, size=18,
            frame=UDim2.new(0.6,0,0,28), pos=UDim2.new(0,10,0,6)
        })
        Label(card, (breed.name or ""), {
            color=SECONDARY, size=13,
            frame=UDim2.new(0.6,0,0,18), pos=UDim2.new(0,10,0,28)
        })

        -- Rarity
        Label(card, rarityInfo.name or "", {
            color=rarityInfo.color or DARK, font=C.FONT_TITLE, size=12,
            frame=UDim2.new(0.3,0,0,18), pos=UDim2.new(0,10,0,46)
        })

        -- Bond bar
        local bb = Frame(card, { bg=Color3.fromRGB(220,200,240), size=UDim2.new(0.5,0,0,8), pos=UDim2.new(0,10,0,68), corner=4 })
        Frame(bb, { bg=PRIMARY, size=UDim2.new((horse.bond or 0)/100, 0, 1, 0), corner=4 })
        Label(card, "Bond "..math.floor(horse.bond or 0).."%", {
            color=DARK, size=10,
            frame=UDim2.new(0.5,0,0,16), pos=UDim2.new(0,10,0,52)
        })

        -- Energy
        Label(card, "Energy: "..(horse.energy or 0).."%", {
            color=Color3.fromRGB(80,180,80), size=12,
            frame=UDim2.new(0.35,0,0,18), pos=UDim2.new(0.62,0,0,6)
        })

        -- Level
        Label(card, "Lv."..( horse.level or 1), {
            color=SECONDARY, font=C.FONT_TITLE, size=14,
            frame=UDim2.new(0.2,0,0,24), pos=UDim2.new(0.78,0,0,34)
        })

        -- Select button
        local isActive = (horse.uid == (data.activeHorseUid or ""))
        Button(card, isActive and "Active ✓" or "Select", {
            bg     = isActive and SUCCESS or SECONDARY,
            size   = UDim2.new(0,80,0,28),
            pos    = UDim2.new(1,-90,0,55),
            tsize  = 12,
            corner = 8,
        }, function()
            if not isActive then
                Remote:WaitForChild("SwitchHorse"):FireServer(horse.uid)
            end
        end)

        -- Groom & Feed buttons
        Button(card, "🪮 Groom", { bg=PRIMARY, size=UDim2.new(0,70,0,26), pos=UDim2.new(0.62,0,0,32), tsize=11, corner=8 },
            function() Remote:WaitForChild("GroomHorse"):FireServer() end)
        Button(card, "🍎 Feed", { bg=SUCCESS, size=UDim2.new(0,65,0,26), pos=UDim2.new(0.78,0,0,32), tsize=11, corner=8 },
            function() Remote:WaitForChild("FeedHorse"):FireServer("hay") end)
    end
end

-- ══════════════════════════════════════════════════════════
-- WORLDS MENU
-- ══════════════════════════════════════════════════════════
menuBuilders["worlds"] = function(data)
    clearMenuContent()
    sectionHeader("🌍 Choose Your World", DARK)

    for _, world in ipairs(WorldData.WORLDS) do
        local isUnlocked = data and data.level and (data.level >= world.unlockLevel)
        local isOwned    = false
        if data and data.unlockedWorlds then
            for _, wid in ipairs(data.unlockedWorlds) do
                if wid == world.id then isOwned = true; break end
            end
        end
        local canTravel = isOwned or (isUnlocked and world.unlockCost == 0 and not world.isPremium)

        local card = Card(menuScroll, {
            size  = UDim2.new(1,-20,0,100),
            bg    = canTravel and Color3.fromRGB(240,245,255) or Color3.fromRGB(220,215,230),
            order = 10,
            shadow = true
        })

        -- World name
        Label(card, world.name, { color=DARK, font=C.FONT_TITLE, size=20, frame=UDim2.new(0.65,0,0,28), pos=UDim2.new(0,12,0,6) })
        Label(card, '"'..world.subtitle..'"', { color=SECONDARY, size=13, frame=UDim2.new(0.65,0,0,18), pos=UDim2.new(0,12,0,30) })

        -- Description
        Label(card, world.description:sub(1,100).."…", {
            color=Color3.fromRGB(100,80,120), size=11,
            frame=UDim2.new(0.65,0,0,28), pos=UDim2.new(0,12,0,50),
            wrap=true
        })

        -- Lock / cost info
        if not canTravel then
            local lockMsg = "Requires Lv."..world.unlockLevel
            if world.unlockCost > 0 then lockMsg = lockMsg.." + 🪙"..world.unlockCost end
            if world.isPremium then lockMsg = lockMsg.." + 💎"..(world.unlockGems or 50) end
            Label(card, "🔒 "..lockMsg, { color=DANGER, size=12, frame=UDim2.new(0.3,0,0,18), pos=UDim2.new(0.67,0,0,60) })
        end

        -- Activities tag
        Label(card, "Activities: "..(#world.activities).." | Tracks: "..(#(world.raceTracks or {})), {
            color=Color3.fromRGB(120,100,150), size=11,
            frame=UDim2.new(0.65,0,0,16), pos=UDim2.new(0,12,0,78)
        })

        -- Premium badge
        if world.isPremium then
            local badge = Frame(card, { bg=ACCENT, size=UDim2.new(0,70,0,20), pos=UDim2.new(1,-80,0,6), corner=10 })
            Label(badge, "✨ Premium", { color=DARK, font=C.FONT_TITLE, size=10, frame=UDim2.new(1,0,1,0), xalign=Enum.TextXAlignment.Center })
        end

        -- Travel button
        Button(card, canTravel and "🌟 Travel" or "🔒 Locked", {
            bg     = canTravel and SECONDARY or Color3.fromRGB(160,150,180),
            size   = UDim2.new(0, 90, 0, 34),
            pos    = UDim2.new(1,-100, 0, 33),
            tsize  = 13,
            corner = 10,
        }, canTravel and function()
            Remote:WaitForChild("TravelToWorld"):FireServer(world.id)
            UIManager.closeMenu()
        end or nil)
    end
end

-- ══════════════════════════════════════════════════════════
-- SHOP MENU
-- ══════════════════════════════════════════════════════════
menuBuilders["shop"] = function(data)
    clearMenuContent()
    sectionHeader("🛒 Shop", DARK)

    -- Tab buttons
    local tabs = { "Horses", "Outfits", "Accessories", "Boosts", "Gems" }
    local tabBar = Frame(menuScroll, { bg=Color3.fromRGB(240,235,255), size=UDim2.new(1,-20,0,40), corner=10, name="TabBar" })
    tabBar.LayoutOrder = 2

    for i, tab in ipairs(tabs) do
        Button(tabBar, tab, {
            bg    = i == 1 and SECONDARY or Color3.fromRGB(200,190,220),
            size  = UDim2.new(0, 100, 0, 32),
            pos   = UDim2.new(0, (i-1)*106 + 4, 0, 4),
            tsize = 12, corner = 8,
        }, function()
            -- Rebuild shop for selected category
            menuBuilders["shop_cat"](data, tab)
        end)
    end

    -- Default: show horses
    menuBuilders["shop_cat"](data, "Horses")
end

menuBuilders["shop_cat"] = function(data, category)
    -- Remove old item cards (keep header and tab bar)
    for _, c in ipairs(menuScroll:GetChildren()) do
        if c.Name == "ItemCard" then c:Destroy() end
    end

    local items = {}
    if category == "Horses" then
        items = HorseData.BREEDS
    elseif category == "Outfits" then
        items = ShopData.RIDER_OUTFITS
    elseif category == "Accessories" then
        items = ShopData.RIDER_ACCESSORIES
    elseif category == "Boosts" then
        items = ShopData.BOOSTS
    elseif category == "Gems" then
        items = ShopData.GEM_PACKS
    end

    for i, item in ipairs(items) do
        local card = Card(menuScroll, { size=UDim2.new(1,-20,0,70), bg=Color3.fromRGB(250,248,255), order=i+10, shadow=true })
        card.Name = "ItemCard"

        Label(card, item.name or item.label or "Item", {
            color=DARK, font=C.FONT_TITLE, size=16,
            frame=UDim2.new(0.6,0,0,26), pos=UDim2.new(0,12,0,8)
        })
        Label(card, item.description or "", {
            color=Color3.fromRGB(120,100,140), size=11,
            frame=UDim2.new(0.6,0,0,26), pos=UDim2.new(0,12,0,32),
            wrap=true
        })

        -- Price tag
        local priceStr = ""
        if item.gemPrice then priceStr = "💎 "..item.gemPrice.." gems"
        elseif item.price and item.price > 0 then priceStr = "🪙 "..item.price.." coins"
        elseif item.price == 0 then priceStr = "FREE (starter)"
        elseif item.robux then priceStr = "R$ "..item.robux
        end
        Label(card, priceStr, { color=ACCENT, font=C.FONT_TITLE, size=14, frame=UDim2.new(0.3,0,0,24), pos=UDim2.new(0.65,0,0,8) })

        -- Buy button
        local alreadyOwned = false
        if data then
            if category == "Horses" then
                for _, h in ipairs(data.horses or {}) do
                    if h.breedId == item.id then alreadyOwned = true; break end
                end
            end
        end

        if item.robux then
            Button(card, "Buy (Robux)", { bg=Color3.fromRGB(0,180,0), size=UDim2.new(0,90,0,28), pos=UDim2.new(0.9,-95,0,36), tsize=11, corner=8 },
                function()
                    -- Opens Robux prompt (implement with MarketplaceService on server)
                end)
        elseif not alreadyOwned then
            Button(card, "Buy", { bg=SUCCESS, size=UDim2.new(0,70,0,28), pos=UDim2.new(0.9,-80,0,36), tsize=12, corner=8 },
                function()
                    Remote:WaitForChild("PurchaseItem"):FireServer(
                        category == "Outfits" and "RIDER_OUTFITS" or
                        category == "Boosts" and "BOOSTS" or "ITEM",
                        item.id
                    )
                end)
        else
            Label(card, "✓ Owned", { color=SUCCESS, font=C.FONT_TITLE, size=13, frame=UDim2.new(0.15,0,0,28), pos=UDim2.new(0.82,0,0,38) })
        end
    end
end

-- ══════════════════════════════════════════════════════════
-- SOCIAL MENU
-- ══════════════════════════════════════════════════════════
menuBuilders["social"] = function(data)
    clearMenuContent()
    sectionHeader("👥 Social", DARK)

    -- Online count
    local onlineLabel = Label(menuScroll, "Riders online: …", {
        color=SECONDARY, font=C.FONT_TITLE, size=16,
        frame=UDim2.new(1,0,0,30), xalign=Enum.TextXAlignment.Center,
        name="OnlineLabel"
    })
    onlineLabel.LayoutOrder = 2

    -- Club section
    local clubSection = Frame(menuScroll, { bg=Color3.fromRGB(245,240,255), size=UDim2.new(1,-20,0,120), corner=14, name="ClubSection" })
    clubSection.LayoutOrder = 3

    if data and data.clubId then
        Label(clubSection, "🌸 Your Club", { color=SECONDARY, font=C.FONT_TITLE, size=16, frame=UDim2.new(1,0,0,30), pos=UDim2.new(0,10,0,4) })
        Label(clubSection, "Club ID: "..data.clubId, { color=DARK, size=13, frame=UDim2.new(1,-20,0,20), pos=UDim2.new(0,10,0,34) })
        Button(clubSection, "Leave Club", { bg=DANGER, size=UDim2.new(0,110,0,32), pos=UDim2.new(0,10,0,80), tsize=13, corner=10 },
            function() Remote:WaitForChild("LeaveClub"):FireServer() end)
    else
        Label(clubSection, "🌸 Riding Clubs", { color=SECONDARY, font=C.FONT_TITLE, size=16, frame=UDim2.new(1,0,0,28), pos=UDim2.new(0,10,0,4) })
        Label(clubSection, "Create or join a club to ride together!", { color=DARK, size=13, frame=UDim2.new(1,-20,0,20), pos=UDim2.new(0,10,0,32), wrap=true })
        Button(clubSection, "✨ Create Club", { bg=SECONDARY, size=UDim2.new(0,120,0,34), pos=UDim2.new(0,10,0,78), tsize=13, corner=10 },
            function()
                Remote:WaitForChild("CreateClub"):FireServer("My Stable", "⭐")
            end)
        Button(clubSection, "Join Club", { bg=PRIMARY, size=UDim2.new(0,100,0,34), pos=UDim2.new(0,140,0,78), tsize=13, corner=10 }, function() end)
    end

    -- Leaderboard section
    local lbSection = Frame(menuScroll, { bg=Color3.fromRGB(245,245,255), size=UDim2.new(1,-20,0,200), corner=14, name="LbSection" })
    lbSection.LayoutOrder = 4
    Label(lbSection, "🏆 Top Riders", { color=ACCENT, font=C.FONT_TITLE, size=18, frame=UDim2.new(1,0,0,30), pos=UDim2.new(0,10,0,4), xalign=Enum.TextXAlignment.Center })

    local lbScroll = Instance.new("ScrollingFrame")
    lbScroll.Size = UDim2.new(1,-20,0,155); lbScroll.Position = UDim2.new(0,10,0,36)
    lbScroll.BackgroundTransparency = 1; lbScroll.ScrollBarThickness = 4; lbScroll.Parent = lbSection
    lbScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", lbScroll).Padding = UDim.new(0,4)

    Label(lbScroll, "Loading leaderboard…", { color=SECONDARY, size=13, frame=UDim2.new(1,0,0,24) })

    -- Async load leaderboard
    task.spawn(function()
        local RF = Remote:WaitForChild("GetLeaderboard")
        -- NOTE: This is a RemoteFunction call pattern; in live code use InvokeServer
        task.wait(0.5)
        for _, c in ipairs(lbScroll:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        Label(lbScroll, "🥇  Galaxy Rider — 102 wins", { color=DARK, size=13, frame=UDim2.new(1,0,0,24) })
        Label(lbScroll, "🥈  StarDust Princess — 88 wins", { color=DARK, size=13, frame=UDim2.new(1,0,0,24) })
        Label(lbScroll, "🥉  Crystal Mane — 74 wins", { color=DARK, size=13, frame=UDim2.new(1,0,0,24) })
    end)
end

-- ══════════════════════════════════════════════════════════
-- RACE MENU
-- ══════════════════════════════════════════════════════════
menuBuilders["race"] = function(data)
    clearMenuContent()
    sectionHeader("🏁 Race", DARK)

    for _, world in ipairs(WorldData.WORLDS) do
        for _, track in ipairs(world.raceTracks or {}) do
            local card = Card(menuScroll, { size=UDim2.new(1,-20,0,80), bg=Color3.fromRGB(248,242,255), order=10, shadow=true })

            Label(card, track.name, { color=DARK, font=C.FONT_TITLE, size=17, frame=UDim2.new(0.55,0,0,26), pos=UDim2.new(0,12,0,6) })
            Label(card, world.name, { color=SECONDARY, size=12, frame=UDim2.new(0.55,0,0,18), pos=UDim2.new(0,12,0,28) })
            Label(card, "Laps: "..track.laps.."  |  "..track.difficulty, {
                color=Color3.fromRGB(120,100,150), size=11,
                frame=UDim2.new(0.55,0,0,16), pos=UDim2.new(0,12,0,48)
            })

            local diffColor = track.difficulty == "Easy" and SUCCESS or
                             (track.difficulty == "Medium" and ACCENT or DANGER)
            local diffBadge = Frame(card, { bg=diffColor, size=UDim2.new(0,65,0,22), pos=UDim2.new(0.57,0,0,8), corner=11 })
            Label(diffBadge, track.difficulty, { color=WHITE, font=C.FONT_TITLE, size=11, frame=UDim2.new(1,0,1,0), xalign=Enum.TextXAlignment.Center })

            Button(card, "🏁 Join Race", {
                bg=SECONDARY, size=UDim2.new(0,100,0,32), pos=UDim2.new(0.88,-105,0,40), tsize=12, corner=10
            }, function()
                Remote:WaitForChild("JoinRace"):FireServer(track.id)
                UIManager.closeMenu()
            end)
        end
    end
end

-- ══════════════════════════════════════════════════════════
-- HOME MENU
-- ══════════════════════════════════════════════════════════
menuBuilders["home"] = function(data)
    clearMenuContent()
    sectionHeader("🌟 Welcome, "..(data and player.DisplayName or "Rider").."!", DARK)

    -- Daily quests
    local questSection = Frame(menuScroll, {
        bg=Color3.fromRGB(245,240,255), size=UDim2.new(1,-20,0,0), corner=14, name="Quests"
    })
    questSection.AutomaticSize = Enum.AutomaticSize.Y
    questSection.LayoutOrder = 3

    Label(questSection, "📋 Daily Quests", { color=ACCENT, font=C.FONT_TITLE, size=18, frame=UDim2.new(1,0,0,32), pos=UDim2.new(0,10,0,4), xalign=Enum.TextXAlignment.Center })

    if data and data.dailyQuests then
        local ql = Instance.new("UIListLayout"); ql.Parent = questSection; ql.Padding = UDim.new(0,6)
        for _, qid in ipairs(data.dailyQuests) do
            local quest = nil
            for _, q in ipairs(AchData.DAILY_QUESTS) do
                if q.id == qid then quest = q; break end
            end
            if quest then
                local prog = (data.dailyQuestProgress or {})[qid] or 0
                local qRow = Frame(questSection, { bg=WHITE, size=UDim2.new(1,-20,0,44), corner=10 })
                Label(qRow, quest.name, { color=DARK, font=C.FONT_TITLE, size=14, frame=UDim2.new(0.6,0,0,22), pos=UDim2.new(0,10,0,4) })
                Label(qRow, quest.description, { color=SECONDARY, size=11, frame=UDim2.new(0.6,0,0,16), pos=UDim2.new(0,10,0,24) })
                local rewardStr = quest.reward.coins and "🪙"..quest.reward.coins or "💎"..quest.reward.gems
                Label(qRow, rewardStr, { color=ACCENT, font=C.FONT_TITLE, size=13, frame=UDim2.new(0.2,0,0,24), pos=UDim2.new(0.78,0,0,10) })
                local pbg = Frame(qRow, { bg=Color3.fromRGB(220,210,240), size=UDim2.new(0.36,0,0,6), pos=UDim2.new(0.62,0,0,32), corner=3 })
                Frame(pbg, { bg=SUCCESS, size=UDim2.new(math.min(1,prog), 0, 1, 0), corner=3 })
            end
        end
    else
        Label(questSection, "No quests yet — log in daily to earn them!", { color=DARK, size=13, frame=UDim2.new(1,-20,0,30), pos=UDim2.new(0,10,0,34), wrap=true })
    end

    -- Achievements teaser
    local achSection = Frame(menuScroll, { bg=Color3.fromRGB(245,242,255), size=UDim2.new(1,-20,0,80), corner=14, name="AchSection" })
    achSection.LayoutOrder = 4
    Label(achSection, "🏅 Achievements", { color=SECONDARY, font=C.FONT_TITLE, size=16, frame=UDim2.new(0.6,0,0,28), pos=UDim2.new(0,12,0,6) })
    local achCount = 0
    if data and data.achievements then
        for _ in pairs(data.achievements) do achCount = achCount + 1 end
    end
    Label(achSection, achCount.." / "..#AchData.ACHIEVEMENTS.." unlocked", { color=DARK, size=13, frame=UDim2.new(0.5,0,0,20), pos=UDim2.new(0,12,0,36) })
    Button(achSection, "View All →", { bg=SECONDARY, size=UDim2.new(0,90,0,28), pos=UDim2.new(0.88,-98,0,50-14), tsize=12, corner=10 }, function() end)
end

-- ══════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ══════════════════════════════════════════════════════════
local notifQueue   = {}
local notifRunning = false

local function showNextNotif()
    if #notifQueue == 0 then notifRunning = false; return end
    notifRunning = true
    local notif = table.remove(notifQueue, 1)

    local panel = Frame(NotifGui, {
        bg     = Color3.fromRGB(30,20,50),
        trans  = 0,
        size   = UDim2.new(0, 320, 0, 70),
        pos    = UDim2.new(1, 10,  0, 70),
        corner = 14,
        name   = "NotifPanel"
    })
    Gradient(panel, Color3.fromRGB(60,20,100), Color3.fromRGB(20,10,50))
    local stroke = Instance.new("UIStroke", panel); stroke.Color = PRIMARY; stroke.Thickness = 1.5

    Label(panel, notif.title or "Notice", { color=ACCENT, font=C.FONT_TITLE, size=15, frame=UDim2.new(1,-10,0,26), pos=UDim2.new(0,10,0,6) })
    Label(panel, notif.message or "", { color=WHITE, size=12, frame=UDim2.new(1,-10,0,22), pos=UDim2.new(0,10,0,30), wrap=true })

    -- Slide in
    TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -330, 0, 70)
    }):Play()

    task.delay(notif.duration or 4, function()
        TweenService:Create(panel, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 10, 0, 70)
        }):Play()
        task.delay(0.3, function()
            panel:Destroy()
            showNextNotif()
        end)
    end)
end

local function pushNotif(data)
    table.insert(notifQueue, data)
    if not notifRunning then showNextNotif() end
end

-- ══════════════════════════════════════════════════════════
-- RACE HUD overlay
-- ══════════════════════════════════════════════════════════
local raceHUD = Frame(HUDGui, {
    bg=Color3.fromRGB(0,0,0), trans=0.5,
    size=UDim2.new(1,0,0,50), pos=UDim2.new(0,0,0,50),
    name="RaceHUD"
})
raceHUD.Visible = false
local raceCountdown = Label(raceHUD, "", { color=WHITE, font=C.FONT_TITLE, size=30, frame=UDim2.new(1,0,1,0), xalign=Enum.TextXAlignment.Center, name="RaceCountdown" })
local racePos       = Label(raceHUD, "Position: —", { color=ACCENT, font=C.FONT_TITLE, size=16, frame=UDim2.new(0,200,1,0), pos=UDim2.new(0,10,0,0), name="RacePos" })
local raceTimer     = Label(raceHUD, "0:00", { color=WHITE, font=C.FONT_TITLE, size=16, frame=UDim2.new(0,100,1,0), pos=UDim2.new(1,-110,0,0), name="RaceTimer" })

Remote:WaitForChild("RaceCountdown").OnClientEvent:Connect(function(data)
    raceHUD.Visible = true
    local secs = data.seconds
    task.spawn(function()
        while secs > 0 do
            raceCountdown.Text = "🏁 Starting in "..secs.."…"
            task.wait(1)
            secs = secs - 1
        end
        raceCountdown.Text = "GO! 🐴"
        task.delay(1, function() raceCountdown.Text = "" end)
    end)
end)

Remote:WaitForChild("RaceStarted").OnClientEvent:Connect(function(data)
    local startTime = data.startTime
    task.spawn(function()
        while raceHUD.Visible do
            local elapsed = os.time() - startTime
            local m = math.floor(elapsed / 60)
            local s = elapsed % 60
            raceTimer.Text = string.format("%d:%02d", m, s)
            task.wait(0.5)
        end
    end)
end)

Remote:WaitForChild("RaceResult").OnClientEvent:Connect(function(data)
    raceHUD.Visible = false
    pushNotif({
        title   = data.place == 1 and "🏆 You Won!" or "Race Finished!",
        message = "Position: #"..data.place.."  |  Earned: 🪙"..data.coinsEarned,
        duration = 6,
    })
end)

Remote:WaitForChild("RaceLeaderboardUpdate").OnClientEvent:Connect(function(data)
    for rank, entry in ipairs(data.leaderboard or {}) do
        if entry.userId == player.UserId then
            racePos.Text = "Position: #"..rank
            break
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- SERVER EVENT LISTENERS
-- ══════════════════════════════════════════════════════════
Remote:WaitForChild("InitialPlayerData").OnClientEvent:Connect(function(data)
    sessionPlayerData = data
    coinLabel.Text  = tostring(data.coins or 0)
    gemLabel.Text   = tostring(data.gems  or 0)
    lvlLabel.Text   = "Lv. "..(data.level or 1)

    -- XP bar
    local xpNeeded = 500 * (1.25 ^ math.max(0, (data.level or 1) - 2))
    xpFill.Size = UDim2.new(math.min(1, (data.xp or 0) / xpNeeded), 0, 1, 0)

    -- Horse status
    if data.horses and #data.horses > 0 then
        local activeHorse = data.horses[1]
        for _, h in ipairs(data.horses) do
            if h.uid == data.activeHorseUid then activeHorse = h; break end
        end
        bondFill.Size   = UDim2.new((activeHorse.bond or 0)/100, 0, 1, 0)
        energyFill.Size = UDim2.new((activeHorse.energy or 0)/100, 0, 1, 0)
    end
end)

Remote:WaitForChild("UpdateCurrency").OnClientEvent:Connect(function(data)
    TweenService:Create(coinLabel, TweenInfo.new(0.3), {}):Play()
    coinLabel.Text = tostring(data.coins or 0)
    gemLabel.Text  = tostring(data.gems  or 0)
end)

Remote:WaitForChild("UpdateXP").OnClientEvent:Connect(function(data)
    lvlLabel.Text = "Lv. "..(data.level or 1)
    local xpNeeded = 500 * (1.25 ^ math.max(0, (data.level or 1) - 2))
    TweenService:Create(xpFill, TweenInfo.new(0.4), {
        Size = UDim2.new(math.min(1, (data.xp or 0) / xpNeeded), 0, 1, 0)
    }):Play()
end)

Remote:WaitForChild("PlayerLevelUp").OnClientEvent:Connect(function(data)
    pushNotif({
        title   = "⭐ Level Up! You're now Level "..data.level.."!",
        message = "Keep riding to unlock new horses and worlds!",
        duration = 5,
    })
end)

Remote:WaitForChild("AchievementUnlocked").OnClientEvent:Connect(function(ach)
    pushNotif({
        title   = "🏅 Achievement Unlocked: "..ach.name,
        message = ach.description,
        duration = 6,
    })
end)

Remote:WaitForChild("CareFeedback").OnClientEvent:Connect(function(data)
    if data.success then
        pushNotif({
            title   = data.action == "groom" and "🪮 Groomed!" or "🍎 Fed!",
            message = "Bond +"..( data.bondGain or 0),
            duration = 3,
        })
        if data.newEnergy then
            energyFill.Size = UDim2.new(data.newEnergy/100, 0, 1, 0)
        end
    else
        pushNotif({ title="⏳ Not yet!", message=data.reason, duration=3 })
    end
end)

Remote:WaitForChild("UpdateHorseBond").OnClientEvent:Connect(function(data)
    TweenService:Create(bondFill, TweenInfo.new(0.4), {
        Size = UDim2.new((data.bond or 0)/100, 0, 1, 0)
    }):Play()
end)

Remote:WaitForChild("UpdateHorseEnergy").OnClientEvent:Connect(function(data)
    TweenService:Create(energyFill, TweenInfo.new(0.4), {
        Size = UDim2.new((data.energy or 0)/100, 0, 1, 0)
    }):Play()
end)

Remote:WaitForChild("ShowNotification").OnClientEvent:Connect(function(data)
    if not data then return end
    pushNotif(data)
end)

Remote:WaitForChild("GiftReceived").OnClientEvent:Connect(function(data)
    pushNotif({
        title   = "🎁 Gift from "..data.fromName.."!",
        message = "You received: "..data.itemId,
        duration = 5,
    })
end)

Remote:WaitForChild("OnlineCount").OnClientEvent:Connect(function(data)
    -- update in social menu if open
end)

-- ══════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════
local UIManager = {}

function UIManager.openMenu(name)
    if activeMenu == name then UIManager.closeMenu(); return end
    activeMenu = name

    local builder = menuBuilders[name]
    if builder then
        menuPanel.Visible = true
        TweenService:Create(menuPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0,700,1,-100)
        }):Play()
        builder(sessionPlayerData)
    end
end

function UIManager.closeMenu()
    activeMenu = nil
    TweenService:Create(menuPanel, TweenInfo.new(0.2), {
        Size = UDim2.new(0,0,1,-100)
    }):Play()
    task.delay(0.2, function()
        menuPanel.Visible = false
        clearMenuContent()
    end)
end

-- Escape closes
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Escape and activeMenu then
        UIManager.closeMenu()
    end
end)

return UIManager
