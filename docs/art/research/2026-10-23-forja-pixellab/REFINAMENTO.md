# Forja — da auditoria a um fluxo que preserva a arte

23/10/2026. Continuação do PR #117 (`68ed1c8`) e da auditoria do PR #118
(`9ee6b4c`). O objetivo desta entrega é corrigir os caminhos de produção que
falhavam e tornar a revisão verificável. Não recuperámos pesos privados do
PixelLab nem executámos treino ou geração paga.

## O que a nova pesquisa mudou

A [OpenAPI pública](https://api.pixellab.ai/v2/openapi.json) distingue modelos
com capacidades incompatíveis. Pixflux aceita lados até 400; Bitforge até 200;
Pixen até 768, múltiplos de quatro e área até 512². A transparência do Pixen
limita a área a 256². Pixen não recebe `init_image`, `color_image` ou `shading`.
O conector agora valida estas diferenças antes da autenticação e do envio.

O endpoint `animate-with-text-v3` parte de um quadro nativo e admite último
quadro opcional; exige contagem par entre 4 e 16, lados até 256 e orçamento de
524288 pixels por sequência. A Forja oferece este caminho diretamente,
preserva as respostas e verifica tamanho, quantidade e primeiro quadro.

A documentação [MCP do PixelLab](https://api.pixellab.ai/mcp/docs) descreve
`pixelart_workbench`: inspeção, lint, comparação e reparação, além de operações
de animação. Portanto, a afirmação anterior de que o PixelLab não critica
resultados era incorreta. A especialização da Forja está nos contratos,
proveniência e integrações locais do Empire.

O [Gemini](https://ai.google.dev/gemini-api/docs/image-generation) não usa
tamanhos arbitrários equivalentes aos pedidos OpenAI. O plano automático
agora usa tela quadrada 2K, grade inteira centralizada e margens explícitas.
O recorte fica no `expect.json`; as guias refletem a mesma geometria e são
anexadas. A resposta tem de medir 2048×2048 antes do recorte; não há esticamento
nem inferência de uma nova escala a partir de um tamanho inesperado.

Os projetos [perfectPixel](https://github.com/theamusing/perfectPixel) e
[Pixel Snapper](https://github.com/Hugo-Dz/spritefusion-pixel-snapper) continuam
a ser referências públicas úteis para recuperação de grade. A comparação
anterior descreve algoritmos; não foi executado um benchmark comum contra
essas implementações. Os 150 casos sintéticos próprios não demonstram
superioridade visual nem reconstrução de feições perdidas.

## Auditoria fechada por comportamento

As identificações F01–F09 vêm da
[auditoria independente](../2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md).
Os registros originais permanecem como evidência histórica do PR #117.

| Achado | Correção implementada | Evidência de regressão |
| --- | --- | --- |
| F01 — POST repetido após falha incerta | Sem reenvio automático de POST em 5xx genérico ou falha de transporte; limites e Retry-After controlados | `test_reliability` |
| F02 — tamanho/referência PixelLab incompatíveis | Pedido nativo, validação por modelo e referência com tela conferida; opção incompatível causa erro | `test_reliability`, `test_generation_workflow` |
| F03 — geometria Gemini e guias ausentes | Plano 2K com padding registrado, guias transmitidas e validação de tamanho real | `test_generation_workflow` |
| F04 — azul apagado na edição | Alpha verdadeiro; máscara validada; tamanho inesperado recusado | `test_preservation`: round-trip azul, magenta e verde |
| F05 — pixels isolados/furos apagados | `remove_orphans` e `fill_holes` explícitos e desligados por padrão no pipeline | `test_preservation`: preservação e idempotência com ruído desligado |
| F06 — salto transformado em pose parada | Com layout e escala conhecidos, preserva a origem de cada célula; estabilização de pés é escolha explícita | `test_preservation`: salto mantém 4 pixels de deslocamento |
| F07 — contar quadros confundido com aceitar movimento | `ok` estrutural separado de `ready`; revisão por tag detecta sequência estática, translação rígida e salto na emenda | `test_quality`; `auto` considera avisos e guarda a melhor tentativa |
| F08 — direção ignorada no Godot | Ordem e durações de forward, reverse, pingpong e pingpong_reverse preservadas | `test_preservation`, teste de recursos no motor |
| F09 — polling sem término/retomada | Prazo monotônico, número máximo de consultas, estados terminais e recibo salvo antes de consultar | `test_generation_workflow`, `test_native_animation` |

Também foram corrigidos problemas que estas nove sondas não cobriam:

- grade explícita 1× percorre cada pixel, sem reestimar o período;
- recorte de células conserva armas de um pixel;
- células ausentes mantêm seus índices e não deslocam tags seguintes;
- pranchas vazias devolvem um diagnóstico; faltas, extras e clipping bloqueiam exportações para o jogo;
- normalização pela altura foi retirada porque deforma poses;
- prompt de cenário pede um pixel lógico de contorno antes de ampliar o cluster;
- MCP valida tipos, rejeita argumentos desconhecidos, sobrevive a mensagens
  inválidas e devolve `structuredContent` e `isError` coerentes;
- a prévia aceita listas de arquivos e o botão de quadro cancela o temporizador;
- pastas com recibos anteriores não são sobrescritas pelo modo automático.

## Revisão que mede sem redesenhar

`review` lê quadros nativos e compara tags separadamente. Mede rasters e formas
distintos, diferenças entre vizinhos, candidatos a cintilação e continuidade
da emenda. Com referência, devolve diferenças de pixels e IoU de silhueta.
`--protected-box` é uma exigência explícita de região imóvel: qualquer mudança
é erro. Não é reconhecimento de rosto nem reconstrução automática da cara.

Uma pausa pode usar [cels ligados](https://www.aseprite.org/docs/linked-cels/)
ou desenhos repetidos intencionalmente. Por isso duplicação é aviso revisável,
não motivo para inventar poses. Uma sequência sem avisos também não prova
boa anatomia, expressão, peso ou personalidade. `artistic_approval` continua
falso; essa decisão pertence ao autor.

Foi executada a mesma revisão nos oito `.aseprite` V15 existentes:
**822 quadros, 104 tags**, fontes com hashes preservados, sem geração ou escrita
em `art/`. Nenhuma tag acionou os três avisos de movimento atuais. As medidas
estão em [revisao-v15.json](revisao-v15.json), reproduzidas por
[review_cast.py](review_cast.py). Este resultado mostra compatibilidade com o
acervo e os limites do detector; não reaprova artisticamente esses assets.

## Como usar agora

O [guia atualizado](../../FORJA.md) contém os comandos completos. O percurso
recomendado é preparar um plano sem chave, conferir referências nativas e
gerar com um número máximo de tentativas. Para animação PixelLab, usar
`animate-native` a partir de um quadro revisto. Se a espera for interrompida,
`job --job-id …` consulta o trabalho já existente sem um novo POST.

Os recibos ficam no disco local da execução; o processo de geração remota
continua no fornecedor. Retomar baixa as imagens e os metadados, mas não
implica revisão artística nem substitui automaticamente um asset do jogo.
Os limites de submissões não são uma estimativa de preço: custos e quotas
dependem da conta e do endpoint.

## Verificação e limites da entrega

Os testes novos foram executados antes das correções para reproduzir as falhas.
`make forja` executa a prova sintética e toda a suíte Python; `make portoes`
também confere inventários, conteúdo, formato e manifestos. `./run_tests.sh`
verifica o jogo no Godot fixado. Os resultados finais ficam registrados no PR.

- Conectores testados com transporte simulado, incluindo erro remoto, job
  concluído vazio, corpo de erro com segredo, limite de polling e checkpoint.
- `.aseprite` conferido pelo leitor existente; recursos carregados no Godot.
  Não houve abertura no aplicativo Aseprite.
- Sem dependências novas, alterações de contratos canônicos ou assets do jogo.
- Sem chamadas autenticadas a geradores: desempenho, custo real, identidade
  visual e obediência às guias ainda precisam do piloto do
  [plano de benchmark](../2026-10-23-pixellab/benchmark-plan.json).
- Pro/Pro Flash, personagens persistentes, skeleton-to-animation e treino
  próprio permanecem no projeto de pesquisa; não são anunciados como conectores implementados.

## Commits e publicação verificados

Consulta direta à conexão Vercel desta sessão confirmou `READY` para produção
`68ed1c8`, para a auditoria `9ee6b4c` e para a Oficina da Coroa `92a3896`.
Os dois últimos eram previews distintos no momento da leitura. Isto complementa
a limitação de acesso registrada na auditoria anterior. O trabalho da Oficina
foi identificado e não foi alterado por esta entrega.

Vercel publica o site e o jogo; a Forja continua sendo CLI/MCP local. Um
deployment pronto não demonstra que um gerador pago foi executado. A revisão
final cruza o SHA do GitHub com o deployment correspondente, sem atribuir a
produção a um preview de outra branch.
