#!/usr/bin/env python3
"""Replace semitransparent edge RGB with nearby opaque subject colors."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--inset", type=int, default=2)
    args = parser.parse_args()

    image = Image.open(args.source).convert("RGBA")
    rgba = np.asarray(image).copy()
    alpha = rgba[:, :, 3]
    solid = alpha >= 250
    color_source = solid.copy()
    # Pull the color source inward without adding a SciPy dependency. This
    # prevents a chroma-contaminated opaque rim from becoming the source color.
    for _ in range(args.inset):
        padded = np.pad(color_source, 1, constant_values=False)
        eroded = np.ones_like(color_source)
        for dy in range(3):
            for dx in range(3):
                eroded &= padded[dy : dy + color_source.shape[0], dx : dx + color_source.shape[1]]
        if not eroded.any():
            break
        color_source = eroded

    fringe = (alpha > 0) & ~color_source
    known = color_source.copy()
    colors = rgba[:, :, :3].astype(np.uint32)
    height, width = known.shape
    for _ in range(64):
        pending = fringe & ~known
        if not pending.any():
            break
        padded_known = np.pad(known, 1, constant_values=False)
        padded_colors = np.pad(colors, ((1, 1), (1, 1), (0, 0)), constant_values=0)
        count = np.zeros((height, width), dtype=np.uint16)
        total = np.zeros((height, width, 3), dtype=np.uint32)
        for dy in range(3):
            for dx in range(3):
                if dy == 1 and dx == 1:
                    continue
                neighbor_known = padded_known[dy : dy + height, dx : dx + width]
                count += neighbor_known
                total += padded_colors[dy : dy + height, dx : dx + width] * neighbor_known[:, :, None]
        fill = pending & (count > 0)
        if not fill.any():
            break
        colors[fill] = total[fill] // count[fill][:, None]
        known[fill] = True
    rgba[fringe, :3] = colors[fringe].astype(np.uint8)

    rgba[alpha == 0, :3] = 0
    args.output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba, mode="RGBA").save(args.output, optimize=True)


if __name__ == "__main__":
    main()
