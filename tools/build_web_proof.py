#!/usr/bin/env python3
"""Build an actual D + threaded DRuntime/Phobos + USER wrapper Web proof."""
import argparse,json,os,shutil,subprocess,hashlib
from pathlib import Path
from build_manifest import ROOT,sha
p=argparse.ArgumentParser();p.add_argument('--ldc',required=True,type=Path);p.add_argument('--emsdk',required=True,type=Path);p.add_argument('--runtime-root',type=Path);p.add_argument('--build',type=Path,default=ROOT/'.build/web-review');p.add_argument('--dest',type=Path,default=ROOT/'.build/d-web-proof');a=p.parse_args()
ldc=a.ldc.resolve(strict=True);builder=ldc.with_name('ldc-build-runtime');toolchain=a.emsdk.resolve()/'upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake'
runtime=(a.runtime_root or ROOT/'.build/web-runtime').resolve();dest=a.dest.resolve();dest.mkdir(parents=True,exist_ok=True)
commands=[]
def run(argv):
    commands.append([str(x) for x in argv]);subprocess.run(commands[-1],check=True,cwd=ROOT)
def fingerprint():
    paths=[ldc,builder,toolchain,Path(__file__)]
    for rel in ['ldc-src.zip','ldc-src/runtime/CMakeLists.txt','ldc-src/runtime/druntime','ldc-src/runtime/phobos']:
        q=runtime/rel
        if q.is_file():paths.append(q)
        elif q.is_dir():paths+=sorted(x for x in q.rglob('*') if x.is_file())
    body={str(q):sha(q) for q in paths};return hashlib.sha256(json.dumps(body,sort_keys=True).encode()).hexdigest(),body
stamp=runtime/'.dembree-toolchain-fingerprint'
if a.runtime_root:
    # Explicit reuse requires actual configured flags, not a filename match.
    cache=(runtime/'CMakeCache.txt').read_text();argv=(runtime/'compile_commands.json').read_text()
    for term in ['wasm32-unknown-emscripten','+atomics,+bulk-memory,+simd128','-pthread','-fexceptions']:
        if term not in cache+argv:raise SystemExit('DEMBREE_WEB_RUNTIME_IDENTITY '+term)
else:
    current,_=fingerprint()
    if not stamp.exists() or stamp.read_text().strip()!=current:
        if runtime.exists():shutil.rmtree(runtime)
        run([builder,'--ninja','-j','6','--buildDir='+str(runtime),'--dFlags=-mtriple=wasm32-unknown-emscripten;-mattr=+atomics,+bulk-memory,+simd128','--cFlags=-pthread','CMAKE_CXX_FLAGS=-pthread -fexceptions','CMAKE_EXPORT_COMPILE_COMMANDS=ON','--targetSystem=Emscripten;UNIX','CMAKE_TOOLCHAIN_FILE='+str(toolchain)])
        stamp.write_text(fingerprint()[0]+'\n')
archives=[runtime/'lib/libphobos2-ldc.a',runtime/'lib/libdruntime-ldc.a']
if any(not q.is_file() or q.stat().st_size==0 for q in archives):raise SystemExit('DEMBREE_WEB_RUNTIME_POPULATION')
run(['python3',ROOT/'tools/export_web_archives.py',a.build,dest/'archives'])
run([ldc,'-c','-O2','-release','-mtriple=wasm32-unknown-emscripten','-mattr=+atomics,+bulk-memory,+simd128','-d-version=EmbreeTestFaults','-d-version=EmbreeProofEndpointTests','-I'+str(ROOT/'source'),'-I'+str(ROOT/'tests/source'),ROOT/'source/embree/c.d',ROOT/'source/embree/ray_accel.d',ROOT/'tests/source/embree/tests/closed_intervals_test.d',ROOT/'examples/web_proof.d','-of='+str(dest/'proof.o')])
run(['em++',dest/'proof.o','-o',dest/'proof.js','-pthread','-msimd128','-fexceptions','-sDISABLE_EXCEPTION_CATCHING=0','-sPTHREAD_POOL_SIZE=2','-sEXIT_RUNTIME=1','-sENVIRONMENT=node,web','-sSTACK_SIZE=1048576','@'+str(dest/'archives/link.rsp'),*archives])
run(['node',dest/'proof.js'])
_,runtime_inputs=fingerprint()
receipt={'scope':'actual-D-threaded-runtime','commands':commands,'runtime_inputs':runtime_inputs,'runtime_archives':{str(q):sha(q) for q in archives},'inputs':{str(q):sha(q) for q in [ROOT/'source/embree/c.d',ROOT/'source/embree/ray_accel.d',ROOT/'tests/source/embree/tests/closed_intervals_test.d',ROOT/'examples/web_proof.d',a.build/'compile_commands.json',dest/'archives/manifest.json']},'artifacts':{q.name:sha(q) for q in dest.iterdir() if q.is_file() and q.suffix in ['.o','.js','.wasm']}}
(dest/'proof-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print('DEMBREE_D_WEB_PROOF=PASS')
