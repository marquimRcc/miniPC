<#
.SYNOPSIS
    Script de Bootstrap e Execucao Pós-Formatacao Full para o Mini PC (Metalfish T60)
    Executavel tanto online via Web (irm ... | iex) quanto localmente (pos_formatacao_full).
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Garante privilegios de Administrador com auto-elevacao (1 unico UAC)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[*] Solicitando permissao de Administrador (UAC)..." -ForegroundColor Yellow
    if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/marquimRcc/miniPC/main/pos_formatacao_full.ps1 | iex`""
        exit
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "     INICIANDO POS-FORMATACAO FULL - MINI PC SFF                          " -ForegroundColor Cyan
Write-Host "     Metalfish T60 | Ryzen 5 5600 | RX 7600 | JGINYUE B550i               " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

$targetDir = "$env:USERPROFILE\miniPC"
$zipPath   = "$env:TEMP\miniPC_setup.zip"
$tempExt   = "$env:TEMP\miniPC_extracted"

# 2. Se a pasta do repositorio nao existir ou se executado online, baixa a versao mais recente
if (!(Test-Path "$targetDir\EXECUTAR_TUDO.bat")) {
    Write-Host "[1/3] Baixando suite completa do GitHub (marquimRcc/miniPC)..." -ForegroundColor Yellow
    Invoke-RestMethod -Uri "https://github.com/marquimRcc/miniPC/archive/refs/heads/main.zip" -OutFile $zipPath
    
    Write-Host "[2/3] Extraindo arquivos em $targetDir..." -ForegroundColor Yellow
    if (Test-Path $tempExt) { Remove-Item $tempExt -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $zipPath -DestinationPath $tempExt -Force
    
    if (!(Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
    Copy-Item -Path "$tempExt\miniPC-main\*" -Destination $targetDir -Recurse -Force
    
    Remove-Item -Path $zipPath, $tempExt -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "      [OK] Suite baixada e extraida com sucesso." -ForegroundColor Green
} else {
    Write-Host "[1/3] Suite ja localizada localmente em $targetDir." -ForegroundColor Green
}

# 3. Registra comando permanente 'pos_formatacao_full' no Windows (disponivel em qualquer terminal)
Write-Host "[3/3] Registrando comando global 'pos_formatacao_full' no sistema..." -ForegroundColor Yellow
$appsFolder = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
if (Test-Path $appsFolder) {
    $cmdContent = "@echo off`r`ncall `"$targetDir\EXECUTAR_TUDO.bat`" %*"
    Set-Content -Path "$appsFolder\pos_formatacao_full.cmd" -Value $cmdContent -Force
}

# Também garante a pasta no PATH do usuário
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$targetDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$targetDir", "User")
}

Write-Host "      [OK] Comando global 'pos_formatacao_full' ativo! Pode ser chamado de qualquer lugar." -ForegroundColor Green
Write-Host ""
Write-Host "Disparando o orquestrador mestre EXECUTAR_TUDO.bat..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# 4. Inicia a execucao mestre
Set-Location -Path $targetDir
& "$targetDir\EXECUTAR_TUDO.bat"
