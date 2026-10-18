const fs=require('fs'),path=require('path'),R=require('./raster.cjs'),prepare=require('./prepare.cjs'),P=require('./pose.cjs'),special=require('./special.cjs'),actions=require('./actions.cjs'),png=require('./png.cjs');
const sharp=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/sharp');
const data=require('./base-v11.json'),out=process.argv[2];fs.mkdirSync(out,{recursive:true});
const frame=(a,k,i,n)=>P.general(a,k,i,n)||special(a,k,i,n);
function sheet(a,action,n){const s=a.s,w=s*n,b=Buffer.alloc(w*s*4);for(let f=0;f<n;f++){const p=R.rgba(frame(a,action,f,n).pixels);for(let y=0;y<s;y++)p.copy(b,(y*w+f*s)*4,y*s*4,(y+1)*s*4);}return png(w,s,b);}
async function main(){
 for(const c of data.characters){const a=prepare(c),selected=['idle','walk','hit','die',actions(c.id)[9].name],composites=[];
  for(let row=0;row<selected.length;row++){const name=selected[row],n=actions(c.id).find(x=>x.name===name).n;
   const b=await sharp(sheet(a,name,n)).resize(c.width*n*2,c.width*2,{kernel:'nearest'}).png().toBuffer();composites.push({input:b,left:10,top:30+row*(c.width*2+30)});
   const label=Buffer.from(`<svg width="350" height="25"><text x="0" y="18" font-family="sans-serif" font-size="16" fill="white">${c.id} · ${name}</text></svg>`);composites.push({input:label,left:10,top:5+row*(c.width*2+30)});
  }
  await sharp({create:{width:c.width*16+20,height:5*(c.width*2+30),channels:4,background:'#737780'}}).composite(composites).png().toFile(path.join(out,c.id+'-check.png'));
 }
}
main();
