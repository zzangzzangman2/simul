#!/usr/bin/env python3
"""Build contact sheets for manual alpha-edge review."""

from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("preview_root", type=Path)
    parser.add_argument("output_root", type=Path)
    return parser.parse_args()


def build_sheet(files: list[Path], output: Path) -> None:
    if not files:
        return
    tile_width, image_height, label_height = 256, 384, 28
    columns = 3
    rows = math.ceil(len(files) / columns)
    sheet = Image.new(
        "RGB",
        (tile_width * columns, (image_height + label_height) * rows),
        (18, 20, 24),
    )
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=16)
    for index, file in enumerate(files):
        x = (index % columns) * tile_width
        y = (index // columns) * (image_height + label_height)
        image = Image.open(file).convert("RGB")
        sheet.paste(image, (x, y))
        draw.text(
            (x + 6, y + image_height + 5),
            file.stem.rsplit("_", 1)[0],
            fill=(238, 242, 248),
            font=font,
        )
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=95, subsampling=0)


def main() -> None:
    args = parse_args()
    groups = [
        path
        for path in args.preview_root.rglob("*")
        if path.is_dir() and list(path.glob("*_black.jpg"))
    ]
    for group in sorted(groups):
        relative = group.relative_to(args.preview_root)
        label = "__".join(relative.parts)
        for background in ("black", "cyan"):
            files = sorted(group.glob(f"*_{background}.jpg"))
            build_sheet(
                files,
                args.output_root / f"{label}__{background}.jpg",
            )


if __name__ == "__main__":
    main()
