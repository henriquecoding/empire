const R=require('./raster.cjs'),P=require('./pose.cjs');
function rebuild(a,f){f.pixels=R.merge(P.order.filter(k=>f.layers[k]).map(k=>f.layers[k]),a.s);return f;}
function archer(a,action,i,n){
 const shoot=action==='shoot',t=shoot?[.35,1,0,.15,.35][i]:[.15,.6,.35][i],f=P.render(a,{hide:['bow','coin','armL','armR']});
 const {s,c}=a,wood=R.blank(s),string=R.blank(s),C=k=>R.color(c.palette[k]),curve=[[65,5],[65,9],[69,15],[73,21],[74,27],[72,31],[69,34],[69,38],[72,46],[73,53],[68,61],[64,67]];
 for(let j=1;j<curve.length;j++){const [x,y]=curve[j-1],[u,v]=curve[j];R.line(wood,s,x-1,y,u-1,v,C('0'),4);R.line(wood,s,x,y,u,v,C('W'),2);R.line(wood,s,x,y,u,v,C('k'));}
 const drawX=Math.round(54-14*t),linen=C('l'),dark=C('0'),left=R.blank(s),right=R.blank(s),elbow=32-Math.round(6*t);
 R.poly(left,s,[[27,41],[21,37],[elbow-3,30],[elbow+3,28],[drawX+1,31],[drawX+2,35],[elbow+3,36],[30,44]],dark);
 R.poly(left,s,[[27,40],[23,36],[elbow-1,31],[elbow+3,30],[elbow+7,32],[elbow+5,36],[29,42]],C('l'));
 R.line(left,s,elbow+4,33,drawX,33,C('h'),3);R.line(left,s,elbow+4,35,drawX,35,C('c'));
 R.disk(left,s,drawX,33,2,C('h'));R.set(left,s,drawX+1,33,C('L'));
 R.poly(right,s,[[53,37],[58,35],[62,35],[67,32],[71,33],[72,38],[66,42],[59,45],[53,44]],dark);
 R.poly(right,s,[[54,38],[58,36],[61,37],[62,40],[59,43],[54,43]],C('l'));
 R.poly(right,s,[[61,37],[67,34],[70,34],[70,37],[65,41],[61,41]],C('h'));
 R.line(right,s,62,41,66,39,C('c'));R.set(right,s,69,36,C('L'));
 R.line(string,s,65,5,drawX,33,linen);R.line(string,s,drawX,33,63,67,linen);
 if(!shoot||i<2){R.line(string,s,drawX-2,33,73,33,R.color(c.palette.S||c.palette.L));R.line(string,s,drawX-2,32,drawX+1,32,linen);R.set(string,s,74,33,linen);R.set(string,s,73,32,linen);R.set(string,s,73,34,linen);}
 f.layers.armL=left;f.layers.armR=right;f.layers.bow=R.merge([wood,string],s);return rebuild(a,f);
}
function seated(a,t,breath=0){
 const {s}=a,f=P.render(a,{bob:Math.round(10*t)+breath,fold:t,arms:{armL:-28*t,armR:28*t}});
 if(t>.85){
  f.layers.legL=P.grounded(a.parts.legL,s,52,a.rig.pivots.legL,-1);
  f.layers.legR=P.grounded(a.parts.legR,s,-58,a.rig.pivots.legR,-4);
 }
 return rebuild(a,f);
}
module.exports=(a,action,i,n)=>{
 const id=a.c.id,w=Math.sin(2*Math.PI*i/n),rise=Math.sin(Math.PI*i/(n-1));
 if(id==='arqueiro'&&(action==='shoot'||action==='reload'))return archer(a,action,i,n);
 if(id==='sombra'&&['sit','heal','stand'].includes(action))return seated(a,action==='heal'?1:action==='sit'?i/(n-1):1-i/(n-1),action==='heal'&&(i===3||i===4)?-1:0);
 let o={};
 if(id==='rei'&&action==='attack')o={arms:{armL:[15,30,-90,-50,0][i]},weapon:{weapon:[-80,-100,40,15,0][i]},parts:{cape:{dx:[0,1,2,1,0][i]}},bob:[0,-1,0,0,0][i]};
 if(id==='nia'&&action==='attack')o={arms:{armL:[15,45,-12,-4,0][i],armR:[-15,-45,12,4,0][i]},weapon:{weaponL:[0,10,-20,0,0][i],weaponR:[0,-10,20,0,0][i]},bob:[0,-1,0,0,0][i]};
 if(id==='escudeiro'&&action.startsWith('block')){const t=action==='block'?i/2:action==='block_hit'?[1,.6,1][i]:1;o={arms:{armL:-5*t},parts:{shield:{dx:Math.round(-3*t),dy:Math.round(-2*t),pivot:[44,36],angle:-4*t}},bob:action==='block_hold'&&i===2?-1:0};}
 if(id==='bardo'&&['play','cast','inspire'].includes(action))o={arms:{armL:(action==='cast'?[-4,-10,-14,12,6,0]:action==='inspire'?[-3,-8,8,12,4,0]:[-7,-12,0,9,4,-2])[i],armR:[0,0,-3,-3,0,0][i]},bob:i===2||i===3?-1:0,parts:{flag:{dx:i>2?1:0}}};
 if(id==='dancarina'&&action.startsWith('dance')){
  const phase=action==='dance'?i/8:action==='dance_start'?i/16:((n-1-i)/16),wave=Math.sin(phase*2*Math.PI),step=Math.round(wave*2);
  o={bob:Math.abs(wave)>.5?-1:0,arms:{armL:wave*16,armR:wave*8},legs:{legL:{dx:step,dy:wave>0?-2:0},legR:{dx:-step,dy:wave<0?-2:0}},parts:{ribbons:{dx:Math.round(Math.sin(phase*2*Math.PI-.6)),dy:Math.round(Math.sin(phase*2*Math.PI))}}};
 }
 if(id==='intendente'){
  if(action==='receive'||action==='collect')o={arms:{armL:-12*rise},bob:action==='collect'?Math.round(2*rise):0};
  if(action==='deliver')o={arms:{armR:-12*rise},weapon:{arrows:-12*rise},parts:{arrows:{dx:-Math.round(2*rise)}}};
  if(action==='no_payment')o={arms:{armL:10*rise},parts:{head:{dx:[0,-1,1,0][i]},hat:{dx:[0,-1,1,0][i]}}};
 }
 if(action==='command'||action==='mark')o={arms:{armR:-16*rise},bob:rise>.8?-1:0};
 if(action==='pay')o={arms:{armR:-10*rise},hide:id==='arqueiro'&&i>=2?['coin']:[]};
 return P.render(a,o);
};
