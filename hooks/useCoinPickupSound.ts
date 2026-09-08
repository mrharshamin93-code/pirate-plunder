import { useCallback, useEffect, useRef } from 'react';
import { Platform } from 'react-native';
import { useAudioPlayer, useAudioPlayerStatus } from 'expo-audio';

import { ensureGameAudioSession } from '@/lib/game/audioSession';

const COIN_SOUND = require('../assets/sounds/coin_sound_5_premium_plink.mp3');
const EFFECT_VOLUME = 0.8;
const DUPLICATE_GUARD_MS = 260;
const MOBILE_FIRST_PLINK_MS = 58;

export function useCoinPickupSound(): () => void {
  const player = useAudioPlayer(COIN_SOUND, { updateInterval: 50 });
  const status = useAudioPlayerStatus(player);
  const lastPlayAtRef = useRef(0);
  const stopTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    player.loop = false;
    player.volume = EFFECT_VOLUME;
    void ensureGameAudioSession().catch(() => {
      // A later game-start/pickup interaction retries the session setup.
    });

    return () => {
      if (stopTimerRef.current !== null) {
        clearTimeout(stopTimerRef.current);
        stopTimerRef.current = null;
      }
    };
  }, [player]);

  return useCallback(() => {
    const now = Date.now();
    if (now - lastPlayAtRef.current < DUPLICATE_GUARD_MS) return;
    if (!status.isLoaded) return;

    lastPlayAtRef.current = now;

    void ensureGameAudioSession().then(
      () => {
        if (!status.isLoaded) return;

        // The original Premium Plink asset contains a second accent about 65 ms
        // into the file. Desktop speakers blend it into one sound, but phone
        // speakers make it sound like a double click. Keep the original asset
        // untouched and, on native only, play just its first plink.
        player.play();

        if (Platform.OS !== 'web') {
          if (stopTimerRef.current !== null) clearTimeout(stopTimerRef.current);
          stopTimerRef.current = setTimeout(() => {
            player.pause();
            void player.seekTo(0);
            stopTimerRef.current = null;
          }, MOBILE_FIRST_PLINK_MS);
        } else {
          // Web sounds correct with the complete original clip. Rewind after it
          // finishes so the next pickup starts from the beginning.
          if (stopTimerRef.current !== null) clearTimeout(stopTimerRef.current);
          stopTimerRef.current = setTimeout(() => {
            void player.seekTo(0);
            stopTimerRef.current = null;
          }, 320);
        }
      },
      () => {
        // Sound effects are optional; gameplay should never be interrupted.
      },
    );
  }, [player, status.isLoaded]);
}
