# 🚀 miniPC - Guia de Otimização SFF & Reparação Automática

Repositório dedicado à suíte de scripts, diagnósticos e parametrizações de BIOS/GPU para gabinetes compactos (*Small Form Factor* / Mini-ITX) com fluxo de ar restrito.

> 📖 **[Clique aqui para ler o Relatório Técnico Consolidado de Hardware (Metalfish T60)](ANALISE_TECNICA_HARDWARE.md)** com todo o histórico de testes, diagnósticos de boot, memória, riser PCIe 3.0 e benchmarks térmicos.

**Foco primordial:** **Eliminação definitiva de telas pretas no boot**, **baixíssimas temperaturas**, prevenção contra quedas de tensão e estabilidade máxima do Windows 11.

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

Abra o **AMD Software** -> Aba **Desempenho** -> **Ajuste** -> Selecione **Personalizado**:

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

### 1. `Otimizar_Pos_Formatacao.bat` / `.ps1`
Executado após instalar ou formatar o Windows (já possui auto-elevação para Administrador). Aplica automaticamente:
* **[Etapa 1] Desativação Prioritária de Hibernação e Fast Startup** (`powercfg /hibernate off` e `HiberbootEnabled = 0`).
* **[Etapa 2] Trava Térmica da CPU em 3.5 GHz:** Desativa o boost agressivo, fixa o estado máximo em 99% e mínimo em 5% (tensão cai para ~0.93V e consumo para 1.5W em repouso).
* **[Etapa 3] Ativação do Modo de Jogo e Desativação do GameDVR:** Reduz latência e elimina uso do encoder da placa de vídeo em segundo plano.
* **[Etapa 4] Limpeza e Otimização:** Desativação de widgets, telemetria pesada e limpeza de cache de shaders/DNS.
* **[Etapa 5] Comando TRIM no SSD SATA.**

### 2. `Verificar_Reparar_Inicializacao.bat` / `.ps1`
Executa uma bateria de testes diagnósticos no sistema verificando integridade do volume C: (SpotFix), status da RX 7600, garantia de Fast Startup em 0 e logs de encerramento inesperado.
