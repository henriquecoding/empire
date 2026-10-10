# Empire — relatório mestre de auditoria

**Data de corte:** 9 de outubro de 2026.
**Projeto:** Henrique Passos · `henriquecoding/empire`.
**Base auditada:** `main`, commit `b419b6e2672ba7e779344034d448303c3da6b022`, publicado em 8 de outubro.
**Produção:** [empire-phi-eight.vercel.app](https://empire-phi-eight.vercel.app).
**Natureza da entrega:** auditoria de implementação, conformidade com decisões, qualidade e publicação. Nenhuma correção foi aplicada ao jogo, nenhum PR foi integrado e nenhuma resposta do painel foi alterada.

**Navegação:** [Diagnóstico](#1-diagnóstico-executivo) · [Método e limites](#2-método-fontes-e-limites) · [GitHub/Vercel](#3-estado-de-github-ci-e-publicação) · [Matriz de implementação](#4-matriz-mestre-planeado-versus-implementado) · [20 achados](#5-achados-prioritários-e-critérios-de-correção) · [Entregas a preservar](#6-o-que-já-foi-entregue-e-deve-ser-preservado) · [Decisões](#7-o-que-depende-de-decisão-e-o-que-já-pode-avançar) · [Plano de execução](#8-plano-de-execução-recomendado) · [Aceitação](#9-matriz-mínima-de-aceitação-para-os-próximos-marcos) · [Segurança](#10-segurança-privacidade-e-operação) · [187 tickets](#anexo-a--inventário-integral-dos-187-tickets) · [40 respostas novas](#anexo-b--todas-as-respostas-ainda-marcadas-nova) · [Fontes](#anexo-c--mapa-de-fontes-verificáveis) · [Evidências](#anexo-d--pacote-de-evidências-e-reprodução).

## 1. Diagnóstico executivo

O Empire tem um protótipo solo substancial, com uma base de simulação e de testes organizada. Já existem exploração, fundação livre, progressão da sede, construção com trabalhadores, combate manual dos imperadores, economia, floresta persistente, subsolo, sucessão básica, conquistas abstratas e publicação web funcional.

**A implementação ainda não corresponde ao jogo completo descrito nos seus planos mais recentes.** A principal distância está na integração entre sistemas: o mundo social ainda aparece pronto durante a exploração do primeiro dia; a sucessão mantém regras anteriores às suas decisões; o território considera proximidade, mas não todo o percurso de acesso e abastecimento; o tesouro físico ainda não governa a manutenção doméstica; os cenários novos estão integrados principalmente como apresentação, sem todas as construções e passagens funcionais.

Também há problemas concretos de qualidade. Foi reproduzida uma fundação aceite que gera uma cave real sem área útil e com entrada ainda publicada. A curva noturna continua com valores que divergem das aprovações Q-242/Q-243. O orçamento gráfico continua ultrapassado nas medições do projeto. A publicação observada ficou pronta antes de terminar a suite completa do mesmo commit.

### O que exige atenção primeiro

1. **Corrigir a cave real inválida após explorar subsolos e fundar noutro local.** É um bug reproduzido nesta auditoria, não apenas uma hipótese de arquitetura.
2. **Aplicar e medir a curva noturna aprovada.** O runtime continua com rampa de cinco noites e pico na sexta; aprovou sete noites de rampa e primeiro pico na noite doze.
3. **Completar o contrato do Dia Um e do despertar social.** Congelar o relógio até fundar está feito; impedir civilizações prontas antes da fundação e fazê-las evoluir por calendário ainda não.
4. **Atualizar a sucessão e a economia de ausência.** O herdeiro neutro, a troca escolhida, a manutenção contínua e o tesouro doméstico ainda não formam o sistema aprovado.
5. **Fechar desempenho gráfico e publicação com gates efetivos.** A melhoria recente de CPU é real; não resolve os draw calls, a resolução de renderização no toque nem a validação em aparelhos.

Não foi confirmado um incidente P0, perda generalizada de dados ou comprometimento de segurança. Isso não constitui uma certificação de ausência de vulnerabilidades: os limites de acesso e de teste estão descritos adiante.

### Números que podem ser usados com segurança

| Indicador | Resultado verificado | Como interpretar |
|---|---:|---|
| Scripts GDScript em `src/` | 425 | Dimensão do código, não maturidade do produto |
| Ficheiros de testes em `tests/` | 269 | Inventário, não número de jornadas humanas validadas |
| Testes descobertos pelo CI | 1.875 | 1.873 executados e aprovados; dois ignorados |
| Erros/falhas/flaky/orphans na suite do CI | 0/0/0/0 | No commit auditado e nos cenários cobertos |
| Tickets no backlog central | 187 | 127 marcados feitos, 20 parciais, 40 por fazer |
| Respostas no painel consultado | 229 | 189 `aplicada`, 40 `nova` |
| Escolhas no painel | 118 aprovar; 105 outra; 6 adiar | `outra` exige ler o texto; não equivale a rejeição |
| Cenários pintados integrados | 8 reinos + 13 transições | 21 cenas, 129 camadas; não são 21 níveis funcionais completos |
| PRs abertos | 2 | #24 em rascunho e #61 de dependência |

**Não atribuo uma percentagem de conclusão ao jogo.** Os 127 tickets feitos incluem entregas de protótipo, documentação e componentes cujo contrato foi posteriormente ampliado. Dividir 127 por 187 criaria uma medida enganadora.

## 2. Método, fontes e limites

### 2.1. O que foi cruzado

- Repositório, configuração de build, código de simulação/apresentação, CSV, recursos gerados, testes, ADRs e backlog.
- Planeamentos de monarcas, evolução do reino, primeiro dia, despertar do mundo, território, subsolo, vegetação, HUD e cenários; versões consolidadas em `docs/reports`, `docs/recovery` e `docs/design`.
- Guia e planeamentos de cenários de 7–8 de outubro disponibilizados nos seus ficheiros.
- Respostas atuais do painel Supabase, incluindo o texto das decisões Q-195–Q-248. A última atualização observada foi em 7 de outubro, 05:06:48 UTC.
- Estado de branches, PRs, status de deployment e CI do SHA exato.
- Produção pública: manifesto de versão, rotas, ficheiros do jogo, cabeçalhos, cache e compressão.
- Execução de sondas de integração no Godot 4.7.2 e inspeção das capturas do CI do commit auditado.

Foi adotada a precedência do próprio projeto: **decisão explícita recente do dono → especificação consolidada e decisões aceites → ADR/relatório → dados, preservando `_proposed` → implementação e provas de entrega**. Um relatório de proposta não aprova os próprios números; uma linha `feito` não prova que todo o sistema futuro está concluído.

### 2.2. Classes de evidência

| Etiqueta | Significado |
|---|---|
| **R — reproduzido** | Observado em execução nesta auditoria, através de uma sonda ou leitura HTTP verificável |
| **C — código/configuração** | Comportamento demonstrado pelo fluxo de código ou configuração, sem uma sessão humana completa |
| **CI — execução existente** | Resultado dos jobs e artefactos do GitHub Actions no SHA auditado |
| **D — documento/decisão** | Requisito ou medição registada pelo projeto; quando histórica, conserva essa data |
| **V — visual** | Observação das capturas do CI, com commit e proveniência |
| **N — não verificado** | Falta acesso, dispositivo, campanha longa ou decisão para concluir |

As sondas usam os sistemas reais do jogo com semente e estado controlados. A posição do rei é definida diretamente para chegar ao cenário de interesse: isto reduz o tempo da reprodução, mas não equivale a jogar todo o percurso com teclado ou toque.

### 2.3. Limitações materiais

**Vercel:** o conector autenticado apresenta outra equipa e não dá acesso administrativo ao projeto Empire, alojado em `hamriki-s-projects`. A consulta ao deployment identificado pelo GitHub devolveu 403 de âmbito. Foi possível verificar a produção pública e o status da integração GitHub/Vercel. Não foram auditados logs privados de build/runtime, variáveis, utilização, faturação, configuração integral de domínios ou definições internas de proteção do projeto.

**Execução local:** a importação do projeto funcionou e as sondas dirigidas foram executadas. A execução completa local de gdUnit ficou sem processo recuperável após a interrupção do ambiente e o log não contém conclusão. Por isso, **não é contabilizada como suite local completa aprovada**. O resultado completo de referência é o CI verde do mesmo SHA: 1.873 aprovados e dois ignorados. Falhas de materialização do binário no ambiente de auditoria não foram classificadas como bugs do Empire.

**Dispositivos e visual:** foram inspecionadas capturas atuais do CI a 1280×720 e do seletor compacto. Não foi realizada nesta sessão uma campanha manual em Safari/iPhone, Android, Steam Deck ou GPU física. Não há medição nova de FPS mobile, bateria, temperatura ou Core Web Vitals de utilizadores reais.

**Segurança:** a verificação de políticas do painel foi de leitura. Não houve pentest, carga abusiva, envio de feedback real, alteração de decisões ou acesso a dados pessoais desnecessários.

## 3. Estado de GitHub, CI e publicação

### 3.1. Versão entregue

| Superfície | Evidência |
|---|---|
| `main` | `b419b6e2672ba7e779344034d448303c3da6b022` — PR #100, desempenho |
| Manifesto de produção | Mesmo SHA; ramo `main`; ambiente `production`; Godot 4.7.2 |
| Publicação declarada | 08/10/2026, 16:36:22.238 UTC |
| Status Vercel no GitHub | Sucesso às 16:36:28 UTC |
| CI completo | Sucesso às 16:52:41 UTC |
| Nova conferência após retomar a auditoria | GitHub e produção permaneciam no mesmo SHA |

[Commit auditado](https://github.com/henriquecoding/empire/commit/b419b6e2672ba7e779344034d448303c3da6b022) · [CI completo](https://github.com/henriquecoding/empire/actions/runs/37810026878) · [Deployment identificado](https://vercel.com/hamriki-s-projects/empire/GHTgDHmfo85B7Tvi7SdcYp6aP1HD) · [Manifesto público](https://empire-phi-eight.vercel.app/versao.json).

### 3.2. Verificações positivas

O CI concluiu os jobs de gates estáticos, dados/gdUnit, exports Linux/Windows/Web, site, capturas/silhueta noturna e usabilidade do dossiê. A suite registou 15 min 7 s de execução. Os artefactos desktop disponibilizados pelo workflow chamam-se `empire-linux-debug` e `empire-windows-debug`: a existência destes pacotes não certifica uma distribuição comercial otimizada.

O smoke test público `tools/web/fumo.mjs`, executado contra o SHA esperado, terminou com sucesso: `/`, `/en/`, `/jogar/`, `/dossie/`, redirecionamento de `/jogar`, 404 própria, fontes locais, CSS com hash/cache, cabeçalhos de segurança, MIME de WebAssembly, Brotli e disponibilidade do PCK. Isto confirma a entrega HTTP; o arranque e a interação em navegador são sustentados pelo job de site do CI, não por uma nova sessão manual nesta auditoria.

Foram ainda executados localmente os gates `dossie-numeros`, `conteudo`, `manifesto`, `inventario-arte`, `afirmacoes` e `densidade-prova`, sem divergências reportadas. O gate de afirmações valida inventários selecionados; não verifica automaticamente a atualidade de todos os resultados de testes publicados.

### 3.3. Trabalho aberto no GitHub

| PR | Estado | Leitura de auditoria |
|---|---|---|
| [#24 — arte original dos Enramados](https://github.com/henriquecoding/empire/pull/24) | Rascunho | Branch divergente: três commits próprios e 293 atrás de `main`. É trabalho histórico a reconciliar; não deve ser integrado em bloco sem separar o que já foi substituído |
| [#61 — actions/checkout 4 → 7](https://github.com/henriquecoding/empire/pull/61) | Aberto | Manutenção de CI; não representa funcionalidades de gameplay em falta |

Não havia issues ordinárias abertas na consulta; os itens devolvidos eram estes PRs. Isso não significa ausência de bugs: a maior parte do controlo do trabalho vive no backlog do repositório e no painel.

`main` aparece sem proteção e a API de rulesets devolveu lista vazia. No deployment observado, o sucesso Vercel antecedeu o fim do CI completo em **16 min 13 s**. Há, portanto, uma lacuna verificável entre publicar e terminar a validação, mesmo que esta publicação tenha acabado verde.

## 4. Matriz mestre: planeado versus implementado

| Área | O que já funciona ou existe | O que falta ou diverge | Estado real |
|---|---|---|---|
| Entrada e Dia Um | Três imperadores iniciais; caravana; três cidadãos; exploração e relógio congelado até fundar | Mundo social ainda aparece organizado antes de fundar | Parcial; divergência de contrato |
| Fundação livre | Escolha no ponto do rei, paragem, prioridade de interação, assinatura territorial, limpeza persistente | Reconciliação com subsolos já gerados pode criar cave inválida | Implementado com bug reproduzido |
| Bancas e contratação | Bancas fundadoras após fundação; martelo pago; corrida à moeda; ofícios por IA | Fechar as provas de percurso de cada dupla e de ocupação de postos | Base implementada |
| Evolução da sede | Clareira → Acampamento → Povoado → Vila → Vila Fortificada → Fortaleza; vida, custos, obras e requisitos | Capital, postos, rotas e administração de uma rede territorial | Parcial; não existe a etapa Capital |
| Construção e reparação | Muralhas em estágios; construtor necessário; reparação; desbloqueio por espaço/recinto/progressão | Infraestrutura e indústrias dos estágios tardios; UX de pessoal e preparação noturna | Base implementada, expansão pendente |
| Economia doméstica | Produção, custos, soldo com atraso/tolerância/deserção marginal; reservas de celeiro e tesouro físico | Tesouro pagar manutenção local; abastecimento/rotas físicos; comparação robusta de estratégias | Parcial |
| Imperadores e companhia | Rei, Nia e Arqueiro; ataques/habilidades; evolução; bardo pago; aljava paga; escudeiro arqueiro evoluído | Encontros persistentes, roster completo, quarto imperador, ritual e troca escolhida | Núcleo de três implementado; campanha parcial |
| Sucessão | Treino, casa, herdeiro pronto, continuação após morte | Herdeiro neutro, custo contínuo máximo, perda por incumprimento, seleção de desbloqueado e cinco noites de recuperação | Diverge da decisão mais recente |
| Combate | Ataque manual e habilidade separados; golpe próximo; munições; ameaças da Podridão | Combate presencial entre reinos, alvos de estruturas e unificação com cerco delegado | Parcial |
| Noite e dificuldade | Massa, ofertas, luz, emboscadas pagas desde noite três, rampa também para pressão diurna | Q-242/Q-243 não aplicadas; Q-240 ainda demasiado agressiva segundo a decisão | Divergência confirmada |
| Floresta e persistência | Árvores/relações funcionais, corte, limpeza de fundação e persistência; alterações recentes aprovadas | Afinidade regional geral; correspondência fina entre imagem/fauna e fontes | Base funcional, extensão pendente |
| Território e recursos | Água localizada, rocha/cavernas, elegibilidade por faixa/distância; previsão e confirmação comuns | Conhecimento, acesso, direito, exploração e abastecimento completos; tipos de água | Parcial |
| Clima | Quatro estações globais; inverno afeta produção/caça; reserva de celeiro | Clima geralmente quente e variação por bioma; assinatura climática funcional | Modelo antigo ainda ativo |
| Subsolo | Causas/famílias, geração à primeira descida, reserva de espaço, cave real, depósitos/retiradas e migração | Conflito fundação/cave; garantia de área útil em sítios obrigatórios; redes/transportes avançados | Parcial, com bug |
| Dungeons | Bocas, variação de salas e recompensa ligada à primeira geração | Ecossistema e variedade avançada; parte das extensões está adiada em Q-245 | Base implementada; extensão adiada |
| Povos e mercenários | Povos, edifícios locais, tesouraria e rotina de assentamentos; recrutamento/soldo | Nascimento e crescimento desde zero; companhias persistentes, negociação e compromissos | Parcial |
| Diplomacia | Dados e componentes legados de Diplomata | Acesso universal sob IA, missões, incursões, captura/resgate e dívida integrada | Planeado, não concluído |
| Conquista e campanha | Marcha abstrata, baixas, firmeza, vassalagem, tributo e memória | Tomada física de reino, governo inimigo, assimilação, logística e finais plenamente encenados | Protótipo estratégico parcial |
| Arte de personagens/obras | Sprites temporários, efeitos procedurais e inventário de runtime rastreável | Animações próprias por ação, rostos, arte definitiva e variantes por povo/estágio | Provisório, como autorizado |
| Cenários | Oito reinos e 13 transições com camadas no runtime | Três especiais, transições inversas, fachadas inferiores, escadas/casas funcionais, costuras | Integração visual parcial |
| HUD e acessibilidade | Primeira entrega Atlas, contexto, ficha de fundação; opções, toque e atalhos | Validação de toda a campanha em dispositivos, texto ampliado e todos os ecrãs | Parcial; não certificada |
| Áudio | Efeitos provisórios sintetizados em código | 73 cues de produção musical/sonora ainda TODO, identidade sonora e integração final | Provisório |
| Save/retoma | Formato v12, migrações, slots, validação, recuperação e persistência | Retoma exata da noite e matriz mais ampla de mundos antigos/extensos | Funcional com limitação explícita |
| Desempenho | Melhorias de CPU no PR #100 e testes dos atalhos | Draw calls, custo dos planos de luz, grandes sedes e aparelhos reais | Melhorado, orçamento ainda aberto |
| Site/painel | PT/EN, export web, CSP/cache, formulários e administração; RLS ativa | Indicadores publicados desatualizados e governação de releases | Funcional com dívida operacional |
| Coop/PvP | Contratos documentados | Coop local, dois reinos, rede, autoridade do servidor, reconexão e vitória competitiva | Futuro; não implementado |

## 5. Achados prioritários e critérios de correção

**P1:** corrigir antes de expandir o núcleo solo ou promover estabilidade. **P2:** importante para coerência, qualidade e manutenção. **P3:** completar antes de anunciar a funcionalidade ou o marco correspondente. A prioridade não representa autorização para executar mudanças neste relatório.

### AM-01 · P1 · Fundação cria cave real inválida após exploração

**Tipo:** bug de integração. **Evidência:** R + C. **Confiança:** alta.

Na semente `20261007`, foram visitadas as duas passagens iniciais usando `Verbs.assume`, antes de fundar. A fundação livre foi então aceite em `x=520` e, numa execução independente, em `x=2620`. Depois de gerar a cave real, `UnderFit.check` devolveu `no_bay`, mas `UndergroundSites.usable` continuou `true`.

| Fundação | Boca da cave real | Intervalo gerado | Resultado |
|---:|---:|---|---|
| x=520; deslocamento −1400 | 429,6524 | 381,6524–522,0 | Sem baía útil; entrada publicada |
| x=2620; deslocamento +700 | 2529,6524 | 2481,652–2660,116 | Sem baía útil; entrada publicada |

**Causa:** `FoundationChoice.valid` protege bocas e certos elementos, mas não garante espaço conciliado para a nova cave. `LastCartWatch.reanchor` reautora a sede sobre um mundo que pode ter layouts já gerados. `UndergroundSites.usable` aceita sítios obrigatórios mesmo sem reserva válida; `generate` pode usar o `CAP` quando não há limite válido. O teste `test_um_sitio_obrigatorio_sem_chao_publica_mas_diz_porque` inclusive codifica essa exceção.

**Impacto:** o jogador aceita um local aparentemente válido e recebe um subsolo que não cumpre o próprio contrato de área útil. Nos dois casos, a sonda também confirmou `chest_finite=false`: o baú não recebe uma posição finita, inviabilizando a interação normal de reserva nessa geometria. Isto concretiza o risco que a sua Q-237 já mandava resolver.

**Reprodução técnica:** iniciar a semente indicada; montar `Greybox`; visitar e sair de cada `SimLoop.passages` com `Verbs.assume`; posicionar o rei no ponto indicado, limpar alvo e avançar 1 s; chamar `FoundationChoice.claim`; gerar a cave através da boca; medir `why`, `span` e `usable`. A sonda completa acompanha o pacote de evidências.

**Correção recomendada:** resolver fundação e reserva subterrânea numa única transação. Escolher uma política explícita de conciliação: adaptar geometricamente a cave nova, reposicionar conteúdo não protegido ou recusar com motivo útil. Não eliminar dungeons/recompensas já descobertas em silêncio. Para um sítio acessível, a validação tem de garantir chegada, saída, baía e posição válida do baú.

**Aceitação:** os dois casos reproduzidos passam; saves repetidamente recarregados mantêm a geometria e o conteúdo; fundar antes/depois de visitar os mesmos subsolos não cria sobreposição nem entrada sem baía. Acrescentar a composição de sistemas aos testes existentes, substituindo a exceção permissiva quando o contrato for fechado.

**Fontes:** `src/core/foundation_choice.gd`, `last_cart_watch.gd`, `cellar_watch.gd`; `src/sim/systems/underground_sites.gd`, `under_reserve.gd`; `tests/subsolo_area_util_test.gd`; Q-237.

### AM-02 · P1 · Curva da noite não corresponde às aprovações

**Tipo:** decisão aprovada não aplicada. **Evidência:** R + C + painel. **Confiança:** alta.

| Regra | Decisão atual | Runtime/CSV auditado |
|---|---|---|
| Rampa de abertura | Q-242 aprovada: sete noites | `ramp_nights=5` |
| Primeiro pico | Q-243 aprovada: noite 12; depois a cada seis | `rhythm(6)=1.3`; primeiro pico na sexta |
| Estreia de espécie | Q-240: escalada 3/6/9 considerada agressiva | `debut_step=3` continua ativo |
| Pressão acumulada durante o dia | Q-239 aprovada | Aplicada à rampa |
| Emboscada no escuro | Q-241 aprovada | Paga da massa e inicia na noite três |

`data/source/rot.csv` e `data/rot/default.tres` concordam entre si; a divergência é entre implementação e decisão. O teste de ritmo ainda afirma a noite funda de seis em seis desde o princípio, pelo que uma suite verde mantém o comportamento antigo.

**Impacto:** o início pode pressionar demasiado cedo e dificultar apreciar/explorar o reino. A sonda do piloto morrer no dia quatro não prova isoladamente a causa, mas reforça a falta de uma trajetória integrada de aprendizagem e economia validada.

**Correção:** aplicar sete noites e um parâmetro explícito para a primeira noite funda; afinar a estreia de espécies com a mesma curva. Q-240 rejeita a agressividade, mas não fornece um número substituto definitivo: é preciso medir e apresentar uma proposta, sem inventar uma aprovação.

**Aceitação:** tabela das noites 1–20 com massa-base, fatores, espécies e picos; primeiro pico apenas na 12; aprendizagem viável com os três imperadores; derrotas explicáveis; atualização dos testes que perpetuam valores antigos. Preservar Q-239/Q-241, já implementadas.

### AM-03 · P1 · O mundo social ainda nasce pronto durante o Dia Um

**Tipo:** contrato de produto não concluído. **Evidência:** R + C + D. **Confiança:** alta.

O relógio realmente espera pela fundação. Porém, ao gerar a exploração a leste na semente `20261007`, a sonda encontrou **cinco assentamentos no dia um, com `foundation_committed=false`**. Foram gerados 37 segmentos; a posição foi avançada diretamente para testar a geração, não para medir duração de exploração.

`Frontier._aplicar` chama `SettlementWatch.author` quando um segmento nasce. A função cria casa, produção e defesas no nível um, tesouro, cidadãos, construtor, guardas e unidade do povo; não verifica o dia social nem exige a sua fundação. A rotina distante só existe para os registos já materializados.

**Planeado:** mundo inicialmente natural, exploração livre, sociedades/mercenários a surgirem depois, desenvolvimento desde zero e calendário independente da primeira visita. **Entregue:** exploração e fundação livres sobre sociedades geradas em estado inicial já organizado.

**Correção:** separar existência social, evolução temporal e materialização gráfica. Um registo de assentamento deve nascer por regras de mundo e atualizar-se sem depender da câmara; a primeira visita apenas o apresenta. Não basta esconder edifícios durante o Dia Um e fazê-los aparecer maduros no Dia Dois.

**Aceitação:** mesma semente e dia produzem o mesmo estado social visitando primeiro oeste ou leste; nenhum assentamento organizado antes da condição aprovada; crescimento e recursos conservados ao sair/voltar e salvar/carregar. Ticket principal: RG-24.

### AM-04 · P1 · O herdeiro mantém o contrato antigo

**Tipo:** decisões aprovadas não implementadas. **Evidência:** C + painel. **Confiança:** alta.

`Succession.dawn` deixa de cobrar quando `ready()` é verdadeiro. Se faltam moedas durante o treino, retorna sem apagar o progresso. `DawnWork._coroar` entrega à coroação o perfil do imperador que reinava. Estes comportamentos são coerentes com a implementação antiga e não com Q-196/Q-197/Q-202.

Faltam o herdeiro neutro até preparado, manutenção contínua mais elevada, desaparecimento por falta de pagamento, recompra, escolha entre imperadores desbloqueados no local de treino, reinício do ciclo após troca e recuperação de bónus em cinco noites. Encontrar um imperador também ainda não fecha o ciclo de roster persistente e troca.

**Impacto:** a principal ponte entre explorar novos imperadores, gerir dinheiro, morrer e variar gameplay ainda não existe na forma aprovada.

**Correção/aceitação:** tratar treino, pronto, manutenção, perda, escolha e coroação como estados explícitos e persistentes; transação única de troca; uma coroa soberana no solo; testes de falta de dinheiro, morte durante a troca, save/retoma e alteração do roster. UN-16/UN-17/UN-32. O quarto imperador e o ritual de Q-205/Q-206 são trabalhos próprios, não condições para corrigir o núcleo do herdeiro.

### AM-05 · P1 · Ter um tesouro físico ainda não torna o reino autónomo

**Tipo:** integração económica incompleta. **Evidência:** C + backlog. **Confiança:** alta.

Existem baús com depósito e retirada, reservas por celeiro e economias de assentamentos. Contudo, `UpkeepSystem.dawn`, `Succession.dawn` e `DawnWork._abastecer` debitam as moedas carregadas pelo rei. A presença de dinheiro no baú não alimenta automaticamente esses serviços domésticos pelo modelo local planeado.

**Impacto:** explorar longe continua ligado à carteira pessoal para despesas do reino; depósito físico, defesa e manutenção na ausência ainda não formam um sistema coerente. Não é correto dizer que “não existe tesouro”, mas também não é correto dar UN-19 por concluído.

**Correção:** distinguir carteira pessoal, tesouro local e carga em transporte; definir prioridades de pagamento e avisos; dar a cada débito uma origem e um destino auditáveis. Implementar rotas apenas depois de a contabilidade conservar recursos.

**Aceitação:** duas execuções com o rei presente/ausente e o mesmo estado doméstico produzem obrigações locais equivalentes; um baú vazio pode falhar explicitamente; depósitos e remessas não duplicam dinheiro ao carregar o save; não há débito remoto silencioso.

### AM-06 · P1 · Desempenho gráfico continua acima do orçamento

**Tipo:** dívida técnica medida; validação de dispositivos incompleta. **Evidência:** D + C + CI. **Confiança:** alta para as medições documentadas; N para FPS real em mobile.

O PR #100 removeu trabalho repetido de construção, visibilidade, fauna, toque, ordenação do Registry e desenho de tropas. A medição comparativa registou redução de aproximadamente 25–31% no tick e 5–19% em frames de cenários selecionados, preservando o estado final. Esses resultados são de CPU de servidor/render `dummy` e não devem ser anunciados como ganho de FPS em iPhone.

Persistem **cerca de 160–280 draw calls à noite**, perante um orçamento do projeto de 120. O relatório identifica subsolo, chão, faixa de superfície e HUD. Há ainda cerca de oito planos de ecrã inteiro com iluminação e renderização à resolução nativa no toque. Grandes fortalezas e o painel do reino continuam por medir.

**Correção:** medir uma cena representativa com GPU real; evitar desenhar o subsolo coberto; agregar ou pré-renderizar conteúdo estático; avaliar resolução interna do mundo separada da UI, conforme Q-262; preservar nitidez e leitura visual.

**Aceitação:** tabela por dispositivo e momento do jogo, com build, resolução, número de entidades, p50/p95/p99, draw calls e memória; antes/depois visual da mesma semente; cenário com Fortaleza e combate; orçamento revisto explicitamente se 120 deixar de ser a meta. Fonte: `docs/reports/DESEMPENHO-2026-10-08.md`.

### AM-07 · P1 · Produção não esperou pela validação completa observada

**Tipo:** risco de processo de release. **Evidência:** GitHub/configuração/produção. **Confiança:** alta para esta publicação.

O status Vercel ficou verde às 16:36:28 UTC; a suite e o job agregado só terminaram às 16:52:41. A branch `main` está sem proteção e a consulta de rulesets está vazia. Esta evidência não prova como todas as publicações anteriores foram feitas, mas confirma uma janela em que o novo jogo estava publicado sem terminar os gates do mesmo SHA.

**Correção:** configurar revisão/checks obrigatórios na branch e um fluxo que só promova o artefacto testado após gates completos. Se Vercel continuar a construir por push, separar deployment de preview de promoção a produção. O acesso administrativo à equipa Empire é necessário para fechar a verificação da configuração real.

**Aceitação:** provocar deliberadamente uma falha num branch de teste e demonstrar que esse SHA não chega à produção; associar commit, run e deployment; documentar rollback; verificar o manifesto e o smoke depois de promover. Não alterar produção durante esta auditoria.

### AM-08 · P2 · Proximidade de recurso não prova acesso ou abastecimento

**Tipo:** contrato territorial parcial, com contraexemplo reproduzido. **Evidência:** R + C + D.

A sonda levantou as escoras das passagens iniciais: `Passages.open` passou a zero. Mesmo assim, os dois poços de minério conservaram `terrain_bar=""`, antes e depois de `TerritoryWatch.apply`. `TerritoryWatch._rocha` usa todas as passagens, não as passagens abertas, e `PlacementRules` verifica faixa, distância e quantidade.

**Limite da conclusão:** isto demonstra elegibilidade territorial sem acesso; não foi medido neste ensaio minério efetivamente produzido ou transportado através de uma passagem fechada. A ausência de uma regra completa de acesso já é reconhecida como fora do primeiro pacote RG-28.

**Impacto:** a interface pode apresentar um local como sustentável quando a cadeia operacional ainda não foi demonstrada. Os seis estados definidos no dossiê — existência, conhecimento, acesso, direito, exploração e abastecimento — ainda não estão representados integralmente.

**Correção/aceitação:** separar “fonte próxima”, “obra construível” e “atividade operacional”; usar uma relação de acesso persistente e legível; fechar uma passagem deve recalcular o motivo e a operação, sem apagar recursos nem obras existentes. Testar reabertura, outra entrada alternativa e save/retoma. Também faltam diferenciação de rio/lago/costa, portos e navegação: Q-249/Q-250/Q-252 contêm parâmetros/propostas ainda sem resposta observada.

### AM-09 · P2 · Clima regional ainda é uma marca vazia

**Tipo:** direção aprovada por implementar. **Evidência:** C + painel.

`FoundationChoice.signature_at` grava `climate_band="PENDING_CLIMATE_MODEL"`. `Seasons.at` calcula a mesma sucessão global de quatro estações e `yield_mult` zera agricultura no inverno sem receber bioma. Isto não concretiza Q-235: clima geralmente quente e agradável, com variação dinâmica em alguns biomas.

Existem reservas e alternativas parciais para o inverno; não é correto dizer que o jogo só tem uma penalização sem qualquer preparação. Falta, contudo, ligar clima, território, rendimento e comunicação ao bioma escolhido.

**Aceitação:** identidade climática determinística por região, assinatura persistida, perfil vivo de efeitos, recursos alternativos verificáveis e previsão que ajude a decidir onde fundar. Os números de chuva, duração e rendimento precisam de decisão própria. Evitar implementar meteorologia meramente cosmética e depois declarar RG-24 concluído.

### AM-10 · P2 · A tocha tem duas semânticas e falta a corrupção tardia

**Tipo:** integração incompleta e risco de compreensão. **Evidência:** C + painel.

Há uma luz visual permanente em `HandLight`, que não é consumida e não protege contra `Torchlight.in_dark`. Há também o archote comprado, consumível, que arde 60 segundos no modelo atual. Não existe a transição aprovada em Q-247, na qual a ferramenta só passa a gastar-se depois de um acordo que a corrompe.

**Impacto:** ver fogo na mão não significa estar protegido; o jogador pode não compreender por que surgem emboscadas. O comentário do código explica a diferença ao programador, mas não basta para ensinar quem joga.

**Aceitação:** contrato único ou distinção explícita entre luz e proteção; estado da corrupção persistente; antes do evento, comportamento aprovado; depois, consumo e aviso claros. Definir qual pacto/evento ativa a mudança antes de lhe atribuir uma regra definitiva. Testar retoma junto da mudança e a leitura sem som.

### AM-11 · P2 · Água funcional e água desenhada não coincidem plenamente

**Tipo:** legibilidade de gameplay. **Evidência:** C + D, sem nova inspeção de todos os locais.

O RG-28 corrigiu um problema importante: fundar longe da água já não leva consigo uma fonte gratuita para o pesqueiro. Contudo, a água inicial continua autorada em `core_original + 1292 px`, e Q-257 documenta que essa fonte funcional não tem representação correspondente no caminho. Um lago distante pintado não constitui automaticamente fonte utilizável.

**Impacto:** a pessoa escolhe um local olhando o cenário, mas a regra pode responder a outra geografia. A ficha territorial ajuda a diagnosticar; não substitui uma margem legível no mundo.

**Aceitação:** cada fonte utilizada no cálculo tem uma representação reconhecível e ancorada; decoração distante não sugere um recurso inexistente; preview, pagamento, obra e produção apontam para a mesma fonte. O Lago com Ponte e Cais é uma proposta de solução em Q-259, não uma localização já aprovada.

### AM-12 · P2 · Cenários foram integrados, mas o mundo funcional está incompleto

**Tipo:** integração parcial de arte e simulação. **Evidência:** C + D + V.

**Entregue:** oito reinos e 13 transições desenham o fundo e o chão; 21 cenas/129 camadas no inventário validado. A captura atual do CI confirma o novo cenário no jogo. É incorreto repetir que os pacotes ainda não foram integrados.

**Ainda pendente:** três propostas especiais; transições no sentido inverso a oeste; separação da árvore monumental do plano repetível; costuras em algumas pinturas; fachadas, escadas e casas inferiores ligadas às obras e passagens. `SceneryMap` procura o par ordenado esquerda→direita; a ausência do par inverso usa o encontro/fallback entre reinos, não a composição pintada equivalente.

A árvore monumental está num plano que se repete a cada 5120 px; Q-261 regista também costura no plano médio dos Portuários. São problemas documentados da composição atual, não provas de colisão ou de bloqueio do jogador. Fundos de transição de 1280 px não foram usados como parallax repetível porque revelariam a borda.

**Aceitação:** um trecho completo atravessável nos dois sentidos, nas fases Natureza/Fundação/Desenvolvido, com duas obras funcionais, recurso reconhecível e acesso inferior; nenhum desenho de escada promete uma passagem inexistente. Preservar as três faixas do jogo e a pequena altura útil inferior. Não introduzir gravidade/saltos apenas para justificar uma imagem.

**Decisões pendentes:** Q-259/Q-260/Q-261; a consulta do painel não encontrou respostas a essas perguntas. As 24 composições dos pacotes de arte não equivalem a 24 áreas jogáveis concluídas.

### AM-13 · P2 · Animações e identidade de produção continuam provisórias

**Tipo:** qualidade de apresentação/conteúdo ainda por produzir. **Evidência:** C + inventário validado + V.

O inventário `RUNTIME_ART.md` distingue fonte, exportação, chamada em runtime e aprovação. Muitas unidades usam os perfis temporários `royal_*`, com `idle`, `walk` e `flee`; faltam tags próprias de `attack`, `hit`, `die` e `work`. Em `ActorAction.shown`, ações sem tag regressam ao repouso, salvo a cadeia de fallback da fuga.

**Não significa ausência de feedback de combate:** há efeitos, poses e movimentos procedurais. Significa que a ação ainda não tem a animação autorada completa. Há também edifícios com a mesma imagem-base e poucas variantes por estágio/povo.

A utilização temporária de assets foi autorizada para testar gameplay; não é, por si só, um erro ou uma violação de direção artística. A dívida surge ao apresentá-los como arte definitiva ou ao tentar avaliar clareza e personalidade sem concluir o conjunto de ações.

**Aceitação:** matriz personagem × ação × estado, com tags exportadas e chamada real; direção e origem estáveis; escala baseada na decisão recente de 64×64, distinguindo quadro e corpo visível; primeira família completa antes de multiplicar variantes. A PR #24 deve ser reconciliada peça a peça, pois está muito atrás de `main`.

### AM-14 · P2 · Áudio de produção permanece por entregar

**Tipo:** conteúdo incompleto. **Evidência:** C + D.

`docs/audio/AUDIO_CUE_SHEET.csv` contém 73 linhas e todas continuam `TODO`. Não foram encontrados ficheiros `.wav`, `.ogg`, `.mp3` ou `.flac` no inventário de conteúdo do repositório. O jogo produz sons provisórios por síntese; portanto, não está silencioso.

Faltam a produção e integração final dos temas, motivos, ambientes e demais cues planeados. O aquecimento da síntese já foi distribuído para reduzir bloqueio de arranque, mas não substitui essa identidade sonora.

**Aceitação:** cue com ficheiro/licença ou fonte autoral, gatilho, prioridade, limite de vozes, volume, loop e legenda quando comunica gameplay; ouvir um ciclo diurno/noturno completo e uma derrota com/sem som. Não marcar todos os 73 concluídos por existir um sintetizador genérico.

### AM-15 · P2 · Dossiê e painel misturam inventário atual com resultados antigos

**Tipo:** bug de informação e dívida de rastreabilidade. **Evidência:** R + C + CI + painel.

O `/dossie/` publicado contém `gdunit_discovered=1875` e `gdunit_passed=1752`; o segundo número pertence a uma execução anterior. `validation.json` conserva data de 06/10 e base RG-23, ao lado de contagens já atualizadas. O painel usa estes campos para “Testes a passar”. O CI atual demonstra 1873 aprovados, não 1752.

Outros exemplos de reconciliação necessária:

| Registo | O que precisa de correção editorial |
|---|---|
| CONT-06 marcado `por fazer` | A deserção por custo marginal, atraso e tolerância já existem. Ainda falta provar integralmente os critérios económicos/UX do ticket; deve ser decomposto, não simplesmente encerrado |
| F2-01 diz que escudeiro de combate espera Q-114 | Texto anterior ao trabalho posterior de companhias e combate; atualizar a evidência e o âmbito restante |
| Q-239/Q-241 permanecem `nova` | Comportamentos já implementados; falta reconciliação de estado com publicação |
| Q-248 permanece `nova` | Persistência da limpeza/obras foi tratada na implementação posterior; confirmar matriz de migração antes de fechar |
| 40 respostas `nova` | Incluem seis adiamentos, decisões substituídas, implementação parcial e implementação já existente |
| Nove cenas autoradas de segmento em `source_gaps` | Não confundir cenas funcionais de segmento com as 21 composições de cenário incorporadas depois |

**Aceitação:** cada resultado publicado referencia SHA, run, data e escopo; inventário e execução em campos distintos; estado por critério de aceitação, sem sobrescrever o texto do dono. O snapshot de decisões é informação de produto, não prova automática de execução. Nenhum estado foi alterado nesta auditoria.

### AM-16 · P2 · A suite não fecha balanceamento, longa duração e dispositivos

**Tipo:** lacuna de verificação. **Evidência:** CI + C + D.

A suite completa verde é valiosa. Mas dois testes estão explicitamente ignorados: a expectativa de uma a duas mortes na noite cinco e dez dias em menos de dez segundos. As razões registadas são afinação de balanceamento e necessidade de medir em export de release.

A vistoria integrada, configurada para oito dias e semente `20260916`, termina no dia quatro porque o rei morre sem herdeiro. Não encontra invariantes quebradas; esse sucesso significa “não foi detetado estado impossível até à derrota”, não “oito dias foram jogados” ou “a economia é equilibrada”. Há testes de dez dias com harness preparado; estes também não equivalem a uma campanha humana desde a caravana.

**Aceitação:** manter testes unitários e acrescentar poucas jornadas integradas decisivas: fundação após exploração; economia viável até a torre/fortaleza; três imperadores; ausência com tesouro; sucessão; retorno a região; noite 12; save/retoma. Exigir que o piloto alcance os marcos que pretende validar ou declare explicitamente que falhou esse objetivo. Executar as sessões humanas de abertura já planeadas pelo projeto, sem substituir diversão por contagem de asserts.

### AM-17 · P2 · Fechar durante a noite ainda não retoma o ponto exato

**Tipo:** limitação conhecida de persistência. **Evidência:** C.

`SavePoint.allowed` só permite gravar antes do crepúsculo. O código explica que invocação, oferta em curso e `NightTally` não estão integralmente serializados. Ao pausar/fechar de noite mantém-se um checkpoint anterior; não há retoma exata garantida daquele instante.

**Impacto:** particularmente em mobile, interromper a aplicação pode obrigar a repetir progresso desde o último checkpoint. Não foi demonstrada corrupção de save: o problema é a granularidade e a comunicação da retoma.

**Aceitação:** escolher entre checkpoint explicitamente comunicado e serialização completa da noite. Se for retoma exata, comparar estado antes/depois no meio de oferta, emboscada, sucessão e troca de fase; se permanecer checkpoint, mostrar quando foi guardado e não prometer guardar ao fechar em qualquer momento.

### AM-18 · P2 · UX melhorou, mas precisa de validação do percurso completo

**Tipo:** qualidade de uso e cobertura, não um crash confirmado. **Evidência:** C + V + D.

As capturas atuais mostram HUD legível, objetivos, comandos e seletor compacto com scroll. A primeira entrega Atlas existe. Não há fundamento para repetir a crítica antiga de que o painel de fundação gigante ainda ocupa sempre o centro.

Persistem trabalhos de integração: mostrar falta de pessoal e consequência de desocupar um posto; preparação noturna; origem dos pagamentos; diferenciar luz de proteção; explicar recursos indisponíveis e acesso bloqueado. RG-05/RG-08/UN-28 continuam a delimitar essas lacunas. Tipografia/selo definitivos e algumas opções de apresentação estão em perguntas abertas, não aprovados por este relatório.

Há ainda uma discrepância concreta de acessibilidade: `OptionsPanel` e `Preferences` expõem contraste, daltonismo, flashes, legendas, duração do dia e preferências de toque, mas não expõem escala geral do texto ou remapeamento completo. A pesquisa de implementação não encontrou a edição correspondente de eventos do `InputMap`. A matriz de acessibilidade descreve esses recursos como objetivos e chega a prever declaração “sim” na loja; essa declaração deve esperar implementação e prova. Não confundir escala dos botões de toque com escala de texto.

As fotografias do site referenciam `f3efeac`, anterior aos cenários CV-02. Há um mecanismo que identifica fotografias antigas e texto de aviso no site; portanto, não classifico isso como uma falsificação de versão. Convém atualizar as capturas após fechar o próximo passe visual.

**Aceitação:** jogar do início à derrota e à retoma exclusivamente com teclado, comando e toque; testar texto ampliado, canhoto, corrida, analógico fixo, menus longos, reabertura e orientação do aparelho; mensagens de ação curtas com custo/motivo/consequência. Uma captura compacta bonita não certifica a acessibilidade de todos os ecrãs.

### AM-19 · P3 · Conquista, diplomacia e campanha ainda são sistemas parciais

**Tipo:** funcionalidades planeadas por concluir. **Evidência:** C + D + backlog.

Existe marcha abstrata: retira uma comitiva, calcula perdas e firmeza, devolve sobreviventes, cria vassalagem e tributo. Falta ligá-la à conquista presencial de unidades/obras e ao governo real do assentamento tomado, com uma única transição/recompensa mesmo quando cerco delegado e combate resolvem o mesmo alvo.

Também faltam o Diplomata universal sob IA e seu ciclo de missões/captura/resgate, encontros imperiais persistentes, ritual de recuperação de imperador, postos/rotas/Capital, evolução completa de ofícios e produção animal por identidade. Leis, canções, apresentação dos capítulos, diários e epílogos têm componentes e dados, mas a experiência completa não está fechada.

**Aceitação:** primeiro ciclo vertical de um povo: encontrar → negociar/atacar → conquistar → mudar governo → abastecer/defender → sair → regressar → salvar/carregar, sem duplicar unidade, tributo ou recompensa. Só depois generalizar ao resto da campanha. Tickets UN-16–28, UN-32/33, RG-12–15 e XIII-06–09 delimitam o trabalho.

### AM-20 · P3 · Coop e PvP continuam no planeamento

**Tipo:** funcionalidade futura; não é bug do modo solo. **Evidência:** C + D + backlog.

Não foi encontrado no código `src/` um transporte de multiplayer ou chamadas `@rpc`, `ENetMultiplayerPeer`, `WebSocketMultiplayerPeer` ou `WebRTCMultiplayerPeer`. UN-29/30/31 e RG-25 estão por fazer. O site na Vercel serve a build web; isto não constitui um servidor autoritativo do mundo.

Preservar as suas regras: no coop ambos pertencem ao mesmo reino e o criador da sala escolhe a fundação; no competitivo os jogadores começam em extremos opostos, fundam reinos separados e disputam a conquista. O desenho posterior consolidado prevalece sobre propostas antigas de partilha de controlo.

**Aceitação futura:** autoridade sobre moedas/obras/coroas, ordem de comandos determinística ou sincronização adequada, reconexão, save com várias identidades, tratamento de morte/sucessão simultânea, duas fundações, vitória e ausência de duplicação. Transporte/custos/serviço e certos parâmetros competitivos continuam por decidir em Q-236. Não é necessário bloquear a correção dos bugs solo à espera disto.

## 6. O que já foi entregue e deve ser preservado

Esta lista evita que a próxima implementação reabra correções existentes ou ressuscite modelos substituídos.

| Entrega existente | Evidência principal | Cuidado ao continuar |
|---|---|---|
| Fundação livre e gratuita com caravana | `FoundationChoice`, `CaravanWatch`, `SimLoop.step`, RG-23/ADR 0066 | Não voltar a limitar a escolha a dois locais predefinidos nem impor prazo artificial ao Dia Um |
| Bancas depois da fundação e dentro da progressão | `FoundationWatch`, `RealmGrowth`, testes de recinto fundador | Não disponibilizar todas as obras na Clareira |
| Trabalhador constrói/repara | Sistemas de empregos e reparação; decisões Q-210/Q-224 | Evolução de vida não pode substituir trabalho real |
| Recursos locais no preview e na confirmação | `TerritoryWatch`, `PlacementRules`, `territorio_fundacao_test` | Corrigir acesso sem reintroduzir pesqueiro gratuito em qualquer local |
| Limpeza de fundação e vegetação persistem | Manifesto de limpeza, save v12, testes de persistência | Não repovoar árvores removidas ao carregar um mundo antigo |
| Três imperadores e ação manual | `MonarchWatch`, combate e dados de monarcas | Não restaurar a troca de controlo de tropas/classes rejeitada |
| Nia, bardo pago, aljava e companhia arqueira | Q-198/Q-199/Q-200; testes de aljava/bardo/escudeiro | Seis flechas por moeda do imperador não são a reposição de 12 das tropas |
| Escuro pago e início na noite três | `DarkWatch`, Q-241, teste de escuro pago | Afinação de curva não pode criar inimigos fora do orçamento da Podridão |
| Soldo marginal e tolerância | `UpkeepSystem`, `upkeep_system_test` | Reconciliar CONT-06 preservando a correção já existente |
| Recuperação de save e legado | `Resume`, `SaveService`, `SaveMigrations`, testes de recuperação | Não ressuscitar uma campanha encerrada através de um slot mais antigo |
| Cenários atuais e Atlas inicial | ADR 0078/0081, CV-01/CV-02/UX-08 | Separar o trabalho funcional restante da integração visual já entregue |
| Otimizações do PR #100 | `FaunaGrid`, caches e recorte antes de cálculos caros | Manter equivalência de estado e ordem de desenho ao otimizar mais |
| Site estático, assets locais e segurança básica | `vercel.json`, build web e smoke público | Uma mudança de framework não resolve os problemas de simulação |

## 7. O que depende de decisão e o que já pode avançar

### 7.1. Já existe direção suficiente para implementar

- Corrigir a fundação que entrega subsolo inválido, respeitando a preservação do conteúdo conhecido em Q-237.
- Aplicar Q-242/Q-243 e medir o conjunto da curva; conservar Q-239/Q-241.
- Implementar o despertar social desde zero sem depender da primeira visita, conforme o plano consolidado.
- Implementar o contrato do herdeiro Q-196/Q-197/Q-202 e o acesso universal ao Diplomata Q-203.
- Fazer o tesouro e a manutenção local funcionarem na ausência, conservando recursos e avisos.
- Atualizar os indicadores do dossiê e a rastreabilidade de resultados, sem reescrever respostas do dono.
- Prosseguir a matriz de testes de input, persistência e desempenho, distinguindo resultados reais de metas.

### 7.2. Exige fechar parâmetros, arte ou âmbito

| Pergunta/tema | O que falta fechar | O que não deve ser presumido |
|---|---|---|
| Q-234 | Limiar de paragem/footprint e respetiva apresentação | Que todos os parâmetros técnicos atuais foram aprovados |
| Q-235/Q-252 | Números de clima e sequência de expansão territorial | Que a direção “quente e agradável” aprova uma meteorologia completa específica |
| Q-236 | Transporte, serviço online, reconexão e regras competitivas | Que Vercel já é o servidor do mundo multiplayer |
| Q-237 | Política concreta para conflito e migração de subsolo | Que se pode apagar conteúdo descoberto para abrir espaço |
| Q-240 | Nova cadência de estreia de espécies | Que rejeitar 3/6/9 aprova automaticamente 1/2/3 |
| Q-244 | Valores do contrato de área útil e teto de entradas | Que o teste de 1.000 sementes cobre todas as composições de fundação |
| Q-246 | Balanceamento do escudeiro arqueiro evoluído | Que o ataque já implementado tem números finais aprovados |
| Q-247 | Pacto/evento exato que corrompe a tocha | Que toda a luz gratuita já equivale a proteção |
| Q-249/Q-250 | Alcances/tipos de água, cais, portos e operação | Que um cenário pintado é uma fonte ou uma rota |
| Q-251 | Companhias mercenárias e compatibilidade dos acampamentos antigos | Que a regra atual de três contratações pode ser removida sem migração |
| Q-253–256 | Fontes/selo, parallax, gesto de fundação, paleta | Que as escolhas visuais propostas são finais |
| Q-258 | Afinidade regional | Que influência local e identidade de bioma são a mesma métrica |
| Q-259–261 | Especiais, transições inversas, peças/arte em falta | Que se pode espelhar toda a cena ou inserir os três especiais em qualquer sítio |
| Q-262 | Redução de resolução do mundo no toque e composição de lotes | Que aumentar desempenho autoriza desfocar a UI ou alterar silenciosamente a escala |

Não foram encontradas respostas às perguntas Q-249 em diante na leitura do painel. Não é preciso voltar a pedir decisões já dadas em Q-242/Q-243 ou sobre o sentido geral do herdeiro.

### 7.3. Adiamentos a respeitar

As seis respostas `adiar` são Q-081, Q-112, Q-147, Q-191, Q-194 e Q-245. São decisões de escopo, não seis bugs por corrigir imediatamente. Em particular, Q-245 adia extensões de subsolo como transporte avançado, certos ciclos de roubo/fuga e fauna cavernícola. **Corrigir uma cave inválida continua necessário**: é consistência do sistema já entregue, não ativação de toda a expansão adiada.

O texto do quarto imperador em Q-205 define esse conceito e sua escudeira; não aprova todas as outras propostas que acompanhavam a pergunta original. Q-226 estar `aplicada` também não prova que a Capital existe: pode representar a decisão de a colocar mais tarde.

## 8. Plano de execução recomendado

Esta sequência é uma recomendação técnica. Não foram atribuídas datas ou horas fictícias: há trabalhos de design, arte e dispositivos cujo esforço ainda não foi medido.

| Lote | Prioridade | Entrega concreta | Dependências | Critério para encerrar |
|---|---|---|---|---|
| 0 — Verdade do projeto | P1/P2 | Atualizar resultados por SHA; reconciliar backlog; proteger fluxo de release | Acesso à equipa Vercel para verificação completa | Dossiê mostra o run certo; falha de CI não promove produção; tarefas remanescentes explícitas |
| 1 — Fundação segura | P1 | Resolver AM-01 e garantir reserva/baú/saída | Política de conciliação de Q-237 | Casos x=520/2620 corrigidos; save/retoma idempotente; conteúdo preservado |
| 2 — Abertura apreciável | P1 | Curva aprovada; primeira torre economicamente viável; UX da noite | AM-02 e medição de Q-240 | Jornadas dos três imperadores atingem marcos; pico só na noite 12; custos e causas compreensíveis |
| 3 — Mundo que desperta | P1 | Calendário social, sociedades desde zero e estado independente de visita | RG-24; dados determinísticos | Ordem de exploração não altera arbitrariamente maturidade; persistência conserva estado |
| 4 — Economia territorial | P1/P2 | Tesouro local; acesso; direitos básicos; primeiros abastecimentos | AM-05/08; decisões de água/contratos | Conservação de recursos; ausência funcional; bloqueios explicados |
| 5 — Linhagem e encontro | P1/P3 | Herdeiro neutro, troca, roster, perda/ritual mínimo definido | UN-16/32 e decisões existentes | Um ciclo completo de desbloqueio/troca/morte/save sem segunda coroa solo |
| 6 — Território visível | P2 | Fonte de água visível; trecho funcional superior/inferior; transições coerentes | Q-259–261; contrato de acesso/subsolo | Arte, fonte, obra e percurso concordam nos dois sentidos |
| 7 — Qualidade de produto | P1/P2 | Orçamento gráfico; acessibilidade/input; animações e áudio prioritários | Dispositivos e arte | Matriz publicada por dispositivo; ações legíveis; opções implementadas e testadas |
| 8 — Campanha completa | P3 | Um povo com conquista física, governo, comércio e retorno | Economia, sucessão e território | Ciclo vertical completo antes de replicar a todos os povos |
| 9 — Modos com vários jogadores | P3 | Coop e competitivo progressivos | Autoridade, identidades, serviço e reconexão | Regras do anfitrião/dois extremos, persistência e vitória verificadas |

A ordem dentro dos lotes pode ser ajustada, mas acrescentar Capital, mais imperadores e modos online antes de fechar fundação, economia e sucessão aumentaria o número de interações ainda instáveis.

## 9. Matriz mínima de aceitação para os próximos marcos

Os itens abaixo são **testes recomendados**, não resultados já obtidos.

| ID | Cenário | O que deve provar |
|---|---|---|
| QA-01 | Semente 20261007, caves visitadas, fundar x=520 e x=2620 | Baía, baú e saída válidos; conteúdo antigo preservado |
| QA-02 | Mesma semente, fundar antes/depois de explorar | Resultado coerente; nenhuma duplicação ou perda silenciosa |
| QA-03 | Dia Um inteiro explorando os dois lados | Relógio congelado; caravana acompanha; nenhuma sociedade organizada prematura |
| QA-04 | Visitar sociedade cedo/tarde, em ordens opostas | Idade e recursos decorrem do calendário, não da câmara |
| QA-05 | Abertura com Rei, Nia e Arqueiro | Aprendizagem, fontes de renda e primeira defesa viáveis |
| QA-06 | Noites 1–20 e diferentes decisões de oferta | Rampa sete; primeiro pico 12; pressão previsível e consequência conservada |
| QA-07 | Rei ausente com/sem dinheiro no tesouro | Manutenção local, avisos e incumprimento explícitos |
| QA-08 | Selar/reabrir passagem de mina | Elegibilidade operacional e acesso concordam |
| QA-09 | Herdeiro em treino/pronto, falta de pagamento, troca e morte | Máquina de estados aprovada, uma coroa e save consistente |
| QA-10 | Exploração/conquista/retorno ao mesmo reino | Governo, tesouro, tropas, obras e recompensas persistem |
| QA-11 | Save atual e saves legados; carregar duas vezes | Migração idempotente; floresta/obras/baús não duplicam |
| QA-12 | Pausar/fechar durante oferta e emboscada | Retoma exata ou checkpoint comunicado, conforme contrato escolhido |
| QA-13 | Caminhar por água, porto, cave e transição nos dois sentidos | Arte representa fontes e acessos reais |
| QA-14 | Grande Fortaleza, exército e noite em aparelhos reais | Desempenho p95/p99 e legibilidade dentro do orçamento decidido |
| QA-15 | Apenas teclado; apenas comando; apenas toque | Todo o ciclo, incluindo menus, derrota, opções e retoma |
| QA-16 | Texto grande, contraste, daltonismo, flashes/som desligados | Nenhuma ação essencial depende de um único canal |
| QA-17 | Deploy com gate intencionalmente falhado | Nenhuma promoção de produção desse SHA |
| QA-18 | Publicação verde | Manifesto, WASM/PCK, arranque, ação real e rollback rastreáveis |

O caso dos 1.000 seeds de um gerador puro é útil para limites geométricos, mas não substitui QA-01/02: a falha reproduzida nasce da composição de exploração, layouts persistentes e fundação posterior.

## 10. Segurança, privacidade e operação

### Verificado

- RLS está ativa nas três tabelas observadas: `empire_admins`, `empire_feedback` e `empire_respostas`.
- A seleção de administradores restringe-se ao próprio utilizador; respostas têm política administrativa; leitura/alteração/eliminação de feedback exigem a função de administração.
- Inserção pública de feedback exige estado inicial `novo`, sem nota administrativa nem data de resolução. Essa inserção anónima é parte do produto, não foi tratada como vulnerabilidade só por existir.
- Não havia feedback não resolvido no resultado consultado. Ausência de reports não prova ausência de defeitos.
- As rotas públicas e o export apresentam os cabeçalhos esperados pelo smoke. Os scripts do export usam a CSP correspondente ao WebAssembly.
- O workflow declara permissões de conteúdo de leitura. Os problemas de processo identificados estão sobretudo na proteção/promoção de release e na atualidade das provas publicadas.

### Não certificado

Não foram verificados logs privados Vercel, segredos, permissões de toda a organização, faturação, limites contra abuso, recuperação completa do serviço ou todos os caminhos de autenticação. Também não foi feita uma análise de licenças de todos os assets. Os ficheiros e avisos existentes devem ser conservados até essa revisão; uso temporário não dispensa rastreabilidade.

Não foi realizada uma varredura exaustiva de dependências ou um pentest. Este relatório não contém uma afirmação de “100% seguro”. A falta de acesso à equipa Empire fica registada como limitação da auditoria, sem impedir as conclusões sobre o jogo e a produção pública.

## 11. Como ler os anexos e continuar sem perder trabalho

O anexo A conserva os 187 tickets do índice central, com o estado declarado na base auditada. **É inventário de rastreabilidade, não 187 certificações independentes.** Os achados AM-01–20 e a matriz da secção 4 descrevem a revisão técnica aprofundada. Tickets concluídos num âmbito antigo podem necessitar de novos critérios; isto deve ser uma alteração de contrato explícita.

O anexo B relaciona todas as 40 respostas ainda marcadas `nova`. Foi incluída uma interpretação de auditoria para impedir que se volte a implementar algo existente ou se execute uma proposta adiada. Preserva-se o estado real do painel; não foi escrito um estado novo no banco.

O anexo C apresenta fontes e caminhos de código fixados no SHA auditado. O pacote de evidências conserva a sonda, os resultados, o log completo do CI, o log local parcial e as capturas do CI. A captura de noite inclui metadata do motor, semente, renderer e commit.

**Próximo marco recomendado:** fechar os lotes 0–2, demonstrando uma fundação segura e um primeiro ciclo noturno coerente com as decisões atuais. O projeto já tem infraestrutura suficiente para isso; o trabalho principal agora é fazer os contratos dos sistemas concordarem.

## Anexo A — inventário integral dos 187 tickets
Estado declarado no backlog do SHA auditado. Os textos foram conservados; as ressalvas de auditoria da secção 11 aplicam-se a todas as linhas. Não somar estes estados como percentagem de conclusão do jogo.
| Ticket | Título | Estado declarado |
|---|---|---|
| F0-00 | Repositório do dia zero: as ondas 1 e 2 da §68 | feito |
| F0-01 | Criar o projeto Godot 4.6 com as definições do §19 | feito |
| F0-02 | Git LFS para *.aseprite e art/**/*.png | parcial — configurado; a arte que há (art/source/originals, art/export/enramados) está fora do LFS de propósito (.gitattributes), e git lfs ls-files não mostra nada |
| F0-03 | AGENTS.md e os primeiros ADRs | feito |
| F0-04 | Instalar o gdUnit4 e o workflow de CI | feito |
| F0-05 | Band: enum, planos e a matriz de colisão | feito |
| F0-06 | GameClock e o ClockData (prompt 1 da §29) | feito |
| F0-07 | EventBus com os sinais do §46 | feito |
| F0-08 | Câmara com lookahead e limites de região | feito |
| F0-09 | Spike: decidir a escala e fechar a ADR 0001 | por fazer |
| F0-10 | Cena de teste: um sprite anda nas três faixas | feito |
| F0-11 | Registry e boot.tscn | feito |
| F0-12 | RngService: os seis fluxos, snapshot e restore | feito |
| F0-13 | SaveService: escrita atómica e três slots | feito |
| F0-14 | UnitView com cinco slots e o shader da paleta | feito |
| F0-15 | Spike: importar arte do Aseprite e fechar a ADR 0010 | por fazer |
| F1-01 | Moeda física: largar, arco, queda, apanhar, saco | feito |
| F1-02 | UnitData e as seis unidades do §07 | feito |
| F1-03 | UnitSystem com arrays paralelos e time-slicing | feito |
| F1-04 | Recrutar um vagabundo por uma moeda; ele segue-te | feito |
| F1-05 | JobBoard (prompt 4 da §29) | feito |
| F1-06 | Muro: cinco níveis, dois caminhos, slots de contacto | feito |
| F1-07 | Arqueiro: alcance, precisão 0,34 em campo e 1,0 em torre | feito |
| F1-08 | RotSystem (prompt 2 da §29) | feito |
| F1-09 | Criaturas: Rastejante, Alado, Bruto e a tabela de invocação | feito |
| F1-10 | Economy (prompt 3 da §29) e a curve.tres | feito |
| F1-11 | Plantação, pesqueiro e galinheiro com os valores do §06 | feito |
| F1-12 | Moral e fuga com o raio do rei | feito |
| F1-13 | CanvasModulate por faixa, animado pelo GameClock | feito |
| F1-14 | Save e load do estado de src/sim/ com save_version | feito |
| F1-15 | Cenário de combate noturno para afinação | feito |
| F1-16 | Afinar até sobreviver dez dias ser possível e não trivial | feito |
| F1-17 | Arte da mancha: a Podridão e a candeia | feito |
| ART-01 | A primeira personagem real em cinco slots | por fazer |
| ART-02 | A paleta mestra e o LUT | por fazer |
| ART-03 | As seis camadas de parallax com teto de valores | por fazer |
| ART-04 | Rostos e expressões: o catálogo do §60 | por fazer |
| GB-01 | Greybox do segmento zero | parcial — falta a cara fixa do vagabundo (ART-01, Q-104) |
| GB-02 | Greybox dos seis biomas | feito |
| GB-03 | Regras de densidade medidas no greybox | feito |
| GB-04 | O passo do §21: a região atravessa-se em 40–60 s | feito |
| GB-05 | O preço daquilo em cima de que estás | feito |
| GB-06 | Largar em contínuo, que o §24 já mandava | feito |
| GB-07 | O rei não fica preso em combate | feito |
| GB-08 | O golpe que se vê | feito |
| GB-09 | A sombra de contacto da moeda | feito |
| GB-10 | O render interpola, e o rei deixa de andar aos solavancos | feito |
| GB-11 | O gatilho direito, num comando | feito |
| GB-12 | A câmara livre pelo rato na margem | feito |
| GB-13 | Pausa e opções: desligar o tremor e os clarões | feito |
| GB-14 | O sinal da passagem, onde o Verbo 2 pega | feito |
| GB-15 | Os glifos do comando que se está a usar | feito |
| GB-16 | A derrota diz a verdade, e dá um jogo novo | feito |
| GB-17 | O amanhecer que se vê chegar | feito |
| GB-18 | O sol e a lua dizem a hora | feito |
| GB-19 | O pequeno bounce da moeda | feito |
| GB-20 | A cara de quem está ferido | feito |
| GB-21 | As tropas saem dos postos atrás da luz | feito |
| GB-22 | As legendas de som | feito |
| GB-23 | A silhueta fantasma a piscar | feito |
| GB-24 | A duração do dia, ao ritmo de quem joga | feito |
| GB-25 | O controlo de contraste | feito |
| GB-26 | Os modos para daltonismo | feito |
| GB-27 | O painel fala por chave | feito |
| GB-28 | O idioma escolhe-se na pausa | feito |
| NB-01 | Bíblia de nomes e a escolha do nome do jogo | por fazer |
| CD-01 | A base de dados de conteúdo, uma tabela por sessão | feito |
| XIII-01 | §80 · O preto na paleta e a noite castanha | feito |
| XIII-02 | §74 · O termo dos Amargueiros na massa | feito |
| XIII-03 | §74 · O Amargueiro e a candeia, completos | feito |
| XIII-04 | §75 · A Oferta e a Dívida da Candeia | feito — 4 das 12 ofertas com preço e efeito ligados (Q-099) |
| XIII-05 | §76 · O Nome | feito — 5 dos 9 feitos com o que observar (Q-102) |
| XIII-06 | §78 · A Colheita | parcial — falta a conquista que a começa e o gesto da decisão (Q-103) |
| XIII-07 | §77 · Os dez capítulos | parcial — a colocação e os diários feitos (D-09, D-11, D-12); as leis, a arte e as canções por fazer |
| XIII-08 | §79 · Os doze diários e os três epílogos | parcial — a atribuição, o D-12, o D-13 e o diário 1 legível; os outros onze esperam pelas fortalezas e pelos capítulos |
| XIII-09 | §81 · Som: o cante, os motivos e a encomendação | por fazer |
| XIII-10 | §83 · Os primeiros vinte minutos | feito |
| XIII-11 | §84 · Os catorze testes de design e as seis linhas de risco | feito |
| PUB-01 | O jogo passa a jogar-se no browser | feito — a produção segue a main: medido a 25/09/2026, o /versao.json de empire-phi-eight.vercel.app diz ramo main, ambiente production (tools/web/fumo.mjs) |
| PUB-02 | O site passa a ser a página do jogo | feito |
| F2-01 | A classe do Monarca: a aura e a evolução | parcial — a aura, a evolução e o escudeiro que apanha moedas caídas ligados; "o escudeiro torna-se tropa de combate" espera pela Q-114 |
| AUD-01 | Integridade da simulação: a moeda, o muro, a torre, o rei e o save | feito |
| AUD-02 | A economia verdadeira: o que o CI afina é o que o jogo corre | feito — a produção cresce, paga nobres e pede o trabalhador; a manutenção e o vagabundo da alvorada na partida; o D8 passa para o AUD-04 (o Cavador do dia 10, Q-101) |
| AUD-03 | A noite legível e com gestos | feito — o lado dito à tarde, o ritmo, o sacrifício de moedas, a formação da noite e as legendas; som gravado continua a ser da pasta audio/ |
| AUD-04 | As faixas: o subsolo como expedição e o Alado com alvo | feito — o poço nas cavidades, a escora das passagens, o Cavador chamado pelo poço e o Alado que rouba galinhas |
| AUD-05 | Uma campanha mínima: sucessão, fim de região e decay | feito — o herdeiro, o decay, a travessia com o epílogo e as variantes da torre e do canteiro |
| CONT-01 | Transição durável: o legado como transação | feito — LegacyStore: temporário, leitura de volta e rename; os slots só se apagam depois; o primeiro save do jogo novo gasta o legado (Q-139) |
| CONT-02 | Memória da campanha: o que atravessa e o que fica | parcial — a variante, a fase da classe, a dívida, os povos e o treino do herdeiro atravessam; a comitiva só da faixa do rei (Q-140, Q-143); falta separar a dívida local e a identidade da comitiva |
| CONT-03 | Snapshot do trabalho: o Staffing no save | feito — o Staffing grava a fase, quem serve e quem serviu; retomar fecha a fase igual (Q-141) |
| CONT-04 | Transições sem prisão: sucessão e escoras | parcial — uma condição de sucessão (casa de pé) e a escora fecha por cima; a topologia do subsolo e o treino sem casa ficam na Q-137/Q-138 |
| CONT-05 | Medição fiel da partida | parcial — a vistoria pára com o Defeat e diz a causa, conta as moedas por origem e por sorvedouro, e compara duas políticas (Q-142); o piloto já compra o arco na banca e decreta a Chamada às Armas, e a vistoria conta a gente armada (Q-165); falta um piloto que invista em renda e chegue à travessia: medido a 29/09, das seis moedas ele nunca tem saco à tarde e o rei cai ao dia 4 sem levantar a banca |
| CONT-06 | Manutenção com custo marginal | por fazer |
| CONT-07 | Duas economias de conversão válidas | por fazer |
| CONT-08 | Abertura e controlo completos | parcial — o impulso escolhe-se no comando pelo gesto do §24 (manter Y, apontar, largar; Q-148); falta o destinatário da moeda antes de largar, a razão do que não pode e o retorno da expedição |
| CONT-09 | Sinais de ação e ameaça | por fazer |
| CONT-10 | Duas regiões autoradas | por fazer |
| CONT-11 | Um povo, uma escolha completa | por fazer |
| CONT-12 | Evidências e estado derivados | parcial — o validation.json acertado a 27/09; repetir a cada entrega |
| PUB-03 | Decisões compreensíveis no painel | feito |
| PUB-04 | O site mostra o jogo de hoje | feito |
| UX-01 | Reformular a pausa e corrigir o corte visual | feito |
| ART-TEMP-01 | Assets gratuitos temporarios para testar a gameplay | feito — assets gratuitos integrados, testes, portoes e render verificados (ADR 0042). |
| QP-01 | Aplicar as onze respostas restantes do painel | feito |
| CLASSES-01 | Três classes na primeira escolha | feito |
| COMBAT-01 | Combate direto das classes | feito |
| UX-02 | Jogar com os dedos: os controlos por toque | feito |
| UX-03 | A alavanca solta, o FIXAR e o ecrã inteiro | feito |
| UX-04 | O CORRER no toque e as obras com sprite | feito |
| UN-00 | Consolidar as regras dos monarcas e a ADR | feito |
| UN-01 | Esquema de monarcas e companheiros | feito |
| UN-02 | Autoridade por reino e por pessoa | feito |
| UN-03 | Vínculo de companhia | feito |
| UN-04 | Seleção imperial e autoria inicial | feito |
| UN-05 | Retirar o controlo de tropas | feito |
| UN-06 | Migração das campanhas antigas | feito |
| UN-07 | Generalizar a morte e a sucessão | feito — o herdeiro segue o perfil de quem reinava, a proposta da Q-202 por aprovar |
| UN-08 | Despacho do combate e da habilidade | feito |
| UN-09 | A Imperatriz Nia e os números de bancada | feito |
| UN-10 | O Bardo real pago | feito |
| UN-11 | Conversão e hostilidade | feito |
| UN-12 | Promoção e evolução de Nia | feito — os tetos de encantados e de convertidos são propostas da Q-199 por aprovar |
| UN-13 | O Imperador Arqueiro e a aljava | feito |
| UN-14 | O escudeiro que fornece flechas | feito |
| UN-15 | O sangramento | feito |
| UN-16 | Encontros e roster imperial | por fazer |
| UN-17 | Troca imperial transacional | por fazer |
| UN-18 | Diplomata universal sob IA | por fazer |
| UN-19 | Tesouro local e defesa na ausência | por fazer |
| UN-20 | Incursões com Diplomata | por fazer |
| UN-21 | Captura, resgate e dívida | por fazer |
| UN-22 | Alvo de unidade e de obra, e conquista | por fazer |
| UN-23 | Governo inimigo e assimilação | por fazer |
| UN-24 | Viagem da comitiva, montarias e sítios | por fazer |
| UN-25 | Ofícios, evolução e produção animal | por fazer |
| UN-26 | Pontes, torres e um evento de bioma | por fazer |
| UN-27 | Lore e apresentação dos encontros | por fazer |
| UN-28 | O primeiro ciclo e a acessibilidade | por fazer |
| UN-29 | Coop local | por fazer |
| UN-30 | Dois reinos e a vitória | por fazer |
| UN-31 | Spike e integração de rede | por fazer |
| UN-32 | O herdeiro neutro, caro, e a chave da troca | por fazer |
| UN-33 | O quarto imperador e a escudeira que dança | por fazer |
| UN-34 | O escudeiro evoluído dispara flechas | feito |
| QP-02 | As respostas do painel de 02 e 03/10/2026 | feito |
| QP-03 | O baú da sala secreta | feito — RG-22; ADR 0065 |
| QP-04 | O refinamento da jogabilidade de 03/10/2026 | feito |
| QP-05 | A caça a sério | feito |
| RG-00 | O contrato do plano do reino | feito |
| RG-01 | O contrato da sede | feito |
| RG-02 | O pacote e o início | feito |
| RG-03 | A escada da sede, do Acampamento à Fortaleza | feito |
| RG-04 | O contexto do núcleo | feito |
| RG-05 | Empregos e reposição | parcial — o pioneiro repara e a Casa de Treino abre no Povoado; falta a IA preferir o ocioso e o aviso do posto que fica vazio |
| RG-06 | A economia de trajetória | por fazer |
| RG-07 | A primeira defesa aérea | parcial — a torre alta abre no Povoado; a viabilidade das 30 moedas antes do dia 4 por medir |
| RG-08 | A interface do benefício e do compromisso | parcial — o painel da sede, a obra fechada e o objetivo da fundação; faltam a falta de pessoa, a lareira prevista e a preparação noturna |
| RG-09 | Frentes e refúgios | por fazer |
| RG-10 | Expansão e acampamentos | por fazer |
| RG-11 | A Vila Fortificada e a Fortaleza | parcial — os dois estágios abrem as obras que já existem; a infraestrutura de campo e a indústria novas por fazer |
| RG-12 | O primeiro posto | por fazer |
| RG-13 | A primeira rota física | por fazer |
| RG-14 | A Capital | por fazer |
| RG-15 | Integração e ausência | por fazer |
| RG-16 | Arte por estágio e por povo | parcial — o Acampamento, o Povoado, a Vila, a Vila Fortificada e a carroça pintados em formas lisas; faltam as variantes por povo e a arte do dono |
| RG-17 | Migração | parcial — o castelo herdado é a Fortaleza (v8, com teste); a matriz de pagamentos parciais, obras e pessoas por medir |
| RG-18 | Desempenho e mobile | parcial — medidos o tick, o frame, a fauna fora de câmara e os controlos de toque, e corrigido o que se mediu (docs/reports/DESEMPENHO-2026-10-08.md); por medir as sedes grandes e o painel; os draw calls da noite acima do orçamento da §63 |
| RG-20 | Uma clareira, prados de caça e floresta de exploração | feito |
| RG-19 | Construções e recrutamento acompanham a expansão | feito |
| QP-06 | A caça longe do reino | feito |
| RG-21 | Recrutamento por corrida, fundação na lareira e cidade dentro das muralhas | feito |
| RG-22 | A Última Carroça: relatório completo e decisões atuais do painel | feito — protótipo e validação técnica; percepção humana por medir |
| RG-23 | Adaptar relatório mestre e fundação livre Solo | feito — protótipo Solo; visão completa depende de RG-24/RG-25 |
| RG-24 | Identidade territorial e despertar social | por fazer |
| RG-25 | Servidor autoritativo e modos online | por fazer |
| RG-26 | A floresta como território | feito — protótipo P0–P4; arte final, meteorologia e P5 por fazer |
| RG-27 | O subsolo tem chão para além da escada | feito — P0 (SUB-01 a SUB-07) e P1 de geração, recompensas, baú, celeiros e roubo; logística e ensaios por fazer |
| QP-07 | Usar o Painel no desktop e no mobile | feito |
| UX-05 | HUD legível e compacta no telemóvel | feito — implementação e provas locais; confirmação final no CI do PR |
| DOC-01 | Consolidar o dossiê com o painel e as referências territoriais | feito |
| ART-RENEWAL-01 | Renovacao visual do reino | feito — arte integrada na main com a HUD da UX-05; a paisagem espelhada sem buracos (ADR 0075) |
| RG-28 | O território decide o que se levanta | feito — fase 0 (reconciliação) e fase 1 (fontes, avaliador comum e reancoragem); previsão da fundação; água com tipos, porto, contratos e rotas por fazer |
| UX-08 | Atlas do Império: a ficha do sítio e uma só linguagem na HUD | feito — primeiro pacote do plano da HUD (§20): contexto curto, ficha voluntária com confirmação, tokens Atlas na HUD, pausa e toque, e o que cada número quer dizer; fontes, selo, edifícios, armazéns, mapa e testes em aparelhos por fazer |
| CV-01 | Cenários: diagnóstico reproduzível e o contrato dos planos | parcial — o que é código da etapa A do plano de cenários: manifesto de captura, sobreposição do território e contrato dos planos; o kit de arte, a separação do panorama e o trecho piloto por fazer |
| PUB-05 | Primeiro contacto, desempenho e resiliência do site | feito |
| UX-09 | Explicações breves ao parar e pausa móvel rolável | feito — implementação e provas locais; confirmação final no CI do PR |
| UX-10 | Toques da HUD sem conflitos entre dedos e menus | feito — implementação e provas locais; confirmação final no CI do PR |
| CV-02 | Cenários em camadas: os reinos e as transições do dono no jogo | parcial — os 8 reinos e as 13 transições pintam o fundo e o chão do mundo inteiro; as 3 propostas especiais e as transições a oeste de casa esperam decisão (Q-259, Q-260) |

## Anexo B — todas as respostas ainda marcadas `nova`
Snapshot de leitura: 229 respostas no total, 189 aplicadas e as 40 abaixo ainda novas. A coluna final é interpretação de auditoria, não alteração ao painel. As escolhas e os títulos são preservados; os textos completos consultados acompanham o snapshot no pacote de evidências.
| Pergunta | Escolha | Título do painel | Reconciliação de auditoria |
|---|---|---|---|
| Q-081 | adiar | A derrota é de quem tem a cena aberta, e isso é deliberado | Adiamento preservado. A derrota solo existe; a pergunta não deve ser reaberta como bug pendente genérico. |
| Q-112 | adiar | A decisão do circuito 2: como se "aponta um ofício a um edifício" | Adiamento preservado. Não implementar automaticamente o circuito de apontar ofício só por o estado continuar nova. |
| Q-147 | adiar | Ofertas com preço sem sistema | Adiamento de ofertas cujo preço depende de sistemas ausentes. Não criar promessas sem consequência real. |
| Q-170 | aprovar | O acampamento perde-se quando o reino cresce por cima dele (era a Q-E) | Regra de esgotamento/substituição de acampamento já tem implementação. Reconciliar evidência; a companhia persistente é trabalho separado (Q-251). |
| Q-171 | aprovar | Alicerces: o que o decay leva deixa marca (era a Q-G) | Marcas/alicerces após ruína foram tratados no protótipo. Conferir com a persistência atual antes de mudar o estado. |
| Q-172 | outra | Estações e um inverno (era a Q-H) | Estações/reservas implementadas parcialmente; clima e alternativas por bioma devem ser reconciliados com Q-235. AM-09. |
| Q-174 | outra | Obras nas terras geradas | Há assentamentos com obras e rotina. Independência completa e evolução desde zero faltam; não confundir geração pronta com ecossistema concluído. AM-03/19. |
| Q-175 | outra | Cada povo com a sua tabela de segmentos | Tabelas/identidades por povo e nomes atuais existem; Bruma substitui a designação rejeitada. Reconciliar estado editorial. |
| Q-176 | outra | O que há numa masmorra | Variação de salas/recompensas existe no núcleo de dungeons. Extensões posteriores têm escopo próprio e Q-245 adiada. |
| Q-177 | aprovar | O mercenário das trilhas: soldo e lealdade | Recrutamento/soldo mercenário existem. Companhias persistentes e negociação contratual não estão concluídas. AM-19. |
| Q-178 | outra | O rei na terra de outro povo | O modelo antigo de classes viajantes foi substituído pela unificação em imperadores e pela fundação/exploração livre. Não restaurar a restrição antiga. |
| Q-179 | outra | De onde vem a noite, agora que o mundo tem pontas | Fissuras e regras de origem/pressão da noite existem. A curva inicial ainda diverge das respostas mais recentes. AM-02. |
| Q-180 | aprovar | O mapa revelado como legado (§16) | Legado/mapa persistente tem implementação e testes. Reconciliar após conferir a versão publicada. |
| Q-182 | aprovar | O subsolo tapado: o que sobe de baixo, e a cavidade já achada | Escoras, reabertura e subsolo visitado existem. Não encerram a questão distinta de acesso operacional a recursos. AM-08. |
| Q-183 | outra | Completar as três classes sem inventar uma regra definitiva de balanceamento | Decisão encerrada conceitualmente pela unificação de classes/imperadores. Não voltar às classes controláveis antigas. |
| Q-184 | outra | Ataque e habilidade separados nas classes controladas | Ataque e habilidade separados existem. Estado nova não significa que o combate manual está ausente. |
| Q-187 | outra | O toque é o quarto dispositivo: a alavanca, os botões e o mundo | Paridade de ações e preferências de toque têm implementação; falta certificação do ciclo completo em aparelhos reais. AM-18. |
| Q-189 | outra | A noite é difícil de ver, e não impossível; as luzes alumiam | Alteração de iluminação aceite e implementada. Não reabrir a direção aprovada só por faltar marca aplicada. |
| Q-191 | adiar | Sete criaturas, uma família, sete portes | Adiamento de arte/portes de criaturas preservado. O bestiário tem representação provisória; a família definitiva é produção posterior. |
| Q-194 | adiar | As obras que não tinham arte, pintadas no estilo da tua; o sítio vazio à vista | Adiamento artístico preservado. Representações temporárias não equivalem a arte final aprovada. |
| Q-195 | outra | Resolvida — o que o dono decidiu: três monarcas, só imperadores controláveis, flechas pagas | Três iniciais e imperadores como corpos controlados estão implementados; encontros/roster/desbloqueios completos ainda não. AM-04/19. |
| Q-196 | outra | A troca imperial transfere o governo, ou só o controlo? | Troca via herdeiro preparado, vulnerabilidade e manutenção contínua ainda não implementadas integralmente. AM-04. |
| Q-197 | outra | Outro imperador encontrado serve de sucessor? | Encontrar/desbloquear imperador ainda não fecha a seleção por herdeiro. UN-16/32; AM-04/19. |
| Q-201 | outra | O sangramento | Sangramento reservado ao Imperador Arqueiro foi aplicado; reconciliar evidência e estado. |
| Q-202 | outra | O herdeiro: que perfil, e com que força | Herdeiro neutro, perda por não pagar, escolha e recuperação em cinco noites não correspondem ao Succession atual. AM-04. |
| Q-203 | aprovar | O Diplomata universal: acesso, missões, captura e resgate | Acesso universal ao Diplomata, missões, captura e resgate ainda não completos. UN-18–21; AM-19. |
| Q-204 | aprovar | Os dois multiplayer com imperadores | Direção multiplayer aceite, depois refinada pelo relatório: coop de um reino e competitivo em extremos opostos. Não implementado. AM-20. |
| Q-205 | outra | O resto do que o plano deixa aberto | Quarto imperador e dançarina definidos como conceito; não implementados. A resposta não aprova as restantes propostas da pergunta. |
| Q-206 | outra | O imperador que não reina, e morre | Regra de indisponibilidade/morte e ritual está definida; ciclo completo de recuperação do imperador não implementado. AM-19. |
| Q-221 | outra | O pacote fundador: a carroça, o pioneiro e a bancada | Exploração livre, fundação e bancas têm entregas posteriores. Integração territorial/campanha contínua e detalhes de composição ainda parciais. AM-01/03/08. |
| Q-235 | outra | Clima, identidade e despertar social | Direção de clima e base autoral 64×64 definida; modelo climático regional ainda pendente. AM-09. |
| Q-237 | outra | Fundar onde se para, e a carroça que alcança (verificação do PR #85) | Conciliação de subsolo pedida. Bug de cave sem baía e baú sem posição finita reproduzido. AM-01. |
| Q-239 | aprovar | A rampa das primeiras noites pesa também o que escreveste de dia | Pressão escrita de dia sujeita à rampa já implementada. Reconciliar estado com o deploy. |
| Q-240 | outra | Uma espécie nova estreia com poucos | Objeção à escalada agressiva não refletida no debut_step=3. Falta proposta medida substituta. AM-02. |
| Q-241 | aprovar | O escuro paga-se, e só morde a partir da noite 3 | Emboscadas pagas e início na noite três implementados. Reconciliar estado. |
| Q-242 | aprovar | A curva das noites 2 a 6 com o reino que começa numa Clareira | Rampa de sete aprovada, mas runtime mantém cinco. Implementação pendente. AM-02. |
| Q-243 | aprovar | A primeira noite funda logo a seguir à rampa | Primeiro pico na noite 12 aprovado, mas runtime ainda tem pico na sexta. AM-02. |
| Q-245 | adiar | O que o relatório propõe e fica por decidir | Adiamento preservado de extensões de subsolo. Não bloqueia corrigir a área útil do sistema já entregue. |
| Q-247 | outra | A tocha da mão também afasta a emboscada do escuro? | Luz visual sem consumo existe; archote consumível antigo também. Corrupção tardia por pacto ainda não implementada. AM-10. |
| Q-248 | outra | As árvores que os saves de antes já perderam | Persistência de árvores removidas/obras tratada em entregas posteriores. Reconciliar após matriz de migração, sem recriar a floresta apagada. |

## Anexo C — mapa de fontes verificáveis

Todos os links de código abaixo estão fixados no commit auditado, evitando que uma alteração futura de `main` modifique a evidência deste relatório. O painel foi consultado diretamente em leitura; o snapshot editorial do repositório pode representar uma data anterior à última resposta.

| Tema | Fontes |
|---|---|
| Precedência e especificação | [AGENTS.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/AGENTS.md); [docs/dossie.html](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/dossie.html); [docs/reports/EMPIRE-MASTER.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/EMPIRE-MASTER.md) |
| Backlog e resultados publicados | [docs/backlog/tickets.json](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/backlog/tickets.json); [docs/recovery/validation.json](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/recovery/validation.json); [ferramentas/src/03-paineis.js](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/ferramentas/src/03-paineis.js) |
| Decisões e reconciliação | [docs/QUESTIONS.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/QUESTIONS.md); [docs/reports/PANEL-RECONCILIATION.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/PANEL-RECONCILIATION.md); [docs/reports/DECISOES-DOSSIE-2026-10-07.json](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/DECISOES-DOSSIE-2026-10-07.json) |
| AM-01: fundação e autoria | [src/core/foundation_choice.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/foundation_choice.gd); [src/core/last_cart_watch.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/last_cart_watch.gd); [src/core/under_watch.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/under_watch.gd); [src/core/cellar_watch.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/cellar_watch.gd) |
| AM-01: geometria e garantia | [src/sim/systems/underground_sites.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/underground_sites.gd); [src/sim/systems/under_reserve.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/under_reserve.gd); [src/sim/systems/under_fit.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/under_fit.gd); [tests/subsolo_area_util_test.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tests/subsolo_area_util_test.gd) |
| AM-02: curva e teste antigo | [data/source/rot.csv](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/data/source/rot.csv); [data/rot/default.tres](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/data/rot/default.tres); [src/sim/data/rot_profile.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/data/rot_profile.gd); [tests/noite_legivel_test.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tests/noite_legivel_test.gd); [tests/noite_do_07_test.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tests/noite_do_07_test.gd) |
| AM-03: relógio e sociedade | [src/core/sim_loop.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/sim_loop.gd); [src/core/frontier.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/frontier.gd); [src/core/settlement_watch.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/settlement_watch.gd); [docs/design/88-fundacao-sociedades-exploracao-e-rede-territoria.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/design/88-fundacao-sociedades-exploracao-e-rede-territoria.md) |
| AM-04/05: linhagem e pagamentos | [src/sim/systems/succession.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/succession.gd); [src/core/dawn_work.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/dawn_work.gd); [src/sim/systems/upkeep_system.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/upkeep_system.gd); [tests/sucessao_monarca_test.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tests/sucessao_monarca_test.gd); [tests/upkeep_system_test.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tests/upkeep_system_test.gd) |
| AM-06: desempenho | [docs/reports/DESEMPENHO-2026-10-08.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/DESEMPENHO-2026-10-08.md); [docs/qa/PERFORMANCE_MATRIX.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/qa/PERFORMANCE_MATRIX.md); [docs/design/63-orcamentos-e-como-se-medem.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/design/63-orcamentos-e-como-se-medem.md) |
| AM-07: entrega | [vercel.json](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/vercel.json); [.github/workflows/ci.yml](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/.github/workflows/ci.yml); [tools/web/construir.sh](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tools/web/construir.sh); [tools/web/fumo.mjs](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tools/web/fumo.mjs) |
| AM-08/11: fontes e acessos | [src/core/territory_watch.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/territory_watch.gd); [src/sim/systems/placement_rules.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/placement_rules.gd); [src/sim/systems/passages.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/passages.gd); [tests/territorio_fundacao_test.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tests/territorio_fundacao_test.gd); [docs/design/92-fontes-acessos-fundacao-e-producao.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/design/92-fontes-acessos-fundacao-e-producao.md) |
| AM-09/10: clima e luz | [src/sim/systems/seasons.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/seasons.gd); [src/world/hand_light.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/world/hand_light.gd); [src/sim/systems/torchlight.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/torchlight.gd); [src/core/dark_watch.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/dark_watch.gd) |
| AM-12: cenários | [docs/reports/CENARIOS-GODOT.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/CENARIOS-GODOT.md); [src/world/scenery_map.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/world/scenery_map.gd); [art/export/scenery/manifest.json](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/art/export/scenery/manifest.json) |
| AM-13/14: arte e som | [docs/art/RUNTIME_ART.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/art/RUNTIME_ART.md); [src/actors/actor_action.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/actors/actor_action.gd); [docs/audio/AUDIO_CUE_SHEET.csv](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/audio/AUDIO_CUE_SHEET.csv) |
| AM-16/17: verificação e continuidade | [tools/vistoria.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tools/vistoria.gd); [tests/dez_dias_test.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tests/dez_dias_test.gd); [src/core/save_point.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/save_point.gd); [src/core/save_migrations.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/save_migrations.gd); [src/world/resume.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/world/resume.gd) |
| AM-18: UX e acessibilidade | [docs/reports/HUD-UI-ATLAS.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/HUD-UI-ATLAS.md); [docs/qa/ACCESSIBILITY_MATRIX.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/qa/ACCESSIBILITY_MATRIX.md); [src/ui/options_panel.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/ui/options_panel.gd); [src/core/preferences.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/preferences.gd); [tools/web/site/img/capturas.json](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/tools/web/site/img/capturas.json) |
| AM-19/20: campanha e modos | [src/core/realm.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/core/realm.gd); [src/sim/systems/march.gd](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/src/sim/systems/march.gd); [docs/design/89-sucessao-noite-e-modos-de-jogo-sem-contradicoes.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/design/89-sucessao-noite-e-modos-de-jogo-sem-contradicoes.md); [docs/design/95-direitos-logistica-arquitetura-e-compatibilidade.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/design/95-direitos-logistica-arquitetura-e-compatibilidade.md) |
| Conformidade versus implementação | [docs/reports/CONFORMIDADE-DOSSIE-CIVILIZATION-VII-2026-10-07.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/CONFORMIDADE-DOSSIE-CIVILIZATION-VII-2026-10-07.md); [docs/reports/SUBSOLO-ARMAZENS-DUNGEONS.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/SUBSOLO-ARMAZENS-DUNGEONS.md); [docs/reports/VEGETACAO-BIOMAS.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/VEGETACAO-BIOMAS.md); [docs/reports/SITE-EXPERIENCE-2026-10.md](https://github.com/henriquecoding/empire/blob/b419b6e2672ba7e779344034d448303c3da6b022/docs/reports/SITE-EXPERIENCE-2026-10.md) |

### Ficheiros de planeamento consultados fora do repositório

- `EMPIRE-GUIA-2026-10-08.md` — entrega de oito reinos, 13 transições e três especiais; limites de composição estática.
- `EMPIRE-TRANSICOES-BIOMAS-2026-10-07.md` — ligações visuais entre biomas.
- `EMPIRE-REINO-FLUVIAL-GUIA-FUNCIONAL-2026-10-07.md` — espaço inferior, porto, margens e acesso.
- `EMPIRE-PLANO-MESTRE-CENARIOS-GODOT-2026-10-07.md` — composição e ligação ao modelo de faixas.
- Planeamentos de primeiro dia/despertar de 04/10, evolução do reino de 03/10 e monarcas/classes de 02/10; cruzados com as versões consolidadas e decisões posteriores.
- Relatórios anteriores de gameplay, direção visual e assets temporários, usados como histórico e não como autoridade sobre correções posteriores.

Os nomes com sufixos de cópia, quando existentes nos ficheiros originais, não definem precedência. A data, a decisão do dono e a consolidação no projeto foram usadas para resolver divergências.

## Anexo D — pacote de evidências e reprodução

O ZIP que acompanha este relatório contém:

| Ficheiro | Conteúdo e limite |
|---|---|
| `README.md` | Baseline, comandos e interpretação dos resultados |
| `audit_probe.gd` / `audit_probe.tscn` | Sonda temporária de curva, sociedade, fundação e elegibilidade de minas |
| `probe.log` | Resultado final da sonda; duas caves `no_bay`, `usable=true`, `chest_finite=false` |
| `github-ci-suite.log` | Log do job de dados/suite e vistoria do run 37810026878 |
| `local-suite.partial.txt` | Execução local incompleta; não prova aprovação de toda a suite |
| `static-gates.log` | Gates locais de documentação, dados, manifesto e inventário |
| `site-smoke.log` | Verificação pública HTTP contra o SHA esperado |
| `production-version.json` | Manifesto confirmado na produção |
| `panel-answers.json` | 229 decisões consultadas; sem IDs de utilizador ou dados pessoais de feedback |
| `backlog-tickets.json` | Snapshot dos 187 tickets |
| `audit-metadata.json` | Âmbito, acesso e resultados consolidados |
| `visual-ci/` | Capturas do CI; `noite.json` inclui commit, semente e renderer |
| `SHA256SUMS.txt` | Checksums dos ficheiros do pacote |

Para reproduzir a sonda, usar um checkout limpo do SHA auditado com Godot 4.7.2, importar o projeto, copiar os dois ficheiros de sonda para `tools/` e executar:

```bash
godot --headless --path . --import
godot --headless --path . tools/audit_probe.tscn --quit-after 2
```

Para repetir a verificação pública, com Node disponível:

```bash
node tools/web/fumo.mjs https://empire-phi-eight.vercel.app b419b6e2672ba7e779344034d448303c3da6b022
```

Se a produção mudar depois desta data, o segundo comando deve acusar a diferença de SHA; isso é comportamento correto. O relatório continua a descrever a baseline fixada acima.

**Encerramento da auditoria:** as conclusões sustentam um protótipo solo funcional com integração ainda incompleta. A correção prioritária é fazer fundação, subsolo, curva de dificuldade, economia e sucessão cumprirem simultaneamente as decisões aprovadas; depois, ampliar a campanha e os modos futuros com provas por jornada.
