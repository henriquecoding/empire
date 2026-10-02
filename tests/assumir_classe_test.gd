# tests/assumir_classe_test.gd — trocar de classe (§08, §24; Q-150, Q-162, Q-178).
#
# O §08: "Trocar de classe e o Verbo 2 sobre uma tropa da classe correspondente. O
# personagem largado passa a IA com o comportamento normal daquela classe." E o dono
# (Q-162, 30/09/2026): "as classes jogaveis sao maiores do que as tropas". O Verbo 2 do
# rei ao pe de uma tropa tua de uma classe desbloqueada faz dela o corpo jogavel (na
# escala 3), e e esse que passas a conduzir; o Verbo 2 desse corpo ao pe do rei volta
# ao rei. Quem o jogador nao conduz deixa de ser `pilot`, e os sistemas de IA voltam
# a trata-lo como a tropa que e.
extends GdUnitTestSuite

const MEU := 1
const PERTO := 40.0
const ALCANCE := 120.0

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


## O Verbo 2 do rei ao pe de um arqueiro teu: o arqueiro passa ao corpo jogavel, com a
## vida na mesma proporcao, e e ele que o jogador conduz.
func test_a_tropa_passa_a_corpo_jogavel_e_e_conduzida() -> void:
	var u := UnitSystem.new()
	var rei := _tropa(u, &"monarch", 100.0)
	var arqueiro := _tropa(u, &"archer", 100.0 + PERTO)
	u.healths[u.index_of(arqueiro)] = 7
	var r := _roster()
	var quem := r.take(u, rei, ALCANCE, r.unlocked(PackedStringArray(), {}))
	assert_int(quem).is_equal(arqueiro)
	var i := u.index_of(arqueiro)
	assert_str(String(u.data_ids[i])).is_equal("archer_hero")
	var corpo := Registry.entry(&"units", &"archer_hero") as UnitData
	assert_int(u.max_healths[i]).is_equal(corpo.max_health)
	assert_int(u.healths[i]).is_equal(roundi(7.0 * corpo.max_health / 14.0))
	assert_int(u.pilot).is_equal(arqueiro)
	assert_int(r.driven(u, rei)).is_equal(arqueiro)


## Longe, de outro dono, ou de uma classe sem tropa: nao se assume ninguem.
func test_so_se_assume_quem_esta_perto_e_e_teu() -> void:
	var u := UnitSystem.new()
	var rei := _tropa(u, &"monarch", 100.0)
	_tropa(u, &"archer", 100.0 + ALCANCE * 2.0)
	_tropa(u, &"archer", 100.0 + PERTO, RecruitSystem.SEM_DONO)
	_tropa(u, &"spearman", 100.0 + PERTO)
	var r := _roster()
	assert_int(r.take(u, rei, ALCANCE, r.unlocked(PackedStringArray(), {}))).is_equal(Roster.NENHUM)
	assert_int(u.pilot).is_equal(Roster.NENHUM)


## Um corpo por classe: com o Arqueiro vivo, outro arqueiro nao passa a corpo — mas o
## Arqueiro que ja existe assume-se.
func test_um_corpo_por_classe() -> void:
	var u := UnitSystem.new()
	var rei := _tropa(u, &"monarch", 100.0)
	var primeiro := _tropa(u, &"archer", 100.0 + PERTO)
	var r := _roster()
	var todas := r.unlocked(PackedStringArray(), {})
	r.take(u, rei, ALCANCE, todas)
	assert_bool(r.back(u, rei, ALCANCE)).is_true()
	var segundo := _tropa(u, &"archer", 100.0 - PERTO * 0.5)
	assert_int(r.take(u, rei, ALCANCE, todas)).is_equal(primeiro)
	assert_str(String(u.data_ids[u.index_of(segundo)])).is_equal("archer")


## Voltar ao rei: o Verbo 2 do corpo ao pe dele. Longe, nao volta.
func test_volta_se_ao_rei_ao_pe_dele() -> void:
	var u := UnitSystem.new()
	var rei := _tropa(u, &"monarch", 100.0)
	var arqueiro := _tropa(u, &"archer", 100.0 + PERTO)
	var r := _roster()
	r.take(u, rei, ALCANCE, r.unlocked(PackedStringArray(), {}))
	u.xs[u.index_of(arqueiro)] = 100.0 + ALCANCE * 3.0
	assert_bool(r.back(u, rei, ALCANCE)).is_false()
	u.xs[u.index_of(arqueiro)] = 100.0 + PERTO
	assert_bool(r.back(u, rei, ALCANCE)).is_true()
	assert_int(u.pilot).is_equal(Roster.NENHUM)
	assert_int(r.driven(u, rei)).is_equal(rei)


## Morto o corpo conduzido, conduz-se o rei outra vez (§16: "podes assumir outro").
func test_morto_o_corpo_volta_se_ao_rei() -> void:
	var u := UnitSystem.new()
	var rei := _tropa(u, &"monarch", 100.0)
	var arqueiro := _tropa(u, &"archer", 100.0 + PERTO)
	var r := _roster()
	r.take(u, rei, ALCANCE, r.unlocked(PackedStringArray(), {}))
	u.states[u.index_of(arqueiro)] = UnitFsm.State.DEAD
	assert_int(r.driven(u, rei)).is_equal(rei)
	r.forget_dead(u)
	assert_int(u.pilot).is_equal(Roster.NENHUM)


## Uma classe que nao tem tropa (o Trepador, os cavaleiros) chega ao nucleo na
## alvorada a seguir a conquista do povo dela (§13: "um novo personagem controlavel"),
## uma vez so.
func test_a_classe_sem_tropa_chega_na_alvorada_da_conquista() -> void:
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
	var outra := r.arrive(u, estado, rei, 500.0, PackedStringArray(["portuarios"]), povos)
	assert_array(outra).is_empty()


## Cada corpo tem o seu armazenamento (Q-153), e o save guarda-o com quem chegou.
func test_o_save_guarda_os_armazenamentos_e_quem_chegou() -> void:
	var u := UnitSystem.new()
	var rei := _tropa(u, &"monarch", 100.0)
	var arqueiro := _tropa(u, &"archer", 100.0 + PERTO)
	var r := _roster()
	r.take(u, rei, ALCANCE, r.unlocked(PackedStringArray(), {}))
	var aljava := r.storage_of(u, arqueiro)
	assert_str(String(aljava.kind)).is_equal("quiver")
	aljava.put(Storage.ARCHOTE, 1)
	r.arrived.append("climber")
	var copia := _roster()
	copia.from_dict(r.to_dict())
	assert_int(copia.storage_of(u, arqueiro).count(Storage.ARCHOTE)).is_equal(1)
	assert_bool(copia.arrived.has("climber")).is_true()
