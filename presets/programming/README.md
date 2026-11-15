# 编程模式预设（DSH Agent Preset）

一句话：把「标准模式」的全部能力加上 Superpowers 工程纪律与 Superpowers/ponytail 技能库，作为一个可安装的 Agent 预设。

- 预设 id：`programming`
- 列表名称：`编程模式`（`order: 10`，排在「标准模式」之后）
- 载体：一个 `dsh.bundle.patch` 捆绑包（`package.json` + `cordis.patch.yml`），只**新增**预设，不覆盖任何内置预设
- 仓库内的另一预设：「插件开发」（`presets/plugin-dev`，id `plugin-dev`），两者可同时安装

## 它由什么组成

| 来源 | 继承/新增的能力 |
|---|---|
| 标准模式（内置 `standard` 预设） | shell（bash/pwsh）、文件读写与检索、后台任务、定时任务、goals、计划模式、上下文压缩、subagent / subagent_fork、workflow、ask_user、todo、web、present、Office、时间上下文 |
| 本预设 | 九条工程纪律 persona（技能优先、先设计、先计划、TDD、系统化调试、完成前验证、评审收尾、中文文档、Ponytail 代码体量克制）+ 21 个 Superpowers/ponytail 技能 + 官方 `dsh-doc` 技能 |

与内置 `standard` 预设的差异只有两处：

1. `persona` 换成九条纪律 + 中文文档要求；
2. `skill-filesystem` 追加本 bundle 自带的 `skills/`（21 个技能），同时保留官方 `dsh-doc`。

其余插件行逐条对齐 DSH **0.2.2-rc.3** 的 `@deepseek-ai/dsh-web-app/presets/standard.patch.yml`。

## 安装

### 方式 A：插件页（推荐）

1. 打开 **插件** 页；
2. 用 **添加插件** 选择本目录（或安装后的 `.tgz`）；
3. 确认出现「编程模式预设」，行状态为 `active`；
4. **新建会话**，在模式下拉里选择「编程模式」。

### 方式 B：让 Agent 安装

对 Agent 说：用 `plugin_manager` 的 `install_bundle` 安装 `<本目录绝对路径>`。安装动作需要 Full access 或单次审批。

### 方式 C：CLI（`dsh` 在 PATH 上时）

```powershell
dsh plugin --profile desktop add <本目录或 tgz 的绝对路径>
```

CLI 只完成包安装；还要在 **插件** 页把该捆绑包选中（bundle 选择写入 `dsh.profile.bundles`）。

> **如果 profile 的 `cordis.patch.yml` 里已经手动声明过 `preset-programming`**（例如从旧安装包迁移来的），请先删除那段声明再安装本 bundle：profile patch 会按 Loader 行 id 覆盖 bundle 层，留着旧块会让本 bundle 的技能目录配置不生效。

## 验证

1. **插件** 页出现「编程模式预设」，bundle 与预设行都显示激活状态；
2. 新建会话并选择「编程模式」，开场提示词包含「编程模式 (Programming Mode)」与九条纪律；
3. 会话应具备 `pwsh`、`skill`、`subagent`、`workflow`、`schedule`、Office、`present` 等工具；
4. 让 Agent 打开技能目录，应能看到 22 个技能：官方 `dsh-doc` + 21 个自带技能（`using-superpowers`、`brainstorming`、`writing-plans`、`test-driven-development`、`systematic-debugging`、`verification-before-completion`、`ponytail` 系列等）。

## 升级 DSH 之后

预设行引用的是 DSH 安装内的包。每次升级：

1. 对照新版本 `@deepseek-ai/dsh-web-app/presets/standard.patch.yml` 逐行同步（新增、改名、`config` schema 变化）；
2. 重新打包并重装 bundle；
3. 在**新会话**里验证；旧会话保留启动时的插件版本。

## 已知限制

- **不包含「首步强制注入」**：上游安装包的 `force-superpowers` 模块依赖预设目录内的 `declaration.mjs`，并带「安装包卸载后把预设改写成墓碑」的逻辑，与 bundle 自包含的安装模型冲突。纪律由 persona 强制，`using-superpowers` 等技能在目录里可随时用 `skill` 加载。
- **技能根的定位依赖 `profileContext`**：在 profile 中按包名 `@local/dsh-programming-preset` 定位安装目录，带两级回退；定位失败时退化为只加载官方 `dsh-doc`（不会中断会话）。
- 不包含旧安装包的卸载/墓碑逻辑；卸载本 bundle 时按 DSH 插件页的正常流程操作即可。
- 本预设不会把默认模式改成自己；新会话默认仍是「标准模式」。

## 授权与致谢

- Superpowers（[obra/superpowers](https://github.com/obra/superpowers)，MIT）与 ponytail（[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)，MIT）技能由本预设随包分发，出处与授权见 `SKILLS-LICENSE.md`。
- `dsh-doc` 技能来自 DeepSeek Harness 安装包，不随本 bundle 复制。
