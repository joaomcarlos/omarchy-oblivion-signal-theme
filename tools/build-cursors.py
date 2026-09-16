#!/usr/bin/env python3
"""Recolor Bibata-Original-Ice into the Oblivion Signal palette and emit a
complete XCursor theme — pure python, no xcursorgen needed.

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

SRC = os.path.expanduser("~/.local/share/icons/Bibata-Original-Ice/cursors")
OUT = os.path.expanduser(
    "~/Projects/personal/oblivion-theme/icons/oblivion-signal-cursors/cursors")

FILL = (0xA3, 0xCF, 0xE3)   # bright readout — replaces Bibata's white fill
EDGE = (0x0D, 0x14, 0x1C)   # void-dark edge — replaces the black outline


def tint(im):
    """White->bright steel, near-black->void, keep alpha."""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = 0.3 * r + 0.55 * g + 0.15 * b
            if lum > 140:
                px[x, y] = (*FILL, a)
            else:
                px[x, y] = (*EDGE, a)
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
