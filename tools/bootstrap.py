#!/usr/bin/env python3
"""Mode-isolated, locked package-owned native build. Never stages a consumer."""
import argparse,json,os,shutil,subprocess
from pathlib import Path
from build_manifest import ROOT,input_key,ready,validate,native_generator,owned_roots
p=argparse.ArgumentParser();p.add_argument('--faults',choices=('ON','OFF'),default='OFF');a=p.parse_args()
faults=a.faults=='ON';mode='test' if faults else 'native'
base=ROOT/'.build';base.mkdir(exist_ok=True)
with (base/(mode+'.lock')).open('a+b') as lock:
    if os.name=='nt':
        import msvcrt
        lock.write(b'0');lock.flush();lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_LOCK,1)
    else:
        import fcntl
        fcntl.flock(lock,fcntl.LOCK_EX)
    inputs=input_key(faults);build,prefix=owned_roots(faults,inputs['fingerprint'])
    try:
        current=validate(prefix,production=not faults)
        if current['fingerprint']==inputs['fingerprint']:
            print('DEMBREE_BOOTSTRAP=CURRENT MODE='+mode);raise SystemExit(0)
    except (OSError,ValueError,RuntimeError,KeyError):pass
    if prefix.exists():shutil.rmtree(prefix)
    subprocess.run(['cmake',*native_generator(),'-S',str(ROOT),'-B',str(build),'-DCMAKE_BUILD_TYPE=Release','-DBUILD_TESTING=OFF','-DDEMBREE_TEST_FAULTS='+a.faults],check=True)
    subprocess.run(['cmake','--build',str(build),'--config','Release','--parallel','6'],check=True)
    subprocess.run(['cmake','--install',str(build),'--config','Release','--prefix',str(prefix),'--component','runtime'],check=True)
    ready(build,prefix,inputs)
    print('DEMBREE_BOOTSTRAP=READY MODE='+mode)
