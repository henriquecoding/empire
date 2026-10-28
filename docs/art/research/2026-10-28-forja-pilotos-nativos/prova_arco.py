"""Prova do arco do arqueiro de tropa: a observacao sai da revisao visual do candidato e a geometria mede-a.

A revisao (revisoes/arqueiro_tropa-candidato.json) diz onde estao os membros, a corda, a pega e os entalhes; aqui
juntam-se as maos que o manifesto nomeia e o forja equip julga: uma corda, fina, reta, ligada a madeira nas duas
pontas, pega entre elas e a mao da frente nela. Grava equip/observacao.json e equip/veredito.json.
Uso: python3 prova_arco.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[3]))

from tools.forja import equipment, geometry, visual_review as vr  # noqa: E402
from tools.forja.imageops import open_rgba  # noqa: E402

SKIN = ["#FCB275", "#F89861", "#F3814E", "#D47044"]
HANDS = {"hand_front": [43, 42, 52, 50], "hand_rear": [26, 40, 35, 49]}


def main() -> bool:
    image = open_rgba(HERE / "candidatos" / "arqueiro_tropa.png")
    obs = vr.observation(vr.load(HERE / "revisoes" / "arqueiro_tropa-candidato.json"))
    obs["regions"].update({k: {"box": b, "colors": SKIN, "uncertainty": "baixa"} for k, b in HANDS.items()})
    (HERE / "equip" / "observacao.json").write_text(json.dumps(obs, indent=1, ensure_ascii=False) + "\n",
                                                    encoding="utf-8")
    result = geometry.review(equipment.load(HERE / "equip" / "manifesto.json"), equipment.observe(image, obs))
    out = {"image_sha256": obs["image_sha256"], "summary": result["summary"], "blocking": result["blocking"],
           "checks": [{k: c[k] for k in ("check", "part", "status", "detail")} for c in result["checks"]],
           "note": "geometria medida sobre a observacao do agente; a aprovacao da arma continua a ser do dono"}
    (HERE / "equip" / "veredito.json").write_text(json.dumps(out, indent=1, ensure_ascii=False) + "\n",
                                                  encoding="utf-8")
    return not result["blocking"]


if __name__ == "__main__":
    ok = main()
    print(json.dumps({"ok": ok}))
    sys.exit(0 if ok else 1)
