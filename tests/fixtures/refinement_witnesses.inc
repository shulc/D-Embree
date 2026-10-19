// Authenticated packed witnesses; expectations independently round exact Fraction solves.
static void refinementWitnesses() {
    const char *cell=std::getenv("PICK_NUMERIC_CELL");
    if(!cell || std::strcmp(cell,"NEW_FAILURE_BARY") == 0) {
        const float xyz[]={0x1.2800000000000p-2f,-0x1.e000000000000p-3f,0x1.13b3c80000000p-4f,0x1.3000000000000p-2f,-0x1.d000000000000p-3f,0x1.692d100000000p-5f,0x1.2800000000000p-2f,-0x1.d000000000000p-3f,0x1.e9c0d20000000p-5f};
        const uint32_t ids[]={0,1,2};
        DembreeRay ray={{-0x1.290a820000000p-1f,0x1.96d90c0000000p+0f,0x1.54df8a0000000p-3f},{0x1.b85dd40000000p+0f,-0x1.cb3fc00000000p+1f,-0x1.b9fe7a0000000p-3f},0x1.0624de0000000p-10f,0x1.0000000000000p+3f};
        DembreeOwner *o=nullptr; CHECK(dembree_create(&o)==0,"PICK_CREATE");
        for(unsigned mode=0;mode<2;++mode) {
            CHECK((mode ? dembree_update(o,xyz,3) : dembree_build(o,xyz,3,ids,1))==0,"PICK_WITNESS_SETUP");
            DembreeHit h={};
            CHECK(dembree_query(o,&ray,&h)==0 && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            CHECK(h.t==0x1.037e1e0000000p-1f && h.u==0x1.555c260000000p-2f && h.v==0x1.55414c0000000p-2f,"PICK_REFINED_BARY");
        }
        dembree_dispose(&o);
    }
    if(!cell || std::strcmp(cell,"NEW_FAILURE_POINT_bary_exact") == 0) {
        const float xyz[]={0x1.ab66680000000p-1f,0x1.9800000000000p-4f,0x1.4375820000000p-5f,-0x1.7400000000000p-2f,0x1.a000000000000p-4f,0x1.54c7d80000000p-5f,-0x1.7600000000000p-2f,0x1.a000000000000p-4f,0x1.4d56de0000000p-5f};
        const uint32_t ids[]={0,1,2};
        DembreeRay ray={{0x1.4c8c760000000p-1f,-0x1.1a24160000000p+0f,0x1.ce022e0000000p+0f},{-0x1.e789980000000p-3f,0x1.12f9080000000p+0f,-0x1.93889c0000000p+0f},0x1.0624de0000000p-10f,0x1.0000000000000p+3f};
        DembreeOwner *o=nullptr; CHECK(dembree_create(&o)==0,"PICK_CREATE");
        for(unsigned mode=0;mode<2;++mode) {
            CHECK((mode ? dembree_update(o,xyz,3) : dembree_build(o,xyz,3,ids,1))==0,"PICK_WITNESS_SETUP");
            DembreeHit h={};
            CHECK(dembree_query(o,&ray,&h)==0 && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            CHECK(h.t==0x1.1e96e80000000p+0f && h.u==0x1.1ba3300000000p-3f && h.v==0x1.e7d2ba0000000p-3f,"PICK_REFINED_POINT");
        }
        dembree_dispose(&o);
    }
    if(!cell || std::strcmp(cell,"WORST_bary") == 0) {
        const float xyz[]={-0x1.9d45200000000p-2f,-0x1.8658540000000p-4f,0x1.c7d41a0000000p-6f,-0x1.9d4a9e0000000p-2f,-0x1.8254120000000p-4f,0x1.c78a520000000p-6f,-0x1.9dcf5c0000000p-2f,-0x1.8653220000000p-4f,0x1.d01d820000000p-6f};
        const uint32_t ids[]={0,1,2};
        DembreeRay ray={{0x1.f75d1c0000000p-1f,-0x1.109cf80000000p-1f,-0x1.47d5c40000000p+0f},{-0x1.8501540000000p+1f,0x1.ead2f00000000p-1f,0x1.6f0a620000000p+1f},0x1.0624de0000000p-10f,0x1.0000000000000p+3f};
        DembreeOwner *o=nullptr; CHECK(dembree_create(&o)==0,"PICK_CREATE");
        for(unsigned mode=0;mode<2;++mode) {
            CHECK((mode ? dembree_update(o,xyz,3) : dembree_build(o,xyz,3,ids,1))==0,"PICK_WITNESS_SETUP");
            DembreeHit h={};
            CHECK(dembree_query(o,&ray,&h)==0 && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            CHECK(h.t==0x1.d34a840000000p-2f && h.u==0x1.492e0e0000000p-2f && h.v==0x1.0c28d80000000p-2f,"PICK_REFINED_BARY");
        }
        dembree_dispose(&o);
    }
    if(!cell || std::strcmp(cell,"WORST_bary_exact_linf") == 0) {
        const float xyz[]={0x1.2be7a00000000p+0f,0x1.3781940000000p-6f,0x1.53e2c80000000p-4f,-0x1.4fb37a0000000p-2f,0x1.351b800000000p-6f,0x1.53691e0000000p-4f,0x1.2bdd340000000p+0f,0x1.40dde20000000p-6f,0x1.5703600000000p-4f};
        const uint32_t ids[]={0,1,2};
        DembreeRay ray={{0x1.e80cf80000000p-2f,0x1.7462420000000p-1f,0x1.75f53a0000000p+0f},{-0x1.3ee19c0000000p-2f,-0x1.1c390e0000000p+0f,-0x1.146c660000000p+1f},0x1.0624de0000000p-10f,0x1.0000000000000p+3f};
        DembreeOwner *o=nullptr; CHECK(dembree_create(&o)==0,"PICK_CREATE");
        for(unsigned mode=0;mode<2;++mode) {
            CHECK((mode ? dembree_update(o,xyz,3) : dembree_build(o,xyz,3,ids,1))==0,"PICK_WITNESS_SETUP");
            DembreeHit h={};
            CHECK(dembree_query(o,&ray,&h)==0 && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            CHECK(h.t==0x1.46a7780000000p-1f && h.u==0x1.31226c0000000p-1f && h.v==0x1.81f8900000000p-4f,"PICK_REFINED_POINT");
        }
        dembree_dispose(&o);
    }
    if(!cell || std::strcmp(cell,"WORST_ray_exact_linf") == 0) {
        const float xyz[]={-0x1.9d45200000000p-2f,-0x1.8658540000000p-4f,0x1.c7d41a0000000p-6f,-0x1.9d4a9e0000000p-2f,-0x1.8254120000000p-4f,0x1.c78a520000000p-6f,-0x1.9dcf5c0000000p-2f,-0x1.8653220000000p-4f,0x1.d01d820000000p-6f};
        const uint32_t ids[]={0,1,2};
        DembreeRay ray={{0x1.f75d1c0000000p-1f,-0x1.109cf80000000p-1f,-0x1.47d5c40000000p+0f},{-0x1.8501540000000p+1f,0x1.ead2f00000000p-1f,0x1.6f0a620000000p+1f},0x1.0624de0000000p-10f,0x1.0000000000000p+3f};
        DembreeOwner *o=nullptr; CHECK(dembree_create(&o)==0,"PICK_CREATE");
        for(unsigned mode=0;mode<2;++mode) {
            CHECK((mode ? dembree_update(o,xyz,3) : dembree_build(o,xyz,3,ids,1))==0,"PICK_WITNESS_SETUP");
            DembreeHit h={};
            CHECK(dembree_query(o,&ray,&h)==0 && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            CHECK(h.t==0x1.d34a840000000p-2f && h.u==0x1.492e0e0000000p-2f && h.v==0x1.0c28d80000000p-2f,"PICK_REFINED_POINT");
        }
        dembree_dispose(&o);
    }
    if(!cell || std::strcmp(cell,"WORST_t") == 0) {
        const float xyz[]={-0x1.9d45200000000p-2f,-0x1.8658540000000p-4f,0x1.c7d41a0000000p-6f,-0x1.9d4a9e0000000p-2f,-0x1.8254120000000p-4f,0x1.c78a520000000p-6f,-0x1.9dcf5c0000000p-2f,-0x1.8653220000000p-4f,0x1.d01d820000000p-6f};
        const uint32_t ids[]={0,1,2};
        DembreeRay ray={{0x1.f75d1c0000000p-1f,-0x1.109cf80000000p-1f,-0x1.47d5c40000000p+0f},{-0x1.8501540000000p+1f,0x1.ead2f00000000p-1f,0x1.6f0a620000000p+1f},0x1.0624de0000000p-10f,0x1.0000000000000p+3f};
        DembreeOwner *o=nullptr; CHECK(dembree_create(&o)==0,"PICK_CREATE");
        for(unsigned mode=0;mode<2;++mode) {
            CHECK((mode ? dembree_update(o,xyz,3) : dembree_build(o,xyz,3,ids,1))==0,"PICK_WITNESS_SETUP");
            DembreeHit h={};
            CHECK(dembree_query(o,&ray,&h)==0 && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            CHECK(h.t==0x1.d34a840000000p-2f && h.u==0x1.492e0e0000000p-2f && h.v==0x1.0c28d80000000p-2f,"PICK_REFINED_T");
        }
        dembree_dispose(&o);
    }
    if(!cell || std::strcmp(cell,"PROMOTION") == 0) {
        const float xyz[]={-0x1.0000000000000p+0f,0x0.0p+0f,0x0.0p+0f,0x1.0000000000000p-24f,0x0.0p+0f,0x0.0p+0f,-0x1.0000000000000p+0f,0x1.0000000000000p+0f,0x0.0p+0f};
        const uint32_t ids[]={0,1,2};
        DembreeRay ray={{-0x1.0000000000000p-1f,0x1.0000000000000p-2f,0x1.0000000000000p+0f},{0x0.0p+0f,0x0.0p+0f,-0x1.0000000000000p+0f},0x0.0p+0f,0x1.0000000000000p+1f};
        DembreeOwner *o=nullptr; CHECK(dembree_create(&o)==0,"PICK_CREATE");
        for(unsigned mode=0;mode<2;++mode) {
            CHECK((mode ? dembree_update(o,xyz,3) : dembree_build(o,xyz,3,ids,1))==0,"PICK_WITNESS_SETUP");
            DembreeHit h={};
            CHECK(dembree_query(o,&ray,&h)==0 && h.hit && h.triangle==0,"PICK_REFINED_SELECTED_ID");
            CHECK(h.t==0x1.0000000000000p+0f && h.u==0x1.fffffe0000000p-2f && h.v==0x1.0000000000000p-2f,"PICK_REFINEMENT_PROMOTION");
        }
        dembree_dispose(&o);
    }
}
