#!/usr/bin/env python3
"""A rampa de densidade do §11 e do §22, contada sobre uma imagem final (GB-03).

O §22 diz como se mede, e diz que não é a olho: *cores distintas numa janela de
16×16 px, medida na imagem final*. O §11 mede as capturas de referência em seis
faixas horizontais, do topo do ecrã para a base, e é assim que isto as conta:
seis faixas de altura igual, e em cada uma a média das cores distintas por
janela de 16×16.

A regra do GB-03 é a das duas pontas da rampa: **o topo (faixa 1, o céu) não
passa do teto da camada 1, e a base (faixa 5, o plano de jogo, que é a camada de
referência) não fica abaixo do mínimo da camada 5.** Nenhum limiar está escrito
aqui: saem da coluna `colors_per_16px` de `data/source/parallax_layers.csv`,
pelo preset da cena (`open` ou `closed`). Mudar os dados muda o portão.

Três modos, porque o greybox chumba por construção — é de cores chapadas, e a
regra é sobre a arte que vier (o ticket põe-na fora: *"Fase 2"*):

    python3 tools/check_densidade.py --prova            # o portão chumba e passa
    python3 tools/check_densidade.py build/empire.png   # relatório: a rampa medida
    python3 tools/check_densidade.py build/greybox/*.png  # as seis greybox do GB-02
    python3 tools/check_densidade.py --exigir cena.png  # o portão, sobre arte

O `--prova` é o que corre no CI como portão: fabrica uma cena que cumpre e uma
chapada que não cumpre, e chumba se o contador não as separar. O relatório corre
sobre a captura do greybox e escreve os seis números — é o "um número mede-se em
vez de se discutir" do ticket. O `--exigir` é o portão sobre um ecrã acabado.
"""

from __future__ import annotations

import csv
import random
import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
CAMADAS = RAIZ / "data" / "source" / "parallax_layers.csv"
BIOMAS = RAIZ / "data" / "source" / "biomes.csv"

# A janela e o numero de faixas sao a definicao da metrica (§11, §22), e nao
# afinacao: mudar um deles e medir outra coisa.
JANELA = 16
FAIXAS = 6
TOPO = 1
BASE = 5


def intervalos(preset: str) -> dict[int, tuple[int, int]]:
    """camada -> (minimo, maximo) de cores distintas por janela, do CSV."""
    saida: dict[int, tuple[int, int]] = {}
    with CAMADAS.open(encoding="utf-8") as f:
        for linha in csv.DictReader(f):
            if linha["preset"] != preset:
                continue
            minimo, maximo = linha["colors_per_16px"].split("|")
            saida[int(linha["layer"])] = (int(minimo), int(maximo))
    if TOPO not in saida or BASE not in saida:
        raise SystemExit(f"check_densidade: {CAMADAS.name} nao tem as camadas {TOPO} e {BASE} de '{preset}'")
    return saida


def preset_do_bioma(png: Path) -> str | None:
    """O preset de um PNG com o nome de um bioma (build/greybox/<bioma>.png)."""
    with BIOMAS.open(encoding="utf-8") as f:
        for linha in csv.DictReader(f):
            if linha["id"] == png.stem:
                return linha["parallax_preset"]
    return None


def rampa(imagem: Image.Image) -> list[float]:
    """A media de cores distintas por janela de 16x16, em cada uma das seis faixas."""
    rgb = imagem.convert("RGB")
    largura, altura = rgb.size
    px = rgb.load()
    alto = altura // FAIXAS
    medias: list[float] = []
    for faixa in range(FAIXAS):
        contagens: list[int] = []
        for y0 in range(faixa * alto, (faixa + 1) * alto - JANELA + 1, JANELA):
            for x0 in range(0, largura - JANELA + 1, JANELA):
                cores = {px[x, y] for y in range(y0, y0 + JANELA) for x in range(x0, x0 + JANELA)}
                contagens.append(len(cores))
        medias.append(sum(contagens) / len(contagens) if contagens else 0.0)
    return medias


def veredito(medias: list[float], limites: dict[int, tuple[int, int]]) -> list[str]:
    """O que falha nas duas pontas da rampa. Vazio = passa."""
    falhas: list[str] = []
    topo, base = medias[TOPO - 1], medias[BASE - 1]
    if topo > limites[TOPO][1]:
        falhas.append(f"topo (faixa {TOPO}) com {topo:.1f} cores por janela; o teto da camada {TOPO} e {limites[TOPO][1]}")
    if base < limites[BASE][0]:
        falhas.append(f"base (faixa {BASE}) com {base:.1f} cores por janela; o minimo da camada {BASE} e {limites[BASE][0]}")
    return falhas


def _escrever(medias: list[float]) -> None:
    for i, m in enumerate(medias, start=1):
        print(f"  faixa {i}: {m:5.1f} cores por janela de {JANELA}x{JANELA}")


def _cena(alto: int, largura: int, cores_por_faixa: list[int], semente: int) -> Image.Image:
    """Uma imagem sintetica: cada faixa pintada ao acaso com N cores distintas."""
    sorteio = random.Random(semente)
    img = Image.new("RGB", (largura, alto))
    px = img.load()
    faixa_alto = alto // FAIXAS
    for faixa, n in enumerate(cores_por_faixa):
        paleta = [(faixa * 40 % 256, k * 7 % 256, (k * 13 + faixa) % 256) for k in range(n)]
        for y in range(faixa * faixa_alto, (faixa + 1) * faixa_alto):
            for x in range(largura):
                px[x, y] = paleta[sorteio.randrange(n)]
    return img


def prova(preset: str) -> int:
    """O portao tem de chumbar a cena chapada e passar a que cumpre a rampa."""
    limites = intervalos(preset)
    # Uma cena que cumpre: poucas cores no topo, muitas na base. Sao 256 pixeis
    # por janela, e por isso N cores ao acaso aparecem quase todas.
    boa = _cena(720, 1280, [limites[TOPO][0], 16, 20, 24, limites[BASE][1], 20], 20260925)
    # O greybox: uma cor por faixa.
    chapada = _cena(720, 1280, [1, 1, 1, 1, 1, 1], 1)
    # E o contrario da rampa: o topo cheio.
    invertida = _cena(720, 1280, [limites[BASE][1], 20, 20, 20, limites[TOPO][0], 1], 7)
    casos = [("cumpre", boa, True), ("chapada", chapada, False), ("invertida", invertida, False)]
    erros = 0
    for nome, img, deve_passar in casos:
        passa = not veredito(rampa(img), limites)
        estado = "passa" if passa else "chumba"
        certo = passa == deve_passar
        erros += 0 if certo else 1
        print(f"check_densidade --prova: a cena '{nome}' {estado}" + ("" if certo else "  <- ERRADO"))
    return 1 if erros else 0


def main(argv: list[str]) -> int:
    preset = ""
    if "--preset" in argv:
        preset = argv[argv.index("--preset") + 1]
        del argv[argv.index("--preset") : argv.index("--preset") + 2]
    if argv == ["--prova"]:
        return prova(preset or "open")
    exigir = "--exigir" in argv
    ficheiros = [Path(a) for a in argv if not a.startswith("--")]
    if not ficheiros:
        print(__doc__)
        return 2
    resultado = 0
    for png in ficheiros:
        resultado = max(resultado, _medir(png, preset, exigir))
    return resultado


def _medir(png: Path, preset: str, exigir: bool) -> int:
    if not png.exists():
        print(f"check_densidade: {png} nao existe — corre primeiro o `make captura`")
        return 2
    preset = preset or preset_do_bioma(png) or "open"
    medias = rampa(Image.open(png))
    falhas = veredito(medias, intervalos(preset))
    print(f"check_densidade: {png} (preset {preset})")
    _escrever(medias)
    for f in falhas:
        print(f"  {'CHUMBA' if exigir else 'fora da regra'}: {f}")
    if not falhas:
        print("  a rampa cumpre as duas pontas")
    return 1 if (exigir and falhas) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
