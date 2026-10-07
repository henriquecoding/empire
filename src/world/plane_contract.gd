# src/world/plane_contract.gd — o contrato dos planos de profundidade (§6.3 e §40 do plano
# de cenarios de 07/10/2026; ADR 0078).
#
# Le uma cena sem a instanciar (SceneState) e diz: que planos Parallax2D tem, por ordem de
# desenho e com o fator de cada um; e se um no esta dentro de algum. O contrato que o
# planos_test guarda: de tras para a frente cada plano anda mais depressa, nenhum chega ao
# 1 do mundo funcional, e nada de jogo — a superficie, o subsolo, o combate, o chao —
# desliza: a porta, o preco e a colisao ficam onde a simulacao os poe.
class_name PlaneContract
extends RefCounted

const NAME := &"name"
const SCROLL := &"scroll"
const PARALLAX := &"Parallax2D"
## As camadas de jogo da game.tscn e o chao da cena do cenario.
const GAMEPLAY := [
	"Mundo/Aereo",
	"Mundo/Subsolo",
	"Mundo/Terra",
	"Mundo/Superficie",
	"Mundo/Impactos",
	"Mundo/Combate",
	"Mundo/Batalha",
]
const GROUND := ["PathAndSoil", "Field", "RootCellars"]


## Os planos Parallax2D da cena, pela ordem da arvore: nome e scroll_scale.x.
static func planes(cena: PackedScene) -> Array[Dictionary]:
	var planos: Array[Dictionary] = []
	var estado := cena.get_state()
	for i in estado.get_node_count():
		if estado.get_node_type(i) != PARALLAX:
			continue
		var escala := Vector2.ONE
		for p in estado.get_node_property_count(i):
			if estado.get_node_property_name(i, p) == &"scroll_scale":
				escala = estado.get_node_property_value(i, p)
		planos.append({NAME: estado.get_node_name(i), SCROLL: escala.x})
	return planos


## Se o no `caminho` (relativo a raiz) existe e tem um Parallax2D acima dele; um no que nao
## existe tambem responde que sim, para o teste nao passar por engano.
static func in_parallax(cena: PackedScene, caminho: String) -> bool:
	var estado := cena.get_state()
	var tipos := {}
	var achou := false
	for i in estado.get_node_count():
		var onde := String(estado.get_node_path(i)).trim_prefix("./").trim_prefix(".")
		tipos[onde] = estado.get_node_type(i)
		achou = achou or onde == caminho
	if not achou:
		return true
	var partes := caminho.split("/")
	for n in range(1, partes.size()):
		if tipos.get("/".join(partes.slice(0, n)), &"") == PARALLAX:
			return true
	return false
