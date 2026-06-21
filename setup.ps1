param()
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  v2rayN 一键搭建 (全自动)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Run deploy.exe to set up server
$deploy = "$scriptRoot\deploy.exe"
if (-not (Test-Path $deploy)) {
  Write-Host "[!] 找不到 deploy.exe" -ForegroundColor Red
  pause; exit 1
}

& $deploy
if ($LASTEXITCODE -ne 0) {
  Write-Host "[!] 部署失败" -ForegroundColor Red
  pause; exit 1
}

# Step 2: Download v2rayN
$vDir = "$scriptRoot\v2rayN"
$vExe = "$vDir\v2rayN.exe"
if (Test-Path $vExe) {
  Write-Host "`n[OK] v2rayN 已存在" -ForegroundColor Green
} else {
  Write-Host "`n>> 下载 v2rayN..." -ForegroundColor Yellow
  $tag = ""
  try { $tag = (Invoke-RestMethod -Uri "https://ghproxy.com/https://api.github.com/repos/2dust/v2rayN/releases/latest" -TimeoutSec 15 -ErrorAction Stop).tag_name } catch {}
  $urls = if ($tag) { @("https://ghproxy.com/https://github.com/2dust/v2rayN/releases/download/$tag/v2rayN-$tag.zip","https://mirror.ghproxy.com/https://github.com/2dust/v2rayN/releases/download/$tag/v2rayN-$tag.zip") } else { @("https://ghproxy.com/https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-Core.zip") }
  $ok = $false
  foreach ($url in $urls) {
    try { $progressPreference = 'silentlyContinue'; Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\v2rayN.zip" -TimeoutSec 120 -ErrorAction Stop; Expand-Archive "$env:TEMP\v2rayN.zip" -DestinationPath "$env:TEMP\v2rayN-tmp" -Force; Move-Item "$env:TEMP\v2rayN-tmp\*" $vDir -Force; Remove-Item "$env:TEMP\v2rayN-tmp","$env:TEMP\v2rayN.zip" -Recurse -Force -ErrorAction SilentlyContinue; $ok = $true; break } catch {}
  }
  if ($ok) { Write-Host "[OK] v2rayN 下载完成" -ForegroundColor Green } else { Write-Host "[!] 下载失败，手动下载: https://github.com/2dust/v2rayN/releases" -ForegroundColor Yellow }
}

# Step 3: Copy config
$cfg = "$scriptRoot\v2rayN-config.json"
$dst = "$vDir\binConfigs\config.json"
if (Test-Path $cfg) { mkdir "$vDir\binConfigs" -Force | Out-Null; Copy-Item $cfg $dst -Force; Write-Host "[OK] 配置已应用" -ForegroundColor Green }

# Step 4: Start v2rayN
if (Test-Path $vExe) { Start-Process $vExe; Write-Host "[OK] v2rayN 已启动" -ForegroundColor Green }

Write-Host "`n完成！浏览器装 SwitchyOmega，配置 SOCKS5 127.0.0.1:10808" -ForegroundColor Green
pause