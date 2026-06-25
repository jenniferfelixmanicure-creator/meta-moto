# Meta Moto — Guia de Instalação

App financeiro completo para motoboys. Rastreie corridas, km, metas e manutenções.

---

## Pré-requisitos

| Ferramenta | Versão mínima | Download |
|---|---|---|
| Flutter SDK | 3.19+ | https://flutter.dev/docs/get-started/install |
| Android Studio | 2023.1+ | https://developer.android.com/studio |
| Java JDK | 17+ | Incluso no Android Studio |
| Git | qualquer | https://git-scm.com |

---

## Instalação Passo a Passo

### 1. Instalar o Flutter

```bash
# Linux/macOS
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verifique tudo certo
flutter doctor
```

### 2. Instalar dependências do projeto

```bash
# Na pasta meta_moto_flutter/
flutter pub get
```

### 3. Conectar um Android físico (recomendado)

> ⚠️ O KM via GPS e o leitor de notificações funcionam melhor em dispositivo real.

1. No Android: **Configurações → Sobre o telefone → Número de build** (toque 7x)
2. **Configurações → Opções do desenvolvedor → Depuração USB** → Ativar
3. Conecte o cabo USB e aceite a permissão no celular

```bash
flutter devices   # deve aparecer seu dispositivo
```

### 4. Rodar o app

```bash
flutter run
```

Ou, para build de release (APK):

```bash
flutter build apk --release
# APK gerado em: build/app/outputs/flutter-apk/app-release.apk
```

---

## Configurar Leitura Automática de Corridas

Após instalar o app no celular:

1. Abra o **Meta Moto**
2. Toque no ícone de notificação (🔔) no canto superior direito
3. Toque em **"Ativar nas Configurações do Android"**
4. Na lista que abrir, encontre **"Meta Moto"** e ative o toggle
5. Confirme a permissão

A partir daí, ao receber uma notificação de corrida concluída do Uber, 99, iFood, Lalamove ou InDrive, ela será registrada automaticamente com a tag **AUTO**.

### Apps suportados para detecção automática

| Plataforma | Pacote Android |
|---|---|
| Uber | com.ubercab |
| 99 | com.taxis99 |
| iFood | br.com.ifood |
| Lalamove | com.lalamove.android |
| InDrive | sinet.startup.inDriver |

---

## Rastreamento de KM Automático

O app rastreia automaticamente os km rodados enquanto o turno estiver ativo:

1. Toque em **"Iniciar Turno"** na tela inicial
2. Conceda permissão de localização quando solicitado (**"Sempre permitir"** para funcionar em segundo plano)
3. Os km serão contabilizados em tempo real e exibidos no widget do turno
4. Ao encerrar o turno, os km são somados ao odômetro total

O odômetro total alimenta automaticamente os **alertas de manutenção**.

---

## Permissões necessárias

| Permissão | Para que serve |
|---|---|
| Localização (em 2° plano) | Rastrear km automaticamente |
| Leitura de notificações | Detectar corridas automaticamente |
| Notificações | Alertas de manutenção |

---

## Estrutura do projeto

```
meta_moto_flutter/
├── lib/
│   ├── main.dart                    — Entrada do app
│   ├── theme/app_theme.dart         — Tema escuro vermelho
│   ├── models/                      — Ride, Expense, Goal, Shift
│   ├── database/database_helper.dart— SQLite local
│   ├── providers/app_provider.dart  — Estado global
│   ├── services/location_service.dart— GPS / KM tracking
│   └── screens/
│       ├── home_screen.dart         — Dashboard principal
│       ├── history_screen.dart      — Histórico por data
│       ├── expenses_screen.dart     — Despesas
│       ├── goals_screen.dart        — Metas com progress bar
│       ├── reports_screen.dart      — Gráficos diários e por plataforma
│       ├── maintenance_screen.dart  — Alertas de manutenção por KM
│       ├── calculator_screen.dart   — Calculadora + taxas
│       └── notification_setup_screen.dart — Configurar leitura automática
└── android/
    └── app/src/main/kotlin/
        ├── MainActivity.kt          — MethodChannel + EventChannel
        ├── RideNotificationService.kt— NotificationListenerService
        └── RideEventStreamHandler.kt— Ponte Kotlin → Flutter
```

---

## Solução de problemas

**Flutter não encontra dispositivo:**
```bash
adb devices        # deve listar o seu celular
adb kill-server
adb start-server
```

**Erro de versão do Gradle:**
Abra `android/gradle/wrapper/gradle-wrapper.properties` e confirme a URL:
`distributionUrl=https://services.gradle.org/distributions/gradle-8.3-all.zip`

**GPS não rastreia km:**
- Verifique se a permissão é "Sempre permitir" (não apenas "durante o uso")
- Teste em ambiente externo (GPS indoor é impreciso)

**Notificações não detectam corridas:**
- Confirme que o app de entrega envia notificações ao finalizar corridas
- Verifique se o Meta Moto está na lista de "Acesso a notificações"
- Alguns ROMs (MIUI, One UI) podem bloquear serviços em segundo plano — adicione o Meta Moto à lista de apps sem restrição de bateria

---

## Tecnologias

- **Flutter 3.19+** — framework multiplataforma
- **Kotlin** — código nativo Android (NotificationListenerService)
- **SQLite / sqflite** — banco local
- **Geolocator** — GPS e distância via Haversine
- **fl_chart** — gráficos de barras e pizza
- **Provider** — gerenciamento de estado
- **Google Fonts (Inter)** — tipografia

---

Desenvolvido para motoboys brasileiros. 🏍️🇧🇷
