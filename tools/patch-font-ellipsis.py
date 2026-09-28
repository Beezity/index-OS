#!/usr/bin/env python3
"""Patch U+2026 HORIZONTAL ELLIPSIS into the bundled DOS Universal font.

The glyph is derived from the font's own U+002E FULL STOP outline, repeated
three times inside one monospace cell. This preserves the THE INDEX pixel/DOS
visual style without relying on font fallback for GTK/Pango generated text.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

ELLIPSIS = 0x2026
PERIOD = 0x002E


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def unicode_cmaps(font: TTFont):
    for table in font["cmap"].tables:
        if table.isUnicode():
            yield table


def patch_font(path: Path) -> dict[str, object]:
    before = sha256(path)
    font = TTFont(path, recalcBBoxes=True, recalcTimestamp=False)

    if "glyf" not in font:
        raise RuntimeError("expected a TrueType glyf table")

    cmap = font.getBestCmap()
    if PERIOD not in cmap:
        raise RuntimeError("font has no U+002E FULL STOP glyph to derive from")

    period_name = cmap[PERIOD]
    glyph_set = font.getGlyphSet()
    glyf = font["glyf"]
    hmtx = font["hmtx"].metrics

    period_glyph = glyf[period_name]
    period_glyph.recalcBounds(glyf)
    x_min = period_glyph.xMin
    x_max = period_glyph.xMax
    y_min = period_glyph.yMin
    dot_width = max(1, x_max - x_min)
    advance, _ = hmtx[period_name]

    # Keep the source dot at native size whenever three copies fit comfortably
    # in the monospace cell. Only scale if an unusual source glyph is too wide.
    scale = min(1.0, (advance * 0.72) / (dot_width * 3.0))
    scaled_width = dot_width * scale
    gap = (advance - 3.0 * scaled_width) / 4.0
    if gap < 0:
        raise RuntimeError("could not fit three period glyphs into one advance cell")

    existing_name = cmap.get(ELLIPSIS)
    target_name = existing_name or "ellipsis.index"

    order = font.getGlyphOrder()
    if target_name not in order:
        order.append(target_name)
        font.setGlyphOrder(order)

    pen = TTGlyphPen(glyph_set)
    period = glyph_set[period_name]

    # Preserve the period glyph's baseline placement while centering three dots
    # horizontally in one cell.
    y_shift = y_min * (1.0 - scale)
    for index in range(3):
        target_left = gap + index * (scaled_width + gap)
        x_shift = target_left - x_min * scale
        transformed = TransformPen(
            pen,
            (scale, 0.0, 0.0, scale, x_shift, y_shift),
        )
        period.draw(transformed)

    glyf[target_name] = pen.glyph()
    hmtx[target_name] = (advance, int(round(gap)))

    mapped = 0
    for table in unicode_cmaps(font):
        table.cmap[ELLIPSIS] = target_name
        mapped += 1

    font["maxp"].numGlyphs = len(font.getGlyphOrder())
    font.save(path, reorderTables=False)

    # Reopen the output so a malformed result fails before it can be committed.
    check = TTFont(path, recalcBBoxes=True, recalcTimestamp=False)
    check_cmap = check.getBestCmap()
    if check_cmap.get(ELLIPSIS) != target_name:
        raise RuntimeError("saved font does not resolve U+2026 to the patched glyph")

    check_glyph = check["glyf"][target_name]
    check_glyph.recalcBounds(check["glyf"])
    if check_glyph.numberOfContours == 0:
        raise RuntimeError("patched ellipsis glyph has no contours")

    after = sha256(path)
    return {
        "period_name": period_name,
        "target_name": target_name,
        "advance": advance,
        "period_width": dot_width,
        "scale": scale,
        "unicode_cmaps": mapped,
        "before_sha256": before,
        "after_sha256": after,
        "changed": before != after,
        "bounds": (
            check_glyph.xMin,
            check_glyph.yMin,
            check_glyph.xMax,
            check_glyph.yMax,
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("font", type=Path)
    args = parser.parse_args()

    result = patch_font(args.font)
    for key, value in result.items():
        print(f"{key}={value}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
