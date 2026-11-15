# 插件开发预设（DSH Agent Preset）

> 本目录是「DSH 预设」仓库中的一个独立 bundle；下文命令均在本目录（presets/plugin-dev）内执行。

一句话：把「创造模式」的插件开发工具与「编程模式」的工程纪律、Superpowers/ponytail 技能库合成一个可选的 Agent 预设，专用于开发 DeepSeek Harness 的插件、捆绑包与预设。

- 预设 id：`plugin-dev`
- 列表名称：`插件开发`（排序 `order: 5`，位于「创造模式」之后）
- 载体：一个 `dsh.bundle.patch` 捆绑包，只**新增**预设，不覆盖任何内置预设

## 它由什么组成

| 来源 | 继承的能力 |
|---|---|
| 创造模式（内置 `cordis` 预设） | shell（bash/pwsh）、文件读写与检索、后台任务、定时任务、goals、计划模式、上下文压缩、subagent / subagent_fork、workflow、ask_user、todo、web、present、运行时探查（`cordis_inspect_list/query`）、官方 `dsh-doc` 技能、插件管理与插件市场工具 |
| 编程模式（自定义 `programming` 预设） | 九条工程纪律（技能优先、先设计、先计划、先定验证、系统化调试、完成前验证、评审收尾、中文交付、Ponytail 代码体量克制）、Superpowers 15 个技能、ponytail 6 个技能 |
| 本仓库新增 | 第 10 条「插件开发不变量」、自带技能根（含 `dsh-plugin-dev-playbook`）、`engines.dsh` 版本闸门、可选 PTC / 浏览器 MCP / LSP 的注释位 |

与「创造模式」的差异只有两处：`persona` 的内容、`skill-filesystem` 多一个技能根。其余插件行逐条对齐 DSH **0.2.2-rc.3** 的 `@deepseek-ai/dsh-web-app/presets/cordis.patch.yml`。

## 安装

### 方式 A：插件页（推荐）

1. 打开 **插件** 页；
2. 用 **添加插件** 选择本目录（或安装后的 `.tgz`）；
3. 确认出现「插件开发预设」，行状态为 `active`；
4. **新建会话**，在模式下拉里选择「插件开发」。

### 方式 B：让 Agent 安装

对 Agent 说：用 `plugin_manager` 的 `install_bundle` 安装 `<本目录绝对路径>`。安装动作需要 Full access 或单次审批。

### 方式 C：CLI（`dsh` 在 PATH 上时）

```powershell
dsh plugin --profile desktop add <本目录或 tgz 的绝对路径>
```

CLI 只完成包安装；还要在 **插件** 页把该捆绑包选中（bundle 选择写入 `dsh.profile.bundles`）。

## 验证

1. **插件** 页出现「插件开发预设」，bundle 与预设行都显示激活状态；
2. 新建会话并选择「插件开发」；
3. 会话应具备 `cordis_inspect_list` / `cordis_inspect_query`、`plugin_manager`、`skill`、`subagent`、`workflow` 等工具；
4. 让 Agent 调用一次 `cordis_inspect_list`，确认运行时探查可用；
5. 让 Agent 打开技能目录，确认能看到 `dsh-doc`、`using-superpowers`、`dsh-plugin-dev-playbook` 等 23 个技能（官方 1 个 + 自带 22 个）。

### 本地实测记录（2026-11-15，DSH 0.2.2-rc.3，desktop profile）

- bundle `0.1.2` 已安装，依赖来源为 `file:<插件源目录>/local-dsh-plugin-dev-preset-0.1.2.tgz`（实装区副本，不指向开发区）；
- `plugin_manager list_plugins` 中 `include:preset-plugin-dev` 为 `enabled: true`、`fiberPhase: active`；
- 安装目录验证：`cordis.patch.yml`、`locale/zh.json`、`icon.svg`、`README.md`、`skills/` 共 22 个技能均存在；
- 与内置「创造模式」逐行对比（32 个条目）：仅 `persona` 与 `skill-filesystem` 两处差异，符合设计；
- 尚未验证：**新会话中选择「插件开发」后的实际工具目录与技能目录**——这需要你新开一个会话确认（见上方步骤 2–5）。

## 升级 DSH 之后

预设行引用的是 DSH 安装内的包。每次升级：

1. 对照新版本 `@deepseek-ai/dsh-web-app/presets/cordis.patch.yml` 逐行同步（新增、改名、`config` schema 变化）；
2. 重新打包并重装 bundle；
3. 在**新会话**里验证；旧会话保留启动时的插件版本。

## 已知限制

- **预设子行只能解析 DSH 安装内的包**，解析不到 profile 里安装的本 bundle；因此本 bundle 自带的模块不能直接作为预设行 `name`。
- 未移植「编程模式」的 `force-superpowers` 首步强制注入：该行依赖 preset 目录外的 `force-superpowers.mjs`，与「bundle 自包含」冲突。纪律改由 persona 强制，技能在目录里可随时用 `skill` 加载。
- 技能根的定位依赖 `profileContext`。安装方式改变导致定位失败时会退化为只加载官方 `dsh-doc`（不会中断会话）。
- 未内置浏览器验证；需要截图验证 Web 插件时，取消 `cordis.patch.yml` 末尾 `browser-playwright` 注释（要求 Chrome 以 `--remote-debugging-port=9222` 启动）。
- 未内置 PTC 执行器；需要 `run_code` 时取消对应注释，注意启用后工具调用形态整体改变。
- 本预设不会把默认模式改成自己；新会话默认仍是「标准模式」。
- Web 预设编辑器保存的修改会写进 profile 的 `cordis.patch.yml`，按行 id `preset-plugin-dev` 覆盖；优先改 bundle 再重装，避免两处不一致。

## 运维记录

### 2026-11-15 修复桌面 profile 的「编程模式」加载失败

- 现象：`插件开发` 预设正常，`编程模式` 预设加载失败；两者都需要可用。
- 根因：`~/.dsh/.agent-presets/programming/force-superpowers.mjs` 静态 `import './declaration.mjs'`，而 17:26 重建预设目录时只复制了 `force-superpowers.mjs` 与 `skills/`，`declaration.mjs` 丢失，ESM 抛 `ERR_MODULE_NOT_FOUND`；该子行 import 失败使整棵预设 mount 失败。`插件开发` 没有这一行，所以不受影响。
- 未直接补回 `declaration.mjs` 的原因：该模块带孤儿清理；安装包 `@ziduup/dsh-programming-mode` 已不在 profile 依赖中，行一旦挂载成功，它会把预设改写成「编程模式（已卸载）」墓碑（有历史会话时）或删除预设目录（无历史会话时）。
- 处理（实装区）：编辑 `~/.dsh/profiles/desktop/cordis.patch.yml` 的 `preset-programming.config.plugins`，删除 `force-superpowers` 行，并按 DSH 0.2.2-rc.3 的 `standard.patch.yml` 补 `time-context`、`tool-schedule`、`tool-office` 三行；`preset-programming` 声明保留，预设 id 与历史会话不受影响。
- 备份：`cordis.patch.yml.bak-20261115-182847`（修改前，SHA256 `6F986502…`）。回滚：用该备份覆盖 `cordis.patch.yml` 后重启 DSH。
- 生效：profile patch 由 HMR 热重载；若模式列表仍报错，重启 DSH 后新开会话验证。
- 注意：`force-superpowers.mjs` 已无引用，文件仍在预设目录，不要再挂回该行，除非补回 `declaration.mjs` 并解决孤儿清理；重装 `@ziduup/dsh-programming-mode` 会重新写回声明行。
- 仍与 standard 有差异（非故障）：`tool-fs` 未设 `applyPatch: false`、`tool-subagent-control` 未设 `interrupt: false`；首步自动注入已移除，由 persona 纪律承担。

## 目录结构

```
package.json                     # bundle 清单：dsh.bundle.patch / exports / files / engines.dsh
cordis.patch.yml                 # 预设声明（唯一运行入口）
icon.svg                         # 插件页图标
locale/en.json, locale/zh.json   # 插件页展示元数据
skills/                          # bundle 自带 22 个技能（21 个纪律技能 + 本预设 playbook）
SKILLS-LICENSE.md                # Superpowers / ponytail 的 MIT 授权与出处
tools/                           # 只读自检脚本（check-preset.ps1 + 双击 check-preset.bat）
dev/                             # 开发期校验：validate-bundle.cjs、compare-cordis.cjs
dist/                            # 打包产物（*.tgz，不提交）
README.md
LICENSE
```

## 本地校验

两个开发期脚本需要 DSH 自带的 Electron 运行时（能读 `app.asar`）与安装目录里的 `js-yaml`：

```powershell
$env:ELECTRON_RUN_AS_NODE = '1'
$exe = "$env:LOCALAPPDATA\Programs\DeepSeek Harness\DeepSeek Harness.exe"
$install = "C:\Users\<你>\AppData\Local\Programs\DeepSeek Harness\resources\app.asar\dsh\node_modules\@deepseek-ai\dsh"

# 1) 清单 / YAML / 22 个技能 / 图标 / 包名是否存在
& $exe dev\validate-bundle.cjs $PWD $install "$env:TEMP\report.json"

# 2) 与内置「创造模式」逐行对比（预期只有 persona 与 skill-filesystem 两处差异）
& $exe dev\compare-cordis.cjs $PWD $install "$env:TEMP\compare.json"
```

## 授权与致谢

- Superpowers（[obra/superpowers](https://github.com/obra/superpowers)，MIT）与 ponytail（[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)，MIT）技能由本预设随包分发，出处与授权见 `SKILLS-LICENSE.md`。
- `dsh-doc` 技能来自 DeepSeek Harness 安装包，不随本 bundle 复制。
- 形态参考：[zqh260619/DshAgentPresetForPlugin](https://github.com/zqh260619/DshAgentPresetForPlugin)（预设 bundle 结构、profile 内技能定位、浏览器 MCP）、[liupengyang-1008/dsh-plugin-development](https://github.com/liupengyang-1008/dsh-plugin-development)（模板、校验、版本闸门）、[axetroy/dsh-plugin-skills](https://github.com/axetroy/dsh-plugin-skills) 与 [liangdabiao/dsh-plugin-developer-skill](https://github.com/liangdabiao/dsh-plugin-developer-skill)（技能化工作流）。
