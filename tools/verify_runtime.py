#!/usr/bin/env python3
"""Verify the packaged picking ABI, runtime resolution and pinned notices."""
import argparse
import ctypes as c
import hashlib
import platform
import subprocess
import re
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--library', required=True, type=Path)
parser.add_argument('--licenses', required=True, type=Path)
args = parser.parse_args()
library = args.library.resolve(strict=True)
# Exact notices come from the authenticated upstream source through CMake install.
expected = {
    'LICENSE.txt': 'cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30',
    'third-party-programs.txt': '29688ddc73ea2369e7e94f37f4794bf1b5ccd549b73d0debc022c4533c854a42',
}
for name, digest in expected.items():
    path = args.licenses / name
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
        raise SystemExit('EMBREE_RUNTIME_NOTICE=' + name)
class Ray(c.Structure):
    _fields_ = [('origin', c.c_float*3), ('direction', c.c_float*3), ('near', c.c_float), ('far', c.c_float)]
class Hit(c.Structure):
    _fields_ = [('hit', c.c_uint32), ('triangle', c.c_uint32), ('t', c.c_float), ('u', c.c_float), ('v', c.c_float)]
def check(value, marker):
    if not value:
        raise SystemExit(marker)
expected_exports={'dembree_'+name for name in ('create','build','update','query','dispose','abi')}
if platform.system()=='Linux':
    symbols=subprocess.check_output(['nm','-D','--defined-only',str(library)],text=True)
    exported={line.split()[-1] for line in symbols.splitlines() if line.split()}
elif platform.system()=='Darwin':
    symbols=subprocess.check_output(['nm','-gU',str(library)],text=True)
    exported={line.split()[-1].removeprefix('_') for line in symbols.splitlines() if len(line.split())>=3}
elif platform.system()=='Windows':
    symbols=subprocess.check_output(['dumpbin','/NOLOGO','/EXPORTS',str(library)],text=True)
    exported=set(re.findall(r'^\s+\d+\s+[0-9A-F]+\s+[0-9A-F]+\s+(\w+)',symbols,re.M))
else:raise SystemExit('EMBREE_PUBLIC_EXPORTS: unsupported platform')
check(exported==expected_exports,'EMBREE_PUBLIC_EXPORTS')
lib = c.CDLL(str(library))
check(not hasattr(lib, 'dembree_test_fault'), 'EMBREE_RUNTIME_PRODUCTION_FAULTS_OFF')
class Abi(c.Structure):
    _fields_ = [(name, c.c_uint32) for name in ('ray_size', 'ray_align', 'near_offset', 'hit_size', 'hit_align', 't_offset', 'pointer_size')]
lib.dembree_abi.argtypes = [c.POINTER(Abi)]
lib.dembree_abi.restype = None
abi = Abi()
lib.dembree_abi(c.byref(abi))
check([getattr(abi, name) for name, _ in Abi._fields_] == [c.sizeof(Ray), c.alignment(Ray), Ray.near.offset, c.sizeof(Hit), c.alignment(Hit), Hit.t.offset, c.sizeof(c.c_void_p)], 'EMBREE_RUNTIME_ABI')
lib.dembree_create.argtypes = [c.POINTER(c.c_void_p)]
lib.dembree_build.argtypes = [c.c_void_p, c.POINTER(c.c_float), c.c_uint64, c.POINTER(c.c_uint32), c.c_uint64]
lib.dembree_update.argtypes = [c.c_void_p, c.POINTER(c.c_float), c.c_uint64]
lib.dembree_query.argtypes = [c.c_void_p, c.POINTER(Ray), c.POINTER(Hit)]
lib.dembree_dispose.argtypes = [c.POINTER(c.c_void_p)]
lib.dembree_dispose.restype = None
owner = c.c_void_p()
check(lib.dembree_create(c.byref(owner)) == 0 and owner.value, 'EMBREE_RUNTIME_CREATE')
try:
    xyz = (c.c_float*9)(0,0,0,2,0,0,0,2,0)
    indices = (c.c_uint32*3)(0,1,2)
    check(lib.dembree_build(owner, xyz, 3, indices, 1) == 0, 'EMBREE_RUNTIME_BUILD')
    ray, hit = Ray((.5,.25,3), (0,0,-3), 1,1), Hit()
    check(lib.dembree_query(owner,c.byref(ray),c.byref(hit)) == 0 and hit.hit == 1 and hit.triangle == 0 and hit.t == 1 and hit.u == .25 and hit.v == .125, 'EMBREE_RUNTIME_QUERY')
    for i in range(3): xyz[i*3] += 10
    check(lib.dembree_update(owner,xyz,3) == 0, 'EMBREE_RUNTIME_REFIT')
    ray.origin[0] += 10
    check(lib.dembree_query(owner,c.byref(ray),c.byref(hit)) == 0 and hit.hit == 1 and hit.t == 1, 'EMBREE_RUNTIME_MOVED_QUERY')
finally:
    lib.dembree_dispose(c.byref(owner))
check(not owner.value, 'EMBREE_RUNTIME_DISPOSE')
print('EMBREE_RUNTIME=PASS LIBRARY=' + str(library) + ' SHA256=' + hashlib.sha256(library.read_bytes()).hexdigest() + ' NOTICES=2')
