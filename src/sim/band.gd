# src/sim/band.gd — corrigido na v5.1, ver §70
# v5.2: as seis constantes de camada de física passam a uma por linha. A forma
# da §47 ("const A := 1, B := 2") não compila em Godot 4.6 (erro de parse), e
# derrubava também UnitData, que declara `band: Band.Kind`. Ver docs/adr/0009.
class_name Band
enum Kind { AERIAL = 0, SURFACE = 1, UNDERGROUND = 2 }

# Planos de imagem — §11. Fixados na Fase 0 e nunca mexidos.
const SKY_TOP := 0
const HORIZON := 420  # onde as camadas distantes se encontram
const GROUND_LINE := 517  # onde as tropas pisam — valor em aberto até ao greybox (§67)
const SCREEN_BOTTOM := 720
const AERIAL_BOTTOM := 200
const SOIL_CUT := SCREEN_BOTTOM - GROUND_LINE  # 203

# A que distância de uma passagem ela ainda se alcança, em px (§11). Não é
# balanceamento: é a tolerância de um gesto, e o dossiê não lhe dá número —
# fica ancorada na largura de uma tropa à escala 2 (§01). Ver a Q-066.
const PASSAGE_PX := 24.0

# Camadas de física — uma por faixa, mais estáticos (§53)
const L_AERIAL := 1
const L_SURFACE := 2
const L_UNDER := 4
const L_TERRAIN := 8
const L_BUILDING := 16
const L_COIN := 32
