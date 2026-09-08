import { useCallback, useEffect, useRef, useState } from 'react';
import { Platform } from 'react-native';
import { createAudioPlayer, type AudioPlayer } from 'expo-audio';
import { File, Paths } from 'expo-file-system';

const SAMPLE_RATE = 44100;
const DURATION_SECONDS = 0.24;
const FILE_NAME = 'pirates-plunder-coin-premium-plink.wav';
const EFFECT_VOLUME = 0.8;

let soundPromise: Promise<string> | null = null;

function writeAscii(view: DataView, offset: number, value: string) {
  for (let i = 0; i < value.length; i += 1) {
    view.setUint8(offset + i, value.charCodeAt(i));
  }
}

/**
 * Builds the selected Premium Plink coin pickup sound entirely in-app so no
 * binary asset needs to be bundled. It is a short two-tone bell/plink designed
 * to stay clear above the background music without becoming harsh.
 */
function buildPremiumPlinkWav(): Uint8Array {
  const sampleCount = Math.floor(SAMPLE_RATE * DURATION_SECONDS);
  const pcm = new Int16Array(sampleCount);

  for (let i = 0; i < sampleCount; i += 1) {
    const t = i / SAMPLE_RATE;

    const firstEnvelope = Math.exp(-t / 0.07);
    let sample =
      0.48 * Math.sin(2 * Math.PI * 1320 * t) * firstEnvelope +
      0.18 * Math.sin(2 * Math.PI * 2640 * t) * Math.exp(-t / 0.04);

    if (t >= 0.065) {
      const accentT = t - 0.065;
      sample +=
        0.25 * Math.sin(2 * Math.PI * 1760 * accentT) * Math.exp(-accentT / 0.06);
    }

    const attack = Math.min(1, t / 0.0025);
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
  const playerRef = useRef<AudioPlayer | null>(null);

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

    const player = createAudioPlayer({ uri });
    player.volume = EFFECT_VOLUME;
    playerRef.current = player;

    return () => {
      playerRef.current = null;
      player.remove();
    };
  }, [uri]);

  return useCallback(() => {
    const player = playerRef.current;
    if (player === null) return;

    void player.seekTo(0);
    player.play();
  }, []);
}
