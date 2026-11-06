#!/usr/bin/env python3
"""YouTube tutorial (1920x1080, 30 fps): phone recordings + Gujarati voice + karaoke captions.

  python3 marketing/tutorial-6-nov/make_tutorial.py            # -> tutorial.mp4 + chapters in youtube.txt
  python3 marketing/tutorial-6-nov/make_tutorial.py --still 5,30,60,120 DIR   # preview frames (seconds)
  python3 marketing/tutorial-6-nov/make_tutorial.py --thumb    # -> thumbnail.png

Inputs: lines.json + audio/lineN.mp3/.align.json (gen_voice.py), clips/*.mp4 + *.log (phone
screenrecord of the demo build with marks), ../reel-v2-5-nov/audio/music.mp3, assets/icon/icon.png.
"""
import array, json, math, os, re, subprocess, sys, wave
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
from fx import *  # noqa  text_img, GU_B, GU_R, EN_B, ease_*, paste, pop_paste, shadowed, clamp, lerp

W, H, FPS, RATE = 1920, 1080, 30, 48000
NAVY_A, NAVY_B = (24, 52, 98), (6, 18, 42)
GOLD, GOLD_HI, CREAM = (212, 167, 44), (240, 205, 110), (247, 239, 220)
WHITE, DIM = (255, 255, 255), (150, 170, 205)
GREEN, RED = (52, 178, 104), (226, 74, 62)

# phone screen: recordings are 1080x2408; drop status bar + nav bar
CROP_T, CROP_B = 82, 135
SRC_W, SRC_H = 1080, 2408 - CROP_T - CROP_B
PH = 1030; PW = round(SRC_W * PH / SRC_H) // 2 * 2
PX, PY = 1330 - PW // 2, (H - PH) // 2
SC = PH / SRC_H
OFFSET = 0.9          # log time -> video time (screenrecord starts ~1.2 s before t0)


# ======================= audio + timeline =======================
def decode(src, dst):
    if not os.path.exists(dst) or os.path.getmtime(dst) < os.path.getmtime(src):
        subprocess.run(["gst-launch-1.0", "-q", "filesrc", f"location={src}", "!", "decodebin", "!", "audioconvert", "!",
                        "audioresample", "!", f"audio/x-raw,format=S16LE,rate={RATE},channels=1", "!", "wavenc", "!",
                        "filesink", f"location={dst}"], check=True)
    w = wave.open(dst)
    return array.array("h", w.readframes(w.getnframes()))


A = f"{HERE}/audio"; os.makedirs(f"{A}/wav", exist_ok=True)
SPEC = json.load(open(f"{HERE}/lines.json"))
N = len(SPEC)


def load_line(i):
    a = decode(f"{A}/line{i}.mp3", f"{A}/wav/line{i}.wav")
    loud = [j for j in range(0, len(a), 96) if abs(a[j]) > 600]
    s = max(0, loud[0] - RATE // 30); e = min(len(a), loud[-1] + RATE // 6)
    al = json.load(open(f"{A}/line{i}.align.json"))
    words, cur, t0, t1, depth = [], "", None, None, 0
    for ch, cs, ce in zip(al["characters"], al["character_start_times_seconds"], al["character_end_times_seconds"]):
        if ch == "[": depth += 1; continue
        if ch == "]": depth -= 1; continue
        if depth: continue
        if ch == " ":
            if cur.strip(): words.append((cur, t0, t1))
            cur, t0 = "", None; continue
        if t0 is None: t0 = cs
        cur += ch; t1 = ce
    if cur.strip(): words.append((cur, t0, t1))
    off = s / RATE
    return a[s:e], [(w, max(0, x - off), max(0, y - off)) for w, x, y in words]


LINES = [load_line(i) for i in range(N)]
START, t = [], 0.6
for i in range(N):
    START.append(t)
    t += len(LINES[i][0]) / RATE
    if i < N - 1: t += 0.95 if SPEC[i + 1]["sec"] != SPEC[i]["sec"] else 0.4
END = [START[i] + len(LINES[i][0]) / RATE for i in range(N)]
TOTAL = END[-1] + 3.0
WORDS = [[(w, START[i] + a, START[i] + b) for w, a, b in LINES[i][1]] for i in range(N)]
SLOT = [(START[i], START[i + 1] if i < N - 1 else TOTAL) for i in range(N)]  # visual slot per line


def line_at(t):
    for i in range(N - 1, -1, -1):
        if t >= SLOT[i][0] - 0.25: return i
    return 0


# ======================= phone clips =======================
def marks(name):
    m = {}
    for row in open(f"{HERE}/clips/{name}.log"):
        tt, k = row.split(); m.setdefault(k, float(tt) + OFFSET)
    return m


class Clip:
    def __init__(self, name):
        self.path = f"{HERE}/clips/{name}.mp4"; self.p = None; self.idx = -1; self.cur = None
        self.m = marks(name)

    def mark(self, spec):
        m = re.match(r"(\w+)([+-][\d.]+)?$", spec)
        return self.m[m.group(1)] + float(m.group(2) or 0)

    def _open(self):
        if self.p: self.p.kill()
        self.p = subprocess.Popen(
            ["gst-launch-1.0", "-q", "filesrc", f"location={self.path}", "!", "qtdemux", "!", "h264parse", "!", "avdec_h264", "!",
             "videorate", "!", "videocrop", f"top={CROP_T}", f"bottom={CROP_B}", "!", "videoscale", "method=lanczos", "!",
             "videoconvert", "!", f"video/x-raw,format=RGB,width={PW},height={PH},framerate={FPS}/1", "!", "fdsink", "fd=1"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        self.idx = -1; self.cur = None

    def at(self, t):
        want = max(0, int(t * FPS))
        if self.p is None or want < self.idx: self._open()
        size = PW * PH * 3
        while self.idx < want:
            b = self.p.stdout.read(size)
            if len(b) < size: break
            self.cur = b; self.idx += 1
        return Image.frombytes("RGB", (PW, PH), self.cur) if self.cur else Image.new("RGB", (PW, PH), "white")


CLIPS = {}
def clip(name):
    if name not in CLIPS: CLIPS[name] = Clip(name)
    return CLIPS[name]


# per line: (clip, from mark, to mark, highlight boxes in phone px [x0,y0,x1,y1] or None)
SHOTS = {
    2: ("home", "home", "end", None),
    4: ("trader", "tap_add", "saved", None),
    5: ("trader", "saved", "end", None),
    6: ("costing_a", "open_trader", "end", [(84, 289, 377, 661)]),
    7: ("costing_b", "patti", "sagadi", None),
    8: ("costing_b", "sagadi", "labour+20", None),
    9: ("costing_b", "labour+20", "total+1.4", [(0, 2010, 700, 2250)]),
    10: ("costing_c", "vatav_set-2.5", "end", [(0, 2010, 700, 2250)]),
    11: ("bargain", "open-0.5", "p350", [(45, 1919, 1035, 2065)]),
    12: ("bargain", "p350", "p300", None),
    13: ("bargain", "p300", "p340", None),
    14: ("bargain", "p340", "end", None),
    15: ("share", "card", "mine", None),
    16: ("share", "trader", "end", [(398, 2093, 1035, 2239), (45, 2093, 364, 2239), (945, 81, 1080, 216)]),
    17: ("share", "mine", "trader", [(540, 377, 1035, 512)]),
    18: ("duplicate", "list", "end", None),
    19: ("backup", "settings-1.8", "card", [(945, 81, 1080, 216)]),
    20: ("backup", "card", "end", [(90, 672, 990, 818)]),
}
FAST = 9.0   # max fast-forward (typing parts)


def phone_frame(i, t):
    """Frame for line i at absolute time t: the clip segment is time-fitted to the line's slot."""
    name, a, b, _ = SHOTS[i]
    c = clip(name); s0, s1 = c.mark(a), c.mark(b)
    slot0, slot1 = SLOT[i]; D = max(0.5, slot1 - slot0 - 0.15)
    seg = s1 - s0; speed = max(0.8, min(FAST, seg / D))
    if seg / D > FAST: s0 = s1 - FAST * D       # too long even at FAST: skip the start
    lt = s0 + (t - slot0) * speed
    return c.at(min(lt, s1)), speed


# ======================= static art =======================
def gradient():
    bg = Image.new("RGB", (W, H)); px = bg.load()
    for y in range(H):
        for x in range(0, W, 4):
            k = clamp(0.55 * y / H + 0.45 * (1 - x / W) * 0.6)
            c = tuple(int(lerp(NAVY_A[j], NAVY_B[j], k)) for j in range(3))
            for dx in range(4): px[x + dx, y] = c
    bg = bg.convert("RGBA")
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(glow)
    d.ellipse((PX - 260, PY - 160, PX + PW + 260, PY + PH + 160), fill=(70, 120, 200, 70))
    bg.alpha_composite(glow.filter(ImageFilter.GaussianBlur(120)))
    # faint diamond pattern
    pat = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(pat)
    for gx in range(-40, W + 80, 120):
        for gy in range(-40, H + 80, 120):
            d.polygon([(gx, gy - 10), (gx + 8, gy), (gx, gy + 10), (gx - 8, gy)], fill=(255, 255, 255, 10))
    bg.alpha_composite(pat)
    return bg


BG = gradient()
ICON = Image.open(f"{ROOT}/assets/icon/icon.png").convert("RGBA")


def rounded_mask(w, h, r):
    m = Image.new("L", (w, h), 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), r, fill=255); return m


SCREEN_MASK = rounded_mask(PW, PH, 34)
BEZEL = Image.new("RGBA", (PW + 36, PH + 36), (0, 0, 0, 0))
ImageDraw.Draw(BEZEL).rounded_rectangle((0, 0, PW + 35, PH + 35), 50, fill=(14, 18, 28, 255), outline=(70, 82, 110, 255), width=3)
BEZEL = shadowed(BEZEL, blur=26, off=16, alpha=170)
BEZEL_PAD = 26 * 2 + 16


def icon(size):
    return ICON.resize((size, size), Image.LANCZOS)


def pill(txt, f, fg, bg, padx=26, pady=12):
    t = text_img(txt, f, fg)
    im = Image.new("RGBA", (t.width + padx * 2, t.height + pady * 2), (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle((0, 0, im.width - 1, im.height - 1), im.height // 2, fill=bg)
    im.alpha_composite(t, (padx, pady)); return im


GUD = str.maketrans("0123456789", "૦૧૨૩૪૫૬૭૮૯")
STEPS = {"trader": (1, "વેપારી ઉમેરો"), "costing": (2, "નવી કોસ્ટિંગ"), "bargain": (3, "ભાવ-તાલ"),
         "share": (4, "WhatsApp પર મોકલો"), "backup": (5, "મફત બેકઅપ")}
TITLES = {"intro": "કોસ્ટિંગ માસ્ટર શું છે?"}


def clean(txt): return re.sub(r"\[[^\]]*\]\s*", "", txt).strip()


# ---- caption layout (cached per line) ----
CAP_CACHE = {}
def caption_layout(i, maxw, size):
    key = (i, maxw, size)
    if key in CAP_CACHE: return CAP_CACHE[key]
    f = GU_B(size)
    words = [w for w, _, _ in WORDS[i]] or clean(SPEC[i]["text"]).split()
    space = int(size * 0.32)
    imgs_on = [text_img(w, f, WHITE) for w in words]
    imgs_off = [text_img(w, f, (150, 168, 200)) for w in words]
    rows, x, y, lh = [], 0, 0, int(size * 1.55)
    for k, im in enumerate(imgs_on):
        if x and x + im.width > maxw: x = 0; y += lh
        rows.append((x, y)); x += im.width + space - 12
    CAP_CACHE[key] = (rows, imgs_on, imgs_off, y + lh)
    return CAP_CACHE[key]


def draw_caption(fr, i, t, x0, y0, maxw, size=52, center=False):
    rows, on, off, hgt = caption_layout(i, maxw, size)
    k = clamp((t - SLOT[i][0] + 0.25) / 0.3)
    if center:
        # centre each row
        by_row = {}
        for n, (x, y) in enumerate(rows): by_row.setdefault(y, []).append(n)
        shifts = {}
        for y, ns in by_row.items():
            wid = rows[ns[-1]][0] + on[ns[-1]].width
            for n in ns: shifts[n] = (maxw - wid) // 2
    for n, (x, y) in enumerate(rows):
        lit = n < len(WORDS[i]) and t >= WORDS[i][n][1] - 0.05
        im = on[n] if lit or not WORDS[i] else off[n]
        dx = shifts[n] if center else 0
        paste(fr, im, x0 + x + dx, y0 + y + (1 - ease_out(k)) * 20, k)
    return hgt


def ring(fr, box, t, color=GOLD_HI):
    x0, y0, x1, y1 = box
    x0 = PX + x0 * SC; x1 = PX + x1 * SC; y0 = PY + (y0 - CROP_T) * SC; y1 = PY + (y1 - CROP_T) * SC
    pulse = 0.5 + 0.5 * math.sin(t * 5.5)
    g = 6 + 6 * pulse
    d = ImageDraw.Draw(fr)
    d.rounded_rectangle((x0 - g, y0 - g, x1 + g, y1 + g), 26, outline=color + (int(150 + 100 * pulse),), width=5)


def phone(fr, img, alpha=1.0, dy=0):
    fr.alpha_composite(fade(BEZEL, alpha) if alpha < 1 else BEZEL, (PX - 18 - BEZEL_PAD, int(PY - 18 - BEZEL_PAD + dy)))
    scr = img.convert("RGBA"); scr.putalpha(SCREEN_MASK if alpha >= 1 else SCREEN_MASK.point(lambda v: int(v * alpha)))
    fr.alpha_composite(scr, (PX, int(PY + dy)))


def left_panel(fr, i, t):
    sec = SPEC[i]["sec"]
    sec_start = min(SLOT[j][0] for j in range(N) if SPEC[j]["sec"] == sec)
    ks = ease_out((t - sec_start + 0.2) / 0.5)
    x0 = 110
    if sec in STEPS:
        n, title = STEPS[sec]
        chip = pill(f"પગલું {str(n).translate(GUD)} / ૫", GU_B(30), (20, 30, 50), GOLD_HI)
        paste(fr, chip, x0 + (1 - ks) * -60, 170, ks)
        paste(fr, text_img(title, GU_B(78), WHITE), x0 - 6 + (1 - ks) * -60, 232, ks)
        # progress dots
        for s in range(1, 6):
            c = GOLD_HI if s <= n else (70, 90, 130)
            ImageDraw.Draw(fr).rounded_rectangle((x0 + (s - 1) * 92, 372, x0 + (s - 1) * 92 + 78, 380), 4, fill=c + (255,))
        y = 450
    else:
        paste(fr, text_img(TITLES.get(sec, ""), GU_B(70), WHITE), x0 - 6 + (1 - ks) * -60, 220, ks)
        y = 380
    draw_caption(fr, i, t, x0, y, 900, 50)


def brand_corner(fr):
    paste(fr, icon(64), 40, 990 - 0, 0.95)
    paste(fr, text_img("Costing Master", EN_B(30), (220, 230, 245)), 116, 1000, 0.95)


# ======================= special scenes =======================
def scene_hook(fr, i, t):
    s0 = SLOT[i][0]
    if i == 0:
        # notebook + calculator chaos vs question
        k = ease_out((t - s0) / 0.5)
        emo = text_img("📒  🧮  😓", GU_B(120), WHITE)
        pop_paste(fr, emo, W // 2, 330, t - s0)
        draw_caption(fr, 0, t, 260, 520, 1400, 64, center=True)
    else:
        k = t - s0
        pop_paste(fr, shadowed(icon(250), 30, 14, 160), W // 2, 300, k, 0.5)
        name = text_img("કોસ્ટિંગ માસ્ટર", GU_B(96), WHITE)
        paste(fr, name, W // 2 - name.width // 2, 450, clamp((k - 0.3) / 0.4))
        tag = pill("સાડીનો ભાવ ૧ મિનિટમાં  ·  ૧૦૦% મફત", GU_B(38), (20, 30, 50), GOLD_HI, 34, 14)
        paste(fr, tag, W // 2 - tag.width // 2, 600, clamp((k - 0.7) / 0.4))
        draw_caption(fr, 1, t, 260, 760, 1400, 48, center=True)


def scene_store(fr, i, t):
    k = ease_out((t - SLOT[i][0]) / 0.5)
    card = Image.new("RGBA", (820, 400), (0, 0, 0, 0)); d = ImageDraw.Draw(card)
    d.rounded_rectangle((0, 0, 819, 399), 40, fill=(250, 250, 252, 255))
    card.alpha_composite(icon(170), (50, 50))
    card.alpha_composite(text_img("Costing Master - સાડી ભાવ", GU_B(42), (20, 28, 44)), (250, 62))
    card.alpha_composite(text_img("RightDevs  ·  મફત  ·  ગુજરાતી", GU_R(32), (90, 100, 120)), (250, 132))
    btn = pill("ઇન્સ્ટોલ કરો  Install", GU_B(38), WHITE, (24, 110, 70, 255), 60, 18)
    card.alpha_composite(btn, (410 - btn.width // 2, 270))
    search = pill("🔍  Play Store પર શોધો:  Costing Master", GU_B(40), (20, 30, 50), GOLD_HI, 36, 16)
    paste(fr, search, W // 2 - search.width // 2, 150, k)
    paste(fr, shadowed(card, 30, 14, 150), W // 2 - 410 - 76, 280 - 60 + (1 - k) * 40, k)
    draw_caption(fr, i, t, 260, 800, 1400, 48, center=True)


def scene_outro(fr, i, t):
    s = min(SLOT[j][0] for j in range(N) if SPEC[j]["sec"] == "outro")
    k = t - s
    pop_paste(fr, shadowed(icon(210), 30, 14, 160), W // 2, 230, k, 0.5)
    name = text_img("કોસ્ટિંગ માસ્ટર", GU_B(84), WHITE)
    paste(fr, name, W // 2 - name.width // 2, 360, clamp((k - 0.3) / 0.4))
    badges = ["⚡ ઝડપી ભાવ", "✅ સલામત નફો", "🙏 બધું ગુજરાતીમાં"]
    bx = [pill(b, GU_B(40), WHITE, (255, 255, 255, 36), 30, 14) for b in badges]
    tw = sum(b.width for b in bx) + 30 * 2; x = W // 2 - tw // 2
    for n, b in enumerate(bx):
        pop_paste(fr, b, x + b.width // 2, 520, k - 0.6 - n * 0.35); x += b.width + 30
    cta = pill("📲  Play Store પર મફત ડાઉનલોડ કરો  ·  લિંક નીચે", GU_B(44), (20, 30, 50), GOLD_HI, 40, 18)
    if i >= N - 2: pop_paste(fr, cta, W // 2, 650, t - SLOT[N - 2][0])
    if i == N - 1:
        c2 = text_img("💬 કોમેન્ટ કરો   🔁 શેર કરો   🙏 જય શ્રી કૃષ્ણ", GU_B(42), CREAM)
        paste(fr, c2, W // 2 - c2.width // 2, 745, clamp((t - SLOT[i][0]) / 0.4))
    draw_caption(fr, i, t, 260, 860, 1400, 44, center=True)


# ======================= frame =======================
def frame(n):
    t = n / FPS
    fr = BG.copy()
    i = line_at(t)
    sec = SPEC[i]["sec"]
    if i in (0, 1) and i not in SHOTS or sec == "hook":
        scene_hook(fr, i, t)
    elif i == 3:
        scene_store(fr, i, t)
    elif sec == "outro":
        scene_outro(fr, i, t)
    else:
        img, speed = phone_frame(i, t)
        # phone slides in when coming from a non-phone scene
        prev_phone = (i - 1) in SHOTS and SPEC[i - 1]["sec"] != "hook"
        k = 1.0 if prev_phone else ease_out((t - SLOT[i][0] + 0.25) / 0.6)
        phone(fr, img, k, (1 - k) * 80)
        for box in (SHOTS[i][3] or []):
            if t > SLOT[i][0] + 0.4: ring(fr, box, t)
        if speed > 2.5:
            paste(fr, pill("⏩ ફાસ્ટ", GU_B(28), WHITE, (0, 0, 0, 110), 18, 8), PX + PW + 40, PY + 20, 0.9)
        left_panel(fr, i, t)
        brand_corner(fr)
    # global fade in/out
    a = min(clamp(t / 0.5), clamp((TOTAL - t) / 0.8))
    if a < 1:
        fr = Image.blend(Image.new("RGBA", (W, H), (0, 0, 0, 255)), fr, a)
    return fr.convert("RGB")


# ======================= audio mix =======================
def mix_audio(path):
    total = int(TOTAL * RATE)
    mix = [0.0] * total
    for i in range(N):
        pcm = LINES[i][0]; s = int(START[i] * RATE)
        for j, v in enumerate(pcm):
            if s + j < total: mix[s + j] += v / 32768.0
    music = decode(f"{HERE}/../reel-v2-5-nov/audio/music.mp3", f"{A}/wav/music.wav")
    talking = [False] * (total // 480 + 1)
    for i in range(N):
        for b in range(int(START[i] * 100), int(END[i] * 100) + 1):
            if b < len(talking): talking[b] = True
    g = 0.0
    for j in range(total):
        if j % 480 == 0:
            target = 0.05 if talking[j // 480] else 0.11
            g += (target - g) * 0.08
        fade_k = min(1.0, j / RATE / 1.0, (total - j) / RATE / 2.5)
        mix[j] += music[j % len(music)] / 32768.0 * g * fade_k
    peak = max(1e-6, max(abs(v) for v in mix))
    gain = min(1.0, 0.95 / peak)
    out = array.array("h", (int(max(-1, min(1, v * gain)) * 32767) for v in mix))
    w = wave.open(path, "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE); w.writeframes(out.tobytes()); w.close()


def chapters():
    names = {"hook": "શરૂઆત", "intro": "કોસ્ટિંગ માસ્ટર શું છે?", "trader": "પગલું ૧ – વેપારી ઉમેરો",
             "costing": "પગલું ૨ – નવી કોસ્ટિંગ (ડાયમંડ, સગડી, મજૂરી)", "bargain": "પગલું ૩ – ભાવ-તાલ",
             "share": "પગલું ૪ – WhatsApp પર કોસ્ટિંગ શીટ", "backup": "પગલું ૫ – મફત બેકઅપ", "outro": "ડાઉનલોડ કરો"}
    out, seen = [], set()
    for i in range(N):
        s = SPEC[i]["sec"]
        if s in seen: continue
        seen.add(s); tt = 0 if not out else int(SLOT[i][0] - 0.3)
        out.append(f"{tt // 60}:{tt % 60:02d} {names[s]}")
    return out


def main():
    if "--still" in sys.argv:
        k = sys.argv.index("--still"); ts = [float(x) for x in sys.argv[k + 1].split(",")]; d = sys.argv[k + 2]
        os.makedirs(d, exist_ok=True)
        for tt in sorted(ts): frame(int(tt * FPS)).save(f"{d}/t{tt:06.1f}.png")
        print("total", round(TOTAL, 1)); return
    if "--thumb" in sys.argv:
        make_thumb(); return
    out = f"{HERE}/tutorial.mp4"; vid = f"{HERE}/_v.mp4"; wav = f"{HERE}/_a.wav"
    mix_audio(wav)
    total = int(TOTAL * FPS)
    p = subprocess.Popen(["gst-launch-1.0", "-q", "fdsrc", "fd=0", "!",
                          "rawvideoparse", f"width={W}", f"height={H}", "format=rgb", f"framerate={FPS}/1", "!",
                          "videoconvert", "!", "video/x-raw,format=I420", "!",
                          "x264enc", "speed-preset=medium", "bitrate=10000", "key-int-max=60", "!",
                          "video/x-h264,profile=high", "!", "h264parse", "!", "mp4mux", "!",
                          "filesink", f"location={vid}"], stdin=subprocess.PIPE)
    for n in range(total):
        p.stdin.write(frame(n).tobytes())
        if n % 600 == 0: print(f"{n}/{total}", flush=True)
    p.stdin.close(); p.wait()
    subprocess.run(["gst-launch-1.0", "-q", "mp4mux", "name=m", "faststart=true", "!", "filesink", f"location={out}",
                    "filesrc", f"location={vid}", "!", "qtdemux", "!", "h264parse", "!", "queue", "!", "m.",
                    "filesrc", f"location={wav}", "!", "wavparse", "!", "audioconvert", "!", "audioresample", "!",
                    "audio/x-raw,rate=48000,channels=2", "!", "voaacenc", "bitrate=192000", "!", "queue", "!", "m."],
                   check=True)
    os.remove(wav); os.remove(vid)
    open(f"{HERE}/chapters.txt", "w").write("\n".join(chapters()) + "\n")
    print(f"wrote {out} ({TOTAL:.1f}s)")


def make_thumb():
    fr = BG.copy()
    img, _ = (clip("costing_c").at(clip("costing_c").m["quote"] + 1.8), 1)
    phone(fr, img)
    d = ImageDraw.Draw(fr)
    paste(fr, shadowed(icon(150), 20, 10, 150), 70, 70)
    paste(fr, text_img("સાડીનો ભાવ", GU_B(130), WHITE, 4), 90, 270)
    paste(fr, text_img("૧ મિનિટમાં!", GU_B(150), GOLD_HI, 4), 90, 450)
    paste(fr, pill("✅ નફો સલામત  ·  ૧૦૦% મફત", GU_B(54), (20, 30, 50), GOLD_HI, 34, 16), 100, 690)
    paste(fr, text_img("કોસ્ટિંગ માસ્ટર એપ – A to Z", GU_B(52), CREAM), 100, 850)
    fr.convert("RGB").resize((1280, 720), Image.LANCZOS).save(f"{HERE}/thumbnail.png")
    print("wrote thumbnail.png")


if __name__ == "__main__":
    main()
