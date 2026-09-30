"""Minimal App Store Connect client for this session (same JWT recipe as OpenManual's scripts/asc/*.py).
Run through `zsh -ic` so the key variables from ~/.zshrc are set. Never prints key material.

  python3 asc.py get PATH                 print JSON
  python3 asc.py patch PATH BODY.json     PATCH, print JSON
  python3 asc.py post PATH BODY.json      POST, print JSON
  python3 asc.py listings                 read-only: listing text of every app's newest iOS versions
"""
import json, os, sys, time, urllib.error, urllib.request
import jwt

KEY_ID = os.environ["APP_STORE_CONNECT_API_KEY_ID"]
ISSUER = os.environ["APP_STORE_CONNECT_ISSUER_ID"]
KEY_PATH = os.path.expanduser(os.environ["APP_STORE_CONNECT_API_KEY_PATH"])
BASE = "https://api.appstoreconnect.apple.com"
APPS = {"openresponses": "6757338355", "openintelligence": "6756559175", "openmanual": "6804523993", "opencone": "6744467668"}


def token():
    now = int(time.time())
    with open(KEY_PATH) as f:
        key = f.read()
    return jwt.encode({"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": KEY_ID})


def call(method, path, body=None):
    req = urllib.request.Request(BASE + path, method=method,
                                 headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"},
                                 data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(req) as r:
            return json.load(r) if r.status != 204 else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP {e.code} {method} {path}\n{e.read().decode()[:1500]}")


def listings():
    out = {}
    for name, app in APPS.items():
        info = call("GET", f"/v1/apps/{app}/appInfos")["data"]
        app_infos = []
        for i in info:
            locs = call("GET", f"/v1/appInfos/{i['id']}/appInfoLocalizations")["data"]
            app_infos.append({"id": i["id"], "state": i["attributes"].get("appStoreState") or i["attributes"].get("state"),
                              "localizations": [{"id": l["id"], **l["attributes"]} for l in locs]})
        versions = call("GET", f"/v1/apps/{app}/appStoreVersions?filter[platform]=IOS&limit=3")["data"]
        vers = []
        for v in versions:
            locs = call("GET", f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations")["data"]
            vers.append({"id": v["id"], **{k: v["attributes"].get(k) for k in ("versionString", "appStoreState", "releaseType", "copyright", "createdDate")},
                         "localizations": [{"id": l["id"], **l["attributes"]} for l in locs]})
        out[name] = {"app": app, "appInfos": app_infos, "versions": vers}
    return out


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "listings":
        json.dump(listings(), sys.stdout, indent=1, ensure_ascii=False)
    elif cmd == "get":
        json.dump(call("GET", sys.argv[2]), sys.stdout, indent=1, ensure_ascii=False)
    elif cmd in ("patch", "post"):
        body = json.load(open(sys.argv[3]))
        json.dump(call(cmd.upper(), sys.argv[2], body), sys.stdout, indent=1, ensure_ascii=False)
    else:
        raise SystemExit(__doc__)
