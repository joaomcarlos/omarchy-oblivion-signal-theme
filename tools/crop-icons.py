#!/usr/bin/env python3
"""Crop the Codex icon sheet into per-icon PNGs.

Finds each swatch by row/column density of #1B2A3A-ish pixels (the swatch
is a solid rectangle; anti-aliased label text only matches sparsely).
"""
import os
from PIL import Image

SHEET = "mockups/icon-sheet-codex.png"
OUT = "icons/oblivion-signal"
COLS, ROWS = 6, 4

def is_swatch(px):
    r, g, b = px[:3]
    return abs(r - 0x1B) < 0x12 and abs(g - 0x2A) < 0x12 and abs(b - 0x3A) < 0x12

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

img = Image.open(SHEET).convert("RGBA")
W, H = img.size
cw, ch = W / COLS, H / ROWS
tiles = {}

for row in range(ROWS):
    for col in range(COLS):
        name, cat = GRID[row][col]
        x0, y0 = int(col * cw), int(row * ch)
        x1, y1 = int((col + 1) * cw), int((row + 1) * ch)
        region = img.crop((x0, y0, x1, y1))
        px = region.load()
        rw, rh = region.size

        # rows that are mostly swatch = inside the tile rectangle
        row_hits = [sum(1 for x in range(rw) if is_swatch(px[x, y]))
                    for y in range(rh)]
        good_rows = [y for y, c in enumerate(row_hits) if c > rw * 0.20]
        if not good_rows:
            print(f"!! no swatch rows for {name}")
            continue
        # longest contiguous run — neighbor swatches/labels can bleed in
        runs, run = [], [good_rows[0]]
        for y in good_rows[1:]:
            if y == run[-1] + 1:
                run.append(y)
            else:
                runs.append(run); run = [y]
        runs.append(run)
        best = max(runs, key=len)
        miny, maxy = best[0], best[-1]

        col_hits = [sum(1 for y in range(miny, maxy + 1)
                        if is_swatch(px[x, y])) for x in range(rw)]
        good_cols = [x for x, c in enumerate(col_hits) if c > (maxy - miny) * 0.20]
        cruns, crun = [], [good_cols[0]]
        for x in good_cols[1:]:
            if x == crun[-1] + 1:
                crun.append(x)
            else:
                cruns.append(crun); crun = [x]
        cruns.append(crun)
        cbest = max(cruns, key=len)
        minx, maxx = cbest[0], cbest[-1]

        # small pad so the bracket strokes sitting on the edge survive
        pad = 4
        tile = region.crop((max(0, minx - pad), max(0, miny - pad),
                            min(rw, maxx + pad + 1), min(rh, maxy + pad + 1)))
        tiles[name] = (tile, cat)
        print(f"{name}: {tile.size}")

for alias, (cat, src) in ALIAS.items():
    if src in tiles:
        tiles[alias] = (tiles[src][0], cat)

for size in (256, 48):
    for name, (tile, cat) in tiles.items():
        d = f"{OUT}/{size}x{size}/{cat}"
        os.makedirs(d, exist_ok=True)
        w, h = tile.size
        scale = size / max(w, h)
        out = tile.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
        # pad to square with transparency — the swatch tile itself is the icon
        sq = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        sq.paste(out, ((size - out.width) // 2, (size - out.height) // 2))
        sq.save(f"{d}/{name}.png")
print(f"{len(tiles)} icons x 2 sizes written")
