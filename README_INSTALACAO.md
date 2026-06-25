# Meta Moto — Guia de Instalação Completo

App financeiro para motoboys com: rastreamento de km via GPS, detecção automática de corridas, overlay flutuante, alertas de eficiência e manutenção preventiva.

---

## Pré-requisitos

| Ferramenta | Versão mínima | Download |
|---|---|---|
| Flutter SDK | 3.19+ (stable) | https://flutter.dev/docs/get-started/install |
| Android Studio | 2023.1+ | https://developer.android.com/studio |
| Java JDK | 17+ | Incluso no Android Studio |
| Android SDK | API 23+ (Android 6.0+) | Via Android Studio |

---

## Instalação Passo a Passo

### 1. Instalar o Flutter SDK

```bash
# Linux/macOS — clone o Flutter estável
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Windows — baixe o zip em https://flutter.dev e adicione ao PATH

# Verifique se está tudo ok:
flutter doctor
# Todos os itens devem estar ✓ (exceto Chrome/Web, que não é necessário)
```

### 2. Instalar dependências do projeto

```bash
cd meta_moto_flutter/
flutter pub get
```

### 3. Conectar dispositivo Android físico (recomendado)

> ⚠️ GPS, overlay e leitor de notificações funcionam **somente** em dispositivo físico.

1. **Configurações → Sobre o telefone → Número de build** — toque 7x
2. **Configurações → Opções do desenvolvedor → Depuração USB** → Ativar
3. Conecte via USB e aceite a permissão no celular

```bash
flutter devices     # deve listar seu celular
flutter run         # instala e executa o app
```

### 4. Build de APK (para distribuição)

```bash
flutter build apk --release
# APK em: build/app/outputs/flutter-apk/app-release.apk
```

---

## Configurar as 3 Permissões do App

Após instalar, abra o Meta Moto e toque no ícone 🔔 (canto superior direito):

### Permissão 1 — Leitura de Notificações

1. Toque em **"Ativar"** ao lado de "Leitura de Notificações"
2. Encontre **"Meta Moto"** na lista e ative o toggle
3. Confirme o aviso do Android

→ Corridas do Uber, 99 e iFood serão registradas automaticamente.

### Permissão 2 — Overlay Flutuante (Bolinha)

1. Toque em **"Ativar"** ao lado de "Overlay Flutuante"
2. Ative **"Exibir sobre outros apps"** para o Meta Moto

→ Uma bolinha aparecerá sobre qualquer app mostrando a corrida detectada em tempo real.

### Permissão 3 — Localização (GPS para km automático)

1. Ao iniciar o primeiro turno, o app pedirá permissão de localização
2. Escolha **"Sempre permitir"** para rastrear km com a tela bloqueada

→ Os km são acumulados automaticamente durante o turno e alimentam os alertas de manutenção.

---

## Funcionalidades Principais

### 🏍️ KM Automático via GPS
- Ativo durante o turno
- Usa fórmula de Haversine com filtro anti-saltos de GPS
- Total acumulado alimenta os alertas de manutenção

### 🔔 Detecção Automática de Corridas

| Plataforma | Pacote detectado |
|---|---|
| Uber | com.ubercab.driver |
| 99 | com.taxis99.driver |
| iFood | com.ifood.courier |
| Lalamove | com.lalamove.android |
| InDrive | sinet.startup.inDriver |

Extrai automaticamente:
- **Valor (R$)** — regex `R$ 12,50`
- **Distância (km)** — regex `3,2 km`
- **Eficiência** — Valor ÷ KM = R$/km

### 🫧 Overlay Flutuante
Aparece sobre qualquer app ao detectar uma corrida:
- Valor em destaque
- Distância e R$/km
- 🟡 Alerta pulsante se a eficiência estiver abaixo do seu limite

### ⚡ Alerta de Baixa Eficiência
- Limite padrão: **R$ 2,00/km**
- Ajustável na tela "Automação & Overlay" via slider
- Corridas ruins ficam marcadas no histórico

### 🔧 Manutenção Preventiva por KM

| Revisão | Intervalo padrão |
|---|---|
| Troca de Óleo | 3.000 km |
| Corrente | 8.000 km |
| Filtro de Ar | 6.000 km |
| Vela | 12.000 km |
| Pastilha de Freio | 10.000 km |
| Pneu | 15.000 km |

---

## Estrutura do Projeto

```
meta_moto_flutter/
├── lib/
│   ├── main.dart                     ← Entry-points: main() + overlayMain()
│   ├── theme/app_theme.dart          ← Tema preto + vermelho
│   ├── models/                       ← Ride, Expense, Goal, Shift
│   ├── database/database_helper.dart ← SQLite local
│   ├── providers/app_provider.dart   ← Estado global + lógica de eficiência
│   ├── services/
│   │   ├── location_service.dart     ← GPS / km automático (Haversine)
│   │   └── overlay_service.dart     ← Controla a bolinha flutuante
│   ├── widgets/
│   │   ├── overlay_bubble.dart       ← UI da bolinha (engine separado)
│   │   ├── shift_widget.dart         ← Widget do turno com km ao vivo
│   │   ├── ride_tile.dart            ← Tile de corrida com badge AUTO
│   │   └── earnings_card.dart        ← Card com progress bar de meta
│   └── screens/
│       ├── home_screen.dart          ← Dashboard
│       ├── history_screen.dart       ← Histórico por data/plataforma
│       ├── expenses_screen.dart      ← Combustível e manutenção
│       ├── goals_screen.dart         ← Metas diária/semanal/mensal
│       ├── reports_screen.dart       ← Gráficos por dia e plataforma
│       ├── maintenance_screen.dart   ← Alertas de manutenção por km
│       ├── calculator_screen.dart    ← Calculadora + taxas
│       └── notification_setup_screen.dart ← Permissões + limite eficiência
└── android/
    └── app/src/main/
        ├── AndroidManifest.xml       ← Permissões + serviços declarados
        └── kotlin/com/metamoto/meta_moto/
            ├── MainActivity.kt           ← MethodChannel + EventChannel
            ├── RideNotificationService.kt← NotificationListenerService (background)
            └── RideEventStreamHandler.kt ← Ponte Kotlin → Flutter
```

---

## Como o Background Engine Funciona

```
Tela bloqueada
      │
      ▼
RideNotificationService (Kotlin) — roda como serviço do Android
      │  detecta notificação → extrai R$ e km via Regex
      │
      ▼
RideEventStreamHandler.sendRide(platform, value, distKm)
      │
      ▼
EventChannel → Flutter (AppProvider._onNotificationReceived)
      │  calcula eficiência, salva no SQLite
      │
      ▼
OverlayService.mostrarCorridaDetectada()
      │
      ▼
flutter_overlay_window → overlayMain() engine isolado → OverlayBubble widget
```

O `NotificationListenerService` é um serviço nativo Android que o sistema garante que permaneça ativo mesmo com o app fechado ou a tela bloqueada.

---

## Solução de Problemas

**GPS não rastreia km:**
- Permissão deve ser **"Sempre permitir"** (não "durante o uso")
- Em ROMs MIUI/One UI: adicione o Meta Moto à lista de apps sem restrição de bateria

**Corridas não detectadas automaticamente:**
- Confirme que o app de entrega envia notificação ao finalizar (não apenas sons)
- Verifique se "Acesso a notificações" está ativo para o Meta Moto

**Bolinha não aparece:**
- Verifique se "Exibir sobre outros apps" está ativado para o Meta Moto
- Em MIUI: Configurações → Apps → Meta Moto → Outros → Janelas Flutuantes

**Erro de Gradle:**
```bash
cd android && ./gradlew clean
cd .. && flutter clean && flutter pub get && flutter run
```

---

Desenvolvido para motoboys brasileiros. 🏍️🇧🇷
