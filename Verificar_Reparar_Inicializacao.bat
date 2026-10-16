@echo off
title Auto-Reparo e Diagnostico SFF
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Verificar_Reparar_Inicializacao.ps1"
