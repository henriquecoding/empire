# Empire — relatório técnico e criativo para retomada pelo Astra

**Revisão 2 — auditoria de 25 de setembro de 2026.**  
**Entrega consolidada:** 26/09/2026. Os resultados técnicos abaixo são a fotografia da auditoria de 25/09, não uma nova execução em 26/09.  
**Projeto:** [henriquecoding/empire](https://github.com/henriquecoding/empire) · Godot 4.6 · GDScript.  
**Horário de retomada mencionado pelo utilizador:** 16:28. Este documento não verifica a disponibilidade do modelo nem agenda a execução de um agente.  
**Referência temporal das verificações:** 25/09/2026, UTC; a suíte desta auditoria correu aproximadamente entre 16:39 e 16:41.  
**Árvore auditada:** `gameplay/readable-kingdom-loop`, HEAD `b7f8689`, acrescido das alterações locais ainda não commitadas.

> **Leitura de dois minutos para o Astra:** há trabalho local relevante de caça, atribuição de trabalhadores, escolha de muralha, HUD e desenho do cenário. A integração ainda está incompleta. A suíte real descobriu **642 testes: 633 passaram, 3 falharam e 6 foram saltados**. O principal portão acusa **650 ocorrências G4 em nove arquivos**. A caça de introdução já produz uma moeda no primeiro tick e interfere em dois testes existentes. O piloto da vistoria perde o castelo no primeiro dia; a mensagem final “10 dias sem nada a apontar” significa ausência de invariantes quebradas, não dez dias sobrevividos. O pacote de recursos exporta e inclui o manifesto dos sprites, mas o jogo desta árvore não foi validado visualmente num browser. A `main` avançou para `5bf60b5` com mudanças importantes no site. Preservar essas mudanças. Não declarar este trabalho pronto para produção.

## 1. O pedido que orienta a retomada

O utilizador quer que o projeto avance em direção ao dossiê e à inspiração inicial em **Kingdom**. A insatisfação tem três componentes ligados: falta de decisões interessantes, deslocamento repetitivo e cenário em que os elementos parecem iguais ou pouco trabalhados.

O pedido seguinte foi um **relatório denso e completo para auxiliar o Astra**. Esta revisão entrega esse handoff com evidências novas. A auditoria recuperou o motor, executou verificações e examinou o código; **não corrigiu os scripts de gameplay, não integrou a main e não publicou a branch**. As alterações de implementação descritas adiante já estavam no worktree quando esta revisão começou.

O resultado esperado da próxima implementação é um trecho em que o jogador consiga reconhecer o que existe, decidir onde investir e observar as consequências. Mais classes, edifícios ou menus, isoladamente, não demonstram isso. O primeiro objetivo verificável é fechar o circuito:

**encontrar uma oportunidade → investir moeda → recrutar/construir → ver trabalho e rendimento → preparar a noite → defender → encontrar uma nova decisão.**

A referência Kingdom deve orientar a legibilidade, o ritmo e a relação entre gesto e consequência. O dossiê de Empire acrescenta identidade própria: faixas verticais, ofícios, produção/conversão/comércio, Amargueiros, candeia, Ofertas, Nome e capítulos. Não reduzir essas diferenças a uma reprodução de Kingdom.

## 2. Como interpretar as afirmações deste relatório

| Rótulo | Significado |
|---|---|
| **Medido** | Houve execução de ferramenta, teste ou consulta nesta auditoria. |
| **Constatado no código** | O caminho existe e foi lido; isso não prova a experiência visual ou o equilíbrio em jogo. |
| **Risco / hipótese** | Há uma causa plausível no código, mas falta reprodução dirigida. |
| **Proposta** | Sugestão de implementação ou de teste, ainda não uma decisão aprovada. |
| **Histórico** | Informação de documentação, relatório ou conversa anterior, sem nova validação integral. |

Esta distinção é essencial. Um teste de sistema puro pode passar enquanto o primeiro jogador continua sem compreender o edifício, sem dinheiro para a próxima etapa ou sem ver a animação. Um export bem-sucedido também não demonstra que o canvas desenha corretamente.

As imagens fornecidas pelo utilizador são evidência da crítica visual e das referências. **Não são capturas desta branch após a alteração.** Três referências a arquivos PNG locais aparecem com erro de arquivo inexistente na conversa; não foi possível inspecionar esses três arquivos. As imagens efetivamente visíveis na conversa permitem comparar o greybox enviado com as cenas de Kingdom. Não atribuir conteúdo aos anexos ausentes.

## 3. Preferências artísticas que precisam sobreviver à troca de modelo

A recuperação de contexto encontrou decisões explícitas do utilizador, sobretudo de 12 e 19/09:

- O **soldado, o cozinheiro e a personagem do balcão** são referências quase completas. A linguagem desses personagens deve orientar o restante.
- O **arqueiro conceitual foi rejeitado**. Ter o arquivo no projeto não o torna arte aprovada para runtime.
- O **Rei precisa de redesign**, preservando a expressão original. A indicação anterior foi reformular o restante, não apagar a personalidade do rosto.
- Rostos e expressões originais são parte valiosa da autoria. A referência é expressividade cômica, com personagens arredondados e vestimentas medievais.
- O corpo das tropas pequenas deve respeitar a referência do soldado; o chapéu do cozinheiro pode exceder o corpo.
- Há referências anteriores a telas-base de 64×64 para Rei/jogáveis e fauna e 32×32 para personagens menores. O repositório, por sua vez, contém uma escala própria em pixels e uma ADR ainda proposta. **Não resolver essa divergência simplesmente redimensionando as imagens.**
- O cenário autoral foi considerado aproveitável e merecedor de melhoria. A direção é preservar a arquitetura e a personalidade existentes.
- O enquadramento deve se espalhar mais na horizontal e parecer menos extenso verticalmente. Nos estudos anteriores, o utilizador pediu cerca de 3000×1080, mantendo a altura e ampliando a largura; isso é referência de composição, não autorização para mudar a resolução interna do motor sem o spike previsto.
- A árvore do castelo deve ser monumental, podendo sair do enquadramento. O problema não é sua grandeza em si, mas a qualidade da forma e a relação com a arquitetura e com a escala dos personagens.
- Patamares e faixas precisam de conexões claras e acessos que façam sentido. Não deformar os personagens para fazê-los caber numa composição vertical excessiva, nem reduzir o subsolo a uma faixa quase invisível.

O relatório anterior também registrava a arquitetura de árvore-castelo, arcos, telhados e alvenaria. O arquivo autoral `tree_castle.png` existe no recorte recuperado e foi inspecionado: contém uma construção de alvenaria clara, arco, tronco/ramificações e base com arco. Deve ser considerado na composição, não ignorado em favor de uma árvore genérica.

**Não transferir autorizações de outros projetos.** A recuperação de contexto devolveu exemplos de merge/deploy de repositórios distintos; eles não autorizam operações sobre Empire. Para Empire, usar o pedido vigente e o contrato deste repositório.

## 4. Diagnóstico visual a partir das imagens fornecidas

Na captura do jogo enviada pelo utilizador, a árvore central ocupa grande parte da composição, mas é formada por grandes massas lisas. Os diferentes planos usam valores próximos, as unidades são pequenas e a informação importante ocupa grandes painéis de HUD. Há linhas e contornos indicando coisas construíveis, mas pouca linguagem material ou funcional para que se reconheça cada objeto.

Nas referências de Kingdom, a leitura vem de relações concretas: telhados e torres têm perfis diferentes; portas e janelas dão escala; a vegetação organiza a profundidade; a faixa de circulação é clara; os edifícios parecem habitados; materiais respondem de maneira coerente à luz. A água/reflexão ajuda algumas dessas composições, mas não explica sozinha a qualidade.

| Problema percebido | Direção de correção | Evidência que deve comprovar a melhora |
|---|---|---|
| “Tudo parece a mesma coisa” | Silhuetas, materiais e atividade próprios para cada função | Reconhecer produção, defesa e passagem numa captura sem rótulos |
| Árvore central parece um bloco dominante | Compor tronco, copa, arquitetura, abertura e escala humana | Portão, caminho e Rei continuam legíveis junto ao núcleo |
| Planos se confundem | Separar fundo, plano jogável e primeiro plano por valor, contraste e sobreposição | Personagens e moedas distinguíveis de dia e à noite |
| Construções não comunicam uso | Ferramentas, produtos e habitantes associados à função | Entender plantação, pesqueiro e treino sem ler uma descrição |
| Deslocamento parece vazio | Colocar oportunidades e consequências no trajeto | Viagens têm motivo e retornam com mudança no reino |
| HUD explica demais | Fazer mundo e animação carregarem informação | Ação compreendida antes de depender de uma caixa textual |
| Falta de acabamento | Estabelecer uma cena autorada de qualidade e expandir a linguagem | Uma cena representativa funciona em repouso e em movimento |

Essas são direções de composição, não aprovação artística do desenho procedural local. Ainda falta ver o resultado dessa árvore de código em execução.

## 5. Repositório, branches e risco de integração

| Item | Estado verificado |
|---|---|
| Diretório | `/workspace/scratch/7eed40b367f7/empire` |
| Remote | `https://github.com/henriquecoding/empire.git` |
| Branch de trabalho | `gameplay/readable-kingdom-loop` |
| HEAD local | `b7f8689d270d9c87aa4211c7e9181a41f80363b2` |
| Main obtida por fetch | `5bf60b571a52d63261aa241c7db4b73d308b1c23` |
| Default informado pela API GitHub | `claude/gracious-ptolemy-efyrb5` |
| Destino prescrito em AGENTS.md | `main`, via PR |
| Estado da fatia local | Alterações tracked e untracked; ainda sem commit/push desta fatia |
| Vercel no commit da main | Status de integração `success`; não é validação desta branch |
| Acesso direto ao projeto Vercel | Consulta ao projeto `empire`, equipe `hamriki-s-projects`: **403 Forbidden** |

A divergência entre o default da API e o contrato do repositório é real. **O relatório anterior errou ao recomendar abrir o PR automaticamente contra o default antigo.** O trabalho atual foi baseado na main. A próxima sessão deve conferir as referências e seguir o destino do projeto, sem escolher o ramo antigo apenas porque o GitHub o apresenta como padrão.

A main recebeu o PR #29, com a ADR 0025 e o PUB-02. As mudanças incluem site em PT-PT/EN, dados extraídos do repositório, fontes locais, CSP, capturas com procedência e novas verificações. Existem alterações em `AGENTS.md`, `Makefile`, `README.md`, `docs/recovery/`, `tools/web/`, workflow e `vercel.json`.

A integração deve preservar esse trabalho. Antes de merge de branches, criar um checkpoint local revisável das mudanças existentes. Não usar reset destrutivo, não sobrescrever documentação com versões antigas e não tratar cache/local generated como trabalho autoral. Após integrar a main, reler AGENTS e executar os portões novamente.

O contrato pede que trabalho concluído entre na main por PR e não fique indefinidamente abandonado. Também distingue PR em rascunho de entrega pronta. **Esta árvore tem falhas conhecidas e ainda não satisfaz a condição de conclusão.**

Links identificados nesta auditoria:

- Main: https://github.com/henriquecoding/empire/commit/5bf60b571a52d63261aa241c7db4b73d308b1c23
- PR #29: https://github.com/henriquecoding/empire/pull/29
- Status Vercel da main: https://vercel.com/hamriki-s-projects/empire/cBQAF43MQMJDRkimV1oBTHoG3AkR

O 403 foi registrado como limite de acesso, não contornado. Ele não impediu esta auditoria local.

## 6. Fontes de verdade e limites arquiteturais

Leitura mínima antes de alterar código:

1. `AGENTS.md` e o ticket da fatia a executar.
2. §06 economia; §10 muralhas; §24 interface; §25 e §83 abertura.
3. §43 ordem do tick; §47 constantes; §52 trabalhos/FSM; §55 construção; §61 intenções.
4. `docs/QUESTIONS.md`, principalmente Q-048, Q-064, Q-065, Q-068, Q-073 e Q-104.
5. `docs/art/ASSET_BIBLE.md`, `ANIMATION_BIBLE.md`, `EXPRESSION_GUIDE.md`.
6. `docs/world/WORLD_PRODUCTION_BIBLE.md`, `GREYBOX_RULES.md` e registros de segmentos.
7. ADRs 0001, 0003, 0007, 0008, 0010, 0020, 0021, 0024 e a 0025 recebida na main.

Regras operacionais que afetam diretamente a correção:

- Máximo de **250 linhas por GDScript**.
- `src/sim/` permanece puro; sistemas recebem dados e posições por parâmetro.
- Aleatoriedade passa por `RngService`, em fluxo nomeado.
- Balanceamento vem dos CSV; regenerar Resources pela ferramenta, não editar `.tres` à mão.
- Geometria e constantes estruturais podem ser constantes de código conforme §47. Isso não autoriza mover balanceamento arbitrário para `const`.
- Texto visível fica em `data/i18n/strings.csv`, PT-PT/EN.
- Usar sinais do catálogo existente. Acrescentar um sinal exige tratar a fonte e o contrato.
- Função pública de simulação precisa de teste. Escrever regressões que reproduzam o problema antes da correção.
- Não reescrever as seções geradas de `docs/design/` manualmente.
- Não abrir refatorações globais, dependências ou novos sistemas de IA para contornar um problema localizado.

O projeto combina documentação de épocas diferentes. Contagem de arquivos, presença de Resource e status antigo “feito” não equivalem a feature entregue. Usar o código e as medições atuais para atualizar o estado.

## 7. Inventário da fatia local

### 7.1 Arquivos já versionados e modificados

| Grupo | Arquivos | Papel na alteração |
|---|---|---|
| Execução | `project.godot` | Godot 4.6/GL Compatibility e stretch em viewport |
| Tick e ações | `src/core/sim_loop.gd`, `verbs.gd` | Caça, refresh de trabalhos, save e alternância da muralha |
| Trabalho | `src/sim/systems/job_board.gd` | Vagas de construção, revisão e cache de roster |
| Interface | `src/ui/game_hud.gd`, `data/i18n/strings.csv` | Painel compacto e contexto/objetivos |
| Mundo | `band_view.gd`, `build_view.gd`, `terrain_art.gd`, `terrain_backdrop.gd` | Rotas novas de desenho |
| Assets | `.gitattributes`, `.gitignore` | Exceções para o recorte autoral recuperado |
| Estado documental | `README.md`, `docs/recovery/RETOMADA.md`, `validation.json` | Contagens atualizadas parcialmente; há afirmações obsoletas |

No início desta revisão, o diff dos arquivos tracked mostrava 15 arquivos alterados, 260 inserções e 283 remoções. Essa estatística **não inclui** os novos arquivos abaixo nem o volume binário. É uma fotografia do worktree, não uma previsão do tamanho do PR final.

### 7.2 Novos arquivos ainda não commitados

| Arquivos | Conteúdo |
|---|---|
| `src/sim/systems/hunting_system.gd` | Estado puro da caça e serialização |
| `src/core/hunt_watch.gd` | Clareiras, rendimento diário e integração com RNG |
| `src/ui/kingdom_context.gd` | Objetivo sugerido e descrição do alvo do Rei |
| `src/actors/original_art.gd` | Manifesto, atlas, frames e perfis autorais |
| `src/world/citizen_art.gd` | Desenho das unidades com os sprites recuperados |
| `src/world/hunt_view.gd` | Coelhos procedurais |
| `src/world/pixel_brush.gd` | Primitivas de desenho |
| `src/world/kingdom_landscape.gd` | Fundo/terreno por faixa |
| `src/world/kingdom_buildings.gd` | Edifícios e estados |
| `src/world/kingdom_castle.gd` | Castelo-árvore procedural |
| `tests/hunting_test.gd` | Quatro testes de caça |
| `tests/kingdom_loop_test.gd` | Três testes de obras/postos |
| `tests/wall_choice_test.gd` | Dois testes da escolha da muralha |
| `tools/aseprite_source.py`, `tools/export_originals.py` | Leitura e export reprodutível das fontes |
| `art/source/originals/` | `troop.aseprite`, `concept.aseprite`, `archer.aseprite` |
| `art/export/enramados/` | PNGs, imports e `manifest.json` |
| Este relatório | Estado auditado e plano de retomada |

Os arquivos GDScript também possuem UIDs locais. Conferir quais entram no commit junto com os scripts.

### 7.3 O que essa fatia representa

É uma tentativa de ligar economia física, trabalho e identificação visual. Não é arte final, campanha completa nem substituto das cenas autoradas ausentes. Os testes novos comprovam comportamentos delimitados; ainda não comprovam uma partida natural financiável do início ao amanhecer.

## 8. Medições reais desta auditoria

| Verificação | Resultado | Limite da evidência |
|---|---|---|
| Godot recuperado | `4.6.stable.official.89cea1439` | Binário local temporário |
| Import headless | Concluído; a suíte subsequente carregou os scripts | Não mede GPU |
| Suíte completa | 642 descobertos; 633 passados; 3 falhas; 6 saltados; 0 erros; 0 orphans | Árvore local antes de integrar main |
| Novos testes da fatia | 4 de caça + 3 de loop + 2 de muralha passaram | Cobertura parcial |
| `gdformat --check` | 238 arquivos ficariam inalterados | Formatação |
| `gdlint` | Sem problemas | Não substitui G4 |
| `export_originals.py --check` | Fontes/exports correspondem byte a byte | Não valida aprovação artística |
| Dossiê vs CSV | 197 valores conferidos; 0 divergências | Consistência dos números cobertos |
| `content_report.py --check` | Passou | Conteúdo/esquema coberto |
| `check_claims.py` | 0 divergências nas contagens cobertas | Não validou “zero falhas” histórico |
| `git diff --check` | Passou | Whitespace |
| Vistoria, parâmetro 10 dias | Exit 0; sem invariantes apontadas; castelo caiu no dia 1 | Não sobreviveu dez dias |
| Export de pacote Web | `--export-pack Web` concluiu; manifesto e sprites incluídos | Não é export HTML/WASM completo |
| Browser/GPU desta branch | Não executado com êxito | Sem captura atual para aprovação visual |
| Preview desta branch | Não identificado/publicado nesta auditoria | Não confundir com main |

### As três falhas

| Teste | Resultado observado | Diagnóstico |
|---|---|---|
| `architecture_test.test_sem_literais_de_balanceamento` | Lista G4 não vazia | 650 literais não permitidos em nove arquivos |
| `jogo_test.test_largar_tira_do_saco_e_nao_cria_moeda_do_nada` | Esperava 1 moeda, encontrou 2 | Caça de introdução acrescenta moeda no tick inicial |
| `semente_jogo_test.test_sem_semente_largar_numa_arvore_larga_a_moeda` | Esperava 1 moeda, encontrou 2 | Mesma interferência da caça |

Não contar 650 diagnósticos como 650 testes falhados: é uma falha de teste de arquitetura, com 650 ocorrências reportadas.

### Os seis testes saltados

| Teste | Razão registrada |
|---|---|
| `candeia_test.test_uma_luz_domina_por_ecra` | Q-078: farol de 300 px vs candeia até 260 px |
| `noite_do_07_test.test_a_noite_5_ganha_se_com_1_a_2_mortes` | Q-073: capacidade da estacaria e cenário do §07 |
| `noite_do_07_test.test_a_noite_8_perde_se_sem_torre` | Q-073: comportamento medido das muralhas/noites |
| `noite_do_07_test.test_dez_dias_em_menos_de_dez_segundos` | Q-074: limite dependente da máquina |
| `design_data_test.test_arqueiros_nao_param_ariete` | Q-001: números de TTK do dossiê |
| `dez_dias_test.test_e_possivel_sobreviver_dez_dias_a_recusar_todas_as_ofertas` | Q-101: defesa cai ao dia 9 no cenário de recusa |

Esses skips são dívida explícita de design/teste; não devem ser apagados para “ficar verde”.

### A leitura correta da vistoria

Trecho essencial:

```text
vistoria — 10 dias no greybox com piloto, semente 20260916
dia 1: alvorada → manhã → meio-dia → tarde → crepúsculo → noite
o castelo-arvore caiu ao dia 1 — a partida acabou
vistoria: 10 dias sem nada a apontar
```

`tools/vistoria.gd` interrompe a simulação ao cair o núcleo. O resumo final usa o horizonte pedido, não os dias efetivamente concluídos. O `Autopilot` explica no próprio arquivo que não joga bem de propósito; ele exercita os sistemas.

Portanto: **foi medida uma derrota do piloto, não provada a impossibilidade de vencer**, nem demonstrada uma regressão contra a base. A sequência inicial merece teste próprio. Q-068 já documenta conflito entre a noite introdutória garantida da prosa e a massa de inimigos dos dados.

### O export que efetivamente foi feito

Comando executado:

```bash
/tmp/empire-resume-runtime/Godot_v4.6-stable_linux.x86_64 --headless --path . --export-pack Web /tmp/empire-audit-export.pck
```

O log registra `res://art/export/enramados/manifest.json`, `actors.png.import`, as texturas importadas e o Rei. A hipótese de que o manifesto seria necessariamente omitido por `include_filter=""` **não se confirmou neste pacote**. Não acrescentar filtros ou trocar arquitetura de assets para corrigir um problema que esta evidência não mostrou.

Ainda faltam o export Web completo com template, a inicialização no browser e a leitura visual. Não renomear esta verificação para “jogo Web aprovado”.

## 9. P0 técnico: o portão G4

A distribuição medida das ocorrências foi:

| Arquivo | Ocorrências |
|---|---:|
| `src/core/verbs.gd` | 1 |
| `src/ui/game_hud.gd` | 49 |
| `src/ui/kingdom_context.gd` | 1 |
| `src/world/citizen_art.gd` | 26 |
| `src/world/hunt_view.gd` | 22 |
| `src/world/kingdom_buildings.gd` | 220 |
| `src/world/kingdom_castle.gd` | 149 |
| `src/world/kingdom_landscape.gd` | 136 |
| `src/world/pixel_brush.gd` | 46 |
| **Total** | **650** |

O portão em `tools/lint_rules.gd` percorre `src/`, não apenas simulação. Ele admite poucos literais básicos e ignora declarações de constantes. Grande parte das ocorrências novas é geometria ou layout, não economia; ainda assim elas quebram o contrato atual.

**Correção recomendada:** organizar dimensões e composição em constantes com nomes semânticos ou tabelas declarativas de desenho. Separar dados de forma da função que desenha ajuda a manter cada script abaixo de 250 linhas. Números que realmente afinam custo, rendimento, espera ou dificuldade continuam nos dados apropriados.

Evitar duas falsas soluções: desativar G4 nos arquivos novos ou criar centenas de nomes sem significado apenas para satisfazer o scanner. O objetivo é tornar as decisões localizáveis e revisáveis.

`SimLoop` está com 244 linhas; `JobBoard`, 227; `BandView`, 224; `GameHud`, 138. Acrescentar lógica indiscriminadamente ao loop principal provavelmente exigirá extração de um coordenador pequeno, não uma reescrita do sistema.

**Aceitação:** o teste de arquitetura passa, sem ampliar exceções para esconder as ocorrências, e a geometria continua equivalente em captura.

## 10. Caça: implementação, falha e trabalho restante

### O que existe

`HuntingSystem` armazena dia, posições de coelhos, flag de introdução e cooldown por unidade. A cada tick:

1. Atualiza cooldowns e remove entradas de unidades inexistentes.
2. Retorna sem produção se não há luz diurna ou coelhos.
3. Percorre unidades por ID estável.
4. Exige perfil com tag `hunter`, unidade viva, SURFACE, fora de FIGHT/FLEE.
5. Permite uma captura introdutória por unidade sem dono apenas no dia 1, controlada por flag global.
6. Remove o primeiro coelho em alcance e devolve uma moeda física com origem `hunt`.

`HuntWatch` sorteia uma quantidade pela curva `hunt_yield` no fluxo `economy` e abre clareiras em posições fixas relativas ao núcleo. O save inclui esse estado.

### A falha de introdução

A primeira clareira fica em −160 px do núcleo. Um arqueiro inicial fica em −180 px. O primeiro tick abre o dia, encontra alvo em alcance e imediatamente gera moeda. Não há espera nem etapa visível correspondente ao minuto 1:10 de §25/§83.

Isso explica os dois testes que encontram uma moeda extra. A captura pode acontecer antes de o jogador observar a relação entre coelho, arqueiro e rendimento.

**Correção proposta:** autorar o momento introdutório de modo observável e compatível com os dados/relógio. A especificação dá o marco de 1:10, mas a sua relação com o slider de duração do dia deve ser tratada explicitamente. Não colocar “70” solto no tick e não alterar só a expectativa dos testes para dois.

Antes de implementar, escrever uma regressão de integração que registre a origem das moedas e comprove: a primeira ação do jogador não se mistura com uma captura involuntária; a demonstração acontece uma vez; salvar/carregar não a repete.

### O que ainda não constitui caça autônoma

O sistema **não atribui um destino de caça**. Ele só captura um coelho já em alcance. Um arqueiro sem posto pode continuar seguindo o Rei; um arqueiro atribuído à defesa pode não visitar a clareira. A existência de coelhos desenhados e moedas de captura não fecha sozinha o ciclo de renda.

O dado `hunt_yield` tem nota de rendimento **por saída**, enquanto `HuntWatch` o interpreta como estoque **diário**. Essa diferença precisa de pergunta/decisão explícita. Também se deve distinguir a exceção didática perto do núcleo da regra do §06 de sair das muralhas durante o dia.

Há ainda uma interação a medir: o arqueiro sem dono pode procurar e apanhar a própria moeda pelo `RecruitSystem`. Isso não é necessariamente errado, mas pode impedir que o jogador veja/receba a recompensa prevista. Medir antes de decidir.

### Próxima fatia recomendada de caça

- Coordenar destino diurno de caçadores com o JobBoard/follow, mantendo combate e fuga prioritários.
- Evitar que vários caçadores persigam o mesmo coelho sem critério determinista.
- Liberar ou substituir o destino quando a presa acaba, o dia muda ou chega perigo.
- Produzir feedback visual de preparação/disparo/acerto sem transferir a decisão de acerto para a apresentação.
- Preservar consumo, cooldown e reprodução determinista no save.
- Limitar clareiras aos segmentos adequados; hoje as posições são fixas do greybox.

**Testes necessários:** presa fora do alcance requer deslocamento; combate interrompe caça; noite não rende; presa não paga duas vezes; save no meio da ação não duplica moeda; trocar de faixa invalida o alvo; mesma seed e sequência de intenções reproduzem resultado.

## 11. Trabalho, produção e construção

### O que melhorou no código local

`JobBoard.publish()` passa a publicar vaga de `build` para obras em SCAFFOLD/BUILDING. Edifícios de pé mantêm os postos normais. A republicação considera também o nível, permitindo refletir novos postos de uma muralha melhorada.

`refresh()` evita reatribuições sem alteração aparente. O roster observado contém fase, revisão, IDs, donos e a condição “vida > 0”. O loop chama esse refresh na mudança de fase ou a cada fatia de IA.

Vagabundos com tag `worker` recebem aptidão provisória de construção baseada na afinidade de plantação. Há um Resource de posto `build` no projeto; não se trata de uma referência inexistente.

Os três testes novos comprovam: um trabalhador chega a uma obra já em scaffold e ela termina; uma construção concluída e um recruta novo recebem atualização de posto na mesma fase; upgrade de muralha republica postos.

### Limites e riscos a tratar

| Ponto | Consequência possível | Próximo teste ou correção |
|---|---|---|
| Roster não inclui faixa ou perfil | Reatribuição pode ficar desatualizada após passagem/troca de classe | Alterar faixa/classe mantendo vida/dono e verificar posto |
| `clear()` não limpa caches `_publicadas`/`_roster` | Limpar e republicar layout idêntico pode não reconstruir vagas | Regressão direta clear → refresh |
| Layout alterado limpa memória de atribuição | Trabalhadores podem trocar mais do que o esperado | Adicionar obra e verificar estabilidade dos postos não afetados |
| Construção usa presença física de tropas | O papel de “construtor” continua provisório | Conferir Q-064 e manter a regra declarada |
| Follow, combate e jobs escrevem destino | Uma escolha posterior pode sobrepor outra | Testar precedência com ameaça e obra simultâneas |
| Teste coloca a fazenda diretamente em SCAFFOLD | Não prova capacidade de pagar a construção | Teste do gesto físico com o saldo inicial |

Q-064 explica que hoje todos os presentes contribuem igualmente; não aprova automaticamente todas as novas regras de prioridade/afinidade. Documentar a adaptação de worker como opção temporária e reversível.

### Produção ainda não é a cadeia econômica completa

`EconomySystem.on_phase()` acumula fração do rendimento por transição de fase, converte inteiros em moedas físicas e considera o rasto da Podridão. A conversão imediata é o provisório de Q-065.

A produção atual não consulta ocupação do posto para essa passagem econômica. Ter um trabalhador desenhado na fazenda não significa que a produção dependa dele. Não afirmar uma dependência que o código não aplica.

Há funções para modelo de renda, manutenção, ganância e comércio, mas função matemática testada não equivale a rota comercial com carroça jogável. A próxima evolução precisa separar esses níveis de conclusão.

### Reparação

O contexto reconhece DAMAGED e mostra vida, mas o código de construção explicita que reparo com moeda/ofício ainda é assunto aberto. Não escrever um objetivo de “repare a muralha” sem que o gesto, o custo e a execução existam de ponta a ponta.

## 12. Muralha, contexto e comandos

`Verbs.consume()` tenta a passagem ao receber ASSUME; sem passagem válida, tenta alternar o caminho de muralha. `choose_wall()` exige Rei válido/vivo, proximidade e mesma faixa, e delega o bloqueio de caminho ao slot.

Os testes novos cobrem distância inicial, alternância junto ao muro, bloqueio no nível 2 e impossibilidade de atuar através de faixas.

Dois pontos merecem regressão:

- **Prioridade divergente:** `KingdomContext.current()` procura construção antes de passagem, enquanto o verbo tenta passagem antes de muralha. Se os contextos se sobrepuserem, o painel pode anunciar uma ação e E executar outra. Na disposição atual podem estar separados; ainda é um risco de integração que deve ser fechado.
- **Estados e custo já comprometido:** verificar caminho durante pagamento parcial, obra em andamento, dano e nível máximo. O texto deve informar somente ações realmente válidas, inclusive quando a escolha deixou de ser reversível.

O caminho escolhido precisa aparecer no mundo por silhueta, ocupação e estrutura. Uma bandeira de cor distinta ajuda, mas não substitui a leitura “mais postos” versus “mais resistência”, especialmente com daltonismo.

Ações já previstas no dossiê — trocar classe, montar, roda real e impulsos — não devem ser consideradas implementadas apenas porque a tecla E/Tab existe no mapa.

## 13. Interface: assistência útil, mas ainda provisória

O novo `GameHud` mostra dia/fase, moedas/capacidade, população, objetivo de estado e contexto do alvo. Usa chaves de tradução e glifos do dispositivo. Foram acrescentadas 24 chaves, totalizando 329 na árvore auditada.

O objetivo segue a sequência: trabalhador, caçador, produção, muralha, exploração; a ameaça noturna sobrepõe defesa. É uma primeira orientação, mas pode mandar o jogador perseguir uma etapa sem dinheiro ou sem ação acessível.

O §24 pede informação majoritariamente diegética e somente o relógio de dívida como elemento permanente fora do mundo. O painel compacto continua sendo **assistência de greybox**, não a realização completa dessa regra.

Pontos a verificar:

1. O contador de população inclui o monarca e qualquer dono não zero. Definir o que o rótulo pretende contar antes de chamá-lo de “tropas”.
2. Restaurar ou substituir feedback útil perdido na reescrita: o HUD antigo tratava passagem, alvo marcado e pausa; o novo conecta quatro eventos.
3. Contexto, preço físico e ação devem usar a mesma elegibilidade/prioridade.
4. Texto da muralha deve distinguir estado atual de benefício do próximo nível.
5. PT-PT/EN precisam caber em janela, fullscreen e resolução do Deck.
6. Layout em coordenadas fixas de 1280×720 e mudança de stretch precisam de inspeção de escala.
7. Mensagens de “aguardando trabalhador”, “faltam moedas” e “bloqueado” precisam corresponder a estados reais, sem inventar uma mecânica.
8. Pausa deve suspender a simulação e deixar o contexto coerente após retomar.

A meta visual é transferir explicações para chapéu, ferramenta, obra, moeda, postura, luz e som, mantendo ajuda acessível quando necessária.

## 14. Arte, renderização e regressões potenciais

### A integração autoral recuperada

`OriginalArt` lê o manifesto, carrega texturas/atlas e escolhe frames por duração. `CitizenArt` coloca o sprite pelo pé, aplica facing, pequeno bob, sombra e chapéu de recrutado.

A fonte `archer.aseprite` está marcada como conceito rejeitado e `runtime_allowed=false`. O perfil de arqueiro usa temporariamente o corpo `vagrant` com arco procedural. O Rei está marcado `redesign_required`; soldado e cozinheiro são referências próximas do final.

O export determinista passou. Isso comprova correspondência entre fontes e recortes, **não aprovação de desenho, escala, animações ou comportamento facial**.

### Problemas concretos de apresentação a fechar

| Achado no código | Implicação |
|---|---|
| Perfil desconhecido vira `knight` em CitizenArt | Classes sem mapeamento, como lanceiro, perdem diferenciação visual |
| OriginalArt não escolhe tag por FSM | Idle em loop e bob não substituem walk, attack, work, flee e die |
| Vida reduzida não seleciona face ferida nessa rota | O feedback facial de GB-20 pode deixar de aparecer no jogo, mesmo com testes antigos verdes |
| Arco muda de lado, mas offsets internos não são espelhados | A arma pode ficar orientada incorretamente ao virar |
| Chapéu é desenhado por perfil e propriedade | Conferir se cobre rosto/acessórios ou aparece em unidades erradas |
| Desenho procedural do castelo ignora o sprite autoral disponível | Recuperar um asset não significa integrá-lo à cena |
| Canteiros vazios usam placas/icones | O convite de silhueta fantasma de §25 pode ser substituído por outra linguagem sem validação |
| Passagem também recebe retângulo de BandView | Pode cobrir degraus detalhados desenhados no backdrop |
| Caixa de PriceTag continua vindo da geometria antiga | Preço pode flutuar longe ou sobrepor o novo telhado |
| Castelo é desenhado antes do tratamento de estado no renderer novo | Conferir aparência de núcleo danificado/caído |
| Dicionários de facing/posição guardam IDs desenhados | Conferir limpeza em remoção/novo mundo e comportamento ao reentrar na tela |

O ponto dos estados de obra tem um caso de código importante: `BuildView` passa o valor `blink(tempo)` para `KingdomBuildings`; dentro de `_site()`, esse parâmetro volta a ser usado em `sin(time * 3)`. Não é o tempo original. Revisar a semântica para evitar um pulso praticamente estacionário ou diferente do feedback testado.

### Assets recuperados ainda não ligados ao cenário

Há exports de castelo, portão, árvore, armazém, casa de treino e oficina. `KingdomLandscape` e `KingdomCastle` continuam desenhando principalmente primitivas. A próxima etapa visual deve escolher uma linguagem e um conjunto de referências por função, em vez de manter dois caminhos desconectados de arte.

O manifesto e o exporter referem `docs/art/REFERENCE_AUTHORITY.md`, mas esse documento não existe na árvore auditada. Recuperar a autoridade registrada no trabalho anterior ou ajustar a referência com rastreabilidade. Não inventar um documento de aprovação.

### Escala e configuração

`project.godot` mudou o stretch de `canvas_items` para `viewport`. A ADR 0001 ainda é proposta e descreve outra configuração e um spike em 1080p/Deck. Essa mudança precisa ser conferida contra a decisão visual, especialmente nitidez, tamanho de UI e leitura de rostos.

Não reduzir automaticamente os recortes atuais para 32×32/64×64 para “cumprir escala”. As preferências do utilizador e a fonte autoral exigem redesenho consciente quando há incompatibilidade, não destruição dos detalhes por reamostragem.

## 15. Uma cena de referência para substituir o cenário indistinto

**Proposta de trabalho:** fechar primeiro a cena de abertura dos Enramados, conforme o segmento autorado de §25/§83 e a cena-cartaz da bíblia de mundo. A cena-cartaz final prevista inclui ambiente completo, edifícios, personagens e luz; ela deve virar padrão para o resto, não um mockup externo ao jogo.

A composição deve permitir identificar:

| Elemento | Características visuais úteis | Comportamento que confirma a função |
|---|---|---|
| Castelo-árvore | Arco/portão, alvenaria, tronco integrado, escala monumental com entrada humana | Centro do reino e consequência clara quando atacado |
| Estacaria/muralha | Ritmo de pilares/dentes, material por nível, caminho visível | Tropas assumem postos e ruptura muda a defesa |
| Torre | Plataforma elevada, sustentação e acesso | Arqueiro ocupa posição correspondente ao benefício |
| Plantação | Canteiros, plantas e delimitação de cultivo | Trabalho e rendimento surgem daquele lugar |
| Pesqueiro | Água situada no mundo, cais, ferramentas de pesca | Produção visível e coerente com o bioma |
| Galinheiro | Cercado/abrigo e animais próprios | Leitura distinta de casa de treino |
| Casa de treino | Área e ferramentas de atividade reconhecíveis | Só anunciar treino quando o fluxo estiver implementado |
| Passagem | Abertura contínua entre faixas, degraus e ponto de interação | Descida legível e consequência estratégica |
| Ruína/segredo | Sinal de história e descoberta, sem parecer construção pronta | Recompensa de exploração |
| Amargueiro | Árvore com rosto identificável, linguagem própria da Podridão | O reconhecimento depende de preservar o rosto anterior |

Critérios de composição:

- A linha pisável precisa se ler sem depender do rodapé de comandos.
- O cenário distante tem menos contraste e detalhe competitivo que a área interativa.
- Partes ornamentais do castelo não encobrem Rei, moeda, alvo e passagem.
- Repetição modular recebe variação e costura; ruído aleatório não substitui autoria.
- Se houver água/reflexos, fazer com que correspondam ao terreno e à câmera. Não colocar água em toda a base se isso apagar o corte subterrâneo que diferencia Empire.
- Animação ambiental não deve competir com o sinal de ataque, ganho de moeda ou perigo.
- Render de dia, crepúsculo e noite deve preservar os contornos funcionais, inclusive sob filtros de acessibilidade.

A aprovação deve usar capturas reais da mesma build, com seed e enquadramento registrados. Não usar uma imagem gerada como prova de que a implementação está pronta.

## 16. Como transformar o deslocamento em gameplay

O movimento horizontal é o meio de visitar decisões. O problema aparece quando o jogador não sabe o que procura, não recebe consequência pelo investimento ou precisa acompanhar manualmente uma tarefa que deveria ter sido delegada.

### Ciclo curto

O primeiro investimento deve mudar imediatamente a leitura da cena: a moeda cai, a pessoa a recebe, o chapéu/ferramenta identifica a mudança e a unidade parte para uma tarefa plausível. Se uma obra paga aguarda mão de obra, isso precisa ser observável.

O primeiro rendimento deve ter origem perceptível. O jogador precisa ligar coelho, arqueiro e moeda, ou fazenda e colheita, e conseguir empregar esse ganho na próxima decisão.

### Ciclo do dia

Durante a luz, o jogador escolhe entre renda, defesa e exploração. Ao aproximar a noite, precisa ter sinais suficientes para decidir voltar e concluir a preparação. A noite mostra se a preparação funcionou; o amanhecer devolve informação, perda ou oportunidade.

Não obrigar o Rei a ficar parado sobre uma obra para a construção continuar quando o trabalhador já foi designado. Não obrigar o jogador a escoltar continuamente a renda para compensar falta de destino dos caçadores.

### Ciclo de expansão

Quando o circuito curto estiver comprovado, a expansão deve abrir uma decisão com contrapartida: abrir passagem também abre risco; investir em conversão troca lucro imediato por capacidade; poupar um povo pode abrir comércio. São sistemas do dossiê, mas precisam de gestos e feedback concretos antes de serem anunciados como presentes.

### Abertura e orçamento: ponto de teste obrigatório

Os dados atuais fornecem 6 moedas iniciais. Um trabalhador custa 1, um arqueiro 3, uma plantação 4 e a primeira estacaria 6. Essa cesta custa 14 moedas, antes de perdas ou desvios: exige pelo menos 8 de receita adicional. A moeda introdutória sozinha não resolve.

| Exemplo de sequência, sem outras receitas | Saldo |
|---|---:|
| Início | 6 |
| Recrutar trabalhador | 5 |
| Recrutar arqueiro | 2 |
| Recolher a moeda introdutória | 3 |
| Tentar plantação de custo 4 | Falta 1 |

É uma demonstração de dependência econômica, **não prova de bloqueio em todas as estratégias**. Caça adicional, produção, ordem diferente e outras moedas mudam o saldo. O teste correto deve medir uma sequência natural completa, registrando origem e gasto das moedas.

Não resolver esse risco dando renda invisível ou aumentando o saldo inicial sem decisão de design. Primeiro provar se a receita prevista é acessível a tempo e se o jogador compreende como obtê-la.

## 17. Roteiro da abertura: dossiê versus implementação

Os marcos abaixo vêm de §25 e §83. Os horários são referências de design; algumas durações e condições atuais divergem e já geraram perguntas no repositório.

| Marco | Experiência desejada | Estado/ação para a retomada |
|---|---|---|
| 0:00 | Rei, 6 moedas, ruínas/árvore, vagabundo e Amargueiro velho | Greybox dispõe entidades; conferir composição e estado visual do núcleo |
| 0:20 | Uma moeda recruta; chapéu comunica mudança | Mecânica existente e testada; manter identidade facial |
| 1:10 | Arqueiro caça coelho, moeda demonstra renda | Novo sistema captura no primeiro tick; precisa de autoria temporal/espacial |
| 2:00 | Indício de segredo desperta curiosidade | Segredos existem; avaliar leitura sem marcador excessivo |
| 3:30 | Primeira estacaria convidativa, custo 6 | Construção existe; provar orçamento, disponibilidade e execução física |
| Crepúsculo/noite 1 | Ameaça visível; defesa introdutória compreensível | Q-068/Q-073; piloto perdeu no dia 1 |
| Amanhecer | Recompensa, luz e tropas retomam atividade | Sistemas históricos existem; conferir preservação no renderer novo |
| Dia 2 | Casa de treino como promessa de profundidade | Presença de slot não equivale a treino de ofício funcionando |
| 10:00 | Descobrir passagem e perceber camada inferior | Comando existe; conferir sobreposição visual e contexto |
| 11:00 | Semente/diário recompensam exploração | Sistemas de segredo/diário existentes; validar fluxo humano |
| 12:00–14:30 | Abertura traz invasão/perda, rosto vira Amargueiro e decisão aparece | Sistemas parciais existem; a identidade facial é requisito, não detalhe |
| 17:00–18:00 | Primeira Oferta ensina gesto barato e consequência | Conferir ADR 0023/Q-104; não mover o dia para imitar a tabela isolada |
| 20:00 | Uma unidade ganha Nome e valor afetivo | Feitos/Nome têm implementação parcial; validar representação e reconhecimento |

A abertura deve ensinar pela disposição do mundo. Um painel com lista de tarefas pode auxiliar o greybox, mas não substitui a sequência autorada.

## 18. Matriz do dossiê: o que existe e o que continua faltando

Esta matriz cobre as frentes relevantes ao pedido. Não é uma auditoria de cada linha das 87 seções.

| Frente | Base existente | Falta para chamar de experiência entregue | Prioridade |
|---|---|---|---|
| Movimento/câmera | Limites, lookahead, interpolação e comandos | Conferência visual de escala, parada, zoom/resolução | P1 |
| Moeda física/recrutamento | Circuito e testes históricos | Eliminar interferência inicial e melhorar leitura/feedback | P0/P1 |
| Obras/trabalhadores | Slots, estados, nova atribuição de build | Fluxo pago natural, cache, prioridade e estados visuais | P0/P1 |
| Caça | Sistema puro, spawn de clareiras, save, desenho | Timing, deslocamento, origem visível, retorno/defesa | P0/P1 |
| Produção básica | Moeda por fases e reação ao rasto | Atividade visual e clareza da regra de trabalhador | P1 |
| Muralhas/torres | Níveis, caminhos, combate/postos | Escolha contextual consistente e aparência por nível | P1 |
| Noite e Podridão | Simulação integrada e testes | Abertura financiável, ritmo, leitura e conflito de design | P1 |
| Subsolo/segredos | Passagens, faixas, segredos e diário | Cenas autoradas, continuidade visual e descoberta | P1/P2 |
| Arte de personagens | Fontes reais recuperadas | Rei/arqueiro finais, classes, animação/FSM e faces | P1/P2 |
| Mundo autorado | Greybox procedural e novas primitivas | Cenas de segmento ausentes, composição e cena-cartaz | P1/P2 |
| Amargueiros/candeia | Parte XIII implementada em várias camadas | Confirmar continuidade facial e apresentação | P1/P2 |
| Ofertas/Dívida da Candeia | Ticket histórico registra quatro ofertas ligadas | Restante dos efeitos/preços e clareza em jogo | P2 |
| Nome/feitos | Registro histórico de cinco feitos observáveis | Demais observadores e expressão visual | P2 |
| Colheita | Base de regra/estado | Conquista que inicia e gesto da decisão, Q-103 | P2/P3 |
| Ofícios/conversão | Dados, perfis e modelo | Treino, logística e escolha moeda/capacidade completos | P2 |
| Comércio/diplomacia | Modelo numérico/dados | Rotas, carroças, risco e gestos jogáveis | P3 |
| Classes/montarias/roda | Mapa de entradas e dados | Fluxos completos e conteúdo visual de cada papel | P2/P3 |
| Conquista/sucessão/IA rival | Especificação e dados | Integração sistêmica e campanha | P3 |
| Capítulos | Planejamento determinista/dados/recompensas | Cenas, habitantes, leis completas e caminho alternativo | P3 |
| Áudio | Bíblia e registros | Gravações, implementação, mix e feedback no gameplay | P1/P2 |
| Localização/acessibilidade | Traduções e opções existentes | Inspeção no novo HUD/renderer e hardware | P1 |
| Publicação | Site/Vercel da main | Integrar trabalho atual, CI e preview verificado | Após P0/P1 |

P0 significa bloqueio técnico ou evidência enganosa. P1 é o mínimo para a próxima fatia jogável reconhecível. P2 amplia a profundidade de um núcleo já demonstrado. P3 é expansão; não deve consumir a retomada inteira enquanto a abertura continua fraca.

As contagens de pistas de áudio divergem entre documentos históricos. Esta auditoria não fez inventário completo de áudio; não repetir “56” ou “73” como medição nova. O mesmo vale para backlog desatualizado: há tickets marcados por fazer apesar de código/testes históricos existentes.

## 19. Plano de execução recomendado para o Astra

### Etapa A — preservar e corrigir a base de evidência

- Conferir branch, HEAD e worktree completo, incluindo untracked.
- Ler este relatório e comparar a main recebida.
- Guardar um checkpoint local revisável; integrar main sem perder o novo site.
- Corrigir a documentação de estado: `RETOMADA.md` ainda mistura 642 casos com 627 passados e zero falhas; `validation.json` conserva data antiga, 37 passados e zero falhas.
- Manter histórico datado quando necessário. `check_claims` reconta estrutura, mas não transforma histórico em execução atual.

**Saída:** estado rastreável, sem declaração falsa de suíte verde e sem perda de trabalho.

### Etapa B — fechar os três testes vermelhos

- Refatorar geometria/layout para constantes ou dados declarativos, sem relaxar G4.
- Reproduzir e corrigir o evento introdutório da caça.
- Preservar o significado dos testes de conservação/origem de moeda.
- Rodar os testes direcionados e depois a suíte inteira.

**Saída:** zero falhas reais; skips existentes preservados e explicados.

### Etapa C — provar o primeiro circuito jogável

- Acrescentar teste que comece com a abertura normal e use intenções para gastar/recrutar.
- Tornar a caça acessível por comportamento de unidades, com prioridades claras.
- Provar chegada do trabalhador, construção sem o Rei e primeira receita coletável.
- Registrar saldo, origem das moedas, momentos de construção e resultado da primeira noite.
- Separar falha de implementação de conflito de design nas Q-068/Q-073.

**Saída:** uma sequência reproduzível sem manipulação direta de saldo ou estado de obra.

### Etapa D — fechar uma cena visual e suas ações

- Integrar as referências autorais e resolver perfis ausentes.
- Preservar feedback de vida, face, golpe, profissão e morte.
- Unificar posição/caixa desenhada com PriceTag, alvo e efeitos.
- Dar identidade a cada construção, terreno e passagem.
- Testar a cena em dia, crepúsculo e noite.

**Saída:** capturas reais comparáveis e uma pequena sequência em movimento, com os objetos reconhecíveis.

### Etapa E — só então ampliar uma decisão

Escolher uma única expansão do dossiê que aprofunde o circuito comprovado: por exemplo, completar um fluxo de ofício/conversão ou uma escolha de exploração. Escolha final depende do estado encontrado após A–D.

Evitar abrir simultaneamente montarias, vários povos, comércio completo, sucessão e campanha. Cada sistema novo exige representação, gesto, dados, save e teste; implementar só a classe vazia não atende ao pedido.

### Etapa F — integrar e publicar com evidência

- Reexecutar os portões após a integração da main.
- Exportar os alvos necessários e verificar o site.
- Associar preview ao SHA exato da branch.
- Percorrer o fluxo no browser, incluindo carregamento e save.
- Atualizar relatório/backlog com resultados concretos e limitações.
- Seguir a autorização aplicável para PR/merge/produção; não usar a cor verde do deploy da main como substituto.

A sequência não é estimativa de horas. O bloqueio visual e a decisão da abertura podem alterar o esforço; a conclusão deve ser medida por saídas, não por duração prometida.

## 20. Critérios de aceitação e roteiro de teste

### 20.1 Integração funcional

| Cenário | Evidência necessária |
|---|---|
| Novo jogo | Moedas iniciais corretas, estado limpo, ausência de recompensa introdutória prematura |
| Recrutar por moeda | Débito, arco/queda, pickup, dono e representação coerentes |
| Pagar construção | Dinheiro chega à obra; não é recuperado indevidamente pelo Rei |
| Rei afasta-se | Trabalhador continua e obra termina conforme regra de presença |
| Nova construção concluída | Postos disponíveis ainda na mesma fase |
| Upgrade de muro | Custo, caminho, vida e quantidade de postos atualizados |
| Caça diurna | Destino, captura única e moeda com origem identificável |
| Ameaça/anoitecer | Prioridade de defesa/fuga; nenhuma renda indevida de caça |
| Passagem | A ação exibida é a executada; não age em outra faixa |
| Save/reload | Coelhos, cooldowns, moeda, obras e caminho de muro sem duplicação |
| Novo jogo após derrota | Dicionários visuais e estado anterior não contaminam a nova partida |

### 20.2 Inspeção visual

Usar 1280×720 nativo e conferir também 1080p e proporção do Deck quando houver acesso ao hardware/ambiente. Não declarar “testado no Deck” por emulação de tamanho de janela.

Capturas mínimas úteis: abertura junto ao núcleo; rua com produção e defesa; obra em progresso; muralha ocupada; caça; entrada do subsolo; noite com ameaça. Registrar commit, seed, fase/hora e controles/assistência visíveis.

Verificar: pés no chão; armas e acessórios ao virar; texto sem corte em ambos idiomas; moeda visível; preços posicionados junto do objeto; rosto ferido/fuga reconhecível; passagem desobstruída; objeto próximo destacado sem apagar a leitura do entorno.

### 20.3 Playtest de compreensão e prazer

Os alvos documentados são primeira moeda antes de 40 segundos, primeira muralha antes de 4 minutos e descoberta do subsolo antes de 14 minutos. São metas de design a medir, não resultados desta auditoria.

Observar sem explicar:

- O jogador reconhece uma oportunidade e realiza o gesto?
- Consegue dizer de onde veio o dinheiro?
- Entende por que recrutou aquela pessoa?
- Percebe que a obra continua quando sai?
- Prepara algo antes da noite ou só espera?
- Sabe por que a defesa venceu ou perdeu?
- Descobre o subsolo e associa abertura a risco?
- Quer continuar quando acaba o período observado?

Anotar trechos de deslocamento sem objetivo, espera por tarefa, retorno obrigatório e tentativa frustrada. Isso responde diretamente ao pedido “não somente ficar andando”. A contagem de funcionalidades não responde.

### 20.4 Desempenho

Aumentar detalhes de cenário e reavaliar jobs tem custo. Preservar o backdrop que redesenha por mudança de luz, a interpolação de movimento e a fatia de IA.

Medir draw calls/custo de desenho e custo do tick com população representativa. Não extrapolar benchmark headless para FPS de browser. A mudança de renderer e escala torna essa comparação especialmente necessária.

## 21. Comandos e ambiente disponíveis

Binário que funcionou nesta auditoria:

```text
/tmp/empire-resume-runtime/Godot_v4.6-stable_linux.x86_64
4.6.stable.official.89cea1439
```

O arquivo antigo em `/workspace/scratch/3dc574a692e1/bin/Godot_v4.6-stable_linux.x86_64` estava truncado e falhava até no comando de versão. Não reutilizá-lo. O motor recuperado veio do release oficial e o ZIP passou na verificação de integridade de arquivo; isso não equivale a comparação com checksum assinado.

Os caminhos em `/tmp` e os ambientes de sessões anteriores podem desaparecer. Testar existência/versão antes de usá-los.

Comandos principais, a partir do repositório:

```bash
cd /workspace/scratch/7eed40b367f7/empire
git status --short --branch
git diff --stat
git diff --check

/tmp/empire-resume-runtime/Godot_v4.6-stable_linux.x86_64 --version
/tmp/empire-resume-runtime/Godot_v4.6-stable_linux.x86_64 --headless --path . --import
GODOT=/tmp/empire-resume-runtime/Godot_v4.6-stable_linux.x86_64 ./run_tests.sh -c
GODOT=/tmp/empire-resume-runtime/Godot_v4.6-stable_linux.x86_64 make vistoria DIAS=10

python3 tools/export_originals.py --check
python3 tools/check_dossie_vs_csv.py
python3 tools/content_report.py --check
python3 tools/check_claims.py
```

Ferramentas de estilo disponíveis nesta sessão:

```bash
PYTHONPATH=/workspace/scratch/3dc574a692e1/bin/pydeps python3 /workspace/scratch/3dc574a692e1/bin/pydeps/bin/gdformat --check src/ tests/ tools/
PYTHONPATH=/workspace/scratch/3dc574a692e1/bin/pydeps python3 /workspace/scratch/3dc574a692e1/bin/pydeps/bin/gdlint src/ tests/
```

Depois das correções, ler o Makefile atualizado e usar os portões completos dele. O build do site usa `tools/web/construir.sh`; mesmo fornecendo GODOT, ele precisa do template Web. O download via Node não concluiu nesta sessão; a transferência do binário oficial via curl funcionou. Não confundir ausência de template com erro do código do jogo.

A tentativa de Xvfb local não conseguiu abrir os sockets necessários. Não foi obtida renderização GPU por esse caminho. A infraestrutura de browser disponível também não deve ser presumida como tendo acesso ao localhost deste container. Usar um ambiente de visualização suportado ou um preview autorizado e acessível.

## 22. Evidências e correções de documentação

### Arquivos de evidência desta execução

| Evidência | Caminho local |
|---|---|
| Import | `/tmp/empire-resume-import.log` |
| Suíte completa | `/tmp/empire-resume-tests.log` |
| XML gdUnit | `reports/report_5/results.xml` |
| Relatório HTML gdUnit | `reports/report_5/index.html` |
| Vistoria | `/tmp/empire-resume-vistoria.log` |
| Export de recursos | `/tmp/empire-audit-export.log` |
| Pacote de recursos | `/tmp/empire-audit-export.pck` |

Os nomes report_N são gerados e mudam entre execuções. Guardar os resultados relevantes no checkpoint/CI quando a correção for entregue. Não depender permanentemente de arquivos temporários.

### Afirmações do relatório anterior que esta revisão substitui

| Afirmação anterior | Correção atual |
|---|---|
| Não há Godot utilizável | Foi recuperado e executado Godot 4.6-stable |
| A suíte ainda não pôde ser executada | Foi executada: três falhas reais |
| Gdlint limpo sugere arquitetura limpa | G4 falha com 650 ocorrências |
| Caça diurna já fecha o circuito | Captura em alcance existe; busca autônoma e abertura ainda incompletas |
| Nenhum novo export foi possível | Pacote de recursos exportado; Web completo ainda não |
| Abrir PR no default antigo | Conferir a divergência e seguir o destino main prescrito pelo projeto |
| Recolocar a passagem basta | A chamada voltou, mas pode cobrir detalhes do novo cenário |
| Traduções precisam esperar por import | O import foi executado; ainda falta conferir apresentação PT-PT/EN |
| Estado “zero falhas” pode ser repetido | É histórico/obsoleto para esta árvore |

`validation.json`, `RETOMADA.md` e o backlog precisam de reconciliação na próxima implementação. Esta revisão não os alterou para evitar misturar um relatório de auditoria com alegações globais de aprovação.

## 23. Briefing pronto para abrir a próxima sessão

> Continue o Empire em `henriquecoding/empire`, preservando o worktree de `gameplay/readable-kingdom-loop`. Leia primeiro `AGENTS.md` e `docs/recovery/ASTRA-RETOMADA-2026-09-25.md`. A prioridade é tornar a abertura agradável e legível, conforme Kingdom como referência e a identidade autoral do dossiê. A árvore local importa em Godot 4.6, mas a suíte tem 3 falhas: G4 com 650 ocorrências e dois testes de moeda afetados pela caça no primeiro tick. Há 633 testes passados e 6 skips declarados. A vistoria perde o castelo no dia 1 e não prova dez dias de sobrevivência. Feche essas falhas, prove o circuito natural moeda → recrutamento → trabalho → renda → defesa e valide visualmente uma cena autorada. Preserve as expressões e referências aprovadas; não use o arqueiro rejeitado como final. Integre a main atualizada sem perder o site do PR #29. Não confunda o status Vercel da main com o desta branch. Entregue evidências do build real, testes, capturas e limitações restantes. Não declare conclusão com base somente em quantidade de arquivos, contagens de testes ou screenshots ilustrativas.

**Resultado que o utilizador deve perceber na próxima entrega:** ele reconhece cada lugar e pessoa, toma decisões com consequências visíveis e quer continuar a jogar depois da primeira noite.

## 24. Seguimento — 26/09/2026

Esta secção acrescenta; não reescreve a auditoria acima, que continua a ser a fotografia de 25/09.

### O que o chat de 25–26/09 fez depois deste relatório

A fatia local foi reconstruída sobre a `main` e entrou pelo **PR #30** (`d85cfc7`). O CI desse PR ficou verde nos
seis *jobs*, e o deploy de produção da Vercel desse mesmo SHA ficou `READY` (confirmado a 26/09; era o passo que
o chat deixou por fechar, a aguardar o estado `pending`).

### Estado medido na `main` antes desta continuação

| Verificação | Resultado |
|---|---|
| Suíte gdUnit4 em `d85cfc7` | 649 casos, 643 a passar, 6 saltados, **0 falhas reais** (as três de §8 estão fechadas) |
| G4, `gdformat`, `gdlint`, G2, dossiê contra CSV, `check_claims`, export dos originais | limpos |
| Vistoria de 10 dias com piloto | sem invariantes quebradas; o núcleo cai na **noite 2** (era a noite 1) — Q-068 continua a ser a razão |

### O que esta continuação fechou

| Ponto do relatório | O que mudou | Prova |
|---|---|---|
| §8 — a vistoria dizia "10 dias sem nada a apontar" com o núcleo caído no dia 1 | O resumo diz os dias vividos: *"2 de 10 dias, o nucleo caiu — sem invariantes quebradas"* | `make vistoria DIAS=10` |
| §10 — a demonstração da caça | Medido: aos 70 s o coelho que caía era o de −760 px (fora do ecrã), morto pelo arqueiro sem dono de id mais baixo que tivesse **outro** coelho ao alcance. Passa a ser o da primeira clareira (−160 px), pelo arqueiro sem dono mais perto dele; se um caçador teu já o levou, a demonstração deixa de acontecer | `hunting_test` (dois novos), `abertura_natural_test` (falha sem a correção) |
| §10 — "salvar/carregar não a repete" | A clareira da demonstração vai no save (`intro_x`) | `abertura_natural_test` |
| §12 — o contexto anunciava uma ação que o verbo recusava | O painel e o Verbo 2 perguntam a mesma coisa (`Verbs.wall_choice_open`): muralha danificada ou em ruína já não diz "E escolher caminho" | `gameplay_loop_test` |
| §13.1 — "TROPAS" contava o monarca | Conta só quem é teu, sem o rei | `gameplay_loop_test` |
| §13.7 — mensagens que não correspondem ao estado | O "+1 moeda" aparecia quando o arqueiro **sem dono** apanhava a moeda da caça; passa a aparecer só quando entra no saco do rei | `gameplay_loop_test` |
| §19 C — provar o circuito sem mexer no saldo nem nas obras | Um teste joga a abertura só com os dois gestos do §61: recruta o vagabundo e o arqueiro (6 s), junta 4 moedas de caça (20 s), paga o canteiro (27 s), afasta-se, e o trabalhador acaba-o sozinho (34 s); a colheita cai no crepúsculo (225 s). Nenhuma moeda aparece por outra via | `abertura_natural_test` |
| §21 — "não foi obtida renderização" | Neste ambiente o Xvfb funciona: `xvfb-run -a make captura` tira capturas reais (Mesa em *software*). O `--novo` antes de outra opção engolia-a; o parser da captura passou a tratá-lo como bandeira | `tools/captura.gd` |

### O que a medição deixou como pergunta, e não como decisão

- **Q-106** — a caça é um stock do dia e esgota-se em 30 s depois de recrutar o arqueiro; o CSV fala de moedas
  "por saída". Três opções escritas; nada mudou nos dados.
- **Q-107** — a moeda do 1:10 fica com o arqueiro sem dono que a caçou, 0,8 s depois (baixa-lhe o preço para 2).
- **Q-068 / Q-073** continuam: a noite 1 não é "ganha de certeza" com os dados de hoje.

### O que as capturas reais mostram, e continua por fazer

Capturas de 26/09, 1280×720, a partir de `tools/captura.tscn` com `--novo` (a semente é aleatória e a
ferramenta escreve-a na saída, `Empire · semente N`; o dia e a fase ficam na ficha `.json` ao lado do PNG):

- O castelo-árvore autoral e os corpos originais aparecem e leem-se de dia; o preço e a ação por cima do que
  está debaixo do rei (canteiro 4, muralha 6, vagabundo 1) estão certos.
- **O subsolo é uma grelha de caixas escuras vazias** e o painel de contexto assenta em cima dela — é a queixa
  de 25/09 (§3: *"não reduzir o subsolo a uma faixa quase invisível"*) e continua de pé.
- **À noite as tropas quase desaparecem** contra o fundo; é a regra do §80, mas pede a verificação de §20.2.
- Canteiros vazios leem-se como placas e contornos fantasma finos; a §15 continua por fazer.

### Próximo passo recomendado

A etapa D (§19): uma cena autorada da abertura — subsolo com conteúdo e ligação legível à passagem, e cada
obra com silhueta própria —, validada com capturas desta mesma ferramenta, dia, crepúsculo e noite. E uma
resposta à Q-106, que decide se o dia tem motivo para andar depois dos primeiros trinta segundos.
