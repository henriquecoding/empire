const R=require('./raster.cjs'),rigs=require('./rigs.cjs');
const torsos={
 rei:[[31,28],[64,29],[68,40],[66,61],[57,68],[39,66],[25,62],[22,51],[29,40]],
 escudeiro:[[18,26],[33,29],[42,33],[46,44],[42,52],[27,52],[12,52],[10,41]],
 nia:[[25,29],[38,28],[43,33],[43,49],[34,51],[26,50],[22,41]],
 bardo:[[22,29],[41,29],[57,24],[60,29],[51,38],[45,51],[34,55],[20,51],[15,44]],
 arqueiro:[[34,29],[49,28],[58,38],[53,55],[56,63],[42,62],[35,60],[28,62],[26,44]],
 intendente:[[20,29],[34,28],[42,16],[49,16],[53,24],[47,35],[45,48],[39,51],[25,52],[17,48],[17,38]],
 sombra:[[28,24],[37,9],[45,9],[46,22],[62,23],[68,32],[64,44],[64,61],[59,67],[47,64],[45,54],[33,51],[28,42]],
 dancarina:[[27,21],[36,20],[41,25],[44,34],[41,43],[31,46],[25,41],[22,33]]
};
module.exports=c=>{
 const rig={...rigs[c.id],pivots:{...rigs[c.id].pivots}},s=c.width,pixels=R.base(c),parts=R.split(pixels,s,rig),points={};
 for(const [k,p]of Object.entries(parts))if(k!=='body')points[k]=Array.from(p.entries()).filter(([,v])=>v).map(([i])=>[i%s,Math.floor(i/s)]);
 for(let y=0;y<s;y++)for(let x=0;x<s;x++)if(parts.body[y*s+x]&&!R.inside(x+.5,y+.5,torsos[c.id])){
  let best='',distance=Infinity;for(const [k,ps]of Object.entries(points))for(const [px,py]of ps){const d=(x-px)**2+(y-py)**2;if(d<distance){distance=d;best=k;}}
  if(best){parts[best][y*s+x]=parts.body[y*s+x];parts.body[y*s+x]=0;}
 }
 if(c.id==='sombra')for(const side of ['L','R']){
  const lower=parts['arm'+side],upper=R.blank(s),cut=side==='L'?44:45;
  for(let y=0;y<cut;y++)for(let x=0;x<s;x++){upper[y*s+x]=lower[y*s+x];lower[y*s+x]=0;}
  parts['upperArm'+side]=upper;rig.pivots['arm'+side]=side==='L'?[24,44]:[68,45];
 }
 // Complete only the concealed 2–3 pixel joint sockets. The original visible pose stays exact.
 const joints=R.blank(s);
 for(const [name,[x,y]]of Object.entries(rig.pivots))if(name.startsWith('arm')||name.startsWith('leg')){
  const v=pixels[y*s+x]||pixels[(y+1)*s+x]||R.color(c.palette['0']);
  for(let j=-3;j<=3;j++)for(let i=-3;i<=3;i++)if(i*i+j*j<=9&&pixels[(y+j)*s+x+i])R.set(joints,s,x+i,y+j,v);
 }
 return {c,s,rig,pixels,parts,joints};
};
