#!/usr/bin/env python3
"""Recolor an XCursor theme into the Oblivion Signal palette — pure python,
no xcursorgen needed. Default source: Future cursors (white geometry with
amber accents -> bright readout bodies with steel-ice accents). Pass a
source cursors/ dir and profile to use another base:

  build-cursors.py [src-cursors-dir] [future|bibata]

XCursor format (little-endian):
  header:  magic 'Xcur', header_size=16, version=0x10000, ntoc
  toc:     ntoc * (type=0xfffd0002, subtype=nominal_size, position)
  image:   chunk_header(9 ints: header=36, type, subtype=size, version=1,
           width, height, xhot, yhot, delay) + w*h BGRA pixels
"""
import os
import struct
import sys
from PIL import Image

SRC = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else
                         "~/.local/share/icons/Future-cursors/cursors")
PROFILE = sys.argv[2] if len(sys.argv) > 2 else "future"
OUT = os.path.expanduser(
    "~/Projects/personal/oblivion-theme/icons/oblivion-signal-cursors/cursors")

FILL = (0xE2, 0xEF, 0xF8)   # brightest readout — replaces white fills
STEEL = (0x6F, 0xA8, 0xCC)  # steel-ice accent — replaces Future's amber
EDGE = (0x0D, 0x14, 0x1C)   # void-dark edge — replaces the black outline


def tint_future(px):
    """Future cursors: white->bright readout, amber->steel, dark->void."""
    r, g, b, a = px
    if a == 0:
        return px
    if r > b + 60 and r > 120:              # amber accent
        return (*STEEL, a)
    lum = 0.3 * r + 0.55 * g + 0.15 * b
    if lum > 140:                            # white body
        return (*FILL, a)
    return (*EDGE, a)


def tint_bibata(px):
    """Bibata: white->bright steel, near-black->void."""
    r, g, b, a = px
    if a == 0:
        return px
    lum = 0.3 * r + 0.55 * g + 0.15 * b
    if lum > 140:
        return (*(0xA3, 0xCF, 0xE3), a)
    return (*EDGE, a)


TINT = tint_bibata if PROFILE == "bibata" else tint_future


def tint(im):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            px[x, y] = TINT(px[x, y])
    return im


def extract(path):
    """Yield (width, height, xhot, yhot, delay, PIL image) per frame."""
    data = open(path, "rb").read()
    magic, hsize, ver, ntoc = struct.unpack("<4sIII", data[:16])
    assert magic == b"Xcur", path
    pos = 16
    frames = []
    for _ in range(ntoc):
        ctype, csubtype, cpos = struct.unpack("<III", data[pos:pos + 12])
        pos += 12
        if ctype != 0xFFFD0002:
            continue
        (_h, _t, size, _v, w, h, x, y, delay) = struct.unpack(
            "<IIIIIIIII", data[cpos:cpos + 36])
        im = Image.frombytes("RGBA", (w, h),
                             data[cpos + 36:cpos + 36 + w * h * 4],
                             "raw", "BGRA")
        frames.append((size, w, h, x, y, delay, im))
    return frames


def build(name, frames, out_dir):
    """Write a valid Xcursor file. Group by nominal size."""
    chunks, toc = [], []
    off = 16 + 12 * len(frames)
    for size, w, h, x, y, delay, im in frames:
        header = struct.pack("<IIIIIIIII", 36, 0xFFFD0002, size, 1,
                             w, h, x, y, delay)
        body = im.tobytes("raw", "BGRA")
        chunks.append(header + body)
        toc.append(struct.pack("<III", 0xFFFD0002, size, off))
        off += len(chunks[-1])
    out = struct.pack("<4sIII", b"Xcur", 16, 0x10000, len(toc))
    out += b"".join(toc) + b"".join(chunks)
    with open(f"{out_dir}/{name}", "wb") as f:
        f.write(out)


os.makedirs(OUT, exist_ok=True)
count = 0
for fn in sorted(os.listdir(SRC)):
    src = f"{SRC}/{fn}"
    if not os.path.isfile(src):
        continue
    try:
        frames = extract(src)
    except Exception as e:
        print(f"skip {fn}: {e}")
        continue
    frames = [(s, w, h, x, y, d, tint(im)) for s, w, h, x, y, d, im in frames]
    build(fn, frames, OUT)
    count += 1
print(f"{count} cursors written to {OUT}")
