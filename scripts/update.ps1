# Version check + auto-update
param()
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$localVersion = "1.0.0"

Write-Host "检查更新..." -ForegroundColor Yellow
try {
  $remote = Invoke-RestMethod -Uri "https://gitee.com/api/v5/repos/xiaoyaoyou08/v2rayN-quickstart/releases/latest" -TimeoutSec 10 -ErrorAction Stop
  $remoteVer = $remote.tag_name
  if ($remoteVer -gt $localVersion) {
    Write-Host "发现新版本: $remoteVer" -ForegroundColor Cyan
    Write-Host "当前版本: $localVersion" -ForegroundColor Gray
    $ans = Read-Host "是否更新? (y/n)"
    if ($ans -eq "y") {
      $url = "https://gitee.com/xiaoyaoyou08/v2rayN-quickstart/repository/archive/master.zip"
      Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\update.zip" -TimeoutSec 60
      Expand-Archive "$env:TEMP\update.zip" -DestinationPath "$env:TEMP\update" -Force
      Copy-Item "$env:TEMP\update\*\*" $scriptRoot -Recurse -Force
      Remove-Item "$env:TEMP\update.zip" -Force; Remove-Item "$env:TEMP\update" -Recurse -Force
      Write-Host "更新完成，请重新运行" -ForegroundColor Green; pause; exit
    }
  } else { Write-Host "已是最新版" -ForegroundColor Green }
} catch { Write-Host "检查更新失败，跳过" -ForegroundColor Yellow }
