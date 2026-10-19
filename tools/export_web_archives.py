#!/usr/bin/env python3
"""Export CMake's ordered real Web link closure, refusing host archives."""
import hashlib,json,shlex,shutil,sys
from pathlib import Path
from build_manifest import sha
if len(sys.argv)!=3:raise SystemExit('usage: export_web_archives.py BUILD DEST')
build,dest=[Path(p).resolve() for p in sys.argv[1:]]
reply=build/'.cmake/api/v1/reply'
indices=list(reply.glob('index-*.json'))
if not indices:raise SystemExit('EMBREE_WEB_STATIC_CLOSURE: missing CMake file API')
index=json.loads(max(indices).read_text());model=json.loads((reply/index['reply']['codemodel-v2']['jsonFile']).read_text())
config,=model['configurations'];target,=[t for t in config['targets'] if t['name']=='dembree_smoke']
data=json.loads((reply/target['jsonFile']).read_text())
archives=[(build/value).resolve(strict=True) for fragment in data['link']['commandFragments'] if fragment['role']=='libraries' for value in shlex.split(fragment['fragment']) if value.endswith('.a')]
if not archives or archives[0].name!='libdembree.a' or len(set(archives))!=len(archives) or len({p.name for p in archives})!=len(archives):raise SystemExit('EMBREE_WEB_STATIC_CLOSURE')
def wasm_archive(p):
    raw=p.read_bytes()
    if raw[:8]!=b'!<arch>\n':return False
    offset=8;count=0
    while offset<len(raw):
        header=raw[offset:offset+60]
        if len(header)!=60 or header[58:60]!=b'`\n':return False
        size=int(header[48:58]);name=header[:16].decode().strip();body=raw[offset+60:offset+60+size]
        if name.startswith('#1/'):
            n=int(name[3:]);body=body[n:]
        if name not in ('/','//','/SYM64/'):
            if body[:4]!=b'\0asm':return False
            count+=1
        offset+=60+size+(size%2)
    return count>0
if any(not p.is_relative_to(build) or not wasm_archive(p) for p in archives):raise SystemExit('EMBREE_WEB_ARCHITECTURE')
cache=(build/'CMakeCache.txt').read_text()
for term in ['EMBREE_GEOMETRY_USER:BOOL=ON','EMBREE_GEOMETRY_TRIANGLE:BOOL=OFF','EMBREE_TASKING_SYSTEM:STRING=INTERNAL']:
    if term not in cache:raise SystemExit('EMBREE_BUILD_MODE_IDENTITY '+term)
dest.mkdir(parents=True,exist_ok=True);records=[]
for p in archives:
    target=dest/p.name;shutil.copy2(p,target);records.append({'source':str(p),'path':target.name,'sha256':sha(target)})
(dest/'link.rsp').write_text('\n'.join('"'+str(dest/r['path'])+'"' for r in records)+'\n')
manifest={'architecture':'wasm32','order':'CMAKE_FILE_API','faults':'DEMBREE_TEST_FAULTS:BOOL=ON' in cache,'archives':records,'cache_sha256':sha(build/'CMakeCache.txt'),'compile_commands_sha256':sha(build/'compile_commands.json')}
(dest/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('EMBREE_WEB_STATIC_CLOSURE=PASS ARCHIVES='+str(len(records)))
