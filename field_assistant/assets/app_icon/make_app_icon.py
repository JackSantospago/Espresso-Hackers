"""Generate the app icon (Android, iOS, web) from the potato mascot.

The mascot is the same drawing as lib/frontend/chatbot/widgets/potato_mascot.dart
(_PotatoPainter, 200 x 200 grid), written out as SVG so it can be rendered to PNGs.
If the mascot changes there, mirror the change here and re-run:

    pip install cairosvg pillow
    python3 assets/app_icon/make_app_icon.py      # from field_assistant/
"""

import io
import math
import os
import sys

import cairosvg
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = sys.argv[1] if len(sys.argv) > 1 else ROOT

BG = "#E2EEE8"  # colorScheme.primaryContainer
BG_EDGE = "#CFE2D8"

SKIN, SKIN_DARK, OUTLINE = "#D4A06A", "#A8733F", "#6B4423"
STRAW, STRAW_DARK, BAND = "#EBC56B", "#B98B35", "#1E5A46"
WOOD, METAL = "#8B5E34", "#9AA5AE"


def mascot() -> str:
    """The mascot on its 200 x 200 grid, as SVG elements."""
    s = []
    stroke = f'stroke="{OUTLINE}" stroke-linecap="round" stroke-linejoin="round" fill="none"'
    # Hoe handle and blade.
    s.append(f'<line x1="158" y1="186" x2="178" y2="36" stroke="{WOOD}" stroke-width="6" stroke-linecap="round"/>')
    blade = "M174 34 L198 40 L195 56 L177 47 Z"
    s.append(f'<path d="{blade}" fill="{METAL}"/><path d="{blade}" {stroke} stroke-width="2.5"/>')
    # Feet.
    for x in (82, 118):
        s.append(f'<ellipse cx="{x}" cy="186" rx="12" ry="5.5" fill="{SKIN_DARK}"/>')
        s.append(f'<ellipse cx="{x}" cy="186" rx="12" ry="5.5" {stroke} stroke-width="3"/>')
    # Left arm.
    s.append(f'<line x1="52" y1="128" x2="34" y2="140" {stroke} stroke-width="6"/>')
    # Body.
    body = "M100 64 C146 60 160 104 154 138 C148 172 120 184 96 182 C62 180 44 154 47 120 C50 84 70 65 100 64 Z"
    # Flutter RadialGradient(center: (-0.3,-0.4), radius: 0.9) over Rect(46,62,110,122).
    s.append(
        '<defs><radialGradient id="skin" gradientUnits="userSpaceOnUse" cx="84.5" cy="98.6" r="99">'
        f'<stop offset="0" stop-color="#E6BC88"/><stop offset="0.6" stop-color="{SKIN}"/>'
        f'<stop offset="1" stop-color="{SKIN_DARK}"/></radialGradient>'
        '<clipPath id="crown"><path d="M70 72 C68 44 82 32 100 32 C118 32 132 44 130 72 Z"/></clipPath></defs>'
    )
    s.append(f'<path d="{body}" fill="url(#skin)"/><path d="{body}" {stroke} stroke-width="3"/>')
    # Potato spots.
    for x, y, r in ((70, 150, 3.5), (136, 152, 3.0), (128, 98, 2.5), (62, 104, 2.5)):
        s.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{SKIN_DARK}"/>')
    # Right arm, hands.
    s.append(f'<line x1="150" y1="128" x2="166" y2="118" {stroke} stroke-width="6"/>')
    for cx, cy in ((32, 142), (168, 116)):
        s.append(f'<circle cx="{cx}" cy="{cy}" r="7.5" fill="{SKIN}"/>')
        s.append(f'<circle cx="{cx}" cy="{cy}" r="7.5" {stroke} stroke-width="3"/>')
    # Face.
    for x in (86, 116):
        s.append(f'<ellipse cx="{x}" cy="114" rx="5" ry="6.5" fill="#2B1B10"/>')
        s.append(f'<circle cx="{x + 2}" cy="110" r="2.2" fill="#FFFFFF"/>')
    for x in (73, 129):
        s.append(f'<ellipse cx="{x}" cy="130" rx="7" ry="4" fill="#E5736B" fill-opacity="0.333"/>')
    s.append(f'<path d="M89 130 Q101 143 113 130" {stroke} stroke-width="3"/>')
    # Straw hat (outline colour switches to straw-dark, as in the painter).
    hat = stroke.replace(OUTLINE, STRAW_DARK)
    s.append(f'<ellipse cx="100" cy="72" rx="64" ry="13" fill="{STRAW}"/>')
    s.append(f'<ellipse cx="100" cy="72" rx="64" ry="13" {hat} stroke-width="3"/>')
    crown = "M70 72 C68 44 82 32 100 32 C118 32 132 44 130 72 Z"
    s.append(f'<path d="{crown}" fill="{STRAW}"/>')
    s.append(f'<rect x="60" y="58" width="80" height="9" fill="{BAND}" clip-path="url(#crown)"/>')
    s.append(f'<path d="{crown}" {hat} stroke-width="3"/>')
    for i in range(7):
        a = math.pi * (0.15 + i * 0.12)
        x1, y1 = 100 + 52 * math.cos(a + math.pi), 72 + 9 * math.sin(a)
        x2, y2 = 100 + 60 * math.cos(a + math.pi), 72 + 11 * math.sin(a)
        s.append(
            f'<line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" stroke="{STRAW_DARK}" '
            'stroke-opacity="0.6" stroke-width="1.4" stroke-linecap="round"/>'
        )
    return "".join(s)


# The figure spans roughly x 26..199, y 30..193 on its grid; centre it on that box.
FIG_CX, FIG_CY, FIG_H = 112.5, 111.5, 163


def icon_svg(fig_height: float, background: bool) -> str:
    """A 1000 x 1000 icon with the figure [fig_height] tall (in 0..1000 units), centred."""
    k = fig_height / FIG_H
    tx, ty = 500 - FIG_CX * k, 500 - FIG_CY * k + 8  # a touch low reads as centred (hat is wide)
    bg = ""
    if background:
        bg = (
            '<defs><radialGradient id="bg" cx="0.5" cy="0.42" r="0.75">'
            f'<stop offset="0" stop-color="#EEF5F1"/><stop offset="0.7" stop-color="{BG}"/>'
            f'<stop offset="1" stop-color="{BG_EDGE}"/></radialGradient></defs>'
            '<rect width="1000" height="1000" fill="url(#bg)"/>'
        )
    shadow = f'<ellipse cx="{500 + (100 - FIG_CX) * k:.1f}" cy="{ty + 190 * k:.1f}" rx="{62 * k:.1f}" ry="{9 * k:.1f}" fill="#1E5A46" fill-opacity="0.12"/>'
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">'
        f'{bg}{shadow}<g transform="translate({tx:.2f} {ty:.2f}) scale({k:.4f})">{mascot()}</g></svg>'
    )


def render(svg: str, px: int, rgb: bool = False) -> Image.Image:
    # Render big, then downsample: crisper small sizes than rendering small directly.
    big = max(px * 4, 1024)
    img = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode(), output_width=big, output_height=big)))
    img = img.convert("RGBA").resize((px, px), Image.LANCZOS)
    if rgb:  # iOS app icons must not have an alpha channel.
        flat = Image.new("RGB", img.size, BG)
        flat.paste(img, mask=img.split()[3])
        img = flat
    return img


def save(img: Image.Image, rel: str) -> None:
    path = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    print(rel, img.size)


full = icon_svg(780, background=True)  # legacy Android, iOS, web
mask = icon_svg(570, background=True)  # web maskable: keep inside the 80 % safe circle
fore = icon_svg(470, background=False)  # Android adaptive foreground: 66/108 dp safe zone

with open(os.path.join(OUT, "assets/app_icon/app_icon.svg"), "w") as f:
    f.write(full)

res = "android/app/src/main/res"
for d, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    save(render(full, px), f"{res}/mipmap-{d}/ic_launcher.png")
    save(render(fore, px * 108 // 48), f"{res}/mipmap-{d}/ic_launcher_foreground.png")

ios = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
for pt, scales in {20: (1, 2, 3), 29: (1, 2, 3), 40: (1, 2, 3), 60: (2, 3), 76: (1, 2), 83.5: (2,), 1024: (1,)}.items():
    for sc in scales:
        name = f"{pt:g}x{pt:g}@{sc}x"
        save(render(full, round(pt * sc), rgb=True), f"{ios}/Icon-App-{name}.png")

save(render(full, 192, rgb=True), "web/icons/Icon-192.png")
save(render(full, 512, rgb=True), "web/icons/Icon-512.png")
save(render(mask, 192), "web/icons/Icon-maskable-192.png")
save(render(mask, 512), "web/icons/Icon-maskable-512.png")
save(render(full, 32), "web/favicon.png")
