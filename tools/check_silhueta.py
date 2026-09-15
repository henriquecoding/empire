#!/usr/bin/env python3
"""O teste das duas frias do §80, sobre uma captura real (XIII-01).

O §80 fecha a Q-037 com uma decisão — *a noite é castanha* — e escreve a regra
que ela abre:

> Com a noite castanha, o ecrã noturno tem exatamente duas cores que não são
> terra, e cada uma delas quer dizer uma coisa: violeta é A Podridão e só A
> Podridão; âmbar é luz, seja a candeia dela ou uma fogueira tua. Um jogador
> aprende isto em duas noites sem que ninguém lho diga, e a partir daí lê o
> ecrã inteiro de relance.

Uma regra assim não se guarda com uma revisão de código: guarda-se contando
píxeis. É a linha *Duas frias* da tabela da §80 §5, e é o que este script faz.

**Nenhum limiar está escrito aqui.** Os quatro números — os dois limites de
matiz, a saturação mínima e a percentagem de ecrã — são lidos dessa linha da
tabela, em `docs/design/80-*.md`, que é gerada do dossiê. Mudar o dossiê muda o
portão; e se a linha desaparecer ou mudar de forma, isto chumba a dizê-lo, em
vez de continuar a medir uma regra que já não existe. É a regra do `AGENTS.md`:
*não escrevas à mão um número que a ferramenta conta.*

O que este script NÃO faz, e porquê:

- *Teto de valores por camada* — precisa dos PNG de cada camada de parallax, e
  não há arte nenhuma (ART-03).
- *Rampa de densidade* — o greybox é de cores chapadas e chumbava por
  construção, e a regra é sobre a arte que vier depois (GB-03).
- *Leitura a 1 bit* — o próprio §80 escreve "manual, uma vez por ecrã acabado".
  A metade que se automatiza é outra, e está em `tests/outline_test.gd`: duas
  coisas com o mesmo contorno são uma só, e nenhum limiar as separa depois.

    python3 tools/check_silhueta.py build/noite.png
"""

from __future__ import annotations

import colorsys
import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SPEC = RAIZ / "docs" / "design" / "80-o-preto-entra-na-paleta-e-a-noite-deixa-de-ser-a.md"
LINHA = "| Duas frias |"

# A fase em que a regra vale. O §80 diz "à noite", e a noite é a última das seis
# do relógio (§05, §48) — lido do CSV, e não escrito aqui.
CLOCK = RAIZ / "data" / "source" / "clock.csv"
FASES = ["dawn", "morning", "noon", "afternoon", "dusk", "night"]

# A mancha é violeta de propósito, e o §80 diz "fora da mancha". A margem cobre
# a borda em que ela se mistura com o fundo por transparência.
MARGEM_PX = 2


def limiares() -> tuple[float, float, float, float]:
    """Os quatro números da linha *Duas frias* da tabela da §80 §5."""
    if not SPEC.exists():
        erro(f"não encontro a §80 em {SPEC.relative_to(RAIZ)}")
    linha = next((ln for ln in SPEC.read_text("utf-8").splitlines() if ln.startswith(LINHA)), None)
    if linha is None:
        erro(f"a §80 deixou de ter a linha '{LINHA}' — o portão mede uma regra que mudou")
    numeros = [float(n.replace(",", ".")) for n in re.findall(r"\d+(?:[.,]\d+)?", linha)]
    if len(numeros) != 4:
        erro(f"a linha das duas frias tem {len(numeros)} números e não 4: {linha.strip()}")
    matiz_min, matiz_max, saturacao, percentagem = numeros
    return matiz_min, matiz_max, saturacao, percentagem


def fase_da_noite() -> int:
    """O índice da noite nas seis fases do §05, contado do CSV."""
    cabecalho = CLOCK.read_text("utf-8").splitlines()[0].split(",")
    presentes = [f for f in FASES if f in cabecalho]
    if len(presentes) != len(FASES):
        erro(f"o clock.csv tem {len(presentes)} das seis fases do §05")
    return FASES.index("night")


def erro(mensagem: str) -> None:
    print(f"silhueta: {mensagem}", file=sys.stderr)
    raise SystemExit(1)


def frio(r: int, g: int, b: int, matiz_min: float, matiz_max: float, saturacao: float) -> bool:
    """Um píxel frio e saturado — o que, à noite, só pode ser A Podridão."""
    h, _, s = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    return matiz_min <= h * 360.0 <= matiz_max and s > saturacao


def dentro(x: int, y: int, caixas: list[list[float]]) -> bool:
    for cx, cy, cw, ch in caixas:
        esq, topo = cx - MARGEM_PX, cy - MARGEM_PX
        if esq <= x <= cx + cw + MARGEM_PX and topo <= y <= cy + ch + MARGEM_PX:
            return True
    return False


def main() -> int:
    if len(sys.argv) != 2:
        erro("uso: check_silhueta.py <captura.png>")
    png = Path(sys.argv[1])
    ficha_path = png.with_suffix(".json")
    if not png.exists():
        erro(f"não há captura em {png} — corre `make captura-noite` primeiro")
    if not ficha_path.exists():
        erro(f"a captura {png.name} não trouxe ficha ({ficha_path.name}): de que fase é?")

    try:
        from PIL import Image
    except ImportError:
        erro("falta o Pillow: python3 -m pip install -r tools/requirements.txt")

    ficha = json.loads(ficha_path.read_text("utf-8"))
    noite = fase_da_noite()
    if int(ficha.get("fase", -1)) != noite:
        erro(f"a captura é da fase {ficha.get('fase')} e a regra é da noite (fase {noite})")

    matiz_min, matiz_max, saturacao, percentagem = limiares()
    caixas = [c for c in ficha.get("mancha", [])]
    imagem = Image.open(png).convert("RGB")
    largura, altura = imagem.size
    pixeis = imagem.load()

    frias = 0
    na_mancha = 0
    cores = set()
    for y in range(altura):
        for x in range(largura):
            cor = pixeis[x, y]
            cores.add(cor)
            if not frio(*cor, matiz_min, matiz_max, saturacao):
                continue
            if dentro(x, y, caixas):
                na_mancha += 1
            else:
                frias += 1

    # O modo de falhar que este portão tinha e não via: uma captura preta — o
    # xvfb que não arrancou, o motor que não desenhou — não tem um único píxel
    # frio, e passava a dizer que a regra estava cumprida. Um ecrã de uma cor só
    # não é um ecrã, e a contagem de cores distintas não precisa de limiar
    # nenhum para o dizer.
    if len(cores) <= 1:
        erro(f"a captura {png.name} tem uma cor só — não desenhou nada, e um ecrã vazio não passa")

    total = largura * altura
    parte = 100.0 * frias / total
    regra = (
        f"§80: matiz {matiz_min:.0f}°–{matiz_max:.0f}° com saturação > {saturacao}, "
        f"fora da mancha, à noite, não passa de {percentagem}% do ecrã"
    )
    print(regra)
    print(
        f"silhueta: {largura}x{altura}, dia {ficha.get('dia')}, {len(cores)} cores, "
        f"{frias} frias fora da mancha ({parte:.3f}%), {na_mancha} dentro dela"
    )
    if parte > percentagem:
        print(
            f"silhueta: CHUMBA — {parte:.3f}% do ecrã é frio e saturado fora da mancha.\n"
            "  A noite é castanha (ADR 0011): o que fica frio e saturado à noite só pode "
            "ser A Podridão, senão as duas coisas fundem-se e o ecrã deixa de se ler.",
            file=sys.stderr,
        )
        return 1
    print("silhueta: as duas frias passam")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
