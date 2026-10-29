"""Compara tentativas por tarefa e metodo; aceita observacoes humanas, nunca inventa custos."""
from __future__ import annotations

import json
from pathlib import Path

from . import pose
from .backends import digest, sha


def summarize(manifest: dict, base: Path) -> dict:
    if not isinstance(manifest, dict) or manifest.get('schema') != 'forja.benchmark/1':
        raise ValueError('schema: esperado forja.benchmark/1')
    runs = manifest.get('runs')
    if not isinstance(runs, list) or not runs:
        raise ValueError('runs: lista nao vazia')
    groups, seen = {}, set()
    for entry in runs:
        if not isinstance(entry, dict) or bool(entry.get('package')) == bool(entry.get('job')):
            raise ValueError('cada tentativa exige package ou job, exclusivamente')
        raw = (base / (entry.get('package') or entry['job'])).read_bytes()
        if sha(raw) != entry.get('sha256'):
            raise ValueError('hash da tentativa mudou; rever o arquivo exato')
        data = json.loads(raw)
        decision = entry.get('decision', 'pending')
        if decision not in ('accepted', 'rejected', 'pending'):
            raise ValueError('decision: accepted/rejected/pending')
        if decision != 'pending' and (not isinstance(entry.get('reviewer'), str) or not entry['reviewer'].strip()):
            raise ValueError('decisao exige reviewer')
        if entry.get('package'):
            if data.get('schema') != 'forja.review-package/1':
                raise ValueError('pacote de revisao esperado')
            if digest({k: v for k, v in data.items() if k != 'package_sha256'}) != data.get('package_sha256'):
                raise ValueError('hash interno do pacote alterado')
            source = data.get('source', {})
            method = source.get('method', 'import')
            cost = source.get('cost', {}).get('usd')
            ident = source.get('job_id') or sha(raw)
        else:
            if data.get('schema') != 1 or not data.get('operation') or not data.get('id'):
                raise ValueError('job persistente da Forja esperado')
            if decision == 'accepted':
                raise ValueError('job sem pacote visual nao pode ser aceito')
            method, cost, ident = data['operation'].removeprefix('animate-with-'), data['cost']['usd'], data['id']
        if ident in seen:
            raise ValueError('job/pacote repetido: contaria a mesma tentativa duas vezes')
        seen.add(ident)
        task = entry.get('task')
        if not isinstance(task, str) or not task:
            raise ValueError('task obrigatoria para comparar a mesma tarefa')
        extra, minutes = entry.get('extra_cost_usd'), entry.get('correction_minutes')
        for value in (cost, extra, minutes):
            if value is not None and (not pose.number(value) or value < 0):
                raise ValueError('custos/minutos devem ser numeros nao negativos ou null')
        row = groups.setdefault((task, method), {'task': task, 'method': method, 'attempts': 0,
            'accepted': 0, 'rejected': 0, 'pending': 0, 'known_usd': 0, 'unknown_cost_runs': 0,
            'known_correction_minutes': 0, 'unknown_correction_runs': 0})
        row['attempts'] += 1
        row[decision] += 1
        row['known_usd'] += (cost or 0) + (extra or 0)
        row['unknown_cost_runs'] += cost is None or extra is None
        row['known_correction_minutes'] += minutes or 0
        row['unknown_correction_runs'] += minutes is None
    for row in groups.values():
        row['acceptance_rate'] = row['accepted'] / row['attempts']
        row['usd_per_accepted'] = (round(row['known_usd'] / row['accepted'], 6)
                                   if row['accepted'] and not row['unknown_cost_runs'] else None)
    return {'schema': 'forja.benchmark-report/1', 'groups': [groups[k] for k in sorted(groups)],
            'network': False, 'approval': 'pending', 'manifest_sha256': digest(manifest),
            'notes': ['Aceitacao e declarada pelo revisor neste estudo; nao promove referencias no registo.',
                      'USD soma geracao e custos extras declarados, incluindo rejeicoes. Tempo humano separado.',
                      'Custo desconhecido conserva a media em null. Nao compara tarefas diferentes.']}
