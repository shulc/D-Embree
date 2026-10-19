module embree.tests.ray_accel_test;
import embree.ray_accel;
import embree.c;

version (PickAccelDisposeProbe) {
    private uint disposedOwners;
    private extern(C) nothrow @nogc void __real_dembree_dispose(void**);
    extern(C) nothrow @nogc void __wrap_dembree_dispose(void** owner) {
        if (owner && *owner) ++disposedOwners;
        __real_dembree_dispose(owner);
    }
}

unittest {
    version (PickAccelDisposeProbe) auto disposedBefore = disposedOwners;
    assert(abiMatches(), "PICK_D_ABI");
    version (EmbreeTestFaults) auto before = dembree_test_live();
    {
        RayAccel owner;
        float[] xyz = [0,0,-1, 2,0,-1, 0,2,-1];
        uint[] indices = [0,1,2];
        assert(owner.build(xyz, indices) == Status.ok, "PICK_D_BUILD");
        xyz[] = 99;
        indices[] = 99;
        Ray ray = { [.5f,.25f,2], [0,0,-3], 1, 2 };
        Hit hit;
        assert(owner.query(ray, hit) == Status.ok && hit.hit && hit.triangle == 0 &&
            hit.t == 1 && hit.u == .25f && hit.v == .125f, "PICK_D_COPIED_NONUNIT_CLOSED");
        ray = Ray([.5f,.25f,-4], [0,0,3], 1, 1);
        assert(owner.query(ray, hit) == Status.ok && hit.hit && hit.t == 1, "PICK_D_TWO_SIDED");
        float[] moved = [10,0,0, 12,0,0, 10,2,0];
        assert(owner.update(moved) == Status.ok, "PICK_D_UPDATE");
        ray = Ray([10.5f,.25f,3], [0,0,-3], 0, 2);
        assert(owner.query(ray, hit) == Status.ok && hit.hit && hit.t == 1, "PICK_D_REFIT");
        ray.origin[0] = 40;
        assert(owner.query(ray, hit) == Status.ok && !hit.hit, "PICK_D_MISS_STATUS");
        ray.nearT = -1;
        assert(owner.query(ray, hit) == Status.invalid && !hit.hit, "PICK_D_INVALID_STATUS");
        ray.nearT = 0;
        assert(owner.update(moved[0..8]) == Status.invalid, "PICK_D_UPDATE_SHAPE");
        assert(owner.query(ray, hit) == Status.invalid, "PICK_D_DISPOSED");
        assert(owner.build(moved, [0u,1,2]) == Status.ok, "PICK_D_RETRY");
        assert(owner.build(moved, [0u,1,2,0]) == Status.invalid, "PICK_D_BUILD_SHAPE");
        owner.dispose(); owner.dispose();
        version (EmbreeTestFaults) {
            foreach (uint stage; 1..9) {
                assert(owner.build(moved, [0u,1,2]) == Status.ok, "PICK_D_FAULT_SETUP");
                owner.dispose();
                if (stage != 1) assert(owner.build(moved, [0u,1,2]) == Status.ok);
                owner.testFault(stage);
                auto status = stage >= 7 ? owner.query(ray, hit) : stage == 5 ? owner.update(moved) : owner.build(moved, [0u,1,2]);
                assert(status == (stage == 6 || stage == 8 ? Status.nativeError : Status.noMemory), "PICK_D_CAUGHT_FAULT");
                ray = Ray([10.5f,.25f,3], [0,0,-3], 0, 2);
                auto queryStatus = owner.query(ray, hit);
                assert(queryStatus == (stage == 1 ? Status.invalid : Status.notReady) && !hit.hit,
                    "PICK_D_FAILED_NOT_READY");
                assert(owner.build(moved, [0u,1,2]) == Status.ok, "PICK_D_FAULT_RETRY");
            }
        }
        assert(owner.build(moved, [0u,1,2]) == Status.ok, "PICK_D_DESTRUCTOR_SETUP");
    }
    version (PickAccelDisposeProbe) {
        version (EmbreeTestFaults) enum expectedDisposals = 11;
        else enum expectedDisposals = 3;
        assert(disposedOwners == disposedBefore + expectedDisposals, "PICK_D_DESTRUCTOR_CALL");
    }
    version (EmbreeTestFaults) assert(dembree_test_live() == before, "PICK_D_DESTRUCTOR");
}

// Expected floats are independently rounded exact rational solutions of packed witnesses.
unittest {
    assert(Hit.sizeof == 20 && Hit.alignof == 4 && Hit.t.offsetof == 8 &&
           Hit.u.offsetof == 12 && Hit.v.offsetof == 16, "PICK_D_ABI");
    {
        float[] xyz=[0.2890625f,-0.234375f,0.06731012463569641f,0.296875f,-0.2265625f,0.04408887028694153f,0.2890625f,-0.2265625f,0.05978432670235634f];
        auto ray=Ray([-0.5801582932472229f,1.5892493724822998f,0.16644199192523956f],[1.7201817035675049f,-3.5878829956054688f,-0.2158174067735672f],0.0010000000474974513f,8.0f);
        RayAccel owner;
        foreach(mode; 0..2) {
            assert((mode ? owner.update(xyz) : owner.build(xyz,[0u,1,2])) == Status.ok,"PICK_WITNESS_SETUP");
            Hit h;
            assert(owner.query(ray,h)==Status.ok && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            assert(h.t==0.5068215727806091f && h.u==0.33335933089256287f && h.v==0.33325690031051636f,"PICK_REFINED_BARY");
        }
    }
    {
        float[] xyz=[0.8347656726837158f,0.099609375f,0.039484743028879166f,-0.36328125f,0.1015625f,0.041599199175834656f,-0.365234375f,0.1015625f,0.0406908355653286f];
        auto ray=Ray([0.6495091319084167f,-1.102113127708435f,1.8047207593917847f],[-0.23805540800094604f,1.0741124153137207f,-1.576303243637085f],0.0010000000474974513f,8.0f);
        RayAccel owner;
        foreach(mode; 0..2) {
            assert((mode ? owner.update(xyz) : owner.build(xyz,[0u,1,2])) == Status.ok,"PICK_WITNESS_SETUP");
            Hit h;
            assert(owner.query(ray,h)==Status.ok && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            assert(h.t==1.119490146636963f && h.u==0.1384948492050171f && h.v==0.23819489777088165f,"PICK_REFINED_POINT");
        }
    }
    {
        float[] xyz=[-0.40358400344848633f,-0.09529908001422882f,0.02782156504690647f,-0.4036049544811249f,-0.0943184569478035f,0.027803974226117134f,-0.4041113257408142f,-0.09529412537813187f,0.028327347710728645f];
        auto ray=Ray([0.9831322431564331f,-0.5324475765228271f,-1.2806055545806885f],[-3.0391030311584473f,0.9586405754089355f,2.867504358291626f],0.0010000000474974513f,8.0f);
        RayAccel owner;
        foreach(mode; 0..2) {
            assert((mode ? owner.update(xyz) : owner.build(xyz,[0u,1,2])) == Status.ok,"PICK_WITNESS_SETUP");
            Hit h;
            assert(owner.query(ray,h)==Status.ok && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            assert(h.t==0.45633894205093384f && h.u==0.32146474719047546f && h.v==0.26187455654144287f,"PICK_REFINED_BARY");
        }
    }
    {
        float[] xyz=[1.1715030670166016f,0.019012827426195145f,0.0829799473285675f,-0.3278330862522125f,0.018866419792175293f,0.08286391943693161f,1.1713440418243408f,0.01958415098488331f,0.08374345302581787f];
        auto ray=Ray([0.4766119718551636f,0.7273121476173401f,1.4607731103897095f],[-0.31140750646591187f,-1.1102455854415894f,-2.159558057785034f],0.0010000000474974513f,8.0f);
        RayAccel owner;
        foreach(mode; 0..2) {
            assert((mode ? owner.update(xyz) : owner.build(xyz,[0u,1,2])) == Status.ok,"PICK_WITNESS_SETUP");
            Hit h;
            assert(owner.query(ray,h)==Status.ok && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            assert(h.t==0.6379964351654053f && h.u==0.5959657430648804f && h.v==0.09423118829727173f,"PICK_REFINED_POINT");
        }
    }
    {
        float[] xyz=[-0.40358400344848633f,-0.09529908001422882f,0.02782156504690647f,-0.4036049544811249f,-0.0943184569478035f,0.027803974226117134f,-0.4041113257408142f,-0.09529412537813187f,0.028327347710728645f];
        auto ray=Ray([0.9831322431564331f,-0.5324475765228271f,-1.2806055545806885f],[-3.0391030311584473f,0.9586405754089355f,2.867504358291626f],0.0010000000474974513f,8.0f);
        RayAccel owner;
        foreach(mode; 0..2) {
            assert((mode ? owner.update(xyz) : owner.build(xyz,[0u,1,2])) == Status.ok,"PICK_WITNESS_SETUP");
            Hit h;
            assert(owner.query(ray,h)==Status.ok && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            assert(h.t==0.45633894205093384f && h.u==0.32146474719047546f && h.v==0.26187455654144287f,"PICK_REFINED_POINT");
        }
    }
    {
        float[] xyz=[-0.40358400344848633f,-0.09529908001422882f,0.02782156504690647f,-0.4036049544811249f,-0.0943184569478035f,0.027803974226117134f,-0.4041113257408142f,-0.09529412537813187f,0.028327347710728645f];
        auto ray=Ray([0.9831322431564331f,-0.5324475765228271f,-1.2806055545806885f],[-3.0391030311584473f,0.9586405754089355f,2.867504358291626f],0.0010000000474974513f,8.0f);
        RayAccel owner;
        foreach(mode; 0..2) {
            assert((mode ? owner.update(xyz) : owner.build(xyz,[0u,1,2])) == Status.ok,"PICK_WITNESS_SETUP");
            Hit h;
            assert(owner.query(ray,h)==Status.ok && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            assert(h.t==0.45633894205093384f && h.u==0.32146474719047546f && h.v==0.26187455654144287f,"PICK_REFINED_T");
        }
    }
    {
        float[] xyz=[-1.0f,0.0f,0.0f,5.960464477539063e-08f,0.0f,0.0f,-1.0f,1.0f,0.0f];
        auto ray=Ray([-0.5f,0.25f,1.0f],[0.0f,0.0f,-1.0f],0.0f,2.0f);
        RayAccel owner;
        foreach(mode; 0..2) {
            assert((mode ? owner.update(xyz) : owner.build(xyz,[0u,1,2])) == Status.ok,"PICK_WITNESS_SETUP");
            Hit h;
            assert(owner.query(ray,h)==Status.ok && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            assert(h.t==1.0f && h.u==0.4999999701976776f && h.v==0.25f,"PICK_REFINEMENT_PROMOTION");
        }
    }
}

version(EmbreeTestFaults) unittest {
    RayAccel owner;
    float[] xyz=[0,0,0,2,0,0,0,2,0];
    auto ray=Ray([.5f,.25f,1],[0,0,-1],0,2);
    foreach(uint stage; 9..16) {
        assert(owner.build(xyz,[0u,1,2])==Status.ok,"PICK_REFINEMENT_ERROR_SETUP");
        const before=owner.testRefineCalls();
        owner.testFault(stage);
        Hit h=Hit(1,99,99,99,99);
        assert(owner.query(ray,h)==Status.nativeError && h==Hit(0,0,0,0,0) &&
            owner.testRefineCalls()==before+1,"PICK_REFINEMENT_ERROR");
        assert(owner.query(ray,h)==Status.notReady,"PICK_REFINEMENT_ERROR_READY");
        assert(owner.build(xyz,[0u,1,2])==Status.ok,"PICK_REFINEMENT_ERROR_REBUILD");
        assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_REFINEMENT_ERROR_RECOVERY");
    }
}

unittest {
    float[] xyz=[0.0f,0.0f,-1.5f,2.0f,0.0f,-1.5f,0.0f,2.0f,-1.5f,0.0f,0.0f,5.960464477539063e-08f,2.0f,0.0f,5.960464477539063e-08f,0.0f,2.0f,5.960464477539063e-08f,6.480276107788086f,-5.792384624481201f,2.190798759460449f,22.870615005493164f,-5.792384624481201f,9.599451065063477f,6.480276107788086f,-3.35605788230896f,-1.9048489332199097f,0.519353985786438f,8.504541397094727f,-4.3649468421936035f,15.613693237304688f,8.504541397094727f,-1.135607123374939f,0.519353985786438f,27.976764678955078f,-7.185471534729004f,1.3625291585922241f,1.9570763111114502f,-2.6506757736206055f,11.866731643676758f,1.9570763111114502f,0.018697235733270645f,1.3625291585922241f,7.9629411697387695f,0.8310231566429138f,-3.138324499130249f,-6.30498743057251f,-6.69605016708374f,11.76162052154541f,-6.30498743057251f,-12.722453117370605f,-3.138324499130249f,3.2098233699798584f,-5.028817653656006f,4.255955219268799f,-6.141201496124268f,4.928675174713135f,15.093621253967285f,-6.141201496124268f,10.701006889343262f,4.255955219268799f,7.888274192810059f,9.37032413482666f,4.36215353012085f,-6.594987392425537f,-3.320612907409668f,14.694625854492188f,-6.594987392425537f,1.4815882444381714f,4.36215353012085f,-4.192990779876709f,-3.984531879425049f,-2.260338544845581f,3.399111747741699f,0.7837908864021301f,-1.6163864135742188f,3.399111747741699f,0.776556670665741f,-2.260338544845581f,6.443855285644531f,-3.933929443359375f,9.269137382507324f,-6.336475372314453f,-2.3099825382232666f,10.994254112243652f,-6.336475372314453f,-9.594701766967773f,9.269137382507324f,12.61346435546875f,-3.7379539012908936f,-3.9147613048553467f,7.807218551635742f,-1.6471322774887085f,11.052665710449219f,7.807218551635742f,-5.039437770843506f,-3.9147613048553467f,22.57318878173828f,0.9730216860771179f];
    uint[] ids=[0u,1u,2u,3u,4u,5u,6u,7u,8u,9u,10u,11u,12u,13u,14u,15u,16u,17u,18u,19u,20u,21u,22u,23u,24u,25u,26u,27u,28u,29u,30u,31u,32u];
    RayAccel owner;
    assert(owner.build(xyz,ids)==Status.ok,"PICK_SELECTED_SETUP");
    auto ray=Ray([.5f,.25f,3],[0,0,-3],1,2); Hit h;
    assert(owner.query(ray,h)==Status.ok && h.hit && h.triangle==0 && h.t==1.5f &&
        h.u==.25f && h.v==.125f,"PICK_REFINED_SELECTED_ID");
    version(EmbreeTestFaults) assert(owner.testRefineCalls()==1 && owner.testCallbackCalls()>0,
        "PICK_CALLBACK_DISAGREEMENT_POPULATION");
}

unittest {
    import core.stdc.math : nextafterf;
    RayAccel owner;
    foreach(winding;0..2) {
        assert(owner.build([0f,0,0,2,0,0,0,2,0],winding ? [0u,2,1] : [0u,1,2])==Status.ok);
        auto ray=Ray([.5f,.25f,3],[0,0,-3],1,1); Hit h;
        assert(owner.query(ray,h)==Status.ok && h.hit && h.t==1,"PICK_POSITIVE_SINGLETON");
        ray.nearT=nextafterf(1,2); ray.farT=2;
        assert(owner.query(ray,h)==Status.ok && !h.hit,"PICK_INTERVAL_OUTSIDE_NEAR");
        ray.nearT=nextafterf(1,0);
        assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_NEAR_INSIDE_ULP");
        ray.nearT=0; ray.farT=nextafterf(1,0);
        assert(owner.query(ray,h)==Status.ok && !h.hit,"PICK_INTERVAL_OUTSIDE_FAR");
        ray.farT=nextafterf(1,2);
        assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_FAR_INSIDE_ULP");
        ray.farT=float.max;
        assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_FINITE_EXTREME_BOUNDS");
        ray.nearT=float.max;
        assert(owner.query(ray,h)==Status.ok && !h.hit,"PICK_FINITE_EXTREME_SINGLETON");
        ray=Ray([.5f,.25f,0],[0,0,-3],-0.0f,0);
        assert(owner.query(ray,h)==Status.ok && h.hit && h.t==0,"PICK_ZERO_CLOSED");
        ray.nearT=-1;
        assert(owner.query(ray,h)==Status.invalid,"PICK_NEGATIVE_INTERVAL");
        ray.nearT=2; ray.farT=1;
        assert(owner.query(ray,h)==Status.invalid,"PICK_REVERSED_INTERVAL");
        ray.nearT=float.nan;
        assert(owner.query(ray,h)==Status.invalid,"PICK_NONFINITE_INTERVAL");
    }
    foreach(z;[-0x1p-24f,0x1p-24f]) {
        assert(owner.build([0f,0,z,2,0,z,0,2,z],[0u,1,2])==Status.ok);
        auto ray=Ray([.5f,.25f,0],[0,0,-3],0,0); Hit h;
        assert(owner.query(ray,h)==Status.ok && !h.hit,"PICK_ZERO_OUTSIDE");
    }
    assert(owner.build([0f,0,-1,2,0,-1,0,2,-1,0,0,0,2,0,0,0,2,0],[0u,1,2,3,4,5])==Status.ok);
    auto ray=Ray([.5f,.25f,0],[0,0,-3],0,2); Hit h;
    assert(owner.query(ray,h)==Status.ok && h.hit && h.triangle==1 && h.t==0,"PICK_ZERO_NEAREST");
    assert(owner.build([0f,0,0,1,0,0,2,0,0],[0u,1,2])==Status.ok);
    assert(owner.query(ray,h)==Status.ok && !h.hit,"PICK_DEGENERATE_MISS");
    assert(owner.build([0f,0,0,0,2,0,0,0,2],[0u,1,2])==Status.ok);
    assert(owner.query(ray,h)==Status.ok && !h.hit,"PICK_PARALLEL_MISS");
}
