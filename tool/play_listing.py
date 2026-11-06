#!/usr/bin/env python3
"""Update the Play Store listing graphics through the Play Developer API.

Only needs python3 + openssl (no pip installs). Auth is the Play service
account JSON (same one CI uses: PLAY_SERVICE_ACCOUNT_JSON).

  # show listing languages and current images
  python3 tool/play_listing.py --key sa.json list

  # replace the hi-res icon (resized to 512x512 if Pillow is installed)
  python3 tool/play_listing.py --key sa.json upload icon assets/icon/icon.png

  # set title/descriptions + default language from tool/play_listing_text.json
  python3 tool/play_listing.py --key sa.json text tool/play_listing_text.json

  # replace phone screenshots (in this order)
  python3 tool/play_listing.py --key sa.json upload phoneScreenshots screenshots/*.png

Image types: icon, featureGraphic, phoneScreenshots, sevenInchScreenshots,
tenInchScreenshots, tvBanner, tvScreenshots, wearScreenshots.
`upload` replaces all images of that type in every listing language unless
--lang is given. Changes go live only when the edit is committed (done
automatically unless --dry-run).
"""
import argparse, base64, json, os, subprocess, sys, tempfile, time
import urllib.parse, urllib.request, urllib.error

PACKAGE = "com.rightdevs.costing_master"
API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" + PACKAGE
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/" + PACKAGE


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def access_token(sa: dict) -> str:
    now = int(time.time())
    header = b64url(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    claims = b64url(json.dumps({
        "iss": sa["client_email"],
        "scope": "https://www.googleapis.com/auth/androidpublisher",
        "aud": sa["token_uri"],
        "iat": now, "exp": now + 3600,
    }).encode())
    signing_input = f"{header}.{claims}".encode()
    with tempfile.NamedTemporaryFile("w", delete=False) as f:
        f.write(sa["private_key"])
        key_path = f.name
    try:
        sig = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path],
                             input=signing_input, capture_output=True, check=True).stdout
    finally:
        os.unlink(key_path)
    body = urllib.parse.urlencode({
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": f"{header}.{claims}.{b64url(sig)}",
    }).encode()
    with urllib.request.urlopen(sa["token_uri"], body) as r:
        return json.load(r)["access_token"]


class Play:
    def __init__(self, token):
        self.token = token

    def call(self, method, url, data=None, content_type="application/json"):
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", "Bearer " + self.token)
        if data is not None:
            req.add_header("Content-Type", content_type)
        try:
            with urllib.request.urlopen(req) as r:
                raw = r.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            sys.exit(f"{method} {url}\n-> HTTP {e.code}: {e.read().decode()}")


def png_bytes(path, image_type):
    """Icon must be 512x512 32-bit PNG; resize if Pillow is available."""
    if image_type != "icon":
        return open(path, "rb").read()
    try:
        from PIL import Image
        import io
        img = Image.open(path).convert("RGBA")
        if img.size != (512, 512):
            img = img.resize((512, 512), Image.LANCZOS)
        buf = io.BytesIO()
        img.save(buf, "PNG", optimize=True)
        return buf.getvalue()
    except ImportError:
        print("Pillow not installed; uploading as-is (must already be 512x512)")
        return open(path, "rb").read()


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--key", default=os.environ.get("PLAY_SERVICE_ACCOUNT_JSON_FILE"),
                   help="service account JSON file (or env PLAY_SERVICE_ACCOUNT_JSON_FILE)")
    p.add_argument("--lang", action="append", help="listing language(s), default: all")
    p.add_argument("--dry-run", action="store_true", help="don't commit the edit")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    tx = sub.add_parser("text")
    tx.add_argument("file", help="JSON: defaultLanguage, languages, title, shortDescription, fullDescription")
    up = sub.add_parser("upload")
    up.add_argument("type")
    up.add_argument("files", nargs="+")
    args = p.parse_args()
    if not args.key:
        p.error("--key is required")

    play = Play(access_token(json.load(open(args.key))))
    edit = play.call("POST", f"{API}/edits", b"{}")["id"]
    langs = args.lang or [l["language"] for l in play.call("GET", f"{API}/edits/{edit}/listings").get("listings", [])]
    print("listing languages:", ", ".join(langs))

    if args.cmd == "list":
        for lang in langs:
            for t in ("icon", "featureGraphic", "phoneScreenshots"):
                imgs = play.call("GET", f"{API}/edits/{edit}/listings/{lang}/{t}").get("images", [])
                print(f"  {lang} {t}: {len(imgs)}", *[i.get("url") for i in imgs], sep="\n    ")
        play.call("DELETE", f"{API}/edits/{edit}")
        return

    if args.cmd == "text":
        t = json.load(open(args.file))
        full = t["fullDescription"]
        body = {"title": t["title"], "shortDescription": t["shortDescription"],
                "fullDescription": "\n".join(full) if isinstance(full, list) else full}
        video = next((l.get("video") for l in play.call("GET", f"{API}/edits/{edit}/listings").get("listings", [])
                      if l.get("video")), None)
        video = t.get("video") or video
        if video:
            body["video"] = video
        graphics = {k: [(f, png_bytes(f, k)) for f in v] for k, v in t.get("graphics", {}).items()}
        for lang in args.lang or t["languages"]:
            play.call("PUT", f"{API}/edits/{edit}/listings/{lang}",
                      json.dumps(dict(body, language=lang)).encode())
            print(f"  {lang}: {t['title']}")
            for kind, items in graphics.items():
                play.call("DELETE", f"{API}/edits/{edit}/listings/{lang}/{kind}")
                for f, blob in items:
                    play.call("POST", f"{UPLOAD}/edits/{edit}/listings/{lang}/{kind}?uploadType=media",
                              blob, "image/png")
                print(f"    {kind}: {len(items)}")
        if t.get("defaultLanguage"):
            play.call("PATCH", f"{API}/edits/{edit}/details",
                      json.dumps({"defaultLanguage": t["defaultLanguage"]}).encode())
            print("  default language:", t["defaultLanguage"])
        langs = []  # nothing to upload
    blobs = [] if args.cmd == "text" else [png_bytes(f, args.type) for f in args.files]
    for lang in langs:
        play.call("DELETE", f"{API}/edits/{edit}/listings/{lang}/{args.type}")
        for f, blob in zip(args.files, blobs):
            r = play.call("POST", f"{UPLOAD}/edits/{edit}/listings/{lang}/{args.type}?uploadType=media",
                          blob, "image/png")
            print(f"  {lang} {args.type} <- {f} ({r['image']['id'][:12]}...)")

    if args.dry_run:
        play.call("DELETE", f"{API}/edits/{edit}")
        print("dry run: edit discarded")
    else:
        play.call("POST", f"{API}/edits/{edit}:commit")
        print("committed: listing updated")


if __name__ == "__main__":
    main()
