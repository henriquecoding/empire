# Empire — pesquisa comparativa e melhoria do site

Data: 07/10/2026. Tarefa: PUB-05. Decisão: ADR 0080.
Âmbito: página de entrada PT/EN, reportes, painel, carregamento e publicação.

## Conclusão e método

O Empire precisa de apresentar primeiro a experiência jogável e de gastar
recursos quando a pessoa os utiliza. A base técnica existente é adequada:
HTML estático gerado do repositório, assets locais, Vercel e API Supabase
isolada nos formulários. Trocar de framework acrescentaria custo sem resolver
os problemas encontrados.

A pesquisa cruzou as páginas oficiais de dois jogos próximos, documentação
de desempenho do Chrome/web.dev, W3C, MDN, Godot e Supabase. A auditoria do
produto incluiu código, artefacto gerado, produção, capturas do jogo, tamanhos
de ficheiros e testes reais de navegador. As referências são fontes primárias;
a comparação visual não é um benchmark de velocidade nem prova de conversão.

Durante o trabalho entraram as PR #94 e #95. A base foi atualizada para
`f3ad88e`, preservando o Atlas, a HUD e a consolidação do dossiê. As capturas
continuam válidas: a PR #95 alterou documentação e rótulos, não a arte do jogo. O projeto observado na Vercel é `empire`; a API
usada pelo painel é a do projeto Supabase configurado no repositório. O painel
foi testado com respostas simuladas, sem criar feedback ou alterar decisões reais.

## Comparação que informa o produto

| Referência | O que a página apresenta | Aplicação ao Empire | Limite da comparação |
|---|---|---|---|
| Kingdom Two Crowns [1] | Imagens reconhecíveis do jogo, proposta curta e ação de jogar/comprar | Jogo visível junto do título e CTA; a imagem demonstra o produto | Não copiar arte, marca, composição ou prometer funcionalidades desse jogo |
| Thronefall, página do editor na Steam [2] | Explicação direta de construir de dia e defender à noite, capturas e requisitos | Explicar o ciclo e dar três passos concretos antes do detalhe técnico | A página Steam tem checkout e descoberta próprios; não mede a conversão deste site |
| web.dev: LCP [3] | Separar resposta, descoberta, transferência e atraso de render | Primeiro quadro no HTML e preload coerente com srcset; conteúdo sem espera por animação | Bytes menores não garantem LCP menor; exige medição de campo |
| web.dev: INP e layout [4–5] | Trabalho do evento e custo de DOM/layout afetam a resposta | Indexar pesquisa uma vez, eliminar procura quadrática e relógio desnecessário | Uma prova de complexidade não é um valor de INP real |
| WAI: navegação e controlos [6–8] | Botão de disclosure, estado anunciado, Escape/foco, pausa e alvos utilizáveis | Menu com fallback, pausa real e ações principais de 44px | Os 44px são a opção do projeto; WCAG 2.2 AA tem mínimo de 24px com exceções |

## Achados, prioridade e implementação

| Prioridade | Evidência na versão anterior | Mudança implementada | Como verificar |
|---|---|---|---|
| P0 | Fotografias de 03/10, anteriores à arte renovada e à HUD atual | Novas fotografias nativas, seis fases e interface em PT/EN; proveniência preservada | `capturas.json`, fingerprint de aparência, revisão de imagens |
| P0 | Texto introdutório e metadados competiam com a imagem e o objetivo | Abertura em duas colunas, pitch curto, factos rápidos, guia e CTA final | Capturas 390/1440px e ação visível no primeiro ecrã |
| P1 | Um único JS partilhado incluía animação e simulador da home | `site.js` só navegação; `palco.js`/`candeia.js` só na home | Scripts declarados por rota |
| P1 | Motor JS em prefetch em todas as visitas | Prefetch apenas com foco/ponteiro sobre Jogar e ligação adequada | Nenhum pedido a `/jogar/` no primeiro carregamento |
| P1 | Relógio em requestAnimationFrame, inclusive sem interação | Temporizador de 125ms; suspenso fora do ecrã, em aba oculta ou pausado | Estado do relógio, redução de movimento e teste de navegação |
| P1 | Imagem de largura única e cartões de 640px | Hero 640/1280px; cartões 320/640px; dimensões e sizes explícitos | `currentSrc` mobile/desktop e orçamento do artefacto |
| P1 | Menu e conteúdo dependiam da entrega completa do JS | Conteúdo sempre visível; menu só recolhe depois de instalar eventos | Interromper pedido do script e verificar links acessíveis |
| P1 | A cada letra o painel relia e normalizava os artigos; cruzava listas com `.some` | Índice textual e Map/Set; atualização da resposta ao guardar | Mil registos, dez pesquisas, só mil leituras do DOM |
| P1 | Rede sem prazo deixava botões e estados pendentes | AbortController de 15s; mensagem de resultado incerto; sem repetição automática | Pedido pendurado abortado, uma escrita, sessão preservada |
| P1 | Erro de formulário anunciado longe do campo | Foco e aria-invalid/aria-describedby no campo, aria-busy e bloqueio de duplicados | Validação vazia e envio pendente PT/EN |
| P2 | Trocar idioma no cabeçalho de um reporte levava à home | Mantém o contexto `/reportar/` ↔ `/en/report/` | Ligação recíproca no navegador |

## Desempenho: ganhos demonstráveis e custo da arte

O `site.js` partilhado passou de **13 947 para 4 307 bytes**, redução de 69,1%
sem minificação adicional. Isto beneficia sobretudo reportes e painel; a home
carrega também os dois módulos próprios. Não se apresenta essa redução como
redução de 69% de todo o JavaScript da home.

O relógio deixa de seguir os frames do monitor. O intervalo de 125ms limita
as atualizações programadas a oito por segundo, sujeito ao agendamento do
navegador. Não há temporizador ativo quando está parado, oculto ou fora de vista.
Isto não é uma medição de energia ou uma promessa de FPS. O dia simulado no
motor Godot e as suas regras não foram alterados.

As fotografias atuais contêm mais textura e cores do que as antigas. **O peso
total da página aumenta face às capturas antigas**. Publicar o jogo antigo
para preservar um número baixo seria uma comparação enganadora. Mantivemos
WebP sem perdas e amostragem por vizinho mais próximo; os cartões novos
permitem ao browser pedir 320px em DPR 1, reservando 640px para maior densidade.
O primeiro quadro tem prioridade alta e nunca é lazy; os restantes entram
quando necessários. A imagem visível só muda quando a próxima está carregada.

O ensaio com as fotografias da base `f3efeac` mediu **657 KiB de recursos
críticos declarados e 1611 KiB para a página inteira**, em 1440px/DPR 1,
ficheiros sem compressão HTTP. O teste pausa a animação e espera pela
decodificação de todas as imagens lazy; antes, uma rolagem rápida podia omitir
imagens da amostra. Os tetos são revistos explicitamente
na ADR 0080 e no portão, não escondidos como uma otimização. O JSON de QA inclui
também os recursos realmente pedidos na entrada, por língua e largura; essa
medição não é idêntica ao subconjunto crítico declarado pelo portão.

Os alvos de produto para medição futura são LCP ≤2,5s, INP ≤200ms e CLS ≤0,1
no percentil 75 [3–4,9]. Não foi recolhida uma amostra de utilizadores nem
ativada telemetria. Não há uma classificação Lighthouse, CrUX ou melhoria
percentual de conversão a anunciar. A existência de dimensões explícitas e de
fallbacks reduz causas conhecidas de instabilidade; não certifica CLS em campo.

## Vercel, Godot e Supabase

**Vercel.** Mantém-se a construção estática, assets com hash e política de cache
existente. A PR produz uma pré-visualização; a publicação final deve corresponder
ao SHA do merge e estar READY. Verificar `/`, `/en/`, `/reportar/`, `/en/report/`
e `/jogar/` após publicar, incluindo cabeçalhos e versão. Não é introduzido um
servidor Node para servir uma página que já funciona como ficheiro estático.

**Godot Web.** A documentação [10] distingue restrições do navegador de desempenho
da landing page. O download do jogo continua explícito e o tamanho inicial é
calculado pela construção existente. Reduzir o custo de entrar no site não
reduz automaticamente o WASM nem o tempo de compilar o motor. O portão completo
continua a verificar o arranque, escolha do monarca, toque e retorno à home.

**Supabase.** O advisor de desempenho não mostrou uma consulta lenta que
justificasse migração; indicou um índice sem uso observado. Não remover esse
índice apenas com esse sinal. A melhoria sustentada era no cliente: pesquisa
local repetida e fetch sem prazo. A API REST existente continua em uso.
Paginação `range` [11] é adequada quando uma coleção crescer para além do limite
de resposta; implementá-la deve manter ordem determinística e testar todas as
páginas. Não trocar uma coleção parcial por uma contagem enganadora.

O timeout interrompe a espera do cliente, mas **não prova que uma escrita não
chegou ao servidor** [12]. Por isso a mensagem pede verificação antes de repetir,
e não acrescenta retry automático a POST. A renovação existente após um 401
explícito permanece coberta pelos testes de sessão. Estados de sessão, rascunhos
e política de autorização não são reescritos nesta tarefa.

## Verificação e continuidade

- `node --test tests/web/*.test.mjs`: contratos de sessão, índice, timeout e dados.
- `node tests/web/painel-ui.mjs`: sessão, rascunhos, decisões, teclado e axe, com API simulada.
- `node tests/web/experience-ui.mjs`: PT/EN, mobile/desktop, fallback, Save-Data,
  teclado, validação e envio único; imagens e JSON em `build/qa/`.
- `node tools/web/verificar_site.mjs`: matriz de larguras/temas, axe, ligações,
  SEO, CSP, dados, controles, imagens, arranque do jogo e orçamentos.
- `./run_tests.sh` e `make portoes`: regressões e contratos do repositório.

O Chromium disponível inicialmente neste ambiente local falhava no arranque
WebGL tanto na base como na versão alterada. O ensaio local das páginas foi
separado desse diagnóstico; o gate completo do CI mantém o jogo obrigatório.
Não se considera o teste parcial uma aprovação do fluxo WebGL.

O próximo trabalho deve ser guiado por evidência: cinco sessões observadas do
primeiro contacto, conforme §32; waterfall e LCP em rede móvel; tarefas concretas
de pesquisa e resposta no painel. Otimizar fontes variáveis ou export do motor
só depois de isolar o custo respetivo. Publicar vídeo, instalar analytics,
adicionar bibliotecas de animação ou trocar a arquitetura não são prioridades
demonstradas pela auditoria.

## Referências primárias consultadas

1. Kingdom: https://kingdomthegame.com/kingdom-two-crowns/
2. Thronefall (página do editor): https://store.steampowered.com/app/2239150/Thronefall/
3. LCP: https://web.dev/articles/optimize-lcp
4. INP: https://web.dev/articles/optimize-inp
5. DOM e layout: https://web.dev/articles/avoid-large-complex-layouts-and-layout-thrashing
6. Navegação disclosure: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/
7. Alvos: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
8. Pausar movimento: https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html
9. CLS: https://web.dev/articles/optimize-cls
10. Godot Web: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
11. Paginação Supabase: https://supabase.com/docs/reference/javascript/using-modifiers-range
12. AbortSignal e cancelamento: https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/timeout_static
13. Carregamento diferido: https://developer.mozilla.org/en-US/docs/Web/Performance/Guides/Lazy_loading
14. Rede e adaptação: https://web.dev/articles/adaptive-serving-based-on-network-quality
15. Atualizações Supabase: https://supabase.com/changelog
