# PUB-04 · O site mostra o jogo de hoje

```text
Porque    O dono, a 03/10/2026: «melhore o design e a experiência do site, ainda está tudo muito
          amador; pesquise densamente e refine tudo, inclusive tem muita informação
          desatualizada». Medido no build da main (caa92b5): as seis fotografias eram do
          greybox de 25/09, de antes dos sprites; os oito povos diziam todos «é este que se
          joga hoje»; «Atacar» não tinha tecla, porque o leitor do project.godot só conhecia
          o formato longo dos eventos; a candeia era descrita «cor de brasa» quando o Lume
          é roxo desde a ADR 0034; os monarcas (ADR 0052), o combate manual, o subsolo em
          sítios e as tuas luzes não apareciam; e o jogo só se via abaixo da dobra.
Spec      docs/design/36-wishlists-pagina-demo-e-trailer.md
          docs/design/08-quatro-arquetipos-duas-fases-cada.md
          docs/design/74-a-podridao-ganha-um-lume-e-o-combustivel-es-tu.md
          docs/design/80-o-preto-entra-na-paleta-e-a-noite-deixa-de-ser-a.md
Depende   PUB-02
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     As fotografias são o jogo de hoje: as seis fases sem a interface, o quadro inteiro,
          e o ecrã com a interface em cada língua (tools/web/capturas.py, captura --limpo).
          A abertura mostra o jogo acima da dobra, com a linha do dia por baixo, e só
          descarrega a fotografia seguinte quando é precisa. Secção nova dos monarcas, lida
          do ecrã de escolha do jogo (monarchs.csv, strings.csv, classes.csv); as últimas
          decisões lidas de docs/adr/; o povo de partida pelo segmento do SimFactory; o
          âmbar do fogo e o roxo do Lume do rot.csv; os eventos compactos do project.godot.
          Uma letra para a interface (IBM Plex Mono) e a Silkscreen só no nome. O portão do
          site mede tudo isto (ADR 0056).
Fora      Um domínio próprio. Um devlog ou um press kit (§36: Fase 4). A página de Steam.
          A casca do jogo em /jogar/ e o painel do dono. O nome final e o logótipo (NB-01).
Estado    feito
Horas     —
```

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
