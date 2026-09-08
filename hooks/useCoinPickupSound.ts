import { useCallback, useEffect, useRef, useState } from 'react';
import { Platform } from 'react-native';
import { createAudioPlayer, type AudioPlayer } from 'expo-audio';
import { File, Paths } from 'expo-file-system';

const SAMPLE_RATE = 44100;
const DURATION_SECONDS = 0.18;
const FILE_NAME = 'pirates-plunder-coin-premium-plink.wav';
const EFFECT_VOLUME = 0.8;
const PLAYER_POOL_SIZE = 4;
const REWIND_DELAY_MS = Math.ceil(DURATION_SECONDS * 1000) + 40;

let soundPromise: Promise<string> | null = null;

function writeAscii(view: DataView, offset: number, value: string) {
  for (let i = 0; i < value.length; i += 1) {
    view.setUint8(offset + i, value.charCodeAt(i));
  }
}

/**
 * Builds one short premium plink with no delayed second note.
 */
function buildPremiumPlinkWav(): Uint8Array {
  const sampleCount = Math.floor(SAMPLE_RATE * DURATION_SECONDS);
  const pcm = new Int16Array(sampleCount);

  for (let i = 0; i < sampleCount; i += 1) {
    const t = i / SAMPLE_RATE;

    const envelope = Math.exp(-t / 0.055);
    const attack = Math.min(1, t / 0.002);

    const sample =
      0.5 * Math.sin(2 * Math.PI * 1320 * t) * envelope +
      0.15 * Math.sin(2 * Math.PI * 2640 * t) * Math.exp(-t / 0.03);

    const value = Math.max(-1, Math.min(1, sample * attack));
    pcm[i] = Math.round(value * 32767);
  }

  const dataBytes = pcm.length * 2;
  const buffer = new ArrayBuffer(44 + dataBytes);
  const view = new DataView(buffer);

  writeAscii(view, 0, 'RIFF');
  view.setUint32(4, 36 + dataBytes, true);
  writeAscii(view, 8, 'WAVE');
  writeAscii(view, 12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, SAMPLE_RATE, true);
  view.setUint32(28, SAMPLE_RATE * 2, true);
  view.setUint16(32, 2, true);
  view.setUint16(34, 16, true);
  writeAscii(view, 36, 'data');
  view.setUint32(40, dataBytes, true);

  for (let i = 0; i < pcm.length; i += 1) {
    view.setInt16(44 + i * 2, pcm[i], true);
  }

  return new Uint8Array(buffer);
}

function prepareSound(): Promise<string> {
  soundPromise ??= new Promise<string>((resolve, reject) => {
    setTimeout(() => {
      try {
        const bytes = buildPremiumPlinkWav();

        if (Platform.OS === 'web') {
          resolve(URL.createObjectURL(new Blob([bytes], { type: 'audio/wav' })));
          return;
        }

        const file = new File(Paths.cache, FILE_NAME);
        if (file.exists) file.delete();
        file.create();
        file.write(bytes);
        resolve(file.uri);
      } catch (error) {
        reject(error instanceof Error ? error : new Error(String(error)));
      }
    }, 0);
  });

  return soundPromise;
}

export function useCoinPickupSound(): () => void {
  const [uri, setUri] = useState<string | null>(null);
  const playersRef = useRef<AudioPlayer[]>([]);
  const nextPlayerRef = useRef(0);
  const rewindTimersRef = useRef<ReturnType<typeof setTimeout>[]>([]);

  useEffect(() => {
    let active = true;

    prepareSound().then(
      (value) => {
        if (active) setUri(value);
      },
      () => {
        // Sound effects are optional; gameplay continues if audio setup fails.
      },
    );

    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    if (uri === null) return undefined;

    const players = Array.from({ length: PLAYER_POOL_SIZE }, () => {
      const player = createAudioPlayer({ uri });
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
  }, [uri]);

  return useCallback(() => {
    const players = playersRef.current;
    if (players.length === 0) return;

    const index = nextPlayerRef.current;
    const player = players[index];
    nextPlayerRef.current = (index + 1) % players.length;

    player.play();

    const timer = setTimeout(() => {
      void player.seekTo(0);
      rewindTimersRef.current = rewindTimersRef.current.filter((t) => t !== timer);
    }, REWIND_DELAY_MS);

    rewindTimersRef.current.push(timer);
  }, []);
}
