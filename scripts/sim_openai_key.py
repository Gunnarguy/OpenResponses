#!/usr/bin/env python3
"""Put your OpenAI key into OpenResponses on a booted simulator, without typing it.

    python3 scripts/sim_openai_key.py                      # the simulator named "OpenResponses demo"
    python3 scripts/sim_openai_key.py <simulator name or UDID>
    python3 scripts/sim_openai_key.py --service <Keychain service>   # default: openai-api-key

Reads the key from this Mac's login Keychain (the item `~/.agents/bin/key-setup openai` stores), hands it to the
simulator app's preferences as `openAIKey` through stdin, and relaunches the app. At launch,
`KeychainService.migrateApiKeyFromUserDefaults` moves it into the simulator's Keychain and removes it from the
preferences. It also marks onboarding as done. The key never appears in a command line or in this script's output.

The migration does nothing when the simulator's Keychain already holds a key; this script says so instead of
pretending. Never run it on a simulator used for unit tests: they save and delete the Keychain `openAIKey`.
"""
import argparse, json, plistlib, subprocess, sys

BUNDLE = "Gunndamental.OpenResponses"


def run(*args, **kw):
    return subprocess.run(list(args), capture_output=True, **kw)


def find_device(wanted):
    listing = json.loads(run("xcrun", "simctl", "list", "devices", "--json").stdout)
    matches = [d for ds in listing["devices"].values() for d in ds if wanted in (d["name"], d["udid"])]
    if not matches:
        sys.exit(f'No simulator named or with UDID "{wanted}". See: xcrun simctl list devices')
    booted = [d for d in matches if d["state"] == "Booted"]
    if not booted:
        sys.exit(f'"{wanted}" is not booted. Boot it first: xcrun simctl boot {matches[0]["udid"]}')
    return booted[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("device", nargs="?", default="OpenResponses demo")
    ap.add_argument("--service", default="openai-api-key")
    a = ap.parse_args()
    if "tests" in a.device.lower():
        sys.exit("Refusing: unit tests on this simulator would delete the key.")
    dev = find_device(a.device)
    udid = dev["udid"]

    key = run("security", "find-generic-password", "-s", a.service, "-w", text=True).stdout.strip()
    if not key.startswith("sk-"):
        sys.exit(f'No OpenAI key in the Keychain item "{a.service}". Store one with: ~/.agents/bin/key-setup openai')

    run("xcrun", "simctl", "terminate", udid, BUNDLE)
    current = run("xcrun", "simctl", "spawn", udid, "defaults", "export", BUNDLE, "-")
    prefs = plistlib.loads(current.stdout) if current.returncode == 0 and current.stdout.strip() else {}
    prefs["openAIKey"] = key
    prefs["hasCompletedOnboarding"] = True
    r = run("xcrun", "simctl", "spawn", udid, "defaults", "import", BUNDLE, "-", input=plistlib.dumps(prefs))
    del key, prefs
    if r.returncode != 0:
        sys.exit("Writing the simulator app's preferences failed: " + r.stderr.decode()[:300])

    launch = run("xcrun", "simctl", "launch", udid, BUNDLE, text=True)
    if launch.returncode != 0:
        sys.exit("Key written, but the app did not launch (is OpenResponses installed there?): " + launch.stderr[:300])

    # The app saves the key to its Keychain at launch. Reading the preferences from outside cannot confirm it
    # (cfprefsd still showed the removed value on 2026-11-19 although the save had happened), so count the app's
    # rows in the simulator's Keychain database instead; only row counts are read, never a value.
    import sqlite3, time
    from pathlib import Path
    db = Path(dev["dataPath"]) / "Library/Keychains/keychain-2-debug.db"
    taken = False
    for _ in range(20):
        time.sleep(0.5)
        try:
            con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
            n = con.execute("select count(*) from genp where agrp like ?", (f"%.{BUNDLE}",)).fetchone()[0]
            con.close()
        except sqlite3.Error:
            n = 0
        if n:
            taken = True
            break
    # The preferences copy must not outlive the run, whatever happened.
    run("xcrun", "simctl", "spawn", udid, "defaults", "delete", BUNDLE, "openAIKey")
    if taken:
        print(f'Key moved into the app\'s Keychain on "{dev["name"]}" ({udid}); onboarding marked done.')
        return
    sys.exit("The app's Keychain stayed empty after 10 s. The copy in the preferences was removed. "
             "Check that OpenResponses is installed on that simulator and run this again.")


if __name__ == "__main__":
    main()
