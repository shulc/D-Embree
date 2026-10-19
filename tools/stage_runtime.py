#!/usr/bin/env python3
"""Validate and stage the manifest-selected shared runtime and notices."""
import argparse,json,shutil
from pathlib import Path
from build_manifest import validate,sha
p=argparse.ArgumentParser();p.add_argument('--prefix',required=True,type=Path);p.add_argument('--dest',required=True,type=Path);a=p.parse_args()
prefix=a.prefix.resolve(strict=True);manifest=validate(prefix)
dest=a.dest.resolve();dest.mkdir(parents=True,exist_ok=True)
runtime=[n for n in manifest['artifacts'] if n.endswith(('.so','.dylib','.dll'))]
notices=[n for n in manifest['artifacts'] if n.startswith('share/licenses/dembree/')]
if len(runtime)!=1:raise SystemExit('EMBREE_RUNTIME_STAGE')
if len(notices)<4:raise SystemExit('EMBREE_NOTICE_POPULATION')
records={}
for name in runtime+notices:
    source=prefix/name
    target=dest/(Path(name).name if name in runtime else 'licenses/dembree/'+Path(name).name)
    target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    records[str(target.relative_to(dest))]=sha(target)
result={'fingerprint':manifest['fingerprint'],'faults':False,'artifacts':records,'runtime':Path(runtime[0]).name}
(dest/'dembree-runtime.json').write_text(json.dumps(result,indent=2)+'\n')
print('EMBREE_RUNTIME_STAGE=PASS ARTIFACTS='+str(len(records)))
