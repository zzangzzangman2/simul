#!/usr/bin/env python3
"""Batch the approved v3 character sprites through one segmentation session."""

from __future__ import annotations

import argparse
from pathlib import Path
from types import SimpleNamespace

from rembg import new_session

from extract_character_alpha import extract_character


GIRL_FOLDERS = (
    "kim_seoa",
    "lee_jian",
    "choi_iseo",
    "jung_arin",
    "park_haeun",
    "han_sua",
    "oh_jiwoo",
    "yoon_chaea",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_root", type=Path)
    parser.add_argument("output_root", type=Path)
    parser.add_argument("--model", default="birefnet-general-lite")
    parser.add_argument("--mask-inset", type=int, default=2)
    parser.add_argument("--defringe-inset", type=int, default=6)
    parser.add_argument("--preview-dir", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    production_root = args.source_root / "production_soft_painted"
    nis_root = (
        args.source_root
        / "cinematic_soft_painted"
        / "decimal_nis_1999"
        / "characters"
    )
    sources = [
        path
        for folder in GIRL_FOLDERS
        for path in sorted((production_root / folder).glob("*.png"))
    ]
    sources.extend(sorted(nis_root.glob("*.png")))
    if len(sources) != 78:
        raise RuntimeError(f"Expected 78 v3 character sprites, found {len(sources)}")

    options = SimpleNamespace(
        model=args.model,
        threshold=8,
        model_input="raw",
        intersect_source_alpha=False,
        no_defringe=False,
        post_process_mask=False,
        keep_border_checker=False,
        keep_enclosed_checker=False,
        mask_inset=args.mask_inset,
        defringe_inset=args.defringe_inset,
        preview_dir=args.preview_dir,
        preview_scale=0.25,
    )
    session = new_session(args.model)
    for index, source in enumerate(sources, start=1):
        relative = source.relative_to(args.source_root)
        output = args.output_root / relative
        options.preview_dir = (
            args.preview_dir / relative.parent if args.preview_dir else None
        )
        extract_character(source, output, options, session)
        print(f"[{index:02d}/78] {relative.as_posix()}", flush=True)


if __name__ == "__main__":
    main()
