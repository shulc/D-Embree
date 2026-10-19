module embree.c;
/// Stable C ABI. Inputs are borrowed only during a call; native storage is owned.
enum Status : int { ok, invalid, notReady, nativeError, noMemory }
struct Ray { float[3] origin, direction; float nearT, farT; }
struct Hit { uint hit, triangle; float t, u, v; }
struct Abi { uint raySize, rayAlign, nearOffset, hitSize, hitAlign, tOffset, pointerSize; }
struct DembreeOwner;
extern(C) nothrow @nogc {
    int dembree_create(DembreeOwner**);
    int dembree_build(DembreeOwner*, const(float)*, ulong, const(uint)*, ulong);
    int dembree_update(DembreeOwner*, const(float)*, ulong);
    int dembree_query(DembreeOwner*, const(Ray)*, Hit*);
    void dembree_dispose(DembreeOwner**);
    void dembree_abi(Abi*);
}
version(EmbreeTestFaults) {
    struct TestCounts { uint builds, updates, queries, caught, disposals; }
    extern(C) nothrow @nogc {
        uint dembree_test_live();
        void dembree_test_fault(DembreeOwner*, uint);
        void dembree_test_counts(TestCounts*);
        uint dembree_test_last_callback(DembreeOwner*);
        uint dembree_test_refine_calls(DembreeOwner*);
        uint dembree_test_callback_calls(DembreeOwner*);
        uint dembree_test_working_bound(DembreeOwner*);
        void dembree_test_seed_first(DembreeOwner*, uint);
        uint dembree_test_rne(double);
    }
}
