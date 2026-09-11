import type { ConfigContext, ExpoConfig } from '@expo/config';

type ExpoPlugins = NonNullable<ExpoConfig['plugins']>;

export default ({ config }: ConfigContext): ExpoConfig => {
  const nativePlugins: ExpoPlugins =
    process.env.EXPO_PLATFORM === 'native'
      ? [['expo-dev-client', { launchMode: 'most-recent' }], 'react-native-maps']
      : [];

  return {
    ...config,

    // App identity
    name: "Pirate's Plunder",
    slug: 'pirate-plunder',
    version: process.env.BILT_APP_VERSION ?? '1.0.0',
    scheme: 'pirate-plunder',
    icon: './public/icons/icon-512.png',

    // App settings
    newArchEnabled: true,
    orientation: 'portrait',
    userInterfaceStyle: 'automatic',

    runtimeVersion: {
      policy: 'appVersion',
    },

    assetBundlePatterns: ['**/*'],

    // iOS
    ios: {
      infoPlist: {
        ITSAppUsesNonExemptEncryption: false,
      },

      supportsTablet: true,

      bundleIdentifier:
        process.env.BILT_IOS_BUNDLE_ID ?? 'com.harshamin.piratesplunder',

      icon: './public/icons/icon-512.png',
    },

    // Android
    android: {
      package:
        process.env.BILT_ANDROID_PACKAGE ?? 'com.harshamin.piratesplunder',

      // Firebase Android config
      googleServicesFile: './google-services.json',

      // Pirate's Plunder only plays audio and stores app-private data.
      // Explicitly block permissions that can be contributed by native libraries
      // but are not required by the game.
      blockedPermissions: [
        'android.permission.RECORD_AUDIO',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.WRITE_EXTERNAL_STORAGE',
      ],

      // Use the standard launcher icon instead of the adaptive foreground setup.
      // icon-512-maskable.png was byte-for-byte identical to icon-512.png, so
      // Android treated the entire finished icon as an adaptive foreground layer
      // and enlarged/cropped it inside the launcher mask.
      icon: './public/icons/icon-512.png',
    },

    // Web
    web: {
      bundler: 'metro',
      output: 'single',
      favicon: './public/icons/icon-192.png',
    },

    // Extra Expo / EAS config
    extra: {
      appStoreAppId: process.env.BILT_APP_STORE_APP_ID,

      eas: {
        projectId: '7b93db2f-0866-4f20-bb30-f4be96435582',
      },
    },

    // Expo config plugins
    plugins: [
      'expo-router',

      'expo-font',

      // Configure expo-audio for playback only. The game does not record audio.
      [
        'expo-audio',
        {
          recordAudioAndroid: false,
          microphonePermission: false,
        },
      ],

      // React Native Firebase
      // Use direct plugin path to avoid INVALID_PLUGIN_IMPORT error.
      '@react-native-firebase/app/app.plugin.js',

      [
        'expo-splash-screen',
        {
          image: './public/icons/icon-512.png',
          imageWidth: 240,
          resizeMode: 'contain',
          backgroundColor: '#06202B',

          dark: {
            image: './public/icons/icon-512.png',
            backgroundColor: '#06202B',
          },
        },
      ],

      ...nativePlugins,
    ],

    experiments: {
      typedRoutes: true,
      reactCompiler: true,
    },
  };
};
