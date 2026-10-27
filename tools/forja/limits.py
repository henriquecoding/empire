"""O que a forja acrescenta ao lint depois de pousar a figura: a que nao cabe na tela, o traco mais fino que a
grade e a imagem sem grade nenhuma. Cada um traz a frase para o gerador, e o corte cala as frases que sao a
mesma causa (auditoria de 26/10, O4 e O5).
"""
from __future__ import annotations

from PIL import Image

from . import lint
from .contracts import Contract


def too_big(contract: Contract, clipped: int, native: tuple[int, int]) -> dict:
    """A figura nao cabe na tela: reduzir nao redesenha (licao de 18/10/2026), gera-se de novo na grade certa."""
    return lint.finding("clipped", "error", f"{clipped} pixels ficaram fora da tela; a figura tem "
                        f"{native[0]}x{native[1]} pixels logicos. Reduzir nao redesenha feicoes: gerar de novo na "
                        "grade do contrato",
                        hint=f"Draw the figure smaller: {lint.tall(contract, native[1])} logical pixels tall, completely "
                             "inside its cell.")


def below_grid(sub: dict, box: list[int]) -> dict:
    """Detalhe desenhado mais fino que a grade (o rosto, quase sempre): o voto nao o recupera."""
    return lint.finding("subgrid", "warn", f"{sub['cells']} celulas misturadas ({sub['share']:.0%} da figura); a "
                        f"maior zona tem {sub['largest']} celulas em {box}: ali o gerador desenhou mais fino do que "
                        "a grade", [box], f"forja inpaint <png> --box {','.join(str(v) for v in box)} --change \"...\"",
                        "Draw the face and small details with whole pixels on the same grid as the body: eyes, mouth "
                        "and brows as 1-2 pixel marks, never lines thinner than one block.")


def clipped(report: dict, item: dict) -> dict:
    """O `clipped`, e as frases de altura e de margem que sao a mesma causa caladas para o gerador (O5)."""
    for f in report["findings"]:
        if f["rule"] in ("height", "margin") and f["prompt_hint"]:
            f["prompt_hint"], f["because"] = None, "clipped"
    return lint.add(report, item)


def no_grid(img: Image.Image, contract: Contract, size: tuple[int, int]) -> dict:
    """Uma imagem sem grade muito maior que a tela (O4): o relatorio de uma recusa, sem limpar milhoes de pixels."""
    item = lint.finding("no_grid", "error", f"nenhuma grade de pixel art numa imagem de {size[0]}x{size[1]}, mais "
                        f"do dobro da tela {contract.canvas[0]}x{contract.canvas[1]}: nao e pixel art nesta escala; "
                        "gerar de novo",
                        hint="Draw real pixel art: every logical pixel is one crisp solid square block on an exact "
                             "grid, with no painterly shading, blur or anti-aliasing.")
    coherence = {"status": "not_evaluated", "counts": {}, "figure": None, "where": [], "reason": "sem grade"}
    return {**lint._summary(img, contract, [item]), "coherence": coherence}


def losses(snapinfo: dict, to_final) -> list[dict]:
    """As celulas cujo conteudo a amostragem apagou (loss.py), mesmo com pureza alta e abaixo dos limiares do
    `subgrid`: uma so celula pode ser um olho. Informa onde, no PNG final; o que era fica no JSON (`snap.loss`)."""
    from .loss import groups
    info = snapinfo.get("loss") or {}
    if not info.get("erased_cells"):
        return []
    by = ", ".join(f"{n} {k}" for k, n in info["by_kind"].items() if n)
    boxes = [to_final(b) for b in groups(info)[:4]]
    return [lint.finding("erased", "warn", f"{info['erased_cells']} celulas com conteudo apagado pela amostragem "
                         f"({by}); pureza {snapinfo['sample'].get('purity')}: a pureza mede o miolo que ficou, nao o "
                         f"que saiu. Zonas no PNG final: {boxes}", boxes,
                         hint="Draw small features (eyes, brows, teeth, strings) as whole logical pixels: each mark "
                              "fills its whole block, never a partial block or a line thinner than one block.")]


def grid_origin(report: dict) -> list[dict]:
    """A reducao deliberada e o recuperado que nao cabe na tela, ditos como tal (FORJA-07)."""
    out = []
    if report["origin"] == "deliberately_reduced":
        out.append(lint.finding("grid_reduced", "info", "grade reduzida deliberadamente: o resultado e uma "
                                "adaptacao com perda e nao prova recuperacao fiel nem autoria nativa"))
    if report["fits_target"] is False:
        mix = report.get("mixed_scale")
        zones = (f"; quase toda a imagem segue uma grade de {mix['coarse_period']} px ({mix['coarse_cells'][0]}x"
                 f"{mix['coarse_cells'][1]} celulas) e {mix['fine_cells']} celulas pedem a de {mix['fine_period']} "
                 f"px, por exemplo {mix['zones'][:3]} na entrada") if mix else ""
        out.append(lint.finding("grid_budget", "warn", f"a grade {report['origin']} recupera {report['native_size'][0]}"
                                f"x{report['native_size'][1]} pixels e a tela e {report['target_canvas'][0]}x"
                                f"{report['target_canvas'][1]}{zones}. Reduzir para caber e adaptacao com perda "
                                "(desenho, --reduce), nao recuperacao", mix["zones"][:3] if mix else []))
    return out
