-- ============================================================
-- WorldData.lua
-- All rideable worlds with their atmosphere, music, and
-- activity configurations.
-- ============================================================

local WorldData = {}

-- ── World Definitions ─────────────────────────────────────
WorldData.WORLDS = {

    -- ── 1. Enchanted Meadow (Starter World) ───────────────
    {
        id            = "EnchantedMeadow",
        name          = "Enchanted Meadow",
        subtitle      = "Where adventures begin",
        unlockLevel   = 1,
        unlockCost    = 0,
        isPremium     = false,

        -- Visual atmosphere
        skyColor      = Color3.fromRGB(180, 220, 255),
        fogColor      = Color3.fromRGB(200, 230, 200),
        fogEnd        = 800,
        ambientColor  = Color3.fromRGB(180, 200, 160),
        sunAngle      = 45,
        timeOfDay     = "14:00:00",

        -- Terrain colours
        grassColor    = Color3.fromRGB(100, 190, 80),
        pathColor     = Color3.fromRGB(200, 180, 140),
        waterColor    = Color3.fromRGB(100, 180, 220),

        -- Decorations spawned into the world
        decorations   = {
            { type="Tree",      variant="Cherry",   density=0.6 },
            { type="Flower",    variant="Daisy",    density=1.2 },
            { type="Flower",    variant="Tulip",    density=0.8 },
            { type="Butterfly", density=0.4 },
            { type="Fountain",  count=2 },
            { type="Barn",      count=1 },
            { type="Windmill",  count=1 },
        },

        -- Ambient particles
        particles     = { "FloatingPetals", "GoldenDust" },

        -- Music playlist (asset IDs)
        music         = {
            "rbxassetid://MUSIC_MEADOW_1",
            "rbxassetid://MUSIC_MEADOW_2",
            "rbxassetid://MUSIC_PEACEFUL",
        },

        -- Activities available here
        activities    = { "TrailRide", "Dressage", "Grooming", "PhotoBooth" },

        -- Race tracks in this world
        raceTracks    = {
            { id="meadow_sprint", name="Meadow Sprint", laps=1, distance=800, difficulty="Easy",   checkpoints=5 },
            { id="valley_loop",   name="Valley Loop",   laps=2, distance=600, difficulty="Easy",   checkpoints=4 },
        },

        -- Jump courses
        jumpCourses   = {
            { id="beginner_blooms", name="Beginner Blooms", obstacles=6, difficulty="Easy" },
        },

        -- Trail ride waypoints
        trailPoints   = 8,

        loadingImage  = "rbxassetid://LOADING_MEADOW",
        thumbnail     = "rbxassetid://THUMB_MEADOW",
        description   = "A magical sunlit meadow full of wildflowers, sparkling streams, and friendly woodland creatures. The perfect place to begin your riding journey!",
    },

    -- ── 2. Crystal Cove ───────────────────────────────────
    {
        id            = "CrystalCove",
        name          = "Crystal Cove",
        subtitle      = "Gallop along shimmering shores",
        unlockLevel   = 5,
        unlockCost    = 500,
        isPremium     = false,

        skyColor      = Color3.fromRGB(130, 200, 255),
        fogColor      = Color3.fromRGB(150, 220, 255),
        fogEnd        = 1000,
        ambientColor  = Color3.fromRGB(170, 200, 230),
        sunAngle      = 35,
        timeOfDay     = "10:00:00",

        grassColor    = Color3.fromRGB(120, 200, 100),
        pathColor     = Color3.fromRGB(230, 210, 170),
        waterColor    = Color3.fromRGB(60, 160, 230),

        decorations   = {
            { type="PalmTree",  density=0.4 },
            { type="Seashell",  density=1.5 },
            { type="Starfish",  density=0.8 },
            { type="CrystalRock", density=0.3 },
            { type="Lighthouse", count=1 },
            { type="BeachHut",  count=3 },
            { type="Pier",      count=1 },
        },

        particles     = { "OceanSpray", "GlitteringWaves", "SeaBubbles" },

        music         = {
            "rbxassetid://MUSIC_BEACH_1",
            "rbxassetid://MUSIC_OCEAN_BREEZE",
            "rbxassetid://MUSIC_SEASIDE",
        },

        activities    = { "TrailRide", "BeachRace", "Dressage", "PhotoBooth", "Tricks" },

        raceTracks    = {
            { id="shoreline_gallop", name="Shoreline Gallop", laps=1, distance=1000, difficulty="Medium", checkpoints=6 },
            { id="pier_circuit",     name="Pier Circuit",     laps=3, distance=500,  difficulty="Easy",   checkpoints=4 },
        },

        jumpCourses   = {
            { id="beach_barriers",   name="Beach Barriers",   obstacles=8, difficulty="Easy" },
            { id="crystal_challenge",name="Crystal Challenge", obstacles=10, difficulty="Medium" },
        },

        trailPoints   = 10,
        loadingImage  = "rbxassetid://LOADING_COVE",
        thumbnail     = "rbxassetid://THUMB_COVE",
        description   = "Gleaming crystal formations rise from turquoise waters as you gallop along golden beaches. Dolphins leap in the waves and seagulls call overhead!",
    },

    -- ── 3. Mystic Forest ──────────────────────────────────
    {
        id            = "MysticForest",
        name          = "Mystic Forest",
        subtitle      = "Ancient trees hide fairy secrets",
        unlockLevel   = 10,
        unlockCost    = 1000,
        isPremium     = false,

        skyColor      = Color3.fromRGB(80, 100, 60),
        fogColor      = Color3.fromRGB(100, 140, 80),
        fogEnd        = 600,
        ambientColor  = Color3.fromRGB(80, 120, 60),
        sunAngle      = 20,
        timeOfDay     = "18:00:00",

        grassColor    = Color3.fromRGB(60, 140, 50),
        pathColor     = Color3.fromRGB(150, 120, 90),
        waterColor    = Color3.fromRGB(60, 120, 80),

        decorations   = {
            { type="AncientTree",  density=0.8 },
            { type="Mushroom",     density=1.0 },
            { type="GlowingOrbs",  density=0.6 },
            { type="FairyHouse",   count=5 },
            { type="WishingWell",  count=2 },
            { type="StoneBridge",  count=3 },
            { type="WillowTree",   density=0.3 },
        },

        particles     = { "FairyDust", "GlowingLeaves", "FirefliesSwarm" },

        music         = {
            "rbxassetid://MUSIC_FOREST_1",
            "rbxassetid://MUSIC_MYSTICAL",
            "rbxassetid://MUSIC_ENCHANTED",
        },

        activities    = { "TrailRide", "TreasureHunt", "Dressage", "PhotoBooth", "FairyQuest" },

        raceTracks    = {
            { id="forest_path",   name="Forest Path",   laps=1, distance=900,  difficulty="Medium", checkpoints=7 },
            { id="root_rally",    name="Root Rally",    laps=2, distance=700,  difficulty="Hard",   checkpoints=6 },
        },

        jumpCourses   = {
            { id="log_leaps",     name="Log Leaps",      obstacles=10, difficulty="Medium" },
            { id="fairy_gates",   name="Fairy Gates",    obstacles=12, difficulty="Hard" },
        },

        trailPoints   = 12,
        specialEvent  = "FairyQuestLine",
        loadingImage  = "rbxassetid://LOADING_FOREST",
        thumbnail     = "rbxassetid://THUMB_FOREST",
        description   = "An ancient forest alive with fairy magic. Glowing mushrooms light hidden paths, fireflies dance between ancient oaks, and mysterious ruins hold treasures waiting to be found!",
    },

    -- ── 4. Winter Wonderland ──────────────────────────────
    {
        id            = "WinterWonderland",
        name          = "Winter Wonderland",
        subtitle      = "Gallop through sparkling snow",
        unlockLevel   = 15,
        unlockCost    = 2000,
        isPremium     = false,

        skyColor      = Color3.fromRGB(190, 210, 255),
        fogColor      = Color3.fromRGB(220, 230, 255),
        fogEnd        = 700,
        ambientColor  = Color3.fromRGB(180, 200, 240),
        sunAngle      = 15,
        timeOfDay     = "12:00:00",

        grassColor    = Color3.fromRGB(240, 248, 255),   -- snow-white
        pathColor     = Color3.fromRGB(200, 220, 245),
        waterColor    = Color3.fromRGB(150, 200, 240),

        decorations   = {
            { type="SnowTree",      density=0.7 },
            { type="Icicle",        density=1.0 },
            { type="SnowGlobe",     count=3 },
            { type="FrozenLake",    count=1 },
            { type="IceCastle",     count=1 },
            { type="CandyCane",     density=0.4 },
            { type="SnowDeer",      count=4 },
        },

        particles     = { "Snowflakes", "IceSparkles", "FrostyBreath" },

        music         = {
            "rbxassetid://MUSIC_WINTER_1",
            "rbxassetid://MUSIC_SNOW_DANCE",
            "rbxassetid://MUSIC_ICE_KINGDOM",
        },

        activities    = { "TrailRide", "SnowRace", "Dressage", "PhotoBooth", "Tricks", "IceJumping" },

        raceTracks    = {
            { id="ice_circuit",    name="Ice Circuit",    laps=2, distance=800,  difficulty="Medium", checkpoints=6 },
            { id="blizzard_run",   name="Blizzard Run",   laps=1, distance=1200, difficulty="Hard",   checkpoints=8 },
        },

        jumpCourses   = {
            { id="icicle_course",  name="Icicle Course",   obstacles=10, difficulty="Medium" },
            { id="frozen_falls",   name="Frozen Falls",    obstacles=14, difficulty="Hard" },
        },

        trailPoints   = 10,
        weatherEffect = "Snowfall",
        loadingImage  = "rbxassetid://LOADING_WINTER",
        thumbnail     = "rbxassetid://THUMB_WINTER",
        description   = "A dazzling kingdom of ice and snow! Gallop past frosted pines, leap over glittering icicles, and discover the magical Ice Castle at the heart of the frozen valley.",
    },

    -- ── 5. Starlight Kingdom (Premium) ───────────────────
    {
        id            = "StarlightKingdom",
        name          = "Starlight Kingdom",
        subtitle      = "Where magic meets the sky",
        unlockLevel   = 20,
        unlockCost    = 0,
        unlockGems    = 50,
        isPremium     = true,

        skyColor      = Color3.fromRGB(20, 10, 60),
        fogColor      = Color3.fromRGB(40, 20, 80),
        fogEnd        = 1200,
        ambientColor  = Color3.fromRGB(80, 60, 140),
        sunAngle      = 0,
        timeOfDay     = "00:00:00",

        grassColor    = Color3.fromRGB(60, 40, 120),
        pathColor     = Color3.fromRGB(180, 160, 220),
        waterColor    = Color3.fromRGB(40, 20, 100),

        decorations   = {
            { type="StarPillar",    density=0.4 },
            { type="GlowingCrystal",density=0.8 },
            { type="MoonArch",      count=3 },
            { type="FloatingIsland",count=4 },
            { type="CelestialFountain", count=2 },
            { type="StarGarden",    count=1 },
            { type="CosmicPortal",  count=2 },
        },

        particles     = { "StarDust", "CosmicNebula", "MeteorShower", "MoonbeamRays" },

        music         = {
            "rbxassetid://MUSIC_CELESTIAL_1",
            "rbxassetid://MUSIC_STARDREAM",
            "rbxassetid://MUSIC_COSMIC_WALTZ",
        },

        activities    = { "TrailRide", "StarRace", "Dressage", "PhotoBooth", "Tricks",
                          "CosmicJumping", "StarHunt", "CelestialDance" },

        raceTracks    = {
            { id="nebula_run",    name="Nebula Run",    laps=1, distance=1400, difficulty="Hard",     checkpoints=8 },
            { id="comet_trail",   name="Comet Trail",   laps=2, distance=1000, difficulty="Hard",     checkpoints=7 },
            { id="galaxy_grand",  name="Galaxy Grand Prix", laps=3, distance=800, difficulty="Expert", checkpoints=6 },
        },

        jumpCourses   = {
            { id="moongate_course", name="Moongate Course", obstacles=12, difficulty="Hard" },
            { id="star_gauntlet",   name="Star Gauntlet",   obstacles=16, difficulty="Expert" },
        },

        trailPoints   = 15,
        exclusiveReward = "NebulaDream_Fragment",
        loadingImage  = "rbxassetid://LOADING_STARLIGHT",
        thumbnail     = "rbxassetid://THUMB_STARLIGHT",
        description   = "Float above the clouds in a kingdom of stars, cosmic light, and floating islands. The most breathtaking world in Starlight Stables — reserved for the most adventurous riders!",
    },

    -- ── 6. Sakura Valley ──────────────────────────────────
    {
        id            = "SakuraValley",
        name          = "Sakura Valley",
        subtitle      = "Petals on the wind",
        unlockLevel   = 12,
        unlockCost    = 1500,
        isPremium     = false,

        skyColor      = Color3.fromRGB(255, 200, 220),
        fogColor      = Color3.fromRGB(255, 210, 230),
        fogEnd        = 900,
        ambientColor  = Color3.fromRGB(240, 190, 210),
        sunAngle      = 40,
        timeOfDay     = "08:00:00",

        grassColor    = Color3.fromRGB(140, 200, 100),
        pathColor     = Color3.fromRGB(220, 190, 160),
        waterColor    = Color3.fromRGB(160, 200, 240),

        decorations   = {
            { type="CherryTree",  density=0.9 },
            { type="Lantern",     density=0.5 },
            { type="Pagoda",      count=2 },
            { type="KoiPond",     count=3 },
            { type="BambooGrove", density=0.3 },
            { type="StoneGarden", count=2 },
            { type="CherryBlossom_Arch", count=4 },
        },

        particles     = { "CherryBlossomPetals", "LanternGlow", "GoldenKoi" },

        music         = {
            "rbxassetid://MUSIC_SAKURA_1",
            "rbxassetid://MUSIC_SPRING_BREEZE",
            "rbxassetid://MUSIC_ORIENTAL_DREAM",
        },

        activities    = { "TrailRide", "Dressage", "PhotoBooth", "Tricks", "PetalRace" },

        raceTracks    = {
            { id="blossom_path",  name="Blossom Path",   laps=2, distance=700,  difficulty="Medium", checkpoints=5 },
            { id="valley_winds",  name="Valley Winds",   laps=1, distance=1100, difficulty="Medium", checkpoints=7 },
        },

        jumpCourses   = {
            { id="bamboo_jumps",  name="Bamboo Jumps",    obstacles=8, difficulty="Medium" },
            { id="petal_gates",   name="Petal Gates",     obstacles=12, difficulty="Hard" },
        },

        trailPoints   = 11,
        loadingImage  = "rbxassetid://LOADING_SAKURA",
        thumbnail     = "rbxassetid://THUMB_SAKURA",
        description   = "A serene valley cloaked in cherry blossom pink. Lanterns glow softly along stone pathways while golden koi leap through crystal streams. Breathtakingly beautiful.",
    },
}

-- ── Helper functions ───────────────────────────────────────
function WorldData.getWorld(id)
    for _, world in ipairs(WorldData.WORLDS) do
        if world.id == id then return world end
    end
    return nil
end

function WorldData.getUnlockedWorlds(playerLevel, ownedWorldIds)
    local owned = {}
    for _, id in ipairs(ownedWorldIds) do owned[id] = true end

    local result = {}
    for _, world in ipairs(WorldData.WORLDS) do
        if owned[world.id] or (world.unlockLevel <= playerLevel and world.unlockCost == 0 and not world.isPremium) then
            table.insert(result, world)
        end
    end
    return result
end

return WorldData
