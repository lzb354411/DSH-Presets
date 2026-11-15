// Drift check: compare this bundle's preset rows with the shipped Creator preset.
// Run with the DSH Electron runtime (ASAR-aware):
//   ELECTRON_RUN_AS_NODE=1 <DeepSeek Harness.exe> dev/compare-cordis.cjs <bundleDir> <installDir> <outFile>
// Reports rows missing, extra, or configured differently. persona and skill-filesystem are
// expected differences for this preset.
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');

const [bundleDir, installDir, outFile] = process.argv.slice(2);
const jsYaml = require(Module.createRequire(path.join(installDir, 'package.json')).resolve('js-yaml'));
const jsType = new jsYaml.Type('tag:yaml.org,2002:js', {
  kind: 'scalar',
  construct: (data) => ({ __js: String(data) }),
});
const schema = jsYaml.DEFAULT_SCHEMA.extend([jsType]);

function load(file) {
  const doc = jsYaml.load(fs.readFileSync(file, 'utf8'), { schema, filename: file });
  const rows = doc[0].insert[0].config.plugins;
  const map = new Map();
  function walk(list, trail) {
    for (const row of list) {
      map.set(trail ? `${trail}/${row.id}` : row.id, row);
      if (row.group === true && Array.isArray(row.config)) walk(row.config, trail ? `${trail}/${row.id}` : row.id);
    }
  }
  walk(rows, '');
  return map;
}

const shippedFile = Module.createRequire(path.join(installDir, 'package.json'))
  .resolve('@deepseek-ai/dsh-web-app/presets/cordis.patch.yml');
const ours = load(path.join(bundleDir, 'cordis.patch.yml'));
const shipped = load(shippedFile);
const expected = new Set(['persona', 'skill-filesystem']);
const lines = [];

for (const [id, row] of shipped) {
  if (!ours.has(id)) {
    lines.push(`MISSING  ${id} (${row.name})`);
  }
}
for (const [id, row] of ours) {
  if (!shipped.has(id)) {
    lines.push(`EXTRA    ${id} (${row.name})`);
  }
}
for (const [id, row] of ours) {
  const base = shipped.get(id);
  if (!base) continue;
  const a = JSON.stringify(row.config ?? null);
  const b = JSON.stringify(base.config ?? null);
  const sameName = row.name === base.name;
  const sameConfig = a === b;
  if (sameName && sameConfig) continue;
  const label = expected.has(id) ? 'EXPECTED' : 'CHANGED ';
  lines.push(`${label} ${id}`);
  if (!sameName) lines.push(`  name: ${base.name} -> ${row.name}`);
  if (!sameConfig) lines.push(`  config differs`);
}

const summary = {
  ok: !lines.some((line) => line.startsWith('MISSING') || line.startsWith('EXTRA') || line.startsWith('CHANGED')),
  shippedRows: shipped.size,
  ourRows: ours.size,
  differences: lines,
};
const text = JSON.stringify(summary, null, 2);
if (outFile) fs.writeFileSync(outFile, text, 'utf8');
process.stdout.write(text + '\n');
process.exitCode = summary.ok ? 0 : 1;
