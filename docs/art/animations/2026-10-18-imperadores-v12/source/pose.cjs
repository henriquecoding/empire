const R=require('./raster.cjs');
const order=['cape','flag','ribbons','joints','legR','legL','body','tabard','upperArmR','upperArmL','armR','hood','head','hair','hat','crown','armL','shield','weapon','weaponL','weaponR','bow','arrows','coin','effect'];
function point(p,pivot,angle,dx=0,dy=0){const a=angle*Math.PI/180,x=p[0]-pivot[0],y=p[1]-pivot[1];return [Math.round(pivot[0]+x*Math.cos(a)-y*Math.sin(a)+dx),Math.round(pivot[1]+x*Math.sin(a)+y*Math.cos(a)+dy)];}
function fit(p,s,margin=1){const b=R.bounds(p,s);return R.transform(p,s,{dx:Math.max(margin-b[0],Math.min(0,s-1-margin-b[2])),dy:Math.max(margin-b[1],Math.min(0,s-1-margin-b[3]))});}
function cloth(p,s,dy){const q=R.blank(s),b=R.bounds(p,s),top=b[1],end=Math.min(s-2,b[3]+dy),length=end-top-dy;for(let y=top+dy;y<=end;y++){const sy=Math.round(top+(y-top-dy)*(b[3]-top)/Math.max(1,length));for(let x=0;x<s;x++)if(sy>=0&&sy<s)q[y*s+x]=p[sy*s+x];}return q;}
function grounded(p,s,angle,pivot,shift=0){let q=R.transform(p,s,{angle,pivot,dy:-15});let b=R.bounds(q,s);q=R.transform(q,s,{dx:shift,dy:s-2-b[3]});return q;}
function render(a,o={}){
 const {c,s,rig,parts}=a,bob=o.bob||0,dx=o.dx||0,layers={},arms=o.arms||{},mods=o.parts||{};
 for(const [name,original]of Object.entries({...parts,joints:a.joints})){
  let p=Uint32Array.from(original);if(o.closed&&name==='head')R.paintClosed(p,s,c,rig);
  if(o.hide?.includes(name)){layers[name]=R.blank(s);continue;}
  if(name.startsWith('leg')){
   const m=o.legs?.[name]||{},b=R.bounds(p,s),lx=Math.max(1-b[0],Math.min(s-2-b[2],m.dx||0));
   p=o.fold?grounded(p,s,(name==='legL'?48:-40)*o.fold,rig.pivots[name],name==='legL'?2*o.fold:-2*o.fold):R.leg(p,s,{hip:rig.hipY,boot:rig.boots,bob,dx:lx,dy:m.dy||0});
  }else if(o.fold&&(name==='cape'||name==='tabard'))p=cloth(p,s,bob);
  else {
   const arm=name==='armL'?'armL':name==='armR'?'armR':null;
   p=R.transform(p,s,{pivot:rig.pivots[arm]||rig.head,angle:arms[arm]||0,dx,dy:bob});
  }
  const parent={weapon:'armL',weaponL:'armL',weaponR:'armR',bow:'armL',arrows:'armR'}[name];
  if(parent){p=R.transform(original,s,{pivot:rig.pivots[name]||rig.handL,angle:o.weapon?.[name]||0});p=R.transform(p,s,{pivot:rig.pivots[parent],angle:arms[parent]||0,dx,dy:bob});}
  if(mods[name])p=R.transform(p,s,mods[name]);
  layers[name]=p;
 }
 if(o.fold){
  const left=rig.pivots.legL[0],right=rig.pivots.legR[0],y=Math.min(s-12,rig.hipY+bob-2),v=parts.legL[Math.min(s-1,rig.hipY+2)*s+left]||R.color(c.palette['8']||c.palette['0']);
  const support=R.blank(s);if(o.fold>.4)R.poly(support,s,[[left,y],[right,y],[right+1,y+5],[(left+right)/2,y+9],[left-1,y+5]],v);
  if(c.id==='sombra'&&o.fold>.4)R.poly(support,s,[[31,rig.hipY+bob-5],[47,rig.hipY+bob-7],[62,rig.hipY+bob-3],[67,s-10],[56,s-7],[34,s-8]],R.color(c.palette.C));
  layers.joints=R.merge([support,layers.joints],s);
 }
 if(o.effect)layers.effect=o.effect;
 return {layers,pixels:R.merge(order.filter(k=>layers[k]).map(k=>layers[k]),s)};
}
function walking(a,i,n,fast=false){
 const {s}=a,t=2*Math.PI*i/n,amp=fast?5:4,step=Math.round(Math.cos(t)*amp),bob=Math.abs(Math.sin(t))>.65?-1:0;
 const liftedL=Math.sin(t)>0?-Math.round(Math.sin(t)*(fast?4:3)):0,liftedR=Math.sin(t)<0?Math.round(Math.sin(t)*(fast?4:3)):0;
 const sway=Math.round(Math.sin(t)*3),o={bob,legs:{legL:{dx:step,dy:liftedL},legR:{dx:-step,dy:liftedR}},arms:{armL:sway,armR:-sway},parts:{cape:{dx:Math.sin(t-.8)>.4?1:0},flag:{dx:Math.sin(t-.8)>.4?1:0},ribbons:{dx:Math.sin(t-.8)>.4?-1:0}}};
 if(a.c.id==='dancarina')o.arms={armL:sway,armR:0};
 return o;
}
function defeat(a,t){
 const maxDrop=Math.min(a.s===80?10:8,a.s-2-R.bounds(a.parts.body,a.s)[3]),bob=Math.round(maxDrop*t),o={bob,fold:t,closed:t>.2,arms:{armL:-12*t,armR:12*t},weapon:{weapon:-80*t},parts:{}};
 if(a.c.id==='dancarina')o.arms.armR=-92*t;
 if(a.c.id==='arqueiro')o.hide=t>.3?['coin']:[];
 return o;
}
function crownFall(a,frame,t){
 const {s,parts,rig}=a;if(!parts.crown||!t)return frame;
 let p=R.transform(parts.crown,s,{pivot:rig.head,angle:t*75,dy:10});
 const b=R.bounds(p,s),targetX=s-2-(b[2]-b[0]),targetY=Math.min(s-2-(b[3]-b[1]),Math.round(4+(s-12)*(t*t)));
 p=R.transform(p,s,{dx:targetX-b[0],dy:targetY-b[1]});
 const b2=R.bounds(p,s);if(b2[3]>=s-2)p=R.transform(p,s,{dy:s-2-b2[3]});
 frame.layers.crown=p;frame.pixels=R.merge(order.filter(k=>frame.layers[k]).map(k=>frame.layers[k]),s);return frame;
}
function general(a,action,i,n){
 if(action==='walk'||action==='run')return render(a,walking(a,i,n,action==='run'));
 if(action==='idle')return render(a,{bob:i===2||i===3?-1:0,parts:{cape:{dx:i>2?1:0},flag:{dx:i>2?1:0},ribbons:{dx:i>2?-1:0}}});
 if(action==='blink')return render(a,{closed:i===1});
 if(action==='hit')return render(a,{closed:true,dx:i===0?-1:0,arms:{armL:-4,armR:4},parts:{cape:{dx:1}}});
 if(action==='die')return crownFall(a,render(a,defeat(a,i/(n-1))),Math.max(0,(i-1)/(n-2)));
 if(action==='rise')return render(a,{...defeat(a,1-i/(n-1)),hide:[...(a.c.id==='arqueiro'?['coin']:[]),'crown']});
 if(action==='interact')return render(a,{arms:{armR:[0,-8,-12,0][i],armL:[0,3,6,0][i]}});
 if(action==='celebrate'){const lift=[0,-1,-2,-2,-1,0][i];return render(a,{bob:lift,legs:{legL:{dy:lift},legR:{dy:lift}},arms:{armL:[0,8,12,12,6,0][i],armR:a.c.id==='dancarina'?0:[0,-8,-12,-12,-6,0][i]}});}
 return null;
}
module.exports={render,general,walking,defeat,order,point,fit,cloth,grounded};
