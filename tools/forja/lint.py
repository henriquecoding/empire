"""Conferir um sprite contra o contrato do Empire e dizer o que corrigir.

Cada achado traz: a regra, a gravidade, a mensagem, onde (amostra de
coordenadas), o comando da Forja que corrige quando ha um, e uma frase em
ingles para o gerador de imagens (`prompt_hint`). A soma das frases e o
prompt corretivo da proxima geracao: o ciclo fecha sem um humano a traduzir.

Os limites vem do contrato; os achados de "estilo" (gradiente, ruido) sao avisos
— o olho do autor decide, a ferramenta so aponta.
"""
from __future__ import annotations

from collections import Counter

from PIL import Image

from . import cleanup, clusters, color, outline
from .contracts import Contract
from .imageops import flat, foot_point, grid as to_grid, is_binary_alpha, opaque_bbox
from .palette import Palette
from .quantize import off_palette


def finding(rule: str, severity: str, message: str, where=None, fix: str | None = None,
            hint: str | None = None) -> dict:
    return {"rule": rule, "severity": severity, "message": message, "where": where or [],
            "fix": fix, "prompt_hint": hint}


def check(image: Image.Image, contract: Contract, palette: Palette | None = None,
          frame: bool = True, exempt=None) -> dict:
    """`frame=False` para pecas soltas (sem tela nem pivot a conferir). `exempt`: pixels sem contorno
    declarados (uma corda de 1 px, um vazio), que nao contam na parte da borda com contorno."""
    img = image.convert("RGBA")
    found: list[dict] = []
    box = opaque_bbox(img)
    if not box:
        found.append(finding("empty", "error", "imagem sem nenhum pixel opaco"))
        return {**_summary(img, contract, found), "coherence": _coherence(img, contract, found)}
    if frame and contract.canvas and img.size != contract.canvas:
        found.append(finding("canvas", "error", f"tela {img.size[0]}x{img.size[1]}, contrato "
                             f"{contract.canvas[0]}x{contract.canvas[1]}", fix=f"forja fit --kind {contract.kind}"))
    if not is_binary_alpha(img):
        found.append(finding("alpha", "error", "alfa parcial (o projeto usa alfa binario)", fix="forja clean",
                             hint="Use a fully transparent or perfectly flat background; no soft or semi-transparent edges."))
    _palette(img, contract, palette, found)
    _structure(img, contract, found, exempt)
    if frame:
        _placement(img, contract, box, found)
    _style(img, contract, found)
    coherence = _coherence(img, contract, found)
    return {**_summary(img, contract, found), "coherence": coherence}


def _coherence(img, contract, found) -> dict:
    """A cor no espaco (clusters.py), ao lado do contrato: informa, nao chumba nem entra no prompt."""
    if contract.kind == "fx":
        return {"status": "not_evaluated", "counts": {}, "figure": None, "where": [],
                "reason": "efeitos: particulas e padroes tem politica propria (por decidir)"}
    diag = clusters.summary(clusters.diagnose(img))
    if diag["counts"]["review"]:
        found.append(finding("fragments", "info", f"{diag['counts']['review']} fragmentos de cor de 1-"
                             f"{clusters.SMALL} px sem papel declarado (candidatos: olhos, brilhos e pontas podem "
                             "ser de proposito)", diag["where"], "forja cores <png> [--observation ...]"))
    return diag


def _palette(img, contract, palette, found):
    colors = {p[:3] for p in flat(img) if p[3] >= 128}
    if palette is not None and len(palette):
        off = off_palette(img, palette)
        if off:
            n = sum(o[2] for o in off)
            found.append(finding("palette", "error", f"{len(off)} cores fora da paleta ({n} pixels)",
                                 [list(o[:2]) for o in off[:8]], f"forja quantize --palette {contract.palette}",
                                 "Use only colors from the attached palette swatch; no new hues or in-between shades."))
    if contract.max_colors and len(colors) > contract.max_colors:
        found.append(finding("colors", "error", f"{len(colors)} cores; o contrato permite {contract.max_colors}",
                             fix=f"forja quantize --colors {contract.max_colors}",
                             hint=f"Use at most {contract.max_colors} flat colors in total."))


def _structure(img, contract, found, exempt=None):
    rows = to_grid(img)
    orphans = [(x, y) for y, row in enumerate(rows) for x, p in enumerate(row)
               if p[3] >= 128 and not any(q[3] >= 128 for q in cleanup._neighbors(rows, x, y))]
    if orphans and cleanup.policy_for(contract.kind) == "scenery":
        found.append(finding("orphans", "error", f"{len(orphans)} pixels soltos (sem vizinho opaco)",
                             [list(o) for o in orphans[:8]], "forja clean",
                             hint="No stray isolated pixels or specks around the figure."))
    elif orphans:  # F05: fora do cenario um pixel solto pode ser olho, brilho, particula ou rebento
        found.append(finding("orphans", "warn", f"{len(orphans)} pixels soltos: confirme se sao de proposito",
                             [list(o) for o in orphans[:8]], "forja clean (se forem ruido)",
                             hint="No stray isolated pixels or specks around the figure, unless they are intended."))
    if contract.cluster > 1:
        islands = cleanup.small_islands(img, contract.cluster)
        if islands:
            found.append(finding("cluster", "error", f"{len(islands)} manchas com area menor que "
                                 f"{contract.cluster}x{contract.cluster} (cluster minimo do cenario)",
                                 [list(i[:2]) for i in islands[:8]], f"forja clean --cluster {contract.cluster}",
                                 f"Build every shape from clusters of at least {contract.cluster}x{contract.cluster} pixels; no single-pixel detail."))
        shape = cleanup.footprint(img, contract.cluster)
        if shape["without_block"]:
            found.append(finding("blocks", "info", f"{shape['without_block']} manchas com area de sobra mas sem um "
                                 f"bloco {contract.cluster}x{contract.cluster} (tiras): o cluster minimo pede area ou "
                                 "bloco? (Q-277)", [s["at"] for s in shape["shapes"][:8]]))
    if contract.outline_px is not None:
        m = outline.measure(img, contract.outline_color, exempt)
        if contract.outline_px == 0 and m["outline_share"] > 0.5:
            found.append(finding("outline", "error", "contorno presente numa camada sem contorno",
                                 fix="forja outline --strip", hint="No outline at all; shapes are separated by value only."))
        elif contract.outline_px and m["outline_share"] < 0.85:
            found.append(finding("outline", "error", f"so {m['outline_share']:.0%} da borda tem o contorno "
                                 f"{m['color']} (esperado {contract.outline_px} px)",
                                 fix=f"forja outline --width {contract.outline_px}",
                                 hint=f"Surround the whole silhouette with a {contract.outline_px}-pixel pure black (#000000) outline."))
        elif contract.outline_px and m["thickness"] != contract.outline_px:
            found.append(finding("outline_width", "warn", f"contorno com {m['thickness']} px; contrato "
                                 f"{contract.outline_px} px", hint=f"The outline must be exactly {contract.outline_px} pixel(s) thick."))


def _placement(img, contract, box, found):
    w, h = img.size
    if contract.pivot:
        feet = foot_point(img)
        px, py = contract.pivot
        if feet and feet[1] != py:
            found.append(finding("pivot", "error", f"os pes estao na linha {feet[1]}, o pivot na {py}",
                                 [list(feet)], f"forja fit --kind {contract.kind}",
                                 "Feet must rest exactly on the baseline marked in the template."))
        elif feet and abs(feet[0] - px) > 2:
            found.append(finding("pivot_x", "warn", f"o centro dos pes esta em x={feet[0]}, pivot x={px}",
                                 [list(feet)], f"forja fit --kind {contract.kind}"))
    if contract.useful_height:
        height = box[3] - box[1]
        lo, hi = contract.useful_height
        if not lo <= height <= hi:
            found.append(finding("height", "warn", f"altura util {height} px, contrato {lo}-{hi} px ({contract.status})",
                                 hint=f"The figure must be {lo}-{hi} pixels tall on the {w}x{h} canvas."))
    if box[0] == 0 or box[1] == 0 or box[2] == w or box[3] == h:
        found.append(finding("margin", "warn", "o desenho toca a borda da tela (risco de corte)", [list(box)],
                             hint="Keep clear empty space between the figure and the image border."))
    if contract.width_multiple and (box[2] - box[0]) % contract.width_multiple:
        found.append(finding("width", "info", f"largura {box[2] - box[0]} px nao e multipla de {contract.width_multiple}"))


def _style(img, contract, found):
    rows = to_grid(img)
    checker = sum(1 for y in range(1, len(rows) - 1) for x in range(1, len(rows[0]) - 1)
                  if _is_checker(rows, x, y))
    solid = sum(1 for p in flat(img) if p[3] >= 128)
    if not contract.dither and solid and checker / solid > 0.04:
        found.append(finding("dither", "warn", f"padrao de xadrez em {checker} pixels (dither ou ruido)",
                             fix="forja clean", hint="No dithering, no noise texture; flat clusters of color only."))
    ramps = _ramps(rows)
    if ramps:
        found.append(finding("gradient", "warn", f"{len(ramps)} rampas longas de tons vizinhos (possivel gradiente)",
                             [list(r) for r in ramps[:6]],
                             hint="Two tones per material (light and shadow); no gradients or soft shading."))


def _is_checker(rows, x, y) -> bool:
    p = rows[y][x]
    if p[3] < 128:
        return False
    n4 = [rows[y - 1][x], rows[y + 1][x], rows[y][x - 1], rows[y][x + 1]]
    diag = [rows[y - 1][x - 1], rows[y - 1][x + 1], rows[y + 1][x - 1], rows[y + 1][x + 1]]
    return all(q[3] >= 128 and q[:3] != p[:3] for q in n4) and all(q == p for q in diag) \
        and len({q[:3] for q in n4}) == 1


def _ramps(rows, length: int = 5) -> list[tuple[int, int]]:
    """Corridas de `length`+ tons distintos com a luminosidade sempre a subir ou a descer."""
    out = []
    columns = [list(col) for col in zip(*rows)]
    for vertical, lines in ((False, rows), (True, columns)):
        for j, line in enumerate(lines):
            run, last, direction = 1, None, 0
            for i, p in enumerate(line):
                if p[3] < 128:
                    run, last, direction = 1, None, 0
                    continue
                if last is None or p[:3] == last[:3]:
                    last = p
                    continue
                d = 1 if color.oklab(p[:3])[0] > color.oklab(last[:3])[0] else -1
                run = run + 1 if d == direction else 2
                direction, last = d, p
                if run == length:
                    out.append((j, i) if vertical else (i, j))
    return out


def too_big(contract: Contract, clipped: int, native: tuple[int, int]) -> dict:
    """A figura nao cabe na tela: reduzir nao redesenha (licao de 18/10/2026), gera-se de novo na grade certa."""
    lo, hi = contract.useful_height or (1, contract.canvas[1] if contract.canvas else native[1])
    return finding("clipped", "error", f"{clipped} pixels ficaram fora da tela; a figura tem {native[0]}x{native[1]} "
                   "pixels logicos. Reduzir nao redesenha feicoes: gerar de novo na grade do contrato",
                   hint=f"Draw the figure smaller: {lo}-{hi} logical pixels tall, completely inside its cell.")


def below_grid(sub: dict, box: list[int]) -> dict:
    """Detalhe desenhado mais fino que a grade (o rosto, quase sempre): o voto nao o recupera."""
    return finding("subgrid", "warn", f"{sub['cells']} celulas misturadas ({sub['share']:.0%} da figura); a maior zona "
                   f"tem {sub['largest']} celulas em {box}: ali o gerador desenhou mais fino do que a grade",
                   [box], f"forja inpaint <png> --box {','.join(str(v) for v in box)} --change \"...\"",
                   "Draw the face and small details with whole pixels on the same grid as the body: eyes, mouth "
                   "and brows as 1-2 pixel marks, never lines thinner than one block.")


def add(report: dict, item: dict) -> dict:
    report["findings"].append(item)
    report["errors"] += item["severity"] == "error"
    report["warnings"] += item["severity"] == "warn"
    report["ok"] = report["errors"] == 0
    hints = [f["prompt_hint"] for f in report["findings"] if f["prompt_hint"]]
    report["prompt_feedback"] = " ".join(dict.fromkeys(hints))
    return report


def _summary(img, contract, found) -> dict:
    count = Counter(f["severity"] for f in found)
    hints = [f["prompt_hint"] for f in found if f["prompt_hint"]]
    return {"kind": contract.kind, "size": list(img.size), "ok": count["error"] == 0,
            "errors": count["error"], "warnings": count["warn"], "findings": found,
            "prompt_feedback": " ".join(dict.fromkeys(hints))}
