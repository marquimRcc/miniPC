@echo off
title Otimizacao SFF - Metalfish T60 (Ryzen 5600 + RX 7600)
chcp 65001 >nul
cd /d "%~dp0"

:: Auto-elevacao para Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de Administrador...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo ==========================================================================
echo    INICIANDO SUITE DE OTIMIZACAO SFF POS-FORMATACAO (ADMIN)
echo ==========================================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Otimizar_Pos_Formatacao.ps1"

echo.
echo ==========================================================================
echo   Processo finalizado com sucesso! Pressione qualquer tecla para sair...
echo ==========================================================================
pause >nul
