"""O tempo entre quadros: diagnosticar a cintilacao antes de a corrigir, e so corrigir onde se sabe (FORJA-04).

O `deflicker` antigo prendia ao quadro anterior qualquer cor que mudasse menos de um limiar NA MESMA COORDENADA, e o
`blink` voltava a A qualquer pixel A -> B -> A com os vizinhos parados. As provas do relatorio de 25/10 (§7, §14):
o blink reabriu um olho fechado de proposito; o deflicker igualou o segundo quadro ao primeiro numa faixa de baixo
contraste que andou uma coluna. A mesma coordenada nao separa movimento de ruido.

Agora cada mudanca pequena (cor a menos de `threshold` em OKLab) e cada piscar A -> B -> A sao candidatos, com um
estado:
- `expected`: numa regiao de accao declarada (olho que pisca, boca, chama, brilho que corre);
- `motion`: o padrao a volta andou (o vizinhanca 3x3, com estrutura, esta deslocada no quadro anterior);
- `review`: numa regiao estatica declarada e sem movimento: candidato a cintilacao;
- `inconclusive`: fora de qualquer regiao estatica — nao ha prova de que devia ficar parado.
`stabilize` so corrige `review`, quadro a quadro contra o anterior ja corrigido. Sem regiao estatica, nada muda.

Sobre o PixelLab: segundo a especificacao OpenAPI v2 lida pelo relatorio (P10), o `drift_threshold` de
`/v2/reduce-colors` compara cada quadro com o PRIMEIRO, zero pede a correcao de todos e valores maiores corrigem
menos. Aqui compara-se com o quadro anterior, a distancia tem de ser MENOR que o limiar e zero nao corrige nada. Os
dois nomes nao sao o mesmo controlo, e nenhuma equivalencia de algoritmo foi demonstrada.
"""
from __future__ import annotations

from collections import Counter

from PIL import Image

from . import color, masks
from .imageops import from_grid, grid as to_grid

STATUSES = ("review", "motion", "expected", "protected", "inconclusive")


def _patch(rows, x: int, y: int) -> list:
    h, w = len(rows), len(rows[0])
    return [rows[y + j][x + i] if 0 <= x + i < w and 0 <= y + j < h else None
            for j in (-1, 0, 1) for i in (-1, 0, 1)]


def moved(prev, cur, x: int, y: int, radius: int = 2) -> bool:
    """A vizinhanca 3x3 de (x, y) no quadro atual esta, deslocada, no anterior? So conta se tiver estrutura."""
    patch = _patch(cur, x, y)
    if len({p for p in patch if p is not None}) < 2:
        return False
    return any(_patch(prev, x + dx, y + dy) == patch for dy in range(-radius, radius + 1)
               for dx in range(-radius, radius + 1) if dx or dy)


def _boxes(boxes) -> frozenset:
    return frozenset().union(*[masks.box(b) for b in boxes]) if boxes else frozenset()


def _changes(grids, threshold: float) -> list[tuple[int, int, int, str]]:
    """(quadro, x, y, tipo): piscar A -> B -> A (qualquer B) e mudanca pequena de cor; o regresso de um piscar
    nao conta outra vez."""
    found, blinks = [], set()
    for i in range(1, len(grids) - 1):
        a, b, c = grids[i - 1], grids[i], grids[i + 1]
        for y in range(min(len(a), len(b), len(c))):
            for x in range(min(len(a[y]), len(b[y]), len(c[y]))):
                if a[y][x] == c[y][x] != b[y][x] and a[y][x][3] >= 128 and b[y][x][3] >= 128:
                    blinks.add((i, x, y))
                    found.append((i, x, y, "blink"))
    for i in range(1, len(grids)):
        a, b = grids[i - 1], grids[i]
        for y in range(min(len(a), len(b))):
            for x in range(min(len(a[y]), len(b[y]))):
                p, q = b[y][x], a[y][x]
                if (i, x, y) in blinks or (i - 1, x, y) in blinks or p == q or p[3] < 128 or q[3] < 128:
                    continue
                if threshold > 0 and color.delta(p[:3], q[:3]) < threshold:
                    found.append((i, x, y, "drift"))
    return found


def _classify(grids, change, static, actions, keep=frozenset()) -> str:
    i, x, y, _ = change
    if (x, y) in keep:
        return "protected"
    if (x, y) in actions:
        return "expected"
    if moved(grids[i - 1], grids[i], x, y):
        return "motion"
    return "review" if (x, y) in static else "inconclusive"


def diagnose(frames: list[Image.Image], threshold: float = 0.05, static=None, actions=None,
             limit: int = 200, keep=frozenset()) -> dict:
    """Os candidatos a cintilacao de uma sequencia, cada um com o seu estado. Nao muda nenhum pixel.

    `keep`: pixels protegidos (do quadro), que nunca se estabilizam."""
    grids = [to_grid(f) for f in frames]
    zone, acts = _boxes(static), _boxes(actions)
    cands = [{"frame": c[0], "at": [c[1], c[2]], "kind": c[3], "status": _classify(grids, c, zone, acts, keep)}
             for c in _changes(grids, threshold)]
    counts = Counter(c["status"] for c in cands)
    return {"threshold": threshold, "static": [list(b) for b in static or []],
            "actions": [list(b) for b in actions or []], "counts": {s: counts[s] for s in STATUSES},
            "candidates": cands[:limit], "note": _note(counts, bool(static))}


def _note(counts: Counter, has_static: bool) -> str:
    if not has_static:
        return (f"nenhuma regiao estatica declarada: {counts['inconclusive']} mudancas pequenas ficaram nao "
                "avaliadas e nada foi alterado")
    return f"{counts['inconclusive']} mudancas fora das regioes estaticas ficaram nao avaliadas"


def stabilize(frames: list[Image.Image], threshold: float = 0.05, static=None,
              actions=None, keep=frozenset()) -> tuple[list[Image.Image], dict]:
    """Corrige so os candidatos `review`, contra o quadro anterior ja corrigido; diz o que mudou e onde."""
    grids = [to_grid(f) for f in frames]
    report = diagnose(frames, threshold, static, actions, keep=keep)
    zone, acts = _boxes(static), _boxes(actions)
    changed = []
    if zone:
        for i in range(1, len(grids)):
            for c in _changes(grids[max(0, i - 1):i + 2], threshold):
                if c[0] != 1 or _classify(grids[max(0, i - 1):i + 2], c, zone, acts, keep) != "review":
                    continue
                x, y = c[1], c[2]
                grids[i][y][x] = grids[i - 1][y][x]
                changed.append([i, x, y])
    report["changed"] = changed
    return ([from_grid(g) for g in grids] if changed else [f.copy() for f in frames]), report
