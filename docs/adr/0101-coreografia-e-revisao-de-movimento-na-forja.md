# ADR 0101 — coreografia e revisão de movimento na Forja

Data: 29/10/2026 · Estado: aceite para ferramentas, por pedido do dono.

## Contexto

O dono pediu implementar a pesquisa sobre poses, animações e cenários. Os contratos,
jobs duráveis, referências, escala e Aseprite existentes continuam autoritativos.
Uma imagem válida não demonstra apoio, contacto com equipamento ou continuidade.

## Decisão

1. `forja.pose/1` declara 18 articulações em pixels nativos, sockets, apoios,
   pontos inferidos/ocultos, ordem de partes e regiões por comportamento.
2. `forja.clip/1` conserva identidade por hash, tela, ação, tempos, raiz por quadro
   e loop do contrato. Os roteiros idle/walk/attack/die são estudos editáveis.
3. PixelLab usa adaptador próprio para skeleton-v3 ou text-v3, dentro dos limites
   verificados no OpenAPI. Skeleton-v3 aceita cinco quadros e tela de 80 pixels;
   text-v3 recusa contagens ímpares antes da rede. Não redimensionar nem completar
   a sequência com cópias para satisfazer uma rota incompatível.
4. Envio continua explícito, limitado e persistente. Uma pasta representa uma
   intenção: repetir o comando retoma o job, sem repetir um POST de resultado
   desconhecido. Só `last_response.images`, pela ordem, fornece quadros.
5. Revisão mede apoio no mundo (`root_px + ponto`), contactos, regiões preservadas
   e extremos de transições. Pontos inferidos ficam pendentes; nada prova sozinho
   que o raster acompanha as anotações. A aprovação do dono continua em `refs`.
6. Componentes opcionais de `forja.scene/1` têm região, âncora, camada, papel e
   quadros próprios. A composição parte de uma base limpa e comprova que nenhum
   pixel fora das regiões animadas mudou. Interações declaradas têm evidência separada.
7. O pacote inclui PNGs originais, referência, clip portável, atlas, Aseprite,
   SpriteFrames e revisão. O Aseprite separa corpo e guia oculto; não inventa
   camadas anatómicas a partir de um retorno achatado. Os sockets viram slices.
8. A bancada estática `/forja/` lê arquivos no navegador e exporta observações.
   O hash dos bytes carregados e de cada quadro liga a revisão à versão exata.
   A página não recebe chaves de API nem inicia gerações.
9. O benchmark agrupa tarefa e método, inclui rejeições e jobs sem pacote,
   distingue gasto desconhecido de zero e regista correção humana separadamente.

## Consequências e limites

Sem novas dependências, alterações de balanceamento ou instalação de arte no jogo.
Sem geração paga nesta implementação. Não há detector automático de anatomia,
editor visual de poses, rigs 3D ou aprovação artística automática. A aplicação
das poses aos pixels, a atuação e a leitura com atores reais continuam trabalho
de produção e revisão. Métodos experimentais não viram dependências sem piloto.

## Evidência e uso

[FORJA-15](../backlog/FORJA-15.md), [guia operacional](../art/FORJA_MOVIMENTO.md),
testes `test_choreography`, `test_clip_delivery`, `test_scene_motion`,
`test_motion_benchmark`, `tests/web/forja.test.mjs` e `tests/web/forja-ui.mjs`.

API consultada em 29/10/2026: [OpenAPI PixelLab](https://api.pixellab.ai/v2/openapi.json).
O hash da especificação fica no descritor do pedido. Continuidade do
[Aseprite](0100-a-forja-fala-aseprite-provado-contra-o-aplicativo.md) e dos
[cenários por régua](0098-a-forja-desenha-cenarios-pela-regua-dos-atores.md), quando aplicável.
