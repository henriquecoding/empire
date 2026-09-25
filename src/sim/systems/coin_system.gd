# src/sim/systems/coin_system.gd — a moeda fisica, que e o Verbo 1 (§02, §61).
#
# "Tudo o que o jogador faz passa por ela": recrutar, construir, subir uma
# muralha, alimentar A Podridao. Por isso a moeda nao e um numero num contador —
# e um objeto que sai da mao, faz um arco, cai, fica no chao, e pode ser apanhada
# por outra pessoa antes de ti.
#
# Colunas, como as tropas (Q-060). Uma moeda largada por engano no sitio errado
# tem de continuar la amanha, e um dia haverao centenas no chao.
#
# Puro, e com duas consequencias que se veem na assinatura dos metodos:
#  · a fisica vem de um EconomyCurve entregue no construtor, como o GameClock
#    recebe o ClockData — nao ha um unico numero escrito aqui;
#  · a dispersao do arco vem de FORA, ja sorteada. A simulacao nao pode chamar o
#    RngService (§70), e o portao G2 chumbaria um randf_range aqui dentro.
class_name CoinSystem
extends RefCounted

const NENHUM := -1

## O desvio do arco chega normalizado. Nao e afinacao: e o intervalo do
## parametro, e a dispersao em pixeis vem toda do coin_drop_spread_px_s.
const DESVIO_MAX := 1.0

var ids: PackedInt32Array = PackedInt32Array()
var xs: PackedFloat32Array = PackedFloat32Array()
## Altura acima da linha do solo da FAIXA, em px. Zero e pousada. Ao contrario
## das tropas, uma moeda no ar tem altura propria — nao e derivavel da faixa, e
## por isso e o unico Y que o §45 nao proibe guardar.
var heights: PackedFloat32Array = PackedFloat32Array()
var vxs: PackedFloat32Array = PackedFloat32Array()
var vys: PackedFloat32Array = PackedFloat32Array()
var bands: PackedByteArray = PackedByteArray()
var amounts: PackedInt32Array = PackedInt32Array()
var settled: PackedByteArray = PackedByteArray()

var _curva: EconomyCurve
var _por_id: Dictionary = {}


func _init(curva: EconomyCurve) -> void:
	assert(curva != null, "o CoinSystem precisa de um EconomyCurve")
	_curva = curva


func count() -> int:
	return ids.size()


func index_of(coin_id: int) -> int:
	return _por_id.get(coin_id, NENHUM)


## Larga uma moeda. `desvio` esta em [-1, 1] e vem sorteado de fora, do fluxo
## `economy`: onde a moeda cai afeta a simulacao, por isso tem de ser um fluxo
## determinista e nao o visual (§42).
func drop(estado: GameState, x: float, faixa: Band.Kind, quanto: int, desvio: float) -> int:
	var coin_id := estado.take_id()
	ids.append(coin_id)
	xs.append(x)
	heights.append(0.0)
	vxs.append(clampf(desvio, -DESVIO_MAX, DESVIO_MAX) * _curva.coin_drop_spread_px_s)
	vys.append(_curva.coin_drop_speed_px_s)
	bands.append(int(faixa))
	amounts.append(quanto)
	settled.append(0)
	_por_id[coin_id] = ids.size() - 1
	return coin_id


## O arco e a queda. Passo 5 do §43: e movimento, e tem de estar feito antes de
## o BuildSystem ler as moedas largadas no passo 8.
func tick(delta: float) -> void:
	for i in ids.size():
		if settled[i] == 1:
			continue
		# Euler semi-implicito: a velocidade PRIMEIRO, a posicao depois. A ordem
		# inversa ultrapassa o apice — a 30 Hz media-se 26 px onde a conta
		# continua da 23 — e acumula energia em qualquer coisa que salte muitas
		# vezes. Esta ordem e estavel e e a que os motores usam.
		vys[i] -= _curva.coin_gravity_px_s2 * delta
		xs[i] += vxs[i] * delta
		heights[i] += vys[i] * delta
		if heights[i] <= 0.0:
			heights[i] = 0.0
			vxs[i] = 0.0
			vys[i] = 0.0
			settled[i] = 1


## A altura maxima do arco de uma moeda largada, em px: v²/2g. Nao e um numero
## novo — sai dos dois que a §61 ja tem em data/ —, e existe porque quem desenha
## a sombra de contacto dela (§22) precisa de saber contra o que a medir. Zero
## com gravidade zero: sem queda nao ha arco, e uma divisao por zero aqui era
## uma sombra de tamanho infinito.
func apex_px() -> float:
	if _curva.coin_gravity_px_s2 <= 0.0:
		return 0.0
	var impulso := _curva.coin_drop_speed_px_s
	# O 2 e o da formula e nao um numero de balanceamento — o portao G4 diz o
	# mesmo ao deixar passar o inteiro e nao o float.
	return impulso * impulso / (2 * _curva.coin_gravity_px_s2)


## Apanha por DISTANCIA, nao por colisao: colisao de moeda com 300 unidades e
## desperdicio (§53, Q-058). So apanha o que esta pousado, na mesma faixa, e ate
## `espaco` moedas — a capacidade do saco vem de UnitData.coin_capacity.
##
## Devolve os ids apanhados, para quem chama emitir coin_collected.
func collect(x: float, faixa: Band.Kind, espaco: int) -> PackedInt32Array:
	var apanhados := PackedInt32Array()
	if espaco <= 0:
		return apanhados
	var raio := _curva.coin_pickup_px
	var levado := 0
	for i in ids.size():
		if settled[i] == 0 or bands[i] != int(faixa):
			continue
		if absf(xs[i] - x) > raio:
			continue
		if levado + amounts[i] > espaco:
			continue
		levado += amounts[i]
		apanhados.append(ids[i])
	for coin_id in apanhados:
		remove(coin_id)
	return apanhados


## Apanha UMA moeda em concreto — a que esta unidade foi buscar — e devolve o
## que ela valia, ou zero se ja la nao esta, se mudou de faixa, se ainda nao
## pousou, se esta fora do raio, ou se nao cabe no saco.
##
## Existe por causa do custo, e o custo foi medido: o collect() por raio varre
## TODAS as moedas do chao, e o value_of() obriga a fotografar o amounts_by_id()
## antes — um dicionario com todas elas. Chamar os dois uma vez por unidade e por
## tick punha o passo 5 a custar o produto de unidades por moedas, e um tick de
## 300 unidades com 60 moedas dava 4372 us contra os 4000 us que o §63 da a
## simulacao INTEIRA. Aqui e uma pesquisa por id e uma comparacao.
##
## Quem sabe qual e a moeda e o passo 4, que ja a escolheu e a guardou em
## target_ids. Apanha-se aquela por que se veio, e nao o que calhar no caminho.
func collect_one(coin_id: int, x: float, faixa: Band.Kind, espaco: int) -> int:
	var i := index_of(coin_id)
	if i == NENHUM or settled[i] == 0 or bands[i] != int(faixa):
		return 0
	if amounts[i] > espaco or absf(xs[i] - x) > _curva.coin_pickup_px:
		return 0
	var valor := amounts[i]
	remove(coin_id)
	return valor


## Quanto vale o que foi apanhado. Separado de collect() porque quem apanha
## precisa dos dois numeros e a lista ja nao tem as moedas.
func value_of(coin_ids: PackedInt32Array, antes: Dictionary) -> int:
	var total := 0
	for coin_id in coin_ids:
		total += antes.get(coin_id, 0)
	return total


## O valor de cada moeda por id, para quem quiser contar antes de apanhar.
func amounts_by_id() -> Dictionary:
	var mapa := {}
	for i in ids.size():
		mapa[ids[i]] = amounts[i]
	return mapa


func remove(coin_id: int) -> bool:
	var i := index_of(coin_id)
	if i == NENHUM:
		return false
	var ultimo := ids.size() - 1
	if i != ultimo:
		_copiar(ultimo, i)
		_por_id[ids[i]] = i
	_encolher()
	_por_id.erase(coin_id)
	return true


## Quantas moedas ainda estao no ar. Zero nao quer dizer que nao ha moedas —
## quer dizer que ninguem esta a espera de nenhuma.
func in_flight() -> int:
	var n := 0
	for i in settled.size():
		if settled[i] == 0:
			n += 1
	return n


## As colunas em tipos base, para o save (§62). Sem Object nenhum.
func to_dict() -> Dictionary:
	return Columns.to_dict(self)


## Repoe do save. Reindexa no fim: o dicionario de ids e derivado das colunas e
## nao vem no ficheiro — guarda-lo era guardar duas vezes a mesma coisa.
func from_dict(d: Dictionary) -> void:
	Columns.from_dict(self, d)
	_reindexar()


func _copiar(de: int, para: int) -> void:
	ids[para] = ids[de]
	xs[para] = xs[de]
	heights[para] = heights[de]
	vxs[para] = vxs[de]
	vys[para] = vys[de]
	bands[para] = bands[de]
	amounts[para] = amounts[de]
	settled[para] = settled[de]


func _encolher() -> void:
	var n := ids.size() - 1
	ids.resize(n)
	xs.resize(n)
	heights.resize(n)
	vxs.resize(n)
	vys.resize(n)
	bands.resize(n)
	amounts.resize(n)
	settled.resize(n)


func _reindexar() -> void:
	_por_id.clear()
	for i in ids.size():
		_por_id[ids[i]] = i
