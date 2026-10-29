/* Validacao e tempo da bancada; sem acesso a rede ou alteracao do projeto. */
(() => {
  function validate(data) {
    if (!data || data.schema !== 'forja.review-package/1') throw Error('Esperado um pacote forja.review-package/1.');
    if (!Array.isArray(data.canvas) || data.canvas.length !== 2 || data.canvas.some(n => !Number.isInteger(n) || n < 1 || n > 4096)) throw Error('Tela inválida.');
    if (!Array.isArray(data.frames) || !data.frames.length || data.frames.length > 600) throw Error('Quantidade de quadros inválida.');
    if (data.canvas[0] * data.canvas[1] * data.frames.length * 4 > 268435456) throw Error('O pacote excede o limite de memória da bancada.');
    if (typeof data.loop !== 'boolean') throw Error('O pacote precisa declarar loop.');
    const image = value => typeof value === 'string' && /^data:image\/png;base64,[a-zA-Z0-9+/=]+$/.test(value);
    if (!image(data.reference) || data.frames.some(f => !f || !image(f.image))) throw Error('Imagens devem ser PNG incorporados, sem URLs externas.');
    if (data.frames.some(f => !Number.isInteger(f.duration_ms) || f.duration_ms < 1 || f.duration_ms > 65535)) throw Error('Duração inválida.');
    if (typeof data.package_sha256 !== 'string' || !data.package_sha256) throw Error('Falta a identidade do pacote.');
    return data;
  }
  function at(data, elapsed) {
    const total = data.frames.reduce((n, f) => n + f.duration_ms, 0);
    let t = data.loop ? elapsed % total : Math.min(elapsed, total - 1);
    for (let i = 0; i < data.frames.length; i++) { if (t < data.frames[i].duration_ms) return i; t -= data.frames[i].duration_ms; }
    return data.frames.length - 1;
  }
  function notes(data, observations, reviewer) {
    if (!reviewer.trim()) throw Error('Preencha o nome de quem reviu.');
    return { schema: 'forja.review-notes/1', package_sha256: data.package_sha256, loaded_file_sha256: data.loaded_file_sha256 || null, clip_sha256: data.clip_sha256 || null,
      commit: data.commit || null, reviewer: reviewer.trim(), recorded_at: new Date().toISOString(),
      observations: data.frames.map((f, i) => ({ frame: i, image_sha256: f.sha256 || null, ...observations[i] })), approval: 'pending' };
  }
  async function hash(bytes) {
    return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)), n=>n.toString(16).padStart(2,'0')).join('');
  }
  async function bind(raw) {
    const bytes=typeof raw==='string'?new TextEncoder().encode(raw):new Uint8Array(raw);
    const data=validate(JSON.parse(new TextDecoder().decode(bytes)));
    for(const f of [{image:data.reference}, ...data.frames]) {
      const bytes=Uint8Array.from(atob(f.image.split(',')[1]),c=>c.charCodeAt(0)), view=new DataView(bytes.buffer);
      if(bytes.length<24 || view.getUint32(0)!==0x89504e47 || view.getUint32(4)!==0x0d0a1a0a ||
         view.getUint32(16)!==data.canvas[0] || view.getUint32(20)!==data.canvas[1]) throw Error('PNG inválido ou tela diferente da declarada.');
      const actual=await hash(bytes);
      if(f.sha256 && actual!==f.sha256) throw Error('O hash de um quadro mudou. Refaça o pacote antes de rever.');
      f.sha256=actual;
    }
    data.loaded_file_sha256=await hash(bytes);
    return data;
  }
  globalThis.ForjaReview = { validate, at, notes, bind };
})();
