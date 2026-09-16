#!/usr/bin/env python3
"""Generate -symbolic icons: 16px monochrome versions of the glyph set."""
import os

ROOT = "/home/jc/Projects/personal/oblivion-theme/icons/oblivion-signal"
FG = "#B5D2E3"   # single color; GTK tints -symbolic icons anyway
SW = 1.3

def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" '
            f'viewBox="0 0 16 16">{body}</svg>')

def write(cat, name, body):
    path = f"{ROOT}/scalable/{cat}/{name}.svg"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(svg(body))

def folder_sym(emblem=""):
    return ('<path d="M2.5 5.5 h3.5 l1.2 -1.8 h5.3 a1.2 1.2 0 0 1 1.2 1.2 '
            'v7.1 a1.2 1.2 0 0 1 -1.2 1.2 H2.5 a1.2 1.2 0 0 1 -1.2 -1.2 '
            'V6.7 a1.2 1.2 0 0 1 1.2 -1.2 z" fill="none" stroke="%s" '
            'stroke-width="%s" stroke-linejoin="round"/>'
            '<line x1="1.3" y1="6.8" x2="14.7" y2="6.8" stroke="%s" '
            'stroke-width="0.7"/>' % (FG, SW, FG)) + emblem

def file_sym(emblem=""):
    return ('<path d="M3.5 1.5 h6 l3 3 v8.5 a1.2 1.2 0 0 1 -1.2 1.2 H3.5 '
            'a1.2 1.2 0 0 1 -1.2 -1.2 V2.7 a1.2 1.2 0 0 1 1.2 -1.2 z" '
            'fill="none" stroke="%s" stroke-width="%s" '
            'stroke-linejoin="round"/>'
            '<path d="M9.5 1.5 v3 h3" fill="none" stroke="%s" '
            'stroke-width="0.8"/>' % (FG, SW, FG)) + emblem

def lines(y0=7.5, n=3):
    return "".join('<line x1="4.5" y1="%.1f" x2="11.5" y2="%.1f" stroke="%s" '
                   'stroke-width="0.8"/>' % (y0+i*2, y0+i*2, FG)
                   for i in range(n))

# places
for name in ["folder", "inode-directory", "folder-documents"]:
    write("places", name + "-symbolic", folder_sym(lines(8.5, 2)))
write("places", "folder-download-symbolic", folder_sym(
    '<path d="M8 7.5 v3.5 M6.2 9.6 L8 11.4 L9.8 9.6" fill="none" '
    'stroke="%s" stroke-width="0.9" stroke-linecap="round"/>' % FG))
write("places", "folder-pictures-symbolic", folder_sym(
    '<circle cx="6" cy="8.6" r="0.9" fill="none" stroke="%s" stroke-width="0.8"/>'
    '<path d="M4.5 12 l3-3 2 2 1.5-1.5 2 2.5" fill="none" stroke="%s" '
    'stroke-width="0.8"/>' % (FG, FG)))
write("places", "folder-videos-symbolic", folder_sym(
    '<path d="M6.5 8.5 l4 2 -4 2 z" fill="none" stroke="%s" '
    'stroke-width="0.9" stroke-linejoin="round"/>' % FG))
write("places", "folder-music-symbolic", folder_sym(
    '<path d="M6.8 12 V7.8 l3.5-0.9 V10" fill="none" stroke="%s" '
    'stroke-width="0.9"/><circle cx="6" cy="12" r="0.9" fill="%s"/>' % (FG, FG)))
for name in ["folder-desktop", "user-desktop"]:
    write("places", name + "-symbolic", folder_sym(
        '<rect x="5.5" y="8" width="5" height="3.5" fill="none" stroke="%s" '
        'stroke-width="0.8"/>' % FG))
write("places", "folder-publicshare-symbolic", folder_sym(
    '<circle cx="6" cy="9" r="1" fill="none" stroke="%s" stroke-width="0.8"/>'
    '<circle cx="10" cy="7.8" r="1" fill="none" stroke="%s" stroke-width="0.8"/>'
    '<circle cx="10" cy="10.6" r="1" fill="none" stroke="%s" '
    'stroke-width="0.8"/><path d="M7 8.6 l2 -0.6 M7 9.4 l2 0.9" stroke="%s" '
    'stroke-width="0.7"/>' % ((FG,) * 4)))
write("places", "folder-templates-symbolic", folder_sym(
    '<rect x="5.5" y="8" width="2.4" height="2.4" fill="none" stroke="%s" '
    'stroke-width="0.7"/><rect x="8.5" y="8" width="2.4" height="2.4" '
    'fill="none" stroke="%s" stroke-width="0.7"/>'
    '<rect x="5.5" y="10.6" width="2.4" height="2.4" fill="none" stroke="%s" '
    'stroke-width="0.7"/><rect x="8.5" y="10.6" width="2.4" height="2.4" '
    'fill="none" stroke="%s" stroke-width="0.7"/>' % ((FG,) * 4)))
write("places", "folder-remote-symbolic", folder_sym(
    '<circle cx="8" cy="9.7" r="2.2" fill="none" stroke="%s" '
    'stroke-width="0.8"/><path d="M8 7.1 v1 M8 11.3 v1 M5.4 9.7 h1 M9.6 9.7 h1" '
    'stroke="%s" stroke-width="0.7"/>' % (FG, FG)))

write("places", "user-home-symbolic",
      '<path d="M3.5 8.5 L8 4 L12.5 8.5" fill="none" stroke="%s" '
      'stroke-width="%s" stroke-linejoin="round"/>'
      '<path d="M4.5 8 v4.5 a0.8 0.8 0 0 0 0.8 0.8 h5.4 a0.8 0.8 0 0 0 '
      '0.8-0.8 V8" fill="none" stroke="%s" stroke-width="%s" '
      'stroke-linejoin="round"/>' % (FG, SW, FG, SW))

write("places", "computer-symbolic",
      '<rect x="2" y="3" width="12" height="8" rx="1" fill="none" '
      'stroke="%s" stroke-width="%s"/>'
      '<line x1="8" y1="11" x2="8" y2="13.5" stroke="%s" stroke-width="0.9"/>'
      '<line x1="5" y1="13.5" x2="11" y2="13.5" stroke="%s" stroke-width="0.9"/>'
      % (FG, SW, FG, FG))

write("places", "network-workplace-symbolic",
      '<circle cx="8" cy="8" r="5.5" fill="none" stroke="%s" '
      'stroke-width="%s"/>'
      '<path d="M8 1.5 v2 M8 12.5 v2 M1.5 8 h2 M12.5 8 h2" stroke="%s" '
      'stroke-width="0.8"/><circle cx="8" cy="8" r="1.5" fill="none" '
      'stroke="%s" stroke-width="0.8"/>' % (FG, SW, FG, FG))

write("devices", "drive-harddisk-symbolic",
      '<rect x="1.8" y="4.5" width="12.4" height="7.5" rx="1" fill="none" '
      'stroke="%s" stroke-width="%s"/>'
      '<circle cx="5.8" cy="8.2" r="2" fill="none" stroke="%s" '
      'stroke-width="0.8"/><circle cx="11.8" cy="10.8" r="0.7" fill="%s"/>'
      % (FG, SW, FG, FG))

write("devices", "drive-removable-media-symbolic",
      '<rect x="4.5" y="5.5" width="7" height="9" rx="1" fill="none" '
      'stroke="%s" stroke-width="%s"/>'
      '<rect x="6" y="1.8" width="4" height="3.7" rx="0.7" fill="none" '
      'stroke="%s" stroke-width="0.8"/>' % (FG, SW, FG))

for name, emblem in [
    ("user-trash", '<path d="M6.5 6.5 v6 M8 6.5 v6 M9.5 6.5 v6" stroke="%s" '
                   'stroke-width="0.7"/>' % FG),
    ("user-trash-full", '<path d="M6.5 6.5 v6 M8 6.5 v6 M9.5 6.5 v6" '
                        'stroke="%s" stroke-width="0.7"/>'
                        '<circle cx="6.5" cy="3.2" r="0.8" fill="%s"/>'
                        '<circle cx="9.5" cy="2.8" r="0.8" fill="%s"/>'
                        % (FG, FG, FG))]:
    write("places", name + "-symbolic",
          '<path d="M4.5 4 h7 M6 4 V3 a0.8 0.8 0 0 1 0.8-0.8 h2.4 a0.8 0.8 0 '
          '0 1 0.8 0.8 v1" fill="none" stroke="%s" stroke-width="0.9"/>'
          '<path d="M5 4 l0.9 9.2 a1 1 0 0 0 1 0.9 h2.2 a1 1 0 0 0 1-0.9 '
          'L11 4" fill="none" stroke="%s" stroke-width="%s" '
          'stroke-linejoin="round"/>%s' % (FG, FG, SW, emblem))

# mimetypes
write("mimetypes", "text-x-generic-symbolic", file_sym(lines()))
write("mimetypes", "x-office-document-symbolic", file_sym(lines(7, 4)))
write("mimetypes", "application-pdf-symbolic", file_sym(lines()))
write("mimetypes", "image-x-generic-symbolic", file_sym(
    '<circle cx="5.8" cy="7.6" r="0.9" fill="none" stroke="%s" '
    'stroke-width="0.8"/><path d="M4.3 12.5 l2.8-2.8 2 2 1.4-1.4 1.8 2.2" '
    'fill="none" stroke="%s" stroke-width="0.8"/>' % (FG, FG)))
write("mimetypes", "audio-x-generic-symbolic", file_sym(
    '<path d="M7 12.4 V8 l3.4-0.9 v4" fill="none" stroke="%s" '
    'stroke-width="0.9"/><circle cx="6.2" cy="12.4" r="0.9" fill="%s"/>'
    % (FG, FG)))
write("mimetypes", "video-x-generic-symbolic", file_sym(
    '<path d="M6.5 8.5 l3.5 1.9 -3.5 1.9 z" fill="none" stroke="%s" '
    'stroke-width="0.9" stroke-linejoin="round"/>' % FG))
write("mimetypes", "text-html-symbolic", file_sym(
    '<path d="M6 8.5 L4.5 9.8 6 11.1 M10 8.5 l1.5 1.3 -1.5 1.3" fill="none" '
    'stroke="%s" stroke-width="0.8" stroke-linecap="round"/>' % FG))
write("mimetypes", "application-x-executable-symbolic",
      '<rect x="2.5" y="3" width="11" height="9" rx="1" fill="none" '
      'stroke="%s" stroke-width="%s"/>'
      '<path d="M4.5 5.5 l2.5 1.8 -2.5 1.8" fill="none" stroke="%s" '
      'stroke-width="0.9" stroke-linecap="round"/>' % (FG, SW, FG))
for name in ["package-x-generic", "application-zip"]:
    write("mimetypes", name + "-symbolic", file_sym(
        '<path d="M8 5 v8 M6.8 5 v2.5 M9.2 5 v1.2" stroke="%s" '
        'stroke-width="0.7" stroke-dasharray="0.8 0.9"/>' % FG))
write("mimetypes", "application-octet-stream-symbolic", file_sym(
    '<path d="M4.5 8 h2 M8 8 h2 M11.5 8 h0.5 M4.5 10 h1 M7 10 h2 M10.5 10 h1" '
    'stroke="%s" stroke-width="0.8"/>' % FG))
write("mimetypes", "unknown-symbolic", file_sym())
write("mimetypes", "application-x-generic-symbolic", file_sym())
write("mimetypes", "text-x-preview-symbolic", file_sym())

# apps
for name in ["utilities-terminal", "system-file-manager",
             "org.gnome.Nautilus"]:
    write("apps", name + "-symbolic",
          '<rect x="2" y="3" width="12" height="9" rx="1" fill="none" '
          'stroke="%s" stroke-width="%s"/>'
          '<path d="M4 5.3 l2.4 1.7 -2.4 1.7" fill="none" stroke="%s" '
          'stroke-width="0.9" stroke-linecap="round"/>' % (FG, SW, FG)
          if name == "utilities-terminal" else folder_sym())

# status
write("status", "dialog-warning-symbolic",
      '<path d="M8 3 L14 13 H2 z" fill="none" stroke="%s" stroke-width="%s" '
      'stroke-linejoin="round"/><line x1="8" y1="6.5" x2="8" y2="9.5" '
      'stroke="%s" stroke-width="1"/><circle cx="8" cy="11.3" r="0.7" '
      'fill="%s"/>' % (FG, SW, FG, FG))
write("status", "dialog-error-symbolic",
      '<circle cx="8" cy="8" r="5.5" fill="none" stroke="%s" '
      'stroke-width="%s"/><path d="M5.5 5.5 l5 5 M10.5 5.5 l-5 5" stroke="%s" '
      'stroke-width="1"/>' % (FG, SW, FG))
write("status", "dialog-information-symbolic",
      '<circle cx="8" cy="8" r="5.5" fill="none" stroke="%s" '
      'stroke-width="%s"/><line x1="8" y1="7" x2="8" y2="11" stroke="%s" '
      'stroke-width="1"/><circle cx="8" cy="5" r="0.7" fill="%s"/>'
      % (FG, SW, FG, FG))
write("status", "dialog-question-symbolic",
      '<circle cx="8" cy="8" r="5.5" fill="none" stroke="%s" '
      'stroke-width="%s"/><path d="M6.4 6 a1.7 1.7 0 1 1 1.6 2.4 v1.4" '
      'fill="none" stroke="%s" stroke-width="0.9"/>'
      '<circle cx="8" cy="11.8" r="0.7" fill="%s"/>' % (FG, SW, FG, FG))

print("symbolic done")
