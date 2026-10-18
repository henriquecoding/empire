const names = {oficina:'Oficina do Reino',vigilia:'Vigília da Fronteira'};
const labels = {dia:'Dia',noite:'Noite · indisponibilidade',subsolo:'Subsolo · recarga',pausa:'Pausa',fundacao:'Ficha de fundação',toque:'Toque · 844 × 390',estados:'Estados e ícones'};
const details = {dia:'Contagens ilustrativas. Cenário e personagem conservam os pixels da captura nativa.',noite:'Composição sobre a captura noturna existente do site; não é o mesmo estado da captura diurna. Bloqueio explicado por texto, sem depender só da cor.',subsolo:'Recarga e comandos no topo, preservando a circulação na faixa inferior. Imagem de campanha existente.',pausa:'Proposta de linguagem visual para a pausa. O véu é uma camada modal da composição, sem desfocar o cenário.',fundacao:'Abrir a ficha não funda. Voltar recebe o foco inicial. Os requisitos reais continuam a pertencer à simulação.',toque:'Recorte demonstrativo sem redimensionar os pixels do cenário. Correr, Fixar, moeda, interação, ataque, habilidade e pausa preservados no desenho; gestos ainda não implementados.',estados:'Normal, foco, premido, recarga, bloqueado e sem moedas. Biblioteca de ícones desenhada na grelha 16 × 16.'};
let theme='oficina', mode='dia';
function update(){
  const file=`${theme}-${mode}.png`,screen=document.getElementById('screen');
  screen.src=file;screen.alt=`${names[theme]} · ${labels[mode]}. Composição conceptual da interface do Empire.`;
  screen.width=mode==='toque'?844:1280;screen.height=mode==='toque'?390:mode==='estados'?352:720;
  document.getElementById('caption').textContent=`${names[theme]} · ${labels[mode]}`;
  document.getElementById('description').textContent=details[mode];
  document.getElementById('full').href=file;
  for(const b of document.querySelectorAll('[data-theme]'))b.setAttribute('aria-pressed',String(b.dataset.theme===theme));
  for(const b of document.querySelectorAll('[data-mode]'))b.setAttribute('aria-pressed',String(b.dataset.mode===mode));
}
document.getElementById('themes').addEventListener('click',event=>{const b=event.target.closest('[data-theme]');if(b){theme=b.dataset.theme;update();}});
document.getElementById('modes').addEventListener('click',event=>{const b=event.target.closest('[data-mode]');if(b){mode=b.dataset.mode;update();}});
document.getElementById('native').addEventListener('change',event=>document.getElementById('viewport').classList.toggle('native',event.target.checked));
