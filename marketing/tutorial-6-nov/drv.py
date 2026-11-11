import subprocess, re, time, sys, xml.etree.ElementTree as ET
ADB = ["/home/krupal/Android/Sdk/platform-tools/adb", "-s", "RZCT81DD2WZ"]
def sh(*a): return subprocess.run(ADB + ["shell", *a], capture_output=True, text=True).stdout
def nodes():
    sh("uiautomator", "dump", "/sdcard/ui.xml")
    x = subprocess.run(ADB + ["exec-out", "cat", "/sdcard/ui.xml"], capture_output=True).stdout.decode()
    out = []
    for n in ET.fromstring(x).iter("node"):
        b = list(map(int, re.findall(r"\d+", n.get("bounds"))))
        out.append(dict(t=n.get("text"), d=n.get("content-desc"), c=n.get("class"), b=b,
                        cx=(b[0]+b[2])//2, cy=(b[1]+b[3])//2))
    return out
def find(s, ns=None, i=0):
    ns = ns or nodes()
    m = [n for n in ns if s in (n["d"] or "") or s in (n["t"] or "")]
    if len(m) <= i: raise SystemExit(f"not found: {s}")
    return m[i]
def edits(ns=None):
    return [n for n in (ns or nodes()) if n["c"] == "android.widget.EditText" and n["b"][3] > n["b"][1] + 60 and n["b"][1] > 220 and n["b"][3] < 2000]
def tap(x, y, pause=0.6): sh("input", "tap", str(x), str(y)); time.sleep(pause)
def tapn(n, pause=0.6): tap(n["cx"], n["cy"], pause)
def typ(s, per=0.0):
    if per:
        for ch in s: sh("input", "text", ch.replace(" ", "%s")); time.sleep(per)
    else: sh("input", "text", s.replace(" ", "%s"))
def swipe(y1, y2, ms=700): sh("input", "swipe", "540", str(y1), "540", str(y2), str(ms)); time.sleep(0.8)
def back(): sh("input", "keyevent", "BACK"); time.sleep(0.6)
if __name__ == "__main__":
    for n in nodes():
        if n["t"] or n["d"] or n["c"].endswith("EditText"):
            print(n["c"].split(".")[-1][:8], n["b"], repr((n["t"] or "")[:40]), repr((n["d"] or "")[:60]))

def kb(): return "mInputShown=true" in sh("dumpsys", "input_method")
def limit(ns):
    if kb(): return 1390
    fp = [n for n in ns if "Final price" in (n["d"] or "")]
    return fp[0]["b"][1] if fp else 2000
def vis_edits(ns):
    lim = limit(ns)
    es = [n for n in ns if n["c"] == "android.widget.EditText" and n["b"][1] > 225 and n["b"][3] <= lim and n["b"][3] - n["b"][1] > 120]
    return sorted(es, key=lambda n: (n["b"][1], n["b"][0]))
SECTIONS = ["પટ્ટી ડાયમંડ", "બુટા ડાયમંડ", "સગડી", "મજૂરી", "વટાવ અને નફો"]
def own_edits(ns, h):
    """EditTexts between this header and the next section header."""
    nxt = [n["b"][1] for n in ns if any((n["d"] or "").startswith(x + "\n") for x in SECTIONS) and n["b"][1] > h["b"][3]]
    end = min(nxt) if nxt else 99999
    return [e for e in vis_edits(ns) if h["b"][3] < e["b"][1] < end]
def header_top(name, expand=True, up_first=False):
    """Scroll so the section header sits near the top, expanding it if collapsed."""
    for _ in range(8):
        ns = nodes(); h = [n for n in ns if (n["d"] or "").startswith(name + "\n")]
        if h and 230 < h[0]["b"][1] < 1700:
            h = h[0]
            if h["b"][1] > 300:
                swipe(h["b"][1], 280, 1600); ns = nodes(); h = [n for n in ns if (n["d"] or "").startswith(name + "\n")][0]
            below = own_edits(ns, h)
            if expand and not below:
                tapn(h, 1.2); continue
            return h
        if h: down = h[0]["b"][1] >= 1700
        else:
            vis = [SECTIONS.index(x) for n in ns for x in SECTIONS if (n["d"] or "").startswith(x + "\n")]
            down = (min(vis) < SECTIONS.index(name)) if vis else not up_first
        swipe(1500, 700, 900) if down else swipe(700, 1500, 900)
    raise SystemExit("header " + name)
def fill(name, seq, per=0.07, gap=0.35):
    """seq: list of (field index within section, value). Fills in order."""
    if kb(): back(); time.sleep(0.6)
    header_top(name)
    last = None  # (k, value str, y)
    for k, val in seq:
        val = str(val)
        for _ in range(8):
            ns = nodes(); es = vis_edits(ns); lim = limit(ns)
            if last is None:
                hh = [n for n in ns if (n["d"] or "").startswith(name + "\n")]
                if not hh: swipe(600, 1200, 1500); continue
                cand = own_edits(ns, hh[0]); pos = k
            else:
                lk, lv, ly = last
                m = [i for i, e in enumerate(es) if e["t"] == lv]
                if not m: swipe(600, 1150, 1500); continue
                i = min(m, key=lambda i: abs(es[i]["b"][1] - ly))
                cand = es; pos = i + (k - lk)
            if pos < len(cand) and cand[pos]["b"][3] < lim - 10: break
            d = 450 if last is None else max(150, min(450, es[i]["b"][1] - 300))
            swipe(1250, 1250 - d, 1500)
        else:
            raise SystemExit(f"field {name} {k}")
        tgt = cand[pos]; tapn(tgt, 0.4); typ(val, per); time.sleep(gap)
        last = (k, val, tgt["b"][1])
