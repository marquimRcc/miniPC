@echo off
title miniPC - Enviar para o GitHub (Push)
cd /d "C:\Users\MarcosMiniPC\miniPC"
echo ========================================================
echo   miniPC - Enviando Commits para o GitHub
echo ========================================================
echo.
"C:\Users\MarcosMiniPC\Tools\Git\cmd\git.exe" push origin main
echo.
echo ========================================================
echo Concluido! Pressione qualquer tecla para fechar.
echo ========================================================
pause
