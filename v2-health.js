/* PROJECT 100M V4.1 — streaming Apple Health importer.
Reads large export.zip / export.xml incrementally without expanding ZIP into a giant Blob.
Only selected wellness metrics are retained; the original file never leaves the device.
fflate 0.8.2 is used only for streaming ZIP decompression. */
(function(){
"use strict";
const A=window.P100;if(!A)return;
const number=v=>v===null||v===""||v===undefined?null:Number.isFinite(Number(v))?Number(v):null;
const attrs=tag=>Object.fromEntries([...tag.matchAll(/([\w:.-]+)="([^"]*)"/g)].map(m=>[m[1],m[2]]));
const when=x=>x?Date.parse(x.replace(/^(\d{4}-\d\d-\d\d) (\d\d:\d\d:\d\d) ([+-]\d\d)(\d\d)$/,'$1T$2$3:$4')):NaN;
const toKm=(v,u)=>{const n=number(v);return n===null?null:/mi/i.test(u||"")?n*1.609344:/^(m)$/i.test(u||"")?n/1000:/yd/i.test(u||"")?n*.0009144:n};
function dayDelta(days){const d=new Date();d.setDate(d.getDate()-days);return d.getFullYear()+"-"+String(d.getMonth()+1).padStart(2,"0")+"-"+String(d.getDate()).padStart(2,"0")}
const pause=()=>new Promise(resolve=>setTimeout(resolve,0));
const BYTES_PER_YIELD=1024*1024;
function createParser(days,progress){
 days=Math.max(7,Math.min(365,Number(days)||90));
 const cutoff=dayDelta(days),future=dayDelta(-1),sums=Object.create(null),sleep=Object.create(null),workouts=[],heartSamples=[];
 let count=0,carry="",bytes=0,decoder=new TextDecoder(),ended=false;
 function add(date,k,v){if(!sums[date])sums[date]=Object.create(null);if(!sums[date][k])sums[date][k]=[0,0];sums[date][k][0]+=v;sums[date][k][1]++}
 function record(tag){
   // Nearly all Apple Health XML tags (often millions) are irrelevant. Skip before attribute parsing.
   if(!tag.includes("HKQuantityTypeIdentifierRestingHeartRate")&&!tag.includes("HKQuantityTypeIdentifierHeartRateVariabilitySDNN")&&!tag.includes("HKQuantityTypeIdentifierBodyMass")&&!tag.includes("HKCategoryTypeIdentifierSleepAnalysis")&&!tag.includes("HKQuantityTypeIdentifierHeartRate"))return;
   const a=attrs(tag),type=a.type||"",date=(a.endDate||a.startDate||"").slice(0,10),v=number(a.value);
   if(!date||date<cutoff||date>future)return;
   if(type==="HKQuantityTypeIdentifierRestingHeartRate"&&v!==null){add(date,"rhr",v);count++}
   else if(type==="HKQuantityTypeIdentifierHeartRateVariabilitySDNN"&&v!==null){add(date,"hrv",a.unit==="s"?v*1000:v);count++}
   else if(type==="HKQuantityTypeIdentifierBodyMass"&&v!==null){add(date,"weight",a.unit==="lb"?v*.453592:v);count++}
   else if(type==="HKCategoryTypeIdentifierSleepAnalysis"){
     const start=when(a.startDate),end=when(a.endDate),value=String(a.value||"");
     if(Number.isFinite(start)&&Number.isFinite(end)&&end>start&&end-start<24*3600000){
       const stages=(sleep[date]??={total:[],core:[],deep:[],rem:[],awake:[],inBed:[],unspecified:[]});
       const stage=value.includes("AsleepCore")?"core":value.includes("AsleepDeep")?"deep":value.includes("AsleepREM")?"rem":value.includes("Asleep")?"unspecified":value.includes("Awake")?"awake":value.includes("InBed")?"inBed":null;
       if(stage){stages[stage].push([start,end]);if(["core","deep","rem","unspecified"].includes(stage))stages.total.push([start,end]);count++}
     }
   }else if(type==="HKQuantityTypeIdentifierHeartRate"&&v!==null&&heartSamples.length<100000){
      const ts=when(a.startDate);if(Number.isFinite(ts)&&v>35&&v<240){heartSamples.push([ts,v]);count++}
   }
 }
 function workout(tag){
   const a=attrs(tag.slice(0,tag.indexOf(">")+1)),activity=a.workoutActivityType||"";
   if(!/Running|StrengthTraining|Walking/.test(activity))return;
   const date=String(a.startDate||"").slice(0,10);
   if(!date||date<cutoff||date>future)return;
   let avgHr=null,maxHr=null;
   for(const m of tag.matchAll(/<WorkoutStatistics\b[^>]*>/g)){
     const st=attrs(m[0]);if((st.type||"").includes("HeartRate")){avgHr=number(st.average);maxHr=number(st.maximum)}
   }
   let duration=number(a.duration);
   if(duration!==null){if(["s","sec"].includes(a.durationUnit))duration/=60;else if(["h","hr"].includes(a.durationUnit))duration*=60}
   else duration=(when(a.endDate)-when(a.startDate))/60000;
   const key=a.uuid||(String(a.startDate)+"-"+activity+"-"+String(a.duration));
   workouts.push({id:"apple-"+key,date,kind:activity.includes("Running")?"Running":activity.includes("Walking")?"Walking":"Strength",duration:Number.isFinite(duration)?Math.round(duration*10)/10:null,distanceKm:toKm(a.totalDistance,a.totalDistanceUnit||"km"),avgHr,maxHr,source:"apple-health",start:when(a.startDate),end:when(a.endDate)});count++
 }
 function consume(){
   let n=0;
   while(n++<250000){
     const rec=carry.indexOf("<Record "),work=carry.indexOf("<Workout "),isWork=work>=0&&(rec<0||work<rec),at=isWork?work:rec;
     if(at<0){carry=carry.slice(-20);return}
     if(at>0)carry=carry.slice(at);
     if(isWork){const end=carry.indexOf("</Workout>");
       if(end<0){if(carry.length>16*1024*1024)throw Error("พบ Workout XML ที่ยาวผิดปกติ");return}
       workout(carry.slice(0,end+10));carry=carry.slice(end+10);
     }else{const end=carry.indexOf(">");
       if(end<0){if(carry.length>1024*1024)throw Error("พบ Record XML ที่ยาวผิดปกติ");return}
       record(carry.slice(0,end+1));carry=carry.slice(end+1)
     }
   }
   throw Error("รูปแบบ XML ผิดปกติ โปรดลองนำเข้าไฟล์อีกครั้ง");
 }
 function feed(chunk){
   if(ended)throw Error("ข้อมูล Apple Health ถูกส่งมาซ้ำหลังไฟล์จบ");
   if(!chunk||!chunk.length)return;
   bytes+=chunk.length;
   // A per-import stream safeguard, NOT the old 250MB expanded-file cap.
   if(bytes>8*1024*1024*1024)throw Error("ข้อมูล XML มีขนาดเกิน 8GB ที่รองรับสำหรับการนำเข้าครั้งเดียว");
   carry+=decoder.decode(chunk,{stream:true});consume();
 }
 function unionIntervals(ranges){
   if(!ranges||!ranges.length)return {duration:0,start:null,end:null};
   const sorted=ranges.slice().sort((a,b)=>a[0]-b[0]);
   let start=sorted[0][0],end=sorted[0][1],ms=0,lastEnd=end;
   for(let i=1;i<sorted.length;i++){const [a,b]=sorted[i];lastEnd=Math.max(lastEnd,b);if(a<=end)end=Math.max(end,b);else{ms+=end-start;start=a;end=b}}
   ms+=end-start;
   return {duration:ms,start:sorted[0][0],end:lastEnd}
 }
 function finish(){
   if(ended)throw Error("ประมวลผลข้อมูลนี้แล้ว");ended=true;
   carry+=decoder.decode();consume();
   const recovery=Object.create(null);
   for(const [date,kv] of Object.entries(sums)){recovery[date]={date};for(const [k,[sum,n]] of Object.entries(kv))recovery[date][k]=Math.round(sum/n*10)/10}
   for(const [date,stages] of Object.entries(sleep)){
     const all=unionIntervals(stages.total);if(!all.duration)continue;
     const h=ms=>Math.round(ms/360000)/10;
     const deep=h(unionIntervals(stages.deep).duration),rem=h(unionIntervals(stages.rem).duration),core=h(unionIntervals(stages.core).duration),
       unspecified=h(unionIntervals(stages.unspecified).duration),awake=h(unionIntervals(stages.awake).duration),inBed=h(unionIntervals(stages.inBed).duration);
     recovery[date]??={date};
     const row=recovery[date];row.sleep=h(all.duration);
     row.sleepStages={deep,rem,core,unspecified};
     row.sleepStageCoverage=Math.round(Math.min(100,(deep+rem+core)/Math.max(row.sleep,.01)*100));
     row.sleepAwake=awake;row.sleepInBed=inBed||null;
     row.sleepEfficiency=inBed?Math.round(Math.min(100,all.duration/unionIntervals(stages.inBed).duration*100)):null;
     row.sleepStart=Number.isFinite(all.start)?new Date(all.start).toISOString():null;
     row.sleepEnd=Number.isFinite(all.end)?new Date(all.end).toISOString():null;
   }
   heartSamples.sort((a,b)=>a[0]-b[0]);
   for(const w of workouts){
     if(w.avgHr===null&&Number.isFinite(w.start)&&Number.isFinite(w.end)){
       let lo=0,hi=heartSamples.length;
       while(lo<hi){const mid=(lo+hi)>>1;if(heartSamples[mid][0]<w.start)lo=mid+1;else hi=mid}
       let total=0,n=0,max=0;
       while(lo<heartSamples.length&&heartSamples[lo][0]<=w.end){const h=heartSamples[lo++][1];total+=h;n++;max=Math.max(max,h)}
       if(n){w.avgHr=Math.round(total/n);w.maxHr=max}
     }
     delete w.start;delete w.end
   }
   return {recovery,workouts,found:count,processedBytes:bytes}
 }
 return {feed,finish}
}
async function parseXml(file,days,progress){
 if(!file.stream)throw Error("เบราว์เซอร์นี้ไม่รองรับการอ่านไฟล์แบบสตรีม กรุณาอัปเดต iOS");
 const proc=createParser(days),reader=file.stream().getReader();let read=0,untilYield=0;
 try{
   while(true){const part=await reader.read();if(part.done)break;proc.feed(part.value);read+=part.value.length;untilYield+=part.value.length;
     progress(Math.min(99,Math.floor(read/Math.max(file.size,1)*100)));
     if(untilYield>=BYTES_PER_YIELD){untilYield=0;await pause()}
   }
   progress(100);return proc.finish()
 }finally{reader.releaseLock?.()}
}
async function parseZip(file,days,progress){
 const fflate=window.fflate;
 if(!fflate?.Unzip||!fflate?.UnzipInflate)throw Error("โหลดตัวอ่าน ZIP ไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วรีเฟรชหน้าเว็บ");
 if(!file.stream)throw Error("เบราว์เซอร์นี้ไม่รองรับการอ่าน ZIP แบบสตรีม กรุณาอัปเดต iOS");
 const proc=createParser(days),reader=file.stream().getReader();
 let found=false,finished=false,failure=null,read=0,untilYield=0,entries=0;
 const unzip=new fflate.Unzip(entry=>{
   entries++;const path=String(entry.name||"");
   // Apple Health may package export.xml in apple_health_export/export.xml.
   if(!/(^|\/)export\.xml$/i.test(path)||found)return;
   found=true;
   entry.ondata=(err,chunk,final)=>{
     if(failure)return;
     if(err){failure=err;return}
     try{if(chunk?.length)proc.feed(chunk);if(final)finished=true}catch(e){failure=e}
   };
   try{entry.start()}catch(e){failure=e}
 });
 unzip.register(fflate.UnzipInflate);
 try{
   while(true){
     const part=await reader.read();
     if(part.done){try{unzip.push(new Uint8Array(0),true)}catch(e){if(!failure)failure=e}break}
     try{unzip.push(part.value,false)}catch(e){failure=e}
     if(failure)throw failure;
     read+=part.value.length;untilYield+=part.value.length;
     progress(Math.min(99,Math.floor(read/Math.max(file.size,1)*100)));
     if(untilYield>=BYTES_PER_YIELD){untilYield=0;await pause()}
   }
   if(failure)throw failure;
   if(!found)throw Error("ไม่พบ export.xml ในไฟล์ ZIP กรุณาเลือกไฟล์ที่ส่งออกโดย Apple Health");
   if(!finished)throw Error("อ่าน export.xml จาก ZIP ไม่ครบ อาจเป็นไฟล์ ZIP ไม่สมบูรณ์หรือใช้วิธีบีบอัดที่ไม่รองรับ");
   progress(100);return proc.finish()
 }finally{reader.releaseLock?.()}
}
async function importAppleHealth(file,days,progress=()=>{}){
 if(!file||!file.name)throw Error("กรุณาเลือกไฟล์ Apple Health");
 const extension=file.name.toLowerCase();
 const res=extension.endsWith(".zip")?await parseZip(file,days,progress):
   extension.endsWith(".xml")?await parseXml(file,days,progress):
   (()=>{throw Error("รองรับเฉพาะ export.zip หรือ export.xml จาก Apple Health")})();
 if(!res.found)throw Error("ไม่พบข้อมูลสุขภาพที่รองรับในช่วงวันที่เลือก กรุณาลองเลือกช่วง 365 วัน");
 // Read active profile only AFTER asynchronous processing, so switching profiles mid-import
 // never silently writes one user's health export into another person's profile.
 const p=A.profile();p.appleWorkouts=p.appleWorkouts||[];
 const known=new Set(p.appleWorkouts.map(x=>x.id)),newer=res.workouts.filter(x=>!known.has(x.id));
 p.appleWorkouts.push(...newer);p.appleWorkouts.sort((a,b)=>b.date.localeCompare(a.date));
 p.recovery=p.recovery||[];
 let count=0;
 for(const [date,incoming] of Object.entries(res.recovery)){
   let existing=p.recovery.find(x=>x.date===date);
   if(!existing){existing={date,updatedAt:A.iso(),source:"apple-health"};p.recovery.push(existing)}
   for(const key of ["sleep","rhr","hrv","weight","sleepStages","sleepStageCoverage","sleepAwake","sleepInBed","sleepEfficiency","sleepStart","sleepEnd"]){
     if(incoming[key]!==undefined&&(existing[key]===undefined||existing[key]===null||existing.source==="apple-health"))existing[key]=incoming[key]
   }
   if(existing.source==="apple-health")existing.updatedAt=A.iso();
   count++
 }
 p.recovery.sort((a,b)=>b.date.localeCompare(a.date));A.store();
 return {workouts:newer.length,recoveryDays:count,totalFound:res.found,processedMB:Math.round(res.processedBytes/1048576)}
}
A.importAppleHealth=importAppleHealth;
A.createAppleHealthParser=createParser; // pure parser exposed for lightweight self-tests, not part of the UI
})();
