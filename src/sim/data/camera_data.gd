# src/sim/data/camera_data.gd — a camara como dados (§19, §24, §59).
# Gerado a partir de data/source/camera.csv.
#
# Uma camara so (§11): o mundo e uma linha, o enquadramento vertical e fixo, e
# por isso nada aqui fala de Y. O que se afina e como ela segue em X.
#
# So um destes numeros vem do dossie — os 2 s do regresso da camara livre (§24).
# Os outros estao marcados em _proposed e a pergunta e a Q-057: sao propostas
# por aprovar, nao decisoes tomadas em silencio.
class_name CameraData
extends Resource

## Quanto a camara se adianta na direcao do movimento, em px. Zero desliga a
## antecipacao — que e o que a cegueira do Cavaleiro Selado faz (§24).
@export var lookahead_px: float = 0.0

## Constante de tempo da antecipacao, em segundos: quanto demora a assentar
## depois de o alvo mudar de direcao. Alta de proposito — uma antecipacao que
## salta ao primeiro passo para tras da enjoo.
@export var lookahead_seconds: float = 0.0

## Constante de tempo do seguimento, em segundos. Baixa: a camara cola-se ao
## alvo, e e a antecipacao que da a folga.
@export var follow_seconds: float = 0.0

## Velocidade da camara livre (§24: stick direito, Q e Z), em px/s.
@export var free_speed_px_s: float = 0.0

## §24: "Reconhecimento; volta sozinha em 2 s". O unico numero desta tabela que
## o dossie escreve.
@export var free_return_seconds: float = 2.0
