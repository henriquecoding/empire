"""O plano de um pedido, por gerador, validado antes de qualquer rede (auditoria F02 e F03).

Cada gerador recebe o que realmente aceita, e o plano escreve-o:
- PixelLab: o canvas nativo do contrato (royal_64 -> 64x64, royal_80 -> 80x80,
  character_s2 -> 96x96), conferido contra os limites do modelo; o design aprovado
  vai como `init_image` e a paleta como `color_image`, com hash. Pranchas animadas
  nao: os endpoints de imagem sao estaticos e os de animacao ainda nao estao ligados.
- gpt-image: lados livres (multiplos de 16) e escala exata; com imagens anexadas o
  pedido vai para /images/edits, com o papel de cada imagem no texto.
- Gemini: uma proporcao e uma resolucao que o modelo suporta; a prancha centrada
  nessa proporcao, com as margens escritas em pixels logicos; o tamanho em pixels
  e estimado, e quem recorta mede o que chegou.
O prompt so promete as imagens que vao anexadas. Um plano nao e arte produzida.
"""
from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass, field
from pathlib import Path

from . import contracts, fidelity as fidelity_mod, guides, owner_rules, plan_native, production, prompts, refs as refs_mod
from .backends import Call, gemini_images, openai_images, pixellab_api, pixellab_convert, sha
from .imageops import png_bytes as png
from .palette import Palette

BACKENDS = ("openai", "gemini", "pixellab")
GUIDES = ("auto", "none", "palette", "layout", "all")
_UNREVIEWED = "nao avaliada: confirmar os termos do fornecedor antes de qualquer uso em treino"
PERMISSION = {"pixellab": "proibido treinar ou destilar sem autorizacao escrita do PixelLab (termos lidos em "
                          "23/10/2026)", "openai": _UNREVIEWED, "gemini": _UNREVIEWED}


@dataclass
class Plan:
    data: dict
    images: list[tuple[str, bytes]] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.data["errors"]

    def call(self, prompt: str | None = None) -> Call:
        """O pedido deste plano (com o prompt dado, ou o do plano)."""
        if not self.ok:
            raise ValueError("plano invalido: " + "; ".join(self.data["errors"]))
        d, prompt = self.data, prompt or self.data["prompt"]
        context = (d.get("expect") or {}).get("owner_rules")
        if not context or context.get("revision") != owner_rules.context()["revision"]:
            raise ValueError("plano sem consulta atual das regras do dono: compilar de novo antes de gerar")
        if context and d["model"] != pixellab_convert.MODEL and "FORJA_OWNER_RULES:" + context["revision"] not in prompt:
            raise ValueError("prompt substituido sem as regras do dono: compilar de novo antes de gerar")
        if d["model"] != pixellab_convert.MODEL and any(r["text"] not in prompt for r in
                owner_rules.prompt_rules(d["kind"], d["frames"] > 1)):
            raise ValueError("prompt sem o texto das regras do dono: compilar de novo antes de gerar")
        r = d["request"]
        if d["backend"] == "pixellab" and d["model"] == pixellab_convert.MODEL:
            return pixellab_convert.call(self.images[0][1], r["width"], r["height"], **r["params"])
        if d["backend"] == "pixellab":
            kw = {**r["params"], **{role: data for role, data in self.images}}
            return pixellab_api.call(prompt, r["width"], r["height"], d["model"], **kw)
        roles = [refs_mod.family(x) for x, _ in self.images]
        if d["backend"] == "openai":
            if self.images:
                return openai_images.edit_call(prompt, [b for _, b in self.images], None, r["size"], d["model"],
                                               background=r["background"], roles=roles)
            return openai_images.generate_call(prompt, r["size"], d["model"], background=r["background"])
        return gemini_images.call(prompt, list(zip(roles, [b for _, b in self.images])), d["model"],
                                  r["aspect_ratio"], r["image_size"])

    def write(self, folder: str | Path) -> Path:
        out = Path(folder)
        out.mkdir(parents=True, exist_ok=True)
        for (role, data), entry in zip(self.images, self.data["attachments"]):
            path = out / f"attach_{entry['index']:02d}_{role}.png"
            path.write_bytes(data)
            entry["file"] = str(path)
        (out / "plan.json").write_text(json.dumps(self.data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        (out / "prompt.txt").write_text(self.data["prompt"] + "\n", encoding="utf-8")
        return out / "plan.json"


def _want(guides_mode: str, role: str, palette: Palette | None, listed: int = 24) -> bool:
    if role == "palette":
        return palette is not None and (guides_mode in ("palette", "all") or
                                        (guides_mode == "auto" and len(palette) > listed))
    return guides_mode in ("layout", "all")


def _built(d: dict, palette, target: str, background: str, attached: list[str], geo: dict) -> dict:
    built = prompts.build(d["subject"], d["kind"], d["tags"], d["facing"], False, palette, target, background,
                          attached=attached, geo=geo, mode=d["mode"], fidelity=d["fidelity_prompt"])
    d.update(constraints=built["constraints"], implicit=built["implicit"])
    return built


def _attach(d: dict, refs, palette, guides_mode, expect_for_layout) -> list[tuple[str, bytes]]:
    images = [(r, data) for r, data in refs if refs_mod.family(r) in ("identity", "style")]
    if _want(guides_mode, "palette", palette):
        images.append(("palette", png(guides.palette_swatch(palette))))
    if _want(guides_mode, "layout", palette) and d["frames"] > 1:
        c = contracts.get(d["kind"])
        pivot_row = c.pivot[1] // c.cluster if c.pivot else None
        images.append(("layout", png(guides.template(expect_for_layout, pivot_row))))
    return images


def _openai(d: dict, refs, palette, model, guides_mode, background) -> list[tuple[str, bytes]]:
    try:
        model = d["model"] = openai_images.check_model(model or openai_images.DEFAULT_MODEL)
    except ValueError as err:
        d["errors"].append(str(err))
        return []
    geo = prompts.geometry(d["kind"], d["tags"], "gpt-image")
    probe = _built(d, palette, "gpt-image", background, [], geo)["expect"]
    images = _attach(d, refs, palette, guides_mode, probe)
    if len(images) > openai_images.MAX_IMAGES:
        d["errors"].append(f"gpt-image: ate {openai_images.MAX_IMAGES} imagens; o plano tem {len(images)}")
    built = _built(d, palette, "gpt-image", background, [r for r, _ in images], geo)
    try:
        openai_images.check_size(built["size"], model)
    except ValueError as err:
        d["errors"].append(str(err))
    bg = "transparent" if built["expect"]["background"] == "transparent" else "opaque"
    d["request"] = {"endpoint": "images.edits" if images else "images.generations", "size": built["size"],
                    "background": bg}
    d.update(prompt=built["prompt"], expect=built["expect"], advice=built["advice"],
             authoring="generated_high_resolution_then_grid_recovered")
    return images


def _gemini(d: dict, refs, palette, model, guides_mode, background, size) -> list[tuple[str, bytes]]:
    try:
        caps = gemini_images.capabilities(model)
    except ValueError as err:
        d["errors"].append(str(err))
        return []
    model = d["model"] = caps["model"]
    base = prompts.geometry(d["kind"], d["tags"], "gemini")
    lw, lh = base["logical"]
    aspect, w, h = gemini_images.fit_aspect(lw, lh, caps["aspects"])
    ox, oy = (w - lw) // 2, (h - lh) // 2
    if size and size not in caps["sizes"]:
        d["errors"].append(f"{model}: resolucao {size} nao suportada (use {', '.join(caps['sizes'])})")
        size = None
    size = size or next((s for s in caps["sizes"] if gemini_images.estimate(aspect, s, model)[0] / w >= 8),
                        caps["sizes"][-1])
    est = gemini_images.estimate(aspect, size, model)
    geo = {**base, "logical": [w, h], "content": [ox, oy, ox + lw, oy + lh], "scale": round(est[0] / w, 2),
           "size": list(est), "exact": False}
    probe = _built(d, palette, "gemini", background, [], geo)["expect"]
    images = _attach(d, refs, palette, guides_mode, probe)
    d["errors"] += gemini_images.check(model, aspect, size, [refs_mod.family(r) for r, _ in images])
    built = _built(d, palette, "gemini", background, [r for r, _ in images], geo)
    d["request"] = {"endpoint": "interactions", "aspect_ratio": aspect, "image_size": size,
                    "estimated_output": list(est),
                    "output_size_known": gemini_images.published(model, aspect, size) is not None}
    d.update(prompt=built["prompt"], expect=built["expect"], advice=built["advice"],
             authoring="generated_high_resolution_then_grid_recovered")
    d["notes"].append(f"Gemini {aspect} {size}: saida estimada {est[0]}x{est[1]} (tabela de pixels nao documentada); "
                      f"prancha de {lw}x{lh} logicos centrada em {w}x{h}, margem ({ox},{oy})")
    return images


def make(backend: str, subject: str, kind: str | None = None, tags: list[tuple[str, int]] | None = None,
         facing: str = "right", references: list[tuple[str, str]] = (), palette: Palette | None = None,
         model: str | None = None, guides_mode: str = "auto", background: str = "auto",
         init_strength: int | None = None, seed: int | None = None, size: str | None = None,
         register: dict | None = None, mode: str | None = None, fidelity: dict | None = None,
         character: str | None = None, pose: str | None = None, decisions: dict | None = None) -> Plan:
    """`references`: (papel, caminho) com papel identity, concept ou style; o estado de cada uma vem do `register`
    (refs.py) e decide as palavras do prompt (FORJA-06). `fidelity` (fidelity.py) com `character`/`pose` prende o
    pedido a autoridade e da o modo (FORJA-07); `decisions`: max_colors e tones ditos no pedido. Nada sai para a rede."""
    if guides_mode not in GUIDES:
        raise ValueError(f"guias: {', '.join(GUIDES)}")
    ch = fidelity_mod.character(fidelity, character, pose) if fidelity and character else None
    selected = production.resolve(subject, kind, ch)
    kind = selected["kind"]
    given = [(r, str(p), Path(p).read_bytes()) for r, p in references]
    seen = [(name, data, *refs_mod.resolve(r, data, register)) for r, name, data in given]
    prep = fidelity_mod.prepare(fidelity, character, pose, mode, [(got[2] or ref[0], *ref[1:])
                                                                  for ref, got in zip(given, seen)])
    references = list(references) + [(r, name) for r, name, _ in prep["attach"]]
    seen += [(name, data, *refs_mod.resolve(r, data, register)) for r, name, data in prep["attach"]]
    refs = [(r, data) for _, data, r, _, err in seen if not err]
    states = [rec["state"] for _, _, r, rec, err in seen if not err and refs_mod.family(r) == "identity"]
    d: dict = {"schema": 1, "backend": backend, "model": model, "kind": kind, "subject": subject, "facing": facing,
               "tags": [list(t) for t in tags] if tags else None, "frames": sum(n for _, n in tags) if tags else 1,
               "references": [{"role": role, "prompt_role": r, "path": p, "sha256": sha(data), "state": rec["state"],
                               "id": rec["id"]} for (role, _), (p, data, r, rec, _) in zip(references, seen)],
               "authority": {"stage": refs_mod.stage(states), "states": states, "register": register and register["path"]},
               "errors": [f"referencia {p}: {err}" for p, _, _, _, err in seen if err], "notes": [], "prompt": "",
               "expect": None, "request": None, "advice": None,
               "training_permission": PERMISSION.get(backend), "contracts": contracts.get(kind).as_dict()}
    d.update(mode=prep["mode"], fidelity=prep["record"], production=selected, constraints=[], implicit=[],
             fidelity_prompt={**(prep["prompt"] or {}), **(decisions or {}), "role": selected["role"]})
    d["errors"] += selected["errors"] + prep["errors"] + fidelity_mod.guide_alone(prep["mode"], seen, states)
    d["notes"] += prep["notes"] + ([] if "approved" in states else
                                   ["recuperacao: o que sair e uma adaptacao em revisao, nao um mestre"])
    d["errors"] += [f"assunto: {c}" for c in prompts.camera_conflicts(subject, facing)]
    if backend == "pixellab":
        images = plan_native.prepare(d, contracts.get(kind), refs, palette, model, guides_mode, init_strength, seed)
    elif backend == "openai":
        images = _openai(d, refs, palette, model, guides_mode, background)
    elif backend == "gemini":
        images = _gemini(d, refs, palette, model, guides_mode, background, size)
    else:
        raise ValueError(f"gerador desconhecido: {backend} (use {', '.join(BACKENDS)})")
    if d["expect"] is not None:
        d["expect"].update(role=selected["role"], target_useful_bbox=d["fidelity_prompt"].get("target_useful_bbox"))
        d["expect"]["owner_rules"] = owner_rules.context(prep["record"])
    d["attachments"] = [{"index": i, "role": refs_mod.family(r), "prompt_role": r, "sha256": sha(b), "bytes": len(b)}
                        for i, (r, b) in enumerate(images, 1)]
    d["prompt_sha256"] = hashlib.sha256(d["prompt"].encode("utf-8")).hexdigest()
    return Plan(d, images)
