import { memo } from 'react';
import Svg, {
  Circle,
  Defs,
  Ellipse,
  G,
  Line,
  Path,
  Polygon,
  RadialGradient,
  Rect,
  Stop,
} from 'react-native-svg';

import { GAME } from '@/lib/game/engine';

/**
 * All artwork here is original vector art authored for this game.
 *
 * Each sprite is a STATIC svg drawn once and never re-rendered: position,
 * rotation and pulsing are applied by the Reanimated wrappers in GameCanvas.
 * Every viewBox is centered on (0,0) and square, so the view's own center
 * matches the entity center — rotation about the view center is correct.
 *
 * NOTE: react-native-svg (iOS/Android) cannot parse CSS `oklch()` color
 * functions, so these are pre-resolved to hex. Do not use oklch() in SVG props.
 */
const PALETTE = {
  seaLight: '#1f74a8',
  seaDeep: '#152036',
  seaMid: '#22456b',
  subDark: '#c07d3b',
  monster: '#3fae6a',
  monsterDark: '#2c8350',
  dubloon: '#e9c04a',
  dubloonEdge: '#c99a34',
  mine: '#8a5a4a',
  mineSpike: '#4a332b',
  danger: '#e04a3a',
  foreground: '#f2f6fb',
  background: '#2a3a56',
} as const;

/** Square canvas size (px) of each sprite's static svg. */
export const SPRITE_BOX = {
  sub: 60,
  monster: 104,
  dubloon: 28,
  mine: 46,
} as const;

/** Diameter of the mine's pulsing core, animated as a plain view. */
export const MINE_CORE_SIZE = Math.round(GAME.mineRadius * 0.7);

export const MINE_CORE_COLOR = PALETTE.danger;

export const WaterBackground = memo(function WaterBackground({
  width,
  height,
}: {
  width: number;
  height: number;
}) {
  return (
    <Svg width={width} height={height} style={{ position: 'absolute', left: 0, top: 0 }}>
      <Defs>
        <RadialGradient id="water" cx="50%" cy="35%" r="80%">
          <Stop offset="0%" stopColor={PALETTE.seaMid} />
          <Stop offset="100%" stopColor={PALETTE.seaDeep} />
        </RadialGradient>
      </Defs>
      <Rect x={0} y={0} width={width} height={height} fill="url(#water)" />
    </Svg>
  );
});

export const SubArt = memo(function SubArt() {
  const box = SPRITE_BOX.sub;
  const half = box / 2;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      {/* tail fin */}
      <Polygon points="-16,-8 -24,-14 -16,0 -24,14 -16,8" fill={PALETTE.subDark} />
      {/* hull */}
      <Ellipse cx={0} cy={0} rx={18} ry={11} fill={PALETTE.seaLight} />
      <Ellipse cx={0} cy={0} rx={18} ry={11} fill="none" stroke={PALETTE.subDark} strokeWidth={2} />
      {/* conning tower */}
      <Rect x={-4} y={-16} width={9} height={7} rx={2} fill={PALETTE.subDark} />
      {/* porthole */}
      <Circle cx={5} cy={-1} r={4} fill={PALETTE.foreground} opacity={0.9} />
      <Circle cx={5} cy={-1} r={4} fill="none" stroke={PALETTE.subDark} strokeWidth={1.5} />
      {/* nose light */}
      <Circle cx={18} cy={0} r={2.5} fill="#ffe9a8" />
    </Svg>
  );
});

export const MonsterArt = memo(function MonsterArt() {
  const box = SPRITE_BOX.monster;
  const half = box / 2;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <G>
        {/* tentacle trail */}
        <Path
          d="M -18 6 Q -34 14 -40 4 M -18 -6 Q -34 -14 -40 -4 M -20 0 Q -40 0 -48 0"
          stroke={PALETTE.monsterDark}
          strokeWidth={4}
          fill="none"
          strokeLinecap="round"
        />
        {/* head */}
        <Circle cx={0} cy={0} r={22} fill={PALETTE.monster} />
        <Circle cx={0} cy={0} r={22} fill="none" stroke={PALETTE.monsterDark} strokeWidth={3} />
        {/* mouth */}
        <Path d="M 8 -9 L 24 -13 L 20 0 L 24 13 L 8 9 Z" fill={PALETTE.monsterDark} />
        <Polygon points="12,-6 20,-9 16,-2" fill={PALETTE.background} />
        <Polygon points="12,6 20,9 16,2" fill={PALETTE.background} />
        {/* eyes */}
        <Circle cx={-2} cy={-9} r={5} fill="#fff" />
        <Circle cx={-2} cy={9} r={5} fill="#fff" />
        <Circle cx={0} cy={-9} r={2.4} fill={PALETTE.monsterDark} />
        <Circle cx={0} cy={9} r={2.4} fill={PALETTE.monsterDark} />
      </G>
    </Svg>
  );
});

export const DubloonArt = memo(function DubloonArt() {
  const box = SPRITE_BOX.dubloon;
  const half = box / 2;
  const r = GAME.dubloonRadius;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Circle cx={0} cy={0} r={r} fill={PALETTE.dubloon} />
      <Circle cx={0} cy={0} r={r} fill="none" stroke={PALETTE.dubloonEdge} strokeWidth={2.5} />
      <Circle
        cx={0}
        cy={0}
        r={r * 0.6}
        fill="none"
        stroke={PALETTE.dubloonEdge}
        strokeWidth={1.5}
      />
      <Line x1={0} y1={-r * 0.5} x2={0} y2={r * 0.5} stroke={PALETTE.seaDeep} strokeWidth={2} />
      <Line x1={-r * 0.4} y1={0} x2={r * 0.4} y2={0} stroke={PALETTE.seaDeep} strokeWidth={2} />
    </Svg>
  );
});

const MINE_SPIKES = [0, 45, 90, 135, 180, 225, 270, 315];

export const MineArt = memo(function MineArt() {
  const box = SPRITE_BOX.mine;
  const half = box / 2;
  const r = GAME.mineRadius;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      {MINE_SPIKES.map((a) => {
        const rad = (a * Math.PI) / 180;
        const inner = r * 0.9;
        const outer = r * 1.4;
        return (
          <Line
            key={a}
            x1={Math.cos(rad) * inner}
            y1={Math.sin(rad) * inner}
            x2={Math.cos(rad) * outer}
            y2={Math.sin(rad) * outer}
            stroke={PALETTE.mineSpike}
            strokeWidth={3}
            strokeLinecap="round"
          />
        );
      })}
      <Circle cx={0} cy={0} r={r} fill={PALETTE.mine} />
      <Circle cx={0} cy={0} r={r} fill="none" stroke={PALETTE.mineSpike} strokeWidth={2} />
    </Svg>
  );
});

export { PALETTE as GAME_PALETTE };
