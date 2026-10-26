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

from collections import Counter

from PIL import Image, ImageFilter

from . import color
from .imageops import grid as to_grid

N8 = ((-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1))
N4 = ((0, -1), (-1, 0), (1, 0), (0, 1))
SMALL = 3
EDGE_CAP = 32
ROLES = ("eye", "mouth", "brow", "nose", "highlight", "seam", "string", "tip", "buckle", "particle", "flower",
         "spark", "accent")
STATUSES = ("review", "protected", "expected", "inconclusive")
NOT_MEASURED = ("planos de luz e sombra (se a cor explica o volume)", "banding (faixas que repetem a borda)",
                "dois tons por material e rampas", "microvariacao de tons quase iguais em areas grandes",
                "degraus de curvas e diagonais", "continuidade entre quadros")


def _opaque(p) -> bool:
    return p[3] >= 128


def _all(rows, offsets) -> list[tuple[tuple[int, int, int], list[tuple[int, int]]]]:
    """Os componentes da imagem inteira, sobre inteiros e um bytearray (o caminho rapido de `components`)."""
    h, w = len(rows), len(rows[0]) if rows else 0
    flat = [(p[0] << 16 | p[1] << 8 | p[2]) if p[3] >= 128 else -1 for row in rows for p in row]
    seen, out = bytearray(w * h), []
    for i, c in enumerate(flat):
        if c < 0 or seen[i]:
            continue
        seen[i], stack, members = 1, [i], []
        while stack:
            j = stack.pop()
            members.append((j % w, j // w))
            x, y = j % w, j // w
            for dx, dy in offsets:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    k = ny * w + nx
                    if not seen[k] and flat[k] == c:
                        seen[k] = 1
                        stack.append(k)
        out.append(((c >> 16, c >> 8 & 255, c & 255), members))
    return out


def components(rows, keep=None, offsets=N8) -> list[tuple[tuple[int, int, int], list[tuple[int, int]]]]:
    """Componentes da mesma cor opaca, so com os pixels de `keep` (None: todos). Com `keep`, so se anda nele."""
    if keep is None:
        return _all(rows, offsets)
    h, w = len(rows), len(rows[0]) if rows else 0
    seen: set = set()
    out = []
    for x, y in sorted(keep, key=lambda p: (p[1], p[0])):
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h) or not _opaque(rows[y][x]):
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
                        and rows[ny][nx][:3] == k and (nx, ny) in keep:
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


def edge_distance(image: Image.Image, wanted, cap: int = EDGE_CAP) -> dict[tuple[int, int], int]:
    """A distancia (8 vizinhos) ao vazio mais perto, so para os pixels de `wanted`; fora da tela conta como vazio.

    Erosoes sucessivas do alfa (MinFilter 3x3, em C): o pixel que some na erosao d esta a d do vazio. Mais fundo
    que `cap` fica `cap` (quer dizer `cap` ou mais): num sprite a borda esta sempre mais perto."""
    w, h = image.size
    mask = Image.new("L", (w + 2, h + 2), 0)
    mask.paste(image.getchannel("A").point(lambda a: 255 if a >= 128 else 0), (1, 1))
    todo, dist, d = set(wanted), {}, 0
    while todo:
        d += 1
        mask = mask.filter(ImageFilter.MinFilter(3))
        px = mask.load()
        gone = {p for p in todo if not px[p[0] + 1, p[1] + 1]}
        dist.update((p, d) for p in gone)
        todo -= gone
        if d >= cap:
            dist.update((p, cap) for p in todo)
            break
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


def _single4_all(rows) -> int:
    w = len(rows[0]) if rows else 0
    flat = [(p[0] << 16 | p[1] << 8 | p[2]) if p[3] >= 128 else -1 for row in rows for p in row]
    n, size = 0, len(flat)
    for i, c in enumerate(flat):
        x = i % w
        n += c >= 0 and not ((x and flat[i - 1] == c) or (x < w - 1 and flat[i + 1] == c)
                             or (i >= w and flat[i - w] == c) or (i + w < size and flat[i + w] == c))
    return n


def _single4(rows, x: int, y: int, keep) -> bool:
    h, w, k = len(rows), len(rows[0]), rows[y][x][:3]
    return not any(0 <= x + dx < w and 0 <= y + dy < h and _opaque(rows[y + dy][x + dx])
                   and rows[y + dy][x + dx][:3] == k and (keep is None or (x + dx, y + dy) in keep) for dx, dy in N4)


def metrics(rows, keep=None, review_here: int = 0, small: int = SMALL, g8=None) -> dict:
    """Area, cores, componentes N8 por 100 pixels (F), fracao em singletons N8 (S8) e candidatos sem papel (U)."""
    g8 = components(rows, keep) if g8 is None else g8
    area = sum(len(m) for _, m in g8)
    single8 = sum(len(m) == 1 for _, m in g8)
    single4 = _single4_all(rows) if keep is None else sum(_single4(rows, x, y, keep) for _, m in g8 for x, y in m)
    out = {"area": area, "colors": len({k for k, _ in g8}), "components8": len(g8),
           "singletons4": single4, "singletons8": single8,
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
    g8 = components(rows)
    small_ones = [(k, m) for k, m in g8 if len(m) <= small]
    dist = edge_distance(image.convert("RGBA"), [p for _, m in small_ones for p in m])
    cands = [candidate(rows, k, m, known, frozenset(protected), dist) for k, m in small_ones]
    counts = Counter(c["status"] for c in cands)
    review = [c for c in cands if c["status"] == "review"]
    figure = metrics(rows, None, len(review), small, g8)
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
