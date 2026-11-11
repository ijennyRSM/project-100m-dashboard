/* PROJECT 100M V2 — Local Apple Health export importer.
Only selected fitness signals are parsed. Original XML/ZIP is never uploaded. */
(function(){
"use strict";
const A=window.P100;if(!A)return;
const number=v=>v===null||v===""||v===undefined?null:Number.isFinite(Number(v))?Number(v):null;
const attrs=tag=>Object.fromEntries([...tag.matchAll(/([\w:.-]+)="([^"]*)"/g)].map(m=>[m[1],m[2]]));
const when=x=>x?Date.parse(x.replace(/^(\d{4}-\d\d-\d\d) (\d\d:\d\d:\d\d) ([+-]\d\d)(\d\d)$/,'$1T$2$3:$4')):NaN;
const toKm=(v,u)=>{const n=number(v);return n===null?null:/mi/i.test(u||"")?n*1.609344:/^(m)$/i.test(u||"")?n/1000:/yd/i.test(u||"")?n*.0009144:n};
function recentDay(days){const d=new Date();d.setDate(d.getDate()-days);return d.getFullYear()+"-"+String(d.getMonth()+1).padStart(2,"0")+"-"+String(d.getDate()).padStart(2,"0")}
async function fileToXml(file){
if(/\.xml$/i.test(file.name)){if(file.size>250*1024*1024)throw Error("XML เกิน 250MB กรุณาเลือกช่วงข้อมูลสั้นลง");return file}
if(!/\.zip$/i.test(file.name))throw Error("รองรับเฉพาะ Apple Health export.xml และ export.zip");
if(!window.JSZip)throw Error("ไม่สามารถเปิด ZIP ได้ ลองใช้แอป Files แตก ZIP แล้วเลือก export.xml");
const archive=await window.JSZip.loadAsync(file);
const entry=Object.values(archive.files).find(x=>!x.dir&&/(^|\/)export\.xml$/i.test(x.name));
if(!entry)throw Error("ZIP นี้ไม่มี export.xml");
if(entry._data?.uncompressedSize>250*1024*1024)throw Error("ข้อมูลใหญ่เกิน 250MB กรุณาแตก ZIP แล้วนำเข้าข้อมูลชุดที่เล็กกว่า");
return entry.async("blob")
}
async function parse(xml,days=90,progress=()=>{}){
days=Math.max(7,Math.min(365,Number(days)||90));
const cutoff=recentDay(days),future=recentDay(-1),sums={},sleep={},workouts=[],heartSamples=[];
let count=0,carry="",bytes=0;
function add(date,k,v){if(!sums[date])sums[date]={};if(!sums[date][k])sums[date][k]=[0,0];sums[date][k][0]+=v;sums[date][k][1]++}
function record(tag){
 const a=attrs(tag),type=a.type||"",date=(a.endDate||a.startDate||"").slice(0,10),v=number(a.value);
 if(!date||date<cutoff||date>future)return;
 if(type==="HKQuantityTypeIdentifierRestingHeartRate"&&v!==null){add(date,"rhr",v);count++}
 else if(type==="HKQuantityTypeIdentifierHeartRateVariabilitySDNN"&&v!==null){add(date,"hrv",a.unit==="s"?v*1000:v);count++}
 else if(type==="HKQuantityTypeIdentifierBodyMass"&&v!==null){add(date,"weight",a.unit==="lb"?v*.453592:v);count++}
 else if(type==="HKCategoryTypeIdentifierSleepAnalysis"&&String(a.value||"").includes("Asleep")){
   const start=when(a.startDate),end=when(a.endDate);
   if(Number.isFinite(start)&&Number.isFinite(end)&&end>start&&end-start<24*3600000){(sleep[date]??=[]).push([start,end]);count++}
 }else if(type==="HKQuantityTypeIdentifierHeartRate"&&v!==null&&heartSamples.length<200000){
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
 let limit=0;
 while(limit++<150000){
   const rec=carry.indexOf("<Record "),work=carry.indexOf("<Workout "),isWork=work>=0&&(rec<0||work<rec),at=isWork?work:rec;
   if(at<0){carry=carry.slice(-30);return}
   if(at>0)carry=carry.slice(at);
   if(isWork){const end=carry.indexOf("</Workout>");
     if(end<0){if(carry.length>12*1024*1024)throw Error("พบ Workout XML ยาวผิดปกติ");return}
     workout(carry.slice(0,end+10));carry=carry.slice(end+10);
   }else{const end=carry.indexOf(">");
     if(end<0)return;
     record(carry.slice(0,end+1));carry=carry.slice(end+1)
   }
 }
 if(limit>=150000)throw Error("ไฟล์มีข้อมูลผิดรูปแบบ")
}
const reader=xml.stream().getReader(),decoder=new TextDecoder();
while(true){const {value,done}=await reader.read();if(done)break;bytes+=value.byteLength;carry+=decoder.decode(value,{stream:true});consume();if(carry.length>12*1024*1024)throw Error("XML record ใหญ่ผิดปกติ");progress(Math.min(99,Math.round(bytes/xml.size*100)));if(bytes%(1024*1024)<65536)await new Promise(resolve=>setTimeout(resolve,0))}
carry+=decoder.decode();consume();
const recovery={};
for(const [date,kv] of Object.entries(sums)){recovery[date]??={date};for(const [k,[sum,n]] of Object.entries(kv))recovery[date][k]=Math.round(sum/n*10)/10}
for(const [date,ranges] of Object.entries(sleep)){
 ranges.sort((a,b)=>a[0]-b[0]);let duration=0,head=null;
 for(const [start,end] of ranges){if(!head)head=[start,end];else if(start<=head[1])head[1]=Math.max(head[1],end);else{duration+=head[1]-head[0];head=[start,end]}}
 if(head)duration+=head[1]-head[0];
 recovery[date]??={date};recovery[date].sleep=Math.round(duration/360000)/10;
}
heartSamples.sort((a,b)=>a[0]-b[0]);
for(const w of workouts){if(w.avgHr===null&&Number.isFinite(w.start)&&Number.isFinite(w.end)){
 let lo=0,hi=heartSamples.length;
 while(lo<hi){const mid=(lo+hi)>>1;if(heartSamples[mid][0]<w.start)lo=mid+1;else hi=mid}
 let total=0,count=0,max=0;
 while(lo<heartSamples.length&&heartSamples[lo][0]<=w.end){const h=heartSamples[lo++][1];total+=h;count++;max=Math.max(max,h)}
 if(count){w.avgHr=Math.round(total/count);w.maxHr=max}
 }
 delete w.start;delete w.end;
}
progress(100);
return {recovery,workouts,found:count}
}
async function importAppleHealth(file,days,progress){const p=A.profile(),xml=await fileToXml(file),r=await parse(xml,days,progress);if(!r.found)throw Error("ไม่พบข้อมูล Apple Health ประเภทที่รองรับ");
p.appleWorkouts=p.appleWorkouts||[];
const known=new Set(p.appleWorkouts.map(x=>x.id));const newer=r.workouts.filter(x=>!known.has(x.id));
p.appleWorkouts.push(...newer);p.appleWorkouts.sort((a,b)=>b.date.localeCompare(a.date));
p.recovery=p.recovery||[];
let count=0;
for(const [date,incoming] of Object.entries(r.recovery)){
 let existing=p.recovery.find(x=>x.date===date);
 if(!existing){existing={date,updatedAt:A.iso(),source:"apple-health"};p.recovery.push(existing)}
 for(const key of ["sleep","rhr","hrv","weight"]){if(incoming[key]!==undefined&&(existing[key]===undefined||existing[key]===null||existing.source==="apple-health"))existing[key]=incoming[key]}
 if(existing.source==="apple-health")existing.updatedAt=A.iso();
 count++;
}
p.recovery.sort((a,b)=>b.date.localeCompare(a.date));
A.store();
return {workouts:newer.length,recoveryDays:count,totalFound:r.found};
}
A.importAppleHealth=importAppleHealth;
})();
