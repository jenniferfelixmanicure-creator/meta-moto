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

  // 2. Copy Kotlin files + patch MainApplication.kt
  config = withDangerousMod(config, [
    'android',
    (cfg) => {
      const projectRoot = cfg.modRequest.projectRoot;
      const packageDir = path.join(
        projectRoot,
        'android/app/src/main/java/com/metamoto/app'
      );
      fs.mkdirSync(packageDir, { recursive: true });

      // Copy all Kotlin source files from modules/notification-listener/android/
      const srcDir = path.join(
        projectRoot,
        'modules/notification-listener/android'
      );
      if (fs.existsSync(srcDir)) {
        fs.readdirSync(srcDir).forEach((file) => {
          fs.copyFileSync(
            path.join(srcDir, file),
            path.join(packageDir, file)
          );
        });
      }

      // Patch MainApplication.kt to add our package
      const mainAppPath = path.join(packageDir, 'MainApplication.kt');
      if (fs.existsSync(mainAppPath)) {
        let content = fs.readFileSync(mainAppPath, 'utf8');

        if (!content.includes('NotificationListenerPackage')) {
          // Add after PackageList(this).packages
          content = content.replace(
            /val packages = PackageList\(this\)\.packages/,
            `val packages = PackageList(this).packages\n        packages.add(NotificationListenerPackage())`
          );
          // Fallback: try mutable list approach
          if (!content.includes('NotificationListenerPackage()')) {
            content = content.replace(
              /PackageList\(this\)\.packages\.apply \{/,
              `PackageList(this).packages.apply {\n            add(NotificationListenerPackage())`
            );
          }
          fs.writeFileSync(mainAppPath, content, 'utf8');
        }
      }

      return cfg;
    },
  ]);

  return config;
}

module.exports = withNotificationListener;
