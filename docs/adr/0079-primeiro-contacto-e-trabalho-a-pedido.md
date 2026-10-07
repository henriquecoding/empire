# ADR 0079 — Primeiro contacto claro e trabalho a pedido

- Estado: aceite
- Data: 2026-10-07
- Secção do dossiê: §26, §32, §36
- Complementa: ADR 0025, 0026, 0056
- Tarefa: PUB-05

## Contexto

O pedido do dono inclui pesquisa, implementação, PR e merge. A auditoria e a
comparação estão em `docs/reports/SITE-EXPERIENCE-2026-10.md`. A página já é
estática, bilingue e servida pela Vercel, com fontes locais e CSP. O problema
não pede outro framework: pede hierarquia, imagens fiéis, menos trabalho
sem interação e estados de erro que permitam continuar.

A `main` recebeu a arte renovada e, durante esta tarefa, o Atlas (PR #94).
As capturas antigas já não representavam esse jogo. Fotografias novas têm
mais informação: o orçamento do greybox/arte anterior não mede a mesma coisa.

## Decisão

1. Título e ação ao lado do jogo no desktop; empilhados no telemóvel. Guia de
   três passos e ligação aos controlos antes das secções extensas. Proveniência
   acessível num `details`, sem competir com a ação principal. PT e EN mantêm
   a mesma estrutura. O idioma de um reporte leva ao mesmo formulário.
2. O conteúdo nasce visível. A navegação móvel só recolhe os links quando o
   script está instalado. Escape devolve o foco ao botão; saída de foco ou
   clique fora fecha o menu. Controlos principais com pelo menos 44px.
3. O palco usa um relógio de apresentação de 125ms. Não agenda trabalho quando
   pausado, oculto ou fora do viewport. Começa pausado para movimento reduzido,
   toque, Save-Data ou rede 2G/3G; pode ser comandado explicitamente. As imagens
   são carregadas antes de substituir a imagem visível. Sem RAF permanente.
4. O motor Web só recebe prefetch com foco/ponteiro num link de jogar, respeitando
   economia de dados. Scripts do palco e da candeia só entram na home; formulários
   e painel recebem apenas os scripts de que precisam.
5. Capturas reais, WebP sem perdas, dimensões explícitas e `srcset` coerente com
   o preload. Hero: 640/1280px. Cartões: 320/640px, com vizinho mais próximo.
   Interface: captura por língua. Imagens de partilha também regeneradas.
6. A pesquisa do painel normaliza os textos uma vez e atualiza o índice de
   respostas ao guardar. `Set`/`Map` substituem a procura repetida no DOM e a
   verificação quadrática de visibilidade dos botões.
7. Cada pedido de rede tem prazo de 15s com AbortController. Um timeout de escrita
   comunica resultado incerto e não provoca nova escrita automática. Sessão e
   rascunhos são preservados. Não é alterada a política existente de renovar
   sessão perante uma recusa 401. O formulário marca/foca o campo inválido,
   anuncia estado e impede submissões concorrentes.
8. Sem dependências novas de produção, sem analytics e sem alterações de RLS.

## Orçamentos e alternativas

Mantemos a arte sem perdas: uma alternativa WebP com perdas baixaria bytes mas
alteraria os pixels. O comparável é o mesmo conjunto de capturas. Os cartões a
320px reduzem o seu peso em cerca de 70% em DPR 1 face a enviar sempre 640px.
Os antigos tetos de 420/800 KiB passariam a rejeitar a representação fiel do jogo.
O portão passa a exigir 660 KiB para os recursos críticos declarados e 1700 KiB
para toda a home em 1440px/DPR 1. A medição foi 657/1611 KiB. A animação fica
pausada e todas as imagens lazy são decodificadas: a medição anterior podia
omitir imagens quando a rolagem de teste passava depressa por elas.
Isto é um aumento explícito do teto de transferência, não um ganho de LCP.
O relatório distingue custos da arte nova dos ganhos de carregamento a pedido.

Rejeitados: trocar a stack estática; lazy-load da primeira imagem; vídeo automático;
carregar o motor em cada visita; retirar índices de Postgres só porque o advisor
não viu uso; repetir POST depois de uma ligação interrompida. Nenhuma dessas
mudanças é sustentada pelo problema observado.

## Verificação

`experience.test.mjs` prova o índice e o timeout, com regressões observadas antes
da implementação. `experience-ui.mjs` verifica PT/EN, duas larguras, falha de
script, Save-Data, teclado, idioma no contexto e um único POST em voo. A API é
simulada; não se criam reportes reais. Os testes existentes de painel e o portão
completo do site continuam obrigatórios no CI, incluindo arranque Web do jogo.
Os artefactos de QA são gerados em `build/qa/`. LCP/INP/CLS reais e compreensão
humana do primeiro dia exigem medições posteriores, não inferências destes testes.
