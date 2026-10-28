"""Propor o patch 04 do arqueiro de tropa: o arco redesenhado, autorizado por Henrique a 28/10.

Pedido do dono: "A corda esta atras do personagem, a arma esta mal feita". Na prancha a corda sai da ponta de cima
e some atras da manga; o membro de baixo acaba na mao de tras; entre as maos ha um segmento cinzento sem funcao.
O reparo, so na arma (rosto, capuz, roupa, maos e gesto ficam):
- a lasca cinzenta sai e a tunica continua ate ao contorno da bracadeira;
- a ponta de cima entra 1 px (margem da tela) e a corda velha, que acabava no vazio, sai;
- a corda nova e uma linha reta em degraus 2-1, do entalhe de cima (na madeira) ao entalhe de baixo (a ponta junto
  a mao de tras), A FRENTE do corpo: clara sobre o fundo e a bracadeira, num tom medio sobre o creme da tunica.
Uso: python3 propor_arco.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[3]))
sys.path.insert(0, str(HERE))

import pilotos  # noqa: E402
from propor_orcamento import patch  # noqa: E402
from tools.forja import color, fidelity  # noqa: E402

OLD_STRING = ("#F2EADD", "#FAF3E8", "#FDFBF9")
STRING, STRING_ON_CREAM = "#F2EADD", "#878171"
CREAM, CREAM_SHADE, OUTLINE = "#F9E8C3", "#E0C59C", "#000000"
TOP, BOTTOM = (49, 29), (25, 45)  # entalhes: a corda toca a madeira em (50,29) e em (26,46)
FRAGMENT = {(28, 42): CREAM, (29, 42): CREAM, (30, 42): CREAM_SHADE, (29, 43): CREAM, (30, 43): CREAM_SHADE,
            (29, 44): CREAM, (30, 44): CREAM, (31, 44): CREAM_SHADE, (30, 45): CREAM, (31, 45): CREAM_SHADE,
            (32, 46): OUTLINE,
            (35, 37): CREAM}  # brilho da manga no tom da corda, encostado a ela: engrossava-a (forja equip, string_line)


def line(a, b) -> list[tuple[int, int]]:
    """Degraus regulares: 24 para o lado e 16 para baixo dao o padrao 2-1, sem dentes."""
    (x0, y0), (x1, y1) = a, b
    n = abs(x1 - x0)
    return [(x0 - i if x1 < x0 else x0 + i, y0 + round(i * (y1 - y0) / n)) for i in range(n + 1)]


def main() -> None:
    contract = fidelity.load(pilotos.CONTRACT)
    image, _ = pilotos.stages(contract, "arqueiro_tropa", upto="04")
    px = image.load()
    clear = [[x, y, "transparent"] for y in range(26, 37) for x in range(35, 50)
             if px[x, y][3] and color.to_hex(px[x, y][:3]) in OLD_STRING]
    string = []
    for x, y in line(TOP, BOTTOM):
        under = color.to_hex(px[x, y][:3]) if px[x, y][3] else None
        cream = under in (CREAM, CREAM_SHADE, "#F4DEB6", "#E9D2AA", "#D7BA8E") or (x, y) in FRAGMENT
        string.append([x, y, STRING_ON_CREAM if cream else STRING])
    ops = [{"op": "paint", "pixels": clear},
           {"op": "paint", "pixels": [[x, y, c] for (x, y), c in sorted(FRAGMENT.items())]},
           {"op": "move", "box": [49, 25, 54, 32], "select": "opaque", "to": [-1, 0]},
           {"op": "paint", "pixels": string}]
    out = patch(image, ops, [[24, 24, 54, 50]], "reparo autorizado por Henrique (28/10: 'a corda esta atras do "
                "personagem, a arma esta mal feita'): lasca cinzenta fora, ponta de cima 1 px para dentro, corda reta "
                "de entalhe a entalhe a frente do corpo")
    out["authorized_by"] = "Henrique, 2026-10-28"
    (HERE / "patches/arqueiro_tropa/04-arco.json").write_text(json.dumps(out, indent=1) + "\n", encoding="utf-8")
    print(len(clear), "pixels da corda velha;", len(string), "da corda nova")


if __name__ == "__main__":
    main()
