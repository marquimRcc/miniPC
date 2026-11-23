<#
.SYNOPSIS
    FRENTE 1: Script de Validacao das Automacoes e Otimizacoes SFF (Baixa Temperatura)
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not $env:MINIPC_CHAIN) { Clear-Host }

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "     PAINEL DE VALIDACAO DAS OTIMIZACOES SFF (BAIXA TEMPERATURA)          " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Validar Plano de Energia
$scheme = (powercfg /getactivescheme)
$isBalanced = $scheme -like "*381b4222-f694-41f0-9685-ff5bb260df2e*" -or $scheme -like "*Equilibrado*"
if ($isBalanced) {
    Write-Host "  [OK] Plano de Energia: EQUILIBRADO (Permite que o Ryzen 5600 esfrie em repouso)" -ForegroundColor Green
} else {
    Write-Host "  [ALERTA] Plano de Energia: NAO EQUILIBRADO ($scheme)" -ForegroundColor Yellow
}

# 2. Validar Status da Placa de Video (GPU)
$gpu = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Radeon RX 7600*" }
if ($gpu -and $gpu.Status -eq "OK") {
    Write-Host "  [OK] GPU AMD Radeon RX 7600: OPERANDO NORMALMENTE (Status OK, 3D Ativo)" -ForegroundColor Green
} else {
    Write-Host "  [ERRO] GPU AMD Radeon RX 7600: COM FALHA OU DESATIVADA ($($gpu.Status) / $($gpu.ProblemDescription))" -ForegroundColor Red
}

# 3. Validar Game Mode e GameDVR
$gameMode = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -ErrorAction SilentlyContinue).AutoGameModeEnabled
$gameDvr = (Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue).GameDVR_Enabled

if ($gameMode -eq 1) {
    Write-Host "  [OK] Modo de Jogo do Windows: ATIVADO (Prioridade maxima para jogos)" -ForegroundColor Green
} else {
    Write-Host "  [ALERTA] Modo de Jogo do Windows: DESATIVADO" -ForegroundColor Yellow
}

if ($gameDvr -eq 0) {
    Write-Host "  [OK] Gravacao GameDVR em segundo plano: DESATIVADA (Zero overhead na GPU)" -ForegroundColor Green
} else {
    Write-Host "  [ALERTA] Gravacao GameDVR: ATIVA (Consumindo encoder de video)" -ForegroundColor Yellow
}

# 4. Validar Conflito do GameInput
$gameInputRedist = Get-Service -Name "GameInputRedistService" -ErrorAction SilentlyContinue
if (!$gameInputRedist -or $gameInputRedist.Status -eq "Stopped" -or $gameInputRedist.StartType -eq "Disabled") {
    Write-Host "  [OK] Conflito Microsoft GameInput: ELIMINADO (Servico legado desativado e parado)" -ForegroundColor Green
} else {
    Write-Host "  [ERRO] Conflito Microsoft GameInput: SERVICO REDUNDANTE AINDA ATIVO" -ForegroundColor Red
}

# 5. Validar Inicializacao Rapida (Fast Startup / Hiberboot) e Hibernacao
$hiber = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue).HiberbootEnabled
if ($hiber -eq 0) {
    Write-Host "  [OK] Inicializacao Rapida (Fast Startup): DESATIVADA (Sem congelamentos de boot)" -ForegroundColor Green
} else {
    Write-Host "  [ALERTA] Inicializacao Rapida: ATIVA ($hiber)" -ForegroundColor Yellow
}

$hibEnabled = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -ErrorAction SilentlyContinue).HibernateEnabled
if ($hibEnabled -eq 0) {
    Write-Host "  [OK] Hibernacao do Windows: DESATIVADA" -ForegroundColor Green
} else {
    Write-Host "  [ALERTA] Hibernacao do Windows: ATIVA (Execute EXECUTAR_TUDO.bat como Administrador)" -ForegroundColor Yellow
}

# 6. Validar Link PCIe da GPU (Riser Gen3)
if ($gpu) {
    $linkSpeed = (Get-PnpDeviceProperty -InstanceId $gpu.InstanceId -KeyName "DEVPKEY_PciDevice_CurrentLinkSpeed" -ErrorAction SilentlyContinue).Data
    if ($linkSpeed -eq 3) {
        Write-Host "  [OK] Barramento PCIe da GPU: Gen3 (Ideal para o cabo Riser)" -ForegroundColor Green
    } elseif ($linkSpeed) {
        Write-Host "  [ALERTA] Barramento PCIe da GPU em Gen$linkSpeed (Verifique na BIOS: Advanced > PCI Subsystem > Gen3)" -ForegroundColor Yellow
    }
}

# 7. Validar Blindagem de Video da GPU (Anti-BSOD 0x119, MPO e Windows Update)
$mpo = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -ErrorAction SilentlyContinue).OverlayTestMode
$wuDrivers = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue).ExcludeWUDriversInQualityUpdate
$tdr = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDelay" -ErrorAction SilentlyContinue).TdrDelay

if ($mpo -eq 5) {
    Write-Host "  [OK] MPO (Multi-Plane Overlay): DESATIVADO (Prevenção ativa contra BSOD 0x119 / travamento de tela)" -ForegroundColor Green
} else {
    Write-Host "  [ALERTA] MPO: ATIVO (Risco de congelamentos e BSOD 0x119 na RX 7600 em navegadores)" -ForegroundColor Yellow
}

if ($wuDrivers -eq 1) {
    Write-Host "  [OK] Windows Update: BLOQUEADO PARA DRIVERS (Preserva o AMD Adrenalin oficial limpo)" -ForegroundColor Green
} else {
    Write-Host "  [ALERTA] Windows Update: PODE SOBRESCREVER DRIVERS (Risco de corromper o driver da AMD)" -ForegroundColor Yellow
}

if ($tdr -eq 8) {
    Write-Host "  [OK] GPU TDR Delay: 8 SEGUNDOS (Margem estendida contra falsos timeouts graficos)" -ForegroundColor Green
} else {
    Write-Host "  [INFO] GPU TDR Delay: PADRAO DO WINDOWS (2s)" -ForegroundColor Gray
}

# 8. Validar Widgets da Barra de Tarefas
$widgets = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -ErrorAction SilentlyContinue).TaskbarDa
$widgetsPolicy = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue).AllowNewsAndInterests
if ($widgets -eq 0 -or $widgetsPolicy -eq 0) {
    Write-Host "  [OK] Widgets da Barra de Tarefas: DESATIVADOS (Economia de RAM)" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Widgets da Barra de Tarefas: ATIVOS" -ForegroundColor Gray
}

# 9. Memoria RAM e Armazenamento
$os = Get-CimInstance Win32_OperatingSystem
$freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$usedRamGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
Write-Host "  [INFO] Memoria RAM: $freeRamGB GB Livres / $totalRamGB GB Total (Em uso: $usedRamGB GB)" -ForegroundColor Cyan

# Status dos Volumes e Unidades de Disco
$volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }
foreach ($v in $volumes) {
    $freeGB = [math]::Round($v.SizeRemaining / 1GB, 1)
    $totalGB = [math]::Round($v.Size / 1GB, 1)
    Write-Host "  [INFO] Volume $($v.DriveLetter): ($($v.FileSystemLabel)) - $freeGB GB Livres / $totalGB GB Total (Status: $($v.HealthStatus))" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "             VALIDACAO CONCLUIDA COM SUCESSO!                             " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""
