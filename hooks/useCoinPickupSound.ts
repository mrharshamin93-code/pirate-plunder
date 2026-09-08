import { useCallback, useEffect, useRef } from 'react';
import { createAudioPlayer, type AudioPlayer } from 'expo-audio';

const COIN_SOUND = require('../assets/sounds/coin_sound_5_premium_plink.mp3');
const EFFECT_VOLUME = 0.8;
const REWIND_DELAY_MS = 320;
const DUPLICATE_GUARD_MS = 120;

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
    lastPlayAtRef.current = now;

    const player = playerRef.current;
    if (player === null) return;

    player.play();

    if (rewindTimerRef.current !== null) {
      clearTimeout(rewindTimerRef.current);
    }

    rewindTimerRef.current = setTimeout(() => {
      void player.seekTo(0);
      rewindTimerRef.current = null;
    }, REWIND_DELAY_MS);
  }, []);
}
