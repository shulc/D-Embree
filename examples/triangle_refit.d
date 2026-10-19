import embree.ray_accel;
import std.stdio : writeln;
void main() {
    assert(abiMatches(), "DEMBREE_ABI");
    RayAccel tree;
    float[] xyz=[0,0,0,2,0,0,0,2,0];
    const uint[] triangles=[0,1,2];
    assert(tree.build(xyz,triangles)==Status.ok);
    Ray ray=Ray([.5f,.25f,3],[0,0,-3],1,1);
    Hit hit;
    assert(tree.query(ray,hit)==Status.ok && hit.hit && hit.t==1 && hit.u==.25f && hit.v==.125f);
    foreach(i;0..3) xyz[i*3]+=10;
    assert(tree.update(xyz)==Status.ok);
    ray.origin[0]+=10;
    assert(tree.query(ray,hit)==Status.ok && hit.hit && hit.t==1);
    writeln("DEMBREE_TRIANGLE_REFIT=PASS");
}
