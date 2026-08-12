import { memo, useCallback, useMemo } from 'react';
import { Platform, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  makeMutable,
  runOnJS,
  useAnimatedStyle,
  useFrameCallback,
  useSharedValue,
  type SharedValue,
} from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';

import { DubloonArt, MineArt, MonsterArt, SPRITE_BOX, SubArt } from '@/components/game/Sprites';
import { circlesHit, GAME, spawnPoint } from '@/lib/game/engine';

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

const DUBLOON_POOL = GAME.targetDubloons + 3;
const MINE_POOL = GAME.maxMines;
/** how often the live score is pushed to the HUD, in seconds */
const SCORE_REPORT_INTERVAL = 0.12;

interface PoolEntity {
  /** stable identity of this pool slot, for use as a React list key */
  id: number;
  x: SharedValue<number>;
  y: SharedValue<number>;
  vx: SharedValue<number>;
  vy: SharedValue<number>;
  /** animation phase: coin spin / mine pulse */
  phase: SharedValue<number>;
  /** 1 = in play, 0 = free slot */
  active: SharedValue<number>;
}

/** Monotonic ids so dubloon and mine pool slots never share a React key. */
let poolIdCounter = 0;

function nextPoolId(): number {
  poolIdCounter += 1;
  return poolIdCounter;
}

function useEntityPool(count: number): PoolEntity[] {
  return useMemo(
    () =>
      Array.from({ length: count }, () => ({
        id: nextPoolId(),
        x: makeMutable(0),
        y: makeMutable(0),
        vx: makeMutable(0),
        vy: makeMutable(0),
        phase: makeMutable(0),
        active: makeMutable(0),
      })),
    [count],
  );
}

function haptic(kind: 'light' | 'heavy') {
  if (Platform.OS === 'web') return;
  if (kind === 'light') void Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  else void Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
}

interface GameCanvasProps {
  width: number;
  height: number;
  onGameOver: (score: number, dubloons: number) => void;
  onScoreChange: (score: number) => void;
  onDubloonsChange: (count: number) => void;
}

export const GameCanvas = memo(function GameCanvas({
  width,
  height,
  onGameOver,
  onScoreChange,
  onDubloonsChange,
}: GameCanvasProps) {
  const dubloons = useEntityPool(DUBLOON_POOL);
  const mines = useEntityPool(MINE_POOL);

  const subX = useSharedValue(width / 2);
  const subY = useSharedValue(height / 2);
  const subAngle = useSharedValue(0);
  const monsterX = useSharedValue(40);
  const monsterY = useSharedValue(40);
  const monsterAngle = useSharedValue(0);

  const dirX = useSharedValue(0);
  const dirY = useSharedValue(0);

  const elapsed = useSharedValue(0);
  const score = useSharedValue(0);
  const coins = useSharedValue(0);
  const mineTimer = useSharedValue(0);
  const reportTimer = useSharedValue(0);
  const started = useSharedValue(0);
  const over = useSharedValue(0);

  const finishRun = useCallback(
    (finalScore: number, finalCoins: number) => {
      haptic('heavy');
      onGameOver(finalScore, finalCoins);
    },
    [onGameOver],
  );

  const spawnDubloon = useCallback(
    (slot: PoolEntity) => {
      'worklet';
      const p = spawnPoint(width, height, 40, subX.value, subY.value, 90);
      slot.x.value = p.x;
      slot.y.value = p.y;
      slot.phase.value = Math.random() * Math.PI * 2;
      slot.active.value = 1;
    },
    [width, height, subX, subY],
  );

  const spawnMine = useCallback(
    (slot: PoolEntity, speed: number) => {
      'worklet';
      const p = spawnPoint(width, height, 30, subX.value, subY.value, 130);
      const drift = speed * (0.25 + Math.random() * 0.35);
      const heading = Math.random() * Math.PI * 2;
      slot.x.value = p.x;
      slot.y.value = p.y;
      slot.vx.value = Math.cos(heading) * drift;
      slot.vy.value = Math.sin(heading) * drift;
      slot.phase.value = Math.random() * Math.PI * 2;
      slot.active.value = 1;
    },
    [width, height, subX, subY],
  );

  useFrameCallback((info) => {
    'worklet';
    if (over.value === 1) return;

    if (started.value === 0) {
      started.value = 1;
      subX.value = width / 2;
      subY.value = height / 2;
      monsterX.value = 40;
      monsterY.value = 40;
      for (let i = 0; i < GAME.targetDubloons; i += 1) spawnDubloon(dubloons[i]);
      for (let i = 0; i < GAME.startMines; i += 1) spawnMine(mines[i], GAME.monsterBaseSpeed);
      return;
    }

    const dt = Math.min((info.timeSincePreviousFrame ?? 16) / 1000, 0.05);
    elapsed.value += dt;

    // --- player ------------------------------------------------------------
    const dx = dirX.value;
    const dy = dirY.value;
    const len = Math.sqrt(dx * dx + dy * dy);
    let sx = subX.value;
    let sy = subY.value;
    if (len > 0.0001) {
      const step = GAME.subDirSpeed * dt;
      sx += (dx / len) * step;
      sy += (dy / len) * step;
      subAngle.value = Math.atan2(dy, dx);
    }
    const r = GAME.subRadius;
    sx = Math.max(r, Math.min(width - r, sx));
    sy = Math.max(r, Math.min(height - r, sy));
    subX.value = sx;
    subY.value = sy;

    // --- monster -----------------------------------------------------------
    const chase = Math.min(
      GAME.monsterMaxSpeed,
      GAME.monsterBaseSpeed + elapsed.value * GAME.monsterRamp,
    );
    const mx = monsterX.value;
    const my = monsterY.value;
    const tx = sx - mx;
    const ty = sy - my;
    const td = Math.max(0.0001, Math.sqrt(tx * tx + ty * ty));
    monsterX.value = mx + (tx / td) * chase * dt;
    monsterY.value = my + (ty / td) * chase * dt;
    monsterAngle.value = Math.atan2(ty, tx);

    // --- dubloons ----------------------------------------------------------
    let collected = 0;
    let liveDubloons = 0;
    for (let i = 0; i < dubloons.length; i += 1) {
      const d = dubloons[i];
      if (d.active.value === 0) continue;
      d.phase.value += dt * 6;
      if (circlesHit(sx, sy, r, d.x.value, d.y.value, GAME.dubloonRadius)) {
        d.active.value = 0;
        collected += 1;
      } else {
        liveDubloons += 1;
      }
    }
    if (collected > 0) {
      coins.value += collected;
      score.value += GAME.dubloonScore * collected;
      runOnJS(haptic)('light');
      runOnJS(onDubloonsChange)(coins.value);
    }
    if (liveDubloons < GAME.targetDubloons) {
      for (let i = 0; i < dubloons.length; i += 1) {
        if (dubloons[i].active.value === 0) {
          spawnDubloon(dubloons[i]);
          break;
        }
      }
    }

    // --- mines -------------------------------------------------------------
    const mineR = GAME.mineRadius;
    let dead = circlesHit(
      sx,
      sy,
      r * 0.8,
      monsterX.value,
      monsterY.value,
      GAME.monsterRadius * 0.75,
    );
    let liveMines = 0;
    for (let i = 0; i < mines.length; i += 1) {
      const m = mines[i];
      if (m.active.value === 0) continue;
      liveMines += 1;
      m.phase.value += dt * 3;

      let px = m.x.value + m.vx.value * dt;
      let py = m.y.value + m.vy.value * dt;
      if (px < mineR) {
        px = mineR;
        m.vx.value = Math.abs(m.vx.value);
      } else if (px > width - mineR) {
        px = width - mineR;
        m.vx.value = -Math.abs(m.vx.value);
      }
      if (py < mineR) {
        py = mineR;
        m.vy.value = Math.abs(m.vy.value);
      } else if (py > height - mineR) {
        py = height - mineR;
        m.vy.value = -Math.abs(m.vy.value);
      }
      m.x.value = px;
      m.y.value = py;

      if (!dead && circlesHit(sx, sy, r * 0.75, px, py, mineR * 0.8)) dead = true;
    }

    mineTimer.value += dt;
    if (mineTimer.value > GAME.mineInterval && liveMines < GAME.maxMines) {
      mineTimer.value = 0;
      for (let i = 0; i < mines.length; i += 1) {
        if (mines[i].active.value === 0) {
          spawnMine(mines[i], GAME.monsterBaseSpeed + elapsed.value * GAME.mineSpeedRamp);
          break;
        }
      }
    }

    // --- scoring / end of run ---------------------------------------------
    score.value += GAME.survivalScore * dt;
    reportTimer.value += dt;
    if (reportTimer.value > SCORE_REPORT_INTERVAL) {
      reportTimer.value = 0;
      runOnJS(onScoreChange)(Math.floor(score.value));
    }

    if (dead) {
      over.value = 1;
      runOnJS(finishRun)(Math.floor(score.value), coins.value);
    }
  });

  return (
    <View style={{ width, height, overflow: 'hidden' }}>
      {dubloons.map((d) => (
        <DubloonView key={d.id} entity={d} />
      ))}
      {mines.map((m) => (
        <MineView key={m.id} entity={m} />
      ))}

      <SubView x={subX} y={subY} angle={subAngle} />
      <MonsterView x={monsterX} y={monsterY} angle={monsterAngle} />

      <Joystick dirX={dirX} dirY={dirY} />
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

const DubloonView = memo(function DubloonView({ entity }: { entity: PoolEntity }) {
  const half = SPRITE_BOX.dubloon / 2;
  const style = useAnimatedStyle(() => ({
    opacity: entity.active.value,
    transform: [
      { translateX: entity.x.value - half },
      { translateY: entity.y.value - half },
      // squash horizontally to fake a spinning coin
      { scaleX: 0.55 + 0.45 * Math.abs(Math.cos(entity.phase.value)) },
    ],
  }));
  return (
    <Animated.View pointerEvents="none" style={[spriteBox(SPRITE_BOX.dubloon), style]}>
      <DubloonArt />
    </Animated.View>
  );
});

const MineView = memo(function MineView({ entity }: { entity: PoolEntity }) {
  const half = SPRITE_BOX.mine / 2;
  const style = useAnimatedStyle(() => ({
    opacity: entity.active.value,
    transform: [
      { translateX: entity.x.value - half },
      { translateY: entity.y.value - half },
      // slow breathing pulse so the hazard reads as alive
      { scale: 1 + 0.07 * Math.sin(entity.phase.value) },
      { rotate: `${Math.sin(entity.phase.value * 0.5) * 0.12}rad` },
    ],
  }));
  return (
    <Animated.View pointerEvents="none" style={[spriteBox(SPRITE_BOX.mine), style]}>
      <MineArt />
    </Animated.View>
  );
});

interface ActorProps {
  x: SharedValue<number>;
  y: SharedValue<number>;
  angle: SharedValue<number>;
}

const SubView = memo(function SubView({ x, y, angle }: ActorProps) {
  const half = SPRITE_BOX.sub / 2;
  const style = useAnimatedStyle(() => {
    const a = angle.value;
    return {
      transform: [
        { translateX: x.value - half },
        { translateY: y.value - half },
        { rotate: `${a}rad` },
        // mirror instead of turning the face upside-down when heading left
        { scaleY: Math.cos(a) < 0 ? -1 : 1 },
      ],
    };
  });
  return (
    <Animated.View pointerEvents="none" style={[spriteBox(SPRITE_BOX.sub), style]}>
      <SubArt />
    </Animated.View>
  );
});

const MonsterView = memo(function MonsterView({ x, y, angle }: ActorProps) {
  const half = SPRITE_BOX.monster / 2;
  const style = useAnimatedStyle(() => {
    const a = angle.value;
    return {
      transform: [
        { translateX: x.value - half },
        { translateY: y.value - half },
        { rotate: `${a}rad` },
        { scaleY: Math.cos(a) < 0 ? -1 : 1 },
      ],
    };
  });
  return (
    <Animated.View pointerEvents="none" style={[spriteBox(SPRITE_BOX.monster), style]}>
      <MonsterArt />
    </Animated.View>
  );
});

const JOYSTICK_SIZE = 132;
const KNOB_SIZE = 58;
const MAX_OFFSET = (JOYSTICK_SIZE - KNOB_SIZE) / 2;

/**
 * Analog joystick anchored bottom-right. Drag the knob in any direction to
 * steer at that angle; distance from center is clamped to the base radius.
 * Writes the normalized direction straight into the simulation's shared
 * values, so steering never crosses onto the JS thread.
 */
function Joystick({ dirX, dirY }: { dirX: SharedValue<number>; dirY: SharedValue<number> }) {
  const knobX = useSharedValue(0);
  const knobY = useSharedValue(0);

  const pan = useMemo(() => {
    const apply = (ex: number, ey: number) => {
      'worklet';
      const center = JOYSTICK_SIZE / 2;
      let ox = ex - center;
      let oy = ey - center;
      const len = Math.sqrt(ox * ox + oy * oy);
      if (len > MAX_OFFSET) {
        ox = (ox / len) * MAX_OFFSET;
        oy = (oy / len) * MAX_OFFSET;
      }
      knobX.value = ox;
      knobY.value = oy;
      dirX.value = ox / MAX_OFFSET;
      dirY.value = oy / MAX_OFFSET;
    };

    return Gesture.Pan()
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
        knobX.value = 0;
        knobY.value = 0;
        dirX.value = 0;
        dirY.value = 0;
      });
  }, [dirX, dirY, knobX, knobY]);

  const knobStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: knobX.value }, { translateY: knobY.value }],
  }));

  return (
    <View
      pointerEvents="box-none"
      style={{ position: 'absolute', right: 24, bottom: 40 }}
      className="pb-safe"
    >
      <GestureDetector gesture={pan}>
        <View
          style={{
            width: JOYSTICK_SIZE,
            height: JOYSTICK_SIZE,
            borderRadius: JOYSTICK_SIZE / 2,
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: 'rgba(255,255,255,0.1)',
            borderWidth: 3,
            borderColor: 'rgba(255,255,255,0.32)',
          }}
        >
          <Animated.View
            style={[
              {
                width: KNOB_SIZE,
                height: KNOB_SIZE,
                borderRadius: KNOB_SIZE / 2,
                backgroundColor: 'rgba(255,255,255,0.34)',
                borderWidth: 3,
                borderColor: 'rgba(255,255,255,0.62)',
                alignItems: 'center',
                justifyContent: 'center',
              },
              knobStyle,
            ]}
          >
            <View
              style={{
                width: KNOB_SIZE * 0.3,
                height: KNOB_SIZE * 0.3,
                borderRadius: KNOB_SIZE * 0.15,
                backgroundColor: 'rgba(255,255,255,0.55)',
                marginBottom: KNOB_SIZE * 0.18,
                marginRight: KNOB_SIZE * 0.18,
              }}
            />
          </Animated.View>
        </View>
      </GestureDetector>
    </View>
  );
}
