@echo off
chcp 65001 >nul
title VLESS + REALITY 一键部署工具

echo ================================================
echo   VLESS + REALITY 一键部署工具
echo ================================================
echo.
echo  正在启动部署助手...
echo  请勿关闭此窗口
echo.

cd /d "%~dp0"

REM 检查 PowerShell 执行策略，临时绕过
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0start.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  按任意键退出...
    pause >nul
)
