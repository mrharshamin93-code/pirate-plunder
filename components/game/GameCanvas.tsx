import { memo, useCallback, useMemo } from 'react';
import { Platform, View } from 'react-native';
import { Gesture } from 'react-native-gesture-handler';
import Animated, {
  makeMutable,
  runOnJS,
  useAnimatedStyle,
  useFrameCallback,
  useSharedValue,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';

import { Joystick, JOYSTICK, type JoystickInput } from '@/components/game/Joystick';
import {
  BoatArt,
  CoinArt,
  ExplosionArt,
  MineArt,
  SPRITE_BOX,
  WhirlpoolArt,
} from '@/components/game/Sprites';
import {
  angleDelta,
  circlesHit,
  COIN_TIER_COUNT,
  GAME,
  pickCoinTier,
  spawnPoint,
  TIER_POINTS,
} from '@/lib/game/engine';

/**
 * Rendering strategy
 * ------------------
 * The simulation runs entirely inside a single Reanimated frame worklet on the
 * UI thread. Entities live in fixed-size pools of shared values allocated once,
 * and each sprite is a static svg inside an Animated.View whose transform is
 * driven from those shared values. React therefore performs ZERO work per
 * frame — the JS thread is only touched to report the score (~8x/sec), to fire
 * haptics, and to end the run.
 */

/** Screen insets that carve the arena out of the full-bleed ocean. */
const FIELD_INSET = { top: 106, bottom: 158, side: 8 } as const;

/** how often live stats are pushed to the HUD, in seconds */
const STATS_INTERVAL = 0.12;

const TIER_INDEXES = Array.from({ length: COIN_TIER_COUNT }, (_, i) => i);

interface MineEntity {
  /** stable identity of this pool slot, for use as a React list key */
  id: number;
  x: SharedValue<number>;
  y: SharedValue<number>;
  /** seconds of arming left — an arming mine cannot kill the boat yet */
  arm: SharedValue<number>;
  /** bob/roll animation phase */
  phase: SharedValue<number>;
  /** 1 = in play, 0 = free slot */
  active: SharedValue<number>;
}

interface BlastEntity {
  id: number;
  x: SharedValue<number>;
  y: SharedValue<number>;
  /** seconds since the blast started */
  t: SharedValue<number>;
  active: SharedValue<number>;
}

/** Monotonic ids so pool slots never share a React key. */
let poolIdCounter = 0;

function nextPoolId(): number {
  poolIdCounter += 1;
  return poolIdCounter;
}

function useMinePool(count: number): MineEntity[] {
  return useMemo(
    () =>
      Array.from({ length: count }, () => ({
        id: nextPoolId(),
        x: makeMutable(0),
        y: makeMutable(0),
        arm: makeMutable(0),
        phase: makeMutable(0),
        active: makeMutable(0),
      })),
    [count],
  );
}

function useBlastPool(count: number): BlastEntity[] {
  return useMemo(
    () =>
      Array.from({ length: count }, () => ({
        id: nextPoolId(),
        x: makeMutable(0),
        y: makeMutable(0),
        t: makeMutable(0),
        active: makeMutable(0),
      })),
    [count],
  );
}

function haptic(kind: 'light' | 'medium' | 'heavy') {
  if (Platform.OS === 'web') return;
  if (kind === 'light') void Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  else if (kind === 'medium') void Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  else void Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
}

/**
 * The thumbstick: the direction and strength it is pushed in, plus the gesture
 * that writes to it. Created here so the component that owns the shared values
 * is also the only one that mutates them; the Joystick view only reads them.
 */
function useJoystickInput(): JoystickInput {
  const dirX = useSharedValue(1);
  const dirY = useSharedValue(0);
  const magnitude = useSharedValue(0);
  const knobX = useSharedValue(0);
  const knobY = useSharedValue(0);

  const gesture = useMemo(() => {
    const centre = JOYSTICK.base / 2;

    const apply = (px: number, py: number) => {
      'worklet';
      const dx = px - centre;
      const dy = py - centre;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < JOYSTICK.deadZone) {
        magnitude.value = 0;
        knobX.value = dx;
        knobY.value = dy;
        return;
      }

      dirX.value = dx / dist;
      dirY.value = dy / dist;
      magnitude.value = Math.min(1, dist / JOYSTICK.throw);
      const clamped = Math.min(dist, JOYSTICK.throw);
      knobX.value = (dx / dist) * clamped;
      knobY.value = (dy / dist) * clamped;
    };

    return (
      Gesture.Pan()
        // no activation threshold, so the first touch already steers
        .minDistance(0)
        .maxPointers(1)
        .onBegin((e) => {
          'worklet';
          apply(e.x, e.y);
        })
        .onUpdate((e) => {
          'worklet';
          apply(e.x, e.y);
        })
        .onFinalize(() => {
          'worklet';
          magnitude.value = 0;
          knobX.value = withTiming(0, { duration: 140 });
          knobY.value = withTiming(0, { duration: 140 });
        })
    );
  }, [dirX, dirY, magnitude, knobX, knobY]);

  return useMemo(
    () => ({ dirX, dirY, magnitude, knobX, knobY, gesture }),
    [dirX, dirY, magnitude, knobX, knobY, gesture],
  );
}

export interface GameStats {
  score: number;
  coins: number;
  mines: number;
}

interface GameCanvasProps {
  width: number;
  height: number;
  onGameOver: (score: number, coins: number) => void;
  onStats: (stats: GameStats) => void;
  onPickup: (points: number, x: number, y: number) => void;
}

export const GameCanvas = memo(function GameCanvas({
  width,
  height,
  onGameOver,
  onStats,
  onPickup,
}: GameCanvasProps) {
  const mines = useMinePool(GAME.maxMines);
  const blasts = useBlastPool(GAME.explosionPool);

  const left = FIELD_INSET.side;
  const top = FIELD_INSET.top;
  const right = width - FIELD_INSET.side;
  const bottom = height - FIELD_INSET.bottom;

  const boatX = useSharedValue((left + right) / 2);
  const boatY = useSharedValue((top + bottom) / 2);
  const boatAngle = useSharedValue(-Math.PI / 2);
  const boatVX = useSharedValue(0);
  const boatVY = useSharedValue(0);

  const stick = useJoystickInput();

  const coinX = useSharedValue(0);
  const coinY = useSharedValue(0);
  const coinTier = useSharedValue(0);
  const coinPhase = useSharedValue(0);
  const coinActive = useSharedValue(0);

  const whirlX = useSharedValue(0);
  const whirlY = useSharedValue(0);
  const whirlLife = useSharedValue(0);
  const whirlSpin = useSharedValue(0);
  const whirlActive = useSharedValue(0);

  const score = useSharedValue(0);
  const collected = useSharedValue(0);
  const statsTimer = useSharedValue(0);
  const started = useSharedValue(0);
  const over = useSharedValue(0);
  /** seconds since the boat went down, used to hold the sinking beat */
  const deathTimer = useSharedValue(0);
  const reported = useSharedValue(0);
  const boatAlive = useSharedValue(1);

  const finishRun = useCallback(
    (finalScore: number, finalCoins: number) => {
      onGameOver(finalScore, finalCoins);
    },
    [onGameOver],
  );

  /** Puts the next coin on the water, well clear of the boat. */
  const placeCoin = useCallback(() => {
    'worklet';
    const p = spawnPoint(
      left + 28,
      top + 28,
      right - 28,
      bottom - 28,
      boatX.value,
      boatY.value,
      GAME.coinMinDistance,
    );
    coinX.value = p.x;
    coinY.value = p.y;
    coinTier.value = pickCoinTier();
    coinActive.value = 1;
  }, [left, top, right, bottom, boatX, boatY, coinX, coinY, coinTier, coinActive]);

  /**
   * Fires one more mine from the Pawkeet. Landing spots are near-random, just
   * as in the original, so a mine really can drop next to you — but it spends
   * `mineArmTime` arming, which is the window the original lets you skim over.
   */
  const fireMine = useCallback(() => {
    'worklet';
    for (let i = 0; i < mines.length; i += 1) {
      const m = mines[i];
      if (m.active.value === 1) continue;
      const p = spawnPoint(
        left + 24,
        top + 24,
        right - 24,
        bottom - 24,
        boatX.value,
        boatY.value,
        46,
      );
      m.x.value = p.x;
      m.y.value = p.y;
      m.arm.value = GAME.mineArmTime;
      m.phase.value = Math.random() * Math.PI * 2;
      m.active.value = 1;
      return;
    }
  }, [mines, left, top, right, bottom, boatX, boatY]);

  const openWhirlpool = useCallback(() => {
    'worklet';
    const p = spawnPoint(
      left + 40,
      top + 40,
      right - 40,
      bottom - 40,
      boatX.value,
      boatY.value,
      GAME.whirlpoolMinDistance,
    );
    whirlX.value = p.x;
    whirlY.value = p.y;
    whirlLife.value = GAME.whirlpoolLife;
    whirlSpin.value = 0;
    whirlActive.value = 1;
  }, [left, top, right, bottom, boatX, boatY, whirlX, whirlY, whirlLife, whirlSpin, whirlActive]);

  const blast = useCallback(
    (x: number, y: number) => {
      'worklet';
      for (let i = 0; i < blasts.length; i += 1) {
        const b = blasts[i];
        if (b.active.value === 1) continue;
        b.x.value = x;
        b.y.value = y;
        b.t.value = 0;
        b.active.value = 1;
        return;
      }
    },
    [blasts],
  );

  useFrameCallback((info) => {
    'worklet';
    const frameDt = Math.min((info.timeSincePreviousFrame ?? 16) / 1000, 0.05);

    // The boat has gone down: hold on the wreck for a beat so the blast reads,
    // then hand the run over to the game-over screen.
    if (over.value === 1) {
      deathTimer.value += frameDt;
      for (let i = 0; i < blasts.length; i += 1) {
        const b = blasts[i];
        if (b.active.value === 0) continue;
        b.t.value += frameDt;
        if (b.t.value >= GAME.explosionLife) b.active.value = 0;
      }
      if (deathTimer.value > 0.7 && reported.value === 0) {
        reported.value = 1;
        runOnJS(finishRun)(Math.floor(score.value), collected.value);
      }
      return;
    }

    if (started.value === 0) {
      started.value = 1;
      boatX.value = (left + right) / 2;
      boatY.value = (top + bottom) / 2;
      boatAngle.value = -Math.PI / 2;
      boatVX.value = 0;
      boatVY.value = 0;
      boatAlive.value = 1;
      // the original opens with a single coin and no mines at all
      placeCoin();
      return;
    }

    const dt = frameDt;
    const r = GAME.boatRadius;

    /* --- the boat: rotate, thrust, drift, drag --------------------------- */
    let vx = boatVX.value;
    let vy = boatVY.value;
    const speed = Math.sqrt(vx * vx + vy * vy);
    const speedFrac = Math.min(1, speed / GAME.maxSpeed);

    const turn = stick.magnitude.value;
    if (turn > 0) {
      // she heads where the stick points, swinging the short way round; the
      // faster she runs, the wider that swing is
      const target = Math.atan2(stick.dirY.value, stick.dirX.value);
      const diff = angleDelta(boatAngle.value, target);
      const rate = GAME.turnRate * (1 - GAME.turnAtSpeed * speedFrac) * dt;
      boatAngle.value += Math.abs(diff) <= rate ? diff : Math.sign(diff) * rate;
    }

    const heading = boatAngle.value;
    if (turn > 0) {
      // rowing effort follows how far the stick is pushed
      vx += Math.cos(heading) * GAME.thrust * turn * dt;
      vy += Math.sin(heading) * GAME.thrust * turn * dt;
    }

    let caughtInEye = false;
    let suckX = 0;
    let suckY = 0;
    if (whirlActive.value === 1) {
      const wx = whirlX.value - boatX.value;
      const wy = whirlY.value - boatY.value;
      const wd = Math.sqrt(wx * wx + wy * wy);
      if (wd < GAME.whirlpoolCore) caughtInEye = true;
      else if (wd < GAME.whirlpoolRange) {
        const pull = (1 - wd / GAME.whirlpoolRange) * GAME.whirlpoolPull * dt;
        suckX = (wx / wd) * pull + (-wy / wd) * pull * 0.45;
        suckY = (wy / wd) * pull + (wx / wd) * pull * 0.45;
      }
    }

    const damp = Math.exp(-GAME.drag * dt);
    const grip = Math.exp(-GAME.lateralGrip * dt);
    // Split her way into "along the bow" and "sideways", then bleed the
    // sideways part off hard — that is the keel, and it kills the skating.
    const fx = Math.cos(heading);
    const fy = Math.sin(heading);
    const along = vx * fx + vy * fy;
    const sideX = vx - along * fx;
    const sideY = vy - along * fy;
    vx = along * damp * fx + sideX * grip;
    vy = along * damp * fy + sideY * grip;

    // the vortex drags the whole hull, so it is added after the keel damping —
    // otherwise the grip would simply cancel it out
    vx += suckX;
    vy += suckY;

    const newSpeed = Math.sqrt(vx * vx + vy * vy);
    if (newSpeed > GAME.maxSpeed) {
      vx = (vx / newSpeed) * GAME.maxSpeed;
      vy = (vy / newSpeed) * GAME.maxSpeed;
    }

    let bx = boatX.value + vx * dt;
    let by = boatY.value + vy * dt;
    if (bx < left + r) {
      bx = left + r;
      if (vx < 0) vx = 0;
    } else if (bx > right - r) {
      bx = right - r;
      if (vx > 0) vx = 0;
    }
    if (by < top + r) {
      by = top + r;
      if (vy < 0) vy = 0;
    } else if (by > bottom - r) {
      by = bottom - r;
      if (vy > 0) vy = 0;
    }
    boatX.value = bx;
    boatY.value = by;
    boatVX.value = vx;
    boatVY.value = vy;

    /* --- mines: home in, explode on each other, get swallowed ----------- */
    const mineR = GAME.mineRadius;
    let dead = caughtInEye;
    let liveMines = 0;

    for (let i = 0; i < mines.length; i += 1) {
      const m = mines[i];
      if (m.active.value === 0) continue;

      if (m.arm.value > 0) m.arm.value = Math.max(0, m.arm.value - dt);
      m.phase.value += dt * 2.4;

      let mx = m.x.value;
      let my = m.y.value;

      // whirlpools drag mines in far harder than the boat, and destroy them
      let dragX = 0;
      let dragY = 0;
      if (whirlActive.value === 1) {
        const wx = whirlX.value - mx;
        const wy = whirlY.value - my;
        const wd = Math.sqrt(wx * wx + wy * wy);
        if (wd < GAME.whirlpoolCore + GAME.mineRadius * 0.5) {
          m.active.value = 0;
          blast(mx, my);
          continue;
        }
        if (wd < GAME.whirlpoolRange) {
          const pull =
            (1 - wd / GAME.whirlpoolRange) * GAME.whirlpoolPull * GAME.whirlpoolMinePull * 0.35;
          dragX = (wx / wd) * pull + (-wy / wd) * pull * 0.6;
          dragY = (wy / wd) * pull + (wx / wd) * pull * 0.6;
        }
      }

      const tx = bx - mx;
      const ty = by - my;
      const td = Math.max(0.0001, Math.sqrt(tx * tx + ty * ty));
      // a mine that senses the boat nearby surges after it
      const chase = td < GAME.mineAlertRange ? GAME.mineAlertSpeed : GAME.mineSpeed;
      const headX = tx / td;
      const headY = ty / td;
      // each mine weaves on its own phase, so their paths cross and they can
      // run into each other instead of trailing the boat in a neat column
      const weave = Math.sin(m.phase.value * 0.55) * GAME.mineWander;
      mx += ((headX - headY * weave) * chase + dragX) * dt;
      my += ((headY + headX * weave) * chase + dragY) * dt;

      m.x.value = Math.max(left + mineR, Math.min(right - mineR, mx));
      m.y.value = Math.max(top + mineR, Math.min(bottom - mineR, my));
      liveMines += 1;

      if (
        !dead &&
        m.arm.value <= 0 &&
        circlesHit(bx, by, r * 0.8, m.x.value, m.y.value, mineR * 0.85)
      ) {
        dead = true;
      }
    }

    // two mines that touch each other both go up and leave the water
    for (let i = 0; i < mines.length; i += 1) {
      const a = mines[i];
      if (a.active.value === 0) continue;
      for (let j = i + 1; j < mines.length; j += 1) {
        const b = mines[j];
        if (b.active.value === 0) continue;
        // spike tips: they blow the moment the drawn spikes actually touch
        if (
          circlesHit(
            a.x.value,
            a.y.value,
            GAME.mineSpikeRadius,
            b.x.value,
            b.y.value,
            GAME.mineSpikeRadius,
          )
        ) {
          blast(a.x.value, a.y.value);
          blast(b.x.value, b.y.value);
          a.active.value = 0;
          b.active.value = 0;
          liveMines -= 2;
          runOnJS(haptic)('medium');
          break;
        }
      }
    }

    /* --- the coin ---------------------------------------------------- */
    coinPhase.value += dt * 3;
    if (
      coinActive.value === 1 &&
      circlesHit(bx, by, r, coinX.value, coinY.value, GAME.coinRadius)
    ) {
      const points = TIER_POINTS[coinTier.value];
      score.value += points;
      collected.value += 1;
      runOnJS(onPickup)(points, coinX.value, coinY.value);
      runOnJS(haptic)('light');

      placeCoin();
      // every coin salvaged means one more mine in the water
      if (liveMines < GAME.maxMines) {
        fireMine();
        liveMines += 1;
      }
      if (whirlActive.value === 0 && Math.random() < GAME.whirlpoolChance) openWhirlpool();
    }

    /* --- timers --------------------------------------------------------- */
    if (whirlActive.value === 1) {
      whirlSpin.value += dt * 1.5;
      whirlLife.value -= dt;
      if (whirlLife.value <= 0) whirlActive.value = 0;
    }

    for (let i = 0; i < blasts.length; i += 1) {
      const b = blasts[i];
      if (b.active.value === 0) continue;
      b.t.value += dt;
      if (b.t.value >= GAME.explosionLife) b.active.value = 0;
    }

    statsTimer.value += dt;
    if (statsTimer.value > STATS_INTERVAL) {
      statsTimer.value = 0;
      runOnJS(onStats)({
        score: Math.floor(score.value),
        coins: collected.value,
        mines: liveMines,
      });
    }

    if (dead) {
      over.value = 1;
      deathTimer.value = 0;
      boatAlive.value = 0;
      coinActive.value = 0;
      blast(bx, by);
      runOnJS(haptic)('heavy');
      runOnJS(onStats)({
        score: Math.floor(score.value),
        coins: collected.value,
        mines: liveMines,
      });
    }
  });

  return (
    <View style={{ width, height, overflow: 'hidden' }}>
      {/* arena bounds */}
      <View
        pointerEvents="none"
        style={{
          position: 'absolute',
          left,
          top,
          width: Math.max(0, right - left),
          height: Math.max(0, bottom - top),
          borderRadius: 18,
          borderWidth: 2,
          borderColor: 'rgba(217,244,251,0.18)',
        }}
      />

      <WhirlpoolView x={whirlX} y={whirlY} life={whirlLife} spin={whirlSpin} active={whirlActive} />

      <CoinView x={coinX} y={coinY} tier={coinTier} phase={coinPhase} active={coinActive} />

      {mines.map((m) => (
        <MineView key={m.id} entity={m} />
      ))}

      <BoatView x={boatX} y={boatY} angle={boatAngle} alive={boatAlive} />

      {blasts.map((b) => (
        <BlastView key={b.id} entity={b} />
      ))}

      <Joystick input={stick} />
    </View>
  );
});

/** Absolute box that a sprite's static svg is drawn into. */
function spriteBox(size: number) {
  return {
    position: 'absolute' as const,
    left: 0,
    top: 0,
    width: size,
    height: size,
  };
}

const BoatView = memo(function BoatView({
  x,
  y,
  angle,
  alive,
}: {
  x: SharedValue<number>;
  y: SharedValue<number>;
  angle: SharedValue<number>;
  alive: SharedValue<number>;
}) {
  const half = SPRITE_BOX.boat / 2;
  const style = useAnimatedStyle(() => ({
    opacity: alive.value,
    transform: [
      { translateX: x.value - half },
      { translateY: y.value - half },
      { rotate: `${angle.value}rad` },
      // the hull is drawn at half scale, about the sprite's own centre
      { scale: GAME.boatScale },
    ],
  }));
  return (
    <Animated.View pointerEvents="none" style={[spriteBox(SPRITE_BOX.boat), style]}>
      <BoatArt />
    </Animated.View>
  );
});

/**
 * All seven denominations are mounted at once and cross-faded by index, so the
 * coin's face value can change on the UI thread without a React render.
 */
const CoinView = memo(function CoinView({
  x,
  y,
  tier,
  phase,
  active,
}: {
  x: SharedValue<number>;
  y: SharedValue<number>;
  tier: SharedValue<number>;
  phase: SharedValue<number>;
  active: SharedValue<number>;
}) {
  const half = SPRITE_BOX.coin / 2;
  const style = useAnimatedStyle(() => ({
    opacity: active.value,
    transform: [
      { translateX: x.value - half },
      { translateY: y.value - half },
      { scale: 1 + 0.08 * Math.sin(phase.value) },
    ],
  }));
  return (
    <Animated.View pointerEvents="none" style={[spriteBox(SPRITE_BOX.coin), style]}>
      {TIER_INDEXES.map((index) => (
        <CoinFace key={index} index={index} tier={tier} />
      ))}
    </Animated.View>
  );
});

const CoinFace = memo(function CoinFace({
  index,
  tier,
}: {
  index: number;
  tier: SharedValue<number>;
}) {
  const style = useAnimatedStyle(() => ({ opacity: tier.value === index ? 1 : 0 }));
  return (
    <Animated.View style={[{ position: 'absolute', left: 0, top: 0 }, style]}>
      <CoinArt tier={index} />
    </Animated.View>
  );
});

const MineView = memo(function MineView({ entity }: { entity: MineEntity }) {
  const half = SPRITE_BOX.mine / 2;
  const style = useAnimatedStyle(() => {
    // an arming mine drops in: small and faded until it goes live
    const armFrac = entity.arm.value / GAME.mineArmTime;
    const live = 1 - Math.max(0, Math.min(1, armFrac));
    return {
      opacity: entity.active.value * (0.3 + 0.7 * live),
      transform: [
        { translateX: entity.x.value - half },
        { translateY: entity.y.value - half },
        {
          scale: GAME.mineScale * (0.55 + 0.45 * live) * (1 + 0.05 * Math.sin(entity.phase.value)),
        },
        { rotate: `${Math.sin(entity.phase.value * 0.6) * 0.15}rad` },
      ],
    };
  });
  return (
    <Animated.View pointerEvents="none" style={[spriteBox(SPRITE_BOX.mine), style]}>
      <MineArt />
    </Animated.View>
  );
});

const WhirlpoolView = memo(function WhirlpoolView({
  x,
  y,
  life,
  spin,
  active,
}: {
  x: SharedValue<number>;
  y: SharedValue<number>;
  life: SharedValue<number>;
  spin: SharedValue<number>;
  active: SharedValue<number>;
}) {
  const half = SPRITE_BOX.whirlpool / 2;
  const style = useAnimatedStyle(() => {
    const age = GAME.whirlpoolLife - life.value;
    const rising = Math.max(0, Math.min(1, age / 0.5));
    const fading = Math.max(0, Math.min(1, life.value / 1.2));
    return {
      opacity: active.value * rising * fading,
      transform: [
        { translateX: x.value - half },
        { translateY: y.value - half },
        { rotate: `${spin.value}rad` },
        { scale: 0.6 + 0.4 * rising },
      ],
    };
  });
  return (
    <Animated.View pointerEvents="none" style={[spriteBox(SPRITE_BOX.whirlpool), style]}>
      <WhirlpoolArt />
    </Animated.View>
  );
});

const BlastView = memo(function BlastView({ entity }: { entity: BlastEntity }) {
  const half = SPRITE_BOX.explosion / 2;
  const style = useAnimatedStyle(() => {
    const p = Math.max(0, Math.min(1, entity.t.value / GAME.explosionLife));
    return {
      opacity: entity.active.value * (1 - p),
      transform: [
        { translateX: entity.x.value - half },
        { translateY: entity.y.value - half },
        { scale: 0.35 + p * 1.05 },
      ],
    };
  });
  return (
    <Animated.View pointerEvents="none" style={[spriteBox(SPRITE_BOX.explosion), style]}>
      <ExplosionArt />
    </Animated.View>
  );
});
