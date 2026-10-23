# ADR 0088 — A Forja: a pixel art dos geradores passa pelos contratos do projeto

- Estado: aceite
- Data: 2026-10-23
- Secção do dossiê: §01 e §22 (a unidade gráfica, a paleta, o contorno), §58 (os slots), §60 (a paleta como LUT)
- Complementa: ADR 0010 (o import do Aseprite, ainda por fechar), ADR 0084 e 0087 (produção com geração de imagem);
  o [guia de personagens](../art/CHARACTER_PRODUCTION_GUIDE.md) §5 e §6
- Tarefa: [FORJA-01](../backlog/FORJA-01.md)

## Contexto

O dono, a 23/10/2026: quer uma engenharia reversa do PixelLab e uma ferramenta completa no repositório, melhor do
que a original, para que agentes que geram imagens bem (o ChatGPT, por exemplo) trabalhem com pixel art exatamente
como o projeto pede.

O projeto já produz com geração de imagem (V13–V15, cenários nativos) e já registou porque correu mal: figuras
grandes reduzidas não redesenham feições nem agrupamentos (pesquisa de 18/10). Os contratos existem — paleta de
trabalho, contorno preto, clusters de 2 px no cenário, pivô nos pés, 10 fps, alfa binário —, mas cada entrega os
aplicava com scripts próprios (`native_scenery_pixels.py`, extrações da V15) e conferia-os à mão.

Os geradores gerais desenham "estilo pixel art": blocos de tamanho que deriva, bordas suavizadas, ruído e cores a
mais. O PixelLab resolve isto com modelos próprios, pagos, na nuvem, sem conhecer os contratos do Empire.

## Decisão

**Toda a imagem gerada que se queira usar como pixel art do Empire passa pela Forja (`tools/forja/`): o pedido sai
dela, a grade é recuperada e não reduzida, os contratos são aplicados e conferidos por dados, e o resultado sai com
relatório e proveniência.**

1. **Ferramenta fora do jogo.** `tools/forja/` é Python com a biblioteca padrão e o Pillow já fixado em
   `tools/requirements.txt`. Nenhuma dependência nova; nada entra no export do jogo. Os conectores a geradores
   (OpenAI, Gemini, PixelLab) são opcionais, usam `urllib` e só correm com a chave no ambiente.
2. **Os contratos são dados.** `tools/forja/contracts.json` guarda telas, pivôs, contornos, clusters, tetos de cor
   e as tags de animação, cada um com a fonte. Um teste confere-os contra as tabelas da Asset Bible e da Animation
   Bible: se um documento mudar e o outro não, o portão chumba.
3. **Gerar na grade final.** O compilador de prompts pede a grade lógica do contrato e o tamanho de imagem que a
   torna exata; a figura que não cabe na tela é um erro (`clipped`) com a altura certa devolvida ao gerador, nunca
   uma redução.
4. **O ciclo fecha por texto.** O lint devolve achados, a correção da Forja e uma frase em inglês para o gerador; o
   relatório traz o prompt corretivo. Um agente repete sem um humano a traduzir.
5. **Saídas que o projeto já lê.** PNG na tela do contrato, JSON no formato do CLI do Aseprite, `.aseprite` escrito
   pela especificação pública e relido por `tools/aseprite_source.py`, `TileSet` e `SpriteFrames` do Godot.
6. **Para agentes.** A CLI devolve JSON; `python3 -m tools.forja mcp` serve as mesmas ferramentas por MCP, com os
   esquemas derivados da CLI. O `.mcp.json` da raiz liga-o no Claude Code; o guia mostra o Codex.
7. **A Forja não aprova.** A proveniência marca cada saída como adaptação de imagem gerada, revisão manual pendente
   e sem aprovação artística. Escreve onde lhe dizem (`build/forja/`); `art/` continua fora sem pedido do dono.
8. **Portão.** `make forja` corre a prova (pixel art falsa fabricada com verdade conhecida, prancha, Aseprite,
   costura dos tiles, lint) e os testes; entra nos portões estáticos do CI.

## Alternativas consideradas

- **Usar o PixelLab como ferramenta do projeto.** Gera bem na grade, mas é pago, remoto, não lê ficheiros locais e
  não conhece paleta, pivô, cluster ou cadência do Empire. Fica como conector opcional.
- **Instalar unfake, perfectPixel ou Pixel Snapper.** Resolvem só a grade, com dependências novas (Rust, OpenCV,
  numpy) e sem contratos, animação, Aseprite, Godot ou ciclo de correção. As ideias foram estudadas e superadas
  (autocorrelação dos dois eixos, pente de contraste, reta por mínimos quadrados, OKLab).
- **Acrescentar numpy.** Tornaria o processamento mais rápido, mas exige ADR de dependência e uma versão que sirva o
  Python 3.11 do CI. Com o Pillow a fazer o trabalho pesado em C, uma imagem de 1024 px forja-se em menos de um
  segundo.
- **Reduzir figuras grandes e quantizar, como antes.** É o processo que a pesquisa de 18/10 rejeitou.

## Consequências

- Um agente com geração de imagem consegue produzir, conferir e corrigir sprites do Empire sem conhecer os
  documentos de arte de cor: o pedido e o lint trazem-nos.
- As telas da Asset Bible continuam propostas; o contrato da Forja diz o estado de cada uma e muda quando os
  documentos mudarem (o teste obriga).
- Mais um portão estático, de poucos segundos.
- O `.aseprite` escrito foi conferido como ficheiro; abrir no aplicativo continua por registar. Os conectores
  seguem as referências de 23/10/2026 e não foram chamados com chaves reais.
- Se a decisão for revertida: apagar `tools/forja/`, o `.mcp.json`, o alvo `forja` do Makefile e o passo do CI. Nada
  do jogo depende dela.
