#!/usr/bin/env python3
"""Convert a floor texture image into a 128x64 floor atlas (two 64x64 tiles).

Usage:
    python3 tools/convert_floor.py /path/to/floor.png

Crops two non-overlapping square regions from the source image,
resizes each to 64x64 using nearest-neighbor, and saves them
side by side as assets/sprites/tiles/floor_atlas.png.
"""

import os
import sys
from PIL import Image

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tools/convert_floor.py <input_image>")
        sys.exit(1)

    src_path = sys.argv[1]
    img = Image.open(src_path)
    w, h = img.size
    print(f"Source image: {w}x{h}")

    # Crop two square regions from the image
    # Use the shorter dimension as the square size
    square = min(w // 2, h)

    # Left tile: top-left square
    tile1 = img.crop((0, 0, square, square))
    # Right tile: offset to the right for variety
    tile2 = img.crop((square, 0, square * 2, square))

    # Resize to 64x64 with nearest-neighbor for pixel art look
    tile1 = tile1.resize((64, 64), Image.NEAREST)
    tile2 = tile2.resize((64, 64), Image.NEAREST)

    # Combine into 128x64 atlas
    atlas = Image.new("RGBA", (128, 64))
    atlas.paste(tile1, (0, 0))
    atlas.paste(tile2, (64, 0))

    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "tiles")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "floor_atlas.png")
    atlas.save(out_path)
    print(f"Saved: {out_path}")

if __name__ == "__main__":
    main()
