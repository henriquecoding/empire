const fs=require('fs'),path=require('path'),crypto=require('crypto');
const encodePng=require('./png.cjs');
const writeAse=require('./ase.cjs');
const root=path.resolve(__dirname,'..'),data=JSON.parse(fs.readFileSync(path.join(__dirname,'native-pixels.json')));
const hex=s=>[parseInt(s.slice(1,3),16),parseInt(s.slice(3,5),16),parseInt(s.slice(5,7),16),255];
const frames=[];
for(const dir of ['png','aseprite','palette'])fs.mkdirSync(path.join(root,dir),{recursive:true});
for(const c of data.characters){
 if(c.rows.length!==c.height||c.rows.some(r=>r.length!==c.width))throw Error('Grade inválida: '+c.id);
 const base=Buffer.alloc(c.width*c.height*4),finish=Buffer.alloc(base.length);
 for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++){
  const s=c.rows[y][x];if(s==='.')continue;if(!c.palette[s])throw Error('Cor desconhecida: '+s);Buffer.from(hex(c.palette[s])).copy(base,(y*c.width+x)*4);
 }
 for(const p of c.nativeEdits){
  if(!Number.isInteger(p.x)||!Number.isInteger(p.y)||p.x<0||p.x>=c.width||p.y<0||p.y>=c.height)throw Error('Edição fora da grade');
  const n=(p.y*c.width+p.x)*4;if(p.color===null)base.fill(0,n,n+4);else Buffer.from(hex(p.color)).copy(finish,n);
 }
 const rgba=Buffer.from(base);for(let n=0;n<rgba.length;n+=4)if(finish[n+3])finish.copy(rgba,n,n,n+4);
 const stem=`${c.id}-${c.width}x${c.height}`;
 const png=encodePng(c.width,c.height,rgba);
 fs.writeFileSync(path.join(root,'png',stem+'.png'),png);
 const ase=writeAse(c.width,c.height,[{name:'corpo',rgba:base},{name:'acabamento-nativo',rgba:finish}],c.pivot);
 fs.writeFileSync(path.join(root,'aseprite',stem+'.aseprite'),ase);
 const colours=[...new Set([...Object.values(c.palette),...c.nativeEdits.filter(p=>p.color).map(p=>p.color)])];
 fs.writeFileSync(path.join(root,'palette',c.id+'.gpl'),'GIMP Palette\nName: Empire '+c.id+' V8\nColumns: 8\n#\n'+colours.map((h,i)=>hex(h).slice(0,3).join(' ')+' cor-'+i).join('\n')+'\n');
 const used=new Set();let l=c.width,t=c.height,r=-1,b=-1;
 for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++){const n=(y*c.width+x)*4;if(!rgba[n+3])continue;used.add(rgba.slice(n,n+3).toString('hex'));l=Math.min(l,x);t=Math.min(t,y);r=Math.max(r,x);b=Math.max(b,y);}
 frames.push({id:c.id,file:'png/'+stem+'.png',source:'aseprite/'+stem+'.aseprite',width:c.width,height:c.height,frames:1,pivot:c.pivot,visibleBox:[l,t,r+1,b+1],colours:used.size,alpha:'binary',sha256:crypto.createHash('sha256').update(png).digest('hex'),nativeEdits:c.nativeEdits.length});
}
fs.writeFileSync(path.join(root,'manifest.json'),JSON.stringify({version:8,scope:'Uma pose estática por personagem; sem ciclos de animação ou integração no jogo.',source:'source/native-pixels.json',construction:'Adaptação dos conceitos compactos gerados, paleta por agrupamento e acabamento no raster final. Não desenhado do zero em 64/80 pelo modelo.',nativeFromScratch:false,frames},null,2)+'\n');
console.log(JSON.stringify(frames.map(x=>({id:x.id,size:[x.width,x.height],colours:x.colours,edits:x.nativeEdits}))));
