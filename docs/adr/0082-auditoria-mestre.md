# ADR 0082 — Corrigir os contratos observados na auditoria mestre

Data: 2026-10-09. Estado: implementada; publicação depende do CI do commit.

## Contexto

A auditoria entregue pelo dono reproduziu fundações com cave sem baía, pagamentos à
bolsa do rei ausente e divergências entre decisões, indicadores e publicação.
Fonte: `docs/reports/AUDITORIA-MESTRE-2026-10-09.md`. Não substitui respostas do dono.

## Decisões de implementação

- A fundação procura uma baía válida dentro do primeiro recinto, preservando todos
  os interiores conhecidos. Experimenta os lados e os limites livres das reservas.
  Sem espaço, recusa com motivo; nunca publica entrada inválida ou baú não finito.
  A localização escolhida fica na assinatura do sítio e sobrevive à retoma.
- Q-242/Q-243: rampa de sete noites; primeiro pico na noite 12, depois cada seis.
  Q-239/Q-241 mantêm-se. Q-240 continua sem um novo valor aprovado.
- O primeiro amanhecer depois de fundar e atravessar uma noite inicia todas as
  sociedades, segundo o mapa determinístico. Começam sem edifícios prontos; pagam
  construções com o tesouro próprio e precisam do construtor. Não dependem da visita.
- Tesouro da cave: paga herdeiro, soldos e reposição doméstica, por esta ordem,
  conservando os custos existentes. A aljava pessoal continua a exigir compra.
  O extrato da última alvorada é limitado e persistente. A bolsa não paga à distância.
- Herdeiro neutro: manutenção continua depois de formado; falta de fundos perde o
  treino. Na casa, o jogador pode consumir a formação para escolher outro dos três
  imperadores iniciais. Vida proporcional, moeda, coroa e flechas pagas conservam-se;
  os bónus recuperam ao longo das cinco noites aprovadas. Encontros e imperadores
  adicionais continuam fora deste elenco e por implementar.
- Q-203: banca universal de emissários no primeiro recinto. Usa um trabalhador e
  o preço existente de 20 moedas, sem Sementes Reais. A Embaixada mantém a formação
  superior. A banca nasce depois das obras carregadas, preservando os ids antigos.
- Fontes de rocha conservam a localização e distinguem o acesso. Uma passagem
  fechada impede operação; a reabertura recalcula. Água funcional desenhada a partir
  da mesma fonte usada pelo avaliador, sem deslocar o recurso com a sede.
- Subsolo inteiramente tapado não é enviado para desenho; janelas visitadas e a
  transição de abertura preservam o interior. Isto não certifica o orçamento GPU.
- Pausa noturna identifica o dia do checkpoint e não promete guardar a noite.
  Escala de texto/painéis independente da preferência de tamanho dos botões de toque.
- Resultados de testes pertencem a uma execução com data, SHA e URL; inventário é
  contado separadamente. Cada execução do CI publica a sua própria evidência JSON.
- Produção Vercel espera pela conclusão bem-sucedida do workflow completo `ci.yml`,
  disparado por push na `main` do mesmo SHA. Ausência, erro, cancelamento e timeout
  recusam o build. Não exige tokens (repo público), nem cria dependências. Preview e
  CI local não aguardam a si próprios. O artefacto é reconstruído do SHA aprovado;
  não se afirma que é o mesmo binário exportado no CI.

## Limites

Não aprova propostas de clima, nova cadência de espécies, pacto da tocha, tipos de
água, novos cenários, áudio, imperadores por encontro ou infraestrutura multiplayer.
Proteção administrativa da `main` é independente do bloqueio do build de produção.
Os resultados e lacunas por achado estão no relatório de implementação.
