"""KiSA ilova ikonkasini generatsiya qiladi — teal-yashil gradient + oq 'KiSA' matni.
Ilova ichidagi KisaLogo widgeti bilan bir xil ko'rinishda.
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = os.path.join(ROOT, "assets", "icon")
FONT_DIR = os.path.join(ROOT, "assets", "fonts")
SIZE = 1024

# Brend gradient ranglari (app_theme.dart kGradient bilan mos)
TOP_LEFT = (21, 115, 127)       # #15737F (teal, past-chap)
BOTTOM_RIGHT = (47, 161, 105)   # #2FA169 (yashil, yuqori-o'ng)
BRAND = (28, 157, 103)          # #1C9D67


def gradient(size, c1, c2):
    base = Image.new("RGB", (size, size), c1)
    top = Image.new("RGB", (size, size), c2)
    mask = Image.new("L", (size, size))
    md = mask.load()
    for y in range(size):
        for x in range(size):
            # diagonal: 0 (top-left) -> 1 (bottom-right)
            md[x, y] = int(255 * ((x + y) / (2 * (size - 1))))
    base.paste(top, (0, 0), mask)
    return base


def draw_text(draw, size, alpha=255):
    ki_font = ImageFont.truetype(os.path.join(FONT_DIR, "Poppins-Regular.ttf"), int(size * 0.30))
    sa_font = ImageFont.truetype(os.path.join(FONT_DIR, "Poppins-ExtraBold.ttf"), int(size * 0.30))
    ki, sa = "Ki", "SA"

    kb = draw.textbbox((0, 0), ki, font=ki_font)
    sb = draw.textbbox((0, 0), sa, font=sa_font)
    kw, kh = kb[2] - kb[0], kb[3] - kb[1]
    sw, sh = sb[2] - sb[0], sb[3] - sb[1]
    total = kw + sw
    h = max(kh, sh)
    x = (size - total) / 2
    y = (size - h) / 2

    col = (255, 255, 255, alpha)
    draw.text((x - kb[0], y - kb[1]), ki, font=ki_font, fill=col)
    draw.text((x + kw - sb[0], y - sb[1]), sa, font=sa_font, fill=col)


def main():
    os.makedirs(ICON_DIR, exist_ok=True)

    # 1) To'liq ikonka (iOS / web / legacy android) — gradient + matn, alfasiz
    icon = gradient(SIZE, TOP_LEFT, BOTTOM_RIGHT).convert("RGBA")
    draw_text(ImageDraw.Draw(icon), SIZE)
    icon.convert("RGB").save(os.path.join(ICON_DIR, "kisa_icon.png"))

    # 2) Adaptiv old qatlam (Android) — shaffof fon, faqat matn, xavfsiz zonada
    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    # matn adaptiv ikonkada ~66% markazda qolishi kerak, shuning uchun kichikroq tuvalda chizamiz
    inner = Image.new("RGBA", (int(SIZE * 0.66), int(SIZE * 0.66)), (0, 0, 0, 0))
    draw_text(ImageDraw.Draw(inner), inner.width)
    fg.paste(inner, ((SIZE - inner.width) // 2, (SIZE - inner.height) // 2), inner)
    fg.save(os.path.join(ICON_DIR, "kisa_icon_fg.png"))

    print("Generated:", os.listdir(ICON_DIR))


if __name__ == "__main__":
    main()
