# Retomada do relatório aprofundado e das decisões do painel

Data: 2026-10-04. Base analisada: `main`, commit
`c3bdec896adb7adf9227dc7c05075d089c8d8ac7`.

**Estado atual: recuperado, integrado na main e publicado em 04/10/2026.**

O [PR #84](https://github.com/henriquecoding/empire/pull/84) integra o código do
protótipo no commit `0d04d3a2f710134b86ad2848e4cc8d66cdea6ba8`.
A [CI final 37216619611](https://github.com/henriquecoding/empire/actions/runs/37216619611)
passou os sete jobs, com 1.652 testes aprovados e dois previamente ignorados.
A produção https://empire-phi-eight.vercel.app confirmou esse SHA em
`/versao.json` e passou `make site-fumo`. As 23 decisões atendidas foram
marcadas aplicada no painel, conservando escolha, texto, título, data e autoria.
O fluxo de fundação, coleta, resgate e companheiro pago passou no navegador.
O protocolo de observação humana continua pendente, assim como a arte final
e as dependências futuras de Capital/expansão registradas em RG-12/RG-13.

**Registro histórico do bloqueio anterior — não é o estado atual:**
O conteúdo abaixo preserva o checkpoint feito durante a indisponibilidade.

**Estado no checkpoint: bloqueado por indisponibilidade do ambiente de execução.**
Este ramo contém um registro de retomada. Não contém o código do protótipo,
não constitui uma entrega do jogo e não deve ser integrado como se concluísse
a implementação.

## Pedido e limite da evidência

O pedido é analisar os vários pontos do relatório aprofundado, confrontá-los
com as decisões já tomadas no painel e implementar o conjunto aplicável.
Não reduzir o relatório a uma mudança de tela ou a uma única mecânica.

O relatório foi lido integralmente e o painel foi consultado no projeto
Supabase `ohpyuifmdsbcjntabemr`, tabela `public.empire_respostas`.
A proposta de abertura escolhida foi **A Última Carroça**. As outras aberturas
do relatório são alternativas mutuamente exclusivas, não tarefas cumulativas.

Foi desenvolvido um protótipo no ramo local `codex/last-cart-opening`.
O ambiente deixou de responder durante a rodada final de testes, antes de
um commit ou envio desse código. A API informa
`409 environment_offline: Environment is not connected`.
Não foi possível voltar a ler os arquivos ou verificar o fim da suíte.
A persistência desses arquivos locais precisa ser confirmada na retomada.
Este documento preserva o contexto e não substitui os arquivos.

## Cobertura que precisa ser recuperada e revisada

| Ponto do relatório | Trabalho desenvolvido localmente | Situação de entrega |
| --- | --- | --- |
| Controle imediato e chegada em marcha | Rei já controlável, carroça em movimento e relógio do dia iniciado pela escolha da fundação | Código sem envio remoto |
| Primeira decisão espacial | Dois marcos gratuitos, estrada e bosque; fundar antes de gastar moeda | Código sem envio remoto |
| Identidade ecológica | Raiz antiga visível, sinal da Podridão antes dos inimigos, trilho que se deteriora e deixa cicatriz persistente | Código sem envio remoto |
| Reserva e risco | Reserva inicial preservada; parte separada e exposta, resgatável por trabalhador contratado | Código sem envio remoto |
| Custo de oportunidade | Trabalhador escolhe construir, colher, resgatar ou explorar; caminha até o local e fica indisponível para outros trabalhos | Código sem envio remoto |
| Renda além da caça | Coleta inicial limitada por dia, além da produção e caça existente; terreno da caça não se desloca junto com a sede | Código sem envio remoto |
| Primeira noite | Ameaça ao recurso exposto; luz, fogueira e muro protegem; resultado e perda ficam no save | Código sem envio remoto |
| Amanhecer e consolidação | Registrar sobrevivência e perda; reparação requer deslocamento e presença real de construtor | Código sem envio remoto |
| Introdução do subsolo | Câmara inicial pequena, tesouro próprio vazio, escavação paga e progressiva ligada ao nível da sede | Código sem envio remoto |
| Tesouro e invasão | Depositar e retirar riqueza própria; inimigos podem roubá-la; tesouro estrangeiro transfere riqueza existente | Código sem envio remoto |
| Progressão do reino | Riqueza e provas de maturidade: renda, noite, muralhas, população, produção e subsolo | Código sem envio remoto |
| Companheiro e vínculo | Contratar primeiro um vagabundo; pagar treinamento no posto; evolução por combate conjunto | Código sem envio remoto |
| Tutorial contextual | Objetivos no lugar e momento adequados, sem manter instruções do prólogo no meio da campanha | Código sem envio remoto |
| Validação da experiência | Registro local exportável pela pausa e protocolo de sessões de observação | Protótipo e protocolo sem envio remoto; observação humana não realizada |
| Capital como rede | Mantida a decisão de progressão posterior por rede; depende da implementação correspondente do reino | Não concluída |
| Novas fundações durante expansão | Explicitada a dependência das tarefas de expansão RG-12/RG-13 | Não concluída |
| Arte final orientada por percepção | Aguardar observação de jogadores antes de produzir arte final | Não realizada; art/ e audio/ preservados |

As metas de tempo do relatório são hipóteses de avaliação. Não simular
resultados humanos nem transformar essas metas em transições forçadas pelo relógio.

## Decisões do painel que orientaram o protótipo

| Decisão | Aplicação necessária |
| --- | --- |
| Q-207 | Manter distância mínima de 24 px entre espaços úteis; verificar as duas posições de fundação |
| Q-208 / Q-212 / Q-216 | Recuperação parado já existente; corrida normal de 30 s e evoluída de 50 s; recuperação completa parado prepara a próxima corrida com capacidade 1,5 vezes maior |
| Q-209 | Preservar o áudio sintetizado existente |
| Q-210 / Q-224 | Construtor precisa chegar e permanecer para reparar; ficar parado acelera seu trabalho; amanhecer não repara instantaneamente sedes próprias ou estrangeiras |
| Q-211 | Mostrar alcance terrestre de torre antes e depois da construção com a mesma regra usada no combate |
| Q-213 / Q-215 / Q-217 / Q-218 / Q-228 / Q-229 | Preservar fauna, escala, dificuldade e recompensas por espécie; renda alternativa na abertura; caça continua fora das muralhas e ligada aos habitats |
| Q-214 | Javali provocado pode atingir muro, causar dano e ficar atordoado |
| Q-219 | Preservar escala das criaturas |
| Q-220 | Vida e defesa da sede crescem com estágio; escavação inicial pequena e paga exige construtor e respeita nível da sede |
| Q-222 | Casa de herdeiro só após Fortaleza; respeitar o espaço delimitado pelas muralhas concluídas |
| Q-223 | Três vagabundos perto da chegada; nenhum companheiro gratuito; contratar vagabundo e depois pagar sete moedas no posto; evolução pelo combate conjunto |
| Q-225 / Q-226 | Castelos antigos continuam Fortaleza; Capital corresponde à etapa posterior de rede |
| Q-227 | Manter bancada e ferramentas com os preços decididos |
| Q-186 | Tesouro próprio inicia vazio; depósito e saque precisam funcionar na partida e no save |

Q-221 não tinha resposta: preservar a reserva inicial de oito moedas e não
inventar um pioneiro gratuito.

Algumas decisões já estavam implementadas na base. Não recriar essas funções
nem marcar todas as respostas pendentes como aplicadas. Não houve alteração
do estado das respostas no painel nesta sessão.

A evolução das flechas do Escudeiro do Imperador Arqueiro (Q-200 / UN-34) e
as tarefas anteriores de sucessão, diplomacia, multiplayer e novos heróis
não foram concluídas por este protótipo.

## Arquitetura e invariantes do trabalho local

- Novo CSV `data/source/arrival.csv`, Resource `ArrivalRules` e geração
  de `data/economy/arrival.tres` pelo conversor existente.
- Novos sistemas puros de chegada, vínculo do companheiro, tesouro,
  maturidade, reparação da alvorada e impacto de javalis.
- Integração no tick por `src/core/sim_loop.gd`; manter o limite de linhas
  e as fronteiras de importação definidas em AGENTS.md.
- Save versão 10; saves antigos recebem chegada inativa e preservam
  companheiro, evolução e sede anteriores. Fôlego e estados novos são salvos.
- Nenhum sinal novo no catálogo fechado do EventBus; métricas locais em
  dicionário, sem serviço externo.
- Texto visível por `data/i18n/strings.csv`; desenho procedural submetido à
  iluminação existente; nenhuma edição em art/ ou audio/.
- Parâmetros não decididos foram identificados como propostas no CSV e nos
  rascunhos locais Q-232/Q-233. Não tratá-los como decisões do dono.

Geometria local final a verificar: fundação estrada em x=0 e bosque em x=-256;
rei inicial em x=-360; carroça entra por x=-440 e estaciona em x=-150 relativo
à fundação; raiz antiga em x=-620; caixa exposta fixada em x=-520 para impedir
sobreposição com a carroça nas duas escolhas; posto do companheiro em x=+612
e escavação em x=-612 relativos à sede, ambos com largura de 24 px.
Não trasladar fauna ou recursos naturais com a sede.

A última correção também reposicionou a legenda da raiz antiga e impediu
que a morte de aliados convertidos contasse para evolução por batalha.
Os construtores estrangeiros só podem reparar obras do próprio dono.

## Validação observada antes da desconexão

Rodadas focadas confirmaram os contratos da chegada e as regressões da
campanha anterior. Foram corrigidos problemas de companheiro gratuito nos
fixtures, coleta prematura de moeda, tesouro estrangeiro, reparação,
objetivo contextual vazio e sobreposição entre caixa e carroça.

Passaram os portões estáticos, geração de conteúdo, formatação, lint,
catálogo de RNG, verificação das contagens por ferramenta, testes da casca
web e verificações de acessibilidade, teclado, toque, idiomas, privacidade
e responsividade da versão exportada.

O fluxo real no navegador confirmou entrada em português, controle por
teclado, fundação gratuita no bosque e exportação do registro local pela
pausa. Isso foi automação técnica, não sessão de observação humana.

Uma captura nativa da noite, com o rei preparado vivo na sede, passou a
verificação de silhueta. A vistoria anterior não encontrou quebra de
invariantes; terminou com derrota no quarto dia. Não afirmar que o jogo
sobreviveu aos oito dias solicitados pela vistoria.

A rodada completa anterior apontou regressões que foram corrigidas e
verificadas em testes focados. Uma nova rodada completa foi iniciada após
a correção de espaçamento. Seu resultado final não foi lido.
O último fluxo de navegador após essa correção também ficou sem inspeção
final devido à desconexão. Portanto, **a suíte final não está confirmada
verde** e não há autorização técnica para declarar o trabalho concluído.

Não atualizar à mão contagens em README, painel ou validation.json.
Obter os números dos relatórios reais e das ferramentas do repositório.

## Sequência para concluir

1. Restabelecer o ambiente e verificar os arquivos em
   `/workspace/scratch/57dd7258224f/empire`, ramo local
   `codex/last-cart-opening`. Caso estejam presentes, fazer imediatamente
   um commit de recuperação e enviar o ramo antes de outra rodada longa.
2. Ler `suite-final2.log`, `browser-flow2.log` e os relatórios de GdUnit.
   Se a suíte foi interrompida, executá-la novamente.
3. Inspecionar a abertura nas duas fundações após a correção da caixa e da
   legenda; repetir a vistoria final porque houve mudanças no tick e mundo.
4. Conferir ticket RG-22, ADR 0065, QUESTIONS, protocolo de observação,
   CSVs, tradução e arquivos design gerados a partir de docs/dossie.html.
   Esses rascunhos pertencem ao código local, não a este ramo de registro.
5. Atualizar dados de validação exclusivamente pelos resultados reais.
   Manter a avaliação humana e as dependências não implementadas explícitas.
6. Trazer a main atualizada, cumprir os testes exigidos por AGENTS.md,
   abrir PR não rascunho para main, aguardar checks e integrar.
7. Confirmar que `https://empire-phi-eight.vercel.app/versao.json` mostra o
   SHA integrado e verificar a produção. O conector Vercel da sessão
   estava limitado a outro escopo de equipe; não inferir implantação
   bem-sucedida apenas da existência do projeto ou de um preview.
8. Somente depois de integração e produção verificadas, atualizar
   seletivamente `estado` das respostas realmente atendidas, preservando
   texto, escolha e identidade do autor. Não usar uma string no campo UUID
   `atualizado_por`.

Sem PR, merge ou publicação do código nesta sessão.
