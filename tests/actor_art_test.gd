# tests/actor_art_test.gd — a cara de quem esta ferido (§24; GB-20).
#
# O HUD diegetico do §24: "Vida de tropa — camada face muda para ferido abaixo
# de 50% — no sprite". O corpo tinha uma cara e ela nunca mudava.
extends GdUnitTestSuite


## O limiar e o do dossie, e nao outro.
func test_o_limiar_e_metade_da_vida() -> void:
	assert_float(ActorArt.FERIDA.limiar).is_equal(0.5)


func test_abaixo_de_metade_esta_ferido_e_a_metade_ainda_nao() -> void:
	assert_bool(ActorArt.wounded(49, 100)).is_true()
	assert_bool(ActorArt.wounded(50, 100)).is_false()
	assert_bool(ActorArt.wounded(100, 100)).is_false()


## Um corpo sem vida maxima (um dado por preencher) nao se desenha ferido: dizer
## que esta mal quem nao se sabe como esta era mentir no sprite.
func test_sem_vida_maxima_nao_ha_ferida() -> void:
	assert_bool(ActorArt.wounded(0, 0)).is_false()
