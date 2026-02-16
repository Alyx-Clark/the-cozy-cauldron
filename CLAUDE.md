# CLAUDE.md

Project instructions for Claude Code when working on **The Cozy Cauldron**.

## Project Overview

**The Cozy Cauldron** is a cozy 2D automation game built in Godot 4. Players play as a wizard building automated potion production chains using conveyor belts, cauldrons, and magical machines in an expandable world with linear progression. The player character walks around a 60x35 grid, placing machines within range to create automated potion factories.

**Tech Stack:** Godot 4.5, GDScript, 2D top-down view
**Target Platform:** Steam (Windows/Mac/Linux)
**Commercial Goal:** Make $100+ revenue

## Design Philosophy

1. **Focused scope** - Pure automation gameplay, no feature creep
2. **Polish over features** - One mechanic done extremely well beats many half-baked features
3. **Cozy aesthetic** - No stress, no timers, relaxing automation
4. **Clear progression** - 10 unlockable potion recipes, 7 unlockable regions
5. **YouTube-friendly** - Satisfying to watch (colorful particles, smooth movement)
6. **Warm cozy pixel wood pub** - Aesthetic should evoke a rustic wooden pub: warm tones, pixel art, cozy lighting

## Code Guidelines

- **Use GDScript** (not C#)
- **Prefer scenes over code** where appropriate (Godot's node system)
- **Keep scripts simple** - Readability over cleverness
- **Comment non-obvious logic** - Another dev should understand it
- **No premature optimization** - Make it work, then make it fast
- **Duplicate constants** across scripts -- don't cross-reference `class_name` constants. Load order isn't deterministic.
- **`data.get("key", default)` for save data** -- ensures backward compatibility when fields are added.

## Project Structure -- File Map

```
scenes/
  main.tscn                    # Root scene: Background + GameWorld + UI CanvasLayer
  player.tscn                  # Player: CharacterBody2D + CollisionShape2D + Camera2D
  machines/
    machine_base.tscn          # Base machine scene (script-only, no visuals)
    dispenser.tscn             # Ingredient dispenser
    conveyor_belt.tscn         # Conveyor belt
    cauldron.tscn              # Potion-brewing cauldron
    fast_belt.tscn             # Fast conveyor belt (2x speed)
    storage_chest.tscn         # Item buffer (8 slots)
    splitter.tscn              # Item duplicator (1->2)
    sorter.tscn                # Type-based item router
    bottler.tscn               # Potion bottling station
    auto_seller.tscn           # Potion -> gold converter
  items/
    item.tscn                  # Moving item entity

scripts/
  main.gd                     # Root: wires all subsystems, creates managers/UI, restore logic
  game_world.gd               # Placement/removal, ghost preview, input handling, build range
  game_state.gd               # AUTOLOAD: gold, unlocks, sell prices, central signal hub
  grid_manager.gd             # 60x35 grid (64px cells), Dictionary-based storage
  grid_overlay.gd             # Faint grid dots, camera-aware (only draws visible dots)
  ghost_preview.gd            # Semi-transparent placement preview (valid/invalid color)
  player.gd                   # CharacterBody2D, WASD movement, 4-directional, world clamping
  region_manager.gd           # 7 unlockable rectangular regions, gold cost, save/load
  region_overlay.gd           # Dark overlay + dashed borders on locked regions, cost labels
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
    splitter.gd               # Duplicates: 1 input -> 2 outputs (forward + side)
    sorter.gd                 # Routes by type: matching -> forward, other -> side
    bottler.gd                # Bottles potions (1s), sets is_bottled for 2x sell price
    auto_seller.gd            # Sink: sells potions for gold via GameState
  ui/
    toolbar.gd                # 9 toggle buttons with lock/unlock awareness
    gold_display.gd           # Top-right HUD: gold coin + amount, bounce/flash animation
    unlock_shop.gd            # Toggle with U key: buy recipes and machines, purchase animation
    order_panel.gd            # Right-side panel: active order cards
    notification_popup.gd     # Self-contained "Order Complete!" banner (fade in/out, auto-free)
    minimap.gd                # Corner minimap (M key toggle), shows regions/machines/player/camera
    region_prompt.gd          # "Unlock region?" popup when player approaches locked boundary
```

## Architecture

### Scene Tree (main.tscn + runtime additions)

```
Main (Node2D, main.gd)
|-- Background (ColorRect, 3840x2240, mouse_filter=IGNORE)
|-- GameWorld (Node2D, game_world.gd)
|   |-- GridOverlay (Node2D, z=0)         -- camera-aware grid dots
|   |-- RegionOverlay (Node2D, z=0)       -- [runtime] locked region dark overlay + borders
|   |-- GridManager (Node2D, z=0)         -- no visuals, maintains _grid Dictionary
|   |-- MachineContainer (Node2D, z=1)    -- dynamically holds placed machines
|   |-- ItemContainer (Node2D, z=2)       -- dynamically holds moving items
|   |-- Player (CharacterBody2D, z=3)     -- [runtime] WASD wizard character
|   |   |-- CollisionShape2D              -- 20x20 RectangleShape2D
|   |   +-- Camera2D                      -- smooth follow, clamped to world bounds
|   |-- EffectsContainer (Node2D, z=4)    -- particle bursts and floating text
|   +-- GhostPreview (Node2D, z=5)        -- placement preview cursor
|-- RegionManager (Node, region_manager.gd)    -- [runtime] region unlock state
|-- OrderManager (Node, order_manager.gd)      -- [runtime] potion order tracking
|-- SaveManager (Node, save_manager.gd)        -- [runtime] JSON persistence
|-- TutorialManager (Node, tutorial_manager.gd) -- [runtime] contextual hints
+-- UI (CanvasLayer)
    |-- Toolbar (PanelContainer, toolbar.gd)   -- defined in .tscn
    |-- GoldDisplay (HBoxContainer)            -- [runtime]
    |-- OrderPanel (PanelContainer)            -- [runtime]
    |-- UnlockShop (PanelContainer)            -- [runtime]
    |-- Minimap (PanelContainer)               -- [runtime]
    +-- (RegionPrompt, NotificationPopup, TutorialHint) -- transient, created/freed dynamically
```

Nodes marked `[runtime]` are created in `main.gd`'s `_ready()`, not defined in the `.tscn` file. This is because they are pure scripts with no scene structure.

### Autoloads (project.godot)

| Name | Script | Purpose |
|---|---|---|
| `GameState` | `game_state.gd` | Gold, unlocks, sell prices, central signal hub |
| `SoundManager` | `sound_manager.gd` | 9 synth sounds, `SoundManager.play("name")` |

### Initialization Order (main.gd _ready)

Order matters because later steps depend on earlier ones:

1. **Scene-defined nodes** - GameWorld, Toolbar, UI CanvasLayer (from main.tscn)
2. **Player** - Instantiate player.tscn, add to GameWorld, set game_world.player
3. **RegionManager** - Create via .new(), add to Main, set game_world.region_manager
4. **RegionOverlay** - Create via .new(), insert into GameWorld (z=0, after GridOverlay)
5. **OrderManager** - Create via preload().new(), add to Main
6. **SaveManager** - Create via preload().new(), add to Main
7. **TutorialManager** - Create via .new(), connect to UI CanvasLayer
8. **UI panels** - GoldDisplay, OrderPanel, UnlockShop, Minimap (added to UI CanvasLayer)
9. **Wire save_manager.setup()** - Pass all subsystem references
10. **Load or fresh start** - save_manager.load_game() then _restore_machines()/_restore_player_pos(), or tutorial_manager.show_initial_hint()

### Player + Camera System

**Player** (`player.gd`, `player.tscn`): CharacterBody2D with WASD movement.

- **Movement**: 4-directional only (no diagonal). When both axes pressed, dominant axis wins. `move_speed = 200.0 px/s`.
- **Facing**: Stored as `Vector2i`, updated on input. Used for visual indicator dot.
- **World bounds**: Position clamped to `[16, world_width - 16]` after each `move_and_slide()`.
- **Grid position**: `get_grid_pos()` converts pixel position to grid coords (integer division by CELL_SIZE).
- **Visuals**: Placeholder `_draw()` circle + triangle hat (replaced with sprite in Phase 5).

**Camera2D** (child of Player):
- `position_smoothing_enabled = true`, `position_smoothing_speed = 5.0`
- Limits: `left=0, top=0, right=3840, bottom=2240` (full world bounds)
- Viewport remains 1280x720 -- camera handles scrolling.

**Input routing**: Player polls `Input.is_key_pressed()` in `_physics_process()`. Mouse events use `get_global_mouse_position()` in `game_world._unhandled_input()` to convert screen coords to world coords.

### Grid System

- **Size:** 60x35 cells, 64px each -> 3840x2240 px (expanded from original 20x11)
- **Data:** `_grid: Dictionary` mapping `Vector2i -> Node2D` (machine or null)
- **Coords:** `world_pos = grid_pos * 64 + 32` (cell center)
- **Key methods:** `place_machine()`, `remove_machine()`, `get_machine_at()`, `get_neighbor()`, `world_to_grid()`, `grid_to_world()`

### Region System

**RegionManager** (`region_manager.gd`): Divides the 60x35 grid into 7 rectangular regions.

| ID | Name | Grid Rect | Cost |
|---|---|---|---|
| 0 | Starter Workshop | (0,0) -> (14,11) | Free |
| 1 | East Wing | (15,0) -> (29,11) | 500g |
| 2 | South Cellar | (0,12) -> (14,23) | 750g |
| 3 | Grand Hall | (15,12) -> (29,23) | 1000g |
| 4 | North Tower | (0,24) -> (29,34) | 1500g |
| 5 | Enchanted Annex | (30,0) -> (59,17) | 2000g |
| 6 | Master Laboratory | (30,18) -> (59,34) | 3000g |

Regions are stored as `Rect2i(x, y, width, height)`. `has_point()` checks membership.

**RegionOverlay** (`region_overlay.gd`): Draws locked regions as dark semi-transparent rectangles with dashed borders and name/cost labels. Camera-aware (`queue_redraw()` every frame).

**Region Prompt** (`region_prompt.gd`): When the player walks within 2 cells of a locked region boundary, `main._check_region_prompt()` creates a `PanelContainer` prompt at the top of the screen with region name, cost, and Yes/No buttons. Dismissed when player walks away or clicks No. Only one prompt shows at a time (tracked by `_prompt_region_id`).

### Build Range Enforcement

`game_world.BUILD_RANGE = 5` cells (Chebyshev distance: `max(|dx|, |dy|) <= 5`).

Checked in:
- `_update_ghost_preview()` -- ghost turns red when out of range
- `_try_place()` -- blocks placement
- `_try_remove()` -- blocks removal
- `_try_place()` (no tool) -- blocks machine interaction and hand-sell

Also checks `region_manager.is_unlocked(grid_pos)` -- can't build in locked regions.

### Machine Inheritance

```
MachineBase (Node2D)          -- grid_pos, direction, current_item, item_container, try_push_item(), receive_item()
|-- Dispenser                 -- spawns items on timer, click to cycle (unlocked ingredients only)
|-- ConveyorBelt              -- simple relay: accept -> arrive -> push forward (120 px/s)
|-- FastBelt                  -- same as conveyor but 2x speed (240 px/s)
|-- Cauldron                  -- accepts 2 ingredients -> brew 1.5s -> output potion
|-- StorageChest              -- buffers up to 8 items, FIFO output
|-- Splitter                  -- duplicates: 1 input -> 2 copies (forward + 90deg CW side)
|-- Sorter                    -- routes by type: matching -> forward, non-matching -> side. Click to set filter.
|-- Bottler                   -- potions only, 1.0s process, sets is_bottled (2x sell price)
+-- AutoSeller                -- sink: sells potions for gold, 0.5s sell time
```

### Item Flow (Push + Reservation)

This is the core transport model. All item movement is "push"-based:

1. Machine A calls `target.receive_item(item)` -- reserves target's `current_item` slot
2. Target stores item reference; item begins smooth movement to target position
3. Item arrives (`is_moving = false`), target can now process or push it onward
4. `try_push_item()` checks: target exists AND `target.current_item == null`
5. Cauldron/StorageChest/Bottler/AutoSeller use `_waiting_for_arrival` flag to distinguish incoming items (being consumed) from output items (being pushed forward)

The reservation prevents two machines from sending items to the same target simultaneously.

### Recipe System

- **10 recipes implemented** (2 unlocked at start, 8 unlockable with gold)
- **Lookup:** sorted ingredient pair key (e.g. `"1,2"`) -> [recipe_index, result_type], unlock-aware
- **30 item types:** 20 ingredients + 10 potions
- **Unlock gating:** `Recipes.check()` returns NONE for locked recipes

### Signal Architecture

GameState is the central signal hub. Connection map:

```
GameState.gold_changed      -> GoldDisplay (UI bounce + color flash)
                            -> TutorialManager (triggers "open_shop" hint)
                            -> UnlockShop (refresh button affordability)

GameState.recipe_unlocked   -> Toolbar (refresh button lock states)
                            -> UnlockShop (refresh button states)

GameState.machine_unlocked  -> Toolbar (refresh button lock states)
                            -> UnlockShop (refresh button states)

GameState.potion_sold       -> OrderManager (increment order progress)

GameState.potion_brewed     -> TutorialManager (triggers "cycle_dispenser" + "hand_sell" hints)

GameState.region_unlocked   -> RegionOverlay (queue_redraw to remove dark overlay)

Toolbar.machine_selected    -> GameWorld.select_machine (set placement tool)

OrderManager.order_completed -> (currently unused externally, available for future features)
```

### Effects System

**EffectsManager** -- static class, no instance needed. Uses `CPUParticles2D` (not GPU -- GL Compatibility renderer). Setup once from `game_world._ready()`.

| Method | Used By | Visual |
|---|---|---|
| `spawn_burst(pos, color, count, radius, lifetime)` | Cauldron, AutoSeller, Dispenser, Bottler, GameWorld | One-shot particle burst, auto-frees |
| `spawn_gold_text(pos, amount)` | AutoSeller, GameWorld (hand-sell) | Floating "+Xg" label, tweens up + fades |

**SoundManager** -- autoload singleton. Generates 16-bit mono PCM audio buffers programmatically in `_ready()` using `AudioStreamWAV`. No external audio files.

| Sound | Trigger | Description |
|---|---|---|
| `place` | Machine placed | Rising sweep 300->500 Hz |
| `remove` | Machine removed | Falling sweep 400->200 Hz |
| `brew_complete` | Cauldron finishes | Bright sine chime 800 Hz |
| `sell` | AutoSeller sells / hand-sell | Coin clink (two quick hits) |
| `unlock` | Shop purchase / region unlock | 3-note ascending arpeggio |
| `dispense` | Dispenser spawns item | Soft noise burst |
| `bottle` | Bottler finishes | Glass sine clink |
| `order_complete` | Order fulfilled | 3-note fanfare |
| `click` | Toolbar / dispenser click | Tiny noise burst |

### Tutorial System

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

### Minimap

Corner minimap (`minimap.gd`) toggles with M key. Uses a `Control` child with custom `_draw()` inside a `PanelContainer`.

- **Scale**: 4 pixels per grid cell -> 240x140 px display
- **Shows**: Locked regions (dark), region borders, machine dots (green), player dot (white), camera viewport rect (white outline)
- **Updates**: `queue_redraw()` every frame when visible
- **Position**: Top-right corner, below gold display

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
  "tutorial_seen": ["select_dispenser", "rotate_hint", "place_belts"],
  "unlocked_regions": [0, 1],
  "player_pos": { "x": 480.0, "y": 352.0 }
}
```

Backward compatible: new fields use `data.get("key", default)`. Machine restoration is a two-step process -- `save_manager.load_game()` populates `loaded_machines` and `loaded_player_pos`, then `main._restore_machines()` and `main._restore_player_pos()` apply them.

## Controls

| Input | Action |
|---|---|
| W/A/S/D | Move player (4-directional, no diagonal) |
| Left click | Place machine (with tool) / Interact or hand-sell (without tool) |
| Right click | Remove machine |
| R | Rotate placement direction 90deg CW |
| M | Toggle minimap |
| U | Toggle Unlock Shop |
| Ctrl+S | Manual save |
| Click dispenser/sorter | Cycle ingredient/filter type (no tool selected) |

## Conventions & Gotchas

### GDScript Patterns
- **All visuals use `_draw()`** -- no external art assets, no sprites (Phases 1-4). Phase 5 will replace with pixel art.
- **All sounds are procedural** -- no external .wav/.ogg files. AudioStreamWAV buffers generated at startup.
- **Constants are duplicated** across scripts (e.g. `CELL_SIZE := 64` in grid_manager.gd, machine_base.gd, player.gd, region_manager.gd, grid_overlay.gd). Don't cross-reference via `class_name` -- load order isn't deterministic.
- **`@warning_ignore("integer_division")`** for grid math (`int / int` triggers a Godot warning).
- **Static class pattern:** `EffectsManager` uses static methods + static var `_container`, set via `setup()`.
- **`_waiting_for_arrival` pattern:** Cauldron, StorageChest, Bottler, and AutoSeller use this flag to distinguish incoming items (in transit, will be consumed) from output items (at rest, ready to push).

### Godot Engine Gotchas
- **`mouse_filter = 2` (IGNORE)** on full-screen `ColorRect` backgrounds. Control nodes default to `MOUSE_FILTER_STOP` and will eat clicks, preventing `_unhandled_input()` from firing.
- **Autoloads can't use class_names:** `game_state.gd` and `sound_manager.gd` use `load()` at runtime for cross-script access. Never reference `class_name` identifiers in autoload scripts.
- **Private members are enforced:** `_`-prefixed members can't be accessed cross-script in Godot 4. Use public names for shared APIs.
- **CPUParticles2D only:** The project uses GL Compatibility renderer. GPUParticles2D is not supported.
- **CPUParticles2D.color_ramp** expects `Gradient`, NOT `GradientTexture1D`.
- **AudioStreamWAV byte format**: 16-bit little-endian, `data[i*2]=low byte`, `data[i*2+1]=high byte`.
- **Label property shadowing**: Don't name method params `text` in classes extending Label.
- **Type inference with `or`/`and`**: `var x := expr_a or expr_b` fails type inference. Use explicit type: `var x: bool = expr_a or expr_b`.
- **`global_script_class_cache.cfg`**: When creating new `.gd` files with `class_name` outside the editor, the cache becomes stale. Run `godot --headless --import` or open the editor to force a rescan. Path: `/Users/Alex/Desktop/Godot.app/Contents/MacOS/Godot`
- **`get_global_mouse_position()`**: Required for mouse-to-world conversion when using Camera2D. `event.position` gives screen coords, not world coords.

## Development Status

### Phase 1 (Core Mechanics) -- COMPLETE
- **Grid system** -- 64px cells with Dictionary-based storage, `world_to_grid()`/`grid_to_world()` conversion
- **Conveyor belts** -- Push-based relay with smooth item movement (120 px/s)
- **Items** -- 4 ingredients + 2 potions, colored circles via `_draw()`, variable speed movement
- **Cauldrons** -- 2-ingredient combining with 1.5s brew timer, sorted-key recipe lookup
- **Dispensers** -- Auto-spawn every 3s, click to cycle ingredient type
- **Ghost preview** -- Semi-transparent placement cursor, red for invalid positions
- **Grid overlay** -- Faint dots at cell intersections for visual reference
- **Basic UI toolbar** -- 3 toggle buttons (Conveyor, Dispenser, Cauldron) with selection state
- **2 recipes working** -- Health Potion (Mushroom+Herb), Mana Potion (Crystal+Water)
- **Core input** -- Left-click place, right-click remove, R rotate direction 90deg CW
- **Push + Reservation transport** -- `receive_item()` reserves slot, prevents double-sends

### Phase 2 (Progression) -- COMPLETE
- **10 recipes** -- 20 ingredients + 10 potions, unlock-gated brewing via `Recipes.check()`
- **6 new machines** -- Fast Belt (2x speed), Storage Chest (8-slot FIFO buffer), Splitter (1->2 duplication), Sorter (type-based routing), Bottler (2x sell price), Auto-Seller (gold sink)
- **GameState autoload** -- Gold currency, potion sell prices (10g-60g base), unlock costs for recipes (50g-400g) and machines (30g-250g), central signal hub
- **Unlock shop** -- U key toggles full-screen overlay, buy recipes and machines, green flash + scale bounce on purchase
- **Order system** -- Up to 3 concurrent orders generated by OrderManager, no time pressure, bonus gold on completion (50-150% of base value)
- **Save/load system** -- JSON at `user://savegame.json`, auto-save every 60s, manual Ctrl+S, save-on-quit via `NOTIFICATION_WM_CLOSE_REQUEST`. Two-step machine restoration: `loaded_machines` array -> `main._restore_machines()`
- **Hand-sell** -- Click potions on machines (no tool selected) to sell for floor(base/2) price, minimum 1g
- **Bootstrap economy** -- Start with 0g, hand-sell potions to earn first gold, unlock Auto-Seller (250g) to automate income
- **9-button toolbar** -- Lock/unlock awareness per machine type, toggle button selection with visual states
- **Order panel** -- Right-side UI showing active order cards with potion name, quantity, progress, reward
- **Gold display** -- Top-right HUD showing coin icon + amount

### Phase 3 (Polish) -- COMPLETE
- **Particle effects** -- `EffectsManager` static class using CPUParticles2D one-shot bursts for: brew complete (purple), sell (gold), dispense (green), bottle (amber), place (white), remove (red-orange)
- **Sound effects** -- `SoundManager` autoload generating 9 programmatic synth sounds via AudioStreamWAV (16-bit mono PCM): place (rising sweep), remove (falling sweep), brew_complete (sine chime), sell (coin clink), unlock (3-note arpeggio), dispense (noise burst), bottle (glass clink), order_complete (fanfare), click (tiny burst)
- **Gold display animation** -- Scale bounce (1.0 -> 1.3 -> 1.0 over 0.3s) + color flash (green on gain, red on spend)
- **Order completion notification** -- Centered "Order Complete! +Xg" banner, fades in over 0.2s, holds 2s, fades out over 0.5s, auto-frees
- **Unlock shop animation** -- Green flash + scale bounce on purchase confirmation
- **Tutorial system** -- 7 contextual hints shown sequentially (`select_dispenser` -> `rotate_hint` -> `place_belts` -> `place_cauldron` -> `cycle_dispenser` -> `hand_sell` -> `open_shop`), dismissed by clicking anywhere, state persisted in save data as `tutorial_seen` string array
- **Floating gold text** -- "+Xg" labels spawned at sell points, tween upward 30px + fade out over 0.7s, auto-free

### Phase 4 (Player + World) -- COMPLETE
- **Player CharacterBody2D** -- WASD movement (4-directional, no diagonal, 200 px/s), `move_and_slide()` with world bounds clamping, placeholder `_draw()` purple circle + triangle hat + facing dot
- **Camera2D** -- Child of Player, position smoothing (speed 5.0), limits clamped to world bounds (0,0 -> 3840,2240), viewport remains 1280x720
- **Grid expanded** -- 20x11 -> 60x35 cells (3840x2240 px world), Background ColorRect resized to match
- **7 unlockable regions** -- RegionManager with Rect2i regions covering all 2100 cells, Region 0 free, others 500g-3000g, `is_unlocked()`/`unlock_region()` API
- **Build range enforcement** -- 5 cells from player (Chebyshev distance), checked in ghost preview, placement, removal, and interaction. Ghost turns red when out of range
- **Region overlay** -- Dark semi-transparent rectangles on locked regions, dashed borders on all regions (bold for locked, subtle for unlocked), centered name/cost labels
- **Region unlock prompt** -- PanelContainer at top-center when player walks within 2 cells of locked boundary, Yes/No buttons, fade in/out animation, affordability-aware disabled state
- **Minimap** -- M key toggle, PanelContainer with custom `_draw()` Control, 4px/cell scale (240x140 display), shows regions/machines/player/camera rect
- **Grid overlay optimized** -- Camera-aware dot rendering using `get_canvas_transform().affine_inverse()`, only draws dots visible in viewport
- **Save/load extended** -- `unlocked_regions` (Array of region IDs) + `player_pos` ({x, y} dict), backward compatible via `data.get("key", default)`
- **Input routing updated** -- `get_global_mouse_position()` for screen-to-world conversion with Camera2D, WASD handled by Player's `_physics_process()` (not `_unhandled_input`)

### Phase 5 (Art Pass) -- PLANNED

Replace all procedural `_draw()` visuals with pixel art sprites. Target aesthetic: warm cozy pixel pub (Stardew Valley feel).

- **Asset directory structure** -- `assets/sprites/machines/` (9x 64x64 PNGs), `assets/sprites/items/` (30x 20x20 PNGs: 20 ingredients + 10 potions), `assets/sprites/player/` (4-direction walk spritesheet), `assets/sprites/ui/` (wood panel, button bg, coin, icons), `assets/sprites/tiles/` (floor tileset), `assets/fonts/pixel_font.ttf`
- **Floor TileMapLayer** -- Replace Background ColorRect with TileMapLayer using 64x64 floor tileset (warm wood planks for unlocked regions, dark stone/dirt for locked), z_index=-1
- **Machine sprites** -- Add Sprite2D child to each machine .tscn, load texture from `assets/sprites/machines/{type}.png`, remove `_draw()` overrides from all 9 machine scripts + machine_base.gd. Direction handling via `sprite.rotation` or 4-direction sheets. Keep minimal `_draw()` overlays for brew progress bubbles on Cauldron
- **Item sprites** -- Replace colored circle `_draw()` in item.gd with Sprite2D loaded by `item_type`. Add `SPRITE_PATHS` dict to ItemTypes for type -> texture lookup. Bottled variant: swap to bottled sprite or add bottle overlay
- **Player AnimatedSprite2D** -- Replace placeholder circle with 4-direction spritesheet (~32x48 per frame), idle (1-2 frames) + walk (3-4 frames) animations per direction. Play animation based on `velocity` and `facing`
- **Ghost preview sprites** -- Replace semi-transparent rectangle with semi-transparent machine sprite at 50% alpha, red tint for invalid, green tint for valid
- **Region visual polish** -- Locked regions get darker floor tiles + overlay, unlock triggers brief "unveil" animation (tween overlay alpha 1.0 -> 0.0)
- **Files: New** -- `assets/sprites/**/*.png` (9 machines + 30 items + player spritesheet + tiles + UI textures), `assets/fonts/pixel_font.ttf`, floor TileMapLayer scene/resource
- **Files: Modified** -- `machine_base.gd` + all 9 machine scripts + .tscn files (add Sprite2D, remove _draw), `item.gd` + `item.tscn`, `player.gd` + `player.tscn`, `ghost_preview.gd`, `item_types.gd` (SPRITE_PATHS), `main.tscn`
- **Asset sourcing** -- Character spritesheet + floor tileset from itch.io asset packs, machine/item sprites custom pixel art or AI-generated, pixel font from Google Fonts or itch.io (e.g., "Press Start 2P" or "Silver")

### Phase 6 (UI Overhaul) -- PLANNED

Replace all code-built `StyleBoxFlat` UI with warm wood panel aesthetic, pixel font, icons, and tooltips.

- **Pixel font + theme resource** -- Create `theme/cozy_theme.tres` (Godot Theme resource) with pixel font as default, font sizes 12/16/20/28, styled Button/Panel/Label defaults. Apply to root node or UI CanvasLayer so all children inherit
- **Wood panel StyleBoxTexture** -- Replace all `StyleBoxFlat` (solid color rectangles) with `StyleBoxTexture` using 9-slice wood panel PNG on: toolbar, unlock shop, order panel, minimap, tutorial hints, notification popups, region prompt
- **Toolbar redesign** -- Replace text-only buttons with icon buttons showing machine sprite (scaled ~32x32) + short label below. Selected state: golden glow border. Locked state: greyed-out sprite + lock icon overlay. Hover: slight scale-up or brightness increase
- **Tooltips** -- New `scripts/ui/tooltip.gd`. Hover tooltips on toolbar buttons + shop items showing machine/recipe info (name, description, cost). Wood panel background, pixel font, positioned near cursor, clamped to screen bounds
- **Gold display redesign** -- Replace text "coin" with proper coin sprite (`assets/sprites/ui/coin.png`), keep bounce/flash animation, add wood panel background
- **Order panel redesign** -- Wood panel card per order, potion sprite icon + name + progress bar (filled portion colored), reward shown as coin icon + amount, completion animation: card flashes gold then slides off
- **Unlock shop redesign** -- Full-screen overlay with wood panel background, two sections ("Recipes" and "Machines") with headers, each item shows sprite icon + name + cost + "Buy" button (or "Owned" badge), grid layout instead of vertical list, close button + ESC
- **Build range indicator** -- Subtle visual showing buildable cells around player, faint highlighted cells within 5-cell range, only visible when a tool is selected (machine placement mode), drawn in GameWorld between grid overlay and machines
- **Notification + tutorial reskin** -- Notifications: wood panel background, pixel font, coin icon for gold amounts. Tutorial hints: parchment/scroll style panel, warm yellow text, click-to-dismiss indicator
- **Files: New** -- `theme/cozy_theme.tres`, `scripts/ui/tooltip.gd`, `assets/sprites/ui/*.png` (wood panel 9-slice, coin, lock icon, button backgrounds)
- **Files: Modified** -- `toolbar.gd`, `gold_display.gd`, `order_panel.gd`, `unlock_shop.gd`, `notification_popup.gd`, `tutorial_manager.gd`, `game_world.gd` (build range indicator), `main.tscn` (apply theme)

### Phase 7 (Menu + Music + Steam) -- PLANNED

Add main menu, pause menu, settings system, background music, and Steam integration for release.

- **Main menu scene** -- New `scenes/main_menu.tscn` + `scripts/ui/main_menu.gd`. Title "The Cozy Cauldron" in large pixel font with warm glow, cozy pub background illustration or animated scene (bubbling cauldrons, flickering candles). Buttons: "New Game", "Continue" (greyed if no save), "Settings", "Quit". Set as `project.godot` main_scene. Scene transition: fade-to-black tween (0.5s)
- **Settings manager autoload** -- New `scripts/settings_manager.gd`, registered in project.godot. Persistent settings at `user://settings.json`: master_volume, music_volume, sfx_volume (all 0.0-1.0), fullscreen toggle. Settings UI panel with volume sliders + fullscreen toggle, accessible from main menu and pause menu
- **Music manager autoload** -- New `scripts/music_manager.gd`, registered in project.godot. Plays CC0 music tracks (`.ogg` Vorbis format) with crossfade (1.0s tween). Two AudioStreamPlayers (current + fade). 2-3 tracks: menu theme, gameplay theme, shop/unlock theme. `MusicManager.play_track("gameplay")`, `.stop()`, `.set_volume()`. Responds to SettingsManager.music_volume. Sources: opengameart.org, itch.io CC0 fantasy/tavern/cozy packs
- **Pause menu** -- New `scripts/ui/pause_menu.gd`. ESC key opens overlay (CanvasLayer): darkened background, buttons "Resume", "Settings", "Main Menu", "Quit". `get_tree().paused = true`, pause menu node has `process_mode = PROCESS_MODE_ALWAYS`
- **Music wiring** -- Main menu: play menu theme. Gameplay: crossfade to gameplay theme on scene load. Shop open: optionally lower gameplay volume. Order complete: brief musical sting (already have sound)
- **Endgame popup** -- New `scripts/ui/endgame_popup.gd`. When player unlocks all regions + all recipes + all machines: show congratulations banner with stats (total gold earned, potions brewed). "Continue playing" button for sandbox mode. Not a hard ending, just a milestone celebration
- **Steam integration** -- GodotSteam addon for basic integration: init, achievements, cloud save. Steam achievements mapped to milestones: first brew, first 100g, all recipes unlocked, all regions unlocked. Export presets for Windows/Mac/Linux. App icon from pixel art assets. Window title "The Cozy Cauldron"
- **Files: New** -- `scenes/main_menu.tscn`, `scripts/ui/main_menu.gd`, `scripts/settings_manager.gd`, `scripts/music_manager.gd`, `scripts/ui/pause_menu.gd`, `scripts/ui/endgame_popup.gd`, `assets/music/*.ogg` (2-3 CC0 tracks)
- **Files: Modified** -- `project.godot` (main_scene -> main_menu.tscn, add autoloads: SettingsManager, MusicManager), `main.gd` (pause menu, music wiring), `unlock_shop.gd` (music volume change), `game_state.gd` (endgame detection), `sound_manager.gd` (respect SFX volume setting)

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
| Cauldron | `cauldron` | Free | Combines 2 ingredients -> potion (1.5s brew) |
| Fast Belt | `fast_belt` | 30g | 2x speed conveyor (240 px/s) |
| Storage Chest | `storage` | 60g | Buffers up to 8 items (FIFO) |
| Sorter | `sorter` | 80g | Routes by type: matching -> forward, other -> side |
| Splitter | `splitter` | 100g | Duplicates: 1 input -> 2 outputs (forward + side) |
| Bottler | `bottler` | 120g | Bottles potions (1s), is_bottled = 2x sell price |
| Auto-Seller | `auto_seller` | 250g | Sink: sells potions for gold (0.5s) |

## Region Unlock Costs (7 regions)

| ID | Region | Size | Cost |
|---|---|---|---|
| 0 | Starter Workshop | 15x12 | Free |
| 1 | East Wing | 15x12 | 500g |
| 2 | South Cellar | 15x12 | 750g |
| 3 | Grand Hall | 15x12 | 1000g |
| 4 | North Tower | 30x11 | 1500g |
| 5 | Enchanted Annex | 30x18 | 2000g |
| 6 | Master Laboratory | 30x17 | 3000g |

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
2. If you added new `.gd` files with `class_name`, rescan: `"/Users/Alex/Desktop/Godot.app/Contents/MacOS/Godot" --headless --import`
3. Run in Godot editor
4. Test manually -- walk to machines, build chain: Dispenser -> Belt -> Cauldron -> Bottler -> Auto-Seller
5. Verify: particles fire, sounds play, gold animates, orders complete, build range enforced
6. Walk to locked region boundary, verify prompt appears, try unlock
7. Press M to verify minimap
8. Delete save file (`user://savegame.json`) to test tutorial flow from scratch

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
- **No diagonal movement** - Player is 4-directional only (pixel aesthetic)

---

When in doubt: **Keep it simple, keep it focused, keep it cozy.**
