@echo off
title miniPC - Setup Completo Pos-Formatacao (Metalfish T60)
cd /d "%~dp0"

:: 1. Auto-elevacao unica para Administrador (1 UAC no inicio)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de Administrador - apenas 1 vez...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

if not exist "%~dp0Logs" mkdir "%~dp0Logs"
set "MINIPC_CHAIN=1"

echo ===============================================================================
echo     miniPC - SETUP COMPLETO POS-FORMATACAO (EXECUTANDO TODAS AS ETAPAS)
echo ===============================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; Start-Transcript -Path '%~dp0Logs\Setup_Completo.log' -Force; & '%~dp0Otimizar_Pos_Formatacao.ps1'; & '%~dp0Instalar_Programas_Automatico.ps1'; & '%~dp0Verificar_Reparar_Inicializacao.ps1'; & '%~dp0Validar_Otimizacoes_SFF.ps1'; & '%~dp0Diagnostico_Video.ps1'; Stop-Transcript"

echo.
echo ===============================================================================
echo  Todas as etapas foram concluidas! Log salvo em: Logs\Setup_Completo.log
echo  Pressione qualquer tecla para fechar esta janela...
echo ===============================================================================
pause >nul
