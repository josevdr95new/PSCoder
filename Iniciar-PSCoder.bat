@echo off
REM PSCoder Launcher
REM Note: -ExecutionPolicy Bypass is required to run local scripts.
REM This is safe for locally-developed scripts but should not be used
REM for scripts from untrusted sources.
chcp 65001 >nul
title PSCoder - AI Assistant
echo.
echo  Starting PSCoder...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0Start-PSCoder.ps1"
pause
