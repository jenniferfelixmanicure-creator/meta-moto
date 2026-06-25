const { withAndroidManifest, withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

/**
 * Expo config plugin: adds NotificationListenerService to the Android build.
 * - Registers the service in AndroidManifest.xml
 * - Copies Kotlin source files into the Android project
 * - Patches MainApplication.kt to register the native module package
 */
function withNotificationListener(config) {
  // 1. Add service to AndroidManifest.xml
  config = withAndroidManifest(config, (cfg) => {
    const app = cfg.modResults.manifest.application[0];
    if (!app.service) app.service = [];

    const already = app.service.some(
      (s) => s.$?.['android:name'] === '.RideNotificationService'
    );
    if (!already) {
      app.service.push({
        $: {
          'android:name': '.RideNotificationService',
          'android:label': 'Captura de Corridas Meta Moto',
          'android:exported': 'false',
          'android:permission': 'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE',
        },
        'intent-filter': [
          {
            action: [
              {
                $: {
                  'android:name':
                    'android.service.notification.NotificationListenerService',
                },
              },
            ],
          },
        ],
      });
    }
    return cfg;
  });

  // 2. Local Expo Module system handles native linking automatically via expo-module.config.json
  // No manual patching of MainApplication.kt needed.

  return config;
}

module.exports = withNotificationListener;
