-- ============================================================
-- HorseData.lua
-- All horse breeds, stats, colors, and accessories
-- ============================================================

local HorseData = {}

-- ── Rarity Tiers ───────────────────────────────────────────
HorseData.RARITY = {
    COMMON    = { name = "Common",    color = Color3.fromRGB(180,180,180), starCount = 1 },
    RARE      = { name = "Rare",      color = Color3.fromRGB(80, 160, 255), starCount = 2 },
    EPIC      = { name = "Epic",      color = Color3.fromRGB(200, 80, 255),  starCount = 3 },
    LEGENDARY = { name = "Legendary", color = Color3.fromRGB(255, 200, 0),   starCount = 4 },
    MYTHICAL  = { name = "Mythical",  color = Color3.fromRGB(255, 100, 180), starCount = 5 },
}

-- ── Breed Definitions ──────────────────────────────────────
-- speed      : 1-10 (affects race velocity)
-- stamina    : 1-10 (affects energy drain)
-- agility    : 1-10 (affects turning & jump height)
-- beauty     : 1-10 (affects show-score bonus)
-- price      : cost in coins (0 = starter horse)
-- gemPrice   : cost in gems (nil = coin-only)
-- unlockLevel: player level required
-- rarity     : key into HorseData.RARITY
-- description: flavour text shown in stable UI

HorseData.BREEDS = {
    -- ── Starter Horses ────────────────────────────────────
    {
        id          = "sunrise_pony",
        name        = "Sunrise Pony",
        rarity      = "COMMON",
        speed       = 4,
        stamina     = 6,
        agility     = 5,
        beauty      = 5,
        price       = 0,
        unlockLevel = 1,
        description = "A sweet little pony perfect for every new rider. Her warm chestnut coat glows at dawn.",
        bodyColor   = Color3.fromRGB(180, 100, 50),
        maneColor   = Color3.fromRGB(90, 50, 20),
        tailColor   = Color3.fromRGB(90, 50, 20),
        eyeColor    = Color3.fromRGB(90, 60, 30),
        modelId     = "rbxassetid://PONY_MODEL_ID",
        icon        = "rbxassetid://PONY_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_1", gallop = "rbxassetid://SFX_GALLOP_SOFT" },
    },
    {
        id          = "silver_star",
        name        = "Silver Star",
        rarity      = "COMMON",
        speed       = 5,
        stamina     = 5,
        agility     = 5,
        beauty      = 6,
        price       = 300,
        unlockLevel = 1,
        description = "A dapple-grey filly with a perfect white star on her forehead. Gentle and reliable.",
        bodyColor   = Color3.fromRGB(200, 200, 210),
        maneColor   = Color3.fromRGB(240, 240, 245),
        tailColor   = Color3.fromRGB(240, 240, 245),
        eyeColor    = Color3.fromRGB(80, 100, 140),
        modelId     = "rbxassetid://HORSE_MODEL_ID",
        icon        = "rbxassetid://SILVER_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_2", gallop = "rbxassetid://SFX_GALLOP_MED" },
    },

    -- ── Rare Horses ───────────────────────────────────────
    {
        id          = "moonwhisper",
        name        = "Moonwhisper",
        rarity      = "RARE",
        speed       = 6,
        stamina     = 6,
        agility     = 7,
        beauty      = 7,
        price       = 1200,
        unlockLevel = 5,
        description = "A pale blue roan who seems to whisper secrets from the moon. Her hooves leave faint glowing prints.",
        bodyColor   = Color3.fromRGB(180, 195, 230),
        maneColor   = Color3.fromRGB(210, 220, 255),
        tailColor   = Color3.fromRGB(210, 220, 255),
        eyeColor    = Color3.fromRGB(120, 160, 230),
        particleEffect = "MoonGlow",
        modelId     = "rbxassetid://HORSE_MODEL_ID",
        icon        = "rbxassetid://MOON_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_3", gallop = "rbxassetid://SFX_GALLOP_MED" },
    },
    {
        id          = "rosebud",
        name        = "Rosebud",
        rarity      = "RARE",
        speed       = 5,
        stamina     = 7,
        agility     = 6,
        beauty      = 9,
        price       = 1500,
        unlockLevel = 5,
        description = "A pale pink mare with a flowing rose-gold mane. She earns extra beauty scores in dressage.",
        bodyColor   = Color3.fromRGB(255, 210, 220),
        maneColor   = Color3.fromRGB(230, 160, 170),
        tailColor   = Color3.fromRGB(230, 160, 170),
        eyeColor    = Color3.fromRGB(200, 100, 130),
        particleEffect = "RosePetals",
        modelId     = "rbxassetid://HORSE_MODEL_ID",
        icon        = "rbxassetid://ROSE_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_2", gallop = "rbxassetid://SFX_GALLOP_SOFT" },
    },
    {
        id          = "thunderstep",
        name        = "Thunderstep",
        rarity      = "RARE",
        speed       = 8,
        stamina     = 5,
        agility     = 5,
        beauty      = 5,
        price       = 1800,
        unlockLevel = 8,
        description = "A bold black stallion bred for speed. His hoofbeats sound like distant thunder.",
        bodyColor   = Color3.fromRGB(30, 25, 25),
        maneColor   = Color3.fromRGB(20, 15, 15),
        tailColor   = Color3.fromRGB(20, 15, 15),
        eyeColor    = Color3.fromRGB(220, 60, 60),
        particleEffect = "LightningTrail",
        modelId     = "rbxassetid://HORSE_MODEL_ID",
        icon        = "rbxassetid://THUNDER_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_4", gallop = "rbxassetid://SFX_GALLOP_HEAVY" },
    },

    -- ── Epic Horses ───────────────────────────────────────
    {
        id          = "aurora_dancer",
        name        = "Aurora Dancer",
        rarity      = "EPIC",
        speed       = 7,
        stamina     = 8,
        agility     = 9,
        beauty      = 8,
        price       = 4000,
        unlockLevel = 15,
        description = "A shimmering mare whose coat shifts through northern-light colours. She excels at show jumping.",
        bodyColor   = Color3.fromRGB(150, 200, 255),
        maneColor   = Color3.fromRGB(180, 130, 255),
        tailColor   = Color3.fromRGB(130, 220, 200),
        eyeColor    = Color3.fromRGB(100, 230, 200),
        particleEffect = "AuroraTrail",
        modelId     = "rbxassetid://HORSE_MODEL_ID",
        icon        = "rbxassetid://AURORA_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_5", gallop = "rbxassetid://SFX_GALLOP_MED" },
    },
    {
        id          = "crystal_mist",
        name        = "Crystal Mist",
        rarity      = "EPIC",
        speed       = 7,
        stamina     = 9,
        agility     = 7,
        beauty      = 9,
        price       = 4500,
        gemPrice    = 40,
        unlockLevel = 15,
        description = "A translucent white horse that seems made of living crystal. Her beauty score is legendary.",
        bodyColor   = Color3.fromRGB(240, 248, 255),
        maneColor   = Color3.fromRGB(200, 230, 255),
        tailColor   = Color3.fromRGB(200, 230, 255),
        eyeColor    = Color3.fromRGB(160, 210, 255),
        particleEffect = "CrystalSparkle",
        modelId     = "rbxassetid://HORSE_MODEL_ID",
        icon        = "rbxassetid://CRYSTAL_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_5", gallop = "rbxassetid://SFX_GALLOP_SOFT" },
    },

    -- ── Legendary Horses ──────────────────────────────────
    {
        id          = "starfire",
        name        = "Starfire",
        rarity      = "LEGENDARY",
        speed       = 9,
        stamina     = 8,
        agility     = 8,
        beauty      = 9,
        price       = 0,
        gemPrice    = 150,
        unlockLevel = 25,
        description = "Born from a fallen star, Starfire blazes gold and leaves a trail of stardust. The envy of every stable.",
        bodyColor   = Color3.fromRGB(255, 200, 50),
        maneColor   = Color3.fromRGB(255, 230, 100),
        tailColor   = Color3.fromRGB(255, 230, 100),
        eyeColor    = Color3.fromRGB(255, 140, 0),
        particleEffect = "StardustTrail",
        modelId     = "rbxassetid://HORSE_MODEL_ID",
        icon        = "rbxassetid://STARFIRE_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_LEGENDARY", gallop = "rbxassetid://SFX_GALLOP_HEAVY" },
    },
    {
        id          = "nebula_dream",
        name        = "Nebula Dream",
        rarity      = "LEGENDARY",
        speed       = 8,
        stamina     = 9,
        agility     = 9,
        beauty      = 10,
        price       = 0,
        gemPrice    = 200,
        unlockLevel = 30,
        description = "A horse painted with the colours of distant galaxies. Her mane flows like cosmic silk.",
        bodyColor   = Color3.fromRGB(80, 40, 120),
        maneColor   = Color3.fromRGB(200, 100, 255),
        tailColor   = Color3.fromRGB(100, 200, 255),
        eyeColor    = Color3.fromRGB(200, 150, 255),
        particleEffect = "CosmicDust",
        modelId     = "rbxassetid://HORSE_MODEL_ID",
        icon        = "rbxassetid://NEBULA_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_LEGENDARY", gallop = "rbxassetid://SFX_GALLOP_HEAVY" },
    },

    -- ── Mythical / Event Horses ───────────────────────────
    {
        id          = "unicorn_dream",
        name        = "Lumina (Unicorn)",
        rarity      = "MYTHICAL",
        speed       = 10,
        stamina     = 10,
        agility     = 10,
        beauty      = 10,
        price       = 0,
        gemPrice    = 500,
        unlockLevel = 40,
        description = "A radiant unicorn whose horn casts healing light. Riding her feels like flying through rainbows.",
        bodyColor   = Color3.fromRGB(255, 245, 255),
        maneColor   = Color3.fromRGB(255, 200, 230),
        tailColor   = Color3.fromRGB(200, 220, 255),
        eyeColor    = Color3.fromRGB(220, 180, 255),
        hornColor   = Color3.fromRGB(255, 215, 0),
        particleEffect = "RainbowAura",
        isUnicorn   = true,
        modelId     = "rbxassetid://UNICORN_MODEL_ID",
        icon        = "rbxassetid://UNICORN_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_MAGICAL", gallop = "rbxassetid://SFX_GALLOP_MAGICAL" },
    },
    {
        id          = "pegasus_sky",
        name        = "Zephyr (Pegasus)",
        rarity      = "MYTHICAL",
        speed       = 10,
        stamina     = 9,
        agility     = 10,
        beauty      = 9,
        price       = 0,
        gemPrice    = 500,
        unlockLevel = 40,
        description = "A winged horse of white feathers and cloud-grey body. She can glide above the ground while galloping.",
        bodyColor   = Color3.fromRGB(245, 245, 255),
        maneColor   = Color3.fromRGB(255, 255, 255),
        tailColor   = Color3.fromRGB(255, 255, 255),
        eyeColor    = Color3.fromRGB(100, 180, 255),
        wingColor   = Color3.fromRGB(255, 255, 255),
        particleEffect = "CloudTrail",
        hasFlight   = true,
        modelId     = "rbxassetid://PEGASUS_MODEL_ID",
        icon        = "rbxassetid://PEGASUS_ICON_ID",
        sounds      = { whinny = "rbxassetid://SFX_WHINNY_MAGICAL", gallop = "rbxassetid://SFX_GALLOP_MAGICAL" },
    },
}

-- ── Saddle & Tack Accessories ──────────────────────────────
HorseData.SADDLES = {
    { id="basic_saddle",    name="Basic Saddle",       price=0,    gemPrice=nil, description="A well-worn but reliable saddle." },
    { id="floral_saddle",   name="Floral Saddle",      price=200,  gemPrice=nil, description="Embroidered with pretty wildflowers." },
    { id="royal_saddle",    name="Royal Saddle",       price=800,  gemPrice=nil, description="Deep crimson with gold trim." },
    { id="rainbow_saddle",  name="Rainbow Saddle",     price=0,    gemPrice=25,  description="Shimmers with every colour of the rainbow." },
    { id="starlight_saddle",name="Starlight Saddle",   price=0,    gemPrice=60,  description="Encrusted with tiny glowing gems." },
    { id="fairy_saddle",    name="Fairy Saddle",       price=0,    gemPrice=80,  description="Gossamer-light with butterfly wings on the stirrups." },
}

HorseData.MANE_STYLES = {
    { id="natural",     name="Natural",          price=0   },
    { id="braided",     name="Braided",          price=150  },
    { id="flowing",     name="Flowing",          price=300  },
    { id="rosettes",    name="Rosette Braids",   price=500  },
    { id="starweave",   name="Starweave",        price=0,    gemPrice=15 },
    { id="unicorn_flow",name="Enchanted Flow",   price=0,    gemPrice=35 },
}

HorseData.ACCESSORIES = {
    { id="flower_crown",  name="Flower Crown",        slot="head",  price=250  },
    { id="tiara",         name="Princess Tiara",       slot="head",  gemPrice=20 },
    { id="butterfly_set", name="Butterfly Wings",      slot="back",  price=600  },
    { id="glitter_hooves",name="Glitter Hooves",       slot="hooves",price=300  },
    { id="star_blanket",  name="Star Blanket",         slot="body",  price=400  },
    { id="gem_necklace",  name="Gem Necklace",         slot="neck",  price=350  },
    { id="fairy_tail_bow",name="Fairy Tail Bow",       slot="tail",  gemPrice=10 },
    { id="aurora_wings",  name="Aurora Wings",         slot="back",  gemPrice=50 },
    { id="moon_tiara",    name="Moon Tiara",           slot="head",  gemPrice=30 },
    { id="rose_garland",  name="Rose Garland",         slot="neck",  price=500  },
}

-- ── Helper: get breed by id ────────────────────────────────
function HorseData.getBreed(id)
    for _, breed in ipairs(HorseData.BREEDS) do
        if breed.id == id then return breed end
    end
    return nil
end

-- ── Helper: compute effective speed with bond bonus ────────
-- bondPercent: 0-100
function HorseData.effectiveSpeed(breed, bondPercent)
    local bonus = (bondPercent / 100) * 2   -- max +2 speed from bond
    return math.min(10, breed.speed + bonus)
end

return HorseData
