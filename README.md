# 🚀 miniPC - Guia de Otimização SFF & Reparação Automática

Repositório dedicado à suíte de scripts, diagnósticos e parametrizações de BIOS/GPU para gabinetes compactos (*Small Form Factor* / Mini-ITX) com fluxo de ar restrito.

> 📖 **[Clique aqui para ler o Relatório Técnico Consolidado de Hardware (Metalfish T60)](ANALISE_TECNICA_HARDWARE.md)** com todo o histórico de testes, diagnósticos de boot, memória, riser PCIe 3.0 e benchmarks térmicos.

**Foco primordial:** **Eliminação definitiva de telas pretas no boot**, **baixíssimas temperaturas**, prevenção contra quedas de tensão e estabilidade máxima do Windows 11.

---

## ⚡ 0. Início Rápido Pós-Formatação (1 Comando / 1 UAC)

Logo após instalar o Windows, abra o **Terminal (Admin)** (`Win + X` → *Terminal (Administrador)*) e cole **apenas esta linha** para baixar o repositório e executar todas as etapas em sequência automática com **1 único UAC**:

```powershell
$d="$env:USERPROFILE\miniPC"; irm "https://github.com/marquimRcc/miniPC/archive/refs/heads/main.zip" -OutFile "$env:TEMP\m.zip"; Expand-Archive "$env:TEMP\m.zip" "$env:TEMP\m" -Force; New-Item -ItemType Directory -Force $d | Out-Null; Copy-Item "$env:TEMP\m\miniPC-main\*" $d -Recurse -Force; Remove-Item "$env:TEMP\m.zip","$env:TEMP\m" -Recurse -Force; & "$d\EXECUTAR_TUDO.bat"
```

Se a pasta `miniPC` já estiver no computador, basta dar duplo clique em **`EXECUTAR_TUDO.bat`** (que executa otimizações, instalador de programas/drivers AMD, auto-reparo, validação e diagnóstico de vídeo em sequência, salvando tudo em `Logs\Setup_Completo.log`).

---

## 🖥️ 1. Perfil do Hardware (Metalfish T60)

| Componente | Modelo / Especificação | Desafio Térmico em Gabinete Compacto (SFF) |
| :--- | :--- | :--- |
| **Gabinete** | Metalfish T60 (Mini-ITX / SFF) | Cabo extensor (Riser) PCIe 3.0; volume interno reduzido. |
| **Processador** | AMD Ryzen 5 5600 (6 Cores / 12 Threads) | Em stock atinge 88W e 1.35V+, aquecendo rapidamente sem fluxo direto de ar. |
| **Placa de Vídeo** | AMD Radeon RX 7600 8GB | Arquitetura RDNA 3 com consumo de 165W-185W; gera calor concentrado no chassis. |
| **Placa-Mãe** | JGINYUE B550i-GAMING (Mini-ITX) | Formato compacto; BIOS atualizada para **`JA500SAM (GEN3)`** (AGESA 1.2.0.F). |
| **Armazenamento**| SSD XrayDisk 1TB SATA | 100% Saudável (41°C, TRIM ativo, zero setores defeituosos). |
| **Memória** | 16 GB DDR4 Corsair (DDR4-3200) | Operando em Single Channel a 2133 MHz (estabilidade de boot). |
| **Monitor** | 1920x1080 @ 60 Hz | Taxa máxima de exibição de 60 FPS (quadros acima geram puro calor inútil). |

---

## 🔥 2. PRIORIDADE Nº 1 ABSOLUTA PÓS-FORMATAÇÃO: ANTI-TELA PRETA NO RISER

> [!CRITICAL]
> **ESTES SÃO OS PRIMEIROS COMANDOS OBRIGATÓRIOS A SEREM EXECUTADOS ASSIM QUE O WINDOWS FOR INSTALADO:**

```cmd
:: 1. Desativa Hibernacao e Inicializacao Rapida (Fast Startup)
powercfg /hibernate off
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f

:: 2. Desativa Suspensao Automatica (evita travamento ao tentar acordar GPU no Riser)
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0

:: 3. Desativa Economia de Energia do Barramento PCIe (ASPM)
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
powercfg /setactive SCHEME_CURRENT
```

### Por que esses comandos são prioritários?
1. O cabo extensor (Riser) do Metalfish T60 é **PCIe 3.0**, enquanto a placa-mãe e a RX 7600 suportam **PCIe 4.0**.
2. A Inicialização Rápida (*Fast Startup*) e a Suspensão Automática (*Sleep/Standby S3*) tentam reestabelecer o link PCIe a frio, causando falha de comunicação (*link training timeout / LiveKernelEvent 1b0*) no riser.
3. Isso causa a temida **TELA PRETA (o PC liga, as ventoinhas giram, mas não dá vídeo nem mostra o logo da BIOS, ou congela ao acordar)**.
4. Desativando a hibernação, a suspensão e o ASPM, o Windows é forçado a realizar um **boot UEFI 100% limpo e estável todas as vezes**, eliminando essa falha.

---

## ⚡ 2.1. Instalação dos Drivers Oficiais AMD (Pós-Formatação)

Como os utilitários da AMD contêm pacotes pesados de kernel e interface gráfica de calibração, siga esta ordem logo após rodar o script mestre:

1. **AMD Software: Adrenalin Edition (Driver da RX 7600):**  
   * Baixe pelo [Site Oficial AMD Drivers](https://www.amd.com/pt/support/download/drivers.html) ou use o instalador salvo no pendrive.
   * Selecione a opção **Instalação Completa (Full Install)** para ter acesso à aba de Ajuste/Tuning.
   * Em seguida, **importe o perfil `Curva_Fria_RX7600.xml`** (instruções na Seção 4).
2. **AMD Ryzen Master (Controle Térmico da CPU):**  
   * Baixe pelo [Site Oficial do Ryzen Master](https://www.amd.com/pt/products/software/ryzen-master.html).
   * Ative o **Eco Mode** (45W PPT) ou configure o *Curve Optimizer* em All Cores Negative -25 para derrubar a temperatura da CPU.

---

## ❄️ 3. Ajustes de BIOS Recomendados (JGINYUE B550i-GAMING GEN3)

1. Ligue o PC e pressione `DEL` repetidamente para acessar o menu da BIOS.
2. **Pressione `F9`** (*Load Optimized Defaults*) e tecle `Enter` para carregar as definições de fábrica da BIOS GEN3.
3. **PCI Subsystem Settings (Aba Advanced):**
   * **Above 4G Decoding:** `Enabled`
   * **Re-Size BAR Support:** `Enabled` *(Ativa o AMD Smart Access Memory de 8GB)*
   * **CSM Support:** `Disabled` *(Garante boot puro UEFI)*
4. **Velocidade PCIe:** Se houver a opção de velocidade do slot PCIe, travar em **`Gen3`**.
5. **Curva de Ventoinha da CPU (Hardware Monitor na BIOS):**
   * `35°C` -> PWM **`150`** (~60%)
   * `45°C` -> PWM **`190`** (~75%)
   * `55°C` -> PWM **`230`** (~90%)
   * `60°C` -> PWM **`255`** (**100% de rotação máxima já aos 60°C**)
4. Pressione `F10` para salvar e reiniciar.

---

## 🌪️ 4. Ajustes de GPU Recomendados (AMD Software: Adrenalin)

> [!TIP]
> **Importação Automática em 1 Clique com o Perfil Pronto:**  
> Este repositório inclui o arquivo oficial pronto **[`Curva_Fria_RX7600.xml`](Curva_Fria_RX7600.xml)**.  
> Para aplicar tudo de uma vez sem precisar configurar nada manualmente:
> 1. Abra o **AMD Software: Adrenalin Edition**.
> 2. Vá na aba **Desempenho** ➔ **Ajuste**.
> 3. No canto superior direito, clique no botão **Importar perfil** (ícone de seta/pasta).
> 4. Selecione o arquivo `Curva_Fria_RX7600.xml`.
> 5. **Resultado:** Curva de ventoinha agressiva, limite de energia em -6% e clock controlado são aplicados imediatamente, derrubando a temperatura da GPU em até **10°C**!

Caso prefira ajustar manualmente, abra o **AMD Software** -> Aba **Desempenho** -> **Ajuste** -> Selecione **Personalizado**:

1. **Ajuste da GPU (Frequência e Tensão):**
   * **Tensão Máxima (mV):** Definir em **`1100 mV`** *(Testado em bancada: 1050mV gerou artefatos/pipocos visuais; 1100mV é o ponto ideal 100% estável)*.
   * **Frequência Máxima (MHz):** Limitar em **`2450 MHz`** (ou `2550 MHz`) *(evita clocks excessivos e reduz hotspot em mais de 25°C)*.

2. **Ajuste da Ventoinha (Curva Agressiva - Foco em Temperatura Baixa):**
   * **Zero RPM:** **DESATIVAR** *(evita calor passivo acumulado no gabinete Metalfish T60)*.
   * **Pontos da Curva de Velocidade dos Fans:**
     * `30°C` -> **50%**
     * `43°C` -> **70%**
     * `53°C` -> **85%**
     * `64°C` -> **95%**
     * `80°C` -> **100%** *(mantém Hotspot abaixo de 75°C sob estresse máximo)*.

3. **Ajuste de Energia:**
   * **Limite de Energia (%):** Definir em **`-6%`** *(máximo permitido pela VBIOS)*.

4. **Radeon Chill (Sincronizado com Monitor 60Hz):**
   * Em **Jogos** -> **Gráficos**, ative o **Radeon Chill**:
     * **FPS Mínimo:** `60`
     * **FPS Máximo:** `60` (ou `70`)
     * *Resultado:* Economia imediata de 20°C a 30°C em jogos sem perda visual.

---

## 🛠️ 5. Estrutura dos Scripts Disponíveis

### 0. `EXECUTAR_TUDO.bat` *(Orquestrador Único Recomendado)*
Ponto de entrada único pós-formatação com auto-elevação (1 UAC no início). Executa em sequência automática, sem pausas intermediárias, registrando tudo em `Logs\Setup_Completo.log`:
1. `Otimizar_Pos_Formatacao.ps1`
2. `Instalar_Programas_Automatico.ps1`
3. `Verificar_Reparar_Inicializacao.ps1`
4. `Validar_Otimizacoes_SFF.ps1`
5. `Diagnostico_Video.ps1`

### 1. `1_CLIQUE_AQUI_POS_FORMATACAO.bat` (ou `Otimizar_Pos_Formatacao.bat`)
Executado após instalar ou formatar o Windows (possui auto-elevação para Administrador). Aplica automaticamente com 1 clique:
* **[Etapa 1] Desativação Prioritária de Hibernação, Fast Startup e Suspensão Automática** (`powercfg /hibernate off`, `HiberbootEnabled = 0`, `standby-timeout = 0` e `ASPM = 0`).
* **[Etapa 2] Trava Térmica da CPU em 3.5 GHz:** Desativa o boost agressivo, fixa o estado máximo em 99% e mínimo em 5% (tensão cai para ~0.93V e consumo para 1.5W em repouso).
* **[Etapa 3] Ativação do Modo de Jogo e Desativação do GameDVR:** Reduz latência e elimina uso do encoder da placa de vídeo em segundo plano.
* **[Etapa 4] Limpeza e Otimização:** Desativação de widgets, telemetria pesada e limpeza de cache de shaders/DNS.
* **[Etapa 5] Comando TRIM no SSD SATA.**

### 2. `Instalar_Programas_Automatico.bat` / `.ps1`
Instalador automático e 100% silencioso para pós-formatação. Instala todos os softwares essenciais via Winget e baixa/instala automaticamente os drivers e utilitários oficiais da AMD:
* **Drivers & Utilitários AMD (Automático):** 
  * **AMD Software: Adrenalin Edition** (Driver de vídeo oficial da RX 7600)
  * **AMD Ryzen Master** (Gerenciador oficial para Eco Mode / Curve Optimizer da CPU)
* **Navegadores & IA:** Brave Browser, Mozilla Firefox, ChatGPT Desktop, Telegram Desktop.
* **Jogos:** Steam, Ubisoft Connect, Minecraft Launcher.
* **Mídia & Downloads:** VLC Media Player, Stremio, qBittorrent.
* **Desenvolvimento:** Git para Windows, Python 3.11, Notepad++, 7-Zip, Windows Terminal, Google Antigravity.
* *Recurso inteligente:* Verifica se o aplicativo já existe antes de baixar, pulando itens já presentes e exibindo resumo final.

### 3. `Verificar_Reparar_Inicializacao.bat` / `.ps1`
Executa uma bateria de testes diagnósticos no sistema verificando integridade do volume C: (SpotFix), status da RX 7600, garantia de Fast Startup em 0 e logs de encerramento inesperado.
