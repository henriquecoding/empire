"""A revisao automatica de uma animacao: o que se mede, o que so se suspeita e o que e do autor (F07).

Tres respostas que nunca se misturam (e, desde o FORJA-03, os sete vereditos de verdicts.py,
onde a geometria do equipamento e a pose ficam `not_evaluated` ate haver manifesto e observacao):
- `contract_valid`: contagem, tela, paleta, contorno, nada cortado. Mede-se.
- `motion_checks`: quadros estaticos, repetidos sem hold declarado, saltos sem
  intermedio, partes que somem, deriva do apoio. Indicios para rever; so um
  movimento que nao existe (todos os quadros iguais) obriga a gerar outra vez.
- `artistic_approval`: so o autor. A ferramenta escreve sempre "pendente".
Um hold e um quadro repetido de proposito: vem declarado, com a duracao e a razao;
`same_as` declara a reutilizacao de um quadro mais atras (ex.: levantar = queda invertida).
A ordem dos quadros e a continuidade de bracos, maos e objetos ficam sempre para
a revisao visual (velocidade real, quadro a quadro, onion skin).
"""
from __future__ import annotations

from PIL import Image

from . import verdicts
from .imageops import flat, foot_point

STATIC_TAGS = ("hold", "pose", "static", "portrait")


def parse_holds(items: list[str] | None) -> list[dict]:
    """'3:200:antecipacao' -> quadro 3 (a contar de 0) repete o anterior de proposito, 200 ms."""
    out = []
    for item in items or []:
        frame, _, rest = item.partition(":")
        ms, _, reason = rest.partition(":")
        if not reason.strip():
            raise ValueError(f"hold sem razao: {item!r} (use quadro:ms:razao)")
        out.append({"frame": int(frame), "ms": int(ms) if ms else None, "reason": reason.strip()})
    return out


def _mask(frame: Image.Image) -> set[int]:
    return {i for i, p in enumerate(flat(frame)) if p[3] >= 128}


def _components(frame: Image.Image) -> int:
    w = frame.width
    todo, count = _mask(frame), 0
    while todo:
        count += 1
        stack = [todo.pop()]
        while stack:
            i = stack.pop()
            x, y = i % w, i // w
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                j = ny * w + nx
                if 0 <= nx < w and j in todo:
                    todo.discard(j)
                    stack.append(j)
    return count


def motion(frames: list[Image.Image], tags: list[tuple], holds: list[dict] | None = None,
           align: str = "preserve", loop: bool | dict = True) -> dict:
    """Os indicios de uma timeline. Os pares comparam-se dentro de cada tag (e o fecho do loop dela)."""
    holds_at = {h["frame"]: h for h in holds or []}
    rasters = [f.tobytes() for f in frames]
    checks, blocking = [], []
    for name, start, end, *_ in tags:
        span = rasters[start:end + 1]
        declared = all(i in holds_at for i in range(start + 1, end + 1))
        if len(span) > 1 and len(set(span)) == 1 and name not in STATIC_TAGS and not declared:
            c = {"check": "static_tag", "status": "fail", "tag": name, "frames": [start, end],
                 "detail": f"'{name}': os {len(span)} quadros sao o mesmo raster — nao ha movimento"}
            checks.append(c)
            blocking.append(c)
    first: dict[bytes, int] = {}
    for i, r in enumerate(rasters):
        if i in holds_at:
            of = holds_at[i].get("same_as", i - 1)
            same = 0 <= of < len(rasters) and rasters[of] == r
            checks.append({"check": "hold", "status": "ok" if same else "flag", "frame": i, **holds_at[i],
                           "detail": "repeticao declarada" if same else
                           f"repeticao declarada, mas o quadro difere do {of}"})
        elif r in first:
            checks.append({"check": "hidden_duplicate", "status": "flag", "frame": i, "same_as": first[r],
                           "detail": f"quadro {i} repete o {first[r]} sem hold declarado"})
        first.setdefault(r, i)
    masks = [_mask(f) for f in frames]
    parts = [_components(f) for f in frames]
    pairs = []
    for name, start, end, *_ in tags:
        pairs += [(i, i + 1) for i in range(start, end)]
        if (loop.get(name, True) if isinstance(loop, dict) else loop) and end - start >= 2:
            pairs.append((end, start))
    for a, b in pairs:
        if rasters[a] == rasters[b] or not masks[a] or not masks[b]:
            continue
        shared = len(masks[a] & masks[b]) / min(len(masks[a]), len(masks[b]))
        if shared < 0.35:
            checks.append({"check": "big_jump", "status": "flag", "frames": [a, b], "overlap": round(shared, 3),
                           "detail": "pouca sobreposicao entre quadros seguidos: falta um intermedio?"})
        change = (len(masks[b]) - len(masks[a])) / len(masks[a])
        if change < -0.25 or parts[b] < parts[a]:
            checks.append({"check": "part_lost", "status": "flag", "frames": [a, b], "area_change": round(change, 3),
                           "components": [parts[a], parts[b]],
                           "detail": "area ou pecas a menos: um braco, mao ou arma pode ter sumido"})
    feet = [foot_point(f) for f in frames]
    if align == "feet":
        checks.append({"check": "support", "status": "n/a",
                       "detail": "cada quadro alinhado pelo proprio apoio: deriva zero imposta, nao e evidencia"})
    else:
        ground = max((p[1] for p in feet if p), default=0)
        xs = [p[0] for p in feet if p and p[1] == ground]
        spread = max(xs) - min(xs) if xs else 0
        checks.append({"check": "support", "status": "info" if spread > 2 else "ok", "grounded": len(xs),
                       "spread_px": spread, "detail": f"o apoio no chao varia {spread} px na horizontal (num ciclo no "
                       "lugar o pe recua por desenho: conferir no jogo, a velocidade real)"})
    checks.append({"check": "order_and_limbs", "status": "visual",
                   "detail": "ordem dos quadros e continuidade de bracos, maos e objetos: so na revisao visual"})
    reasons = [c["detail"] for c in checks if c["status"] in ("fail", "flag", "visual")]
    return {"motion_checks": checks, "blocking": blocking, "flags": sum(c["status"] == "flag" for c in checks),
            "review_reasons": reasons}


def verdict(contract_valid: bool, motion_result: dict | None) -> dict:
    blocking = bool(motion_result and motion_result["blocking"])
    return {"contract_valid": contract_valid,
            "motion_checks": motion_result["motion_checks"] if motion_result else None,
            "needs_regeneration": not contract_valid or blocking, "needs_review": True,
            "review_reasons": motion_result["review_reasons"] if motion_result else ["revisao visual do desenho"],
            "artistic_approval": "pendente",
            "verdicts": verdicts.summary(verdicts.for_review(contract_valid, motion_result,
                                                             2 if motion_result else 1))}
