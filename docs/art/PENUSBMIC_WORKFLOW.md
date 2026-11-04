# Estudo Penusbmic aplicado à Forja

Implementação de [FORJA-19](../backlog/FORJA-19.md), [ADR 0105](../adr/0105-estudo-penusbmic-em-ensaios-verificaveis.md).
Consultar `python3 -m tools.forja estudo` para fontes, propostas e revisão do estudo recebido em 03/11/2026.
O [original e suas transcrições](research/2026-11-03-penusbmic/README.md) ficam preservados. Os critérios abaixo
são adaptações ao Empire; não atribuem ao professor regras inventadas para o projeto.

## Aplicação das propostas

| Proposta | Comportamento implementado | Evidência que continua humana |
| --- | --- | --- |
| P0-01 | Mãos/objetos por quadro, braço, pega, orientação, oclusor e medida absoluta dos objetos partilhados | Anatomia, dedos e peso convincentes; medida autorizada do frasco |
| P0-02 | Estados/orientações faciais vinculados ao conceito, invariantes e observação por quadro | Referências autorizadas para esforço, dano e novas orientações |
| P0-03 | Apoio, fase, partes condutoras/secundárias, entrada, recuperação e corpo sem efeitos | Atuação e continuidade vistas em movimento |
| P1-01 | `variantes` compara alternativas na mesma grade; recusa personagem já escolhido e referências rejeitadas | Escolha de design pelo dono |
| P1-02 | `cena-piloto` compõe massas, planos, ator, acesso inferior e dia/noite em escala nativa | Escala, leitura dos planos, materiais e emendas |
| P1-03 | `ensaio` e `ensaio-comparar`: mesma receita de entrada/estado/câmara, duração e hashes dos arquivos | Ensaio de autoria não executa entradas no Godot |
| R2-01 | Exportação por ação, tempos exatos, pivô fixo e reconstrução do canvas após trim | Autoria nativa, importação e apresentação no jogo |
| R2-02 | Efeitos por região e intervalo; pixels fora da declaração bloqueiam a revisão | Intenção do efeito e legibilidade do ator |
| R2-03 | Massas e circulação antes de detalhe; grupos de bioma e regiões procedurais declaradas | Limpeza de sobreposições e hierarquia visual |

`prompt` e `plan` incluem o método e sua procedência, inclusive nos pedidos de cena. Os conceitos escolhidos,
as regras do dono, o dossiê e os contratos atuais têm precedência. A ferramenta não gera novas aprovações.

## Ensaio de animação

Começar com a fonte `.aseprite` existente, tags completas e pivô do contrato explícito desde o quadro zero.
Os caminhos abaixo são exemplos de arquivos de trabalho, não assets já produzidos.

```bash
python3 -m tools.forja ensaio build/forja/personagem.aseprite \
  --kind royal_64 --character alchemist_squire --effect-layer fx --trim \
  -o build/forja/ensaio-v1
```

Abrir `build/forja/ensaio-v1/index.html`. A prévia mostra 1×, ampliações inteiras, fundos claro/escuro,
quadro anterior/seguinte, onion skin dentro da ação, pivô, composição sem VFX e composição final.
Com `--character`, mostra o recorte do conceito lado a lado. Sem conceito, a revisão continua pendente.
As ações usam sua direção de reprodução; cada passagem é finita. Para conferir repetição e saída,
declarar os ciclos e a transição na receita. Reproduzir ao chegar ao fim reinicia o ensaio.

O pacote contém cópia exata da fonte, PNG/JSON separados por ação e variante, manifesto com hashes,
receita e ficha de revisão. `--trim` economiza armazenamento, mas recompõe cada quadro no canvas original
antes de comparar pixels e mostrar a prévia. Não recentra poses, não muda a escala por causa de VFX e não
arredonda 65 ms para uma taxa de quadros. Quadros vazios continuam presentes. A duração válida não substitui
a cadência canônica: esta exportação é um ensaio e não o portão final do asset.

Sem prévia, usar `forja exportar fonte.aseprite --actions --kind troop_64 --trim -o build/forja/acoes`.
O modo histórico de exportação por camada permanece disponível. Camadas anatômicas/equipamento reconhecidas
pelos slots não podem ser declaradas VFX. Nomear efeitos explicitamente; camada desconhecida é erro.

## Ficha de revisão e autoridade

Copiar `review.template.json` para `review.json`, observar as imagens exatas e preencher:

- `observer`: autor, método e data; `views`: 1×, ampliação inteira, fundos e comparação com conceito.
- `frames`: conservar índice, hashes, tempo e pivô. Observar ambas as mãos, braço, objeto, trajetória,
  orientação, oclusor e caixa em pixels. Uma mão ocluída exige identificar quem a cobre.
- `face`: estado/orientação da referência autorizada, caixa e invariantes realmente conferidos.
- `support`: fase, tipo/ponto de apoio, partes condutoras/secundárias e oclusão.
- `shared_props`: observar cada objeto obrigatório, inclusive ausência ou oclusão. Dimensões sem autoridade
  ficam pendentes; não inventar um padrão para o frasco a partir de um candidato.
- `actions`: entrada, mudanças de apoio/oclusão, recuperação, loop/saída, trajetória e reação secundária.
- `body_without_vfx`, `final_composition`, `effects_review` e `replay_review`: evidência concreta.

Cada observação tem `status: pass|fail|pending|inconclusive` e `evidence`. “Pass” vazio não passa.
Defeito observado bloqueia; incerteza permanece pendente. A ficha inicial nunca declara êxito.

```bash
python3 -m tools.forja ensaio-rever build/forja/ensaio-v1/manifest.json \
  --review build/forja/ensaio-v1/review.json
```

O resultado é `pass`, `pending` ou `blocked`; somente `pass` devolve `ok: true`; a CLI sai com erro quando a revisão não passa. Mesmo assim,
`release_ready` permanece falso: é conferência técnica e evidência visual declarada. Não substitui
`forja entrega`, a cadeia de perdas, a fidelidade, a decisão do dono ou o teste Godot.

Por omissão, a autoridade facial contém somente a pose do conceito (`orientation: concept`), sem autorizar
novos ângulos. `--face-states estados.json` aceita o registro declarado de estados autorizados:

```json
{
  "character": "alchemist_squire",
  "authority_crop_sha256": "HASH_DO_CONCEITO",
  "states": [{"id": "effort", "orientation": "right",
    "reference_sha256": "HASH_DA_REFERENCIA_DESTE_ESTADO",
    "authorized_by": "DECISOR", "date": "DATA_DA_DECISAO",
    "instruction": "INSTRUCAO_EXPLICITA", "invariants": ["eye", "nose"]}]
}
```

É um registro de evidência, não autenticação da identidade do decisor. Conservar a referência indicada
com a decisão original. Não preencher a autorização em nome do dono nem usar invariantes inventados.

## Receita repetível e efeitos intencionais

`--recipe receita.json` fixa `forja.replay/1`, com `steps`. Cada passo tem `action`, `cycles` (1 a 20),
`input`, `state` e `camera: [x,y]` em pixels inteiros. Todas as ações devem ser exercitadas.
`input`, `state` e `camera` são condições registradas do ensaio de autoria; não simulam controles ou câmera
do jogo. O renderer mostra o canvas do ator sem deslocá-lo. O ensaio Godot é uma prova separada.

```json
{"schema":"forja.replay/1","steps":[
  {"action":"idle","cycles":2,"input":"none","state":"idle","camera":[0,0]},
  {"action":"attack","cycles":1,"input":"attack","state":"attack","camera":[0,0]},
  {"action":"idle","cycles":1,"input":"none","state":"recovery","camera":[0,0]}
]}
```

Depois da edição, criar `ensaio-v2` com a mesma receita e executar:

```bash
python3 -m tools.forja ensaio-comparar build/forja/ensaio-v1/manifest.json \
  build/forja/ensaio-v2/manifest.json
```

Mudança de receita, tempos, pivô, canvas, quantidade de quadros ou integridade invalida a comparação.
A lista de quadros alterados localiza a edição; não diz que ela ficou melhor.

`effect_windows` da ficha é uma lista como `[ {"from": 2, "to": 4, "box": [10,8,30,25], "reason": "flash"} ]`.
Índices começam em zero e o intervalo é inclusivo; caixa usa `[x0,y0,x1,y1)` no canvas nativo.
Toda diferença entre ator limpo e composição final precisa caber nas regiões/intervalos declarados.
A mesma lista pode ir em `sheet --effect-windows efeitos.json`: deflicker respeita o intervalo dentro
de cada tag e não carrega o efeito ao quadro seguinte; lock preserva pixels protegidos do quadro e da referência.
As antigas caixas `--action` continuam protegidas durante toda a sequência.

## Alternativas e piloto de cenário

```bash
python3 -m tools.forja variantes build/forja/a.png build/forja/b.png \
  --kind troop_64 --function "explorador de design ainda aberto" -o build/forja/variantes
python3 -m tools.forja cena-piloto build/forja/piloto.json -o build/forja/piloto
```

Variantes exigem imagens distintas no mesmo canvas. `--character` recusa personagens do elenco escolhido;
para eles, usar preservação/reparo. `--refs` consulta decisões registradas. A ferramenta nunca escolhe o vencedor.

O JSON `forja.scene_pilot/1` declara caminhos relativos a ele:

```json
{
  "schema": "forja.scene_pilot/1", "contract": "cena.json",
  "planes": {"background":"fundo.png","midground":"meio.png","foreground":"frente.png"},
  "masses":"massas.png", "night":"noite-fundo-e-meio.png", "night_foreground":"noite-frente.png",
  "actor":"ator.png", "actor_kind":"troop_64", "actor_at":[32,64],
  "lower_access":[0,96,32,128], "biome_groups":["musgo junto às raízes","cogumelos agrupados"],
  "procedural_regions":[[0,0,32,32]], "reference_register":"referencias.json"
}
```

`cena.json` segue o contrato existente `forja.scene/1`, com extensão, vãos, materiais e estados.
Todos os planos, massas e noite têm essa extensão. O ator usa seu canvas nativo sem escala e fica entre
o plano médio e o primeiro plano. `night` contém fundo/meio noturnos; `night_foreground` mantém a oclusão correta.
O acesso inferior e as regiões procedurais devem caber na cena. A imagem de massas é fornecida pelo autor;
o programa não infere que foi desenhada antes dos detalhes. Sem ator aprovado no registro, revisão pendente.

Abrir `index.html` e preencher `review.template.json`. O mesmo `ensaio-rever` confere estes pilotos.
A ficha exige portas/bancadas, acesso, planos, dia/noite, emendas, junções de materiais, grupos do bioma
e limpeza procedural. Uma região declarada não autoriza gerar nela nem aprova seu conteúdo.

Todos os comandos estão expostos pelo registro CLI/MCP existente. Não acrescentam dependências, chamadas
pagas, assets em `art/`, mecânicas ou um importador alternativo do jogo.
