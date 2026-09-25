#!/usr/bin/env python3
"""tools/web/capturas.py — as imagens do site sao o jogo, tiradas do jogo (ADR 0025).

O site mostra o dia a passar sobre o castelo-arvore, da alvorada a noite, e a
candeia da Podridao a chegar — que e o GIF que o §03 e o §36 pedem. Nenhuma
dessas imagens e desenhada para o site: sao seis fotografias da build, tiradas
pelo tools/captura.tscn no mesmo segmento, com o relogio avancado ao meio de
cada fase. Os instantes saem do clock.csv e nao de uma lista escrita aqui: se a
duracao de uma fase mudar, a fotografia muda com ela.

A noite e a excepcao, e e de proposito: o meio da noite e o reino as escuras e
a mancha ainda fora do quadro. O que interessa e a candeia a entrar, e por isso
a noite tira-se a NOITE_FRACCAO dela — e confere-se na ficha da captura que a
mancha esta mesmo dentro do ecra. Se um dia a Podridao andar mais devagar e nao
chegar ao quadro, isto chumba em vez de publicar uma noite vazia.

Os instrumentos do greybox (os paineis de cima e a linha de teclas de baixo)
saem pelo recorte, que tambem se le da ficha: e o rectangulo entre eles. Uma
imagem fica inteira, com os instrumentos, porque o site tambem tem de mostrar o
ecra como ele e hoje.

WebP sem perdas: e pixel art, e uma compressao com perdas borra o degrau de
2 px que o §22 mede.

    xvfb-run -a python3 tools/web/capturas.py        # ou: make site-capturas

Precisa do motor (GODOT ou `godot` no PATH), de um ecra (xvfb-run num servidor)
e do Pillow do tools/requirements.txt. Fora do jogo; corre-se a mao, quando o
que se ve mudou. A Vercel nao a corre: nao tem ecra.
"""

from __future__ import annotations

import csv
import json
import os
import subprocess
import sys
from datetime import date
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent.parent
SAIDA = RAIZ / "tools/web/site/img"
TRABALHO = RAIZ / "build/capturas"
GODOT = os.environ.get("GODOT", "godot")

FASES = ("alvorada", "manha", "meiodia", "tarde", "crepusculo", "noite")
COLUNAS = ("dawn", "morning", "noon", "afternoon", "dusk", "night")
NOITE_FRACCAO = 0.71
INTEIRA = "manha"
# O painel de baixo tem sombra por cima dele: medido na captura de 1280x720,
# as linhas 654-671 sao uma faixa escura de ponta a ponta que nao e o jogo.
SOMBRA_PX = 24


def instantes() -> dict[str, float]:
    """O segundo do dia 1 em que cada fase e fotografada, contado do clock.csv."""
    linha = next(csv.DictReader((RAIZ / "data/source/clock.csv").open(encoding="utf-8")))
    saida: dict[str, float] = {}
    inicio = 0.0
    for fase, coluna in zip(FASES, COLUNAS):
        dura = float(linha[coluna])
        fraccao = NOITE_FRACCAO if fase == "noite" else 0.5
        saida[fase] = round(inicio + dura * fraccao, 2)
        inicio += dura
    return saida


def fotografar(fase: str, segundo: float) -> dict:
    png = TRABALHO / f"{fase}.png"
    comando = [
        GODOT, "--path", str(RAIZ), "--resolution", "1280x720", "tools/captura.tscn", "--",
        "--segundos", "2", "--avancar", str(segundo), "--saida", str(png), "--novo",
    ]
    subprocess.run(comando, check=True, capture_output=True, timeout=240)
    ficha = json.loads(png.with_suffix(".json").read_text(encoding="utf-8"))
    ficha["segundo"] = segundo
    return ficha


def recorte(ficha: dict) -> tuple[int, int, int, int]:
    """O rectangulo entre os instrumentos de cima e os de baixo, a largura toda."""
    altura = int(ficha["altura"])
    cima = max([int(y + h) for x, y, w, h in ficha["instrumentos"] if y <= 0] or [0])
    baixo = min([int(y) for x, y, w, h in ficha["instrumentos"] if y + h >= altura - 24] or [altura])
    return (0, cima, int(ficha["largura"]), baixo - SOMBRA_PX)


def conferir_noite(ficha: dict, caixa: tuple[int, int, int, int]) -> None:
    if not ficha["mancha"]:
        sys.exit("capturas: a noite nao tem mancha nenhuma — a Podridao nao nasceu?")
    x, y, w, h = ficha["mancha"][0]
    if x + w <= 0 or x >= caixa[2] or y >= caixa[3] or y + h <= caixa[1]:
        sys.exit(f"capturas: a candeia esta fora do quadro ({x:.0f}, {y:.0f}) — muda NOITE_FRACCAO")


def foco(ficha: dict, caixa: tuple[int, int, int, int]) -> float:
    """Onde o olho deve ficar quando o ecra e estreito e a imagem se recorta.

    De dia e o centro, que e onde o rei e o castelo-arvore estao. De noite e a
    candeia: num telemovel o quadro perde as pontas, e a noite sem ela e so o
    reino as escuras. E o valor do object-position, que encosta a janela ao
    lado do ponto — com a candeia a tres quartos, o castelo ao meio continua la.
    """
    largura = caixa[2] - caixa[0]
    if not ficha.get("mancha"):
        return 0.5
    x, _y, w, _h = ficha["mancha"][0]
    centro = x + w / 2
    # No crepusculo a mancha ja existe e ainda esta la fora, na borda do mapa.
    if centro < 0 or centro > largura:
        return 0.5
    return round(centro / largura, 3)


def gravar(png: Path, destino: Path, caixa: tuple[int, int, int, int] | None) -> int:
    imagem = Image.open(png).convert("RGB")
    if caixa is not None:
        imagem = imagem.crop(caixa)
    imagem.save(destino, "WEBP", lossless=True, quality=100, method=6)
    return destino.stat().st_size


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=RAIZ, capture_output=True, text=True).stdout.strip()


def main() -> int:
    TRABALHO.mkdir(parents=True, exist_ok=True)
    SAIDA.mkdir(parents=True, exist_ok=True)
    fichas = {fase: fotografar(fase, s) for fase, s in instantes().items()}
    for fase, ficha in fichas.items():
        esperada = FASES.index(fase)
        if int(ficha["fase"]) != esperada:
            sys.exit(f"capturas: {fase} saiu na fase {ficha['fase']}, e nao na {esperada}")
    caixa = recorte(fichas["manha"])
    conferir_noite(fichas["noite"], caixa)
    quadros = {}
    for fase in FASES:
        n = gravar(TRABALHO / f"{fase}.png", SAIDA / f"dia-{fase}.webp", caixa)
        quadros[fase] = {
            "segundo": fichas[fase]["segundo"],
            "dia": fichas[fase]["dia"],
            "bytes": n,
            "foco": foco(fichas[fase], caixa),
        }
        print(f"capturas: dia-{fase}.webp · {n / 1024:.0f} KB · {fichas[fase]['segundo']} s")
    n = gravar(TRABALHO / f"{INTEIRA}.png", SAIDA / "ecra.webp", None)
    print(f"capturas: ecra.webp · {n / 1024:.0f} KB · com os instrumentos")
    ficha = {
        "commit": git("rev-parse", "HEAD"),
        "tiradas": date.today().isoformat(),
        "godot": (RAIZ / ".godot-version").read_text(encoding="utf-8").strip(),
        "largura": caixa[2] - caixa[0],
        "altura": caixa[3] - caixa[1],
        "ecra": [int(fichas[INTEIRA]["largura"]), int(fichas[INTEIRA]["altura"])],
        "recorte": list(caixa),
        "noite_fraccao": NOITE_FRACCAO,
        "quadros": quadros,
    }
    (SAIDA / "capturas.json").write_text(json.dumps(ficha, indent=2) + "\n", encoding="utf-8")
    print(f"capturas: {SAIDA / 'capturas.json'} · commit {ficha['commit'][:7]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
