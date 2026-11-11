#!/usr/bin/env python3
"""Render the first Instagram reel (1080x1920, 30 fps) with Gujarati voiceover.

  python3 marketing/first-reel-5-nov/make_reel.py            # -> reel.mp4
  python3 marketing/first-reel-5-nov/make_reel.py --still 1,8,15 /tmp/out

Inputs in this folder: vo/1..7.wav (voice lines, see voiceover.txt) and
clips/calculator.mp4, clips/bargain.mp4, clips/quote.mp4 (adb screenrecord).
Needs Pillow (raqm), Noto Sans Gujarati, gst-launch-1.0 (x264enc, avdec_h264,
voaacenc, mp4mux).
"""
import array, math, os, subprocess, sys, wave
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
W, H, FPS, RATE = 1080, 1920, 30, 48000

NAVY_A, NAVY_B = (30, 63, 112), (8, 24, 52)
GOLD, CREAM, SOFT = (212, 167, 44), (247, 239, 220), (178, 198, 228)
RED, GREEN = (222, 64, 52), (52, 178, 96)
FD = "/usr/share/fonts/truetype/noto/"


def font(name, size):
    return ImageFont.truetype(FD + name, size, layout_engine=ImageFont.Layout.RAQM)


GU_B = lambda s: font("NotoSansGujarati-Bold.ttf", s)
GU_R = lambda s: font("NotoSansGujarati-Regular.ttf", s)
EN_B = lambda s: font("NotoSans-Bold.ttf", s)


def clamp(t): return max(0.0, min(1.0, t))
def ease_out(t): t = clamp(t); return 1 - (1 - t) ** 3
def ease_back(t):
    t = clamp(t); c = 1.7
    return 1 + (c + 1) * (t - 1) ** 3 + c * (t - 1) ** 2


def _runs(txt):
    """Split into (is_latin, text) runs: the Gujarati font has no Latin letters."""
    out = []
    for ch in txt:
        lat = ("A" <= ch <= "Z") or ("a" <= ch <= "z")
        if out and (lat == out[-1][0] or ch == " "):
            out[-1][1] += ch
        else:
            out.append([lat, ch])
    return out


def text_img(txt, f, fill, stroke=0):
    path = f.path
    latin = font(("NotoSans-Bold.ttf" if "Bold" in path else "NotoSans-Regular.ttf"), f.size) \
        if "Gujarati" in path else f
    parts = []
    for lat, run in _runs(txt):
        ff = latin if lat else f
        l, t, r, b = ff.getbbox(run, stroke_width=stroke, anchor="ls")
        parts.append((ff, run, l, t, r, b))
    asc = -min(p[3] for p in parts); desc = max(p[5] for p in parts)
    w = sum(p[4] - p[2] for p in parts) + 12 + 2 * len(parts)
    im = Image.new("RGBA", (w, asc + desc + 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(im); x = 6
    for ff, run, l, t, r, b in parts:
        d.text((x - l, 6 + asc), run, font=ff, fill=fill, anchor="ls",
               stroke_width=stroke, stroke_fill=(5, 14, 32))
        x += r - l + 2
    return im


def paste(frame, im, x, y, k=1.0):
    if k <= 0.01: return
    if k < 1:
        im = im.copy(); im.putalpha(im.getchannel("A").point(lambda v: int(v * k)))
    frame.alpha_composite(im, (int(x), int(y)))


def center(frame, im, cy, k=1.0, dy=0):
    paste(frame, im, W / 2 - im.width / 2, cy - im.height / 2 + dy, k)


# ---------------- audio / timeline ----------------
def load_wav(path):
    w = wave.open(path)
    assert w.getframerate() == RATE and w.getnchannels() == 1
    a = array.array("h", w.readframes(w.getnframes()))
    loud = [i for i in range(0, len(a), 120) if abs(a[i]) > 500]
    s, e = max(0, loud[0] - RATE // 20), min(len(a), loud[-1] + RATE // 6)
    return a[s:e]


VO = [load_wav(f"{HERE}/vo/{i}.wav") for i in range(1, 8)]
GAP = 0.35            # silence after each line
LEAD = 0.4            # silence before the first line
TAIL = 1.6            # end card hold after last line
starts, t = [], LEAD
for v in VO:
    starts.append(t); t += len(v) / RATE + GAP
TOTAL = t - GAP + TAIL
# Scene i runs from the start of its line (scene 0 from 0) to the next start.
SCENE = [(0 if i == 0 else starts[i] - 0.15, starts[i + 1] - 0.15 if i < 6 else TOTAL) for i in range(7)]
SPEECH = [(starts[i], starts[i] + len(VO[i]) / RATE) for i in range(7)]


def write_audio(path):
    out = array.array("h", bytes(2 * int(TOTAL * RATE)))
    for s, v in zip(starts, VO):
        o = int(s * RATE); out[o:o + len(v)] = v
    w = wave.open(path, "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
    w.writeframes(out.tobytes()); w.close()


# ---------------- captions (big subtitles, many watch muted) ----------------
CAPTIONS = [
    ["વેપારી ભાવ ઓછો કરાવે…", "ને નફો તો ગયો?"],
    ["કાગળ ને કેલ્ક્યુલેટર છોડો!", "આવી ગયું કોસ્ટિંગ માસ્ટર"],
    ["ડાયમંડ, જરકન, સગડી, મજૂરી…", "૧૦૦ નો ભાવ ને સંખ્યા લખો", "ભાવ ૧ મિનિટમાં તૈયાર!"],
    ["વેપારી ઓછો ભાવ કહે?", "તરત જુઓ: નફો કે નુકસાન"],
    ["નામ ને લોગો સાથે", "કોસ્ટિંગ શીટ સીધી WhatsApp પર", "વટાવ-નફો વેપારીને દેખાય નહીં"],
    ["ઇન્ટરનેટ વગર · બેકઅપ ફ્રી", "બધું ગુજરાતીમાં"],
    ["સંપૂર્ણ મફત!", "Play Store પર શોધો: Costing Master"],
]
CAP_IMG = [[text_img(c, GU_B(58), (255, 255, 255), stroke=5) for c in caps] for caps in CAPTIONS]


def draw_caption(f, i, t, cy):
    s, e = SPEECH[i]
    caps = CAP_IMG[i]
    n = len(caps)
    k = clamp((t - s) / max(0.01, e - s))
    idx = min(n - 1, int(k * n)) if t >= s else 0
    seg_start = s + (e - s) * idx / n
    pop = ease_back((t - seg_start) / 0.25)
    im = caps[idx]
    if pop < 0.98:
        z = 0.85 + 0.15 * pop
        im = im.resize((max(1, int(im.width * z)), max(1, int(im.height * z))), Image.BILINEAR)
    pad = 26
    box = Image.new("RGBA", (im.width + pad * 2, im.height + pad), (0, 0, 0, 0))
    ImageDraw.Draw(box).rounded_rectangle((0, 0, box.width - 1, box.height - 1), 28, fill=(5, 14, 32, 170))
    box.alpha_composite(im, (pad, pad // 2))
    center(f, box, cy, min(1, (t - SCENE[i][0]) / 0.2))


# ---------------- static art ----------------
def background():
    top = Image.new("RGB", (1, H))
    for y in range(H):
        k = y / H
        top.putpixel((0, y), tuple(int(NAVY_A[c] + (NAVY_B[c] - NAVY_A[c]) * k) for c in range(3)))
    return top.resize((W, H)).convert("RGBA")


def glow(r, color, a):
    g = Image.new("RGBA", (r * 2, r * 2), (0, 0, 0, 0))
    ImageDraw.Draw(g).ellipse((r // 2, r // 2, r * 3 // 2, r * 3 // 2), fill=color + (a,))
    return g.filter(ImageFilter.GaussianBlur(r // 3))


BG = background()
GLOW = glow(520, (90, 140, 220), 70)
ICON = Image.open(ROOT + "/assets/icon/icon.png").convert("RGBA")


def icon(size):
    im = ICON.resize((size, size), Image.LANCZOS)
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size - 1, size - 1), int(size * 0.22), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0)); out.paste(im, (0, 0), m)
    return out


ICON_BIG = icon(360)


def notebook():
    w, h = 640, 760
    im = Image.new("RGBA", (w + 40, h + 40), (0, 0, 0, 0))
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((20, 32, w + 20, h + 32), 24, fill=(0, 0, 0, 140))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(14)))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((20, 20, w + 20, h + 20), 24, fill=(250, 246, 232))
    for y in range(120, h, 62):
        d.line((40, y + 20, w, y + 20), fill=(170, 196, 230), width=2)
    d.line((110, 20, 110, h + 20), fill=(230, 120, 120), width=3)
    hand = GU_R(44)
    rows = ["ડાયમંડ  40 × 12 = ?", "જરકન  18 × 12 = ?", "સગડી  60 × 1.5 = ?", "મજૂરી  … ?", "વટાવ 2%  ?", "નફો ??"]
    for i, r in enumerate(rows):
        d.text((130, 88 + i * 62 + 20), r, font=hand, fill=(40, 52, 90))
    return im


NOTE = notebook()


def red_x(size):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im); m = size * 0.12
    d.line((m, m, size - m, size - m), fill=RED + (255,), width=int(size * 0.13))
    d.line((size - m, m, m, size - m), fill=RED + (255,), width=int(size * 0.13))
    return im


XMARK = red_x(420)


def bubble(lines):
    ims = [text_img(l, GU_B(86), (30, 30, 40)) for l in lines]
    w = max(i.width for i in ims) + 100; h = sum(i.height for i in ims) + 70
    im = Image.new("RGBA", (w, h + 50), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, w, h), 46, fill=(255, 255, 255))
    d.polygon([(w * 0.22, h - 2), (w * 0.34, h - 2), (w * 0.18, h + 48)], fill=(255, 255, 255))
    y = 35
    for i in ims:
        im.alpha_composite(i, ((w - i.width) // 2, y)); y += i.height
    return im


BUBBLE = bubble(["વેપારી:", "“ભાવ ઓછો કરો!”"])


def phone_frame(sw, sh_):
    bez, rad = 18, 64
    pad = 50
    pw, ph = sw + bez * 2, sh_ + bez * 2
    im = Image.new("RGBA", (pw + pad * 2, ph + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((pad, pad + 24, pad + pw, pad + ph + 24), rad, fill=(0, 0, 0, 160))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(24)))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((pad, pad, pad + pw, pad + ph), rad, fill=(18, 20, 26, 255))
    d.rounded_rectangle((pad, pad, pad + pw, pad + ph), rad, outline=(70, 78, 96, 255), width=3)
    mask = Image.new("L", (sw, sh_), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh_ - 1), rad - bez, fill=255)
    return im, mask, pad + bez


# ---------------- phone recordings ----------------
CLIP_W, CLIP_H = 584, 1302  # width multiple of 4 (GStreamer RGB row stride)
FRAME_IM, FRAME_MASK, FRAME_OFF = phone_frame(CLIP_W, CLIP_H)


class Clip:
    """Streams decoded frames of an mp4 at 30 fps; frame(t) maps scene time to clip time."""

    def __init__(self, path, scene_len, trim=(0.0, None)):
        self.path, self.scene_len, self.trim = path, scene_len, trim
        self.p = None; self.idx = -1; self.cur = None
        self.dur = 1.0 if not os.path.exists(path) else float(subprocess.run(
            ["gst-discoverer-1.0", path], capture_output=True, text=True).stdout
            .split("Duration: ")[1].split()[0].split(":")[-1]) + 60 * int(
            subprocess.run(["gst-discoverer-1.0", path], capture_output=True, text=True).stdout
            .split("Duration: ")[1].split(":")[1])

    def open(self):
        self.p = subprocess.Popen(
            ["gst-launch-1.0", "-q", "filesrc", f"location={self.path}", "!", "qtdemux", "!", "h264parse", "!",
             "avdec_h264", "!", "videorate", "!", "videoscale", "!", "videoconvert", "!",
             f"video/x-raw,format=RGB,width={CLIP_W},height={CLIP_H},framerate={FPS}/1", "!", "fdsink", "fd=1"],
            stdout=subprocess.PIPE)

    def frame(self, t):
        if not os.path.exists(self.path): return Image.new("RGB", (CLIP_W, CLIP_H), (240, 240, 240))
        if self.p is None: self.open()
        a, b = self.trim[0], self.trim[1] or self.dur
        want = int((a + (b - a) * clamp(t / self.scene_len)) * FPS)
        size = CLIP_W * CLIP_H * 3
        while self.idx < want:
            buf = self.p.stdout.read(size)
            if len(buf) < size: break
            self.cur = buf; self.idx += 1
        if self.cur is None: return Image.new("RGB", (CLIP_W, CLIP_H), (240, 240, 240))
        return Image.frombytes("RGB", (CLIP_W, CLIP_H), self.cur)


def phone_with(clip_img):
    im = FRAME_IM.copy()
    im.paste(clip_img, (FRAME_OFF, FRAME_OFF), FRAME_MASK)
    return im


# ---------------- scenes ----------------
TITLES = {2: "💎 ભાવ ૧ મિનિટમાં", 3: "🤝 ભાવ-તાલ", 4: "📲 WhatsApp પર કોસ્ટિંગ"}
TITLE_IMG = {k: text_img(v.split(" ", 1)[1], GU_B(80), GOLD) for k, v in TITLES.items()}
CLIPS = {}


def scene_hook(f, t):
    k = ease_back(t / 0.45)
    shake = 10 * math.sin(t * 38) * max(0, 1 - t / 1.2)
    b = BUBBLE.resize((max(1, int(BUBBLE.width * k)), max(1, int(BUBBLE.height * k))), Image.BILINEAR)
    paste(f, b, W / 2 - b.width / 2 + shake, 260)
    kn = ease_out((t - 0.5) / 0.6)
    paste(f, NOTE, W / 2 - NOTE.width / 2, 700 + 120 * (1 - kn), kn)
    kx = ease_back((t - 2.0) / 0.35)
    if kx > 0.02:
        x = XMARK.resize((max(1, int(420 * kx)),) * 2, Image.BILINEAR)
        paste(f, x, W / 2 - x.width / 2, 1100 - x.height / 2)


T_NAME = text_img("Costing Master", EN_B(104), CREAM)
T_NAME_GU = text_img("કોસ્ટિંગ માસ્ટર", GU_B(78), GOLD)


def scene_logo(f, t):
    # notebook flies away first
    kn = ease_out(t / 0.5)
    paste(f, NOTE, W / 2 - NOTE.width / 2 - 900 * kn, 700, 1 - kn)
    s = ease_back((t - 0.35) / 0.6)
    if s > 0.02:
        ic = ICON_BIG.resize((max(1, int(360 * s)),) * 2, Image.LANCZOS)
        center(f, ic, 640)
    k = ease_out((t - 0.8) / 0.5); center(f, T_NAME, 950, k, 40 * (1 - k))
    k = ease_out((t - 1.1) / 0.5); center(f, T_NAME_GU, 1080, k, 40 * (1 - k))


def scene_phone(f, i, t):
    d = SCENE[i][1] - SCENE[i][0]
    k = ease_out(t / 0.5)
    ko = 1 - ease_out((t - (d - 0.3)) / 0.3)
    center(f, TITLE_IMG[i], 170, k * ko, -30 * (1 - k))
    ph = phone_with(CLIPS[i].frame(t))
    paste(f, ph, W / 2 - ph.width / 2, 260 + 200 * (1 - k), k * ko)


BADGES = [("📴", "ઇન્ટરનેટ વગર ચાલે"), ("☁", "Google બેકઅપ ફ્રી"), ("ગુ", "બધું ગુજરાતીમાં")]


def badge(txt):
    t = text_img(txt, GU_B(66), CREAM)
    w, h = 820, 170
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, w - 1, h - 1), 40, fill=(255, 255, 255, 28), outline=GOLD + (255,), width=4)
    d.ellipse((34, 35, 134, 135), fill=GOLD + (255,))
    d.line([(60, 86), (78, 106), (110, 66)], fill=NAVY_B, width=12, joint="curve")
    im.alpha_composite(t, (170, (h - t.height) // 2))
    return im


BADGE_IMG = [badge(b) for _, b in BADGES]


def scene_badges(f, t):
    for n, b in enumerate(BADGE_IMG):
        k = ease_back((t - 0.15 - n * 0.55) / 0.5)
        paste(f, b, W / 2 - b.width / 2 - 600 * (1 - k), 480 + n * 230, clamp(k))


T_FREE = text_img("સંપૂર્ણ મફત", GU_B(120), GOLD)
T_SEARCH = text_img("Play Store પર શોધો", GU_B(64), CREAM)
T_PLAY = text_img("Costing Master", EN_B(70), NAVY_B)


def scene_end(f, t):
    s = ease_back(t / 0.6)
    if s > 0.02:
        ic = ICON_BIG.resize((max(1, int(300 * s)),) * 2, Image.LANCZOS)
        center(f, ic, 460)
    k = ease_out((t - 0.4) / 0.5); center(f, T_FREE, 760, k, 40 * (1 - k))
    k = ease_out((t - 0.8) / 0.5); center(f, T_SEARCH, 920, k, 40 * (1 - k))
    k = ease_out((t - 1.1) / 0.5)
    if k > 0:
        pulse = 1 + 0.03 * math.sin(max(0, t - 1.6) * 5)
        bw, bh = (T_PLAY.width + 220) * pulse, (T_PLAY.height + 70) * pulse
        cx, cy = W / 2, 1090
        d = ImageDraw.Draw(f)
        d.rounded_rectangle((cx - bw / 2, cy - bh / 2, cx + bw / 2, cy + bh / 2), bh / 2, fill=GOLD + (int(255 * k),))
        d.polygon([(cx - bw / 2 + 50, cy - 30), (cx - bw / 2 + 50, cy + 30), (cx - bw / 2 + 100, cy)],
                  fill=NAVY_B + (int(255 * k),))
        paste(f, T_PLAY, cx - T_PLAY.width / 2 + 30, cy - T_PLAY.height / 2, k)


def frame(n):
    t = n / FPS
    f = BG.copy()
    f.alpha_composite(GLOW, (int(-400 + 140 * math.sin(t * 0.4)), int(-300 + 120 * math.cos(t * 0.3))))
    f.alpha_composite(GLOW, (int(300 + 120 * math.cos(t * 0.35)), int(1000 + 100 * math.sin(t * 0.3))))
    i = next(j for j, (s, e) in enumerate(SCENE) if s <= t < e or j == 6)
    st = t - SCENE[i][0]
    if i == 0: scene_hook(f, st)
    elif i == 1: scene_logo(f, st)
    elif i in (2, 3, 4): scene_phone(f, i, st)
    elif i == 5: scene_badges(f, st)
    else: scene_end(f, st)
    cap_y = {0: 1640, 1: 1450, 2: 1700, 3: 1700, 4: 1700, 5: 1450, 6: 1500}[i]
    if i not in (5, 6):  # badges / end card already show the words
        draw_caption(f, i, t, cap_y)
    return f.convert("RGB")


def setup_clips(trims):
    for i, name in ((2, "calculator"), (3, "bargain"), (4, "quote")):
        CLIPS[i] = Clip(f"{HERE}/clips/{name}.mp4", SCENE[i][1] - SCENE[i][0], trims.get(name, (0.0, None)))


TRIMS = {"calculator": (0.4, 15.3), "bargain": (0.6, 8.6), "quote": (0.6, 9.3)}  # seconds inside each recording


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else f"{HERE}/reel.mp4"
    setup_clips(TRIMS)
    wav, vid = f"{HERE}/.voice.wav", f"{HERE}/.video.mp4"
    write_audio(wav)
    total = int(TOTAL * FPS)
    p = subprocess.Popen(["gst-launch-1.0", "-q", "fdsrc", "fd=0", "!",
                          "rawvideoparse", f"width={W}", f"height={H}", "format=rgb", f"framerate={FPS}/1", "!",
                          "videoconvert", "!", "video/x-raw,format=I420", "!",
                          "x264enc", "speed-preset=slow", "bitrate=12000", "key-int-max=60", "!",
                          "video/x-h264,profile=high", "!", "h264parse", "!", "mp4mux", "!",
                          "filesink", f"location={vid}"], stdin=subprocess.PIPE)
    for n in range(total):
        p.stdin.write(frame(n).tobytes())
        if n % 150 == 0: print(f"{n}/{total}", flush=True)
    p.stdin.close(); p.wait()
    subprocess.run(["gst-launch-1.0", "-q", "mp4mux", "name=m", "faststart=true", "!", "filesink", f"location={out}",
                    "filesrc", f"location={vid}", "!", "qtdemux", "!", "h264parse", "!", "queue", "!", "m.",
                    "filesrc", f"location={wav}", "!", "wavparse", "!", "audioconvert", "!", "audioresample", "!",
                    "audio/x-raw,rate=48000,channels=2", "!", "voaacenc", "bitrate=160000", "!", "queue", "!", "m."],
                   check=True)
    os.remove(wav); os.remove(vid)
    print(f"wrote {out} ({TOTAL:.1f}s)")


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--still":
        setup_clips(TRIMS)
        os.makedirs(sys.argv[3], exist_ok=True)
        for s in sys.argv[2].split(","):
            frame(int(float(s) * FPS)).save(f"{sys.argv[3]}/still_{s}.png")
    else:
        main()
