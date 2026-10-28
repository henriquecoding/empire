# ADR 0097 — A Forja observa a imagem exata, edita ao pixel e parte da grade da própria prancha

Data: 28/10/2026. Estado: decisão de ferramenta, implementada no FORJA-10. Não aprova arte nem muda contratos de
runtime; as decisões de desenho dos pilotos ficam em revisão (Q-292–Q-294).

## Contexto

O handoff de 28/10 (FORJA-09, ADR 0096) deixou três lacunas por fechar: o núcleo mede regiões anotadas mas não vê
sozinho uma arma, um dedo ou uma expressão (P0); refinar um rosto ou uma corda pedia outra geração global, que perde
a identidade (P1); e faltava escolher um caminho que produza a grade exigida e permita reparos locais (P1). No mesmo
dia Henrique viu o arco da prancha e decidiu: «A corda está atrás do personagem, a arma está mal feita».

Medido no recorte de autoridade, e não na imagem regerada de 1254 px da entrega anterior (onde a grade estimada
tinha confiança 0,429), a prancha tem grade própria: período 6,04/6,48/6,25 px, confiança 0,96/0,94/0,95 para Rei,
Escudeiro e Arqueiro. Recuperada nessa grade, sem reduzir, a figura dá 81×77, 45×48 e 53×64.

## Decisão

1. **Revisão visual `forja.visual_review/1`** (`visual_review.py`, `forja visual`). Quem tem visão (o agente ou
   um adaptador autorizado) regista o que viu numa imagem presa ao hash dos pixels, na fase `reference` (o recorte,
   antes do pedido) e `candidate` (depois do retorno): regiões e âncoras dentro da tela, cada uma observada, inferida
   ou tapada (com quem tapa); achados com categoria, caixa, evidência, certeza e ação. O validador recusa outra
   imagem, coordenadas fora da tela, uma parte tapada dada como ausente, a troca da classe declarada pelo dono e um
   reparo declarado na referência. Um defeito certo sem decisão em `reference_issues` bloqueia; o incerto fica
   pendente e visível, nunca `pass`. A revisão alimenta o que existe, não o substitui: a da referência entra em
   todas as rotas com `--fidelity` (`visual_review.reference` no contrato); a do candidato entra no `forja fidelity
   --visual-review` e dá os `reference_issue_reviews` e a observação do `forja equip`, cuja geometria continua a
   decidir a corda e as pontas. A identidade continua a pedir uma revisão de pessoa ou a aprovação do dono. A
   motivação está medida: os modelos de visão erram em relações finas de posição e contacto (Rahmanzadehgervi et
   al., arXiv 2407.06581); as marcas numeradas (`--marks-out`) seguem o Set-of-Mark (Yang et al., arXiv 2310.11441)
   para quem revê conferir onde cada coisa foi apontada.
2. **Patch nativo `forja.pixel_patch/1`** (`pixel_patch.py`, `forja patch`). Pintar pixels, reescrever uma região por
   linhas e legenda, ou mover um agrupamento (ou o bloco inteiro) só numa máscara autorizada, com regiões protegidas
   e pinos conferidos na base. Recusa outra imagem ou tela, fora da tela, fora da máscara, protegido, alfa intermédio
   (no pedido e na base) e cor fora da paleta sem `allow_new_colors`. Não há blur, reamostragem nem limpeza de pixels
   isolados. O exterior é conferido byte a byte depois de aplicar; grava antes/depois/diferença e os dois hashes, e
   a observação da imagem anterior deixa de valer. A tela fica exata por construção; a arte não fica aprovada.
3. **Tons por limiar** (`tones.py`). Numa fonte com compressão, as cores juntam-se pela distância OKLab, sem teto;
   um tom pequeno e longe de tudo (uma pupila, um brilho) fica; a cor do projeto só substitui um tom indistinguível
   dele. A quantização para a paleta de trabalho trocava o vinho por castanho e manchava a pele dos três: as rampas
   saem como proposta (`paleta-pilotos-proposta.gpl`), à espera do dono (Q-289, Q-293).
4. **Caminho principal dos pilotos**: quando a autoridade já é pixel art numa grade mensurável, recuperar essa grade
   (`snap` no recorte), limpar, organizar tons e resolver orçamento e reparos com patches nativos, cada etapa com o
   seu hash (`pilotos.py`, reproduzível no `make forja`). A geração nativa (`create-image-*`) e a conversão
   (`image-to-pixelart`) ficam para fontes que não são pixel art ou para poses novas, e não foram executadas
   (sem credencial). Uma redução não é este caminho e não vira autoridade.
5. **Conversão nativa com moldura**: a especificação pública (sha256 `b6dd212c…8834`, reconferida) pede a mesma
   proporção na entrada e na saída e recomenda a saída a 1/4 da entrada; a fonte ganha moldura (sem reamostrar) até
   à proporção da saída, com a figura na caixa útil, e o plano regista `source_frame`. Fora de 3–5× fica uma nota:
   a interface do fornecedor diz que redimensiona em segundo plano.

## Consequências e limites

Os três candidatos (Rei 80×80, Escudeiro 64×64, Arqueiro de tropa 64×64) cumprem o contrato do runtime, ficam dentro
da caixa útil, com o pivô nos pés e sem corte, e os pinos de 1 px estão verificados. A corda do arqueiro passa a
geometria (uma, fina, reta, ligada à madeira nas duas pontas); a pega, debaixo da mão, é inferida e deixa
`bow_nocks` inconclusivo — uma região ou âncora inferida entra com incerteza alta e nunca dá pass. Isto não é aprovação: a
identidade e o mestre são do dono, e as decisões de orçamento (capa do Rei 4 px para dentro com margem esquerda 0;
três linhas do arqueiro) e a corda em dois tons estão em Q-292–Q-294. A revisão visual foi escrita pelo agente: o
transporte simulado testa o contrato, não a qualidade de uma visão, e nenhuma taxa de acerto foi medida. O
`.aseprite` relê-se igual ao PNG com o leitor do projeto; não foi aberto no Aseprite. Não há dependência nova nem
edição de art/, audio/, src/, scenes/ ou data/.
