"""A revisao em quatro estados que nao se misturam (FORJA-07; auditoria de 27/10, §15.2 e §16.4).

Ha quatro perguntas, com evidencias diferentes, e nenhuma nota que as junte:

1. `runtime` — o ficheiro cumpre o contrato do jogo (o lint raster). E evidencia de ficheiro.
2. `declared_feature_preservation` — os sinais declarados (pinos e regioes do contrato de fidelidade, e os do forge)
   chegaram ao PNG final: `signals.py`. Sem nada declarado, pendente.
3. `identity_and_pose` — e o mesmo personagem, com a roupa, a atuacao, as proporcoes, as maos e o equipamento da
   pose de autoridade. So uma pessoa o diz: um registo `identity_reviews` com quem reviu, quando, o hash dos pixels e
   uma observacao por aspeto (ASPECTS), ou a aprovacao do dono desta imagem no `forja.refs/1`. Um candidato rejeitado
   (no contrato ou no registo) fica `blocked`, por mais que passe no runtime: o arqueiro de tunica verde comprida.
4. `native_master_approval` — o dono aprovou ESTA imagem como mestre (`refs.approval`). A Forja nunca o escreve.

`technical_pass` nao preenche nenhum dos outros: um estado sem avaliacao fica `pending`; uma exigencia reprovada,
`blocked`.

FORJA-15 (auditoria de fidelidade de 29/10): o fecho e um so. `deliverable` (e `release_ready`) pede os quatro em
`pass` E a cadeia de etapas sem perda critica aberta (`lineage.closure`): zero perdas na ultima etapa nao encerra a de
antes. Os sinais do estado 2 sao os herdados da autoridade (regioes criticas, a ficha facial `face.py` e os pinos com
`source_kind: authority`); os pinos tirados do proprio candidato protegem-no (`candidate_protection`) e nao provam
fidelidade ao conceito. A preservacao vale para esta etapa (`scope`). Sem fecho, o candidato e um estudo (`label`).
"""
from __future__ import annotations

from PIL import Image, ImageDraw

from . import delivery_review, face, fidelity, lineage, production, refs, signals, visual_review
from .equipment import image_sha
from .imageops import on_background, upscale

STATES = ("runtime", "declared_feature_preservation", "identity_and_pose", "native_master_approval")
ASPECTS = ("face", "clothing", "proportions", "hands", "equipment")


def identity(ch: dict, candidate: Image.Image, reg: dict | None, visual: dict | None = None) -> dict:
    bad = fidelity.rejected(ch, candidate)
    if bad:
        return {"status": "blocked", "evidence": [f"candidato rejeitado por {bad['decided_by']} em {bad['date']}: "
                                                  + "; ".join(bad.get("reasons", []))]}
    rec = refs.record(reg, candidate)
    if rec["state"] == "rejected":
        return {"status": "blocked", "evidence": [f"registo {rec['register']}: {rec['id']} rejeitada"]}
    seen = visual_review.state(visual, candidate, ch) if visual else None
    if seen and visual.get("phase") != "candidate":
        seen = {**seen, "status": "invalid", "errors": [f"revisao da fase {visual.get('phase')!r}: a evidencia do "
                                                         "candidato e uma revisao candidate desta imagem"]}
    if seen and seen["status"] in ("invalid", "blocked"):
        return {"status": "blocked", "evidence": seen.get("errors") or seen["blocking"], "visual_review": seen}
    if seen:
        derived = visual_review.issue_reviews(visual)
        ch = {**ch, "reference_issue_reviews": ch.get("reference_issue_reviews", []) + derived}
    repairs = production.repairs_state(ch, image_sha(candidate))
    if repairs["status"] != "pass":
        return repairs
    if seen and seen["status"] == "pending":
        return {"status": "pending", "evidence": seen["uncertain"], "visual_review": seen}
    if refs.approval(reg, candidate)["status"] == "approved":
        return {"status": "pass", "evidence": [f"aprovada pelo dono no registo ({rec['id']})"]}
    sha = image_sha(candidate)
    for r in ch.get("identity_reviews", []):
        if r.get("pixels_sha256") != sha:
            continue
        missing = [a for a in ASPECTS if not str((r.get("observations") or {}).get(a, "")).strip()]
        if r.get("status") == "fail":
            return {"status": "blocked", "evidence": [f"revista por {r.get('reviewed_by')} em {r.get('date')}: "
                                                      "divergencia obrigatoria", r.get("observations")]}
        if r.get("status") == "pass" and r.get("reviewed_by") and r.get("date") and not missing:
            return {"status": "pass", "evidence": [f"revista por {r['reviewed_by']} em {r['date']}",
                                                   r["observations"]]}
        return {"status": "pending", "evidence": [f"revisao incompleta: faltam {missing or ['quem e quando']}"]}
    return {"status": "pending", "evidence": ["sem revisao de identidade desta imagem (conceito e candidato lado a "
                                              "lado, por aspeto)"]}


def preservation(ch: dict, candidate: Image.Image, forge: dict | None) -> dict:
    """O estado 2: os sinais herdados da autoridade nesta etapa; os pinos do candidato so como protecao local."""
    kind = {p.get("id"): p.get("source_kind") for p in ch.get("pixel_pins", [])}
    pins = signals.target_pins(candidate, ch.get("pixel_pins", []))
    authority, local = [p for p in pins if kind.get(p["id"]) == "authority"], [
        p for p in pins if kind.get(p["id"]) != "authority"]
    erased = info = None
    if forge:
        local += forge.get("signals", {}).get("pins", [])
        erased = ((forge.get("snap") or {}).get("loss") or {}).get("erased", []) if forge.get("snap") else None
        info = forge.get("finish")
    sig = signals.state(authority, signals.regions(ch.get("critical_regions", []), erased, info))
    faces, guard = face.check(ch.get("face_sheet"), candidate), signals.state(local, [])
    blocked = sig["blocked"] + faces["blocked"] + (guard["blocked"] if local else [])
    pending = sig["pending"] + faces["pending"]
    return {"status": "blocked" if blocked else "pending" if pending else "pass", "evidence": blocked + pending,
            "signals": sig, "face": faces, "scope": "this_stage",
            "candidate_protection": {"pins": len(local), "status": guard["status"] if local else "none",
                                     "note": "pinos tirados do candidato protegem-no; nao provam fidelidade"}}


def review(ch: dict, candidate: Image.Image, reg: dict | None = None, lint_result: dict | None = None,
           forge: dict | None = None, visual: dict | None = None, resolutions: list[dict] | None = None) -> dict:
    """Os quatro estados de um candidato contra a pose de autoridade `ch` do contrato de fidelidade, e o fecho."""
    runtime = ({"status": "pending", "evidence": ["contrato raster nao conferido"]} if lint_result is None else
               {"status": "pass" if lint_result["ok"] else "blocked",
                "evidence": [f["message"] for f in lint_result["findings"] if f["severity"] == "error"]})
    kept = preservation(ch, candidate, forge)
    approval = refs.approval(reg, candidate)
    states = {"runtime": runtime, "declared_feature_preservation": kept,
              "identity_and_pose": identity(ch, candidate, reg, visual),
              "native_master_approval": {"status": "pass" if approval["status"] == "approved" else "pending",
                                         "evidence": [approval]}}
    req = [r for r in ch.get("critical_regions", []) if r.get("required")]
    release = lineage.closure((forge or {}).get("lineage"), candidate,
                              {r["id"]: r["target_box"] for r in req if r.get("target_box")} |
                              face.boxes(ch.get("face_sheet")), resolutions or [],
                              [r["id"] for r in req if not r.get("target_box")])
    blocked = [k for k in STATES if states[k]["status"] == "blocked"] + (
        ["inherited_losses"] if release["status"] == "blocked" else [])
    protocol = delivery_review.check(ch, candidate, forge, visual)
    if protocol["status"] == "blocked":
        blocked.append("owner_rules")
    done = all(states[k]["status"] == "pass" for k in STATES) and release["status"] == "pass" and protocol["ready_for_review"]
    ready = protocol["ready_for_review"] and release["status"] == "pass" and all(
        states[k]["status"] == "pass" for k in STATES if k != "native_master_approval")
    return {"character": ch["id"], "pose": ch["pose"], "candidate_pixels_sha256": image_sha(candidate),
            "states": states, "summary": {k: states[k]["status"] for k in STATES}, "blocked": blocked,
            "release": release, "deliverable": done, "release_ready": done,
            "production_review": protocol, "ready_for_review": ready,
            "raster_valid": runtime["status"] == "pass", "label": "release" if done else "blocked" if blocked else "study",
            "technical_pass": runtime["status"] == "pass", "technical_pass_implies_identity_pass": False,
            "note": "a Forja nao preenche a identidade nem a aprovacao: sao de quem reve e do dono; um estudo "
                    "exporta-se, mas nao se chama mestre concluido"}


def sheet(contract: dict, ch: dict, candidate: Image.Image, height: int = 320) -> Image.Image:
    """Conceito e candidato lado a lado, na mesma pose de autoridade: o conceito reduzido so para ver (fora da
    grade), o candidato a 1x e ampliado por um inteiro; por baixo, cada regiao com caixa nas duas imagens."""
    concept = fidelity.authority_crop(contract, ch).convert("RGB")
    concept = concept.resize((max(1, round(concept.width * height / concept.height)), height))
    k = max(1, height // candidate.height)
    big = on_background(upscale(candidate, k)).convert("RGB")
    small = on_background(candidate).convert("RGB")
    rows = [r for r in ch.get("critical_regions", []) if r.get("authority_box") and r.get("target_box")]
    width = concept.width + small.width + big.width + 64
    out = Image.new("RGB", (max(width, 480), height + 56 + 136 * len(rows)), (24, 30, 36))
    draw = ImageDraw.Draw(out)
    x = 16
    for label, im in (("conceito (autoridade, fora da grade)", concept), ("candidato 1x", small),
                      (f"candidato {k}x", big)):
        out.paste(im, (x, 32))
        draw.text((x, 10), label, fill=(240, 230, 210))
        x += im.width + 16
    y = height + 48
    with Image.open(f"{contract['base']}/{contract['authority']['file']}") as auth:
        for r in rows:
            a = auth.convert("RGB").crop(tuple(r["authority_box"]))
            a = a.resize((max(1, round(a.width * 120 / a.height)), 120))
            t = on_background(candidate.crop(tuple(r["target_box"]))).convert("RGB")
            t = upscale(t, max(1, 120 // t.height))
            draw.text((16, y), r["id"], fill=(240, 230, 210))
            out.paste(a, (120, y))
            out.paste(t, (136 + a.width, y))
            y += 136
    return out
