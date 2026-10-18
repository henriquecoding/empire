const fs=require('fs'),path=require('path'),crypto=require('crypto'),R=require('./raster.cjs'),prepare=require('./prepare.cjs'),P=require('./pose.cjs'),special=require('./special.cjs'),finish=require('./finish.cjs'),actions=require('./actions.cjs'),png=require('./png.cjs'),ase=require('./ase.cjs');
const data=require('./base-v11.json');
function frame(a,k,i,n){return finish(a,P.general(a,k,i,n)||special(a,k,i,n),k);}
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
function sheet(s,frames,columns){const rows=Math.ceil(frames.length/columns),w=s*columns,h=s*rows,b=Buffer.alloc(w*h*4);for(let f=0;f<frames.length;f++){if(!frames[f])continue;const p=R.rgba(frames[f].pixels),ox=(f%columns)*s,oy=Math.floor(f/columns)*s;for(let y=0;y<s;y++)p.copy(b,((oy+y)*w+ox)*4,y*s*4,(y+1)*s*4);}return png(w,h,b);}
function build(output){
 fs.mkdirSync(output,{recursive:true});const manifest={version:12,title:'Empire — oito personagens animados',base:'V11; conceitos adaptados antes desta animação. Não constitui arte desenhada originalmente do zero em 64/80.',nativeFrameEditing:true,artDirectionApproval:'aguarda revisão visual do autor',runtimeIntegration:false,alpha:'binary 0/255',filter:'nearest',directions:['right','left'],mirroring:'left é o espelho horizontal exato de right; equipamento também espelha',characters:[]};
 const all={};
 for(const c of data.characters){
  const a=prepare(c),s=c.width,defs=actions(c.id),folder=path.join(output,'personagens',c.id);fs.rmSync(path.join(folder,'acoes'),{recursive:true,force:true});fs.mkdirSync(path.join(folder,'acoes'),{recursive:true});
  const atlas=[],frames=[],tags=[],entries=[],cache={};let row=0,cleaned=0;
  for(const dir of ['right','left'])for(const d of defs){
   const ff=[];for(let i=0;i<d.n;i++){
    let f=frame(a,d.name,i,d.n);cleaned+=f.cleaned; if(dir==='left')f={...f,pixels:R.mirror(f.pixels,s),layers:Object.fromEntries(Object.entries(f.layers).map(([k,p])=>[k,R.mirror(p,s)]))};
    f.ms=d.fps===12?([83,84,83][i%3]):100;ff.push(f);
   }
   const from=frames.length;tags.push({name:d.name+'_'+dir,from,to:from+d.n-1,loop:d.loop});
   const cells=ff.map((f,i)=>({index:i,aseFrame:from+i,rect:{x:i*s,y:row*s,w:s,h:s},durationMs:f.ms,pivot:[s/2,s-2],rgbaSha256:hash(R.rgba(f.pixels))}));
   frames.push(...ff);for(let i=0;i<8;i++)atlas.push(ff[i]||null);
   const name=d.name+'_'+dir;fs.writeFileSync(path.join(folder,'acoes',name+'.png'),sheet(s,ff,d.n));
   entries.push({name,action:d.name,direction:dir,loop:d.loop,fps:d.fps,events:d.events.map(e=>dir==='left'&&e.socket?{...e,socket:[s-1-e.socket[0],e.socket[1]]}:e),sheet:'acoes/'+name+'.png',frames:cells});cache[name]=ff;row++;
  }
  const names=P.order.filter(k=>frames.some(f=>f.layers[k]));
  fs.writeFileSync(path.join(folder,c.id+'.aseprite'),ase(s,s,names,frames.map(f=>({ms:f.ms,layers:Object.fromEntries(names.filter(k=>f.layers[k]).map(k=>[k,R.rgba(f.layers[k])]))})),tags,[s/2,s-2]));
  fs.writeFileSync(path.join(folder,'atlas.png'),sheet(s,atlas,8));
  const metadata={id:c.id,width:s,height:s,pivot:[s/2,s-2],atlas:'atlas.png',columns:8,rows:row,layers:names,frames:frames.length,animations:entries,cleanup:{isolatedPixelsRemovedAcrossAllFrames:cleaned},notes:['Sem recorte automático; todos os quadros usam a grade completa.','Animação no lugar; deslocamento no mundo pertence ao jogo.','die termina em queda sentada/ajoelhada; rise não recolhe a coroa.','Ocultar a camada crown segundo o estado de posse definido pelo jogo.']};
  fs.writeFileSync(path.join(folder,'animacoes.json'),JSON.stringify(metadata,null,2)+'\n');
  fs.writeFileSync(path.join(folder,'paleta.json'),JSON.stringify(c.palette,null,2)+'\n');
  manifest.characters.push({id:c.id,size:s,frames:frames.length,tags:tags.length,metadata:'personagens/'+c.id+'/animacoes.json',aseprite:'personagens/'+c.id+'/'+c.id+'.aseprite',atlas:'personagens/'+c.id+'/atlas.png'});
  all[c.id]={a,cache,metadata};
 }
 manifest.totalFrames=manifest.characters.reduce((n,c)=>n+c.frames,0);manifest.totalAnimationTags=manifest.characters.reduce((n,c)=>n+c.tags,0);
 fs.writeFileSync(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');return {manifest,all};
}
if(require.main===module){if(!process.argv[2])throw Error('Uso: node source/export.cjs DIRETORIO_DE_SAIDA');const r=build(path.resolve(process.argv[2]));console.log(JSON.stringify({characters:r.manifest.characters.length,frames:r.manifest.totalFrames,tags:r.manifest.totalAnimationTags}));}
module.exports={build,frame,sheet};
