#!/usr/bin/env python3
"""Synthetic provenance controls; real build/loader proofs run separately."""
import copy,json,os,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tools'))
import build_manifest as native
import web_runtime_manifest as web

class Provenance(unittest.TestCase):
    def test_native(self):
        with tempfile.TemporaryDirectory() as t:
            root=Path(t).resolve()
            for d in native.SOURCE_DIRS:(root/d).mkdir()
            for f in ('CMakeLists.txt','dub.json','LICENSE','THIRD_PARTY_LICENSES.md'):(root/f).write_text('fixture')
            (root/'native/patches').mkdir();(root/'native/patches/preimages.json').write_text('{}')
            with patch.object(native,'ROOT',root):
                inputs=native.input_key(False);build,prefix=native.owned_roots(False,inputs['fingerprint']);build.mkdir(parents=True);prefix.mkdir(parents=True)
                (prefix/'lib').mkdir();(prefix/'lib/dembree.dll').write_text('runtime')
                upstream=build/'_deps/dembree_upstream-src/include/embree4';upstream.mkdir(parents=True)
                for i in range(9):(upstream/(str(i)+'.h')).write_text(str(i))
                archive=build/'_deps/dembree_upstream-build';archive.mkdir();(archive/'embree.lib').write_text('static')
                (build/'CMakeCache.txt').write_text('CMAKE_CXX_COMPILER:FILEPATH='+sys.executable+'\n')
                (build/'compile_commands.json').write_text('[]')
                good=native.ready(build,prefix,inputs)
                self.assertEqual(native.validate(prefix),good,'NATIVE_CURRENT')
                self.assertIn(str(archive/'embree.lib'),good['native_inputs'],'MSVC_STATIC_CLOSURE')
                mutations={'source_root':'elsewhere','prefix':'elsewhere','build_root':str(build.parent),'fingerprint':'stale','compiler':{},'environment':{},'sources':{}}
                for key,value in mutations.items():
                    bad=copy.deepcopy(good);bad[key]=value;(prefix/'manifest.json').write_text(json.dumps(bad))
                    with self.assertRaises((RuntimeError,OSError),msg='NATIVE_REFUSE_'+key):native.validate(prefix)
                (prefix/'manifest.json').write_text(json.dumps(good))
                with patch.dict(os.environ,{'CXXFLAGS':'changed'}):
                    with self.assertRaises(RuntimeError,msg='NATIVE_FRESH_ENVIRONMENT'):native.validate(prefix)
                (prefix/'lib/dembree.dll').write_text('corrupt')
                with self.assertRaisesRegex(RuntimeError,'EMBREE_RUNTIME_STAGE',msg='NATIVE_ARTIFACT_BYTES'):native.validate(prefix)
                (prefix/'lib/dembree.dll').write_text('runtime')
                (archive/'embree.lib').write_text('corrupt')
                with self.assertRaisesRegex(RuntimeError,'EMBREE_DEPENDENCY_INPUT_FRESHNESS',msg='NATIVE_ARCHIVE_BYTES'):native.validate(prefix)
    def test_windows_generator(self):
        with patch.object(native.os,'name','nt'),patch.object(native.shutil,'which',return_value='ninja'),patch.dict(os.environ,{'CMAKE_GENERATOR':'Ninja'}):
            self.assertEqual(native.native_generator(),['-G','Ninja'],'WINDOWS_NINJA')
            with patch.dict(os.environ,{'CMAKE_GENERATOR':'Visual Studio'}):
                with self.assertRaisesRegex(RuntimeError,'DEMBREE_NATIVE_GENERATOR'):native.native_generator()
            with patch.object(native.shutil,'which',return_value=None):
                with self.assertRaisesRegex(RuntimeError,'DEMBREE_NATIVE_GENERATOR'):native.native_generator()
    def test_web(self):
        with tempfile.TemporaryDirectory() as t:
            root=Path(t);runtime=root/'runtime';sdk=root/'sdk';ldc=root/'bin/ldc2'
            files=[ldc,ldc.with_name('ldc-build-runtime')]
            files += [sdk/rel for rel in ('upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake','upstream/emscripten/emcc','upstream/emscripten/em++','upstream/emscripten/emar','upstream/emscripten/emranlib','upstream/bin/clang','upstream/bin/clang++','upstream/bin/llvm-ar','upstream/bin/wasm-ld','.emscripten')]
            files += [runtime/rel for rel in ('ldc-src.zip','ldc-src/runtime/CMakeLists.txt','ldc-src/runtime/a.d','ldc-src/runtime/a.c','lib/libphobos2-ldc.a','lib/libdruntime-ldc.a','objects/a.o','build.ninja')]
            for f in files:f.parent.mkdir(parents=True,exist_ok=True);f.write_text('fixture')
            cache=runtime/'CMakeCache.txt';cache.write_text('TARGET_SYSTEM:STRING=Emscripten;UNIX\nCMAKE_TOOLCHAIN_FILE:FILEPATH='+str(sdk/'upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake'))
            commands=runtime/'compile_commands.json';entries=[{'arguments':[str(sdk/'upstream/emscripten/emcc'),'-pthread','-c',str(runtime/'ldc-src/runtime/a.c')],'file':str(runtime/'ldc-src/runtime/a.c')}];commands.write_text(json.dumps(entries))
            ninja=str(ldc)+' -c -mtriple=wasm32-unknown-emscripten -mattr=+atomics,+bulk-memory,+simd128 a.d\n'+str(ldc)+' -lib objects/a.o'
            def output(argv,**kw):return ninja if argv[0]=='ninja' else 'fixture version'
            with patch.object(web.subprocess,'check_output',side_effect=output):
                good=web.authenticate_runtime(runtime,ldc,sdk,accept=True)
                self.assertEqual(web.authenticate_runtime(runtime,ldc,sdk),good,'WEB_AUTHENTICATED_REUSE')
                for f in (cache,commands,sdk/'upstream/bin/clang',runtime/'lib/libphobos2-ldc.a',runtime/'objects/a.o',runtime/'ldc-src/runtime/a.d',runtime/'build.ninja'):
                    original=f.read_bytes();f.write_bytes(original+b' ')
                    with self.assertRaises((RuntimeError,ValueError),msg='WEB_REFUSE_'+f.name):web.authenticate_runtime(runtime,ldc,sdk)
                    f.write_bytes(original)
                with patch.object(web.subprocess,'check_output',return_value=ninja.replace('-mattr=+atomics,+bulk-memory,+simd128','')):
                    with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_D_FLAGS'):web.authenticate_runtime(runtime,ldc,sdk)
                bad=copy.deepcopy(entries);bad[0]['arguments'].remove('-pthread');commands.write_text(json.dumps(bad))
                with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_C_FLAGS'):web.authenticate_runtime(runtime,ldc,sdk)
if __name__=='__main__':unittest.main()
