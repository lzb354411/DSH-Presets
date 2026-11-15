# 插件开发预设 0.1.3 离线修复与安装（DeepSeek Harness 必须已关闭）
#
# 背景：在线 install_bundle 时 pnpm 无法改名被运行中 DSH 占用的包目录（EPERM），
# profile 里 @local/dsh-plugin-dev-preset 只剩一个空目录，完整的 0.1.2 停在
# dsh-plugin-dev-preset_tmp_19640_10，0.1.3 的 tgz 在仓库 dist/ 下。
# 本脚本先恢复 0.1.2 作为可回退状态，再用 dsh CLI 安装 0.1.3 并校验。
#
# 用法：双击 repair-install-preset-0.1.3.bat，或
#       pwsh -NoProfile -ExecutionPolicy Bypass -File .\repair-install-preset-0.1.3.ps1
# 只检查不修改：加 -CheckOnly

[CmdletBinding()]
param([switch]$CheckOnly)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }

$profileDir = if ($env:DSH_PROFILE_DIR) { $env:DSH_PROFILE_DIR } else { 'C:\Users\14544\.dsh\profiles\desktop' }
$localDir = Join-Path $profileDir 'node_modules\@local'
$target = Join-Path $localDir 'dsh-plugin-dev-preset'
$staged = Join-Path $localDir 'dsh-plugin-dev-preset_tmp_19640_10'
$sourcesDir = 'C:\Users\14544\.dsh\plugin-sources\dsh-plugin-dev-preset'
$tgzSrc = 'E:\2-agent-hub\DSH-预设-插件开发预设\dist\local-dsh-plugin-dev-preset-0.1.3.tgz'
$tgzDest = Join-Path $sourcesDir 'local-dsh-plugin-dev-preset-0.1.3.tgz'
$appExe = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\DeepSeek Harness.exe'
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\resources\app.asar\dsh\node_modules\@deepseek-ai\dsh'
$binJs = Join-Path $installDir 'lib\bin.js'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Write-Section([string]$title) {
    Write-Host ''
    Write-Host ('== ' + $title + ' ==') -ForegroundColor Cyan
}

function Get-PresetVersion([string]$dir) {
    $file = Join-Path $dir 'package.json'
    if (-not (Test-Path -LiteralPath $file)) { return $null }
    try { return (Get-Content -LiteralPath $file -Raw -Encoding utf8 | ConvertFrom-Json).version } catch { return $null }
}

function Test-DshRunning {
    $procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq 'DeepSeek Harness' })
    return $procs.Count -gt 0
}

Write-Host '插件开发预设 0.1.3 - 离线修复与安装' -ForegroundColor Green
Write-Section '当前状态'
Write-Host ("profile : " + $profileDir)
Write-Host ("target  : " + $target + "  version=" + (Get-PresetVersion $target))
Write-Host ("staged  : " + $staged + "  version=" + (Get-PresetVersion $staged))
Write-Host ("tgz     : " + $tgzSrc + "  exists=" + (Test-Path -LiteralPath $tgzSrc))
Write-Host ("DSH     : running=" + (Test-DshRunning))

if ($CheckOnly) {
    Write-Host ''
    Write-Host '-CheckOnly：只检查，未做任何修改。'
    exit 0
}

if (-not (Test-Path -LiteralPath $tgzSrc)) {
    Write-Host ('找不到安装包：' + $tgzSrc) -ForegroundColor Red
    exit 2
}

if (Test-DshRunning) {
    Write-Host ''
    Write-Host 'DSH 正在运行。请先完全退出 DeepSeek Harness（含托盘图标），本脚本每 2 秒自动重试，最多等 15 分钟。' -ForegroundColor Yellow
    $deadline = (Get-Date).AddMinutes(15)
    while (Test-DshRunning) {
        if ((Get-Date) -gt $deadline) {
            Write-Host '等待超时：DSH 仍在运行，已退出，未做任何修改。' -ForegroundColor Red
            exit 3
        }
        Start-Sleep -Seconds 2
    }
    Write-Host 'DSH 已退出，继续。' -ForegroundColor Green
}

Write-Host ''
Write-Host '将执行：'
Write-Host '  1) 把没有 package.json 的损坏目录改名保留（*.broken-时间戳）'
Write-Host '  2) 把 0.1.2 暂存目录恢复到原路径（可回退状态）'
Write-Host '  3) 把 0.1.3 的 tgz 复制到插件源目录'
Write-Host '  4) 运行 dsh CLI：plugin --profile desktop add <tgz>'
Write-Host '  5) 校验版本、技能数量、browser-playwright 行与 profile 依赖'
$answer = Read-Host '输入 YES 继续'
if ($answer -ne 'YES') {
    Write-Host '已取消，未做任何修改。'
    exit 0
}

Write-Section '1/5 处理损坏目录'
if (Test-Path -LiteralPath $target) {
    if (-not (Test-Path -LiteralPath (Join-Path $target 'package.json'))) {
        $broken = "$target.broken-$stamp"
        Rename-Item -LiteralPath $target -NewName (Split-Path -Leaf $broken)
        Write-Host ('已改名保留：' + $broken)
    } else {
        Write-Host '目标目录已有 package.json，保持原样。'
    }
}

Write-Section '2/5 恢复 0.1.2 暂存目录'
if (-not (Test-Path -LiteralPath $target)) {
    if (-not (Test-Path -LiteralPath $staged)) {
        Write-Host '既没有目标目录，也没有暂存目录可恢复。' -ForegroundColor Red
        exit 4
    }
    Rename-Item -LiteralPath $staged -NewName 'dsh-plugin-dev-preset'
    Write-Host '已恢复暂存目录。'
}
$before = Get-PresetVersion $target
if (-not $before) {
    Write-Host '恢复后的目录没有可解析的 package.json，停止。' -ForegroundColor Red
    exit 4
}
Write-Host ('恢复后版本：' + $before)

Write-Section '3/5 复制安装包到插件源'
New-Item -ItemType Directory -Force -Path $sourcesDir | Out-Null
Copy-Item -LiteralPath $tgzSrc -Destination $tgzDest -Force
Write-Host ('已复制：' + $tgzDest)

Write-Section '4/5 dsh CLI 安装 0.1.3'
$env:ELECTRON_RUN_AS_NODE = '1'
$log = Join-Path $env:TEMP ("dsh-plugin-add-" + $stamp + ".log")
$errLog = $log + '.err'
$proc = Start-Process -FilePath $appExe -ArgumentList @($binJs, 'plugin', '--profile', 'desktop', 'add', $tgzDest) -Wait -PassThru -NoNewWindow -RedirectStandardOutput $log -RedirectStandardError $errLog
if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log -Encoding utf8 -ErrorAction SilentlyContinue | Select-Object -Last 25 }
if ((Test-Path -LiteralPath $errLog) -and (Get-Item $errLog).Length -gt 0) {
    Write-Host 'stderr:' -ForegroundColor Yellow
    Get-Content -LiteralPath $errLog -Encoding utf8 -ErrorAction SilentlyContinue | Select-Object -Last 25
}
if ($proc.ExitCode -ne 0) {
    Write-Host ('dsh plugin add 失败，退出码 ' + $proc.ExitCode + '；日志：' + $log) -ForegroundColor Red
    Write-Host '当前仍是 0.1.2（可用），可以重跑本脚本或把日志发给我。'
    exit 5
}

Write-Section '5/5 校验'
$after = Get-PresetVersion $target
$skills = @(Get-ChildItem (Join-Path $target 'skills') -Directory -ErrorAction SilentlyContinue).Count
$patchFile = Join-Path $target 'cordis.patch.yml'
$hasBrowser = (Test-Path -LiteralPath $patchFile) -and (Select-String -LiteralPath $patchFile -Pattern 'browser-playwright' -Quiet)
$hasApplyPatch = (Test-Path -LiteralPath $patchFile) -and (Select-String -LiteralPath $patchFile -Pattern 'applyPatch: true' -Quiet)
$profileJson = Get-Content -LiteralPath (Join-Path $profileDir 'package.json') -Raw -Encoding utf8 | ConvertFrom-Json
$dep = $null
if ($profileJson.dependencies.PSObject.Properties.Name -contains '@local/dsh-plugin-dev-preset') {
    $dep = $profileJson.dependencies.'@local/dsh-plugin-dev-preset'
}
Write-Host ('安装版本      : ' + $after)
Write-Host ('自带技能数量  : ' + $skills)
Write-Host ('browser-playwright 行 : ' + $hasBrowser)
Write-Host ('applyPatch: true      : ' + $hasApplyPatch)
Write-Host ('profile 依赖  : ' + $dep)

$ok = ($after -eq '0.1.3') -and ($skills -eq 22) -and $hasBrowser -and $hasApplyPatch -and ($dep -like '*0.1.3.tgz')
if (-not $ok) {
    Write-Host '校验未全部通过，请把上面的输出发给我。' -ForegroundColor Red
    exit 6
}
Write-Host '0.1.3 安装完成，校验通过。' -ForegroundColor Green
Write-Host '下一步：启动 DSH，新建会话并选「插件开发」，确认工具里有 mcp__playwright__* 与 apply_patch。'
Write-Host '提示：已打开的旧会话保留启动时的预设版本，必须新开会话。'

$startAnswer = Read-Host '现在启动 DSH？(Y/n)'
if ($startAnswer -ne 'n') {
    Start-Process -FilePath $appExe
    Write-Host '已尝试启动 DeepSeek Harness。'
}
