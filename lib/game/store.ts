import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';

import type { GamePhase, HighScore } from './types';

const STORAGE_KEY = 'piratesplunder.highscores.v2';
const MUSIC_KEY = 'piratesplunder.music.muted.v1';
const MAX_SCORES = 5;

interface GameStore {
  phase: GamePhase;
  lastScore: number;
  lastCoins: number;
  highScores: HighScore[];
  loaded: boolean;
  musicMuted: boolean;
  loadScores: () => Promise<void>;
  startGame: () => void;
  endGame: (score: number, coins: number) => Promise<void>;
  goToMenu: () => void;
  toggleMusic: () => void;
}

function sortScores(scores: HighScore[]): HighScore[] {
  return [...scores].sort((a, b) => b.score - a.score).slice(0, MAX_SCORES);
}

function hasNumberProp(obj: object, key: string): boolean {
  const descriptor = Object.getOwnPropertyDescriptor(obj, key);
  return descriptor !== undefined && typeof descriptor.value === 'number';
}

function isHighScoreArray(value: unknown): value is HighScore[] {
  if (!Array.isArray(value)) return false;
  return value.every((item: unknown) => {
    if (typeof item !== 'object' || item === null) return false;
    return (
      hasNumberProp(item, 'score') && hasNumberProp(item, 'coins') && hasNumberProp(item, 'date')
    );
  });
}

export const useGameStore = create<GameStore>((set, get) => ({
  phase: 'menu',
  lastScore: 0,
  lastCoins: 0,
  highScores: [],
  loaded: false,
  musicMuted: false,

  loadScores: async () => {
    try {
      const [raw, muted] = await Promise.all([
        AsyncStorage.getItem(STORAGE_KEY),
        AsyncStorage.getItem(MUSIC_KEY),
      ]);
      const json: unknown = raw ? JSON.parse(raw) : [];
      const parsed = isHighScoreArray(json) ? json : [];
      set({ highScores: sortScores(parsed), loaded: true, musicMuted: muted === '1' });
    } catch {
      set({ highScores: [], loaded: true });
    }
  },

  startGame: () => set({ phase: 'playing', lastScore: 0, lastCoins: 0 }),

  endGame: async (score, coins) => {
    const entry: HighScore = { score, coins, date: Date.now() };
    const next = sortScores([...get().highScores, entry]);
    set({ phase: 'gameover', lastScore: score, lastCoins: coins, highScores: next });
    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    } catch {
      // ignore persistence failure; scores remain in-memory
    }
  },

  goToMenu: () => set({ phase: 'menu' }),

  toggleMusic: () => {
    const muted = !get().musicMuted;
    set({ musicMuted: muted });
    void AsyncStorage.setItem(MUSIC_KEY, muted ? '1' : '0').catch(() => {
      // ignore persistence failure; the choice still holds for this session
    });
  },
}));

export function isNewBest(score: number, scores: HighScore[]): boolean {
  if (score <= 0) return false;
  const best = scores.length > 0 ? Math.max(...scores.map((s) => s.score)) : 0;
  return score >= best;
}
