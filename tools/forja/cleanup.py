"""Limpeza na resolucao nativa: pixels soltos, ruido de cor, aglomerados pequenos
e cantos dobrados nos tracos de 1 px.

A Asset Bible distingue: no cenario um pixel solto e proibido (cluster minimo
2x2); num personagem um pixel isolado pode ser o olho, um brilho, a ponta de uma
flecha ou o rebento de uma flor. Por isso (auditoria F05) as tres limpezas sao
separadas e cada tipo de asset tem a sua politica: tirar pixels soltos e tapar
furos so no cenario; num personagem ou num efeito ficam e vao para o relatorio
como candidatos. O ruido de cor so se corrige quando o pixel e QUASE da cor dos
vizinhos (ruido do gerador), nunca quando contrasta (intencao), e `noise=0`
desliga-o. Pixels protegidos nunca mudam; cada mudanca fica escrita.
"""
from __future__ import annotations

from collections import Counter

from PIL import Image

from . import color
from .imageops import CLEAR, grid as to_grid, from_grid

N8 = ((-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1))
N4 = ((0, -1), (-1, 0), (1, 0), (0, 1))


def _neighbors(rows, x: int, y: int, offsets=N8):
    h, w = len(rows), len(rows[0])
    for dx, dy in offsets:
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h:
            yield rows[ny][nx]


SCENERY = ("building", "prop", "tile", "parallax_far", "parallax_mid", "foreground")
POLICIES = {
    "conservative": {"remove_orphans": False, "fill_holes": False, "denoise": False},
    "character": {"remove_orphans": False, "fill_holes": False, "denoise": True},
    "fx": {"remove_orphans": False, "fill_holes": False, "denoise": False},
    "scenery": {"remove_orphans": True, "fill_holes": True, "denoise": True},
}


def policy_for(kind: str, name: str = "auto") -> str:
    """A politica de limpeza de um contrato: cenario, efeito, personagem; `free` e conservadora."""
    if name != "auto":
        if name not in POLICIES:
            raise ValueError(f"limpeza desconhecida: {name} (use auto, {', '.join(POLICIES)})")
        return name
    if kind in SCENERY:
        return "scenery"
    if kind == "fx":
        return "fx"
    return "conservative" if kind == "free" else "character"


def clean(image: Image.Image, policy: str | dict = "conservative", noise: float = 0.08,
          protect: list[tuple[int, int, int, int]] | None = None, limit: int = 200) -> tuple[Image.Image, dict]:
    """Limpa pela politica e diz o que mudou, onde e porque; os pixels soltos que ficam sao candidatos.

    `policy` e um nome de POLICIES ou um dict com remove_orphans, fill_holes e denoise.
    `protect` sao caixas (x0, y0, x1, y1) em que nada muda.
    """
    rule = POLICIES[policy] if isinstance(policy, str) else policy
    rows = to_grid(image)
    src = [row[:] for row in rows]
    guarded = {(x, y) for x0, y0, x1, y1 in protect or [] for y in range(y0, y1) for x in range(x0, x1)}
    changes: dict[str, list] = {"orphans": [], "holes": [], "noise": []}
    kept, skipped = [], 0
    for y, row in enumerate(src):
        for x, p in enumerate(row):
            around = list(_neighbors(src, x, y))
            solid = [q for q in around if q[3] >= 128]
            new, why = None, None
            if p[3] >= 128 and not solid:
                if rule["remove_orphans"]:
                    new, why = CLEAR, "orphans"
                else:
                    kept.append([x, y])
            elif p[3] < 128 and rule["fill_holes"] and len(around) == 8 and len(solid) == 8:
                new, why = Counter(solid).most_common(1)[0][0], "holes"
            elif p[3] >= 128 and solid and rule["denoise"] and noise > 0:
                top, n = Counter(q[:3] for q in solid).most_common(1)[0]
                if p[:3] != top and n >= 5 and p[:3] not in {q[:3] for q in solid} \
                        and color.delta(p[:3], top) < noise:
                    new, why = (*top, 255), "noise"
            if new is None:
                continue
            if (x, y) in guarded:
                skipped += 1
                continue
            rows[y][x] = new
            changes[why].append([x, y])
    info = {"policy": policy if isinstance(policy, str) else "explicit", **{k: len(v) for k, v in changes.items()}, "protected_kept": skipped,
            "kept_isolated": len(kept), "candidates": kept[:limit],
            "changed": {k: v[:limit] for k, v in changes.items() if v}}
    return from_grid(rows), info


def despeckle(image: Image.Image, noise: float = 0.08, holes: bool = True) -> tuple[Image.Image, dict]:
    """`forja clean`: o pedido explicito de tirar pixels soltos (e tapar furos de 1 px, se `holes`)."""
    return clean(image, {"remove_orphans": True, "fill_holes": holes, "denoise": True}, noise)


def components(rows, key=lambda p: p[:3] if p[3] >= 128 else None, offsets=N4):
    """Componentes ligados de pixels com a mesma chave: [(chave, [(x, y), ...])]."""
    h, w = len(rows), len(rows[0])
    seen = [[False] * w for _ in range(h)]
    out = []
    for y in range(h):
        for x in range(w):
            k = key(rows[y][x])
            if seen[y][x] or k is None:
                continue
            stack, members = [(x, y)], []
            seen[y][x] = True
            while stack:
                cx, cy = stack.pop()
                members.append((cx, cy))
                for dx, dy in offsets:
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and key(rows[ny][nx]) == k:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            out.append((k, members))
    return out


def min_cluster(image: Image.Image, size: int = 2, connectivity: int = 8,
                protect: list[tuple[int, int, int, int]] | None = None) -> tuple[Image.Image, int]:
    """Funde na cor vizinha mais comum cada mancha com menos de size x size pixels de AREA.

    Por omissao a mancha conta com 8 vizinhos: uma diagonal de um pixel e uma linha e fica (com 4 vizinhos,
    a prova do relatorio de 25/10 apagou uma diagonal de oito). `connectivity=4` e escolha explicita, para o
    cenario, onde o detalhe de 1 px e proibido. `protect`: caixas que nao mudam."""
    rows = to_grid(image)
    guarded = {(x, y) for x0, y0, x1, y1 in protect or [] for y in range(y0, y1) for x in range(x0, x1)}
    offsets = N8 if connectivity == 8 else N4
    merged = 0
    for _ in range(3):
        changed = 0
        for k, members in components(rows, offsets=offsets):
            if len(members) >= size * size or guarded.intersection(members):
                continue
            spots = set(members)
            around = Counter(rows[ny][nx][:3] for x, y in members for nx, ny in
                             ((x + dx, y + dy) for dx, dy in N4)
                             if 0 <= nx < len(rows[0]) and 0 <= ny < len(rows)
                             and (nx, ny) not in spots and rows[ny][nx][3] >= 128)
            if not around:
                continue
            fill = around.most_common(1)[0][0]
            for x, y in members:
                rows[y][x] = (*fill, 255)
            changed += len(members)
        merged += changed
        if not changed:
            break
    return from_grid(rows), merged


def small_islands(image: Image.Image, size: int = 2) -> list[tuple[int, int, int]]:
    """Manchas de cor (4 vizinhos) com AREA menor que size x size: (x, y, pixels) do primeiro pixel de cada.

    Area nao e forma: uma tira 1x4 tem a area de um bloco 2x2 e nao aparece aqui (ver `footprint`)."""
    rows = to_grid(image)
    return [(m[0][0], m[0][1], len(m)) for _, m in components(rows) if len(m) < size * size]


def footprint(image: Image.Image, k: int = 2) -> dict:
    """Area, caixa e bloco de cada mancha de cor (4 vizinhos): tres medidas que nao se confundem.

    `below_area`: menos de k*k pixels; `without_block`: area que chega mas nenhum bloco k x k da mesma cor (uma
    tira 1x4); `uncovered_pixels`: pixels que nao estao dentro de nenhum bloco k x k da sua cor."""
    rows = to_grid(image)
    h, w = len(rows), len(rows[0])
    covered: set = set()
    for y in range(h - k + 1):
        for x in range(w - k + 1):
            p = rows[y][x]
            if p[3] >= 128 and all(rows[y + j][x + i][3] >= 128 and rows[y + j][x + i][:3] == p[:3]
                                   for j in range(k) for i in range(k)):
                covered.update((x + i, y + j) for j in range(k) for i in range(k))
    comps = components(rows)
    shapes, below = [], 0
    for _, m in comps:
        if len(m) < k * k:
            below += 1
        elif not covered.intersection(m):
            xs, ys = [p[0] for p in m], [p[1] for p in m]
            shapes.append({"at": list(m[0]), "area": len(m), "size": [max(xs) - min(xs) + 1, max(ys) - min(ys) + 1]})
    return {"k": k, "components": len(comps), "below_area": below, "without_block": len(shapes),
            "uncovered_pixels": sum(p not in covered for _, m in comps for p in m), "shapes": shapes[:16]}


def pixel_perfect(image: Image.Image, line: tuple[int, int, int] = (0, 0, 0)) -> tuple[Image.Image, int]:
    """Tira os cantos em L dos tracos de 1 px da cor `line` (o "pixel perfect" do Aseprite).

    Um pixel do traco sai quando tem um vizinho do traco na horizontal e outro na
    vertical (que se tocam na diagonal) e os restantes vizinhos do traco tocam um
    desses dois: o traco continua ligado pela diagonal e perde o degrau duplo.
    """
    rows = to_grid(image)
    h, w = len(rows), len(rows[0])
    removed = 0

    def is_line(x: int, y: int) -> bool:
        return 0 <= x < w and 0 <= y < h and rows[y][x][3] >= 128 and rows[y][x][:3] == line

    for y in range(h):
        for x in range(w):
            if not is_line(x, y):
                continue
            hor = [dx for dx in (-1, 1) if is_line(x + dx, y)]
            ver = [dy for dy in (-1, 1) if is_line(x, y + dy)]
            if len(hor) != 1 or len(ver) != 1 or is_line(x + hor[0], y + ver[0]):
                continue
            a, c = (x + hor[0], y), (x, y + ver[0])
            others = [(x + dx, y + dy) for dx, dy in N8 if is_line(x + dx, y + dy)
                      and (x + dx, y + dy) not in (a, c)]
            if all(any(max(abs(o[0] - q[0]), abs(o[1] - q[1])) <= 1 for q in (a, c)) for o in others):
                rows[y][x] = _fill_from(rows, x, y, line)
                removed += 1
    return from_grid(rows), removed


def _fill_from(rows, x: int, y: int, line: tuple[int, int, int]):
    near = list(_neighbors(rows, x, y, N4))
    if len(near) < 4 or any(q[3] < 128 for q in near):
        return CLEAR
    around = [q for q in near if q[:3] != line]
    return Counter(around).most_common(1)[0][0] if around else CLEAR


def binarize_rows(rows, threshold: int = 128):
    return [[p if p[3] >= threshold else CLEAR for p in row] for row in rows]
