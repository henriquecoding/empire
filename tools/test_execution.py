"""Regista casos realmente executados pelo gdUnit, sem usar o inventário de funções."""
import datetime
import json
import os
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

reports = list(Path('reports').glob('report_*/results.xml'))
if not reports:
    raise SystemExit('Não há relatório de execução gdUnit4.')
report = max(reports, key=lambda p: p.stat().st_mtime_ns)
root = ET.parse(report).getroot()
counts = dict(passed=0, skipped=0, failed=0, errors=0)
for case in root.iter('testcase'):
    key = ('errors' if case.find('error') is not None else 'failed' if case.find('failure') is not None
           else 'skipped' if case.find('skipped') is not None else 'passed')
    counts[key] += 1
sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
dirty = bool(subprocess.check_output(['git', 'status', '--porcelain'], text=True).strip())
run = os.environ.get('GITHUB_RUN_ID')
record = dict(date=datetime.datetime.now(datetime.timezone.utc).isoformat(), source_sha=sha, worktree_dirty=dirty,
              run_url=f"https://github.com/{os.environ.get('GITHUB_REPOSITORY')}/actions/runs/{run}" if run else None,
              cases=sum(counts.values()), **counts, report=str(report))
Path('build').mkdir(exist_ok=True)
Path('build/test-execution.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps(record))
