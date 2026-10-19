# 📋 Relatório Técnico Consolidado — Mini PC ITX (Metalfish T60)

> **Documento de Referência de Hardware, Benchmarks e Diagnóstico**  
> **Gabinete:** Metalfish T60 (Mini-ITX / Small Form Factor)  
> **Hardware:** AMD Ryzen 5 5600 | AMD Radeon RX 7600 8GB | JGINYUE B550I-GAMING | 16GB DDR4 | XrayDisk 1TB SSD  

---

## 1. Hardware Confirmado

* **Gabinete:** Metalfish T60 (SFF / Mini-ITX compacto com circulação restrita de ar).
* **Fonte:** Metalfish 600W (Linha +12V: 50A) — Potência suficiente para a combinação Ryzen 5600 + RX 7600.
* **Placa-Mãe:** JGINYUE B550I-GAMING (Chipset AMD B550, Socket AM4, PCIe 4.0).
  * **BIOS Atual:** American Megatrends v5.17 | ID: `JA500SCA` | Data: 12/06/2026 | AGESA: `ComboAM4v2PI 1.2.0.F`.
* **Processador:** AMD Ryzen 5 5600 (6 Cores / 12 Threads, TDP 65W, Zen 3 Vermeer).
  * Sem vídeo integrado (sem iGPU) — Toda imagem depende 100% da placa dedicada.
* **Placa de Vídeo:** AMD Radeon RX 7600 8GB (Navi 33, 8GB GDDR6 Samsung, Barramento 128-bit, PCIe 4.0 x8 nativo).
* **Armazenamento:** SSD XrayDisk 1TB SATA (Saúde 100% Healthy, 41°C, TRIM ativo, zero erros).
* **Rede:** Realtek 2.5 GbE onboard | Módulo Wi-Fi interno M.2/PCIe **REMOVIDO** | Wi-Fi via adaptador USB externo.
* **Monitor:** Samsung C24F390 Curvo (1080p @ 60 Hz, suporte a AMD FreeSync).

---

## 2. Diagnóstico da Falha de Cold Boot e Telas Pretas (Causas Raízes)

### Causa 1: Conflito PCIe Gen4 vs Cabo Riser Gen3 (A Descoberta de Baixo Nível)
Ao inspecionar diretamente as propriedades de hardware do barramento PCIe no Windows, foi descoberto:
* **Velocidade Negociada:** `DEVPKEY_PciDevice_CurrentLinkSpeed : 4` (**PCIe Gen 4 — 16.0 GT/s**)
* **Erros de Integridade de Pacote:** `DEVPKEY_PciDevice_ECRC_Errors : 160`

**Mecanismo da Falha:**
1. A placa B550i e a RX 7600 suportam PCIe Gen4. O cabo extensor (Riser do Metalfish T60) é **PCIe Gen 3.0**.
2. Em modo "Auto", a placa-mãe tenta treinar o barramento em 16 GHz no cold boot.
3. O cabo riser Gen3 não tem blindagem para 16 GHz com o PC frio, gerando estouro de tempo no link training durante o POST.
4. **Resultado:** A placa de vídeo **não consegue inicializar o sinal de vídeo e o monitor fica 100% preto** (sem nem exibir a logo da BIOS).
5. **Solução Definitiva:** Como a BIOS `JA500SCA` não possui a opção manual de travar em Gen3, a fabricante JGINYUE disponibiliza a versão oficial de BIOS **`(GEN3)`** travada nativamente em PCIe 3.0 para usuários de gabinetes ITX com riser.

### Causa 2: Inicialização Rápida (Fast Startup / Hiberboot) do Windows
* O Fast Startup do Windows salva um estado híbrido da memória e do subsistema PCIe no desligamento.
* Ao religar o PC, a GPU tentava acordar rápido demais pelo riser, travando o sinal de vídeo.
* **Solução:** Desativação permanente e prioritária da Inicialização Rápida e da Hibernação (`powercfg /hibernate off` e `HiberbootEnabled = 0`).

### Causa 3: Módulo Wi-Fi Interno M.2
* O módulo Wi-Fi interno causava conflitos no barramento PCIe da placa-mãe.
* **Solução:** Módulo removido fisicamente; Wi-Fi agora opera via adaptador USB.

---

## 3. Prioridade Máxima Pós-Formatação: Desativação de Hibernação

> [!CRITICAL]
> **ESTE É O PRIMEIRO COMANDO OBRIGATÓRIO A SER EXECUTADO EM QUALQUER INSTALAÇÃO DO WINDOWS:**

```cmd
powercfg /hibernate off
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f
```
Sem isso, o sistema continuará gerando telas pretas ao ligar devido à incompatibilidade do riser com a suspensão híbrida do kernel.

---

## 4. GPU — Calibração Consolidada no AMD Adrenalin (RX 7600)

Perfil 100% testado, estável e livre de artefatos visuais:
* **Frequência Máxima:** `2450 MHz` (ou `2550 MHz`)
* **Tensão Máxima:** `1100 mV` *(Testado em bancada: 1050mV gerou artefatos/pipocos visuais; 1100mV é o ponto ideal 100% estável)*.
* **Power Limit:** `-6%` (limite máximo permitido pela VBIOS)
* **Zero RPM:** `DESATIVADO` (ventoinhas girando continuamente para evitar calor passivo)
* **Curva de Ventoinha Hiper-Agressiva:**
  * 30°C -> 50%
  * 43°C -> 70%
  * 53°C -> 85%
  * 64°C -> 95%
  * 80°C -> 100%
* **Radeon Chill:** Ativado (60 FPS Min / 60 FPS Max para sincronizar com o monitor Samsung 60Hz).
* **Resultado:** Hotspot caiu de **101°C para ~75°C** e temperatura da GPU fica entre **45°C e 52°C** em jogos leves.

---

## 5. CPU — Calibração Consolidada (Ryzen 5 5600)

* **Trava Térmica no Windows:** Clock base travado em **3.5 GHz** com boost desativado (`be337238-0d82-4146-a960-4f3749d470c7 = 0`).
  * Tensão cai para **~0.93V** e consumo em idle para apenas **1.5W** (temperatura de repouso em **~40°C**).
* **Trava de Hardware (Ryzen Master):** **Eco Mode** ativado (limita o PPT da CPU de 76W para **45W**).
* **Curva da Ventoinha da CPU (Smart Fan na BIOS):**
  * 35°C -> PWM 150 (~60%)
  * 45°C -> PWM 190 (~75%)
  * 55°C -> PWM 230 (~90%)
  * 60°C -> PWM 255 (**100% de rotação máxima aos 60°C**)

---

## 6. Saúde do SSD (XrayDisk 1TB SATA)

* **Status:** `Healthy (Saudável)`
* **Temperatura:** `41 °C`
* **Erros de Leitura / Setores Defeituosos:** `0 erros` nos logs do sistema
* **Comando TRIM:** `Ativo (DisableDeleteNotify = 0)`
