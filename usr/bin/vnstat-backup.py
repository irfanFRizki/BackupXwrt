#!/usr/bin/env python3
"""Minimal VNStat Backup - Hanya butuh Python3-light"""
import base64, json, sys
from urllib.request import Request, urlopen

# CONFIG
TOKEN = "ghp_YOUR_TOKEN_HERE"
OWNER = "irfanFRizki"
REPO = "BackupXwrt"
BRANCH = "main"
SOURCE = "/etc/vnstat/vnstat.db"
DEST = "etc/vnstat/vnstat.db"

print("🚀 Starting backup...")

# Read & encode
try:
    with open(SOURCE, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()
    print(f"✓ Encoded: {len(b64)} bytes")
except Exception as e:
    print(f"❌ Read error: {e}")
    sys.exit(1)

# Check existing file
url = f"https://api.github.com/repos/{OWNER}/{REPO}/contents/{DEST}?ref={BRANCH}"
sha = None
try:
    req = Request(url, headers={"Authorization": f"token {TOKEN}"})
    with urlopen(req) as r:
        sha = json.loads(r.read())["sha"]
        print(f"✓ File exists (SHA: {sha[:8]}...)")
except:
    print("ℹ️  Creating new file")

# Upload
payload = {"message": "Auto backup vnstat.db by Script Python", "content": b64, "branch": BRANCH}
if sha: payload["sha"] = sha

try:
    req = Request(url.split("?")[0], 
                  data=json.dumps(payload).encode(),
                  headers={"Authorization": f"token {TOKEN}", "Content-Type": "application/json"},
                  method="PUT")
    with urlopen(req) as r:
        result = json.loads(r.read())
        print(f"✅ Success! Commit: {result['commit']['sha'][:8]}...")
except Exception as e:
    print(f"❌ Upload failed: {e}")
    sys.exit(1)
