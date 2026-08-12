export type GamePhase = 'menu' | 'playing' | 'gameover';

export interface HighScore {
  score: number;
  dubloons: number;
  date: number;
}
