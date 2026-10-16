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

---

## 2. Diagnóstico da Falha de Boot / Cold Boot (A Grande Descoberta)

### O Problema Histórico:
O computador frequentemente não ligava ou não dava vídeo ao ligar (*Cold Boot*). Parecia ser resolvido temporariamente ao alternar os slots de memória RAM, o que gerava a falsa suspeita de defeito na RAM ou na placa-mãe.

### A Causa Real Comprovada:
O problema **não era a memória RAM**. O módulo Wi-Fi interno M.2/PCIe estava causando instabilidade de sinal e travando a inicialização do barramento PCIe durante o POST da placa-mãe. A troca da RAM apenas forçava um reset de treinamento de memória (*memory retraining*), mascarando a causa real.

### A Solução Definitiva:
1. Remoção física do módulo Wi-Fi interno M.2.
2. Uso de adaptador Wi-Fi USB de alta velocidade.
3. Atualização da BIOS para a versão `JA500SCA`.
4. Resultado: Inicialização 100% estável e consistente.

---

## 3. Barramento PCIe e Cabo Riser (Metalfish T60)

* O gabinete Metalfish T60 utiliza um **cabo extensor (Riser) PCIe 3.0**.
* A RX 7600 opera em **PCIe 3.0 x8 (8.0 GT/s)**, compatível com o cabo riser.
* Na BIOS `JA500SCA`, a opção `PCIe/GFX Lanes Configuration` deve permanecer em **`x16`** (bifurcação padrão).
* ReBAR (Resizable BAR) e Above 4G Decoding suportados e ativados com sucesso.

---

## 4. GPU — Testes de Temperatura e Ponto Doce de Undervolt

### Comparativo de Benchmarks em Estresse (98% de Carga):

| Cenário | Configuração | Temp. GPU | Temp. Hotspot | Fan RPM | Estabilidade |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Stock (Fábrica)** | 2630 MHz / ~1200 mV / Fan Auto | 72 °C | **101 °C** (Delta 29°C!) | 2.117 RPM | Perigoso para SFF |
| **Agressivo Instável**| 2600 MHz / 1050 mV / Fan Manual | 55 °C | 71 °C | 2.500 RPM | **Instável:** Artefatos/pipocos visuais |
| **Ponto Doce (Ideal)**| **2550 MHz / 1100 mV / Fan Manual** | **59 °C** | **77 °C** (Delta 18°C) | **2.503 RPM** | **100% Estável e Frio** |

### Configuração Recomendada no AMD Software Adrenalin:
* **Frequência Máxima:** `2550 MHz`
* **Tensão Máxima:** `1100 mV`
* **Power Limit:** `0%`
* **Zero RPM:** `DESATIVADO` (evita aquecimento passivo em repouso no SFF)
* **Curva de Ventoinha:**
  * 45°C -> 45%
  * 55°C -> 65%
  * 65°C -> 85%
  * 70°C+ -> 100%
* **Radeon Chill:** Ativado (60 FPS Min / 60 FPS Max para sincronizar com monitor de 60Hz).

---

## 5. CPU — Diagnóstico Térmico e Soluções (Ryzen 5 5600)

* **Comportamento em Teste:** Em estresse com CPU-Z consumindo ~45W, a CPU atingiu **80°C a 83°C mesmo com a tampa do gabinete aberta**.
* **Diagnóstico:** O aquecimento ocorre pela capacidade do cooler low-profile ou contato térmico direto.
* **Curva de Ventoinha da CPU recomendada na BIOS (Hardware Monitor):**
  * `35°C` -> PWM **`120`** (~47%)
  * `45°C` -> PWM **`170`** (~67%)
  * `55°C` -> PWM **`220`** (~86%)
  * `65°C` -> PWM **`255`** (**100% de rotação aos 65°C**)
* **Precision Boost Overdrive (PBO):**
  * Curve Optimizer: `All Cores` -> `Negative` -> Magnitude **`10`** (ou **`15`** / **`20`** se estável).
  * PPT Limit: `65 W`
  * Platform Thermal Throttle Limit: `75 °C` (Garante que a CPU nunca passe de 75°C sob carga pesada).
* **Revisão Física:** Se continuar passando de 80°C, verificar fixação do cooler, conferir ausência de película plástica protetora e aplicar pasta térmica de alto desempenho.

---

## 6. Saúde do SSD (XrayDisk 1TB SATA)

Diagnóstico oficial realizado em outubro/2026:
* **Status:** `Healthy (Saudável)`
* **Temperatura:** `41 °C`
* **Horas de Uso:** `6.544 horas`
* **Erros de Leitura / Setores Defeituosos:** `0 erros`
* **Comando TRIM:** `Ativo (DisableDeleteNotify = 0)`

---

## 7. Recomendações de Fans de Gabinete para o Metalfish T60

* Instalação de **2x fans de 120x25mm no topo** configurados como **EXAUSTÃO** (puxando o ar quente de dentro do gabinete e jogando para fora).
* **Melhores modelos recomendados:**
  1. **Arctic P12 Pro / P12 Max:** Alta pressão estática, excelente fluxo para grades perfuradas de SFF.
  2. **Noctua NF-F12 industrialPPC-3000:** Força bruta de refrigeração para quem não se importa com ruído.
