/* PROJECT 100M v1.0 bootstrap. App source is losslessly gzip-packed into
   four same-origin static chunks for deployment. Health data stays in this
   browser's localStorage; this bootstrap fetches code only. */
(async function(){
  const files=[1,2,3,4].map(i=>'payload/chunk-'+i+'.txt');
  const pieces=await Promise.all(files.map(async f=>{
    const r=await fetch(f,{cache:'no-cache'});
    if(!r.ok)throw new Error('Failed to load '+f+' ('+r.status+')');
    return (await r.text()).trim();
  }));
  const base64=pieces.join('');
  if(base64.length!==12604)throw new Error('Application bundle incomplete');
  if(!('DecompressionStream' in window))throw new Error('Please update Safari/iOS to use this app');
  const bytes=Uint8Array.from(atob(base64),c=>c.charCodeAt(0));
  const inflated=new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
  const source=await new Response(inflated).text();
  if(!source.startsWith("'use strict';"))throw new Error('Invalid application bundle');
  const objectURL=URL.createObjectURL(new Blob([source],{type:'text/javascript'}));
  const script=document.createElement('script');
  script.src=objectURL;
  script.addEventListener('load',()=>URL.revokeObjectURL(objectURL),{once:true});
  script.addEventListener('error',()=>URL.revokeObjectURL(objectURL),{once:true});
  document.body.appendChild(script);
})().catch(err=>{
  console.error('Project 100M startup error',err);
  const message=document.createElement('p');
  message.style='position:fixed;z-index:100;background:#40272e;color:#fff;left:12px;right:12px;top:12px;padding:16px;border-radius:12px;font:14px sans-serif';
  message.textContent='PROJECT 100M: ไม่สามารถเปิด Dashboard ได้ ('+err.message+') โปรดลองรีเฟรชหน้าเว็บ';
  document.body.prepend(message);
});