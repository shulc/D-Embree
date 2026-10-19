#ifndef DEMBREE_C_H
#define DEMBREE_C_H
#include <stddef.h>
#include <stdint.h>
#if defined(_WIN32)
# if defined(DEMBREE_BUILD)
#  define DEMBREE_API __declspec(dllexport)
# else
#  define DEMBREE_API __declspec(dllimport)
# endif
#else
# define DEMBREE_API __attribute__((visibility("default")))
#endif
#ifdef __cplusplus
extern "C" {
#endif
/* Calls for an owner are serialized on its calling thread. No exception crosses this ABI. Inputs are borrowed only during the call; result records are out params. */
typedef struct DembreeOwner DembreeOwner;
enum DembreeStatus { DEMBREE_OK=0, DEMBREE_INVALID=1, DEMBREE_NOT_READY=2,
    DEMBREE_NATIVE_ERROR=3, DEMBREE_NO_MEMORY=4 };
typedef struct DembreeRay { float origin[3], direction[3], near_t, far_t; } DembreeRay;
typedef struct DembreeHit { uint32_t hit, triangle; float t, u, v; } DembreeHit;
typedef struct DembreeAbi { uint32_t ray_size, ray_align, near_offset,
    hit_size, hit_align, t_offset, pointer_size; } DembreeAbi;
DEMBREE_API int dembree_create(DembreeOwner **out);
DEMBREE_API int dembree_build(DembreeOwner *, const float *xyz, uint64_t vertices,
    const uint32_t *triples, uint64_t triangles);
DEMBREE_API int dembree_update(DembreeOwner *, const float *xyz, uint64_t vertices);
DEMBREE_API int dembree_query(DembreeOwner *, const DembreeRay *, DembreeHit *);
DEMBREE_API void dembree_dispose(DembreeOwner **);
DEMBREE_API void dembree_abi(DembreeAbi *);
#ifdef DEMBREE_TEST_FAULTS
/* Faults 16=exact capacity,17=lane,18=ID,19=callback,20=publication; 1=device,2=scene,3=buffer,4=commit,5=update,6=caught C++ throw.
 * 7=query allocation,8=query device-error callback.
 * 9=final ID,10=determinant,11=ratio,12=float overflow,13=final interval,14/15=v float overflow/ratio. Fault is consumed once. Before create use a null owner. */
DEMBREE_API void dembree_test_fault(DembreeOwner *, uint32_t);
DEMBREE_API uint32_t dembree_test_live(void);
typedef struct DembreeTestCounts { uint32_t builds, updates, queries, caught, disposals; } DembreeTestCounts;
DEMBREE_API void dembree_test_counts(DembreeTestCounts *);
DEMBREE_API uint32_t dembree_test_last_callback(DembreeOwner *);
DEMBREE_API uint32_t dembree_test_refine_calls(DembreeOwner *);
DEMBREE_API void dembree_test_seed_first(DembreeOwner *, uint32_t);
DEMBREE_API uint32_t dembree_test_working_bound(DembreeOwner *);
DEMBREE_API uint32_t dembree_test_callback_calls(DembreeOwner *);
DEMBREE_API uint32_t dembree_test_rne(double);
DEMBREE_API uint32_t dembree_test_rejections(DembreeOwner *);
#endif
#ifdef __cplusplus
}
#endif
#endif
