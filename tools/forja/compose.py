"""A recomposicao local de um reparo: adicionar, substituir ou remover, e provar o que ficou igual (FORJA-03).

Adicionar e substituir sao operacoes diferentes. No guia de inpainting do PixelLab (22/07/2026), a
camada so com as alteracoes deixa o chapeu antigo por baixo; para o tirar troca-se o metodo de saida.
Aqui o metodo e declarado em cada reparo:
- `add`: dentro da mascara so entram os pixels opacos do candidato; o resto fica como estava;
- `replace`: dentro da mascara manda o candidato, transparencia incluida;
- `remove`: como `replace`, e nenhum pixel do objeto antigo pode ficar igual.
Com o objeto antigo marcado (`old`), diz-se quanto dele continua visivel: por baixo de uma camada nova,
fora da mascara, ou intacto depois de uma remocao. Fora da mascara os pixels ficam byte a byte, as
regioes protegidas guardam o hash, e `verify` repete a prova depois de todo o acabamento.
"""
from __future__ import annotations

from PIL import Image

from . import masks
from .imageops import CLEAR

METHODS = ("add", "replace", "remove")


def compose(native: Image.Image, candidate: Image.Image, editable, method: str = "replace",
            protect=frozenset(), old=frozenset(), joints=()) -> tuple[Image.Image, dict]:
    """O sprite com o candidato pousado so dentro de `editable`, pelo metodo dado."""
    if method not in METHODS:
        raise ValueError(f"metodo de composicao desconhecido: {method} (use {', '.join(METHODS)})")
    native, candidate = native.convert("RGBA"), candidate.convert("RGBA")
    if native.size != candidate.size:
        raise ValueError(f"o candidato tem {candidate.size}, o sprite {native.size}: nao se estica")
    editable, protect, old = frozenset(editable), frozenset(protect), frozenset(old)
    if not editable:
        raise ValueError("mascara vazia: nada para reparar")
    if any(not (0 <= x < native.width and 0 <= y < native.height) for x, y in editable):
        raise ValueError(f"a mascara sai do sprite {native.size}")
    refuse_protected(editable, protect)
    out = native.copy()
    src, new, dst = native.load(), candidate.load(), out.load()
    for p in editable:
        if new[p] == src[p] or (new[p][3] < 128 and src[p][3] < 128) or (method == "add" and new[p][3] < 128):
            continue
        dst[p] = new[p] if new[p][3] >= 128 else CLEAR
    seen = {p for p in old if src[p][3] >= 128}
    findings = []
    stale = sorted(p for p in seen & editable if method == "add" and new[p][3] < 128)
    if stale:
        findings.append({"code": "overlay_keeps_old", "pixels": len(stale), "where": masks.bbox(stale),
                         "detail": "a camada nova foi adicionada por cima: o objeto antigo continua visivel por baixo "
                                   "(use replace ou remove)"})
    outside = sorted(seen - editable) if method != "add" else []
    if outside:
        findings.append({"code": "old_outside_mask", "pixels": len(outside), "where": masks.bbox(outside),
                         "detail": "parte do objeto antigo esta fora da mascara e fica: alargue a mascara a unidade "
                                   "funcional inteira"})
    intact = sorted(p for p in seen & editable if method == "remove" and dst[p] == src[p])
    if intact:
        findings.append({"code": "removed_object_remains", "pixels": len(intact), "where": masks.bbox(intact),
                         "detail": "a remocao deixou pixels do objeto antigo iguais"})
    cut = [list(j) for j in joints if tuple(j) not in masks.dilate(editable, 1)]
    if cut:
        findings.append({"code": "joint_outside_mask", "joints": cut,
                         "detail": "a mascara deixa de fora uma ligacao do objeto (ponta, mao, correia): a emenda "
                                   "pode ficar ma"})
    proof = verify(native, out, editable, protect)
    info = {"method": method, "editable_pixels": len(editable), "editable_box": masks.bbox(editable),
            "changed_pixels": sum(1 for p in editable if dst[p] != src[p]), **proof, "findings": findings,
            "ok": proof["outside_identical"] and proof["protected_identical"] and not findings}
    return out, info


def refuse_protected(editable, protect) -> None:
    """Uma mascara que toca uma regiao protegida e recusada — antes de qualquer pedido pago."""
    clash = frozenset(editable) & frozenset(protect)
    if clash:
        raise ValueError(f"a mascara cobre {len(clash)} pixels protegidos, ex.: {sorted(clash)[:4]}")


def verify(before: Image.Image, after: Image.Image, editable, protect=frozenset()) -> dict:
    """A prova de preservacao, para repetir depois de quantizar, contornar ou pousar na tela."""
    outside = masks.changed(before, after, frozenset(editable))
    protect = frozenset(protect)
    return {"outside_changed": len(outside), "outside_identical": not outside,
            "outside_examples": [list(p) for p in outside[:6]],
            "protected_pixels": len(protect),
            "protected_identical": masks.digest(before, protect) == masks.digest(after, protect)}
