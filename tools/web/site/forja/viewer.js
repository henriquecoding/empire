(() => {
  const $=id=>document.getElementById(id), model=globalThis.ForjaReview, renderer=globalThis.ForjaRenderer;
  let data=null, images=[], reference=null, index=0, playing=false, elapsed=0, last=0, notes=[], generation=0;
  const status=text=>{$('status').textContent=text;};
  const total=()=>data?.frames.reduce((n,f)=>n+f.duration_ms,0)||0;
  const offset=i=>data.frames.slice(0,i).reduce((n,f)=>n+f.duration_ms,0);
  const store=()=>{if(data)notes[index]={status:$('verdict').value,note:$('note').value};};
  function stop(){playing=false;$('play').textContent='Reproduzir';}
  function show(i, seek=true){
    if(!data)return;
    if(i!==index){store();index=i;}
    if(seek)elapsed=offset(index);
    $('timeline').value=index;$('counter').textContent=`${index+1} / ${images.length}`;
    $('time').textContent=`${offset(index)} ms`;$('frame-caption').textContent=`Quadro ${index+1} · ${data.frames[index].duration_ms} ms`;
    $('verdict').value=notes[index]?.status||'pending';$('note').value=notes[index]?.note||'';
    for(const b of $('frames').children)b.setAttribute('aria-current',String(Number(b.dataset.index)===index));
    const options={scale:Number($('scale').value),reference};
    for(const name of ['onion','skeleton','trajectory','difference'])options[name]=$(name).checked;
    renderer.draw($('candidate'),data,images,index,options);
    renderer.draw($('reference'),{...data,frames:[{}]},[reference],0,{scale:options.scale});
    $('canvases').className='canvases '+$('background').value;
  }
  async function decode(uri, size){
    const image=new Image();image.src=uri;await image.decode();
    if(image.width!==size[0]||image.height!==size[1])throw Error('Uma imagem difere da tela declarada.');
    return image;
  }
  async function open(raw){
    const next=model.validate(raw), ticket=++generation;stop();
    const loaded=await Promise.all(next.frames.map(f=>decode(f.image,next.canvas))), ref=await decode(next.reference,next.canvas);
    if(ticket!==generation)return;
    data=next;images=loaded;reference=ref;index=0;elapsed=0;notes=data.frames.map(()=>({status:'pending',note:''}));
    $('title').textContent=data.id||'Sequência';$('timeline').max=images.length-1;$('frames').replaceChildren();
    for(let i=0;i<images.length;i++){
      const button=document.createElement('button'), thumb=document.createElement('img'), label=document.createElement('span');
      thumb.src=data.frames[i].image;thumb.alt='';label.textContent=String(i+1);button.dataset.index=i;
      button.setAttribute('aria-label',`Ver quadro ${i+1}`);button.append(thumb,label);button.onclick=()=>{stop();show(i);};$('frames').append(button);
    }
    for(const id of ['play','previous','next','timeline','save'])$(id).disabled=false;
    $('verdict').value='pending';$('note').value='';$('timing').textContent=`${total()} ms · ${data.loop?'Ciclo contínuo':'Uma execução; termina no último quadro'}`;
    $('dimensions').textContent=`${data.canvas.join(' × ')} px`;
    const found=[...(data.review?.findings||[])];
    for(const f of data.review?.interactions||[])if(f.status!=='measured')found.push({code:'scene_contact',point:f.id,status:f.status});
    for(const [i,n] of (data.review?.outside_changes||[]).entries())if(n)found.push({frame:i,code:'outside_changed',status:'review',point:`${n} px`});
    $('summary').textContent=found.length?`${found.length} observações para conferir.`:'Sem alertas automáticos neste pacote. A revisão visual continua necessária.';
    $('findings').replaceChildren();
    const labels={support_slide:'Apoio desliza',support_unknown:'Apoio por confirmar',contact_unknown:'Contacto por confirmar',contact_gap:'Contacto afastado',region_unknown:'Região por confirmar',region_changed:'Região preservada mudou',scene_contact:'Interação na cena',outside_changed:'Estrutura alterada fora da região'};
    for(const f of found){const li=document.createElement('li');li.textContent=`Quadro ${(f.frame??0)+1} · ${f.message||labels[f.code]||f.code} · ${f.point||f.region||''}`;$('findings').append(li);}
    for(const note of data.review?.notes||[]){const li=document.createElement('li');li.textContent=note;$('findings').append(li);}
    $('provenance').textContent=JSON.stringify({commit:data.commit,loaded_file_sha256:data.loaded_file_sha256,package_sha256:data.package_sha256,clip_sha256:data.clip_sha256,source:data.source,authority:data.authority},null,2);
    status(data.source?.method==='synthetic-guides'?'Exemplo técnico carregado. Guias geométricos, sem arte aprovada.':'Pacote carregado localmente. As observações serão exportadas com a identidade desta versão.');show(0);
  }
  $('package').onchange=async event=>{try{const file=event.target.files[0];if(!file)return;if(file.size>64*1024*1024)throw Error('Limite de 64 MiB por pacote.');await open(await model.bind(await file.arrayBuffer()));}catch(e){status(e.message);}};
  $('play').onclick=()=>{if(playing){stop();return;}if(!data.loop&&elapsed>=total()-1)show(0);playing=true;last=performance.now();$('play').textContent='Pausar';};
  $('previous').onclick=()=>{stop();show(Math.max(0,index-1));};$('next').onclick=()=>{stop();show(Math.min(images.length-1,index+1));};
  $('timeline').oninput=()=>{stop();show(Number($('timeline').value));};
  for(const id of ['scale','background','onion','skeleton','trajectory','difference'])$(id).onchange=()=>{store();show(index,false);};
  $('note').oninput=store;$('verdict').onchange=store;
  $('save').onclick=()=>{try{store();const result=model.notes(data,notes,$('reviewer').value), url=URL.createObjectURL(new Blob([JSON.stringify(result,null,2)],{type:'application/json'}));
    const a=document.createElement('a');a.href=url;a.download='forja-observacoes.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);status('Observações exportadas; aprovação artística permanece pendente.');}catch(e){status(e.message);}};
  $('demo64').onclick=()=>open(renderer.demo(64)).catch(e=>status(e.message));$('demo80').onclick=()=>open(renderer.demo(80)).catch(e=>status(e.message));
  document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
  function tick(now){if(playing&&data){elapsed+=(now-last)*Number($('speed').value);last=now;
    if(!data.loop&&elapsed>=total()){elapsed=total()-1;stop();}show(model.at(data,elapsed),false);}requestAnimationFrame(tick);}
  requestAnimationFrame(tick);
  if(location.protocol!=='file:')fetch('review.json').then(r=>r.ok?r.arrayBuffer():null).then(async bytes=>bytes&&open(await model.bind(bytes))).catch(e=>status(e.message));
})();
