# tests/dawn_cascade_test.gd — as tropas saem dos postos atras da luz (§24; GB-21, Q-089).
#
# "Amanhecer — sino + varrimento de luz da esquerda para a direita a 900 px/s +
# as tropas a sairem dos postos em cascata, nao todas ao mesmo tempo." O passo 3
# do §43 dava o alvo do dia a toda a gente no mesmo tick, e toda a gente
# arrancava junta. A cascata segue a frente da luz: quem esta a direita dela
# espera que ela chegue.
extends GdUnitTestSuite

const DAWN := GameClock.Phase.DAWN

## Um so GameState por teste: e dele que saem os ids (§45), e dois estados
## novos davam o mesmo id a duas tropas.
var _estado: GameState


func _relogio() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


## O numero e o do §24, e vive no clock.csv: a luz que se ve (DawnSweep) e a que
## solta as tropas sao a mesma frente.
func test_a_frente_anda_aos_900_px_s_do_24() -> void:
	assert_float(_relogio().dawn_sweep_px_s).is_equal(900.0)
	assert_float(DawnCascade.front(DAWN, 2.0, 900.0)).is_equal(1800.0)


## Fora da alvorada nao ha frente: ninguem fica retido.
func test_fora_da_alvorada_ninguem_espera() -> void:
	assert_float(DawnCascade.front(GameClock.Phase.MORNING, 20.0, 900.0)).is_equal(INF)
	assert_float(DawnCascade.front(DAWN, 1.0, 0.0)).is_equal(INF)


func before_test() -> void:
	_estado = GameState.new()


func _tropa_com_posto(sistema: UnitSystem, x: float, alvo: float) -> int:
	var unit_id := sistema.spawn(_estado, Registry.entry(&"units", &"archer"), 1, x)
	sistema.job_ids[sistema.index_of(unit_id)] = 7
	sistema.set_target_x(unit_id, alvo)
	return unit_id


## Quem tem posto e esta a direita da frente fica; quem a luz ja apanhou sai.
func test_quem_a_luz_ainda_nao_apanhou_espera() -> void:
	var sistema := UnitSystem.new()
	var perto := _tropa_com_posto(sistema, 500.0, 900.0)
	var longe := _tropa_com_posto(sistema, 3000.0, 3400.0)
	sistema.tick_movement(1.0 / 30.0, UnitSystem.NENHUM, 1000.0)
	assert_float(sistema.xs[sistema.index_of(perto)]).is_greater(500.0)
	assert_float(sistema.xs[sistema.index_of(longe)]).is_equal(3000.0)


## So espera quem SAI de um posto. Quem segue o rei nao tem posto e anda; quem
## foge nao espera por luz nenhuma (§07); e o rei e de quem o conduz (§24).
func test_so_espera_quem_tem_posto_e_nao_foge() -> void:
	var sistema := UnitSystem.new()
	var sem_posto := sistema.spawn(_estado, Registry.entry(&"units", &"vagrant"), 1, 3000.0)
	sistema.set_target_x(sem_posto, 3100.0)
	var foge := _tropa_com_posto(sistema, 3000.0, 2000.0)
	sistema.states[sistema.index_of(foge)] = UnitFsm.State.FLEE
	var rei := _tropa_com_posto(sistema, 3000.0, 3200.0)
	sistema.tick_movement(1.0 / 30.0, rei, 1000.0)
	assert_float(sistema.xs[sistema.index_of(sem_posto)]).is_greater(3000.0)
	assert_float(sistema.xs[sistema.index_of(foge)]).is_less(3000.0)
	assert_float(sistema.xs[sistema.index_of(rei)]).is_greater(3000.0)


## A frente atravessa a regiao inteira antes de a alvorada acabar: nenhuma tropa
## passa a manha retida por uma luz que ja nao existe.
func test_a_frente_atravessa_a_regiao_dentro_da_alvorada() -> void:
	var dados := _relogio()
	var alvorada := dados.phase_durations[DAWN] * dados.day_seconds_min / dados.day_seconds
	var regiao := 3840.0
	assert_float(regiao / dados.dawn_sweep_px_s).is_less(alvorada)
