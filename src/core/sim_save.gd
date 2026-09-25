# src/core/sim_save.gd — as coleccoes da §45 em tipos base, e de volta.
#
# O §45 lista o que e estado autoritativo: units, creatures, coins_on_ground,
# buildings, rot. Cada um deles sabe converter-se — e este ficheiro e a lista de
# QUAIS entram no save, que e a unica coisa que nenhum deles pode saber.
#
# Vive em src/core/ e nao em src/sim/ por uma razao so: junta sistemas que nao
# se conhecem uns aos outros, e a §70 nao lhes deixa conhecer. O SimLoop guarda
# a ordem dos onze passos (ADR 0020) e nao tambem a forma do ficheiro de save.
#
# O que NAO entra, e nao e esquecimento: a escada de uma obra, a largura dela e
# os efeitos sao AUTORADOS pelo segmento (§21) e voltam a existir quando ele
# volta a ser montado. Grava-los era guardar o mundo dentro do save, e um mundo
# que muda de versao deixava de poder ser carregado (§62).
class_name SimSave
extends RefCounted

const UNIDADES := &"units"
const CRIATURAS := &"creatures"
const MOEDAS := &"coins"
const OBRAS := &"builds"
const PODRIDAO := &"rot"
const REI := &"king_id"
const CAMPO := &"amargueiros"
const OFERTAS := &"offers"
const NOMES := &"names"
const COLHEITA := &"harvest"


static func world(
	unidades: UnitSystem,
	bichos: CreatureSystem,
	moedas: CoinSystem,
	obras: BuildSystem,
	noite: NightWatch,
	king_id: int
) -> Dictionary:
	return {
		UNIDADES: unidades.to_dict(),
		CRIATURAS: bichos.to_dict(),
		MOEDAS: moedas.to_dict(),
		OBRAS: obras.to_dict(),
		PODRIDAO: noite.rot.to_dict(),
		CAMPO: noite.trees.to_dict(),
		OFERTAS: noite.offers.to_dict(),
		NOMES: noite.names.to_dict(),
		COLHEITA: noite.harvest.to_dict(),
		REI: king_id,
	}


## Repoe e devolve o king_id guardado. Uma coleccao em falta fica como estava —
## um save de outra versao degrada em vez de recusar (§62).
static func restore(
	unidades: UnitSystem,
	bichos: CreatureSystem,
	moedas: CoinSystem,
	obras: BuildSystem,
	noite: NightWatch,
	mundo: Dictionary
) -> int:
	unidades.from_dict(mundo.get(UNIDADES, {}))
	bichos.from_dict(mundo.get(CRIATURAS, {}))
	moedas.from_dict(mundo.get(MOEDAS, {}))
	obras.from_dict(mundo.get(OBRAS, []))
	noite.rot.from_dict(mundo.get(PODRIDAO, {}))
	noite.trees.from_dict(mundo.get(CAMPO, {}))
	noite.offers.from_dict(mundo.get(OFERTAS, {}))
	noite.names.from_dict(mundo.get(NOMES, {}))
	noite.harvest.from_dict(mundo.get(COLHEITA, {}))
	return mundo.get(REI, UnitSystem.NENHUM)
