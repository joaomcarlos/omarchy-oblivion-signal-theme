#!/usr/bin/env python3
"""Crop the Codex v2 icon sheet (transparent glyph atlas) into per-icon
PNGs, remapping the saturated generated colors onto the Oblivion Signal
palette. Glyph detection is by alpha channel; no labels/tiles in v2.
"""
import os
from PIL import Image

SHEET = "oblivion-theme-docs/mockups/icon-sheet-codex-v2.png"
OUT = "icons/oblivion-signal"
COLS, ROWS = 6, 4

# palette targets
STEEL = (0x6F, 0xA8, 0xCC)   # primary stroke
BRIGHT = (0xA3, 0xCF, 0xE3)  # bright detail
CRIMSON = (0xA6, 0x45, 0x5C) # exception

GRID = [
    [("folder", "places"), ("folder-documents", "places"),
     ("folder-download", "places"), ("folder-pictures", "places"),
     ("folder-music", "places"), ("folder-videos", "places")],
    [("folder-desktop", "places"), ("folder-remote", "places"),
     ("user-home", "places"), ("user-trash", "places"),
     ("computer", "places"), ("drive-harddisk", "devices")],
    [("drive-removable-media", "devices"), ("network-workplace", "places"),
     ("text-x-generic", "mimetypes"), ("x-office-document", "mimetypes"),
     ("application-pdf", "mimetypes"), ("image-x-generic", "mimetypes")],
    [("audio-x-generic", "mimetypes"), ("video-x-generic", "mimetypes"),
     ("text-html", "mimetypes"), ("utilities-terminal", "apps"),
     ("dialog-warning", "status"), ("dialog-error", "status")],
]

ALIAS = {
    "inode-directory": ("places", "folder"),
    "system-file-manager": ("apps", "folder"),
    "org.gnome.Nautilus": ("apps", "folder"),
    "folder-publicshare": ("places", "folder-remote"),
    "folder-templates": ("places", "folder-documents"),
    "user-trash-full": ("places", "user-trash"),
    "user-desktop": ("places", "folder-desktop"),
    "folder-open": ("places", "folder"),
    "application-zip": ("mimetypes", "x-office-document"),
    "package-x-generic": ("mimetypes", "x-office-document"),
    "application-x-generic": ("mimetypes", "text-x-generic"),
    "unknown": ("mimetypes", "text-x-generic"),
    "application-octet-stream": ("mimetypes", "x-office-document"),
    "text-x-preview": ("mimetypes", "text-x-generic"),
}


# image-gen bakes a soft glow skirt around strokes (~130k px at alpha<16
# on the v2 sheet); crush it and stretch the rest so edges stay smooth
ALPHA_FLOOR = 56


def remap(px):
    """Map a generated pixel to the palette, tightening the alpha skirt."""
    r, g, b, a = px
    if a <= ALPHA_FLOOR:
        return (r, g, b, 0)
    a = round((a - ALPHA_FLOOR) * 255 / (255 - ALPHA_FLOOR))
    if r > b + 25:                      # reddish -> dusty crimson
        return (*CRIMSON, a)
    lum = 0.3 * r + 0.5 * g + 0.2 * b
    if lum > 150:                       # light cyan accents -> bright
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
        # alpha bounding box of the glyph
        bbox = cell.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()
        if not bbox:
            print(f"!! empty cell {name}")
            continue
        glyph = cell.crop(bbox)
        # remap colors
        px = glyph.load()
        for y in range(glyph.height):
            for x in range(glyph.width):
                px[x, y] = remap(px[x, y])
        tiles[name] = (glyph, cat)
        print(f"{name}: {glyph.size}")

for alias, (cat, src) in ALIAS.items():
    if src in tiles:
        tiles[alias] = (tiles[src][0], cat)

for size in (256, 48):
    for name, (glyph, cat) in tiles.items():
        d = f"{OUT}/{size}x{size}/{cat}"
        os.makedirs(d, exist_ok=True)
        w, h = glyph.size
        scale = (size * 0.82) / max(w, h)   # breathing room inside the square
        g = glyph.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
        sq = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        sq.paste(g, ((size - g.width) // 2, (size - g.height) // 2), g)
        sq.save(f"{d}/{name}.png")
print(f"{len(tiles)} icons x 2 sizes written")
