# 🌟 Starlight Stables — Roblox Horse Riding Game

> *Ride, Bond, and Shine!*

A full-featured, beautifully crafted Roblox horse-riding experience designed for players aged 12–14 who love horses, fashion, exploration, and playing with friends.

---

## ✨ Feature Overview

### 🐴 Horses (11 breeds across 5 rarity tiers)

| Tier       | Stars | Examples                            |
|------------|-------|-------------------------------------|
| Common     | ⭐    | Sunrise Pony, Silver Star           |
| Rare       | ⭐⭐  | Moonwhisper, Rosebud, Thunderstep   |
| Epic       | ⭐⭐⭐ | Aurora Dancer, Crystal Mist         |
| Legendary  | ⭐⭐⭐⭐| Starfire, Nebula Dream              |
| Mythical   | ⭐⭐⭐⭐⭐| Lumina (Unicorn), Zephyr (Pegasus) |

Every horse has unique **speed, stamina, agility, and beauty** stats, individual particle trail effects, and custom body/mane/tail colours.

### 🌍 Six Stunning Worlds

| World               | Theme                        | Unlock        |
|---------------------|------------------------------|---------------|
| Enchanted Meadow    | Sunny wildflower fields       | Free (starter)|
| Crystal Cove        | Tropical beach & crystals     | Lv. 5         |
| Mystic Forest       | Glowing fairy woodland        | Lv. 10        |
| Sakura Valley       | Cherry blossom paradise       | Lv. 12        |
| Winter Wonderland   | Ice castle & snow trails      | Lv. 15        |
| Starlight Kingdom   | Cosmic floating islands       | Lv. 20 + Gems |

Each world features its own **music playlist, particle atmosphere, weather effects, race tracks, jump courses, and trail rides**.

### 🏁 Activities

- **Trail Rides** — Explore each world's scenery, collect coins at checkpoints
- **Racing** — Up to 8 players compete on world-specific tracks (Easy → Expert)
- **Show Jumping** — Timed obstacle courses with difficulty ratings
- **Dressage / Tricks** — Perform Rear, Bow, Spin, SideStep, Wave, Whinny
- **Horse Care** — Groom and feed your horse to build **Bond** (improves speed) and restore **Energy**
- **Photo Booth** — Strike poses with your horse against gorgeous world backdrops
- **Treasure Hunts** — Discover hidden collectibles in the Mystic Forest
- **Fairy Quests** — Story-style quests unique to the Mystic Forest

### 👗 Customisation

- **6 Rider Outfits** (from classic to fairy and starlight)
- **11 Rider Accessories** (tiaras, wings, sparkling boots…)
- **6 Saddle designs** including Rainbow and Starlight
- **6 Mane styles** per horse
- **10 Horse accessories** (flower crowns, aurora wings, gem necklaces…)
- **10 Stable decorations** (fairy lights, crystal troughs, trophy shelves…)

### 👥 Social & Multiplayer

- **Riding Clubs** — Create or join clubs, ride together, climb the leaderboard
- **Friend Rides** — Send ride invites, teleport to your friend's location instantly
- **Gifting System** — Send accessories to friends (3 gifts/day)
- **Global Leaderboard** — Top riders by total race wins
- **Online Counter** — See how many riders are currently exploring

### 🏅 Progression System

- **50 Player Levels** with XP earned from all activities
- **30 Horse Levels** with bond bonuses at max bond
- **23 Achievements** (including 4 hidden ones)
- **Daily Login Rewards** with streak bonuses
- **3 Daily Quests** re-rolled every day
- **Titles** earned through achievements ("Champion", "Unicorn Rider", etc.)

### 💎 Economy

| Currency | Earned by                                      | Spent on                              |
|----------|------------------------------------------------|---------------------------------------|
| 🪙 Coins | Races, trails, daily login, quests, care       | Horses, outfits, accessories, worlds  |
| 💎 Gems  | Daily login, achievements, Robux purchases     | Premium horses, exclusive worlds, VIP |

**6 Boost types** including Speed Surge, Energy Elixir, Glamour Potion, and Star XP Charm.

---

## 🗂️ Project Structure

```
StarlightStables/
├── default.project.json          ← Rojo project file
├── src/
│   ├── ReplicatedStorage/
│   │   └── Modules/
│   │       ├── GameConfig.lua        ← Central configuration
│   │       ├── HorseData.lua         ← All breeds, accessories, rarities
│   │       ├── WorldData.lua         ← All worlds, tracks, atmospheres
│   │       ├── ShopData.lua          ← Shop items, boosts, gamepasses
│   │       └── AchievementData.lua   ← Achievements, daily quests
│   │
│   ├── ServerScriptService/
│   │   ├── GameManager.server.lua    ← Bootstrap, gamepasses, daily quests
│   │   ├── PlayerDataManager.server.lua ← DataStore, economy, XP/level
│   │   ├── HorseManager.server.lua   ← Horse spawning, care, tricks
│   │   ├── WorldManager.server.lua   ← World travel, decoration, atmosphere
│   │   ├── RaceManager.server.lua    ← Lobbies, countdown, checkpoints, rewards
│   │   └── SocialManager.server.lua  ← Clubs, gifts, photo, leaderboard
│   │
│   ├── StarterPlayerScripts/
│   │   ├── HorseController.client.lua    ← Movement, mount, jump, tricks
│   │   ├── CameraController.client.lua   ← Orbit cam, photo mode, transitions
│   │   ├── UIManager.client.lua          ← All menus, HUD, notifications
│   │   ├── SoundManager.client.lua       ← Music, SFX, crossfade
│   │   └── AtmosphereController.client.lua ← Lighting, fog, weather, particles
│   │
│   └── Workspace/
│       └── WorldSetup.lua            ← Checkpoints, jumps, stable, photo booth
```

---

## 🚀 Getting Started (Developer)

### Prerequisites
- [Rojo](https://rojo.space/) v7+
- Roblox Studio

### Setup

```bash
# Clone the repo
git clone <repo-url>
cd horse_game_roblox

# Install Rojo plugin into Studio (if not already done)
# https://github.com/rojo-rbx/rojo/releases

# Sync to Studio
rojo serve default.project.json
```

In Studio, click **Connect** in the Rojo plugin panel.

### Asset IDs to Replace

Search for `rbxassetid://` in all Lua files and replace placeholder IDs with your published:
- Horse model asset IDs (`HORSE_MODEL_ID`, `PONY_MODEL_ID`, `UNICORN_MODEL_ID`, `PEGASUS_MODEL_ID`)
- Sound effect IDs for gallop, whinny, and UI sounds
- Particle texture IDs for sparkle effects
- Music track IDs per world
- Icon IDs for each horse breed and shop item

### Gamepass Setup (GameManager.server.lua)

```lua
local GAMEPASS_IDS = {
    vip_pass          = 123456789,   -- Your real gamepass IDs
    unlimited_stalls  = 987654321,
    auto_care         = 111222333,
}
```

---

## 🎨 Design Philosophy

### Visual Style
- **Soft, pastel colour palette** — pinks, purples, golds, and teals
- **Gradient UI panels** with subtle glow and rounded corners
- **Particle effects** on every horse breed and world transition
- **Smooth camera** with obstacle-avoiding raycast and cinematic world-entry pans

### Gameplay Loop
```
Daily Login → Collect Reward → Check Quests
     ↓
Choose Horse → Go to a World → Trail Ride / Race / Jump
     ↓
Earn Coins + XP + Bond → Level Up → Unlock New Horses / Worlds
     ↓
Visit Shop → Customise Horse & Rider → Show Off to Friends
     ↓
Join / Create Club → Race Together → Climb Leaderboard
```

### Social Design (key for multiplayer appeal)
- **Racing** naturally brings groups together in structured sessions
- **Clubs** give squads a persistent identity and shared goal
- **Gifting** encourages friend connections and daily interaction
- **Photo Booth** creates shareable moments and memories
- **Leaderboard** provides healthy friendly competition

---

## 📋 Planned Future Features

- [ ] Seasonal events (Spring Festival, Winter Gala, Star Night)
- [ ] Horse breeding system
- [ ] Auction house for trading horses & accessories
- [ ] Story campaign with NPC characters and quest chains
- [ ] Mobile-optimised touch controls (virtual joystick)
- [ ] In-game horse shows (judged by beauty + dressage score)
- [ ] Animated horse rigs with full walk/trot/canter/gallop cycles
- [ ] Voice-acted tutorial guide character ("Stella the Fairy")

---

## 📜 License

This project is private. All content is property of the game developers.
Roblox assets must comply with Roblox's [Terms of Service](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use).
