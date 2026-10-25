// Editable vector masters and raster exports; no provider calls.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {createRequire} from 'node:module';
const req=createRequire('C:/Users/slavd/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/runtime.cjs');
const sharp=req('sharp');
const root=process.cwd(),out=path.join(root,'assets/production/needle-quay/graphics');await fs.mkdir(out,{recursive:true});
const data=JSON.parse(await fs.readFile(path.join(root,'data/needle-quay-environment.v1.json'),'utf8'));
const c={teal:'#2F5C58',cream:'#E8D8B7',coral:'#CA7453',amber:'#F3B65F',ink:'#162322',wood:'#79513B'};
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
const text=(s,x,y,size=30,fill=c.cream,extra='')=>`<text x="${x}" y="${y}" text-anchor="middle" font-family="Georgia,serif" font-size="${size}" font-weight="bold" fill="${fill}" ${extra}>${esc(s)}</text>`;
const rect=(x,y,w,h,fill,r=12)=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}"/>`;
function lines(s,n=21){const a=[];let t='';for(const w of s.split(' ')){if((t+' '+w).trim().length>n&&t){a.push(t);t=w;}else t=(t+' '+w).trim();}if(t)a.push(t);return a;}
function wave(x,y,w,h,color=c.coral){let d=`M ${x} ${y}`;for(let i=0;i<=32;i++)d+=` L ${x+i*w/32} ${y+Math.sin(i*Math.PI/4)*h*(.3+.7*Math.sin(i*Math.PI/32))}`;return `<path d="${d}" fill="none" stroke="${color}" stroke-width="8" stroke-linecap="round"/>`;}
function badge(i,x,y,r=35){
 if(i===2)return `<circle cx="${x}" cy="${y}" r="${r}" fill="${c.ink}" stroke="${c.cream}" stroke-width="3"/><circle cx="${x}" cy="${y}" r="${r*.35}" fill="${c.coral}"/>`;
 if(i===3)return `<path d="M ${x-r*.7} ${y-r*.6} L ${x+r*.7} ${y+r*.6} M ${x-r*.7} ${y+r*.6} L ${x+r*.7} ${y-r*.6}" stroke="${c.amber}" stroke-width="13" stroke-linecap="round"/>`;
 if(i===5)return `<path d="M ${x} ${y+r} L ${x} ${y-r} M ${x-r*.5} ${y} Q ${x-r*1.1} ${y-r*.5} ${x-r*.5} ${y-r} M ${x+r*.5} ${y} Q ${x+r*1.1} ${y-r*.5} ${x+r*.5} ${y-r}" fill="none" stroke="${c.amber}" stroke-width="7"/>`;
 if(i===1)return rect(x-r*.6,y-r*.8,r*1.2,r*1.6,c.amber,7)+`<path d="M ${x-r*.8} ${y-r*.8} Q ${x} ${y-r*1.5} ${x+r*.8} ${y-r*.8}" fill="none" stroke="${c.cream}" stroke-width="7"/>`;
 if(i===4)return `<path d="M ${x-r} ${y-r*.4} L ${x} ${y-r} L ${x+r} ${y-r*.4} V ${y+r} H ${x-r} Z" fill="none" stroke="${c.cream}" stroke-width="6"/>`;
 return wave(x-r,y,r*2,r*.5,c.amber);
}
const manifest=[];
for(const g of data.graphics){
 if(g.kind==='transparent_graffiti')continue;
 let w=512,h=g.kind==='poster'?768:g.kind==='service_decal'?256:256,body='';
 const num=Number(g.id.split('-').at(-1));
 if(g.kind==='sign'){
  body=rect(8,8,496,240,c.ink,25)+rect(17,17,478,222,num<=5?c.teal:c.wood,19)+`<rect x="28" y="28" width="456" height="200" rx="13" fill="none" stroke="${c.cream}" stroke-width="4"/>`;
  body+=badge(num,256,72,28);const words=lines(g.subject.toUpperCase(),23);for(let i=0;i<words.length;i++)body+=text(words[i],256,136+i*36,words.length>2?25:29);
  body+=text('NEEDLE QUAY',256,219,12,c.amber,'letter-spacing="5"');
 }else if(g.kind==='wayfinding'){
  body=rect(5,14,502,228,c.teal,18)+`<path d="M 45 128 L 105 66 V 105 H 145 V 151 H 105 V 190 Z" fill="${c.cream}"/>`;
  const words=lines(g.subject.toUpperCase(),15);words.forEach((s,i)=>body+=text(s,322,112+i*39,30));body+=text('NEEDLE QUAY',322,205,12,c.amber);
 }else if(g.kind==='poster'){
  const palettes=[[c.cream,c.ink,c.coral],[c.teal,c.cream,c.amber],[c.coral,c.cream,c.ink]];const [bg,fg,ac]=palettes[(num-1)%3];
  body=rect(0,0,w,h,bg,0)+`<rect x="22" y="22" width="468" height="724" fill="none" stroke="${fg}" stroke-width="3"/>`+text('NEEDLE QUAY / COMMUNITY SERIES',256,62,13,fg,'letter-spacing="2"');
  const title=g.subject.replace(' old concert','').toUpperCase();const ls=lines(title,17);ls.forEach((s,i)=>body+=text(s,256,134+i*54,45,fg));
  const y=ls.length>2?365:330;
  if(num%3===1){body+=`<circle cx="256" cy="${y+95}" r="128" fill="${ac}"/><circle cx="256" cy="${y+95}" r="90" fill="none" stroke="${fg}" stroke-width="4"/><circle cx="256" cy="${y+95}" r="36" fill="${bg}"/>`;}
  else if(num%3===2){for(let k=0;k<5;k++)body+=wave(64,y+k*42,384,27,k%2?fg:ac);}
  else {for(let k=0;k<8;k++)body+=rect(62+k*49,y+180-(k%4+1)*40,30,(k%4+1)*40,ac,6);body+=`<circle cx="256" cy="${y-5}" r="55" fill="${fg}"/>`;}
  body+=text('MUSIC · MAKING · TOGETHER',256,658,17,fg)+text('ORIGINAL QUAY SESSIONS',256,696,13,fg,'letter-spacing="3"');
 }else{
  w=256;body=rect(6,6,244,244,c.ink,14)+`<rect x="17" y="17" width="222" height="222" rx="8" fill="none" stroke="${c.cream}" stroke-width="3"/>`;
  const pack=g.id.split('-')[1];
  if(/warning|boundary|parking/i.test(g.subject)){body+=`<path d="M 128 37 L 202 152 H 54 Z" fill="${c.amber}"/>`+text('!',128,132,65,c.ink);}
  else if(/arrow|route|loading/i.test(g.subject)){body+=`<path d="M 48 98 H 146 V 65 L 210 127 L 146 189 V 156 H 48 Z" fill="${c.cream}"/>`;}
  else if(/quest|symbol/i.test(g.subject)){body+=badge(num,128,108,52);}
  else {body+=text(String(num).padStart(2,'0'),128,129,68,c.amber);}
  const isGameBacking=/quest/i.test(g.subject);const labels=isGameBacking?['']:lines(g.subject.toUpperCase(),19);labels.slice(0,2).forEach((s,i)=>body+=text(s,128,187+i*21,15));
  body+=text(pack,128,232,10,c.cream,'letter-spacing="3"');
 }
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;
 const svgp=path.join(out,g.id+'.svg'),pngp=path.join(out,g.id+'.png');await fs.writeFile(svgp,svg);await sharp(Buffer.from(svg)).png().toFile(pngp);
 const rec={id:g.id,kind:g.kind,subject:g.subject,source:path.relative(root,svgp).replaceAll('\\','/'),png:path.relative(root,pngp).replaceAll('\\','/'),width:w,height:h,sha256:crypto.createHash('sha256').update(await fs.readFile(pngp)).digest('hex'),stage:'AUTHORED_VECTOR_ART_CANDIDATE',art_approved:false};
 if(g.kind==='poster'){
  const faded=svg.replaceAll(c.coral,'#bd9679').replaceAll(c.teal,'#72867a').replaceAll(c.cream,'#d0c3a8').replaceAll(c.ink,'#6b7060');const f=path.join(out,g.id+'-faded.svg');await fs.writeFile(f,faded);await sharp(Buffer.from(faded)).png().toFile(path.join(out,g.id+'-faded.png'));rec.faded_source=path.relative(root,f).replaceAll('\\','/');
 }
 manifest.push(rec);
}
await fs.writeFile(path.join(out,'vector-manifest.json'),JSON.stringify({date:'2026-10-25',authoring:'Deterministic editable SVG with sharp raster export',canonical_graphic_base_designs:manifest.length,graphics:manifest,gameplay_text:'No gameplay instructions rasterized; quest marker is symbol-only backing',new_art_approval_required:true},null,2)+'\n');
console.log('Authored',manifest.length,'vector masters with PNG exports and eight faded poster variants.');
