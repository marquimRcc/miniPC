@echo off
title Auto-Reparo e Diagnostico de Inicializacao
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Verificar_Reparar_Inicializacao.ps1"
if not "%1"=="--silent" (
    echo.
    echo Pressione qualquer tecla para sair...
    pause >nul
)
