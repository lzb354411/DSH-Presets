# DSH 预设（DSH Presets）

两个可安装的 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) Agent 预设，均为 `dsh.bundle.patch` 捆绑包，只新增预设、不覆盖任何内置预设。

| 预设 | 预设 id | 目录 | 说明 |
|---|---|---|---|
| 插件开发 | `plugin-dev` | [`presets/plugin-dev`](presets/plugin-dev) | 以创造模式的插件开发工具为基底，融入编程模式的工程纪律与 Superpowers/ponytail 技能库，覆盖插件、捆绑包与预设的设计、实现、安装和验证 |
| 编程模式 | `programming` | [`presets/programming`](presets/programming) | 在标准模式全部能力之上强制执行 Superpowers 工程纪律（技能优先、先设计、先计划、TDD、系统化调试、完成前验证、评审收尾、中文文档、Ponytail 代码体量克制），随包分发 Superpowers/ponytail 技能库 |

两个预设可**同时安装**，预设 id 不同，互不覆盖；新建会话时在模式下拉里任选。

## 安装

每个 bundle 单独安装，任选一种方式：

- **插件页**：打开 **插件** 页 → **添加插件** → 选择 `presets/plugin-dev` 或 `presets/programming` 目录（或安装后的 `.tgz`）；确认对应预设行状态为 `active`，然后**新建会话**选择该模式。
- **让 Agent 安装**：对 Agent 说「用 `plugin_manager` 的 `install_bundle` 安装 `<目录绝对路径>`」（需要 Full access 或单次审批）。
- **CLI**：`dsh plugin --profile desktop add <目录或 tgz 绝对路径>`，再在插件页把 bundle 选中。

> 若 profile 的 `cordis.patch.yml` 里已手动声明过 `preset-programming`，安装「编程模式」bundle 前请先删除那段声明，否则 profile 层会按行 id 覆盖 bundle 层。

## 验证

1. **插件** 页出现「插件开发预设」/「编程模式预设」，bundle 与预设行都显示激活；
2. 新建会话并选择对应模式；
3. 插件开发：会话具备 `cordis_inspect_list` / `cordis_inspect_query`、`plugin_manager`、`skill`、`subagent`、`workflow`、`apply_patch`、`mcp__playwright__*` 等工具；
4. 编程模式：开场包含「编程模式 (Programming Mode)」九条纪律，具备 `pwsh`、`skill`、`subagent`、`workflow`、`schedule`、Office、`present` 等工具；
5. 技能目录：插件开发 23 个（官方 `dsh-doc` + 22 个自带），编程模式 22 个（官方 `dsh-doc` + 21 个自带）。

## 仓库结构

```
presets/
  plugin-dev/          # 「插件开发」bundle（含 dev/ 自检脚本与 tools/ 安装自检）
    cordis.patch.yml
    package.json
    locale/  skills/  icon.svg
    README.md  SKILLS-LICENSE.md  LICENSE
  programming/         # 「编程模式」bundle
    cordis.patch.yml
    package.json
    locale/  skills/  icon.svg
    README.md  SKILLS-LICENSE.md  LICENSE
README.md
LICENSE
```

每个 `presets/<id>/` 目录本身就是一个可安装的 bundle，可单独复制、打包为 tgz 或作为插件源引用。

## 升级 DSH 之后

两个预设的插件行都引用 DSH 安装内的包。每次升级：

1. 对照新版本 `@deepseek-ai/dsh-web-app/presets/standard.patch.yml`（编程模式）与 `cordis.patch.yml`（插件开发）逐行同步；
2. 重新打包并重装 bundle；
3. 在**新会话**里验证；旧会话保留启动时的插件版本。

## 已知限制

详见各 bundle 的 README。共性限制：

- 预设子行只能解析 DSH 安装内的包，解析不到 profile 里安装的 bundle；技能目录用 `profileContext` 定位并保留回退。
- 本仓库不内置 PTC 执行器与 LSP；需要时在插件开发预设的 `cordis.patch.yml` 注释处按需启用（LSP 还要求安装版本里内置 `dsh-lsp*` 包）。浏览器验证已默认内置（Playwright MCP + 系统 Edge）。
- 两个预设都不会把默认模式改成自己。

## 授权与致谢

- 本仓库整体以 MIT 授权，见 [`LICENSE`](LICENSE)。
- Superpowers（[obra/superpowers](https://github.com/obra/superpowers)，MIT）与 ponytail（[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)，MIT）技能随包分发，出处与授权见各 bundle 的 `SKILLS-LICENSE.md`。
- `dsh-doc` 技能来自 DeepSeek Harness 安装包，不随本仓库复制。
- 形态参考：[zqh260619/DshAgentPresetForPlugin](https://github.com/zqh260619/DshAgentPresetForPlugin)、[liupengyang-1008/dsh-plugin-development](https://github.com/liupengyang-1008/dsh-plugin-development)、[axetroy/dsh-plugin-skills](https://github.com/axetroy/dsh-plugin-skills)、[liangdabiao/dsh-plugin-developer-skill](https://github.com/liangdabiao/dsh-plugin-developer-skill)。
