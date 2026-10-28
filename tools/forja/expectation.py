"""O que se pediu contra o que chegou: tamanho e grade, a mesma conta no `auto` e no `forge`/`sheet` (FORJA-06).

Solucao de 27/10, §7.2. O ciclo fechado ja media o tamanho recebido e a grade detetada contra o plano; o caminho
manual (o agente que gera com a sua ferramenta e forja com `--expect`) so usava o expect para recortar, e uma
imagem noutro tamanho passava calada. Agora os dois caminhos comparam com estas funcoes e deixam a pendencia escrita:
um tamanho que nao e o pedido torna o contrato invalido e pede outra geracao; uma grade nao seguida vai para a
revisao e para o prompt corretivo. Um pedido nativo (PixelLab) so e tratado como nativo se o tamanho o confirmar.
"""
from __future__ import annotations

HARD = ("native_size_mismatch", "size_mismatch")


def raster_check(expect: dict, received: list[int]) -> dict:
    """O tamanho que chegou contra o pedido. No Gemini o pedido e estimado: so se regista o desvio."""
    want = expect["size"]
    out = {"requested": list(want), "received": list(received), "matches": list(received) == list(want),
           "requested_is_estimate": not expect.get("scale_exact", True)}
    lw, lh = expect["cells"]
    out["expected_period"] = round(received[0] / lw, 3) if expect["grid"] != "native" else 1.0
    out["aspect_deviation"] = round(abs(received[0] / received[1] - want[0] / want[1]) / (want[0] / want[1]), 4)
    return out


def region(expect: dict, received: list[int]) -> tuple[int, int, int, int] | None:
    """A caixa da prancha (sem margens) no raster recebido, pelas proporcoes logicas do plano."""
    lw, lh = expect["cells"]
    x0, y0, x1, y1 = expect.get("content") or (0, 0, lw, lh)
    if (x0, y0, x1, y1) == (0, 0, lw, lh):
        return None
    w, h = received
    return round(x0 * w / lw), round(y0 * h / lh), round(x1 * w / lw), round(y1 * h / lh)


def native(expect: dict, received) -> bool:
    """Um pedido nativo so e lido a 1x quando o tamanho recebido e o pedido."""
    return expect.get("grid") == "native" and list(received) == list(expect.get("size") or [])


def size_findings(expect: dict, check: dict) -> list[dict]:
    if expect["grid"] == "native" and not check["matches"]:
        return [{"code": "native_size_mismatch", "detail": f"pedido {expect['size']}, recebido {check['received']}: "
                 "nao se trata como nativo; a grade e detetada"}]
    if expect.get("scale_exact", True) and not check["matches"]:
        return [{"code": "size_mismatch", "detail": f"pedido {expect['size']}, recebido {check['received']}",
                 "hint": f"The image must be exactly {expect['size'][0]}x{expect['size'][1]} pixels."}]
    return []


def grid_finding(check: dict, detected: float | None, cells: list[int]) -> dict | None:
    """`detail` e para quem le o relatorio; `hint` (em ingles) vai para o gerador no prompt corretivo."""
    if detected is None or check["expected_period"] <= 1:
        return None
    want = check["expected_period"]
    deviation = abs(detected - want) / want
    check["detected_period"], check["period_deviation"] = round(detected, 3), round(deviation, 3)
    if deviation > 0.12:
        return {"code": "grid_not_followed", "detail": f"grade detetada {detected:.2f} px, pedida "
                f"{want:.2f} px: o gerador nao seguiu o pedido de grade",
                "hint": f"Use exactly {cells[0]}x{cells[1]} logical pixels for the whole image: every logical pixel "
                        f"is one solid block of about {want:.0f}x{want:.0f} image pixels, not {detected:.0f}x"
                        f"{detected:.0f}."}
    return None


def compare(expect: dict, received, detected: float | None) -> dict:
    """O confronto inteiro: o raster, os achados por ordem (tamanho, depois grade) e os que invalidam o contrato."""
    if not (expect.get("size") and expect.get("cells")):
        return {"raster": None, "findings": [], "hard": [], "pending": [],
                "not_compared": "o expect nao traz size e cells (o do forja prompt/plan traz): nada a conferir"}
    check = raster_check(expect, list(received))
    findings = size_findings(expect, check)
    grid = grid_finding(check, detected, expect["cells"])
    findings += [grid] if grid else []
    return {"raster": check, "findings": findings, "hard": [f["code"] for f in findings if f["code"] in HARD],
            "pending": [f["detail"] for f in findings]}


def mark(review: dict, comparison: dict) -> dict:
    """A revisao com a pendencia escrita: um tamanho errado invalida o contrato e pede outra geracao."""
    out = {**review, "review_reasons": list(review.get("review_reasons") or []) + comparison["pending"]}
    if comparison["hard"]:
        out.update(contract_valid=False, needs_regeneration=True,
                   verdicts={**review["verdicts"], "raster_contract": "fail"})
    return out


def from_period(frames: list[dict]) -> float | None:
    """A grade de uma prancha: a mediana dos periodos de cada quadro (os que tem grade)."""
    periods = sorted(f["period"] for f in frames if f.get("period", 0) > 1)
    if not periods:
        return None
    mid = len(periods) // 2
    return periods[mid] if len(periods) % 2 else (periods[mid - 1] + periods[mid]) / 2


def frame(exp: dict, canvas=None, pivot=None) -> tuple:
    """A tela, o pivot, a origem e a grade que o pedido de uma cena fixou (FORJA-09); o que foi dito na linha de
    comandos prevalece. A origem e a celula do canto da tela na grade pedida (a margem do Gemini incluida): com ela
    a figura fica onde a grade a pos, e os vaos e os sinais do contrato continuam no sitio."""
    held = exp.get("placement") == "origin"
    return (canvas or (tuple(exp["canvas_px"]) if exp.get("canvas_px") else None),
            pivot or (tuple(exp["pivot_px"]) if exp.get("pivot_px") else None),
            tuple(exp["content"][:2]) if held and not canvas else None, tuple(exp["cells"]) if held else None)
