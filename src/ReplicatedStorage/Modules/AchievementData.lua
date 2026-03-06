-- ============================================================
-- AchievementData.lua
-- Badges, achievements, and titles earned by players
-- ============================================================

local AchievementData = {}

AchievementData.ACHIEVEMENTS = {

    -- ── Riding Milestones ─────────────────────────────────
    { id="first_ride",         name="First Ride!",          icon="🐴",
      description="Complete your very first trail ride.",
      reward={ coins=100 }, category="Riding" },

    { id="trail_blazer",       name="Trail Blazer",          icon="🌟",
      description="Complete 10 trail rides.",
      reward={ coins=300 }, category="Riding" },

    { id="world_explorer",     name="World Explorer",        icon="🌍",
      description="Visit every world in Starlight Stables.",
      reward={ coins=500, gems=5 }, category="Riding" },

    { id="speed_demon",        name="Speed Demon",           icon="⚡",
      description="Win 5 races with a time under 2 minutes.",
      reward={ coins=400, title="Speed Demon" }, category="Racing" },

    { id="champion_rider",     name="Champion Rider",        icon="🏆",
      description="Win 50 races total.",
      reward={ coins=1000, gems=15, title="Champion" }, category="Racing" },

    { id="jump_queen",         name="Jump Queen",            icon="👑",
      description="Complete every jump course with a perfect score.",
      reward={ coins=600, gems=8 }, category="Jumping" },

    -- ── Horse Care ────────────────────────────────────────
    { id="horse_whisperer",    name="Horse Whisperer",       icon="💗",
      description="Reach 100% bond with any horse.",
      reward={ coins=500, gems=5, title="Horse Whisperer" }, category="Care" },

    { id="stable_master",      name="Stable Master",         icon="🏡",
      description="Own 5 different horses.",
      reward={ coins=300, gems=3 }, category="Care" },

    { id="perfect_groom",      name="Perfect Groom",         icon="✨",
      description="Groom your horse 30 times.",
      reward={ coins=200 }, category="Care" },

    { id="legendary_collector",name="Legendary Collector",   icon="🌠",
      description="Own at least one Legendary or Mythical horse.",
      reward={ coins=1000, gems=20, title="Legend Keeper" }, category="Care" },

    -- ── Social ────────────────────────────────────────────
    { id="best_friends",       name="Best Friends",          icon="🤝",
      description="Ride together with a friend 10 times.",
      reward={ coins=250 }, category="Social" },

    { id="club_founder",       name="Club Founder",          icon="🌸",
      description="Create your own riding club.",
      reward={ coins=200, gems=2 }, category="Social" },

    { id="photo_star",         name="Photo Star",            icon="📸",
      description="Take 20 photos in the photo booth.",
      reward={ coins=150 }, category="Social" },

    { id="gift_giver",         name="Gift Giver",            icon="🎁",
      description="Send 5 gifts to friends.",
      reward={ coins=100, gems=1 }, category="Social" },

    -- ── Fashion ───────────────────────────────────────────
    { id="fashion_icon",       name="Fashion Icon",          icon="👗",
      description="Collect 10 different rider outfits.",
      reward={ coins=400, title="Fashion Icon" }, category="Fashion" },

    { id="accessory_addict",   name="Accessory Addict",      icon="💎",
      description="Purchase 20 horse accessories.",
      reward={ coins=300 }, category="Fashion" },

    { id="colour_queen",       name="Colour Queen",          icon="🌈",
      description="Customise a horse with 5 different mane styles.",
      reward={ coins=200, gems=2 }, category="Fashion" },

    -- ── Special / Hidden ──────────────────────────────────
    { id="unicorn_rider",      name="Unicorn Rider",         icon="🦄",
      description="[HIDDEN] Ride a Mythical Unicorn.",
      reward={ coins=500, gems=10, title="Unicorn Rider" }, category="Special", hidden=true },

    { id="daily_devotee",      name="Daily Devotee",         icon="📅",
      description="Log in for 30 days in a row.",
      reward={ coins=500, gems=5, title="Devoted Rider" }, category="Special" },

    { id="rainbow_chase",      name="Rainbow Chaser",        icon="🌦️",
      description="[HIDDEN] Find the rainbow in Crystal Cove after rain.",
      reward={ coins=300, gems=3 }, category="Special", hidden=true },

    { id="midnight_ride",      name="Midnight Rider",        icon="🌙",
      description="[HIDDEN] Complete a trail ride in Starlight Kingdom at midnight.",
      reward={ coins=400, gems=5, title="Midnight Rider" }, category="Special", hidden=true },
}

-- ── Player Titles unlocked via achievements ─────────────
AchievementData.TITLES = {
    "Speed Demon", "Champion", "Horse Whisperer", "Legend Keeper",
    "Fashion Icon", "Unicorn Rider", "Devoted Rider", "Midnight Rider",
    "World Explorer",
}

-- ── Daily Quests (re-rolled each day) ────────────────────
AchievementData.DAILY_QUESTS = {
    { id="dq_trail",   name="Morning Rider",      description="Complete 2 trail rides.",     reward={ coins=80 } },
    { id="dq_race",    name="Race Challenger",    description="Finish a race (any placing).", reward={ coins=60 } },
    { id="dq_groom",   name="Grooming Time",      description="Groom your horse 3 times.",   reward={ coins=50 } },
    { id="dq_feed",    name="Feeding Hour",       description="Feed your horse 3 times.",    reward={ coins=50 } },
    { id="dq_jump",    name="Jump Practice",      description="Complete a jump course.",      reward={ coins=70 } },
    { id="dq_photo",   name="Photo Moment",       description="Take a photo at any world.",  reward={ coins=40 } },
    { id="dq_friend",  name="Riding Together",    description="Ride with a friend.",         reward={ coins=90 } },
    { id="dq_gift",    name="Generous Rider",     description="Send a gift to a friend.",    reward={ coins=30, gems=1 } },
    { id="dq_trick",   name="Trick Show",         description="Perform 3 horse tricks.",     reward={ coins=60 } },
    { id="dq_win_race",name="Race Winner",        description="Win 1 race.",                 reward={ coins=120, gems=1 } },
}

-- ── Helper: find achievement by id ───────────────────────
function AchievementData.get(id)
    for _, ach in ipairs(AchievementData.ACHIEVEMENTS) do
        if ach.id == id then return ach end
    end
    return nil
end

return AchievementData
