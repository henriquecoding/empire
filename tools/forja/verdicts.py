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


CONDITIONS = {
    "matches_authority": "corresponde ao conceito de autoridade: identidade, expressao e proporcoes (a olho, o dono)",
    "contract_and_materials": "tela, grade e papeis de material: o contrato raster passa e nenhum conflito de rampa "
                              "fica pendente",
    "preserved_outside_change": "fora da mudanca autorizada, os pixels do mestre (so numa edicao local)",
    "review_recorded": "o estado real de revisao registado: a aprovacao do dono, para esta imagem exata",
}
_CLOSED = ("pass", "not_applicable")


def closure(summary: dict, approval: dict, material: dict | None = None, preservation: dict | None = None) -> dict:
    """As quatro condicoes de uma entrega (solucao de 27/10, §9; FORJA-06). Um eixo `not_evaluated` nunca fecha
    nada. O que so o dono ve (identidade, aprovacao) fecha-se pelo registo dele desta imagem exata; um lint limpo, um
    hash igual ou uma prova de preservacao sao evidencia de ficheiro e nunca passam por aprovacao."""
    owner = approval.get("status") == "approved"
    raster, mat = summary.get("raster_contract", "not_evaluated"), (material or {}).get("status", "not_evaluated")
    cond = {"matches_authority": "fail" if summary.get("identity_consistency") == "fail" else
            ("pass" if owner else "pending"), "review_recorded": "pass" if owner else "pending"}
    if raster != "pass":
        cond["contract_and_materials"] = raster
    elif mat == "pending":
        cond["contract_and_materials"] = "pending"
    else:
        cond["contract_and_materials"] = "pass" if mat == "resolved" or owner else "not_evaluated"
    if preservation is None:
        cond["preserved_outside_change"] = "not_applicable"
    else:
        kept = preservation.get("outside_identical") and preservation.get("protected_identical")
        cond["preserved_outside_change"] = "pass" if kept else "fail"
    failed = [a for a in AXES if summary.get(a) == "fail"]
    missing = (["identity_consistency"] * (cond["matches_authority"] != "pass")
               + ["raster_contract"] * (raster != "pass") + ["material"] * (raster == "pass" and
                                                                           cond["contract_and_materials"] != "pass")
               + ["preservation"] * (cond["preserved_outside_change"] not in _CLOSED)
               + ["artistic_approval"] * (not owner))
    done = all(s in _CLOSED for s in cond.values()) and not failed
    return {"deliverable": done, "state": "approved" if done else "adaptation_in_review",
            "conditions": {k: {"status": v, "question": CONDITIONS[k]} for k, v in cond.items()},
            "missing": list(dict.fromkeys(missing + failed)), "approval": approval,
            "note": "lint, hashes e provas sao evidencia de ficheiro: nao e aprovacao artistica; essa e do dono, no "
                    "registo forja.refs/1"}
