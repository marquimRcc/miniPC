<#
.SYNOPSIS
    Instalador Automatico e Silencioso de Aplicativos e Drivers AMD - miniPC
    Hardware: AMD Ryzen 5 5600 + AMD Radeon RX 7600 (Metalfish T60)
#>

[Console]::OutputEncoding = [System.Text.Encoding]::ASCII
if (-not $env:MINIPC_CHAIN) { Clear-Host }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "    INSTALADOR AUTOMATICO DE PROGRAMAS & DRIVERS AMD                      " -ForegroundColor Cyan
Write-Host "    miniPC Metalfish T60 | Windows 11                                     " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
if (-not $isAdmin) {
    Write-Host "[AVISO] Executando sem Administrador; instaladores de sistema podem falhar." -ForegroundColor Yellow
}
Write-Host ""

# Verificar se o Winget esta disponivel
$wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetCheck) {
    Write-Host "[ERRO CRITICO] O gerenciador de pacotes Winget nao foi encontrado no sistema!" -ForegroundColor Red
    Write-Host "Instale o Instalador de Aplicativos da Microsoft Store e tente novamente." -ForegroundColor Yellow
    pause
    exit 1
}

# Funcao para verificar presenca no registro de instalacao do Windows
function Test-ProgramInstalled($pattern) {
    $keys = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $found = Get-ItemProperty $keys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $pattern }
    return ($null -ne $found)
}

# Lista estruturada dos programas essenciais via Winget
$apps = @(
    [PSCustomObject]@{ Categoria = "Navegador"; Nome = "Brave Browser"; Id = "Brave.Brave" },
    [PSCustomObject]@{ Categoria = "Navegador"; Nome = "Mozilla Firefox"; Id = "Mozilla.Firefox" },
    [PSCustomObject]@{ Categoria = "Comunicacao"; Nome = "Telegram Desktop"; Id = "Telegram.TelegramDesktop" },
    [PSCustomObject]@{ Categoria = "Inteligencia Artificial"; Nome = "ChatGPT Desktop"; Id = "OpenAI.ChatGPT" },
    [PSCustomObject]@{ Categoria = "Jogos"; Nome = "Steam"; Id = "Valve.Steam" },
    [PSCustomObject]@{ Categoria = "Jogos"; Nome = "Ubisoft Connect"; Id = "Ubisoft.Connect" },
    [PSCustomObject]@{ Categoria = "Jogos"; Nome = "Minecraft Launcher"; Id = "Mojang.MinecraftLauncher" },
    [PSCustomObject]@{ Categoria = "Multimidia"; Nome = "VLC Media Player"; Id = "VideoLAN.VLC" },
    [PSCustomObject]@{ Categoria = "Multimidia"; Nome = "Stremio"; Id = "Stremio.Stremio" },
    [PSCustomObject]@{ Categoria = "Downloads"; Nome = "qBittorrent"; Id = "qBittorrent.qBittorrent" },
    [PSCustomObject]@{ Categoria = "Desenvolvimento"; Nome = "Git para Windows"; Id = "Git.Git" },
    [PSCustomObject]@{ Categoria = "Desenvolvimento"; Nome = "Python 3.11"; Id = "Python.Python.3.11" },
    [PSCustomObject]@{ Categoria = "Editores"; Nome = "Notepad++"; Id = "Notepad++.Notepad++" },
    [PSCustomObject]@{ Categoria = "Utilitarios"; Nome = "7-Zip"; Id = "7zip.7zip" },
    [PSCustomObject]@{ Categoria = "Terminal"; Nome = "Windows Terminal"; Id = "Microsoft.WindowsTerminal" },
    [PSCustomObject]@{ Categoria = "IA / Dev"; Nome = "Google Antigravity"; Id = "Google.Antigravity" }
)

# 16 programas Winget + 2 utilitarios oficiais AMD
$total = $apps.Count + 2
$instalados = 0
$jaExistentes = 0
$falhas = 0
$contador = 0

$startTime = Get-Date

Write-Host "Iniciando verificacao e instalacao de $total componentes (Softwares & Drivers AMD)..." -ForegroundColor White
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

# =========================================================================
# FASE 1: INSTALACAO AUTOMATICA DOS SOFTWARES VIA WINGET
# =========================================================================
foreach ($app in $apps) {
    $contador++
    $pct = [Math]::Round(($contador / $total) * 100)
    $barraProgresso = "[" + ("=" * [Math]::Round($pct / 5)) + (" " * (20 - [Math]::Round($pct / 5))) + "]"

    Write-Host ""
    Write-Host "[$contador/$total] $barraProgresso $pct% | Categoria: $($app.Categoria)" -ForegroundColor DarkCyan
    Write-Host "Programa: $($app.Nome) (ID: $($app.Id))" -ForegroundColor White

    # Checagem previa: Verificar se o programa ja esta instalado (compat. com pacotes normais e portateis)
    $checkList = winget list --id $app.Id --exact --accept-source-agreements 2>&1
    $idPattern = "(?<!\S)$([regex]::Escape($app.Id))(?!\S)"
    $isInstalled = ($LASTEXITCODE -eq 0 -and ($checkList -match $idPattern))
    if (-not $isInstalled) {
        $checkFallback = winget list $app.Id --accept-source-agreements 2>&1
        $isInstalled = ($LASTEXITCODE -eq 0 -and ($checkFallback -match $idPattern))
    }

    if ($isInstalled) {
        Write-Host "  -> [JA INSTALADO] O aplicativo ja esta presente no sistema. Pulando..." -ForegroundColor Yellow
        $jaExistentes++
    } else {
        Write-Host "  -> [INSTALANDO] Baixando e instalando silenciosamente via Winget..." -ForegroundColor Cyan
        
        $installOutput = winget install --id $app.Id --exact --silent --accept-package-agreements --accept-source-agreements 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Host "  -> [SUCESSO] $($app.Nome) instalado com sucesso!" -ForegroundColor Green
            $instalados++
        } else {
            if ($installOutput -match "ja instalado" -or $installOutput -match "already installed") {
                Write-Host "  -> [JA INSTALADO] Detectado como ja instalado pela instalacao." -ForegroundColor Yellow
                $jaExistentes++
            } else {
                Write-Host "  -> [AVISO] Falha ao instalar $($app.Nome) (Codigo: $exitCode)." -ForegroundColor Red
                $falhas++
            }
        }
    }
}

# =========================================================================
# FASE 2: DRIVER DE VIDEO AMD SOFTWARE ADRENALIN (GPU RX 7600)
# =========================================================================
$contador++
$pct = [Math]::Round(($contador / $total) * 100)
$barraProgresso = "[" + ("=" * [Math]::Round($pct / 5)) + (" " * (20 - [Math]::Round($pct / 5))) + "]"

Write-Host ""
Write-Host "[$contador/$total] $barraProgresso $pct% | Categoria: Driver Grafico AMD" -ForegroundColor DarkCyan
Write-Host "Componente: AMD Software: Adrenalin Edition (Radeon RX 7600)" -ForegroundColor White

if (Test-ProgramInstalled "AMD Software") {
    Write-Host "  -> [JA INSTALADO] AMD Software: Adrenalin ja instalado no sistema. Pulando..." -ForegroundColor Yellow
    $jaExistentes++
} else {
    Write-Host "  -> [DOWNLOAD] Localizando e baixando instalador oficial AMD..." -ForegroundColor Cyan
    try {
        # Obter o link mais recente direto da pagina de suporte da AMD
        $headers = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }
        $page = Invoke-WebRequest -Uri "https://www.amd.com/pt/support/download/drivers.html" -Headers $headers -UseBasicParsing
        $match = [regex]::Match($page.Content, 'href="(https://drivers\.amd\.com/drivers/installer/[^"]+\.exe)"')
        
        $adrenalinUrl = if ($match.Success) { $match.Groups[1].Value } else { "https://drivers.amd.com/drivers/installer/26.20/beta/amd-software-adrenalin-edition-26.10.2-minimalsetup-261029_web.exe" }
        $adrenalinDest = "$env:TEMP\AMD_Software_Adrenalin_Setup.exe"

        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.Headers.Add("Referer", "https://www.amd.com/pt/support/download/drivers.html")
        $wc.DownloadFile($adrenalinUrl, $adrenalinDest)

        Write-Host "  -> [INSTALANDO] Executando instalacao do driver de video AMD..." -ForegroundColor Cyan
        # Executa o instalador da AMD
        $proc = Start-Process -FilePath $adrenalinDest -ArgumentList "-INSTALL" -PassThru -Wait
        
        Remove-Item $adrenalinDest -Force -ErrorAction SilentlyContinue
        if ($proc.ExitCode -in @(0, 3010) -or (Test-ProgramInstalled "AMD Software")) {
            Write-Host "  -> [SUCESSO] AMD Software: Adrenalin instalado com sucesso! (Codigo: $($proc.ExitCode))" -ForegroundColor Green
            $instalados++
        } else {
            Write-Host "  -> [AVISO] Instalador AMD Adrenalin retornou codigo $($proc.ExitCode)." -ForegroundColor Red
            $falhas++
        }
    } catch {
        Write-Host "  -> [AVISO] Falha ao baixar/instalar AMD Software automaticamente: $_" -ForegroundColor Red
        $falhas++
    }
}

# =========================================================================
# FASE 3: AMD RYZEN MASTER (CPU RYZEN 5 5600 - ECO MODE)
# =========================================================================
$contador++
$pct = [Math]::Round(($contador / $total) * 100)
$barraProgresso = "[" + ("=" * [Math]::Round($pct / 5)) + (" " * (20 - [Math]::Round($pct / 5))) + "]"

Write-Host ""
Write-Host "[$contador/$total] $barraProgresso $pct% | Categoria: Software Processador AMD" -ForegroundColor DarkCyan
Write-Host "Componente: AMD Ryzen Master (Ryzen 5 5600 - Eco Mode / Curve Optimizer)" -ForegroundColor White

if (Test-ProgramInstalled "AMD Ryzen Master") {
    Write-Host "  -> [JA INSTALADO] AMD Ryzen Master ja instalado no sistema. Pulando..." -ForegroundColor Yellow
    $jaExistentes++
} else {
    Write-Host "  -> [DOWNLOAD] Localizando e baixando AMD Ryzen Master oficial..." -ForegroundColor Cyan
    try {
        $headers = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }
        $rmPage = Invoke-WebRequest -Uri "https://www.amd.com/pt/products/software/ryzen-master.html" -Headers $headers -UseBasicParsing
        $rmMatch = [regex]::Match($rmPage.Content, 'href="(https://drivers\.amd\.com/drivers/amd_ryzen_master_[^"]+\.exe)"')
        
        $rmUrl = if ($rmMatch.Success) { $rmMatch.Groups[1].Value } else { "https://drivers.amd.com/drivers/amd_ryzen_master_3.1.2.5621.exe" }
        $rmDest = "$env:TEMP\AMD_Ryzen_Master_Setup.exe"

        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.Headers.Add("Referer", "https://www.amd.com/pt/products/software/ryzen-master.html")
        $wc.DownloadFile($rmUrl, $rmDest)

        Write-Host "  -> [INSTALANDO] Executando instalacao do AMD Ryzen Master..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath $rmDest -ArgumentList '/s /v"/qn /norestart"' -PassThru -Wait
        
        Remove-Item $rmDest -Force -ErrorAction SilentlyContinue
        if ($proc.ExitCode -in @(0, 3010) -or (Test-ProgramInstalled "AMD Ryzen Master")) {
            Write-Host "  -> [SUCESSO] AMD Ryzen Master instalado com sucesso! (Codigo: $($proc.ExitCode))" -ForegroundColor Green
            $instalados++
        } else {
            Write-Host "  -> [AVISO] Instalador AMD Ryzen Master retornou codigo $($proc.ExitCode)." -ForegroundColor Red
            $falhas++
        }
    } catch {
        Write-Host "  -> [AVISO] Falha ao baixar/instalar AMD Ryzen Master automaticamente: $_" -ForegroundColor Red
        $falhas++
    }
}

$elapsed = (Get-Date) - $startTime
$tempoFormatado = "{0:D2}m {1:D2}s" -f $elapsed.Minutes, $elapsed.Seconds

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "    RESUMO DA INSTALACAO AUTOMATICA                                       " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "  Total de Itens Analisados:    $total" -ForegroundColor White
Write-Host "  Itens Instalados Agora:       $instalados" -ForegroundColor Green
Write-Host "  Itens Ja Existentes:          $jaExistentes" -ForegroundColor Yellow
Write-Host "  Falhas / Nao Instalados:      $falhas" -ForegroundColor $(if ($falhas -eq 0) { "Green" } else { "Red" })
Write-Host "  Tempo Total de Execucao:      $tempoFormatado" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "[DICA] Apos a instalacao do AMD Adrenalin, importe o arquivo 'Curva_Fria_RX7600.xml'" -ForegroundColor Cyan
Write-Host "       (Aba Desempenho > Ajuste > Importar Perfil) para baixar a GPU em ate 10C!" -ForegroundColor Cyan
Write-Host ""
