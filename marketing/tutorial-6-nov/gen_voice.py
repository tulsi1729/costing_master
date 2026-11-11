#!/usr/bin/env python3
"""Voice for the tutorial: ElevenLabs eleven_v3, Bhavesh Bhai, with word timestamps.

  ELEVEN_KEY=sk_... python3 marketing/tutorial-6-nov/gen_voice.py [indices]   # -> audio/lineN.mp3 + .align.json
  ELEVEN_KEY=sk_... python3 marketing/tutorial-6-nov/gen_voice.py --stt       # Scribe check (Gujarati?)
Skips lines that already exist unless their index is passed.
"""
import base64, json, os, sys, urllib.request, uuid

HERE = os.path.dirname(os.path.abspath(__file__))
KEY = os.environ["ELEVEN_KEY"]
VOICE = "UHwU6ReRgTsCs68KHc6C"  # Bhavesh Bhai
LINES = json.load(open(f"{HERE}/lines.json"))
A = f"{HERE}/audio"
os.makedirs(A, exist_ok=True)


def post(url, body, headers):
    req = urllib.request.Request(url, data=body, headers={"xi-api-key": KEY, **headers})
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


def tts(i):
    body = {"text": LINES[i]["text"], "model_id": "eleven_v3", "language_code": "gu",
            "voice_settings": {"stability": 0.5, "similarity_boost": 0.8}}
    try:
        raw = post(f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE}/with-timestamps?output_format=mp3_44100_128",
                   json.dumps(body).encode(), {"Content-Type": "application/json"})
    except urllib.error.HTTPError as e:
        raise SystemExit(f"line {i}: {e.code} {e.read()[:300]}")
    d = json.loads(raw)
    open(f"{A}/line{i}.mp3", "wb").write(base64.b64decode(d["audio_base64"]))
    json.dump(d.get("normalized_alignment") or d["alignment"], open(f"{A}/line{i}.align.json", "w"), ensure_ascii=False)
    print("ok", i, flush=True)


def stt(i):
    b = uuid.uuid4().hex
    data = open(f"{A}/line{i}.mp3", "rb").read()
    body = (f"--{b}\r\nContent-Disposition: form-data; name=\"model_id\"\r\n\r\nscribe_v1\r\n"
            f"--{b}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"a.mp3\"\r\nContent-Type: audio/mpeg\r\n\r\n").encode() \
        + data + f"\r\n--{b}--\r\n".encode()
    d = json.loads(post("https://api.elevenlabs.io/v1/speech-to-text", body,
                        {"Content-Type": f"multipart/form-data; boundary={b}"}))
    print(i, d.get("language_code"), round(d.get("language_probability", 0), 2), d.get("text", "")[:120], flush=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["--stt"]:
        for i in ([int(x) for x in args[1:]] or range(len(LINES))): stt(i)
    else:
        want = [int(x) for x in args]
        for i in range(len(LINES)):
            if want and i not in want: continue
            if not want and os.path.exists(f"{A}/line{i}.mp3"): continue
            tts(i)
