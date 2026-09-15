# src/world/band_layers.gd — a matriz de colisao do §53, num sitio so.
#
# A invariante I3: uma camara so, tres faixas, camadas de fisica separadas. A
# regra que faz a matriz funcionar e simples e nao esta escrita em lado nenhum
# como formula, so como tabela: **duas coisas so colidem se partilharem o bit da
# faixa**. O terreno tambem tem faixa. E por isso que uma voadora atravessa uma
# cavidade sem dar por ela — nao por um `if` algures, mas porque a mascara dela
# nao tem o bit do subsolo.
#
# Ninguem poe collision_layer a mao. Chama-se apply_body() e apply_terrain(), e
# a faixa decide. Um `if band == AERIAL` espalhado por tres ficheiros e
# exatamente o que a §11 avisa que custa uma reescrita no dia 200.
class_name BandLayers
extends RefCounted


## O bit da faixa. AERIAL=1, SURFACE=2, UNDERGROUND=4 (§47).
static func bit(faixa: Band.Kind) -> int:
	match faixa:
		Band.Kind.AERIAL:
			return Band.L_AERIAL
		Band.Kind.SURFACE:
			return Band.L_SURFACE
		_:
			return Band.L_UNDER


## Em que camada vive um corpo desta faixa.
static func body_layer(faixa: Band.Kind) -> int:
	return bit(faixa)


## Com o que e que ele colide. So o que esta na mesma faixa — e, na superficie e
## no subsolo, tambem os edificios (§53: L_BUILDING colide com "Superficie e
## subsolo"). A faixa aerea ignora tudo o que e de solo: nao leva L_BUILDING.
static func body_mask(faixa: Band.Kind) -> int:
	if faixa == Band.Kind.AERIAL:
		return Band.L_AERIAL
	return bit(faixa) | Band.L_BUILDING


## O terreno tem faixa. O mesmo TileMapLayer com mascara de revelacao serve as
## tres "seletivamente" (§53) — e a seletividade e esta: cada pedaco de terreno
## leva o bit da faixa a que pertence, mais L_TERRAIN para quem quiser perguntar
## "isto e terreno?" sem saber a faixa.
static func terrain_layer(faixa: Band.Kind) -> int:
	return bit(faixa) | Band.L_TERRAIN


## O terreno nao procura ninguem: e quem anda que o encontra.
static func terrain_mask() -> int:
	return 0


## Um edificio e atacavel da superficie e do subsolo (§53).
static func building_layer() -> int:
	return Band.L_BUILDING


static func building_mask() -> int:
	return Band.L_SURFACE | Band.L_UNDER | Band.L_TERRAIN


## Uma moeda cai e assenta no terreno da faixa onde foi largada, mas nao e
## apanhada por colisao — a apanha e por proximidade, porque colisao de moeda
## com 300 unidades e desperdicio (§53). Ver a Q-058.
static func coin_layer() -> int:
	return Band.L_COIN


static func coin_mask(faixa: Band.Kind) -> int:
	return terrain_layer(faixa)


## Poe a faixa num corpo que anda. O unico sitio onde isto se faz.
static func apply_body(corpo: CollisionObject2D, faixa: Band.Kind) -> void:
	corpo.collision_layer = body_layer(faixa)
	corpo.collision_mask = body_mask(faixa)


## Poe a faixa num pedaco de terreno.
static func apply_terrain(corpo: CollisionObject2D, faixa: Band.Kind) -> void:
	corpo.collision_layer = terrain_layer(faixa)
	corpo.collision_mask = terrain_mask()


## Poe a faixa num edificio.
static func apply_building(corpo: CollisionObject2D) -> void:
	corpo.collision_layer = building_layer()
	corpo.collision_mask = building_mask()


## Verdadeiro se um corpo destas duas faixas se pode tocar. A pergunta que o
## teste faz, e que qualquer sistema deve fazer aqui em vez de a re-deduzir.
static func collide(a: Band.Kind, b: Band.Kind) -> bool:
	return (body_mask(a) & body_layer(b)) != 0
