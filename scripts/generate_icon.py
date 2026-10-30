"""Generate the modern XieQian application icon.

Three tilted glass cards in a cyan-to-purple gradient overlap under a glowing
white four-point sparkle. The master is rendered at 2x and downsampled with
Lanczos for clean antialiased edges at every icon size.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ICON_PATH = ROOT / "assets" / "app.ico"
UI_ICON_PATH = ROOT / "ui" / "assets" / "app-icon-512.png"
PREVIEW_DIR = ROOT / "build" / "icon-preview"

SIZES = (16, 32, 48, 64, 128, 256)
MASTER_SIZE = 1024
SUPERSAMPLE = 2
CANVAS = MASTER_SIZE * SUPERSAMPLE

CYAN = (0x00, 0xF0, 0xFF)
PURPLE = (0x8A, 0x2B, 0xE2)
WHITE = (255, 255, 255)


def lerp(start, end, t):
    return tuple(round(a + (b - a) * t) for a, b in zip(start, end))


def diagonal_gradient(size, start_color, end_color, range_start=0.0, range_end=1.0):
    image = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(image)
    total = size * 2 - 1
    for value in range(total):
        raw = value / (total - 1)
        t = max(0.0, min(1.0, (raw - range_start) / (range_end - range_start)))
        color = lerp(start_color, end_color, t)
        if value < size:
            first, second = (value, 0), (0, value)
        else:
            offset = value - (size - 1)
            first, second = (size - 1, offset), (offset, size - 1)
        draw.line([first, second], fill=color)
    return image


def card_mask(size, center, card_width, card_height, radius):
    mask = Image.new("L", (size, size), 0)
    left = center[0] - card_width / 2
    top = center[1] - card_height / 2
    ImageDraw.Draw(mask).rounded_rectangle(
        [left, top, left + card_width, top + card_height],
        radius=radius,
        fill=255,
    )
    return mask


def tinted_mask(mask, alpha, color):
    layer = Image.new("RGBA", mask.size, color + (0,))
    layer.putalpha(mask.point(lambda value: value * alpha // 255))
    return layer


def draw_cards(size, gradient):
    center = size / 2
    card_width = 0.440 * size
    card_height = 0.580 * size
    radius = 0.062 * size
    angle = -15.0

    cards = (
        ((-0.060 * size, 0.052 * size), 0.60, 115),
        ((0.0, 0.0), 0.68, 130),
        ((0.060 * size, -0.045 * size), 0.76, 145),
    )

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    stack = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    for (offset_x, offset_y), opacity, border_opacity in cards:
        card_center = (center + offset_x, center + offset_y)
        mask = card_mask(size, card_center, card_width, card_height, radius)
        rotated_mask = mask.rotate(angle, resample=Image.Resampling.BICUBIC, center=card_center)

        card_shadow = tinted_mask(rotated_mask, 45, (8, 12, 36)).filter(
            ImageFilter.GaussianBlur(0.010 * size)
        )
        shadow.alpha_composite(card_shadow, dest=(0, round(0.006 * size)))

        card = gradient.convert("RGBA")
        card.putalpha(rotated_mask.point(lambda value: value * round(opacity * 255) // 255))
        card = card.rotate(angle, resample=Image.Resampling.BICUBIC, center=card_center)

        border = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        border_draw = ImageDraw.Draw(border)
        left = card_center[0] - card_width / 2
        top = card_center[1] - card_height / 2
        border_draw.rounded_rectangle(
            [left, top, left + card_width, top + card_height],
            radius=radius,
            outline=(255, 255, 255, border_opacity),
            width=max(2, round(0.0032 * size)),
        )
        border = border.rotate(angle, resample=Image.Resampling.BICUBIC, center=card_center)

        stack.alpha_composite(card)
        stack.alpha_composite(border)

    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.alpha_composite(shadow)
    result.alpha_composite(stack)
    return result


def sparkle_mask(size, scale=1.0):
    mask = Image.new("L", (size, size), 0)
    center = size / 2
    horizontal = 0.115 * size * scale
    vertical = 0.145 * size * scale

    points = []
    steps = 240
    for step in range(steps):
        angle = 2 * math.pi * step / steps
        cosine = math.cos(angle)
        sine = math.sin(angle)
        points.append((center + horizontal * cosine ** 3, center + vertical * sine ** 3))

    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def draw_sparkle(size):
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = sparkle_mask(size)

    wide_glow = mask.filter(ImageFilter.GaussianBlur(0.050 * size))
    layer.alpha_composite(tinted_mask(wide_glow, 65, WHITE))

    tight_glow = mask.filter(ImageFilter.GaussianBlur(0.016 * size))
    layer.alpha_composite(tinted_mask(tight_glow, 180, WHITE))

    core = Image.new("RGBA", (size, size), WHITE + (255,))
    core.putalpha(mask)
    layer.alpha_composite(core)
    return layer


def build_master():
    gradient = diagonal_gradient(CANVAS, CYAN, PURPLE, 0.16, 0.84)
    canvas = draw_cards(CANVAS, gradient)
    canvas.alpha_composite(draw_sparkle(CANVAS))
    return canvas.resize((MASTER_SIZE, MASTER_SIZE), Image.Resampling.LANCZOS)


def main():
    master = build_master()
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    master.save(PREVIEW_DIR / f"icon-{MASTER_SIZE}.png")

    for size in SIZES:
        master.resize((size, size), Image.Resampling.LANCZOS).save(PREVIEW_DIR / f"icon-{size}.png")

    UI_ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    master.resize((512, 512), Image.Resampling.LANCZOS).save(UI_ICON_PATH)

    ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    # 32-bit BMP entries keep the ICO compatible with rc.exe and Inno Setup.
    master.save(ICON_PATH, format="ICO", sizes=[(size, size) for size in SIZES], bitmap_format="bmp")
    print(f"wrote {ICON_PATH} ({ICON_PATH.stat().st_size} bytes)")
    print(f"wrote {UI_ICON_PATH}")


if __name__ == "__main__":
    main()
