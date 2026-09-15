# 44 — Definições · Os recursos, com todos os campos

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Doze classes de Resource. Cada uma é gerada a partir de um CSV em data/source/ pela ferramenta tools/csv_to_tres.gd — o CSV é a fonte, o .tres é artefacto, e nenhum dos dois se edita à mão no outro lado.

| Classe | CSV de origem | Linhas na fatia vertical | Campos-chave |
| --- | --- | --- | --- |
| UnitData | units.csv | 6 | custo, vida, dano, intervalo, precisão aberta, alcance, faixa, velocidade |
| CreatureData | creatures.csv | 3 (de 6) | massa, vida, dano, intervalo, velocidade, dia mínimo, faixa, alvo preferido |
| BuildingData | buildings.csv | 7 (de 13) | custo, matéria produzida, ritmo, bioma exigido, largura, slots, estados |
| WallData | walls.csv | 5 | nível, custo, vida, slots de contacto, material, peças |
| PeopleData | peoples.csv | 1 (de 6) | kit de arquitetura, rampa de paleta, fonte arquitetónica, tropa única, modificadores |
| ClassData | classes.csv | 1 (de 4) | fases, verbo, custo de Semente Real, efeitos |
| CraftData | crafts.csv | 3 (de 5) | matéria consumida, moeda agora, capacidade depois, edifício-alvo |
| BiomeData | biomes.csv | 1 (de 6) | tabela de criaturas, recursos disponíveis, preset atmosférico, faixas de parallax |
| SegmentData | segments.csv | 8 | tipo, peso, restrições de adjacência, cena, slots de construção, cavidades |
| EconomyCurve | economy.csv | 1 | curva de rendimento, dia de asfixia alvo, preços de mercenário por fase |
| RotProfile | rot.csv | 1 | velocidade base e por dia, massa base e por dia, intervalo de invocação, abrandamentos |
| MountData | mounts.csv | 0 (Fase 6) | velocidade, capacidade, faixa, penalização sem montaria |


## As duas que mais interessam, por extenso

```gdscript
# src/sim/data/unit_data.gd
class_name UnitData extends Resource

@export var id: StringName                      # &"archer" — chave do Registry
@export var display_key: String                   # chave de tradução, não texto
@export var people: StringName = &"neutral"

@export_group("Combate")
@export var max_health: int = 10
@export var damage: int = 0
@export var attack_interval: float = 1.2          # segundos
@export var accuracy_open: float = 0.34            # 1.0 dentro de torre
@export var range_px: int = 28
@export var targets_bands: Array[int] = [1]         # que faixas consegue atingir

@export_group("Economia")
@export var recruit_cost: int = 1
@export var upkeep_per_day: float = 0.0
@export var drops_on_death: Array[StringName] = []

@export_group("Mundo")
@export var band: Band.Kind = Band.Kind.SURFACE
@export var move_speed: float = 26.0               # px/s
@export var scale_tier: int = 2                    # 1, 2 ou 3 — §22
@export var can_change_band: bool = false

@export_group("Arte")
@export var sprite_frames: SpriteFrames
@export var layer_slots: Array[StringName] = [&"body", &"face", &"weapon"]
@export var shadow_width: int = 18                 # largura da elipse de contacto
```

```gdscript
# src/sim/data/rot_profile.gd — A Podridão como dados, não como código
class_name RotProfile extends Resource

@export var speed_base: float = 14.0               # px/s
@export var speed_per_day: float = 0.9
@export var mass_base: float = 60.0
@export var mass_per_day: float = 26.0
@export var mass_per_fortress: float = 40.0
@export var summon_interval: Vector2 = Vector2(4.0, 7.0)
@export var consecrated_slowdown: float = 0.40      # -40% em terreno consagrado
@export var trail_move_penalty: float = 0.20
@export var two_sided_from_day: int = 12
@export var sacrifice_mass_per_coin: float = 0.5
```

> **A regra do texto**
>
> Nenhum .tres contém texto visível — só display_key. O jogo do dossiê é quase sem texto (§27), mas quase não é nada, e a diferença entre pôr as strings numa tabela desde o dia 1 e migrá-las no mês 20 é de duas horas contra duas semanas.
