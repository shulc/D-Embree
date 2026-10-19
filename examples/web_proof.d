import embree.ray_accel;
import embree.c;
import core.stdc.stdio : puts;
import core.stdc.string : memcpy;
private void check(bool value,string marker) { if(!value) throw new Exception(marker); }
private float unpack(uint u) nothrow @nogc { float f; memcpy(&f,&u,4); return f; }
void main() {
    check(abiMatches() && Hit.sizeof==20 && Hit.u.offsetof==12 && Hit.v.offsetof==16,"PICK_D_ABI");
    bool caught;
    try { throw new Exception("owned D exception"); } catch(Exception) { caught=true; }
    check(caught,"PICK_D_EXCEPTION");
    RayAccel owner;
    float[] xyz=[0,0,0,2,0,0,0,2,0];
    uint[] ids=[0,1,2];
    auto ray=Ray([.5f,.25f,3],[0,0,-3],1,1);Hit hit;
    foreach(phase;0..2) {
        check((phase?owner.update(xyz):owner.build(xyz,ids))==Status.ok,"PICK_D_BUILD_REFIT");
        check(owner.query(ray,hit)==Status.ok && hit.hit && hit.t==1 && hit.u==.25f && hit.v==.125f,"PICK_D_QUERY");
    }
    foreach(i;0..3) xyz[i*3]+=10;
    check(owner.update(xyz)==Status.ok,"PICK_D_MOVED_REFIT");ray.origin[0]+=10;
    check(owner.query(ray,hit)==Status.ok && hit.hit,"PICK_REFIT_OUTSIDE_OLD_BOUNDS");
    foreach(uv;0..2) {
        xyz=uv ? [0f,0,1,1,0,1,0,1,1] : [-1f,-1,0x1p-40f,1,-1,0x1p-40f,0,1,0x1p-40f];
        ray=uv ? Ray([unpack(0x200),unpack(0x100),0],[0,0,1],1,1) : Ray([0,0,0],[0,0,0x1p100f],unpack(0x200),unpack(0x200));
        foreach(phase;0..2) {
            check((phase?owner.update(xyz):owner.build(xyz,ids))==Status.ok,"PICK_D_RAW_SETUP");
            check(owner.query(ray,hit)==Status.ok && hit.hit,"PICK_D_RAW_QUERY");
            uint[5] raw;memcpy(raw.ptr,&hit,20);
            check(raw[2]==(uv?0x3f800000u:0x200u) && raw[3]==(uv?0x200u:0x3e800000u) && raw[4]==(uv?0x100u:0x3f000000u),"PICK_SUBNORMAL_PUBLICATION");
        }
    }
    version(EmbreeTestFaults) {
        owner.testFault(19);
        check(owner.query(ray,hit)==Status.nativeError && !hit.hit,"PICK_USER_CALLBACK_ERROR");
        check(owner.query(ray,hit)==Status.notReady,"PICK_D_FAILED_READY");
        check(owner.build(xyz,ids)==Status.ok,"PICK_D_RECOVERY");
        check(owner.query(ray,hit)==Status.ok && hit.hit,"PICK_D_RECOVERY_QUERY");
    }
    puts("DEMBREE_D_WEB=PASS ABI=20/4/8/12/16 REFIT=PASS RAW=PASS D_EXCEPTION=PASS");
}
