"""
MOFU アプリアイコン生成スクリプト
肉球デザインのPNGアイコンを生成します
"""
from PIL import Image, ImageDraw
import math, os

# MOFUカラー
BG_COLOR     = (255, 248, 240)   # クリーム #FFF8F0
PAW_COLOR    = (212, 169, 138)   # ウォームタン #D4A98A
SHADOW_COLOR = (184, 140, 108)   # 少し暗め

def draw_circle(draw, cx, cy, r, color):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)

def draw_paw(size=512):
    img = Image.new("RGBA", (size, size), BG_COLOR + (255,))
    draw = ImageDraw.Draw(img)

    s = size / 512  # スケール係数

    # 角丸背景（iOSアイコン用）
    corner = int(115 * s)
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    bg_draw.rounded_rectangle([0, 0, size, size], radius=corner, fill=BG_COLOR + (255,))
    img = Image.composite(img, Image.new("RGBA", (size, size), (0, 0, 0, 0)), bg)
    img.paste(bg, mask=bg)
    draw = ImageDraw.Draw(img)

    # メイン肉球（中央下）
    main_cx, main_cy = int(256 * s), int(310 * s)
    main_rx, main_ry = int(110 * s), int(95 * s)
    draw.ellipse([
        main_cx - main_rx, main_cy - main_ry,
        main_cx + main_rx, main_cy + main_ry
    ], fill=PAW_COLOR)

    # 指球（左上）
    draw_circle(draw, int(148 * s), int(210 * s), int(52 * s), PAW_COLOR)
    # 指球（右上）
    draw_circle(draw, int(364 * s), int(210 * s), int(52 * s), PAW_COLOR)
    # 指球（左）
    draw_circle(draw, int(176 * s), int(268 * s), int(42 * s), PAW_COLOR)
    # 指球（右）
    draw_circle(draw, int(336 * s), int(268 * s), int(42 * s), PAW_COLOR)

    # ハイライト（メイン肉球の上部を明るく）
    hl_color = (232, 196, 160, 120)
    hl = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hl_draw = ImageDraw.Draw(hl)
    hl_cx, hl_cy = int(256 * s), int(295 * s)
    hl_rx, hl_ry = int(55 * s), int(45 * s)
    hl_draw.ellipse([
        hl_cx - hl_rx, hl_cy - hl_ry,
        hl_cx + hl_rx, hl_cy + hl_ry
    ], fill=hl_color)
    img = Image.alpha_composite(img, hl)

    return img

def main():
    out_dir = "web/icons"
    os.makedirs(out_dir, exist_ok=True)

    # 各サイズを生成
    sizes = {
        "Icon-512.png":          512,
        "Icon-192.png":          192,
        "Icon-maskable-512.png": 512,
        "Icon-maskable-192.png": 192,
        "apple-touch-icon.png":  180,
        "favicon.png":            32,
    }

    base = draw_paw(512)

    for filename, size in sizes.items():
        resized = base.resize((size, size), Image.LANCZOS)
        rgb = Image.new("RGB", (size, size), BG_COLOR)
        rgb.paste(resized, mask=resized.split()[3])
        path = os.path.join(out_dir, filename)
        rgb.save(path, "PNG", optimize=True)
        print(f"OK {path} ({size}x{size})")

    # favicon.icoも生成
    favicon = base.resize((32, 32), Image.LANCZOS)
    favicon_rgb = Image.new("RGB", (32, 32), BG_COLOR)
    favicon_rgb.paste(favicon, mask=favicon.split()[3])
    favicon_rgb.save("web/favicon.png", "PNG")
    print("OK web/favicon.png (32x32)")

    print("\nIcon generation complete!")

if __name__ == "__main__":
    main()
