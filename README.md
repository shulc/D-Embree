# D-Embree

A small owned ray-acceleration API for D, backed by pinned Embree 4.4.1 USER
geometry. The MIT wrapper exposes six C entry points and a move-only
`embree.ray_accel.RayAccel`. The upstream Apache-2.0 notices are preserved under
`licenses/embree` and installed with the runtime.

## Native

Prerequisites: CMake 3.24+, Python 3.9+, Git, a C++17 compiler, and DMD 2.111+
or LDC 1.41+. Windows additionally requires Ninja and an MSVC x64 developer
environment (including the selected D compiler on PATH); bootstrap selects
Ninja so actual compiler commands can be authenticated. Apple builds currently
support Intel x86_64 only; arm64 and universal builds are refused. Initial configuration downloads the SHA256-authenticated original
upstream archive. No global Embree SDK is used.

```sh
python3 tools/run_dub.py triangle_refit
python3 tools/run_dub.py tests
cmake -S . -B .build/review -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DDEMBREE_TEST_FAULTS=ON
cmake --build .build/review --parallel 6
ctest --test-dir .build/review --output-on-failure
cmake -P native/bootstrap.cmake
python3 tools/stage_runtime.py --prefix .build/native-runtime --dest .build/staged
python3 tools/verify_runtime.py --library .build/staged/libdembree.so --licenses .build/staged/licenses/dembree
```

Use the platform runtime filename (`libdembree.dylib` or `dembree.dll`) on macOS
or Windows. The package run wrapper selects the test or production DLL directory on PATH
before DUB starts; use it for tests/examples on Windows. On Unix, DUB's library configuration supplies development loader paths;
applications explicitly stage the runtime and notices beside their executables.
Staging is required after each application build, even an up-to-date build. The
library hooks write only under this package. Production and fault-enabled test
builds have separate locked, fingerprinted caches. A test runtime cannot satisfy
production staging. `tools/check_public_boundary.py` validates tracked sources
and every local commit before publication.

```d
import embree.ray_accel;
RayAccel tree;
assert(tree.build([0f,0,0,2,0,0,0,2,0], [0u,1,2]) == Status.ok);
auto ray = Ray([.5f,.25f,3], [0,0,-3], 1, 1);
Hit result;
assert(tree.query(ray, result) == Status.ok && result.hit);
```

Calls to one owner must be serialized by its caller. Each owner has its own
native device; internal workers access copied native buffers only. Input slices
are borrowed for the duration of a call. Position updates retain connectivity
and use Embree's LOW/DYNAMIC/REFIT path. Topology changes require `build`.
Disposal is idempotent. Build/update/native-query failures invalidate readiness;
errors are distinct from successful misses. A successful rebuild recovers.
No exception crosses the C ABI.

## Numerical contract

Rays preserve the original, unnormalized parameter. Bounds are finite binary32
with `0 <= near <= far`; both endpoints, singleton intervals and signed zero
are included. Nonfinite inputs, zero direction and invalid intervals are
refused. Geometry bounds must lie strictly inside Embree's native coordinate
envelope `(-1.844E18f,+1.844E18f)`; otherwise build/update returns a native error.
Degenerate and parallel triangles do not have a unique hit.

One USER BVH uses exact dyadic expansion signs for triangle/interval admission
and rational nearest comparison. Equal exact depths retain an unspecified tied
primitive. The owned macro-scoped patch uses conservative scalar binary64
slabs. Final t/u/v use the selected triangle's binary64 solve, then an integer
IEEE round-to-nearest-even binary32 encoder; exact endpoint t copies the
original bound's raw bits. The result ABI is 20 bytes, alignment 4, t/u/v offsets
8/12/16. This preserves subnormal result words with native FTZ/DAZ enabled.
The caller's FP state is preserved. Native queries require both the C floating
point environment and MXCSR rounding controls to select nearest. Unsupported
rounding returns an error before traversal. Fast math and reassociation are
unsupported. The qualified kernel is scalar SSE2 USER geometry; packet,
motion/instance, GPU and other ISA paths are outside this contract. Results
retain a binary64 final refinement and are not exact-rational publications.

## Web

The `web` DUB configuration exposes D sources without native hooks or host
linker flags. Build the package root using the Emscripten toolchain in an
independent build root:

```sh
emcmake cmake -S . -B .build/web -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build .build/web --parallel 6
node .build/web/dembree_smoke.js
node .build/web/dembree_exact.js
python3 tools/export_web_archives.py .build/web .build/web-export
```

The static closure comes from CMake's actual smoke-target link data, in order.
C++ compilation and final linking require `-fexceptions -pthread -msimd128`,
`-sDISABLE_EXCEPTION_CATCHING=0 -sPTHREAD_POOL_SIZE=2`. D and rebuilt
DRuntime/Phobos require the matching wasm atomics/bulk-memory/SIMD features and
threaded C runtime. A browser needs isolated shared Wasm memory, two precreated
workers, and a sufficient stack (the examples use 1 MiB). Hosting and application
asset/worker delivery belong to the consumer. WebAssembly has fixed nearest
arithmetic; no native FTZ/DAZ claim applies to it.

The test sources cover native and Web ABI, copied storage, refit, exact closed
intervals, numerical refinement, subnormal publication, rational nearest and
error recovery. CI definitions are executable recipes, not platform pass
receipts. An actual Linux result does not qualify Windows, macOS or a browser;
report each executed toolchain and platform separately.

The Web proof records and validates the rebuilt runtime CMake cache, every
effective compile command, source/generated inputs, actual archives and compiler/
Emscripten driver identity. `--runtime-root` accepts only an already authenticated
runtime; a mismatch refuses reuse. Omit that option to rebuild a stale runtime.
