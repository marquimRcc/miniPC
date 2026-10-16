@echo off
title Painel de Validacao SFF
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Validar_Otimizacoes_SFF.ps1"
echo.
echo Pressione qualquer tecla para sair...
pause >nul
