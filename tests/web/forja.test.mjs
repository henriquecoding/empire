import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { webcrypto } from 'node:crypto';

const scope = vm.createContext({crypto:webcrypto,TextEncoder,TextDecoder,atob});
vm.runInContext(readFileSync('tools/web/site/forja/review-model.js','utf8'), scope);
const model=scope.ForjaReview;
const png='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLttAAAAABJRU5ErkJggg==';
const sample=()=>({schema:'forja.review-package/1',canvas:[1,1],loop:false,reference:png,
  package_sha256:'test',frames:[{image:png,duration_ms:100},{image:png,duration_ms:300}]});

test('one-shot holds last frame while loop wraps at exact duration',()=>{
  const data=sample();assert.equal(model.at(data,99),0);assert.equal(model.at(data,100),1);
  assert.equal(model.at(data,800),1);data.loop=true;assert.equal(model.at(data,400),0);
});
test('external images, excessive memory and invalid durations refused',()=>{
  let data=sample();data.frames[0].image='https://example.com/pixel.png';assert.throws(()=>model.validate(data));
  data=sample();data.canvas=[4096,4096];data.frames=Array(600).fill(data.frames[0]);assert.throws(()=>model.validate(data));
  data=sample();data.frames[0].duration_ms=0;assert.throws(()=>model.validate(data));
});
test('observations bind exact file bytes and each frame; tampering refused',async()=>{
  const text=JSON.stringify(sample()), bound=await model.bind(text);
  assert.match(bound.loaded_file_sha256,/^[a-f0-9]{64}$/);
  assert.match(bound.frames[0].sha256,/^[a-f0-9]{64}$/);
  const notes=model.notes(bound,[{status:'observed',note:'checked'}],'Reviewer');
  assert.equal(notes.loaded_file_sha256,bound.loaded_file_sha256);assert.equal(notes.approval,'pending');
  assert.notEqual((await model.bind(text+' ')).loaded_file_sha256,bound.loaded_file_sha256);
  const bom=new Uint8Array([239,187,191,...new TextEncoder().encode(text)]);
  assert.notEqual((await model.bind(bom.buffer)).loaded_file_sha256,bound.loaded_file_sha256);
  bound.frames[0].sha256='wrong';await assert.rejects(()=>model.bind(JSON.stringify(bound)),/hash/);
  assert.throws(()=>model.notes(bound,[],' '),/nome/);
});
