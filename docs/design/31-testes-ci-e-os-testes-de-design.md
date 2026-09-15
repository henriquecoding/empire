# 31 — Testes · novo · Testes, CI e os testes de design

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Sem testes automáticos não consegues rever o que a IA escreve, e vais deixar de tentar ao fim de duas semanas. Com testes, podes aceitar 400 linhas sem as ler linha a linha — porque sabes o que elas têm de fazer.

> **Revisto na Parte XIII**
>
> Os catorze testes que guardam os sistemas da Parte XIII estão na §84 e vivem em tests/design_unknown_test.gd.

## Três níveis

**Unitário — src/sim/** — Rápido, sem editor, cobertura alta. Toda a função pública. É aqui que vive 80% da suite.

Uma noite completa em modo headless com delta fixo. Verifica que o muro aguenta e que ninguém fica preso.

Afirmações sobre intervalos-alvo de balanceamento. Falham quando o jogo deixa de estar afinado, não quando o código parte.

### Os testes de design a escrever primeiro

```gdscript
# tests/design_targets_test.gd
extends GdUnitTestSuite

func test_dia_de_asfixia_no_intervalo() -> void:
    var eco := Economy.new(load("res://data/economy/curve.tres"))
    var d := eco.suffocation_day(EconomyProfile.BALANCED)
    assert_int(d).is_between(9, 14)

func test_noite_1_e_sempre_ganha() -> void:
    var r := SimHarness.run_night(1, {&"archers": 2, &"wall": 1})
    assert_bool(r.wall_survived).is_true()
    assert_int(r.deaths).is_less_equal(0)

func test_noite_8_sem_torre_e_sempre_perdida() -> void:
    var r := SimHarness.run_night(8, {&"archers": 6, &"wall": 2, &"towers": 0})
    assert_bool(r.wall_survived).is_false()

func test_arqueiros_nao_param_ariete() -> void:
    var ttk := Combat.ttk("archer_open", "slime_ram")
    assert_float(ttk).is_greater(105.0)   # mais do que uma noite inteira

func test_sim_nao_toca_em_nos() -> void:
    for f in FileScan.gd_files("res://src/sim/"):
        var src := FileAccess.get_file_as_string(f)
        assert_bool(src.contains("extends Node")).is_false()
        assert_bool(src.contains("get_tree()")).is_false()
```

## Os cinco portões estão na §64

Estes três níveis são a estrutura. Os cinco portões de CI que a fazem cumprir — incluindo o teste de reprodutibilidade por seed, que apanha o que nenhum dos outros apanha — estão especificados na §64.

> **O último teste é o guarda-costas da arquitetura**
>
> Um agente que não leu bem o CLAUDE.md vai, mais cedo ou mais tarde, pôr um extends Node em src/sim/. Esse teste apanha-o em segundos, sem tu leres nada. São vinte linhas de código que protegem a decisão mais importante do projeto durante dois anos.

### CI em GitHub Actions

```gdscript
# .github/workflows/test.yml
name: testes
on: [push, pull_request]
jobs:
  gdunit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { lfs: true }
      - uses: godot-gdunit-labs/gdUnit4-action@v1
        with:
          godot-version: '4.6'
          paths: 'res://tests'
          timeout: 8
          report-name: relatorio.xml
```

Oito minutos de limite. Se a suite passar disso, é porque estás a testar cenas onde devias testar lógica pura — o sinal de que a fronteira de src/sim/ foi violada.
