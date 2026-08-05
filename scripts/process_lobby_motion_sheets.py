from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "flutter_app" / "assets" / "images" / "production_soft_painted"
SOURCES = ART / "lobby_motion_sources"

MOTIONS = {
    "choi_iseo": ("choi_iseo_thread_tidy_sheet_v1.png", "thread_tidy", "grid"),
    "jung_arin": ("jung_arin_tie_reset_sheet_v1.png", "tie_reset", "grid"),
    "park_haeun": ("park_haeun_welcome_sheet_v1.png", "welcome", "grid"),
    "han_sua": ("han_sua_stretch_strip_v2.png", "stretch", "strip"),
    "yoon_chaea": ("yoon_chaea_uniform_tidy_sheet_v1.png", "uniform_tidy", "grid"),
}

CANVAS = (1024, 1536)
TARGET_FRAME_HEIGHT = 1450
TARGET_BOTTOM = 1512


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 16 else 0)
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("Frame contains no visible character pixels")
    return bbox


def split_sheet(sheet: Image.Image, layout: str) -> list[Image.Image]:
    width, height = sheet.size
    if layout == "strip":
        frame_width = width // 4
        return [
            sheet.crop((index * frame_width, 0, (index + 1) * frame_width, height))
            for index in range(4)
        ]
    half_width = width // 2
    half_height = height // 2
    return [
        sheet.crop((0, 0, half_width, half_height)),
        sheet.crop((half_width, 0, width, half_height)),
        sheet.crop((0, half_height, half_width, height)),
        sheet.crop((half_width, half_height, width, height)),
    ]


def process_motion(
    character_id: str, source_name: str, motion_name: str, layout: str
) -> None:
    sheet = Image.open(SOURCES / source_name).convert("RGBA")
    frames = split_sheet(sheet, layout)
    boxes = [alpha_bbox(frame) for frame in frames]
    destination = ART / character_id
    destination.mkdir(parents=True, exist_ok=True)
    for index, (frame, bbox) in enumerate(zip(frames, boxes, strict=True)):
        subject = frame.crop(bbox)
        scale = TARGET_FRAME_HEIGHT / subject.height
        resized = subject.resize(
            (
                max(1, round(subject.width * scale)),
                max(1, round(subject.height * scale)),
            ),
            Image.Resampling.LANCZOS,
        )
        canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        x = (CANVAS[0] - resized.width) // 2
        y = TARGET_BOTTOM - resized.height
        canvas.alpha_composite(resized, (x, y))
        output = destination / f"10_lobby_{motion_name}_f{index}_v2.png"
        canvas.save(output, optimize=True)
        corner_alpha = [
            canvas.getpixel((0, 0))[3],
            canvas.getpixel((CANVAS[0] - 1, 0))[3],
            canvas.getpixel((0, CANVAS[1] - 1))[3],
            canvas.getpixel((CANVAS[0] - 1, CANVAS[1] - 1))[3],
        ]
        if any(corner_alpha):
            raise ValueError(f"{output.name}: canvas corners must remain transparent")
        print(
            f"{output.relative_to(ROOT)} size={canvas.size} "
            f"subject={resized.size} anchor=({x},{y})"
        )


def main() -> None:
    for character_id, (source_name, motion_name, layout) in MOTIONS.items():
        process_motion(character_id, source_name, motion_name, layout)


if __name__ == "__main__":
    main()
