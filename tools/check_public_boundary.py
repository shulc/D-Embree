#!/usr/bin/env python3
"""Check curated tracked source and every commit eligible for publication."""
import argparse,hashlib,json,os,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ROOT_FILES={'LICENSE','README.md','THIRD_PARTY_LICENSES.md','CMakeLists.txt','dub.json','.gitignore','.gitattributes'}
ROOT_DIRS={'include','csrc','source','native','tools','tests','examples','licenses','.github'}
FORBIDDEN=[b'vibe'+b'3d',b'task'+b'2026',b'doc/'+b'receipts',b'/'+b'home/',b'lx'+b'sdk',b'\x5cUsers\x5c',b'scratch/'+b'slice']
EXTENSIONS={'.md','.txt','.json','.yml','.yaml','.cmake','.cpp','.h','.d','.py','.map','.apple','.patch','.inc','.tsv'}
def git(root,*args):return subprocess.check_output(['git','-C',str(root),*args])
def check(path,raw,mode):
    parts=Path(path).parts
    if not parts or (len(parts)==1 and path not in ROOT_FILES) or (len(parts)>1 and parts[0] not in ROOT_DIRS):raise ValueError('path '+path)
    if mode=='120000':raise ValueError('symlink '+path)
    if path not in ROOT_FILES and Path(path).suffix not in EXTENSIONS:raise ValueError('type '+path)
    if len(raw)>1024*1024 or b'\0' in raw or raw[:4] in (b'\x7fELF',b'\0asm',b'PK\x03\x04') or raw[:2]==b'MZ':raise ValueError('binary '+path)
    low=raw.lower()+path.lower().encode()
    if any(token.lower() in low for token in FORBIDDEN):raise ValueError('private token '+path)
    if b'\x2e\x2e/' in path.encode():raise ValueError('escape '+path)
def run(root,history=True):
    entries=[s for s in git(root,'ls-files','--stage','-z').decode().split('\0') if s]
    if not entries:raise ValueError('empty tracked tree')
    paths=[];roster=[]
    for entry in entries:
        info,path=entry.split('\t',1);mode=info.split()[0];p=root/path
        if p.is_symlink():raise ValueError('symlink '+path)
        if not p.resolve(strict=True).is_relative_to(root.resolve()):raise ValueError('escape '+path)
        raw=p.read_bytes();check(path,raw,mode);paths.append(path);roster.append((path,hashlib.sha256(raw).hexdigest()))
    for d in ROOT_DIRS:
        if not any(p.startswith(d+'/') for p in paths):raise ValueError('root population '+d)
    commits=[]
    if history:
        commits=git(root,'rev-list','--all').decode().splitlines()
        for rev in commits:
            for entry in git(root,'ls-tree','-rz',rev).split(b'\0'):
                if not entry:continue
                info,path=entry.split(b'\t',1);mode,typ,oid=info.decode().split()
                if typ!='blob':raise ValueError('nonblob '+path.decode())
                check(path.decode(),git(root,'cat-file','blob',oid),mode)
    digest=hashlib.sha256(json.dumps(roster,separators=(',',':')).encode()).hexdigest()
    return {'paths':paths,'files':len(paths),'commits':len(commits),'inventory_sha256':digest}
def selftest():
    good=('source/embree/c.d',b'module embree.c;','100644');check(*good)
    cells=[('source/embree/c.d',b'import '+FORBIDDEN[0]+b'.internal;','100644'),('tests/fixtures/data.json',FORBIDDEN[2],'100644'),('tools/link.py',b'x','120000'),('csrc/a.cpp',b'\x7fELF\0','100644'),('outside/x.d',b'module x;','100644')]
    for cell in cells:
        try:check(*cell)
        except ValueError:continue
        raise ValueError('negative control stayed green')
    # Synthetic history proves a deleted forbidden blob still refuses export.
    with tempfile.TemporaryDirectory() as t:
        r=Path(t);subprocess.run(['git','init','-q','-b','main',t],check=True)
        subprocess.run(['git','-C',t,'config','user.email','fixture@example.invalid'],check=True)
        subprocess.run(['git','-C',t,'config','user.name','Fixture'],check=True)
        for name in ROOT_FILES:(r/name).write_text('fixture')
        for directory in ROOT_DIRS:
            q=r/directory/'fixture.txt';q.parent.mkdir(parents=True,exist_ok=True);q.write_text('fixture')
        p=r/'source/embree/c.d';p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(FORBIDDEN[0])
        staged=[str(q.relative_to(r)) for q in r.rglob('*') if q.is_file() and '.git' not in q.relative_to(r).parts]
        subprocess.run(['git','-C',t,'add','--',*staged],check=True)
        subprocess.run(['git','-C',t,'commit','-qm','fixture'],check=True)
        p.write_text('module embree.c;')
        subprocess.run(['git','-C',t,'add','source/embree/c.d'],check=True)
        subprocess.run(['git','-C',t,'commit','-qm','clean fixture'],check=True)
        run(r,history=False)
        try:run(r,history=True)
        except ValueError as error:
            if 'private token' not in str(error):raise
        else:raise ValueError('history negative stayed green')
    print('EMBREE_PUBLIC_SOURCE_EXPORT_CONTROLS=PASS CELLS=6')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--self-test',action='store_true');p.add_argument('--inventory',type=Path);a=p.parse_args()
    try:
        if a.self_test:selftest()
        result=run(ROOT)
        if a.inventory:a.inventory.write_text(json.dumps(result,indent=2)+'\n')
        print('EMBREE_PUBLIC_SOURCE_EXPORT=PASS FILES='+str(result['files'])+' COMMITS='+str(result['commits'])+' SHA256='+result['inventory_sha256'])
    except (ValueError,OSError,subprocess.CalledProcessError) as e:raise SystemExit('EMBREE_PUBLIC_SOURCE_EXPORT: '+str(e))
