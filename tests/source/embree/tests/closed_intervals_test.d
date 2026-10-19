module embree.tests.closed_intervals_test;
import embree.ray_accel;
import core.stdc.string : memcpy;
private float unpack(uint u) nothrow @nogc { float f; memcpy(&f,&u,4); return f; }
unittest {
 uint population;
 {
 uint[9] words=[0u,0u,0u,3201315456u,3200290048u,1052294336u,1040617472u,1002504192u,3209079456u];
 uint[8] rayWords=[3205169532u,1049024208u,3197142848u,1053818880u,3196583936u,1034944512u,0u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ORDINARY");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1067450368u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3207224448u,3204726592u,3202882368u,3207310880u,1062059328u,1056618816u];
 uint[8] rayWords=[3210188738u,1056505488u,3173079488u,1053818880u,3196583936u,1034944512u,0u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ORDINARY");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1067450368u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3206382368u,1055031424u,3200216640u,1055916160u,1060621952u,3208503552u];
 uint[8] rayWords=[3203666180u,1059302548u,3201405260u,1053818880u,3196583936u,1034944512u,0u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ORDINARY");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1067450368u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1038880768u,3187778304u,1013843968u,3207654720u,1054250112u,3140026368u];
 uint[8] rayWords=[3207840196u,1054926624u,3185054288u,1053818880u,3196583936u,1034944512u,0u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ORDINARY");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1067450368u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1036049152u,3204969696u,1045050752u,3196276096u,1061164160u,3190201344u];
 uint[8] rayWords=[3205627642u,1055854844u,3187166576u,1053818880u,3196583936u,1034944512u,0u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ORDINARY");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1067450368u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3191494656u,1015219200u,3204684160u,3207159264u,1061900096u,3207848544u];
 uint[8] rayWords=[3208620406u,1058360650u,3201877772u,1053818880u,3196583936u,1034944512u,0u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ORDINARY");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1067450368u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1051368640u,1001574400u,1060454400u,3206646208u,3193808640u,1052009856u];
 uint[8] rayWords=[3206839386u,1049093124u,1040887664u,1053818880u,3196583936u,1034944512u,0u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ORDINARY");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1067450368u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1058799936u,1026708992u,3204122816u,1057292960u,3209215552u,3177012224u];
 uint[8] rayWords=[3194797000u,1036180592u,3193794168u,1053818880u,3196583936u,1034944512u,0u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ORDINARY");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1067450368u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3189155584u,3195180288u,3197911680u,3209349664u,1059438624u,3203236160u];
 uint[8] rayWords=[3196902908u,1042396216u,3192850872u,1053818880u,3196583936u,1034944512u,2147483648u,0u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ZERO");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[2147483648u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3173923840u,1061672544u,3205760896u,1038125568u,3209873696u,3203817856u];
 uint[8] rayWords=[1020745216u,3185784128u,3196354888u,1053818880u,3196583936u,1034944512u,2147483648u,0u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ZERO");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[2147483648u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3208730112u,3209385024u,1030044160u,3182403584u,3188734848u,1059922816u];
 uint[8] rayWords=[3190583680u,3192230344u,1046686488u,1053818880u,3196583936u,1034944512u,2147483648u,0u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ZERO");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[2147483648u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3204016960u,3196941184u,3204544224u,3197779712u,1050514112u,3152470016u];
 uint[8] rayWords=[3191730072u,1026933152u,3183916208u,1053818880u,3196583936u,1034944512u,2147483648u,0u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ZERO");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[2147483648u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1047655168u,3207638400u,1050726272u,3167542272u,3192234624u,1048270080u];
 uint[8] rayWords=[1024816096u,3192014056u,1040898144u,1053818880u,3196583936u,1034944512u,2147483648u,0u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ZERO");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[2147483648u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3205027680u,3208094208u,1060017792u,1050169536u,3206598112u,3204623840u];
 uint[8] rayWords=[3152929280u,3198770540u,3171000800u,1053818880u,3196583936u,1034944512u,2147483648u,0u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ZERO");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[2147483648u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3169422336u,1061584736u,3208107872u,1061634688u,1046574976u,1054069440u];
 uint[8] rayWords=[1047763416u,1046172896u,3148855808u,1053818880u,3196583936u,1034944512u,2147483648u,0u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ZERO");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[2147483648u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1031774208u,1057749696u,1044344832u,1057269216u,3207704896u,1059955008u];
 uint[8] rayWords=[1043450584u,3186246400u,1048374928u,1053818880u,3196583936u,1034944512u,2147483648u,0u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_ZERO");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[2147483648u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3198836928u,3203302272u,3204737280u,3204672032u,1050092672u,3207807424u];
 uint[8] rayWords=[3206613564u,1049264832u,3201151096u,1053818880u,3196583936u,1034944512u,1065353216u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_SINGLETON");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3206455424u,1032992512u,3206408416u,1052031488u,3205765728u,1044736512u];
 uint[8] rayWords=[3201499664u,1036593248u,3188768136u,1053818880u,3196583936u,1034944512u,1065353216u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_SINGLETON");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3209036160u,3209914976u,3183121152u,1059590208u,3192115072u,3176146432u];
 uint[8] rayWords=[3199284840u,1028717952u,3186852224u,1053818880u,3196583936u,1034944512u,1065353216u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_SINGLETON");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3208509888u,1058796544u,3191157888u,3209652000u,3208843392u,3205431104u];
 uint[8] rayWords=[3209457422u,1041310304u,3197525108u,1053818880u,3196583936u,1034944512u,1065353216u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_SINGLETON");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1048135424u,3199803968u,1059479232u,1060403840u,3199300416u,1042298752u];
 uint[8] rayWords=[3188697488u,1035425344u,1034793168u,1053818880u,3196583936u,1034944512u,1065353216u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_SINGLETON");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1037645824u,3207138944u,1057894496u,1060348928u,3196800256u,1058222848u];
 uint[8] rayWords=[3190494656u,1030263808u,1045079048u,1053818880u,3196583936u,1034944512u,1065353216u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_SINGLETON");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3203048064u,3196352896u,1057124320u,1057566176u,1060636352u,1034756864u];
 uint[8] rayWords=[3198566860u,1055010160u,1024689536u,1053818880u,3196583936u,1034944512u,1065353216u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_SINGLETON");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1042667648u,3208861760u,3210263104u,3202904256u,1049109120u,983793664u];
 uint[8] rayWords=[3204746104u,1045599072u,3195676032u,1053818880u,3196583936u,1034944512u,1065353216u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_SINGLETON");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1043081472u,1034817792u,3206447328u,3199740864u,1059111904u,3208304064u];
 uint[8] rayWords=[3204016596u,1056219960u,3202102764u,1053818880u,3196583936u,1034944512u,1065353216u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_NEAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3209186624u,1053349120u,3203581696u,1059175808u,3201518208u,3207986112u];
 uint[8] rayWords=[3199600264u,1045905744u,3200991912u,1053818880u,3196583936u,1034944512u,1065353216u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_NEAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1030674432u,3183231232u,3197868096u,1061397888u,3199259904u,3206668864u];
 uint[8] rayWords=[3189784320u,1041224904u,3199097332u,1053818880u,3196583936u,1034944512u,1065353216u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_NEAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1049194560u,1037886976u,3206630720u,1048929344u,1054628992u,1032146688u];
 uint[8] rayWords=[3196881824u,1054291888u,3191612824u,1053818880u,3196583936u,1034944512u,1065353216u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_NEAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3205735264u,1034986496u,3204779616u,1055737408u,3204739200u,1041825024u];
 uint[8] rayWords=[3200071504u,1039533440u,3188456376u,1053818880u,3196583936u,1034944512u,1065353216u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_NEAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1062478656u,1062691520u,1058186656u,1061507456u,1049184256u,3186801152u];
 uint[8] rayWords=[3156474624u,1057084868u,3162443136u,1053818880u,3196583936u,1034944512u,1065353216u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_NEAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3194137728u,1057833696u,3190738688u,3182347008u,1055120192u,1062164704u];
 uint[8] rayWords=[3203589992u,1057101516u,1040869448u,1053818880u,3196583936u,1034944512u,1065353216u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_NEAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1043035136u,1059478560u,1044348544u,1060532704u,1041111296u,1035074816u];
 uint[8] rayWords=[3189492712u,1054643828u,3166848512u,1053818880u,3196583936u,1034944512u,1065353216u,1073741824u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_NEAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3188018432u,1049540032u,1041251584u,1061440960u,1057742336u,3194308736u];
 uint[8] rayWords=[3192102208u,1056582868u,3187972920u,1053818880u,3196583936u,1034944512u,0u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_FAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3207021888u,3210326304u,3204625696u,1051240320u,3168084992u,3205856448u];
 uint[8] rayWords=[3201959328u,1036570496u,3199889892u,1053818880u,3196583936u,1034944512u,0u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_FAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3204527936u,3198012736u,3162443776u,1048951168u,1061446976u,3187865088u];
 uint[8] rayWords=[3201739456u,1055205580u,3187927568u,1053818880u,3196583936u,1034944512u,0u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_FAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3204627808u,3197218880u,3208875616u,1057740352u,3204651104u,3147763712u];
 uint[8] rayWords=[3198787868u,1029045696u,3194763376u,1053818880u,3196583936u,1034944512u,0u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_FAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,3204794496u,1037998848u,3181336576u,3188669952u,1051060736u,3205657504u];
 uint[8] rayWords=[3205246576u,1053182052u,3197042788u,1053818880u,3196583936u,1034944512u,0u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_FAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1047842048u,1060560480u,3202034688u,1056451904u,1039567616u,1053754176u];
 uint[8] rayWords=[3193371976u,1054856768u,3173202400u,1053818880u,3196583936u,1034944512u,0u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_FAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1062606688u,1052214208u,3197316480u,1035311616u,1047121280u,1060196704u];
 uint[8] rayWords=[3194162792u,1053749456u,1033693520u,1053818880u,3196583936u,1034944512u,0u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_FAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 {
 uint[9] words=[0u,0u,0u,1038213888u,3204804032u,3204966560u,3200176192u,3189214208u,1045542272u];
 uint[8] rayWords=[3204482360u,1039737824u,3187198848u,1053818880u,3196583936u,1034944512u,0u,1065353216u];
 float[] xyz; foreach(w;words) xyz~=unpack(w);
 Ray ray; memcpy(&ray,rayWords.ptr,32);
 foreach(j;0..32) { float x=100+j*4; xyz~=[x,100f,0,x+2,100,0,x,102,0]; }
 uint[] ids; foreach(j;0..99) ids~=cast(uint)j;
 assert(xyz.length==297 && ids.length==99,"PICK_ENDPOINT_TREE_POPULATION");
 RayAccel owner;
 foreach(phase;0..2) {
 assert((phase ? owner.update(xyz) : owner.build(xyz,ids))==Status.ok,"PICK_ENDPOINT_SETUP");
 Hit h; assert(owner.query(ray,h)==Status.ok && h.hit,"PICK_ENDPOINT_TREE_FAR");
 uint[5] actual; memcpy(actual.ptr,&h,20);
 assert(actual[2..5]==[1065353216u,1044381696u,1050673152u],"PICK_EXACT_ENDPOINT_ASSIGN"); ++population;
 }
 }
 assert(population==80,"PICK_ENDPOINT_POPULATION");
}
