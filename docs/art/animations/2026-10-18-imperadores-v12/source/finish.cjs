const R=require('./raster.cjs'),P=require('./pose.cjs');
module.exports=(a,f,action)=>{
 const s=a.s;
 if(a.c.id==='sombra'&&['die','rise'].includes(action)){
  const b=R.bounds(f.layers.head,s),base=R.bounds(a.parts.head,s),dy=b[1]-base[1],cap=R.blank(s),C=k=>R.color(a.c.palette[k]);
  R.poly(cap,s,[[46,13+dy],[51,11+dy],[56,12+dy],[59,16+dy],[56,20+dy],[47,18+dy]],C('0'));
  R.poly(cap,s,[[47,14+dy],[51,12+dy],[55,13+dy],[57,16+dy],[55,18+dy],[48,17+dy]],C('C'));
  R.line(cap,s,51,13+dy,55,14+dy,C('G'));
  f.layers.head=R.merge([cap,f.layers.head],s);
  f.pixels=R.merge(P.order.filter(k=>f.layers[k]).map(k=>f.layers[k]),s);
 }
 const seen=new Uint8Array(s*s),removed=[];
 for(let n=0;n<f.pixels.length;n++)if(f.pixels[n]&&!seen[n]){
  const q=[n];seen[n]=1;for(let h=0;h<q.length;h++){const i=q[h],x=i%s,y=Math.floor(i/s);for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const xx=x+dx,yy=y+dy,j=yy*s+xx;if(xx>=0&&yy>=0&&xx<s&&yy<s&&!seen[j]&&f.pixels[j]){seen[j]=1;q.push(j);}}}
  if(q.length<=2)for(const i of q){removed.push(i);f.pixels[i]=0;for(const p of Object.values(f.layers))p[i]=0;}
 }
 f.cleaned=removed.length;return f;
};
