@echo off
title Otimizacao SFF - Metalfish T60 (Ryzen 5600 + RX 7600)
cd /d "%~dp0"

echo ==========================================================================
echo    INICIANDO SUITE DE OTIMIZACAO SFF POS-FORMATACAO
echo ==========================================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Otimizar_Pos_Formatacao.ps1"

echo.
echo ==========================================================================
echo   Processo finalizado! Pressione qualquer tecla para fechar esta janela...
echo ==========================================================================
pause >nul
