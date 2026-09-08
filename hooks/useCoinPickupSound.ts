import { useCallback, useEffect, useRef } from 'react';
import { createAudioPlayer, type AudioPlayer } from 'expo-audio';

const COIN_SOUND = require('../assets/sounds/coin_sound_5_premium_plink.mp3');
const EFFECT_VOLUME = 0.8;
const PLAYER_POOL_SIZE = 3;
const REWIND_DELAY_MS = 320;
const DUPLICATE_GUARD_MS = 100;

export function useCoinPickupSound(): () => void {
  const playersRef = useRef<AudioPlayer[]>([]);
  const nextPlayerRef = useRef(0);
  const lastPlayAtRef = useRef(0);
  const rewindTimersRef = useRef<ReturnType<typeof setTimeout>[]>([]);

  useEffect(() => {
    const players = Array.from({ length: PLAYER_POOL_SIZE }, () => {
      const player = createAudioPlayer(COIN_SOUND);
      player.volume = EFFECT_VOLUME;
      return player;
    });

    playersRef.current = players;
    nextPlayerRef.current = 0;

    return () => {
      rewindTimersRef.current.forEach(clearTimeout);
      rewindTimersRef.current = [];
      playersRef.current = [];
      players.forEach((player) => player.remove());
    };
  }, []);

  return useCallback(() => {
    const now = Date.now();
    if (now - lastPlayAtRef.current < DUPLICATE_GUARD_MS) return;
    lastPlayAtRef.current = now;

    const players = playersRef.current;
    if (players.length === 0) return;

    const index = nextPlayerRef.current;
    const player = players[index];
    nextPlayerRef.current = (index + 1) % players.length;

    // The sound asset is preloaded by expo-audio, so playback starts immediately.
    // Rewind only after the clip has finished to avoid seek latency before playback.
    player.play();

    const timer = setTimeout(() => {
      void player.seekTo(0);
      rewindTimersRef.current = rewindTimersRef.current.filter((t) => t !== timer);
    }, REWIND_DELAY_MS);

    rewindTimersRef.current.push(timer);
  }, []);
}
