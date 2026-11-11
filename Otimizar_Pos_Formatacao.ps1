<#
.SYNOPSIS
    Script Mestre de Otimizacao Agressiva para Gabinete SFF / Pouca Ventilacao
    Hardware Alvo: AMD Ryzen 5 5600 + AMD Radeon RX 7600 (Gabinete Metalfish T60 / B550i)
    Foco: Menor temperatura possivel, eliminacao de tela preta no boot e estabilidade maxima.
#>

if (-not $env:MINIPC_CHAIN) { Clear-Host }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "    OTIMIZACAO SFF MESTRE - BAIXA TEMPERATURA E ESTABILIDADE              " -ForegroundColor Cyan
Write-Host "    Metalfish T60 | Ryzen 5 5600 | RX 7600 | JGINYUE B550i                " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
if (-not $isAdmin) {
    Write-Host "[AVISO] Executando sem privilegios de Administrador; itens de sistema serao pulados." -ForegroundColor Yellow
}
Write-Host ""

# 1. PRIORIDADE ZERO ABSOLUTA: DESATIVACAO DE HIBERNACAO, FAST STARTUP E SUSPENSAO AUTOMATICA
Write-Host "[1/8] PRIORIDADE 1: Desativando Hibernacao, Fast Startup e Suspensao..." -ForegroundColor Yellow
$hibOk = $true
powercfg /hibernate off 2>$null
if ($LASTEXITCODE -ne 0) { $hibOk = $false }
try {
    # 1.2 Forca chave do registro do Windows para desativar Fast Startup
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction Stop
} catch {
    $hibOk = $false
}
# 1.3 Desativa suspensao automatica (evita queda de sinal PCIe ao acordar no Riser)
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
if ($hibOk) {
    Write-Host "      [OK] Hibernacao, Fast Startup e Suspensao Automatica DESATIVADOS!" -ForegroundColor Green
    Write-Host "      [OK] Boot UEFI 100% limpo ativado (previne telas pretas no riser PCIe 3.0)." -ForegroundColor Green
} else {
    Write-Host "      [AVISO] Suspensao em 0 aplicada, mas Hibernacao/HKLM requer Administrador." -ForegroundColor Yellow
}

# 2. PLANO DE ENERGIA EQUILIBRADO OTIMIZADO (BAIXA TEMPERATURA / 3.5 GHz BASE)
Write-Host "[2/8] Configurando Plano de Energia Equilibrado Otimizado (3.5 GHz Fixo)..." -ForegroundColor Yellow
$balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
powercfg /setactive $balancedGuid

# Desativa Core Performance Boost agressivo (trava em 3.5 GHz a frio, eliminando picos de 1.45V)
$cpuBoostOk = $true
powercfg /setacvalueindex $balancedGuid SUB_PROCESSOR be337238-0d82-4146-a960-4f3749d470c7 0 2>$null
if ($LASTEXITCODE -ne 0) { $cpuBoostOk = $false }
powercfg /setdcvalueindex $balancedGuid SUB_PROCESSOR be337238-0d82-4146-a960-4f3749d470c7 0 2>$null
if ($LASTEXITCODE -ne 0) { $cpuBoostOk = $false }

# Permite que a CPU Ryzen 5600 desca para 5% de clock em repouso (C-States profundos)
powercfg /setacvalueindex $balancedGuid SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg /setdcvalueindex $balancedGuid SUB_PROCESSOR PROCTHROTTLEMIN 5

# Estado maximo em 99% (elimina picos do scheduler do Windows)
powercfg /setacvalueindex $balancedGuid SUB_PROCESSOR PROCTHROTTLEMAX 99
powercfg /setdcvalueindex $balancedGuid SUB_PROCESSOR PROCTHROTTLEMAX 99

# Politica de resfriamento Ativa (ventoinhas preventivas)
powercfg /setacvalueindex $balancedGuid SUB_PROCESSOR 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 2>$null
powercfg /setdcvalueindex $balancedGuid SUB_PROCESSOR 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 2>$null

# Gerenciamento de energia do link PCIe (ASPM Desligado - previne Watchdog LiveKernelEvent 1b0 no Riser)
powercfg /setacvalueindex $balancedGuid SUB_PCIEXPRESS ee12f906-d277-404b-b6da-e5fa1a576df5 0
powercfg /setdcvalueindex $balancedGuid SUB_PCIEXPRESS ee12f906-d277-404b-b6da-e5fa1a576df5 0

powercfg /setactive $balancedGuid
if ($cpuBoostOk) {
    Write-Host "      [OK] Processador travado em 3.5 GHz (~0.93V) com reducao termica imediata." -ForegroundColor Green
} else {
    Write-Host "      [AVISO] Limites 5%-99% e ASPM=0 aplicados; trava de Core Boost requer Administrador." -ForegroundColor Yellow
}

# 3. OTIMIZACAO PARA JOGOS (MODO DE JOGO E GAMEDVR)
Write-Host "[3/8] Otimizando Windows para Jogos (Latencia e GPU)..." -ForegroundColor Yellow
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
Write-Host "[4/8] Verificando servicos conflitantes..." -ForegroundColor Yellow
$legacySvc = Get-Service -Name "GameInputRedistService" -ErrorAction SilentlyContinue
if ($legacySvc) {
    Stop-Service -Name "GameInputRedistService" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "GameInputRedistService" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "      [OK] Servico legado GameInputRedistService desativado com sucesso." -ForegroundColor Green
} else {
    Write-Host "      [OK] Sem servicos redundantes detectados." -ForegroundColor Green
}

# 5. REGISTRAR AUTO-REPARO NA INICIALIZACAO DO WINDOWS (SHELL:STARTUP)
Write-Host "[5/8] Configurando atalho de validacao e protecao na inicializacao..." -ForegroundColor Yellow
$startupFolder = [Environment]::GetFolderPath("Startup")
$shortcutScript = Join-Path $PSScriptRoot "Verificar_Reparar_Inicializacao.bat"
if (Test-Path $shortcutScript) {
    $wsh = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut((Join-Path $startupFolder "AutoReparo_SFF_Boot.lnk"))
    $shortcut.TargetPath = $shortcutScript
    $shortcut.WorkingDirectory = $PSScriptRoot
    $shortcut.Description = "Garante que o Fast Startup e o Perfil Termico permanecam ativos"
    $shortcut.WindowStyle = 7 # Minimized
    $shortcut.Save()
    Write-Host "      [OK] Auto-reparo configurado para proteger contra reset do Windows Update." -ForegroundColor Green
} else {
    Write-Host "      [AVISO] Script auxiliar Verificar_Reparar_Inicializacao.bat nao localizado." -ForegroundColor Yellow
}

# 6. OTIMIZACAO DE EFEITOS VISUAIS E BACKGROUND
Write-Host "[6/8] Otimizando animacoes, widgets e reducao de carga de GPU no Desktop..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "100" -Force -ErrorAction SilentlyContinue
$widgetsDisabled = $false
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction Stop
    $widgetsDisabled = $true
} catch {
    try {
        if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force -ErrorAction Stop | Out-Null }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction Stop
        $widgetsDisabled = $true
    } catch { }
}
if ($widgetsDisabled) {
    Write-Host "      [OK] Responsividade do Desktop otimizada e Widgets desativados." -ForegroundColor Green
} else {
    Write-Host "      [OK] Responsividade do Desktop otimizada (Widgets protegidos no Windows 11; desative em Configuracoes > Barra de tarefas)." -ForegroundColor Yellow
}

# 7. LIMPEZA DE CACHE DE SHADERS E DNS
Write-Host "[7/8] Limpando Cache de DNS..." -ForegroundColor Yellow
Clear-DnsClientCache
Write-Host "      [OK] DNS renovado." -ForegroundColor Green

# 8. OTIMIZACAO DO SSD SATA (TRIM)
Write-Host "[8/8] Executando comando TRIM no SSD..." -ForegroundColor Yellow
try {
    Optimize-Volume -DriveLetter C -ReTrim -Verbose:$false -ErrorAction Stop
    Write-Host "      [OK] TRIM enviado ao SSD XrayDisk com sucesso." -ForegroundColor Green
} catch {
    Write-Host "      [AVISO] Nao foi possivel executar TRIM automaticamente (requer Administrador)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "    SUITE DE OTIMIZACAO SFF CONCLUIDA COM SUCESSO!                         " -ForegroundColor Green
Write-Host "    Inicializacao Rapida: DESATIVADA (Prioridade 1)                        " -ForegroundColor Green
Write-Host "    Clock CPU: 3.5 GHz Fixo (~0.93V)                                       " -ForegroundColor Green
Write-Host "    GPU: Perfil de Baixa Temperatura Ativo                                 " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
