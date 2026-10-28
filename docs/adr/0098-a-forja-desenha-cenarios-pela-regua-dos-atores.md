# ADR 0098 — A Forja desenha cenários e construções pela régua dos atores

- Estado: aceite
- Data: 2026-10-28
- Secção do dossiê: §01, §11, §21 e §22 (a unidade gráfica, as faixas, os segmentos, o cenário)
- Complementa: ADR 0088 (a Forja), 0089 (pede uma vez e mede), 0093 (o mestre aprovado), 0094 (a perda e a autoridade)
  e 0095; a Asset Bible e os contratos raster não mudam
- Tarefa: [FORJA-11](../backlog/FORJA-11.md)
- Origem: o relatório do dono *A construção de um mundo em pixel art* (revisão 2, 28/10) e o pedido: *«transformar a
  forja também em uma ferramenta/estrutura pronta para desenvolver cenários e construções […] e como pegar uma
  referencia e adequar ela corretamente para personagens […] 64x64 e 80x80»*;
  [pesquisa e piloto](../art/research/2026-10-28-forja-cenarios/README.md)

## Contexto

A Forja nasceu para personagens. Num edifício faltava-lhe quase tudo: o contrato `building` não tem tela, e o
compilador dava-lhe 64×64; o prompt falava de rosto, roupa, pose e «perfil estrito virado para a direita», e um
assunto com «fachada frontal» era um conflito de câmara; o contorno de 2 px de ecrã do cenário chegava ao gerador como
«2 pixels lógicos» (4 px); a limpeza tirava o céu de um plano opaco; e não havia como dizer, nem conferir, que a porta
deixa passar o rei, que a casa assenta no chão, que a chaminé continua ligada ou que o estado `damaged` só mudou o
telhado. Faltava também a pergunta prévia: a que tamanho fica uma referência quando os atores têm 50–65 px visíveis e o
cenário se desenha em células de 2 px.

As três pesquisas de 28/10 (167 fontes, em `pesquisa/`) dão a medida: em vista lateral, portas comuns a 1,0–1,2× o ator
e públicas a 1,4–1,9×; comprime-se o número de vãos e pisos, não a porta; não se reduz uma referência, redesenha-se; um
tamanho de célula por plano; e as emendas provam-se pela topologia, não pelo contraste médio.

## Decisão

1. **A régua lê-se do jogo.** `regua.py` tira a altura e a largura de cada ator do manifesto V15 (`body_bounds`), a
   linha do chão e o nível inferior do manifesto das composições do dono, o horizonte da `band.gd`, a janela do
   `project.godot`, e a fase da grade de 2 px dos planos já exportados (todos em (0, 0)). Nenhum destes números se
   escreve à mão. As métricas de arquitetura são fatores sobre a régua, com origem, em `tools/forja/scenery.json`; as
   propostas esperam pelo dono (Q-295). Sem a textura (checkout sem LFS), a silhueta é a caixa do corpo, e di-lo.
2. **Uma cena tem contrato.** `forja.scene/1`: o asset (`building`, `wall_segment`, `prop`, `tree`, `terrain_strip`,
   `plane_far`, `plane_mid`, `foreground`) e o contrato raster dele, a **extensão explícita** em px de ecrã, a projeção
   (elevação lateral, separada da orientação dos atores), os vãos medidos pela régua (uma porta abaixo do mínimo é
   erro; a soleira assenta no chão), os sinais de identidade com nome e região, os materiais, os estados e condições e o
   que cada estado pode mudar, e as referências em papéis que dizem o que transportam e o que não autorizam copiar
   (`asset_concept`, `composition`, `style_master`, `material`, `junction`, `actor_ruler`).
3. **O pedido fala arquitetura.** O prompt de cena diz a projeção, o chão, a régua em pixels lógicos, os vãos em
   coordenadas, os sinais, a gramática de cada material, o telhado, o contorno da silhueta (1 pixel lógico = os 2 px da
   Asset Bible) e cada linha diz a origem. Vai com a régua em imagem: as silhuetas reais do ator mais alto e do mais
   baixo, a altura da porta e os vãos, no tamanho exato do pedido. `forja cena`, e `plan`/`auto` com `--scene`, planeiam
   sem rede para os três geradores; o PixelLab desenha nas células, e acima do modelo o plano falha e propõe a partição.
4. **Sem tela inventada.** `prompts.geometry` recusa um contrato sem tela e sem extensão dita, em vez de 64×64.
   Um plano opaco forja-se com `--bg keep`. A tela, o pivô, o fundo de cada gerador e a origem da cena chegam ao
   `forge` e ao `auto` pelo `expect`: com a grade pedida medida, a peça fica onde ela a pôs, sem recentrar.
5. **A estrutura confere-se à parte.** `forja estrutura` mede, sem nota global: extensão, grade, base no chão, cada vão
   (escuro, aceso ou vazado; a altura livre até à soleira contra a régua), os sinais (presentes; iguais ao mestre quando
   há mestre), a repetição e os conectores (o degrau da emenda contra o maior entre colunas interiores), e os estados
   (nada muda fora das zonas declaradas). O que não se mediu fica `not_evaluated`, também um estado declarado sem
   imagem; a aprovação fica `pending`.
6. **As emendas Wang provam-se.** `forja tileset` confere os 64+64 pares compatíveis pela topologia da aresta e os
   cachos partidos nas emendas e nos 512 cruzamentos 2×2.
7. **A prova é uma cena.** `forja montagem` põe a peça no mundo 1280×720 pela sua âncora (chão, horizonte ou fundo do
   ecrã; repetida em x quando o contrato o pede) e na fase da grade, com os
   atores reais, de dia e numa noite aproximada (a modulação da fase do `clock.csv`, sem luzes); `forja escala` leva uma
   referência à régua por marcos funcionais, diz se os marcos concordam, compara o pixel aparente com a célula e mostra a
   referência na escala do jogo, ao lado dos atores.

## Alternativas consideradas

- **Medidas de arquitetura fixas em px.** Partiam-se no dia em que o elenco mudasse; um fator sobre a régua lida segue o
  manifesto.
- **Escolher a escala de uma referência pelo tamanho da imagem ou pela grade dela.** A grade de uma imagem gerada não
  diz a que tamanho ficam os atores; e a referência do pacote mistura escalas (a porta da casa contra os barris da
  oficina). O marco funcional, conferido por outro, é a medida.
- **Uma receita de cena completa que gera a `.tscn`** (B §7a). A posição dos sítios e das obras é da simulação
  (`PlaneContract`); a Forja produz e confere peças com origem e âncora. A receita fica como proposta.
- **Pôr a noite nas imagens geradas.** Uma noite gerada muda cada cor e a identidade cromática (C §6); a noite é do
  motor (ADR 0011, 0048).
- **Dependências (unfake, proper-pixel-art, um rótulo de componentes em NumPy).** A régua, o contrato e as verificações
  cabem na biblioteca padrão e no Pillow (regra 8).

## Consequências

- Módulos novos: `regua.py`, `scene.py`, `scene_prompt.py`, `scene_plan.py`, `estrutura.py`, `montagem.py`,
  `cmd_cenario.py` e os dados `scenery.json`. Comandos novos: `regua`, `cena`, `estrutura`, `montagem`, `escala`
  (também por MCP); `plan` e `auto` ganham `--scene`; `tileset` devolve `pairs` e `junctions`.
- **Muda de comportamento:** um pedido `--kind building|prop|parallax_*|foreground` sem extensão é recusado (antes, 64×64
  calado); o prompt de um contrato com cluster 2 diz «1-logical-pixel outline» (antes «2»); `forja tileset` pode
  devolver `ok: false` quando uma emenda falha; o adaptador do PixelLab regista o hash `ae1f76eb…` da especificação
  (só mudou uma descrição; 63/63 conformes).
- A Forja passa a **ler** `art/export/royals/manifest.json`, `art/export/scenery_owner/manifest.json`, `src/sim/band.gd`,
  `project.godot` e `data/source/clock.csv`; continua a não escrever fora de onde lhe dizem.
- Aprovar continua a ser do dono, para a imagem exata (ADR 0093). As métricas, a fase do nível inferior, o contorno do
  cenário e a cadência do parallax ficam como perguntas (Q-295–Q-300).
