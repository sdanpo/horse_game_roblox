-- ============================================================
-- ShopData.lua
-- Shop categories: horses, accessories, boosts, cosmetics
-- ============================================================

local ShopData = {}

-- ── Rider Outfits ──────────────────────────────────────────
ShopData.RIDER_OUTFITS = {
    {
        id          = "default_outfit",
        name        = "Riding Basics",
        price       = 0,
        description = "Classic breeches, boots, and a riding helmet.",
        preview     = "rbxassetid://OUTFIT_BASIC",
    },
    {
        id          = "floral_rider",
        name        = "Floral Rider",
        price       = 400,
        description = "Pretty floral-print jacket with matching helmet cover.",
        preview     = "rbxassetid://OUTFIT_FLORAL",
    },
    {
        id          = "royal_equestrian",
        name        = "Royal Equestrian",
        price       = 900,
        description = "Crisp white and gold show-jumping ensemble.",
        preview     = "rbxassetid://OUTFIT_ROYAL",
    },
    {
        id          = "fairy_rider",
        name        = "Fairy Rider",
        price       = 0,
        gemPrice    = 30,
        description = "Shimmering outfit with translucent fairy wings and a flower crown.",
        preview     = "rbxassetid://OUTFIT_FAIRY",
    },
    {
        id          = "starlight_rider",
        name        = "Starlight Rider",
        price       = 0,
        gemPrice    = 60,
        description = "Cosmic purple suit that glitters with embedded star-dust.",
        preview     = "rbxassetid://OUTFIT_STARLIGHT",
    },
    {
        id          = "rainbow_rider",
        name        = "Rainbow Rider",
        price       = 0,
        gemPrice    = 45,
        description = "Every colour of the rainbow, head to toe!",
        preview     = "rbxassetid://OUTFIT_RAINBOW",
    },
}

-- ── Rider Accessories ─────────────────────────────────────
ShopData.RIDER_ACCESSORIES = {
    { id="basic_helmet",    name="Classic Helmet",     slot="head",  price=0 },
    { id="flower_helmet",   name="Flower Helmet",      slot="head",  price=250 },
    { id="gem_tiara",       name="Gem Tiara",           slot="head",  gemPrice=20 },
    { id="star_tiara",      name="Star Tiara",          slot="head",  gemPrice=35 },
    { id="butterfly_clip",  name="Butterfly Clip",      slot="hair",  price=150 },
    { id="braid_ribbons",   name="Braid Ribbons",       slot="hair",  price=200 },
    { id="riding_gloves",   name="Riding Gloves",       slot="hands", price=100 },
    { id="sparkling_boots", name="Sparkling Boots",     slot="feet",  price=350 },
    { id="rainbow_scarf",   name="Rainbow Scarf",       slot="neck",  price=300 },
    { id="fairy_wings",     name="Fairy Wings",         slot="back",  gemPrice=25 },
    { id="angel_wings",     name="Angel Wings",         slot="back",  gemPrice=40 },
}

-- ── Boosts (temporary power-ups) ──────────────────────────
ShopData.BOOSTS = {
    {
        id          = "speed_boost",
        name        = "Speed Surge",
        duration    = 300,      -- seconds
        effect      = { speedBonus = 2 },
        price       = 150,
        icon        = "rbxassetid://ICON_BOOST_SPEED",
        description = "Your horse gallops 20% faster for 5 minutes.",
    },
    {
        id          = "stamina_boost",
        name        = "Energy Elixir",
        duration    = 300,
        effect      = { energyDrainMult = 0.5 },
        price       = 150,
        icon        = "rbxassetid://ICON_BOOST_STAMINA",
        description = "Halves energy drain for 5 minutes.",
    },
    {
        id          = "beauty_boost",
        name        = "Glamour Potion",
        duration    = 600,
        effect      = { beautyBonus = 2 },
        price       = 200,
        icon        = "rbxassetid://ICON_BOOST_BEAUTY",
        description = "Adds +2 to beauty score in shows for 10 minutes.",
    },
    {
        id          = "bond_boost",
        name        = "Love Potion",
        duration    = 600,
        effect      = { bondGainMult = 2 },
        price       = 200,
        icon        = "rbxassetid://ICON_BOOST_BOND",
        description = "Doubles all bond gains for 10 minutes.",
    },
    {
        id          = "xp_boost",
        name        = "Star XP Charm",
        duration    = 900,
        effect      = { xpMult = 1.5 },
        gemPrice    = 10,
        icon        = "rbxassetid://ICON_BOOST_XP",
        description = "Earn 50% more XP for 15 minutes.",
    },
    {
        id          = "coin_boost",
        name        = "Golden Horseshoe",
        duration    = 900,
        effect      = { coinMult = 1.5 },
        gemPrice    = 10,
        icon        = "rbxassetid://ICON_BOOST_COIN",
        description = "Earn 50% more coins for 15 minutes.",
    },
}

-- ── Stable Decorations ────────────────────────────────────
ShopData.STABLE_DECORATIONS = {
    { id="flower_wreath",   name="Flower Wreath",      price=200,  slot="door" },
    { id="star_banner",     name="Star Banner",         price=300,  slot="wall" },
    { id="rose_planter",    name="Rose Planter",        price=250,  slot="floor" },
    { id="lantern_set",     name="Lantern Set",         price=400,  slot="ceiling" },
    { id="gem_feed_bucket", name="Gem Feed Bucket",     gemPrice=8, slot="floor" },
    { id="rainbow_hay",     name="Rainbow Hay",         gemPrice=5, slot="floor" },
    { id="crystal_trough",  name="Crystal Water Trough",gemPrice=12,slot="floor" },
    { id="fairy_lights",    name="Fairy Lights",        gemPrice=15,slot="ceiling" },
    { id="trophy_shelf",    name="Trophy Shelf",        price=500,  slot="wall" },
    { id="photo_frame",     name="Photo Frame",         price=150,  slot="wall" },
}

-- ── Coin Pack / Gem Pack (for UI display only – actual
--    purchases go through Roblox DevProducts/Gamepasses) ──
ShopData.GEM_PACKS = {
    { id="gems_80",   gems=80,   robux=99,   bonus=0,    label="Starter Pack" },
    { id="gems_200",  gems=200,  robux=199,  bonus=20,   label="Value Pack" },
    { id="gems_500",  gems=500,  robux=399,  bonus=75,   label="Popular Pack" },
    { id="gems_1200", gems=1200, robux=799,  bonus=250,  label="Mega Pack" },
    { id="gems_2500", gems=2500, robux=1499, bonus=700,  label="Ultimate Pack" },
}

ShopData.GAMEPASSES = {
    { id="vip_pass",       name="VIP Rider Pass",   robux=299, perks={ coinMult=1.25, exclusiveOutfit="vip_rider", specialTrail="VIPSparkle" } },
    { id="unlimited_stalls",name="Unlimited Stalls", robux=199, perks={ stableSlots=12 } },
    { id="auto_care",      name="Auto-Groomer",      robux=149, perks={ autoGroom=true, autoFeed=true } },
}

return ShopData
