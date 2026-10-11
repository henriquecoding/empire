# ADR 0080 — Correções da auditoria de 11/10/2026

O dono pediu implementar os achados da auditoria desta sessão. Mantêm-se o design,
balanceamento, arte, áudio e as decisões históricas; corrige-se a sua execução.

O relógio é espelhado antes dos consumidores da alvorada. O abastecimento recebe
o mesmo dia explícito dos restantes pagamentos. A retoma valida as colunas, tipos,
IDs, relógio e referências essenciais antes de instalar o candidato; slots inválidos
permanecem no disco e o slot anterior válido continua disponível.

O painel escreve condicionalmente à revisão lida. Um conflito mantém o rascunho,
exige carregar a versão guardada para revisão e só depois permite uma nova escrita
explícita. Rascunhos incluem a revisão de origem e os de reportes também impedem
fechar/sair sem guardar. Aprovações guardam a proposta exata, SHA-256 e commit;
aprovações antigas são identificadas como não arquivadas, sem inventar o seu texto.
O histórico de revisões fica protegido por RLS, apenas legível pela administração.
Recriar uma pergunta eliminada continua a numeração do histórico, conservando as
aprovações anteriores e recusando escritas de abas anteriores à eliminação.

O teto público é serializado por um lock transacional no servidor. A deduplicação
usa um UUID aleatório por operação, reutilizado apenas no reenvio do mesmo conteúdo;
texto igual de pessoas diferentes não é descartado. Não se guardam IPs nem IDs de
visitantes. Clientes mantêm apenas as permissões utilizadas pela aplicação.

As dependências de QA existentes (Playwright e axe) passam a versões exatas e
lockfile. Acrescenta-se **@electric-sql/pglite 0.5.8**, só em QA, para executar as
migrações e regressões de RLS, revisões e idempotência num Postgres isolado, sem
credenciais, dados nem alterações de teste permanentes em produção. O site e o jogo
continuam sem esta dependência. Actions e downloads do motor usam hashes fixados.

A vistoria publica a duração realmente executada e pode exigir cobertura mínima.
Medições CPU em ambiente virtual ficam separadas da certificação física da matriz
de desempenho; não se declara aprovação de Steam Deck sem medir esse equipamento.
