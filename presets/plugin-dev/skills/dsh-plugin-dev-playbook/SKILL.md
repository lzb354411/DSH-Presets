---
name: dsh-plugin-dev-playbook
description: Use when building, installing, updating, or publishing a DeepSeek Harness (DSH) plugin, bundle, or agent preset in this profile; when choosing among Host plugin, Client plugin, preset row, skill, and MCP as the extension point; or when an install, activation, or display metadata behaves unexpectedly. Carries the workflow and the verified traps; dsh-doc remains authoritative for API facts.
---

# DSH plugin development playbook

This skill is the operating companion to `dsh-doc`. `dsh-doc` owns the API facts and the install procedure; this file carries the workflow this preset expects and the traps that cost previous sessions time. Verified against DSH **0.2.2-rc.3** on Windows with the `desktop` profile. Re-verify anything version-specific before relying on it.

## 0. Ground rules

- Three areas, one direction: develop in the workspace (开发区), produce a clean package as the release artifact (产物区), then install into the profile (实装区). Never point the profile at a working copy, and never hand-write the profile's `package.json` or `cordis.patch.yml`.
- `plugin_manager install_bundle` owns installation and bundle selection. It needs Full access or a per-call approval.
- Ask before writing outside the workspace: C: drive, `$DSH_HOME`, the profile, registry, environment variables, services. Back up any config you touch.
- Read the running installation's version first: `$env:DSH_INSTALL_DIR/package.json` (`@deepseek-ai/dsh`). Do not answer from memory.

## 1. Choose the extension point

| You want | Extension point | First reference |
|---|---|---|
| A new tool or command for the model | Host plugin registering into `ctx.tools` / `ctx.commands` | `plugin-development.md`, `tool-design.md` |
| A panel, widget, sidebar entry, or chat row | Client plugin + Slot registration | `ui-plugin.md`, live `Slots` inspect |
| Different tools, persona, or prompt rules | Agent preset declaration row | `compositions.md` |
| Reusable procedures the model should load | Skill directory + `skill-filesystem` | `tool-design.md`, this bundle's `skills/` |
| An existing external server's tools | Configuration-only bundle with `dsh-mcp-client` | `mcp-bundle.md` |
| Shared state or an application action | Service, Remote, or user action over existing seams | `practices.md`, `user-actions.md` |

Prefer the smallest extension that satisfies the request; do not add a Host plugin when a preset row or a skill suffices.

## 2. Gather facts before writing code

1. `cordis_inspect_list`, then targeted `cordis_inspect_query`: `Service`, `Event`, `Config` (a mounted plugin's schema and `packageDir`), `Tool`, and Client `Slots` / `Theme`.
2. `dsh-doc` references, in this order: `locate-docs.md`, `plugin-development.md`, `host-plugin.md`, then the reference that matches the extension point.
3. `packages.md` for a package name and whether its row takes `config`. Confirm the name exists in this DSH version's installation.
4. Read one shipped patch as a template: `@deepseek-ai/dsh-web-app/cordis.patch.yml` and its `presets/*.patch.yml`.

## 3. Author the bundle

- `package.json`: `dsh.bundle.patch`; `exports` for `./locale/*.json` and `./icon`; `files` covering every runtime file, locale, icon, skill, and document. Add `engines.dsh` as a version gate when the bundle depends on a release surface.
- `cordis.patch.yml`: `insert` your rows, or override a shipped row by its exact `id`. A `config` override replaces the whole object — restate every field.
- Host entry: `export function apply(ctx, config)` or a service class; register everything through `ctx.effect`/`ctx.on` and return cleanup.
- Client entry: declare the client manifest, register slots, and keep the UI inside the theme tokens.
- Locales: `meta.title`, `meta.description`, and optionally `meta.detail` in each locale; English in sentence case, the user's language beside it.
- Icon: 36×36 SVG (or PNG/JPEG/WebP ≤ 256 KiB), original or licensed, transparent where it should be, no text unless drawn as paths.
- Document limitations and how to use the result in `meta.description` or the README.

## 4. Install and verify

1. Check the manifest and every JavaScript file's syntax before installing.
2. `plugin_manager` → `install_bundle` with the absolute package directory or a packed tarball. Read `application`, `warnings`, and `bundle` in the result.
3. Confirm the new row without an approval: `list_bundles` / `list_plugins` report the bundle and each row's `fiberPhase`. A preset row that failed activation stays on the roster with a diagnostic.
4. For a preset, open a **new** session and select it; existing sessions keep the plugin revision they started with.
5. Exercise the capability, inspect the live Client registration, and verify display metadata, icon, and detail page. Installation and slot registration alone do not prove what the user sees.

## 5. Verified traps

1. **Preset child rows resolve package names from the DSH installation, never from the profile.** A preset cannot mount a package that only the bundle installed. Put such a row at profile level, or use a shipped package.
2. **A bundle-local module is not addressable as a preset row `name`.** The row `name` is a literal specifier evaluated at mount; profile-only packages are invisible to it. A literal `file:///…` path works but breaks when the package moves.
3. **Resolve a bundle's own resources through `profileContext`.** `!!js` config can call `ctx.get('profileContext')` and `createRequire(join(pc.dir, 'package.json')).resolve('<pkg>/package.json')`; `baseUrl` points at the DSH installation, not the profile.
4. **`!!js` is Loader syntax; `!js` is invalid.** Keep expressions in `config` and `disabled`, and quote the expression when it contains YAML-special characters.
5. **The Web preset editor saves overrides into the profile patch by row `id`.** Hand edits to the profile patch can be shadowed or replaced; change the bundle, then reinstall.
6. **One scope permits one tool executor.** Mounting `@deepseek-ai/dsh-tool-executor-ptc` is a mode change: only `run_code` stays directly callable, and every other tool becomes a program binding. Do not add it as if it were one more tool.
7. **A local directory install links the checkout.** Use it for iteration, but pack a tarball for anything that must survive edits to the source directory.
8. **Replacing an installed package needs a restart** to load a fresh module generation; a new bundle can activate through HMR. Confirm with the installed row, not the logs.
9. **Sandbox output capture.** Under a confined shell, a native program's piped stdio can fail with EPERM. Run it through `Start-Process` with output redirected to a file, then read the file.
10. **Windows file conventions.** `.md`/`.json`/`.ts` UTF-8 without BOM, `.ps1` UTF-8 with BOM, `.bat` ASCII only; verify a double-clickable script actually runs before delivering it.

## 6. Publish

`npm pack` → inspect the packed file list → install that tarball in a clean profile → tag `v<major>.<minor>.<patch>` → changelog. Keep `engines.dsh` and the preset rows in sync with the DSH release you tested.

## References

- `dsh-doc` skill and its `references/` directory.
- Prior art: `zqh260619/DshAgentPresetForPlugin` (preset bundle shape, profile-resolved skills, browser MCP), `liupengyang-1008/dsh-plugin-development` (templates, validation, version gate), `axetroy/dsh-plugin-skills` and `liangdabiao/dsh-plugin-developer-skill` (skill-shaped guidance).
