/* PROJECT 100M V2 — responsive UI */
(function(){
"use strict";
const A=window.P100, app=document.getElementById("app");
if(!A||!app){document.body.textContent="Unable to load PROJECT 100M";return}
const esc=v=>String(v??"").replace(/[&<>"']/g,ch=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[ch]));
const f=(v,d=0)=>A.num(v)===null?"—":Number(v).toFixed(d);
let page="home",chosenKey=null,chosenBlock=1,mode="quick",notice="",draftWorkout={};
const download=(name,content,mime)=>{const blob=new Blob([content],{type:mime}),url=URL.createObjectURL(blob),a=document.createElement("a");a.href=url;a.download=name;document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000)};
function banner(){if(!notice)return"";return '<div class="notice" role="status">'+esc(notice)+'</div>'}
function chip(t,kind){return '<span class="chip '+(kind||"")+'">'+esc(t)+'</span>'}
function pctBar(n){return '<div class="progress"><i style="width:'+Math.min(100,Math.max(0,n))+'%"></i></div>'}
function stat(k,v,sub){return '<div class="metric"><span>'+esc(k)+'</span><strong>'+esc(v)+'</strong><small>'+esc(sub||"")+'</small></div>'}
function trendChart(items,key,unit,digits=0){
 const points=items.filter(x=>x&&A.num(x[key])!==null&&A.num(x[key])>0).sort((a,b)=>String(a.date).localeCompare(String(b.date))).slice(-16);
 if(points.length<2)return '<p class="help">ต้องมีข้อมูลอย่างน้อย 2 จุดจึงจะแสดงกราฟได้</p>';
 const values=points.map(x=>Number(x[key])),lo=Math.min(...values),hi=Math.max(...values),range=Math.max(.5,hi-lo);
 const w=500,h=150,pad=20,coords=values.map((v,i)=>[pad+i*(w-2*pad)/(values.length-1),h-pad-(v-lo)/range*(h-2*pad)]);
 const path=coords.map(x=>x.join(",")).join(" ");
 return '<div class="chartbox"><svg viewBox="0 0 '+w+' '+h+'" role="img" aria-label="Trend chart '+esc(key)+'" preserveAspectRatio="none"><path d="M20 130H480 M20 75H480 M20 20H480" stroke="#355363" stroke-width="1" fill="none"/><polyline points="'+path+'" fill="none" stroke="#c8f566" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'+coords.map(x=>'<circle cx="'+x[0]+'" cy="'+x[1]+'" r="3.5" fill="#75dbbc"/>').join("")+'</svg><div class="row space chartlabels"><span>'+esc(points[0].date)+'</span><b>'+values[0].toFixed(digits)+esc(unit)+' → '+values[values.length-1].toFixed(digits)+esc(unit)+'</b><span>'+esc(points[points.length-1].date)+'</span></div></div>'
}
function button(text,act,cls,other){return '<button type="button" class="btn '+(cls||"")+'" data-action="'+esc(act)+'" '+(other||"")+'>'+text+'</button>'}
function allPlansMenu(){const p=A.profile();return p.plans.map(x=>{const tmpl=A.planTemplate(x);const ov=A.planOverview(x);return '<option value="'+esc(x.id)+'" '+(p.activePlanId===x.id?"selected":"")+'>'+esc(tmpl?.name||x.templateId)+" · "+ov.completed+"/"+ov.total+"</option>"}).join("")}
function ico(name,size=20){
const paths={
home:'<path d="m3 10 9-7 9 7v10a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1z"/>',
plans:'<rect x="3" y="4" width="18" height="17" rx="2"/><path d="M7 2v4M17 2v4M3 9h18M8 14h3M14 14h3M8 18h3"/>',
history:'<path d="M3 3v18h18"/><path d="m7 16 5-6 4 3 5-7"/>',
recovery:'<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"/>',
settings:'<circle cx="12" cy="8" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2"/>',
arrow:'<path d="M5 12h14m-6-6 6 6-6 6"/>',
check:'<path d="m5 12 4 4L19 6"/>',
clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
calendar:'<rect x="3" y="4" width="18" height="17" rx="2"/><path d="M8 2v4m8-4v4M3 9h18"/>',
activity:'<path d="M3 12h4l3-8 4 16 3-8h4"/>',
spark:'<path d="m12 2 1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8zM19 17l.8 1.7L22 19.5l-2.2.8L19 22l-.8-1.7-2.2-.8 2.2-.8z"/>',
cloud:'<path d="M20 17a4 4 0 0 0-2-7.5A6.5 6.5 0 0 0 5.8 11 4 4 0 0 0 6 19h12"/><path d="m9 15 3 3 3-3"/>',
chevron:'<path d="m9 18 6-6-6-6"/>',
shoe:'<path d="M2 14c3 0 6-1 8-5 1 2 4 5 9 6 2 1 3 2 3 4v1H2z"/><path d="m12 12-2 3m6 0-2 2"/>',
book:'<path d="M4 4h15v16H4a2 2 0 0 1 0-4h15M4 4a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2"/>'
};
return '<svg class="ui-icon" aria-hidden="true" width="'+size+'" height="'+size+'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">'+(paths[name]||paths.spark)+'</svg>';
}
function hello(){
 const h=new Date().getHours();return h<11?"อรุณสวัสดิ์":h<17?"สวัสดีตอนบ่าย":"สวัสดีตอนเย็น";
}
function nav(){
 const navs=[["home","หน้าหลัก","home"],["plans","แผนฝึก","plans"],["history","บันทึก","history"],["recovery","สุขภาพ","recovery"],["settings","บัญชี","settings"]];
 return navs.map(([id,label,ic])=>'<button type="button" aria-label="'+label+'" data-page="'+id+'" class="'+(page===id?"active":"")+'">'+ico(ic,21)+'<b>'+label+'</b></button>').join("");
}
function header(){
 const p=A.profile(),user=A.cloudUser,cloud=A.cloudStatus;
 const accountLabel=user?"ซิงก์ข้อมูลกับบัญชีแล้ว":"ข้อมูลในเครื่องนี้";
 return '<aside class="sidebar"><div class="brand">'+
 '<div class="brand-mark">'+ico("activity",24)+'</div><div><span class="brand-name">PROJECT 100M</span><small>MOVE AT YOUR PACE</small></div></div>'+
 '<div class="sidebar-caption">เส้นทางที่ดี<br>เริ่มจากก้าวของเราเอง</div><nav aria-label="เมนูหลัก">'+nav()+'</nav>'+
 '<div class="sidebar-note">'+ico("spark",18)+' <span>ไม่ต้องซ้อมตามวัน<br>กลับมาเมื่อพร้อม แล้วไปต่อได้เลย</span></div></aside>'+
 '<main class="main"><header class="top"><button type="button" class="top-brand" data-page="home"><span class="top-logo">'+ico("activity",20)+'</span><span>PROJECT <b>100M</b></span></button>'+
 '<div class="account"><div class="account-meta"><span class="cloud-dot '+(cloud==="synced"?"ok":"")+'" title="'+esc(cloud)+'"></span><span class="cloud-label">'+esc(accountLabel)+'</span></div>'+
 '<label class="sr-only" for="switchProfile">เลือกโปรไฟล์</label><span class="avatar">'+esc(p.name?.slice(0,1).toUpperCase()||"A")+'</span>'+
 '<select id="switchProfile" aria-label="เลือกโปรไฟล์">'+A.profiles().map(x=>'<option value="'+esc(x.id)+'" '+(x.id===p.id?"selected":"")+'>'+esc(x.name)+'</option>').join("")+'</select></div></header>'+
 banner()+'<div class="content">'+content()+'</div>'+
 '<footer><span>Made for progress, at your pace.</span><a href="https://unsplash.com/photos/a-person-running-through-a-field-at-sunrise-d6mx781xnvM" target="_blank" rel="noopener">ภาพ: Uran Wang</a> · <a href="https://unsplash.com/photos/a-male-runner-in-starting-blocks-on-a-track-P-UYSWGKilA" target="_blank" rel="noopener">Peter Zhan / Unsplash</a></footer></main>'+
 '<nav class="bottom-nav" aria-label="เมนูมือถือ">'+nav()+'</nav>';
}
function summary(){
 const p=A.profile(),pl=A.activePlan(),name=esc(p.name);
 if(!pl)return '<section class="welcome-wrap"><div class="welcome-copy"><span class="eyebrow">YOUR SPACE TO GROW</span><h1>'+hello()+', '+name+' <span class="greeting-hand">✳</span></h1><p>มาเริ่มด้วยแผนฝึกที่เหมาะกับคุณกัน</p></div><div class="welcome-photo" role="img" aria-label="บรรยากาศธรรมชาติสำหรับการออกกำลังกาย"></div></section><article class="intro-empty"><div class="empty-symbol">'+ico("spark",28)+'</div><h2>ทุกก้าวเริ่มต้นที่นี่</h2><p>เลือกแผนที่อยากฝึก แล้วแอปจะคอยบอกว่าครั้งต่อไปต้องทำอะไร</p>'+button('เลือกแผนฝึก '+ico("arrow",18),'openPlans','primary')+'</article>';
 const tmpl=A.planTemplate(pl),o=A.planOverview(pl),last=A.history()[0],next=o.next,percent=o.percent;
 return '<section class="welcome-wrap"><div class="welcome-copy"><span class="eyebrow">WELCOME BACK</span><h1>'+hello()+', '+name+' <span class="greeting-hand">✳</span></h1><p>ไม่จำเป็นต้องรีบ — เราค่อย ๆ เก่งขึ้นทีละ Session</p></div><div class="welcome-photo" role="img" aria-label="บรรยากาศอบอุ่นของคนวิ่งตอนเช้า"></div></section>'+
 '<div class="dash-grid"><section class="training-primary"><div class="section-title"><h2>ครั้งต่อไปของคุณ</h2><span>Next up</span></div>'+
 (next?'<article class="next-card"><div class="next-text">'+
 '<div class="next-label"><span class="pulse-dot"></span> พร้อมเมื่อคุณพร้อม <span class="next-separator">·</span> Block '+next.block+' / '+tmpl.blocks+'</div>'+
 '<h2>'+esc(next.title)+'</h2><p>'+esc(next.summary)+'</p>'+
 '<div class="next-meta"><span>'+ico("clock",16)+' ประมาณ '+next.minutes+' นาที</span><span>'+ico("activity",16)+' '+esc(next.kind.toUpperCase())+'</span></div>'+
 button('ดูวิธีฝึก '+ico("arrow",18),'openWorkout','primary','data-key="'+esc(next.key)+'"')+'</div><div class="next-photo" aria-hidden="true"></div></article>':
 '<article class="next-card finish-card"><div class="next-text"><span class="eyebrow">WELL DONE</span><h2>คุณทำครบทุก Session แล้ว!</h2><p>กลับไปดูความก้าวหน้า หรือเลือกแผนใหม่ได้เลย</p>'+button('ดูความก้าวหน้า '+ico("arrow",18),'openHistory','primary')+'</div></article>')+
 '<div class="quick-links"><button type="button" data-page="plans">'+ico("book",22)+'<span><b>ดูแผนทั้งหมด</b><small>รายละเอียดทุกช่วงการฝึก</small></span>'+ico("chevron",17)+'</button>'+
 '<button type="button" data-page="recovery">'+ico("recovery",22)+'<span><b>วันนี้รู้สึกอย่างไร?</b><small>เช็กการพักฟื้นและการนอน</small></span>'+ico("chevron",17)+'</button></div></section>'+
 '<aside class="progress-panel"><div class="section-title"><h2>เส้นทางของคุณ</h2><span>My journey</span></div><div class="journey-card"><div class="journey-header"><div><span class="tiny-label">CURRENT PROGRAM</span><h3>'+esc(tmpl.name)+'</h3></div>'+ico("spark",24)+'</div>'+
 '<div class="progress-ring" style="--percent:'+percent+'"><div><strong>'+percent+'%</strong><small>ความคืบหน้า</small></div></div>'+
 '<div class="journey-count"><span>'+ico("check",17)+' ฝึกครบ <b>'+o.completed+'</b> Sessions</span><span>ทั้งหมด '+o.total+'</span></div>'+
 '<p class="journey-note">ไม่มีวันหมดอายุของแผน หยุดพักแล้วกลับมาฝึกต่อได้เสมอ</p>'+button('ดูเส้นทางทั้งหมด '+ico("arrow",17),'openPlans','subtle')+'</div></aside></div>'+
 '<div class="section-title section-title-lower"><h2>ภาพรวมของคุณ</h2>'+button('ดูประวัติ '+ico("arrow",16),'openHistory','link')+'</div>'+
 '<div class="stats stats-home">'+stat("ฝึกสำเร็จ",o.completed+" / "+o.total,"Sessions")+stat("บันทึกการฝึก",A.history().length,"รายการทั้งหมด")+stat("ครั้งล่าสุด",last?new Date(last.at).toLocaleDateString("th-TH",{day:"numeric",month:"short"}):"—",last?last.title:"ยังไม่มีบันทึก")+'</div>';
}
function planCard(t){
 const current=A.profile().plans.some(p=>p.templateId===t.id);
 const titles={sprint100:"วิ่งเร็ว 100 เมตร",run5k:"เริ่มต้นวิ่ง 5K",strength:"สร้างความแข็งแรง",wellness:"ขยับร่างกายให้สดใส"};
 const cat={sprint100:"SPEED",run5k:"RUNNING",strength:"STRENGTH",wellness:"WELLNESS"};
 return '<article class="template-card template-'+esc(t.id)+'"><div class="template-card-top"><span class="template-art">'+ico(t.id==="sprint100"?"activity":t.id==="wellness"?"recovery":t.id==="strength"?"spark":"shoe",25)+'</span><span class="template-tag">'+esc(cat[t.id]||"FITNESS")+'</span></div><h3>'+esc(titles[t.id]||t.name)+'</h3><p>'+esc(t.description)+'</p><div class="template-bottom"><small>'+t.blocks+' ช่วงการฝึก</small>'+button(current?'เริ่มรอบใหม่ '+ico("arrow",16):'เลือกแผนนี้ '+ico("arrow",16),'startPlan','secondary','data-template="'+esc(t.id)+'"')+'</div></article>';
}
function plans(){
 const p=A.profile(),pl=A.activePlan(),o=A.planOverview(pl),tmpl=A.planTemplate(pl);
 let html='<div class="page-head"><span class="eyebrow">YOUR JOURNEY</span><h1>แผนฝึกของคุณ</h1><p>ฝึกตามลำดับ ไม่จำเป็นต้องฝึกตรงวัน เลือกดูได้ทุกช่วงของโปรแกรม</p></div>';
 if(p.plans.length){
  const next=o.next;
  html+='<article class="panel plan-overview"><div class="row space wrap"><div><span class="tiny-label">กำลังฝึกอยู่</span><h2>'+esc(tmpl?.name||"Training Plan")+'</h2></div><label class="plan-switch">เปลี่ยนโปรแกรม <select id="planSelect">'+allPlansMenu()+'</select></label></div>'+
  '<div class="row space"><span>ความคืบหน้าของโปรแกรม</span><strong>'+o.percent+'%</strong></div>'+pctBar(o.percent)+
  '<div class="plan-overview-foot"><span>'+ico("check",16)+' ทำครบ '+o.completed+' ครั้ง</span><span>ทั้งหมด '+o.total+' Sessions</span></div>'+
  (next?'<button class="plan-next-cta" type="button" data-action="openWorkout" data-key="'+esc(next.key)+'"><span><small>ครั้งต่อไป</small><b>'+esc(next.title)+'</b></span>'+ico("arrow",20)+'</button>':'')+'</article>'+
  '<div class="section-title"><h2>แต่ละช่วงการฝึก</h2><span>เลือกดู Blocks</span></div>'+
  '<div class="blocks" role="group" aria-label="เลือกช่วงการฝึก">'+Array.from({length:tmpl.blocks},(_,i)=>{const count=o.sessions.filter(s=>s.block===i+1&&o.marked.get(s.key)?.status==="completed").length,total=o.sessions.filter(s=>s.block===i+1).length;return '<button type="button" aria-label="Block '+(i+1)+'" class="'+(chosenBlock===i+1?'active':'')+'" data-block="'+(i+1)+'"><b>'+(i+1)+'</b><small>'+count+'/'+total+'</small></button>'}).join("")+'</div>'+
  '<div class="panel session-list"><div class="row space"><div><span class="tiny-label">TRAINING BLOCK</span><h2>ช่วงที่ '+String(chosenBlock).padStart(2,"0")+'</h2></div><span class="session-count">'+(o.sessions.filter(s=>s.block===chosenBlock&&o.marked.get(s.key)?.status==="completed").length)+' / '+o.sessions.filter(s=>s.block===chosenBlock).length+' เสร็จแล้ว</span></div>';
  for(const s of o.sessions.filter(s=>s.block===chosenBlock)){
   const mark=o.marked.get(s.key),status=mark?.status||"upcoming";
   const statusLabel={completed:"เสร็จแล้ว",skipped:"ข้าม",partial:"ทำบางส่วน",upcoming:"ยังไม่เริ่ม"};
   html+='<button class="session-row '+(next?.key===s.key?'is-next':'')+'" data-action="openWorkout" data-key="'+esc(s.key)+'"><span class="session-number">'+(status==="completed"?ico("check",18):s.slot)+'</span><span class="session-text"><b>'+esc(s.title)+'</b><small>'+esc(s.summary)+'</small></span><span class="session-badge '+esc(status)+'">'+(next?.key===s.key?'ถัดไป':statusLabel[status])+'</span>'+ico("chevron",17)+'</button>';
  }
  html+='</div>';
 }else html+='<div class="intro-empty"><h2>เลือกเส้นทางของคุณ</h2><p>เริ่มแผนฝึกแบบที่เหมาะกับตัวเองได้จากด้านล่าง</p></div>';
 html+='<div class="section-title"><h2>แผนอื่น ๆ ที่น่าสนใจ</h2><span>Training library</span></div><div class="template-grid">'+A.templates.map(planCard).join("")+'</div>';
 return html;
}
function exerciseContent(s){if(!s)return"";const e=s.exercises||{},parts=[];if(e.sprint)parts.push('<div class="exercise"><b>Sprint: '+e.sprint.reps+' × '+e.sprint.meters+'m</b><small>Effort '+esc(e.sprint.effort)+' · พักจนฟื้นตัว</small></div>');if(e.duration)parts.push('<div class="exercise"><b>Time target: '+e.duration+' นาที</b><small>เน้นความสบายก่อนความเร็ว</small></div>');if(e.strength)for(let i=0;i<e.strength.length;i++){const x=e.strength[i];parts.push('<div class="exercise"><b>'+esc(x.name)+'</b><small>'+x.sets+' sets × '+esc(x.reps)+'</small></div>')}return parts.join("")}
function workout(){const s=A.sessionByKey(chosenKey)||A.planOverview(A.activePlan())?.next;if(!s)return '<div class="page-head"><h1>ยังไม่มี Workout</h1></div>'+button('เลือกแผน','openPlans','primary');chosenKey=s.key;const warnings=A.readiness(s),logged=A.planOverview(A.activePlan()).marked.get(s.key);
return '<div class="page-head"><span class="eyebrow">ช่วงฝึกที่ '+s.block+' · ครั้งที่ '+s.slot+'</span><h1>'+esc(s.title)+'</h1><p>'+esc(s.summary)+'</p></div><div class="row wrap">'+chip(s.kind.toUpperCase())+chip("EST. "+s.minutes+" MIN")+(logged?chip("ล่าสุด: "+logged.status):"")+'</div>'+
(warnings.length?'<div class="warning"><b>Recovery Check</b>'+warnings.map(w=>'<p>'+esc(w)+'</p>').join("")+'<p>หากมีอาการเจ็บหรืออาการผิดปกติขณะออกแรง ควรหยุดและประเมินความพร้อมก่อน</p></div>':"")+
'<div class="panel"><h2>วิธีฝึกครั้งนี้</h2><p>'+esc(s.details)+'</p><div class="exercise-list">'+exerciseContent(s)+'</div></div>'+
'<div class="section-title"><h2>บันทึกผลหลังซ้อม</h2><span>ตามที่คุณทำจริง</span></div>'+
'<div class="segmented"><button data-mode="quick" class="'+(mode==="quick"?"active":"")+'">บันทึกแบบเร็ว</button><button data-mode="detailed" class="'+(mode==="detailed"?"active":"")+'">บันทึกละเอียด</button></div>'+
'<form id="workoutForm" class="panel form"><input type="hidden" name="key" value="'+esc(s.key)+'"><input type="hidden" name="mode" value="'+mode+'"><div class="grid-2">'+
'<label>วันที่ซ้อมจริง<input name="date" type="date" value="'+A.day()+'" required></label><label>วันนี้ทำได้แค่ไหน?<select name="status"><option value="completed">ทำครบตามแผน</option><option value="partial">ทำได้บางส่วน</option><option value="skipped">ข้ามการฝึกครั้งนี้</option></select></label>'+
'<label>ระยะเวลาจริง (นาที)<input name="duration" inputmode="decimal" type="number" min="0" max="600" step=".1" placeholder="เช่น 35"></label>'+
(mode==="quick"?'<div class="quick-rpe"><label>วันนี้รู้สึกเหนื่อยแค่ไหน?</label><input type="hidden" name="rpe" value=""><div class="feelings" role="group" aria-label="เลือกความเหนื่อย"><button type="button" data-rpe="2" aria-pressed="false"><span>☺</span><b>สบาย ๆ</b><small>RPE 2</small></button><button type="button" data-rpe="4" aria-pressed="false"><span>◡</span><b>กำลังดี</b><small>RPE 4</small></button><button type="button" data-rpe="6" aria-pressed="false"><span>⌁</span><b>เริ่มเหนื่อย</b><small>RPE 6</small></button><button type="button" data-rpe="8" aria-pressed="false"><span>!</span><b>หนักมาก</b><small>RPE 8</small></button></div></div>':'<label>ความเหนื่อย RPE (1–10)<input name="rpe" type="number" min="1" max="10" step="1" placeholder="เช่น 6"></label>')+'</div>'+
(mode==="detailed"?'<div class="grid-2"><label>ระยะทาง (กม.)<input name="distanceKm" type="number" min="0" step=".01" placeholder="2.5"></label><label>Average HR (bpm)<input name="avgHr" type="number" min="30" max="250" step="1"></label><label>Maximum HR (bpm)<input name="maxHr" type="number" min="30" max="250" step="1"></label><label>จำนวนเที่ยว Sprint จริง<input name="repsDone" type="number" min="0" max="100" step="1"></label><label>ระยะ Sprint ที่จับเวลา (เมตร)<input name="sprintMeters" type="number" min="1" max="1000" step="1" placeholder="100"></label><label>เวลาที่จับได้ (วินาที)<input name="sprintSeconds" type="number" min="0" max="600" step=".01" placeholder="ต้องจับเวลาจริง"></label></div>'+
(s.exercises.strength?'<div class="detail-sets"><b>ผลเวทจริง (น้ำหนัก × ครั้ง × เซต)</b>'+s.exercises.strength.map((x,i)=>'<label>'+esc(x.name)+'<input name="ex_'+i+'" maxlength="100" placeholder="เช่น 12kg × 8 × 2"></label>').join("")+'</div>':""):"")+
'<label>บันทึกเพิ่มเติม<textarea name="notes" rows="3" maxlength="2000" placeholder="เช่น รู้สึกเร็วขึ้น / ตึงกล้ามเนื้อ / ย้ายวันซ้อม"></textarea></label><div class="row wrap">'+button('บันทึกผลการฝึก ✓','saveWorkout','primary')+button('กลับไปที่แผน','openPlans','secondary')+'</div><p class="help">Completed จะเปิด Session ถัดไป · Partial จะยังค้าง Session เดิม · Skipped ต้องเลือกเองอย่างชัดเจน</p></form>';
}
function history(){const list=A.history(),legacy=A.profile().legacyWorkouts||[],apple=A.profile().appleWorkouts||[],pb=list.filter(x=>x.sprintMeters===100&&x.sprintSeconds>0),best=pb.length?Math.min(...pb.map(x=>x.sprintSeconds)):null;
return '<div class="page-head"><small class="eyebrow">YOUR PROGRESS</small><h1>บันทึกการฝึก</h1><p>ดูย้อนหลังว่าทำอะไรจริง รวมทั้งความก้าวหน้าของ 100 เมตร</p></div>'+
'<div class="stats">'+stat("RECORDS",list.length,"V2 sessions")+stat("100M BEST",best===null?"—":f(best,2)+" sec","จับเวลาจริงเท่านั้น")+stat("V1 IMPORTED",legacy.length,"Workout บันทึกเก่า")+'</div>'+
'<div class="panel"><h2>100m Personal Best Trend</h2>'+trendChart(list.filter(x=>x.sprintMeters===100&&x.sprintSeconds>0),"sprintSeconds"," sec",2)+'</div>'+
'<div class="panel"><div class="row space"><h2>บันทึกการฝึกที่ผ่านมา</h2>'+button('Export Coach Report','downloadReport','secondary')+'</div>'+
(list.length?list.slice(0,100).map(x=>'<div class="history-item"><div><b>'+esc(x.title)+'</b><small>'+esc(x.template)+' · '+esc(x.date)+' · '+esc(x.status)+'</small><p>'+esc([x.duration!==null?x.duration+" min":"",x.rpe!==null?"RPE "+x.rpe:"",x.distanceKm!==null?x.distanceKm+" km":"",x.notes].filter(Boolean).join(" · "))+'</p></div>'+chip(x.status,x.status==="completed"?"green":"")+'</div>').join(""):'<div class="empty">ยังไม่มีข้อมูลการซ้อม · บันทึกจาก Next Workout ได้เลย</div>')+'</div>'+
(apple.length?'<div class="panel"><h2>Apple Watch Workouts · นำเข้าจาก Apple Health</h2><p class="help">Workout เหล่านี้เก็บเป็นหลักฐานการออกกำลังกาย แต่ไม่ได้ทำเครื่องหมาย Session ว่า Completed อัตโนมัติ</p>'+apple.slice(0,50).map(x=>'<div class="history-item"><div><b>'+esc(x.kind)+'</b><small>'+esc(x.date)+' · '+(x.duration??'—')+' นาที'+(x.distanceKm!==null?' · '+f(x.distanceKm,2)+' km':'')+'</small><p>HR avg '+(x.avgHr??'—')+' bpm · max '+(x.maxHr??'—')+' bpm</p></div>'+chip('APPLE HEALTH','green')+'</div>').join('')+'</div>':'')+
(legacy.length?'<div class="panel"><h2>Previous V1 History</h2>'+legacy.slice(0,30).map(x=>'<div class="history-item"><div><b>'+esc(x.type||"Workout")+'</b><small>'+esc(x.date)+' · '+esc(x.minutes||"")+" นาที"+'</small></div>'+chip("V1")+'</div>').join("")+'</div>':"");
}
function recovery(){const p=A.profile(),rows=p.recovery||[],latest=rows[0];return '<div class="page-head"><small class="eyebrow">RECOVERY</small><h1>สุขภาพและการพักฟื้น</h1><p>ติดตามการนอน หัวใจขณะพัก ความล้า และอาการกล้ามเนื้อ ไม่ใช้ตัวเลขเหล่านี้วินิจฉัยโรค</p></div>'+
'<div class="stats">'+stat("SLEEP",latest&&latest.sleep!==null?f(latest.sleep,1)+" h":"—","ล่าสุด")+stat("RESTING HR",latest&&latest.rhr!==null?f(latest.rhr,0)+" bpm":"—","ล่าสุด")+stat("HRV (SDNN)",latest&&latest.hrv!==null?f(latest.hrv,0)+" ms":"—","เทียบแนวโน้มรายบุคคล")+'</div>'+
'<div class="panel"><h2>Resting HR Trend</h2>'+trendChart(rows,"rhr"," bpm",0)+'</div>'+
'<div class="panel"><h2>Sleep Trend</h2>'+trendChart(rows,"sleep"," h",1)+'</div>'+
'<form id="recoveryForm" class="panel form"><h2>เช็กความพร้อมของวันนี้</h2><div class="grid-2"><label>วันที่<input type="date" name="date" value="'+A.day()+'" required></label><label>นอน (ชั่วโมง)<input type="number" name="sleep" min="0" max="24" step=".1"></label><label>Resting HR (bpm)<input type="number" name="rhr" min="25" max="250" step="1"></label><label>HRV SDNN (ms)<input type="number" name="hrv" min="0" max="500" step=".1"></label><label>Fatigue (1–5)<select name="fatigue"><option value="">ไม่ระบุ</option>'+Array.from({length:5},(_,i)=>'<option value="'+(i+1)+'">'+(i+1)+'</option>').join("")+'</select></label><label>Muscle soreness (1–5)<select name="soreness"><option value="">ไม่ระบุ</option>'+Array.from({length:5},(_,i)=>'<option value="'+(i+1)+'">'+(i+1)+'</option>').join("")+'</select></label></div><label>หมายเหตุ<textarea name="notes" rows="2" maxlength="1000" placeholder="เช่น นอนน้อยเพราะทำงาน / ปวดหลังต้นขา"></textarea></label><button type="submit" class="btn primary">บันทึก Recovery</button></form>'+
'<div class="panel"><h2>บันทึกการพักฟื้นล่าสุด</h2>'+(rows.length?rows.slice(0,14).map(x=>'<div class="history-item"><div><b>'+esc(x.date)+'</b><small>Sleep '+(x.sleep??"—")+'h · RHR '+(x.rhr??"—")+' · HRV '+(x.hrv??"—")+' · Fatigue '+(x.fatigue??"—")+'/5</small><p>'+esc(x.notes||"")+'</p></div></div>').join(""):'<div class="empty">ยังไม่มี Recovery Check-in</div>')+'</div>';
}
function settings(){const user=A.cloudUser,c=A.cloudStatus,p=A.profile(),configured=!!window.PROJECT100M_CONFIG?.url;return '<div class="page-head"><small class="eyebrow">MY SPACE</small><h1>บัญชีและข้อมูล</h1><p>โปรไฟล์และข้อมูลแยกกัน · ใช้ Supabase Auth สำหรับซิงก์เมื่อเชื่อมบริการแล้ว</p></div>'+
'<div class="panel form"><h2>โปรไฟล์ของฉัน</h2><p>โปรไฟล์ที่แยกกันจะมีโปรแกรมและบันทึกของตัวเอง ถ้าต้องการใช้คนละโทรศัพท์พร้อมข้อมูลส่วนตัวจริง ๆ ให้แต่ละคนล็อกอินคนละบัญชี</p><form id="renameForm" class="inline-form"><label>ชื่อโปรไฟล์<input name="name" maxlength="50" value="'+esc(p.name)+'" required></label><button type="submit" class="btn secondary">เปลี่ยนชื่อ</button></form><form id="addProfileForm" class="inline-form"><label>สร้างโปรไฟล์ใหม่<input name="name" maxlength="50" placeholder="ชื่อผู้ฝึก" required></label><button type="submit" class="btn secondary">+ Add Profile</button></form></div>'+
'<div class="panel form"><div class="row space"><h2>เข้าสู่ระบบและซิงก์ข้อมูล</h2>'+chip(c,c==="synced"?"green":"")+'</div>'+
(!configured?'<div class="warning"><b>ยังไม่ได้เปิด Cloud Sync</b><p>เว็บไซต์ยังไม่มี Supabase Project URL และ Publishable Key ข้อมูลจะเก็บในเบราว์เซอร์นี้เท่านั้น ต้องทำขั้นตอนในไฟล์ CLOUD_SETUP.md ก่อนจึงจะล็อกอินและซิงก์ข้าม iPhone ได้</p></div>':
 user?'<p>กำลังใช้บัญชี <b>'+esc(user.email||user.id)+'</b> · revision '+A.cloudRevision+'</p><div class="row wrap">'+button('ซิงก์ตอนนี้','syncNow','primary')+button('Download cloud version','pullCloud','secondary')+button('ออกจากระบบ','signOut','danger')+'</div>':
 '<p class="help">ก่อนใช้ Magic Link ครั้งแรก เจ้าของโปรเจกต์ต้องตั้งค่า <a href="https://supabase.com/dashboard/project/rbryddekjwytcoqqgcgu/auth/url-configuration" target="_blank" rel="noopener">Auth URL Configuration</a> ให้ Site URL และ Redirect URLs เป็น https://ijennyrsm.github.io/project-100m-dashboard/</p><form id="signInForm" class="inline-form"><label>อีเมลสำหรับ Magic Link<input type="email" name="email" required placeholder="you@example.com"></label><button type="submit" class="btn primary">ส่งลิงก์เข้าสู่ระบบ</button></form><p class="help">เปิดอีเมลบน iPhone แล้วกดลิงก์เข้าสู่ระบบ ไม่ต้องตั้งรหัสผ่าน</p>')+
'<p class="help">สถานะ '+esc(c)+' · ระบบจะไม่ส่งข้อมูลไปคลาวด์จนกว่าจะตั้งค่าและเข้าสู่ระบบสำเร็จ</p></div>'+
'<div class="panel form"><h2>สำรองและกู้คืนข้อมูล</h2><p>ควรสำรองเป็นประจำ โดยเฉพาะระหว่างที่ยังไม่ได้เปิด Cloud Sync</p><div class="row wrap">'+button('Download JSON Backup','backup','secondary')+button('Export Coach Report','downloadReport','secondary')+'</div><label>Restore PROJECT 100M V2 JSON<input id="restoreFile" type="file" accept=".json,application/json"></label><p class="help">Restore จะแทนข้อมูลโปรไฟล์ทั้งหมดของบัญชีหรือเครื่องนี้ กรุณาสำรองก่อน</p></div>'+
'<div class="panel form"><h2>เชื่อมข้อมูลจาก Apple Health</h2><p>นำเข้า Workout ที่บันทึกจาก Apple Watch รวมทั้ง Resting HR, HRV, Sleep และ Weight โดยระบบจะอ่านไฟล์ในเบราว์เซอร์และเก็บเฉพาะข้อมูลที่เกี่ยวข้อง</p><label>ช่วงข้อมูลที่ต้องการนำเข้า <select id="healthDaysV2"><option value="30">30 วัน</option><option value="90" selected>90 วัน</option><option value="180">180 วัน</option><option value="365">365 วัน</option></select></label><label>เลือกไฟล์ export.xml หรือ export.zip จากแอป Health<input id="healthFileV2" type="file" accept=".xml,.zip,application/xml,application/zip"></label><p id="healthImportStatus" class="help">ยังไม่ได้เลือกไฟล์ · สามารถส่งออกได้จาก Apple Health → โปรไฟล์ → Export All Health Data</p><p class="help">ไม่นำเข้าข้อมูลสุขภาพทั้งหมด และไม่อัปโหลดไฟล์ต้นฉบับขึ้น GitHub หากคุณเปิด Cloud Sync ข้อมูลที่สกัดแล้วของโปรไฟล์นี้จะซิงก์ไปยังบัญชี Supabase ตามที่คุณยินยอม Apple Health ไม่สามารถซิงก์อัตโนมัติจาก Safari อย่างเดียว</p><div class="row wrap"><button type="button" class="btn secondary" data-action="openV1">ดูหน้า V1 เดิม</button><button type="button" class="btn secondary" data-action="importLegacy">นำประวัติ V1 เข้ามาอีกครั้ง</button><span class="help">กรณีคุณยังนำเข้าไฟล์ผ่านเว็บ V1</span></div></div>'+
'<div class="panel"><h2>ความเป็นส่วนตัว</h2><p>เว็บไซต์นี้เผยแพร่โค้ดผ่าน GitHub Pages แต่ข้อมูลสุขภาพไม่ถูก commit ลง GitHub เมื่อเปิด Cloud Sync ข้อมูลจะถูกเก็บใน Supabase ภายใต้ Row Level Security ตามบัญชีผู้ใช้</p></div>';
}
function content(){
 switch(page){case "plans":return plans();case "workout":return workout();case "history":return history();case "recovery":return recovery();case "settings":return settings();default:return summary()}
}
function render(){app.innerHTML=header();document.title="PROJECT 100M — "+(page==="home"?"หน้าหลัก":page);if(page==="workout"&&Object.keys(draftWorkout).length){const f=document.getElementById("workoutForm");if(f)for(const [name,value] of Object.entries(draftWorkout)){const input=f.elements.namedItem(name);if(input&&["INPUT","TEXTAREA","SELECT"].includes(input.tagName)&&name!=="mode"&&name!=="key")input.value=value}if(draftWorkout.rpe){app.querySelectorAll("[data-rpe]").forEach(el=>el.setAttribute("aria-pressed",String(el.dataset.rpe===String(draftWorkout.rpe))))}}}
function captureWorkout(){const f=document.getElementById("workoutForm");if(f)draftWorkout=Object.fromEntries(new FormData(f))}

function show(t){if(t==="plans"&&page!==t){chosenBlock=A.planOverview(A.activePlan())?.next?.block||1}page=t;notice="";render();window.scrollTo({top:0,behavior:"instant"})}
function info(message){notice=message;render();window.scrollTo({top:0,behavior:"smooth"})}
async function handleAction(el){const a=el.dataset.action;try{
if(a==="openPlans"){draftWorkout={};show("plans")}
else if(a==="openHistory")show("history");
else if(a==="openWorkout"){chosenKey=el.dataset.key||A.planOverview(A.activePlan())?.next?.key;mode="quick";draftWorkout={};show("workout")}
else if(a==="startPlan"){const id=el.dataset.template;if(A.activePlan()&&!confirm("เริ่มโปรแกรมใหม่? โปรแกรมเดิมยังเก็บไว้ในรายการ Plans สามารถสลับกลับได้"))return;A.startPlan(id);chosenBlock=1;show("plans");info("เริ่มโปรแกรมใหม่แล้ว เลือก Session เพื่อดูรายละเอียดได้เลย")}
else if(a==="saveWorkout"){const form=document.getElementById("workoutForm");if(!form.reportValidity())return;const x=Object.fromEntries(new FormData(form));if(x.sprintSeconds&&(!x.sprintMeters||Number(x.sprintMeters)<=0))throw Error("กรุณาระบุระยะที่จับเวลา");if(x.sprintMeters&&x.sprintSeconds&&Number(x.sprintMeters)===100&&Number(x.sprintSeconds)<8)throw Error("เวลา 100m ต่ำผิดปกติ กรุณาตรวจสอบ");const sets=Object.keys(x).filter(k=>k.startsWith("ex_")).map(k=>x[k]&&k+": "+x[k]).filter(Boolean).join("; ");A.recordSession(x.key,{...x,sets});chosenKey=null;draftWorkout={};show("home");info(x.status==="completed"?"บันทึกเรียบร้อย · Session ถัดไปพร้อมแล้ว":x.status==="partial"?"บันทึกบางส่วนแล้ว · Session เดิมยังรอให้ทำครบ":"ข้าม Session นี้แล้ว · ดูรายการต่อไปได้")}
else if(a==="backup")download("project-100m-v2-"+A.day()+".json",A.backup(),"application/json");
else if(a==="downloadReport")download("project-100m-coach-report-"+A.day()+".md",A.coachReport(),"text/markdown");
else if(a==="syncNow"){await A.sync();info("สถานะ Sync: "+A.cloudStatus)}
else if(a==="pullCloud"){if(!confirm("ต้องการโหลดข้อมูลจากคลาวด์แทนข้อมูลปัจจุบัน? กรุณา Download JSON Backup ก่อน"))return;await A.pullCloud(true);info("โหลดข้อมูลคลาวด์เรียบร้อย")}
else if(a==="openV1"){window.open("v1.html","_blank","noopener")}
else if(a==="importLegacy"){const ok=A.importLegacy(true);info(ok?"ดึงข้อมูลจาก V1 เข้ามาแล้ว":"ยังไม่พบข้อมูล V1 บนอุปกรณ์นี้")}
else if(a==="signOut"){await A.signOut();show("home")}
}catch(e){alert(e.message||String(e))}}
app.addEventListener("click",e=>{const el=e.target.closest("[data-page],[data-action],[data-mode],[data-block],[data-rpe]");if(!el)return;if(el.dataset.page){show(el.dataset.page);return}if(el.dataset.mode){captureWorkout();mode=el.dataset.mode;render();return}if(el.dataset.rpe){const f=document.getElementById("workoutForm");const inp=f?.elements.namedItem("rpe");if(inp){inp.value=el.dataset.rpe;app.querySelectorAll("[data-rpe]").forEach(x=>x.setAttribute("aria-pressed",String(x===el)))}return}if(el.dataset.block){chosenBlock=Number(el.dataset.block);render();return}if(el.dataset.action)void handleAction(el)});
app.addEventListener("change",e=>{if(e.target.id==="healthFileV2"){const file=e.target.files?.[0];if(!file)return;const input=e.target,days=document.getElementById("healthDaysV2")?.value||90;const status=document.getElementById("healthImportStatus");if(A.cloudUser&&!confirm("ข้อมูลที่นำเข้าจาก Apple Health จะเก็บในโปรไฟล์และซิงก์ไปยัง Supabase ของคุณ ต้องการทำต่อไหม?")){input.value="";return}input.disabled=true;if(status)status.textContent="กำลังอ่านไฟล์...";A.importAppleHealth(file,days,pct=>{const el=document.getElementById("healthImportStatus");if(el)el.textContent="กำลังนำเข้า "+pct+"%"}).then(res=>{info("นำเข้า Apple Health สำเร็จ: Workout ใหม่ "+res.workouts+" รายการ และข้อมูลพักฟื้น "+res.recoveryDays+" วัน")}).catch(err=>{const el=document.getElementById("healthImportStatus");if(el)el.textContent="นำเข้าไม่สำเร็จ: "+err.message;else alert(err.message)}).finally(()=>{input.disabled=false;input.value=""});return}
if(e.target.id==="switchProfile"){A.selectProfile(e.target.value);chosenKey=null;chosenBlock=1;show("home")}else if(e.target.id==="planSelect"){A.selectPlan(e.target.value);chosenBlock=1;render()}else if(e.target.id==="restoreFile"){const file=e.target.files?.[0];if(!file)return;if(!confirm("Restore จะแทนข้อมูลในโปรไฟล์ทั้งหมด ต้องการทำต่อหรือไม่?"))return;file.text().then(t=>{A.restore(t);show("home");info("กู้คืนข้อมูล V2 สำเร็จ")}).catch(err=>alert("Restore ไม่สำเร็จ: "+err.message))}});
app.addEventListener("submit",async e=>{e.preventDefault();const form=e.target,values=Object.fromEntries(new FormData(form));try{
if(form.id==="recoveryForm"){A.recordRecovery(values);info("บันทึกข้อมูล Recovery เรียบร้อย");}
if(form.id==="renameForm"){A.renameProfile(values.name);info("แก้ไขชื่อโปรไฟล์แล้ว");}
if(form.id==="addProfileForm"){A.addProfile(values.name);show("home");info("สร้างโปรไฟล์แล้ว คุณสามารถเลือกโปรแกรมที่ต่างจากคนอื่นได้");}
if(form.id==="signInForm"){await A.signIn(values.email);info("ส่งลิงก์เข้าสู่ระบบแล้ว กรุณาตรวจอีเมล")}
}catch(err){alert(err.message||String(err))}});
A.onChange(()=>render());A.importLegacy();render();void A.initCloud();
})();
