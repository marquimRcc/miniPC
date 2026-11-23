$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== 1. DISPOSITIVOS DE VIDEO (PnP) ==="
Get-PnpDevice -Class Display | Format-Table -AutoSize FriendlyName, Status, Problem, ConfigManagerErrorCode, InstanceId

Write-Host "`n=== 2. CONTROLADORES DE VIDEO (Win32_VideoController) ==="
Get-CimInstance Win32_VideoController | Format-List Name, Status, DriverVersion, VideoModeDescription, CurrentRefreshRate, VideoProcessor, PNPDeviceID

Write-Host "`n=== 3. MONITORES DETECTADOS (WmiMonitorID / WmiMonitorConnectionParams) ==="
$monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue
if ($monitors) {
    foreach ($m in $monitors) {
        $name = [System.Text.Encoding]::ASCII.GetString(($m.UserFriendlyName | Where-Object { $_ -ne 0 }))
        $serial = [System.Text.Encoding]::ASCII.GetString(($m.SerialNumberID | Where-Object { $_ -ne 0 }))
        Write-Host "Monitor Detectado: Nome='$name', Serial='$serial', Instance=$($m.InstanceName)"
    }
} else {
    Write-Host "AVISO: Nenhum monitor fisico ativo/conectado detectado pelo WMI!" -ForegroundColor Yellow
}

$connParams = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorConnectionParams -ErrorAction SilentlyContinue
if ($connParams) {
    foreach ($cp in $connParams) {
        Write-Host "Conexao de Video: Tipo=$($cp.VideoOutputTechnology), Ativo=$($cp.Active), Instance=$($cp.InstanceName)"
    }
}

Write-Host "`n=== 4. STATUS DO SERVICO ANYDESK E SESSOES DE USUARIO ==="
Get-Service -Name "*AnyDesk*" | Format-Table -AutoSize Name, Status, StartType
quser 2>&1

Write-Host "`n=== 5. EVENTOS RECENTES DE DISPLAY / DWM / GPU (Ultimas 2 horas) ==="
$cutoff = (Get-Date).AddHours(-2)
Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=$cutoff} -ErrorAction SilentlyContinue | 
    Where-Object { $_.ProviderName -match 'Display|amdkmdag|BasicDisplay|nvlddmkm|igfx' } | 
    Select-Object -First 10 TimeCreated, ProviderName, Id, LevelDisplayName, Message | Format-Table -Wrap

Write-Host "`n=== 6. VERIFICACAO DE DWM (Desktop Window Manager) ==="
Get-Process -Name dwm -ErrorAction SilentlyContinue | Format-Table -AutoSize Id, ProcessName, WorkingSet64, Responding

Write-Host "`n=== 7. BLINDAGEM DE VIDEO E REGISTRO (MPO, WU DRIVERS, TDR) ==="
$mpoVal = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -ErrorAction SilentlyContinue).OverlayTestMode
$wuVal  = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue).ExcludeWUDriversInQualityUpdate
$tdrVal = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDelay" -ErrorAction SilentlyContinue).TdrDelay
Write-Host "MPO OverlayTestMode : $(if ($mpoVal -eq 5) { '5 (DESATIVADO - OK)' } else { "$mpoVal (ATIVO - ALERTA)" })"
Write-Host "WU ExcludeDrivers   : $(if ($wuVal -eq 1) { '1 (BLOQUEADO - OK)' } else { "$wuVal (PERMITIDO - ALERTA)" })"
Write-Host "Graphics TdrDelay   : $(if ($tdrVal) { "$tdrVal segundos" } else { "Padrao (2 segundos)" })"

Write-Host "`n=== 8. HISTORICO DE TELAS AZUIS / CRASHES DE VIDEO (Ultimos 5 dias) ==="
$werEvents = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WER-SystemErrorReporting'; StartTime=(Get-Date).AddDays(-5)} -ErrorAction SilentlyContinue
if ($werEvents) {
    foreach ($we in $werEvents) {
        $p1 = $we.Properties[0].Value
        Write-Host "[$($we.TimeCreated)] BSOD Detectado: $p1" -ForegroundColor $(if ($p1 -match "0x00000119") { "Red" } else { "Yellow" })
    }
} else {
    Write-Host "Nenhum evento de tela azul (Bugcheck 1001) registrado nos ultimos 5 dias." -ForegroundColor Green
}
