#!/usr/bin/env python3
"""tools/revisao.py — as imagens que a revisao visual compara, sempre as mesmas.

Duas pranchas, do planejamento de 26/09:

  marco   (§8)  As onze capturas do marco dos Enramados: tres vistas da
                superficie — oeste, centro e leste — de dia, ao crepusculo e de
                noite, e o rei no subsolo em cada uma das duas passagens.
  escala  (§4.5, ADR 0001)  A mesma cena em 1280x720, 1920x1080 e 1280x800,
                com o modo atual (fractional, nearest), o que a ADR 0001 propoe
                (fractional, linear) e a escala inteira (integer, nearest).
  obras   (§6 lote 3, §7)  Oito quadros do centro com obras preparadas em cada
                ponto do SiteStage — vazio, pago em parte, a espera, em obra, a
                operar, tocada, em reparo e em ruina —, rotulados na ficha.

Cada imagem sai com a ficha do tools/captura.gd (commit, motor, renderer que
correu, resolucao, escala, semente, fase, rei, natural/preparado), e a prancha
junta-as num indice.json e numa folha de contacto. Tudo em build/revisao/ —
nao se versiona: o que se publica passa pela revisao, e depois pelo
tools/web/capturas.py.

    xvfb-run -a python3 tools/revisao.py marco     # ou: make marco
    xvfb-run -a python3 tools/revisao.py escala    # ou: make escala
    xvfb-run -a python3 tools/revisao.py obras     # ou: make obras

A semente e fixa (SEMENTE) e o jogo e novo: duas corridas no mesmo commit dao a
mesma regiao, a mesma gente e a mesma noite. Os instantes saem do clock.csv.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parent.parent
SAIDA = RAIZ / "build/revisao"
GODOT = os.environ.get("GODOT", "godot")
SEMENTE = 20260926
BASE = (1280, 720)

# Os centros de camara do §8: em 1280 de largura, 640, 1920 e 3200 cobrem os
# 3840 px da regiao. Em px a contar do nucleo, que e o que o `--rei` le.
VISTAS = {"oeste": -1280, "centro": 0, "leste": 1280}
# As duas passagens do Greybox (PASSAGENS_X). Se mudarem la, a ficha apanha: a
# prancha confere que o rei ficou na faixa de baixo e onde a camara ficou.
PASSAGENS = {"passagem-oeste": -950, "passagem-leste": 950}
FASES = ("dawn", "morning", "noon", "afternoon", "dusk", "night")
MOMENTOS = {"dia": "noon", "crepusculo": "dusk", "noite": "night"}
# A camara antecipa ate 120 px (camera.csv); mais do que isto e outro enquadramento.
FOLGA_CAMARA = 2.0

# Os oito pontos do SiteStage, e as quatro obras do centro que os atravessam: a
# casa de treino e a cozinha (o piloto do lote 3), um canteiro (a obra
# produtiva) e o muro de dentro a leste. Em cada quadro cada obra esta num ponto
# diferente, e ao fim dos oito cada uma passou por todos.
ETAPAS = ("available", "paying", "waiting", "working", "operating", "damaged", "mending", "ruin")
OBRAS_PILOTO = {"training_house": 0, "kitchen": 4, "farm#1": 2, "stakes#2": 6}

RESOLUCOES = ("1280x720", "1920x1080", "1280x800")
MODOS = {
    "atual": {"escala": "fractional", "filtro": "nearest"},
    "adr-0001": {"escala": "fractional", "filtro": "linear"},
    "inteira": {"escala": "integer", "filtro": "nearest"},
}


def meio_da_fase(fase: str) -> float:
    """O segundo do dia 1 no meio de `fase`, contado do clock.csv."""
    linha = next(csv.DictReader((RAIZ / "data/source/clock.csv").open(encoding="utf-8")))
    inicio = sum(float(linha[f]) for f in FASES[: FASES.index(fase)])
    return round(inicio + float(linha[fase]) / 2, 2)


def fotografar(png: Path, resolucao: str, extra: list[str]) -> dict:
    comando = [
        GODOT, "--path", str(RAIZ), "--resolution", resolucao, "tools/captura.tscn", "--",
        "--segundos", "2", "--saida", str(png), "--novo", "--semente", str(SEMENTE), *extra,
    ]
    r = subprocess.run(comando, capture_output=True, text=True, timeout=300)
    # Um script que nao compila nao para o motor: a fotografia sai, sem o que ele
    # desenhava. Uma prancha de revisao com um buraco destes e pior do que nada.
    erro = "SCRIPT ERROR" in r.stdout + r.stderr
    if r.returncode != 0 or not png.exists() or erro:
        sys.exit(f"revisao: a captura {png.name} falhou\n{r.stdout[-2000:]}{r.stderr[-2000:]}")
    ficha = json.loads(png.with_suffix(".json").read_text(encoding="utf-8"))
    ficha.pop("instrumentos", None)
    return ficha


def marco() -> dict:
    pasta = SAIDA / "marco"
    pasta.mkdir(parents=True, exist_ok=True)
    pedidos: list[tuple[str, int, str, str]] = []
    for momento, fase in MOMENTOS.items():
        for vista, dx in VISTAS.items():
            pedidos.append((f"{vista}-{momento}", dx, fase, "surface"))
    for nome, dx in PASSAGENS.items():
        pedidos.append((nome, dx, "noon", "underground"))
    quadros = {}
    for nome, dx, fase, faixa in pedidos:
        segundo = meio_da_fase(fase)
        extra = ["--avancar", str(segundo), "--rei", str(dx), "--faixa", faixa]
        ficha = fotografar(pasta / f"{nome}.png", f"{BASE[0]}x{BASE[1]}", extra)
        ficha["segundo"] = segundo
        conferir_marco(nome, ficha, FASES.index(fase), faixa)
        quadros[nome] = ficha
        print(f"revisao: {nome} · fase {ficha['fase']} · camara x={ficha['camara_x']:.0f}")
    folha(pasta, list(quadros), colunas=3)
    return quadros


def conferir_marco(nome: str, ficha: dict, fase: int, faixa: str) -> None:
    if int(ficha["fase"]) != fase:
        sys.exit(f"revisao: {nome} saiu na fase {ficha['fase']} e nao na {fase}")
    if ficha.get("rei", {}).get("faixa") != faixa:
        sys.exit(f"revisao: {nome} tem o rei em {ficha.get('rei')} e nao na faixa {faixa}")
    if abs(float(ficha["camara_x"]) - float(ficha["rei"]["x"])) > FOLGA_CAMARA:
        sys.exit(
            f"revisao: {nome} enquadrou x={ficha['camara_x']} e o rei esta em "
            f"{ficha['rei']['x']} — a convencao dos tres centros nao vale aqui"
        )


def obras() -> dict:
    pasta = SAIDA / "obras"
    pasta.mkdir(parents=True, exist_ok=True)
    segundo = meio_da_fase("noon")
    quadros = {}
    for k in range(len(ETAPAS)):
        pedido = {o: ETAPAS[(k + d) % len(ETAPAS)] for o, d in OBRAS_PILOTO.items()}
        nome = f"obras-{k + 1}"
        extra = ["--avancar", str(segundo), "--rei", "0"]
        extra += ["--obras", ",".join(f"{o}={e}" for o, e in pedido.items())]
        ficha = fotografar(pasta / f"{nome}.png", f"{BASE[0]}x{BASE[1]}", extra)
        if len(ficha["preparacao"]) < len(OBRAS_PILOTO) + 1:
            sys.exit(f"revisao: {nome} nao preparou as obras todas: {ficha['preparacao']}")
        ficha["etapas"] = pedido
        quadros[nome] = ficha
        print(f"revisao: {nome} · " + " · ".join(f"{o} {e}" for o, e in pedido.items()))
    folha(pasta, list(quadros), colunas=2)
    return quadros


def escala() -> dict:
    pasta = SAIDA / "escala"
    pasta.mkdir(parents=True, exist_ok=True)
    segundo = meio_da_fase("noon")
    quadros = {}
    for resolucao in RESOLUCOES:
        for modo, opcoes in MODOS.items():
            nome = f"{resolucao}-{modo}"
            extra = ["--avancar", str(segundo), "--esticar", "canvas_items"]
            extra += ["--escala", opcoes["escala"], "--filtro", opcoes["filtro"]]
            quadros[nome] = fotografar(pasta / f"{nome}.png", resolucao, extra)
    referencia = cores(pasta / f"{RESOLUCOES[0]}-atual.png")
    for nome, ficha in quadros.items():
        medir(ficha, pasta / f"{nome}.png", referencia)
        print(
            f"revisao: {nome:24} fator {ficha['fator']:.3f} · imagem {ficha['imagem']} · "
            f"barras {ficha['barras']:.1%} · passo {ficha['passo_px']} px · "
            f"cores {ficha['cores']} ({ficha['cores_x']:.1f}x)"
        )
    folha(pasta, list(quadros), colunas=len(MODOS))
    return quadros


def cores(png: Path) -> int:
    return len(Image.open(png).convert("RGB").getcolors(maxcolors=1 << 24))


def medir(ficha: dict, png: Path, referencia: int) -> None:
    """Tres numeros que se leem sem gosto: quanto do ecra fica sem imagem, que
    tamanhos tem um pixel da arte no ecra, e quantas cores diferentes ha contra
    a mesma cena a 1:1. O filtro linear inventa cores entre pixeis vizinhos; o
    nearest nao. A contagem, e nao a comparacao pixel a pixel, porque a luz da
    fase anda durante os dois segundos da captura e muda todas as cores um pouco.
    """
    janela = ficha["janela"][0] * ficha["janela"][1]
    fator = float(ficha["fator"])
    imagem = BASE[0] * fator * BASE[1] * fator
    ficha["barras"] = round(max(0.0, 1.0 - imagem / janela), 4)
    baixo, alto = int(fator), int(-(-fator // 1))
    ficha["passo_px"] = f"{baixo}" if baixo == alto else f"{baixo} e {alto}"
    ficha["cores"] = cores(png)
    ficha["cores_x"] = round(ficha["cores"] / referencia, 2)


def folha(pasta: Path, nomes: list[str], colunas: int) -> None:
    """Uma folha de contacto a metade do tamanho, com o nome de cada quadro."""
    miniaturas = [Image.open(pasta / f"{n}.png").convert("RGB") for n in nomes]
    largo, alto = BASE[0] // 2, BASE[1] // 2
    linhas = -(-len(nomes) // colunas)
    faixa = 20
    prancha = Image.new("RGB", (largo * colunas, (alto + faixa) * linhas), (16, 13, 9))
    desenho = ImageDraw.Draw(prancha)
    for k, (nome, img) in enumerate(zip(nomes, miniaturas)):
        img.thumbnail((largo, alto), Image.Resampling.NEAREST)
        x, y = (k % colunas) * largo, (k // colunas) * (alto + faixa)
        prancha.paste(img, (x + (largo - img.width) // 2, y + faixa))
        desenho.text((x + 6, y + 4), nome, fill=(231, 197, 135))
    prancha.save(pasta / "folha.png")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("prancha", choices=("marco", "escala", "obras"))
    args = parser.parse_args()
    quadros = {"marco": marco, "escala": escala, "obras": obras}[args.prancha]()
    manifesto = subprocess.run(
        [sys.executable, str(RAIZ / "tools/manifesto.py")], capture_output=True, text=True
    )
    indice = {
        "prancha": args.prancha,
        "semente": SEMENTE,
        "declarado": json.loads(manifesto.stdout),
        "quadros": quadros,
    }
    destino = SAIDA / args.prancha / "indice.json"
    destino.write_text(json.dumps(indice, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"revisao: {len(quadros)} quadros · {destino.relative_to(RAIZ)} · folha.png ao lado")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
