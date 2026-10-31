"""Generate modern blue-green icon proposals for XieQian.

Run without arguments to render four 512x512 previews into
build/icon-previews/. Once a scheme is chosen, run with --finalize a|b|c|d to
write assets/app.ico and ui/assets/app-icon-512.png for that scheme.
"""

import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ICON_PATH = ROOT / "assets" / "app.ico"
UI_ICON_PATH = ROOT / "ui" / "assets" / "app-icon-512.png"
PREVIEW_DIR = ROOT / "build" / "icon-previews"

SIZES = (16, 32, 48, 64, 128, 256)
MASTER_SIZE = 1024
SUPERSAMPLE = 2
CANVAS = MASTER_SIZE * SUPERSAMPLE

BLUE = (0x3B, 0x8B, 0xF6)
GREEN = (0x2E, 0xD4, 0xA5)

SCHEMES = {
    "a": ("A-stacked-sticks", "层叠的木签 (Stacked Sticks)"),
    "b": ("B-diamond-sparkle", "极简星芒 (Diamond Sparkle)"),
    "c": ("C-overlapping-cards", "交叠的视界 (Overlapping Cards)"),
    "d": ("D-infinity-fold", "无限折线 (Infinity Fold)"),
}


def lerp(start, end, t):
    return tuple(round(a + (b - a) * t) for a, b in zip(start, end))


def gradient_image(size):
    """Bottom-left blue to top-right green."""
    image = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(image)
    total = size * 2 - 1
    for value in range(-(size - 1), size):
        raw = (value + size - 1) / total
        t = max(0.0, min(1.0, (raw - 0.12) / 0.76))
        color = lerp(BLUE, GREEN, t)
        if value >= 0:
            first, second = (value, 0), (size - 1, size - 1 - value)
        else:
            first, second = (0, -value), (size - 1 + value, size - 1)
        draw.line([first, second], fill=color)
    return image


def canvas(size):
    return Image.new("RGBA", (size, size), (0, 0, 0, 0))


def filled(mask, gradient, alpha=255, brightness=1.0):
    layer = gradient.convert("RGBA")
    if brightness != 1.0:
        layer = ImageEnhance.Brightness(layer).enhance(brightness)
    layer.putalpha(mask.point(lambda value: value * alpha // 255))
    return layer


def rotate_layer(layer, angle, center):
    return layer.rotate(angle, resample=Image.Resampling.BICUBIC, center=center)


def rounded_rect_mask(size, center, width, height, radius):
    mask = Image.new("L", (size, size), 0)
    left = center[0] - width / 2
    top = center[1] - height / 2
    ImageDraw.Draw(mask).rounded_rectangle(
        [left, top, left + width, top + height],
        radius=radius,
        fill=255,
    )
    return mask


def astroid_mask(size, center, horizontal, vertical, points=240):
    mask = Image.new("L", (size, size), 0)
    outline = []
    for step in range(points):
        angle = 2 * math.pi * step / points
        outline.append((
            center[0] + horizontal * math.cos(angle) ** 3,
            center[1] + vertical * math.sin(angle) ** 3,
        ))
    ImageDraw.Draw(mask).polygon(outline, fill=255)
    return mask


def scheme_a(gradient):
    size = CANVAS
    center = size / 2
    result = canvas(size)

    stick_width = 0.117 * size
    stick_height = 0.605 * size
    radius = 0.055 * size
    angle = -20.0
    layers = (
        ((-0.137 * size, 0.040 * size), 0.80, 220),
        ((0.0, -0.012 * size), 1.00, 245),
        ((0.137 * size, -0.052 * size), 1.14, 255),
    )

    for (offset_x, offset_y), brightness, alpha in layers:
        card_center = (center + offset_x, center + offset_y)
        mask = rounded_rect_mask(size, card_center, stick_width, stick_height, radius)
        mask = mask.rotate(angle, resample=Image.Resampling.BICUBIC, center=card_center)
        result.alpha_composite(filled(mask, gradient, alpha, brightness))

    return result


def scheme_b(gradient):
    size = CANVAS
    center = size / 2
    result = canvas(size)

    side = 0.460 * size
    diamond_mask = rounded_rect_mask(size, (center, center), side, side, 0.075 * size)
    diamond_mask = diamond_mask.rotate(45.0, resample=Image.Resampling.BICUBIC, center=(center, center))
    result.alpha_composite(filled(diamond_mask, gradient))

    sparkles = (
        ((0.725, 0.275), 0.090, 0.115, 1.18, 245),
        ((0.295, 0.705), 0.055, 0.070, 1.10, 170),
        ((0.630, 0.195), 0.035, 0.045, 1.20, 120),
    )
    for (x, y), horizontal, vertical, brightness, alpha in sparkles:
        mask = astroid_mask(size, (x * size, y * size), horizontal * size, vertical * size)
        result.alpha_composite(filled(mask, gradient, alpha, brightness))

    return result


def scheme_c(gradient):
    size = CANVAS
    center = size / 2
    result = canvas(size)

    card_width = 0.380 * size
    card_height = 0.550 * size
    radius = 0.070 * size
    cards = (
        (-20.0, (-0.060 * size, 0.045 * size), 0.55),
        (0.0, (0.0, 0.0), 0.63),
        (20.0, (0.060 * size, -0.035 * size), 0.72),
    )

    for angle, (offset_x, offset_y), alpha in cards:
        card_center = (center + offset_x, center + offset_y)
        mask = rounded_rect_mask(size, card_center, card_width, card_height, radius)
        mask = mask.rotate(angle, resample=Image.Resampling.BICUBIC, center=card_center)
        result.alpha_composite(filled(mask, gradient, round(alpha * 255)))

    return result


def scheme_d(gradient):
    size = CANVAS
    result = canvas(size)
    stroke = 0.105 * size

    ring_center = (0.470 * size, 0.460 * size)
    ring_radius = 0.235 * size
    attach = (
        ring_center[0] + ring_radius * math.cos(math.radians(45)),
        ring_center[1] + ring_radius * math.sin(math.radians(45)),
    )
    corner = (0.800 * size, attach[1])
    tail_end = (0.800 * size, 0.830 * size)

    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)

    outer = ring_radius + stroke / 2
    inner = ring_radius - stroke / 2
    draw.ellipse(
        [ring_center[0] - outer, ring_center[1] - outer,
         ring_center[0] + outer, ring_center[1] + outer],
        fill=255,
    )
    draw.ellipse(
        [ring_center[0] - inner, ring_center[1] - inner,
         ring_center[0] + inner, ring_center[1] + inner],
        fill=0,
    )

    # Two capsules form the folded tail (one rounded corner, round caps).
    draw.rounded_rectangle(
        [attach[0] - stroke / 2, attach[1] - stroke / 2,
         corner[0] + stroke / 2, corner[1] + stroke / 2],
        radius=stroke / 2,
        fill=255,
    )
    draw.rounded_rectangle(
        [corner[0] - stroke / 2, corner[1] - stroke / 2,
         tail_end[0] + stroke / 2, tail_end[1] + stroke / 2],
        radius=stroke / 2,
        fill=255,
    )

    result.alpha_composite(filled(mask, gradient))
    return result


SCHEME_BUILDERS = {
    "a": scheme_a,
    "b": scheme_b,
    "c": scheme_c,
    "d": scheme_d,
}


def render(choice):
    gradient = gradient_image(CANVAS)
    return SCHEME_BUILDERS[choice](gradient).resize((MASTER_SIZE, MASTER_SIZE), Image.Resampling.LANCZOS)


def build_previews():
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    for choice, (filename, title) in SCHEMES.items():
        master = render(choice)
        path = PREVIEW_DIR / f"{filename}.png"
        master.resize((512, 512), Image.Resampling.LANCZOS).save(path)
        print(f"{choice.upper()}: {title} -> {path}")


def finalize(choice):
    master = render(choice)
    UI_ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    master.resize((512, 512), Image.Resampling.LANCZOS).save(UI_ICON_PATH)

    ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    # 32-bit BMP entries keep the ICO compatible with rc.exe and Inno Setup.
    master.save(ICON_PATH, format="ICO", sizes=[(size, size) for size in SIZES], bitmap_format="bmp")
    print(f"finalized scheme {choice.upper()}: {ICON_PATH}, {UI_ICON_PATH}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--finalize", choices=sorted(SCHEMES), help="write ICO and UI PNG for one scheme")
    args = parser.parse_args()

    if args.finalize:
        finalize(args.finalize)
    else:
        build_previews()


if __name__ == "__main__":
    main()
