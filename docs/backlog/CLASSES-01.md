# CLASSES-01 — Três classes na primeira escolha

```text
Estado    feito
```

Implementado; verificação de integração antes do merge.
- **Pedido:** dono, 01/10/2026. Escolher três classes ao iniciar pela primeira vez, com a jogabilidade do dossiê; pesquisar também na web.
- **Fonte:** §08, §24; Q-114, Q-140, Q-150, Q-162 e Q-163. ADR 0044; propostas de execução em Q-183.

## Comportamento

Partida nova abre a escolha de Monarca, Arqueiro e Bardo com retrato, papel, habilidade base, evolução e controlos. O tempo fica parado até confirmar. O corpo inicial do Arqueiro ou Bardo nasce junto do rei; o rei mantém coroa, moedas e gestão. Continuar mantém a escolha e os feitos.

Monarca mantém aura de defesa, escudeiro e evolução. Arqueiro marca um alvo para as tropas do mesmo dono; evoluído, marca em área e um tiro atinge a coluna à frente. Bardo encanta criaturas fracas temporariamente e anda mais depressa; Maestro converte criaturas poderosas permanentemente e promove tropas próprias. Evoluir exige feito e Semente Real. Reencantar a mesma criatura não repete o feito.

Criaturas encantadas combatem a Podridão, não recebem fogo amigo, não roubam galinhas nem são repelidas pelas luzes do reino. Conversões permanentes sobrevivem à alvorada e ao save. Só o Monarca constrói e contrata.

## Critérios verificáveis

- [x] As três opções existem e só a confirmação começa a partida.
- [x] Rei e economia continuam presentes nas escolhas de Arqueiro e Bardo.
- [x] Alvos marcados têm prioridade para tropas do mesmo dono, dentro do alcance.
- [x] A flecha evoluída causa dano na coluna à frente; não atinge a coluna atrás.
- [x] Encanto base expira; conversão do Maestro persiste; o feito conta criaturas distintas.
- [x] Promoção conserva a proporção de vida, sem curar a tropa gratuitamente.
- [x] Escolha, corpo, feitos, marcas e conversões têm serialização compatível com saves anteriores.
- [ ] Suite completa, portões, vistoria e verificação visual do export Web.

## Investigação usada

O dossiê continua a definir as regras. As fontes externas informaram a apresentação e os controlos:

- [Kingdom Two Crowns — Raw Fury](https://rawfury.com/games/kingdom-two-crowns/): gestão pela coroa e papéis distintos; a escolha comunica a obrigação de voltar ao Monarca para gerir.
- [Godot — navegação de interface](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html): foco inicial e navegação por teclado/comando.
- [Godot — ScrollContainer](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html): foco acompanha a rolagem nas telas menores.
- [Game Accessibility Guidelines — mesma entrada no jogo e na interface](https://gameaccessibilityguidelines.com/ensure-that-all-areas-of-the-user-interface-can-be-accessed-using-the-same-input-method-as-the-gameplay/): escolha utilizável sem exigir rato.

## Testes

`starting_classes_test.gd` foi escrito e executado antes de `Roster.begin`: quatro casos falharam por ausência do método. Os testes de habilidades, combate completo e interface acrescentam alcance, dono, expiração, perfuração, evolução, promoção, compatibilidade e pausa do mundo antes de confirmar. O teste de combate expôs a falta de defesa por criaturas aliadas diante das muralhas; a implementação foi corrigida.
