# 插件开发预设可用性验证报告

- 测试时间：2026-11-15 19:03–19:45（Asia/Shanghai）
- 测试会话：`session-1449509b-f440-4c19-81ee-a736fec9b076`（本会话，模式「插件开发」）
- 运行版本：DSH `0.2.2-rc.3`｜Profile `desktop`｜`DSH_HOME=C:\Users\14544\.dsh`
- 工作区：`E:\2-agent-hub\DSH-预设-插件开发预设`（仓库 `main`，测试前工作树干净）

## 1. 结论

**能用，且本会话正在使用它。** bundle 已在桌面 profile 实装、预设行处于 `active`、本会话已切入 `plugin-dev` 模式，persona、技能目录、工具面与运行时探查全部生效；bundle 自带的三项自检脚本全部通过。

三条结论性证据：

1. `plugin_manager list_plugins`：`include:preset-plugin-dev` → `enabled: true`、`fiberPhase: active`。
2. 会话日志事件 `agent-preset/selected`（seq=5）记录 `{"agentPreset":"plugin-dev"}`，随后注入的系统提示词即本 bundle 的 11 条纪律（含第 10 条「插件开发不变量」）。
3. 技能实际从 `C:\Users\14544\.dsh\profiles\desktop\node_modules\@local\dsh-plugin-dev-preset\skills\using-superpowers` 加载 —— `profileContext` 技能根解析成功，没有退化成回退路径。

## 2. 实装状态

| 项 | 实测值 |
|---|---|
| bundle | `@local/dsh-plugin-dev-preset@0.1.2` |
| 依赖来源 | `file:C:/Users/14544/.dsh/plugin-sources/dsh-plugin-dev-preset/local-dsh-plugin-dev-preset-0.1.2.tgz` |
| 安装形态 | profile `node_modules` 下的解包副本（无符号链接），符合「产物区打包 → 实装区安装」 |
| 是否选中 | profile `package.json` 的 `dsh.profile.bundles` 含该 bundle |
| 与开发区一致性 | `package.json`、`cordis.patch.yml`、`locale/zh.json`、`locale/en.json`、`icon.svg` 五份 SHA256 全部相同 |
| 版本闸门 | `engines.dsh: >=0.2.2-rc.3`，当前 `0.2.2-rc.3` 满足 |
| 展示元数据 | `locale/zh.json` 含 `meta.title`「插件开发预设」与 `meta.description`；`icon.svg` 583 字节 |

## 3. 能力验证（有证据的部分）

### 3.1 运行时探查（预设核心能力）

| 查询 | 结果 |
|---|---|
| `cordis_inspect_list` | 9 个 provider：host `Service` / `Event` / `Config` / `Tool`，client `Service` / `Event` / `Builtin` / `Slots` / `Theme` |
| host `Service.listService` | 返回 `agentPresets`（含 `select` / `mount` / `recompose`）、`tools`、`subagents`、`workflowEngine` 等方法签名与类型 |
| host `Config.listConfigs(name=@deepseek-ai/dsh-agent-preset)` | 6 个预设声明行：standard / ptc / minimal / cordis / **plugin-dev** / programming，schema 状态正常 |
| host `Tool.listTools` | 本会话 54 个可直接调用的工具 |
| client `Slots.listSubTree` | 返回 root 槽树（含 `conversation.chat.node` 的 `tool.call.toolview` key 域与已占用 key 表） |
| client `Theme.listTokens` | 14 个 `--dsw-alias-*` 主题 token |

### 3.2 工具面

预设 `cordis.patch.yml` 声明的模型侧行全部命中：

- 终端与文件：`pwsh`、`read` / `write` / `edit` / `glob` / `grep`、`read_image`
- 后台与定时：`job_list` / `job_output` / `job_kill`、`schedule_create` / `schedule_list` / `schedule_view` / `schedule_edit`
- 目标与计划：`get_goal` / `create_goal` / `update_goal`、`exit_plan_mode`
- 委派与编排：`subagent`、`subagent_fork`、`workflow`、`list_agents` / `wait_agent` / `send_message`
- 交互与任务：`ask_user_question`、`todo_write`、`web_search` / `web_fetch`、`present`
- 插件开发专用：`cordis_inspect_list` / `cordis_inspect_query`、`skill`、`plugin_manager`、`plugin_market`
- 其他自 profile bundle 注册：`team_task_*`、`remote_*`、`propose_action`、`create_worktree`、`load_workspace_dependencies`、`working_directory`

按设计缺席：`bash`（win32 禁用）、`apply_patch`（`applyPatch: false`）、`run_code`（未挂载 PTC）、LSP、浏览器 MCP 工具。

### 3.3 技能

- 实装包 `skills/` 22 个目录；会话技能目录 = 22 个自带 + 官方 `dsh-doc` = **23**，与 README 期望一致。
- 本次实际加载 4 个：`using-superpowers`、`dsh-doc`、`dsh-plugin-dev-playbook`、`verification-before-completion`，`skill` 工具均从实装包路径返回内容。

### 3.4 文档源

- `dsh-doc` 的 `references/locate-docs.md`、安装包内 `docs/user/index.md` 均可通过 read 工具从 `app.asar` 读取。
- 子代理独立复核：`resources\app.asar` 为单归档（209,021,953 字节），按 asar 头定位 `@deepseek-ai/dsh/package.json` 读出 `version=0.2.2-rc.3`，与 `runtime.json` 的 `desktopVersion` 一致。

### 3.5 子代理

`probe` 子代理完成冒烟：返回 `profile=desktop`、`version=0.2.2-rc.3`、`installerExe=DeepSeek Harness.exe`，全程只读。

### 3.6 bundle 自检脚本

| 脚本 | 结果 |
|---|---|
| `tools/check-preset.ps1` | 8 项 `[OK]`，exit 0：「已安装并已选中」 |
| `dev/validate-bundle.cjs`（Electron 作 node） | `ok: true`；preset `plugin-dev` / `插件开发` / `order: 5`；pluginRows 23、packages 28、skills 22、iconBytes 583、`problems: []` |
| `dev/compare-cordis.cjs` | `shippedRows: 32` / `ourRows: 32`；差异仅 `EXPECTED persona`、`EXPECTED skill-filesystem`（均为设计内差异） |

### 3.7 能力状态汇总

| 能力 | 状态 |
|---|---|
| 预设挂载、persona、技能根 | 已实测 |
| 运行时探查（Service / Config / Tool / Slots / Theme） | 已实测 |
| 文件读写、pwsh、grep、glob | 已实测 |
| `skill`、`todo_write`、`present`、`plugin_manager`（只读）、`plugin_market`（只读） | 已实测 |
| `subagent` | 已实测 |
| `subagent_fork`、`workflow`、`schedule_*`、goal 系列、`ask_user_question`、remote / team 系列 | 仅确认已注册，未逐一执行 |
| `install_bundle`（写实装区） | 未执行（不必要，且会改 profile） |

## 4. 能力边界

1. **没有浏览器控制**：Playwright MCP 未挂载，无法截图或点击 GUI；Web 插件的视觉验证要么由用户查看，要么按 `cordis.patch.yml` 末尾注释启用 `browser-playwright`（需 Chrome 以 `--remote-debugging-port=9222` 启动）。
2. **没有 `run_code`**：PTC 执行器未挂载；启用后一个作用域只能有一个执行器，其余工具会变成程序内绑定。
3. **没有 LSP、没有 `apply_patch`**，Windows 下没有 `bash`（与预设设计一致）。
4. **预设子行只从 DSH 安装解析包名**：bundle 自带技能靠 `profileContext` 定位；若安装位置或方式改变导致解析失败，会退化为只加载 `dsh-doc`，不中断会话。
5. **权限现状**：本会话已是 `danger-full-access` 且关闭审批；但按预设第 10 条，写 C 盘、`$DSH_HOME`、profile、注册表等仍应先征得用户同意。

## 5. 一个容易误判的点

会话头里的 `agentPreset` 字段是**创建时**的值（本会话为 `standard`），切换模式只追加 `agent-preset/selected` 事件，不改写头部。判断某个会话实际用的模式要看事件与系统提示词，不能看头部字段。

## 6. 复现命令（PowerShell 7+）

```powershell
$bundle = 'E:\2-agent-hub\DSH-预设-插件开发预设\presets\plugin-dev'
$exe = "$env:LOCALAPPDATA\Programs\DeepSeek Harness\DeepSeek Harness.exe"

# 安装自检（只读）
& "$bundle\tools\check-preset.ps1"

# 清单 / 包名 / 技能 / 图标校验；注意路径含空格，必须走 ArgumentList 传参
$psi = [System.Diagnostics.ProcessStartInfo]::new($exe)
foreach ($a in @("$bundle\dev\validate-bundle.cjs", $bundle, $env:DSH_INSTALL_DIR, "$env:TEMP\report.json")) { $psi.ArgumentList.Add($a) }
$psi.Environment['ELECTRON_RUN_AS_NODE'] = '1'
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$p = [System.Diagnostics.Process]::Start($psi)
$p.StandardOutput.ReadToEnd(); $p.WaitForExit(); "exit=$($p.ExitCode)"
```

## 7. 建议（未执行）

- `presets/plugin-dev/README.md` 的「本地实测记录」仍写着「尚未验证：新会话中选择插件开发后的实际工具目录与技能目录」。本次已补齐该验证，可把该条改成已验证并链接本报告。