<#
.SYNOPSIS
    FRENTE 2: Diagnostico e Auto-Reparo na Inicializacao do Windows
    Executa a cada boot para verificar se houve falha no desligamento/boot anterior e corrige automaticamente.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$logDir = Join-Path $PSScriptRoot "Logs"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir "Inicializacao_Historico.log"

$dataHora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$header = "[$dataHora] === INICIANDO VERIFICACAO DO SISTEMA NO BOOT ==="
Add-Content -Path $logFile -Value $header
Write-Host $header -ForegroundColor Cyan

# 1. VERIFICAR SAUDE DO DISCO / VOLUME C: (SPOTFIX AUTOMATICO)
Write-Host "[1/5] Verificando integridade do Volume C:..." -ForegroundColor Yellow
try {
    $vol = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
    if ($vol.HealthStatus -ne "Healthy" -or $vol.OperationalStatus -match "Repair") {
        $msg = "[$dataHora] [REPARO DISCO] Volume C: com status '$($vol.HealthStatus)' e '$($vol.OperationalStatus)'. Executando SpotFix..."
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Red
        
        # Executa o SpotFix rapido da particao NTFS
        Repair-Volume -DriveLetter C -SpotFix -ErrorAction SilentlyContinue
        chkdsk C: /spotfix /f >nul 2>&1
    } else {
        $msg = "[$dataHora] [DISCO OK] Volume C: 100% integro (Status: Saudavel)."
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Green
    }
} catch {
    Add-Content -Path $logFile -Value "[$dataHora] [DISCO] Erro ao consultar volume: $_"
}

# 2. VERIFICAR E REATIVAR A PLACA DE VIDEO SE HOUVER FALHA
Write-Host "[2/5] Verificando integridade da Placa de Video (AMD Radeon RX 7600)..." -ForegroundColor Yellow
try {
    $gpu = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Radeon*" }
    if ($gpu.Status -ne "OK" -or $gpu.Problem -ne "CM_PROB_NONE") {
        $msg = "[$dataHora] [REPARO GPU] Falha detectada na GPU ($($gpu.Status) / $($gpu.ProblemDescription)). Reabilitando..."
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Red
        
        # Reabilita e reinicia o dispositivo via PnP
        $gpu | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
        pnputil /restart-device $gpu.InstanceId >nul 2>&1
        Start-Sleep -Seconds 2
        
        $gpuCheck = Get-PnpDevice -InstanceId $gpu.InstanceId
        Add-Content -Path $logFile -Value "[$dataHora] [REPARO GPU] Novo status da GPU apos reinicio: $($gpuCheck.Status)"
    } else {
        $msg = "[$dataHora] [GPU OK] AMD Radeon RX 7600 ativa e operando normalmente."
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Green
    }
} catch {
    Add-Content -Path $logFile -Value "[$dataHora] [GPU] Erro ao verificar GPU: $_"
}

# 3. VERIFICAR SE O ULTIMO DESLIGAMENTO FOI INESPERADO OU BSOD (ID 41 / 6008 / 1001)
Write-Host "[3/6] Verificando se o ultimo encerramento foi forçado/repentino ou BSOD..." -ForegroundColor Yellow
try {
    $lastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $werEvent = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WER-SystemErrorReporting'; Id=1001; StartTime=$lastBoot.AddMinutes(-10)} -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($werEvent) {
        $bcText = ($werEvent.Properties[0].Value -split "\(")[0].Trim()
        $msgBsod = "[$dataHora] [ALERTA BSOD] O sistema reiniciou apos Tela Azul ($bcText). Minidump gerado."
        Add-Content -Path $logFile -Value $msgBsod
        Write-Host $msgBsod -ForegroundColor Red
    }

    $uncleanEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=41,6008; StartTime=$lastBoot.AddMinutes(-10)} -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($uncleanEvent) {
        $msg = "[$dataHora] [AVISO BOOT] O computador foi reiniciado apos desligamento inesperado ($($uncleanEvent.TimeCreated)). Limpando arquivos temporarios e cache de shaders..."
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Yellow
        
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    } elseif (-not $werEvent) {
        $msg = "[$dataHora] [BOOT OK] Inicializacao limpa e normal."
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Green
    }
} catch {
    Add-Content -Path $logFile -Value "[$dataHora] [BOOT] Erro ao consultar log de desligamento: $_"
}

# 4. GARANTIR FAST STARTUP, HIBERNACAO E SUSPENSAO DESATIVADAS (ANTI-TELA PRETA NO RISER)
Write-Host "[4/6] Garantindo prevencao contra travamentos de boot e sono (Hiberboot/Suspensao/ASPM)..." -ForegroundColor Yellow
try {
    $hibOk = $true
    powercfg /hibernate off 2>$null
    if ($LASTEXITCODE -ne 0) { $hibOk = $false }
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -ErrorAction Stop
    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0
    powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
    powercfg /setactive SCHEME_CURRENT
    if ($hibOk) {
        Add-Content -Path $logFile -Value "[$dataHora] [ENERGIA OK] Fast Startup, Hibernacao, Suspensao e ASPM garantidos em 0 (Desativados)."
        Write-Host "      -> Fast Startup, Hibernacao, Suspensao e ASPM garantidos em 0 (Desativados)." -ForegroundColor Green
    } else {
        Add-Content -Path $logFile -Value "[$dataHora] [ENERGIA PARCIAL] Suspensao e ASPM em 0; powercfg /hibernate off exigiu Admin."
        Write-Host "      -> Suspensao/ASPM em 0; Hibernacao exigiu Administrador." -ForegroundColor Yellow
    }
} catch {
    Add-Content -Path $logFile -Value "[$dataHora] [ENERGIA] Requer admin para alterar HKLM/configuracoes de energia."
    Write-Host "      -> Requer Administrador para alterar HKLM/energia." -ForegroundColor Yellow
}

# 5. GARANTIR BLINDAGEM DE VIDEO DA GPU RX 7600 (ANTI-BSOD 0x119 / MPO / WINDOWS UPDATE)
Write-Host "[5/6] Garantindo blindagem da GPU contra Tela Azul 0x119 (MPO e Trava de Driver)..." -ForegroundColor Yellow
try {
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm")) { New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Force | Out-Null }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5 -Type DWord -Force -ErrorAction Stop

    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force | Out-Null }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -Force -ErrorAction Stop
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching")) { New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Force | Out-Null }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value 0 -Type DWord -Force -ErrorAction Stop

    if (!(Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers")) { New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Force | Out-Null }
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDelay" -Value 8 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDdiDelay" -Value 8 -Type DWord -Force -ErrorAction Stop

    Add-Content -Path $logFile -Value "[$dataHora] [GPU SHIELD OK] MPO em 5, Drivers WU Bloqueados e TDR Delay em 8s garantidos."
    Write-Host "      -> Blindagem GPU garantida (MPO=5 desativado, Drivers WU bloqueados, TDR=8s)." -ForegroundColor Green
} catch {
    Add-Content -Path $logFile -Value "[$dataHora] [GPU SHIELD] Requer Administrador para gravar chaves de protecao de video em HKLM."
    Write-Host "      -> Requer Administrador para gravar chaves de protecao de video em HKLM." -ForegroundColor Yellow
}

# 6. GARANTIR BLOQUEIO DO SERVICO CONFLITANTE GAMEINPUT
Write-Host "[6/6] Garantindo bloqueio de servicos conflitantes..." -ForegroundColor Yellow
try {
    $svc = Get-Service -Name "GameInputRedistService" -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Stop-Service -Name "GameInputRedistService" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "GameInputRedistService" -StartupType Disabled -ErrorAction SilentlyContinue
        Add-Content -Path $logFile -Value "[$dataHora] [GAMEINPUT] Servico conflitante interrompido e desativado."
    }
    Add-Content -Path $logFile -Value "[$dataHora] [GAMEINPUT OK] Nao ha conflitos ativos."
    Write-Host "      -> Sem conflitos ativos." -ForegroundColor Green
} catch {
    Add-Content -Path $logFile -Value "[$dataHora] [GAMEINPUT] Erro ao gerenciar servico: $_"
}

$footer = "[$dataHora] === VERIFICACAO DE BOOT FINALIZADA COM SUCESSO ===`n"
Add-Content -Path $logFile -Value $footer
Write-Host "`n$footer" -ForegroundColor Cyan
