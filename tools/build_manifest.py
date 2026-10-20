#!/usr/bin/env python3
"""Authenticate source, patched upstream, effective compiler inputs and artifacts."""
import hashlib,json,platform,subprocess,os,shutil,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SOURCE_DIRS=('include','csrc','native','tools','licenses','source')
ENVIRONMENT=('CC','CXX','CFLAGS','CXXFLAGS','CPPFLAGS','LDFLAGS','SDKROOT','MACOSX_DEPLOYMENT_TARGET','CMAKE_GENERATOR','CMAKE_OSX_ARCHITECTURES','PATH','INCLUDE','LIB','LIBPATH')
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def source_inputs():
    paths=[ROOT/'CMakeLists.txt',ROOT/'dub.json',ROOT/'LICENSE',ROOT/'THIRD_PARTY_LICENSES.md']
    paths += [p for directory in SOURCE_DIRS for p in (ROOT/directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    return {str(p.relative_to(ROOT)):sha(p) for p in sorted(paths)}
def native_generator():
    if os.name=='nt':
        if os.environ.get('CMAKE_GENERATOR','Ninja')!='Ninja' or not shutil.which('ninja'):
            raise RuntimeError('DEMBREE_NATIVE_GENERATOR: Windows requires Ninja in the compiler developer environment')
        return ['-G','Ninja']
    return []
def compiler_identity():
    defaults=('cl','clang++','c++') if os.name=='nt' else ('c++','clang++','cl')
    compiler=next((shutil.which(v) for v in (os.environ.get('CXX',''),*defaults) if v and shutil.which(v)),None)
    if not compiler:raise RuntimeError('DEMBREE_COMPILER_MISSING')
    p=Path(compiler).resolve()
    return {'path':str(p),'sha256':sha(p),'version':subprocess.run([str(p),'/Bv' if p.stem.lower()=='cl' else '--version'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True).stdout,'machine':platform.machine(),'system':platform.system(),'pointer_bits':__import__('struct').calcsize('P')*8}
def environment_identity():
    result={k:os.environ.get(k) for k in ENVIRONMENT}
    loader_paths={str(ROOT/'.build'/m/'bin') for m in ('native-runtime','test-runtime')}
    result['PATH']=os.pathsep.join(p for p in os.environ.get('PATH','').split(os.pathsep) if p not in loader_paths)
    return result
def input_key(faults):
    body={'sources':source_inputs(),'compiler':compiler_identity(),'faults':bool(faults),'configuration':'Release','kernel':'USER-scalar-exact-closed-interval-v1','tasking':'INTERNAL','generator':native_generator(),'environment':environment_identity(),'cmake':subprocess.check_output(['cmake','--version'],text=True)}
    body['fingerprint']=hashlib.sha256(json.dumps(body,sort_keys=True).encode()).hexdigest();return body
def owned_roots(faults,fingerprint):
    mode='test' if faults else 'native'
    return (ROOT/'.build'/('t' if faults else 'n')/fingerprint).resolve(),(ROOT/'.build'/(mode+'-runtime')).resolve()
def static_archives(build):
    return sorted(p for p in build.rglob('*') if p.is_file() and p.suffix.lower() in ('.a','.lib'))
def effective_compilers(build):
    cache=(build/'CMakeCache.txt').read_text()
    names=re.findall(r'^CMAKE_(?:C|CXX)_COMPILER:(?:FILEPATH|STRING)=(.+)$',cache,re.M)
    if not names:raise RuntimeError('DEMBREE_EFFECTIVE_COMPILER_POPULATION')
    return {str(Path(p).resolve(strict=True)):sha(p) for p in names}
def ready(build,prefix,inputs):
    build=Path(build).resolve(strict=True);prefix=Path(prefix).resolve(strict=True)
    if (build,prefix)!=owned_roots(inputs['faults'],inputs['fingerprint']):raise RuntimeError('EMBREE_BUILD_ROOT_IDENTITY')
    if inputs!=input_key(inputs['faults']):raise RuntimeError('EMBREE_BUILD_FINGERPRINT')
    upstream=build/'s'
    pre=json.loads((ROOT/'native/patches/preimages.json').read_text())
    for name,entry in pre.items():
        if sha(upstream/name)!=entry['after']:raise RuntimeError('DEMBREE_PATCH_POSTIMAGE')
    paths=[build/'CMakeCache.txt',build/'compile_commands.json']
    paths += list((upstream/'include/embree4').rglob('*.h'))
    paths += list((build/'b').rglob('*.h'))
    archives=static_archives(build/'b')
    if not archives:raise RuntimeError('DEMBREE_STATIC_CLOSURE_POPULATION')
    paths += archives
    paths += [upstream/name for name in pre]
    paths += list((build/'p').rglob('archive.tar'))
    if len(paths)<10:raise RuntimeError('DEMBREE_BUILD_INPUT_POPULATION')
    artifacts={p.relative_to(prefix).as_posix():sha(p) for p in sorted(prefix.rglob('*')) if p.is_file() and p.name!='manifest.json'}
    if not artifacts:raise RuntimeError('DEMBREE_RUNTIME_POPULATION')
    result=dict(inputs,source_root=str(ROOT),build_root=str(build),prefix=str(prefix),native_inputs={str(p):sha(p) for p in sorted(paths)},effective_compilers=effective_compilers(build),artifacts=artifacts)
    (prefix/'manifest.json').write_text(json.dumps(result,indent=2)+'\n');return result

def validate(prefix,production=True):
    prefix=Path(prefix).resolve(strict=True)
    result=json.loads((prefix/'manifest.json').read_text())
    if production and result['faults']:raise RuntimeError('EMBREE_BUILD_MODE_IDENTITY')
    fresh=input_key(result['faults'])
    build,expected_prefix=owned_roots(result['faults'],fresh['fingerprint'])
    if result['source_root']!=str(ROOT) or result['prefix']!=str(prefix) or prefix!=expected_prefix or result['build_root']!=str(build):raise RuntimeError('EMBREE_BUILD_ROOT_IDENTITY')
    if any(result.get(k)!=v for k,v in fresh.items()):raise RuntimeError('EMBREE_BUILD_FINGERPRINT')
    if not build.is_dir() or not result['native_inputs']:raise RuntimeError('EMBREE_DEPENDENCY_INPUT_FRESHNESS')
    if result['effective_compilers']!=effective_compilers(build):raise RuntimeError('EMBREE_BUILD_COMPILER_IDENTITY')
    for path,digest in result['native_inputs'].items():
        p=Path(path).resolve(strict=True)
        if not p.is_relative_to(build) or sha(p)!=digest:raise RuntimeError('EMBREE_DEPENDENCY_INPUT_FRESHNESS '+path)
    if not result['artifacts']:raise RuntimeError('EMBREE_RUNTIME_STAGE')
    for name,digest in result['artifacts'].items():
        path=(prefix/name).resolve(strict=True)
        if not path.is_relative_to(prefix) or sha(path)!=digest:raise RuntimeError('EMBREE_RUNTIME_STAGE '+name)
    return result
