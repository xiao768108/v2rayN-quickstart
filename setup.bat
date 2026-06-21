@echo off
chcp 65001 >nul
title v2rayN 一键搭建工具

echo ================================================
echo   v2rayN 一键搭建工具
echo ================================================
echo.

cd /d "%~dp0"

REM 检查更新
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0scripts\update.ps1"

if %ERRORLEVEL% NEQ 0 goto :eof

REM 运行主程序
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0start.ps1"

pause
