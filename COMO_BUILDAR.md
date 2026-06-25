# Meta Moto — Como Gerar o APK

## Pre-requisitos (instalar no celular via Termux)

```bash
# 1. Instale o Termux na Play Store (ou F-Droid)
# 2. Dentro do Termux, execute:
pkg update && pkg upgrade -y
pkg install nodejs git -y
npm install -g eas-cli
```

## Passo a passo

```bash
# 1. Clone o repositorio
git clone https://github.com/jenniferfelixmanicure-creator/meta-moto.git
cd meta-moto

# 2. Instale as dependencias
npm install

# 3. Faca login na sua conta Expo
eas login

# 4. Configure o projeto (apenas na primeira vez)
eas build:configure

# 5. GERE O APK (preview)
eas build --platform android --profile preview

# Aguarde o build terminar (5-10 minutos)
# Voce recebera um link para baixar o APK
```

## Sobre o NotificationListenerService

Apos instalar o APK:
1. Abra o Meta Moto
2. Va em Configuracoes do Android > Aplicativos > Acesso especial > Acesso a notificacoes
3. Ative o Meta Moto
4. O app passara a detectar automaticamente corridas do Uber, 99, iFood, etc.

## Perfis de build disponíveis

| Perfil | Comando | Resultado |
|--------|---------|-----------|
| preview | `eas build --platform android --profile preview` | APK para instalar direto |
| production | `eas build --platform android --profile production` | AAB para Google Play |

## Duvidas
- Site da Expo: https://expo.dev
- Documentacao EAS: https://docs.expo.dev/build/introduction/
