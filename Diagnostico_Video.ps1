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
