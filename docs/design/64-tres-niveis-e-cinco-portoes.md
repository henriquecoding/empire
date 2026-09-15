# 64 — Testes · Três níveis e cinco portões

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Sem testes automáticos não consegues rever o que a IA escreve, e vais deixar de tentar ao fim de duas semanas. Com testes, podes aceitar 400 linhas sem as ler linha a linha — porque sabes o que elas têm de fazer.

**Unitário — src/sim/** — Rápido, sem editor, cobertura alta. Toda a função pública. 80% da suite vive aqui, e corre em menos de dois segundos.

Uma noite completa em headless com delta fixo. Verifica que o muro aguenta e que ninguém fica preso.

Afirmações sobre intervalos-alvo de balanceamento. Falham quando o jogo deixa de estar afinado, não quando o código parte.

## Os cinco portões de CI

| # | Portão | Defende | Custo |
| --- | --- | --- | --- |
| G1 | test_sim_nao_toca_em_nos | Invariante I1 — a decisão mais importante do projeto | 20 linhas |
| G2 | Lint de RNG: sem randi/randf/randomize fora de RngService | I2 — a promessa da seed | 10 linhas |
| G3 | test_eventos_no_catalogo: nenhum sinal emitido fora do §46 | I7 — impede a proliferação de sinais quase iguais | 15 linhas |
| G4 | test_sem_literais_de_balanceamento | I4 — números fora dos .tres | 30 linhas |
| G5 | Testes de design no intervalo | O jogo continuar afinado | Ver abaixo |


Os testes de design propriamente ditos — dia de asfixia, noite 1 sempre ganha, noite 8 sem torre sempre perdida, arqueiros não param aríetes — estão escritos na §31 e não se repetem aqui. O que a §31 não tinha são os cinco portões acima e o teste que se segue.

```gdscript
# tests/determinism_test.gd — o que apanha o que os outros não apanham
func test_seed_reproduz() -> void:
    var a := SimHarness.run_days(10, 12345)
    var b := SimHarness.run_days(10, 12345)
    assert_str(a.checksum()).is_equal(b.checksum())
```

> **O último é o que apanha tudo o resto**
>
> test_seed_reproduz corre dez dias duas vezes e compara uma soma de controlo do estado final. Se um agente introduzir um randf() solto, uma iteração de dicionário, ou uma ordem de resolução dependente de posição de memória, este teste falha — mesmo que os quatro portões anteriores passem. É o teste mais barato de escrever e o que mais bugs impossíveis te vai poupar.
