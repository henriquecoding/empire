"""A forma de um objeto observado contra o modelo nativo dele (FORJA-15, P0-02).

O envelope igual nao e o mesmo molde: dois frascos 13x20 podem ter bojos diferentes (auditoria de 29/10, caso A:
IoU 0,728 entre as mascaras visiveis). Aqui o objeto observado (as regioes `<item>.<parte>` de um `forja.observation/1`)
alinha-se ao modelo pelo melhor encaixe num deslocamento pequeno, com o espelho so quando a orientacao e uma variacao
declarada, e compara-se:

- o envelope (tamanho absoluto) contra o do modelo;
- linha a linha, a largura da silhueta e de cada parte (o bojo, o gargalo, o aro, a rolha), com 1 px de folga;
- a sobreposicao (IoU) do que se ve.

O que um oclusor declarado tapa (a mao no vidro) nao se compara: fica fora da conta, e se tapa demais a forma e
`inconclusive`, nunca `pass`. A cor nao entra (o liquido verde ou ambar e variacao permitida): mede-se so a forma das
regioes observadas. Contra um modelo `proposed`, o melhor resultado e `inconclusive`.
"""
from __future__ import annotations

from . import props

IOU_MIN = 0.85
ROW_TOL = 1
VISIBLE_MIN = 0.6


def _occluders(item: dict, obs: dict) -> frozenset:
    names = {o for spec in item["parts"].values() for o in spec["occluders"]}
    return frozenset().union(*[obs["regions"].get(n, frozenset()) for n in names]) if names else frozenset()


def _observed(item: dict, obs: dict) -> dict[str, frozenset]:
    return {p: obs["regions"][f"{item['id']}.{p}"] for p in item["parts"] if f"{item['id']}.{p}" in obs["regions"]}


def _bbox(cells) -> list[int]:
    return [min(x for x, _ in cells), min(y for _, y in cells), max(x for x, _ in cells) + 1,
            max(y for _, y in cells) + 1]


def measure(item: dict, obs: dict) -> dict:
    """O envelope do que se ve do objeto e se um oclusor o corta (a borda do envelope encosta a ele)."""
    seen = _observed(item, obs)
    cells = frozenset().union(*seen.values()) if seen else frozenset()
    if not cells:
        return {"envelope": None, "visible": 0}
    x0, y0, x1, y1 = _bbox(cells)
    hide = _occluders(item, obs)
    edge = {(x, y) for x in range(x0 - 1, x1 + 1) for y in (y0 - 1, y1)} | \
        {(x, y) for y in range(y0 - 1, y1 + 1) for x in (x0 - 1, x1)}
    return {"envelope": [x1 - x0, y1 - y0], "box": [x0, y0, x1, y1], "visible": len(cells),
            "cut_by_occluder": bool(edge & hide)}


def _rows(cells) -> dict[int, int]:
    out: dict[int, int] = {}
    for _, y in cells:
        out[y] = out.get(y, 0) + 1
    return out


def _fit(model: dict, seen: dict[str, frozenset], hide: frozenset, mirror: bool) -> dict:
    w, h = model["size"]
    every = frozenset().union(*seen.values())
    x0, y0, _, _ = _bbox(every)
    best = None
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            def at(p):
                x = w - 1 - p[0] if mirror else p[0]
                return x + x0 + dx, p[1] + y0 + dy
            mparts = {k: frozenset(at(p) for p in v) for k, v in model["parts"].items()}
            mall = frozenset().union(*mparts.values())
            shown = mall - hide
            iou = len(shown & every) / max(1, len(shown | every))
            if best is None or iou > best["iou"]:
                best = {"iou": iou, "parts": mparts, "all": mall, "shown": shown, "mirror": mirror, "offset": [dx, dy]}
    return best


def compare(model: dict, item: dict, obs: dict, allowed: list[str] | None = None) -> dict:
    """`pass`, `fail`, `inconclusive` ou `not_evaluated`, com as linhas e as partes que divergem."""
    seen, hide = _observed(item, obs), _occluders(item, obs)
    if not seen or not any(seen.values()):
        return {"status": "not_evaluated", "detail": "sem regioes observadas do objeto"}
    allowed = allowed or []
    fits = [_fit(model, seen, hide, False)] + ([_fit(model, seen, hide, True)] if "orientation" in allowed else [])
    fit = max(fits, key=lambda f: f["iou"])
    visible = len(fit["shown"]) / max(1, len(fit["all"]))
    every = frozenset().union(*seen.values())
    env = measure(item, obs)["envelope"]
    hidden_rows = {y for _, y in fit["all"] & hide}
    want, got = _rows(fit["shown"]), _rows(every)
    rows = [y for y in sorted(set(want) | set(got)) if y not in hidden_rows
            and abs(want.get(y, 0) - got.get(y, 0)) > ROW_TOL]
    parts = []
    for name, cells in fit["parts"].items():
        if name not in seen:
            continue
        mw, ow = _rows(cells - hide), _rows(seen[name])
        bad = [y for y in sorted(set(mw) | set(ow)) if y not in hidden_rows and abs(mw.get(y, 0) - ow.get(y, 0)) > ROW_TOL]
        span_m = (max(mw) - min(mw) + 1) if mw else 0
        span_o = (max(ow) - min(ow) + 1) if ow else 0
        if bad or abs(span_m - span_o) > ROW_TOL:
            parts.append(f"{name}: {span_o} linhas (modelo {span_m}), largura diverge em {len(bad)} linhas")
    reasons = ([f"envelope {env} e o modelo {model['size']}"] if env and env != list(model["size"]) and
               not hidden_rows else []) + ([f"silhueta diverge em {len(rows)} linhas (ex.: {rows[:4]})"] if rows else [])
    reasons += parts + ([f"IoU {fit['iou']:.3f} < {IOU_MIN}"] if fit["iou"] < IOU_MIN else [])
    evidence = {"iou": round(fit["iou"], 3), "mirrored": fit["mirror"], "offset": fit["offset"],
                "visible_share": round(visible, 3), "occluded_rows": sorted(hidden_rows), "rows": rows[:12],
                "model": model.get("id"), "model_status": model.get("status")}
    if visible < VISIBLE_MIN:
        return {"status": "inconclusive", "detail": f"so {visible:.0%} do modelo a vista: tapado, sem prova",
                "evidence": evidence}
    if reasons:
        return {"status": "fail", "detail": "; ".join(reasons), "evidence": evidence}
    if not model.get("approved"):
        return {"status": "inconclusive", "detail": "como o modelo proposto (nao aprovado pelo dono)",
                "evidence": evidence}
    return {"status": "pass", "detail": f"o mesmo molde (IoU {fit['iou']:.3f})", "evidence": evidence}


def check(item: dict, obs: dict, base=None) -> dict:
    """A verificacao `prop_shape` do geometry.evaluate para um objeto com `model` no manifesto."""
    model = props.load_model(item["model"], base)
    res = compare(model, item, obs, item.get("allowed_variations"))
    return {"axis": "equipment_geometry", "check": "prop_shape", "item": item["id"], "part": None,
            "status": res["status"], "detail": f"{item['id']}: {res['detail']}", "evidence": res.get("evidence", {})}
