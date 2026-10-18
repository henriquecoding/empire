const fs=require('fs'),path=require('path'),crypto=require('crypto');
const png=require('./png.cjs'),ase=require('./ase.cjs');
const root=path.resolve(__dirname,'..'),data=JSON.parse(fs.readFileSync(path.join(__dirname,'native-pixels.json')));
const rgba=h=>[parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16),255];
const atlas=Buffer.alloc(320*160*4),frames=[],rects={};
for(const name of ['png','aseprite','palette'])fs.mkdirSync(path.join(root,name),{recursive:true});
for(const [index,c]of data.characters.entries()){
 if(c.rows.length!==c.height||c.rows.some(r=>r.length!==c.width))throw Error('Grade inválida: '+c.id);
 const base=Buffer.alloc(c.width*c.height*4),finish=Buffer.alloc(base.length);
 for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++){
  const k=c.rows[y][x];if(k==='.')continue;if(!c.palette[k])throw Error('Cor desconhecida');Buffer.from(rgba(c.palette[k])).copy(base,(y*c.width+x)*4);
 }
 for(const p of c.nativeEdits){
  if(!Number.isInteger(p.x)||!Number.isInteger(p.y)||p.x<0||p.y<0||p.x>=c.width||p.y>=c.height)throw Error('Pixel fora do quadro');
  const n=(p.y*c.width+p.x)*4;if(p.color===null)base.fill(0,n,n+4);else Buffer.from(rgba(p.color)).copy(finish,n);
 }
 const flat=Buffer.from(base);for(let n=0;n<flat.length;n+=4)if(finish[n+3])finish.copy(flat,n,n,n+4);
 const stem=c.id+'-'+c.width+'x'+c.height,bytes=png(c.width,c.height,flat);
 fs.writeFileSync(path.join(root,'png',stem+'.png'),bytes);
 fs.writeFileSync(path.join(root,'aseprite',stem+'.aseprite'),ase(c.width,c.height,[{name:'arte-base',rgba:base},{name:'acabamento64-80',rgba:finish}],c.pivot));
 const colors=[...new Set([...Object.values(c.palette),...c.nativeEdits.filter(p=>p.color).map(p=>p.color)])];
 fs.writeFileSync(path.join(root,'palette',c.id+'.gpl'),'GIMP Palette\nName: Empire '+c.id+' V11\nColumns: 8\n#\n'+colors.map((h,i)=>rgba(h).slice(0,3).join(' ')+' color-'+i).join('\n')+'\n');
 const used=new Set();let x0=c.width,y0=c.height,x1=0,y1=0;
 for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++){const n=(y*c.width+x)*4;if(!flat[n+3])continue;used.add(flat.subarray(n,n+3).toString('hex'));x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x+1);y1=Math.max(y1,y+1);}
 const ax=(index%4)*80,ay=Math.floor(index/4)*80;
 for(let y=0;y<c.height;y++)flat.copy(atlas,((ay+y)*320+ax)*4,y*c.width*4,(y+1)*c.width*4);
 rects[c.id]={frame:{x:ax,y:ay,w:c.width,h:c.height},pivot:{x:c.pivot[0],y:c.pivot[1]},file:'png/'+stem+'.png'};
 frames.push({id:c.id,file:'png/'+stem+'.png',source:'aseprite/'+stem+'.aseprite',width:c.width,height:c.height,frames:1,pivot:c.pivot,visibleBox:[x0,y0,x1,y1],colours:used.size,alpha:'binary',nativeEdits:c.nativeEdits.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
}
fs.writeFileSync(path.join(root,'EMPIRE-ATLAS-1X-V11.png'),png(320,160,atlas));
fs.writeFileSync(path.join(root,'atlas.json'),JSON.stringify({image:'EMPIRE-ATLAS-1X-V11.png',size:{w:320,h:160},frames:rects},null,2)+'\n');
fs.writeFileSync(path.join(root,'manifest.json'),JSON.stringify({version:11,scope:'Oito personagens completos; uma pose estática cada. Sem animações ou integração no jogo.',construction:'Adaptação dos estudos gerados para as dimensões reais, paleta discreta, transparência binária e acabamento localizado na grade final.',nativeFromScratch:false,authorApproved:false,source:'source/native-pixels.json',frames},null,2)+'\n');
console.log(JSON.stringify(frames.map(c=>({id:c.id,size:[c.width,c.height],colours:c.colours}))));
