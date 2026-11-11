@echo off
title miniPC - Enviar para o GitHub (Push)
cd /d "%~dp0"
echo ========================================================
echo   miniPC - Enviando Commits para o GitHub
echo ========================================================
echo.
set "GIT_EXE=git"
where git >nul 2>&1
if %errorlevel% neq 0 (
    if exist "C:\Program Files\Git\cmd\git.exe" set "GIT_EXE=C:\Program Files\Git\cmd\git.exe"
    if exist "C:\Users\MarcosMiniPC\Tools\Git\cmd\git.exe" set "GIT_EXE=C:\Users\MarcosMiniPC\Tools\Git\cmd\git.exe"
)
"%GIT_EXE%" push origin main
echo.
echo ========================================================
echo Concluido! Pressione qualquer tecla para fechar.
echo ========================================================
pause
