# ADR 0026 — Reportes e respostas às perguntas vivem num Supabase só do Empire

- Estado: aceite
- Data: 2026-09-28
- Secção do dossiê: §32, §36
- Complementa: ADR 0025 (o site não pede nada a terceiros)

## Contexto
O `docs/QUESTIONS.md` tem 140 perguntas à espera do dono, e a única maneira de lhes responder era editar o
ficheiro à mão ou numa conversa com um agente. Quem joga também não tinha onde dizer que um muro não caiu. O
dono pediu as duas coisas e que se aproveitasse o motor de reportes e sugestões do Recibo Certo (a Central de
Feedback: `site_feedback`, migração 018 de lá) — mas num projeto Supabase **só do Empire**, e não dentro do
Recibo Certo.

A ADR 0025 diz que o site não pede nada a outra origem, e é um portão (`verificar_site.mjs`, 12 · privacidade).
Um formulário que grava num servidor é, por definição, um pedido a outra origem.

## Decisão
**Um projeto Supabase do Empire, com o desenho da Central de Feedback copiado — não ligado —, e duas páginas no
site que só falam com ele quando a pessoa carrega num botão.**

1. **A base de dados** é `tools/web/supabase/001_empire_reportes.sql`: completa e independente, aplica-se num
   projeto vazio (é idempotente). `empire_feedback` (qualquer pessoa envia, só a administração lê, muda o estado e
   apaga), `empire_respostas` (só a administração lê e escreve), `empire_admins` e `empire_e_admin()` (quem
   administra; escreve-se só pelo SQL Editor). As regras são as da 018 do Recibo Certo: o texto com código é
   recusado no cliente e limpo outra vez num gatilho. Nada deste projeto toca no Recibo Certo.
2. **O site** ganha `/reportar/` e `/en/report/` (o formulário, nas duas línguas) e `/painel/` (o dono entra com
   email e palavra-passe, responde às perguntas — aprovar a proposta, outra resposta, adiar — e trata os
   reportes). As perguntas saem do `QUESTIONS.md` em cada publicação (`tools/web/perguntas.mjs`), como o resto
   do site sai do repositório.
3. **A exceção à ADR 0025 é estreita.** Só estas três páginas têm o Supabase no `connect-src` da CSP; a entrada,
   o 404, o jogo e o dossiê continuam sem ele, e o portão 12 continua a medi-los. Nenhuma das três faz um pedido
   ao carregar: o primeiro é o do botão «Enviar» ou «Entrar». O rodapé diz isto em vez de «sem pedidos a
   terceiros».
4. **Sem dependências novas.** O cliente (`tools/web/paginas/motor.js`) é JavaScript sem SDK: `fetch` à API REST
   e ao Auth do Supabase. A chave no site é a **publicável** — o que ela deixa fazer decide-o o RLS — e a
   construção chumba se lhe derem uma chave secreta. O endereço e a chave vêm de `EMPIRE_SUPABASE_URL` e
   `EMPIRE_SUPABASE_CHAVE` ou, sem elas, de `tools/web/supabase/config.json`.
5. **As respostas voltam ao repositório por um agente.** O painel copia-as em markdown; um agente com acesso ao
   Supabase lê `empire_respostas`, aplica cada uma no `QUESTIONS.md` (e no código, se for o caso) e marca-a
   `aplicada`. O painel nunca escreve no repositório.

## Consequências
- O que se guarda de quem reporta é o que ela escreve, a página, o commit publicado e, se quiser, o nome e o
  email. Sem `user_id`, sem IP, sem cookies.
- O projeto Supabase passa a fazer parte do site: se estiver em baixo ou por configurar, as páginas publicam-se
  na mesma e dizem que o envio não está ligado.
- Uma resposta mudada no painel volta a `nova`: tem de ser aplicada outra vez.
