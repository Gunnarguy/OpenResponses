"""OpenResponses release steps for the version being prepared (mirrors OpenManual's asc_attach.py and asc_submit.py). Run through `zsh -ic` from this folder; set VERSION below for each release.
  status          run, builds, attached build, version state, open submissions, purchases
  wait RUN        poll until Xcode Cloud run RUN finished and its build is VALID (or failed); prints changes only
  attach --go     attach the newest VALID 2.8 build
  submit --go     create or reuse a review submission, add the version, submit
"""
import sys, time
sys.path.insert(0, sys.path[0])
from asc import call
APP, VERSION, PRODUCT = "6757338355", "8dc1e46a-ea72-462b-891f-b1b2a7b2c2bc", "02676c39-e39d-49e8-af7f-412bc7c32473"
OPEN = {"READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "IN_REVIEW", "UNRESOLVED_ISSUES"}

def builds():
    return call("GET", f"/v1/builds?filter[app]={APP}&filter[preReleaseVersion.version]=2.8&sort=-uploadedDate&limit=4")["data"]

def run_state(number):
    for r in call("GET", f"/v1/ciProducts/{PRODUCT}/buildRuns?sort=-number&limit=4")["data"]:
        if r["attributes"]["number"] == number:
            return r["attributes"].get("executionProgress"), r["attributes"].get("completionStatus")
    return None, None

cmd, go = sys.argv[1], "--go" in sys.argv
if cmd == "status":
    for b in builds():
        a = b["attributes"]; print(f"build {a['version']} {a['processingState']} uploaded {a['uploadedDate']} encryption={a.get('usesNonExemptEncryption')}")
    v = call("GET", f"/v1/appStoreVersions/{VERSION}")["data"]["attributes"]
    att = call("GET", f"/v1/appStoreVersions/{VERSION}/build").get("data")
    print(f"version {v['versionString']} {v['appStoreState']} release={v['releaseType']} attached={att['attributes']['version'] if att else None}")
    for s in call("GET", f"/v1/apps/{APP}/reviewSubmissions?filter[platform]=IOS&limit=5")["data"]:
        print("submission", s["id"], s["attributes"].get("state"), s["attributes"].get("submittedDate"))
    for p in call("GET", f"/v1/apps/{APP}/inAppPurchasesV2?limit=20")["data"]:
        print("purchase", p["attributes"].get("productId"), p["attributes"].get("state"))
elif cmd == "wait":
    number, last = int(sys.argv[2]), None
    for _ in range(90):
        progress, status = run_state(number)
        bs = [b for b in builds() if b["attributes"]["version"] == str(number)]
        state = (progress, status, bs[0]["attributes"]["processingState"] if bs else None)
        if state != last:
            print(time.strftime("%H:%M"), f"run {number}: {progress} {status}; build {number}: {state[2]}", flush=True); last = state
        if state[2] == "VALID" or status in ("FAILED", "ERRORED", "CANCELED") or state[2] in ("FAILED", "INVALID"):
            break
        time.sleep(60)
elif cmd == "attach":
    valid = call("GET", f"/v1/builds?filter[app]={APP}&filter[preReleaseVersion.version]=2.8&filter[processingState]=VALID&sort=-uploadedDate&limit=1")["data"]
    newest = valid[0]; print("newest valid 2.8 build:", newest["attributes"]["version"])
    if not go: sys.exit("dry run; add --go")
    call("PATCH", f"/v1/appStoreVersions/{VERSION}/relationships/build", {"data": {"type": "builds", "id": newest["id"]}})
    print("now attached:", call("GET", f"/v1/appStoreVersions/{VERSION}/build")["data"]["attributes"]["version"])
elif cmd == "submit":
    v = call("GET", f"/v1/appStoreVersions/{VERSION}")["data"]["attributes"]
    att = call("GET", f"/v1/appStoreVersions/{VERSION}/build").get("data")
    print(f"version {v['versionString']} {v['appStoreState']}; attached build {att['attributes']['version'] if att else None}")
    if not att: sys.exit("no build attached")
    pending = [p for p in call("GET", f"/v1/apps/{APP}/inAppPurchasesV2?limit=20")["data"] if p["attributes"].get("state") != "APPROVED"]
    if pending: sys.exit(f"purchases not approved: {[p['attributes'].get('productId') for p in pending]}")
    subs = call("GET", f"/v1/apps/{APP}/reviewSubmissions?filter[platform]=IOS&limit=10")["data"]
    open_subs = [s for s in subs if s["attributes"].get("state") in OPEN]
    if v["appStoreState"] not in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"):
        sys.exit(f"version is {v['appStoreState']}; nothing to submit")
    print("plan:", ("reuse " + open_subs[0]["id"]) if open_subs else "create a submission", "add the version, submit")
    if not go: sys.exit("dry run; add --go")
    sub_id = open_subs[0]["id"] if open_subs else call("POST", "/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions",
        "attributes": {"platform": "IOS"}, "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})["data"]["id"]
    items = call("GET", f"/v1/reviewSubmissions/{sub_id}/items")["data"]
    if not any((i["relationships"].get("appStoreVersion", {}).get("data") or {}).get("id") == VERSION for i in items):
        call("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION}}}}})
        print("added the version item")
    call("PATCH", f"/v1/reviewSubmissions/{sub_id}", {"data": {"type": "reviewSubmissions", "id": sub_id, "attributes": {"submitted": True}}})
    time.sleep(4)
    s = call("GET", f"/v1/reviewSubmissions/{sub_id}")["data"]["attributes"]
    v = call("GET", f"/v1/appStoreVersions/{VERSION}")["data"]["attributes"]
    print(f"submission {sub_id} is {s.get('state')}; version {v['versionString']} is {v['appStoreState']}")
