#include "embree_c.h"
#include "exact_dyadic.h"
#include "closed_intervals.inc"
#include "ieee_rounding.inc"
#include "working_bound.inc"
#include <vector>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <cfenv>
#if (defined(__SSE__) || defined(_M_X64) || defined(_M_IX86)) && !defined(__EMSCRIPTEN__)
#include <xmmintrin.h>
#endif
using namespace dembree_exact;
#define CHECK(x,m) do { if(!(x)) { std::fprintf(stderr,"%s line %d\n",m,__LINE__); std::abort(); } } while(0)
static void tree(std::vector<float>& xyz,std::vector<uint32_t>& ids,unsigned dummies=32) {
    for(unsigned i=0;i<dummies;++i) {
        const float x=100+float(i)*4;
        const float tri[]={x,100,0,x+2,100,0,x,102,0};
        xyz.insert(xyz.end(),tri,tri+9);
    }
    ids.resize(xyz.size()/3);for(unsigned i=0;i<ids.size();++i) ids[i]=i;
}
static std::vector<float> packed(std::initializer_list<double> values) {
    std::vector<float> result;for(auto v:values)result.push_back(word(encode(v)));return result;
}
static void checkQuery(DembreeOwner* o,const DembreeRay& r,uint32_t id,uint32_t t,uint32_t u,uint32_t v,const char* marker) {
    DembreeHit h{};
    CHECK(dembree_query(o,&r,&h)==DEMBREE_OK,marker);
    uint32_t words[5];std::memcpy(words,&h,20);
    CHECK(words[0]==1 && words[1]==id && words[2]==t && words[3]==u && words[4]==v,marker);
}
static void endpoints() {
    unsigned population=0;
    unsigned cellIndex=0;
    for(const auto& c:endpointCells) for(unsigned expanded=0;expanded<2;++expanded) {
        DembreeOwner* o=nullptr;CHECK(dembree_create(&o)==0,"PICK_CREATE");
        for(unsigned phase=0;phase<2;++phase) {
            std::vector<float> xyz;for(auto w:c.xyz)xyz.push_back(word(w));
            DembreeRay ray;std::memcpy(&ray,c.ray,32);
            if(phase) {
                for(auto& f:xyz)f*=2;
                for(unsigned j=0;j<3;++j) { ray.origin[j]*=2;ray.direction[j]*=2; }
            }
            std::vector<uint32_t> ids;tree(xyz,ids,expanded?32:0);
            CHECK(xyz.size()==(expanded?297:9) && ids.size()==(expanded?99:3),"PICK_ENDPOINT_POPULATION");
            CHECK((phase?dembree_update(o,xyz.data(),ids.size()):dembree_build(o,xyz.data(),ids.size(),ids.data(),ids.size()/3))==0,"PICK_ENDPOINT_SETUP");
            const char* markers[]={"PICK_ENDPOINT_TREE_ORDINARY","PICK_ENDPOINT_TREE_ZERO","PICK_ENDPOINT_TREE_SINGLETON","PICK_ENDPOINT_TREE_NEAR","PICK_ENDPOINT_TREE_FAR"};
            checkQuery(o,ray,0,c.expected[0],c.expected[1],c.expected[2],markers[cellIndex/2/8]);
            ++population;
        }
        dembree_dispose(&o);++cellIndex;
    }
    CHECK(population==160,"PICK_ENDPOINT_POPULATION");
}
static void exactNearest() {
    for(unsigned order=0;order<2;++order) for(unsigned winding=0;winding<2;++winding) {
        std::vector<float> xyz;
        for(unsigned j=0;j<2;++j) {
            float z=word(encode(j==order?0x1p-25:0x1p-26));
            const float t[]={0,0,z,2,0,z,0,2,z};xyz.insert(xyz.end(),t,t+9);
        }
        std::vector<uint32_t> ids;tree(xyz,ids);
        if(winding)for(unsigned j=0;j<ids.size();j+=3)std::swap(ids[j+1],ids[j+2]);
        DembreeOwner* o=nullptr;CHECK(dembree_create(&o)==0,"PICK_CREATE");
        DembreeRay r={{.5f,.25f,1},{0,0,-1},0,2};
        for(unsigned phase=0;phase<2;++phase) {
            CHECK((phase?dembree_update(o,xyz.data(),ids.size()):dembree_build(o,xyz.data(),ids.size(),ids.data(),ids.size()/3))==0,"PICK_NEAREST_SETUP");
            DembreeHit h{};CHECK(dembree_query(o,&r,&h)==0 && h.hit && h.triangle==order && h.t==1,"PICK_EXACT_NEAREST");
        }
        dembree_dispose(&o);
    }
}
static void special(unsigned mode) {
    const double z=0x1p-40;
    struct Cell {std::vector<float> xyz;DembreeRay ray;uint32_t t,u,v;const char* marker;};
    std::vector<Cell> cells;
    auto target=packed({-1,-1,z,1,-1,z,0,1,z});
    for(unsigned k=0;k<4;++k) {
        DembreeRay r={{0,0,0},{0,0,word(encode(0x1p100))},word(k<2?0x200:0),word(k==0||k==2?0x200:0x3f800000)};
        cells.push_back({target,r,0x200,0x3e800000,0x3f000000,"PICK_SUBNORMAL_PUBLICATION"});
    }
    cells.push_back({packed({0,0,1,1,0,1,0,1,1}),{{word(0x200),word(0x100),0},{0,0,1},1,1},0x3f800000,0x200,0x100,"PICK_SUBNORMAL_PUBLICATION"});
    cells.push_back({packed({.25,-2,0x1p-100,1.25,-2,0x1p-100,.25,2,0x1p-100}),{{0,0,0},{word(encode(0x1p-50)),0,word(1)},word(encode(0x1p49)),word(encode(0x1p49))},encode(0x1p49),0x3e800000,0x3f000000,"PICK_USER_SLAB_CONSERVATIVE"});
    cells.push_back({packed({0,0,0,0x1p-138,0,0,0,0x1p-138,0}),{{word(0x200),word(0x100),word(0x200)},{0,0,word(0x80000200)},1,1},0x3f800000,0x3e800000,0x3e000000,"PICK_USER_BOUND_FTZ"});
    for(auto& c:cells) {
        std::vector<uint32_t> ids;tree(c.xyz,ids);
        DembreeOwner* o=nullptr;CHECK(dembree_create(&o)==0,"PICK_CREATE");
        for(unsigned phase=0;phase<2;++phase) {
            CHECK((phase?dembree_update(o,c.xyz.data(),ids.size()):dembree_build(o,c.xyz.data(),ids.size(),ids.data(),ids.size()/3))==0,"PICK_SPECIAL_SETUP");
            checkQuery(o,c.ray,0,c.t,c.u,c.v,c.marker);
#ifdef DEMBREE_TEST_FAULTS
            CHECK(dembree_test_callback_calls(o)>0,"PICK_CALLBACK_POPULATION");
            CHECK(dembree_test_working_bound(o)>=0x00800000u,"PICK_TFAR_FTZ_FLOOR");
#endif
        }
        dembree_dispose(&o);
    }
    (void)mode;
}
static void faults() {
#ifdef DEMBREE_TEST_FAULTS
    auto xyz=packed({-1,-1,0x1p-40,1,-1,0x1p-40,0,1,0x1p-40});std::vector<uint32_t> ids;tree(xyz,ids);
    DembreeRay r={{0,0,0},{0,0,word(encode(0x1p100))},word(0x200),word(0x200)};
    DembreeOwner* o=nullptr;CHECK(dembree_create(&o)==0,"PICK_CREATE");
    for(uint32_t fault=16;fault<=20;++fault) for(unsigned phase=0;phase<2;++phase) {
        CHECK(dembree_build(o,xyz.data(),ids.size(),ids.data(),ids.size()/3)==0,"PICK_FAULT_SETUP");
        if(phase)CHECK(dembree_update(o,xyz.data(),ids.size())==0,"PICK_FAULT_SETUP");
        const auto before=dembree_test_callback_calls(o);
        dembree_test_fault(o,fault);DembreeHit h={1,99,99,99,99};
        CHECK(dembree_query(o,&r,&h)==DEMBREE_NATIVE_ERROR,"PICK_USER_CALLBACK_ERROR");
        uint32_t words[5];std::memcpy(words,&h,20);
        CHECK(dembree_test_callback_calls(o)>before,"PICK_CALLBACK_POPULATION");
        for(auto w:words)CHECK(w==0,"PICK_FINAL_PUBLISHED_INTERVAL_GUARD");
        CHECK(dembree_query(o,&r,&h)==DEMBREE_NOT_READY,"PICK_FAILED_READY");
        CHECK(dembree_build(o,xyz.data(),ids.size(),ids.data(),ids.size()/3)==0,"PICK_ERROR_RECOVERY");
        checkQuery(o,r,0,0x200,0x3e800000,0x3f000000,"PICK_ERROR_RECOVERY");
    }
    dembree_dispose(&o);
#endif
}
static void rounding() {
    for(const auto& c:roundingCells) { double d;std::memcpy(&d,&c.input,8);CHECK(encode(d)==c.expected,"PICK_INTEGER_RNE"); }
    Certificate q; q.t=Expansion(1); q.d=Expansion(25);
    auto bound=workingBound(q);
    CHECK(decode(bound)>=1.0/25 && bound>=0x00800000u,"PICK_TFAR_CONSERVATIVE");
    q.t=Expansion(0);CHECK(workingBound(q)>=0x00800000u,"PICK_TFAR_FTZ_FLOOR");
    q.t=Expansion(decode(0x7f7fffffu));q.d=Expansion(1);CHECK(workingBound(q)==0x7f800000u,"PICK_TFAR_CONSERVATIVE");
}
static void seeded() {
#ifdef DEMBREE_TEST_FAULTS
    std::vector<float> xyz;for(auto w:workingTree)xyz.push_back(word(w));
    std::vector<uint32_t> ids(xyz.size()/3);for(unsigned i=0;i<ids.size();++i)ids[i]=i;
    CHECK(ids.size()==195,"PICK_TFAR_TREE_POPULATION");
    for(unsigned seed=0;seed<2;++seed) {
        DembreeOwner* o=nullptr;CHECK(dembree_create(&o)==0,"PICK_CREATE");
        dembree_test_seed_first(o,seed);
        DembreeRay r={{0,0,0},{0,0,word(encode(0x1p100))},0,1};
        for(unsigned phase=0;phase<2;++phase) {
            CHECK((phase?dembree_update(o,xyz.data(),ids.size()):dembree_build(o,xyz.data(),ids.size(),ids.data(),65))==0,"PICK_TFAR_TREE_SETUP");
            checkQuery(o,r,1,0x100,0x3ba237c3,0x3f000000,"PICK_TFAR_FTZ_FLOOR");
            CHECK(dembree_test_callback_calls(o)>0,"PICK_TFAR_CALLBACK_POPULATION");
        }
        dembree_dispose(&o);
    }
#endif
}
static void rangeRefusal() {
    DembreeOwner* o=nullptr;CHECK(dembree_create(&o)==0,"PICK_CREATE");
    float xyz[]={0,0,0,2,0,0,0,2,0};const uint32_t ids[]={0,1,2};
    DembreeRay r={{.5f,.25f,1},{0,0,-1},0,2};DembreeHit h{};
    for(unsigned phase=0;phase<2;++phase) {
        xyz[0]=0;CHECK(dembree_build(o,xyz,3,ids,1)==0,"PICK_RANGE_SETUP");
        xyz[0]=std::numeric_limits<float>::max();
        CHECK((phase?dembree_update(o,xyz,3):dembree_build(o,xyz,3,ids,1))==DEMBREE_NATIVE_ERROR,"PICK_NATIVE_RANGE_REFUSAL");
        CHECK(dembree_query(o,&r,&h)==DEMBREE_NOT_READY && !h.hit,"PICK_RANGE_FAILED_READY");
        xyz[0]=0;CHECK(dembree_build(o,xyz,3,ids,1)==0,"PICK_RANGE_RECOVERY");
        CHECK(dembree_query(o,&r,&h)==0 && h.hit,"PICK_RANGE_RECOVERY");
    }
    dembree_dispose(&o);
}
static void unsupportedMode() {
#if (defined(__SSE__) || defined(_M_X64) || defined(_M_IX86)) && !defined(__EMSCRIPTEN__)
    const auto old=_mm_getcsr();
    for(auto mode:{0x2000u,0x4000u,0x6000u}) for(unsigned phase=0;phase<2;++phase) {
        DembreeOwner* o=nullptr;CHECK(dembree_create(&o)==0,"PICK_CREATE");
        const float xyz[]={0,0,0,2,0,0,0,2,0};const uint32_t ids[]={0,1,2};
        CHECK(dembree_build(o,xyz,3,ids,1)==0,"PICK_FP_SETUP");
        if(phase)CHECK(dembree_update(o,xyz,3)==0,"PICK_FP_SETUP");
        DembreeRay r={{.5f,.25f,1},{0,0,-1},0,2};DembreeHit h={1,99,99,99,99};
#ifdef DEMBREE_TEST_FAULTS
        const auto before=dembree_test_callback_calls(o);
#endif
        _mm_setcsr((old&~0x6000u)|mode);
        const int status=dembree_query(o,&r,&h);
        _mm_setcsr(old);
        CHECK(status==DEMBREE_NATIVE_ERROR && !h.hit,"PICK_FP_ARITHMETIC_MODE");
#ifdef DEMBREE_TEST_FAULTS
        CHECK(dembree_test_callback_calls(o)==before,"PICK_FP_BEFORE_CALLBACK");
#endif
        CHECK(dembree_query(o,&r,&h)==DEMBREE_NOT_READY,"PICK_FP_FAILED_READY");
        CHECK(dembree_build(o,xyz,3,ids,1)==0,"PICK_FP_RECOVERY");
        CHECK(dembree_query(o,&r,&h)==0 && h.hit,"PICK_FP_RECOVERY");
        dembree_dispose(&o);
    }
#endif
}
int main() {
    endpoints();exactNearest();rangeRefusal();unsupportedMode();
#if (defined(__SSE__) || defined(_M_X64) || defined(_M_IX86)) && !defined(__EMSCRIPTEN__)
    const unsigned old=_mm_getcsr();
    for(unsigned mode:{0u,0x8000u,0x40u,0x8040u}) { _mm_setcsr((old&~0xe040u)|mode);special(mode);faults();rounding();seeded(); }
    _mm_setcsr(old);
#else
    special(0);faults();rounding();seeded();
#endif
    std::puts("DEMBREE_EXACT=PASS ENDPOINTS=160 ABI=20/4/8/12/16");
}
