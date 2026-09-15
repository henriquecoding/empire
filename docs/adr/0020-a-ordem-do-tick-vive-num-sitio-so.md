# ADR 0020 — A ordem do §43 vive num sítio só: o `SimLoop`

- Estado: aceite
- Data: 2026-09-15
- Secção do dossiê: §43, §41, §46, §62
- Revê: ADR 0006

## Contexto

A ADR 0006 pôs o `_physics_process` dentro do `ClockService`, e para um relógio
sozinho isso chegava. O §43 fixa **onze passos por tick, por ordem escrita**, e
o passo 11 — `EventBus.flush()` — tem de correr depois de todo o estado do tick
estar consolidado: *"sem esta regra, um ouvinte reage a um estado a meio de
mudar, e apanhas bugs em que uma tropa morre e ainda ataca no mesmo tick."*

Com cada sistema a conduzir-se a si próprio no seu `_physics_process`, a ordem
dos onze passos passa a ser a **ordem de declaração dos *autoloads* no
`project.godot`**. É implícita, não se vê em lado nenhum, e o §43 diz
exatamente o que lhe acontece: *"uma ordem implícita é uma ordem que muda
sozinha quando um agente reorganiza um ficheiro."*

Reorganizar a lista de *autoloads* — uma coisa que parece inofensiva — mudava a
ordem da simulação sem um único teste a chumbar.

## Decisão

`src/core/sim_loop.gd` é o **único `_physics_process` da simulação**. Corre os
onze passos do §43 pela ordem escrita, com os que ainda não existem presentes
como comentário e o ticket que os preenche, e termina sempre em
`EventBus.flush()`.

O `ClockService` deixa de ter `_physics_process` e passa a expor `step(delta)`.
Continua a valer tudo o resto da ADR 0006: o relógio é puro, o serviço não tem
lógica, e traduz o que o `tick()` devolve em sinais do §46.

O `SimLoop` é também dono do `GameState` em execução e de o espelhar a partir
do relógio, e faz o *autosave* no DAWN de cada dia (§62).

## Alternativas consideradas

**Manter cada sistema a conduzir-se e pôr o `flush` num *autoload* declarado por
último.** Funciona, e é precisamente o defeito que esta ADR evita: a correção
fica a depender de uma ordem que ninguém vê ao ler o código.

**Um nó de cena em vez de um *autoload*.** Obriga a cena de jogo a existir para a
simulação andar, e a Fase 0 ainda não tem cena de jogo (ADR 0005).

## Consequências

- O `AGENTS.md` ganha `src/core/sim_loop.gd` na tabela de caminhos canónicos.
- Os passos 2 a 10 estão escritos e vazios, cada um com o ticket que o preenche.
  Um passo que falte é uma linha que falta, não um sistema que ninguém chama.
- O `SimLoop` é declarado depois de todos os outros *autoloads*, mas isso deixou
  de importar: já não há dois sítios a competir pela mesma ordem.
