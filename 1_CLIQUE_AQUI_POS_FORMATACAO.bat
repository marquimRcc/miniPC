@echo off
title Suite Pos-Formatacao - Mini PC Metalfish T60
cd /d "%~dp0"

:: Auto-elevacao para Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de Administrador para aplicar otimizacoes...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cls
echo ===============================================================================
echo     APLICANDO CONFIGURACOES DE SEGURANCA E BAIXA TEMPERATURA (POS-FORMATACAO)
echo ===============================================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Otimizar_Pos_Formatacao.ps1"

echo.
echo ===============================================================================
echo  Tudo pronto! Pressione qualquer tecla para fechar esta janela...
echo ===============================================================================
pause >nul
