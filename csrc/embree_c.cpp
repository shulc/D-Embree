#include "embree_c.h"
#include "exact_dyadic.h"
#include <algorithm>
#include <cfenv>
#if (defined(__SSE__) || defined(_M_X64) || defined(_M_IX86)) && !defined(__EMSCRIPTEN__)
#include <xmmintrin.h>
#endif
using namespace dembree_exact;
#include <embree4/rtcore.h>
#include <atomic>
#include <cmath>
#include <cstring>
#include <limits>
#include <new>
#include <stdexcept>

#ifdef DEMBREE_TEST_FAULTS
static std::atomic<uint32_t> live{0};
static std::atomic<uint32_t> builds{0}, updates{0}, queries{0}, caught{0}, disposals{0};
#endif
struct Position { float x,y,z,pad; };
struct Triangle { uint32_t a,b,c; };
struct DembreeOwner {
    RTCDevice device = nullptr;
    RTCScene scene = nullptr;
    RTCGeometry geometry = nullptr;
    Position *positions = nullptr;
    Triangle *triangles = nullptr;
    uint64_t vertices = 0, count = 0;
    std::atomic<int> error{0};
    bool ready = false;
#ifdef DEMBREE_TEST_FAULTS
    uint32_t fault = 0, rejections = 0, lastCallback = UINT32_MAX, refineCalls = 0, callbackCalls = 0, workingBits = 0;
    bool seedFirst = false;
    DembreeOwner() { ++live; }
#endif
    void clear() noexcept {
        ready = false;
        if (geometry) rtcReleaseGeometry(geometry);
        if (scene) rtcReleaseScene(scene);
        geometry = nullptr; scene = nullptr;
        delete[] positions; delete[] triangles;
        positions = nullptr; triangles = nullptr; vertices = count = 0;
    }
    ~DembreeOwner() noexcept {
        clear(); if(device) rtcReleaseDevice(device);
#ifdef DEMBREE_TEST_FAULTS
        --live;
#endif
    }
};
static void errorCallback(void *, RTCError, const char *) noexcept;
#ifdef DEMBREE_TEST_FAULTS
static uint32_t createFault = 0;
static void fault(DembreeOwner *o, uint32_t stage) {
    uint32_t &value = o ? o->fault : createFault;
    if(value == 8 && stage == 7) { value = 0; errorCallback(o,RTC_ERROR_UNKNOWN,"pick test callback"); return; }
    if(value == stage) { value = 0; throw std::bad_alloc(); }
    if(value == 6) { ++caught; value = 0; throw std::runtime_error("pick test exception"); }
}
#else
static void fault(DembreeOwner *, uint32_t) {}
#endif
static void errorCallback(void *ptr, RTCError error, const char *) noexcept {
    static_cast<DembreeOwner *>(ptr)->error.store(int(error));
}
static bool healthy(DembreeOwner *o) noexcept {
    const RTCError code = rtcGetDeviceError(o->device);
    return code == RTC_ERROR_NONE && o->error.exchange(0) == 0;
}
struct QueryContext {
    RTCRayQueryContext context; // Must be first: Embree returns this address.
    const DembreeRay *ray;
    DembreeOwner *owner;
    bool hit=false, failed=false;
    uint32_t id=UINT32_MAX;
    Certificate winner;
};
struct TriangleSolve {
    double ex,ey,ez,fx,fy,fz,sx,sy,sz,den,t;
};
static bool planeSolve(const DembreeOwner *o, uint32_t id, const DembreeRay &r, TriangleSolve &s) noexcept {
    if(id>=o->count) return false;
    const auto tri=o->triangles[id];
    const auto a=o->positions[tri.a], b=o->positions[tri.b], c=o->positions[tri.c];
    s.ex=decode(b.x)-decode(a.x); s.ey=decode(b.y)-decode(a.y); s.ez=decode(b.z)-decode(a.z);
    s.fx=decode(c.x)-decode(a.x); s.fy=decode(c.y)-decode(a.y); s.fz=decode(c.z)-decode(a.z);
    s.sx=decode(r.origin[0])-decode(a.x); s.sy=decode(r.origin[1])-decode(a.y); s.sz=decode(r.origin[2])-decode(a.z);
    const double nx=s.ey*s.fz-s.ez*s.fy, ny=s.ez*s.fx-s.ex*s.fz, nz=s.ex*s.fy-s.ey*s.fx;
    s.den=nx*decode(r.direction[0])+ny*decode(r.direction[1])+nz*decode(r.direction[2]);
    if(s.den==0 || !std::isfinite(s.den)) return false;
    s.t=-(nx*s.sx+ny*s.sy+nz*s.sz)/s.den;
    return std::isfinite(s.t);
}
static bool nativeBounds(const DembreeOwner* o) noexcept {
    const double limit=decode(1.844E18f);
    for(uint64_t i=0;i<o->count;++i) {
        const auto t=o->triangles[i];
        const uint32_t indices[3]={t.a,t.b,t.c};
        for(auto id:indices) {
            const float* p=&o->positions[id].x;
            for(unsigned axis=0;axis<3;++axis) if(decode(p[axis])<=-limit || decode(p[axis])>=limit) return false;
        }
    }
    return true;
}
static void boundsCallback(const RTCBoundsFunctionArguments* args) noexcept {
    auto* o=static_cast<DembreeOwner*>(args->geometryUserPtr);
    if(args->primID>=o->count) { o->error=RTC_ERROR_UNKNOWN; return; }
    const Triangle t=o->triangles[args->primID];
    const uint32_t indices[3]={t.a,t.b,t.c};
    float low[3], high[3];
    for(unsigned j=0;j<3;++j) {
        uint32_t lo=bits((&o->positions[indices[0]].x)[j]),hi=lo;
        for(unsigned k=1;k<3;++k) {
            uint32_t v=bits((&o->positions[indices[k]].x)[j]);
            if(decode(v)<decode(lo)) lo=v;
            if(decode(v)>decode(hi)) hi=v;
        }
        if(std::abs(decode(lo))<0x1p-126) lo=0x80800000u;
        if(std::abs(decode(hi))<0x1p-126) hi=0x00800000u;
        std::memcpy(&low[j],&lo,4); std::memcpy(&high[j],&hi,4);
    }
    auto* b=args->bounds_o;
    b->lower_x=low[0]; b->lower_y=low[1]; b->lower_z=low[2];
    b->upper_x=high[0]; b->upper_y=high[1]; b->upper_z=high[2];
}
static void intersectCallback(const RTCIntersectFunctionNArguments* args) noexcept {
    auto* q=reinterpret_cast<QueryContext*>(args->context);
    if(q->failed) return;
    try {
        if(args->N!=1) throw std::runtime_error("USER_LANE");
        if(!args->valid[0]) return;
        uint32_t id=args->primID;
#ifdef DEMBREE_TEST_FAULTS
        ++q->owner->callbackCalls; q->owner->lastCallback=id;
        if(q->owner->fault==16) { q->owner->fault=0; throw std::runtime_error("EXACT_CAPACITY"); }
        if(q->owner->fault==17) { q->owner->fault=0; throw std::runtime_error("USER_LANE"); }
        if(q->owner->fault==18) { q->owner->fault=0; id=UINT32_MAX; }
        if(q->owner->fault==19) { q->owner->fault=0; throw std::runtime_error("USER_CALLBACK"); }
#endif
        if(id>=q->owner->count) throw std::runtime_error("USER_ID");
        const auto tri=q->owner->triangles[id];
        auto c=solve(&q->owner->positions[tri.a].x,&q->owner->positions[tri.b].x,
            &q->owner->positions[tri.c].x,q->ray->origin,q->ray->direction);
        if(!admitted(c,q->ray->near_t,q->ray->far_t)) {
#ifdef DEMBREE_TEST_FAULTS
            ++q->owner->rejections;
#endif
            return;
        }
        if(q->hit && !nearer(c,q->winner)) return;
        const uint32_t bound=workingBound(c);
        q->winner=c; q->id=id; q->hit=true;
        auto* rh=reinterpret_cast<RTCRayHit*>(args->rayhit);
        std::memcpy(&rh->ray.tfar,&bound,4);
        rh->hit.geomID=args->geomID; rh->hit.primID=id;
        for(unsigned i=0;i<RTC_MAX_INSTANCE_LEVEL_COUNT;++i) rh->hit.instID[i]=RTC_INVALID_GEOMETRY_ID;
#ifdef DEMBREE_TEST_FAULTS
        q->owner->workingBits=bound;
#endif
    } catch(...) { q->failed=true; }
}
static bool arithmeticMode() noexcept {
    if(std::fegetround()!=FE_TONEAREST) return false;
#if (defined(__SSE__) || defined(_M_X64) || defined(_M_IX86)) && !defined(__EMSCRIPTEN__)
    if((_mm_getcsr()&_MM_ROUND_MASK)!=_MM_ROUND_NEAREST) return false;
#endif
    return true;
}
static bool refine(const DembreeOwner *o, uint32_t id, const DembreeRay &r, const Certificate& certificate, DembreeHit &result) {
    TriangleSolve s;
#ifdef DEMBREE_TEST_FAULTS
    if(o->fault==9) id=UINT32_MAX;
#endif
    if(!planeSolve(o,id,r,s)) return false;
#ifdef DEMBREE_TEST_FAULTS
    if(o->fault==10) s.den=0;
#endif
    if(s.den==0 || !std::isfinite(s.den)) return false;
    const double dx=decode(r.direction[0]), dy=decode(r.direction[1]), dz=decode(r.direction[2]);
    double u=-(s.sx*(dy*s.fz-dz*s.fy)+s.sy*(dz*s.fx-dx*s.fz)+s.sz*(dx*s.fy-dy*s.fx))/s.den;
    double v=-(dx*(s.sy*s.ez-s.sz*s.ey)+dy*(s.sz*s.ex-s.sx*s.ez)+dz*(s.sx*s.ey-s.sy*s.ex))/s.den;
#ifdef DEMBREE_TEST_FAULTS
    if(o->fault==11) u=std::numeric_limits<double>::infinity();
    if(o->fault==12) u=std::numeric_limits<double>::max();
    if(o->fault==14) v=std::numeric_limits<double>::max();
    if(o->fault==15) v=std::numeric_limits<double>::infinity();
    if(o->fault==13) s.t=std::nextafter(double(r.far_t),std::numeric_limits<double>::infinity());
#endif
    if(!std::isfinite(s.t) || !std::isfinite(u) || !std::isfinite(v)) return false;
    uint32_t tb=encode(s.t), ub=encode(u), vb=encode(v);
    if(lower(certificate,r.near_t).sign()==0) tb=bits(r.near_t);
    else if(upper(certificate,r.far_t).sign()==0) tb=bits(r.far_t);
#ifdef DEMBREE_TEST_FAULTS
    if(o->fault==13) tb=bits(r.far_t)+1;
    if(o->fault==20) tb=0;
#endif
    if(!finite(tb)||!finite(ub)||!finite(vb)||decode(tb)<decode(r.near_t)||decode(tb)>decode(r.far_t)) return false;
    const uint32_t words[5]={1,id,tb,ub,vb};
    static_assert(sizeof(result)==sizeof(words),"result ABI");
    std::memcpy(&result,words,sizeof(words));
    return true;
}
static bool validPositions(const float *p,uint64_t n) noexcept {
    if(!p || !n || n>UINT32_MAX || n>SIZE_MAX/sizeof(Position) || n>SIZE_MAX/3) return false;
    for(uint64_t i=0;i<n*3;++i) if(!finite(bits(p[i]))) return false;
    return true;
}
static void copyPositions(DembreeOwner *o,const float *p) noexcept {
    for(uint64_t i=0;i<o->vertices;++i) o->positions[i]={p[i*3],p[i*3+1],p[i*3+2],0};
}
extern "C" {
int dembree_create(DembreeOwner **out) {
    if(!out || *out) return DEMBREE_INVALID;
    DembreeOwner *o=nullptr;
    try {
        fault(nullptr,1);
        o=new DembreeOwner;
#ifdef __EMSCRIPTEN__
        o->device=rtcNewDevice("threads=2");
#else
        o->device=rtcNewDevice(nullptr);
#endif
        if(!o->device) { delete o; return DEMBREE_NATIVE_ERROR; }
        rtcSetDeviceErrorFunction(o->device,errorCallback,o);
        if(!healthy(o)) { delete o; return DEMBREE_NATIVE_ERROR; }
        *out=o;
        return DEMBREE_OK;
    } catch(const std::bad_alloc &) { delete o; return DEMBREE_NO_MEMORY; }
      catch(...) { delete o; return DEMBREE_NATIVE_ERROR; }
}
int dembree_build(DembreeOwner *o,const float *xyz,uint64_t vertices,const uint32_t *triples,uint64_t count) {
    if(!o) return DEMBREE_INVALID;
    o->clear();
#ifdef DEMBREE_TEST_FAULTS
    ++builds;
#endif
    try {
        if(!validPositions(xyz,vertices) || !triples || !count || count>UINT32_MAX || count>SIZE_MAX/sizeof(Triangle) || count>SIZE_MAX/3) return DEMBREE_INVALID;
        for(uint64_t i=0;i<count*3;++i) if(triples[i]>=vertices) return DEMBREE_INVALID;
        o->error=0; (void)rtcGetDeviceError(o->device);
        fault(o,2);
        o->scene=rtcNewScene(o->device);
        if(!o->scene) { o->clear(); return DEMBREE_NATIVE_ERROR; }
        rtcSetSceneFlags(o->scene,RTC_SCENE_FLAG_ROBUST | RTC_SCENE_FLAG_DYNAMIC);
        rtcSetSceneBuildQuality(o->scene,RTC_BUILD_QUALITY_LOW);
        o->geometry=rtcNewGeometry(o->device,RTC_GEOMETRY_TYPE_USER);
        if(!o->geometry) { o->clear(); return DEMBREE_NATIVE_ERROR; }
        fault(o,3);
        o->positions=new Position[size_t(vertices)];
        o->triangles=new Triangle[size_t(count)];
        o->vertices=vertices; o->count=count;
        copyPositions(o,xyz); std::memcpy(o->triangles,triples,size_t(count)*sizeof(Triangle));
        if(!nativeBounds(o)) { o->clear(); return DEMBREE_NATIVE_ERROR; }
        rtcSetGeometryBuildQuality(o->geometry,RTC_BUILD_QUALITY_REFIT);
        rtcSetGeometryUserPrimitiveCount(o->geometry,unsigned(count));
        rtcSetGeometryUserData(o->geometry,o);
        rtcSetGeometryBoundsFunction(o->geometry,boundsCallback,o);
        rtcSetGeometryIntersectFunction(o->geometry,intersectCallback);
        fault(o,4);
        rtcCommitGeometry(o->geometry);
        rtcAttachGeometry(o->scene,o->geometry);
        rtcCommitScene(o->scene);
        if(!healthy(o)) { o->clear(); return DEMBREE_NATIVE_ERROR; }
        o->ready=true;
        return DEMBREE_OK;
    } catch(const std::bad_alloc &) { o->clear(); return DEMBREE_NO_MEMORY; }
      catch(...) { o->clear(); return DEMBREE_NATIVE_ERROR; }
}
int dembree_update(DembreeOwner *o,const float *xyz,uint64_t vertices) {
    if(!o) return DEMBREE_INVALID;
    if(!o->ready) return DEMBREE_NOT_READY;
    o->ready=false;
#ifdef DEMBREE_TEST_FAULTS
    ++updates;
#endif
    try {
        if(vertices!=o->vertices || !validPositions(xyz,vertices)) { o->clear(); return DEMBREE_INVALID; }
        fault(o,5); copyPositions(o,xyz);
        if(!nativeBounds(o)) { o->clear(); return DEMBREE_NATIVE_ERROR; }
        rtcCommitGeometry(o->geometry); rtcCommitScene(o->scene);
        if(!healthy(o)) { o->clear(); return DEMBREE_NATIVE_ERROR; }
        o->ready=true; return DEMBREE_OK;
    } catch(const std::bad_alloc &) { o->clear(); return DEMBREE_NO_MEMORY; }
      catch(...) { o->clear(); return DEMBREE_NATIVE_ERROR; }
}
int dembree_query(DembreeOwner *o,const DembreeRay *ray,DembreeHit *out) {
    if(out) *out={};
#ifdef DEMBREE_TEST_FAULTS
    ++queries;
#endif
    if(!o || !ray || !out) return DEMBREE_INVALID;
    for(unsigned i=0;i<3;++i) if(!finite(bits(ray->origin[i])) || !finite(bits(ray->direction[i]))) return DEMBREE_INVALID;
    if((decode(ray->direction[0])==0 && decode(ray->direction[1])==0 && decode(ray->direction[2])==0) ||
        !finite(bits(ray->near_t)) || !finite(bits(ray->far_t)) || decode(ray->near_t)<0 ||
        decode(ray->near_t)>decode(ray->far_t)) return DEMBREE_INVALID;
    if(!o->ready) return DEMBREE_NOT_READY;
    if(!arithmeticMode()) { o->clear(); return DEMBREE_NATIVE_ERROR; }
    try {
        fault(o,7);
        RTCRayHit rh={};
        rh.ray.org_x=ray->origin[0]; rh.ray.org_y=ray->origin[1]; rh.ray.org_z=ray->origin[2];
        rh.ray.dir_x=ray->direction[0]; rh.ray.dir_y=ray->direction[1]; rh.ray.dir_z=ray->direction[2];
        rh.ray.tnear=0; rh.ray.tfar=std::numeric_limits<float>::infinity();
        rh.ray.mask=UINT32_MAX; rh.hit.geomID=RTC_INVALID_GEOMETRY_ID;
        QueryContext q={}; rtcInitRayQueryContext(&q.context); q.ray=ray; q.owner=o;
        RTCIntersectArguments args; rtcInitIntersectArguments(&args); args.context=&q.context;
#ifdef DEMBREE_TEST_FAULTS
        if(o->seedFirst) {
            int valid=-1; RTCIntersectFunctionNArguments seed={};
            seed.valid=&valid; seed.geometryUserPtr=o; seed.context=&q.context;
            seed.rayhit=reinterpret_cast<RTCRayHitN*>(&rh); seed.N=1; seed.primID=0; seed.geomID=0;
            intersectCallback(&seed);
        }
#endif
        rtcIntersect1(o->scene,&rh,&args);
        if(q.failed || !healthy(o)) { o->clear(); return DEMBREE_NATIVE_ERROR; }
        if(q.hit) {
            #ifdef DEMBREE_TEST_FAULTS
            ++o->refineCalls;
#endif
            const bool refined=refine(o,q.id,*ray,q.winner,*out);
#ifdef DEMBREE_TEST_FAULTS
            if(o->fault>=9 && o->fault<=20) o->fault=0;
#endif
            if(!refined) { *out={}; o->clear(); return DEMBREE_NATIVE_ERROR; }
        }
        return DEMBREE_OK;
    } catch(const std::bad_alloc &) { *out={}; o->clear(); return DEMBREE_NO_MEMORY; }
      catch(...) { *out={}; o->clear(); return DEMBREE_NATIVE_ERROR; }
}
void dembree_dispose(DembreeOwner **o) {
    if(o && *o) {
        #ifdef DEMBREE_TEST_FAULTS
        ++disposals;
        #endif
        delete *o; *o=nullptr;
    }
}
void dembree_abi(DembreeAbi *a) {
    if(a) *a={sizeof(DembreeRay),alignof(DembreeRay),offsetof(DembreeRay,near_t),sizeof(DembreeHit),alignof(DembreeHit),offsetof(DembreeHit,t),sizeof(void *)};
}
#ifdef DEMBREE_TEST_FAULTS
void dembree_test_fault(DembreeOwner *o,uint32_t f) { if(o) o->fault=f; else createFault=f; }
uint32_t dembree_test_live() { return live.load(); }
void dembree_test_counts(DembreeTestCounts *out) { if(out) *out={builds.load(),updates.load(),queries.load(),caught.load(),disposals.load()}; }
uint32_t dembree_test_last_callback(DembreeOwner *o) { return o ? o->lastCallback : UINT32_MAX; }
uint32_t dembree_test_refine_calls(DembreeOwner *o) { return o ? o->refineCalls : 0; }
void dembree_test_seed_first(DembreeOwner* o,uint32_t v) { if(o) o->seedFirst=v!=0; }
uint32_t dembree_test_working_bound(DembreeOwner* o) { return o ? o->workingBits : 0; }
uint32_t dembree_test_callback_calls(DembreeOwner* o) { return o ? o->callbackCalls : 0; }
uint32_t dembree_test_rne(double v) { return encode(v); }
uint32_t dembree_test_rejections(DembreeOwner *o) { return o ? o->rejections : 0; }
#endif
}
