/* PROJECT 100M — transparent sleep and coach insight summaries, not medical advice.
Original code based on Apple Health data definitions; no code copied from NOOP. */
(function(){
"use strict";
const A=window.P100;if(!A)return;
const esc=v=>String(v??"").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#39;");
const num=x=>x===null||x===undefined||x===""||!Number.isFinite(Number(x))?null:Number(x);
const avg=a=>a.length?a.reduce((x,y)=>x+y,0)/a.length:null;
const med=a=>{if(!a.length)return null;const s=a.slice().sort((x,y)=>x-y);return s.length%2?s[(s.length-1)/2]:(s[s.length/2-1]+s[s.length/2])/2};
const fmt=(x,n=1)=>x===null||x===undefined?"—":Number(x).toFixed(n);
function rows(){return(A.profile()?.recovery||[]).filter(x=>x.date).slice().sort((a,b)=>String(b.date).localeCompare(String(a.date)))}
function goal(){const x=num(A.profile()?.sleepGoalHours);return x>=5&&x<=11?x:8}
function sleepAnalysis(){
 const r=rows(),s=r.filter(x=>num(x.sleep)!==null&&x.sleep>0),last=s[0]||null,old=s.slice(1,15);
 const baseline=med(old.map(x=>num(x.sleep)).filter(x=>x!==null)),hours=num(last?.sleep),g=goal();
 const rhr=r.filter(x=>num(x.rhr)!==null).slice(0,15),hrv=r.filter(x=>num(x.hrv)!==null).slice(0,15);
 const bedtime=s.slice(0,14).filter(x=>x.sleepStart).map(x=>{const d=new Date(x.sleepStart);if(!Number.isFinite(d.getTime()))return null;let mins=d.getHours()*60+d.getMinutes();return mins<720?mins+1440:mins}).filter(x=>x!==null);
 const m=med(bedtime);
 const flags=[];
 if(hours!==null&&hours<g-1)flags.push("คืนล่าสุดนอนต่ำกว่าเป้าหมายมากกว่า 1 ชั่วโมง");
 const rhrBase=med(rhr.slice(1).map(x=>Number(x.rhr))),hrvBase=med(hrv.slice(1).map(x=>Number(x.hrv)));
 if(rhr.length>=5&&rhrBase!==null&&rhr[0].rhr>1.1*rhrBase)flags.push("Resting HR ล่าสุดสูงกว่าค่ากลางก่อนหน้า");
 if(hrv.length>=5&&hrvBase!==null&&hrv[0].hrv<.8*hrvBase)flags.push("HRV ล่าสุดต่ำกว่าค่ากลางก่อนหน้า");
 if(num(r[0]?.fatigue)>=4||num(r[0]?.soreness)>=4)flags.push("ความล้าหรือปวดเมื่อยสูงจากการบันทึกล่าสุด");
 return {last,hours,goal:g,baseline,average7:avg(s.slice(0,7).map(x=>Number(x.sleep))),percent:hours===null?null:Math.min(100,Math.round(hours/g*100)),count:s.length,stages:last?.sleepStages||null,coverage:last?.sleepStageCoverage??null,
  consistency:bedtime.length>=5?med(bedtime.map(x=>Math.abs(x-m))):null,bedtimeCount:bedtime.length,
  rhrNow:num(rhr[0]?.rhr),rhrBase,hrvNow:num(hrv[0]?.hrv),hrvBase,flags};
}
function sleepView(){
 const x=sleepAnalysis(),p=x.last;
 if(!p)return '<article class="panel sleep-empty"><div class="sleep-moon">☾</div><h2>ยังไม่มีข้อมูลการนอน</h2><p>นำเข้าไฟล์ Apple Health ที่หน้า <b>บัญชี</b> หรือกรอกชั่วโมงนอนใน Recovery เพื่อเริ่มติดตามแนวโน้ม</p><button type="button" class="btn secondary" data-page="settings">นำเข้าข้อมูล Apple Health</button></article>';
 const values=x.stages||{},arr=[["core","Core / หลับตื้น","#b8ceb0"],["deep","Deep / หลับลึก","#558a76"],["rem","REM","#9aadd7"],["unspecified","ไม่ระบุระยะ","#d9ddd5"]];
 const total=arr.reduce((sum,[k])=>sum+(num(values[k])||0),0);
 return '<article class="panel sleep-card"><div class="sleep-title"><div><span class="eyebrow">SLEEP INSIGHTS · BETA</span><h2>เมื่อคืนคุณนอนเป็นอย่างไร?</h2><p>ข้อมูลล่าสุด: '+esc(p.date)+' · '+esc(p.source||"บันทึกส่วนตัว")+'</p></div><div class="sleep-score"><strong>'+fmt(x.percent,0)+'%</strong><small>ของเป้าหมาย</small></div></div>'+
 '<div class="sleep-hero"><div><small>เวลานอนรวม</small><strong>'+fmt(x.hours)+' <span>ชม.</span></strong></div><div><small>เป้าหมาย</small><strong>'+fmt(x.goal)+' <span>ชม.</span></strong></div><div><small>เฉลี่ย 7 คืน</small><strong>'+fmt(x.average7)+' <span>ชม.</span></strong></div></div>'+
 (total>0?'<div class="sleep-stages"><div class="row space"><b>ช่วงการนอนจาก Apple Watch</b><small>ข้อมูลระยะการนอน '+(x.coverage??"—")+'%</small></div>'+
 '<div class="sleep-stage-strip">'+arr.filter(([k])=>(num(values[k])||0)>0).map(([k,label,color])=>'<span style="background:'+color+';width:'+Math.max(.5,values[k]/total*100)+'%" title="'+esc(label)+'"></span>').join("")+'</div>'+
 '<div class="sleep-stage-legend">'+arr.filter(([k])=>(num(values[k])||0)>0).map(([k,label,color])=>'<span><i style="background:'+color+'"></i>'+label+' <b>'+fmt(values[k])+' ชม.</b></span>').join("")+'</div></div>':
 '<p class="help">ยังไม่มีข้อมูลระยะ REM, Deep และ Core หาก Apple Health มีข้อมูลจาก Apple Watch จะนำเข้าได้จากหน้า บัญชี</p>')+
 '<div class="sleep-footnote">เปอร์เซ็นต์คือเวลานอนเทียบกับเป้าหมาย ไม่ใช่คะแนน WHOOP หรือคะแนนทางการแพทย์ ระยะการนอนเป็นค่าประมาณจากอุปกรณ์และอาจไม่ครบทุกช่วง</div></article>';
}
function bullets(){
 const x=sleepAnalysis(),items=[],next=A.planOverview(A.activePlan())?.next,last=A.history()[0];
 if(!x.count)items.push({tone:"neutral",title:"เริ่มจากข้อมูลพื้นฐาน",body:"ยังไม่มีคืนที่บันทึกเวลานอน นำเข้าจาก Apple Health หรือบันทึกเองก่อน จะไม่คาดเดาคะแนนหรือแนวโน้ม"});
 else if(x.hours<x.goal-1)items.push({tone:"caution",title:"เมื่อคืนพักผ่อนน้อยกว่าเป้าหมาย",body:"นอน "+fmt(x.hours)+" ชั่วโมง เทียบกับเป้าหมาย "+fmt(x.goal)+" ชั่วโมง หากจะซ้อม Sprint หนัก ควรประเมินความพร้อมและอาจลดความหนัก"});
 else items.push({tone:"positive",title:"ข้อมูลการนอนคืนล่าสุด",body:"นอน "+fmt(x.hours)+" ชั่วโมง "+(x.baseline===null?"ยังมีข้อมูลไม่พอเปรียบเทียบ":(x.hours>=x.baseline?"สูง":"ต่ำ")+"กว่าค่ากลางก่อนหน้าประมาณ "+fmt(Math.abs(x.hours-x.baseline))+" ชั่วโมง")});
 if(x.consistency!==null)items.push({tone:"neutral",title:"ความสม่ำเสมอของเวลาเข้านอน",body:"เวลาเข้านอนคลาดเคลื่อนจากค่ากลางประมาณ "+Math.round(x.consistency)+" นาที จาก "+x.bedtimeCount+" คืน"});
 if(x.rhrNow!==null&&x.hrvNow!==null&&x.rhrBase!==null&&x.hrvBase!==null)items.push({tone:"neutral",title:"แนวโน้มหัวใจและการฟื้นตัว",body:"RHR ล่าสุด "+fmt(x.rhrNow,0)+" bpm เทียบค่ากลาง "+fmt(x.rhrBase,0)+" และ HRV "+fmt(x.hrvNow,0)+" ms เทียบค่ากลาง "+fmt(x.hrvBase,0)+" ms ค่านี้ผันแปรได้จากหลายปัจจัย"});
 if(x.flags.length)items.push({tone:"caution",title:"เช็กความพร้อมก่อนออกแรง",body:x.flags.join(" · ")+" หากมีอาการผิดปกติควรหยุดฝึกและปรึกษาผู้เชี่ยวชาญ"});
 if(next)items.push({tone:"neutral",title:"การฝึกครั้งต่อไป",body:next.title+" — "+next.summary+". แผนยังรอคุณและไม่ผูกกับวันที่"});
 if(last)items.push({tone:"neutral",title:"การซ้อมครั้งก่อน",body:last.title+" ("+last.date+") · "+last.status+(last.rpe?" · RPE "+last.rpe+"/10":"")});
 return items.slice(0,6)
}
function coachView(){
 const list=bullets(),x=sleepAnalysis();
 return '<div class="page-head"><span class="eyebrow">YOUR TRAINING COMPANION</span><h1>Coach Insights</h1><p>สรุปการฝึก การนอน และการฟื้นตัวให้เข้าใจง่าย เพื่อประกอบการตัดสินใจ</p></div>'+
 '<div class="panel coach-intro"><span class="eyebrow">EXPLAINABLE COACH · BETA</span><h2>ข้อมูลก่อนคำแนะนำเสมอ</h2><p>ตอนนี้ใช้กฎวิเคราะห์ที่ตรวจสอบได้ ยังไม่ใช่โมเดล AI สนทนาแบบ Generative AI การเชื่อม AI จริงต้องมีบริการฝั่งเซิร์ฟเวอร์และจัดการ API Key อย่างปลอดภัย</p><div class="coach-data-count"><span>การนอน '+x.count+' คืน</span><span>Workout '+A.history().length+' ครั้ง</span></div></div>'+
 '<div class="coach-insight-list">'+list.map((i,n)=>'<article class="coach-insight '+i.tone+'"><span class="coach-insight-index">'+String(n+1).padStart(2,"0")+'</span><div><h3>'+esc(i.title)+'</h3><p>'+esc(i.body)+'</p></div></article>').join("")+'</div>'+
 '<div class="panel coach-actions"><h2>อยากให้โค้ชช่วยดูละเอียดกว่านี้?</h2><p>ส่งออกรายงานแล้วนำไปให้ ChatGPT หรือโค้ชวิเคราะห์เพิ่มเติม คุณเลือกเองว่าจะแชร์ข้อมูลใด</p><button class="btn primary" data-action="downloadReport">ส่งออกรายงานสำหรับ Coach</button><p class="help">ไม่มีการส่งข้อมูลสุขภาพให้บริการ AI โดยอัตโนมัติ</p></div>';
}
window.P100Insights={sleepAnalysis,sleepView,coachView,bullets};
})();
