import { useCallback, useEffect, useRef } from 'react';
import { Platform } from 'react-native';
import {
  createAudioPlayer,
  setAudioModeAsync,
  type AudioPlayer,
} from 'expo-audio';

const COIN_SOUND = require('../assets/sounds/coin_sound_5_premium_plink.mp3');
const EFFECT_VOLUME = 0.8;
const REWIND_DELAY_MS = 320;
const PLAY_LOCK_MS = 360;

export function useCoinPickupSound(): () => void {
  const playerRef = useRef<AudioPlayer | null>(null);
  const lockedRef = useRef(false);
  const rewindTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const unlockTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    let active = true;
    let createdPlayer: AudioPlayer | null = null;

    const prepare = async () => {
      // On native, configure the audio session before creating the effect player.
      // Previously this only happened inside the background-music hook, which is
      // why coin audio could stay silent until the music button was toggled.
      if (Platform.OS !== 'web') {
        try {
          await setAudioModeAsync({
            playsInSilentMode: true,
            shouldPlayInBackground: false,
          });
        } catch {
          // Keep gameplay running even if the platform rejects audio-mode setup.
        }
      }

      if (!active) return;

      const player = createAudioPlayer(COIN_SOUND);
      player.loop = false;
      player.volume = EFFECT_VOLUME;
      createdPlayer = player;
      playerRef.current = player;
    };

    void prepare();

    return () => {
      active = false;

      if (rewindTimerRef.current !== null) {
        clearTimeout(rewindTimerRef.current);
        rewindTimerRef.current = null;
      }
      if (unlockTimerRef.current !== null) {
        clearTimeout(unlockTimerRef.current);
        unlockTimerRef.current = null;
      }

      lockedRef.current = false;
      playerRef.current = null;
      createdPlayer?.remove();
    };
  }, []);

  return useCallback(() => {
    const player = playerRef.current;
    if (player === null || lockedRef.current) return;

    // Keep one native playback active at a time. This prevents the same pickup
    // from being heard twice on mobile while preserving the original MP3 asset.
    lockedRef.current = true;
    player.play();

    if (rewindTimerRef.current !== null) clearTimeout(rewindTimerRef.current);
    rewindTimerRef.current = setTimeout(() => {
      void player.seekTo(0);
      rewindTimerRef.current = null;
    }, REWIND_DELAY_MS);

    if (unlockTimerRef.current !== null) clearTimeout(unlockTimerRef.current);
    unlockTimerRef.current = setTimeout(() => {
      lockedRef.current = false;
      unlockTimerRef.current = null;
    }, PLAY_LOCK_MS);
  }, []);
}
