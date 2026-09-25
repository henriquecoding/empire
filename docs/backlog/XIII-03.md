# XIII-03 · §74 · O Amargueiro e a candeia, completos

```text
Porque    É o melhor rácio da parte inteira: 11 h de código e 3 de arte para a alavanca 2.
Spec      docs/design/74-a-podridao-ganha-uma-candeia-e-o-combustivel-es-.md
          docs/design/55-buildsystem-moeda-fisica-slots-pre-definidos.md
Depende   XIII-02, F1-06, ART-04
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Os três destinos com o Verbo 1; a cara na casca; a candeia com raio e cor do rot.tres
Fora      A Oferta — é o XIII-04. O cante da alvorada — é o XIII-09.
Estado    feito, falta a Semente Real (Q-087)
Horas     13 (10 + 3 arte)
```

## Notas

- Q-047: uma noite de pé, ou mais? A proposta é uma, fixa.
- O Lenho Amargo não tem preço (regra 1) — o D-02 chumba se alguém lhe der um.
- **O sistema.** `src/sim/systems/amargueiro_system.gd`, em colunas com os nomes da §84, pendurado na alvorada pela `NightWatch` (é o "sinal de alvorada que o GameClock já emite" da §74). Na alvorada: envelhece as árvores de pé, põe a serra às que já aguentaram uma noite, e levanta os mortos da noite — fora das muralhas criam raiz, dentro desaparecem como perda normal. No crepúsculo seguinte, cada árvore de pé é +22 de massa, ou +45 com nome.
- **Onde nasce** é o `AmargueiroRoots`, as cinco linhas da §74: dentro das muralhas não cria; no subsolo cria, e cresce do tecto para baixo; a voadora cai para a superfície; o Marco protege o raio dele. "Dentro" é haver um muro de pé cuja face de fora está mais longe do núcleo do que o corpo — quem morre no posto do muro morreu em cima dele. Foi essa leitura que manteve os dez dias do §66 a passar: com o centro do muro em vez da face, metade dos arqueiros do muro criava raiz e a defesa caía ao dia 9.
- **Cortar** é um slot de destino no BuildSystem (§55): a serra só pega na segunda alvorada (regra 2; as moedas largadas antes ficam no chão), custa as 6 moedas de `amargueiros.csv`, e anda enquanto houver alguém presente — o mesmo contrato de qualquer obra, com o mesmo preço a aparecer por cima (GB-05). Rende 1·2·3 Lenho por escala, 5 se tinha nome; o moral do nomeado sai no evento e é o XIII-05 que o cobra.
- **Consagrar** está inteiro no sistema — Marco de pedra, sai da massa, protege 120 px de raízes novas, e a mancha abranda sobre ele (a `NightWatch` passa os Marcos ao `RotSystem.tick` como terreno consagrado). Falta quem o chame: a Semente Real ainda não é coisa que se largue (Q-087).
- **A cara na casca** é o `AmargueiroView`: um tronco mais alto do que a pessoa, pela escala dela, com a copa curta e dois olhos — acesos se tinha nome. A serra a meio vê-se como a vida da árvore a descer. É greybox: o rosto real é do ART-04.
- **A candeia** já estava: raio `150 + 4 × dia` com teto 260 e as três paragens de cor, lidos do `rot.tres` desde o F1-17 (`WorldLight`, `RotView`).
- **O save** leva as árvores, o Lenho e a serra a meio, e repõe-nas depois das obras autoradas — provado pelo ficheiro, em `tests/save_world_test.gd`.
- Perguntas abertas por este ticket: Q-086 (a largura da base), Q-087 (a Semente Real), Q-088 (recolher o corpo é o gesto do §16), Q-089 (o vagabundo rende como escala 1).

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
