"""Records the tutorial clips on the phone (demo build). Usage: python3 record.py [scene ...] [--dry]"""
import os, signal, subprocess, sys, time
from drv import *

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "clips")
DRY = "--dry" in sys.argv
PKG = "com.rightdevs.costing_master"


class rec:
    def __init__(self, name): self.name = name
    def __enter__(self):
        if not DRY:
            sh("rm", "-f", f"/sdcard/tut_{self.name}.mp4")
            self.p = subprocess.Popen(ADB + ["shell", "screenrecord", "--size", "1080x2408", "--bit-rate", "16000000", f"/sdcard/tut_{self.name}.mp4"])
            time.sleep(1.2)
        t0 = time.time(); self.log = open(f"{OUT}/{self.name}.log", "w"); self.t0 = t0
        return self
    def mark(self, label):
        self.log.write(f"{time.time() - self.t0 + 0.0:.2f} {label}\n"); self.log.flush()
    def __exit__(self, *a):
        time.sleep(1.0)
        if not DRY:
            sh("pkill", "-INT", "screenrecord"); self.p.wait(); time.sleep(1.5)
            subprocess.run(ADB + ["pull", f"/sdcard/tut_{self.name}.mp4", f"{OUT}/{self.name}.mp4"], capture_output=True)
        self.log.close(); print("clip", self.name, flush=True)


def restart():
    sh("am", "force-stop", PKG); time.sleep(0.5)
    sh("am", "start", "-n", f"{PKG}/.MainActivity"); time.sleep(6)


def scene_home():
    restart()
    with rec("home") as r:
        time.sleep(2.0); r.mark("home")
        swipe(1600, 1000, 1200); time.sleep(1.2)
        swipe(1000, 1600, 1200); time.sleep(1.5)
        r.mark("end")


def scene_trader():
    with rec("trader") as r:
        time.sleep(1.0); r.mark("tap_add")
        tapn([n for n in nodes() if n["d"] == "વેપારી ઉમેરો"][-1], 1.5)
        es = edits(); r.mark("name")
        tapn(es[0], 0.5); typ("Krishna Fashion", 0.06); time.sleep(0.6)
        r.mark("phone"); tapn(es[1], 0.5); typ("9825012345", 0.07); time.sleep(0.5)
        r.mark("city"); tapn(es[2], 0.5); typ("Surat", 0.08); time.sleep(0.8)
        back(); time.sleep(0.6); r.mark("save")
        tapn(find("સેવ કરો"), 2.5); r.mark("saved")
        time.sleep(1.5); r.mark("end")


def scene_costing_a():
    with rec("costing_a") as r:
        r.mark("open_trader"); tapn(find("Krishna Fashion"), 2.0)
        r.mark("new"); tapn([n for n in nodes() if n["d"] == "નવી કોસ્ટિંગ"][-1], 2.0)
        es = edits(); r.mark("name")
        tapn(es[0], 0.5); typ("Peacock Pallu", 0.06); time.sleep(0.5)
        r.mark("design"); tapn(es[1], 0.5); typ("145", 0.15); time.sleep(0.6)
        back(); time.sleep(0.5); r.mark("photo")
        tapn(find("Design photo"), 0.1)
        r.mark("end")
    # off camera: pick the saree photo from the gallery (keeps personal photos out of the video)
    time.sleep(1.0); tapn(find("Choose from gallery"), 2.5)
    tap(177, 1556, 3.0)


def check(name, want):
    if kb(): back(); time.sleep(0.5)
    h = header_top(name, expand=False, up_first=True)
    got = h["d"].split("\n")[-1]
    if got != want: raise SystemExit(f"WRONG VALUE in {name}: {got} (want {want}) - stopping")


def scene_costing_b():
    with rec("costing_b") as r:
        time.sleep(1.5); r.mark("photo_set")
        r.mark("patti")
        fill("પટ્ટી ડાયમંડ", [(0, 24), (1, 10), (2, 30), (6, 12), (7, 10), (8, 40)])
        check("પટ્ટી ડાયમંડ", "₹120.00")
        r.mark("buta")
        fill("બુટા ડાયમંડ", [(9, 6), (10, 40), (11, 25)])
        check("બુટા ડાયમંડ", "₹60.00")
        r.mark("sagadi")
        fill("સગડી", [(0, 40), (1, 1), (2, 2), (3, 15)])
        check("સગડી", "₹70.00")
        r.mark("labour")
        fill("મજૂરી", [(0, 30), (1, 15), (2, 5), (3, 8), (5, 5)])
        check("મજૂરી", "₹63.00")
        back(); time.sleep(1.0); r.mark("total")
        time.sleep(1.5)
        r.mark("margins")
        header_top("વટાવ અને નફો"); time.sleep(0.6)
        tapn(find("2%"), 1.2); r.mark("vatav_set")
        tapn(find("15%"), 1.5); r.mark("profit_set")
        time.sleep(1.0); r.mark("final")
        time.sleep(2.0); r.mark("save")
        tapn(find("સેવ કરો"), 3.0); r.mark("quote")
        time.sleep(2.0); r.mark("end")


def scene_bargain():
    with rec("bargain") as r:
        time.sleep(1.0); r.mark("open")
        tapn(find("Bargain"), 1.5)
        e = edits()[0]; tapn(e, 0.6); r.mark("p350"); typ("350", 0.25); time.sleep(2.5)
        sh("input", "keyevent", "67", "67", "67"); time.sleep(0.4)
        r.mark("p300"); typ("300", 0.25); time.sleep(3.0)
        sh("input", "keyevent", "67", "67", "67"); time.sleep(0.4)
        r.mark("p340"); typ("340", 0.25); time.sleep(2.5)
        r.mark("close"); back(); back(); time.sleep(1.0)
        r.mark("end")


def scene_share():
    with rec("share") as r:
        time.sleep(1.0); r.mark("card")
        swipe(1500, 700, 2000); time.sleep(1.0); swipe(1500, 700, 2000); time.sleep(1.0)
        swipe(700, 1500, 800); swipe(700, 1500, 800); time.sleep(0.8)
        r.mark("mine"); tapn(find("મારા માટે"), 1.5); swipe(1500, 800, 2000); time.sleep(1.5)
        swipe(800, 1500, 800); r.mark("trader"); tapn(find("વેપારી માટે"), 1.5)
        r.mark("share"); time.sleep(2.5); r.mark("end")


def scene_duplicate():
    with rec("duplicate") as r:
        back(); time.sleep(1.5); r.mark("list")
        lst = [n for n in nodes() if "Peacock Pallu" in (n["d"] or "") and n["b"][1] > 380]
        n = lst[0]
        r.mark("longpress"); sh("input", "swipe", str(n["cx"]), str(n["cy"]), str(n["cx"]), str(n["cy"]), "900"); time.sleep(1.5)
        r.mark("dup"); tapn(find("નકલ બનાવો"), 2.5)
        r.mark("copy"); time.sleep(2.0)
        back(); time.sleep(1.0)
        r.mark("end")


def scene_backup():
    with rec("backup") as r:
        for _ in range(3):
            if any("સેટિંગ્સ · Settings" == (n["d"] or "") for n in nodes()): break
            back(); time.sleep(1.0)
        r.mark("settings"); tapn(find("સેટિંગ્સ · Settings"), 2.0)
        r.mark("card"); time.sleep(1.5)
        time.sleep(2.5); r.mark("end")


def scene_costing_c():
    with rec("costing_c") as r:
        time.sleep(1.0); r.mark("margins")
        for _ in range(3):
            swipe(1500, 600, 1500); time.sleep(0.6)
            ns = nodes()
            if any(n["d"] == "15%" for n in ns): break
            tapn([n for n in ns if (n["d"] or "").startswith("વટાવ અને નફો\n")][0], 1.2)
        tapn(find("2%"), 1.2); r.mark("vatav_set")
        tapn(find("15%"), 1.5); r.mark("profit_set")
        fp = find("Final price")["d"]
        if "₹367" not in fp: raise SystemExit("WRONG final " + fp)
        time.sleep(1.5); r.mark("save")
        tapn(find("સેવ કરો"), 3.0); r.mark("quote")
        time.sleep(2.0); r.mark("end")


SCENES = ["home", "trader", "costing_a", "costing_b", "bargain", "share", "duplicate", "backup"]
if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    want = [a for a in sys.argv[1:] if not a.startswith("--")] or SCENES
    for s in want: globals()["scene_" + s]()

