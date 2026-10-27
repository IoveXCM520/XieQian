"""Generate the XieQian application icon.

The mark is an open, rounded ring (the sign tube) in a diagonal dai-blue to
bamboo-green gradient, with a gold arrow (the drawn sign) rising from its
centre. The master artwork is rendered at 4x and downsampled with Lanczos for
clean antialiased edges at every icon size.
"""

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ICON_PATH = ROOT / "assets" / "app.ico"
PREVIEW_DIR = ROOT / "build" / "icon-preview"

SIZES = (16, 32, 48, 64, 128, 256)
MASTER_SIZE = 1024
SUPERSAMPLE = 4
CANVAS = MASTER_SIZE * SUPERSAMPLE

RING_COLORS = ((0x2D, 0x3E, 0x50), (0x7A, 0x9E, 0x8E))
GOLD_COLORS = ((0xE8, 0xC9, 0x6E), (0xC1, 0x98, 0x2C))

RING_OUTER = 0.400
RING_WIDTH = 0.095
GAP_START_DEG = -52.0
GAP_END_DEG = 232.0


def lerp(start, end, t):
    return tuple(round(a + (b - a) * t) for a, b in zip(start, end))


def diagonal_gradient(size, start_color, end_color):
    """Top-left to bottom-right linear gradient."""
    image = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(image)
    total = size * 2 - 1
    for value in range(total):
        t = value / (total - 1)
        color = lerp(start_color, end_color, t)
        if value < size:
            first, second = (value, 0), (0, value)
        else:
            offset = value - (size - 1)
            first, second = (size - 1, offset), (offset, size - 1)
        draw.line([first, second], fill=color)
    return image


def ring_mask(size):
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    center = size / 2
    radius = RING_OUTER * size
    width = RING_WIDTH * size
    box = [center - radius, center - radius, center + radius, center + radius]

    # PIL angles start at 3 o'clock and grow clockwise; this leaves an 80° gap
    # at the top for the sign to rise through.
    draw.arc(box, GAP_START_DEG, GAP_END_DEG, fill=255, width=round(width))

    cap_radius = width / 2
    mid_radius = radius - cap_radius
    for angle in (GAP_START_DEG, GAP_END_DEG):
        radians = math.radians(angle)
        x = center + math.cos(radians) * mid_radius
        y = center + math.sin(radians) * mid_radius
        draw.ellipse([x - cap_radius, y - cap_radius, x + cap_radius, y + cap_radius], fill=255)
    return mask


def normalize(vector):
    length = math.hypot(*vector)
    return (vector[0] / length, vector[1] / length)


def rounded_polygon_mask(size, vertices, radius):
    """Fill a convex polygon whose corners use true circular arcs."""
    outline = []
    count = len(vertices)

    for index, (x, y) in enumerate(vertices):
        previous = vertices[(index - 1) % count]
        following = vertices[(index + 1) % count]
        toward_previous = normalize((previous[0] - x, previous[1] - y))
        toward_next = normalize((following[0] - x, following[1] - y))

        angle = math.acos(max(-1.0, min(1.0, toward_previous[0] * toward_next[0] +
                                         toward_previous[1] * toward_next[1])))
        tangent_distance = radius / math.tan(angle / 2)
        bisector = normalize((toward_previous[0] + toward_next[0], toward_previous[1] + toward_next[1]))
        center_distance = radius / math.sin(angle / 2)
        center = (x + bisector[0] * center_distance, y + bisector[1] * center_distance)

        start = (x + toward_previous[0] * tangent_distance, y + toward_previous[1] * tangent_distance)
        end = (x + toward_next[0] * tangent_distance, y + toward_next[1] * tangent_distance)
        start_angle = math.atan2(start[1] - center[1], start[0] - center[0])
        end_angle = math.atan2(end[1] - center[1], end[0] - center[0])
        delta = (end_angle - start_angle + math.pi) % (2 * math.pi) - math.pi

        steps = 24
        for step in range(steps + 1):
            current = start_angle + delta * step / steps
            outline.append((center[0] + math.cos(current) * radius,
                            center[1] + math.sin(current) * radius))

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon(outline, fill=255)
    return mask


def arrow_mask(size):
    center = size / 2
    tip = (center, 0.275 * size)
    base_y = 0.505 * size
    half_head = 0.120 * size
    head = rounded_polygon_mask(
        size,
        [tip, (center - half_head, base_y), (center + half_head, base_y)],
        radius=0.032 * size,
    )

    stem = Image.new("L", (size, size), 0)
    stem_draw = ImageDraw.Draw(stem)
    half_stem = 0.052 * size
    stem_draw.rounded_rectangle(
        [center - half_stem, 0.470 * size, center + half_stem, 0.740 * size],
        radius=0.044 * size,
        fill=255,
    )
    return ImageChops.lighter(head, stem)


def build_master():
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))

    ring = diagonal_gradient(CANVAS, *RING_COLORS).convert("RGBA")
    ring.putalpha(ring_mask(CANVAS))
    canvas.alpha_composite(ring)

    sign = diagonal_gradient(CANVAS, *GOLD_COLORS).convert("RGBA")
    sign.putalpha(arrow_mask(CANVAS))
    canvas.alpha_composite(sign)

    return canvas.resize((MASTER_SIZE, MASTER_SIZE), Image.Resampling.LANCZOS)


def main():
    master = build_master()
    master_path = PREVIEW_DIR / f"icon-{MASTER_SIZE}.png"
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    master.save(master_path)

    for size in SIZES:
        master.resize((size, size), Image.Resampling.LANCZOS).save(PREVIEW_DIR / f"icon-{size}.png")

    ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    # 32-bit BMP entries keep the ICO compatible with rc.exe and Inno Setup.
    master.save(ICON_PATH, format="ICO", sizes=[(size, size) for size in SIZES], bitmap_format="bmp")
    print(f"wrote {ICON_PATH} ({ICON_PATH.stat().st_size} bytes)")
    print(f"previews in {PREVIEW_DIR}")


if __name__ == "__main__":
    main()
