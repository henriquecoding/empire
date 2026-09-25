# src/sim/data/chapter_data.gd — os dez Capitulos (§77).
# Um lugar, uma lei, um habitante, uma cancao. O gerador coloca seis por
# campanha, no maximo um por regiao. Gerado de data/source/chapters.csv.
class_name ChapterData
extends Resource

@export var id: StringName
@export var display_key: String
## A lei, numa frase. Se precisar de duas, sao dois capitulos (§77, regra 1).
@export var law_key: String
## Quem a cumpre com naturalidade e nunca a justifica (§77, regra 2).
@export var inhabitant_key: String
## Vinte a quarenta segundos, sem letra traduzivel (§77, regra 3; §81).
@export var song_key: String

@export_group("Colocacao")
## Vazio = qualquer bioma. Caso contrario o id de data/biomes/ (§44).
@export var biome: StringName = &""
## &"bifurcation", &"roadside", &"crossing", &"fortress", &"near_mercenary_camp".
@export var placement: StringName = &""
## O preco do desvio, em segundos: 25 numa bifurcacao, 40 numa travessia (§77).
@export var detour_seconds: float = 0.0
## O Cerco Que Nao Acaba sai sempre — e o que garante o diario 12 (§77, D-11).
@export var guaranteed: bool = false
## A ordem da §77, de 1 a 10. Um diario cujo capitulo nao saiu vai para o
## seguinte que tenha saido, por esta ordem (§77, "a historia chega inteira").
@export var order: int = 0

@export_group("Recompensa")
## &"journal" ou &"ancient_seed" (§77, regra 4).
@export var reward_kind: StringName = &""
## O id do diario, quando reward_kind e &"journal".
@export var reward_id: StringName = &""

@export_group("Regras")
## A lei nao entra em casa — exceto num capitulo, e de proposito (§77, D-10).
@export var law_enters_walls: bool = false
## As visitas contam para a Casa Que Conta e para a Ponte (§77, §84).
@export var visits_tracked: bool = false
## A raiz verificavel, para que ninguem a perca pelo caminho (§77).
@export var folk_root: String = ""
