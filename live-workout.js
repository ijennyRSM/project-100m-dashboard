/* PROJECT 100M — LIVE WORKOUT ENGINE
Original implementation. Offline-capable session draft persists in profile state and supports cloud sync.
No GPS-based sprint timing or automatic Apple Health completion. */
(function(){
"use strict";
const A=window.P100;if(!A)return;
const clean=s=>String(s??"").replace(/[&<>"']/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[m]));
const iso=()=>new Date().toISOString(), now=()=>Date.now(), toMin=ms=>Math.max(0,Math.round(ms/60000));
function get(){const p=A.profile();const l=p&&p.activeLive;if(!l)return null;return l;}
function session(){const l=get(),plan=A.activePlan();return l&&plan&&plan.id===l.planId?A.sessionByKey(l.key):null;}
function stepsFor(s){
 const rows=[{id:"warmup",kind:"warmup",title:"Warm-up · เตรียมร่างกาย",detail:"ค่อย ๆ เพิ่มอุณหภูมิร่างกายและฝึกท่าวิ่งตามแผน",total:1,done:0,restSeconds:0}];
 const ex=s.exercises||{};
 if(ex.sprint)rows.push({id:"sprint",kind:"sprint",title:"Sprint "+ex.sprint.meters+"m",detail:ex.sprint.reps+" เที่ยว · "+ex.sprint.effort+" · พักระหว่างเที่ยวจนฟื้นตัว",total:ex.sprint.reps,done:0,restSeconds:ex.sprint.meters>=50?240:150,meters:ex.sprint.meters});
 if(ex.duration)rows.push({id:"cardio",kind:"cardio",title:s.kind==="walk"?"เดินแบบสบาย":"Easy Run / Run–Walk",detail:"เป้าหมาย "+ex.duration+" นาที · พูดคุยเป็นประโยคได้",total:1,done:0,restSeconds:0});
 if(Array.isArray(ex.strength))for(let i=0;i<ex.strength.length;i++){const a=ex.strength[i];rows.push({id:"strength-"+i,kind:"strength",title:a.name,detail:a.sets+" เซต × "+a.reps,sets:a.sets,reps:a.reps,total:a.sets,done:0,restSeconds:90})}
 rows.push({id:"cooldown",kind:"cooldown",title:"Cooldown · ผ่อนลง",detail:"เดินเบา ๆ ลดความหนัก และเช็กอาการก่อนจบ",total:1,done:0,restSeconds:0});
 return rows;
}
function startedMs(l,at=now()){return Math.max(0,(l.elapsedMs||0)+(l.runningSince?at-Date.parse(l.runningSince):0));}
function runTimer(l,at=now()){return !l||!l.runningSince?0:Math.max(0,at-Date.parse(l.runningSince))}
function start(key){
 const p=A.profile(),plan=A.activePlan(),s=A.sessionByKey(key||A.planOverview(plan)?.next?.key);
 if(!plan||!s)throw Error("กรุณาเลือก Workout ที่ต้องการเริ่ม");
 if(p.activeLive){
  if(p.activeLive.planId===plan.id&&p.activeLive.key===s.key)return p.activeLive;
  throw Error("มี Workout ที่กำลังฝึกค้างอยู่ ให้กลับไปจบหรือยกเลิกก่อนเริ่มรายการใหม่");
 }
 p.activeLive={version:1,planId:plan.id,key:s.key,title:s.title,startedAt:iso(),runningSince:iso(),elapsedMs:0,index:0,steps:stepsFor(s),restUntil:null,createdBy:"live-workout",updatedAt:iso()};
 A.store();return p.activeLive;
}
function touch(l){l.updatedAt=iso();A.store();return l}
function activeStep(){const l=get();return l?.steps?.[l.index]||null;}
function mark(){
 const l=get(),s=activeStep();if(!l||!s)throw Error("ยังไม่ได้เริ่ม Workout");
 if(s.done>=s.total)return l;
 s.done++;if(s.restSeconds>0&&s.done<s.total)l.restUntil=now()+s.restSeconds*1000;
 else l.restUntil=null;
 return touch(l);
}
function undo(){const l=get(),s=activeStep();if(!l||!s)return;if(s.done>0)s.done--;l.restUntil=null;touch(l)}
function next(){const l=get();if(!l)return;if(l.index<l.steps.length-1)l.index++;l.restUntil=null;touch(l)}
function previous(){const l=get();if(!l)return;if(l.index>0)l.index--;l.restUntil=null;touch(l)}
function togglePause(){
 const l=get();if(!l)return;
 if(l.runningSince){l.elapsedMs=startedMs(l);l.runningSince=null;l.pauseStartedAt=iso()}else{l.runningSince=iso();l.pauseStartedAt=null;}
 return touch(l);
}
function skipRest(){const l=get();if(l){l.restUntil=null;touch(l)}}
function setRest(seconds){const l=get();if(!l)return;l.restUntil=seconds?now()+Math.max(5,Math.min(seconds,600))*1000:null;touch(l)}
function cancel(){const l=get();if(!l)return;A.profile().activeLive=null;A.store()}
function finish(rpe=null,notes=""){
 const l=get(),s=session();if(!l||!s)throw Error("ไม่พบ Workout ที่กำลังบันทึก");
 const all=l.steps.every(x=>x.done>=x.total);
 const dur=Math.max(1,toMin(startedMs(l)));
 const sprint=l.steps.find(x=>x.kind==="sprint");
 const sets=l.steps.filter(x=>x.kind==="strength").map(x=>x.title+": "+x.done+"/"+x.total+" เซต").join("; ");
 const status=all?"completed":"partial";
 A.profile().activeLive=null;
 try{
   A.recordSession(l.key,{status,mode:"live",date:A.day(),duration:dur,rpe:rpe===""?null:rpe,repsDone:sprint?.done??null,sets,notes:"Live Workout · "+l.steps.map(x=>x.title+" "+x.done+"/"+x.total).join(" | ")+(notes?" · "+String(notes).slice(0,400):"")});
 }catch(err){A.profile().activeLive=l;A.store();throw err}
 return {status,complete:all,duration:dur};
}
function fmt(ms){const sec=Math.max(0,Math.floor(ms/1000)),h=Math.floor(sec/3600),m=Math.floor(sec%3600/60),s=sec%60;return h?String(h).padStart(2,"0")+":"+String(m).padStart(2,"0")+":"+String(s).padStart(2,"0"):String(m).padStart(2,"0")+":"+String(s).padStart(2,"0")}
function ticks(){const l=get();if(!l)return;const el=document.getElementById("liveElapsed"),rest=document.getElementById("liveRestTime");if(el)el.textContent=fmt(startedMs(l));if(rest){rest.textContent=fmt(Math.max(0,(l.restUntil||0)-now()));if(l.restUntil&&now()>=l.restUntil)rest.classList.add("finished");else rest.classList.remove("finished")}}
function render(){
 const l=get();if(!l)return '<div class="page-head"><h1>เริ่ม Live Workout</h1><p>เลือกแผนและ Session ที่อยากฝึกก่อน</p></div><button data-page="plans" class="btn primary">เลือกแผน</button>';
 const s=session(),step=activeStep();
 if(!s)return '<div class="panel warning"><h2>Session นี้ไม่ได้อยู่ในแผนปัจจุบัน</h2><p>กลับไปเลือกแผนที่กำลังฝึกก่อน หรือยกเลิก Workout นี้</p><button class="btn danger" data-live="cancel">ยกเลิก Workout</button></div>';
 const total=l.steps.reduce((t,x)=>t+x.total,0),done=l.steps.reduce((t,x)=>t+x.done,0),full=l.steps.every(x=>x.done>=x.total);
 return '<div class="live-shell">'+
 '<div class="live-topline"><span class="eyebrow">LIVE WORKOUT · YOUR PACE</span><button type="button" class="btn subtle" data-page="home">กลับหน้าแรก</button></div>'+
 '<div class="live-head"><div><h1>'+clean(s.title)+'</h1><p>Block '+s.block+' · Session '+s.slot+' · บันทึกทีละเที่ยว ทีละเซต</p></div><div class="live-clock"><small>เวลาซ้อม</small><strong id="liveElapsed">'+fmt(startedMs(l))+'</strong></div></div>'+
 '<div class="live-progressbar"><div style="width:'+Math.round(done/Math.max(total,1)*100)+'%"></div></div>'+
 '<div class="live-progress-caption"><span>สำเร็จ '+done+' จาก '+total+' ขั้นย่อย</span><span>ขั้นตอน '+(l.index+1)+' / '+l.steps.length+'</span></div>'+
 '<div class="live-stage"><div class="stage-eyebrow">'+clean(step.kind==="sprint"?"วิ่งเร็ว":step.kind==="strength"?"เวทขา":step.kind==="cardio"?"แอโรบิก":"เตรียมและฟื้นฟู")+'</div>'+
 '<h2>'+clean(step.title)+'</h2><p>'+clean(step.detail)+'</p>'+
 '<div class="live-unit-count"><strong>'+step.done+'</strong><span>/ '+step.total+' '+(step.kind==="sprint"?"เที่ยว":step.kind==="strength"?"เซต":"ขั้นตอน")+'</span></div>'+
 '<div class="live-action-row"><button type="button" class="btn subtle" data-live="undo" '+(step.done===0?"disabled":"")+' aria-label="ย้อนกลับหนึ่งเที่ยว">− 1</button>'+
 '<button type="button" class="btn primary" data-live="mark" '+(step.done>=step.total?"disabled":"")+'>'+(step.done>=step.total?"ทำครบแล้ว ✓":step.kind==="sprint"?"เสร็จอีก 1 เที่ยว ✓":step.kind==="strength"?"เสร็จอีก 1 เซต ✓":"ทำขั้นตอนนี้แล้ว ✓")+'</button></div>'+
 (step.restSeconds>0?'<div class="live-rest"><div><small>REST TIMER</small><strong id="liveRestTime">'+fmt(Math.max(0,(l.restUntil||0)-now()))+'</strong></div><button type="button" class="btn secondary" data-live="rest" data-seconds="'+step.restSeconds+'">เริ่มพัก '+Math.round(step.restSeconds/60*10)/10+' นาที</button>'+(l.restUntil?'<button type="button" class="btn subtle" data-live="skiprest">ข้ามพัก</button>':"")+'</div>':"")+
 '</div>'+
 '<div class="live-pagination"><button type="button" class="btn subtle" data-live="previous" '+(l.index===0?"disabled":"")+'>&larr; ก่อนหน้า</button><button type="button" class="btn secondary" data-live="next" '+(l.index===l.steps.length-1?"disabled":"")+' >ขั้นตอนถัดไป &rarr;</button></div>'+
 '<div class="live-steps"><h3>รายการที่ต้องฝึก</h3>'+l.steps.map((x,i)=>'<button type="button" class="live-step-row '+(i===l.index?"selected":"")+'" data-live="goto" data-index="'+i+'"><span class="live-step-num">'+(x.done===x.total?"✓":i+1)+'</span><span><b>'+clean(x.title)+'</b><small>'+x.done+'/'+x.total+' · '+clean(x.detail)+'</small></span><span class="live-step-chevron">›</span></button>').join("")+'</div>'+
 '<div class="live-bottom panel"><div><b>พร้อมจบการซ้อมแล้วหรือยัง?</b><p>'+(full?"ทำครบทุกขั้นตอนแล้ว บันทึกเสร็จตามแผนได้เลย":"ถ้ายังไม่ครบ สามารถบันทึกแบบ Partial และกลับมาทำ Session นี้ต่อในครั้งหน้า")+'</p></div>'+
 '<label>ความเหนื่อย (RPE 1–10) <input id="liveRpe" type="number" min="1" max="10" inputmode="numeric" placeholder="ไม่บังคับ"></label>'+
 '<button type="button" class="btn primary" data-live="finish">'+(full?"บันทึกว่าเสร็จแล้ว ✓":"บันทึกที่ทำไป (Partial)")+'</button>'+
 '<div class="live-secondary-actions"><button class="btn subtle" type="button" data-live="pause">'+(l.runningSince?"หยุดนาฬิกาชั่วคราว":"เดินนาฬิกาต่อ")+'</button><button class="btn danger" type="button" data-live="cancel">ยกเลิก Live Workout</button></div></div>'+
 '<p class="help">หากปิดเว็บหรือกลับหน้าแรก งานที่กดเช็กไว้จะยังอยู่ในโปรไฟล์ สามารถกลับมาฝึกต่อได้ เวลาจับจากนาฬิกาในเครื่อง ไม่ใช่การจับเวลา Sprint อัตโนมัติ</p></div>';
}
const API={get,session,stepsFor,start,mark,undo,next,previous,togglePause,skipRest,setRest,cancel,finish,fmt,ticks,render};
window.P100Live=API;
if(typeof document!=="undefined"&&typeof setInterval==="function")setInterval(ticks,1000);
})();
