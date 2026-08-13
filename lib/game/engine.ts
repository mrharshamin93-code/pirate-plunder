/**
 * Pirate's Plunder — rules, constants and worklet-safe helpers.
 *
 * Faithful to the original Neopets game (g772):
 *  - You steer Dorak's boat with a thumbstick: she heads where the stick points
 *    and rows harder the further you push. She keeps a little momentum, but the
 *    keel bites, so she tracks her bow instead of skidding broadside.
 *  - Exactly ONE coin is on the water at a time. Denominations are worth
 *    5x their face value in points, and the valuable ones are rare.
 *  - Every coin collected fires one more homing mine from the Black Pawkeet,
 *    up to nine at once. Mines chase you and speed up when you get close.
 *  - Two mines that touch each other both explode.
 *  - Touching a mine ends the run.
 *  - Whirlpools appear now and then, drag the boat in and destroy any mine
 *    they swallow. The eye of the whirlpool is fatal.
 *
 * The whole simulation runs on the UI thread (Reanimated worklets), so every
 * helper here carries the 'worklet' directive and must stay free of
 * JS-thread-only APIs.
 */

export const GAME = {
  /* --- boat ------------------------------------------------------------- */
  boatRadius: 8,
  /** the boat sprite is drawn at half scale, matching the smaller hull */
  boatScale: 0.5,
  /** how fast the boat swings onto the stick heading, in radians/sec */
  turnRate: 9,
  /** turning is this much slower at full speed than at rest */
  turnAtSpeed: 0.28,
  /** forward thrust in px/sec^2 at full stick deflection */
  thrust: 620,
  /**
   * Drag along the hull's own heading, as an exponential decay coefficient per
   * second. Terminal speed is roughly thrust / drag.
   */
  drag: 3.6,
  /**
   * Drag on the SIDEWAYS part of her velocity — the keel biting the water.
   * Much higher than `drag`, so she follows her bow instead of skating
   * broadside through turns.
   */
  lateralGrip: 11,
  /** hard cap on boat speed in px/sec (drag settles her a little below this) */
  maxSpeed: 190,

  /* --- coins --------------------------------------------------------- */
  coinRadius: 13,
  /** a fresh coin never lands closer than this to the boat */
  coinMinDistance: 90,

  /* --- mines ------------------------------------------------------------ */
  /** collision radius — matched to the boat so a mine is the same size as her */
  mineRadius: 8,
  /**
   * How far the spike tips reach on the drawn sprite. Two mines detonate when
   * their spikes touch, not when the casings meet.
   */
  mineSpikeRadius: 11,
  /** the mine sprite is drawn at this scale, matching boatScale */
  mineScale: 0.5,
  /** hard cap on simultaneous mines, exactly as in the original */
  maxMines: 9,
  /** cruising chase speed in px/sec — always slower than the boat */
  mineSpeed: 58,
  /** chase speed once the boat is within mineAlertRange */
  mineAlertSpeed: 96,
  /** distance at which a mine senses the boat and accelerates */
  mineAlertRange: 130,
  /**
   * How much a mine weaves sideways as it chases, as a fraction of its speed.
   * Without this every mine tracks the boat on the same line and they never
   * meet; the weave makes their paths cross so they can take each other out.
   */
  mineWander: 0.42,
  /** seconds a freshly fired mine spends arming — it cannot kill you yet */
  mineArmTime: 0.55,

  /* --- whirlpools ------------------------------------------------------- */
  /** chance a coin pickup also summons a whirlpool */
  whirlpoolChance: 0.13,
  /** radius of influence in px */
  whirlpoolRange: 74,
  /** the eye — fatal to the boat, destroys mines */
  whirlpoolCore: 12,
  /** pull on the boat at the very centre, in px/sec^2 */
  whirlpoolPull: 260,
  /** mines are dragged in far harder than the boat */
  whirlpoolMinePull: 2.6,
  /** seconds a whirlpool lasts, including spin-up and fade */
  whirlpoolLife: 6.5,
  /** a whirlpool never opens closer than this to the boat */
  whirlpoolMinDistance: 110,

  /* --- explosions ------------------------------------------------------- */
  /** render pool size for mine explosions — a pair of mines uses two slots */
  explosionPool: 10,
  explosionLife: 0.45,
} as const;

/**
 * Coin denominations. `weight` is the relative spawn chance, so the two
 * coin coin turns up constantly and the two hundred is a jackpot.
 * Points are always five times the face value.
 */
export const COIN_TIERS = [
  { value: 2, points: 10, weight: 38 },
  { value: 5, points: 25, weight: 26 },
  { value: 10, points: 50, weight: 17 },
  { value: 20, points: 100, weight: 10 },
  { value: 50, points: 250, weight: 5 },
  { value: 100, points: 500, weight: 3 },
  { value: 200, points: 1000, weight: 1 },
] as const;

export const COIN_TIER_COUNT = COIN_TIERS.length;

/** Cumulative weights, precomputed so the worklet picker stays allocation free. */
const TIER_CUMULATIVE: number[] = (() => {
  const out: number[] = [];
  let total = 0;
  for (const tier of COIN_TIERS) {
    total += tier.weight;
    out.push(total);
  }
  return out;
})();

const TIER_TOTAL = TIER_CUMULATIVE[TIER_CUMULATIVE.length - 1];

/** Points awarded for a tier index, readable from a worklet. */
export const TIER_POINTS: number[] = COIN_TIERS.map((t) => t.points);

/** Weighted random denomination, returned as an index into COIN_TIERS. */
export function pickCoinTier(): number {
  'worklet';
  const roll = Math.random() * TIER_TOTAL;
  for (let i = 0; i < TIER_CUMULATIVE.length; i += 1) {
    if (roll < TIER_CUMULATIVE[i]) return i;
  }
  return 0;
}

export interface Point {
  x: number;
  y: number;
}

/**
 * Random point inside the rectangle, kept at least `minDist` away from
 * (avoidX, avoidY) when possible.
 */
export function spawnPoint(
  left: number,
  top: number,
  right: number,
  bottom: number,
  avoidX: number,
  avoidY: number,
  minDist: number,
): Point {
  'worklet';
  const w = Math.max(1, right - left);
  const h = Math.max(1, bottom - top);
  let x = left;
  let y = top;
  const minSq = minDist * minDist;
  for (let i = 0; i < 24; i += 1) {
    x = left + Math.random() * w;
    y = top + Math.random() * h;
    const dx = x - avoidX;
    const dy = y - avoidY;
    if (dx * dx + dy * dy >= minSq) break;
  }
  return { x, y };
}

/**
 * Shortest signed angle from `from` to `to`, wrapped into [-PI, PI], so the
 * boat always swings the short way round onto the stick heading.
 */
export function angleDelta(from: number, to: number): number {
  'worklet';
  let d = (to - from) % (Math.PI * 2);
  if (d > Math.PI) d -= Math.PI * 2;
  if (d < -Math.PI) d += Math.PI * 2;
  return d;
}

/** Circle overlap test without a square root. */ export function circlesHit(
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
