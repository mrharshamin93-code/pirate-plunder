/**
 * Game constants and worklet-safe helpers.
 *
 * The whole simulation runs on the UI thread (Reanimated worklets), so every
 * helper in this file carries the 'worklet' directive and must stay free of
 * JS-thread-only APIs.
 */
export const GAME = {
  subRadius: 16,
  monsterRadius: 26,
  dubloonRadius: 11,
  mineRadius: 14,
  /** sub speed in px/sec at full joystick deflection */
  subDirSpeed: 240,
  /** base monster chase speed in px/sec */
  monsterBaseSpeed: 70,
  /** monster speed added per second survived */
  monsterRamp: 3.2,
  /** cap on monster speed */
  monsterMaxSpeed: 260,
  /** how many dubloons should be on screen at once */
  targetDubloons: 4,
  /** mines present at the start of a run */
  startMines: 3,
  /** hard cap on simultaneous mines (also the render pool size) */
  maxMines: 10,
  /** seconds between mine spawns */
  mineInterval: 6,
  /** extra mine drift speed added per second survived */
  mineSpeedRamp: 2,
  /** points per dubloon */
  dubloonScore: 25,
  /** survival points per second */
  survivalScore: 5,
} as const;

export interface Point {
  x: number;
  y: number;
}

/**
 * Random point inside the play area, kept at least `minDist` away from
 * (avoidX, avoidY) when possible.
 */
export function spawnPoint(
  w: number,
  h: number,
  pad: number,
  avoidX: number,
  avoidY: number,
  minDist: number,
): Point {
  'worklet';
  let x = pad;
  let y = pad;
  const minSq = minDist * minDist;
  for (let i = 0; i < 20; i += 1) {
    x = pad + Math.random() * Math.max(1, w - pad * 2);
    y = pad + Math.random() * Math.max(1, h - pad * 2);
    const dx = x - avoidX;
    const dy = y - avoidY;
    if (dx * dx + dy * dy >= minSq) break;
  }
  return { x, y };
}

/** Circle overlap test without a square root. */
export function circlesHit(
  ax: number,
  ay: number,
  ar: number,
  bx: number,
  by: number,
  br: number,
): boolean {
  'worklet';
  const dx = ax - bx;
  const dy = ay - by;
  const r = ar + br;
  return dx * dx + dy * dy < r * r;
}
