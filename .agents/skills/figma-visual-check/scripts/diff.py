#!/usr/bin/env python3
"""Diff a Figma render against a browser screenshot of the same UI.

usage: diff.py FIGMA_PNG ACTUAL_PNG [--max-mismatch PCT] [--out DIR]
Exit 0 = match, 1 = mismatch, 2 = unreadable input.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image, ImageChops

# A channel off by more than this (out of 255) counts: antialiasing passes, a wrong token does not.
CHANNEL_TOLERANCE = 32
# Sizes may differ by this many pixels before the size check fails.
SIZE_TOLERANCE_PX = 1
DEFAULT_MAX_MISMATCH_PCT = 2.0
# The diff image fades the Figma render to this much white, then paints mismatches red.
FADE = 0.7
PERCENT = 100
DECIMALS = 2
MAX_CHANNEL = 255
EXIT_MATCH = 0
EXIT_MISMATCH = 1
EXIT_BAD_INPUT = 2


def load(path):
    try:
        return Image.open(path).convert("RGB")
    except OSError as err:
        print(f"cannot read {path}: {err}", file=sys.stderr)
        sys.exit(EXIT_BAD_INPUT)


def mismatch_mask(want, got):
    """White where the two images differ beyond the tolerance, black elsewhere."""
    if got.size != want.size:
        got = got.resize(want.size)
    return ImageChops.difference(want, got).convert("L").point(
        lambda v: MAX_CHANNEL if v > CHANNEL_TOLERANCE else 0
    )


def save_overlay(want, mask, path):
    overlay = Image.blend(want, Image.new("RGB", want.size, "white"), FADE)
    overlay.paste(Image.new("RGB", want.size, "red"), mask=mask)
    overlay.save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("figma")
    ap.add_argument("actual")
    ap.add_argument("--max-mismatch", type=float, default=DEFAULT_MAX_MISMATCH_PCT)
    ap.add_argument("--out", default=".")
    a = ap.parse_args()

    want, got = load(a.figma), load(a.actual)
    size_ok = all(abs(w - g) <= SIZE_TOLERANCE_PX for w, g in zip(want.size, got.size))
    mask = mismatch_mask(want, got)
    pct = PERCENT * mask.histogram()[MAX_CHANNEL] / (want.width * want.height)

    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    save_overlay(want, mask, out / "diff.png")

    print(f"figma  {want.width}x{want.height}")
    print(f"actual {got.width}x{got.height}")
    print(f"size   {'ok' if size_ok else 'MISMATCH'}")
    print(f"pixels {pct:.{DECIMALS}f}% differ (max {a.max_mismatch}%)  {out / 'diff.png'}")
    sys.exit(EXIT_MATCH if size_ok and pct <= a.max_mismatch else EXIT_MISMATCH)


if __name__ == "__main__":
    main()
