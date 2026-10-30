# ADR 0104 — A Forja gera e revê animações nativas

- Estado: aceite, implementação dos pontos pendentes pedida por Henrique
- Data: 2026-10-30
- Tarefa: [FORJA-18](../backlog/FORJA-18.md)
- Complementa ADRs 0097, 0100, 0101, 0102 e 0103; sem dependências novas.

## Problema

A auditoria fechou integridade de pranchas e prévias, mas faltavam o pedido aos endpoints de animação
e o fecho da sequência completa. Um PNG de tamanho correto não demonstra autoria nativa, e a revisão
de uma pose não cobre alterações de anatomia, expressão, equipamento ou tempo nas restantes.

## Decisão

1. `anim-plan` compila offline o mestre exato, conceito/função/tela do personagem, consulta atual das
   regras, origem/perdas, plano das bibles e pedido. `animar` recompila e compara o plano antes da rede.
   Os adaptadores são `animate-with-text-v3` e `animate-with-skeleton-v3`, segundo o OpenAPI público.
   Texto: 4–16 quadros pares e limite de área. Esqueleto: 3–15 poses, 18 pontos por pose e na pose
   inicial, coordenadas finitas/normalizadas; observador e hash da imagem inicial obrigatórios.
   Não se inventam esqueletos, nem se altera a contagem do runtime para contornar limites do fornecedor.
2. O índice da pasta liga plano a job antes do POST; jobs/budget existentes conservam o teto e a
   retoma por GET. Timeout ou resposta ambígua não autoriza repetir o POST. A lista `images` é ordenada
   e conserva repetições legítimas; referências e prévias do envelope não contam como quadros.
   Contagem/tela/formato incorretos conservam os brutos como diagnóstico, sem cortar ou redimensionar.
3. PNGs nativos, atlas, JSON, Aseprite e prévias partilham pixels e timeline. `anim-patch` usa os patches
   por máscara existentes em quadros explícitos, numa pasta nova. Conserva os antecessores, quadros
   restantes, cadência e pivô; não limpa, reamostra ou regenera o corpo. Nenhum destes passos aprova arte.
4. A identidade da sequência inclui pixels ordenados, durações, tags/direções, pivô, tela, holds,
   personagem, referência, regras e cadeia completa. `animacao` oferece prova e ficha pendente;
   `entrega-anim` exige raster, runtime, origem sem redução, autoridade atual e evidência de todos os
   quadros/ações. Tem de haver observação de anatomia, apoio, volume, rosto, mãos/pega, materiais,
   equipamento, articulação, chaves, transições e fecho do ciclo. Divergências nos exports bloqueiam.
5. Perdas por quadro exigem resolução identificada na cadeia e sequência exatas: reparo provado
   nos pixels atuais ou exceção atribuída ao dono. Patches de coordenadas idênticas conservam a
   posição da ocorrência; outra transformação não presume essa correspondência. Reduções herdadas
   nunca passam por uma exceção de perda. Perdas críticas de um mestre ancestral sem prova individual
   mantêm uma prancha pendente. A geração de poses não mede identidade por igualdade de pixels.
6. `ready_for_review` significa revisão documentada completa, não aprovação. `--release` exige
   registo separado de Henrique para o hash exato da sequência. Não há comando para fabricar essa
   aprovação. Uma alteração invalida os registos anteriores. Integração no jogo continua etapa distinta.

## Validação e limites

Testes com transporte falso cobrem contratos, ordem, falhas, retoma, orçamento, exports, reparos e fecho.
O recorte factual do OpenAPI e o hash da fonte estão em `tools/forja/tests/fixtures/pixellab-animation-openapi.json`.
Não houve geração paga, aprovação de novos sprites ou alteração de arte de runtime.

O programa valida declarações e evidências; não certifica por visão a qualidade de mãos, atuação ou peso.
`hit` de dois quadros não cabe nestes endpoints: usar desenho nativo/prancha com origem e revisão, não
descartar quadros de uma geração maior. O [guia](../art/FORJA_ANIMATION.md) dá o fluxo e os schemas.
