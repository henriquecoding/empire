# LEGAL — o mapa, antes da primeira coisa pública

> Isto é um mapa do que tem de estar resolvido e onde, não aconselhamento jurídico. O dossiê diz o mesmo sobre
> contratos (§35): **antes de assinares seja o que for, mostra-o a um advogado que trabalhe com jogos.**

## 1 · De quem é o quê

| Coisa | Situação | Ficheiro |
|---|---|---|
| Código, design, dados, texto, áudio original | teu, todos os direitos reservados | `LICENSE` |
| Arte | tua, todos os direitos reservados; nunca entra num pacote de *assets* | `LICENSE` |
| Componentes de terceiros | cada um com a sua licença e a sua prova | `NOTICE.md`, `docs/legal/THIRD_PARTY_ASSETS.csv` |
| Referências (Milki Delivery, Eastward, Chef RPG) | dos respetivos estúdios; **só para medição**, nunca no repositório público, no jogo ou em marketing | `THIRD_PARTY_ASSETS.csv` |

**Regra:** nenhum ficheiro de terceiros entra em `art/`, `audio/` ou `addons/` sem uma linha no
`THIRD_PARTY_ASSETS.csv` com licença, uso comercial, atribuição e prova arquivada.

## 2 · O nome e a marca

*Empire* é codinome e quase de certeza colide com marcas registadas (§36). O nome final passa pela verificação da
Bíblia de nomes (Steam, EUIPO, INPI, domínio, *handles*) **antes da Fase 4** — antes de logótipo, capsule ou
página. Ver `docs/content/NAMING_BIBLE.md` §1.

## 3 · Privacidade e telemetria (RGPD)

A decisão do §32, que é a única compatível com o RGPD sem trabalho de conformidade:

- **Sem dados pessoais**: um ID aleatório gerado localmente; sem IP, sem nome, sem perfil de Steam.
- **Consentimento explícito** no primeiro arranque; **desligada por omissão** na versão pública.
- Nos *playtests* fechados, com consentimento escrito, pode ser mais generosa (PLAYTEST_FORM, parte A).

**Antes da demo** falta escrever: o aviso de privacidade (o que se recolhe, para quê — afinar o jogo —, onde fica
guardado, durante quanto tempo, e como desligar) e decidir onde vivem os dados. Se houver um servidor de terceiros
a recebê-los, entra aqui e no `THIRD_PARTY_ASSETS.csv`. Item da `docs/release/RELEASE_CHECKLIST.md`.

## 4 · Plataforma e atividade

- **Steam Direct** (§35): 100 USD por produto, recuperáveis depois de 1 000 USD de vendas; o acordo de distribuição
  da Steam aplica-se ao jogo e à página.
- **Atividade e contabilidade** (§35): abertura de atividade e contabilista para os 2–3 anos do projeto. As vendas
  na Steam têm regras fiscais próprias — confirma com o contabilista, não com este documento.
- **Classificação etária:** a Steam usa o seu questionário de conteúdo; para consolas (Fase 8 e parcerias, §35)
  entra o IARC/PEGI.

## 5 · Contratos com terceiros

| Contrato | O que exigir |
|---|---|
| Compositor / *sound design* | cessão ou licença para o jogo **e** para *trailers* e marketing; ficheiros-fonte (*stems*) entregues; crédito |
| Publisher / marketing / consolas | as cláusulas a recusar sempre estão no §35: propriedade da IP, receita perpétua, recuperação só da tua parte, sem auditoria, sem reversão, marketing vago, cessão sem consentimento |
| Tradutores | cessão dos textos traduzidos; confidencialidade até ao anúncio |
| Playtesters | consentimento de gravação e de dados (PLAYTEST_FORM) |
