"""Vereditos que nao se misturam: um por pergunta, e nenhuma nota que esconda uma falha (FORJA-03).

O relatorio de 24-25/10 mostrou que um ficheiro pode cumprir o contrato raster e ter duas guardas na
espada. Por isso cada pergunta tem a sua resposta e nao ha media: uma paleta boa nao compensa uma
segunda lamina. O que nao foi avaliado diz `not_evaluated` e nunca passa a `pass` por falta de erro;
a aprovacao artistica e sempre do autor e a ferramenta so escreve `pending`.
"""
from __future__ import annotations

AXES = ("raster_contract", "color_coherence", "equipment_geometry", "functional_pose", "identity_consistency",
        "temporal_consistency", "artistic_approval", "runtime_integration")
STATES = ("pass", "fail", "needs_review", "inconclusive", "not_evaluated", "not_applicable", "pending", "not_tested")
QUESTIONS = {
    "raster_contract": "tela, alfa, paleta, contorno, pivo, nada cortado",
    "color_coherence": "a cor forma massas: nenhum fragmento de 1-3 px sem papel declarado (planos e banding a olho)",
    "equipment_geometry": "as partes de cada objeto existem, na quantidade certa, construidas e ligadas",
    "functional_pose": "a pose comunica um uso possivel: mao na empunhadura, corda no estado certo",
    "identity_consistency": "continua a ser o mesmo personagem e o mesmo objeto da referencia aceita",
    "temporal_consistency": "nada troca de mao, some ou muda de tamanho entre quadros",
    "artistic_approval": "so o autor",
    "runtime_integration": "visto no motor, com camadas, pivos, tempos e sockets",
}
_ORDER = ("fail", "inconclusive", "needs_review", "not_evaluated")


def initial(frames: int = 1) -> dict:
    """Nada avaliado ainda: e assim que um relatorio comeca, e nao como aprovado."""
    out = {axis: {"status": "not_evaluated", "evidence": []} for axis in AXES}
    out["temporal_consistency"]["status"] = "not_applicable" if frames <= 1 else "not_evaluated"
    out["artistic_approval"]["status"] = "pending"
    out["runtime_integration"]["status"] = "not_tested"
    return out


def put(verdicts: dict, axis: str, status: str, evidence=None) -> dict:
    if axis not in AXES:
        raise ValueError(f"eixo desconhecido: {axis}")
    if status not in STATES:
        raise ValueError(f"estado desconhecido: {status}")
    if axis == "artistic_approval" and status != "pending":
        raise ValueError("a aprovacao artistica e do autor: a Forja so escreve 'pending'")
    if axis == "runtime_integration" and status == "pass":
        raise ValueError("a integracao so passa quando foi vista no motor: registe-a fora da Forja")
    verdicts[axis] = {"status": status, "evidence": list(evidence or [])}
    return verdicts


def combine(statuses: list[str]) -> str:
    """O estado de um eixo a partir dos estados das suas verificacoes, sem media.

    Uma falha manda. So passa quando tudo o que se aplica passou; avaliado em parte e inconclusivo."""
    live = [s for s in statuses if s != "not_applicable"]
    if not statuses:
        return "not_evaluated"
    if not live:
        return "not_applicable"
    for status in _ORDER:
        if status in live and (status != "not_evaluated" or all(s == "not_evaluated" for s in live)):
            return status
    if "not_evaluated" in live:
        return "inconclusive"
    return "pass" if all(s == "pass" for s in live) else "needs_review"


def from_checks(verdicts: dict, axis: str, checks: list[dict]) -> dict:
    """Pousa num eixo o resultado das verificacoes que lhe pertencem, com elas como evidencia."""
    mine = [c for c in checks if c.get("axis") == axis]
    return put(verdicts, axis, combine([c["status"] for c in mine]), mine)


def for_review(contract_valid: bool, motion_result: dict | None, frames: int = 1,
               coherence: dict | list[dict] | None = None) -> dict:
    """Os vereditos da revisao automatica de uma figura ou prancha (sem manifesto de equipamento).

    `coherence`: o diagnostico de cor (clusters.py) da figura, ou um por quadro; nunca bloqueia."""
    v = initial(frames)
    put(v, "raster_contract", "pass" if contract_valid else "fail")
    if coherence is not None:
        found = coherence if isinstance(coherence, list) else [coherence]
        put(v, "color_coherence", combine([c["status"] for c in found]),
            [{"status": c["status"], "counts": c["counts"]} for c in found])
    if motion_result is not None:
        blocking = bool(motion_result["blocking"])
        put(v, "temporal_consistency", "fail" if blocking else "needs_review", motion_result["review_reasons"])
    return v


def blocking(verdicts: dict) -> list[str]:
    """Os eixos que falharam."""
    return [axis for axis in AXES if verdicts[axis]["status"] == "fail"]


def summary(verdicts: dict) -> dict:
    """Eixo -> estado, para ler de relance (a evidencia fica no relatorio completo)."""
    return {axis: verdicts[axis]["status"] for axis in AXES}
