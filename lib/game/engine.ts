import type { Entity, Monster, Sub, Vec2 } from './types';

/** Tunable game constants. */
export const GAME = {
  subRadius: 16,
  monsterRadius: 26,
  dubloonRadius: 11,
  mineRadius: 14,
  /** how quickly the sub eases toward the finger target (0..1 per frame @60fps) */
  subFollow: 0.16,
  /** base monster chase speed in px/sec */
  monsterBaseSpeed: 70,
  /** monster speed added per second survived */
  monsterRamp: 3.2,
  /** cap on monster speed */
  monsterMaxSpeed: 260,
  maxDubloons: 7,
  maxMines: 10,
  /** points per dubloon */
  dubloonScore: 25,
  /** survival points per second */
  survivalScore: 5,
} as const;

export function dist(a: Vec2, b: Vec2): number {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return Math.sqrt(dx * dx + dy * dy);
}

/** Distance from center used to avoid spawning on top of the player. */
function farEnough(p: Vec2, from: Vec2, min: number): boolean {
  return dist(p, from) >= min;
}

let entityIdCounter = 1;

export function nextEntityId(): number {
  entityIdCounter += 1;
  return entityIdCounter;
}

function randomPointInBounds(w: number, h: number, pad: number): Vec2 {
  return {
    x: pad + Math.random() * (w - pad * 2),
    y: pad + Math.random() * (h - pad * 2),
  };
}

export function makeDubloon(w: number, h: number, avoid: Vec2): Entity {
  let p = randomPointInBounds(w, h, 40);
  let guard = 0;
  while (!farEnough(p, avoid, 90) && guard < 20) {
    p = randomPointInBounds(w, h, 40);
    guard += 1;
  }
  return {
    id: nextEntityId(),
    kind: 'dubloon',
    x: p.x,
    y: p.y,
    r: GAME.dubloonRadius,
    vx: 0,
    vy: 0,
    phase: Math.random() * Math.PI * 2,
    alive: true,
  };
}

export function makeMine(w: number, h: number, avoid: Vec2, speed: number): Entity {
  let p = randomPointInBounds(w, h, 30);
  let guard = 0;
  while (!farEnough(p, avoid, 130) && guard < 20) {
    p = randomPointInBounds(w, h, 30);
    guard += 1;
  }
  const dir = Math.random() * Math.PI * 2;
  const drift = speed * (0.25 + Math.random() * 0.35);
  return {
    id: nextEntityId(),
    kind: 'mine',
    x: p.x,
    y: p.y,
    r: GAME.mineRadius,
    vx: Math.cos(dir) * drift,
    vy: Math.sin(dir) * drift,
    phase: Math.random() * Math.PI * 2,
    alive: true,
  };
}

/** Ease a value toward a target by factor t, frame-rate normalized. */
export function damp(current: number, target: number, t: number, dt: number): number {
  const factor = 1 - Math.pow(1 - t, dt * 60);
  return current + (target - current) * factor;
}

export function moveSubToward(sub: Sub, target: Vec2, dt: number): void {
  const nx = damp(sub.x, target.x, GAME.subFollow, dt);
  const ny = damp(sub.y, target.y, GAME.subFollow, dt);
  const dx = nx - sub.x;
  const dy = ny - sub.y;
  if (Math.abs(dx) > 0.05 || Math.abs(dy) > 0.05) {
    sub.angle = Math.atan2(dy, dx);
  }
  sub.x = nx;
  sub.y = ny;
}

/** Monster chases the sub; speed scales with elapsed time. */
export function moveMonster(monster: Monster, sub: Sub, elapsed: number, dt: number): void {
  const speed = Math.min(GAME.monsterMaxSpeed, GAME.monsterBaseSpeed + elapsed * GAME.monsterRamp);
  const dx = sub.x - monster.x;
  const dy = sub.y - monster.y;
  const d = Math.max(0.0001, Math.sqrt(dx * dx + dy * dy));
  monster.x += (dx / d) * speed * dt;
  monster.y += (dy / d) * speed * dt;
  monster.angle = Math.atan2(dy, dx);
}

export function moveMine(mine: Entity, w: number, h: number, dt: number): void {
  mine.x += mine.vx * dt;
  mine.y += mine.vy * dt;
  // bounce off walls
  if (mine.x < mine.r) {
    mine.x = mine.r;
    mine.vx = Math.abs(mine.vx);
  } else if (mine.x > w - mine.r) {
    mine.x = w - mine.r;
    mine.vx = -Math.abs(mine.vx);
  }
  if (mine.y < mine.r) {
    mine.y = mine.r;
    mine.vy = Math.abs(mine.vy);
  } else if (mine.y > h - mine.r) {
    mine.y = h - mine.r;
    mine.vy = -Math.abs(mine.vy);
  }
}

export function circlesHit(a: Vec2, ar: number, b: Vec2, br: number): boolean {
  return dist(a, b) < ar + br;
}
