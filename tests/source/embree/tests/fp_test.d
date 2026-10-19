module embree.tests.fp_test;
import embree.ray_accel;
import embree.c;
import core.stdc.string : memcpy;
private float unpack(uint u) nothrow @nogc { float f;memcpy(&f,&u,4);return f; }
version(EmbreeTestFaults) unittest {
    const old=dembree_test_fp_state(0,0);
    scope(exit) dembree_test_fp_state(old,1);
    uint population;
    foreach(mode;[0u,0x8000u,0x40u,0x8040u]) foreach(uv;0..2) {
        // Pack before enabling FTZ/DAZ and copy raw bytes before restoring it.
        float[] xyz=uv ? [0f,0,1,1,0,1,0,1,1] : [-1f,-1,0x1p-40f,1,-1,0x1p-40f,0,1,0x1p-40f];
        auto ray=uv ? Ray([unpack(0x200),unpack(0x100),0],[0,0,1],1,1) : Ray([0,0,0],[0,0,0x1p100f],unpack(0x200),unpack(0x200));
        RayAccel owner;
        dembree_test_fp_state((old&~0xe040u)|mode,1);
        foreach(phase;0..2) {
            assert((phase?owner.update(xyz):owner.build(xyz,[0u,1,2]))==Status.ok,"PICK_D_FP_SETUP");
            Hit hit;assert(owner.query(ray,hit)==Status.ok && hit.hit,"PICK_D_FP_QUERY");
            uint[5] raw;memcpy(raw.ptr,&hit,20);
            assert(raw[2]==(uv?0x3f800000u:0x200u) && raw[3]==(uv?0x200u:0x3e800000u) && raw[4]==(uv?0x100u:0x3f000000u),"PICK_SUBNORMAL_PUBLICATION");
            ++population;
        }
        dembree_test_fp_state(old,1);
    }
    assert(population==16,"PICK_D_FP_POPULATION");
}
