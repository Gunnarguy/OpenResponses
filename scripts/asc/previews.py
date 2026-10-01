"""App Store previews for the version release.py points at (2026-10-01).  Run through `zsh -ic` from this folder.

  cancel --go                  pull the open review submission so the version takes new media (it goes back in the queue)
  upload FILE... --go          add previews to the 6.5" iPhone set, in order; 6.9", 6.3" and 6.1" use them scaled
  clear --go                   delete every preview in the set (to re-upload one stuck in processing)
  state                        every preview in the set: file, processing state, poster time code
  poster INDEX TIMECODE --go   set one preview's poster frame (the default is 5 s in)

Apple's App Preview Specifications (read 2026-10-01): 886x1920 portrait for 6.5" and 6.9", H.264 High up to level 4.0,
30 fps, stereo AAC, 15 to 30 s, 500 MB.  Fields from the App Store Connect API reference: appPreviews take fileName,
fileSize, mimeType and previewFrameTimeCode, then commit with uploaded and sourceFileChecksum (the file's MD5);
reviewSubmissions cancel with canceled.
"""
import hashlib, os, re, sys, time, urllib.request
sys.path.insert(0, sys.path[0])
from asc import call

# The version release.py points at, read as text: importing it would run its command line.
APP, VERSION = re.search(r'APP, VERSION, PRODUCT = "(\d+)", "([0-9a-f-]+)"', open(os.path.join(sys.path[0], "release.py")).read()).groups()

go = "--go" in sys.argv
args = [a for a in sys.argv[1:] if a != "--go"]


def localization():
    return call("GET", f"/v1/appStoreVersions/{VERSION}/appStoreVersionLocalizations")["data"][0]["id"]


def preview_set(create=False):
    sets = call("GET", f"/v1/appStoreVersionLocalizations/{localization()}/appPreviewSets")["data"]
    found = next((s for s in sets if s["attributes"]["previewType"] == "IPHONE_65"), None)
    if found or not create:
        return found
    return call("POST", "/v1/appPreviewSets", {"data": {"type": "appPreviewSets", "attributes": {"previewType": "IPHONE_65"},
        "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": localization()}}}}})["data"]


def previews():
    s = preview_set()
    return call("GET", f"/v1/appPreviewSets/{s['id']}/appPreviews")["data"] if s else []


cmd = args[0]
if cmd == "cancel":
    v = call("GET", f"/v1/appStoreVersions/{VERSION}")["data"]["attributes"]
    subs = [s for s in call("GET", f"/v1/apps/{APP}/reviewSubmissions?filter[platform]=IOS&limit=10")["data"]
            if s["attributes"].get("state") in ("WAITING_FOR_REVIEW", "READY_FOR_REVIEW")]
    print(f"version {v['versionString']} {v['appStoreState']}; open submissions {[s['id'] for s in subs]}")
    if not subs: sys.exit("nothing to cancel")
    if not go: sys.exit("dry run; add --go")
    call("PATCH", f"/v1/reviewSubmissions/{subs[0]['id']}", {"data": {"type": "reviewSubmissions", "id": subs[0]["id"], "attributes": {"canceled": True}}})
    for _ in range(40):
        state = call("GET", f"/v1/reviewSubmissions/{subs[0]['id']}")["data"]["attributes"]["state"]
        v = call("GET", f"/v1/appStoreVersions/{VERSION}")["data"]["attributes"]["appStoreState"]
        print(time.strftime("%H:%M:%S"), f"submission {state}, version {v}", flush=True)
        if v in ("DEVELOPER_REJECTED", "PREPARE_FOR_SUBMISSION"): break
        time.sleep(15)
elif cmd == "upload":
    files = args[1:]
    for f in files:
        print(f"{os.path.basename(f)}: {os.path.getsize(f) / 1e6:.1f} MB")
    if not go: sys.exit("dry run; add --go")
    s = preview_set(create=True)
    for f in files:
        data = open(f, "rb").read()
        r = call("POST", "/v1/appPreviews", {"data": {"type": "appPreviews",
            "attributes": {"fileName": os.path.basename(f), "fileSize": len(data), "mimeType": "video/quicktime"},
            "relationships": {"appPreviewSet": {"data": {"type": "appPreviewSets", "id": s["id"]}}}}})["data"]
        for op in r["attributes"]["uploadOperations"]:
            chunk = data[op["offset"]: op["offset"] + op["length"]]
            headers = {h["name"]: h["value"] for h in op.get("requestHeaders") or []}
            urllib.request.urlopen(urllib.request.Request(op["url"], data=chunk, method=op["method"], headers=headers)).read()
        call("PATCH", f"/v1/appPreviews/{r['id']}", {"data": {"type": "appPreviews", "id": r["id"],
            "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
        print(f"uploaded {os.path.basename(f)} as {r['id']} in {len(r['attributes']['uploadOperations'])} parts", flush=True)
elif cmd == "clear":
    # Apple's forums: a preview stuck in processing past an hour is deleted and uploaded again (2026-10-01: three
    # sat at PROCESSING for 80 minutes).
    found = previews()
    for p in found:
        print("delete", p["attributes"].get("fileName"), p["id"])
    if not go: sys.exit("dry run; add --go")
    for p in found:
        call("DELETE", f"/v1/appPreviews/{p['id']}")
    print("left in the set:", len(previews()))
elif cmd == "state":
    for i, p in enumerate(previews()):
        a = p["attributes"]
        print(i, a.get("fileName"), (a.get("videoDeliveryState") or {}).get("state"), (a.get("videoDeliveryState") or {}).get("errors"),
              "poster", a.get("previewFrameTimeCode"))
elif cmd == "poster":
    index, code = int(args[1]), args[2]
    p = previews()[index]
    print(p["attributes"].get("fileName"), "poster", p["attributes"].get("previewFrameTimeCode"), "->", code)
    if not go: sys.exit("dry run; add --go")
    call("PATCH", f"/v1/appPreviews/{p['id']}", {"data": {"type": "appPreviews", "id": p["id"], "attributes": {"previewFrameTimeCode": code}}})
    print("now", call("GET", f"/v1/appPreviews/{p['id']}")["data"]["attributes"].get("previewFrameTimeCode"))
