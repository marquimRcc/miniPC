@echo off
title Validacao das Otimizacoes SFF
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Validar_Otimizacoes_SFF.ps1"
echo.
echo Pressione qualquer tecla para sair...
pause >nul
