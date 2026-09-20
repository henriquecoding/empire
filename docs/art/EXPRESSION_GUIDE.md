# Guia de expressões — o humor está na cara

> **Referência principal:** os personagens quase concluídos enviados pelo autor, conforme [REFERENCE_AUTHORITY.md](REFERENCE_AUTHORITY.md). O arqueiro antigo foi rejeitado e o rei exige redesign. As medidas deste guia são orientações; não autorizam normalizar os rostos originais.

> O dossiê é curto e firme: **bocas largas com dentes, olhos afastados, narizes grandes; o humor está na cara,
> não em piadas de texto — e por isso atravessa idiomas de graça** (§01, §22). O rosto é também interface: a
> camada `face` diz a vida e a lealdade da tropa sem barra nem número (§07, §24, §58). Este guia fixa como.

## 1 · A gramática do rosto

Medidas para a escala 2 (46–52 px de altura, rosto ≈ 10 × 10 px). Na escala 1 tira-se 1 px a cada medida;
na escala 3 soma-se 1 px.

| Elemento | Regra | Porquê |
|---|---|---|
| Olhos | 1 × 2 px (pupila preta), **afastados**: 3–4 px entre eles | olhos afastados leem-se como ingénuos e cómicos a esta escala |
| Sobrancelhas | Opcionais. 1 px de altura, 2–3 px de largura; só aparecem para dizer alguma coisa (raiva, medo) | em repouso, sobrancelha é ruído |
| Nariz | **Grande**: 3–4 px, tom de pele mais escuro, sem contorno próprio | é a massa que dá carácter ao perfil |
| Boca | **Larga**: 5–7 px; fechada é uma linha de 1 px; aberta mostra dentes | a boca é o mostrador de emoção |
| Dentes | Blocos brancos de 1–2 px, com o contorno da boca a separá-los | "bocas largas com dentes" é a assinatura (§01) |
| Contorno | 1 px preto no exterior da cabeça; o rosto interior não leva contorno | lei da escala dupla: personagens a 1 px (§01) |
| Cor | Dois tons de pele por povo (sombra e luz), da rampa do povo | §22: dois tons por material |

**Proibido:** pupilas maiores do que 2 × 2 px (viram *anime*), bochechas com gradiente e deformar a cabeça em *squash & stretch* (ANIMATION_BIBLE §1).

## 2 · A matriz

Uma expressão por estado de jogo. A camada `face` troca-se por dados (`health`, `loyalty`, estado da FSM), nunca
por animação própria: **o rosto muda de estado sem mudar de frame**.

| Estado | Camada | Olhos | Boca | Postura (camada `body`) | Quando aparece |
|---|---|---|---|---|---|
| Repouso | `face_normal` | conforme a identidade original | expressão própria: sorriso dentado, língua ou boca característica | postura original | `idle`, `walk` |
| Trabalho | `face_normal` | focados (1 px mais baixos) | fechada, cantos para dentro | ativa | `work`, `build`, `smith`, `cook` |
| Medo | `face_fear` | grandes (2 × 2) | aberta, dentes de cima | retraída, joelhos | `flee` (§07: muro cai, vida < 30%) |
| Raiva | `face_angry` | apertados + sobrancelha em V | dentes cerrados | inclinada para a frente | `attack`, berserker sempre |
| Golpe recebido | `face_hit` | fechados | careta | compressão de 1 px | `hit` (2 frames) |
| Ferido | `face_hurt` | um meio fechado | torta, dente partido | ombro caído | **vida < 50%** (§07) — é o HUD da vida |
| Vitória | `face_normal` | arqueados (^ ^) | sorriso aberto, dentes | peito aberto | `celebrate`, amanhecer ganho |
| Encantado | `face_charmed` | semicerrados, sonhadores | sorriso pequeno | balanço | encantado pelo bardo (§08); `loyalty` < 1 |
| Apodrecido | `face_rotten` | caídos | aberta, sem dentes à vista | curvada | rasto da Podridão; é o `palette_lut` a fazer a cor, não desenho novo (§22) |
| A dormir | `face_sleep` | fechados (linha) | fechada | deitado | `sleep` |
| Corpo | `face_sleep` | fechados — **nunca em X** | fechada | último frame de `die` | ressuscitável até ao amanhecer (§16): lê-se como dormir, não como fim |

Mínimo para a fatia vertical: `normal`, `hurt`, `hit`, `fear`. O §22 conta 3 h para "ferido · encantado · apodrecido".

## 3 · Leitura

- **A 1×.** Tira uma captura a 1280 × 720 sem zoom e outra a 50%. A expressão tem de se ler na primeira; a
  silhueta da postura, na segunda.
- **Em movimento.** O rosto acompanha o pivot da cabeça. Dano e medo reagem imediatamente; prioridade: impacto, medo, ferido, ação, repouso. A troca de expressão não reinicia o corpo.
- **Identidade.** Assimetria de boca é permitida quando pertence ao desenho original e continua legível a 1×.
- **No Steam Deck.** O ecrã do Deck é praticamente a tua tela (§19); se lá não se lê, não se lê.
- **Com 300 unidades.** Em multidão, só o `face_hurt` e o `face_fear` têm de sobressair: são informação de jogo.
  O resto pode perder-se.

## 4 · Diferenças entre povos — proposta

A gramática é a mesma para todos; muda o sotaque. Nada disto está no dossiê: é para o primeiro povo novo decidir.

| Povo | Sotaque do rosto |
|---|---|
| Enramados | Rostos compridos, nariz de ponta; sobrancelhas espessas como ramos |
| Portuários | Olhos semicerrados de sol e sal; pele mais escura; rugas de 1 px nos cantos |
| Fenda | Sobrancelha pesada contínua; nariz largo e chato; pouca expressão — a pedra fala pouco |
| Horta | Os legumes: cabeça é o próprio vegetal (Knight Potato, Archer Leek); olhos e boca pintados sobre a forma |
| Fornalha | Fuligem na cara (manchas de 2 px); à noite, os olhos refletem a forja |
| Sob-Raiz | Olhos maiores (2 × 2 em repouso, habituados ao escuro); pele pálida; nariz pequeno — a exceção à regra |

## 5 · Classes e elites

| Quem | O que o rosto faz |
|---|---|
| Monarca | Gordo, coroa torta, sorriso de quem nunca pagou a conta — a coroa nunca troca (§04) |
| Escudeiro | Elmo grande a tapar metade dos olhos; a boca faz o trabalho todo |
| Bardo | O mais expressivo: boca sempre aberta ou a cantar |
| Ferreiro | Bigode (§04); a boca quase não se vê |
| Cozinheiro | Língua, boca original e barrete branco; rosto e corpo da referência preservados |
| Cavaleiro Enterrado | Elmo fechado: a expressão vive **só na postura** |
| Cavaleiro Selado | O elmo tapa os olhos (§08): só boca e queixo — quando fica cego, a boca é tudo o que resta |
| Elite (escala 3) | A mesma gramática com 1 px a mais em cada medida e **um** detalhe extra (cicatriz, dente de ouro) |
| Tropa comum (escala 2) | Nenhum detalhe extra: a cabeça (`head`) é que dá a identidade |

## Integração de 19/09/2026

O atlas atual conserva as faces originais. Flash de impacto e prioridade de expressão são assuntos diferentes: o flash já está ligado; os sprites `hurt`, `hit` e `fear` ainda precisam de desenho. Ver ADR 0022.
