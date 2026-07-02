export type Vec2 = { x: number; y: number };

export type EntityKind = 'dubloon' | 'mine';

export interface Entity {
  id: number;
  kind: EntityKind;
  x: number;
  y: number;
  r: number;
  /** velocity for drifting mines; dubloons are static */
  vx: number;
  vy: number;
  /** small bob phase for animation */
  phase: number;
  alive: boolean;
}

export interface Monster {
  x: number;
  y: number;
  /** current heading angle in radians, used for smooth rotation */
  angle: number;
  r: number;
}

export interface Sub {
  x: number;
  y: number;
  /** rendered heading, eased toward movement direction */
  angle: number;
  r: number;
}

export type GamePhase = 'menu' | 'playing' | 'gameover';

export interface HighScore {
  score: number;
  dubloons: number;
  date: number;
}
