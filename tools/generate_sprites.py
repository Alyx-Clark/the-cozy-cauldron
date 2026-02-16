#!/usr/bin/env python3
"""Generate all pixel art sprites for The Cozy Cauldron.

Output structure:
  assets/sprites/tiles/floor_atlas.png      (128x64: 2 wood tile variants)
  assets/sprites/machines/{type}.png         (9 files, 64x64)
  assets/sprites/items/{name}.png            (30 files, 20x20)
  assets/sprites/items/bottle_overlay.png    (20x20)
  assets/sprites/player/player_spritesheet.png (128x192: 4 cols x 4 rows, 32x48)
"""

import os
import math
import random
from PIL import Image, ImageDraw

# Deterministic for reproducibility
random.seed(42)

BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def clamp(v, lo=0, hi=255):
    return max(lo, min(hi, int(v)))


def rgba(r, g, b, a=255):
    return (clamp(r), clamp(g), clamp(b), clamp(a))


def col_to_rgba(r, g, b, a=1.0):
    """Convert 0-1 float color to 0-255 RGBA tuple."""
    return rgba(r * 255, g * 255, b * 255, a * 255)


def darken(c, factor=0.7):
    return rgba(c[0] * factor, c[1] * factor, c[2] * factor, c[3])


def lighten(c, factor=1.3):
    return rgba(min(255, c[0] * factor), min(255, c[1] * factor), min(255, c[2] * factor), c[3])


# ── Floor Tiles ──────────────────────────────────────────────────────────────

def generate_floor_atlas():
    """128x64 atlas: 2 warm wood plank tile variants side by side."""
    img = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for tile_idx in range(2):
        ox = tile_idx * 64
        # Base warm wood color
        base_colors = [
            rgba(140, 100, 60),  # Variant 1: medium oak
            rgba(130, 90, 55),   # Variant 2: slightly darker
        ]
        base = base_colors[tile_idx]

        # Fill base
        draw.rectangle([ox, 0, ox + 63, 63], fill=base)

        # Horizontal plank lines
        plank_line = darken(base, 0.75)
        for py in [15, 31, 47]:
            draw.line([ox, py, ox + 63, py], fill=plank_line, width=1)

        # Vertical stagger lines (offset per plank row)
        for row_idx, (y_start, y_end) in enumerate([(0, 14), (16, 30), (32, 46), (48, 63)]):
            offset = (row_idx * 20 + tile_idx * 10) % 64
            stagger_x = ox + offset
            if 0 <= stagger_x - ox < 64:
                draw.line([stagger_x, y_start, stagger_x, y_end], fill=plank_line, width=1)

        # Subtle wood grain (random darker pixels)
        rng = random.Random(42 + tile_idx)
        for _ in range(50):
            gx = ox + rng.randint(0, 63)
            gy = rng.randint(0, 63)
            grain = darken(base, rng.uniform(0.85, 0.95))
            img.putpixel((gx, gy), grain)

        # Subtle lighter highlights
        for _ in range(25):
            gx = ox + rng.randint(0, 63)
            gy = rng.randint(0, 63)
            highlight = lighten(base, rng.uniform(1.05, 1.15))
            img.putpixel((gx, gy), highlight)

    return img


# ── Machine Sprites (64x64, art in ~52x52 centered) ─────────────────────────

def draw_rounded_rect(draw, bbox, color, radius=4):
    """Draw a filled rounded rectangle."""
    x0, y0, x1, y1 = bbox
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=color)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=color)
    draw.ellipse([x0, y0, x0 + radius * 2, y0 + radius * 2], fill=color)
    draw.ellipse([x1 - radius * 2, y0, x1, y0 + radius * 2], fill=color)
    draw.ellipse([x0, y1 - radius * 2, x0 + radius * 2, y1], fill=color)
    draw.ellipse([x1 - radius * 2, y1 - radius * 2, x1, y1], fill=color)


def machine_conveyor():
    """Conveyor belt: grey with rollers."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = rgba(105, 105, 115)
    draw_rounded_rect(draw, [6, 6, 57, 57], body, 4)
    # Belt track (darker strip)
    track = darken(body, 0.7)
    draw.rectangle([10, 20, 53, 43], fill=track)
    # Rollers
    roller = rgba(140, 140, 150)
    for rx in [16, 26, 36, 46]:
        draw.rectangle([rx, 22, rx + 3, 41], fill=roller)
    # Side rails
    rail = lighten(body, 1.2)
    draw.rectangle([10, 18, 53, 20], fill=rail)
    draw.rectangle([10, 43, 53, 45], fill=rail)
    return img


def machine_fast_belt():
    """Fast belt: golden with speed lines."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = rgba(180, 145, 50)
    draw_rounded_rect(draw, [6, 6, 57, 57], body, 4)
    # Belt track
    track = darken(body, 0.7)
    draw.rectangle([10, 20, 53, 43], fill=track)
    # Rollers (gold)
    roller = rgba(210, 175, 60)
    for rx in [14, 24, 34, 44]:
        draw.rectangle([rx, 22, rx + 3, 41], fill=roller)
    # Speed chevrons
    chevron = rgba(255, 220, 80, 180)
    for cx in [20, 32, 44]:
        draw.line([cx, 28, cx + 4, 32], fill=chevron, width=2)
        draw.line([cx + 4, 32, cx, 36], fill=chevron, width=2)
    # Side rails
    rail = lighten(body, 1.2)
    draw.rectangle([10, 18, 53, 20], fill=rail)
    draw.rectangle([10, 43, 53, 45], fill=rail)
    return img


def machine_dispenser():
    """Dispenser: green hopper with funnel shape."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = rgba(70, 155, 95)
    draw_rounded_rect(draw, [6, 6, 57, 57], body, 4)
    # Hopper (trapezoid top)
    hopper = darken(body, 0.8)
    draw.polygon([(14, 10), (49, 10), (43, 26), (20, 26)], fill=hopper)
    # Output chute
    chute = darken(body, 0.7)
    draw.rectangle([24, 26, 39, 50], fill=chute)
    # Ingredient circle placeholder (white ring)
    draw.ellipse([24, 32, 39, 47], outline=rgba(255, 255, 255, 180), width=2)
    # Bolts
    bolt = rgba(160, 180, 160)
    for bx, by in [(10, 10), (52, 10), (10, 52), (52, 52)]:
        draw.rectangle([bx, by, bx + 2, by + 2], fill=bolt)
    return img


def machine_cauldron():
    """Cauldron: purple pot with bubbling rim."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = rgba(145, 85, 155)
    draw_rounded_rect(draw, [6, 6, 57, 57], body, 4)
    # Cauldron pot (darker interior circle)
    pot = rgba(35, 25, 45)
    draw.ellipse([14, 16, 49, 51], fill=pot)
    # Pot rim
    rim = rgba(120, 70, 130)
    draw.ellipse([14, 16, 49, 51], outline=rim, width=2)
    # Rim highlight (top arc)
    draw.arc([14, 14, 49, 34], 200, 340, fill=lighten(rim, 1.4), width=2)
    # Bubble spots
    bubble = rgba(180, 140, 210, 160)
    draw.ellipse([22, 28, 28, 34], fill=bubble)
    draw.ellipse([34, 32, 39, 37], fill=bubble)
    draw.ellipse([27, 38, 32, 43], fill=bubble)
    # Legs
    leg = darken(body, 0.6)
    draw.rectangle([16, 50, 20, 56], fill=leg)
    draw.rectangle([43, 50, 47, 56], fill=leg)
    return img


def machine_storage_chest():
    """Storage chest: brown wooden chest with metal trim."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = rgba(130, 90, 45)
    draw_rounded_rect(draw, [6, 6, 57, 57], body, 4)
    # Lid (upper portion, slightly lighter)
    lid = lighten(body, 1.15)
    draw.rectangle([8, 8, 55, 26], fill=lid)
    # Metal band across middle
    band = rgba(160, 150, 100)
    draw.rectangle([8, 24, 55, 28], fill=band)
    # Lock/clasp
    clasp = rgba(190, 170, 80)
    draw.rectangle([28, 22, 35, 30], fill=clasp)
    draw.rectangle([29, 23, 34, 29], fill=darken(clasp, 0.7))
    # Wood planks on body
    plank_line = darken(body, 0.75)
    draw.line([8, 38, 55, 38], fill=plank_line, width=1)
    draw.line([8, 48, 55, 48], fill=plank_line, width=1)
    # Corner braces
    brace = rgba(140, 130, 80)
    for bx, by in [(8, 8), (52, 8), (8, 52), (52, 52)]:
        draw.rectangle([bx, by, bx + 4, by + 4], fill=brace)
    return img


def machine_splitter():
    """Splitter: purple with Y-fork symbol."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = rgba(145, 70, 170)
    draw_rounded_rect(draw, [6, 6, 57, 57], body, 4)
    # Y-fork symbol (lighter)
    fork_color = rgba(200, 160, 220)
    # Stem from left
    draw.rectangle([10, 28, 30, 35], fill=fork_color)
    # Upper branch to right
    draw.polygon([(30, 28), (52, 14), (52, 22), (30, 32)], fill=fork_color)
    # Lower branch to right
    draw.polygon([(30, 31), (52, 41), (52, 49), (30, 35)], fill=fork_color)
    # Gem in center
    gem = rgba(220, 180, 255)
    draw.ellipse([26, 27, 36, 37], fill=gem)
    draw.ellipse([28, 29, 34, 35], fill=lighten(gem, 1.1))
    return img


def machine_sorter():
    """Sorter: teal with branching arrow + filter circle."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = rgba(50, 145, 145)
    draw_rounded_rect(draw, [6, 6, 57, 57], body, 4)
    # Filter lens (top area)
    lens = rgba(70, 180, 180)
    draw.ellipse([22, 10, 41, 29], fill=lens)
    draw.ellipse([24, 12, 39, 27], fill=darken(lens, 0.7))
    # Lens glint
    draw.ellipse([26, 14, 30, 18], fill=rgba(120, 220, 220, 160))
    # Two channels below filter
    channel = rgba(40, 110, 110)
    # Forward channel
    draw.rectangle([28, 29, 35, 52], fill=channel)
    # Side channel
    draw.rectangle([35, 36, 52, 43], fill=channel)
    # Junction dot
    draw.ellipse([29, 33, 38, 42], fill=rgba(80, 160, 160))
    return img


def machine_bottler():
    """Bottler: amber with bottle silhouette."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = rgba(180, 130, 35)
    draw_rounded_rect(draw, [6, 6, 57, 57], body, 4)
    # Bottle silhouette (centered)
    bottle = rgba(220, 200, 160)
    # Body
    draw.rectangle([22, 26, 41, 50], fill=bottle)
    # Neck
    draw.rectangle([27, 14, 36, 26], fill=bottle)
    # Cap
    draw.rectangle([25, 10, 38, 14], fill=rgba(160, 120, 30))
    # Label on body
    label = rgba(255, 240, 200)
    draw.rectangle([24, 34, 39, 44], fill=label)
    # Shine on bottle
    shine = rgba(255, 255, 230, 120)
    draw.line([24, 28, 24, 48], fill=shine, width=1)
    return img


def machine_auto_seller():
    """Auto-seller: gold with coin/gold stack."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = rgba(190, 165, 25)
    draw_rounded_rect(draw, [6, 6, 57, 57], body, 4)
    # Gold coin stack
    coin_dark = rgba(170, 140, 10)
    coin_light = rgba(230, 200, 40)
    # Bottom coins (stack)
    for cy_offset in [40, 34, 28]:
        draw.ellipse([18, cy_offset, 45, cy_offset + 10], fill=coin_dark)
        draw.ellipse([18, cy_offset - 2, 45, cy_offset + 8], fill=coin_light)
    # Top coin detail
    draw.ellipse([22, 24, 41, 34], fill=rgba(200, 175, 20))
    # "G" on top coin
    draw.ellipse([28, 26, 35, 33], outline=rgba(140, 110, 10), width=1)
    # Sparkle
    sparkle = rgba(255, 255, 200, 200)
    draw.line([14, 14, 18, 18], fill=sparkle, width=1)
    draw.line([16, 14, 16, 18], fill=sparkle, width=1)
    draw.line([14, 16, 18, 16], fill=sparkle, width=1)
    draw.line([46, 12, 50, 16], fill=sparkle, width=1)
    draw.line([48, 12, 48, 16], fill=sparkle, width=1)
    draw.line([46, 14, 50, 14], fill=sparkle, width=1)
    return img


# ── Item Sprites (20x20) ────────────────────────────────────────────────────

def make_item_base(color_tuple):
    """Create a 20x20 base item image with the given RGBA color."""
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([2, 2, 17, 17], fill=color_tuple)
    # Inner highlight
    hl = lighten(color_tuple, 1.4)
    draw.ellipse([5, 4, 9, 8], fill=(hl[0], hl[1], hl[2], 100))
    return img


def item_mushroom():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cap = rgba(184, 72, 72)
    stem = rgba(220, 200, 170)
    # Stem
    draw.rectangle([7, 10, 12, 17], fill=stem)
    # Cap (half ellipse top)
    draw.ellipse([3, 2, 16, 14], fill=cap)
    # Cap spots
    draw.ellipse([6, 5, 8, 7], fill=rgba(255, 220, 200, 180))
    draw.ellipse([11, 4, 13, 6], fill=rgba(255, 220, 200, 180))
    draw.ellipse([8, 8, 10, 10], fill=rgba(255, 220, 200, 140))
    return img


def item_herb():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    green = rgba(80, 180, 80)
    stem_c = rgba(60, 120, 50)
    # Stem
    draw.line([10, 17, 10, 6], fill=stem_c, width=2)
    # Leaves
    draw.ellipse([4, 4, 10, 10], fill=green)
    draw.ellipse([10, 3, 16, 9], fill=green)
    draw.ellipse([6, 8, 12, 14], fill=lighten(green, 1.1))
    return img


def item_crystal():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(130, 130, 230)
    # Crystal points
    draw.polygon([(10, 2), (15, 10), (10, 18), (5, 10)], fill=c)
    # Facet highlight
    draw.polygon([(10, 2), (12, 10), (10, 14)], fill=lighten(c, 1.3))
    # Shine
    draw.line([8, 5, 9, 7], fill=rgba(200, 200, 255, 200), width=1)
    return img


def item_water():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(60, 135, 210)
    # Droplet shape
    draw.polygon([(10, 3), (16, 12), (10, 17), (4, 12)], fill=c)
    draw.ellipse([5, 9, 15, 17], fill=c)
    # Shine
    draw.ellipse([7, 8, 10, 11], fill=rgba(120, 180, 240, 150))
    return img


def item_feather():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(225, 225, 232)
    # Quill shaft
    draw.line([5, 17, 15, 3], fill=rgba(180, 180, 190), width=1)
    # Feather vane
    draw.polygon([(15, 3), (12, 7), (6, 14), (4, 14), (10, 6)], fill=c)
    draw.polygon([(15, 3), (16, 7), (12, 14), (10, 14), (14, 6)], fill=lighten(c, 1.05))
    return img


def item_lightning():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(255, 240, 50)
    # Lightning bolt
    draw.polygon([(12, 2), (6, 10), (10, 10), (8, 18), (14, 9), (10, 9)], fill=c)
    # Glow
    draw.polygon([(11, 4), (8, 9), (10, 9), (9, 15), (13, 9), (10, 9)], fill=lighten(c, 1.2))
    return img


def item_rose():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    petal = rgba(240, 100, 150)
    stem_c = rgba(50, 120, 50)
    # Stem
    draw.line([10, 17, 10, 10], fill=stem_c, width=2)
    # Petals (overlapping circles)
    draw.ellipse([5, 3, 12, 10], fill=petal)
    draw.ellipse([8, 2, 15, 9], fill=petal)
    draw.ellipse([6, 5, 13, 12], fill=lighten(petal, 1.1))
    # Center
    draw.ellipse([8, 5, 12, 9], fill=rgba(200, 60, 100))
    return img


def item_heart():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(215, 38, 64)
    # Heart shape from two circles + triangle
    draw.ellipse([3, 4, 11, 12], fill=c)
    draw.ellipse([9, 4, 17, 12], fill=c)
    draw.polygon([(3, 9), (17, 9), (10, 17)], fill=c)
    # Highlight
    draw.ellipse([5, 5, 9, 9], fill=lighten(c, 1.2))
    return img


def item_shadow():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(60, 48, 85)
    # Dark wispy shape
    draw.ellipse([3, 3, 17, 17], fill=c)
    draw.ellipse([5, 5, 15, 15], fill=darken(c, 0.7))
    # Wisps
    draw.ellipse([2, 8, 8, 14], fill=rgba(50, 40, 70, 150))
    draw.ellipse([12, 6, 18, 12], fill=rgba(50, 40, 70, 150))
    # Eye-like glint
    draw.ellipse([9, 9, 11, 11], fill=rgba(120, 100, 160, 200))
    return img


def item_moonlight():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(215, 215, 180)
    # Crescent moon
    draw.ellipse([4, 3, 16, 17], fill=c)
    draw.ellipse([7, 2, 18, 16], fill=(0, 0, 0, 0))  # Cut out
    # Glow dots (stars)
    star = rgba(255, 255, 220, 180)
    draw.point((14, 5), fill=star)
    draw.point((16, 9), fill=star)
    draw.point((13, 14), fill=star)
    return img


def item_ice():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(150, 225, 240)
    # Crystal/snowflake
    cx, cy = 10, 10
    for angle_deg in [0, 60, 120]:
        rad = math.radians(angle_deg)
        dx = int(6 * math.cos(rad))
        dy = int(6 * math.sin(rad))
        draw.line([cx - dx, cy - dy, cx + dx, cy + dy], fill=c, width=2)
    # Center
    draw.ellipse([8, 8, 12, 12], fill=lighten(c, 1.2))
    # Tips
    for angle_deg in [0, 60, 120, 180, 240, 300]:
        rad = math.radians(angle_deg)
        tx = cx + int(6 * math.cos(rad))
        ty = cy + int(6 * math.sin(rad))
        draw.point((tx, ty), fill=rgba(200, 240, 255))
    return img


def item_lava():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(240, 100, 25)
    # Blob shape
    draw.ellipse([3, 4, 17, 17], fill=c)
    # Hot core
    draw.ellipse([6, 7, 14, 14], fill=rgba(255, 180, 50))
    draw.ellipse([8, 9, 12, 13], fill=rgba(255, 230, 100))
    # Drip
    draw.polygon([(10, 4), (12, 7), (8, 7)], fill=c)
    return img


def item_dragon_scale():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(50, 128, 75)
    # Scale shape (shield-like)
    draw.polygon([(10, 2), (17, 8), (14, 17), (6, 17), (3, 8)], fill=c)
    # Scale texture lines
    draw.line([10, 2, 10, 14], fill=darken(c, 0.7), width=1)
    draw.line([6, 8, 14, 8], fill=darken(c, 0.7), width=1)
    # Highlight
    draw.polygon([(10, 3), (14, 8), (10, 8)], fill=lighten(c, 1.3))
    return img


def item_ember():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(255, 150, 35)
    # Flame shape
    draw.polygon([(10, 2), (15, 10), (13, 17), (7, 17), (5, 10)], fill=c)
    # Inner flame
    draw.polygon([(10, 5), (13, 10), (11, 15), (9, 15), (7, 10)], fill=rgba(255, 200, 80))
    # Core
    draw.polygon([(10, 8), (12, 11), (10, 14), (8, 11)], fill=rgba(255, 240, 150))
    return img


def item_glowshroom():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cap = rgba(175, 240, 75)
    stem = rgba(190, 210, 150)
    # Stem
    draw.rectangle([8, 10, 12, 17], fill=stem)
    # Cap
    draw.ellipse([3, 2, 17, 13], fill=cap)
    # Glow spots
    glow = rgba(220, 255, 130, 200)
    draw.ellipse([6, 4, 8, 6], fill=glow)
    draw.ellipse([12, 5, 14, 7], fill=glow)
    draw.ellipse([9, 7, 11, 9], fill=glow)
    return img


def item_eye():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(215, 180, 50)
    # Eye white (ellipse)
    draw.ellipse([2, 5, 18, 15], fill=rgba(240, 230, 200))
    # Iris
    draw.ellipse([7, 6, 14, 14], fill=c)
    # Pupil
    draw.ellipse([9, 8, 12, 12], fill=rgba(30, 20, 10))
    # Glint
    draw.point((10, 9), fill=rgba(255, 255, 255, 220))
    # Eyelid line
    draw.arc([2, 3, 18, 15], 200, 340, fill=rgba(150, 120, 40), width=1)
    return img


def item_seaweed():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(35, 128, 115)
    # Wavy strands
    draw.line([7, 17, 6, 12, 8, 8, 6, 3], fill=c, width=2, joint="curve")
    draw.line([13, 17, 14, 12, 12, 8, 14, 3], fill=c, width=2, joint="curve")
    draw.line([10, 17, 10, 10, 11, 5], fill=lighten(c, 1.2), width=2, joint="curve")
    return img


def item_bubble():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(180, 230, 255, 160)
    # Main bubble
    draw.ellipse([3, 3, 17, 17], fill=c)
    draw.ellipse([3, 3, 17, 17], outline=rgba(200, 240, 255, 200), width=1)
    # Shine
    draw.ellipse([6, 5, 10, 9], fill=rgba(230, 245, 255, 180))
    # Small bubble
    draw.ellipse([14, 13, 16, 15], fill=rgba(220, 240, 255, 140))
    return img


def item_clover():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(50, 150, 60)
    stem_c = rgba(40, 100, 45)
    # Stem
    draw.line([10, 17, 10, 11], fill=stem_c, width=2)
    # 4 leaves (clover)
    for ox, oy in [(-3, -3), (3, -3), (-3, 3), (3, 3)]:
        draw.ellipse([10 + ox - 3, 8 + oy - 3, 10 + ox + 3, 8 + oy + 3], fill=c)
    # Center
    draw.ellipse([9, 7, 11, 9], fill=lighten(c, 1.3))
    return img


def item_star():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(255, 215, 50)
    # 5-pointed star
    points = []
    for i in range(10):
        angle = math.radians(i * 36 - 90)
        r = 8 if i % 2 == 0 else 4
        px = 10 + r * math.cos(angle)
        py = 10 + r * math.sin(angle)
        points.append((int(px), int(py)))
    draw.polygon(points, fill=c)
    # Center glow
    draw.ellipse([8, 8, 12, 12], fill=lighten(c, 1.3))
    return img


def make_potion(color_tuple):
    """Generic potion bottle filled with color."""
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    bottle_glass = rgba(200, 200, 210, 140)
    # Bottle body
    draw.rectangle([5, 8, 14, 17], fill=color_tuple)
    draw.rectangle([5, 8, 14, 17], outline=bottle_glass, width=1)
    # Bottle neck
    draw.rectangle([7, 4, 12, 8], fill=rgba(color_tuple[0], color_tuple[1], color_tuple[2], 120))
    draw.rectangle([7, 4, 12, 8], outline=bottle_glass, width=1)
    # Cork
    draw.rectangle([8, 2, 11, 4], fill=rgba(160, 120, 70))
    # Shine
    draw.line([6, 9, 6, 15], fill=rgba(255, 255, 255, 80), width=1)
    return img


def item_bottle_overlay():
    """Golden bottle outline overlay for bottled potions."""
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    gold = rgba(230, 200, 80, 200)
    # Bottle outline
    draw.rectangle([4, 7, 15, 18], outline=gold, width=2)
    draw.rectangle([6, 3, 13, 7], outline=gold, width=2)
    # Star sparkle
    draw.line([2, 2, 4, 4], fill=rgba(255, 230, 100, 180), width=1)
    draw.line([3, 2, 3, 4], fill=rgba(255, 230, 100, 180), width=1)
    draw.line([2, 3, 4, 3], fill=rgba(255, 230, 100, 180), width=1)
    return img


# ── Player Spritesheet (128x192: 4 cols x 4 rows, 32x48 frames) ────────────

def generate_player_spritesheet():
    """4 rows (down, right, up, left) x 4 columns (walk frames).
    Each frame is 32x48. Purple-robed wizard with pointy hat."""
    img = Image.new("RGBA", (128, 192), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colors
    robe = rgba(130, 65, 170)
    robe_dark = rgba(100, 50, 140)
    hat = rgba(90, 40, 130)
    hat_band = rgba(180, 140, 50)
    skin = rgba(230, 190, 150)
    shoe = rgba(80, 50, 30)

    # Directions: down=0, right=1, up=2, left=3
    for row in range(4):
        for col in range(4):
            ox = col * 32
            oy = row * 48

            # Walk animation: slight bob (frames 1,3 are stride frames)
            bob = -1 if col in [1, 3] else 0
            # Leg offset for walking
            leg_offset = 2 if col == 1 else (-2 if col == 3 else 0)

            # Hat (pointy, top of frame)
            hat_tip_y = oy + 2 + bob
            hat_base_y = oy + 14 + bob
            draw.polygon([
                (ox + 16, hat_tip_y),
                (ox + 22, hat_base_y),
                (ox + 10, hat_base_y)
            ], fill=hat)
            # Hat brim
            draw.rectangle([ox + 8, hat_base_y, ox + 24, hat_base_y + 3], fill=hat)
            # Hat band
            draw.rectangle([ox + 10, hat_base_y - 2, ox + 22, hat_base_y], fill=hat_band)

            # Head (face)
            head_y = oy + 15 + bob
            draw.ellipse([ox + 11, head_y, ox + 21, head_y + 10], fill=skin)

            if row == 0:  # Facing down - show face
                draw.point((ox + 14, head_y + 4), fill=rgba(40, 30, 20))
                draw.point((ox + 18, head_y + 4), fill=rgba(40, 30, 20))
                draw.point((ox + 16, head_y + 7), fill=rgba(190, 150, 120))
            elif row == 2:  # Facing up - no face
                pass
            elif row == 1:  # Facing right
                draw.point((ox + 18, head_y + 4), fill=rgba(40, 30, 20))
                draw.point((ox + 19, head_y + 7), fill=rgba(190, 150, 120))
            elif row == 3:  # Facing left
                draw.point((ox + 13, head_y + 4), fill=rgba(40, 30, 20))
                draw.point((ox + 12, head_y + 7), fill=rgba(190, 150, 120))

            # Body/robe
            body_y = oy + 25 + bob
            draw.rectangle([ox + 10, body_y, ox + 22, body_y + 14], fill=robe)
            # Robe shadow
            if row == 1:  # Facing right
                draw.rectangle([ox + 10, body_y, ox + 15, body_y + 14], fill=robe_dark)
            elif row == 3:  # Facing left
                draw.rectangle([ox + 17, body_y, ox + 22, body_y + 14], fill=robe_dark)
            else:
                draw.rectangle([ox + 10, body_y + 8, ox + 22, body_y + 14], fill=robe_dark)

            # Arms (sticks out to side slightly)
            arm_y = body_y + 3
            if row == 1:  # Right
                draw.rectangle([ox + 22, arm_y, ox + 25, arm_y + 6], fill=robe)
            elif row == 3:  # Left
                draw.rectangle([ox + 7, arm_y, ox + 10, arm_y + 6], fill=robe)
            else:
                draw.rectangle([ox + 7, arm_y, ox + 10, arm_y + 5], fill=robe)
                draw.rectangle([ox + 22, arm_y, ox + 25, arm_y + 5], fill=robe)

            # Legs/shoes
            feet_y = body_y + 14
            left_foot_x = ox + 11 + leg_offset
            right_foot_x = ox + 18 - leg_offset
            draw.rectangle([left_foot_x, feet_y, left_foot_x + 4, feet_y + 4], fill=shoe)
            draw.rectangle([right_foot_x, feet_y, right_foot_x + 4, feet_y + 4], fill=shoe)

    return img


# ── Main Generation ──────────────────────────────────────────────────────────

def main():
    # Directories
    tiles_dir = os.path.join(BASE, "tiles")
    machines_dir = os.path.join(BASE, "machines")
    items_dir = os.path.join(BASE, "items")
    player_dir = os.path.join(BASE, "player")

    for d in [tiles_dir, machines_dir, items_dir, player_dir]:
        ensure_dir(d)

    # ── Floor atlas ──
    floor = generate_floor_atlas()
    floor.save(os.path.join(tiles_dir, "floor_atlas.png"))
    print("  tiles/floor_atlas.png")

    # ── Machine sprites ──
    machines = {
        "conveyor": machine_conveyor,
        "fast_belt": machine_fast_belt,
        "dispenser": machine_dispenser,
        "cauldron": machine_cauldron,
        "storage": machine_storage_chest,
        "splitter": machine_splitter,
        "sorter": machine_sorter,
        "bottler": machine_bottler,
        "auto_seller": machine_auto_seller,
    }
    for name, fn in machines.items():
        sprite = fn()
        sprite.save(os.path.join(machines_dir, f"{name}.png"))
        print(f"  machines/{name}.png")

    # ── Item sprites ──
    # Ingredient sprites (custom per type)
    ingredient_sprites = {
        "mushroom": item_mushroom,
        "herb": item_herb,
        "crystal": item_crystal,
        "water": item_water,
        "feather": item_feather,
        "lightning": item_lightning,
        "rose": item_rose,
        "heart": item_heart,
        "shadow": item_shadow,
        "moonlight": item_moonlight,
        "ice": item_ice,
        "lava": item_lava,
        "dragon_scale": item_dragon_scale,
        "ember": item_ember,
        "glowshroom": item_glowshroom,
        "eye": item_eye,
        "seaweed": item_seaweed,
        "bubble": item_bubble,
        "clover": item_clover,
        "star": item_star,
    }
    for name, fn in ingredient_sprites.items():
        sprite = fn()
        sprite.save(os.path.join(items_dir, f"{name}.png"))
        print(f"  items/{name}.png")

    # Potion sprites (generic bottle filled with potion color)
    potion_colors = {
        "health_potion": col_to_rgba(1.0, 0.2, 0.3),
        "mana_potion": col_to_rgba(0.3, 0.2, 1.0),
        "speed_potion": col_to_rgba(1.0, 0.95, 0.1),
        "love_potion": col_to_rgba(1.0, 0.3, 0.65),
        "invisibility_potion": col_to_rgba(0.85, 0.85, 0.9),
        "fire_resistance_potion": col_to_rgba(1.0, 0.5, 0.0),
        "strength_potion": col_to_rgba(0.7, 0.1, 0.15),
        "night_vision_potion": col_to_rgba(0.6, 1.0, 0.2),
        "water_breathing_potion": col_to_rgba(0.1, 0.85, 0.85),
        "lucky_potion": col_to_rgba(1.0, 0.8, 0.0),
    }
    for name, color in potion_colors.items():
        sprite = make_potion(color)
        sprite.save(os.path.join(items_dir, f"{name}.png"))
        print(f"  items/{name}.png")

    # Bottle overlay
    overlay = item_bottle_overlay()
    overlay.save(os.path.join(items_dir, "bottle_overlay.png"))
    print("  items/bottle_overlay.png")

    # ── Player spritesheet ──
    player = generate_player_spritesheet()
    player.save(os.path.join(player_dir, "player_spritesheet.png"))
    print("  player/player_spritesheet.png")

    total = 1 + len(machines) + len(ingredient_sprites) + len(potion_colors) + 1 + 1
    print(f"\nDone! Generated {total} sprites.")


if __name__ == "__main__":
    print("Generating sprites for The Cozy Cauldron...\n")
    main()
