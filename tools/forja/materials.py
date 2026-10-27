"""Cor por material, dentro da paleta autorizada, e o agrupamento de fragmentos so com prova local (FORJA-04).

Relatorio de 25/10, §11.5 e §12. As 112 cores do Empire organizam familias; nenhum personagem as usa todas. O
mapeamento global decide pixel a pixel pela cor mais perto e pode trocar o papel de uma cor (pele em couro). Aqui:

- `remap`: numa regiao com rampa declarada (contida na paleta mestra), cada pixel fora dela vai para o tom mais
  perto DA RAMPA; uma regiao sem rampa nao muda (politica conservadora para o desconhecido); um pixel preso nao muda
  e, se esta fora da rampa, fica escrito como conflito.
- `regroup`: um fragmento a rever (clusters.py) funde-se na cor que o cerca so com as quatro provas locais — dentro
  da zona editavel e longe do que esta preso; o alfa nao muda; nao e a cor do contorno, nao e um traco diagonal e
  nao separa duas massas da cor que o absorveria; essa cor e da rampa e tem a maioria estrita da vizinhanca. Na
  duvida fica, com as alternativas escritas. Nunca e um filtro de mediana nem uma votacao no sprite inteiro.
- `separation`: C(R), as fronteiras entre regioes vizinhas que deixam de ter cores diferentes.

O plano (`forja.cores/1`) diz que regioes ficam presas, que rampas valem e onde se agrupa. Nao altera a paleta
mestra, nao impoe um teto global (Q-273) e nao liga dithering num personagem.
"""
from __future__ import annotations

from collections import Counter

from PIL import Image

from . import clusters, color
from .imageops import grid as to_grid
from .palette import Palette

SCHEMA = "forja.cores/1"
OUTLINE = (0, 0, 0)


def validate(plan: dict, master: Palette, names: set[str]) -> list[str]:
    """Os erros do plano (lista vazia: valido), contra a paleta mestra e as regioes da observacao."""
    errors = [] if plan.get("schema") == SCHEMA else [f"schema: esperado {SCHEMA}"]
    if plan.get("budget") is not None:
        errors.append("budget: um teto global de cores e decisao do dono (Q-273); use rampas por regiao")
    if plan.get("dither", "none") != "none":
        errors.append("dither: so 'none' em personagens (Asset Bible §1)")
    lock = plan.get("lock", [])
    for name in lock:
        if name not in names:
            errors.append(f"lock: regiao {name!r} nao esta na observacao")
    for name, spec in plan.get("regions", {}).items():
        if name not in names:
            errors.append(f"regiao {name!r} nao esta na observacao")
        if name in lock:
            errors.append(f"{name}: presa e editavel ao mesmo tempo")
        if spec.get("group") and not spec.get("ramp"):
            errors.append(f"{name}: agrupar pede uma rampa declarada (sem rampa a regiao nao muda)")
        for h in spec.get("ramp", []):
            if color.parse_hex(h) not in master:
                errors.append(f"{name}: {h} nao esta na paleta mestra {master.name or ''}".rstrip())
    return errors


def regions_from(raw: dict, observed: dict) -> dict:
    """As regioes de uma observacao com papel, material e se sao de confiar (incerteza e marcacao)."""
    return {name: {"pixels": observed["regions"][name], "role": spec.get("role"), "material": spec.get("material"),
                   "trusted": name not in observed["uncertain"] and spec.get("annotation", "marked") != "proposed"}
            for name, spec in raw.get("regions", {}).items()}


def _order(points):
    return sorted(points, key=lambda p: (p[1], p[0]))


def remap(image: Image.Image, regions: dict, ramps: dict, locked=frozenset()) -> tuple[Image.Image, dict]:
    """Cada regiao com rampa so com cores da rampa; o resto da imagem e os pixels presos ficam."""
    out = image.copy()
    px = out.load()
    report = {}
    for name, ramp in ramps.items():
        pixels = regions[name]
        before = {px[p][:3] for p in pixels if px[p][3] >= 128}
        changed, off = 0, []
        for p in _order(pixels):
            q = px[p]
            if q[3] < 128 or q[:3] in ramp:
                continue
            if p in locked:
                off.append([p[0], p[1], color.to_hex(q)])
                continue
            px[p] = (*ramp.nearest(q), 255)
            changed += 1
        after = {px[p][:3] for p in pixels if px[p][3] >= 128}
        report[name] = {"ramp": ramp.hexes(), "colors_before": len(before), "colors_after": len(after),
                        "changed": changed, "locked_off_ramp": off}
    return out, report


def _labels(rows) -> dict:
    return {p: i for i, (_, members) in enumerate(clusters.components(rows)) for p in members}


def _ring(rows, members):
    spots, h, w = set(members), len(rows), len(rows[0])
    for x, y in members:
        for dx, dy in clusters.N8:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in spots and rows[ny][nx][3] >= 128:
                yield (nx, ny), rows[ny][nx][:3]


def _decide(rows, labels, cand: dict, pixels, ramp, locked, touched, outline) -> tuple[tuple | None, dict]:
    members = [tuple(p) for p in cand["pixels"]]
    note = {"at": cand["at"], "pixels": cand["pixels"], "color": cand["color"]}
    ring = list(_ring(rows, members))
    if any(p not in pixels for p in members):
        return None, {**note, "why": "parte fora da zona editavel"}
    if any(p in locked for p, _ in ring) or any(p in touched for p, _ in ring):
        return None, {**note, "why": "encosta a um pixel preso ou ja mudado"}
    if color.parse_hex(cand["color"]) == outline:
        return None, {**note, "why": "cor do contorno: e estrutura"}
    votes = Counter(c for _, c in ring if c != outline and (ramp is None or c in ramp))
    if not votes:
        return None, {**note, "why": "nenhuma cor da rampa a volta"}
    (top, n), total = votes.most_common(1)[0], len(ring)
    if n * 2 <= total:
        why = ("vizinhanca dividida: escolher a olho" if len(votes) > 1 else
               "cercado sobretudo pelo contorno ou por outra regiao: escolher a olho")
        return None, {**note, "why": why, "alternatives": [color.to_hex(c) for c, _ in votes.most_common(2)]}
    if len({labels[p] for p, c in ring if c == top}) > 1:
        return None, {**note, "why": f"separa duas massas de {color.to_hex(top)}: pinta-lo juntava o que o "
                                     "desenho separa"}
    return top, {**note, "from": cand["color"], "to": color.to_hex(top), "share": round(n / total, 3)}


def regroup(image: Image.Image, regions: dict, ramps: dict, editable: set[str], locked=frozenset(),
            outline=OUTLINE) -> tuple[Image.Image, dict]:
    """Funde os fragmentos a rever das regioes editaveis, um a um, com as provas de `_decide`."""
    diag = clusters.diagnose(image, regions, locked, limit=10 ** 6)
    rows = to_grid(image)
    labels = _labels(rows)
    out = image.copy()
    px = out.load()
    merged, kept, touched = [], [], set()
    for cand in diag["candidates"]:
        home = [n for n in cand["regions"] if n in editable]
        if cand["status"] != "review" or not home:
            continue
        pixels = frozenset().union(*[regions[n]["pixels"] for n in home])
        target, note = _decide(rows, labels, cand, pixels, ramps.get(home[0]), locked, touched, outline)
        if target is None:
            kept.append(note)
            continue
        for x, y in cand["pixels"]:
            px[x, y] = (*target, 255)
            touched.add((x, y))
        merged.append(note)
    return out, {"merged": merged, "kept": kept}


def _same_or_line(kinds: dict | None, a: str, b: str) -> bool:
    if not kinds:
        return False
    return bool(kinds.get(a)) and kinds.get(a) == kinds.get(b) or "line" in (kinds.get(a), kinds.get(b))


def separation(before: Image.Image, after: Image.Image, regions: dict, kinds: dict | None = None) -> list[dict]:
    """C(R): em cada par de regioes vizinhas, as fronteiras de pixel (N4) com cores diferentes, antes e depois.

    Um pixel em varias regioes pertence a mais pequena (o olho dentro do rosto). Com `kinds` (regiao ->
    material), dois lados do mesmo material declarado nao contam (ali a fronteira nao e uma separacao), nem uma
    regiao de material `line`: o traco nao e um material, e a estrutura dele confere-se no contorno do lint."""
    owner = {}
    for name in sorted(regions, key=lambda n: (len(regions[n]), n)):
        for p in regions[name]:
            owner.setdefault(p, name)
    a, b = before.load(), after.load()
    pairs: dict[tuple[str, str], list[int]] = {}
    for p, mine in owner.items():
        for q in ((p[0] + 1, p[1]), (p[0], p[1] + 1)):
            other = owner.get(q)
            if other is None or other == mine or _same_or_line(kinds, mine, other):
                continue
            rec = pairs.setdefault(tuple(sorted((mine, other))), [0, 0, 0])
            rec[0] += 1
            rec[1] += a[p][:3] != a[q][:3]
            rec[2] += b[p][:3] != b[q][:3]
    return [{"pair": list(k), "borders": n, "distinct_before": x, "distinct_after": y, "lost": y < x}
            for k, (n, x, y) in sorted(pairs.items())]


def apply(image: Image.Image, plan: dict, regions: dict, master: Palette,
          outline=OUTLINE) -> tuple[Image.Image, dict]:
    """O plano inteiro: rampas, agrupamento e as provas — E(P) nos presos, nada fora da zona, o alfa igual e as
    fronteiras entre materiais diferentes mantidas. `ok` diz so isso; a leitura a 1x e a aprovacao sao do autor."""
    errors = validate(plan, master, set(regions))
    if errors:
        raise ValueError("plano de cores invalido: " + "; ".join(errors))
    pix = {n: r["pixels"] for n, r in regions.items()}
    locked = frozenset().union(*[pix[n] for n in plan.get("lock", [])])
    spec = plan.get("regions", {})
    ramps = {n: Palette([color.parse_hex(h) for h in s["ramp"]], n) for n, s in spec.items() if s.get("ramp")}
    zone = frozenset().union(*[pix[n] for n in spec]) - locked
    before = clusters.diagnose(image, regions, locked)
    step, remapped = remap(image, pix, ramps, locked)
    out, grouped = regroup(step, regions, ramps, {n for n, s in spec.items() if s.get("group")}, locked, outline)
    after = clusters.diagnose(out, regions, locked)
    a, b = image.load(), out.load()
    changed = [(x, y) for y in range(image.height) for x in range(image.width) if a[x, y] != b[x, y]]
    sep = separation(image, out, pix, {n: r.get("material") for n, r in regions.items()})
    report = {"changed_pixels": len(changed), "outside_zone_changed": sum(p not in zone for p in changed),
              "locked": {"pixels": len(locked), "changed": sum(p in locked for p in changed)},
              "alpha_identical": image.getchannel("A").tobytes() == out.getchannel("A").tobytes(),
              "remap": remapped, "regroup": grouped, "metrics": compare(before, after),
              "separation": sep, "status": {"before": before["status"], "after": after["status"]},
              "counts": {"before": before["counts"], "after": after["counts"]},
              "before": before, "after": after}
    report["ok"] = (not report["outside_zone_changed"] and not report["locked"]["changed"]
                    and report["alpha_identical"] and not any(s["lost"] for s in sep))
    report["material"] = material_state(remapped, sep)
    return out, report


def material_state(remapped: dict, sep: list[dict]) -> dict:
    """O material, a parte da prova tecnica (FORJA-06, solucao de 27/10, §5): um pixel preso fora da rampa da sua
    regiao e um conflito de seletores (a lamina que apanha a mao), e uma fronteira perdida junta materiais. Enquanto
    houver um dos dois, o material fica `pending`, mesmo com `ok`: nao se tira a protecao para limpar o relatorio,
    reveem-se as regioes (lamina, punho e maos separados, cada um com autoridade)."""
    conflicts = {n: r["locked_off_ramp"] for n, r in remapped.items() if r["locked_off_ramp"]}
    lost = [s["pair"] for s in sep if s["lost"]]
    return {"status": "pending" if conflicts or lost else "resolved",
            "conflicts": sum(len(v) for v in conflicts.values()), "regions": sorted(conflicts),
            "separation_lost": lost,
            "next": "rever os seletores: separar as regioes que se sobrepoem ao que esta preso" if conflicts else None}


def compare(before: dict, after: dict) -> dict:
    """Antes e depois por regiao (e na figura): o que cada metrica fez."""
    keys = ("area", "colors", "components8", "singletons8", "S8", "F", "U")
    names = ["figure"] + [n for n in before["regions"] if n in after["regions"]]
    pick = lambda d, n: d["figure"] if n == "figure" else d["regions"][n]  # noqa: E731
    return {n: {k: [pick(before, n)[k], pick(after, n)[k]] for k in keys} for n in names}
