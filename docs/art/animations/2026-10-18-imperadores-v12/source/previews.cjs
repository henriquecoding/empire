const fs=require('fs'),path=require('path'),cp=require('child_process'),sharp=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/sharp'),R=require('./raster.cjs'),prepare=require('./prepare.cjs'),{frame}=require('./export.cjs'),actions=require('./actions.cjs'),flowers=require('./flowers.cjs');
const data=require('./base-v11.json'),output=path.resolve(process.argv[2]),temp=path.resolve(process.argv[3]),dir=path.join(output,'previas');fs.mkdirSync(dir,{recursive:true});fs.mkdirSync(temp,{recursive:true});
const names={rei:'Rei',escudeiro:'Escudeiro',nia:'Nia',bardo:'Bardo',arqueiro:'Arqueiro',intendente:'Intendente',sombra:'Sombra',dancarina:'Dançarina'},own={rei:'attack',escudeiro:'block_hit',nia:'attack',bardo:'play',arqueiro:'shoot',intendente:'deliver',sombra:'heal',dancarina:'dance'};
const models=data.characters.map(c=>({c,a:prepare(c),defs:actions(c.id),cache:{}}));
function get(m,k,i){const n=m.defs.find(d=>d.name===k).n,key=k+':'+i%n;if(!m.cache[key])m.cache[key]=frame(m.a,k,i%n,n);return m.cache[key];}
function special(m,i){if(m.c.id==='sombra')return i<6?['sit',i]:i<36?['heal',(i-6)%8]:i<42?['stand',i-36]:['idle',i-42];if(m.c.id==='arqueiro')return i%8<5?['shoot',i%8]:['reload',i%8-5];if(m.c.id==='dancarina')return i<4?['dance_start',i]:i<44?['dance',(i-4)%8]:['dance_end',i-44];return [own[m.c.id],i];}
async function sprite(f,s,scale=3){return sharp(R.rgba(f.pixels),{raw:{width:s,height:s,channels:4}}).resize(s*scale,s*scale,{kernel:'nearest'}).png().toBuffer();}
function label(text,w=240,size=15,color='#f7f4ed'){return Buffer.from(`<svg width="${w}" height="30"><text x="0" y="21" fill="${color}" font-size="${size}" font-family="DejaVu Sans,sans-serif">${text}</text></svg>`);}
async function board(mode,i,file){const comps=[{input:label('EMPIRE · ANIMAÇÕES V12',900,25),left:24,top:10},{input:label(mode==='walk'?'Caminhada · quadros nativos ampliados 3×':'Ações dos oito personagens · quadros nativos ampliados 3×',1000,14,'#c5cdd9'),left:24,top:43}];
 for(let j=0;j<models.length;j++){const m=models[j],s=m.c.width,x=24+(j%4)*264,y=83+Math.floor(j/4)*300,[action,index]=mode==='walk'?['walk',i]:special(m,i);
  comps.push({input:{create:{width:248,height:283,channels:4,background:'#777b85'}},left:x,top:y},{input:await sprite(get(m,action,index),s),left:x+Math.floor((248-s*3)/2),top:y+244-s*3},{input:label(names[m.c.id]+' · '+s+'×'+s,235,16),left:x+12,top:y+248});
 }
 await sharp({create:{width:1080,height:692,channels:4,background:'#222832'}}).composite(comps).png().toFile(file);
}
function gif(folder,file){cp.execFileSync('ffmpeg',['-v','error','-y','-framerate','10','-i',path.join(folder,'%03d.png'),'-filter_complex','[0:v]split[a][b];[a]palettegen=stats_mode=full:max_colors=256[p];[b][p]paletteuse=dither=none','-loop','0',file],{stdio:'pipe'});}
async function main(){
 const walk=path.join(temp,'walk'),act=path.join(temp,'actions');fs.mkdirSync(walk,{recursive:true});fs.mkdirSync(act,{recursive:true});
 for(let i=0;i<8;i++)await board('walk',i,path.join(walk,String(i).padStart(3,'0')+'.png'));
 for(let i=0;i<48;i++)await board('actions',i,path.join(act,String(i).padStart(3,'0')+'.png'));
 gif(walk,path.join(dir,'PREVIA-CAMINHADA-V12.gif'));gif(act,path.join(dir,'PREVIA-ACOES-V12.gif'));
 fs.copyFileSync(path.join(walk,'000.png'),path.join(dir,'EMPIRE-ANIMACOES-V12.png'));
 for(const m of models){const folder=path.join(temp,m.c.id);fs.mkdirSync(folder,{recursive:true});const s=m.c.width,n=m.c.id==='sombra'||m.c.id==='dancarina'?48:m.c.id==='arqueiro'?8:m.defs.find(d=>d.name===own[m.c.id]).n;
  for(let i=0;i<n;i++){const [k,f]=special(m,i),width=m.c.id==='sombra'?160:s+16,height=s+16,comps=[];
   if(m.c.id==='sombra'&&i>=6&&i<42){const stage=i<14?(i-6)/7:i<36?1:1-(i-36)/5,fx=await sharp(flowers.draw(Math.max(0,stage)),{raw:{width:160,height:32,channels:4}}).png().toBuffer();comps.push({input:fx,left:0,top:s-23});}
   comps.push({input:await sprite(get(m,k,f),s,1),left:Math.floor((width-s)/2),top:8});
   const native=await sharp({create:{width,height,channels:4,background:'#777b85'}}).composite(comps).png().toBuffer();await sharp(native).resize(width*3,height*3,{kernel:'nearest'}).png().toFile(path.join(folder,String(i).padStart(3,'0')+'.png'));
  }
  gif(folder,path.join(dir,m.c.id+'.gif'));
 }
 const video=path.join(temp,'video');fs.mkdirSync(video,{recursive:true});for(let i=0;i<84;i++)fs.copyFileSync(path.join(i<24?walk:act,String(i<24?i%8:(i-24)%48).padStart(3,'0')+'.png'),path.join(video,String(i).padStart(3,'0')+'.png'));
 cp.execFileSync('ffmpeg',['-v','error','-y','-framerate','10','-i',path.join(video,'%03d.png'),'-c:v','libx264','-crf','14','-pix_fmt','yuv420p','-movflags','+faststart',path.join(dir,'EMPIRE-ANIMACOES-V12.mp4')],{stdio:'pipe'});
 console.log('Previews created: 10 GIFs, 1 PNG, 1 MP4.');
}
main().catch(e=>{console.error(e.message);process.exit(1);});
