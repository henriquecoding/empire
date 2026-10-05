# ADR 0067 — Solo, Coop e Conquista

- **Estado:** design aceite pelo relatório de 05/10/2026; implementação online por fazer.
- **Substitui parcialmente:** Q-204 e UN-29/UN-30, conforme a precedência pedida nesta sessão.

Solo tem um reino. Coop tem um reino, uma população e economia partilhadas; apenas o
criador da sala pode fundar. P2 explora e sugere, mas não herda automaticamente a
autoridade se P1 sair antes da fundação. Depois de fundar, as estruturas pertencem ao reino.

PvP inicial tem dois reinos independentes. P1 nasce a Oeste e P2 a Este, cada um com
carroça, cidadãos, tesouro e conhecimento próprios. A condição canónica é soberania
total sobre os reinos relevantes, não a antiga alternativa de simples fim da continuidade.
A captura concreta e a graça de fundação precisam de dados e ADR de combate competitivo.

Um protótipo local pode testar permissões e propriedade, mas não conclui o modo online.
`PlayerId`, `TeamId` e `RealmId` têm significados próprios; não se infere fundador de peer 1.
Critérios completos em `docs/reports/EMPIRE-MASTER.md`; execução UN-29 a UN-31 e RG-25.
