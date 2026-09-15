# 05 — Loop · O dia, a noite e A Podridão

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Um dia dura 360 segundos reais. Cada fase tem uma função de jogo distinta e um estado visual inequívoco — cor da luz ambiente, som, e comportamento das tropas. O jogador nunca precisa de olhar para um relógio.

| Fase | Duração | Função | Estado das tropas | Luz ambiente |
| --- | --- | --- | --- | --- |
| Alvorada | 15 s | Sino. A Podridão retrai-se. Perdas são contadas. | Saem dos postos | Âmbar rasante |
| Manhã | 85 s | Recrutar, expandir, colher, explorar | Trabalho livre | Neutra |
| Meio-dia | 40 s | Fortalezas inimigas detetam presença. Risco de contra-ataque. | Trabalho livre | Alta, dura |
| Tarde | 85 s | Última janela de construção. Preços de mercenários sobem 25%. | Trabalho livre | Dourada |
| Crepúsculo | 30 s | A Podridão nasce na borda do mapa. Aviso sonoro. | Recolha aos postos | Vermelha baixa |
| Noite | 105 s | Defesa. Nada se constrói exceto pelo construtor evoluído. | Posto de cerco | Castanho profundo · 32° · 0,22 · 0,16 |


> **Revisto na Parte XIII**
>
> A massa, a velocidade e a natureza desta entidade foram revistas na §74: A Podridão passa a trazer uma candeia e a comer os mortos que ficam no campo. A cor da noite está decidida: a linha da Noite nesta tabela já foi corrigida para castanho, e a razão está na §80 e na ADR 0011 (Q-037, fechada a 13/09/2026). A caixa "Alimentar" ganhou voz e preço na §75.

## A Podridão — especificação completa

A tua ideia de "uma sombra que vai de encontro ao império invocando inimigos até chegar" é a mecânica mais original da lista. Merece ser um sistema de primeira classe, não um spawner disfarçado.

- **Natureza** — Entidade única com posição em X, largura, e uma massa que funciona como orçamento de invocação
- **Nascimento** — No crepúsculo, na borda mais distante do lado ameaçado (ou nos dois lados a partir do dia 12)
- **Velocidade** — v = 14 + 0,9 × dia px/s no plano do jogo; abranda 40% ao atravessar terreno consagrado
- **Massa** — M = 60 + 26 × dia + 40 × fortalezas_conquistadas — substituída pela §74: M = 40 + 18 × dia + 30 × fortalezas + 22 × amargueiros + 45 × amargueiros_nomeados + 8 × min(recusas_nos_últimos_5_dias, 5). O rot.csv traz os termos novos.
- **Invocação** — Gasta massa a cada 4–7 s a criar criaturas da tabela do bioma; a criatura nasce dentro da mancha
- **Rasto** — Deixa terreno apodrecido: plantações destruídas, animais mortos, movimento −20% até ao dia seguinte
- **Morte** — Não pode ser morta em campo aberto. Recua ao amanhecer. Só é impedida.

### Como o jogador interage com ela

- Ver — a mancha é visível no horizonte durante o crepúsculo. O jogador consegue estimar a que horas chega, e isso é uma decisão: avançar mais uma plantação ou recuar já?
- Atrasar — fogueiras, barris de fogo e terreno consagrado abrandam-na. Cada segundo de atraso é uma vaga de invocação a menos.
- Desviar — pontes e o nível subterrâneo permitem que ela passe por baixo ou por cima do teu império se o caminho de superfície estiver selado. Isto é uma tática avançada, não um bug.
- Alimentar — deixar sacrifícios (animais, tropas fracas, ouro) reduz a massa. Sinistro, eficaz, e mecanicamente honesto: transformas economia em segurança.

> **Porque é que isto é melhor do que ondas**
>
> Uma onda é um número que aparece. Uma mancha que avança é informação espacial contínua: o jogador olha para o horizonte e sabe quanto tempo tem. O Kingdom tem de te dizer que a noite chegou; o teu jogo mostra-a a chegar. Esta única diferença gera tensão durante 135 segundos por dia, todos os dias — e é o teu GIF de marketing (§36).

## Os dois verbos — e só dois

**Verbo 1 — Largar moeda** — Recrutar, construir, melhorar, pagar, alimentar, subornar. O contexto define o efeito. Toda a economia passa por aqui. É o verbo do Kingdom, herdado inteiro.

Trocar de personagem controlado (rei ↔ classe), montar, entrar e sair da camada subterrânea, subir numa criatura enorme. Um botão, sempre contextual, sempre o mesmo botão.

> **Regra inegociável**
>
> Se aparecer um terceiro verbo, uma mecânica está mal desenhada. O menu de gestão do rei conta como Verbo 2 — assumes o rei, o menu é o corpo dele. Isto mantém o jogo jogável em comando e no Steam Deck sem UI de rato (§24, §26).
