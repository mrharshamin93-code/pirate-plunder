import { Platform } from 'react-native';
import { setAudioModeAsync, setIsAudioActiveAsync } from 'expo-audio';

let sessionPromise: Promise<void> | null = null;

/**
 * Configure Expo Audio once for the whole game. Keeping this in one place avoids
 * the music and sound-effect players racing each other while changing the native
 * audio session on Android/iOS.
 */
export function ensureGameAudioSession(): Promise<void> {
  if (Platform.OS === 'web') return Promise.resolve();

  sessionPromise ??= (async () => {
    await setIsAudioActiveAsync(true);
    await setAudioModeAsync({
      playsInSilentMode: true,
      shouldPlayInBackground: false,
      interruptionMode: 'mixWithOthers',
    });
  })().catch((error) => {
    // Allow a later user interaction to retry if the native audio session was
    // temporarily unavailable during app startup.
    sessionPromise = null;
    throw error;
  });

  return sessionPromise;
}
