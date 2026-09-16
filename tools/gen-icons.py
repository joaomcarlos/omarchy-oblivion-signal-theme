#!/usr/bin/env python3
"""Generate the Oblivion Signal icon theme — thin monoline glyphs."""
import os

ROOT = "/home/jc/Projects/personal/oblivion-theme/icons/oblivion-signal"
ACC = "#6FA8CC"   # active steel-blue strokes
MUT = "#5F7F93"   # secondary/muted strokes
HI  = "#A3CFE3"   # highlight details
COR = "#A6455C"   # exception coral

SW = 2.5  # stroke width on the 64px grid

def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" '
            f'viewBox="0 0 64 64">{body}</svg>')

def write(cat, name, body):
    path = f"{ROOT}/scalable/{cat}/{name}.svg"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(svg(body))
    print(path)

# ---------- shared motifs ----------

def ticks(x=6, y=6, w=52, h=52, l=7, color=MUT, sw=1.2):
    """L-shaped registration ticks at the four corners of a rect."""
    r = []
    for cx, cy, dx, dy in ((x, y, 1, 1), (x + w, y, -1, 1),
                           (x, y + h, 1, -1), (x + w, y + h, -1, -1)):
        r.append(f'<path d="M{cx + dx*l} {cy} h{-dx*l} v{dy*l}" fill="none" '
                 f'stroke="{color}" stroke-width="{sw}"/>')
    return "".join(r)

def folder_path(tab_h=5):
    """Folder silhouette: body rect + tab notch, top-left."""
    return ('M10 22 h14 l5 -7 h23 a4 4 0 0 1 4 4 v29 a4 4 0 0 1 -4 4 '
            'H10 a4 4 0 0 1 -4 -4 V26 a4 4 0 0 1 4 -4 z')

def folder(emblem="", color=ACC):
    """Folder outline + optional centered emblem glyph."""
    return (f'<path d="{folder_path()}" fill="none" stroke="{color}" '
            f'stroke-width="{SW}" stroke-linejoin="round"/>'
            f'<line x1="6" y1="27" x2="56" y2="27" stroke="{MUT}" '
            f'stroke-width="1.2"/>{emblem}')

def file_page(emblem="", color=ACC, fold=True):
    """Document page with folded corner."""
    body = ('<path d="M14 8 h24 l12 12 v34 a4 4 0 0 1 -4 4 H14 a4 4 0 0 1 -4 -4 '
            'V12 a4 4 0 0 1 4 -4 z" fill="none" stroke="%s" stroke-width="%s" '
            'stroke-linejoin="round"/>' % (color, SW))
    if fold:
        body += ('<path d="M38 8 v12 h12" fill="none" stroke="%s" '
                 'stroke-width="1.5"/>' % MUT)
    return body + emblem

def hairlines(y0=28, n=3, x1=18, x2=46, gap=7, color=MUT):
    return "".join(f'<line x1="{x1}" y1="{y0+i*gap}" x2="{x2}" y2="{y0+i*gap}" '
                   f'stroke="{color}" stroke-width="1.5"/>'
                   for i in range(n))

def emblem_glyph(kind):
    """Small centered glyph used inside folders/files."""
    g = {
        "download": ('<path d="M32 32 v10 M26 37 l6 6 6-6" fill="none" '
                     f'stroke="{HI}" stroke-width="2" stroke-linecap="round"/>'
                     f'<line x1="24" y1="46" x2="40" y2="46" stroke="{HI}" '
                     'stroke-width="2"/>'),
        "image": ('<circle cx="26" cy="33" r="3" fill="none" stroke="%s" '
                  'stroke-width="1.8"/>'
                  '<path d="M20 46 l8-9 6 6 4-4 6 7" fill="none" stroke="%s" '
                  'stroke-width="1.8" stroke-linejoin="round"/>') % (HI, HI),
        "audio": ('<path d="M27 46 V31 l12-3 v14" fill="none" stroke="%s" '
                  'stroke-width="2" stroke-linejoin="round"/>'
                  '<circle cx="24" cy="46" r="3" fill="none" stroke="%s" '
                  'stroke-width="2"/>'
                  '<circle cx="36" cy="42" r="3" fill="none" stroke="%s" '
                  'stroke-width="2"/>') % ((HI,) * 3),
        "video": ('<path d="M27 33 l14 7 -14 7 z" fill="none" stroke="%s" '
                  'stroke-width="2" stroke-linejoin="round"/>') % HI,
        "docs": hairlines(34, 3, 22, 44, 6, HI),
        "star": ('<path d="M32 31 l2.5 5.5 6 .5 -4.5 4 1.5 6 -5.5-3.5 -5.5 3.5 '
                 '1.5-6 -4.5-4 6-.5 z" fill="none" stroke="%s" '
                 'stroke-width="1.8" stroke-linejoin="round"/>') % HI,
        "share": ('<circle cx="25" cy="36" r="3" fill="none" stroke="%s" '
                  'stroke-width="1.8"/><circle cx="39" cy="30" r="3" '
                  'fill="none" stroke="%s" stroke-width="1.8"/>'
                  '<circle cx="39" cy="42" r="3" fill="none" stroke="%s" '
                  'stroke-width="1.8"/>'
                  '<path d="M28 35 l8-4 M28 37 l8 4" stroke="%s" '
                  'stroke-width="1.5"/>') % ((HI,) * 4),
        "template": ('<rect x="23" y="32" width="8" height="8" fill="none" '
                     'stroke="%s" stroke-width="1.5"/>'
                     '<rect x="33" y="32" width="8" height="8" fill="none" '
                     'stroke="%s" stroke-width="1.5"/>'
                     '<rect x="23" y="42" width="8" height="8" fill="none" '
                     'stroke="%s" stroke-width="1.5"/>'
                     '<rect x="33" y="42" width="8" height="8" fill="none" '
                     'stroke="%s" stroke-width="1.5"/>') % ((HI,) * 4),
        "monitor": ('<rect x="23" y="31" width="18" height="12" fill="none" '
                    'stroke="%s" stroke-width="1.8"/>'
                    '<line x1="32" y1="43" x2="32" y2="47" stroke="%s" '
                    'stroke-width="1.8"/>'
                    '<line x1="27" y1="47" x2="37" y2="47" stroke="%s" '
                    'stroke-width="1.8"/>') % ((HI,) * 3),
        "reticle": ('<circle cx="32" cy="38" r="7" fill="none" stroke="%s" '
                    'stroke-width="1.8"/>'
                    '<path d="M32 29 v4 M32 43 v4 M23 38 h4 M37 38 h4" '
                    'stroke="%s" stroke-width="1.5"/>') % (HI, HI),
    }
    return g.get(kind, "")

# ---------- places ----------
write("places", "folder", folder())
write("places", "inode-directory", folder())
write("places", "folder-documents", folder(emblem_glyph("docs")))
write("places", "folder-download", folder(emblem_glyph("download")))
write("places", "folder-pictures", folder(emblem_glyph("image")))
write("places", "folder-videos", folder(emblem_glyph("video")))
write("places", "folder-music", folder(emblem_glyph("audio")))
write("places", "folder-desktop", folder(emblem_glyph("monitor")))
write("places", "user-desktop", folder(emblem_glyph("monitor")))
write("places", "folder-publicshare", folder(emblem_glyph("share")))
write("places", "folder-templates", folder(emblem_glyph("template")))
write("places", "folder-remote", folder(emblem_glyph("reticle")))
write("places", "folder-important", folder(emblem_glyph("star")))
write("places", "folder-favorites", folder(emblem_glyph("star")))

write("places", "user-home",
      '<path d="M14 34 L32 16 L50 34" fill="none" stroke="%s" stroke-width="%s" '
      'stroke-linejoin="round"/>'
      '<path d="M18 32 v18 a3 3 0 0 0 3 3 h22 a3 3 0 0 0 3-3 V32" fill="none" '
      'stroke="%s" stroke-width="%s" stroke-linejoin="round"/>'
      '<path d="M28 53 v-11 h8 v11" fill="none" stroke="%s" stroke-width="1.8"/>'
      % (ACC, SW, ACC, SW, MUT))

write("places", "computer",
      '<rect x="8" y="14" width="48" height="30" rx="3" fill="none" '
      'stroke="%s" stroke-width="%s"/>'
      '<line x1="32" y1="44" x2="32" y2="52" stroke="%s" stroke-width="2"/>'
      '<line x1="22" y1="52" x2="42" y2="52" stroke="%s" stroke-width="2"/>'
      '<line x1="14" y1="38" x2="50" y2="38" stroke="%s" stroke-width="1.2"/>'
      % (ACC, SW, MUT, MUT, MUT))

write("places", "network-workplace",
      '<circle cx="32" cy="32" r="20" fill="none" stroke="%s" '
      'stroke-width="%s"/>'
      '<path d="M32 8 v8 M32 48 v8 M8 32 h8 M48 32 h8" stroke="%s" '
      'stroke-width="1.5"/>'
      '<circle cx="32" cy="32" r="8" fill="none" stroke="%s" stroke-width="1.5"/>'
      '<circle cx="32" cy="32" r="1.5" fill="%s"/>'
      % (ACC, SW, MUT, MUT, HI))

write("devices", "drive-harddisk",
      '<rect x="8" y="18" width="48" height="30" rx="3" fill="none" '
      'stroke="%s" stroke-width="%s"/>'
      '<circle cx="24" cy="33" r="8" fill="none" stroke="%s" stroke-width="1.5"/>'
      '<circle cx="24" cy="33" r="2" fill="%s"/>'
      '<circle cx="47" cy="42" r="1.8" fill="%s"/>'
      % (ACC, SW, MUT, MUT, HI))

write("devices", "drive-removable-media",
      '<rect x="18" y="22" width="28" height="34" rx="3" fill="none" '
      'stroke="%s" stroke-width="%s"/>'
      '<rect x="24" y="8" width="16" height="14" rx="2" fill="none" '
      'stroke="%s" stroke-width="2"/>'
      '<line x1="29" y1="12" x2="29" y2="18" stroke="%s" stroke-width="1.5"/>'
      '<line x1="35" y1="12" x2="35" y2="18" stroke="%s" stroke-width="1.5"/>'
      % (ACC, SW, MUT, MUT, MUT))

write("places", "user-trash",
      '<path d="M18 18 h28 M24 18 v-4 a2 2 0 0 1 2-2 h12 a2 2 0 0 1 2 2 v4" '
      'fill="none" stroke="%s" stroke-width="2"/>'
      '<path d="M20 18 l3 34 a3 3 0 0 0 3 3 h12 a3 3 0 0 0 3-3 l3-34" '
      'fill="none" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>'
      '<path d="M27 25 v24 M32 25 v24 M37 25 v24" stroke="%s" stroke-width="1.5"/>'
      % (MUT, ACC, SW, MUT))

write("places", "user-trash-full",
      '<path d="M18 18 h28 M24 18 v-4 a2 2 0 0 1 2-2 h12 a2 2 0 0 1 2 2 v4" '
      'fill="none" stroke="%s" stroke-width="2"/>'
      '<path d="M20 18 l3 34 a3 3 0 0 0 3 3 h12 a3 3 0 0 0 3-3 l3-34" '
      'fill="none" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>'
      '<path d="M27 25 v24 M32 25 v24 M37 25 v24" stroke="%s" stroke-width="1.5"/>'
      '<circle cx="26" cy="14" r="2" fill="%s"/><circle cx="38" cy="12" r="2" '
      'fill="%s"/>'
      % (MUT, ACC, SW, MUT, COR, COR))

# ---------- mimetypes ----------
write("mimetypes", "text-x-generic", file_page(hairlines()))
write("mimetypes", "x-office-document", file_page(hairlines(26, 4)))
write("mimetypes", "application-pdf", file_page(hairlines() +
      '<circle cx="42" cy="46" r="3" fill="none" stroke="%s" '
      'stroke-width="1.8"/>' % COR))
write("mimetypes", "image-x-generic", file_page(emblem_glyph("image")))
write("mimetypes", "audio-x-generic", file_page(emblem_glyph("audio")))
write("mimetypes", "video-x-generic", file_page(emblem_glyph("video")))
write("mimetypes", "text-html",
      file_page('<path d="M25 33 l-5 5 5 5 M39 33 l5 5 -5 5" fill="none" '
                'stroke="%s" stroke-width="2" stroke-linecap="round"/>'
                '<line x1="35" y1="31" x2="29" y2="45" stroke="%s" '
                'stroke-width="1.8"/>' % (HI, HI)))
write("mimetypes", "application-x-executable",
      '<rect x="10" y="12" width="44" height="36" rx="3" fill="none" '
      'stroke="%s" stroke-width="%s"/>'
      '<path d="M18 22 l8 6 -8 6" fill="none" stroke="%s" stroke-width="2.2" '
      'stroke-linecap="round" stroke-linejoin="round"/>'
      '<line x1="30" y1="35" x2="42" y2="35" stroke="%s" stroke-width="2.2"/>'
      % (ACC, SW, HI, HI))
write("mimetypes", "package-x-generic",
      file_page('<path d="M32 22 v26 M28 22 v8 M36 22 v4" stroke="%s" '
                'stroke-width="1.5" stroke-dasharray="2 3"/>' % MUT, fold=False))
write("mimetypes", "application-octet-stream",
      file_page('<path d="M20 32 h8 M36 32 h8 M20 40 h4 M28 40 h8 M40 40 h4" '
                'stroke="%s" stroke-width="1.8"/>' % HI))
write("mimetypes", "application-zip", file_page(
      '<path d="M32 22 v26 M28 22 v8 M36 22 v4" stroke="%s" '
      'stroke-width="1.5" stroke-dasharray="2 3"/>' % MUT, fold=False))

# ---------- apps ----------
write("apps", "utilities-terminal",
      '<rect x="8" y="12" width="48" height="38" rx="3" fill="none" '
      'stroke="%s" stroke-width="%s"/>'
      '<path d="M17 21 l9 7 -9 7" fill="none" stroke="%s" stroke-width="2.4" '
      'stroke-linecap="round" stroke-linejoin="round"/>'
      '<line x1="30" y1="36" x2="44" y2="36" stroke="%s" stroke-width="2.4"/>'
      % (ACC, SW, HI, HI))
write("apps", "system-file-manager", folder())
write("apps", "org.gnome.Nautilus", folder())

# ---------- status ----------
write("status", "dialog-warning",
      '<path d="M32 12 L56 50 H8 z" fill="none" stroke="%s" stroke-width="%s" '
      'stroke-linejoin="round"/>'
      '<line x1="32" y1="26" x2="32" y2="38" stroke="%s" stroke-width="2.4"/>'
      '<circle cx="32" cy="44" r="1.8" fill="%s"/>' % (COR, SW, COR, COR))
write("status", "dialog-error",
      '<circle cx="32" cy="32" r="20" fill="none" stroke="%s" '
      'stroke-width="%s"/>'
      '<path d="M23 23 l18 18 M41 23 l-18 18" stroke="%s" stroke-width="2.2"/>'
      % (COR, SW, COR))
write("status", "dialog-information",
      '<circle cx="32" cy="32" r="20" fill="none" stroke="%s" '
      'stroke-width="%s"/>'
      '<line x1="32" y1="28" x2="32" y2="42" stroke="%s" stroke-width="2.4"/>'
      '<circle cx="32" cy="21" r="1.8" fill="%s"/>' % (ACC, SW, HI, HI))
write("status", "dialog-question",
      '<circle cx="32" cy="32" r="20" fill="none" stroke="%s" '
      'stroke-width="%s"/>'
      '<path d="M26 24 a6 6 0 1 1 6 9 v5" fill="none" stroke="%s" '
      'stroke-width="2.2"/>'
      '<circle cx="32" cy="44" r="1.8" fill="%s"/>' % (ACC, SW, HI, HI))
write("status", "emblem-important",
      '<path d="M32 14 L54 50 H10 z" fill="none" stroke="%s" stroke-width="2" '
      'stroke-linejoin="round"/>'
      '<line x1="32" y1="28" x2="32" y2="38" stroke="%s" stroke-width="2.2"/>'
      '<circle cx="32" cy="44" r="1.8" fill="%s"/>' % (COR, COR, COR))
write("status", "starred", emblem_glyph("star").replace('cy="3', 'cy="3'))
write("status", "emblem-favorite", emblem_glyph("star"))
write("status", "emblem-shared", emblem_glyph("share"))

print("done")
