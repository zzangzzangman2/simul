#!/usr/bin/env python3
"""Extract a character alpha mask and remove checkerboard edge contamination."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from rembg import new_session, remove
from scipy import ndimage


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--model", default="isnet-anime")
    parser.add_argument("--threshold", type=int, default=8)
    parser.add_argument(
        "--model-input",
        choices=("raw", "dark-composite"),
        default="raw",
    )
    parser.add_argument(
        "--intersect-source-alpha",
        action="store_true",
        help="Keep the new mask inside the source alpha instead of replacing it.",
    )
    parser.add_argument("--no-defringe", action="store_true")
    parser.add_argument("--post-process-mask", action="store_true")
    parser.add_argument("--mask-inset", type=int, default=1)
    parser.add_argument("--defringe-inset", type=int, default=3)
    parser.add_argument("--keep-border-checker", action="store_true")
    parser.add_argument("--keep-enclosed-checker", action="store_true")
    parser.add_argument("--preview-dir", type=Path)
    parser.add_argument("--preview-scale", type=float, default=0.5)
    return parser.parse_args()


def extract_character(
    source_path: Path,
    output_path: Path,
    args: argparse.Namespace,
    session: object,
) -> None:
    source = Image.open(source_path).convert("RGBA")

    if args.model_input == "raw":
        # Generated PNGs retain their original checker/matte RGB even where an
        # earlier pass made pixels transparent. Showing that complete pattern to
        # the model makes the background spatially consistent again.
        model_input = source.convert("RGB")
    else:
        model_input = Image.new("RGB", source.size, (24, 24, 28))
        model_input.paste(source.convert("RGB"), mask=source.getchannel("A"))

    mask = remove(
        model_input,
        session=session,
        only_mask=True,
        post_process_mask=args.post_process_mask,
    ).convert("L")
    if args.threshold > 0:
        mask = mask.point(lambda value: 0 if value <= args.threshold else value)
    if not args.keep_border_checker:
        rgba = np.asarray(source)
        rgb = rgba[:, :, :3].astype(np.int16)
        original_alpha = rgba[:, :, 3]
        channel_range = rgb.max(axis=2) - rgb.min(axis=2)
        luminance = rgb.mean(axis=2)
        checker_candidate = (
            (original_alpha <= 8)
            & (channel_range <= 12)
            & (luminance >= 230)
        )
        border_seed = np.zeros(checker_candidate.shape, dtype=bool)
        border_seed[0, :] = checker_candidate[0, :]
        border_seed[-1, :] = checker_candidate[-1, :]
        border_seed[:, 0] = checker_candidate[:, 0]
        border_seed[:, -1] = checker_candidate[:, -1]
        border_checker = ndimage.binary_propagation(
            border_seed,
            structure=np.ones((3, 3), dtype=bool),
            mask=checker_candidate,
        )
        mask_array = np.asarray(mask).copy()
        mask_array[border_checker] = 0
        mask = Image.fromarray(mask_array.astype("uint8"))
    if not args.keep_enclosed_checker:
        rgba = np.asarray(source)
        rgb = rgba[:, :, :3].astype(np.int16)
        channel_range = rgb.max(axis=2) - rgb.min(axis=2)
        luminance = rgb.mean(axis=2)
        foreground = np.asarray(mask) >= 128
        bright_neutral = (
            foreground & (channel_range <= 12) & (luminance >= 230)
        )
        labels, count = ndimage.label(
            bright_neutral,
            structure=np.ones((3, 3), dtype=bool),
        )
        sizes = np.bincount(labels.ravel())
        enclosed_checker = np.zeros(foreground.shape, dtype=bool)
        for label in range(1, count + 1):
            if sizes[label] < 10000:
                continue
            yy, xx = np.where(labels == label)
            width = int(xx.max() - xx.min() + 1)
            height = int(yy.max() - yy.min() + 1)
            aspect = max(width / height, height / width)
            if (
                aspect >= 3.5
                and int(yy.min()) >= source.height * 0.4
                and float(luminance[yy, xx].std()) >= 4
            ):
                enclosed_checker |= labels == label
        if enclosed_checker.any():
            enclosed_checker = ndimage.binary_dilation(
                enclosed_checker,
                iterations=2,
            )
            mask_array = np.asarray(mask).copy()
            mask_array[enclosed_checker] = 0
            mask = Image.fromarray(mask_array.astype("uint8"))
    if args.mask_inset > 0:
        mask_array = ndimage.grey_erosion(
            np.asarray(mask),
            size=(args.mask_inset * 2 + 1, args.mask_inset * 2 + 1),
            mode="constant",
            cval=0,
        )
        mask = Image.fromarray(mask_array.astype("uint8"))

    if args.intersect_source_alpha:
        original_alpha = source.getchannel("A")
        mask = Image.fromarray(
            __import__("numpy").minimum(
                __import__("numpy").asarray(mask),
                __import__("numpy").asarray(original_alpha),
            ).astype("uint8")
        )

    output = source.copy()
    output.putalpha(mask)
    if not args.no_defringe:
        rgba = np.asarray(output).copy()
        alpha = rgba[:, :, 3]
        solid = alpha >= 250
        color_source = solid
        if args.defringe_inset > 0:
            eroded = ndimage.binary_erosion(
                solid,
                iterations=args.defringe_inset,
                border_value=0,
            )
            if eroded.any():
                color_source = eroded
        if color_source.any():
            nearest = ndimage.distance_transform_edt(
                ~color_source,
                return_distances=False,
                return_indices=True,
            )
            fringe = (alpha > 0) & ~color_source
            rgba[fringe, :3] = rgba[
                nearest[0][fringe], nearest[1][fringe], :3
            ]
        rgba[alpha == 0, :3] = 0
        output = Image.fromarray(rgba, mode="RGBA")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path, optimize=True)

    if args.preview_dir:
        args.preview_dir.mkdir(parents=True, exist_ok=True)
        for name, color in {
            "black": (0, 0, 0, 255),
            "magenta": (116, 0, 88, 255),
            "cyan": (0, 92, 104, 255),
        }.items():
            preview = Image.new("RGBA", output.size, color)
            preview.alpha_composite(output)
            preview_rgb = preview.convert("RGB")
            if 0 < args.preview_scale < 1:
                preview_rgb = preview_rgb.resize(
                    (
                        round(preview_rgb.width * args.preview_scale),
                        round(preview_rgb.height * args.preview_scale),
                    ),
                    Image.Resampling.LANCZOS,
                )
            preview_rgb.save(
                args.preview_dir / f"{output_path.stem}_{name}.jpg",
                quality=94,
                subsampling=0,
            )


def main() -> None:
    args = parse_args()
    extract_character(
        args.source,
        args.output,
        args,
        new_session(args.model),
    )


if __name__ == "__main__":
    main()
