param()

Clear-Host
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     VLESS + REALITY 一键搭建工具            ║" -ForegroundColor Cyan
Write-Host "║     帮你自动搭好翻墙服务器                   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  你需要准备：一台海外 VPS（香港的最好）" -ForegroundColor White
Write-Host "  你需要知道：VPS 的 IP 地址 和 root 密码" -ForegroundColor White
Write-Host ""
Write-Host "  准备好后，按回车继续..." -ForegroundColor Gray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$hasNode = $false

# 第一步：检查环境
Write-Host "`n>> 检查电脑环境..." -ForegroundColor Yellow
try { $nv = node --version 2>$null; if ($nv) { $hasNode = $true; Write-Host "  [OK] Node.js $nv" -ForegroundColor Green } } catch {}
if (-not $hasNode) {
  Write-Host "  正在安装 Node.js（约1分钟）..." -ForegroundColor Yellow
  $nodeUrl = "https://npmmirror.com/mirrors/node/latest/win-x64/node.exe"
  $nodeDir = "$env:ProgramFiles\nodejs"
  try {
    if (-not (Test-Path $nodeDir)) { mkdir $nodeDir -Force | Out-Null }
    $progressPreference = 'silentlyContinue'
    Invoke-WebRequest -Uri $nodeUrl -OutFile "$nodeDir\node.exe" -TimeoutSec 120 -ErrorAction Stop
    $progressPreference = 'Continue'
    $env:Path += ";$nodeDir"
    Write-Host "  [OK] Node.js 已安装" -ForegroundColor Green
  } catch {
    Write-Host "  [X] 自动安装失败，请手动安装 Node.js" -ForegroundColor Red
    pause; exit 1
  }
}
Write-Host "  准备 SSH 工具..." -ForegroundColor Yellow
pushd $scriptRoot
if (-not (Test-Path "node_modules\ssh2")) {
  npm init -y 2>$null | Out-Null
  npm install ssh2 --registry https://registry.npmmirror.com 2>$null | Out-Null
}
popd
Write-Host "  [OK] 环境就绪" -ForegroundColor Green

# 第二步：输入服务器信息
Write-Host "`n>> 连接你的服务器..." -ForegroundColor Yellow
$serverIp = Read-Host "  请输入服务器 IP"
$password = Read-Host -AsSecureString "  请输入 root 密码（输入时不显示）"
$plainPw = [System.Net.NetworkCredential]::new("", $password).Password

# 第三步：部署
Write-Host "`n>> 正在部署（约1-2分钟）..." -ForegroundColor Yellow
Write-Host "    - 连接服务器"
Write-Host "    - 安装 xray（服务端软件）"
Write-Host "    - 生成密钥和配置"
Write-Host "    - 启动服务"
pushd $scriptRoot
node server/deploy.js $serverIp $plainPw 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Host "`n  [X] 部署失败" -ForegroundColor Red
  Write-Host "     可能的原因：IP或密码错误、服务器未开机、网络不稳定"
  Write-Host "     检查后重新运行 setup.bat 再试一次"
  pause; exit 1
}
popd

# 第四步：下载 v2rayN
Write-Host "`n>> 准备客户端软件..." -ForegroundColor Yellow
$vDir = "$scriptRoot\v2rayN-windows-64"
$vExe = "$vDir\v2rayN.exe"
if (Test-Path $vExe) {
  Write-Host "  [OK] v2rayN 已存在" -ForegroundColor Green
} else {
  Write-Host "  下载 v2rayN（约50MB）..." -ForegroundColor Yellow
  $tag = ""
  try { $tag = (Invoke-RestMethod -Uri "https://ghproxy.com/https://api.github.com/repos/2dust/v2rayN/releases/latest" -TimeoutSec 15 -ErrorAction Stop).tag_name } catch {}
  $urls = if ($tag) { @("https://ghproxy.com/https://github.com/2dust/v2rayN/releases/download/$tag/v2rayN-$tag.zip","https://mirror.ghproxy.com/https://github.com/2dust/v2rayN/releases/download/$tag/v2rayN-$tag.zip") } else { @("https://ghproxy.com/https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-Core.zip") }
  $ok = $false
  foreach ($url in $urls) {
    try { $progressPreference = 'silentlyContinue'; Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\v2rayN.zip" -TimeoutSec 120 -ErrorAction Stop; $progressPreference = 'Continue'; Expand-Archive "$env:TEMP\v2rayN.zip" -DestinationPath $vDir -Force -ErrorAction Stop; Remove-Item "$env:TEMP\v2rayN.zip" -Force; $ok = $true; break } catch {}
  }
  if (-not $ok) { Write-Host "  下载失败，可手动下载解压到 $vDir" -ForegroundColor Yellow }
}

# 第五步：完成
$cfg = "$scriptRoot\output\v2rayN-config.json"
$dst = "$vDir\binConfigs\config.json"
if (Test-Path $cfg) { mkdir "$vDir\binConfigs" -Force | Out-Null; Copy-Item $cfg $dst -Force }
if (Test-Path $vExe) { Start-Process $vExe }

Clear-Host
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  完成！" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  v2rayN 已启动，在右下角托盘可以找到它"
Write-Host ""
Write-Host "  配置浏览器翻墙："
Write-Host "  1. 打开 Edge 浏览器"
Write-Host "  2. 搜索 SwitchyOmega 插件并安装"
Write-Host "  3. 新建代理配置：SOCKS5 / 127.0.0.1 / 10808"
Write-Host ""
Write-Host "  配置参数备份在: output\v2rayN-config.json"
Write-Host ""
Write-Host "按回车退出..."
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")