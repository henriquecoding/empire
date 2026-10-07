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

As seis fases tiram-se com `--limpo true`: so o mundo, sem a interface por
cima — o quadro inteiro, 16:9, como o jogo o desenha. O ecra com a interface
tira-se a parte, uma vez por lingua (a do LANG, que e a que o jogo escolhe ao
arrancar sem preferencia gravada), porque o site tambem tem de mostrar o ecra
como ele e hoje, e a pagina portuguesa nao mostra um painel em ingles.

WebP sem perdas: e pixel art, e uma compressao com perdas borra o degrau de
2 px que o §22 mede.

    xvfb-run -a python3 tools/web/capturas.py        # ou: make site-capturas

Precisa do motor (GODOT ou `godot` no PATH), de um ecra (xvfb-run num servidor)
e do Pillow do tools/requirements.txt. Fora do jogo; corre-se a mao, quando o
que se ve mudou. A Vercel nao a corre: nao tem ecra.
"""

from __future__ import annotations

import csv
import hashlib
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
# O ecra com a interface, uma vez por lingua do site: o LANG de cada corrida.
LINGUAS = {"pt": "pt_PT.UTF-8", "en": "en_US.UTF-8"}


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


def fotografar(nome: str, segundo: float, limpo: bool = True, lingua: str = "pt") -> dict:
    png = TRABALHO / f"{nome}.png"
    comando = [
        GODOT, "--path", str(RAIZ), "--resolution", "1280x720", "tools/captura.tscn", "--",
        "--segundos", "2", "--avancar", str(segundo), "--saida", str(png), "--novo",
    ]
    if limpo:
        comando += ["--limpo", "true"]
    ambiente = {**os.environ, "LANG": LINGUAS[lingua], "LC_ALL": LINGUAS[lingua], "LANGUAGE": ""}
    subprocess.run(comando, check=True, capture_output=True, timeout=240, env=ambiente)
    ficha = json.loads(png.with_suffix(".json").read_text(encoding="utf-8"))
    ficha["segundo"] = segundo
    return ficha


def quadro(ficha: dict) -> tuple[int, int, int, int]:
    """O quadro inteiro: sem interface, nao ha nada a cortar."""
    return (0, 0, int(ficha["largura"]), int(ficha["altura"]))


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


def gravar(png: Path, destino: Path, caixa: tuple[int, int, int, int] | None, divisor: int = 1) -> int:
    imagem = Image.open(png).convert("RGB")
    if caixa is not None:
        imagem = imagem.crop(caixa)
    if divisor > 1:
        # A miniatura dos cartoes das fases: meio tamanho, pelo vizinho mais
        # proximo — o pixel do jogo tem 2 px de ecra (§22), e assim fica com 1.
        imagem = imagem.resize((imagem.width // divisor, imagem.height // divisor), Image.NEAREST)
    imagem.save(destino, "WEBP", lossless=True, quality=100, method=6)
    return destino.stat().st_size


# O que o jogo mostra depende destes ficheiros, e so destes. A impressao deles vai
# na ficha das imagens, e o site (tools/web/dados.mjs) volta a calcula-la na
# publicacao: se diferir, as imagens sao de um jogo que ja nao e o publicado, e a
# pagina di-lo em vez de as apresentar como o ecra de hoje. Sem git: a Vercel
# nao tem o historico, tem os ficheiros. A mesma conta dos dois lados.
APARENCIA_PASTAS = ("src", "scenes", "art/export", "shaders", "data")
APARENCIA_TIPOS = (".gd", ".tscn", ".tres", ".gdshader", ".png", ".json", ".csv", ".godot")


def aparencia(raiz: Path = RAIZ) -> str:
    """sha256 de `caminho\\0sha256(conteudo)\\n` por ficheiro, pela ordem do caminho."""
    ficheiros = [raiz / "project.godot"]
    for pasta in APARENCIA_PASTAS:
        ficheiros += [
            f for f in (raiz / pasta).rglob("*") if f.is_file() and f.suffix in APARENCIA_TIPOS
        ]
    total = hashlib.sha256()
    for caminho in sorted(f.relative_to(raiz).as_posix() for f in ficheiros):
        conteudo = hashlib.sha256((raiz / caminho).read_bytes()).hexdigest()
        total.update(f"{caminho}\0{conteudo}\n".encode())
    return total.hexdigest()


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
    caixa = quadro(fichas["manha"])
    conferir_noite(fichas["noite"], caixa)
    quadros = {}
    for fase in FASES:
        n = gravar(TRABALHO / f"{fase}.png", SAIDA / f"dia-{fase}.webp", caixa)
        gravar(TRABALHO / f"{fase}.png", SAIDA / f"mini-{fase}.webp", caixa, divisor=2)
        gravar(TRABALHO / f"{fase}.png", SAIDA / f"cartao-{fase}.webp", caixa, divisor=4)
        quadros[fase] = {
            "segundo": fichas[fase]["segundo"],
            "dia": fichas[fase]["dia"],
            "bytes": n,
            "foco": foco(fichas[fase], caixa),
        }
        print(f"capturas: dia-{fase}.webp e mini-{fase}.webp · {n / 1024:.0f} KB · {fichas[fase]['segundo']} s")
    segundo = instantes()[INTEIRA]
    for lingua in LINGUAS:
        fichas[f"ecra-{lingua}"] = fotografar(f"ecra-{lingua}", segundo, limpo=False, lingua=lingua)
        n = gravar(TRABALHO / f"ecra-{lingua}.png", SAIDA / f"ecra-{lingua}.webp", None)
        print(f"capturas: ecra-{lingua}.webp · {n / 1024:.0f} KB · com a interface, em {lingua}")
    ficha = {
        "commit": git("rev-parse", "HEAD"),
        "aparencia": aparencia(),
        "tiradas": date.today().isoformat(),
        "godot": (RAIZ / ".godot-version").read_text(encoding="utf-8").strip(),
        "largura": caixa[2] - caixa[0],
        "altura": caixa[3] - caixa[1],
        "ecra": [int(fichas["ecra-pt"]["largura"]), int(fichas["ecra-pt"]["altura"])],
        "recorte": list(caixa),
        "noite_fraccao": NOITE_FRACCAO,
        "quadros": quadros,
    }
    (SAIDA / "capturas.json").write_text(json.dumps(ficha, indent=2) + "\n", encoding="utf-8")
    print(f"capturas: {SAIDA / 'capturas.json'} · commit {ficha['commit'][:7]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
