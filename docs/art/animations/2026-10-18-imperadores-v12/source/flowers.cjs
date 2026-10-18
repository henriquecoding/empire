const fs=require('fs'),path=require('path'),R=require('./raster.cjs'),png=require('./png.cjs'),ase=require('./ase.cjs');
const colours={soil:'#35472d',stem:'#4c6a3c',leaf:'#789956',light:'#a8bd71',pink:'#d76b9f',pinkLight:'#f3a5c9',pinkDark:'#963b69',blue:'#6e9bc4',blueLight:'#b2d5e5',blueDark:'#445d89',yellow:'#efc969',yellowLight:'#fff0ba',yellowDark:'#a87a3c'};
function draw(stage,sway=0){
 const s=160,p=R.blank(s),C=k=>R.color(colours[k]),plants=[[10,10,'pink'],[24,15,'yellow'],[39,9,'blue'],[48,13,'pink'],[112,11,'blue'],[124,16,'pink'],[138,12,'yellow'],[150,9,'blue']];
 if(stage<=0)return R.rgba(p).subarray(0,160*32*4);
 for(const [x,h,type]of plants){const height=Math.max(1,Math.round(h*stage)),top=30-height,dx=stage>.8?sway:0;
  R.line(p,s,x,30,x+dx,top,C('stem'));if(stage>.2){R.line(p,s,x,26,x-3,24,C('leaf'));R.line(p,s,x-1,25,x-4,25,C('stem'));R.line(p,s,x,27,x+3,25,C('light'));}
  if(stage>.5){const cx=x+dx,cy=top;R.line(p,s,cx-2,cy,cx+2,cy,C(type+'Dark'));R.line(p,s,cx-1,cy-1,cx+1,cy-1,C(type));R.line(p,s,cx-1,cy+1,cx+1,cy+1,C(type));R.set(p,s,cx,cy-2,C(type+'Light'));R.set(p,s,cx,cy,C('yellowLight'));}
  R.line(p,s,x-2,30,x+2,30,C('soil'));
 }
 return R.rgba(p).subarray(0,160*32*4);
}
function build(output){const folder=path.join(output,'efeitos');fs.mkdirSync(folder,{recursive:true});const frames=[],tags=[],entries=[];
 for(const [name,n,loop]of [['grow',8,false],['idle',4,true],['wither',4,false]]){const from=frames.length;for(let i=0;i<n;i++){const t=name==='grow'?i/(n-1):name==='idle'?1:1-i/(n-1);frames.push({ms:100,layers:{flowers:draw(t,name==='idle'&&i===2?1:0)}});}tags.push({name,from,to:frames.length-1,loop});entries.push({name,from,to:frames.length-1,loop,fps:10});}
 const w=160*frames.length,b=Buffer.alloc(w*32*4);for(let i=0;i<frames.length;i++)for(let y=0;y<32;y++)frames[i].layers.flowers.copy(b,(y*w+i*160)*4,y*160*4,(y+1)*160*4);
 fs.writeFileSync(path.join(folder,'sombra-flores.png'),png(w,32,b));fs.writeFileSync(path.join(folder,'sombra-flores.aseprite'),ase(160,32,['flowers'],frames,tags,[80,31]));
 fs.writeFileSync(path.join(folder,'sombra-flores.json'),JSON.stringify({width:160,height:32,pivot:[80,31],sheet:'sombra-flores.png',animations:entries,integration:'Efeito de chão separado. Disparar grow uma vez ao começar a cura, idle enquanto dura e wither ao terminar; nunca reiniciar grow a cada loop de heal.'},null,2)+'\n');return frames;
}
if(require.main===module)build(path.resolve(process.argv[2]));module.exports={build,draw};
