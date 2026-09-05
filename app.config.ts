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
      googleServicesFile: './google-services.json',
      icon: './public/icons/icon-512.png',
      adaptiveIcon: {
        foregroundImage: './public/icons/icon-512-maskable.png',
        backgroundColor: '#06202B',
      },
    },

    // Web
    web: {
      bundler: 'metro',
      output: 'single',
      favicon: './public/icons/icon-192.png',
    },

    extra: {
      appStoreAppId: process.env.BILT_APP_STORE_APP_ID,
      eas: {
        projectId: '7b93db2f-0866-4f20-bb30-f4be96435582',
      },
    },

    plugins: [
      'expo-router',
      'expo-font',
      '@react-native-firebase/app',
      '@react-native-firebase/analytics',
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
