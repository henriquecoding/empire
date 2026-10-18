const fs=require('fs'),path=require('path');
const file=path.join(__dirname,'native-pixels.json'),data=JSON.parse(fs.readFileSync(file));
for(const c of data.characters)c.nativeEdits=[];
function set(id,points,symbol,reason){
 const c=data.characters.find(c=>c.id===id),color=c.palette[symbol];
 if(!color)throw Error('Cor inexistente');
 for(const [x,y] of points){const previous=c.nativeEdits.find(p=>p.x===x&&p.y===y);if(previous){previous.color=color;previous.reason=reason;}else c.nativeEdits.push({x,y,color,reason});}
}
set('rei',[[46,17]],'0','Pupila próxima com dois pixels de altura; conservar a pálpebra pesada.');
set('escudeiro',[[39,22]],'0','Pupila contínua e visível no olho exposto sob o elmo.');
set('escudeiro',[[40,21]],'Y','Separar a pupila do plano lateral do rosto.');
set('nia',[[32,21],[33,21],[32,22]],'d','Esclera próxima em um pequeno grupo legível.');
set('nia',[[33,22]],'1','Pupila próxima de um pixel, contida na abertura do olho.');
set('nia',[[34,22],[40,21]],'Q','Recuperar o plano de pele entre olho, nariz e cabelo.');
set('nia',[[39,21],[39,22]],'d','Esclera distante abreviada para a vista de três quartos.');
set('nia',[[40,22]],'1','Pupila distante alinhada com a direção do olhar.');
set('nia',[[32,24],[33,25],[37,25],[35,26]],'3','Recompor o sorriso oblíquo no lugar da mancha de boca circular.');
set('nia',[[33,25],[34,25],[35,25],[36,25]],'d','Grupo único de dentes do sorriso confiante.');
set('nia',[[32,25],[33,26],[34,26],[35,26],[36,26]],'3','Limite inferior contínuo do sorriso; evitar leitura de boca circular.');
set('nia',[[34,27],[35,27]],'N','Plano inferior do lábio e da bochecha sem contorno excessivo.');
set('bardo',[[32,20],[32,21],[39,19]],'1','Pupilas de um a dois pixels; conservar a expressão de canto.');
set('bardo',[[38,19]],'d','Olho distante legível abaixo da sobrancelha.');
set('bardo',[[36,20],[37,20],[38,20],[39,20],[36,21],[37,21],[38,21],[39,21],[40,21]],'Y','Nariz na mesma rampa de pele das bochechas; manter volume sem mancha vermelha exclusiva.');
set('bardo',[[37,22],[38,22],[39,22],[40,22],[41,22]],'V','Sombra inferior do nariz usando a rampa normal de pele.');
set('bardo',[[37,20]],'b','Luz curta no plano do nariz.');
set('bardo',[[33,23],[34,23],[35,23],[38,23],[39,23],[40,23]],'D','Bigode ruivo escuro em dois grupos; barba preservada.');
set('arqueiro',[[44,21]],'1','Pupila próxima vertical e contida na esclera.');
set('arqueiro',[[45,21]],'b','Pele separa olho e nariz comprido.');
set('arqueiro',[[43,25],[44,26],[45,26],[46,26],[47,25]],'F','Sorriso contido de canto, individualizado em relação ao rei.');
set('intendente',[[26,20]],'1','Pupila próxima do olhar impaciente.');
set('intendente',[[19,19]],'Y','Reduzir a abertura distante a uma esclera e uma pupila.');
set('intendente',[[20,21],[21,21],[22,21]],'Y','Nariz baixo com a cor local normal do rosto.');
set('intendente',[[20,22],[21,22],[22,22]],'V','Sombra do nariz na rampa de pele, conservando o bigode.');
set('dancarina',[[35,16]],'l','Esclera distante de um pixel.');
set('dancarina',[[36,16]],'1','Pupila distante de um pixel, sem aumentar o olho.');
set('dancarina',[[34,20],[35,19]],'G','Pequeno sorriso de atenção no rosto completo.');
fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n');
console.log(data.characters.map(c=>({id:c.id,edits:c.nativeEdits.length})));
