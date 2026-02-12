# CLAUDE.md

Project instructions for Claude Code when working on **The Cozy Cauldron**.

## Project Overview

**The Cozy Cauldron** is a cozy 2D automation game built in Godot 4. Players build automated potion production chains using conveyor belts, cauldrons, and magical machines.

**Tech Stack:** Godot 4.3, GDScript, 2D top-down view
**Target Platform:** Steam (Windows/Mac/Linux)
**Development Timeline:** 3-4 weeks
**Commercial Goal:** Make $100+ revenue

## Design Philosophy

1. **Focused scope** - Pure automation gameplay, no feature creep
2. **Polish over features** - One mechanic done extremely well beats many half-baked features
3. **Cozy aesthetic** - No stress, no timers, relaxing automation
4. **Clear progression** - 10-15 unlockable potion recipes
5. **YouTube-friendly** - Satisfying to watch (colorful particles, smooth movement)

## Code Guidelines

- **Use GDScript** (not C#)
- **Prefer scenes over code** where appropriate (Godot's node system)
- **Keep scripts simple** - Readability over cleverness
- **Comment non-obvious logic** - Another dev should understand it
- **No premature optimization** - Make it work, then make it fast

## Project Structure

```
scenes/       # All .tscn scene files
scripts/      # All .gd script files
assets/       # Art, sounds, fonts
  sprites/    # PNG/SVG sprites
  sounds/     # Audio files (will use Godot synth for now)
  fonts/      # Custom fonts
```

## Key Systems to Build

### Phase 1 (Week 1) - Core Mechanics
- **Grid system** - Snap-to-grid placement for machines
- **Conveyor belts** - Move items from A to B
- **Items** - Ingredients (mushroom, herb, etc.) as objects
- **Cauldrons** - Combine 2 ingredients → output potion
- **Basic UI** - Placement toolbar, simple HUD

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
