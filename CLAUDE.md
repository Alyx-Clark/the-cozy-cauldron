# CLAUDE.md

Project instructions for Claude Code when working on **The Cozy Cauldron**.

## Project Overview

**The Cozy Cauldron** is a cozy 2D automation game built in Godot 4. Players build automated potion production chains using conveyor belts, cauldrons, and magical machines.

**Tech Stack:** Godot 4.5, GDScript, 2D top-down view
**Target Platform:** Steam (Windows/Mac/Linux)
**Development Timeline:** 3-4 weeks
**Commercial Goal:** Make $100+ revenue

## Design Philosophy

1. **Focused scope** - Pure automation gameplay, no feature creep
2. **Polish over features** - One mechanic done extremely well beats many half-baked features
3. **Cozy aesthetic** - No stress, no timers, relaxing automation
4. **Clear progression** - 10-15 unlockable potion recipes
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
  game_world.gd               # Placement/removal, ghost preview, input handling
  game_state.gd               # AUTOLOAD: gold, unlocks, sell prices, signals
  grid_manager.gd             # 20×11 grid (64px cells), Dictionary-based storage
  ghost_preview.gd            # Semi-transparent placement preview (valid/invalid)
  grid_overlay.gd             # Faint grid dots for visual reference
  order_manager.gd            # Generates and tracks potion orders (max 3)
  save_manager.gd             # JSON save/load, auto-save 60s, Ctrl+S
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
    gold_display.gd           # Top-right HUD: gold coin + amount
    unlock_shop.gd            # Toggle with U key: buy recipes and machines
    order_panel.gd            # Right-side panel: active order cards
```

## Architecture

### Scene Tree (main.tscn)

```
Main (Node2D, main.gd)
├── Background (ColorRect, 1280×720, mouse_filter=IGNORE)
├── GameWorld (Node2D, game_world.gd)
│   ├── GridOverlay (Node2D, z=0)   — grid dots
│   ├── GridManager (Node2D, z=0)   — no visuals, maintains _grid Dictionary
│   ├── MachineContainer (Node2D, z=1) — dynamically holds placed machines
│   ├── ItemContainer (Node2D, z=2)    — dynamically holds moving items
│   └── GhostPreview (Node2D, z=3)     — placement preview cursor
├── OrderManager (Node, order_manager.gd) — created in main._ready()
├── SaveManager (Node, save_manager.gd)   — created in main._ready()
└── UI (CanvasLayer)
    ├── Toolbar (PanelContainer, toolbar.gd)
    ├── GoldDisplay (HBoxContainer)       — created in main._ready()
    ├── OrderPanel (PanelContainer)       — created in main._ready()
    └── UnlockShop (PanelContainer)       — created in main._ready()
```

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

1. Machine A calls `target.receive_item(item)` — reserves target's `current_item` slot
2. Target stores item reference; item begins smooth movement to target position
3. Item arrives (`is_moving = false`), target can now process or push it onward
4. `try_push_item()` checks: target exists AND `target.current_item == null`
5. Cauldron uses `_waiting_for_arrival` flag to distinguish incoming vs. output items

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

## Conventions & Gotchas

- **All visuals use `_draw()`** — no external art assets, no sprites. Machines and items are drawn procedurally.
- **Constants are duplicated** across scripts (e.g. `CELL_SIZE := 64` in both `grid_manager.gd` and `machine_base.gd`). Don't cross-reference via `class_name` — load order isn't deterministic.
- **`mouse_filter = 2` (IGNORE)** on full-screen `ColorRect` backgrounds. Control nodes default to `MOUSE_FILTER_STOP` and will eat clicks, preventing `_unhandled_input()` from firing.
- **`@warning_ignore("integer_division")`** for grid math (`int / int` triggers a Godot warning).
- **Controls:** Left-click place, Right-click remove, R rotate, click dispenser/sorter (no selection) to cycle type, U toggle unlock shop, Ctrl+S manual save.
- **Autoloads can't use class_names:** `game_state.gd` uses `load()` at runtime for cross-script access. Never reference class_name identifiers in autoload scripts.
- **Private members are enforced:** `_`-prefixed members can't be accessed cross-script in Godot 4. Use public names for shared APIs.

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

### Phase 3 (Week 3) - Polish
- **Particle effects** - Bubbles, sparkles, colored liquids
- **Sound effects** - Godot AudioStreamGenerator for synth sounds
- **Campaign mode** - 15-20 handcrafted levels with goals
- **UI polish** - Smooth transitions, feedback, juice
- **Tutorial** - First 2-3 levels teach mechanics

## Narrative Framing (Aesthetic Only)

**Setting:** Player runs the potion brewery at "The Cozy Cauldron" magical pub

**Implementation:**
- Intro cutscene/animation (simple, 10-15 seconds)
- Maybe a decorative "front room" you can visit (cosmetic only, no gameplay)
- All actual gameplay happens in the factory/back room

**Important:** Do NOT add pub service mechanics (serving customers, etc.). Keep scope focused on pure automation.

## Potion Recipes (15 total planned)

Start with 1, unlock progressively:
1. Health Potion = Mushroom + Herb
2. Mana Potion = Crystal + Water
3. Speed Potion = Feather + Lightning
4. Love Potion = Rose + Heart
5. Invisibility = Shadow + Moonlight
6. Fire Resistance = Ice + Lava
7. Strength = Dragon Scale + Ember
8. Night Vision = Glowshroom + Eye
9. Water Breathing = Seaweed + Bubble
10. Lucky = Clover + Star
... (continue to 15)

## Machine Types (10 total planned)

1. Ingredient Dispenser (spawns items)
2. Conveyor Belt (moves items)
3. Cauldron (combines 2+ ingredients)
4. Bottling Station (finalizes potion)
5. Sorter (routes by type)
6. Storage Chest (buffers items)
7. Splitter (duplicates ingredients)
8. Fast Belt (upgraded speed)
9. Multi-Cauldron (3-ingredient recipes)
10. Auto-Seller (sells finished potions)

## Development Workflow

**No tests, no CI/CD.** Manual testing only.

**To run:**
```bash
# Open in Godot editor and press F5
```

**To test changes:**
1. Make code changes
2. Run in Godot editor
3. Test manually
4. Iterate

**Git workflow:**
- Commit frequently with clear messages
- No branching needed (solo dev)
- Push to remote for backup

## Marketing Plan (Post-Development)

- Steam store page with screenshots/trailer
- YouTube shorts (satisfying automation clips)
- Reddit posts (r/CozyGamers, r/godot, r/IndieGaming)
- Price: $4.99
- Tags: Automation, Casual, Relaxing, Singleplayer, 2D, Magic

## What NOT to Do

❌ **No scope creep** - Resist adding new features (multiplayer, meta-progression, etc.)
❌ **No perfectionism** - Ship a polished v1, iterate post-launch if successful
❌ **No complex systems** - Keep everything simple and readable
❌ **No art perfectionism** - Placeholder art is fine, particles do the heavy lifting
❌ **No pub gameplay mechanics** - It's narrative framing only

## Success Criteria

**Minimum Viable Product (MVP):**
- 5 potion recipes working
- 5 machine types
- Grid placement + conveyor system
- Basic progression (unlock recipes with gold)
- 10 campaign levels
- Polished particles and sound

**Commercial Success:**
- Make $100+ revenue on Steam (25+ sales after Valve's 30% cut)
- Positive reviews (focus on polish and satisfying gameplay)

---

When in doubt: **Keep it simple, keep it focused, keep it cozy.** 🧙‍♂️✨
