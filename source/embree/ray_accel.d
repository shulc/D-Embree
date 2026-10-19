module embree.ray_accel;
public import embree.c : Ray, Hit, Status;
private import embree.c;

/// Serialized calling-thread owner of native copied geometry.
/// Failure statuses are distinct from a successful miss; no GC pointer survives a call.
bool abiMatches() nothrow @nogc {
    Abi a;
    dembree_abi(&a);
    return a.raySize == Ray.sizeof && a.rayAlign == Ray.alignof &&
        a.nearOffset == Ray.nearT.offsetof && a.hitSize == Hit.sizeof &&
        a.hitAlign == Hit.alignof && a.tOffset == Hit.t.offsetof &&
        a.pointerSize == (void*).sizeof;
}

struct RayAccel {
    private DembreeOwner* owner;
    @disable this(this);
    ~this() nothrow @nogc { dispose(); }

    void dispose() nothrow @nogc { dembree_dispose(&owner); }

    Status build(scope const(float)[] xyz, scope const(uint)[] triples) nothrow @nogc {
        if (xyz.length % 3 || triples.length % 3) {
            dispose();
            return Status.invalid;
        }
        if (!owner) {
            auto status = cast(Status) dembree_create(&owner);
            if (status != Status.ok) return status;
        }
        return cast(Status) dembree_build(owner, xyz.ptr, xyz.length / 3,
            triples.ptr, triples.length / 3);
    }

    Status update(scope const(float)[] xyz) nothrow @nogc {
        if (xyz.length % 3) {
            dispose();
            return Status.invalid;
        }
        return cast(Status) dembree_update(owner, xyz.ptr, xyz.length / 3);
    }

    Status query(ref const Ray ray, out Hit hit) nothrow @nogc {
        return cast(Status) dembree_query(owner, &ray, &hit);
    }

    version (EmbreeTestFaults) {
        uint testLastCallback() nothrow @nogc { return dembree_test_last_callback(owner); }
        uint testRefineCalls() nothrow @nogc { return dembree_test_refine_calls(owner); }
        uint testCallbackCalls() nothrow @nogc { return dembree_test_callback_calls(owner); }
        uint testWorkingBound() nothrow @nogc { return dembree_test_working_bound(owner); }
        void testSeedFirst(bool enabled) nothrow @nogc { dembree_test_seed_first(owner, enabled); }
        void testFault(uint stage) nothrow @nogc { dembree_test_fault(owner, stage); }
    }
}
