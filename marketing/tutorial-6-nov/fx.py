"""Text + compositing helpers (copied from reel v2)."""
import array, json, math, os, subprocess, sys, wave
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


NAVY_A, NAVY_B = (30, 63, 112), (8, 24, 52)
GOLD, GOLD_HI, CREAM = (212, 167, 44), (240, 205, 110), (247, 239, 220)
INK = (22, 28, 44)
RED, GREEN = (214, 58, 48), (40, 160, 90)
FD = "/usr/share/fonts/truetype/noto/"


# ======================= text =======================
def font(name, size):
    return ImageFont.truetype(FD + name, size, layout_engine=ImageFont.Layout.RAQM)


GU_B = lambda s: font("NotoSansGujarati-Bold.ttf", s)
GU_R = lambda s: font("NotoSansGujarati-Regular.ttf", s)
EN_B = lambda s: font("NotoSans-Bold.ttf", s)
EMOJI = ImageFont.truetype(FD + "NotoColorEmoji.ttf", 109)


def _kind(ch):
    o = ord(ch)
    if o >= 0x1F000 or 0x2600 <= o <= 0x27BF or o in (0x2B06, 0x23E9, 0x23EA, 0xFE0F):
        return "emoji"
    if 0x0A80 <= o <= 0x0AFF or ch in " ,.?!-–'\"()":
        return "gu"
    return "latin"


def _runs(txt):
    out = []
    for ch in txt:
        k = _kind(ch)
        if out and (k == out[-1][0] or (ch == " " and out[-1][0] != "emoji")):
            out[-1][1] += ch
        else:
            out.append([k, ch])
    return out


def text_img(txt, f, fill, stroke=0, stroke_fill=(5, 14, 32)):
    """Mixed Gujarati / Latin / colour-emoji text on a transparent image."""
    latin = font("NotoSans-Bold.ttf" if "Bold" in f.path else "NotoSans-Regular.ttf", f.size)
    parts = []
    for k, run in _runs(txt):
        if k == "emoji":
            for ch in run:
                if ch == "️": continue
                e = Image.new("RGBA", (140, 140), (0, 0, 0, 0))
                ImageDraw.Draw(e).text((4, 4), ch, font=EMOJI, embedded_color=True)
                e = e.crop(e.getbbox() or (0, 0, 1, 1))
                s = f.size * 1.05 / 109
                e = e.resize((max(1, int(e.width * s)), max(1, int(e.height * s))), Image.LANCZOS)
                parts.append(("img", e))
            continue
        ff = latin if k == "latin" else f
        l, t, r, b = ff.getbbox(run, stroke_width=stroke, anchor="ls")
        parts.append(("txt", (ff, run, l, t, r, b)))
    asc = int(f.size * 1.05); desc = int(f.size * 0.45)
    for kind, p in parts:
        if kind == "txt":
            asc = max(asc, -p[3]); desc = max(desc, p[5])
    w = 12 + sum((p.width + 6) if k == "img" else (p[4] - p[2] + 2) for k, p in parts)
    im = Image.new("RGBA", (w, asc + desc + 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(im); x = 6
    for kind, p in parts:
        if kind == "img":
            im.alpha_composite(p, (x + 3, 6 + asc - p.height + int(f.size * 0.12))); x += p.width + 6
        else:
            ff, run, l, t, r, b = p
            d.text((x - l, 6 + asc), run, font=ff, fill=fill, anchor="ls", stroke_width=stroke, stroke_fill=stroke_fill)
            x += r - l + 2
    return im


# ======================= helpers =======================
def clamp(t): return max(0.0, min(1.0, t))
def ease_out(t): t = clamp(t); return 1 - (1 - t) ** 3
def ease_io(t): t = clamp(t); return 3 * t * t - 2 * t * t * t
def ease_back(t):
    t = clamp(t); c = 1.7
    return 1 + (c + 1) * (t - 1) ** 3 + c * (t - 1) ** 2
def lerp(a, b, k): return a + (b - a) * k


def fade(im, k):
    if k >= 0.999: return im
    im = im.copy(); im.putalpha(im.getchannel("A").point(lambda v: int(v * max(0.0, k)))); return im


def paste(frame, im, x, y, k=1.0):
    if k <= 0.01: return
    frame.alpha_composite(fade(im, k), (int(x), int(y)))


def pop_paste(frame, im, cx, cy, t, dur=0.35, k=1.0):
    """Scale-bounce in, centred at (cx, cy); t = time since it appeared."""
    if t < 0: return
    s = ease_back(t / dur)
    if s < 0.03: return
    if abs(s - 1) > 0.01:
        im = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.BILINEAR)
    paste(frame, im, cx - im.width / 2, cy - im.height / 2, min(1, t / 0.12) * k)


def shadowed(layer, blur=18, off=12, alpha=140):
    pad = blur * 2 + off
    out = Image.new("RGBA", (layer.width + pad * 2, layer.height + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", layer.size, (0, 0, 0, 255)); sh.putalpha(layer.getchannel("A").point(lambda v: v * alpha // 255))
    out.alpha_composite(sh, (pad, pad + off)); out = out.filter(ImageFilter.GaussianBlur(blur))
    out.alpha_composite(layer, (pad, pad))
    return out


