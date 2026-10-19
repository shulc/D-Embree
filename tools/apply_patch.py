#!/usr/bin/env python3
"""Apply the owned upstream patch exactly once to a private build source copy."""
import argparse, hashlib, json, subprocess
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('source',type=Path); a=p.parse_args()
root=Path(__file__).resolve().parents[1]
pre=json.loads((root/'native/patches/preimages.json').read_text())
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
state=[digest(a.source/name) for name in pre]
before=[v['before'] for v in pre.values()];after=[v['after'] for v in pre.values()]
if state==after: print('DEMBREE_PATCH=ALREADY_VERIFIED')
elif state!=before:raise SystemExit('DEMBREE_PATCH_PREIMAGE')
else:
    subprocess.run(['git','apply','--check',str(root/'native/patches/embree4.4.1-user-closed-interval.patch')],cwd=a.source,check=True)
    subprocess.run(['git','apply',str(root/'native/patches/embree4.4.1-user-closed-interval.patch')],cwd=a.source,check=True)
    if [digest(a.source/name) for name in pre]!=after:raise SystemExit('DEMBREE_PATCH_POSTIMAGE')
    print('DEMBREE_PATCH=APPLIED')
