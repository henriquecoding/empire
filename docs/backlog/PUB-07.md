# PUB-07 · O portão de produção espera pelo limite da API

```text
Porque    O dono, a 20/10/2026, com o registo do deploy de produção do 722fad6:
          «O deploy falhou, verifique tudo o que foi feito mal e corrija». O
          portão (tools/web/release-gate.mjs) esperou 19 min pelo CI e morreu
          num HTTP 403 a cinco minutos do verde: a API do GitHub sem token dá 60
          pedidos por hora a cada IP, e a máquina de build da Vercel partilha o
          dela com outros projetos.
Spec      docs/backlog/RG-29.md (o portão)
          docs/adr/0024-o-jogo-publica-se-na-vercel.md
Depende   RG-29
Contrato  Só o CI verde do mesmo commit da main autoriza a produção, como antes;
          mas o limite da API é uma espera, não uma recusa, e o que recusa diz
          porquê. Sem segredo obrigatório; um token só de leitura, se existir,
          nunca vai para o registo.
Feito     403/429 de limite (x-ratelimit-remaining 0, retry-after ou a mensagem
          do limite secundário) esperam até renovar, dentro do prazo; se só
          renovam depois dele, recusa logo e diz-se. Erros de rede e 5xx voltam
          a pedir e falham fechados no fim do prazo, com o último erro. Um 403
          que não é limite recusa logo, com a razão do GitHub. Pede de dois em
          dois minutos (eram 60 s). EMPIRE_GITHUB_TOKEN, nas variáveis da
          Vercel, autentica o pedido (5000 por hora).
Fora      Mudar quem dispara a produção (um deploy hook a partir do CI), o
          cancelamento do CI anterior na main e o Supabase do painel.
Estado    feito
Horas     —
```
