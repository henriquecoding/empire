"""A cor organizada no espaco: componentes de cor, fragmentos e o que se sabe deles (FORJA-04).

O lint ve o alfa, a paleta e o contorno; `orphans` so apanha um pixel sem vizinho OPACO. Um ponto de cor
cercado de pixels opacos passa sem aviso, e duas imagens com o mesmo histograma (16 pontos espalhados ou um
bloco) dao as mesmas respostas a qualquer medida de frequencia (relatorio de 25/10, §7 e §8.1). Aqui conta-se a
cor por componentes ligados, com 4 e com 8 vizinhos (N4 sobreconta os fragmentos de uma diagonal), e cada
componente pequeno vira um candidato com descritores e um estado:

- `protected`: toca a zona protegida; `expected`: esta numa regiao com papel de acento declarado (olho, brilho,
  corda, ponta...); `inconclusive`: ligado so pela diagonal (analisar como traco) ou numa regiao pouco fiavel;
  `review`: um fragmento sem papel conhecido — suspeita com evidencia, nunca defeito confirmado.

Nada aqui muda um pixel. O limite de 1-3 pixels e um ponto de partida para calibrar (relatorio §11.3), nao uma
regra de arte; o que nao se mede (planos, banding, rampas, tempo) diz-se em `not_measured`.
"""
from __future__ import annotations

from collections import Counter, deque

from PIL import Image

from . import color
from .imageops import grid as to_grid

N8 = ((-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1))
N4 = ((0, -1), (-1, 0), (1, 0), (0, 1))
SMALL = 3
ROLES = ("eye", "mouth", "brow", "nose", "highlight", "seam", "string", "tip", "buckle", "particle", "flower",
         "spark", "accent")
STATUSES = ("review", "protected", "expected", "inconclusive")
NOT_MEASURED = ("planos de luz e sombra (se a cor explica o volume)", "banding (faixas que repetem a borda)",
                "dois tons por material e rampas", "microvariacao de tons quase iguais em areas grandes",
                "degraus de curvas e diagonais", "continuidade entre quadros")


def _opaque(p) -> bool:
    return p[3] >= 128


def components(rows, keep=None, offsets=N8) -> list[tuple[tuple[int, int, int], list[tuple[int, int]]]]:
    """Componentes da mesma cor opaca, so com os pixels de `keep` (None: todos)."""
    h, w = len(rows), len(rows[0]) if rows else 0
    seen: set = set()
    out = []
    for y in range(h):
        for x in range(w):
            if (x, y) in seen or not _opaque(rows[y][x]) or (keep is not None and (x, y) not in keep):
                continue
            k = rows[y][x][:3]
            stack, members = [(x, y)], []
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                members.append((cx, cy))
                for dx, dy in offsets:
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and _opaque(rows[ny][nx]) \
                            and rows[ny][nx][:3] == k and (keep is None or (nx, ny) in keep):
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            out.append((k, members))
    return out


def _around(rows, x: int, y: int):
    h, w = len(rows), len(rows[0])
    for dx, dy in N8:
        nx, ny = x + dx, y + dy
        yield (nx, ny, rows[ny][nx]) if 0 <= nx < w and 0 <= ny < h else (nx, ny, None)


def _interior(rows, x: int, y: int) -> bool:
    return all(p is not None and _opaque(p) for _, _, p in _around(rows, x, y))


def stats(image: Image.Image) -> dict:
    """As contagens do relatorio (§6): N4/N8, singletons, singletons interiores e orfaos de alfa."""
    rows = to_grid(image)
    g4, g8 = components(rows, offsets=N4), components(rows)
    flat = [p for row in rows for p in row]
    lonely = sum(_opaque(p) and not any(q is not None and _opaque(q) for _, _, q in _around(rows, x, y))
                 for y, row in enumerate(rows) for x, p in enumerate(row))
    return {"size": [image.width, image.height], "opaque": sum(_opaque(p) for p in flat),
            "colors": len({p[:3] for p in flat if _opaque(p)}), "components4": len(g4), "components8": len(g8),
            "color_singletons4": sum(len(m) == 1 for _, m in g4), "color_singletons8": sum(len(m) == 1 for _, m in g8),
            "interior_color_singletons8": sum(len(m) == 1 and _interior(rows, *m[0]) for _, m in g8),
            "alpha_orphans8": lonely}


def edge_distance(rows) -> dict[tuple[int, int], int]:
    """A distancia (8 vizinhos) de cada pixel opaco ao vazio mais perto; fora da tela conta como vazio."""
    dist, queue = {}, deque()
    for y, row in enumerate(rows):
        for x, p in enumerate(row):
            if _opaque(p) and any(q is None or not _opaque(q) for _, _, q in _around(rows, x, y)):
                dist[(x, y)] = 1
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for nx, ny, q in _around(rows, x, y):
            if q is not None and _opaque(q) and (nx, ny) not in dist:
                dist[(nx, ny)] = dist[(x, y)] + 1
                queue.append((nx, ny))
    return dist


def _check(regions: dict | None) -> dict:
    out = {}
    for name, spec in (regions or {}).items():
        role = spec.get("role")
        if role is not None and role not in ROLES:
            raise ValueError(f"regiao {name}: papel {role!r} desconhecido (ha {', '.join(ROLES)})")
        out[name] = {"pixels": frozenset(spec.get("pixels", ())), "role": role, "material": spec.get("material"),
                     "trusted": bool(spec.get("trusted", True))}
    return out


def _status(members, inside: list[str], regions: dict, protected, pieces: int) -> tuple[str, str]:
    if protected and any(p in protected for p in members):
        return "protected", "na zona protegida"
    roles = [regions[n]["role"] for n in inside if regions[n]["role"]]
    if roles:
        return "expected", f"papel declarado: {roles[0]}"
    if pieces > 1:
        return "inconclusive", "ligado so pela diagonal: analisar como traco, nao apagar"
    if any(not regions[n]["trusted"] for n in inside):
        return "inconclusive", "regiao ou material pouco fiavel (incerteza alta ou marcacao proposta)"
    return "review", "fragmento de cor sem papel declarado"


def candidate(rows, rgb, members, regions: dict, protected, dist) -> dict:
    spots = set(members)
    near = Counter(q[:3] for x, y in members for nx, ny, q in _around(rows, x, y)
                   if q is not None and _opaque(q) and (nx, ny) not in spots)
    pieces = len(components(rows, keep=spots, offsets=N4))
    inside = [n for n, r in regions.items() if spots & r["pixels"]]
    status, reason = _status(members, inside, regions, protected, pieces)
    dominant = near.most_common(1)[0][0] if near else None
    xs, ys = [p[0] for p in members], [p[1] for p in members]
    first = min(members, key=lambda p: (p[1], p[0]))
    return {"at": list(first), "pixels": [list(p) for p in sorted(members, key=lambda p: (p[1], p[0]))],
            "color": color.to_hex(rgb), "size": len(members), "bbox": [min(xs), min(ys), max(xs) + 1, max(ys) + 1],
            "n4_pieces": pieces, "interior": all(_interior(rows, *p) for p in members),
            "edge_distance": min(dist.get(p, 0) for p in members),
            "dominant": color.to_hex(dominant) if dominant else None,
            "dominant_delta": round(color.delta(rgb, dominant), 4) if dominant else None,
            "nearest_delta": round(min(color.delta(rgb, c) for c in near), 4) if near else None,
            "neighbors": {color.to_hex(c): n for c, n in near.most_common(3)},
            "regions": inside, "status": status, "reason": reason}


def metrics(rows, keep=None, review_here: int = 0, small: int = SMALL) -> dict:
    """Area, cores, componentes N8 por 100 pixels (F), fracao em singletons N8 (S8) e candidatos sem papel (U)."""
    g8 = components(rows, keep)
    g4 = components(rows, keep, N4)
    area = sum(len(m) for _, m in g8)
    single8 = sum(len(m) == 1 for _, m in g8)
    out = {"area": area, "colors": len({k for k, _ in g8}), "components8": len(g8),
           "singletons4": sum(len(m) == 1 for _, m in g4), "singletons8": single8,
           "interior_singletons8": sum(len(m) == 1 and _interior(rows, *m[0]) for _, m in g8),
           "small_components8": sum(len(m) <= small for _, m in g8), "U": review_here}
    out["S8"] = round(single8 / area, 4) if area else "n/a"
    out["F"] = round(100 * len(g8) / area, 2) if area else "n/a"
    return out


def diagnose(image: Image.Image, regions: dict | None = None, protected=frozenset(), small: int = SMALL,
             limit: int = 200) -> dict:
    """O diagnostico de uma imagem: metricas da figura e de cada regiao, e os candidatos com o seu estado.

    `regions`: nome -> {"pixels", "role", "material", "trusted"} (de uma observacao); `protected`: pixels
    sob protecao. Sem regioes, a figura e a unica regiao conhecida (o alfa) e o material e desconhecido."""
    rows = to_grid(image)
    known = _check(regions)
    dist = edge_distance(rows)
    cands = [candidate(rows, k, m, known, frozenset(protected), dist)
             for k, m in components(rows) if len(m) <= small]
    counts = Counter(c["status"] for c in cands)
    review = [c for c in cands if c["status"] == "review"]
    figure = metrics(rows, None, len(review), small)
    per_region = {n: metrics(rows, r["pixels"], sum(n in c["regions"] for c in review), small)
                  for n, r in known.items()}
    if not figure["area"]:
        status = "not_evaluated"
    elif counts["review"]:
        status = "needs_review"
    elif counts["inconclusive"]:
        status = "inconclusive"
    else:
        status = "pass"
    return {"schema": "forja.coherence/1", "small": small, "status": status,
            "counts": {s: counts[s] for s in STATUSES}, "figure": figure, "regions": per_region,
            "candidates": cands[:limit], "not_measured": list(NOT_MEASURED)}


def summary(diag: dict, n: int = 8) -> dict:
    """O que o lint leva: estado, contagens, a figura e onde estao os primeiros candidatos a rever."""
    return {"status": diag["status"], "counts": diag["counts"], "figure": diag["figure"],
            "where": [c["at"] for c in diag["candidates"] if c["status"] == "review"][:n]}


def compare(before: dict, after: dict) -> dict:
    """Antes e depois por regiao (e na figura): o que cada metrica fez."""
    keys = ("area", "colors", "components8", "singletons8", "S8", "F", "U")
    names = ["figure"] + [n for n in before["regions"] if n in after["regions"]]
    pick = lambda d, n: d["figure"] if n == "figure" else d["regions"][n]  # noqa: E731
    return {n: {k: [pick(before, n)[k], pick(after, n)[k]] for k in keys} for n in names}
