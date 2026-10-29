"""`forja.face_sheet/1`: a ficha facial de cada personagem, presa ao conceito escolhido (FORJA-15, P0-03).

Auditoria de fidelidade de 29/10, caso B: a direcao do olhar nao basta para reproduzir uma expressao. Os contratos
tinham uma caixa critica de rosto e os pinos da etapa final eram tirados da propria adaptacao: impediam outra mudanca,
nao provavam que a adaptacao era fiel. A ficha regista, por personagem, a intencao da expressao e os marcos que a fazem
reconhecivel (olho e palpebra, pupila, sobrancelhas, nariz, cantos da boca, dentes, pelos), cada um com a caixa no
conceito (`authority_box`, a evidencia) e a caixa reservada na grade nativa (`target_box`), e as relacoes entre eles:

- `offset`: onde fica um marco dentro de outro (a pupila no olho: o olhar);
- `asymmetry`: a altura das duas pontas de um traco (o sorriso torto, a sobrancelha cetica);
- `above`: um marco acima de outro (sobrancelha sobre o olho);
- `pieces`: quantos agrupamentos separados (dentes com espaco entre eles);
- `extent`: largura ou altura minima (o nariz grande que se projeta).

As relacoes dizem-se no sentido do conceito; `target_mirrored` diz que o sprite olha para o outro lado (esquerda e
direita trocam).

As relacoes medem-se em agrupamentos de pixels das cores declaradas do marco, nao em cores soltas. A maquina sinaliza;
o que nao e deterministico fica para a revisao visual. Um nariz grande, a assimetria, dentes irregulares e olhos
semicerrados sao escolhas aprovadas, nao ruido a limpar. Sem caixa no destino ou sem cores, o marco fica `pending`.
"""
from __future__ import annotations

from PIL import Image

from . import color

SCHEMA = "forja.face_sheet/1"
FEATURES = ("eye", "lid", "pupil", "brow", "nose", "mouth", "mouth_corner", "teeth", "tongue", "facial_hair",
            "glasses", "cheek", "wrinkle", "other")
RELATIONS = {"offset": ("a", "within", "expect"), "asymmetry": ("a", "expect"), "above": ("a", "b"),
             "pieces": ("a", "min"), "extent": ("a", "axis", "min")}
EXPECT = {"offset": ("left", "right", "up", "down", "center"), "asymmetry": ("left_higher", "right_higher", "level")}


def _box(b, size=None) -> bool:
    ok = isinstance(b, list) and len(b) == 4 and all(type(v) is int for v in b) and b[0] < b[2] and b[1] < b[3]
    return ok and (size is None or (0 <= b[0] and 0 <= b[1] and b[2] <= size[0] and b[3] <= size[1]))


def validate(sheet: dict | None, canvas=None, crop=None) -> list[str]:
    """Os erros da ficha (vazia: valida). `canvas`: a tela de destino; `crop`: o recorte de autoridade."""
    if sheet is None:
        return []
    errors = [] if sheet.get("schema") == SCHEMA else [f"ficha facial: schema esperado {SCHEMA}"]
    if not str(sheet.get("intent", "")).strip():
        errors.append("ficha facial sem intencao da expressao (o que a torna reconhecivel)")
    marks = sheet.get("landmarks") or []
    ids = [m.get("id") for m in marks]
    if not marks and sheet.get("face_visible", True):
        errors.append("ficha facial sem marcos (um rosto tapado declara face_visible: false)")
    for m in marks:
        name = m.get("id")
        if not name or ids.count(name) > 1:
            errors.append(f"marco {name!r}: id em falta ou repetido")
        if m.get("feature") not in FEATURES:
            errors.append(f"marco {name}: feature {m.get('feature')!r} (use {', '.join(FEATURES)})")
        if not str(m.get("intent", "")).strip():
            errors.append(f"marco {name}: sem intencao")
        a = m.get("authority_box")
        if a is not None and (not _box(a) or crop and not (crop[0] <= a[0] and crop[1] <= a[1] and a[2] <= crop[2]
                                                         and a[3] <= crop[3])):
            errors.append(f"marco {name}: authority_box invalida ou fora do recorte de autoridade")
        if m.get("target_box") is not None and not _box(m["target_box"], canvas):
            errors.append(f"marco {name}: target_box invalida ou fora da tela {canvas}")
        for c in m.get("colors") or []:
            try:
                color.parse_hex(c)
            except ValueError as err:
                errors.append(f"marco {name}: {err}")
    for r in sheet.get("relations") or []:
        kind = r.get("type")
        if kind not in RELATIONS:
            errors.append(f"relacao {r.get('id')}: tipo {kind!r} (use {', '.join(RELATIONS)})")
            continue
        missing = [k for k in RELATIONS[kind] if r.get(k) in (None, "")]
        refs = [r.get(k) for k in ("a", "b", "within") if r.get(k)]
        if missing or any(x not in ids for x in refs) or (kind in EXPECT and r.get("expect") not in EXPECT[kind]):
            errors.append(f"relacao {r.get('id')}: campos {missing or 'expect'} ou marcos {refs} fora da ficha")
    return errors


def _mask(img: Image.Image, m: dict) -> set[tuple[int, int]]:
    x0, y0, x1, y1 = m["target_box"]
    want = {(*color.parse_hex(c), 255) for c in m["colors"]}
    px = img.load()
    return {(x, y) for y in range(max(0, y0), min(img.height, y1)) for x in range(max(0, x0), min(img.width, x1))
            if px[x, y] in want}


def _pieces(cells: set) -> int:
    seen, n = set(), 0
    for start in cells:
        if start in seen:
            continue
        n += 1
        stack = [start]
        seen.add(start)
        while stack:
            x, y = stack.pop()
            for nb in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if nb in cells and nb not in seen:
                    seen.add(nb)
                    stack.append(nb)
    return n


def _center(cells) -> tuple[float, float]:
    return sum(x for x, _ in cells) / len(cells), sum(y for _, y in cells) / len(cells)


FLIP = {"left": "right", "right": "left", "left_higher": "right_higher", "right_higher": "left_higher"}


def _relation(r: dict, masks: dict, marks: dict, mirrored: bool = False) -> tuple[str, str]:
    a = masks[r["a"]]
    r = {**r, "expect": FLIP.get(r.get("expect"), r.get("expect")) if mirrored else r.get("expect")}
    if r["type"] == "offset":
        x0, y0, x1, y1 = marks[r["within"]]["target_box"]
        cx, cy = _center(a)
        dx, dy = cx - (x0 + x1 - 1) / 2, cy - (y0 + y1 - 1) / 2
        horiz = "left" if dx < -0.5 else "right" if dx > 0.5 else "center"
        vert = "up" if dy < -0.5 else "down" if dy > 0.5 else "center"
        got = vert if r["expect"] in ("up", "down") else horiz if r["expect"] != "center" or horiz != "center" else vert
        return ("pass" if got == r["expect"] else "fail"), f"{r['a']} esta {got} em {r['within']} (dx {dx:+.1f}, dy " \
                                                            f"{dy:+.1f}); o conceito pede {r['expect']}"
    if r["type"] == "asymmetry":
        left, right = min(x for x, _ in a), max(x for x, _ in a)
        yl, yr = min(y for x, y in a if x == left), min(y for x, y in a if x == right)
        need = r.get("min", 1)
        got = "left_higher" if yr - yl >= need else "right_higher" if yl - yr >= need else "level" if yl == yr else \
            "slight"
        return ("pass" if got == r["expect"] else "fail"), f"pontas de {r['a']} a y={yl} e y={yr} ({got}); o conceito " \
                                                            f"pede {r['expect']}"
    if r["type"] == "above":
        b = masks[r["b"]]
        ok = max(y for _, y in a) < min(y for _, y in b)
        return ("pass" if ok else "fail"), f"{r['a']} {'acima' if ok else 'nao fica acima'} de {r['b']}"
    if r["type"] == "pieces":
        n = _pieces(a)
        return ("pass" if n >= r["min"] else "fail"), f"{r['a']}: {n} agrupamentos separados (minimo {r['min']})"
    i = 0 if r["axis"] == "x" else 1
    size = max(p[i] for p in a) - min(p[i] for p in a) + 1
    ok = size >= r["min"] and size <= r.get("max", size)
    return ("pass" if ok else "fail"), f"{r['a']}: {size} px em {r['axis']} (minimo {r['min']})"


def check(sheet: dict | None, image: Image.Image) -> dict:
    """Os marcos e as relacoes da ficha num PNG final: `pass`, `pending` ou `blocked`, com cada um."""
    if not sheet:
        return {"status": "pending", "landmarks": [], "relations": [],
                "pending": ["ficha facial por registar (forja.face_sheet/1): intencao, marcos e relacoes"],
                "blocked": []}
    if sheet.get("face_visible", True) is False:
        return {"status": "pass" if sheet.get("status") == "registered" else "pending", "landmarks": [],
                "relations": [], "pending": [], "blocked": [], "intent": sheet.get("intent"),
                "note": "rosto tapado nesta pose (face_visible: false): a expressao vive na postura"}
    marks = {m["id"]: m for m in sheet.get("landmarks", [])}
    masks, rows, pending, blocked = {}, [], [], []
    for m in marks.values():
        if not (m.get("target_box") and m.get("colors")):
            pending.append(f"marco {m['id']}: sem caixa reservada ou cores na grade nativa")
            rows.append({"id": m["id"], "state": "pending"})
            continue
        cells = _mask(image, m)
        masks[m["id"]] = cells
        state = "present" if cells else "missing"
        if not cells and m.get("required", True):
            blocked.append(f"marco {m['id']} ({m['feature']}): nenhum pixel das cores declaradas na caixa reservada")
        rows.append({"id": m["id"], "state": state, "pixels": len(cells), "intent": m.get("intent")})
    rels = []
    for r in sheet.get("relations", []):
        needed = [r["a"], *([r["b"]] if r.get("b") else [])]
        if any(not masks.get(n) for n in needed) or (r.get("within") and not marks[r["within"]].get("target_box")):
            rels.append({"id": r["id"], "status": "not_evaluated", "detail": "marco sem medida"})
            pending.append(f"relacao {r['id']}: marcos sem medida")
            continue
        status, detail = _relation(r, masks, marks, bool(sheet.get("target_mirrored")))
        rels.append({"id": r["id"], "type": r["type"], "status": status, "detail": detail, "intent": r.get("intent")})
        if status == "fail":
            blocked.append(f"relacao {r['id']}: {detail}")
    status = "blocked" if blocked else "pending" if pending or not rels else "pass"
    if status == "pass" and sheet.get("status") != "registered":
        status, pending = "pending", pending + [f"ficha em estado {sheet.get('status')!r}, nao registered"]
    return {"status": status, "landmarks": rows, "relations": rels, "pending": pending, "blocked": blocked,
            "intent": sheet.get("intent"),
            "note": "as relacoes medem agrupamentos de pixels; a revisao visual decide o que nao e deterministico"}


def boxes(sheet: dict | None) -> dict[str, list[int]]:
    """As caixas reservadas dos marcos, para o fecho das perdas herdadas (lineage.closure)."""
    return {f"face:{m['id']}": m["target_box"] for m in (sheet or {}).get("landmarks", []) if m.get("target_box")}
