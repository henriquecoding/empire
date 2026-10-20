/* Plant clocks only. Rendering uses pre-drawn pixels at integer coordinates. */
function randomStream(seed){let value=seed>>>0;return()=>{value=(Math.imul(value,1664525)+1013904223)>>>0;return value/4294967296;};}
function createGarden(seed=20261019){
 const rnd=randomStream(seed),plants=[];
 for(let i=0;i<28;i++){
  const front=i>=19,slot=front?i-19:i,count=front?9:19;
  const x=Math.round(5+(slot+.2+rnd()*.6)*(150/count)),y=front?37+Math.floor(rnd()*2):32+Math.floor(rnd()*4);
  const species=Math.floor(rnd()*3),height=front?(rnd()<.6?7:10):[7,10,14][Math.floor(rnd()*3)];
  plants.push({id:i,x,y,layer:front?'front':'back',variant:['ivory','rose','yellow'][species]+'-'+height});
 }
 const order=plants.map(p=>p.id);for(let i=order.length-1;i>0;i--){const j=Math.floor(rnd()*(i+1));[order[i],order[j]]=[order[j],order[i]];}
 let start=1280;for(const id of order){start+=90+Math.floor(rnd()*81);Object.assign(plants[id],{startMs:start,growMs:720+Math.floor(rnd()*681),witherMs:8350+Math.floor(rnd()*1101),exitMs:650+Math.floor(rnd()*601)});}
 return {seed:seed>>>0,width:160,height:40,pivot:[80,38],plants};
}
function plantStage(plant,timeMs){
 if(timeMs<plant.startMs)return -1;
 if(timeMs<plant.witherMs)return Math.min(7,Math.floor((timeMs-plant.startMs)/plant.growMs*8));
 const phase=(timeMs-plant.witherMs)/plant.exitMs;
 if(phase>=1)return -1;
 return 9+Math.min(4,Math.floor(phase*5));
}
const api={randomStream,createGarden,plantStage};
if(typeof module!=='undefined')module.exports=api;
if(typeof window!=='undefined')window.EmpireGarden=api;
