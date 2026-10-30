# Animação nativa na Forja

Fluxo do FORJA-18 / [ADR 0104](../adr/0104-a-forja-gera-e-reve-animacoes-nativas.md).
Consultar primeiro `forja regras`, `forja elenco` e o conceito escolhido. Um mestre em revisão pode
originar um estudo, mas não passa a aprovado por ser animado. Autoria na grade nativa é uma declaração
de origem sustentada pela cadeia, não uma propriedade demonstrada pelas dimensões do PNG.

## Plano sem rede e geração retomável

```sh
python3 -m tools.forja anim-plan build/forja/piloto/mestre.png \
  --character ID --tag walk --lineage build/forja/piloto/mestre.json \
  --model text-v3 -o build/forja/piloto/plano-walk
python3 -m tools.forja animar build/forja/piloto/plano-walk/plan.json \
  -o build/forja/piloto/walk --max-calls 1
```

`--character` resolve id/alias, função, tela e conceito do elenco; `--fidelity CONTRATO` permite contrato
explícito. Tropas/escudeiros atuais são 64×64; Rei/Arqueiro Real e imperadores grandes seguem 80×80.
`--lineage` é a cadeia do mestre individual exato, não de um atlas. Para um desenho nativo que seja
efetivamente a origem, usar `--native-root`. Nunca substituir uma recuperação anterior por essa flag.
Uma referência reduzida ou com perdas críticas por fechar é recusada antes da chamada paga.

O plano guarda `first.png`, parâmetros, hashes e consulta das regras; `--refs` conserva o estado real
da referência. Opcionalmente usar `--last` no modo texto, com `--last-lineage` ou `--last-native-root`
e, se necessário, `--last-source-resolutions`: a pose final tem origem própria e também é validada.
O plano não recebe chave nem faz rede.
Para gerar, configurar `PIXELLAB_API_KEY` no ambiente. O custo não é estimado pelo adaptador; sem
estimativa conhecida, `--max-usd` segue a recusa preventiva do budget existente. O teto executável é
`--max-calls`, persistido na pasta; o custo real reportado pelo fornecedor fica no job.

| Modo | Pedido | Limites validados |
| --- | --- | --- |
| `text-v3` | PNG inicial, ação e opcionalmente PNG final | 4–16 quadros pares; até 256 por lado; área total até 524288 px |
| `skeleton-v3` | PNG inicial, aparência, ação, direção lateral e poses observadas | 3–15 quadros; até 256 por lado; 18 pontos em cada pose e na pose inicial |

Por omissão, a contagem e os tempos vêm da Animation Bible, com chaves no plano. `--frames` explicita
um estudo; a entrega recusa a contagem incompatível com runtime. `text-v3` suporta idle 6/walk 8;
attack 5/die 7 exigem `skeleton-v3`. `hit` 2 exige desenho nativo/prancha: estes endpoints não devolvem
dois quadros. Nunca cortar, duplicar ou omitir poses para declarar a contagem canónica cumprida.

Repetir **o mesmo comando e a mesma pasta** retoma o job original por GET ou reutiliza os brutos
concluídos. `--resume ID` identifica explicitamente o job dessa pasta. Não repetir POST após timeout
ambíguo; consultar `forja jobs list/show`. Uma pasta com outro plano é recusada. Para outra tentativa
intencional, criar outro plano/pasta e orçamento. Não copiar pastas para contornar o teto.

Os quadros recebidos ficam brutos no job, com ordem e repetições preservadas. Só um retorno PNG com
contagem/tela exatas se empacota. Não há quantização, recorte, limpeza, recentragem ou reamostragem
silenciosa. Uma paleta/pose inválida conserva-se para diagnóstico e revisão. Os adaptadores foram
testados com transporte falso e rasters sintéticos; não há prova de geração real ou qualidade artística.

## Esqueleto observado, não fabricado

```sh
python3 -m tools.forja anim-plan build/forja/piloto/mestre.png \
  --character ID --tag attack --model skeleton-v3 --direction east \
  --description 'aparência fiel ao mestre, roupa e equipamento' \
  --skeleton build/forja/piloto/attack-poses.json \
  --lineage build/forja/piloto/mestre.json -o build/forja/piloto/plano-attack
```

`forja.skeleton_animation/1` contém `first_frame_pixels_sha256` (hash de `equipment.image_sha`),
`observer` com author/method/date, `first_frame_keypoints`, `keypoints` (uma lista por quadro devolvido)
e `template_id` (mannequin/bear/cat/dog/horse/lion). Não há gerador de poses automáticas neste fluxo.
Marcar a pose inicial que o PNG realmente mostra; a API usa-a como referência e não a devolve.

Cada ponto tem `label`, `x` e `y` finitos de 0 a 1. `z_index` inteiro é opcional; `depth` opcional
é finito de 0 a 255, ou null. Omitir depth usa o template do fornecedor. Rótulos obrigatórios:
NOSE, NECK, RIGHT SHOULDER, RIGHT ELBOW, RIGHT ARM, LEFT SHOULDER, LEFT ELBOW, LEFT ARM,
RIGHT HIP, RIGHT KNEE, RIGHT LEG, LEFT HIP, LEFT KNEE, LEFT LEG, RIGHT EYE, LEFT EYE, RIGHT EAR, LEFT EAR.
Não renomear ARM/LEG para HAND/FOOT. A presença de 18 pontos não prova que a anatomia foi bem marcada.

## Rever a sequência e refinar quadros

```sh
python3 -m tools.forja animacao build/forja/piloto/walk/animation.forja.json \
  --character ID --template-out build/forja/piloto/walk/review.json \
  --proof-out build/forja/piloto/walk/prova.html
```

A prova põe conceito ao lado dos quadros a 1×/4×, fundos claro/escuro, leitor por ação, velocidade real,
passo por quadro e onion skin. Observar e preencher a ficha: observador/método/data, vistas efetivamente
usadas, caixas/evidência por aspeto em cada quadro; articulação/chaves/timing/transições/fecho por ação;
e cada alerta automático. O template fica pendente. Não preencher pass porque o export teve sucesso.
`ready_for_review` exige todos esses registos, além do contrato e da origem atuais.

O reparo usa os mesmos `forja.pixel_patch/1` do sprite estático, dentro de `forja.animation_patch/1`:

```json
{
  "schema": "forja.animation_patch/1",
  "sequence_sha256": "hash atual devolvido por animacao",
  "frames": [{"frame": 2, "patch": {
    "schema": "forja.pixel_patch/1",
    "base": {"pixels_sha256": "hash deste quadro", "canvas": [64, 64]},
    "author": "observador", "date": "AAAA-MM-DD", "reason": "correção observada",
    "mask": [[29, 40, 30, 41]],
    "operations": [{"op": "paint", "pixels": [[29, 40, "#000000"]]}]
  }}]
}
```

Coordenadas do exemplo são ilustrativas; marcar o defeito real. Pinos e áreas protegidas do patch
continuam disponíveis. Aplicar numa pasta nova, preservando fonte, outros quadros, tempos e cadeia:

```sh
python3 -m tools.forja anim-patch build/forja/piloto/walk/animation.forja.json \
  build/forja/piloto/reparos.json --character ID -o build/forja/piloto/walk-reparado
```

O hash muda; a ficha e aprovação antigas deixam de servir. Voltar a observar toda a sequência nova.

## Perdas e entrega

```sh
python3 -m tools.forja entrega-anim build/forja/piloto/walk/animation.forja.json \
  --character ID --review build/forja/piloto/walk/review.json
```

Uma prancha produzida por `sheet` com cadeia também pode entrar neste portão; conserva-se o conceito
e consulta originais. Redução em qualquer antecessor bloqueia. Divergência de pixels, ordem, tempo,
tags/direções ou pivô entre PNG/JSON/Aseprite bloqueia. Uma cadeia individual do mestre não substitui
a origem de toda a prancha. Um mestre ancestral com perdas críticas ainda sem prova mantém-se pendente.

Perdas por quadro usam `--loss-resolutions` com schema `forja.animation_loss_resolutions/1`, hash atual
`sequence_sha256` e lista `resolutions`. Cada resolução identifica `chain_output_sha256`, `frame` e
`loss` (índice zero-based nessa lista de perdas), com `by`, `date` e `evidence`. `repaired` exige
`pixels_sha256` do quadro atual e `pixels` [[x,y,cor],...], próximos da ocorrência e presentes nesse
quadro. Só se admite correspondência automática de coordenadas através de patches locais; outra
transformação exige prova individual antes da prancha ou exceção explícita. `excepted` exige
`authorized_by: "Henrique"`. Um pass genérico, outra sequência ou outra cor não fecha a ocorrência.

`--release --approvals REGISTO` exige ainda `forja.animation_approvals/1`, com lista `entries`.
Uma decisão tem `sequence_sha256`, `state` approved/rejected, `decided_by: "Henrique"`, `date` e
`evidence`. Não há escritor automático dessa decisão. Só registar a aprovação realmente dada pelo dono.
Pronto para revisão, aprovação artística, abertura desse ficheiro no aplicativo e integração no jogo
são estados distintos; o portão não certifica atuação facial ou biomecânica por visão computacional.

Fonte primária revalidada: [OpenAPI PixelLab](https://api.pixellab.ai/v2/openapi.json), 30/10/2026;
SHA-256 `e7bdfc6e50fc4fdeea424cf92841b5509e01e8acf8975e7dae44bcab34730e4a`.
