<#
.SYNOPSIS
    Instalador Automatico e Silencioso de Aplicativos - miniPC
    Hardware: AMD Ryzen 5 5600 + AMD Radeon RX 7600 (Metalfish T60)
#>

[Console]::OutputEncoding = [System.Text.Encoding]::ASCII
Clear-Host

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "    INSTALADOR AUTOMATICO DE PROGRAMAS - SILENCIOSO (WINGET)              " -ForegroundColor Cyan
Write-Host "    miniPC Metalfish T60 | Windows 11                                     " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se o Winget esta disponivel
$wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetCheck) {
    Write-Host "[ERRO CRITICO] O gerenciador de pacotes Winget nao foi encontrado no sistema!" -ForegroundColor Red
    Write-Host "Instale o Instalador de Aplicativos da Microsoft Store e tente novamente." -ForegroundColor Yellow
    pause
    exit 1
}

# Lista estruturada dos programas essenciais do usuario
$apps = @(
    [PSCustomObject]@{ Categoria = "Navegador"; Nome = "Brave Browser"; Id = "Brave.Brave" },
    [PSCustomObject]@{ Categoria = "Comunicacao"; Nome = "Telegram Desktop"; Id = "Telegram.TelegramDesktop" },
    [PSCustomObject]@{ Categoria = "Inteligencia Artificial"; Nome = "ChatGPT Desktop"; Id = "OpenAI.ChatGPT" },
    [PSCustomObject]@{ Categoria = "Jogos"; Nome = "Steam"; Id = "Valve.Steam" },
    [PSCustomObject]@{ Categoria = "Jogos"; Nome = "Minecraft Launcher"; Id = "Mojang.MinecraftLauncher" },
    [PSCustomObject]@{ Categoria = "Multimidia"; Nome = "VLC Media Player"; Id = "VideoLAN.VLC" },
    [PSCustomObject]@{ Categoria = "Desenvolvimento"; Nome = "Git para Windows"; Id = "Git.Git" },
    [PSCustomObject]@{ Categoria = "Desenvolvimento"; Nome = "Python 3.11"; Id = "Python.Python.3.11" },
    [PSCustomObject]@{ Categoria = "Editores"; Nome = "Notepad++"; Id = "Notepad++.Notepad++" },
    [PSCustomObject]@{ Categoria = "Utilitarios"; Nome = "7-Zip"; Id = "7zip.7zip" },
    [PSCustomObject]@{ Categoria = "Terminal"; Nome = "Windows Terminal"; Id = "Microsoft.WindowsTerminal" },
    [PSCustomObject]@{ Categoria = "IA / Dev"; Nome = "Google Antigravity"; Id = "Google.Antigravity" }
)

$total = $apps.Count
$instalados = 0
$jaExistentes = 0
$falhas = 0
$contador = 0

$startTime = Get-Date

Write-Host "Iniciando verificacao e instalacao de $total programas..." -ForegroundColor White
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

foreach ($app in $apps) {
    $contador++
    $pct = [Math]::Round(($contador / $total) * 100)
    $barraProgresso = "[" + ("=" * [Math]::Round($pct / 5)) + (" " * (20 - [Math]::Round($pct / 5))) + "]"

    Write-Host ""
    Write-Host "[$contador/$total] $barraProgresso $pct% | Categoria: $($app.Categoria)" -ForegroundColor DarkCyan
    Write-Host "Programa: $($app.Nome) (ID: $($app.Id))" -ForegroundColor White

    # 1. Checagem previa: Verificar se o programa ja esta instalado
    $checkList = winget list --id $app.Id --exact 2>&1
    $isInstalled = ($LASTEXITCODE -eq 0 -and ($checkList -match [regex]::Escape($app.Id)))

    if ($isInstalled) {
        Write-Host "  -> [JA INSTALADO] O aplicativo ja esta presente no sistema. Pulando..." -ForegroundColor Yellow
        $jaExistentes++
    } else {
        Write-Host "  -> [INSTALANDO] Baixando e instalando silenciosamente via Winget..." -ForegroundColor Cyan
        
        # Execucao silenciosa com aceitacao automatica de licencas e fontes
        $installOutput = winget install --id $app.Id --exact --silent --accept-package-agreements --accept-source-agreements 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Host "  -> [SUCESSO] $($app.Nome) instalado com sucesso!" -ForegroundColor Green
            $instalados++
        } else {
            # Codigo 0x8A15002B = Pacote ja instalado ou atualizado
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

$elapsed = (Get-Date) - $startTime
$tempoFormatado = "{0:D2}m {1:D2}s" -f $elapsed.Minutes, $elapsed.Seconds

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "    RESUMO DA INSTALACAO AUTOMATICA                                       " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "  Total de Programas Analisados: $total" -ForegroundColor White
Write-Host "  Programas Instalados Agora:   $instalados" -ForegroundColor Green
Write-Host "  Programas Ja Existentes:      $jaExistentes" -ForegroundColor Yellow
Write-Host "  Falhas / Nao Instalados:      $falhas" -ForegroundColor $(if ($falhas -eq 0) { "Green" } else { "Red" })
Write-Host "  Tempo Total de Execucao:      $tempoFormatado" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
