"""Authenticate the effective rebuilt threaded runtime and its toolchain closure."""
import json,hashlib,os,shlex,subprocess
from pathlib import Path
from build_manifest import sha

def runtime_identity(runtime,ldc,emsdk):
    runtime=Path(runtime).resolve(strict=True);ldc=Path(ldc).resolve(strict=True);emsdk=Path(emsdk).resolve(strict=True)
    toolchain=emsdk/'upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake'
    cache=runtime/'CMakeCache.txt';commands=runtime/'compile_commands.json'
    entries=json.loads(commands.read_text());text=cache.read_text()
    if not entries:raise RuntimeError('DEMBREE_WEB_RUNTIME_COMMAND_POPULATION')
    if 'TARGET_SYSTEM:STRING=Emscripten;UNIX' not in text or str(toolchain) not in text:raise RuntimeError('DEMBREE_WEB_RUNTIME_TOOLCHAIN')
    paths={ldc,ldc.with_name('ldc-build-runtime'),toolchain,cache,commands,Path(__file__).resolve()}
    dcount=ccount=0
    for entry in entries:
        argv=entry.get('arguments') or shlex.split(entry['command'])
        compiler=Path(argv[0]).resolve(strict=True)
        paths.add(compiler)
        source=Path(entry['file']).resolve(strict=True)
        if not source.is_relative_to(runtime/'ldc-src'):raise RuntimeError('DEMBREE_WEB_RUNTIME_SOURCE_ROOT')
        paths.add(source)
        if source.suffix=='.d':
            if compiler!=ldc or not all(t in argv for t in ('-mtriple=wasm32-unknown-emscripten','-mattr=+atomics,+bulk-memory,+simd128')):raise RuntimeError('DEMBREE_WEB_RUNTIME_D_FLAGS')
            dcount+=1
        else:
            if not compiler.is_relative_to(emsdk/'upstream/emscripten') or '-pthread' not in argv:raise RuntimeError('DEMBREE_WEB_RUNTIME_C_FLAGS')
            if source.suffix in ('.cpp','.cc','.cxx') and '-fexceptions' not in argv:raise RuntimeError('DEMBREE_WEB_RUNTIME_CXX_FLAGS')
            ccount+=1
    ninja_commands=subprocess.check_output(['ninja','-C',str(runtime),'-t','commands'],text=True)
    for line in ninja_commands.splitlines():
        argv=shlex.split(line)
        if str(ldc) not in argv:continue
        if '-c' in argv:
            if not all(t in argv for t in ('-mtriple=wasm32-unknown-emscripten','-mattr=+atomics,+bulk-memory,+simd128')):raise RuntimeError('DEMBREE_WEB_RUNTIME_D_FLAGS')
            dcount+=1
        if '-lib' in argv:
            for token in argv:
                if token.endswith('.o'):
                    paths.add((runtime/token).resolve(strict=True))
    if not dcount or not ccount:raise RuntimeError('DEMBREE_WEB_RUNTIME_LANGUAGE_POPULATION')
    for rel in ('ldc-src.zip','ldc-src/runtime/CMakeLists.txt','lib/libphobos2-ldc.a','lib/libdruntime-ldc.a'):
        paths.add(runtime/rel)
    # Imported D modules, generated configuration, archiver commands and all
    # Emscripten driver/configuration modules also affect the actual archives.
    for base in (runtime/'ldc-src/runtime',runtime/'CMakeFiles',emsdk/'upstream/emscripten/tools',emsdk/'upstream/emscripten/cmake',emsdk/'upstream/emscripten/src/settings'):
        paths.update(q for q in base.rglob('*') if q.is_file() and '__pycache__' not in q.parts and q.suffix in ('.d','.h','.c','.cpp','.cmake','.make','.ninja','.txt','.json','.py','.js'))
    for rel in ('upstream/emscripten/emcc','upstream/emscripten/em++','upstream/emscripten/emar','upstream/emscripten/emranlib','upstream/bin/clang','upstream/bin/clang++','upstream/bin/llvm-ar','upstream/bin/wasm-ld','.emscripten'):
        paths.add(emsdk/rel)
    for q in (runtime/'build.ninja',runtime/'rules.ninja',runtime/'CMakeFiles/rules.ninja'):
        if q.is_file():paths.add(q)
    files={str(q):sha(q) for q in sorted(paths)}
    versions={str(q):subprocess.check_output([str(q),'--version'],text=True,stderr=subprocess.STDOUT) for q in (ldc,emsdk/'upstream/emscripten/emcc',emsdk/'upstream/bin/clang')}
    body={'root':str(runtime),'files':files,'versions':versions,'environment':{k:os.environ.get(k) for k in ('EMSDK','EM_CONFIG','EM_CACHE','EMCC_CFLAGS','CFLAGS','CXXFLAGS','LDFLAGS')},'languages':{'D':dcount,'C/C++':ccount},'ninja_commands':ninja_commands}
    return {'fingerprint':hashlib.sha256(json.dumps(body,sort_keys=True).encode()).hexdigest(),'body':body}

def authenticate_runtime(runtime,ldc,emsdk,accept=False):
    stamp=Path(runtime)/'.dembree-toolchain-fingerprint.json'
    fresh=runtime_identity(runtime,ldc,emsdk)
    if accept:stamp.write_text(json.dumps(fresh,indent=2)+'\n')
    elif not stamp.is_file() or json.loads(stamp.read_text())!=fresh:raise RuntimeError('DEMBREE_WEB_RUNTIME_FINGERPRINT')
    return fresh
