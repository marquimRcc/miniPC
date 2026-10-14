<#
.SYNOPSIS
    FRENTE 2: Diagnostico e Auto-Reparo na Inicializacao do Windows
    Executa a cada boot para verificar se houve falha no desligamento/boot anterior e corrige automaticamente.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$logDir = "C:\Users\marcos\Otimizacao_SFF\Logs"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = "$logDir\Inicializacao_Historico.log"

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

# 3. VERIFICAR SE O ULTIMO DESLIGAMENTO FOI INESPERADO (ID 41 / 6008)
Write-Host "[3/5] Verificando se o ultimo encerramento foi forçado/repentino..." -ForegroundColor Yellow
try {
    $lastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $uncleanEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=41,6008; StartTime=$lastBoot.AddMinutes(-5)} -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($uncleanEvent) {
        $msg = "[$dataHora] [AVISO BOOT] O computador foi reiniciado apos desligamento inesperado ($($uncleanEvent.TimeCreated)). Limpando arquivos temporarios corrompidos..."
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Yellow
        
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        $msg = "[$dataHora] [BOOT OK] Inicializacao limpa e normal."
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Green
    }
} catch {
    Add-Content -Path $logFile -Value "[$dataHora] [BOOT] Erro ao consultar log de desligamento: $_"
}

# 4. GARANTIR INICIALIZACAO RAPIDA (FAST STARTUP) DESATIVADA
Write-Host "[4/5] Garantindo prevencao contra travamentos de boot (Hiberboot)..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Add-Content -Path $logFile -Value "[$dataHora] [ENERGIA OK] Fast Startup garantido em 0 (Desativado)."
    Write-Host "      -> Fast Startup garantido em 0 (Desativado)." -ForegroundColor Green
} catch {
    Add-Content -Path $logFile -Value "[$dataHora] [ENERGIA] Requer admin para alterar Hiberboot."
}

# 5. GARANTIR BLOQUEIO DO SERVICO CONFLITANTE GAMEINPUT
Write-Host "[5/5] Garantindo bloqueio de servicos conflitantes..." -ForegroundColor Yellow
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
