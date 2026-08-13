export type GamePhase = 'menu' | 'playing' | 'gameover';

export interface HighScore {
  score: number;
  coins: number;
  date: number;
}
