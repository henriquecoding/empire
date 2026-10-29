# Forja — poses, movimento e cenários locais

ADR 0101 · FORJA-15 · 29/10/2026. Ferramentas de estudo e revisão; arte aprovada
continua a exigir o dono e o registo de referências. Começar pelo
[guia de personagens](CHARACTER_PRODUCTION_GUIDE.md), [Forja](FORJA.md) e
[Aseprite](ASEPRITE_WORKFLOW.md).

## Roteiro de trabalho

1. Escolher a identidade e conferir seu papel no `elenco`. Tropas: `troop_64`;
   Rei: `royal_80`; não confundir arqueiro de tropa e Arqueiro Real.
2. Criar o roteiro, ajustar os pontos à imagem e editar as poses de cada fase.
3. Conferir coreografia, apoios, equipamento e transições, antes da rede.
4. Gerar com rota compatível ou importar PNGs produzidos/desenhados fora da Forja.
5. Abrir o pacote na bancada, conferir a 1× e exportar observações.
6. Rever no Aseprite e Godot, corrigir, e só então pedir aprovação da arte exata.

## Poses e clips

```sh
python3 -m tools.forja poses
python3 -m tools.forja poses --reference build/mestre.png --kind troop_64 \
  --action walk --description 'side-view armored soldier' -o build/forja/walk.json
python3 -m tools.forja coreografia build/forja/walk.json -o build/forja/guias
python3 -m tools.forja animar build/forja/walk.json
```

O último comando é plano, sem rede. As receitas possuem fases diferentes, mas
são manequins geométricos com todos os pontos marcados como inferidos. Corrigir a
pose da referência, cada extremo e cada apoio antes de gastar. Remover um ponto
de `inferred` apenas depois de conferir onde ele está nos pixels.

`forja.pose/1` usa os nomes das 18 articulações da API. `RIGHT ARM`/`LEFT ARM`
nomeiam os pulsos; `RIGHT LEG`/`LEFT LEG`, os tornozelos. Coordenadas são pares
`[x,y]` nativos, com origem superior esquerda. A API recebe `x/(largura-1)` e
`y/(altura-1)`; profundidade oculta não é inventada. `view` é `side` e `facing`
é `right` ou `left`. Partes ocultas podem ser declaradas em `occluded`.

Campos adicionais de cada pose:

| Campo | Uso |
| --- | --- |
| `sockets` | Pontos nomeados, por exemplo `grip: [36,40]` |
| `supports` | Pontos em apoio neste quadro, por exemplo `RIGHT LEG` |
| `contacts` | `{point: "RIGHT ARM", target: "grip", tolerance_px: 1}` |
| `parts_order` | Nomes de partes, de trás para frente; anotação a conferir |
| `regions` | Caixas `[x0,y0,x1,y1]`, limites finais exclusivos, por comportamento |

Comportamentos: `fixed` preserva caixa e pixels; `transported` permite translação,
mas compara o conteúdo da caixa; `articulated`, `deformable` e `effect` são
declarações para revisão, sem impor igualdade de pixels. Uma cabeça que roda não
deve ser classificada como cópia rígida. Regiões são comparadas ao primeiro quadro.

Cada quadro de `forja.clip/1` tem `pose`, `duration_ms`, `root_px` e `phase`
opcional. A referência inclui arquivo, SHA-256 e pose. A ação fornece contagem,
tempo total e loop do contrato: idle 6, walk 8, attack 5, die 7 a 10 fps.
Os tempos individuais podem variar, conservando o tempo total contratual.
`root_px` descreve deslocamento do personagem, não uma nova escala do sprite.

## Geração limitada e retomada

```sh
python3 -m tools.forja animar build/forja/walk.json --refs build/referencias.json \
  --method skeleton-v3 --seed 7 --send --max-calls 1 -o build/forja/walk-job
```

Exige `PIXELLAB_API_KEY` apenas no ambiente do processo que envia. Nunca colocar
a chave no clip, no GitHub ou na bancada. `--max-usd` adiciona teto quando há
cotação confiável; sem cotação, o sistema existente recusa prometer um teto
monetário. `--max-calls` limita submissões. O custo informado fica no job;
desconhecido permanece desconhecido.

Repetir o mesmo comando e pasta retoma a mesma intenção. Trocar referência,
seed, roteiro ou método exige outra pasta. Uma submissão ambígua não é repetida.
O polling usa GET; uma sequência inválida é conservada como evidência e não
vira export válido. Não acrescentar o quadro de referência ao retorno.

| Rota | Limite implementado | Uso |
| --- | --- | --- |
| skeleton-v3 | 3–15 quadros; dimensões até 256, respeitando contrato | Controle por poses; inclui 80×80 e attack de 5 quadros |
| text-v3 | 4–16 quadros pares; até 524288 pixels | Alternativa compatível; não aceita attack/die canónicos |

O fluxo textual não garante seguir poses. `enhance_prompt` permanece desligado
para não adicionar reescrita/custo implícito. A documentação do fornecedor não
constitui uma prova de identidade ou de qualidade do resultado.

## Importar, rever e exportar

`ok` indica que o pacote de revisão foi criado. `raster_contract_ok` informa o
lint dos pixels (paleta, alfa e estrutura), separado da validação de tela,
contagem e tempos. Erros aparecem na bancada; não há correção silenciosa de cor.
Não se exige pé preso ao pivot em quedas ou saltos. A aprovação continua pendente.

```sh
python3 -m tools.forja rever-clip build/forja/attack.json \
  --frame build/f0.png --frame build/f1.png --frame build/f2.png \
  --frame build/f3.png --frame build/f4.png -o build/forja/attack-review
```

O pacote leva `identity.png`, `frames/*.png`, `clip.json`, `review.json`, atlas,
JSON, `.aseprite`, `.tres` e a bancada HTML. Aseprite: corpo mais guia de pose
oculto, tags, tempos, pivot e sockets em slices. Não pressupõe camadas de roupa
ou arma separadas no retorno da IA. O `.tres` aponta para o atlas na raiz de um
projeto de teste; ao integrar em outra pasta, ajustar o caminho do recurso.

Abrir `/forja/` no site e selecionar `review.json`, ou servir a pasta do pacote
por HTTP local. A página oferece 1×/4×/8×, fundos, quadro anterior transparente,
pontos, trajetórias, diferenças e observações por quadro. `attack` e `die`
terminam no último quadro. A leitura local não envia imagens ao servidor.

O SHA-256 dos bytes do arquivo carregado e dos PNGs identifica as observações.
O commit e os hashes internos são procedência declarada; não são assinatura de
autoria nem prova de aprovação. Alterar o pacote exige outra revisão. Exportar
observações nunca muda o registo `refs` nem a arte de runtime.

```sh
python3 -m tools.forja transicao build/forja/walk.json build/forja/attack.json \
  --from-frame 7 --to-frame 0 --offset-x 0 --offset-y 0 -o build/transicao.json
```

Para uma interrupção, escolher o quadro de saída real. Para um ciclo, comparar o
clip consigo mesmo e informar o deslocamento da raiz no ciclo seguinte.
O limiar de 1 pixel é triagem configurável, não lei artística. Pontos inferidos
ficam pendentes. Conferir os mesmos extremos com pixels e no motor.

## Cenários por componentes

O contrato `forja.scene/1` conserva régua, extensão, vãos, estados e sinais.
Acrescentar `components` para partes animadas, com `id`, `role` (`structure`,
`material`, `decoration`, `effect`), `region_px`, `anchor_px`, `layer`, `loop`
e `frames`. Cada frame indica arquivo, hash, duração e âncora local. A âncora
local somada à origem da região deve ser igual à âncora da cena.

```json
{"id":"flame","role":"effect","region_px":[96,0,112,16],
 "anchor_px":[104,14],"layer":1,"loop":true,
 "frames":[{"file":"flame-0.png","sha256":"HASH_REAL_DO_PNG",
             "duration_ms":100,"anchor_px":[8,14]}]}
```

Pixels de cenário são pixels de ecrã do contrato, não coordenadas normalizadas.
Uma base limpa não deve conter o componente que será sobreposto; caso contrário,
a imagem antiga continuará por baixo. As partes compõem-se de trás para frente.
Para vãos e oclusão de atores continuam a valer `estrutura` e `montagem`.

```sh
python3 -m tools.forja cena-movimento build/oficina.json --image build/base.png \
  -o build/forja/oficina-review
```

Ciclos de durações distintas usam o mínimo múltiplo comum, com limite de 60 s,
600 quadros e 256 MiB. `--duration-ms` recorta uma amostra; se não fecha todos
os ciclos, o pacote não é marcado como loop. `outside_changes` deve ser zero.
`interactions` relaciona `point_px` e `target_px`, com `observed` explícito e
tolerância. Uma distância pequena não comprova que mão, ferramenta e mesa
estão desenhadas corretamente. Conferir oclusão e luz com os atores no motor.

## Benchmark observado

`comparar-clips manifesto.json -o build/comparacao.json` não gera imagens.
O manifesto usa `schema: "forja.benchmark/1"` e `runs`, cada qual com:

```json
{"package":"attack-review/review.json","sha256":"HASH_REAL_DO_ARQUIVO",
 "task":"rei-attack","decision":"pending","reviewer":"",
 "correction_minutes":null,"extra_cost_usd":null}
```

Usar `job` em vez de `package` para tentativas sem resultado visual, incluindo
falhas e submissões incertas. O hash é do arquivo exato. Não duplicar o mesmo
job na comparação. `accepted`/`rejected` exige revisor; aceitação neste estudo
não promove arte no `refs`. Gasto é lido do pacote/job; custo extra e minutos
são declarados. `null` significa desconhecido e `0`, zero medido.

Agrupar tarefas idênticas e métodos, contabilizar rejeições, comparar custo por
aceito, taxa de aceitação e minutos de correção. Não há benchmark artístico
real nesta entrega: os testes e exemplos são sintéticos. O piloto pago só
deve avançar com referências, poses e orçamento deliberadamente definidos.
