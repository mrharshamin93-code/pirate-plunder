import { useCallback, useEffect, useRef } from 'react';
import { createAudioPlayer, type AudioPlayer } from 'expo-audio';

const COIN_SOUND = require('../assets/sounds/coin_premium_plink_single.mp3');
const EFFECT_VOLUME = 0.8;
const REWIND_DELAY_MS = 130;
const DUPLICATE_GUARD_MS = 140;

export function useCoinPickupSound(): () => void {
  const playerRef = useRef<AudioPlayer | null>(null);
  const lastPlayAtRef = useRef(0);
  const rewindTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    const player = createAudioPlayer(COIN_SOUND);
    player.volume = EFFECT_VOLUME;
    playerRef.current = player;

    return () => {
      if (rewindTimerRef.current !== null) {
        clearTimeout(rewindTimerRef.current);
        rewindTimerRef.current = null;
      }
      playerRef.current = null;
      player.remove();
    };
  }, []);

  return useCallback(() => {
    const now = Date.now();
    if (now - lastPlayAtRef.current < DUPLICATE_GUARD_MS) return;

    const player = playerRef.current;
    if (player === null) return;

    lastPlayAtRef.current = now;

    // Keep one native audio player, matching the original implementation that
    // behaved correctly on mobile. The previous player pool could leave more
    // than one native player active after an audio-session change (mute/unmute),
    // which could make one pickup sound twice on phones.
    player.play();

    if (rewindTimerRef.current !== null) {
      clearTimeout(rewindTimerRef.current);
    }

    // Rewind only after the short clip has finished so playback itself stays
    // immediate; no asynchronous seek sits in front of player.play().
    rewindTimerRef.current = setTimeout(() => {
      void player.seekTo(0);
      rewindTimerRef.current = null;
    }, REWIND_DELAY_MS);
  }, []);
}
