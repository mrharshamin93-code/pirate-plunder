import { Platform } from 'react-native';

let analyticsModulePromise: Promise<typeof import('@react-native-firebase/analytics')> | null = null;

function getAnalyticsModule() {
  if (Platform.OS === 'web') return null;
  analyticsModulePromise ??= import('@react-native-firebase/analytics');
  return analyticsModulePromise;
}

async function logEvent(name: string, params?: Record<string, string | number>) {
  try {
    const modulePromise = getAnalyticsModule();
    if (!modulePromise) return;
    const { getAnalytics, logEvent: firebaseLogEvent } = await modulePromise;
    await firebaseLogEvent(getAnalytics(), name, params);
  } catch (error) {
    if (__DEV__) console.warn(`[analytics] ${name} failed`, error);
  }
}

export function trackGameStarted() {
  return logEvent('game_started');
}

export function trackGameEnded(params: {
  score: number;
  coins: number;
  durationSeconds: number;
}) {
  return logEvent('game_ended', {
    score: Math.max(0, Math.floor(params.score)),
    coins: Math.max(0, Math.floor(params.coins)),
    duration_seconds: Math.max(0, Math.round(params.durationSeconds)),
  });
}

export function trackCoinPickup(points: number) {
  return logEvent('coin_collected', { points: Math.max(0, Math.floor(points)) });
}
