// O relogio segue duracoes do manifesto, sem converter 65 ms em FPS ou recentrar poses.
(async () => {
  const data = JSON.parse(document.getElementById('data').textContent);
  const m = data.manifest;
  const get = id => document.getElementById(id);
  const images = { actor: {}, final: {} };
  await Promise.all(Object.entries(data.images).flatMap(([variant, frames]) =>
    Object.entries(frames).map(async ([index, url]) => {
      const img = new Image(); img.src = url; await img.decode(); images[variant][index] = img;
    })));
  for (const action of m.actions) {
    const option = document.createElement('option');
    option.value = action.name; option.textContent = action.name; get('action').append(option);
  }
  if (data.reference) {
    get('authority').hidden = false; get('reference').src = data.reference;
  }
  get('recipe').textContent = m.replay.recipe_sha256;
  let sequence = m.replay.events, index = 0, playing = false, last = 0, elapsed = 0;
  function draw() {
    const event = sequence[index], variant = get('effects').checked ? 'final' : 'actor';
    for (const [id, scale] of [['native', 1], ['large', Number(get('zoom').value)]]) {
      const canvas = get(id), ctx = canvas.getContext('2d');
      canvas.width = m.canvas[0] * scale; canvas.height = m.canvas[1] * scale;
      ctx.imageSmoothingEnabled = false; ctx.fillStyle = get('background').value;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      if (get('onion').checked) for (const adjacent of [index - 1, index + 1]) {
        const neighbor = sequence[adjacent];
        if (neighbor && neighbor.action === event.action) {
          ctx.globalAlpha = 0.22;
          ctx.drawImage(images[variant][neighbor.frame], 0, 0, canvas.width, canvas.height);
        }
      }
      ctx.globalAlpha = 1;
      ctx.drawImage(images[variant][event.frame], 0, 0, canvas.width, canvas.height);
      if (get('pivot').checked) {
        ctx.fillStyle = '#ef5a9a'; ctx.fillRect(m.pivot[0] * scale, m.pivot[1] * scale, scale, scale);
      }
    }
    get('seek').value = index; get('seek').max = sequence.length - 1;
    get('status').textContent = event.action + ' · quadro ' + event.frame + ' · ' + event.duration_ms + ' ms · '
      + 'estado ' + event.state + ' · entrada ' + event.input + ' · câmara ' + event.camera.join(', ') + ' · '
      + (variant === 'actor' ? 'sem efeitos' : 'composição final');
  }
  function pause() { playing = false; elapsed = 0; get('play').textContent = 'Reproduzir'; }
  get('play').onclick = () => {
    if (!playing && index === sequence.length - 1) { index = 0; elapsed = 0; }
    playing = !playing; last = performance.now(); get('play').textContent = playing ? 'Pausar' : 'Reproduzir';
  };
  get('previous').onclick = () => { pause(); index = Math.max(0, index - 1); draw(); };
  get('next').onclick = () => { pause(); index = Math.min(sequence.length - 1, index + 1); draw(); };
  get('seek').oninput = () => { pause(); index = Number(get('seek').value); draw(); };
  get('action').onchange = () => {
    pause(); index = 0;
    const action = m.actions.find(a => a.name === get('action').value);
    sequence = action ? action.playback.map(frame => ({frame, action: action.name,
      duration_ms: m.frames[frame].duration_ms, state: action.name, input: 'preview', camera: [0, 0]})) : m.replay.events;
    draw();
  };
  for (const id of ['effects', 'onion', 'zoom', 'pivot', 'background']) get(id).onchange = draw;
  document.addEventListener('visibilitychange', () => { if (document.hidden) pause(); });
  function tick(now) {
    if (playing) {
      elapsed += now - last;
      while (playing && elapsed >= sequence[index].duration_ms) {
        elapsed -= sequence[index].duration_ms;
        if (index === sequence.length - 1) { pause(); } else { index++; }
      }
      draw();
    }
    last = now; requestAnimationFrame(tick);
  }
  draw(); requestAnimationFrame(tick);
})().catch(error => {
  document.getElementById('status').textContent = 'Não foi possível abrir o ensaio: ' + error.message;
});
