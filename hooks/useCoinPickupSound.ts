import { useCallback, useEffect, useRef } from 'react';
import { useAudioPlayer, useAudioPlayerStatus } from 'expo-audio';

import { ensureGameAudioSession } from '@/lib/game/audioSession';

const COIN_SOUND = require('../assets/sounds/coin_sound_5_premium_plink.mp3');
const EFFECT_VOLUME = 0.8;
const DUPLICATE_GUARD_MS = 360;
const REWIND_DELAY_MS = 320;

export function useCoinPickupSound(): () => void {
  const player = useAudioPlayer(COIN_SOUND, { updateInterval: 50 });
  const status = useAudioPlayerStatus(player);
  const lastPlayAtRef = useRef(0);
  const rewindTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingRef = useRef(false);

  useEffect(() => {
    player.loop = false;
    player.volume = EFFECT_VOLUME;

    void ensureGameAudioSession().catch(() => {
      // The first user interaction will retry native audio activation.
    });

    return () => {
      if (rewindTimerRef.current !== null) {
        clearTimeout(rewindTimerRef.current);
        rewindTimerRef.current = null;
      }
      pendingRef.current = false;
    };
  }, [player]);

  return useCallback(() => {
    const now = Date.now();

    // One JS playback request per collected coin. This guard is set before the
    // async audio-session check so a duplicate callback cannot queue a second play.
    if (pendingRef.current || now - lastPlayAtRef.current < DUPLICATE_GUARD_MS) return;
    if (!status.isLoaded) return;

    pendingRef.current = true;
    lastPlayAtRef.current = now;

    void ensureGameAudioSession().then(
      () => {
        if (!status.isLoaded) {
          pendingRef.current = false;
          return;
        }

        // There is exactly one player.play() call in the pickup path.
        player.play();

        if (rewindTimerRef.current !== null) clearTimeout(rewindTimerRef.current);
        rewindTimerRef.current = setTimeout(() => {
          void player.seekTo(0);
          rewindTimerRef.current = null;
          pendingRef.current = false;
        }, REWIND_DELAY_MS);
      },
      () => {
        pendingRef.current = false;
      },
    );
  }, [player, status.isLoaded]);
}
