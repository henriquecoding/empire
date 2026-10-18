// Hand-authored clusters. Coordinates are final sprite pixels, never scaled portraits.
const fs=require('fs'),path=require('path');
const file=path.join(__dirname,'native-pixels.json'),data=JSON.parse(fs.readFileSync(file));
const byId=Object.fromEntries(data.characters.map(c=>[c.id,c]));
for(const c of data.characters)c.nativeEdits=[];
function row(id,y,x,s,reason){
 const c=byId[id];
 for(let i=0;i<s.length;i++)if(s[i]!=='.'){
  const color=s[i]==='~'?null:c.palette[s[i]];
  if(s[i]!=='~'&&!color)throw Error(id+': unknown '+s[i]);
  const old=c.nativeEdits.find(p=>p.x===x+i&&p.y===y);
  if(old)Object.assign(old,{color,reason});else c.nativeEdits.push({x:x+i,y,color,reason});
 }
}
function plane(id,spans,s,reason){for(const [y,x,end] of spans)row(id,y,x,s.repeat(end-x+1),reason);}
function feature(id,lines,reason){for(const [y,x,s] of lines)row(id,y,x,s,reason);}
byId.rei.palette['$']='#ffd096';
plane('rei',[[13,41,49],[14,41,50],[15,41,52],[16,41,53],[17,41,54],[18,41,54],[19,41,54],[20,41,53],[21,41,54],[22,41,55],[23,41,56],[24,41,56],[25,42,55],[26,43,54],[27,45,54]],'a','Reorganizar os planos do rosto; remover os sinais faciais V8.');
feature('rei',[[13,41,'$$$'],[14,41,'$$'],[15,41,'$'],[14,43,'5555'],[15,42,'500005'],[16,43,'0hhh0'],[17,43,'hh0h0'],[18,43,'Yh0h0'],[19,44,'YQY'],[15,50,'5005'],[16,50,'0hh0'],[17,50,'h0h0'],[18,50,'Y0h0']],'Sobrancelhas espessas, duas escleras e pupilas separadas, assimétricas em três quartos.');
feature('rei',[[16,49,'$'],[17,49,'$Y'],[18,49,'$aY'],[19,49,'$aaa$aY'],[20,49,'Yaa5QY'],[21,50,'YQQ'],[20,41,'Y'],[21,41,'Ya'],[22,41,'Ya'],[23,41,'Ya'],[24,42,'Ya']],'Ponte, ponta, asa e sombra inferior do nariz na mesma rampa das bochechas.');
feature('rei',[[21,44,'QQaaaaaaQ'],[22,44,'Q500000005Q'],[23,44,'Q0ggg0ggg05'],[24,45,'Q000gg005'],[25,46,'QQQQQQQ'],[26,47,'YaaaY'],[27,46,'YUUUUUUUY']],'Sorriso volumétrico: canto, dentes em grupos, cavidade, lábio inferior e queixo.');

plane('escudeiro',[[18,36,41],[19,35,42],[20,35,43],[21,35,44],[22,35,46],[23,35,46],[24,35,45],[25,35,43],[26,35,42],[27,35,41],[28,36,40]],'Y','Abrir o rosto sob o elmo e recompor a mandíbula.');
feature('escudeiro',[[18,36,'333'],[19,36,'3003'],[20,36,'Zdd0'],[21,36,'Yd0d'],[19,41,'30'],[20,41,'d0'],[21,41,'Y0'],[21,40,'ZYY'],[22,40,'ZYYYYYY'],[23,41,'Y3TYY'],[24,42,'TT']],'Olhar decidido sob a aba; olho distante curto e nariz com plano inferior.');
feature('escudeiro',[[24,36,'3YYYYYY3'],[25,36,'30cccc03'],[26,36,'Y300003'],[27,37,'QQQQQ'],[28,37,'ZYY']],'Adaptar a hierarquia do escudeiro do autor: dentes juntos, lábio, queixo separado.');

byId.nia.palette['$']='#e18a43';
plane('nia',[[19,32,37],[20,31,39],[21,31,40],[22,31,40],[23,31,40],[24,31,41],[25,31,40],[26,32,40],[27,33,39],[28,34,38]],'Q','Dar área útil à expressão mantendo o cabelo, as argolas e o figurino.');
feature('nia',[[19,31,'HHHH'],[20,31,'3QQ33'],[21,31,'3dd13'],[22,31,'Qd1dQ'],[20,38,'H33'],[21,38,'d13'],[22,38,'Q13'],[21,36,'$'],[22,36,'$Q'],[23,36,'$QQQ'],[24,37,'HNN'],[23,31,'$Q'],[24,31,'$Q']],'Sobrancelhas ativas, olhos de tamanhos diferentes e nariz integrado à pele.');
feature('nia',[[24,32,'HQQQQQQH'],[25,32,'3ccccc33'],[26,33,'33333N'],[27,34,'N$$NN'],[28,35,'NNN']],'Sorriso confiante com dentes, canto elevado, lábio inferior e mandíbula.');

plane('bardo',[[18,31,39],[19,31,40],[20,31,40],[21,31,41],[22,32,41],[24,34,40],[25,34,40],[26,34,39],[27,35,39]],'Y','Limpar os sinais do rosto sem retirar barba, cabelo ou bigode.');
feature('bardo',[[18,31,'DDD'],[18,38,'DD'],[19,31,'0dd1'],[20,31,'dd1d'],[21,32,'Vdd'],[19,38,'d10'],[20,38,'Y10'],[20,36,'b'],[21,36,'bYYYYY'],[22,36,'VYDVV'],[22,31,'VY']],'Olhos vivos e nariz bulboso usando a rampa de pele, sem mancha vermelha.');
feature('bardo',[[23,32,'DDDJ..DDD'],[24,33,'D700000D'],[25,34,'0ccccd0'],[26,34,'700000D'],[27,35,'DQQQD'],[28,35,'NNIN'],[29,35,'EIN']],'Bigode em dois volumes, boca de canto aberta e barba ruiva completa em torno do queixo.');

plane('arqueiro',[[17,41,47],[18,41,48],[19,41,49],[20,41,49],[21,41,49],[22,41,50],[23,41,51],[24,41,50],[25,41,48],[26,41,48],[27,41,48],[28,42,48],[29,44,48]],'b','Eliminar a boca em U e restabelecer um rosto comprido sem barba.');
feature('arqueiro',[[17,42,'FFFI'],[18,42,'5bbb5'],[19,42,'bFFFb'],[20,42,'0hh10'],[21,42,'bh1hb'],[22,43,'WZZ'],[18,48,'FF'],[19,48,'h1'],[20,48,'Z1'],[20,47,'d'],[21,47,'dbZ'],[22,47,'dbZZ'],[23,47,'bZZZZ'],[24,48,'ZIW'],[24,41,'Z']],'Sobrancelha arqueada e nariz longo; pálpebra e plano da bochecha individualizam o arqueiro.');
feature('arqueiro',[[24,43,'FbbbbbF'],[25,43,'5ffff05'],[26,44,'F0000F'],[27,45,'WZZZ'],[28,46,'bbZ'],[29,45,'WZZ']],'Sorriso oblíquo dentado com lábio e queixo; não há faixa de bigode.');

plane('intendente',[[18,17,27],[19,17,28],[20,17,28],[21,18,28],[22,18,28],[23,19,28],[24,19,28],[25,19,28],[26,20,28],[27,21,28]],'Y','Recompor o rosto largo, preservando as costeletas e o bigode.');
feature('intendente',[[17,18,'777'],[18,17,'7YYY7'],[19,17,'Ydd1Y'],[20,18,'V1Y'],[18,24,'7777'],[19,24,'7007'],[20,24,'Ydd1'],[21,25,'V1Y'],[21,18,'VV'],[22,18,'VV'],[20,22,'a'],[21,21,'aYYY'],[22,21,'YYYYY'],[23,22,'V7VV']],'Olhos cansados de tamanhos distintos, bolsas e nariz baixo volumétrico.');
feature('intendente',[[23,18,'DD77D'],[23,25,'DD7D'],[24,18,'D7DD'],[24,26,'D7D'],[25,22,'D77D'],[26,22,'VYYV'],[27,22,'SVVYS']],'Bigode castanho separado da boca comprimida e do volume do lábio inferior.');

plane('dancarina',[[13,30,34],[14,29,35],[15,29,36],[16,29,36],[17,29,37],[18,29,37],[19,30,36],[20,30,35],[21,31,35],[22,32,34]],'j','Manter a testa, o coque e a expressão leve, recuperando o espaço da face.');
feature('dancarina',[[14,30,'GG'],[15,30,'7jj'],[16,30,'l1l'],[17,30,'jjh'],[14,35,'G'],[16,35,'l1'],[17,34,'k'],[18,34,'kjjj'],[19,35,'aN'],[18,29,'h'],[19,30,'h']],'Dois olhos com pupilas, ponte nasal e ponta definidos, sem traço de maquiagem isolado.');
feature('dancarina',[[19,31,'hjjja'],[20,31,'GjllG'],[21,32,'aGaj'],[22,32,'hjj']],'Sorriso curto com canto elevado, lábio e queixo legíveis no rosto de 64 pixels.');

feature('bardo',[[25,37,'0'],[26,37,'T']],'Separação breve dos dentes e plano quente interno da boca de canto.');
feature('dancarina',[[21,32,'aaa']],'Lábio inferior contínuo em cor de pele, sem ponto escuro solto.');

for(const c of data.characters){
 c.nativeEdits=c.nativeEdits.filter(p=>p.color!==(c.rows[p.y][p.x]==='.'?null:c.palette[c.rows[p.y][p.x]]));
 c.faceNotes=c.id==='sombra'?'Elmo fechado V8 preservado.':'Feições desenhadas diretamente na grade final; estudo baseado no Aseprite do autor.';
}
fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n');
console.log(data.characters.map(c=>({id:c.id,facePixels:c.nativeEdits.length})));
