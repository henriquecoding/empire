# Implementação da auditoria de 11/10/2026

Base auditada: `99ac902ab7c396d6cd80c2d81510f79e81e450e7`. A ADR 0080 regista
as escolhas de implementação. Balanceamento, decisões de design, arte e áudio
mantêm as respetivas fontes; as alterações abaixo corrigem execução e validação.

| Item | Alteração | Prova / limite |
|---|---|---|
| A01 | Relógio espelhado antes dos consumidores da alvorada | `tests/dawn_calendar_test.gd`: sociedades e prazo da ganância na primeira alvorada |
| A02 | Dia explícito na reposição de flechas | Mesmo teste: manutenção, herdeiro e flechas preservados no extrato e save |
| A03 | Validação estrutural antes das migrações e da instalação de um save | `tests/save_recovery_test.gd`: coluna curta, tipo errado, NaN, IDs repetidos e rei ausente; candidato rejeitado sem substituir a simulação, slot anterior recuperado |
| A04 | Exit code do export preservado antes de filtrar o log | `tests/web/export.test.mjs`: erro com ficheiros presentes continua a chumbar |
| A05 | PATCH e DELETE condicionais à revisão; criação não sobrescreve uma decisão existente | Testes SQL e `tests/web/painel-ui.mjs` com dois separadores: rascunho conservado, conflito visível, revisão explícita antes da nova escrita |
| A06 | Rascunhos de reportes e envios pendentes entram na proteção de saída | Teste de navegador: `beforeunload`, sair, guardar e descartar |
| A07 | Texto da proposta, SHA-256 e SHA da fonte em cada resposta; histórico imutável para clientes | Hash calculado no servidor; RLS no histórico. Decisões antigas têm origem não arquivada, sem reconstrução retroativa inventada |
| A08 | Teto público serializado por advisory lock transacional antes de contar e admitir | SQL real isolado: teto, retry no teto e ordem da deduplicação; isolamento de produção READ COMMITTED |
| A09 | UUID por operação, reutilizado no retry e renovado depois de confirmação | Testes cliente e SQL: conteúdos iguais com UUIDs distintos são dois reportes; retry do mesmo UUID é um só. POST simples, sem exigir SELECT ao visitante |
| A10 | Pendente de plano | O projeto Supabase está no plano Free; proteção de palavras-passe comprometidas requer plano elegível. Nenhum upgrade contratado |
| A11 | TRUNCATE/TRIGGER/REFERENCES e escrita de administradores revogados aos clientes; UPDATE limitado às colunas usadas | Testes SQL com roles reais e RLS; o serviço e o helper de administração conservam as permissões necessárias |
| A12 | Configuração administrativa preparada, ainda não ativada | `.github/main-protection.json`: PR, `ci` do GitHub Actions, base atualizada, administradores incluídos, sem force-push nem eliminação. O conector não expõe escrita de proteção de ramos |
| A13 | Actions por SHA, QA com versões exatas e lockfile, downloads e caches Godot verificados por SHA-256 | CI usa `npm ci`; manifesto `tools/godot-checksums.json`; Dependabot vigia as três camadas |
| A14 | Vistoria distingue pedido, ticks/dias reais, derrota e cobertura mínima | `build/vistoria.json`; `--min-dias` faz falhar cobertura insuficiente. Derrota sem invariantes quebradas é validação parcial; o ensaio fechado de dez noites é uma prova diferente na suite |
| A15 | Benchmark CPU reproduzível com 300 tropas e percentis publicado pela CI | `build/benchmark-sim.json`. Certificação gráfica C1–C6 e máquinas da `PERFORMANCE_MATRIX.md` continua pendente de hardware real |
| A16 | EXECUTE de `rls_auto_enable()` revogado a PUBLIC/anon/authenticated | Migração 003; ativação automática de RLS preservada |

## Reproduzir a validação

```sh
make portoes
make dados testes vistoria benchmark-sim
cd ferramentas && npm ci --no-audit --no-fund && npx playwright install chromium
cd ..
bash tools/web/construir.sh
node --test tests/web/*.test.mjs
node tests/web/painel-ui.mjs
node tests/web/experience-ui.mjs
node tools/web/verificar_site.mjs
```

A CI grava os casos realmente executados, SHA e run em `build/test-execution.json`
e publica esse ficheiro, o relatório gdUnit, a cobertura da vistoria e o benchmark
no artefacto `relatorio-gdunit4`. O inventário de funções em `validation.json`
não substitui o resultado de execução. A Vercel mantém a exigência do `ci` verde
do SHA exato do push para `main` antes de publicar.

## Migração e dados existentes

`tools/web/supabase/003_empire_auditoria_revisoes_e_seguranca.sql` é aditiva e
transacional. Arquiva a revisão atual das respostas existentes, mantendo texto,
escolha e estado; não lhes atribui uma proposta histórica desconhecida.
Não contém IDs gerados, credenciais nem dados pessoais. Testes de produção
usam transação revertida; testes permanentes correm em Postgres isolado de QA.

## Configuração administrativa pendente

A proteção de `main` pode ser aplicada com uma sessão administrativa já autorizada:

```sh
gh api --method PUT repos/henriquecoding/empire/branches/main/protection \
  --input .github/main-protection.json
```

O payload usa o ID de GitHub Actions observado nos checks deste repositório e
zero revisores obrigatórios para não impedir o dono de integrar os seus PRs.
Verificar depois que o ramo está protegido e que `ci` é obrigatório. O conector
conectado não disponibiliza a operação administrativa; o payload ainda não foi aplicado.
Referência: [API de proteção de ramos](https://docs.github.com/en/rest/branches/branch-protection).

Para A10, ativar a proteção contra palavras-passe comprometidas apenas quando
o plano do projeto a disponibilizar; verificar o advisor depois da alteração.
Referência: [segurança de palavras-passe do Supabase](https://supabase.com/docs/guides/auth/password-security).
