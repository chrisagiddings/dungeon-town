# Dungeon Town — M0 Bootstrap

A dungeon-themed colony sim built in Godot 4. This is the **M0 vertical slice**: a runnable foundation with town grid, dungeon entrance, day/night cycle, and an adventurer loop stub.

---

## Requirements

- **Godot 4.2+** (tested with 4.2.x / 4.3.x, GL Compatibility renderer)
- No plugins or additional dependencies required

---

## Setup & Running

### Open in Godot Editor

1. Launch Godot 4
2. Click **"Import"** on the Project Manager
3. Navigate to this `game/` folder and select `project.godot`
4. Click **"Open"**
5. Press **F5** (or the ▶ Play button) to run

### First Run

The main scene (`scenes/Main.tscn`) launches automatically. Godot will build `.godot/` cache on first open — this is normal and takes a few seconds.

---

## Controls

| Input | Action |
|-------|--------|
| **WASD** / Arrow Keys | Pan camera |
| **Scroll Wheel** | Zoom in/out |
| **Middle Mouse + Drag** | Pan camera |
| **Mouse edge** | Edge-scroll pan |

---

## Debug Panel (bottom-right)

| Button | Action |
|--------|--------|
| **Spawn Adventurer** | Spawns a new adventurer into the town |
| **Advance Time** | Manually ticks time forward 0.5 hours |
| **Dungeon Run** | Sends last spawned adventurer into the dungeon |
| **Speed ×2** | Cycles sim speed: 1× → 2× → 4× → 0.25× |
| **Pause/Play** | Toggles simulation pause |

---

## Architecture

### Autoload Singletons

| Singleton | Purpose |
|-----------|---------|
| `EventBus` | Cross-system signal hub. All inter-system communication goes here. |
| `GameState` | Authoritative sim state: day, hour, phase, pause, speed. |
| `EconomyState` | Gold ledger: balance, income, expenses, transaction log. |
| `DataRegistry` | Holds all loaded resource definitions (buildings, adventurers, etc.). |

### Scene Structure (`Main.tscn`)

```
Main (Node2D)
├── TownRoot (Node2D)         — town buildings and terrain
│   └── TerrainGrid           — isometric placeholder grid + dungeon entrance marker
├── DungeonRoot (Node2D)      — dungeon content (empty in M0)
├── Camera2D                  — isometric camera rig (WASD + scroll zoom)
├── DayNightSystem            — listens to phase changes, tweens world modulate
├── AdventurerSpawner         — timer-based adventurer spawning stub
├── DungeonRunStub            — simulates dungeon runs with async timer + gold reward
└── UIRoot (CanvasLayer)
    ├── TopBar                — day/time/gold/speed HUD
    └── DebugPanel            — debug controls + log output
```

### Signal Flow

```
GameState (tick) → EventBus.time_tick / phase_changed
EventBus.phase_changed → TerrainGrid (redraw) + DayNightSystem (modulate tween)
EventBus.phase_changed → TopBarUI (label update)

DebugPanel [Dungeon Run] → DungeonRunStub.start_run()
DungeonRunStub (await timer) → EconomyState.add_gold()
EconomyState.add_gold() → EventBus.gold_changed → TopBarUI (gold label)
```

---

## Resource Scripts

Located in `resources/`:

| File | Class | Purpose |
|------|-------|---------|
| `BuildingData.gd` | `BuildingData` | Placeable building definition |
| `AdventurerData.gd` | `AdventurerData` | Adventurer archetype stats |
| `MobData.gd` | `MobData` | Dungeon enemy stats + loot reference |
| `LootTableData.gd` | `LootTableData` | Loot table with item entries |
| `QuestData.gd` | `QuestData` | Quest definition with objectives |

Create `.tres` resource files using these scripts as the base class via the Godot editor's "New Resource" dialog.

---

## M0 → M1 Roadmap

- [ ] Replace placeholder grid with TileMap + isometric tileset
- [ ] Real adventurer sprites with simple state machine
- [ ] Building placement system (click to place, BuildingData-driven)
- [ ] DataRegistry loads `.tres` files from resource folders
- [ ] Actual dungeon depth/combat simulation
- [ ] Save/load system using GameState + EconomyState serialization
- [ ] Quest board UI

---

## Troubleshooting

**Scene opens with errors about missing scripts:**
Make sure you're opening the `game/` folder (where `project.godot` lives), not a parent folder.

**Godot version warning:**
This project targets Godot 4.2+. Older versions may have minor API differences but should largely work.

**Gold not updating:**
Check the Debug Panel log. Make sure a dungeon run has completed (10-second delay after clicking "Dungeon Run").

**Camera not responding:**
Click on the game window to give it focus before using keyboard pan.
