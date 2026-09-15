# src/core/event_bus.gd — o catalogo fechado da §46, e nada mais.
#
# Sessenta e um sinais DECLARADOS, nao um dicionario de strings: assim ha
# autocompletar, verificacao estatica, e um erro em vez de silencio quando
# alguem escreve unit_dead em vez de unit_died.
#
# Nada em src/sim/ conhece este ficheiro. Os sistemas puros DEVOLVEM pedidos;
# quem os chama e que enfileira. E a convencao de estilo que da de uma so vez
# testes em milissegundos, um save que e so estado, e um multijogador em que so
# os pedidos precisam de ser replicados (§30).
#
# A fila e a regra do §43, passo 11: enfileirar durante o tick, entregar no fim,
# com o estado ja consolidado. Sem ela um ouvinte reage a meio de uma mudanca —
# e aparecem defeitos em que uma tropa morre e ainda ataca no mesmo tick.
#
# Os tipos dos parametros que a tabela da §46 nao da estao escolhidos pela regra
# da Q-056; ids de dados sao StringName, ids de instancia sao int.
extends Node

# ── Relogio — 7 ──────────────────────────────────────────────────────────────
signal day_started(day: int)
signal phase_changed(from: int, to: int)
signal dawn_broke(day: int)
signal dusk_fell(day: int)
signal night_started(day: int)
signal night_survived(day: int, deaths: int, walls_lost: int)
signal game_paused(paused: bool)

# ── Economia — 11 ────────────────────────────────────────────────────────────
signal coin_dropped(x: float, band: int, amount: int, source: StringName)
signal coin_collected(unit_id: int, amount: int)
signal coin_spent(amount: int, purpose: StringName)
signal material_produced(building_id: int, kind: StringName, amount: int)
signal material_consumed(building_id: int, kind: StringName, amount: int)
signal craft_chosen(craft_id: StringName, mode: StringName)
signal capacity_granted(kind: StringName, magnitude: float, duration: float)
signal trade_route_opened(people_id: StringName, income: int)
signal trade_route_closed(people_id: StringName, reason: StringName)
signal seed_royal_gained(amount: int, source: StringName)
signal favor_changed(delta: int, total: int)

# ── Unidades e combate — 14 ──────────────────────────────────────────────────
signal unit_spawned(unit_id: int, data_id: StringName, x: float, band: int)
signal unit_promoted(unit_id: int, from: StringName, to: StringName)
signal unit_state_changed(unit_id: int, from: int, to: int)
signal unit_damaged(unit_id: int, amount: int, from_id: int)
signal unit_died(unit_id: int, x: float, band: int, drops: PackedStringArray)
signal unit_revived(unit_id: int)
signal unit_fled(unit_id: int, reason: StringName)
signal attack_launched(from_id: int, to_id: int, hit: bool)
signal target_marked(target_id: int, by_id: int)
signal contact_slot_taken(wall_id: int, slot: int, unit_id: int)
signal contact_slot_freed(wall_id: int, slot: int)
signal weapon_dropped(x: float, band: int, tier: int)
signal mercenary_hired(unit_id: int, price: int, debt: int)
signal loyalty_changed(unit_id: int, value: float)

# ── A Podridao — 8 ───────────────────────────────────────────────────────────
signal rot_spawned(x: float, width: float, mass: float, side: int)
signal rot_moved(x: float, width: float)
signal rot_summoned(creature_id: StringName, x: float, mass_spent: float)
signal rot_slowed(factor: float, cause: StringName)
signal rot_fed(mass_removed: float, offering: StringName)
signal rot_trail_left(from_x: float, to_x: float)
signal rot_retreated(day: int)
signal creature_died(creature_id: int, x: float, band: int)

# ── Mundo e construcao — 12 ──────────────────────────────────────────────────
signal region_generated(seed: int, segments: int)
signal segment_entered(segment_id: StringName, type: StringName)
signal build_started(slot_id: int, building_id: StringName)
signal build_progressed(slot_id: int, ratio: float)
signal build_completed(building_id: int)
signal building_damaged(building_id: int, ratio: float)
signal building_destroyed(building_id: int, x: float)
signal wall_upgraded(wall_id: int, level: int)
signal wall_breached(wall_id: int)
signal cavity_revealed(cavity_id: int)
signal passage_used(unit_id: int, from_band: int, to_band: int)
signal secret_found(secret_id: StringName)

# ── Coroa e imperios — 9 ─────────────────────────────────────────────────────
signal king_action_chosen(kingdom_id: int, action: StringName)
signal greed_changed(kingdom_id: int, value: int)
signal royal_impulse_used(impulse_id: StringName)
signal king_died(kingdom_id: int, heir_id: int)
signal succession_started(heir_id: int)
signal fortress_conquered(fortress_id: int, people_id: StringName)
signal people_assimilated(people_id: StringName)
signal debt_incurred(amount: int, due_day: int)
signal debt_defaulted(amount: int)

## Historia para depuracao: ~20 s a 30 Hz (§47). Nao se afina em playtest.
## Vem depois dos sinais porque o gdlint exige esta ordem no ambito global.
const EVENT_LOG_SIZE := 600

var _fila: Array[Array] = []
var _log: Array[Array] = []


## Enfileira um evento. NAO o emite: a entrega e no flush (§43, passo 11).
## Um nome fora do catalogo chumba aqui, alto, e nao em silencio tres sistemas
## a frente — e a razao de a lista da §46 ser fechada.
func queue(nome: StringName, args: Array = []) -> void:
	assert(has_signal(nome), "sinal fora do catalogo da §46: %s" % nome)
	_fila.append([nome, args])


## Entrega tudo o que o tick enfileirou, pela ordem de chegada.
## Um ouvinte que enfileire durante a entrega e servido no tick seguinte, nao
## neste: a fila e trocada antes de se emitir seja o que for.
func flush() -> void:
	var a_entregar := _fila
	_fila = []
	for evento in a_entregar:
		_gravar(evento)
		var chamada: Array = [evento[0]]
		chamada.append_array(evento[1])
		callv(&"emit_signal", chamada)


## Os ultimos EVENT_LOG_SIZE eventos entregues — vinte segundos de historia de
## qualquer defeito, sem ligar nada.
func history() -> Array[Array]:
	return _log.duplicate()


## Quantos eventos esperam entrega. Um numero que nao volta a zero todos os
## ticks quer dizer que alguem se esqueceu do passo 11.
func pending() -> int:
	return _fila.size()


## So para os testes e para o arranque: esquece fila e historia.
func reset() -> void:
	_fila = []
	_log = []


func _gravar(evento: Array) -> void:
	_log.append(evento)
	if _log.size() > EVENT_LOG_SIZE:
		_log.pop_front()
