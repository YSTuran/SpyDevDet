from pathlib import Path
import sys

from PIL import Image


def fit_mark(source: Image.Image, canvas_size: int, mark_size: int) -> Image.Image:
    alpha = source.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Source image has no visible pixels")
    mark = source.crop(bounds)
    mark.thumbnail((mark_size, mark_size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    position = ((canvas_size - mark.width) // 2, (canvas_size - mark.height) // 2)
    canvas.alpha_composite(mark, position)
    return canvas


def launcher(mark: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), "#063B4C")
    foreground = fit_mark(mark, size, round(size * 0.76))
    canvas.alpha_composite(foreground)
    return canvas.convert("RGB")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: generate_brand_assets.py SOURCE_PNG")
    root = Path(__file__).resolve().parents[1]
    source = Image.open(sys.argv[1]).convert("RGBA")

    brand_dir = root / "assets" / "branding"
    brand_dir.mkdir(parents=True, exist_ok=True)
    fit_mark(source, 1024, 900).save(brand_dir / "app_mark.png", optimize=True)

    res = root / "android" / "app" / "src" / "main" / "res"
    launcher_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    splash_sizes = {
        "mipmap-mdpi": 84,
        "mipmap-hdpi": 126,
        "mipmap-xhdpi": 168,
        "mipmap-xxhdpi": 252,
        "mipmap-xxxhdpi": 336,
    }
    for folder, size in launcher_sizes.items():
        target = res / folder
        target.mkdir(parents=True, exist_ok=True)
        launcher(source, size).save(target / "ic_launcher.png", optimize=True)
    for folder, size in splash_sizes.items():
        target = res / folder
        fit_mark(source, size, round(size * 0.9)).save(
            target / "launch_image.png", optimize=True
        )

    drawable = res / "drawable-nodpi"
    drawable.mkdir(parents=True, exist_ok=True)
    fit_mark(source, 432, 270).save(
        drawable / "ic_launcher_foreground.png", optimize=True
    )

    windows_icon = root / "windows" / "runner" / "resources" / "app_icon.ico"
    launcher(source, 1024).save(
        windows_icon,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()
