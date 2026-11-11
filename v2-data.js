/* PROJECT 100M V2 — journey, profiles, training templates, storage, optional cloud sync */
(function(){
"use strict";
const PREFIX="project100m-v2:", LEGACY="project100m-local-v1";
const uid=()=>crypto.randomUUID?crypto.randomUUID():"id-"+Date.now()+"-"+Math.random().toString(36).slice(2);
const iso=()=>new Date().toISOString();
const day=()=>{const d=new Date();return d.getFullYear()+"-"+String(d.getMonth()+1).padStart(2,"0")+"-"+String(d.getDate()).padStart(2,"0")};
const num=v=>v===""||v===null||v===undefined?null:Number.isFinite(Number(v))?Number(v):null;
const templates=[
{id:"sprint100",name:"100M — The Comeback",category:"Speed",blocks:12,description:"กลับมาวิ่ง 100 เมตรอย่างค่อยเป็นค่อยไป พร้อมเวทขาและ Easy Run",weeks:"12 training blocks",icon:"⚡"},
{id:"run5k",name:"5K Foundation",category:"Running",blocks:8,description:"พัฒนาจาก Run–Walk สู่การวิ่ง 5 กม. แบบสบาย",weeks:"8 training blocks",icon:"↗"},
{id:"strength",name:"Strength Foundation",category:"Strength",blocks:8,description:"สร้างพื้นฐานความแข็งแรงด้วยท่าหลักที่ทำได้ในยิม",weeks:"8 training blocks",icon:"▦"},
{id:"wellness",name:"Active Wellness",category:"Wellness",blocks:6,description:"เดิน เคลื่อนไหว เวทเบา และฟื้นฟูร่างกาย",weeks:"6 training blocks",icon:"♡"}
];
const sA=[[4,20,"60–70%"],[5,20,"65–75%"],[5,20,"70–80%"],[3,20,"เบา"],[4,20,"75–85%"],[5,20,"80–85%"],[5,30,"80–90%"],[3,20,"เบา"],[4,30,"85–90%"],[4,30,"90–95%"],[3,40,"90–95%"],[3,20,"เบา"]];
const sB=[[4,20,"60–70%"],[4,20,"70%"],[4,30,"70–80%"],[3,20,"เบา"],[4,30,"75–85%"],[4,30,"80–85%"],[4,40,"80–90%"],[3,30,"เบา"],[3,50,"85–90%"],[3,60,"85–90%"],[3,60,"90–95%"],[1,100,"ทดสอบเมื่อพร้อม"]];
const strengthA=[{name:"Goblet Squat",sets:2,reps:"8"},{name:"Romanian Deadlift",sets:2,reps:"8"},{name:"Calf Raise",sets:2,reps:"12"},{name:"Plank",sets:2,reps:"20–30 วินาที"}];
const strengthB=[{name:"Split Squat",sets:2,reps:"8/ข้าง"},{name:"Glute Bridge",sets:2,reps:"12"},{name:"Hamstring Curl",sets:2,reps:"10"},{name:"Side Plank",sets:2,reps:"20 วินาที/ข้าง"}];
function workout(key,block,slot,title,kind,summary,details,exercises,minutes){
return {key,block,slot,title,kind,summary,details,exercises:exercises||[],minutes:minutes||30};
}
function buildSessions(templateId){
const t=templates.find(x=>x.id===templateId);if(!t)return[];
const result=[];
for(let w=1;w<=t.blocks;w++){
if(templateId==="sprint100"){
const a=sA[w-1],b=sB[w-1],rest=w===4||w===8;
const low=w<3?15:w<5?20:w<7?25:w<9?25:30;
const long=w<3?20:w<5?25:w<7?30:w<9?30:40;
const strengthSets=rest||w===12?1:w<5?2:3;
const sa=strengthA.map(x=>({...x,sets:strengthSets}));
const sb=strengthB.map(x=>({...x,sets:strengthSets}));
result.push(workout("w"+w+"-1",w,1,"Sprint A + Strength A","sprint","Sprint "+a[0]+" × "+a[1]+"m · "+a[2]+" + เวทขา","วอร์มอัพ 15–20 นาที, A-March/A-Skip, ฝึกเร่งจากท่ายืน; พักเต็ม 2–3 นาที/เที่ยว ก่อนเวทขา",{sprint:{reps:a[0],meters:a[1],effort:a[2]},strength:sa},55));
result.push(workout("w"+w+"-2",w,2,"Easy Run","easy",low+"–"+(low+5)+" นาที · พูดเป็นประโยคได้","วิ่งช้า หรือสลับวิ่ง–เดินได้ตามการฟื้นตัว หลีกเลี่ยงการฝืนเพซ",{duration:low},low));
result.push(workout("w"+w+"-3",w,3,"Strength B","strength","เวทขา "+strengthSets+" เซต/ท่า","น้ำหนักปานกลาง เหลือแรงประมาณ 2–3 ครั้งต่อเซต; ไม่เล่นจนหมดแรง",{strength:sb},40));
result.push(workout("w"+w+"-4",w,4,w===12?"100M Time Trial":"Sprint B","sprint",w===12?"ทดสอบ 100m หากพร้อม":b[0]+" × "+b[1]+"m · "+b[2],w===12?"ทดสอบได้เมื่อแข็งแรง ฟื้นตัวดี และไม่มีอาการเจ็บ; จับเวลาด้วยวิธีที่สม่ำเสมอ หากไม่พร้อมให้เลื่อน":"วอร์มอัพ 15–20 นาที; เริ่มจากท่ายืน ไม่ต้องใช้รองเท้าตะปู; พัก 2–6 นาทีหรือจนฟื้นตัว",{sprint:{reps:b[0],meters:b[1],effort:b[2]}},40));
result.push(workout("w"+w+"-5",w,5,"Easy Run / Run–Walk","easy",long+"–"+(long+5)+" นาที · สบาย","ออกกำลังระดับที่ยังสนทนาได้ ถ้าไม่พร้อมให้ลดเวลา หรือเลือกเดินฟื้นตัว",{duration:long},long));
}else if(templateId==="run5k"){
let a=Math.min(35,14+(w-1)*3),b=Math.min(45,20+(w-1)*4);
result.push(workout("w"+w+"-1",w,1,"Run–Walk Foundation","easy",a+" นาที","วิ่งช้าสลับเดินได้; เน้นความสบายและความต่อเนื่อง",{duration:a},a));
result.push(workout("w"+w+"-2",w,2,"Strength & Mobility","strength","Squat / Bridge / Calf / Core","เริ่ม 2 เซตต่อท่าและพักเมื่อจำเป็น",{strength:strengthA.map(x=>({...x,sets:2}))},30));
result.push(workout("w"+w+"-3",w,3,"Long Easy Run","easy",b+" นาที","วิ่งช้าสม่ำเสมอหรือเดินสลับ ถ้าเหนื่อยผิดปกติให้ลดระยะ",{duration:b},b));
}else if(templateId==="strength"){
const sets=w<=2?2:w===8?2:3;
result.push(workout("w"+w+"-1",w,1,"Full Body A","strength","Squat / Hinge / Calf / Core","ใช้ท่าที่ควบคุมได้และเพิ่มน้ำหนักอย่างค่อยเป็นค่อยไป",{strength:strengthA.map(x=>({...x,sets}))},45));
result.push(workout("w"+w+"-2",w,2,"Walk & Mobility","walk","เดิน 20–30 นาที","วันฟื้นตัวแบบเคลื่อนไหว; ไม่จำเป็นต้องเดินเร็ว",{duration:25},25));
result.push(workout("w"+w+"-3",w,3,"Full Body B","strength","Single-leg / Bridge / Hamstring / Core","หยุดก่อนถึงภาวะหมดแรง",{strength:strengthB.map(x=>({...x,sets}))},45));
}else{
result.push(workout("w"+w+"-1",w,1,"Active Walk","walk","เดิน "+(20+Math.min(10,w*2))+" นาที","รักษาความสบายและสังเกตการฟื้นตัว",{duration:20+Math.min(10,w*2)},30));
result.push(workout("w"+w+"-2",w,2,"Mobility & Strength","strength","เวทเบา / ท่าขยับข้อต่อ","ปรับตามความพร้อม ไม่ฝืนอาการเจ็บ",{strength:strengthB.map(x=>({...x,sets:2}))},30));
result.push(workout("w"+w+"-3",w,3,"Easy Cardio","easy","20–35 นาที","วิ่งช้า/เดิน/ปั่นตามสะดวก",{duration:20+Math.min(15,w*2)},30));
}
}return result;
}
function blankState(name){const id=uid(),planId=uid();return {version:2,activeProfileId:id,profiles:[{id,name:name||"Athlete",plans:[{id:planId,templateId:"sprint100",startedAt:iso(),records:[]}],activePlanId:planId,recovery:[],legacyWorkouts:[],legacyHealth:{}}],createdAt:iso(),updatedAt:iso()}}
function load(namespace){try{const raw=localStorage.getItem(PREFIX+namespace);if(raw){const val=JSON.parse(raw);if(val&&Array.isArray(val.profiles)&&val.version===2)return val}}catch(e){console.warn("V2 storage invalid",e)}return blankState()}
let namespace="guest",state=load(namespace),cloud=null,cloudUser=null,cloudRevision=0,cloudStatus="local",syncBusy=false,syncPending=false,cloudReady=false;
const listeners=new Set();
function notify(){listeners.forEach(fn=>{try{fn()}catch(e){console.error(e)}})}
function store(){state.updatedAt=iso();try{localStorage.setItem(PREFIX+namespace,JSON.stringify(state))}catch(e){alert("พื้นที่จัดเก็บเต็ม กรุณาสำรองไฟล์ข้อมูล");return false}notify();if(cloud&&cloudUser){syncPending=true;void sync()}return true}
function profiles(){return state.profiles}
function profile(){return state.profiles.find(x=>x.id===state.activeProfileId)||state.profiles[0]}
function activePlan(){const p=profile();return p&&p.plans.find(x=>x.id===p.activePlanId)}
function planTemplate(pl){return pl?templates.find(x=>x.id===pl.templateId):null}
function marked(plan){const m=new Map();if(plan)for(const r of plan.records||[])m.set(r.key,r);return m}
function planOverview(plan){if(!plan)return null;const ss=buildSessions(plan.templateId),m=marked(plan),completed=ss.filter(s=>m.get(s.key)?.status==="completed").length,skipped=ss.filter(s=>m.get(s.key)?.status==="skipped").length,next=ss.find(s=>!["completed","skipped"].includes(m.get(s.key)?.status));return {sessions:ss,completed,skipped,total:ss.length,next,percent:ss.length?Math.round((completed+skipped)/ss.length*100):0,adherence:(completed+skipped)?Math.round(completed/(completed+skipped)*100):0,marked:m}}
function sessionByKey(key){const p=activePlan();return p?buildSessions(p.templateId).find(s=>s.key===key):null}
function startPlan(templateId){if(!templates.some(x=>x.id===templateId))throw Error("Unknown template");const p=profile(),newPlan={id:uid(),templateId,startedAt:iso(),records:[]};p.plans.push(newPlan);p.activePlanId=newPlan.id;store();return newPlan}
function selectPlan(planId){const p=profile();if(!p.plans.some(x=>x.id===planId))return;p.activePlanId=planId;store()}
function addProfile(name){name=String(name||"").trim().slice(0,50);if(!name)throw Error("กรุณาระบุชื่อ");const p={id:uid(),name,plans:[],activePlanId:null,recovery:[],legacyWorkouts:[],legacyHealth:{}};state.profiles.push(p);state.activeProfileId=p.id;store();return p}
function renameProfile(name){name=String(name||"").trim().slice(0,50);if(!name)throw Error("กรุณาระบุชื่อ");profile().name=name;store()}
function selectProfile(id){if(!state.profiles.some(x=>x.id===id))return;state.activeProfileId=id;store()}
function recordSession(key,values){const p=activePlan(),session=sessionByKey(key);if(!p||!session)throw Error("ไม่พบ Session");const status=values.status||"completed";if(!["completed","partial","skipped"].includes(status))throw Error("Invalid status");const r={id:uid(),key,at:iso(),status,mode:values.mode||"quick",date:values.date||day(),duration:num(values.duration),distanceKm:num(values.distanceKm),avgHr:num(values.avgHr),maxHr:num(values.maxHr),rpe:num(values.rpe),sprintSeconds:num(values.sprintSeconds),sprintMeters:num(values.sprintMeters),repsDone:num(values.repsDone),sets:values.sets||"",notes:String(values.notes||"").slice(0,2000),source:"self-reported"};p.records=p.records||[];p.records.push(r);store();return r}
function recordRecovery(val){const p=profile(),d=val.date||day(),previous=p.recovery.find(x=>x.date===d)||{},r={...previous,date:d,updatedAt:iso(),source:"manual-check-in"};for(const key of ["sleep","rhr","hrv","fatigue","soreness","weight"]){if(val[key]!==undefined&&val[key]!==null&&val[key]!=="")r[key]=num(val[key])}if(val.notes!==undefined&&val.notes!=="")r.notes=String(val.notes).slice(0,1000);p.recovery=p.recovery.filter(x=>x.date!==d);p.recovery.push(r);p.recovery.sort((a,b)=>b.date.localeCompare(a.date));store()}
function history(){const p=profile();const out=[];for(const plan of p.plans){const map=new Map(buildSessions(plan.templateId).map(s=>[s.key,s]));for(const rec of plan.records)out.push({...rec,title:map.get(rec.key)?.title||rec.key,template:planTemplate(plan)?.name||""})}return out.sort((a,b)=>b.at.localeCompare(a.at))}
function lastHardSprint(){return history().find(x=>x.status==="completed"&&/Sprint|100M/.test(x.title))}
function readiness(session){const messages=[];if(!session)return messages;
const recent=profile().recovery[0];if(recent&&((recent.fatigue||0)>=4||(recent.soreness||0)>=4)&&((Date.now()-Date.parse(recent.date+"T12:00:00"))/86400000)<3)messages.push("Daily Check-in ล่าสุดระบุความล้าหรือปวดเมื่อยสูง ควรพักหรือปรับลดความหนัก");
if(session.kind==="sprint"){const prev=lastHardSprint();if(prev&&Date.now()-Date.parse(prev.at)<48*3600000)messages.push("คุณเพิ่งบันทึก Sprint ภายใน 48 ชั่วโมง ควรพักให้เพียงพอก่อนซ้อมความเร็วสูง");}
return messages}
function importLegacy(force=false){
 const p=profile();if(!force&&localStorage.getItem(PREFIX+"legacy-migrated"))return false;
 try{
  const old=JSON.parse(localStorage.getItem(LEGACY)||"null");if(!old)return false;
  p.legacyWorkouts=p.legacyWorkouts||[];
  const known=new Set(p.legacyWorkouts.map(x=>x.id));
  for(const x of (Array.isArray(old.sessions)?old.sessions:[])){if(!known.has(x.id)){p.legacyWorkouts.push(x);known.add(x.id)}}
  p.legacyHealth={...p.legacyHealth,...(old.health||{})};
  const days=new Set([...Object.keys(old.health||{}),...Object.keys(old.manual||{})]);
  p.recovery=p.recovery||[];
  for(const date of days){
   const oldVal={...(old.health?.[date]||{}),...(old.manual?.[date]||{})};
   let row=p.recovery.find(x=>x.date===date);
   if(!row){row={date,source:"legacy-v1",updatedAt:iso()};p.recovery.push(row)}
   for(const key of ["sleep","rhr","hrv","weight","fatigue","soreness"]){
     if((row[key]===undefined||row[key]===null)&&oldVal[key]!==undefined&&oldVal[key]!==null&&oldVal[key]!=="")row[key]=num(oldVal[key]);
   }
   if(!row.notes&&oldVal.notes)row.notes=String(oldVal.notes).slice(0,1000);
  }
  p.recovery.sort((a,b)=>b.date.localeCompare(a.date));
  localStorage.setItem(PREFIX+"legacy-migrated","1");store();return true
 }catch(e){console.warn(e);return false}
}
function backup(){return JSON.stringify(state,null,2)}
function restore(json){const data=typeof json==="string"?JSON.parse(json):json;if(!data||data.version!==2||!Array.isArray(data.profiles)||!data.profiles.length)throw Error("ไฟล์สำรองไม่ใช่ PROJECT 100M V2");state=data;store()}
function coachReport(){const p=profile(),pl=activePlan(),ov=planOverview(pl),rows=history().slice(0,100),r=p.recovery.slice(0,40),lines=["# PROJECT 100M — Coach Report","Generated: "+iso(),"Profile: "+p.name,"Plan: "+(planTemplate(pl)?.name||"None"),"Completed: "+(ov?.completed||0)+"/"+(ov?.total||0),"Next: "+(ov?.next?.title||"None"),"","## Workouts"];for(const x of rows)lines.push("- "+x.date+" | "+x.title+" | "+x.status+" | RPE "+(x.rpe??"?")+" | "+(x.duration??"?")+" min | "+(x.distanceKm??"?")+" km | HR "+(x.avgHr??"?")+" bpm | 100m "+(x.sprintSeconds??"?")+" s | "+x.notes.replace(/\n/g," "));lines.push("","## Apple Health workouts (Imported; not proof of plan completion)");for(const x of (p.appleWorkouts||[]).slice(0,50))lines.push("- "+x.date+" | "+x.kind+" | "+(x.duration??"?")+" min | "+(x.distanceKm??"?")+" km | HR avg "+(x.avgHr??"?")+" bpm, max "+(x.maxHr??"?")+" bpm");lines.push("","## Recovery");for(const x of r)lines.push("- "+x.date+": sleep "+(x.sleep??"?")+"h RHR "+(x.rhr??"?")+" HRV "+(x.hrv??"?")+" fatigue "+(x.fatigue??"?")+" soreness "+(x.soreness??"?")+" "+x.notes.replace(/\n/g," "));lines.push("","Review training quality, sprint exposure, recovery and next safe progression. Do not diagnose heart conditions.");return lines.join("\n")}
async function sync(){if(!cloud||!cloudUser||syncBusy)return;syncBusy=true;try{while(syncPending){syncPending=false;const payload=JSON.parse(JSON.stringify(state));const {data,error}=await cloud.rpc("save_training_state",{p_expected_revision:cloudRevision,p_payload:payload});if(error)throw error;if(data===null){cloudStatus="conflict";syncPending=false;notify();return}cloudRevision=Number(data);cloudStatus="synced";notify()}}catch(e){cloudStatus="error: "+e.message;notify()}finally{syncBusy=false}}
async function pullCloud(force=false){if(!cloud||!cloudUser)throw Error("Cloud not connected");const {data,error}=await cloud.from("training_states").select("revision,payload").eq("user_id",cloudUser.id).maybeSingle();if(error)throw error;const remote=data?.payload;
if(remote&&Array.isArray(remote.profiles)){if(force||!localStorage.getItem(PREFIX+namespace)){state=remote;localStorage.setItem(PREFIX+namespace,JSON.stringify(state))}else if(JSON.stringify(state)!==JSON.stringify(remote)){const k=PREFIX+namespace+"-before-cloud-"+Date.now();localStorage.setItem(k,JSON.stringify(state));state=remote;localStorage.setItem(PREFIX+namespace,JSON.stringify(state))}cloudRevision=Number(data.revision)||0;cloudStatus="synced"}
else{cloudRevision=0;cloudStatus="ready";const guest=load("guest"),chosen=guest.profiles.find(x=>x.id===guest.activeProfileId);if(chosen&&(chosen.plans.some(x=>x.records.length)||chosen.recovery.length||chosen.legacyWorkouts?.length)){if(confirm("บัญชีนี้ยังไม่มีข้อมูลคลาวด์ ต้องการคัดลอกเฉพาะโปรไฟล์ "+chosen.name+" จากเครื่องนี้ขึ้นบัญชีนี้หรือไม่?")){state={...guest,profiles:[JSON.parse(JSON.stringify(chosen))],activeProfileId:chosen.id,updatedAt:iso()};localStorage.setItem(PREFIX+namespace,JSON.stringify(state));syncPending=true;void sync()}}}notify()}
async function switchCloudUser(user){if(!user)return;if(cloudUser&&cloudUser.id===user.id)return;cloudUser=user;namespace=user.id;state=load(namespace);cloudStatus="connecting";notify();try{await pullCloud(false)}catch(e){cloudStatus="error: "+e.message;notify()}}
async function initCloud(){const cfg=window.PROJECT100M_CONFIG||{};if(!cfg.url||!cfg.publishableKey){cloudStatus="not-configured";notify();return}if(!window.supabase?.createClient){cloudStatus="library-unavailable";notify();return}
try{cloud=window.supabase.createClient(cfg.url,cfg.publishableKey,{auth:{autoRefreshToken:true,persistSession:true,detectSessionInUrl:true}});const {data,error}=await cloud.auth.getSession();if(error)throw error;if(data?.session?.user)await switchCloudUser(data.session.user);else{cloudStatus="signed-out";notify()}cloud.auth.onAuthStateChange((event,session)=>{setTimeout(async()=>{if(session?.user){if(!cloudUser||cloudUser.id!==session.user.id)await switchCloudUser(session.user)}else if(event==="SIGNED_OUT"){cloudUser=null;namespace="guest";state=load("guest");cloudStatus="signed-out";notify()}},0)})}catch(e){cloudStatus="error: "+e.message;notify()}}
async function signIn(email){if(!cloud)throw Error("ยังไม่ได้ตั้งค่า Supabase");const {error}=await cloud.auth.signInWithOtp({email,options:{emailRedirectTo:location.origin+location.pathname}});if(error)throw error;return true}
async function signOut(){if(!cloud)return;const {error}=await cloud.auth.signOut();if(error)throw error;cloudUser=null;namespace="guest";state=load("guest");cloudStatus="signed-out";notify()}
const api={templates,buildSessions,num,day,iso,get state(){return state},get namespace(){return namespace},get cloudStatus(){return cloudStatus},get cloudUser(){return cloudUser},get cloudRevision(){return cloudRevision},profile,profiles,activePlan,planTemplate,planOverview,sessionByKey,startPlan,selectPlan,addProfile,renameProfile,selectProfile,recordSession,recordRecovery,history,readiness,importLegacy,backup,restore,coachReport,store,onChange:fn=>{listeners.add(fn);return()=>listeners.delete(fn)},initCloud,signIn,signOut,sync:async()=>{syncPending=true;await sync()},pullCloud};
window.P100=api;
})();
