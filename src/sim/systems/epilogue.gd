# src/sim/systems/epilogue.gd — qual dos tres finais, por precedencia (§79).
#
# A ADR 0018 escreve a ordem e este ficheiro e o unico sitio onde ela existe:
# avalia-se de cima para baixo e para na primeira que bater. Os quatro limiares
# vem do rot.csv. Puro: recebe a Divida e as decisoes da Colheita (§78) e diz o
# final — quem o conta e quando e do XIII-08, quando houver capitulos.
class_name Epilogue
extends RefCounted

const DOMINIO := &"dominion"
const UNIAO := &"union"
const TURNO := &"shift"


## 1 · Divida no limiar → Dominio, mesmo com os seis soltos. 2 · povos ficados
## no limiar → Dominio. 3 · Divida baixa e povos soltos → Uniao. 4 · O Turno.
static func of(debt: int, kept: int, released: int, perfil: RotProfile) -> StringName:
	if debt >= perfil.dominion_debt_min:
		return DOMINIO
	if kept >= perfil.dominion_peoples_kept:
		return DOMINIO
	if debt <= perfil.union_debt_max and released >= perfil.union_peoples_released:
		return UNIAO
	return TURNO
