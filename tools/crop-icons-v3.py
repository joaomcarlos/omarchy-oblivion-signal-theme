#!/usr/bin/env python3
"""Crop the Codex v3 supplemental atlas (transparent, 6x2) into per-icon
PNGs, remapping generated colors onto the Oblivion Signal palette.
Same pipeline as crop-icons-v2.py — alpha bbox + palette remap.
"""
import os
from PIL import Image

SHEET = "oblivion-theme-docs/mockups/icon-sheet-codex-v3.png"
OUT = "icons/oblivion-signal"
COLS, ROWS = 6, 2

STEEL = (0x6F, 0xA8, 0xCC)
BRIGHT = (0xA3, 0xCF, 0xE3)
CRIMSON = (0xA6, 0x45, 0x5C)

GRID = [
    [("application-x-executable", "mimetypes"),
     ("dialog-information", "status"), ("dialog-question", "status"),
     ("starred", "status"), ("emblem-favorite", "status"),
     ("emblem-shared", "status")],
    [("emblem-important", "status"), ("folder-recent", "places"),
     ("folder-saved-search", "places"), ("user-bookmarks", "places"),
     ("steam", "apps"), ("google-chrome", "apps")],
]

ALIAS = {
    "emblem-default": ("status", "starred"),
    "emblem-symbolic-link": ("status", "emblem-shared"),
    "folder-saved-search-symbolic": ("places", "folder-saved-search"),
    "com.valvesoftware.Steam": ("apps", "steam"),
    "chromium": ("apps", "google-chrome"),
    "google-chrome-stable": ("apps", "google-chrome"),
}


ALPHA_FLOOR = 56


def remap(px):
    r, g, b, a = px
    if a <= ALPHA_FLOOR:
        return (r, g, b, 0)
    a = round((a - ALPHA_FLOOR) * 255 / (255 - ALPHA_FLOOR))
    if r > b + 25:
        return (*CRIMSON, a)
    lum = 0.3 * r + 0.5 * g + 0.2 * b
    if lum > 150:
        return (*BRIGHT, a)
    return (*STEEL, a)


img = Image.open(SHEET).convert("RGBA")
W, H = img.size
cw, ch = W / COLS, H / ROWS
tiles = {}

for row in range(ROWS):
    for col in range(COLS):
        name, cat = GRID[row][col]
        cell = img.crop((int(col * cw), int(row * ch),
                         int((col + 1) * cw), int((row + 1) * ch)))
        bbox = cell.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()
        if not bbox:
            print(f"!! empty cell {name}")
            continue
        glyph = cell.crop(bbox)
        px = glyph.load()
        for y in range(glyph.height):
            for x in range(glyph.width):
                px[x, y] = remap(px[x, y])
        tiles[name] = (glyph, cat)
        print(f"{name}: {glyph.size}")

for alias, (cat, src) in ALIAS.items():
    if src in tiles:
        tiles[alias] = (tiles[src][0], cat)

for size in (256, 48, 32):
    for name, (glyph, cat) in tiles.items():
        d = f"{OUT}/{size}x{size}/{cat}"
        os.makedirs(d, exist_ok=True)
        w, h = glyph.size
        scale = (size * 0.82) / max(w, h)
        g = glyph.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
        sq = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        sq.paste(g, ((size - g.width) // 2, (size - g.height) // 2), g)
        sq.save(f"{d}/{name}.png")
print(f"{len(tiles)} icons x 3 sizes written")
