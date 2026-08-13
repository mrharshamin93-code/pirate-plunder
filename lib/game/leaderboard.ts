import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

const PLAYER_ID_KEY = 'piratesplunder.player.id.v1';
const PLAYER_NAME_KEY = 'piratesplunder.player.name.v1';
const API_ROOT =
  process.env.EXPO_PUBLIC_API_URL?.replace(/\/$/, '') ??
  (Platform.OS === 'web' ? '' : 'https://pirate-plunder.vercel.app');

export interface GlobalScore {
  name: string;
  score: number;
  coins: number;
  createdAt: string;
}

export interface LeaderboardResult {
  leaderboard: GlobalScore[];
  personalBest: number;
}

function createPlayerId(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (char) => {
    const random = Math.floor(Math.random() * 16);
    const value = char === 'x' ? random : (random & 0x3) | 0x8;
    return value.toString(16);
  });
}

async function getPlayerId(): Promise<string> {
  const saved = await AsyncStorage.getItem(PLAYER_ID_KEY);
  if (saved) return saved;
  const id = createPlayerId();
  await AsyncStorage.setItem(PLAYER_ID_KEY, id);
  return id;
}

async function parseResponse(response: Response): Promise<LeaderboardResult> {
  if (!response.ok) throw new Error('Leaderboard unavailable');
  const value: unknown = await response.json();
  if (typeof value !== 'object' || value === null) throw new Error('Invalid leaderboard response');
  const data = value as Record<string, unknown>;
  if (!Array.isArray(data.leaderboard) || typeof data.personalBest !== 'number') {
    throw new Error('Invalid leaderboard response');
  }
  return {
    leaderboard: data.leaderboard.filter((entry): entry is GlobalScore => {
      if (typeof entry !== 'object' || entry === null) return false;
      const score = entry as Record<string, unknown>;
      return (
        typeof score.name === 'string' &&
        typeof score.score === 'number' &&
        typeof score.coins === 'number' &&
        typeof score.createdAt === 'string'
      );
    }),
    personalBest: data.personalBest,
  };
}

export async function loadLeaderboard(): Promise<LeaderboardResult> {
  const playerId = await getPlayerId();
  const response = await fetch(`${API_ROOT}/api/leaderboard?playerId=${encodeURIComponent(playerId)}`);
  return parseResponse(response);
}

export async function submitGlobalScore(
  name: string,
  score: number,
  coins: number,
): Promise<LeaderboardResult> {
  const playerId = await getPlayerId();
  const cleanName = name.trim().slice(0, 20);
  await AsyncStorage.setItem(PLAYER_NAME_KEY, cleanName);
  const response = await fetch(`${API_ROOT}/api/leaderboard?playerId=${encodeURIComponent(playerId)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: cleanName, score, coins, playerId }),
  });
  return parseResponse(response);
}

export async function loadPlayerName(): Promise<string> {
  return (await AsyncStorage.getItem(PLAYER_NAME_KEY)) ?? '';
}
