"""Decisoes anteriores ao gerador: papel, orcamento nativo e defeitos conhecidos da autoridade (FORJA-09)."""
from __future__ import annotations

import re

ROLE_KINDS = {'troop': 'troop_64', 'monarch': 'royal_80', 'royal_archer': 'royal_80', 'squire': 'royal_64'}


def inferred(text: str) -> str | None:
    text = text.lower().replace('_', ' ')
    excluded = (r'(?:\bnot|\bnao|\bnão|\bdistinct from|\bdifferent from|\bdiferente d[oa]|\bdistinto d[oa])'
                r'\s+(?:(?:a|an|the|o|um|uma)\s+)?$')
    patterns = [('troop', r'\btropas?\b|\btroops?\b'),
                ('royal_archer', r'\broyal archer\b|\barqueiro real\b'),
                ('monarch', r'\bking\b|\bqueen\b|\bmonarch\b|\brei\b|\brainha\b|\bmonarca\b|\bemperor\b|'
                            r'\bempress\b|\bimperador\b|\bimperatriz\b'),
                ('squire', r'\bsquires?\b|\bescudeir[oa]s?\b')]
    for role, pattern in patterns:
        if any(not re.search(excluded, text[:match.start()]) for match in re.finditer(pattern, text)):
            return role
    return None  # um "archer" sem qualificacao nao e automaticamente um monarca


def resolve(subject: str, kind: str | None, character: dict | None = None) -> dict:
    ch = character or {}
    role = ch.get('role') or inferred(ch.get('id', '')) or inferred(subject)
    declared = ch.get('kind')
    chosen = kind or declared or ROLE_KINDS.get(role) or 'character_s2'
    errors = []
    if kind and declared and kind != declared:
        errors.append(f'kind_conflict: pedido {kind}, autoridade {declared}; o preset nao substitui o personagem')
    if role and role not in ROLE_KINDS:
        errors.append(f'role_unknown: {role!r}; use {", ".join(ROLE_KINDS)}')
    elif role and chosen != ROLE_KINDS[role]:
        errors.append(f'role_conflict: {role} usa {ROLE_KINDS[role]}, nao {chosen}')
    return {'kind': chosen, 'role': role, 'errors': errors,
            'source': 'fidelity' if ch else 'explicit_subject' if role else 'kind_or_default'}


def validate(ch: dict) -> list[str]:
    errors = resolve('', ch.get('kind'), ch)['errors']
    box, canvas = ch.get('target_useful_bbox'), ch.get('target_canvas')
    if box is not None and (not isinstance(box, list) or len(box) != 4 or not canvas or
            not all(type(v) is int for v in box) or
            not (0 <= box[0] < box[2] <= canvas[0] and 0 <= box[1] < box[3] <= canvas[1])):
        errors.append('target_useful_bbox: caixa util invalida ou fora da tela')
    seen = set()
    for issue in ch.get('reference_issues', []):
        ident, disposition = issue.get('id'), issue.get('disposition')
        if not ident or ident in seen:
            errors.append('reference_issue: id ausente ou repetido')
        seen.add(ident)
        if disposition not in ('repair', 'unresolved', 'preserve_intentional'):
            errors.append(f'reference_issue {ident}: disposition invalida')
        if disposition in ('repair', 'preserve_intentional') and not all(issue.get(k) for k in
                ('authorized_by', 'date', 'instruction', 'authority_box')):
            errors.append(f'reference_issue {ident}: decisao sem autor, data, instrucao ou regiao')
        region = issue.get('authority_box')
        crop = ch.get('authority_crop_xyxy')
        if region is not None and (not isinstance(region, list) or len(region) != 4 or
                not all(type(v) is int for v in region) or region[0] >= region[2] or region[1] >= region[3] or
                crop and not (crop[0] <= region[0] < region[2] <= crop[2] and
                              crop[1] <= region[1] < region[3] <= crop[3])):
            errors.append(f'reference_issue {ident}: regiao invalida ou fora do recorte de autoridade')
    from . import props  # FORJA-15: a restricao partilhada tem consumidor e esquema
    return errors + props.validate(ch.get('shared_prop_constraints'), ch)


def prepare(ch: dict) -> dict:
    errors = validate(ch)
    errors += [f'reference_issue_unresolved: {i.get("id")}: {i.get("description", "")}'
               for i in ch.get('reference_issues', []) if i.get('disposition') == 'unresolved']
    return {'errors': errors, 'prompt': {'role': ch.get('role'), 'face_sheet': ch.get('face_sheet'),
            'target_useful_bbox': ch.get('target_useful_bbox'),
            'reference_repairs': [i for i in ch.get('reference_issues', []) if i.get('disposition') == 'repair']}}


def rules(fid: dict) -> list[dict]:
    out = []
    box = fid.get('target_useful_bbox')
    if box:
        x0, y0, x1, y1 = box
        out.append({'id': 'native_budget', 'origin': 'fidelity:native_layout',
            'text': f'Useful pixel budget: the WHOLE silhouette, including equipment, must stay within '
                    f'x={x0}..{x1 - 1}, y={y0}..{y1 - 1} on the native canvas. Plan the face and hands there '
                    'before detailing; do not draw at a finer grid and shrink or clip afterwards.'})
    sheet = fid.get('face_sheet')
    if sheet and sheet.get('landmarks'):
        out.append({'id': 'face_sheet', 'origin': 'fidelity:face_sheet',
            'text': 'Facial acting from the concept (face sheet): keep ' + ', '.join(
                f"{m['id']} ({m['feature']})" for m in sheet['landmarks']) + ' as the concept shows them'
                + ''.join(f'; {_say(r)}' for r in sheet.get('relations', [])) + '. Reserve whole native pixels '
                'for each before detailing. Big noses, asymmetry, irregular teeth and squints are approved '
                'choices, not noise to clean or deviations to normalize.'})
    repairs = fid.get('reference_repairs', [])
    if repairs:
        out.append({'id': 'reference_repairs', 'origin': 'fidelity:authorized_reference_exceptions',
            'text': 'Reference exceptions: correct only the listed defects; these instructions override exact '
                    'copying only for the named equipment defects. Preserve the remaining identity, facial acting, '
                    'clothing and proportions. ' + ' '.join(f'{i["id"]}: {i["instruction"]}' for i in repairs)})
    return out


def _say(r: dict) -> str:
    side = {'left': 'left', 'right': 'right', 'left_higher': 'higher on the left', 'right_higher': 'higher on the right',
            'level': 'level', 'up': 'up', 'down': 'down', 'center': 'centered'}.get(r.get('expect'), '')
    return {'offset': f"{r['a']} sits {side} inside {r.get('within')}", 'asymmetry': f"{r['a']} is {side}",
            'above': f"{r['a']} above {r.get('b')}", 'pieces': f"{r['a']} in at least {r.get('min')} separate pieces",
            'extent': f"{r['a']} at least {r.get('min')} px along {r.get('axis')}"}.get(r.get('type'), r.get('id'))


def repairs_state(ch: dict, pixels_sha256: str) -> dict:
    pending, blocked = [], []
    for issue in ch.get('reference_issues', []):
        ident = issue['id']
        if issue['disposition'] == 'preserve_intentional':
            continue
        if issue['disposition'] == 'unresolved':
            blocked.append(f'reference_issue_unresolved: {ident}')
            continue
        seen = next((r for r in reversed(ch.get('reference_issue_reviews', []))
                     if r.get('id') == ident and r.get('pixels_sha256') == pixels_sha256), None)
        complete = seen and all(seen.get(k) for k in ('reviewed_by', 'date', 'observation'))
        if complete and seen.get('status') == 'fail':
            blocked.append(f'{ident}: defeito da referencia ainda presente')
        elif not complete or seen.get('status') != 'pass':
            pending.append(f'{ident}: falta prova da correcao nesta imagem exata')
    return {'status': 'blocked' if blocked else 'pending' if pending else 'pass', 'evidence': blocked + pending}
