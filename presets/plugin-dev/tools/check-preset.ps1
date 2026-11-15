# 插件开发预设 - DSH profile 只读自检脚本
# 不写入任何文件，只检查 bundle 是否已安装、是否已在 profile 的 bundles 列表中被选中。
[CmdletBinding()]
param(
    [string]$ProfileName = 'desktop',
    [string]$BundleName = '@local/dsh-plugin-dev-preset'
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }

$failures = 0
function Ok([string]$text) { Write-Host ('  [OK]   ' + $text) -ForegroundColor Green }
function Warn([string]$text) { Write-Host ('  [WARN] ' + $text) -ForegroundColor Yellow }
function Bad([string]$text) { Write-Host ('  [FAIL] ' + $text) -ForegroundColor Red; $script:failures++ }

Write-Host ''
Write-Host '插件开发预设 - 安装自检' -ForegroundColor Cyan
Write-Host ('bundle: ' + $BundleName)

$profileDir = if ($env:DSH_PROFILE_DIR) {
    $env:DSH_PROFILE_DIR
} else {
    Join-Path ([Environment]::GetFolderPath('UserProfile')) (Join-Path '.dsh\profiles' $ProfileName)
}

Write-Host ('profile: ' + $profileDir)
Write-Host ''

if (-not (Test-Path -LiteralPath $profileDir)) {
    Bad ('profile 目录不存在：' + $profileDir)
    Write-Host ''
    Write-Host '请先在 DSH 里创建该 profile，或改用 -ProfileName 指定正确的名字。' -ForegroundColor Yellow
    exit 2
}
Ok 'profile 目录存在'

$manifestPath = Join-Path $profileDir 'package.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Bad ('profile package.json 不存在：' + $manifestPath)
    exit 2
}

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8 | ConvertFrom-Json
} catch {
    Bad ('profile package.json 不是合法 JSON：' + $_.Exception.Message)
    exit 2
}
Ok 'profile package.json 可解析'

$declared = $null
if ($manifest.dependencies -and $manifest.dependencies.PSObject.Properties.Name -contains $BundleName) {
    $declared = $manifest.dependencies.$BundleName
}
if ($declared) {
    Ok ('已声明依赖：' + $BundleName + ' = ' + $declared)
} else {
    Bad ('未声明依赖：' + $BundleName)
}

$selected = $false
if ($manifest.dsh -and $manifest.dsh.profile -and $manifest.dsh.profile.bundles) {
    $selected = @($manifest.dsh.profile.bundles) -contains $BundleName
}
if ($selected) {
    Ok '已在 dsh.profile.bundles 中选中'
} else {
    Warn '尚未在 dsh.profile.bundles 中选中：去「插件」页启用「插件开发预设」'
}

$packageDir = Join-Path $profileDir (Join-Path 'node_modules' ($BundleName -replace '/', '\'))
$packageFile = Join-Path $packageDir 'package.json'
if (Test-Path -LiteralPath $packageFile) {
    try {
        $package = Get-Content -LiteralPath $packageFile -Raw -Encoding utf8 | ConvertFrom-Json
        Ok ('已安装包版本：' + $package.version)
    } catch {
        Warn '已找到包目录，但 package.json 无法解析'
    }
    if (Test-Path -LiteralPath (Join-Path $packageDir 'cordis.patch.yml')) {
        Ok '预设声明文件 cordis.patch.yml 存在'
    } else {
        Bad '包目录里缺少 cordis.patch.yml'
    }
    $skillsDir = Join-Path $packageDir 'skills'
    if (Test-Path -LiteralPath $skillsDir) {
        $skillCount = @(Get-ChildItem -LiteralPath $skillsDir -Directory -ErrorAction SilentlyContinue).Count
        Ok ('自带技能目录：' + $skillCount + ' 个')
    } else {
        Warn '包目录里没有 skills 目录'
    }
} else {
    Bad ('未安装到 profile：' + $packageDir)
}

Write-Host ''
if ($failures -eq 0 -and $selected) {
    Write-Host '结论：已安装并已选中。新建会话时在模式下拉里选择「插件开发」即可。' -ForegroundColor Green
    Write-Host '提示：已有会话保留启动时的版本，必须新开会话才会用上这个预设。' -ForegroundColor DarkGray
    exit 0
}

if ($failures -eq 0) {
    Write-Host '结论：已安装，但还没选中。打开「插件」页启用后，新建会话选择「插件开发」。' -ForegroundColor Yellow
    exit 1
}

Write-Host '结论：尚未安装完整。安装方式见 README.md 的「安装」一节。' -ForegroundColor Yellow
exit 1
