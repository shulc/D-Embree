#!/usr/bin/env python3
"""Run package tests/example with the selected runtime on the DLL search path."""
import argparse,os,subprocess,sys
from pathlib import Path
from build_manifest import ROOT,validate
p=argparse.ArgumentParser();p.add_argument('mode',choices=('tests','triangle_refit'));a=p.parse_args()
faults=a.mode=='tests';mode='test' if faults else 'native'
prefix=ROOT/'.build'/(mode+'-runtime')
os.environ['PATH']=str(prefix/'bin')+os.pathsep+os.environ.get('PATH','')
subprocess.run([sys.executable,str(ROOT/'tools/bootstrap.py'),'--faults','ON' if faults else 'OFF'],check=True)
prefix=ROOT/'.build'/(mode+'-runtime');validate(prefix,production=not faults)
env=dict(os.environ)
subprocess.run(['dub','test' if faults else 'run','--config='+a.mode],cwd=ROOT,env=env,check=True)
