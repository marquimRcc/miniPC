@echo off
title Otimizacao Agressiva SFF - Temperatura Baixa
chcp 65001 >nul

:: Executa o script PowerShell ignorando politicas de execucao
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Otimizar_Pos_Formatacao.ps1"

echo.
echo Pressione qualquer tecla para sair...
pause >nul
