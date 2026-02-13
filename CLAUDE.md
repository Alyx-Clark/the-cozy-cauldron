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
  items/
    item.tscn                  # Moving item entity

scripts/
  main.gd                     # Root: wires toolbar signal → game_world.select_machine
  game_world.gd               # Placement/removal, ghost preview, input handling
  grid_manager.gd             # 20×11 grid (64px cells), Dictionary-based storage
  ghost_preview.gd            # Semi-transparent placement preview (valid/invalid)
  grid_overlay.gd             # Faint grid dots for visual reference
  data/
    item_types.gd             # ItemTypes enum, color map, name map, is_potion()
    recipes.gd                # Recipe lookup: sorted ingredient pair → potion type
  items/
    item.gd                   # Item entity: type, smooth movement at 120 px/sec
  machines/
    machine_base.gd           # Base class: grid_pos, direction, push/receive API
    dispenser.gd              # Spawns ingredients every 3s, click to cycle type
    conveyor_belt.gd          # Accepts item, waits for arrival, pushes forward
    cauldron.gd               # Stores 2 ingredients, brews 1.5s, outputs potion
  ui/
    toolbar.gd                # 3 toggle buttons, emits machine_selected signal
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
└── UI (CanvasLayer)
    └── Toolbar (PanelContainer, toolbar.gd)
```

### Machine Inheritance

```
MachineBase (Node2D)          — grid_pos, direction, current_item, try_push_item(), receive_item()
├── Dispenser                 — spawns items on timer, click to cycle ingredient
├── ConveyorBelt              — simple relay: accept → arrive → push forward
└── Cauldron                  — accepts 2 ingredients → brew 1.5s → output potion
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

- **2 recipes implemented:** Mushroom+Herb → Health Potion, Crystal+Water → Mana Potion
- **Lookup:** sorted ingredient pair key (e.g. `"1,2"`) → result type, lazy-built on first call
- **6 item types:** MUSHROOM, HERB, CRYSTAL, WATER, HEALTH_POTION, MANA_POTION

## Conventions & Gotchas

- **All visuals use `_draw()`** — no external art assets, no sprites. Machines and items are drawn procedurally.
- **Constants are duplicated** across scripts (e.g. `CELL_SIZE := 64` in both `grid_manager.gd` and `machine_base.gd`). Don't cross-reference via `class_name` — load order isn't deterministic.
- **`mouse_filter = 2` (IGNORE)** on full-screen `ColorRect` backgrounds. Control nodes default to `MOUSE_FILTER_STOP` and will eat clicks, preventing `_unhandled_input()` from firing.
- **`@warning_ignore("integer_division")`** for grid math (`int / int` triggers a Godot warning).
- **Controls:** Left-click place, Right-click remove, R rotate, click dispenser (no selection) to cycle ingredient.

## Development Status

### Phase 1 (Week 1) - Core Mechanics — COMPLETE ✓
- **Grid system** — 20×11 snap-to-grid with Dictionary storage, ghost preview, overlay dots
- **Conveyor belts** — Push-based relay with smooth item movement
- **Items** — 4 ingredients + 2 potions, colored circles via `_draw()`
- **Cauldrons** — 2-ingredient combining with 1.5s brew timer, recipe lookup
- **Dispensers** — Auto-spawn every 3s, click to cycle ingredient type
- **Basic UI** — Bottom toolbar with 3 toggle buttons (Conveyor, Dispenser, Cauldron)
- **2 recipes working** — Health Potion (Mushroom+Herb), Mana Potion (Crystal+Water)

### Phase 2 (Week 2) - Progression
- **Recipe system** - Data-driven potion recipes
- **Unlock system** - Gold currency, unlock new recipes/machines
- **Order/goal system** - "Make 5 health potions" goals
- **Save/load** - Persist progress to disk
- **4-5 machine types** - Dispensers, belts, cauldrons, bottlers, sorters

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
