@echo off
title Instalador Automatico de Programas - miniPC Metalfish T60
cd /d "%~dp0"

:: Auto-elevacao para Administrador (necessario para instalacoes silenciosas)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de Administrador para instalacao silenciosa...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cls
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar_Programas_Automatico.ps1"

echo.
echo ===============================================================================
echo  Instalacao finalizada! Pressione qualquer tecla para fechar esta janela...
echo ===============================================================================
pause >nul
