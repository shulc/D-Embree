#!/usr/bin/env python3
"""Authenticate source, patched upstream, effective compiler inputs and artifacts."""
import hashlib,json,platform,subprocess,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SOURCE_DIRS=('include','csrc','native','tools','licenses')
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def source_inputs():
    paths=[ROOT/'CMakeLists.txt',ROOT/'dub.json',ROOT/'LICENSE',ROOT/'THIRD_PARTY_LICENSES.md']
    paths += [p for directory in SOURCE_DIRS for p in (ROOT/directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    return {str(p.relative_to(ROOT)):sha(p) for p in sorted(paths)}
def compiler_identity():
    import os,shutil
    compiler=next((shutil.which(v) for v in [os.environ.get('CXX',''), 'c++', 'clang++', 'cl'] if v and shutil.which(v)),None)
    if not compiler: raise RuntimeError('DEMBREE_COMPILER_MISSING')
    p=Path(compiler).resolve()
    return {'path':str(p),'sha256':sha(p),'version':subprocess.run([str(p),'/Bv' if p.stem.lower()=='cl' else '--version'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True).stdout,'machine':platform.machine(),'system':platform.system(),'pointer_bits':__import__('struct').calcsize('P')*8}
def input_key(faults):
    body={'sources':source_inputs(),'compiler':compiler_identity(),'faults':bool(faults),'configuration':'Release','kernel':'USER-SSE2-exact-closed-interval-v1','tasking':'INTERNAL','environment':{k:os.environ.get(k) for k in ('CC','CXX','CFLAGS','CXXFLAGS','CPPFLAGS','LDFLAGS','SDKROOT','MACOSX_DEPLOYMENT_TARGET','CMAKE_GENERATOR','CMAKE_OSX_ARCHITECTURES')},'cmake':subprocess.check_output(['cmake','--version'],text=True)}
    body['fingerprint']=hashlib.sha256(json.dumps(body,sort_keys=True).encode()).hexdigest();return body
def ready(build,prefix,inputs):
    upstream=build/'_deps/dembree_upstream-src'
    pre=json.loads((ROOT/'native/patches/preimages.json').read_text())
    for name,entry in pre.items():
        if sha(upstream/name)!=entry['after']:raise RuntimeError('DEMBREE_PATCH_POSTIMAGE')
    paths=[build/'CMakeCache.txt',build/'compile_commands.json']
    paths += list((upstream/'include/embree4').rglob('*.h'))
    paths += list((build/'_deps/dembree_upstream-build').rglob('*.h'))
    paths += list((build/'_deps/dembree_upstream-build').rglob('*.a'))
    paths += [upstream/name for name in pre]
    paths += list((build/'_deps').rglob('archive.tar'))
    if len(paths)<10:raise RuntimeError('DEMBREE_BUILD_INPUT_POPULATION')
    artifacts={str(p.relative_to(prefix)):sha(p) for p in sorted(prefix.rglob('*')) if p.is_file() and p.name!='manifest.json'}
    if not artifacts:raise RuntimeError('DEMBREE_RUNTIME_POPULATION')
    result=dict(inputs,source_root=str(ROOT),build_root=str(build),prefix=str(prefix),native_inputs={str(p):sha(p) for p in sorted(paths)},artifacts=artifacts)
    (prefix/'manifest.json').write_text(json.dumps(result,indent=2)+'\n');return result

def validate(prefix,production=True,inputs=True):
    prefix=Path(prefix).resolve(strict=True)
    result=json.loads((prefix/'manifest.json').read_text())
    if production and result['faults']:raise RuntimeError('EMBREE_BUILD_MODE_IDENTITY')
    if inputs:
        if result['sources']!=source_inputs():raise RuntimeError('EMBREE_DEPENDENCY_INPUT_FRESHNESS')
        for path,digest in result['native_inputs'].items():
            if not Path(path).is_file() or sha(path)!=digest:raise RuntimeError('EMBREE_DEPENDENCY_INPUT_FRESHNESS '+path)
    if not result['artifacts']:raise RuntimeError('EMBREE_RUNTIME_STAGE')
    for name,digest in result['artifacts'].items():
        path=(prefix/name).resolve(strict=True)
        if not path.is_relative_to(prefix) or sha(path)!=digest:raise RuntimeError('EMBREE_RUNTIME_STAGE '+name)
    return result
