import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

function exportWith(code, missing = false) {
  const dir = mkdtempSync(join(tmpdir(), 'empire-export-'));
  try {
    const motor = join(dir, 'motor');
    writeFileSync(motor, `#!/bin/bash\nfor f in index.html index.js index.wasm ${missing ? '' : 'index.pck'}; do echo artifact > '${dir}/'$f; done\necho 'Storing File'\nexit ${code}\n`, { mode: 0o755 });
    return spawnSync('bash', [resolve('tools/web/exportar.sh'), motor, join(dir, 'index.html')], { encoding: 'utf8' });
  } finally { rmSync(dir, { recursive: true, force: true }); }
}
test('export failures remain fatal even with four nonempty output files', () => {
  const result = exportWith(42);
  assert.equal(result.status, 42);
  assert.match(result.stderr, /codigo 42/);
});
test('an empty filtered log does not turn a successful export into failure', () => assert.equal(exportWith(0).status, 0));
test('a missing artifact fails a zero-exit export', () => assert.equal(exportWith(0, true).status, 1));
