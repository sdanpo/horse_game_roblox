-- ============================================================
-- GameConfig.lua
-- Central configuration for Starlight Stables
-- ============================================================

local GameConfig = {}

-- ── Game Identity ──────────────────────────────────────────
GameConfig.GAME_NAME    = "Starlight Stables"
GameConfig.VERSION      = "1.0.0"
GameConfig.TAGLINE      = "Ride, Bond, and Shine!"

-- ── Economy ────────────────────────────────────────────────
GameConfig.STARTING_COINS       = 500
GameConfig.STARTING_GEMS        = 10
GameConfig.DAILY_LOGIN_COINS    = 100
GameConfig.DAILY_LOGIN_GEMS     = 2
GameConfig.COINS_PER_RACE_WIN   = 150
GameConfig.COINS_PER_RACE_TOP3  = 75
GameConfig.COINS_PER_TRAIL_RIDE = 30     -- awarded per checkpoint
GameConfig.GEM_CONVERSION_RATE  = 100    -- 100 coins = 1 gem

-- ── Player Progression ────────────────────────────────────
GameConfig.MAX_PLAYER_LEVEL     = 50
GameConfig.XP_PER_RACE_WIN      = 200
GameConfig.XP_PER_TRAIL_RIDE    = 50
GameConfig.XP_PER_CARE_ACTION   = 20
GameConfig.XP_PER_TRICK         = 15
GameConfig.LEVEL_XP_BASE        = 500    -- XP needed for level 2
GameConfig.LEVEL_XP_MULTIPLIER  = 1.25   -- each level costs 25% more XP

-- ── Horse Stats ────────────────────────────────────────────
GameConfig.MAX_HORSE_LEVEL      = 30
GameConfig.MAX_HORSE_BOND       = 100    -- 0-100 bond percentage
GameConfig.MAX_HORSE_ENERGY     = 100
GameConfig.ENERGY_DRAIN_RACE    = 30
GameConfig.ENERGY_DRAIN_TRAIL   = 10
GameConfig.ENERGY_REGEN_FEED    = 40
GameConfig.ENERGY_REGEN_REST    = 20
GameConfig.BOND_GAIN_GROOM      = 5
GameConfig.BOND_GAIN_FEED       = 3
GameConfig.BOND_GAIN_RACE_WIN   = 8
GameConfig.BOND_GAIN_TRAIL      = 2

-- ── Racing ─────────────────────────────────────────────────
GameConfig.MAX_RACE_PLAYERS     = 8
GameConfig.MIN_RACE_PLAYERS     = 2
GameConfig.RACE_COUNTDOWN_SECS  = 5
GameConfig.RACE_TIMEOUT_SECS    = 180
GameConfig.RACE_LOBBY_WAIT_SECS = 30

-- ── World/Travel ───────────────────────────────────────────
GameConfig.STARTING_WORLD       = "EnchantedMeadow"
GameConfig.TELEPORT_COST_COINS  = 0      -- worlds are free to visit
GameConfig.PREMIUM_WORLD_UNLOCK_GEMS = 50

-- ── Stable Slots ───────────────────────────────────────────
GameConfig.STARTER_STABLE_SLOTS = 3
GameConfig.MAX_STABLE_SLOTS     = 12
GameConfig.STABLE_SLOT_COST_GEMS = 20    -- per additional slot

-- ── UI Colors (BrickColor / Color3 hex suggestions) ────────
GameConfig.COLOR_PRIMARY        = Color3.fromRGB(230, 130, 200)   -- Soft pink
GameConfig.COLOR_SECONDARY      = Color3.fromRGB(160, 100, 220)   -- Purple
GameConfig.COLOR_ACCENT         = Color3.fromRGB(255, 215, 0)     -- Gold
GameConfig.COLOR_SUCCESS        = Color3.fromRGB(80, 200, 120)    -- Green
GameConfig.COLOR_DANGER         = Color3.fromRGB(220, 80, 80)     -- Red
GameConfig.COLOR_BACKGROUND     = Color3.fromRGB(255, 240, 255)   -- Very light pink
GameConfig.COLOR_TEXT_DARK      = Color3.fromRGB(60, 40, 80)      -- Dark purple-gray
GameConfig.COLOR_TEXT_LIGHT     = Color3.fromRGB(255, 255, 255)   -- White

-- ── Font choices ────────────────────────────────────────────
GameConfig.FONT_TITLE           = Enum.Font.GothamBold
GameConfig.FONT_BODY            = Enum.Font.Gotham
GameConfig.FONT_MONO            = Enum.Font.RobotoMono

-- ── Sparkle / Particle settings ────────────────────────────
GameConfig.SPARKLE_ENABLED      = true
GameConfig.SPARKLE_RATE         = 8      -- particles per second

return GameConfig
