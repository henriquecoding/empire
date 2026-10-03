# src/sim/data/monarch_data.gd — ADR 0052. Gerado de data/source/monarchs.csv.
# Um monarca reune corpo, combate, autoridade da coroa e um companheiro proprio:
# a escolha inicial e de monarca, e nao de classe (§08).
class_name MonarchData
extends Resource

@export var id: StringName
@export var display_key: String
## O nome de quem herda a coroa deste monarca: identidade propria (§15, Q-202).
@export var heir_key: String
## A ordem na escolha inicial.
@export var order: int = 0
## O corpo (units.csv). O `monarch` continua a ser o Rei.
@export var unit: StringName
## A classe das fases e dos feitos (classes.csv): o Rei evolui pelo ClassSystem, a Nia
## pelo Bardo e o Arqueiro pelo Arqueiro (HeroProgress).
@export var skill_class: StringName
## A habilidade do botao direito: vigil | song | mark.
@export var skill: StringName
## A chave do nome do ataque no painel de combate.
@export var attack_key: String
## O companheiro vinculado (units.csv) e o servico que vende: shield | song | arrows.
@export var companion: StringName
@export var service: StringName
