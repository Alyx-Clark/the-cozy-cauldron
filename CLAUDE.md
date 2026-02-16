# CLAUDE.md

Project instructions for Claude Code when working on **The Cozy Cauldron**.

## Project Overview

**The Cozy Cauldron** is a cozy 2D automation game built in Godot 4. Players build automated potion production chains using conveyor belts, cauldrons, and magical machines in a single persistent world with linear progression.

**Tech Stack:** Godot 4.5, GDScript, 2D top-down view
**Target Platform:** Steam (Windows/Mac/Linux)
**Commercial Goal:** Make $100+ revenue

## Design Philosophy

1. **Focused scope** - Pure automation gameplay, no feature creep
2. **Polish over features** - One mechanic done extremely well beats many half-baked features
3. **Cozy aesthetic** - No stress, no timers, relaxing automation
4. **Clear progression** - 10 unlockable potion recipes
5. **YouTube-friendly** - Satisfying to watch (colorful particles, smooth movement)
6. **Warm cozy pixel wood pub** - Aesthetic should evoke a rustic wooden pub: warm tones, pixel art, cozy lighting

## Code Guidelines

- **Use GDScript** (not C#)
- **Prefer scenes over code** where appropriate (Godot's node system)
- **Keep scripts simple** - Readability over cleverness
- **Comment non-obvious logic** - Another dev should understand it
- **No premature optimization** - Make it work, then make it fast

## Project Structure — File Map

```
scenes/
  main.tscn                    # Root scene: Background + GameWorld + UI CanvasLayer
  machines/
    machine_base.tscn          # Base machine scene (script-only, no visuals)
    dispenser.tscn             # Ingredient dispenser
    conveyor_belt.tscn         # Conveyor belt
    cauldron.tscn              # Potion-brewing cauldron
    fast_belt.tscn             # Fast conveyor belt (2x speed)
    storage_chest.tscn         # Item buffer (8 slots)
    splitter.tscn              # Item duplicator (1→2)
    sorter.tscn                # Type-based item router
    bottler.tscn               # Potion bottling station
    auto_seller.tscn           # Potion → gold converter
  items/
    item.tscn                  # Moving item entity

scripts/
  main.gd                     # Root: wires toolbar, creates managers and UI nodes
  game_world.gd               # Placement/removal, ghost preview, input handling, effects dispatch
  game_state.gd               # AUTOLOAD: gold, unlocks, sell prices, signals
  grid_manager.gd             # 20×11 grid (64px cells), Dictionary-based storage
  ghost_preview.gd            # Semi-transparent placement preview (valid/invalid)
  grid_overlay.gd             # Faint grid dots for visual reference
  order_manager.gd            # Generates and tracks potion orders (max 3)
  save_manager.gd             # JSON save/load, auto-save 60s, Ctrl+S, save-on-quit
  effects_manager.gd          # Static factory: particle bursts (CPUParticles2D) + floating gold text
  sound_manager.gd            # AUTOLOAD: 9 programmatic synth sounds via AudioStreamWAV
  tutorial_manager.gd         # Contextual hint system (7 sequential hints, persisted in save)
  data/
    item_types.gd             # ItemTypes enum (20 ingredients + 10 potions), colors, names
    recipes.gd                # 10 recipes with unlock awareness
  items/
    item.gd                   # Item entity: type, variable speed movement, is_bottled flag
  machines/
    machine_base.gd           # Base class: grid_pos, direction, item_container, push/receive API
    dispenser.gd              # Spawns ingredients every 3s, smart cycling via GameState
    conveyor_belt.gd          # Accepts item, waits for arrival, pushes forward
    cauldron.gd               # Stores 2 ingredients, brews 1.5s, outputs potion
    fast_belt.gd              # 2x speed conveyor (240 px/s)
    storage_chest.gd          # Buffers up to 8 items, FIFO output
    splitter.gd               # Duplicates: 1 input → 2 outputs (forward + side)
    sorter.gd                 # Routes by type: matching → forward, other → side
    bottler.gd                # Bottles potions (1s), sets is_bottled for 2x sell price
    auto_seller.gd            # Sink: sells potions for gold via GameState
  ui/
    toolbar.gd                # 9 toggle buttons with lock/unlock awareness
    gold_display.gd           # Top-right HUD: gold coin + amount, bounce/flash animation
    unlock_shop.gd            # Toggle with U key: buy recipes and machines, purchase animation
    order_panel.gd            # Right-side panel: active order cards
    notification_popup.gd     # Self-contained "Order Complete!" banner (fade in/out, auto-free)
```

## Architecture

### Scene Tree (main.tscn)

```
Main (Node2D, main.gd)
├── Background (ColorRect, 1280×720, mouse_filter=IGNORE)
├── GameWorld (Node2D, game_world.gd)
│   ├── GridOverlay (Node2D, z=0)        — grid dots
│   ├── GridManager (Node2D, z=0)        — no visuals, maintains _grid Dictionary
│   ├── MachineContainer (Node2D, z=1)   — dynamically holds placed machines
│   ├── ItemContainer (Node2D, z=2)      — dynamically holds moving items
│   ├── EffectsContainer (Node2D, z=4)   — particle bursts and floating text
│   └── GhostPreview (Node2D, z=5)       — placement preview cursor
├── OrderManager (Node, order_manager.gd)     — created in main._ready()
├── SaveManager (Node, save_manager.gd)       — created in main._ready()
├── TutorialManager (Node, tutorial_manager.gd) — created in main._ready()
└── UI (CanvasLayer)
    ├── Toolbar (PanelContainer, toolbar.gd)  — defined in .tscn
    ├── GoldDisplay (HBoxContainer)           — created in main._ready()
    ├── OrderPanel (PanelContainer)           — created in main._ready()
    ├── UnlockShop (PanelContainer)           — created in main._ready()
    └── (NotificationPopup, TutorialHint)     — transient, created/freed dynamically
```

### Autoloads (project.godot)

| Name | Script | Purpose |
|---|---|---|
| `GameState` | `game_state.gd` | Gold, unlocks, sell prices, central signal hub |
| `SoundManager` | `sound_manager.gd` | 9 synth sounds, `SoundManager.play("name")` |

### Machine Inheritance

```
MachineBase (Node2D)          — grid_pos, direction, current_item, item_container, try_push_item(), receive_item()
├── Dispenser                 — spawns items on timer, click to cycle (unlocked ingredients only)
├── ConveyorBelt              — simple relay: accept → arrive → push forward (120 px/s)
├── FastBelt                  — same as conveyor but 2x speed (240 px/s)
├── Cauldron                  — accepts 2 ingredients → brew 1.5s → output potion
├── StorageChest              — buffers up to 8 items, FIFO output
├── Splitter                  — duplicates: 1 input → 2 copies (forward + 90° CW side)
├── Sorter                    — routes by type: matching → forward, non-matching → side. Click to set filter.
├── Bottler                   — potions only, 1.0s process, sets is_bottled (2x sell price)
└── AutoSeller                — sink: sells potions for gold, 0.5s sell time
```

### Item Flow (Push + Reservation)

This is the core transport model. All item movement is "push"-based:

1. Machine A calls `target.receive_item(item)` — reserves target's `current_item` slot
2. Target stores item reference; item begins smooth movement to target position
3. Item arrives (`is_moving = false`), target can now process or push it onward
4. `try_push_item()` checks: target exists AND `target.current_item == null`
5. Cauldron/StorageChest/Bottler/AutoSeller use `_waiting_for_arrival` flag to distinguish incoming items (being consumed) from output items (being pushed forward)

The reservation prevents two machines from sending items to the same target simultaneously.

### Grid System

- **Size:** 20×11 cells, 64px each → 1280×704 px
- **Data:** `_grid: Dictionary` mapping `Vector2i → Node2D` (machine or null)
- **Coords:** `world_pos = grid_pos * 64 + 32` (cell center)
- **Key methods:** `place_machine()`, `remove_machine()`, `get_machine_at()`, `get_neighbor()`

### Recipe System

- **10 recipes implemented** (2 unlocked at start, 8 unlockable with gold)
- **Lookup:** sorted ingredient pair key (e.g. `"1,2"`) → [recipe_index, result_type], unlock-aware
- **30 item types:** 20 ingredients + 10 potions
- **Unlock gating:** `Recipes.check()` returns NONE for locked recipes

### Signal Architecture

GameState is the central signal hub. Connection map:

```
GameState.gold_changed      → GoldDisplay (UI bounce + color flash)
                            → TutorialManager (triggers "open_shop" hint)

GameState.recipe_unlocked   → Toolbar (refresh button lock states)
                            → UnlockShop (refresh button states)

GameState.machine_unlocked  → Toolbar (refresh button lock states)
                            → UnlockShop (refresh button states)

GameState.potion_sold       → OrderManager (increment order progress)

GameState.potion_brewed     → TutorialManager (triggers "cycle_dispenser" + "hand_sell" hints)

Toolbar.machine_selected    → GameWorld.select_machine (set placement tool)

OrderManager.order_completed → (currently unused externally, available for future features)
```

### Effects System (Phase 3)

**EffectsManager** — static class, no instance needed. Uses `CPUParticles2D` (not GPU — GL Compatibility renderer). Setup once from `game_world._ready()`.

| Method | Used By | Visual |
|---|---|---|
| `spawn_burst(pos, color, count, radius, lifetime)` | Cauldron, AutoSeller, Dispenser, Bottler, GameWorld | One-shot particle burst, auto-frees |
| `spawn_gold_text(pos, amount)` | AutoSeller, GameWorld (hand-sell) | Floating "+Xg" label, tweens up + fades |

**SoundManager** — autoload singleton. Generates 16-bit mono PCM audio buffers programmatically in `_ready()` using `AudioStreamWAV`. No external audio files.

| Sound | Trigger | Description |
|---|---|---|
| `place` | Machine placed | Rising sweep 300→500 Hz |
| `remove` | Machine removed | Falling sweep 400→200 Hz |
| `brew_complete` | Cauldron finishes | Bright sine chime 800 Hz |
| `sell` | AutoSeller sells / hand-sell | Coin clink (two quick hits) |
| `unlock` | Shop purchase | 3-note ascending arpeggio |
| `dispense` | Dispenser spawns item | Soft noise burst |
| `bottle` | Bottler finishes | Glass sine clink |
| `order_complete` | Order fulfilled | 3-note fanfare |
| `click` | Toolbar / dispenser click | Tiny noise burst |

### Tutorial System (Phase 3)

7 contextual hints shown sequentially, dismissed by clicking anywhere. State persisted in save data (`tutorial_seen` array of hint ID strings).

| Hint ID | Trigger | Text |
|---|---|---|
| `select_dispenser` | Fresh start (no save) | Place a Dispenser from toolbar |
| `rotate_hint` | First machine placed | Press R to rotate |
| `place_belts` | Dispenser placed | Place Conveyor Belts |
| `place_cauldron` | 3+ machines placed | Place a Cauldron |
| `cycle_dispenser` | First potion brewed | Click Dispenser to change ingredient |
| `hand_sell` | First potion brewed | Click potion to hand-sell |
| `open_shop` | First gold earned | Press U for Unlock Shop |

### Save System

JSON at `user://savegame.json`. Auto-save every 60s, manual Ctrl+S, save-on-quit.

**Save format:**
```json
{
  "gold": 150,
  "unlocked_recipes": [0, 1, 2],
  "unlocked_machines": ["conveyor", "dispenser", "cauldron", "fast_belt"],
  "machines": [
    { "type": "dispenser", "grid_x": 2, "grid_y": 3, "dir_x": 1, "dir_y": 0, "ingredient_type": 1 },
    { "type": "conveyor", "grid_x": 3, "grid_y": 3, "dir_x": 1, "dir_y": 0 }
  ],
  "orders": [
    { "id": 0, "potion_type": 21, "quantity": 5, "progress": 2, "reward": 75 }
  ],
  "tutorial_seen": ["select_dispenser", "rotate_hint", "place_belts"]
}
```

Backward compatible: new fields use `data.get("key", default)`. Machine restoration is a two-step process — `save_manager.load_game()` populates `loaded_machines`, then `main._restore_machines()` instantiates them.

## Conventions & Gotchas

- **All visuals use `_draw()`** — no external art assets, no sprites. Machines and items are drawn procedurally.
- **All sounds are procedural** — no external .wav/.ogg files. AudioStreamWAV buffers generated at startup.
- **Constants are duplicated** across scripts (e.g. `CELL_SIZE := 64` in both `grid_manager.gd` and `machine_base.gd`). Don't cross-reference via `class_name` — load order isn't deterministic.
- **`mouse_filter = 2` (IGNORE)** on full-screen `ColorRect` backgrounds. Control nodes default to `MOUSE_FILTER_STOP` and will eat clicks, preventing `_unhandled_input()` from firing.
- **`@warning_ignore("integer_division")`** for grid math (`int / int` triggers a Godot warning).
- **Autoloads can't use class_names:** `game_state.gd` and `sound_manager.gd` use `load()` at runtime for cross-script access. Never reference class_name identifiers in autoload scripts.
- **Private members are enforced:** `_`-prefixed members can't be accessed cross-script in Godot 4. Use public names for shared APIs.
- **CPUParticles2D only:** The project uses GL Compatibility renderer. GPUParticles2D is not supported.
- **`_waiting_for_arrival` pattern:** Cauldron, StorageChest, Bottler, and AutoSeller use this flag to distinguish incoming items (in transit, will be consumed) from output items (at rest, ready to push). This is the key to understanding how `current_item` serves double duty.
- **Static class pattern:** `EffectsManager` uses static methods + a static container reference. Call `EffectsManager.setup()` once from `game_world._ready()`, then `EffectsManager.spawn_burst()` from anywhere.
- **Controls:** Left-click place, Right-click remove, R rotate, click dispenser/sorter (no selection) to cycle type, U toggle unlock shop, Ctrl+S manual save.

## Development Status

### Phase 1 (Week 1) - Core Mechanics — COMPLETE ✓
- **Grid system** — 20×11 snap-to-grid with Dictionary storage, ghost preview, overlay dots
- **Conveyor belts** — Push-based relay with smooth item movement
- **Items** — 4 ingredients + 2 potions, colored circles via `_draw()`
- **Cauldrons** — 2-ingredient combining with 1.5s brew timer, recipe lookup
- **Dispensers** — Auto-spawn every 3s, click to cycle ingredient type
- **Basic UI** — Bottom toolbar with 3 toggle buttons (Conveyor, Dispenser, Cauldron)
- **2 recipes working** — Health Potion (Mushroom+Herb), Mana Potion (Crystal+Water)

### Phase 2 (Week 2) - Progression — COMPLETE ✓
- **10 recipes** — 20 ingredients + 10 potions, unlock-aware brewing
- **6 new machines** — Fast Belt, Storage Chest, Splitter, Sorter, Bottler, Auto-Seller
- **GameState autoload** — Gold currency, potion sell prices, unlock costs
- **Unlock shop** — U key toggles shop UI, buy recipes (50–400g) and machines (30–250g)
- **Order system** — Up to 3 concurrent orders, no time pressure, bonus gold on completion
- **Save/load** — JSON at user://savegame.json, auto-save 60s, Ctrl+S, save-on-quit
- **UI** — 9-button toolbar with lock states, gold display, order panel
- **Hand-sell** — Click potions on machines (no tool selected) to sell for half price
- **Bootstrap economy** — Start with 0g, hand-sell to earn gold, buy Auto-Seller (250g) to automate

### Phase 3 (Week 3) - Polish — COMPLETE ✓
- **Particle effects** — CPUParticles2D bursts on brew, sell, dispense, bottle, place, remove
- **Sound effects** — 9 programmatic synth sounds via AudioStreamWAV (no external files)
- **Gold display animation** — Scale bounce + color flash (green on gain, red on spend)
- **Order completion notification** — Centered "Order Complete! +Xg" banner with fade in/out
- **Unlock shop animation** — Green flash + scale bounce on purchase
- **Tutorial system** — 7 contextual hints, dismissed by click, persisted in save data
- **Floating gold text** — "+Xg" labels that rise and fade at sell points

## Potion Recipes (10 implemented)

| # | Recipe | Ingredients | Unlock Cost |
|---|---|---|---|
| 1 | Health Potion | Mushroom + Herb | Free (start) |
| 2 | Mana Potion | Crystal + Water | Free (start) |
| 3 | Speed Potion | Feather + Lightning | 50g |
| 4 | Love Potion | Rose + Heart | 75g |
| 5 | Invisibility Potion | Shadow + Moonlight | 100g |
| 6 | Fire Resistance Potion | Ice + Lava | 150g |
| 7 | Strength Potion | Dragon Scale + Ember | 200g |
| 8 | Night Vision Potion | Glowshroom + Eye | 275g |
| 9 | Water Breathing Potion | Seaweed + Bubble | 350g |
| 10 | Lucky Potion | Clover + Star | 400g |

## Machine Types (9 implemented)

| Machine | Key | Unlock Cost | Behavior |
|---|---|---|---|
| Conveyor Belt | `conveyor` | Free | Moves items forward at 120 px/s |
| Dispenser | `dispenser` | Free | Spawns ingredients every 3s, click to cycle |
| Cauldron | `cauldron` | Free | Combines 2 ingredients → potion (1.5s brew) |
| Fast Belt | `fast_belt` | 30g | 2x speed conveyor (240 px/s) |
| Storage Chest | `storage` | 60g | Buffers up to 8 items (FIFO) |
| Sorter | `sorter` | 80g | Routes by type: matching → forward, other → side |
| Splitter | `splitter` | 100g | Duplicates: 1 input → 2 outputs (forward + side) |
| Bottler | `bottler` | 120g | Bottles potions (1s), is_bottled = 2x sell price |
| Auto-Seller | `auto_seller` | 250g | Sink: sells potions for gold (0.5s) |

## Sell Prices

| Recipe Index | Base Price | Bottled Price |
|---|---|---|
| 0 (Health) | 10g | 20g |
| 1 (Mana) | 15g | 30g |
| 2 (Speed) | 20g | 40g |
| 3 (Love) | 25g | 50g |
| 4 (Invisibility) | 30g | 60g |
| 5 (Fire Resist) | 35g | 70g |
| 6 (Strength) | 40g | 80g |
| 7 (Night Vision) | 45g | 90g |
| 8 (Water Breath) | 50g | 100g |
| 9 (Lucky) | 60g | 120g |

Hand-sell price = floor(base / 2), minimum 1g.

## Development Workflow

**No tests, no CI/CD.** Manual testing only.

**To run:**
```bash
# Open in Godot editor and press F5
```

**To test changes:**
1. Make code changes
2. Run in Godot editor
3. Test manually — build full chain: Dispenser → Belt → Cauldron → Bottler → Auto-Seller
4. Verify particles fire, sounds play, gold animates, orders complete
5. Delete save file to test tutorial flow from scratch

**Git workflow:**
- Commit frequently with clear messages
- No branching needed (solo dev)
- Push to remote for backup

## Narrative Framing (Aesthetic Only)

**Setting:** Player runs the potion brewery at "The Cozy Cauldron" magical pub

**Important:** Do NOT add pub service mechanics (serving customers, etc.). Keep scope focused on pure automation. The pub theme is narrative framing only.

## What NOT to Do

- **No scope creep** - Resist adding new features (multiplayer, meta-progression, etc.)
- **No perfectionism** - Ship a polished v1, iterate post-launch if successful
- **No complex systems** - Keep everything simple and readable
- **No art perfectionism** - Procedural visuals are fine, particles do the heavy lifting
- **No pub gameplay mechanics** - It's narrative framing only
- **No GPUParticles2D** - GL Compatibility renderer doesn't support them
- **No external audio files** - All sounds are programmatic
- **No class_name references in autoloads** - Use load() at runtime

---

When in doubt: **Keep it simple, keep it focused, keep it cozy.**
