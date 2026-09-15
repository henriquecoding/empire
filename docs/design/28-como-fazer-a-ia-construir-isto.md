# 28 — Repositório · Como fazer a IA construir isto

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Escolheste o modo em que a IA escreve quase tudo e tu revês e diriges. Funciona — mas só com um repositório desenhado para isso. Estas são as regras que separam um agente produtivo de um gerador de dívida técnica.

## As sete regras do repositório

1. Ficheiros pequenosMáximo 250 linhas por script. Um agente lê e reescreve um ficheiro de 200 linhas com fiabilidade; falha em ficheiros de 800. Esta regra sozinha vale mais do que qualquer prompt.

## Lógica separada de nós

src/sim/ é testável sem abrir o editor. A IA pode iterar aí sem partir cenas.

## Dados fora do código

Balanceamento em .tres/CSV. Alterar um número nunca deve exigir tocar num script.

## Testes primeiro para regras

Toda a função de src/sim/ tem teste em tests/. Sem testes, não consegues rever o que a IA escreve — e vais deixar de rever ao fim de duas semanas.

## CI headless

GitHub Actions com Godot headless a correr a suite em cada commit. É a tua rede de segurança quando não leste 400 linhas geradas.

## ADRs

Cada decisão arquitetónica num ficheiro em docs/adr/. É assim que o agente sabe porque é que algo está como está, sem tu repetires em cada sessão.

## Git LFS para arte

.aseprite e .png em LFS desde o primeiro commit. Migrar depois é doloroso e às vezes destrutivo.

## Ferramentas de ligação

| Ferramenta | O que dá | Estado em 2026 |
| --- | --- | --- |
| Servidor MCP para Godot | O agente lança o Godot, corre o projeto em debug, lê a consola e gere cenas. É o que fecha o ciclo: o agente corre o jogo e lê os erros dele próprio. | Ecossistema jovem mas usável. Há opções abertas (godot-ai, GDAI) e comerciais. |
| gdUnit4 + gdUnit4-action | Testes em CI com relatório, GDScript e C# | Maduro. Action de GitHub pronta. |
| Godot Aseprite Wizard | Arte → cena sem passos manuais, respeitando tags e camadas | Maduro |
| GodotSteam | Steam, conquistas, cloud saves, rede | Maduro. Padrão do ecossistema. |
| LimboAI | Behavior trees só para chefes e Podridão | Maduro. Não uses para tropas comuns. |


> **Três armadilhas do MCP com Godot, documentadas**
>
> 1. Desliga Auto Reload Scripts nas definições do editor durante sessões com agente — recarregar a meio de uma operação corrompe o estado. 2. A tipagem dinâmica do GDScript faz falhar chamadas de ferramenta com mais frequência do que em linguagens tipadas: anota sempre os tipos (func atacar(alvo: Unit) -> void). 3. Modificações que o agente faz na SceneTree em memória podem não chegar ao disco — exige gravação explícita depois de editar.

> **Atualização da v5.1 — lê a §69 antes de copiar o que se segue**
>
> Duas coisas mudaram neste ficheiro. Primeira: o contrato passou a chamar-se AGENTS.md, com um CLAUDE.md de três linhas a apontar para ele — o contrato é do repositório, não da ferramenta, e assim trocas de assistente sem reescrever nada. Segunda, e mais importante: o texto abaixo cita quatro caminhos que nenhuma tarefa da §34 ou da §65 criava — docs/design/, docs/QUESTIONS.md, docs/ASSETS_TODO.md e docs/adr/0007-save-security.md. Um caminho citado e ausente é pior do que não ter contrato: o agente inventa, e inventa diferente em cada sessão. A §68 explica o custo, a §69 fecha-o.

## O ficheiro CLAUDE.md — a versão da v5 (substituída pela §69)

```gdscript
# Empire — contrato do agente

## O que é
Kingdom-builder 2D em pixel art, Godot 4.6, GDScript. Mundo 1.5D com tres faixas
verticais. Ver docs/design/ para os sistemas e docs/adr/ para as decisoes.

## Regras absolutas
1. Maximo 250 linhas por script. Se passar, divide antes de continuar.
2. src/sim/ NAO importa de src/actors/ e NAO usa Node, Node2D ou qualquer classe
   de cena. E logica pura. Se precisares de posicao, recebe-a como parametro.
3. Balanceamento vive em data/**/*.tres. NUNCA escrevas um numero de
   balanceamento num script. Se precisares de um valor novo, cria o campo
   @export no Resource correspondente.
4. Toda a funcao publica de src/sim/ tem teste em tests/. Escreve o teste primeiro.
5. Anota sempre os tipos: func f(x: int) -> void. Sem excecoes.
6. Nao adiciones dependencias externas sem uma ADR em docs/adr/.
7. Nao toques em art/ nem em audio/. Se faltar um asset, cria um placeholder
   de cor lisa em art/export/_placeholder/ e regista-o em docs/ASSETS_TODO.md.

## Vocabulario do dominio (usa estes nomes, em ingles no codigo)
- Band       -> faixa vertical: AERIAL | SURFACE | UNDERGROUND
- Rot        -> A Podridao, a ameaca noturna
- People     -> povo/civilizacao (Enramados, Portuarios, Fenda, Horta,
                Fornalha, SobRaiz)
- Craft      -> oficio (builder, smith, cook, diplomat, bard)
- Boost      -> impulso real
- Greed      -> ganancia do rei (0-100)
- RoyalSeed  -> Semente Real (moeda de meta-progresso)
- Favor      -> moeda de diplomacia

## Ciclo de trabalho esperado
1. Le a tarefa em docs/backlog/<id>.md
2. Escreve/atualiza o teste em tests/
3. Implementa
4. Corre: godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests
5. So depois de verde, propoe o diff

## O que NAO fazer
- Nao inventes mecanicas. Se a spec nao cobre um caso, escreve a pergunta em
  docs/QUESTIONS.md e implementa a opcao mais simples.
- Nao refatores fora do ambito da tarefa.
- Nao adiciones comentarios que repetem o codigo.
- Nao uses load() em ficheiros de save. Ver docs/adr/0007-save-security.md
```

> **A regra do vocabulário**
>
> A secção do vocabulário é a mais subestimada do ficheiro. Sem ela, ao fim de três meses tens Rot, Blight, Decay e Corruption a designar a mesma coisa em ficheiros diferentes, porque cada sessão de IA escolheu uma tradução. Escreve o dossiê em português e o código em inglês, com o mapeamento fixo aqui.

## Ritmo de trabalho semanal

- **Segunda** — Escrever as 3–5 tarefas da semana em docs/backlog/, no formato do §34
- **Terça a quinta** — Sessões de agente, uma tarefa por sessão. Rever o diff antes de fazer merge.
- **Sexta** — Jogar 30 minutos. Não desenvolver. Jogar. Anotar o que aborrece.
- **Sábado** — Arte. É a única coisa que a IA não faz por ti, e é a tua vantagem competitiva.
- **Sempre** — Um GIF por semana para o devlog, mesmo que seja feio (§36)
