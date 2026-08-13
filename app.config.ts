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
    },

    // Android
    android: {
      package:
        process.env.BILT_ANDROID_PACKAGE ?? 'com.harshamin.piratesplunder',
    },

    // Web
    web: {
      bundler: 'metro',
      output: 'single',
      favicon: './public/icons/icon-192.png',
    },

    extra: {
      appStoreAppId: process.env.BILT_APP_STORE_APP_ID,
    },

    plugins: ['expo-router', 'expo-font', ...nativePlugins],

    experiments: {
      typedRoutes: true,
      reactCompiler: true,
    },
  };
};
