param()
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$configFile = "$scriptDir\..\..\v2rayN-windows-64\binConfigs\config.json"

function Title($t) { Write-Host "`n================================================" -ForegroundColor Cyan; Write-Host "  $t" -ForegroundColor Cyan; Write-Host "================================================" -ForegroundColor Cyan }
function Pass($m) { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "  [X] $m" -ForegroundColor Red }
function Info($m) { Write-Host "  [i] $m" -ForegroundColor Gray }

# 1. 环境检查
Title "环境检查"
try { $nv = node --version 2>$null; Pass "Node.js $nv" } catch { Fail "Node.js 未安装" }
$vp = Get-Process -Name "v2rayN" -ErrorAction SilentlyContinue
if ($vp) { Pass "v2rayN 运行中 (PID $($vp.Id))" } else { Warn "v2rayN 未运行" }
$cc = Get-Process -Name "cc-switch" -ErrorAction SilentlyContinue
if ($cc) { Pass "CC Switch 运行中 (PID $($cc.Id))" } else { Warn "CC Switch 未运行" }
$px = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
if ($px.ProxyEnable -eq 1) { Warn "系统代理: $($px.ProxyServer)" } else { Pass "系统代理已关闭" }

# 2. 配置检查
Title "配置检查"
if (-not (Test-Path $configFile)) { Fail "配置文件不存在: $configFile" }
else {
  Pass "配置文件存在"
  try {
    $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
    $ob = $cfg.outbounds | Where-Object { $_.tag -eq "proxy" }
    if ($ob) {
      $sv = $ob.settings.vnext[0]
      Pass "服务器: $($sv.address):$($sv.port)"
      $rs = $ob.streamSettings.realitySettings
      if ($rs.publicKey -and $rs.publicKey -ne "CHANGE_ME") { Pass "PublicKey: 已配置" } else { Fail "PublicKey 无效" }
      if ($rs.shortId) { Pass "ShortId: $($rs.shortId)" } else { Fail "ShortId 为空" }
      if ($rs.serverName) { Pass "SNI: $($rs.serverName)" } else { Fail "SNI 为空" }
    } else { Fail "未找到 proxy 出站" }
  } catch { Fail "配置文件格式错误: $_" }
}

# 3. 端口检查
Title "端口检查"
$ns = netstat -ano 2>$null
if ($ns | Select-String ":10808 ") { Pass "端口 10808 (v2rayN)" } else { Warn "端口 10808 未监听" }
if ($ns | Select-String ":15721 ") { Pass "端口 15721 (CC Switch)" } else { Warn "端口 15721 未监听" }

Title "诊断完成"
Write-Host "  项目: https://github.com/xiao768108/v2rayN-quickstart" -ForegroundColor Cyan
Write-Host ""; $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
