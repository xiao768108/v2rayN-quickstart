# 下载最新版 v2rayN

$repo = "2dust/v2rayN"
$releases = "https://api.github.com/repos/$repo/releases/latest"

Write-Host "获取最新版本信息..." -ForegroundColor Cyan
$tag = (Invoke-RestMethod -Uri $releases).tag_name
Write-Host "最新版本: $tag" -ForegroundColor Green

$downloadUrl = "https://github.com/$repo/releases/download/$tag/v2rayN-$tag.zip"
$output = "$PSScriptRoot\..\v2rayN.zip"

Write-Host "下载中: $downloadUrl" -ForegroundColor Cyan
Invoke-WebRequest -Uri $downloadUrl -OutFile $output

Write-Host "下载完成: $output" -ForegroundColor Green
Write-Host "解压到当前目录后运行 v2rayN.exe" -ForegroundColor Yellow
