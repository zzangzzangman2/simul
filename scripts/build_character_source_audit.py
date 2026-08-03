#!/usr/bin/env python3
"""Render current RGBA character sprites on dark and cyan audit sheets."""

from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def fit_sprite(source: Image.Image, size: tuple[int, int]) -> Image.Image:
    copy = source.copy()
    copy.thumbnail(size, Image.Resampling.LANCZOS)
    return copy


def build_sheet(files: list[Path], output: Path, background: tuple[int, int, int]) -> None:
    tile_width, image_height, label_height = 256, 384, 28
    columns = 3
    rows = math.ceil(len(files) / columns)
    sheet = Image.new(
        "RGB",
        (tile_width * columns, (image_height + label_height) * rows),
        background,
    )
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=15)
    for index, file in enumerate(files):
        x = (index % columns) * tile_width
        y = (index // columns) * (image_height + label_height)
        sprite = fit_sprite(Image.open(file).convert("RGBA"), (tile_width, image_height))
        sprite_x = x + (tile_width - sprite.width) // 2
        sprite_y = y + (image_height - sprite.height) // 2
        tile = Image.new("RGBA", (tile_width, image_height), (*background, 255))
        tile.alpha_composite(sprite, (sprite_x - x, sprite_y - y))
        sheet.paste(tile.convert("RGB"), (x, y))
        draw.text((x + 6, y + image_height + 5), file.stem, fill=(245, 246, 250), font=font)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=96, subsampling=0)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_root", type=Path)
    parser.add_argument("output_root", type=Path)
    args = parser.parse_args()
    root_files = sorted(args.source_root.glob("*.png"))
    if root_files:
        build_sheet(
            root_files,
            args.output_root / f"{args.source_root.name}__black.jpg",
            (0, 0, 0),
        )
        build_sheet(
            root_files,
            args.output_root / f"{args.source_root.name}__cyan.jpg",
            (0, 94, 108),
        )
    for directory in sorted(path for path in args.source_root.iterdir() if path.is_dir()):
        files = sorted(directory.glob("*.png"))
        if not files:
            continue
        build_sheet(files, args.output_root / f"{directory.name}__black.jpg", (0, 0, 0))
        build_sheet(files, args.output_root / f"{directory.name}__cyan.jpg", (0, 94, 108))


if __name__ == "__main__":
    main()
