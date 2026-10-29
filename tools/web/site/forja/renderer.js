(() => {
  const bones = [['NOSE','NECK'],['NECK','RIGHT SHOULDER'],['RIGHT SHOULDER','RIGHT ELBOW'],['RIGHT ELBOW','RIGHT ARM'],
    ['NECK','LEFT SHOULDER'],['LEFT SHOULDER','LEFT ELBOW'],['LEFT ELBOW','LEFT ARM'],['NECK','RIGHT HIP'],
    ['RIGHT HIP','RIGHT KNEE'],['RIGHT KNEE','RIGHT LEG'],['NECK','LEFT HIP'],['LEFT HIP','LEFT KNEE'],['LEFT KNEE','LEFT LEG']];
  function overlay(ctx, p) {
    if (!p || !p.points) return;
    ctx.strokeStyle = '#46d6e1'; ctx.lineWidth = 1;
    for (const [a,b] of bones) if (p.points[a] && p.points[b]) {ctx.beginPath(); ctx.moveTo(...p.points[a]);ctx.lineTo(...p.points[b]);ctx.stroke();}
    for (const [name, xy] of Object.entries(p.points)) {ctx.fillStyle = p.occluded?.includes(name) ? '#e8bb70' : '#ffffff'; ctx.fillRect(xy[0]-1,xy[1]-1,2,2);}
    for (const name of p.supports || []) {const xy = p.points[name] || p.sockets?.[name]; if(xy) {ctx.fillStyle='#6deb9c';ctx.fillRect(xy[0]-2,xy[1],5,1);}}
  }
  function draw(canvas, data, images, index, options) {
    canvas.width=data.canvas[0]; canvas.height=data.canvas[1];
    canvas.style.width=`${canvas.width*options.scale}px`;canvas.style.height=`${canvas.height*options.scale}px`;
    const ctx=canvas.getContext('2d'); ctx.imageSmoothingEnabled=false; ctx.drawImage(images[index],0,0);
    if(options.difference && options.reference) {
      const temp=document.createElement('canvas');temp.width=canvas.width;temp.height=canvas.height;
      const tc=temp.getContext('2d');tc.drawImage(options.reference,0,0);
      const a=ctx.getImageData(0,0,canvas.width,canvas.height), b=tc.getImageData(0,0,canvas.width,canvas.height);
      for(let i=0;i<a.data.length;i+=4) {const same=[0,1,2,3].every(k=>a.data[i+k]===b.data[i+k]); a.data.set(same?[0,0,0,0]:[238,128,78,255],i);}
      ctx.putImageData(a,0,0);
    }
    if(options.onion && index>0) {ctx.globalAlpha=.25;ctx.drawImage(images[index-1],0,0);ctx.globalAlpha=1;}
    if(options.trajectory) {
      const names=['RIGHT ARM','LEFT ARM','RIGHT LEG','LEFT LEG'];ctx.strokeStyle='#b795e0';
      for(const name of names) {ctx.beginPath(); let started=false;
        for(const f of data.frames) {const p=f.pose?.points?.[name];if(p){if(!started){ctx.moveTo(...p);started=true;}else ctx.lineTo(...p);}}ctx.stroke();}
    }
    if(options.skeleton) overlay(ctx,data.frames[index].pose);
  }
  function demo(side) {
    const count=side===64?8:5, action=side===64?'Caminhada':'Ataque'; const frames=[];
    for(let i=0;i<count;i++) {
      const p={points:{}, supports:[],occluded:[]}, walk=side===64, swing=Math.sin(i/count*Math.PI*2)*side*.1;
      const coords={'NOSE':[.57,.22],'NECK':[.5,.34],'RIGHT SHOULDER':[.47,.35],'LEFT SHOULDER':[.54,.35],
        'RIGHT HIP':[.47,.60],'LEFT HIP':[.54,.60],'RIGHT KNEE':[.44,.78],'LEFT KNEE':[.57,.78],
        'RIGHT LEG':[.40,.97],'LEFT LEG':[.61,.97],'RIGHT ELBOW':[.40,.49],'LEFT ELBOW':[.59,.49],
        'RIGHT ARM':[.45,.61],'LEFT ARM':[.65,.59]};
      for(const [n,xy] of Object.entries(coords)) p.points[n]=xy.map(v=>Math.round(v*(side-1)));
      if(walk) {for(const n of ['RIGHT LEG','LEFT ARM'])p.points[n][0]+=Math.round(swing);
        for(const n of ['LEFT LEG','RIGHT ARM'])p.points[n][0]-=Math.round(swing);}
      else {p.points['RIGHT ARM']=[Math.round(side*(.40+i*.09)),Math.round(side*(.60-Math.sin(i*Math.PI/4)*.25))];}
      const canvas=document.createElement('canvas');canvas.width=side;canvas.height=side;overlay(canvas.getContext('2d'),p);
      frames.push({image:canvas.toDataURL('image/png'),duration_ms:100,pose:p,phase:`estudo ${i+1}`});
    }
    return {schema:'forja.review-package/1',id:`${action} · exemplo técnico`,canvas:[side,side],frames,
      loop:side===64,reference:frames[0].image,package_sha256:`demo-${side}`,approval:'pending',source:{method:'synthetic-guides'},
      review:{findings:[],notes:['Exemplo geométrico. Não representa arte ou movimento aprovado do Empire.']}};
  }
  globalThis.ForjaRenderer={draw,demo};
})();
