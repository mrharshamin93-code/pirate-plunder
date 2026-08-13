/**
 * Background music — a procedurally synthesised sea shanty.
 *
 * The game ships no audio files. This module renders a seamless 8-bar loop to
 * 16-bit mono PCM in plain JS the first time it is needed and wraps it in a WAV
 * container, which expo-audio then plays on repeat. That keeps the bundle small,
 * works offline on every platform, and keeps the tune in the same key as the
 * rest of the game's tone.
 *
 * The tune is in D minor, 6/8, at a steady rowing tempo: a lead fiddle line, a
 * plucked bass, staccato accordion chords and a hand drum on the lilt.
 */

const SAMPLE_RATE = 16_000;
/** seconds per eighth note */
const EIGHTH = 0.275;
const EIGHTHS_PER_BAR = 6;
const BARS = 8;
const TOTAL_EIGHTHS = BARS * EIGHTHS_PER_BAR;
const LOOP_SAMPLES = Math.round(TOTAL_EIGHTHS * EIGHTH * SAMPLE_RATE);

/** A single note: MIDI number (0 = rest) and a length in eighth notes. */
type Step = readonly [midi: number, eighths: number];

/** Lead line — bars of 6 eighths each, i - i - iv - iv - VI - V - i - V. */
const MELODY: readonly Step[] = [
  [62, 2],
  [65, 1],
  [69, 2],
  [65, 1],

  [67, 2],
  [65, 1],
  [62, 3],

  [70, 2],
  [69, 1],
  [67, 2],
  [62, 1],

  [67, 2],
  [62, 1],
  [65, 3],

  [74, 2],
  [72, 1],
  [70, 2],
  [69, 1],

  [69, 2],
  [73, 1],
  [69, 3],

  [72, 2],
  [70, 1],
  [69, 2],
  [65, 1],

  [64, 2],
  [61, 1],
  [62, 3],
];


/** A bright whistle response that answers the fiddle every other bar. */
const COUNTER_MELODY: readonly Step[] = [
  [0, 6],
  [74, 3],
  [72, 3],
  [0, 6],
  [70, 3],
  [69, 3],
  [0, 6],
  [77, 2],
  [76, 1],
  [73, 3],
  [0, 6],
  [69, 3],
  [0, 3],
];

/** Bass — root then fifth, half a bar each. */
const BASS: readonly Step[] = [
  [38, 3],
  [45, 3],
  [38, 3],
  [45, 3],
  [43, 3],
  [50, 3],
  [43, 3],
  [50, 3],
  [46, 3],
  [53, 3],
  [45, 3],
  [52, 3],
  [38, 3],
  [45, 3],
  [45, 3],
  [45, 3],
];

/** One triad per bar, strummed on the two strong eighths. */
const CHORDS: readonly (readonly number[])[] = [
  [50, 53, 57],
  [50, 53, 57],
  [50, 55, 58],
  [50, 55, 58],
  [53, 58, 62],
  [52, 57, 61],
  [50, 53, 57],
  [52, 57, 61],
];

function midiToFreq(midi: number): number {
  return 440 * Math.pow(2, (midi - 69) / 12);
}

function triangle(phase: number): number {
  const x = phase - Math.floor(phase);
  return 4 * Math.abs(x - 0.5) - 1;
}

function square(phase: number, duty: number): number {
  const x = phase - Math.floor(phase);
  return x < duty ? 1 : -1;
}

interface ToneOptions {
  gain: number;
  /** 0 = pure triangle, 1 = pure square */
  edge: number;
  duty: number;
  /** fraction of the step that actually sounds, the rest is silence */
  gate: number;
  /** depth of a 5.5 Hz pitch wobble, as a fraction of the frequency */
  vibrato: number;
  /** seconds of fade-in */
  attack: number;
  /** seconds of fade-out at the tail */
  release: number;
  /** how far the level falls from attack to the end of the note */
  decay: number;
}

/**
 * Adds one note into the loop buffer. Indices wrap, so a note that overruns the
 * final bar bleeds into the top of the loop instead of clicking.
 */
function addTone(
  out: Float32Array,
  startSec: number,
  durSec: number,
  freq: number,
  opts: ToneOptions,
): void {
  const startIndex = Math.round(startSec * SAMPLE_RATE);
  const length = Math.max(1, Math.round(durSec * opts.gate * SAMPLE_RATE));
  const attack = Math.max(1, Math.min(opts.attack * SAMPLE_RATE, length * 0.4));
  const release = Math.max(1, Math.min(opts.release * SAMPLE_RATE, length * 0.6));

  let phase = 0;
  for (let i = 0; i < length; i += 1) {
    const t = i / SAMPLE_RATE;
    const wobble = 1 + opts.vibrato * Math.sin(t * Math.PI * 2 * 5.5);
    phase += (freq * wobble) / SAMPLE_RATE;

    const wave = triangle(phase) * (1 - opts.edge) + square(phase, opts.duty) * opts.edge;

    let env = 1 - opts.decay * (i / length);
    if (i < attack) env *= i / attack;
    else if (i > length - release) env *= (length - i) / release;

    out[(startIndex + i) % out.length] += wave * opts.gain * env;
  }
}

/** Hand drum: a short noise slap over a decaying low thud. */
function addDrum(out: Float32Array, startSec: number, gain: number, noise: () => number): void {
  const startIndex = Math.round(startSec * SAMPLE_RATE);
  const length = Math.round(0.16 * SAMPLE_RATE);
  let filtered = 0;
  for (let i = 0; i < length; i += 1) {
    const t = i / SAMPLE_RATE;
    filtered += (noise() - filtered) * 0.35;
    const slap = filtered * Math.exp(-t * 42);
    const thud = Math.sin(t * Math.PI * 2 * 84) * Math.exp(-t * 16);
    out[(startIndex + i) % out.length] += (slap * 0.7 + thud) * gain;
  }
}

/** Deterministic noise, so the track is bit-identical on every launch. */
function makeNoise(seed: number): () => number {
  let state = seed;
  return () => {
    state = (state * 1664525 + 1013904223) % 4294967296;
    return state / 2147483648 - 1;
  };
}

const LEAD: ToneOptions = {
  gain: 0.2,
  edge: 0.25,
  duty: 0.35,
  gate: 0.92,
  vibrato: 0.005,
  attack: 0.02,
  release: 0.07,
  decay: 0.25,
};


const WHISTLE: ToneOptions = {
  gain: 0.085,
  edge: 0.06,
  duty: 0.5,
  gate: 0.88,
  vibrato: 0.009,
  attack: 0.035,
  release: 0.1,
  decay: 0.18,
};

const BASS_TONE: ToneOptions = {
  gain: 0.26,
  edge: 0.1,
  duty: 0.5,
  gate: 0.8,
  vibrato: 0,
  attack: 0.008,
  release: 0.06,
  decay: 0.45,
};

const CHORD_TONE: ToneOptions = {
  gain: 0.055,
  edge: 0.5,
  duty: 0.3,
  gate: 0.42,
  vibrato: 0,
  attack: 0.01,
  release: 0.05,
  decay: 0.5,
};

function renderSteps(out: Float32Array, steps: readonly Step[], opts: ToneOptions): void {
  let position = 0;
  for (const [midi, eighths] of steps) {
    if (midi > 0) {
      addTone(out, position * EIGHTH, eighths * EIGHTH, midiToFreq(midi), opts);
    }
    position += eighths;
  }
}

function renderLoop(): Float32Array {
  const out = new Float32Array(LOOP_SAMPLES);
  const noise = makeNoise(20250813);

  renderSteps(out, MELODY, LEAD);
  renderSteps(out, COUNTER_MELODY, WHISTLE);
  renderSteps(out, BASS, BASS_TONE);

  for (let bar = 0; bar < BARS; bar += 1) {
    const chord = CHORDS[bar];
    const barStart = bar * EIGHTHS_PER_BAR;
    for (const offset of [0, 3]) {
      for (const midi of chord) {
        addTone(out, (barStart + offset) * EIGHTH, EIGHTH, midiToFreq(midi), CHORD_TONE);
      }
    }
    addDrum(out, barStart * EIGHTH, 0.2, noise);
    addDrum(out, (barStart + 3) * EIGHTH, 0.13, noise);
    for (const offset of [1, 2, 4, 5]) {
      addDrum(out, (barStart + offset) * EIGHTH, 0.045, noise);
    }
  }

  return out;
}

/** Renders the loop and wraps it in a 16-bit mono WAV container. */
export function buildMusicWav(): Uint8Array<ArrayBuffer> {
  const samples = renderLoop();
  const dataBytes = samples.length * 2;
  const bytes = new Uint8Array(44 + dataBytes);
  const view = new DataView(bytes.buffer);

  const ascii = (offset: number, text: string) => {
    for (let i = 0; i < text.length; i += 1) bytes[offset + i] = text.charCodeAt(i);
  };

  ascii(0, 'RIFF');
  view.setUint32(4, 36 + dataBytes, true);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true); // PCM
  view.setUint16(22, 1, true); // mono
  view.setUint32(24, SAMPLE_RATE, true);
  view.setUint32(28, SAMPLE_RATE * 2, true); // byte rate
  view.setUint16(32, 2, true); // block align
  view.setUint16(34, 16, true); // bits per sample
  ascii(36, 'data');
  view.setUint32(40, dataBytes, true);

  for (let i = 0; i < samples.length; i += 1) {
    // soft clip, so the mix stays warm rather than crunching on the peaks
    const value = Math.tanh(samples[i] * 1.25);
    view.setInt16(44 + i * 2, Math.round(value * 31_500), true);
  }

  return bytes;
}

/** Name of the cached file written on native platforms. */
export const MUSIC_FILE_NAME = 'pirates-plunder-shanty.wav';
