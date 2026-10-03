# tests/assumir_classe_test.gd — o que ficou do Roster depois da ADR 0052 (§08, §13; Q-153).
#
# Ate 02/10/2026 o Verbo 2 do rei ao pe de uma tropa de classe fazia dela o corpo jogavel.
# O dono: "somente imperadores sao controlaveis [...] tropas, oficios, diplomatas e
# companheiros permanecem sob IA". O Roster ja nao assume ninguem: diz que classes o reino
# conhece, faz chegar o corpo de cada classe sem tropa na alvorada da conquista — sob IA —
# e guarda o armazenamento de cada corpo.
extends GdUnitTestSuite

const MEU := 1
const PERTO := 40.0

var _estado := GameState.new()


func before_test() -> void:
	_estado = GameState.new()


func _roster() -> Roster:
	return Roster.new(
		SimFactory.by_id(&"classes"),
		SimFactory.by_id(&"units"),
		SimFactory.by_id(&"classes/storages")
	)


func _tropa(u: UnitSystem, id: StringName, x: float, dono := MEU) -> int:
	return u.spawn(_estado, Registry.entry(&"units", id) as UnitData, dono, x)


## As classes de inicio contam sempre; as outras, so com o povo delas conquistado (§13).
func test_as_classes_de_inicio_e_as_dos_povos_conquistados() -> void:
	var r := _roster()
	var sem := r.unlocked(PackedStringArray(), {&"fornalha": &"buried_knight"})
	assert_bool(sem.has(&"archer")).is_true()
	assert_bool(sem.has(&"monarch")).is_true()
	assert_bool(sem.has(&"buried_knight")).is_false()
	var com := r.unlocked(PackedStringArray(["fornalha"]), {&"fornalha": &"buried_knight"})
	assert_bool(com.has(&"buried_knight")).is_true()


## ADR 0052 (T03 do plano): o Roster ja nao tem com que assumir uma tropa.
func test_o_roster_nao_assume_ninguem() -> void:
	var r := _roster()
	assert_bool(r.has_method(&"take")).is_false()
	assert_bool(r.has_method(&"back")).is_false()
	assert_bool(r.has_method(&"begin")).is_false()


## Sem corpo conduzido, conduz-se o rei; e se o da troca (UN-17) morrer, volta-se ao rei.
func test_morto_o_corpo_conduzido_volta_se_ao_rei() -> void:
	var u := UnitSystem.new()
	var rei := _tropa(u, &"monarch", 100.0)
	var outro := _tropa(u, &"archer_emperor", 100.0 + PERTO)
	var r := _roster()
	assert_int(r.driven(u, rei)).is_equal(rei)
	u.pilot = outro
	u.states[u.index_of(outro)] = UnitFsm.State.DEAD
	assert_int(r.driven(u, rei)).is_equal(rei)
	r.forget_dead(u)
	assert_int(u.pilot).is_equal(Roster.NENHUM)


## Uma classe que nao tem tropa (o Trepador, os cavaleiros) chega ao nucleo na alvorada a
## seguir a conquista do povo dela, uma vez so — e passa a IA: nao se assume.
func test_a_classe_sem_tropa_chega_na_alvorada_da_conquista_e_nao_e_conduzida() -> void:
	var u := UnitSystem.new()
	var estado := GameState.new()
	var rei := u.spawn(estado, Registry.entry(&"units", &"monarch") as UnitData, MEU, 0.0)
	var r := _roster()
	var povos := {&"portuarios": &"climber"}
	var chegaram := r.arrive(u, estado, rei, 500.0, PackedStringArray(["portuarios"]), povos)
	assert_int(chegaram.size()).is_equal(1)
	var i := u.index_of(chegaram[0])
	assert_str(String(u.data_ids[i])).is_equal("climber")
	assert_int(u.owners[i]).is_equal(MEU)
	assert_int(r.driven(u, rei)).is_equal(rei)
	var outra := r.arrive(u, estado, rei, 500.0, PackedStringArray(["portuarios"]), povos)
	assert_array(outra).is_empty()


## Cada corpo tem o seu armazenamento (Q-153), e o save guarda-o com quem chegou. A escolha
## inicial antiga ja nao vive aqui: e do Monarchy (ADR 0052).
func test_o_save_guarda_os_armazenamentos_e_quem_chegou() -> void:
	var u := UnitSystem.new()
	var arqueiro := _tropa(u, &"archer_hero", 100.0 + PERTO)
	var r := _roster()
	var aljava := r.storage_of(u, arqueiro)
	assert_str(String(aljava.kind)).is_equal("quiver")
	aljava.put(Storage.ARCHOTE, 1)
	r.arrived.append("climber")
	var copia := _roster()
	copia.from_dict(r.to_dict())
	assert_int(copia.storage_of(u, arqueiro).count(Storage.ARCHOTE)).is_equal(1)
	assert_bool(copia.arrived.has("climber")).is_true()
	assert_bool(r.to_dict().has(&"starting_class")).is_false()
