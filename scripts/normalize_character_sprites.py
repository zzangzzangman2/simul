#!/usr/bin/env python3
"""Normalize transparent full-body sprites to a shared canvas and baseline."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def normalize(source: Path, top: int, bottom: int, foot_start: int) -> None:
    image = Image.open(source).convert("RGBA")
    rgba = np.asarray(image).copy()
    alpha = rgba[:, :, 3]

    labels, count = ndimage.label(alpha > 8, structure=np.ones((3, 3), dtype=bool))
    if count == 0:
        raise ValueError(f"No foreground alpha in {source}")
    sizes = np.bincount(labels.ravel())
    largest = int(np.argmax(sizes[1:]) + 1)
    keep = labels == largest
    rgba[~keep] = 0

    yy, xx = np.where(keep)
    crop = Image.fromarray(rgba, mode="RGBA").crop(
        (int(xx.min()), int(yy.min()), int(xx.max()) + 1, int(yy.max()) + 1)
    )
    target_height = bottom - top + 1
    target_width = round(crop.width * target_height / crop.height)
    if target_width > image.width:
        raise ValueError(f"Normalized sprite is too wide for its canvas: {source}")
    crop = crop.resize((target_width, target_height), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    canvas.alpha_composite(crop, ((image.width - target_width) // 2, top))

    normalized = np.asarray(canvas).copy()
    normalized_alpha = normalized[:, :, 3]
    foot_y, foot_x = np.where(
        (normalized_alpha > 0)
        & (np.indices(normalized_alpha.shape)[0] >= foot_start)
    )
    if foot_x.size == 0:
        raise ValueError(f"No foot pixels below y={foot_start}: {source}")
    foot_center = (int(foot_x.min()) + int(foot_x.max()) + 1) / 2
    shift_x = round(image.width / 2 - foot_center)
    if shift_x:
        shifted = np.zeros_like(normalized)
        if shift_x > 0:
            shifted[:, shift_x:] = normalized[:, : image.width - shift_x]
        else:
            shifted[:, :shift_x] = normalized[:, -shift_x:]
        normalized = shifted

    normalized[normalized[:, :, 3] == 0, :3] = 0
    Image.fromarray(normalized, mode="RGBA").save(source, optimize=True)
    print(source)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("sources", nargs="+", type=Path)
    parser.add_argument("--top", type=int, default=20)
    parser.add_argument("--bottom", type=int, default=1516)
    parser.add_argument("--foot-start", type=int, default=1250)
    args = parser.parse_args()
    for source in args.sources:
        normalize(source, args.top, args.bottom, args.foot_start)


if __name__ == "__main__":
    main()
