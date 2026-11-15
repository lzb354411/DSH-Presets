// Bundle validator for @local/dsh-plugin-dev-preset.
// Run with the DSH Electron runtime (ASAR-aware) and js-yaml from the install anchor:
//   EXE=<DeepSeek Harness.exe> ; ELECTRON_RUN_AS_NODE=1
//   <EXE> dev/validate-bundle.cjs <bundleDir> <installDir> <outFile>
// Writes a JSON report; the CLI wrapper prints it. ASCII-only source on purpose.
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');

const [bundleDir, installDir, outFile] = process.argv.slice(2);
const problems = [];
const notes = [];
const stats = {};

function fail(message) {
  problems.push(message);
}

function must(condition, message) {
  if (!condition) fail(message);
  return condition;
}

function readJson(file, label) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (error) {
    fail(`${label}: ${error.message}`);
    return null;
  }
}

// ---------------------------------------------------------------- manifest
const pkg = readJson(path.join(bundleDir, 'package.json'), 'package.json');
if (pkg) {
  must(typeof pkg.name === 'string' && pkg.name.length > 0, 'package.json: name missing');
  must(/^\d+\.\d+\.\d+/.test(pkg.version || ''), 'package.json: version is not semver');
  must(pkg.dsh && pkg.dsh.bundle && typeof pkg.dsh.bundle.patch === 'string',
    'package.json: dsh.bundle.patch missing');
  must(typeof pkg.engines === 'object' && typeof pkg.engines.dsh === 'string',
    'package.json: engines.dsh missing (version gate)');
  must(pkg.exports && pkg.exports['./icon'] && pkg.exports['./locale/*.json'],
    'package.json: exports for ./icon and ./locale/*.json missing');
  must(Array.isArray(pkg.files) && pkg.files.length > 0, 'package.json: files missing');

  const missingFiles = [];
  for (const pattern of pkg.files || []) {
    if (/[*?]/.test(pattern)) {
      const dir = path.dirname(pattern);
      const base = path.basename(pattern);
      const regex = new RegExp('^' + base.replace(/[.+^${}()|\\]/g, '\\$&').replace(/\*/g, '.*') + '$');
      let names = [];
      try {
        names = fs.readdirSync(path.join(bundleDir, dir));
      } catch {
        names = [];
      }
      if (!names.some((name) => regex.test(name))) missingFiles.push(pattern);
    } else if (!fs.existsSync(path.join(bundleDir, pattern))) {
      missingFiles.push(pattern);
    }
  }
  must(missingFiles.length === 0, `package.json: files entries not found: ${missingFiles.join(', ')}`);
}

// ---------------------------------------------------------------- patch
const patchRel = pkg && pkg.dsh && pkg.dsh.bundle && pkg.dsh.bundle.patch;
const patchFile = path.join(bundleDir, patchRel || 'cordis.patch.yml');
let jsYaml = null;
try {
  jsYaml = require(Module.createRequire(path.join(installDir, 'package.json')).resolve('js-yaml'));
} catch (error) {
  fail(`js-yaml unavailable from ${installDir}: ${error.message}`);
}

let doc = null;
if (jsYaml && fs.existsSync(patchFile)) {
  let schema = jsYaml.DEFAULT_SCHEMA;
  try {
    const jsType = new jsYaml.Type('tag:yaml.org,2002:js', {
      kind: 'scalar',
      construct: (data) => data,
    });
    schema = jsYaml.DEFAULT_SCHEMA.extend([jsType]);
  } catch (error) {
    fail(`custom !!js tag registration failed: ${error.message}`);
  }
  try {
    doc = jsYaml.load(fs.readFileSync(patchFile, 'utf8'), { schema, filename: patchFile });
  } catch (error) {
    fail(`cordis.patch.yml: ${error.message}`);
  }
} else if (!fs.existsSync(patchFile)) {
  fail(`cordis.patch.yml missing at ${patchFile}`);
}

const PRESET_ID = 'plugin-dev';
const PRESET_ROW_ID = 'preset-plugin-dev';
let presetConfig = null;
const ids = new Map();
const packageNames = new Set();

function packageOf(spec) {
  const parts = spec.split('/');
  return parts[0].startsWith('@') ? `${parts[0]}/${parts[1]}` : parts[0];
}

function installedPackage(pkgName) {
  try {
    return Module.createRequire(path.join(installDir, 'package.json'))
      .resolve(`${pkgName}/package.json`);
  } catch {
    return null;
  }
}

function walkRows(rows, trail) {
  if (!Array.isArray(rows)) {
    fail(`${trail}: expected an entry list`);
    return;
  }
  for (const [index, row] of rows.entries()) {
    const where = `${trail}[${index}]`;
    if (!row || typeof row !== 'object' || Array.isArray(row)) {
      fail(`${where}: entry is not a mapping`);
      continue;
    }
    if (typeof row.id !== 'string' || row.id.length === 0) {
      fail(`${where}: id missing`);
    } else if (ids.has(row.id)) {
      fail(`${where}: duplicate id ${row.id} (also ${ids.get(row.id)})`);
    } else {
      ids.set(row.id, where);
    }
    if (row.group === true) {
      must(row.name === 'cordis:group', `${where}: group row must use cordis:group`);
      walkRows(row.config, `${where}.config`);
      continue;
    }
    if (typeof row.name !== 'string' || row.name.length === 0) {
      fail(`${where}: name missing`);
      continue;
    }
    if (row.name === 'cordis:group') continue;
    must(row.name.startsWith('@deepseek-ai/') || row.name.startsWith('file:'),
      `${where}: unexpected plugin specifier ${row.name}`);
    if (row.name.startsWith('@deepseek-ai/')) {
      const pkgName = packageOf(row.name);
      packageNames.add(pkgName);
      must(installedPackage(pkgName) !== null, `${where}: ${pkgName} is not installed with this DSH`);
    }
    if (row.disabled !== undefined && typeof row.disabled !== 'boolean' && typeof row.disabled !== 'string') {
      fail(`${where}: disabled must be a boolean or a Loader expression`);
    }
    if (row.config !== undefined && (typeof row.config !== 'object' || row.config === null)) {
      fail(`${where}: config must be a mapping or a list`);
    }
  }
}

if (Array.isArray(doc)) {
  const inserted = doc.filter((entry) => entry && entry.insert);
  must(inserted.length === 1, 'cordis.patch.yml: expected exactly one insert patch');
  const rows = inserted.length === 1 ? inserted[0].insert : [];
  must(Array.isArray(rows) && rows.length === 1, 'cordis.patch.yml: expected exactly one inserted row');
  const declaration = Array.isArray(rows) && rows.length === 1 ? rows[0] : null;
  if (!declaration) {
    fail('cordis.patch.yml: preset declaration row missing');
  } else {
    must(declaration.id === PRESET_ROW_ID, `cordis.patch.yml: row id must be ${PRESET_ROW_ID}`);
    must(declaration.name === '@deepseek-ai/dsh-agent-preset',
      'cordis.patch.yml: declaration must mount @deepseek-ai/dsh-agent-preset');
    presetConfig = declaration.config;
    if (!presetConfig || typeof presetConfig !== 'object') {
      fail('cordis.patch.yml: config missing on the declaration');
    } else {
      must(presetConfig.id === PRESET_ID, `config.id must be ${PRESET_ID}`);
      must(/^[a-z0-9-]+$/.test(presetConfig.id || ''), 'config.id must be lowercase letters, digits, hyphens');
      must(typeof presetConfig.name === 'string' && presetConfig.name.length > 0, 'config.name missing');
      must(typeof presetConfig.description === 'string' && presetConfig.description.length > 20,
        'config.description missing or too short');
      must(Number.isInteger(presetConfig.order), 'config.order must be an integer');
      must(Array.isArray(presetConfig.plugins) && presetConfig.plugins.length > 0, 'config.plugins missing');
      walkRows(presetConfig.plugins, 'config.plugins');
    }
  }
} else if (doc !== null) {
  fail('cordis.patch.yml: root must be a patch array');
}

if (presetConfig && Array.isArray(presetConfig.plugins)) {
  stats.pluginRows = presetConfig.plugins.length;
  stats.packages = packageNames.size;
}

// ---------------------------------------------------------------- locales
for (const language of ['en', 'zh']) {
  const file = path.join(bundleDir, 'locale', `${language}.json`);
  const data = readJson(file, `locale/${language}.json`);
  if (data) {
    must(data.meta && typeof data.meta.title === 'string' && data.meta.title.length > 0,
      `locale/${language}.json: meta.title missing`);
    must(data.meta && typeof data.meta.description === 'string' && data.meta.description.length > 20,
      `locale/${language}.json: meta.description missing or too short`);
    if (data.meta && data.meta.detail) {
      must(fs.existsSync(path.join(bundleDir, data.meta.detail)),
        `locale/${language}.json: meta.detail file missing`);
    }
  }
}

// ---------------------------------------------------------------- skills
const skillsDir = path.join(bundleDir, 'skills');
let skillNames = [];
try {
  skillNames = fs.readdirSync(skillsDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
} catch (error) {
  fail(`skills/: ${error.message}`);
}
for (const name of skillNames) {
  const file = path.join(skillsDir, name, 'SKILL.md');
  if (!fs.existsSync(file)) {
    fail(`skills/${name}: SKILL.md missing`);
    continue;
  }
  const text = fs.readFileSync(file, 'utf8');
  const match = /^---\r?\n([\s\S]*?)\r?\n---/.exec(text);
  if (!match) {
    fail(`skills/${name}: YAML frontmatter missing`);
    continue;
  }
  must(/^name:\s*\S+/m.test(match[1]), `skills/${name}: frontmatter name missing`);
  must(/^description:\s*\S+/m.test(match[1]), `skills/${name}: frontmatter description missing`);
}
stats.skills = skillNames.length;
must(skillNames.length >= 22, `skills/: expected at least 22 skill directories, found ${skillNames.length}`);

// ---------------------------------------------------------------- icon
const iconFile = path.join(bundleDir, 'icon.svg');
if (!fs.existsSync(iconFile)) {
  fail('icon.svg missing');
} else {
  const size = fs.statSync(iconFile).size;
  must(size < 256 * 1024, `icon.svg is ${size} bytes, over the 256 KiB icon limit`);
  const svg = fs.readFileSync(iconFile, 'utf8');
  for (const forbidden of ['<script', '<style', '<image', '<foreignObject', '<text', ' onload=', ' href=']) {
    must(!svg.includes(forbidden), `icon.svg contains forbidden markup ${forbidden}`);
  }
  must(/viewBox="0 0 36 36"/.test(svg), 'icon.svg must use a 36x36 viewBox');
  stats.iconBytes = size;
}

// ---------------------------------------------------------------- report
const report = {
  ok: problems.length === 0,
  bundleDir,
  installDir,
  preset: presetConfig ? { id: presetConfig.id, name: presetConfig.name, order: presetConfig.order } : null,
  stats,
  notes,
  problems,
};
const text = JSON.stringify(report, null, 2);
if (outFile) fs.writeFileSync(outFile, text, 'utf8');
process.stdout.write(text + '\n');
process.exitCode = problems.length === 0 ? 0 : 1;
