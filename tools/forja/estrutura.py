"""A revisao estrutural de uma cena forjada contra o seu contrato (`forja.scene/1`, FORJA-11, FORJA-12).

O lint confere o raster (tela, alfa, paleta, contorno, cluster). Nao sabe se a casa flutua, se a porta fechou na
quantizacao, se o sinal que a identifica sumiu, se a faixa de terreno repete sem degrau ou se o estado `damaged`
mudou a fachada inteira. Cada verificacao diz o que mediu; o que nao se mediu fica `not_evaluated`, nunca `pass`, e
os eixos nao se somam (relatorio de 28/10, §26: uma nota global nao compensa uma porta bloqueada).

As caixas do contrato estao no referencial da extensao. Uma imagem com o tamanho da extensao (o `forge` com a tela e o
pivot da cena) le-se diretamente; noutro tamanho, alinha-se pela ancora: o centro da base com o centro da base.
Os vaos estao em `vaos.py`; as emendas e os estados em `emendas.py`.

O apoio e o da estrutura principal (a maior peca opaca ligada): um bloco solto que toca o chao nao segura uma casa
suspensa, e uma cabana sobre postes ligados ao corpo assenta mesmo com poucas colunas de contacto (auditoria, A2).
Igual ao mestre so passa quando o mestre e o aprovado no registo (`master_state`); igual a uma imagem qualquer prova
igualdade, nao autoridade.
"""
from __future__ import annotations

from PIL import Image

from . import contracts, lint, masks, regua, scene
from .emendas import continuity, joint, states as states_check
from .imageops import opaque_bbox
from .vaos import check, opening, place, shift

AXES = ("raster_contract", "structure", "identity_signals", "continuity", "states", "artistic_approval",
        "runtime_integration")
__all__ = ["AXES", "check", "joint", "review", "summarize"]


def _support(img: Image.Image) -> tuple[frozenset, int]:
    """A estrutura principal (a maior peca opaca ligada) e quantas outras pecas tocam o chao sozinhas."""
    a = img.getchannel("A").load()
    pieces = masks.components(frozenset((x, y) for y in range(img.height) for x in range(img.width)
                                        if a[x, y] >= 128))
    main = max(pieces, key=len)
    loose = sum(1 for p in pieces if p is not main and any(y == img.height - 1 for _, y in p))
    return main, loose


def _frame(img: Image.Image, res: dict) -> list[dict]:
    out, step = [], res["step"]
    w, h = res["extent_px"]
    same = img.size == (w, h)
    out.append(check("structure", "extent", "pass" if same else "fail",
                     f"{img.width}x{img.height} px" + ("" if same else f"; o contrato pede {w}x{h} (alinhado pela "
                                                                         "ancora)"), size=list(img.size)))
    off = [v for v in img.size if v % step]
    out.append(check("structure", "lattice", "fail" if off else "pass",
                     f"lados multiplos de {step} px" if not off else f"lado(s) {off} fora da grade de {step} px",
                     phase=res["lattice"]["phase"]))
    box = opaque_bbox(img)
    if box is None:
        return out + [check("structure", "base_contact", "fail", "imagem vazia")]
    if res["anchor"]["ground"] != "surface":
        out.append(check("structure", "base_contact", "not_evaluated", f"ancora {res['anchor']['ground']}: "
                         "sem linha de chao a conferir"))
        return out
    main, loose = _support(img)
    mb = masks.bbox(main)
    float_px = img.height - mb[3]
    row = sorted({x for x, y in main if y == img.height - 1})
    fill = round((box[2] - box[0]) / max(1, w), 2)
    detail = (f"pousa no chao em {len(row)} de {mb[2] - mb[0]} colunas" if not float_px else
              f"a estrutura principal flutua {float_px} px acima do chao" +
              (f"; {loose} peca(s) solta(s) tocam o chao sem a segurar" if loose else ""))
    out.append(check("structure", "base_contact", "fail" if float_px else "pass", detail, float_px=float_px,
                     contact_columns=len(row), loose_ground_fragments=loose, width_fill=fill))
    if fill < 0.75:
        out.append(check("structure", "fill", "inconclusive", f"o desenho ocupa {fill:.0%} da largura pedida: o "
                         "gerador desenhou mais pequeno? (rever a escala na montagem)", width_fill=fill))
    return out


def _signals(img: Image.Image, res: dict, offset, master: Image.Image | None, master_state: str | None) -> list[dict]:
    out = []
    regions = res["signal_regions"]
    for sid in res["signals"]:
        if sid not in regions:
            out.append(check("identity_signals", sid, "not_evaluated", f"{sid}: sem regiao marcada no contrato"))
            continue
        box = place(regions[sid], offset)
        crop = img.crop(tuple(box))
        cover = sum(crop.getchannel("A").histogram()[128:]) / max(1, crop.width * crop.height)
        if cover < 0.25:
            out.append(check("identity_signals", sid, "fail", f"{sid}: a regiao ficou quase vazia ({cover:.0%})",
                             box=box, coverage=round(cover, 2)))
            continue
        if master is None:
            out.append(check("identity_signals", sid, "inconclusive", f"{sid}: presente ({cover:.0%}); sem mestre, "
                             "a forma revê-se a olho", box=box, coverage=round(cover, 2)))
            continue
        ref = master.crop(tuple(place(regions[sid], shift(master, res))))
        a, b = crop.tobytes(), ref.tobytes()
        changed = sum(a[i:i + 4] != b[i:i + 4] for i in range(0, len(a), 4))
        approved = master_state == "approved"
        status = "fail" if changed else "pass" if approved else "inconclusive"
        detail = (f"{sid}: {changed} px diferentes do mestre" if changed else f"{sid}: igual ao mestre aprovado"
                  if approved else f"{sid}: igual a imagem dada, que nao e o mestre aprovado no registo "
                                   f"(estado: {master_state or 'sem registo'})")
        out.append(check("identity_signals", sid, status, detail, box=box, changed=changed,
                         master_state=master_state))
    return out


def summarize(checks: list[dict], raster_ok: bool | None) -> dict:
    v = {axis: "not_evaluated" for axis in AXES}
    v["artistic_approval"] = "pending"
    if raster_ok is not None:
        v["raster_contract"] = "pass" if raster_ok else "fail"
    for axis in AXES[1:5]:
        found = [c["status"] for c in checks if c["axis"] == axis]
        if found:
            v[axis] = next((s for s in ("fail", "inconclusive", "not_evaluated") if s in found), "pass")
    return v


def review(img: Image.Image, res: dict, master: Image.Image | None = None, neighbors: dict | None = None,
           states: dict | None = None, palette=None, master_state: str | None = None) -> dict:
    img = img.convert("RGBA")
    master = master.convert("RGBA") if master is not None else None
    states = {k: v.convert("RGBA") for k, v in (states or {}).items()}
    offset = shift(img, res)
    raster = lint.check(img, contracts.get(res["kind"]), palette, frame=False)
    checks = _frame(img, res) + [opening(img, o, offset, res["metrics"]) for o in res["openings"]]
    checks += _signals(img, res, offset, master, master_state) + continuity(img, res, neighbors or {})
    checks += states_check(img, res, states)
    v = summarize(checks, raster["ok"])
    profile = regua.data()["metrics_profile"]
    return {"verdicts": v, "blocking": [a for a, s in v.items() if s == "fail"], "checks": checks,
            "raster": {k: raster[k] for k in ("ok", "errors", "warnings", "prompt_feedback")},
            "placement": scene.place(res, img.size), "scene": res["id"],
            "profile": {"status": profile["status"], "decision": profile["decision"]}}
