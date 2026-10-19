// Copyright (c) 2024-2026 Alexander Shagarov. MIT license; see LICENSE.
#ifndef DEMBREE_EXACT_DYADIC_H
#define DEMBREE_EXACT_DYADIC_H
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <stdexcept>

namespace dembree_exact {
static_assert(sizeof(float)==4 && sizeof(double)==8 &&
    std::numeric_limits<float>::is_iec559 && std::numeric_limits<double>::is_iec559,
    "IEEE binary32/binary64 required");
inline uint32_t bits(float f) noexcept { uint32_t u; std::memcpy(&u,&f,4); return u; }
inline float word(uint32_t u) noexcept { float f; std::memcpy(&f,&u,4); return f; }
inline bool finite(uint32_t u) noexcept { return (u&0x7f800000u)!=0x7f800000u; }
inline double decode(uint32_t u) noexcept {
    const unsigned e=(u>>23)&255;
    const double a=std::ldexp(double((u&0x7fffffu)|(e?0x800000u:0u)), e?int(e)-150:-149);
    return u>>31 ? -a : a;
}
inline double decode(float f) noexcept { return decode(bits(f)); }
inline uint64_t roundedShift(uint64_t a,unsigned shift) noexcept {
    if(!shift) return a;
    if(shift>=64) return 0; // Input significands have at most 53 bits.
    const uint64_t q=a>>shift, rem=a&((uint64_t(1)<<shift)-1), half=uint64_t(1)<<(shift-1);
    return q+(rem>half || (rem==half && (q&1)));
}
// Integer RNE publication preserves subnormals even with native FTZ/DAZ.
inline uint32_t encode(double f) noexcept {
    uint64_t u; std::memcpy(&u,&f,8);
    const uint32_t sign=uint32_t(u>>32)&0x80000000u;
    const unsigned eb=unsigned((u>>52)&2047);
    uint64_t sig=u&0xfffffffffffffull;
    if(eb==2047) return sign|0x7f800000u|(sig?0x400000u:0u);
    int e=eb?int(eb)-1023:-1022;
    if(eb) sig|=uint64_t(1)<<52;
    if(e < -126) return sign|uint32_t(roundedShift(sig,unsigned(-e-97)));
    if(e > 127) return sign|0x7f800000u;
    uint64_t q=roundedShift(sig,29);
    if(q==(uint64_t(1)<<24)) { q>>=1; ++e; }
    if(e>127) return sign|0x7f800000u;
    return sign|uint32_t((e+127)<<23)|uint32_t(q&0x7fffffu);
}

// A grow-expansion applies error-free TwoSum in increasing component order.
// Zero elimination preserves strong nonoverlap. Product residuals use explicit
// FMA, and products/sums are accumulated with the same grow operation. Finite
// binary32 inputs imply degree <=6, quantisation >=2^-894, magnitude <2^800;
// all nonzero components are normal binary64. Fewer than 128 strongly
// nonoverlapping components span this range; each append remains checked.
struct Expansion {
    static constexpr unsigned capacity=128;
    std::array<double,capacity> x{};
    unsigned n=0;
    Expansion() noexcept = default;
    explicit Expansion(double a) noexcept { if(a!=0) x[n++]=a; }
    void grow(double b) {
        if(b==0) return;
        double q=b;
        unsigned m=0;
        for(unsigned i=0;i<n;++i) {
            const double sum=q+x[i], z=sum-q;
            const double error=(q-(sum-z))+(x[i]-z);
            if(error!=0) { if(m==capacity) throw std::runtime_error("EXACT_CAPACITY"); x[m++]=error; }
            q=sum;
        }
        if(q!=0) { if(m==capacity) throw std::runtime_error("EXACT_CAPACITY"); x[m++]=q; }
        n=m;
    }
    int sign() const noexcept { return n ? (x[n-1]>0 ? 1 : -1) : 0; }
    double value() const noexcept { double q=0; for(unsigned i=0;i<n;++i) q+=x[i]; return q; }
};
inline Expansion operator+(Expansion a,const Expansion& b) { for(unsigned i=0;i<b.n;++i) a.grow(b.x[i]); return a; }
inline Expansion operator-(Expansion a,const Expansion& b) { for(unsigned i=0;i<b.n;++i) a.grow(-b.x[i]); return a; }
inline Expansion operator-(Expansion a) noexcept { for(unsigned i=0;i<a.n;++i) a.x[i]=-a.x[i]; return a; }
inline Expansion operator*(const Expansion& a,const Expansion& b) {
    Expansion c;
    for(unsigned i=0;i<a.n;++i) for(unsigned j=0;j<b.n;++j) {
        const double p=a.x[i]*b.x[j], error=std::fma(a.x[i],b.x[j],-p);
        if(!std::isfinite(p)||!std::isfinite(error)) throw std::runtime_error("EXACT_INVARIANT");
        c.grow(error); c.grow(p);
    }
    return c;
}
using Vector=std::array<Expansion,3>;
inline Vector vector(const float* p) { return {{Expansion(decode(p[0])),Expansion(decode(p[1])),Expansion(decode(p[2]))}}; }
inline Vector sub(const Vector& a,const Vector& b) { return {{a[0]-b[0],a[1]-b[1],a[2]-b[2]}}; }
inline Vector cross(const Vector& a,const Vector& b) { return {{a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]}}; }
inline Expansion dot(const Vector& a,const Vector& b) { return a[0]*b[0]+a[1]*b[1]+a[2]*b[2]; }
struct Certificate { Expansion d,t,u,v; };
inline Certificate solve(const float* a,const float* b,const float* c,const float* origin,const float* direction) {
    const Vector av=vector(a), e=sub(vector(b),av), f=sub(vector(c),av), s=sub(vector(origin),av), dir=vector(direction);
    Certificate q={dot(e,cross(f,dir)),-dot(e,cross(f,s)),-dot(s,cross(dir,f)),-dot(dir,cross(s,e))};
    if(q.d.sign()<0) { q.d=-q.d; q.t=-q.t; q.u=-q.u; q.v=-q.v; }
    return q;
}
inline Expansion lower(const Certificate& q,float a) { return q.t-Expansion(decode(a))*q.d; }
inline Expansion upper(const Certificate& q,float b) { return Expansion(decode(b))*q.d-q.t; }
inline bool admitted(const Certificate& q,float a,float b) {
    return q.d.sign()>0 && q.u.sign()>=0 && q.v.sign()>=0 && (q.d-q.u-q.v).sign()>=0 &&
        lower(q,a).sign()>=0 && upper(q,b).sign()>=0;
}
inline bool nearer(const Certificate& q,const Certificate& old) { return (q.t*old.d-old.t*q.d).sign()<0; }
inline uint32_t workingBound(const Certificate& q) {
    uint32_t u=encode(q.t.value()/q.d.value());
    if(u>=0x7f800000u) return 0x7f800000u;
    // Certify before and after the extra outward ULP and the FTZ/DAZ floor.
    while((Expansion(decode(u))*q.d-q.t).sign()<0) {
        if(++u==0x7f800000u) return u;
    }
    if(u<0x7f800000u) ++u;
    if(u<0x00800000u) u=0x00800000u;
    if(u<0x7f800000u && (Expansion(decode(u))*q.d-q.t).sign()<0)
        throw std::runtime_error("TFAR_CERTIFICATE");
    return u;
}
}
#endif
