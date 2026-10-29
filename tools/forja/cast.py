"""O elenco escolhido pelo dono: cada identidade aponta para o seu contrato e imagem exata."""
from __future__ import annotations

import json
from pathlib import Path

from . import fidelity, refs

SCHEMA = 'forja.cast/1'
DEFAULT = Path(__file__).with_name('cast.json')
DECISIONS = ('accepted', 'owner_requested_revision')


def load(path: str | Path = DEFAULT) -> dict:
    path = Path(path).resolve()
    data = json.loads(path.read_text(encoding='utf-8'))
    errors = [] if data.get('schema') == SCHEMA else [f'schema: esperado {SCHEMA}']
    base = path.parent
    entries = data.get('characters') or []
    if not entries:
        errors.append('elenco sem personagens')
    keys: set[str] = set()
    ids = {entry.get('id') for entry in entries}
    for entry in entries:
        name = entry.get('id') or '?'
        for key in [entry.get('id'), *entry.get('aliases', [])]:
            if not key or key in keys:
                errors.append(f'{name}: id ou alias ausente/repetido: {key!r}')
            keys.add(key)
        decision = entry.get('design_decision') or {}
        if decision.get('status') not in DECISIONS or not all(decision.get(k) for k in ('by', 'date', 'evidence')):
            errors.append(f'{name}: decisao de design sem estado, autor, data ou evidencia')
        if entry.get('native_master_approved') is not False:
            errors.append(f'{name}: o catalogo de conceitos nao aprova mestres nativos')
        partner = entry.get('paired_with')
        if partner and partner not in ids:
            errors.append(f'{name}: parceiro {partner!r} fora do elenco')
        try:
            contract = fidelity.load(base / entry.get('contract', ''))
            ch = fidelity.character(contract, name, entry.get('pose'))
            if ch['kind'] != entry.get('kind'):
                errors.append(f'{name}: kind diverge do contrato de identidade')
            if not ch.get('prompt_invariants') or not entry.get('function'):
                errors.append(f'{name}: invariantes ou funcao em falta')
        except (OSError, ValueError, KeyError) as exc:
            errors.append(f'{name}: contrato invalido: {exc}')
    try:
        register = refs.load(base / data.get('reference_register', ''))
        if any(e['state'] == 'approved' for e in register['entries']):
            errors.append('o registo do elenco de conceitos nao pode conter aprovacao de mestre nativo')
    except (OSError, ValueError, KeyError) as exc:
        errors.append(f'registo de referencias invalido: {exc}')
    if errors:
        raise ValueError('elenco invalido: ' + '; '.join(errors))
    return {**data, 'path': str(path), 'base': str(base)}


def character(data: dict, ident: str) -> dict:
    found = [e for e in data['characters'] if ident in [e['id'], *e.get('aliases', [])]]
    if len(found) != 1:
        raise ValueError(f'personagem {ident!r} nao esta no elenco; consulte forja elenco')
    return found[0]


def describe(data: dict, entry: dict) -> dict:
    return {k: entry.get(k) for k in ('id', 'label', 'aliases', 'kind', 'paired_with', 'function', 'function_scope',
                                     'design_decision', 'native_master_approved', 'runtime_integrated')}


def authority(data: dict, entry: dict) -> dict:
    return fidelity.load(Path(data['base']) / entry['contract'])


def request_contract(args) -> tuple[dict | None, str | None]:
    ident = getattr(args, 'character', None)
    if getattr(args, 'fidelity', None):
        return fidelity.load(args.fidelity), ident
    if ident:
        data = load()
        entry = character(data, ident)
        return authority(data, entry), entry['id']
    return None, None
