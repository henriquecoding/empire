"""As garantias de preservacao, de ponta a ponta (FORJA-04; relatorio de 25/10, §13).

`protect` era respeitado pela limpeza e perdido depois: a paleta levava o pixel 105 protegido a 100 e o contorno
normalizava um quase-preto protegido para preto (relatorio §7). A garantia de pixel exato verifica-se agora depois
da ultima operacao que muda pixels, no PNG final: cada pixel protegido do recorte nativo tem o mesmo RGBA em todas
as posicoes que ocupa no fim (um bloco k x k quando o cluster amplia, deslocado pelo contorno e pela tela). Num
pixel vazio basta continuar vazio: a cor escondida no transparente nao conta.

Quando a paleta obrigatoria nao tem a cor protegida, nao ha solucao que cumpra as duas garantias: o pixel fica
exato e o conflito e escrito, para o relatorio nao declarar as duas cumpridas.
"""
from __future__ import annotations

from PIL import Image

from . import color, lint, masks
from .imageops import CLEAR


def pixels(boxes, size: tuple[int, int]) -> frozenset:
    """As caixas (x0, y0, x1, y1) do recorte nativo, cortadas a imagem, como conjunto de pixels."""
    return frozenset().union(*[masks.box(b, size) for b in boxes]) if boxes else frozenset()


def same(p, q) -> bool:
    return (p[3] < 128 and q[3] < 128) or tuple(p) == tuple(q)


def colors(source: Image.Image, guarded) -> list[tuple[int, int, int]]:
    """As cores opacas protegidas, pela ordem de leitura (linha a linha)."""
    px = source.load()
    out = [px[x, y][:3] for x, y in sorted(guarded, key=lambda p: (p[1], p[0])) if px[x, y][3] >= 128]
    return list(dict.fromkeys(out))


def restore(image: Image.Image, source: Image.Image, guarded) -> tuple[Image.Image, int]:
    """Repoe os pixels protegidos da fonte, nas mesmas coordenadas; devolve quantos tinham mudado."""
    out = image.copy()
    px, src = out.load(), source.load()
    n = 0
    for x, y in guarded:
        want = src[x, y] if src[x, y][3] >= 128 else CLEAR
        if not same(px[x, y], want):
            px[x, y] = want
            n += 1
    return out, n


def conflicts(source: Image.Image, guarded, palette) -> list[list]:
    """[x, y, cor] dos pixels protegidos cuja cor nao esta na paleta obrigatoria."""
    if palette is None:
        return []
    px = source.load()
    return [[x, y, color.to_hex(px[x, y])] for x, y in sorted(guarded, key=lambda p: (p[1], p[0]))
            if px[x, y][3] >= 128 and px[x, y][:3] not in palette]


def final_xy(xy, info: dict) -> tuple[int, int]:
    """Onde fica no PNG final um pixel do recorte nativo (o canto do bloco, se o cluster ampliou)."""
    k = info.get("cluster_upscale", 1)
    sx, sy = info.get("shift", [0, 0])
    fit = info.get("fit")
    dx, dy = (fit["pivot"][0] - fit["anchor"][0], fit["pivot"][1] - fit["anchor"][1]) if fit else (0, 0)
    return xy[0] * k - sx + dx, xy[1] * k - sy + dy


def placed(info: dict, offset) -> dict:
    """O mapeamento de `info` com a figura deslocada `offset` dentro do quadro de uma prancha."""
    return {**info, "fit": {"pivot": list(offset), "anchor": [0, 0]}}


def frame_pixels(guarded, info: dict) -> frozenset:
    """Os pixels de um quadro (ou PNG final) que os pixels protegidos ocupam."""
    k = info.get("cluster_upscale", 1)
    return frozenset((x + i, y + j) for p in guarded for x, y in [final_xy(p, info)]
                     for j in range(k) for i in range(k))


def verify(final: Image.Image, source: Image.Image, guarded, info: dict) -> dict:
    """E(P): quantos pixels protegidos nao chegaram iguais ao PNG final (cortados pela tela contam)."""
    k = info.get("cluster_upscale", 1)
    fp, src = final.load(), source.load()
    w, h = final.size
    changed = []
    for x, y in sorted(guarded, key=lambda p: (p[1], p[0])):
        fx, fy = final_xy((x, y), info)
        want = src[x, y]
        for j in range(k):
            for i in range(k):
                inside = 0 <= fx + i < w and 0 <= fy + j < h
                if (not inside and want[3] >= 128) or (inside and not same(fp[fx + i, fy + j], want)):
                    changed.append([x, y])
                    break
            else:
                continue
            break
    return {"pixels": len(guarded), "changed_final": len(changed), "where": changed[:8]}


def findings(info: dict) -> list[dict]:
    """O que o acabamento nao conseguiu garantir, como achados do lint: nada fica calado."""
    out = []
    prot = info.get("protect") or {}
    if prot.get("conflicts"):
        out.append(lint.finding("protect_conflict", "error", f"{len(prot['conflicts'])} pixels protegidos com cores "
                                "fora da paleta obrigatoria: ficaram exatos e a paleta nao se cumpre ali",
                                [c[:2] for c in prot["conflicts"][:8]], "escolher: tirar a protecao ou aceitar a cor"))
    if prot.get("changed_final"):
        out.append(lint.finding("protect_changed", "error", f"{prot['changed_final']} pixels protegidos mudaram ou "
                                "ficaram fora da tela no PNG final", prot["where"]))
    budget = (info.get("palette") or {}).get("budget") or {}
    if budget.get("conflict"):
        out.append(lint.finding("colors_budget", "error", budget["conflict"]))
    elif budget and not budget.get("within", True):
        out.append(lint.finding("colors_budget", "warn", f"{budget['output_colors']} cores no fim; pedidas "
                                f"{budget['requested']} (o contorno ou uma protecao fora da paleta somaram)"))
    return out
