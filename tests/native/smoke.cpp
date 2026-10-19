#include "embree_c.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <cmath>
#include <vector>
#include <cstring>
#define CHECK(value, marker) do { if(!(value)) { std::fprintf(stderr,"%s line %d\n",marker,__LINE__); std::abort(); } } while(0)
#include "refinement_witnesses.inc"
#include "selected_witness.inc"
static void validation() {
    DembreeOwner *o=nullptr;
    CHECK(dembree_create(nullptr)==DEMBREE_INVALID,"PICK_CREATE_NULL");
    CHECK(dembree_create(&o)==0,"PICK_CREATE");
    CHECK(dembree_create(&o)==DEMBREE_INVALID,"PICK_CREATE_EXISTING");
    float xyz[]={0,0,0, 2,0,0, 0,2,0};
    uint32_t ids[]={0,1,2};
    DembreeRay ray={{.5f,.25f,3},{0,0,-3},0,2}; DembreeHit hit={};
    CHECK(dembree_query(o,&ray,&hit)==DEMBREE_NOT_READY,"PICK_EMPTY_QUERY");
    CHECK(dembree_update(nullptr,xyz,3)==DEMBREE_INVALID,"PICK_UPDATE_NULL_OWNER");
    CHECK(dembree_update(o,xyz,3)==DEMBREE_NOT_READY,"PICK_EMPTY_UPDATE");
    CHECK(dembree_build(nullptr,xyz,3,ids,1)==DEMBREE_INVALID,"PICK_BUILD_NULL_OWNER");
    CHECK(dembree_build(o,nullptr,3,ids,1)==DEMBREE_INVALID,"PICK_NULL_POSITIONS");
    CHECK(dembree_build(o,xyz,0,ids,1)==DEMBREE_INVALID,"PICK_ZERO_VERTICES");
    CHECK(dembree_build(o,xyz,uint64_t(UINT32_MAX)+1,ids,1)==DEMBREE_INVALID,"PICK_VERTEX_ABI_BOUND");
    CHECK(dembree_build(o,xyz,3,nullptr,1)==DEMBREE_INVALID,"PICK_NULL_INDICES");
    CHECK(dembree_build(o,xyz,3,ids,0)==DEMBREE_INVALID,"PICK_ZERO_TRIANGLES");
    CHECK(dembree_build(o,xyz,3,reinterpret_cast<const uint32_t *>(uintptr_t(1)),uint64_t(UINT32_MAX)+1)==DEMBREE_INVALID,"PICK_TRIANGLE_ABI_BOUND");
    ids[2]=3;
    CHECK(dembree_build(o,xyz,3,ids,1)==DEMBREE_INVALID,"PICK_INDEX_BOUND");
    ids[2]=2;
    xyz[8]=std::numeric_limits<float>::quiet_NaN();
    CHECK(dembree_build(o,xyz,3,ids,1)==DEMBREE_INVALID,"PICK_POSITION_FINITE");
    xyz[8]=0;
    CHECK(dembree_build(o,xyz,3,ids,1)==0,"PICK_BUILD");
    hit.hit=1;
    CHECK(dembree_query(nullptr,&ray,&hit)==DEMBREE_INVALID && !hit.hit,"PICK_QUERY_NULL_OWNER");
    CHECK(dembree_query(o,nullptr,&hit)==DEMBREE_INVALID,"PICK_QUERY_NULL_RAY");
    CHECK(dembree_query(o,&ray,nullptr)==DEMBREE_INVALID,"PICK_QUERY_NULL_OUTPUT");
    DembreeRay miss=ray; miss.origin[0]=99; hit.hit=1;
    CHECK(dembree_query(o,&miss,&hit)==0 && !hit.hit,"PICK_QUERY_MISS_OUTPUT");
    for(unsigned component=0;component<6;++component) {
        DembreeRay bad=ray;
        (component<3 ? bad.origin[component] : bad.direction[component-3])=std::numeric_limits<float>::infinity();
        CHECK(dembree_query(o,&bad,&hit)==DEMBREE_INVALID,"PICK_RAY_FINITE");
    }
    DembreeRay bad=ray; bad.direction[2]=0;
    CHECK(dembree_query(o,&bad,&hit)==DEMBREE_INVALID,"PICK_RAY_NONZERO");
    bad=ray; bad.near_t=std::numeric_limits<float>::quiet_NaN();
    CHECK(dembree_query(o,&bad,&hit)==DEMBREE_INVALID,"PICK_NEAR_FINITE");
    bad=ray; bad.far_t=std::numeric_limits<float>::infinity();
    CHECK(dembree_query(o,&bad,&hit)==DEMBREE_INVALID,"PICK_FAR_FINITE");
    bad=ray; bad.near_t=2; bad.far_t=1;
    CHECK(dembree_query(o,&bad,&hit)==DEMBREE_INVALID,"PICK_INTERVAL_ORDER");
    CHECK(dembree_update(o,xyz,2)==DEMBREE_INVALID,"PICK_UPDATE_LAYOUT");
    CHECK(dembree_query(o,&ray,&hit)==DEMBREE_NOT_READY,"PICK_INVALID_UPDATE_READY");
    CHECK(dembree_build(o,xyz,3,ids,1)==0,"PICK_RETRY");
    xyz[0]=std::numeric_limits<float>::infinity();
    CHECK(dembree_update(o,xyz,3)==DEMBREE_INVALID,"PICK_UPDATE_FINITE");
    dembree_dispose(&o);
}
static void intervalContinuation() {
    DembreeOwner *o=nullptr;
    CHECK(dembree_create(&o)==0,"PICK_CREATE");
    const float front=std::ldexp(1.0f,-24);
    const float xyz[]={0,0,front, 2,0,front, 0,2,front, 0,0,-1.5f, 2,0,-1.5f, 0,2,-1.5f};
    const uint32_t ids[]={0,1,2,3,4,5};
    CHECK(dembree_build(o,xyz,6,ids,2)==0,"PICK_CONTINUATION_BUILD");
    DembreeRay ray={{.5f,.25f,3},{0,0,-3},1,2}; DembreeHit hit={};
    CHECK(dembree_query(o,&ray,&hit)==0 && hit.hit && hit.triangle==1 && hit.t==1.5f,"PICK_INTERVAL_CONTINUE");
#ifdef DEMBREE_TEST_FAULTS
    CHECK(dembree_test_rejections(o)>0,"PICK_INTERVAL_REJECTION_REACHED");
#endif
    dembree_dispose(&o);
}
static void intervalCells() {
    DembreeOwner *o=nullptr; CHECK(dembree_create(&o)==0,"PICK_CREATE");
    const uint32_t forward[]={0,1,2}, backward[]={0,2,1};
    const float xyz[]={0,0,0,2,0,0,0,2,0};
    for(unsigned winding=0;winding<2;++winding) {
        CHECK(dembree_build(o,xyz,3,winding ? backward : forward,1)==0,"PICK_INTERVAL_BUILD");
        DembreeRay r={{.5f,.25f,3},{0,0,-3},1,1}; DembreeHit h={};
        CHECK(dembree_query(o,&r,&h)==0 && h.hit && h.t==1,"PICK_POSITIVE_SINGLETON");
        r.near_t=std::nextafter(1.0f,2.0f); r.far_t=2;
        CHECK(dembree_query(o,&r,&h)==0 && !h.hit,"PICK_INTERVAL_OUTSIDE_NEAR");
        r.near_t=std::nextafter(1.0f,0.0f);
        CHECK(dembree_query(o,&r,&h)==0 && h.hit,"PICK_NEAR_INSIDE_ULP");
        r.near_t=0; r.far_t=std::nextafter(1.0f,0.0f);
        CHECK(dembree_query(o,&r,&h)==0 && !h.hit,"PICK_INTERVAL_OUTSIDE_FAR");
        r.far_t=std::nextafter(1.0f,2.0f);
        CHECK(dembree_query(o,&r,&h)==0 && h.hit,"PICK_FAR_INSIDE_ULP");
        r.far_t=std::numeric_limits<float>::max();
        CHECK(dembree_query(o,&r,&h)==0 && h.hit,"PICK_FINITE_EXTREME_BOUNDS");
        r.near_t=r.far_t;
        CHECK(dembree_query(o,&r,&h)==0 && !h.hit,"PICK_FINITE_EXTREME_SINGLETON");
        r={{.5f,.25f,0},{0,0,-3},-0.0f,0};
        CHECK(dembree_query(o,&r,&h)==0 && h.hit && h.t==0,"PICK_ZERO_CLOSED");
    }
    const float delta=std::ldexp(1.0f,-24);
    for(float z: {-delta,delta}) {
        const float outside[]={0,0,z,2,0,z,0,2,z};
        CHECK(dembree_build(o,outside,3,forward,1)==0,"PICK_INTERVAL_BUILD");
        DembreeRay r={{.5f,.25f,0},{0,0,-3},0,0}; DembreeHit h={};
        CHECK(dembree_query(o,&r,&h)==0 && !h.hit,"PICK_ZERO_OUTSIDE");
    }
    const float competition[]={0,0,-1,2,0,-1,0,2,-1,0,0,0,2,0,0,0,2,0};
    const uint32_t both[]={0,1,2,3,4,5};
    CHECK(dembree_build(o,competition,6,both,2)==0,"PICK_INTERVAL_BUILD");
    DembreeRay r={{.5f,.25f,0},{0,0,-3},0,2}; DembreeHit h={};
    CHECK(dembree_query(o,&r,&h)==0 && h.hit && h.triangle==1 && h.t==0,"PICK_ZERO_NEAREST");
    const float degenerate[]={0,0,0,1,0,0,2,0,0};
    CHECK(dembree_build(o,degenerate,3,forward,1)==0,"PICK_DEGENERATE_BUILD");
    CHECK(dembree_query(o,&r,&h)==0 && !h.hit,"PICK_DEGENERATE_MISS");
    const float parallel[]={0,0,0,0,2,0,0,0,2};
    CHECK(dembree_build(o,parallel,3,forward,1)==0,"PICK_PARALLEL_BUILD");
    CHECK(dembree_query(o,&r,&h)==0 && !h.hit,"PICK_PARALLEL_MISS");
    dembree_dispose(&o);
}
static void largeRefit() {
    DembreeOwner *o=nullptr;
    CHECK(dembree_create(&o)==0,"PICK_CREATE");
    const unsigned n=4096;
    std::vector<float> xyz(n*9);
    std::vector<uint32_t> ids(n*3);
    for(unsigned i=0;i<n;++i) {
        const float x=float(i*3);
        const float tri[]={x,0,0,x+2,0,0,x,2,0};
        for(unsigned j=0;j<9;++j) xyz[i*9+j]=tri[j];
        for(unsigned j=0;j<3;++j) ids[i*3+j]=i*3+j;
    }
    CHECK(dembree_build(o,xyz.data(),n*3,ids.data(),n)==0,"PICK_LARGE_BUILD");
    for(unsigned i=0;i<n*3;++i) xyz[i*3]+=100000;
    CHECK(dembree_update(o,xyz.data(),n*3)==0,"PICK_LARGE_UPDATE");
    DembreeRay ray={{100000.5f,.25f,3},{0,0,-3},0,2}; DembreeHit hit={};
    CHECK(dembree_query(o,&ray,&hit)==0 && hit.hit && hit.triangle==0 && hit.t==1,"PICK_LARGE_REFIT");
    dembree_dispose(&o);
}
int main() {
    if(std::getenv("PICK_INTERVAL_CELL")) {
        intervalContinuation();
        std::puts("PICK_INTERVAL_CELL=PASS"); return 0;
    }
    if(std::getenv("PICK_NUMERIC_CELL")) {
        refinementWitnesses();
        std::puts("PICK_NUMERIC_CELL=PASS"); return 0;
    }
    if(std::getenv("PICK_SELECTED_CELL")) {
        finalSelectedWitness();
        std::puts("PICK_SELECTED_CELL=PASS"); return 0;
    }
    CHECK(sizeof(DembreeHit)==20 && alignof(DembreeHit)==4 && offsetof(DembreeHit,t)==8 && offsetof(DembreeHit,u)==12 && offsetof(DembreeHit,v)==16,"PICK_FLOAT_ABI_LAYOUT");
    DembreeAbi abi={}; dembree_abi(&abi);
    CHECK(abi.ray_size==sizeof(DembreeRay) && abi.ray_align==alignof(DembreeRay) && abi.near_offset==offsetof(DembreeRay,near_t) && abi.hit_size==sizeof(DembreeHit) && abi.hit_align==alignof(DembreeHit) && abi.t_offset==offsetof(DembreeHit,t) && abi.pointer_size==sizeof(void *),"PICK_ABI");
    DembreeOwner *o=nullptr;
    CHECK(dembree_create(&o)==0,"PICK_CREATE");
    float positions[]={0,0,-1, 2,0,-1, 0,2,-1};
    const uint32_t indices[]={0,1,2};
    CHECK(dembree_build(o,positions,3,indices,1)==0,"PICK_BUILD");
    for(auto &v:positions) v=99;
    DembreeRay ray={{.5f,.25f,2},{0,0,-3},1,2}; DembreeHit hit={};
    CHECK(dembree_query(o,&ray,&hit)==0 && hit.hit && hit.triangle==0 && hit.t==1 && hit.u==.25f && hit.v==.125f,"PICK_NEAR_CLOSED");
    ray={{.5f,.25f,-4},{0,0,3},1,1};
    CHECK(dembree_query(o,&ray,&hit)==0 && hit.hit && hit.t==1,"PICK_TWO_SIDED");
    float moved[]={10,0,0, 12,0,0, 10,2,0};
    CHECK(dembree_update(o,moved,3)==0,"PICK_UPDATE");
    ray={{10.5f,.25f,3},{0,0,-3},0,2};
    CHECK(dembree_query(o,&ray,&hit)==0 && hit.hit && hit.t==1,"PICK_REFIT_OUTSIDE_OLD_BOUNDS");
    for(unsigned i=0;i<3;++i) moved[i*3]-=10;
    CHECK(dembree_update(o,moved,3)==0,"PICK_UPDATE");
    ray={{.5f,.25f,0},{0,0,-3},0,0};
    CHECK(dembree_query(o,&ray,&hit)==0 && hit.hit && hit.t==0 && hit.u==.25f && hit.v==.125f,"PICK_ZERO_CLOSED");
    ray.near_t=-1;
    CHECK(dembree_query(o,&ray,&hit)==DEMBREE_INVALID,"PICK_INVALID_RAY");
#ifdef DEMBREE_TEST_FAULTS
    for(uint32_t f=2;f<=8;++f) {
        CHECK(dembree_build(o,moved,3,indices,1)==0,"PICK_RETRY");
        dembree_test_fault(o,f);
        ray.near_t=0;
        int code=f>=7 ? dembree_query(o,&ray,&hit) : f==5 ? dembree_update(o,moved,3) : dembree_build(o,moved,3,indices,1);
        CHECK(code==(f==6 || f==8 ? DEMBREE_NATIVE_ERROR : DEMBREE_NO_MEMORY),"PICK_NATIVE_ERROR");
        ray.near_t=0;
        CHECK(dembree_query(o,&ray,&hit)==DEMBREE_NOT_READY,"PICK_FAILED_READY");
    }
    CHECK(dembree_build(o,moved,3,indices,1)==0,"PICK_QUERY_THROW_SETUP");
    dembree_test_fault(o,6);
    CHECK(dembree_query(o,&ray,&hit)==DEMBREE_NATIVE_ERROR,"PICK_QUERY_CAUGHT_THROW");
    CHECK(dembree_query(o,&ray,&hit)==DEMBREE_NOT_READY,"PICK_QUERY_THROW_INVALIDATED");
    DembreeOwner *failed=nullptr; dembree_test_fault(nullptr,1);
    CHECK(dembree_create(&failed)==DEMBREE_NO_MEMORY && !failed,"PICK_DEVICE_FAULT");
#endif
    dembree_dispose(&o); dembree_dispose(&o); dembree_dispose(nullptr);
#ifdef DEMBREE_TEST_FAULTS
    CHECK(dembree_test_live()==0,"PICK_OWNER_DISPOSE");
#endif
    refinementWitnesses();
    finalSelectedWitness();
#ifdef DEMBREE_TEST_FAULTS
    {
        DembreeOwner *owner=nullptr; CHECK(dembree_create(&owner)==0,"PICK_CREATE");
        const float xyz[]={0,0,0,2,0,0,0,2,0}; const uint32_t ids[]={0,1,2};
        const DembreeRay r={{.5f,.25f,1},{0,0,-1},0,2};
        for(uint32_t f=9;f<=15;++f) {
            CHECK(dembree_build(owner,xyz,3,ids,1)==0,"PICK_REFINEMENT_ERROR_SETUP");
            const auto before=dembree_test_refine_calls(owner);
            dembree_test_fault(owner,f); DembreeHit h={1,99,99,99,99};
            CHECK(dembree_query(owner,&r,&h)==DEMBREE_NATIVE_ERROR &&
                h.hit==0 && h.triangle==0 && h.t==0 && h.u==0 && h.v==0 &&
                dembree_test_refine_calls(owner)==before+1,"PICK_REFINEMENT_ERROR");
            CHECK(dembree_query(owner,&r,&h)==DEMBREE_NOT_READY,"PICK_REFINEMENT_ERROR_READY");
            CHECK(dembree_build(owner,xyz,3,ids,1)==0,"PICK_REFINEMENT_ERROR_REBUILD");
            CHECK(dembree_query(owner,&r,&h)==0 && h.hit,"PICK_REFINEMENT_ERROR_RECOVERY");
        }
        dembree_dispose(&owner);
    }
#endif
    validation();
    intervalContinuation();
    largeRefit();
    intervalCells();
    std::puts("PICK_NATIVE_SMOKE=PASS ABI=PASS CLOSED=PASS REFIT=PASS FAULTS=PASS");
    return 0;
}
