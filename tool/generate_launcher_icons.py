#!/usr/bin/env python3
"""Draw the application icon and export every size the platforms need.

The icon is generated from code instead of being stored as a single opaque
binary, so the geometry stays reviewable and reproducible. Run it after
changing the design; the resulting PNG files under `assets/launcher/` are
versioned and `tool/bootstrap.py` copies them into the generated native
projects.

Requires Pillow. It is not needed to build the application, only to redraw the
icon:

    python3 -m pip install pillow
    python3 tool/generate_launcher_icons.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "launcher"

CANVAS = 1024
BACKGROUND = (0, 88, 84)
BACKGROUND_LIGHT = (0, 122, 116)
GLYPH = (255, 255, 255)
ACCENT = (122, 222, 210)

# Legacy launcher icons are masked by the launcher itself; adaptive icons split
# the drawing into a full-bleed background and a foreground that must stay
# inside the central safe zone.
ANDROID_LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ANDROID_ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
WEB_SIZES = {"Icon-192.png": 192, "Icon-512.png": 512, "Icon-maskable-192.png": 192, "Icon-maskable-512.png": 512}


def rounded_background(size: int) -> Image.Image:
    """Vertical two-tone teal panel with rounded corners."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gradient = Image.new("RGBA", (1, size))
    for y in range(size):
        ratio = y / max(size - 1, 1)
        gradient.putpixel(
            (0, y),
            tuple(
                int(BACKGROUND_LIGHT[channel] + (BACKGROUND[channel] - BACKGROUND_LIGHT[channel]) * ratio)
                for channel in range(3)
            )
            + (255,),
        )
    gradient = gradient.resize((size, size))

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
    image.paste(gradient, (0, 0), mask)
    return image


def draw_glyph(draw: ImageDraw.ImageDraw, size: int, scale: float) -> None:
    """Scanner frame with a QR finder pattern at its centre.

    `scale` is the fraction of the canvas the drawing may occupy. Adaptive
    foregrounds need a smaller value so nothing is clipped by the launcher mask.
    """
    side = size * scale
    left = (size - side) / 2
    top = (size - side) / 2
    right = left + side
    bottom = top + side

    stroke = side * 0.085
    arm = side * 0.30
    radius = stroke * 1.1

    # Four corner brackets, mirroring the reading frame shown by the scanner.
    for x_dir, y_dir, corner in (
        (1, 1, (left, top)),
        (-1, 1, (right, top)),
        (1, -1, (left, bottom)),
        (-1, -1, (right, bottom)),
    ):
        x, y = corner
        horizontal = sorted([x, x + arm * x_dir])
        vertical = sorted([y, y + arm * y_dir])
        draw.rounded_rectangle(
            (horizontal[0], y - stroke / 2, horizontal[1], y + stroke / 2),
            radius=radius,
            fill=GLYPH,
        )
        draw.rounded_rectangle(
            (x - stroke / 2, vertical[0], x + stroke / 2, vertical[1]),
            radius=radius,
            fill=GLYPH,
        )

    # QR finder pattern: concentric square, the most recognisable code motif.
    centre = size / 2
    outer = side * 0.20
    outer_stroke = side * 0.075
    draw.rounded_rectangle(
        (centre - outer, centre - outer, centre + outer, centre + outer),
        radius=outer * 0.28,
        outline=GLYPH,
        width=int(outer_stroke),
    )
    inner = side * 0.082
    draw.rounded_rectangle(
        (centre - inner, centre - inner, centre + inner, centre + inner),
        radius=inner * 0.30,
        fill=GLYPH,
    )

    # Scanning line, in the accent tone used by the interface.
    line_half = side * 0.34
    line_height = side * 0.022
    draw.rounded_rectangle(
        (centre - line_half, centre - line_height, centre + line_half, centre + line_height),
        radius=line_height,
        fill=ACCENT,
    )


def full_icon(size: int) -> Image.Image:
    image = rounded_background(size)
    draw_glyph(ImageDraw.Draw(image), size, scale=0.62)
    return image


def maskable_icon(size: int) -> Image.Image:
    """Full-bleed variant: launchers may crop up to the outer 20 %."""
    image = Image.new("RGBA", (size, size), BACKGROUND + (255,))
    gradient = rounded_background(size * 2).resize((size, size))
    image.paste(gradient, (0, 0))
    flat = Image.new("RGBA", (size, size), BACKGROUND + (255,))
    flat.paste(image, (0, 0), image)
    draw_glyph(ImageDraw.Draw(flat), size, scale=0.48)
    return flat


def adaptive_foreground(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_glyph(ImageDraw.Draw(image), size, scale=0.46)
    return image


def save(image: Image.Image, relative: str) -> None:
    path = OUTPUT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG", optimize=True)
    print(path.relative_to(ROOT))


def main() -> None:
    master = full_icon(CANVAS)
    save(master, "icon-1024.png")

    for density, size in ANDROID_LEGACY.items():
        save(full_icon(CANVAS).resize((size, size), Image.LANCZOS), f"android/mipmap-{density}/ic_launcher.png")
    for density, size in ANDROID_ADAPTIVE.items():
        save(
            adaptive_foreground(CANVAS).resize((size, size), Image.LANCZOS),
            f"android/mipmap-{density}/ic_launcher_foreground.png",
        )

    for name, size in WEB_SIZES.items():
        source = maskable_icon(CANVAS) if "maskable" in name else full_icon(CANVAS)
        save(source.resize((size, size), Image.LANCZOS), f"web/{name}")
    save(full_icon(CANVAS).resize((32, 32), Image.LANCZOS), "web/favicon.png")


if __name__ == "__main__":
    main()
