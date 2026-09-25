# PUB-02 · O site passa a ser a página do jogo

```text
Porque    O PUB-01 pôs o jogo num endereço, e a página à volta dele ficou por fazer: uma língua
          só, as fontes pedidas à Google com o IP de cada visitante, o texto copiado à mão do
          dossiê (e a divergir dele), JavaScript em linha que impedia uma CSP a sério, e uma
          imagem de partilha cortada a meio. O §36 quer a página antes da demo; o §32 quer que
          nada meça quem a lê.
Spec      docs/design/36-wishlists-pagina-demo-e-trailer.md
          docs/design/32-medir-sem-espiar.md
          docs/design/04-cada-imperio-e-um-povo-diferente.md
          docs/design/05-o-dia-a-noite-e-a-podridao.md
          docs/design/80-o-preto-entra-na-paleta-e-a-noite-deixa-de-ser-a.md
Depende   PUB-01
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     / em PT-PT e /en/ em inglês, com a mesma forma, lidas do repositório na construção
          (tools/web/dados.mjs): as fases e a luz do clock.csv, a candeia e as falas da Podridão
          do rot.csv, offers.csv e strings.csv, os controlos do project.godot, os povos, o ciclo e
          o roteiro do §04, do §05 e do §33, o estado do tickets.json. Seis fotografias do jogo ao
          longo do dia, tiradas pelo próprio jogo (make site-capturas). Fontes servidas pelo site,
          nenhum pedido a outra origem, CSP estrita em todas as páginas e na casca do jogo. O
          tools/web/verificar_site.mjs mede tudo isto, em 19 grupos (ADR 0025).
Fora      Um domínio próprio. Um devlog ou um press kit (§36: Fase 4). A página de Steam.
          Telemetria de qualquer espécie. O nome final e o logótipo (NB-01).
Estado    feito
Horas     6
```

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
