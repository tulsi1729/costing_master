#!/usr/bin/env python3
"""Render a 30 s 1920x1080 promo video (YouTube / Play listing) from store screenshots.

  python3 tool/promo_video.py [out.mp4]

Needs Pillow (with raqm for Gujarati shaping), Noto Sans + Noto Sans Gujarati
fonts and gst-launch-1.0 with x264enc. Frames are piped straight into GStreamer.
"""
import math, subprocess, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H, FPS = 1920, 1080, 30
ROOT = __file__.rsplit("/tool/", 1)[0]
OUT = sys.argv[1] if len(sys.argv) > 1 else ROOT + "/screenshots/promo_video.mp4"

NAVY_A, NAVY_B = (30, 63, 112), (8, 24, 52)
GOLD, CREAM, SOFT = (212, 167, 44), (247, 239, 220), (178, 198, 228)
FD = "/usr/share/fonts/truetype/noto/"


def font(name, size):
    return ImageFont.truetype(FD + name, size, layout_engine=ImageFont.Layout.RAQM)


GU_B = lambda s: font("NotoSansGujarati-Bold.ttf", s)
GU_R = lambda s: font("NotoSansGujarati-Regular.ttf", s)
EN_B = lambda s: font("NotoSans-Bold.ttf", s)
EN_R = lambda s: font("NotoSans-Regular.ttf", s)


def ease_out(t):  # cubic
    t = max(0.0, min(1.0, t)); return 1 - (1 - t) ** 3


def ease_back(t):
    t = max(0.0, min(1.0, t)); c = 1.6
    return 1 + (c + 1) * (t - 1) ** 3 + c * (t - 1) ** 2


def text_img(txt, f, fill):
    l, t, r, b = f.getbbox(txt)
    im = Image.new("RGBA", (r - l + 8, b - t + 8), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((4 - l, 4 - t), txt, font=f, fill=fill)
    return im


def fade(im, k):
    if k >= 1: return im
    im = im.copy(); a = im.getchannel("A").point(lambda v: int(v * max(0, k)))
    im.putalpha(a); return im


def paste(frame, im, x, y, k=1.0):
    if k <= 0.01: return
    frame.alpha_composite(fade(im, k), (int(x), int(y)))


# ---------- static layers ----------
def background():
    bg = Image.new("RGB", (W, H))
    px = bg.load()
    for y in range(H):
        for x in range(0, W, 4):
            t = min(1, (x / W * 0.55 + y / H * 0.45))
            c = tuple(int(NAVY_A[i] + (NAVY_B[i] - NAVY_A[i]) * t) for i in range(3))
            for dx in range(4): px[x + dx, y] = c
    return bg.convert("RGBA")


def glow(r, color, a):
    g = Image.new("RGBA", (r * 2, r * 2), (0, 0, 0, 0))
    ImageDraw.Draw(g).ellipse((r // 2, r // 2, r * 3 // 2, r * 3 // 2), fill=color + (a,))
    return g.filter(ImageFilter.GaussianBlur(r // 3))


def phone(path, h=940):
    shot = Image.open(path).convert("RGBA")
    sw = int(h * shot.width / shot.height)
    shot = shot.resize((sw, h), Image.LANCZOS)
    bez, rad = 16, 58
    pw, ph = sw + bez * 2, h + bez * 2
    m = Image.new("L", (sw, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, sw - 1, h - 1), rad - bez, fill=255)
    pad = 60
    ph_im = Image.new("RGBA", (pw + pad * 2, ph + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", ph_im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((pad, pad + 24, pad + pw, pad + ph + 24), rad, fill=(0, 0, 0, 150))
    ph_im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(26)))
    d = ImageDraw.Draw(ph_im)
    d.rounded_rectangle((pad, pad, pad + pw, pad + ph), rad, fill=(18, 20, 26, 255))
    d.rounded_rectangle((pad, pad, pad + pw, pad + ph), rad, outline=(70, 78, 96, 255), width=3)
    ph_im.paste(shot, (pad + bez, pad + bez), m)
    return ph_im


BG = background()
GLOW_GOLD = glow(420, (120, 170, 240), 45)
GLOW_BLUE = glow(520, (90, 140, 220), 70)
ICON = Image.open(ROOT + "/assets/icon/icon.png").convert("RGBA")


def icon(size):
    im = ICON.resize((size, size), Image.LANCZOS)
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size - 1, size - 1), int(size * 0.22), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0)); out.paste(im, (0, 0), m)
    return out


ICON_BIG, ICON_MID = icon(340), icon(240)

# (start s, end s, screenshot, step, Gujarati lines, English line)
SCENES = [
    (4.0, 9.5, "01_home.png", "01", ["બધા વેપારી અને", "ડિઝાઇન એક જગ્યાએ"], "All your traders & designs in one place"),
    (9.5, 15.0, "03_calculator.png", "02", ["ડાયમંડ ગણો,", "ભાવ તરત તૈયાર"], "Count diamonds – price is ready instantly"),
    (15.0, 20.5, "04_bargain.png", "03", ["વેપારી ઓછો ભાવ કહે?", "નફો તરત જુઓ"], "Bargaining? See your profit before you agree"),
    (20.5, 26.0, "05_quote.png", "04", ["સુંદર ક્વોટ", "WhatsApp પર મોકલો"], "Share a neat quote on WhatsApp or PDF"),
]
SC = []
for s, e, shot, step, gu, en in SCENES:
    SC.append(dict(s=s, e=e, phone=phone(ROOT + "/screenshots/" + shot),
                   step=text_img(step, EN_B(46), GOLD),
                   gu=[text_img(l, GU_B(84), CREAM) for l in gu],
                   en=text_img(en, EN_R(40), SOFT)))

T_TITLE = text_img("Costing Master", EN_B(112), CREAM)
T_TAG = text_img("સાડી એમ્બ્રોઇડરીનો ભાવ, સેકંડોમાં", GU_B(62), CREAM)
T_TAG_EN = text_img("Saree embroidery costing for workshops", EN_R(40), SOFT)
T_OUT_TITLE = text_img("Costing Master", EN_B(96), CREAM)
T_DL = text_img("આજે જ ડાઉનલોડ કરો", GU_B(64), CREAM)
T_PLAY = text_img("Get it on Google Play", EN_B(44), NAVY_B)


def dotted(parts, f, fill, gap=56):
    ims = [text_img(x, f, fill) for x in parts]
    h = max(i.height for i in ims)
    out = Image.new("RGBA", (sum(i.width for i in ims) + gap * (len(ims) - 1), h), (0, 0, 0, 0))
    x = 0
    for n, i in enumerate(ims):
        out.alpha_composite(i, (x, (h - i.height) // 2)); x += i.width
        if n < len(ims) - 1:
            ImageDraw.Draw(out).ellipse((x + gap / 2 - 5, h / 2 - 5, x + gap / 2 + 5, h / 2 + 5), fill=fill)
            x += gap
    return out


T_OFF = dotted(["ભાવ ગણતરી", "ભાવ-તાલ", "ક્વોટ", "ઓફલાઇન પણ ચાલે"], GU_R(40), GOLD)


def bar(frame, cx, y, w, k):
    if k <= 0: return
    d = ImageDraw.Draw(frame); ww = w * k
    d.rounded_rectangle((cx - ww / 2, y, cx + ww / 2, y + 8), 4, fill=GOLD + (255,))


def draw_intro(f, t):
    k_out = 1 - ease_out((t - 3.6) / 0.4)
    s = ease_back(t / 0.9)
    if s > 0.02:
        ic = ICON_BIG.resize((max(1, int(340 * s)),) * 2, Image.LANCZOS)
        paste(f, ic, W / 2 - ic.width / 2, 300 - ic.height / 2, min(1, t / 0.3) * k_out)
    k = ease_out((t - 0.6) / 0.6) * k_out
    paste(f, T_TITLE, W / 2 - T_TITLE.width / 2, 520 + 30 * (1 - k), k)
    bar(f, W / 2, 680, 260, ease_out((t - 1.0) / 0.6) * k_out)
    k = ease_out((t - 1.2) / 0.6) * k_out
    paste(f, T_TAG, W / 2 - T_TAG.width / 2, 730 + 30 * (1 - k), k)
    k = ease_out((t - 1.6) / 0.6) * k_out
    paste(f, T_TAG_EN, W / 2 - T_TAG_EN.width / 2, 840, k)


def draw_scene(f, sc, t):
    d = sc["e"] - sc["s"]
    k_out = 1 - ease_out((t - (d - 0.45)) / 0.45)
    # phone
    k = ease_out(t / 0.7)
    ph = sc["phone"]
    z = 1.0 + 0.03 * (t / d)
    if abs(z - 1) > 0.002:
        ph = ph.resize((int(ph.width * z), int(ph.height * z)), Image.BILINEAR)
    y = H / 2 - ph.height / 2 + 140 * (1 - k) - 40 * (1 - k_out)
    paste(f, ph, 1370 - ph.width / 2, y, k * k_out)
    # text
    x0, y0 = 150, 330
    k = ease_out((t - 0.2) / 0.5) * k_out
    paste(f, sc["step"], x0, y0, k)
    ImageDraw.Draw(f).rounded_rectangle((x0 + sc["step"].width + 14, y0 + 26,
                                         x0 + sc["step"].width + 14 + 90 * k, y0 + 32), 3, fill=GOLD + (int(255 * k),))
    yy = y0 + 90
    for i, li in enumerate(sc["gu"]):
        k = ease_out((t - 0.35 - 0.15 * i) / 0.55) * k_out
        paste(f, li, x0 - 50 * (1 - k), yy, k); yy += li.height + 18
    k = ease_out((t - 0.8) / 0.6) * k_out
    paste(f, sc["en"], x0 - 50 * (1 - k), yy + 24, k)


def draw_outro(f, t):
    s = ease_back(t / 0.8)
    if s > 0.02:
        ic = ICON_MID.resize((max(1, int(240 * s)),) * 2, Image.LANCZOS)
        paste(f, ic, W / 2 - ic.width / 2, 250 - ic.height / 2, min(1, t / 0.3))
    k = ease_out((t - 0.4) / 0.6)
    paste(f, T_OUT_TITLE, W / 2 - T_OUT_TITLE.width / 2, 400 + 30 * (1 - k), k)
    k = ease_out((t - 0.8) / 0.6)
    paste(f, T_DL, W / 2 - T_DL.width / 2, 545 + 30 * (1 - k), k)
    k = ease_out((t - 1.2) / 0.6)
    if k > 0:
        pw, phh = T_PLAY.width + 90, T_PLAY.height + 44
        pulse = 1 + 0.025 * math.sin(max(0, t - 1.8) * 4)
        pw2, ph2 = pw * pulse, phh * pulse
        cx, cy = W / 2, 720
        ImageDraw.Draw(f).rounded_rectangle((cx - pw2 / 2, cy - ph2 / 2, cx + pw2 / 2, cy + ph2 / 2), ph2 / 2,
                                            fill=GOLD + (int(255 * k),))
        paste(f, T_PLAY, cx - T_PLAY.width / 2, cy - T_PLAY.height / 2, k)
    k = ease_out((t - 1.7) / 0.6)
    paste(f, T_OFF, W / 2 - T_OFF.width / 2, 830, k)


def frame(i):
    t = i / FPS
    f = BG.copy()
    f.alpha_composite(GLOW_BLUE, (int(-300 + 120 * math.sin(t * 0.3)), int(-420 + 60 * math.cos(t * 0.25))))
    f.alpha_composite(GLOW_GOLD, (int(1250 + 100 * math.cos(t * 0.35)), int(420 + 80 * math.sin(t * 0.3))))
    if t < 4.0:
        draw_intro(f, t)
    elif t >= 26.0:
        draw_outro(f, t - 26.0)
    else:
        for sc in SC:
            if sc["s"] <= t < sc["e"]:
                draw_scene(f, sc, t - sc["s"])
    return f.convert("RGB")


def main():
    total = 30 * FPS
    cmd = ["gst-launch-1.0", "-q", "fdsrc", "fd=0", "!",
           "rawvideoparse", f"width={W}", f"height={H}", "format=rgb", f"framerate={FPS}/1", "!",
           "videoconvert", "!", "video/x-raw,format=I420", "!",
           "x264enc", "speed-preset=slow", "bitrate=10000", "key-int-max=60", "!",
           "video/x-h264,profile=high", "!", "h264parse", "!", "mp4mux", "faststart=true", "!",
           "filesink", f"location={OUT}"]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    for i in range(total):
        p.stdin.write(frame(i).tobytes())
        if i % 150 == 0: print(f"{i}/{total}", flush=True)
    p.stdin.close(); p.wait()
    print("wrote", OUT)


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--still":  # preview: --still t1,t2,... dir
        for t in sys.argv[2].split(","):
            frame(int(float(t) * FPS)).save(f"{sys.argv[3]}/still_{t}.png")
    else:
        main()
