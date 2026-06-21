param()

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  VLESS + REALITY 一键部署工具" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$hasNode = $false

# ─── 1. 检查/安装 Node.js ──────────────────────────────
Write-Host "`n[1/6] 检查 Node.js..."
try {
  $nv = node --version 2>$null
  if ($nv) { Write-Host "  [OK] Node.js $nv" -ForegroundColor Green; $hasNode = $true }
} catch {}

if (-not $hasNode) {
  Write-Host "  [!] 未检测到 Node.js" -ForegroundColor Yellow
  Write-Host "  [..] 正在自动下载安装包..." -ForegroundColor Yellow

  $nodeUrl = "https://npmmirror.com/mirrors/node/latest/win-x64/node.exe"
  $nodeDir = "$env:ProgramFiles\nodejs"
  $nodePath = "$nodeDir\node.exe"

  try {
    if (-not (Test-Path $nodeDir)) { mkdir $nodeDir -Force | Out-Null }
    $progressPreference = 'silentlyContinue'
    Invoke-WebRequest -Uri $nodeUrl -OutFile "$nodeDir\node.exe" -TimeoutSec 120 -ErrorAction Stop
    $progressPreference = 'Continue'
    # 添加到 PATH
    $env:Path += ";$nodeDir"
    [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "Machine") + ";$nodeDir", "Machine")
    $nv = & "$nodePath" --version 2>$null
    Write-Host "  [OK] Node.js $nv 已安装" -ForegroundColor Green
    $hasNode = $true
  } catch {
    Write-Host "  [X] 自动安装失败" -ForegroundColor Red
    Write-Host "  [i] 手动安装: https://nodejs.org (下载 Windows 版安装即可)" -ForegroundColor Yellow
    pause; exit 1
  }
}

# ─── 2. 安装 SSH 依赖 ──────────────────────────────────
Write-Host "`n[2/6] 安装依赖..."
pushd $scriptRoot
if (-not (Test-Path "node_modules\ssh2")) {
  npm init -y 2>$null | Out-Null
  npm install ssh2 --registry https://registry.npmmirror.com 2>$null | Out-Null
  if (-not (Test-Path "node_modules\ssh2")) {
    # 换官方源重试
    npm install ssh2 2>$null | Out-Null
  }
}
popd
Write-Host "  [OK] 依赖就绪" -ForegroundColor Green
Write-Host ""

# ─── 3. 输入服务器信息 ──────────────────────────────────
Write-Host "[3/6] 输入服务器信息"
$serverIp = Read-Host "  服务器 IP"
$password = Read-Host -AsSecureString "  root 密码"
$plainPw = [System.Net.NetworkCredential]::new("", $password).Password

# ─── 4. 部署到服务器 ────────────────────────────────────
Write-Host "`n[4/6] 部署 xray 到服务器..."
Write-Host "       (大约需要 1-2 分钟)"
Write-Host ""
pushd $scriptRoot
node server/deploy.js $serverIp $plainPw 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Host "`n  [X] 部署失败，请检查:" -ForegroundColor Red
  Write-Host "      1. IP 地址是否正确" -ForegroundColor Yellow
  Write-Host "      2. root 密码是否正确" -ForegroundColor Yellow
  Write-Host "      3. 服务器是否已开机" -ForegroundColor Yellow
  pause; exit 1
}
popd

# ─── 5. 下载 v2rayN ────────────────────────────────────
Write-Host "`n[5/6] 检查 v2rayN..."
$vDir = "$scriptRoot\v2rayN-windows-64"
$vExe = "$vDir\v2rayN.exe"

if (Test-Path $vExe) {
  Write-Host "  [OK] v2rayN 已存在" -ForegroundColor Green
} else {
  Write-Host "  [..] 正在下载 v2rayN..."
  Write-Host "        (大小约 50MB，请稍候)"
  Write-Host ""

  # 获取版本号
  $tag = ""
  try {
    $tag = (Invoke-RestMethod -Uri "https://ghproxy.com/https://api.github.com/repos/2dust/v2rayN/releases/latest" -TimeoutSec 15 -ErrorAction Stop).tag_name
  } catch {}

  if ($tag) { $urls = @(
    "https://ghproxy.com/https://github.com/2dust/v2rayN/releases/download/$tag/v2rayN-$tag.zip",
    "https://mirror.ghproxy.com/https://github.com/2dust/v2rayN/releases/download/$tag/v2rayN-$tag.zip"
  )} else { $urls = @(
    "https://ghproxy.com/https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-Core.zip"
  )}

  $ok = $false
  foreach ($url in $urls) {
    try {
      Write-Host "   下载中..."
      $zip = "$env:TEMP\v2rayN.zip"
      $progressPreference = 'silentlyContinue'
      Invoke-WebRequest -Uri $url -OutFile $zip -TimeoutSec 120 -ErrorAction Stop
      $progressPreference = 'Continue'
      Expand-Archive $zip -DestinationPath $vDir -Force -ErrorAction Stop
      Remove-Item $zip -Force -ErrorAction SilentlyContinue
      $ok = $true; break
    } catch { Write-Host "   重试其他源..." -ForegroundColor DarkGray }
  }

  if (-not $ok) {
    Write-Host "  [!] 下载失败" -ForegroundColor Yellow
    Write-Host "      手动下载: https://github.com/2dust/v2rayN/releases" -ForegroundColor Yellow
    Write-Host "      解压到: $vDir" -ForegroundColor Yellow
  }
}

# ─── 6. 配置并启动 ──────────────────────────────────────
Write-Host "`n[6/6] 应用配置..."
$cfg = "$scriptRoot\output\v2rayN-config.json"
$dst = "$vDir\binConfigs\config.json"
if (Test-Path $cfg) {
  mkdir "$vDir\binConfigs" -Force | Out-Null
  Copy-Item $cfg $dst -Force
  Write-Host "  [OK] 配置已应用" -ForegroundColor Green
}
if (Test-Path $vExe) {
  Start-Process $vExe
  Write-Host "  [OK] v2rayN 已启动" -ForegroundColor Green
}

Write-Host "`n================================================" -ForegroundColor Green
Write-Host "  部署完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  下一步:" -ForegroundColor Cyan
Write-Host "  1. 右下角托盘找到 v2rayN 图标" -ForegroundColor White
Write-Host "  2. 浏览器安装 SwitchyOmega 插件" -ForegroundColor White
Write-Host "  3. 配置 SOCKS5 代理 127.0.0.1:10808" -ForegroundColor White
Write-Host ""
Write-Host "  配置参数保存在: output\v2rayN-config.json" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Green
pause
