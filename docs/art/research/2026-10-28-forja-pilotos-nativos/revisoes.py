"""As revisoes visuais (forja.visual_review/1) dos pilotos: o que o agente viu, escrito a mao aqui, por imagem exata.

As caixas foram marcadas olhando a recuperacao na grade da prancha (coordenadas A) e conferidas nas imagens marcadas
(forja visual --marks-out). Este script so converte A para o recorte de autoridade (fase reference) e para a tela
final (fase candidate) e poe o hash dos pixels; nao decide nada. Uma imagem que mude invalida a revisao (hash).
Uso: python3 revisoes.py [--contrato]  (com --contrato liga as revisoes, os pinos e o candidato ao contrato)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[3]))
sys.path.insert(0, str(HERE))

import pilotos  # noqa: E402
from tools.forja import fidelity, visual_review as vr  # noqa: E402
from tools.forja.equipment import image_sha  # noqa: E402
from tools.forja.imageops import open_rgba  # noqa: E402

WHO = {"author": "Claude (agente)", "model": "claude-opus-5-5", "date": "2026-10-28",
       "method": "inspecao visual a 1x e ampliada (6-10x) ao lado do recorte de autoridade; caixas conferidas na imagem "
                 "marcada; geometria do arco medida a parte pelo forja equip"}
GRID = {"rei": (0, 0, 6.037, 3, 1), "escudeiro": (3, 1, 6.476, 1, 2), "arqueiro_tropa": (2, 2, 6.245, 2, 1)}
REGIONS = {  # caixas em coordenadas A (a recuperacao antes de qualquer patch)
    "rei": {"crown": [29, 0, 50, 11], "face_system": [42, 8, 62, 28], "eye_lid_pupil": [47, 12, 52, 18],
            "grin_teeth": [44, 18, 58, 23], "hair_sideburns": [20, 8, 44, 30], "chest_emblem": [53, 32, 66, 46],
            "sword": [9, 50, 38, 74], "hand_sword": [10, 50, 22, 60], "hand_right": [69, 44, 80, 54],
            "cape_back": [0, 26, 16, 70], "belt_buckle": [27, 46, 70, 56]},
    "escudeiro": {"helmet": [8, 0, 40, 18], "face_anxious": [21, 8, 38, 23], "eye": [26, 9, 31, 15],
                  "mouth": [27, 15, 33, 19], "shield": [32, 12, 49, 47], "shield_blue_core": [37, 16, 46, 44],
                  "hand_on_shield": [25, 22, 35, 31], "sleeves": [9, 17, 26, 34]},
    "arqueiro_tropa": {"hood": [8, 0, 37, 31], "face": [16, 5, 37, 24], "eye": [27, 9, 31, 14],
                       "mouth": [27, 16, 32, 19], "quiver": [1, 9, 15, 31], "hand_rear": [17, 41, 28, 49],
                       "hand_front": [34, 43, 43, 50], "front_bracer": [31, 36, 39, 45]}}


def to_crop(ident: str, b: list[int]) -> list[int]:
    x0, y0, p, ox, oy = GRID[ident]
    return [round(x0 + (b[0] + ox) * p), round(y0 + (b[1] + oy) * p), round(x0 + (b[2] + ox) * p),
            round(y0 + (b[3] + oy) * p)]


def _row(ident: str, y: int) -> int:
    if ident == "rei":
        return y + 2
    if ident == "escudeiro":
        return y + 15
    return y + (2 if y < 3 else 1 if y < 30 else 0 if y < 52 else -1)


def to_canvas(ident: str, b: list[int]) -> list[int]:
    dx = {"rei": -4, "escudeiro": 8, "arqueiro_tropa": 9}[ident]
    return [b[0] + dx, _row(ident, b[1]), b[2] + dx, _row(ident, b[3] - 1) + 1]


def base(ident: str, phase: str, image, ch: dict) -> dict:
    return {"schema": vr.SCHEMA, "phase": phase, "image": {"sha256": image_sha(image), "size": list(image.size)},
            "subject": {"character": ident, "pose": ch["pose"], "declared_role": ch["role"],
                        "target_canvas": ch["target_canvas"], "declared_by": "Henrique"},
            "observer": WHO, "regions": {}, "anchors": {}, "findings": [], "invariant_checks": [],
            "repair_claims": []}


def _region(ident, phase, box, state="observed", **extra) -> dict:
    conv = to_crop if phase == "reference" else to_canvas
    return {"box": conv(ident, box), "state": state, **extra}


def _finding(ident, phase, fid, box, category, certainty, evidence, description, action, **extra) -> dict:
    conv = to_crop if phase == "reference" else to_canvas
    return {"id": fid, "category": category, "box": conv(ident, box), "state": "observed", "certainty": certainty,
            "evidence": evidence, "description": description, "action": action, **extra}


EVIDENCE = {  # fase candidate: o que se ve no candidato, invariante a invariante, pela ordem do contrato
    "rei": ["mesma silhueta e relacao cabeca-tronco da prancha: os pixels sao os da grade dela; so o contorno de tras "
            "da capa entrou 4 px", "palpebra, pupila de 1 px, sobrancelha e o sorriso torto com os dentes como no "
            "recorte; nenhum pixel do rosto foi editado", "nariz em laranja de pele, da mesma familia da bochecha",
            "vinho, azul-marinho e creme em tons proprios (a paleta de trabalho trocava-os); a capa ficou 4 px mais "
            "estreita atras do braco", "losango dourado no peito e coroa de tres pontas legiveis a 1x",
            "uma espada baixa na mao esquerda, lamina para baixo, como na prancha"],
    "escudeiro": ["olho arregalado, sobrancelha e boca aberta de lado como no recorte; rosto sem edicao",
                  "aba do elmo cinza por cima do olho, na mesma distancia", "escudo de madeira com miolo azul a frente "
                  "do corpo, com o contorno do topo fechado (2 px)", "tecido vinho e creme em tons proprios; mangas "
                  "com dobras", "mesma pose, sem espada nem gesto novo"],
    "arqueiro_tropa": ["capuz verde e tunica creme da prancha", "olho de lado, sobrancelha franzida e boca entreaberta "
                       "sem edicao", "arco baixo a frente, pega na mao da frente e ponta de baixo junto a mao de tras",
                       "corpo compacto; tres linhas tiradas (copa do capuz, tronco e calcas) para 61 linhas uteis",
                       "nao ha tunica verde comprida, sorriso, mao na cintura nem arco vertical"]}


def reviews(ident: str) -> dict:
    contract = fidelity.load(pilotos.CONTRACT)
    ch = fidelity.character(contract, ident)
    crop = fidelity.authority_crop(contract, ch).convert("RGBA")
    cand = open_rgba(HERE / "candidatos" / f"{ident}.png")
    out = {}
    for phase, image in (("reference", crop), ("candidate", cand)):
        rev = base(ident, phase, image, ch)
        rev["regions"] = {k: _region(ident, phase, b) for k, b in REGIONS[ident].items()}
        if ident == "rei":
            rev["findings"].append(_finding(ident, phase, "pupila_e_dentes", [47, 12, 58, 23], "detail_preserved",
                                            "certain", "pupila de 1 px e dentes claros no sorriso",
                                            "detalhes de 1 px com funcao; nao sao ruido", "keep"))
        if ident == "arqueiro_tropa" and phase == "reference":
            rev["regions"]["bow_main.limb_upper"] = _region(ident, phase, [41, 23, 54, 47])
            rev["regions"]["bow_main.string_visible"] = _region(ident, phase, [37, 27, 50, 36])
            rev["regions"]["bow_main.string_hidden"] = _region(ident, phase, [24, 34, 38, 46], "occluded",
                                                               occluded_by="front_bracer",
                                                               note="a corda some atras da manga e do tronco")
            rev["findings"] += [
                _finding(ident, phase, "lasca_cinzenta", [29, 40, 34, 47], "unidentified_fragment", "certain",
                         "linha cinzenta de 1 px com contorno preto dos dois lados entre a tunica e a bracadeira da "
                         "frente; nao continua nenhum membro, nao tem haste nem ponta (nao e flecha); a cor e a do "
                         "fundo da prancha", "fragmento sem funcao entre as maos", "repair",
                         reference_issue="bow_unidentified_fragment"),
                _finding(ident, phase, "entalhe_de_cima_no_vazio", [46, 26, 51, 31], "equipment_defect", "certain",
                         "o pixel de cima da corda toca o contorno do membro, nao a madeira",
                         "a corda nao chega a madeira na ponta de cima", "repair", reference_issue="bow_connections"),
                _finding(ident, phase, "corda_atras_do_corpo", [24, 27, 50, 47], "equipment_defect", "certain",
                         "a corda desce da ponta de cima e desaparece na manga; a ponta de baixo nao tem corda visivel",
                         "Henrique, 28/10: a corda esta atras do personagem e a arma mal feita", "repair",
                         reference_issue="bow_string_behind_body")]
        if phase == "candidate":
            rev["invariant_checks"] = [{"invariant": inv, "status": "preserved", "evidence": ev}
                                       for inv, ev in zip(ch["required_invariants"], EVIDENCE[ident])]
        if ident == "rei" and phase == "candidate":
            rev["regions"]["cape_back"]["box"] = [0, 28, 12, 72]  # o contorno entrou: no candidato comeca em x=0
            rev["findings"].append(_finding(ident, phase, "capa_recolhida", [4, 38, 16, 70], "other", "certain",
                                            "o contorno de tras da capa esta ate 4 px mais perto do braco que na "
                                            "prancha", "decisao de orcamento da tela (Q-292), a confirmar", "ask_owner"))
        if ident == "arqueiro_tropa" and phase == "candidate":
            rev["regions"].update({
                "bow_main.limb": {"box": [34, 24, 62, 49], "state": "observed",
                                  "colors": ["#9A5324", "#A55926", "#B15B26", "#8A4821", "#47200D", "#7A3F1D",
                                             "#703A1A", "#64341A"], "exclude": {"box": [22, 24, 50, 45]},
                                  "note": "os dois membros: o de cima ate a ponta e o de baixo da mao da frente a de tras"},
                "bow_main.string": {"box": [33, 27, 59, 45], "state": "observed", "colors": ["#F2EADD", "#878171"],
                                    "note": "uma corda reta, clara sobre o fundo e a bracadeira, media sobre o creme"},
                "bow_main.grip": {"box": [43, 43, 50, 49], "state": "inferred", "uncertainty": "media",
                                  "note": "a pega esta debaixo da mao da frente; inferida pelos dois membros"}})
            rev["anchors"] = {"bow_main.nock_top": {"point": [58, 28], "state": "observed"},
                              "bow_main.nock_bottom": {"point": [34, 44], "state": "observed"}}
            rev["repair_claims"] = [
                {"issue": "bow_unidentified_fragment", "status": "fixed", "certainty": "certain", "box": [37, 41, 43, 47],
                 "evidence": "entre a tunica e a bracadeira so ha creme da tunica e o contorno da bracadeira; nenhum cinzento"},
                {"issue": "bow_connections", "status": "fixed", "certainty": "certain", "box": [33, 26, 61, 47],
                 "evidence": "a corda toca a madeira em (59,28) e na ponta de baixo em (35,45); forja equip mede bow_nocks"},
                {"issue": "bow_string_behind_body", "status": "fixed", "certainty": "certain", "box": [33, 27, 59, 45],
                 "evidence": "a corda e uma linha reta continua de entalhe a entalhe, desenhada por cima da bracadeira e "
                             "da tunica; nada a esconde"}]
            rev["findings"].append(_finding(ident, phase, "corda_em_fundo_claro", [37, 27, 50, 36], "other", "certain",
                                            "a parte clara da corda quase desaparece num fundo claro",
                                            "linha de 1 px sem contorno: ler em cena", "ask_owner"))
        out[phase] = rev
    return out


def main() -> bool:
    contract = fidelity.load(pilotos.CONTRACT)
    ok = True
    for ident in pilotos.CAST:
        ch = fidelity.character(contract, ident)
        for phase, rev in reviews(ident).items():
            name = "referencia" if phase == "reference" else "candidato"
            path = HERE / "revisoes" / f"{ident}-{name}.json"
            path.write_text(json.dumps(rev, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
            image = (fidelity.authority_crop(contract, ch).convert("RGBA") if phase == "reference"
                     else open_rgba(HERE / "candidatos" / f"{ident}.png"))
            st = vr.state(rev, image, ch)
            ok = ok and st["status"] in ("pass", "pending")
            print(ident, phase, st["status"], st.get("errors") or st["blocking"] or st["uncertain"])
    return ok




PINS = {  # detalhes de 1 px com funcao, no PNG final: a cor tem de ficar
    "rei": [("pupila", [42, 17], "#000000"), ("branco_do_olho", [40, 17], "#F8F7F6"), ("dente", [43, 22], "#F8F7F6")],
    "escudeiro": [("pupila", [39, 28], "#000000"), ("branco_do_olho", [38, 28], "#FAF8F9"),
                  ("boca_aberta", [39, 33], "#FAF8F9")],
    "arqueiro_tropa": [("pupila", [38, 13], "#000000"), ("branco_do_olho", [37, 13], "#FDFBF9"),
                       ("sobrancelha", [36, 11], "#47200D"), ("boca_entreaberta", [37, 19], "#FDFBF9")]}
TARGETS = {  # regioes criticas do contrato: caixa em A
    "rei": {"face_system": [42, 8, 62, 28], "chest_emblem": [53, 32, 66, 46], "material_planes": [4, 26, 81, 70]},
    "escudeiro": {"helmet_face": [8, 0, 40, 23], "shield_hands": [25, 12, 49, 47], "material_planes": [4, 13, 34, 40]},
    "arqueiro_tropa": {"hood_face": [8, 0, 37, 31], "bow_hands_string": [15, 23, 54, 50],
                       "cream_clothing": [8, 22, 36, 50]}}


def update_contract() -> None:
    """Liga as revisoes e o candidato ao contrato de fidelidade: so dados observados, nunca aprovacao."""
    path = pilotos.CONTRACT
    data = json.loads(path.read_text(encoding="utf-8"))
    rel = "../2026-10-28-forja-pilotos-nativos"
    for ch in data["characters"]:
        ident = ch["id"]
        if ident not in pilotos.CAST:
            continue
        x0, y0 = ch["authority_crop_xyxy"][:2]
        for r in ch["critical_regions"]:
            b = TARGETS[ident][r["id"]]
            crop = to_crop(ident, b)
            r.update(authority_box=[crop[0] + x0, crop[1] + y0, crop[2] + x0, crop[3] + y0],
                     target_box=to_canvas(ident, b), status="annotated_on_candidate")
        if ident == "rei":
            ch["critical_regions"][-1]["target_box"][0] = 0
        ch["pixel_pins"] = [{"id": n, "target_pixel": xy, "color": c, "status": "authorized", "role": "face",
                             "source_annotation": "Claude (agente), 2026-10-28, no candidato em revisao"}
                            for n, xy, c in PINS[ident]]
        ch["visual_review"] = {"reference": f"{rel}/revisoes/{ident}-referencia.json",
                               "candidate": f"{rel}/revisoes/{ident}-candidato.json"}
        cand = open_rgba(HERE / "candidatos" / f"{ident}.png")
        ch["replacement_candidate"] = {"file": f"{rel}/candidatos/{ident}.png", "pixels_sha256": image_sha(cand),
                                       "status": "in_review", "date": "2026-10-28",
                                       "authoring": "grade da prancha recuperada + patches nativos; nao gerado"}
        rev = vr.load(HERE / "revisoes" / f"{ident}-candidato.json")
        keep = [r for r in ch.get("reference_issue_reviews", []) if r.get("source") != vr.SCHEMA]
        ch["reference_issue_reviews"] = keep + vr.issue_reviews(rev)
    path.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    valid = main()
    if "--contrato" in sys.argv:
        update_contract()
    sys.exit(0 if valid else 1)
