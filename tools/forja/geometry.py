"""A geometria do equipamento: a intencao do manifesto contra as regioes observadas numa imagem (FORJA-03).

Nao e um detector de objetos. Trabalha sobre regioes e ancoras que alguem marcou (equipment.observe) e
mede o que se mede em pixels nativos:
- partes: quantas instancias de cada parte ha (uma oclusao declarada liga as pecas que tapa);
- lamina reta: um so tracado por linha de varrimento entre base e ponta (sem bifurcacao), perto do eixo;
- corda: no maximo a largura pedida, perto da reta entre as pontas, ligada as duas e sem segunda corda;
- guarda: encostada a lamina e a empunhadura (guarda e pomo sao partes diferentes, nao duplicacao);
- contactos (pose funcional): a parte e a regiao do corpo encostadas.
A escada normal de uma diagonal raster nao e curvatura; a curva da madeira do arco nao se mede; uma
parte tapada declarada da `inconclusive` e nunca `pass`. Sem regiao nem ancora: `not_evaluated`.
"""
from __future__ import annotations

from . import equipment, masks, verdicts


def _check(axis: str, name: str, item: str, status: str, detail: str, part: str | None = None, **evidence) -> dict:
    return {"axis": axis, "check": name, "item": item, "part": part, "status": status, "detail": detail,
            "evidence": evidence}


def _near(a, b) -> bool:
    d = masks.distance(a, b)
    return d is not None and d <= 1


def _through(item: dict, part: str, obs: dict):
    names = item["parts"][part]["occluders"] + item["parts"][part]["joins"]
    return frozenset().union(*[obs["regions"].get(n, frozenset()) for n in names]) if names else frozenset()


def _settle(check: dict, names: list[str], obs: dict) -> dict:
    """Uma regiao marcada com incerteza alta nao deixa uma verificacao passar."""
    doubtful = [n for n in names if n in obs["uncertain"]]
    if check["status"] == "pass" and doubtful:
        check["status"] = "inconclusive"
        check["detail"] += f" (observacao incerta: {', '.join(doubtful)})"
    return check


def _parts(item: dict, obs: dict) -> list[dict]:
    out, seen = [], 0
    for part, spec in item["parts"].items():
        name = f"{item['id']}.{part}"
        if spec["hidden"]:
            out.append(_check("equipment_geometry", "part_count", item["id"], "not_applicable",
                              f"{name}: oculta nesta vista (declarado)", part))
            continue
        region = obs["regions"].get(name)
        if region is None:
            out.append(_check("equipment_geometry", "part_count", item["id"], "not_evaluated",
                              f"{name}: sem observacao", part))
            continue
        seen += 1
        comps = masks.components(region, _through(item, part, obs))
        n, want = len(comps), spec["count"]
        boxes = [masks.bbox(c) for c in comps]
        if n == want:
            status, detail = "pass", f"{name}: {n} de {want}"
        elif n == 0 and (spec["optional"] or not item["required"]):
            status, detail = "pass", f"{name}: ausente, e opcional"
        elif n == 0 and spec["occluders"]:
            status, detail = "inconclusive", f"{name}: nao visivel; pode estar tapada por {', '.join(spec['occluders'])}"
        elif n == 0:
            status, detail = "fail", f"{name}: ausente (o manifesto pede {want})"
        else:
            status = "fail"
            detail = f"{name}: {n} instancias, o manifesto pede {want}" + (" (duplicada ou partida)" if n > want else "")
        out.append(_settle(_check("equipment_geometry", "part_count", item["id"], status, detail, part,
                                  found=n, wanted=want, boxes=boxes), [name], obs))
    observed = [obs["regions"][f"{item['id']}.{p}"] for p in item["parts"] if f"{item['id']}.{p}" in obs["regions"]]
    hideable = all(s["occluders"] or s["optional"] or s["hidden"] for s in item["parts"].values())
    if seen and item["required"] and not any(observed) and not hideable:
        out.append(_check("equipment_geometry", "item_present", item["id"], "fail",
                          f"{item['id']}: o manifesto pede este objeto e nenhuma parte foi encontrada"))
    return out


def scan(region, a: tuple[int, int], b: tuple[int, int]) -> list[tuple[int, float, list[list[int]]]]:
    """Linhas de varrimento ao longo do eixo a->b: (coordenada maior, menor ideal, tracados [ini, fim])."""
    steep = abs(b[1] - a[1]) >= abs(b[0] - a[0])
    (ma, na), (mb, nb) = ((a[1], a[0]), (b[1], b[0])) if steep else (a, b)
    lo, hi = min(ma, mb), max(ma, mb)
    rows: dict[int, list[int]] = {}
    for x, y in region:
        m, n = (y, x) if steep else (x, y)
        if lo <= m <= hi:
            rows.setdefault(m, []).append(n)
    out = []
    for m in range(lo, hi + 1):
        ideal = na + (nb - na) * (m - ma) / (mb - ma) if mb != ma else float(na)
        runs: list[list[int]] = []
        for n in sorted(rows.get(m, [])):
            if runs and n == runs[-1][1] + 1:
                runs[-1][1] = n
            else:
                runs.append([n, n])
        out.append((m, ideal, runs))
    return out


def _point(m: int, n: float, a, b) -> tuple[int, int]:
    steep = abs(b[1] - a[1]) >= abs(b[0] - a[0])
    return (round(n), m) if steep else (m, round(n))


def _gaps(lines, through, a, b) -> list[int]:
    near = masks.dilate(through, 1) if through else frozenset()
    return [m for m, n, runs in lines if not runs and _point(m, n, a, b) not in near]


def _axis(item: dict, obs: dict) -> dict:
    iid, part = item["id"], item["axis"]
    region = obs["regions"].get(f"{iid}.{part}")
    a, b = (obs["anchors"].get(f"{iid}.{k}") for k in item["anchors"])
    if region is None or a is None or b is None:
        return _check("equipment_geometry", "blade_axis", iid, "not_evaluated",
                      f"{iid}: falta a regiao da lamina ou as ancoras base/ponta", part)
    if not region:
        return _check("equipment_geometry", "blade_axis", iid, "not_evaluated", f"{iid}: sem lamina para medir", part)
    lines = scan(region, a, b)
    forks = [m for m, _, runs in lines if len(runs) > 1]
    centers = [abs((r[0] + r[1]) / 2 - n) for _, n, runs in lines for r in runs]
    deviation = round(max(centers, default=0.0), 2)
    gaps = _gaps(lines, _through(item, part, obs), a, b)
    reasons = ([f"bifurcada em {len(forks)} linhas (ex.: {forks[:3]})"] if forks else []) + \
        ([f"desvio de {deviation} px do eixo base-ponta"] if deviation > item["tolerance"] else []) + \
        ([f"interrompida em {len(gaps)} linhas sem oclusor (ex.: {gaps[:3]})"] if gaps else [])
    status = "fail" if reasons else "pass"
    detail = f"{iid}: " + ("; ".join(reasons) if reasons else "um tracado continuo, perto do eixo")
    return _settle(_check("equipment_geometry", "blade_axis", iid, status, detail, part, forks=forks[:12],
                          max_deviation=deviation, gaps=gaps[:12], base=list(a), tip=list(b)),
                   [f"{iid}.{part}"], obs)


def _line(item: dict, obs: dict) -> dict:
    iid, part = item["id"], item["line"]
    if item["state"] not in equipment.STRAIGHT:
        return _check("equipment_geometry", "string_line", iid, "not_evaluated",
                      f"{iid}: estado {item['state']}; a corda puxada (dois segmentos) ainda nao se mede", part)
    region = obs["regions"].get(f"{iid}.{part}")
    a, b = (obs["anchors"].get(f"{iid}.{k}") for k in item["anchors"])
    if region is None or a is None or b is None:
        return _check("equipment_geometry", "string_line", iid, "not_evaluated",
                      f"{iid}: falta a regiao da corda ou as ancoras das pontas", part)
    through = _through(item, part, obs)
    lines = scan(region, a, b)
    widths = {m: sum(r[1] - r[0] + 1 for r in runs) for m, _, runs in lines}
    width = max(widths.values(), default=0)
    limit = item["parts"][part]["max_width"] or 1
    wide = [m for m, w in widths.items() if w > limit]
    deviation = round(max((abs(v - n) for _, n, runs in lines for r in runs for v in range(r[0], r[1] + 1)),
                          default=0.0), 2)
    gaps = _gaps(lines, through, a, b)
    pieces = len(masks.components(region, through))
    loose = [k for k, p in zip(item["anchors"], (a, b)) if not _near(region, {p})]
    reasons = ([f"largura {width} px em {len(wide)} linhas (maximo {limit}; ex.: {wide[:3]})"] if wide else []) + \
        ([f"afasta-se {deviation} px da reta entre as pontas"] if deviation > item["tolerance"] else []) + \
        ([f"interrompida em {len(gaps)} linhas sem oclusor"] if gaps else []) + \
        ([f"{pieces} pecas (segunda corda ou troco solto)"] if pieces > 1 else []) + \
        ([f"nao chega a {', '.join(loose)}"] if loose else [])
    status = "fail" if reasons or not region else "pass"
    detail = f"{iid}: " + ("; ".join(reasons) if reasons else
                           "sem corda observada" if not region else "fina, reta entre as pontas e ligada a elas")
    return _settle(_check("equipment_geometry", "string_line", iid, status, detail, part, max_width=width,
                          wide_lines=wide[:12], max_deviation=deviation, gaps=gaps[:12], pieces=pieces,
                          ends=[list(a), list(b)]), [f"{iid}.{part}"], obs)


def _guard(item: dict, obs: dict) -> dict:
    iid = item["id"]
    guard, blade, grip = (obs["regions"].get(f"{iid}.{p}") for p in ("guard", "blade", "grip"))
    if guard is None or blade is None or grip is None or not guard:
        return _check("equipment_geometry", "guard_seat", iid, "not_evaluated",
                      f"{iid}: falta observar guarda, lamina ou empunhadura", "guard")
    hand = _through(item, "grip", obs)
    loose = [masks.bbox(c) for c in masks.components(guard)
             if not _near(c, blade) or not _near(c, grip | hand)]
    status = "fail" if loose else "pass"
    detail = f"{iid}: " + (f"{len(loose)} guarda(s) fora do sitio entre lamina e empunhadura: {loose}" if loose
                           else "a guarda assenta entre a lamina e a empunhadura")
    return _settle(_check("equipment_geometry", "guard_seat", iid, status, detail, "guard", loose=loose),
                   [f"{iid}.guard"], obs)


def _contacts(item: dict, obs: dict) -> list[dict]:
    out = []
    for c in item["contacts"]:
        part, body = c["part"], c["body"]
        pr, br = obs["regions"].get(f"{item['id']}.{part}"), obs["regions"].get(body)
        if pr is None or br is None:
            out.append(_check("functional_pose", "contact", item["id"], "not_evaluated",
                              f"{item['id']}.{part} - {body}: sem observacao", part, body=body))
            continue
        d = masks.distance(pr, br)
        if not pr and br and body in item["parts"][part]["occluders"]:
            status, detail = "inconclusive", f"{part} toda tapada por {body}: contacto provavel, nao observado"
        elif d is None or d > 1:
            status, detail = "fail", f"{body} nao toca {part}" + (f" (a {d} px)" if d is not None else "")
        else:
            status, detail = "pass", f"{body} encostada a {part}"
        out.append(_settle(_check("functional_pose", "contact", item["id"], status, f"{item['id']}: {detail}",
                                  part, body=body, distance=d), [f"{item['id']}.{part}", body], obs))
    return out


def evaluate(manifest: dict, obs: dict) -> list[dict]:
    """Todas as verificacoes de todos os objetos, na ordem do manifesto."""
    checks = []
    for item in equipment.items(manifest):
        checks += _parts(item, obs)
        if item["axis"]:
            checks.append(_axis(item, obs))
        if item["line"]:
            checks.append(_line(item, obs))
        if item["family"] == "sword_straight":
            checks.append(_guard(item, obs))
        checks += _contacts(item, obs)
    return checks


def review(manifest: dict, obs: dict, raster_ok: bool | None = None, frames: int = 1,
           coherence: dict | None = None) -> dict:
    """Os vereditos de uma imagem com manifesto: geometria e pose medidas; o resto como estiver."""
    errors = equipment.validate(manifest)
    if errors:
        raise ValueError("manifesto invalido: " + "; ".join(errors))
    checks = evaluate(manifest, obs)
    v = verdicts.initial(frames)
    if raster_ok is not None:
        verdicts.put(v, "raster_contract", "pass" if raster_ok else "fail")
    if coherence is not None:
        verdicts.put(v, "color_coherence", coherence["status"], [{"counts": coherence["counts"]}])
    verdicts.from_checks(v, "equipment_geometry", checks)
    verdicts.from_checks(v, "functional_pose", checks)
    return {"verdicts": v, "summary": verdicts.summary(v), "blocking": verdicts.blocking(v), "checks": checks}
