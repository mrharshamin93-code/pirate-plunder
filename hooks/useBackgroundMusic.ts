import { useEffect, useRef, useState } from 'react';
import { Platform } from 'react-native';
import { createAudioPlayer, setAudioModeAsync, type AudioPlayer } from 'expo-audio';
import { File, Paths } from 'expo-file-system';

import { buildMusicWav, MUSIC_FILE_NAME } from '@/lib/game/music';

/** Sits under the effects rather than over them. */
const MUSIC_VOLUME = 0.42;

let trackPromise: Promise<string> | null = null;

/**
 * Renders the shanty once per app session and returns a uri the audio player can
 * load: a blob url on web, a cached wav file on native. The synthesis is pushed
 * to a later tick so the first paint is never blocked by it.
 */
function prepareTrack(): Promise<string> {
  trackPromise ??= new Promise<string>((resolve, reject) => {
    setTimeout(() => {
      try {
        const bytes = buildMusicWav();

        if (Platform.OS === 'web') {
          resolve(URL.createObjectURL(new Blob([bytes], { type: 'audio/wav' })));
          return;
        }

        const file = new File(Paths.cache, MUSIC_FILE_NAME);
        if (file.exists) file.delete();
        file.create();
        file.write(bytes);
        resolve(file.uri);
      } catch (error) {
        reject(error instanceof Error ? error : new Error(String(error)));
      }
    }, 0);
  });
  return trackPromise;
}

/**
 * Loops the shanty for as long as `enabled` is true. Playback only ever starts
 * after a tap, which is also what browsers require before they will let audio
 * through.
 */
export function useBackgroundMusic(enabled: boolean): void {
  const [uri, setUri] = useState<string | null>(null);
  const playerRef = useRef<AudioPlayer | null>(null);

  useEffect(() => {
    let active = true;
    prepareTrack().then(
      (value) => {
        if (active) setUri(value);
      },
      () => {
        // music is optional; the game plays on in silence
      },
    );
    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    if (uri === null) return undefined;

    if (Platform.OS !== 'web') {
      void setAudioModeAsync({ playsInSilentMode: true, shouldPlayInBackground: false });
    }

    const player = createAudioPlayer({ uri });
    player.loop = true;
    player.volume = MUSIC_VOLUME;
    playerRef.current = player;

    return () => {
      playerRef.current = null;
      player.remove();
    };
  }, [uri]);

  useEffect(() => {
    const player = playerRef.current;
    if (player === null) return;
    if (enabled) player.play();
    else player.pause();
  }, [enabled, uri]);
}
