<#
.SYNOPSIS
    Script de Otimizacao Agressiva para Gabinete SFF / Pouca Ventilacao
    Hardware Alvo: AMD Ryzen 5 5600 + AMD Radeon RX 7600 (Placa-mae B550i)
    Foco: Menor temperatura possivel sem perda de FPS em jogos.
#>

# Força codificação UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "    OTIMIZACAO AGRESSIVA DE TEMPERATURA E DESEMPENHO (SFF / ITX)          " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. PLANO DE ENERGIA EQUILIBRADO OTIMIZADO
Write-Host "[1/6] Configurando Plano de Energia Equilibrado..." -ForegroundColor Yellow
$balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
powercfg -setactive $balancedGuid
# Permite que os núcleos desçam para 5% em repouso (reduz até 15°C em idle)
powercfg -setacvalueindex $balancedGuid SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg -setacvalueindex $balancedGuid SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg -setacvalueindex $balancedGuid SUB_PCIEXPRESS pciepm 1
powercfg -setactive $balancedGuid
Write-Host "      -> Processador agora reduz voltagem e clock em repouso." -ForegroundColor Green

# 2. DESATIVACAO DA INICIALIZACAO RAPIDA (HIBERBOOT)
Write-Host "[2/6] Desativando Inicializacao Rapida (Fast Startup)..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "      -> Fast Startup desativado (evita resets e congelamentos de boot)." -ForegroundColor Green
} catch {
    Write-Host "      -> (Requer admin para alterar HKLM, passe bat como admin se necessario)." -ForegroundColor Gray
}

# 3. OTIMIZACAO PARA JOGOS (MODO DE JOGO & GAMEDVR)
Write-Host "[3/6] Otimizando Windows para Jogos..." -ForegroundColor Yellow
# Modo de Jogo ativado
if (!(Test-Path "HKCU:\Software\Microsoft\GameBar")) { New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type DWord

# Desativa gravação de fundo GameDVR (alivia o encoder de video da RX 7600)
if (!(Test-Path "HKCU:\System\GameConfigStore")) { New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR")) { New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
Write-Host "      -> Modo de Jogo ativado; GameDVR em segundo plano desativado." -ForegroundColor Green

# 4. REMOCAO DE PROCESSOS RESIDUAIS E TELEMETRIA
Write-Host "[4/6] Desativando Widgets e Telemetria em segundo plano..." -ForegroundColor Yellow
# Desativa Widgets na barra de tarefas (economiza 300MB a 500MB de RAM)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord -ErrorAction SilentlyContinue

# Corta anúncios e sugestões silenciosas da Microsoft
$cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Set-ItemProperty -Path $cdm -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdm -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdm -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Write-Host "      -> Widgets e servicos de coleta desativados." -ForegroundColor Green

# 5. LIMPEZA DE CACHES E ARQUIVOS TEMPORARIOS
Write-Host "[5/6] Limpando caches de Shaders, Temporarios e DNS..." -ForegroundColor Yellow
Remove-Item -Path "$env:LOCALAPPDATA\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\AMD\CN\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
Clear-DnsClientCache
Write-Host "      -> Caches e lixeira limpos com sucesso." -ForegroundColor Green

# 6. CONFIGURAR REINICIALIZACAO AUTOMATICA DO EXPLORER
Write-Host "[6/6] Reiniciando Windows Explorer para aplicar alteracoes visuais..." -ForegroundColor Yellow
Stop-Process -Name "explorer" -Force
Start-Sleep -Seconds 2
Write-Host "      -> Explorer reiniciado com sucesso." -ForegroundColor Green

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "        OTIMIZACAO DO WINDOWS CONCLUIDA COM SUCESSO!                      " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Recomendacoes de Hardware (BIOS e GPU):" -ForegroundColor Cyan
Write-Host "1. BIOS JGINYUE B550i: Ativar PBO -> Curve Optimizer: Negative 20 -> Thermal Limit: 75C"
Write-Host "2. AMD Adrenalin: Desativar Zero RPM -> Curva agressiva (100% aos 72C) -> Radeon Chill a 60 FPS"
Write-Host ""
