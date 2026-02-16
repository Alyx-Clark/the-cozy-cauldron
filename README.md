# The Cozy Cauldron

A cozy 2D automation game where you play as a wizard building an automated potion brewery for a magical pub.

## Game Concept

You run the potion brewery at **The Cozy Cauldron**, a magical pub. Walk around your workshop as a wizard, placing machines on a grid to build automated production chains. Brew potions, fulfill orders, earn gold, and expand your factory into new regions.

**Core Gameplay:**
- Walk around as a wizard character (WASD movement)
- Place machines within range on a 60x35 grid
- Automate potion production: Dispensers -> Belts -> Cauldrons -> Bottlers -> Auto-Sellers
- Complete orders to earn bonus gold
- Unlock 10 recipes, 9 machine types, and 7 world regions
- Expand your factory from a small starter workshop into a sprawling laboratory

**Target Audience:** Cozy gamers, automation fans, Factorio/Shapez.io players looking for a lighter experience

## Features

- **Walkable wizard character** -- WASD movement with camera following, 4-directional
- **Expandable world** -- 60x35 grid divided into 7 unlockable regions (500g-3000g)
- **9 machine types** -- Conveyor Belt, Dispenser, Cauldron, Fast Belt, Storage Chest, Splitter, Sorter, Bottler, Auto-Seller
- **10 potion recipes** -- Health, Mana, Speed, Love, Invisibility, Fire Resistance, Strength, Night Vision, Water Breathing, Lucky
- **Build range** -- Must be near machines to place/interact (5-cell range)
- **Gold economy** -- Sell potions to earn gold, unlock recipes, machines, and regions
- **Order system** -- Up to 3 concurrent orders with bonus gold on completion
- **Minimap** -- Toggle with M to see the full world, regions, and factory overview
- **Region unlock prompts** -- Walk near locked boundaries to see unlock options
- **Save/load** -- Auto-save every 60s, manual Ctrl+S, save-on-quit
- **Particle effects** -- Bursts on brewing, selling, dispensing, bottling, placing, removing
- **Synth sound effects** -- 9 procedural sounds (no external audio files)
- **Tutorial hints** -- 7 contextual hints for new players

## Controls

| Input | Action |
|---|---|
| W/A/S/D | Move wizard character |
| Left click | Place machine (with tool) / Interact or hand-sell (without tool) |
| Right click | Remove machine |
| R | Rotate placement direction |
| M | Toggle minimap |
| U | Toggle Unlock Shop |
| Ctrl+S | Manual save |
| Click dispenser/sorter | Cycle ingredient/filter type (no tool selected) |

## Technical Stack

- **Engine:** Godot 4.5
- **Language:** GDScript
- **Renderer:** GL Compatibility
- **Platform:** Windows/Mac/Linux (Steam)
- **Resolution:** 1280x720 viewport, camera-scrolled 3840x2240 world
- **Art Style:** Procedural 2D (`_draw()` calls -- pixel art replacement planned)
- **Audio:** Programmatic synth via AudioStreamWAV (no external audio files)

## Project Structure

```
cozy-cauldron/
├── scenes/              # .tscn scene files
│   ├── main.tscn        #   Root scene (Background + GameWorld + UI)
│   ├── player.tscn      #   Player (CharacterBody2D + Camera2D)
│   ├── machines/        #   9 machine scenes
│   └── items/           #   Item entity scene
├── scripts/             # .gd script files
│   ├── main.gd          #   Root orchestrator
│   ├── game_world.gd    #   Placement, input, build range
│   ├── game_state.gd    #   Autoload: gold, unlocks, signals
│   ├── player.gd        #   WASD movement, facing
│   ├── grid_manager.gd  #   60x35 grid, Dictionary storage
│   ├── region_manager.gd #  7 unlockable regions
│   ├── region_overlay.gd #  Locked region visuals
│   ├── save_manager.gd  #   JSON persistence
│   ├── sound_manager.gd #   Autoload: 9 synth sounds
│   ├── data/            #   ItemTypes enum, Recipes
│   ├── items/           #   Item entity (movement, rendering)
│   ├── machines/        #   MachineBase + 9 subclasses
│   └── ui/              #   Toolbar, GoldDisplay, OrderPanel, UnlockShop, Minimap, etc.
├── project.godot        # Godot config (autoloads: GameState, SoundManager)
├── CLAUDE.md            # Architecture docs for AI assistants
└── README.md
```

## Running the Game

1. Open project in Godot 4.5+
2. Press F5 or click "Run Project"

## Development Status

| Phase | Status | Description |
|---|---|---|
| Phase 1 -- Core Mechanics | Complete | Grid, conveyors, cauldrons, dispensers, 2 recipes |
| Phase 2 -- Progression | Complete | 10 recipes, 9 machines, gold economy, orders, save/load |
| Phase 3 -- Polish | Complete | Particles, sounds, UI animations, tutorial |
| Phase 4 -- Player + World | Complete | Wizard character, camera, 60x35 world, 7 regions, minimap |
| Phase 5 -- Art Pass | Planned | Pixel art sprites, tileset floor, animated character |
| Phase 6 -- UI Overhaul | Planned | Wood panel UI, pixel font, tooltips, icons |
| Phase 7 -- Menu + Music | Planned | Main menu, pause, settings, CC0 music, Steam integration |

## Release Plan

- **Platform:** Steam
- **Price:** $4.99
- **Goal:** Make $100+ revenue (25+ sales after Steam's cut)
- **Marketing:** YouTube shorts, Reddit (r/CozyGamers), DevLog

## License

Copyright 2026 - All Rights Reserved (will update for Steam release)

---

Built with Godot 4
