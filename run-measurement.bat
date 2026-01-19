@echo off
REM Network Performance Measurement - Batch Wrapper
REM This batch file runs the PowerShell script with the correct execution policy

echo Starting Network Performance Measurement...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0measure-network.ps1"

echo.
echo Press any key to exit...
pause >nul
