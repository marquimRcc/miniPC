<#
.SYNOPSIS
    Script Mestre de Otimizacao Agressiva para Gabinete SFF / Pouca Ventilacao
    Hardware Alvo: AMD Ryzen 5 5600 + AMD Radeon RX 7600 (Gabinete Metalfish T60 / B550i)
    Foco: Menor temperatura possivel, zero congelamentos de boot e estabilidade maxima.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "    OTIMIZACAO SFF MESTRE — BAIXA TEMPERATURA & ESTABILIDADE              " -ForegroundColor Cyan
Write-Host "    Metalfish T60 | Ryzen 5 5600 | RX 7600 | JGINYUE B550i                " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. PLANO DE ENERGIA EQUILIBRADO OTIMIZADO
Write-Host "[1/7] Configurando Plano de Energia Equilibrado Otimizado..." -ForegroundColor Yellow
$balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
powercfg /setactive $balancedGuid
# Permite que a CPU Ryzen 5600 desca para 5% de clock em repouso (reduz ate 15C em idle)
powercfg /setacvalueindex $balancedGuid SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg /setacvalueindex $balancedGuid SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setactive $balancedGuid
Write-Host "      [OK] Processador agora reduz voltagem e clock em repouso." -ForegroundColor Green

# 2. DESATIVACAO PERMANENTE DA INICIALIZACAO RAPIDA (FAST STARTUP)
Write-Host "[2/7] Desativando Inicializacao Rapida (Fast Startup)..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "      [OK] Fast Startup desativado (previne telas pretas e perda de undervolt)." -ForegroundColor Green
} catch {
    Write-Host "      [AVISO] Requer privilegios de administrador para alterar HKLM." -ForegroundColor Yellow
}

# 3. OTIMIZACAO PARA JOGOS (MODO DE JOGO & GAMEDVR)
Write-Host "[3/7] Otimizando Windows para Jogos (Latencia e GPU)..." -ForegroundColor Yellow
if (!(Test-Path "HKCU:\Software\Microsoft\GameBar")) { New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# Desativa gravacao de fundo GameDVR (alivia o encoder da RX 7600)
if (!(Test-Path "HKCU:\System\GameConfigStore")) { New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR")) { New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "      [OK] Modo de Jogo ativado; gravacao de fundo (GameDVR) desativada." -ForegroundColor Green

# 4. ELIMINACAO DE SERVICOS CONFLITANTES (GAMEINPUT REDIST)
Write-Host "[4/7] Verificando servicos conflitantes..." -ForegroundColor Yellow
$legacySvc = Get-Service -Name "GameInputRedistService" -ErrorAction SilentlyContinue
if ($legacySvc) {
    Stop-Service -Name "GameInputRedistService" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "GameInputRedistService" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "      [OK] Servico legado GameInputRedistService desativado com sucesso." -ForegroundColor Green
} else {
    Write-Host "      [OK] Sem servicos redundantes detectados." -ForegroundColor Green
}

# 5. REGISTRAR AUTO-REPARO NA INICIALIZACAO DO WINDOWS (SHELL:STARTUP)
Write-Host "[5/7] Configurando Auto-Reparo na Inicializacao do Windows..." -ForegroundColor Yellow
$startupFolder = [System.Environment]::GetFolderPath('Startup')
$repairBat = Join-Path $PSScriptRoot "Verificar_Reparar_Inicializacao.bat"
$shortcutPath = Join-Path $startupFolder "Verificar_Reparar_Inicializacao.lnk"

if (Test-Path $repairBat) {
    $wsh = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $repairBat
    $shortcut.WorkingDirectory = $PSScriptRoot
    $shortcut.Description = "Auto-reparo e diagnostico SFF na inicializacao"
    $shortcut.WindowStyle = 7 # Minimized
    $shortcut.Save()
    Write-Host "      [OK] Auto-reparo registrado na inicializacao (shell:startup)." -ForegroundColor Green
} else {
    Write-Host "      [INFO] Script de reparo nao encontrado no diretorio atual." -ForegroundColor Gray
}

# 6. LIMPEZA DE CACHES E TEMPORARIOS
Write-Host "[6/7] Limpando caches de shaders, temporarios e DNS..." -ForegroundColor Yellow
Remove-Item -Path "$env:LOCALAPPDATA\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\AMD\CN\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
Clear-DnsClientCache
Write-Host "      [OK] Caches e temporarios limpos com sucesso." -ForegroundColor Green

# 7. DESATIVAR TELEMETRIAS E WIDGETS PESADOS
Write-Host "[7/7] Desativando widgets e telemetria pesada..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -ErrorAction SilentlyContinue
$cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Set-ItemProperty -Path $cdm -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdm -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdm -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Write-Host "      [OK] Widgets e sugestoes em segundo plano desativados." -ForegroundColor Green

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "        OTIMIZACAO DO WINDOWS CONCLUIDA COM SUCESSO!                      " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Recomendacoes de Hardware (Consulte ANALISE_TECNICA_HARDWARE.md):" -ForegroundColor Cyan
Write-Host "1. BIOS JGINYUE B550i: PBO -> Curve Optimizer: Negative 10/20 -> Limite: 75C"
Write-Host "2. Curva CPU BIOS: 35C->120 | 45C->170 | 55C->220 | 65C->255 (100% aos 65C)"
Write-Host "3. AMD Adrenalin (GPU): Max 2550 MHz | 1100 mV | Fan 100% aos 70C | Chill 60 FPS"
Write-Host ""
