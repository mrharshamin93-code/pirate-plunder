import { useCallback, useEffect, useRef, useState } from 'react';
import { Platform, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  runOnJS,
  useAnimatedStyle,
  useFrameCallback,
  useSharedValue,
} from 'react-native-reanimated';
import Svg, { Defs, RadialGradient, Rect, Stop } from 'react-native-svg';
import * as Haptics from 'expo-haptics';

import { DubloonSprite, MineSprite, MonsterSprite, SubSprite } from '@/components/game/Sprites';
import {
  circlesHit,
  GAME,
  makeDubloon,
  makeMine,
  moveMine,
  moveMonster,
  moveSubByDir,
} from '@/lib/game/engine';
import type { Entity, Monster, Sub } from '@/lib/game/types';

/**
 * Resolved game palette — mirrors the --color-* tokens in global.css.
 * NOTE: react-native-svg cannot parse CSS `oklch()`, so use hex here.
 */
const PALETTE = {
  seaDeep: '#152036',
  seaMid: '#22456b',
} as const;

interface GameCanvasProps {
  width: number;
  height: number;
  onGameOver: (score: number, dubloons: number) => void;
  onScoreChange: (score: number) => void;
  onDubloonsChange: (count: number) => void;
}

interface WorldState {
  sub: Sub;
  monster: Monster;
  entities: Entity[];
  dir: { x: number; y: number };
  elapsed: number;
  dubloonAccum: number;
  score: number;
  dubloons: number;
  mineTimer: number;
  over: boolean;
}

function createWorld(width: number, height: number): WorldState {
  const cx = width / 2;
  const cy = height / 2;
  const sub: Sub = { x: cx, y: cy, angle: 0, r: GAME.subRadius };
  const monster: Monster = { x: 40, y: 40, angle: 0, r: GAME.monsterRadius };
  const entities: Entity[] = [];
  for (let i = 0; i < 4; i += 1) entities.push(makeDubloon(width, height, sub));
  for (let i = 0; i < 3; i += 1) entities.push(makeMine(width, height, sub, GAME.monsterBaseSpeed));
  return {
    sub,
    monster,
    entities,
    dir: { x: 0, y: 0 },
    elapsed: 0,
    dubloonAccum: 0,
    score: 0,
    dubloons: 0,
    mineTimer: 0,
    over: false,
  };
}

function haptic(kind: 'light' | 'heavy') {
  if (Platform.OS === 'web') return;
  if (kind === 'light') void Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  else void Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
}

export function GameCanvas({
  width,
  height,
  onGameOver,
  onScoreChange,
  onDubloonsChange,
}: GameCanvasProps) {
  const world = useRef<WorldState>(createWorld(width, height));
  const [, forceRender] = useState(0);
  const lastTime = useRef(0);

  const deep = PALETTE.seaDeep;
  const mid = PALETTE.seaMid;

  // called from the joystick worklet with a normalized direction vector
  const setDir = useCallback((x: number, y: number) => {
    world.current.dir.x = x;
    world.current.dir.y = y;
  }, []);

  const tick = useCallback(
    (dt: number) => {
      const w = world.current;
      if (w.over) return;
      const clampedDt = Math.min(dt, 0.05);
      w.elapsed += clampedDt;

      moveSubByDir(w.sub, w.dir, clampedDt);
      // keep sub in bounds
      w.sub.x = Math.max(w.sub.r, Math.min(width - w.sub.r, w.sub.x));
      w.sub.y = Math.max(w.sub.r, Math.min(height - w.sub.r, w.sub.y));

      moveMonster(w.monster, w.sub, w.elapsed, clampedDt);

      for (const e of w.entities) {
        if (e.kind === 'mine') moveMine(e, width, height, clampedDt);
        e.phase += clampedDt * (e.kind === 'dubloon' ? 6 : 3);
      }

      // survival scoring
      w.score += GAME.survivalScore * clampedDt;

      // dubloon collection
      let collected = false;
      for (const e of w.entities) {
        if (e.kind !== 'dubloon' || !e.alive) continue;
        if (circlesHit(w.sub, w.sub.r, e, e.r)) {
          e.alive = false;
          w.dubloons += 1;
          w.score += GAME.dubloonScore;
          collected = true;
        }
      }
      if (collected) {
        haptic('light');
        w.entities = w.entities.filter((e) => e.alive);
        onDubloonsChange(w.dubloons);
      }

      // respawn dubloons up to a target count
      const dubloonCount = w.entities.filter((e) => e.kind === 'dubloon').length;
      if (dubloonCount < 4) {
        w.entities.push(makeDubloon(width, height, w.sub));
      }

      // progressively add mines
      w.mineTimer += clampedDt;
      const mineCount = w.entities.filter((e) => e.kind === 'mine').length;
      if (w.mineTimer > 6 && mineCount < GAME.maxMines) {
        w.mineTimer = 0;
        w.entities.push(makeMine(width, height, w.sub, GAME.monsterBaseSpeed + w.elapsed * 2));
      }

      // report score roughly 10x/sec
      w.dubloonAccum += clampedDt;
      if (w.dubloonAccum > 0.1) {
        w.dubloonAccum = 0;
        onScoreChange(Math.floor(w.score));
      }

      // collisions that end the run
      let dead = false;
      if (circlesHit(w.sub, w.sub.r * 0.8, w.monster, w.monster.r * 0.75)) dead = true;
      if (!dead) {
        for (const e of w.entities) {
          if (e.kind === 'mine' && circlesHit(w.sub, w.sub.r * 0.75, e, e.r * 0.8)) {
            dead = true;
            break;
          }
        }
      }

      if (dead) {
        w.over = true;
        haptic('heavy');
        onGameOver(Math.floor(w.score), w.dubloons);
      }

      forceRender((n) => (n + 1) % 1000000);
    },
    [width, height, onGameOver, onScoreChange, onDubloonsChange],
  );

  useFrameCallback((frame) => {
    'worklet';
    const t = frame.timeSinceFirstFrame / 1000;
    const dt = lastTime.current === 0 ? 1 / 60 : t - lastTime.current;
    lastTime.current = t;
    runOnJS(tick)(dt);
  });

  useEffect(() => {
    const worldRef = world.current;
    return () => {
      worldRef.over = true;
    };
  }, []);

  const w = world.current;

  return (
    <View style={{ width, height }}>
      <Svg width={width} height={height}>
        <Defs>
          <RadialGradient id="water" cx="50%" cy="35%" r="80%">
            <Stop offset="0%" stopColor={mid} />
            <Stop offset="100%" stopColor={deep} />
          </RadialGradient>
        </Defs>
        <Rect x={0} y={0} width={width} height={height} fill="url(#water)" />

        {w.entities
          .filter((e) => e.kind === 'dubloon')
          .map((e) => (
            <DubloonSprite key={e.id} x={e.x} y={e.y} r={e.r} bob={e.phase} angle={0} />
          ))}

        {w.entities
          .filter((e) => e.kind === 'mine')
          .map((e) => (
            <MineSprite key={e.id} x={e.x} y={e.y} r={e.r} bob={e.phase} angle={0} />
          ))}

        <SubSprite x={w.sub.x} y={w.sub.y} angle={w.sub.angle} r={w.sub.r} />
        <MonsterSprite x={w.monster.x} y={w.monster.y} angle={w.monster.angle} r={w.monster.r} />
      </Svg>

      <Joystick onChange={setDir} />
    </View>
  );
}

const JOYSTICK_SIZE = 132;
const KNOB_SIZE = 58;
const MAX_OFFSET = (JOYSTICK_SIZE - KNOB_SIZE) / 2;

/**
 * Analog joystick anchored bottom-right. Drag the knob in any direction to
 * steer at that angle; distance from center is clamped to the base radius.
 * Emits a normalized direction vector (magnitude 0..1) to `onChange`.
 */
function Joystick({ onChange }: { onChange: (x: number, y: number) => void }) {
  const dx = useSharedValue(0);
  const dy = useSharedValue(0);

  const pan = Gesture.Pan()
    .onBegin((e) => {
      'worklet';
      const cx = JOYSTICK_SIZE / 2;
      const cy = JOYSTICK_SIZE / 2;
      let ox = e.x - cx;
      let oy = e.y - cy;
      const len = Math.sqrt(ox * ox + oy * oy);
      if (len > MAX_OFFSET) {
        ox = (ox / len) * MAX_OFFSET;
        oy = (oy / len) * MAX_OFFSET;
      }
      dx.value = ox;
      dy.value = oy;
      runOnJS(onChange)(ox / MAX_OFFSET, oy / MAX_OFFSET);
    })
    .onUpdate((e) => {
      'worklet';
      const cx = JOYSTICK_SIZE / 2;
      const cy = JOYSTICK_SIZE / 2;
      let ox = e.x - cx;
      let oy = e.y - cy;
      const len = Math.sqrt(ox * ox + oy * oy);
      if (len > MAX_OFFSET) {
        ox = (ox / len) * MAX_OFFSET;
        oy = (oy / len) * MAX_OFFSET;
      }
      dx.value = ox;
      dy.value = oy;
      runOnJS(onChange)(ox / MAX_OFFSET, oy / MAX_OFFSET);
    })
    .onFinalize(() => {
      'worklet';
      dx.value = 0;
      dy.value = 0;
      runOnJS(onChange)(0, 0);
    });

  const knobStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: dx.value }, { translateY: dy.value }],
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
            backgroundColor: 'rgba(255,255,255,0.06)',
            borderWidth: 1,
            borderColor: 'rgba(255,255,255,0.2)',
          }}
        >
          <Animated.View
            style={[
              {
                width: KNOB_SIZE,
                height: KNOB_SIZE,
                borderRadius: KNOB_SIZE / 2,
                backgroundColor: 'rgba(255,255,255,0.28)',
                borderWidth: 1,
                borderColor: 'rgba(255,255,255,0.5)',
              },
              knobStyle,
            ]}
          />
        </View>
      </GestureDetector>
    </View>
  );
}
