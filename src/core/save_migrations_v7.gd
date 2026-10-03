# src/core/save_migrations_v7.gd — o passo da versao 6 para a 7: os monarcas jogaveis
# (ADR 0052, UN-06; o dono a 02/10/2026: "somente imperadores sao controlaveis").
#
# "Atualizacoes novas retiram controle de tropa, mas preservam a campanha e suas pessoas"
# (plano §19.2). Quem comecou como Arqueiro ou Bardo tinha um rei oficial ao lado: o
# perfil e o Rei, o corpo de classe fica no mundo sob IA com a vida e o que levava, e o
# controlo volta ao rei. O escudeiro identifica-se uma vez pelo caminho antigo — do reino
# do rei, vivo, o de id mais baixo — e passa a vinculo; sem ele vivo, nao nasce nenhum.
# Nada se inventa: nenhuma flecha, cura ou personagem.
class_name SaveMigrationsV7
extends RefCounted

const NINGUEM := -1
const ESCUDEIRO := &"squire"


static func apply(d: Dictionary) -> void:
	var mundo := _dict(d, &"world")
	if mundo.is_empty():
		return
	mundo[&"pilot"] = NINGUEM  # so imperadores se jogam: conduz-se o rei
	var roster := _dict(mundo, &"roster")
	roster.erase(&"starting_class")
	mundo[&"roster"] = roster
	if not mundo.has(&"monarchy"):
		var rei := int(mundo.get(&"king_id", NINGUEM))
		var escudeiro := _escudeiro(_dict(mundo, &"units"), rei)
		var vinculos := {rei: escudeiro} if escudeiro != NINGUEM else {}
		mundo[&"monarchy"] = {&"profile": Monarchy.REI, &"generation": 0, &"bonds": vinculos}
	if not mundo.has(&"bleeding"):
		mundo[&"bleeding"] = {}
	d[&"world"] = mundo


## O escudeiro vivo do reino do rei, o de id mais baixo, ou NINGUEM.
static func _escudeiro(unidades: Dictionary, rei: int) -> int:
	var ids: Variant = unidades.get(&"ids", PackedInt32Array())
	var dados: Variant = unidades.get(&"data_ids", [])
	var donos: Variant = unidades.get(&"owners", PackedInt32Array())
	var estados: Variant = unidades.get(&"states", PackedByteArray())
	var n := mini(_tamanho(ids), mini(_tamanho(dados), _tamanho(donos)))
	var r := -1
	for i in n:
		if int(ids[i]) == rei:
			r = i
	if r < 0:
		return NINGUEM
	var melhor := NINGUEM
	for i in n:
		if StringName(dados[i]) != ESCUDEIRO or int(donos[i]) != int(donos[r]):
			continue
		if i < _tamanho(estados) and int(estados[i]) == UnitFsm.State.DEAD:
			continue
		if melhor == NINGUEM or int(ids[i]) < melhor:
			melhor = int(ids[i])
	return melhor


## O save real guarda os data_ids como PackedStringArray (Columns._base); os testes
## antigos, como Array. As duas formas contam.
static func _tamanho(valor: Variant) -> int:
	if valor is Array or valor is PackedStringArray:
		return valor.size()
	if valor is PackedInt32Array or valor is PackedByteArray:
		return valor.size()
	return 0


static func _dict(d: Dictionary, chave: StringName) -> Dictionary:
	var valor: Variant = d.get(chave, {})
	return valor if valor is Dictionary else {}
