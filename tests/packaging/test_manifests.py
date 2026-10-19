#!/usr/bin/env python3
"""Synthetic provenance controls; real build/loader proofs run separately."""
import copy,json,os,sys,tempfile,unittest,runpy,shlex
from pathlib import Path,PureWindowsPath
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tools'))
import build_manifest as native
import web_runtime_manifest as web

class WindowsRelativePath(type(Path())):
    """Keep host filesystem I/O; model Windows relative path serialization."""
    def relative_to(self,*args,**kwargs):
        return PureWindowsPath(super().relative_to(*args,**kwargs))

class Provenance(unittest.TestCase):
    def test_native(self):
        with tempfile.TemporaryDirectory() as t:
            root=Path(t).resolve()
            for d in native.SOURCE_DIRS:(root/d).mkdir()
            for f in ('CMakeLists.txt','dub.json','LICENSE','THIRD_PARTY_LICENSES.md'):(root/f).write_text('fixture')
            (root/'source/fixture.d').write_text('module fixture;')
            (root/'native/patches').mkdir();(root/'native/patches/preimages.json').write_text('{}')
            with patch.object(native,'ROOT',root):
                inputs=native.input_key(False);build,prefix=native.owned_roots(False,inputs['fingerprint']);build.mkdir(parents=True);prefix.mkdir(parents=True)
                (prefix/'lib').mkdir();(prefix/'lib/dembree.dll').write_text('runtime')
                notices=('LICENSE','THIRD_PARTY_LICENSES.md','LICENSE.txt','third-party-programs.txt')
                for name in notices:
                    target=prefix/'share/licenses/dembree'/name
                    target.parent.mkdir(parents=True,exist_ok=True);target.write_text(name)
                upstream=build/'_deps/dembree_upstream-src/include/embree4';upstream.mkdir(parents=True)
                for i in range(9):(upstream/(str(i)+'.h')).write_text(str(i))
                archive=build/'_deps/dembree_upstream-build';archive.mkdir();(archive/'embree.lib').write_text('static');(archive/'EMBREE_UPPER.LIB').write_text('static')
                compiler=root/'.build/compiler-bin';compiler.write_text('compiler')
                (build/'CMakeCache.txt').write_text('CMAKE_CXX_COMPILER:FILEPATH='+str(compiler)+'\n')
                (build/'compile_commands.json').write_text('[]')
                good=native.ready(build,prefix,inputs)
                expected_artifacts={'lib/dembree.dll',*('share/licenses/dembree/'+name for name in notices)}
                self.assertEqual(set(good['artifacts']),expected_artifacts,'NATIVE_ARTIFACT_POPULATION')
                self.assertEqual(str(WindowsRelativePath(prefix/'share/licenses/dembree/LICENSE').relative_to(prefix)),
                                 'share\\licenses\\dembree\\LICENSE','WINDOWS_PATH_CONSTRUCTION')
                with patch.object(native,'Path',WindowsRelativePath):
                    windows=native.ready(build,prefix,inputs)
                self.assertEqual(windows['artifacts'],good['artifacts'],'NATIVE_ARTIFACT_PORTABLE_PATHS')
                dest=root/'staged'
                with patch.object(sys,'argv',['stage_runtime.py','--prefix',str(prefix),'--dest',str(dest)]):
                    runpy.run_path(str(Path(__file__).resolve().parents[2]/'tools/stage_runtime.py'),run_name='__main__')
                staged=json.loads((dest/'dembree-runtime.json').read_text())
                expected_staged={str(Path('dembree.dll')),*[str(Path('licenses/dembree')/name) for name in notices]}
                self.assertEqual(set(staged['artifacts']),expected_staged,'STAGED_NOTICE_POPULATION')
                for name,digest in staged['artifacts'].items():
                    self.assertEqual(native.sha(dest/name),digest,'STAGED_ARTIFACT_BYTES')
                self.assertEqual(staged['runtime'],'dembree.dll','STAGED_RUNTIME_NAME')
                self.assertEqual(staged['fingerprint'],inputs['fingerprint'],'STAGED_FINGERPRINT')
                self.assertIs(staged['faults'],False,'STAGED_PRODUCTION_MODE')
                self.assertEqual(native.validate(prefix),good,'NATIVE_CURRENT')
                self.assertIn('source/fixture.d',good['sources'],'D_SOURCE_INPUT')
                compiler.write_text('changed')
                with self.assertRaisesRegex(RuntimeError,'EMBREE_BUILD_COMPILER_IDENTITY',msg='EFFECTIVE_COMPILER_BYTES'):native.validate(prefix)
                compiler.write_text('compiler')
                escaped=copy.deepcopy(good);escaped['native_inputs']={str(prefix/'lib/dembree.dll'):native.sha(prefix/'lib/dembree.dll')};(prefix/'manifest.json').write_text(json.dumps(escaped))
                with self.assertRaisesRegex(RuntimeError,'EMBREE_DEPENDENCY_INPUT_FRESHNESS',msg='NATIVE_INPUT_OWNER'):native.validate(prefix)
                (prefix/'manifest.json').write_text(json.dumps(good))
                for key in ('INCLUDE','LIB','LIBPATH','PATH'):
                    with patch.dict(os.environ,{key:'changed'}):
                        with self.assertRaises(RuntimeError,msg='NATIVE_ENV_'+key):native.validate(prefix)
                self.assertIn(str(archive/'embree.lib'),good['native_inputs'],'MSVC_STATIC_CLOSURE')
                self.assertIn(str(archive/'EMBREE_UPPER.LIB'),good['native_inputs'],'MSVC_STATIC_CASE')
                with self.assertRaisesRegex(RuntimeError,'EMBREE_BUILD_ROOT_IDENTITY',msg='READY_ROOT'):native.ready(build.parent,prefix,inputs)
                changed=dict(inputs,configuration='Debug')
                with self.assertRaisesRegex(RuntimeError,'EMBREE_BUILD_FINGERPRINT',msg='READY_FRESH'):native.ready(build,prefix,changed)
                bad=copy.deepcopy(good);bad['faults']=True;(prefix/'manifest.json').write_text(json.dumps(bad))
                with self.assertRaisesRegex(RuntimeError,'EMBREE_BUILD_MODE_IDENTITY',msg='PRODUCTION_FAULTS'):native.validate(prefix)
                (prefix/'manifest.json').write_text(json.dumps(good))
                with patch.object(native,'effective_compilers',return_value={'different':'compiler'}):
                    with self.assertRaisesRegex(RuntimeError,'EMBREE_BUILD_COMPILER_IDENTITY',msg='EFFECTIVE_COMPILER'):native.validate(prefix)
                with patch.dict(os.environ,{'PATH':str(root/'.build/native-runtime/bin')+os.pathsep+os.environ.get('PATH','')}):
                    self.assertEqual(native.input_key(False),inputs,'LOADER_PATH_NORMALIZATION')
                copied=root/'.build/copied-runtime'
                import shutil
                shutil.copytree(prefix,copied);m=copy.deepcopy(good);m['prefix']=str(copied);(copied/'manifest.json').write_text(json.dumps(m))
                with self.assertRaisesRegex(RuntimeError,'EMBREE_BUILD_ROOT_IDENTITY',msg='CURRENT_PREFIX'):native.validate(copied)
                mutations={'source_root':'elsewhere','prefix':'elsewhere','build_root':str(build.parent),'fingerprint':'stale','compiler':{},'environment':{},'sources':{},'native_inputs':{},'artifacts':{}}
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
    def test_run_wrapper(self):
        root=Path(__file__).resolve().parents[2]
        for mode,dub_command,faults,directory in [('tests','test','ON','test-runtime'),('triangle_refit','run','OFF','native-runtime')]:
            with patch.object(sys,'argv',['run_dub.py',mode]),patch.dict(os.environ),patch('subprocess.run') as run,patch.object(native,'validate') as validate:
                runpy.run_path(str(root/'tools/run_dub.py'),run_name='__main__')
                self.assertEqual(run.call_count,2,'DUB_WRAPPER_CALL_POPULATION')
                self.assertEqual(run.call_args_list[0].args[0][-2:],['--faults',faults],'DUB_WRAPPER_BOOTSTRAP_MODE')
                self.assertEqual(run.call_args_list[1].args[0],['dub',dub_command,'--config='+mode],'DUB_WRAPPER_COMMAND')
                self.assertEqual(run.call_args_list[1].kwargs['env']['PATH'].split(os.pathsep)[0],str(root/'.build'/directory/'bin'),'DUB_WRAPPER_LOADER_MODE')
                validate.assert_called_once_with(root/'.build'/directory,production=mode!='tests')
        workflow=(root/'.github/workflows/ci.yml').read_text()
        for term in ('python tools/run_dub.py tests','python tools/run_dub.py triangle_refit','python tools/stage_runtime.py --prefix .build/native-runtime','python tools/verify_runtime.py','-G Ninja','macos-15-intel'):
            self.assertIn(term,workflow,'PRODUCTION_WORKFLOW_'+term)
        ignores=(root/'.gitignore').read_text().splitlines()
        for name in ('/libd-embree.a','/d-embree.lib','/libd-embree.lib'):
            self.assertIn(name,ignores,'DUB_GENERATED_ARCHIVE_'+name)
    def test_web(self):
        with tempfile.TemporaryDirectory() as t:
            root=Path(t).resolve();runtime=root/'runtime';sdk=root/'sdk';ldc=root/'bin/ldc2'
            files=[ldc,ldc.with_name('ldc-build-runtime'),ldc.parent.parent/'etc/ldc2.conf']
            files += [sdk/rel for rel in ('upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake','upstream/emscripten/emcc','upstream/emscripten/em++','upstream/emscripten/emar','upstream/emscripten/emranlib','upstream/bin/clang','upstream/bin/clang++','upstream/bin/llvm-ar','upstream/bin/wasm-ld','.emscripten','cache/include/stdlib.h','upstream/emscripten/emcc.py','upstream/emscripten/src/settings.js')]
            files += [runtime/rel for rel in ('ldc-src.zip','ldc-src/runtime/CMakeLists.txt','ldc-src/runtime/a.d','ldc-src/runtime/a.c','ldc-src/runtime/a.cpp','lib/libphobos2-ldc.a','lib/libdruntime-ldc.a','objects/a.o','build.ninja','generated.d')]
            (runtime/'directory.d').mkdir(parents=True)
            for f in files:f.parent.mkdir(parents=True,exist_ok=True);f.write_text('fixture')
            cache=runtime/'CMakeCache.txt';cache.write_text('TARGET_SYSTEM:STRING=Emscripten;UNIX\nCMAKE_TOOLCHAIN_FILE:FILEPATH='+str(sdk/'upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake'))
            commands=runtime/'compile_commands.json';entries=[{'arguments':[str(sdk/'upstream/emscripten/emcc'),'-pthread','-c',str(runtime/'ldc-src/runtime/a.c')],'file':str(runtime/'ldc-src/runtime/a.c')}];entries.append({'arguments':[str(sdk/'upstream/emscripten/em++'),'-pthread','-fexceptions','-c',str(runtime/'ldc-src/runtime/a.cpp')],'file':str(runtime/'ldc-src/runtime/a.cpp')});commands.write_text(json.dumps(entries))
            ninja=shlex.quote(str(ldc))+' -c -mtriple=wasm32-unknown-emscripten -mattr=+atomics,+bulk-memory,+simd128 a.d\n'+shlex.quote(str(ldc))+' -lib objects/a.o'
            def output(argv,**kw):return (ninja if argv[-1]=='commands' else '    '+str(sdk/'cache/include/stdlib.h')) if argv[0]=='ninja' else 'fixture version'
            with patch.object(web.subprocess,'check_output',side_effect=output):
                with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_FINGERPRINT',msg='WEB_REQUIRES_STAMP'):web.authenticate_runtime(runtime,ldc,sdk)
                good=web.authenticate_runtime(runtime,ldc,sdk,accept=True)
                self.assertEqual(web.authenticate_runtime(runtime,ldc,sdk),good,'WEB_AUTHENTICATED_REUSE')
                for key in ('EMSDK','EM_CONFIG','EM_CACHE','EMCC_CFLAGS','CFLAGS','CXXFLAGS','LDFLAGS'):
                    value=str(sdk/'.emscripten') if key=='EM_CONFIG' else 'changed'
                    with patch.dict(os.environ,{key:value}):
                        with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_FINGERPRINT',msg='WEB_ENV_'+key):web.authenticate_runtime(runtime,ldc,sdk)
                def changed_version(argv,**kw):return output(argv,**kw) if argv[0]=='ninja' else 'changed version'
                with patch.object(web.subprocess,'check_output',side_effect=changed_version):
                    with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_FINGERPRINT',msg='WEB_EFFECTIVE_VERSION'):web.authenticate_runtime(runtime,ldc,sdk)
                for f in (cache,commands,sdk/'upstream/bin/clang',runtime/'lib/libphobos2-ldc.a',runtime/'lib/libdruntime-ldc.a',runtime/'objects/a.o',runtime/'ldc-src/runtime/a.d',runtime/'build.ninja',runtime/'generated.d',sdk/'cache/include/stdlib.h',ldc.parent.parent/'etc/ldc2.conf',sdk/'upstream/emscripten/emcc.py',sdk/'upstream/emscripten/src/settings.js'):
                    original=f.read_bytes();f.write_bytes(original+b' ')
                    with self.assertRaises((RuntimeError,ValueError),msg='WEB_REFUSE_'+f.name):web.authenticate_runtime(runtime,ldc,sdk)
                    f.write_bytes(original)
                for key,value,marker in [('entries',[], 'DEMBREE_WEB_RUNTIME_COMMAND_POPULATION'),('toolchain','wrong','DEMBREE_WEB_RUNTIME_TOOLCHAIN')]:
                    original=commands.read_text() if key=='entries' else cache.read_text()
                    target=commands if key=='entries' else cache
                    target.write_text(json.dumps(value) if key=='entries' else value)
                    with self.assertRaisesRegex(RuntimeError,marker):web.authenticate_runtime(runtime,ldc,sdk)
                    target.write_text(original)
                with patch.object(web.subprocess,'check_output',return_value=''):
                    with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_LANGUAGE_POPULATION'):web.authenticate_runtime(runtime,ldc,sdk)
                with patch.object(web.subprocess,'check_output',return_value=ninja.replace('-mattr=+atomics,+bulk-memory,+simd128','')):
                    with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_D_FLAGS'):web.authenticate_runtime(runtime,ldc,sdk)
                bad=copy.deepcopy(entries);bad[1]['arguments'].remove('-fexceptions');commands.write_text(json.dumps(bad))
                with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_CXX_FLAGS'):web.authenticate_runtime(runtime,ldc,sdk)
                bad=copy.deepcopy(entries);bad[0]['arguments'].remove('-pthread');commands.write_text(json.dumps(bad))
                with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_C_FLAGS'):web.authenticate_runtime(runtime,ldc,sdk)
                bad=copy.deepcopy(entries);bad[0]['arguments'][0]=str(ldc);commands.write_text(json.dumps(bad))
                with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_C_FLAGS'):web.authenticate_runtime(runtime,ldc,sdk)
                bad=copy.deepcopy(entries);bad[0]['file']=str(ldc);commands.write_text(json.dumps(bad))
                with self.assertRaisesRegex(RuntimeError,'DEMBREE_WEB_RUNTIME_SOURCE_ROOT'):web.authenticate_runtime(runtime,ldc,sdk)
if __name__=='__main__':unittest.main()
