import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import { useAudioPlayer, useAudioPlayerStatus } from 'expo-audio';
import { File, Paths } from 'expo-file-system';

import { ensureGameAudioSession } from '@/lib/game/audioSession';
import { buildMusicWav, MUSIC_FILE_NAME } from '@/lib/game/music';

/** Sits under the effects rather than over them. */
const MUSIC_VOLUME = 0.42;

let trackPromise: Promise<string> | null = null;

/**
 * Renders the shanty once per app session and returns a URI the audio player can
 * load: a blob URL on web, a cached WAV file on native.
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

export function useBackgroundMusic(enabled: boolean): void {
  const [uri, setUri] = useState<string | null>(null);
  const player = useAudioPlayer(null, { updateInterval: 100 });
  const status = useAudioPlayerStatus(player);

  useEffect(() => {
    let active = true;

    void ensureGameAudioSession().catch(() => {
      // A later play request can retry session activation.
    });

    prepareTrack().then(
      (value) => {
        if (active) setUri(value);
      },
      () => {
        // Music is optional; the game continues if synthesis fails.
      },
    );

    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    player.loop = true;
    player.volume = MUSIC_VOLUME;
  }, [player]);

  useEffect(() => {
    if (uri === null) return;
    player.replace({ uri });
  }, [player, uri]);

  useEffect(() => {
    let cancelled = false;

    const syncPlayback = async () => {
      if (!enabled) {
        player.pause();
        return;
      }

      try {
        await ensureGameAudioSession();
      } catch {
        return;
      }

      if (cancelled || !status.isLoaded) return;
      player.play();
    };

    void syncPlayback();

    return () => {
      cancelled = true;
    };
  }, [enabled, player, status.isLoaded]);
}
