// Postgres isolado: as migrações reais, roles e RLS, sem dados de produção.
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
const require = createRequire(resolve('ferramentas/package.json'));
const { PGlite } = require('@electric-sql/pglite');
const ADMIN = '00000000-0000-0000-0000-000000000001';
const OTHER = '00000000-0000-0000-0000-000000000002';

async function fixture() {
  const db = new PGlite();
  await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth; create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    grant usage on schema auth, public to anon, authenticated;
    grant execute on function auth.uid() to anon, authenticated;
    create function public.rls_auto_enable() returns event_trigger language plpgsql as $$ begin return; end $$;
    insert into auth.users values ('${ADMIN}'),('${OTHER}');`);
  for (const file of ['001_empire_reportes.sql','002_empire_reportes_teto.sql','003_empire_auditoria_revisoes_e_seguranca.sql','004_empire_revisao_monotona.sql'])
    await db.exec(readFileSync('tools/web/supabase/' + file,'utf8'));
  await db.exec(`insert into public.empire_admins(user_id) values ('${ADMIN}');`);
  return db;
}
async function as(db, role, user, sql, params = []) {
  await db.exec(`set role ${role}; select set_config('request.jwt.claim.sub','${user || ''}',false);`);
  try { return await db.query(sql, params); } finally { await db.exec('reset role'); }
}

test('RLS, snapshots e revisões recusam escrita e remoção de uma aba antiga', async () => {
  const db = await fixture();
  try {
    const sha = 'a'.repeat(40);
    const first = await as(db,'authenticated',ADMIN, `insert into public.empire_respostas(pergunta,escolha,proposta_texto,fonte_sha)
      values ('Q-999','aprovar','Proposta original',$1) returning *`, [sha]);
    assert.equal(first.rows[0].revisao,1);
    assert.match(first.rows[0].proposta_hash,/^[a-f0-9]{64}$/);
    const saved = await as(db,'authenticated',ADMIN, `update public.empire_respostas set texto='primeira aba' where pergunta='Q-999' and revisao=1 returning *`);
    assert.equal(saved.rows[0].revisao,2);
    assert.equal((await as(db,'authenticated',ADMIN, `update public.empire_respostas set texto='aba antiga' where pergunta='Q-999' and revisao=1 returning *`)).rows.length,0);
    assert.equal((await as(db,'authenticated',ADMIN, `delete from public.empire_respostas where pergunta='Q-999' and revisao=1 returning *`)).rows.length,0);
    assert.equal((await as(db,'authenticated',ADMIN, `select * from public.empire_respostas_historico where pergunta='Q-999'`)).rows.length,2);
    await as(db,'authenticated',ADMIN, `delete from public.empire_respostas where pergunta='Q-999' and revisao=2`);
    const recreated = await as(db,'authenticated',ADMIN, `insert into public.empire_respostas(pergunta,escolha,proposta_texto,fonte_sha)
      values ('Q-999','aprovar','Proposta revista',$1) returning *`, [sha]);
    assert.equal(recreated.rows[0].revisao,3);
    assert.equal((await as(db,'authenticated',ADMIN, `update public.empire_respostas set texto='aba anterior a eliminar' where pergunta='Q-999' and revisao=2 returning *`)).rows.length,0);
    assert.equal((await as(db,'authenticated',ADMIN, `select * from public.empire_respostas_historico where pergunta='Q-999'`)).rows.length,3);
    assert.equal((await as(db,'authenticated',OTHER,'select * from public.empire_respostas')).rows.length,0);
    assert.equal((await as(db,'authenticated',OTHER,'select * from public.empire_respostas_historico')).rows.length,0);
    await assert.rejects(as(db,'authenticated',OTHER,`insert into public.empire_respostas(pergunta,escolha) values ('Q-998','adiar')`),/row-level security/);
    await assert.rejects(as(db,'anon',null,'select * from public.empire_respostas'),/permission denied/);
    await assert.rejects(as(db,'authenticated',ADMIN,'truncate public.empire_respostas'),/permission denied/);
    await assert.rejects(as(db,'authenticated',ADMIN,`insert into public.empire_admins(user_id) values ('${OTHER}')`),/permission denied/);
  } finally { await db.close(); }
});

test('reportes iguais de pessoas distintas existem; reenvio da mesma operação não duplica nem consome teto', async () => {
  const db = await fixture();
  try {
    // O POST é simples: ON CONFLICT exigiria SELECT mesmo com return=minimal.
    await assert.rejects(as(db,'anon',null,`insert into public.empire_feedback(tipo,mensagem,client_nonce)
      values ('erro','Não funciona',$1) on conflict(client_nonce) do nothing`,
      ['00000000-0000-0000-0000-000000000010']),/permission denied/);
    const submit = nonce => as(db,'anon',null,`insert into public.empire_feedback(tipo,mensagem,client_nonce) values ('erro','Não funciona',$1)`,[nonce]);
    await submit('00000000-0000-0000-0000-000000000010');
    await submit('00000000-0000-0000-0000-000000000011');
    await submit('00000000-0000-0000-0000-000000000010');
    assert.equal((await db.query('select count(*)::int n from public.empire_feedback')).rows[0].n,2);
    await assert.rejects(as(db,'anon',null,'select * from public.empire_feedback'),/permission denied/);
    const report = (await db.query('select id,revisao from public.empire_feedback limit 1')).rows[0];
    await as(db,'authenticated',ADMIN,'update public.empire_feedback set nota_admin=$1 where id=$2 and revisao=1',['revista',report.id]);
    assert.equal((await as(db,'authenticated',ADMIN,'update public.empire_feedback set nota_admin=$1 where id=$2 and revisao=1 returning id',['antiga',report.id])).rows.length,0);
    for(let i=0;i<28;i++) await as(db,'anon',null,`insert into public.empire_feedback(tipo,mensagem) values ('duvida',$1)`,['teste '+i]);
    await submit('00000000-0000-0000-0000-000000000010');
    await assert.rejects(submit('00000000-0000-0000-0000-000000000012'),/demasiados reportes/);
    assert.equal((await db.query('select count(*)::int n from public.empire_feedback')).rows[0].n,30);
    await assert.rejects(as(db,'authenticated',ADMIN,'truncate public.empire_feedback'),/permission denied/);
  } finally { await db.close(); }
});
