"""Generate the final XieQian application icon (Aurora Sparkle).

A large concave-sided four-point sparkle with a soft gradient halo, plus one
smaller companion sparkle. Rendered at 2x and downsampled with Lanczos for
clean antialiased edges at every icon size.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ICON_PATH = ROOT / "assets" / "app.ico"
UI_ICON_PATH = ROOT / "ui" / "assets" / "app-icon-512.png"

SIZES = (16, 32, 48, 64, 128, 256)
MASTER_SIZE = 1024
SUPERSAMPLE = 2
CANVAS = MASTER_SIZE * SUPERSAMPLE

BLUE = (0x3B, 0x8B, 0xF6)
GREEN = (0x2E, 0xD4, 0xA5)


def lerp(start, end, amount):
    return tuple(round(a + (b - a) * amount) for a, b in zip(start, end))


def gradient_image(size):
    """Diagonal gradient from bottom-left blue to top-right green."""
    image = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(image)
    total = size * 2 - 1
    for value in range(-(size - 1), size):
        raw = (value + size - 1) / total
        amount = max(0.0, min(1.0, (raw - 0.12) / 0.76))
        color = lerp(BLUE, GREEN, amount)
        if value >= 0:
            first, second = (value, 0), (size - 1, size - 1 - value)
        else:
            first, second = (0, -value), (size - 1 + value, size - 1)
        draw.line([first, second], fill=color)
    return image


def sparkle_mask(size, center, horizontal, vertical, points=240):
    """Concave four-point star shaped like a modern UI sparkle."""
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


def filled(mask, gradient, alpha=255, brightness=1.0):
    layer = gradient.convert("RGBA")
    if brightness != 1.0:
        layer = ImageEnhance.Brightness(layer).enhance(brightness)
    layer.putalpha(mask.point(lambda value: value * alpha // 255))
    return layer


def build_master():
    size = CANVAS
    center = size / 2
    gradient = gradient_image(size)
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    halo = sparkle_mask(size, (center, center), 0.240 * size, 0.300 * size)
    halo = halo.filter(ImageFilter.GaussianBlur(0.045 * size))
    result.alpha_composite(filled(halo, gradient, 70))

    star = sparkle_mask(size, (center, center), 0.205 * size, 0.260 * size)
    result.alpha_composite(filled(star, gradient, 255, 1.08))

    companion = sparkle_mask(size, (0.740 * size, 0.300 * size), 0.070 * size, 0.090 * size)
    result.alpha_composite(filled(companion, gradient, 220, 1.22))

    return result.resize((MASTER_SIZE, MASTER_SIZE), Image.Resampling.LANCZOS)


def main():
    master = build_master()

    UI_ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    master.resize((512, 512), Image.Resampling.LANCZOS).save(UI_ICON_PATH)

    ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    # 32-bit BMP entries keep the ICO compatible with rc.exe and Inno Setup.
    master.save(ICON_PATH, format="ICO", sizes=[(size, size) for size in SIZES], bitmap_format="bmp")

    print(f"wrote {ICON_PATH} ({ICON_PATH.stat().st_size} bytes)")
    print(f"wrote {UI_ICON_PATH}")


if __name__ == "__main__":
    main()
