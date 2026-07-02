import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';

import type { GamePhase, HighScore } from './types';

const STORAGE_KEY = 'dubloon.highscores.v1';
const MAX_SCORES = 5;

interface GameStore {
  phase: GamePhase;
  lastScore: number;
  lastDubloons: number;
  highScores: HighScore[];
  loaded: boolean;
  loadScores: () => Promise<void>;
  startGame: () => void;
  endGame: (score: number, dubloons: number) => Promise<void>;
  goToMenu: () => void;
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
      hasNumberProp(item, 'score') && hasNumberProp(item, 'dubloons') && hasNumberProp(item, 'date')
    );
  });
}

export const useGameStore = create<GameStore>((set, get) => ({
  phase: 'menu',
  lastScore: 0,
  lastDubloons: 0,
  highScores: [],
  loaded: false,

  loadScores: async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      const json: unknown = raw ? JSON.parse(raw) : [];
      const parsed = isHighScoreArray(json) ? json : [];
      set({ highScores: sortScores(parsed), loaded: true });
    } catch {
      set({ highScores: [], loaded: true });
    }
  },

  startGame: () => set({ phase: 'playing', lastScore: 0, lastDubloons: 0 }),

  endGame: async (score, dubloons) => {
    const entry: HighScore = { score, dubloons, date: Date.now() };
    const next = sortScores([...get().highScores, entry]);
    set({ phase: 'gameover', lastScore: score, lastDubloons: dubloons, highScores: next });
    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    } catch {
      // ignore persistence failure; scores remain in-memory
    }
  },

  goToMenu: () => set({ phase: 'menu' }),
}));

export function isNewBest(score: number, scores: HighScore[]): boolean {
  if (score <= 0) return false;
  const best = scores.length > 0 ? Math.max(...scores.map((s) => s.score)) : 0;
  return score >= best;
}
