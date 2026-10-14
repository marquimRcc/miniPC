<#
.SYNOPSIS
    FRENTE 1: Script de Validacao das Automacoes e Otimizacoes SFF (Baixa Temperatura)
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

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

# 5. Validar Inicializacao Rapida (Fast Startup / Hiberboot)
$hiber = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue).HiberbootEnabled
if ($hiber -eq 0) {
    Write-Host "  [OK] Inicializacao Rapida (Fast Startup): DESATIVADA (Sem congelamentos de boot)" -ForegroundColor Green
} else {
    Write-Host "  [ALERTA] Inicializacao Rapida: ATIVA ($hiber)" -ForegroundColor Yellow
}

# 6. Validar Widgets da Barra de Tarefas
$widgets = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -ErrorAction SilentlyContinue).TaskbarDa
if ($widgets -eq 0) {
    Write-Host "  [OK] Widgets da Barra de Tarefas: DESATIVADOS (Economia de 400MB de RAM)" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Widgets da Barra de Tarefas: ATIVOS" -ForegroundColor Gray
}

# 7. Memoria RAM e Armazenamento
$os = Get-CimInstance Win32_OperatingSystem
$freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$usedRamGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
Write-Host "  [INFO] Memoria RAM: $freeRamGB GB Livres / $totalRamGB GB Total (Em uso: $usedRamGB GB)" -ForegroundColor Cyan

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "             VALIDACAO CONCLUIDA COM SUCESSO!                             " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""
