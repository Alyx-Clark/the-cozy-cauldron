# The Cozy Cauldron

A cozy 2D automation game where you build an automated potion brewery for a magical pub.

## Game Concept

You run the potion brewery at **The Cozy Cauldron**, a magical pub. Build automated production chains using conveyor belts, cauldrons, and magical machines to brew potions efficiently.

**Core Gameplay:**
- Place machines on a grid (dispensers, belts, cauldrons, bottlers, sorters)
- Automate potion production chains
- Complete orders to earn gold
- Unlock 10 recipes and 9 machine types
- Optimize your factory layout

**Target Audience:** Cozy gamers, automation fans, Factorio/Shapez.io players looking for a lighter experience

## Features

- **9 machine types** — Conveyor Belt, Dispenser, Cauldron, Fast Belt, Storage Chest, Splitter, Sorter, Bottler, Auto-Seller
- **10 potion recipes** — Health, Mana, Speed, Love, Invisibility, Fire Resistance, Strength, Night Vision, Water Breathing, Lucky
- **Gold economy** — Sell potions to earn gold, unlock new recipes and machines
- **Order system** — Up to 3 concurrent orders with bonus gold on completion
- **Save/load** — Auto-save every 60s, manual Ctrl+S, save-on-quit
- **Particle effects** — Bursts on brewing, selling, dispensing, bottling, placing, removing
- **Synth sound effects** — 9 procedural sounds (no external audio files)
- **Tutorial hints** — 7 contextual hints for new players
- **UI polish** — Gold counter animations, order completion notifications, shop purchase animations

## Controls

| Input | Action |
|---|---|
| Left click | Place machine (with tool) / Interact or hand-sell (without tool) |
| Right click | Remove machine |
| R | Rotate placement direction |
| U | Toggle Unlock Shop |
| Ctrl+S | Manual save |
| Click dispenser/sorter | Cycle ingredient/filter type (no tool selected) |

## Technical Stack

- **Engine:** Godot 4.5
- **Language:** GDScript
- **Renderer:** GL Compatibility
- **Platform:** Windows/Mac/Linux (Steam)
- **Resolution:** 1280x720 base, scalable
- **Art Style:** Procedural 2D (`_draw()` calls, no external sprites)
- **Audio:** Programmatic synth via AudioStreamWAV (no external audio files)

## Project Structure

```
cozy-cauldron/
├── scenes/              # .tscn scene files (main, machines, items)
├── scripts/             # .gd script files
│   ├── data/            # ItemTypes enum, Recipes
│   ├── items/           # Item entity (movement, rendering)
│   ├── machines/        # MachineBase + 9 machine subclasses
│   └── ui/              # Toolbar, GoldDisplay, OrderPanel, UnlockShop, NotificationPopup
├── project.godot        # Godot project config (autoloads: GameState, SoundManager)
├── CLAUDE.md            # Detailed architecture docs for AI assistants
└── README.md
```

## Running the Game

1. Open project in Godot 4.5+
2. Press F5 or click "Run Project"

## Development Status

| Phase | Status | Description |
|---|---|---|
| Phase 1 — Core Mechanics | Complete | Grid, conveyors, cauldrons, dispensers, 2 recipes |
| Phase 2 — Progression | Complete | 10 recipes, 9 machines, gold economy, orders, save/load |
| Phase 3 — Polish | Complete | Particles, sounds, UI animations, tutorial |

## Release Plan

- **Platform:** Steam
- **Price:** $4.99
- **Goal:** Make $100+ revenue (25+ sales after Steam's cut)
- **Marketing:** YouTube shorts, Reddit (r/CozyGamers), DevLog

## License

Copyright 2026 - All Rights Reserved (will update for Steam release)

---

Built with Godot 4
