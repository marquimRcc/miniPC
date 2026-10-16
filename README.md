# 🚀 miniPC - Guia de Otimização SFF & Reparação Automática

Repositório dedicado à suíte de scripts, diagnósticos e parametrizações de BIOS/GPU para gabinetes compactos (*Small Form Factor* / Mini-ITX) com fluxo de ar restrito.

> 📖 **[Clique aqui para ler o Relatório Técnico Consolidado de Hardware (Metalfish T60)](ANALISE_TECNICA_HARDWARE.md)** com todo o histórico de testes, diagnósticos de boot, memória, riser PCIe 3.0 e benchmarks térmicos.

**Foco primordial:** **Baixíssimas temperaturas**, prevenção contra quedas de tensão/desarmes térmicos da fonte e estabilidade de inicialização do Windows 11.

---

## 🖥️ 1. Perfil do Hardware (Metalfish T60)

| Componente | Modelo / Especificação | Desafio Térmico em Gabinete Compacto (SFF) |
| :--- | :--- | :--- |
| **Gabinete** | Metalfish T60 (Mini-ITX / SFF) | Volume interno reduzido; exige exaustão forte no topo. |
| **Processador** | AMD Ryzen 5 5600 (6 Cores / 12 Threads) | Em stock atinge 88W e 1.35V+, aquecendo rapidamente sem fluxo direto de ar. |
| **Placa de Vídeo** | AMD Radeon RX 7600 8GB | Arquitetura RDNA 3 com consumo de 165W-185W; gera calor concentrado no chassis. |
| **Placa-Mãe** | JGINYUE B550i-GAMING (Mini-ITX) | Formato compacto com dissipação reduzida de VRM; BIOS JA500SCA. |
| **Armazenamento**| SSD XrayDisk 1TB SATA | 100% Saudável (41°C, TRIM ativo, zero setores defeituosos). |
| **Memória** | 16 GB DDR4 Corsair (DDR4-3200) | Operando em Single Channel (estabilidade de boot). |
| **Monitor** | 1920x1080 @ 60 Hz | Taxa máxima de exibição de 60 FPS (quadros acima geram puro calor inútil). |

---

## ❄️ 2. Ajustes de BIOS Recomendados (AMD Ryzen 5 5600)

Configurações a serem aplicadas na BIOS da placa-mãe (**JGINYUE B550i-GAMING**):

1. Ligue o PC e pressione `DEL` repetidamente para acessar o menu da BIOS.
2. Navegue até **Advanced** / **AMD Overclocking** -> **Precision Boost Overdrive (PBO)**.
3. Configure:
   * **Precision Boost Overdrive:** `Advanced`
   * **PBO Limits:** `Manual`
     * **PPT (Package Power Tracking):** `65 W` *(padrão de fábrica é 88W; reduz calor drástico)*
     * **TDC (Thermal Design Current):** `45 A`
     * **EDC (Electrical Design Current):** `65 A`
   * **Curve Optimizer:**
     * **Curve Optimizer:** `All Cores`
     * **All Core Curve Optimizer Sign:** `Negative`
     * **All Core Curve Optimizer Magnitude:** `20` *(ou `25` se 100% estável)*
   * **Platform Thermal Throttle Limit:** `75` *(Garante que a CPU nunca ultrapassará 75°C sob carga extrema)*.
4. Pressione `F10` para salvar e reiniciar.

---

## 🌪️ 3. Ajustes de GPU Recomendados (AMD Software: Adrenalin)

Abra o **AMD Software** -> Aba **Desempenho** -> **Ajuste** -> Selecione **Personalizado**:

1. **Ajuste da GPU (Frequência e Tensão):**
   * **Tensão Máxima (mV):** Definir em **`1100 mV`** *(Testado em bancada: 1050mV gerou artefatos/pipocos visuais; 1100mV é o ponto ideal 100% estável)*.
   * **Frequência Máxima (MHz):** Limitar em **`2550 MHz`** *(evita clocks excessivos e reduz hotspot em mais de 24°C)*.

2. **Ajuste da Ventoinha (Curva Agressiva - Foco em Temperatura Baixa):**
   * **Zero RPM:** **DESATIVAR** *(evita calor passivo acumulado no gabinete Metalfish T60)*.
   * **Pontos da Curva de Velocidade dos Fans:**
     * `45°C` -> **45%**
     * `55°C` -> **65%**
     * `65°C` -> **85%**
     * `70°C+` -> **100%** *(mantém Hotspot abaixo de 78°C sob estresse máximo)*.

3. **Ajuste de Energia:**
   * **Limite de Energia (%):** Manter em **`0%`** ou **`-5%`**.

4. **Radeon Chill (Sincronizado com Monitor 60Hz):**
   * Em **Jogos** -> **Gráficos**, ative o **Radeon Chill**:
     * **FPS Mínimo:** `60`
     * **FPS Máximo:** `60` (ou `75` com folga de frametime)
     * *Resultado:* Economia imediata de 20°C a 30°C em jogos sem perda visual.

---

## 🌪️ 3.1 Curva de Ventoinha da CPU (Hardware Monitor na BIOS)

Para manter o Ryzen 5 5600 frio no gabinete Metalfish T60:
* **Temperatura 1:** `35°C` -> PWM **`120`** (~47%)
* **Temperatura 2:** `45°C` -> PWM **`170`** (~67%)
* **Temperatura 3:** `55°C` -> PWM **`220`** (~86%)
* **Temperatura 4:** `65°C` -> PWM **`255`** (**100%** de rotação já aos 65°C)

---

## 🛠️ 4. Estrutura dos Scripts Disponíveis

### 1. `Otimizar_Pos_Formatacao.bat` / `.ps1`
Executado após instalar ou formatar o Windows. Aplica automaticamente:
* **Plano de Energia Equilibrado Otimizado:** Permite à CPU descer para 5% de clock e voltagem mínima em repouso.
* **Desativação da Inicialização Rápida (Fast Startup):** Previne corrupção de drivers de GPU e perda de undervolt ao religar.
* **Ativação do Modo de Jogo e Desativação do GameDVR:** Reduz latência e elimina uso do encoder da placa de vídeo em segundo plano.
* **Limpeza e Otimização:** Desativação de widgets, telemetria pesada e limpeza de cache de shaders/DNS.

### 2. `Validar_Otimizacoes_SFF.bat` / `.ps1`
Executa uma bateria de testes diagnósticos no sistema verificando:
* Estado do driver de GPU (AMD RX 7600)
* Resolução e taxa de atualização (1080p@60Hz)
* Status do Fast Startup
* Status do Plano de Energia e estados mínimos do processador
* Serviços de conflito (ex: GameInput legacy)
* Integridade dos arquivos de sistema

### 3. `Verificar_Reparar_Inicializacao.bat` / `.ps1`
Script utilitário configurável na inicialização (`shell:startup`) ou agendado:
* Analisa logs de eventos do Windows (Kernel-Power, NTFS, BugCheck).
* Dispara reparos silenciosos caso falhas sejam detectadas.
* Mantém histórico detalhado na pasta `Logs/Inicializacao_Historico.log`.

---

## 📊 5. Tabela Comparativa de Resultados

| Métrica | Configuração Padrão (Stock) | Perfil SFF Otimizado |
| :--- | :--- | :--- |
| **Temp. CPU em Repouso (Idle)** | 55°C - 60°C | **40°C - 45°C** |
| **Temp. CPU em Jogos Pesados** | 80°C - 88°C | **65°C - 74°C** |
| **Temp. GPU Hotspot** | 85°C - 95°C | **70°C - 78°C** |
| **Consumo Total Médio em Jogos** | ~260W | **~175W - 185W** |
| **Estabilidade Operacional** | Risco de desligamento por pico térmico/potência | **100% Estável e Frio** |

---

## 📥 Como Usar Após Formatação (Passo a Passo de 1 Clique)

Quando você formatar e reinstalar o Windows 11:

1. **Baixe ou clone o repositório:**
   ```cmd
   git clone https://github.com/marquimRcc/miniPC.git
   ```
   *(Ou simplesmente baixe o ZIP no GitHub e descompacte em qualquer pasta).*
2. **Execute o Script Mestre:**
   - Clique com o botão direito em **`Otimizar_Pos_Formatacao.bat`** e selecione **"Executar como Administrador"**.
   - O script configurará automaticamente:
     - Plano de energia com 5% de clock mínimo para o Ryzen 5600 esfriar em repouso.
     - Bloqueio definitivo da Inicialização Rápida (*Fast Startup*).
     - Ativação do Modo de Jogo e corte do GameDVR.
     - Desativação do serviço redundante conflitante GameInput.
     - Registro automático de **`Verificar_Reparar_Inicializacao.bat`** na inicialização do Windows (`shell:startup`).
     - Limpeza de shaders e caches.
3. **Validação:**
   - Dê dois cliques em **`Validar_Otimizacoes_SFF.bat`** para confirmar que os 6 testes retornaram `[OK]`.

