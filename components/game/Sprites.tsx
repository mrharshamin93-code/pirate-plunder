import { memo } from 'react';
import { Circle, Ellipse, G, Line, Path, Polygon, Rect } from 'react-native-svg';

/** All artwork here is original vector art authored for this game. */

/** Resolved game palette — mirrors the --color-* tokens in global.css. */
const PALETTE = {
  seaLight: 'oklch(0.48 0.11 235)',
  seaDeep: 'oklch(0.2 0.08 250)',
  sub: 'oklch(0.75 0.14 55)',
  subDark: 'oklch(0.58 0.13 45)',
  monster: 'oklch(0.55 0.2 150)',
  monsterDark: 'oklch(0.42 0.18 150)',
  dubloon: 'oklch(0.82 0.16 88)',
  dubloonEdge: 'oklch(0.68 0.15 70)',
  mine: 'oklch(0.45 0.06 30)',
  mineSpike: 'oklch(0.3 0.04 30)',
  danger: 'oklch(0.65 0.23 26)',
  foreground: 'oklch(0.97 0.02 220)',
  background: 'oklch(0.28 0.09 245)',
} as const;

interface SpriteProps {
  x: number;
  y: number;
  angle?: number;
  r: number;
}

export const SubSprite = memo(function SubSprite({ x, y, angle = 0, r }: SpriteProps) {
  const body = PALETTE.seaLight;
  const dark = PALETTE.subDark;
  const glass = PALETTE.foreground;
  const deg = (angle * 180) / Math.PI;
  const s = r / 16;
  return (
    <G x={x} y={y} rotation={deg} originX={0} originY={0}>
      <G scale={s}>
        {/* tail fin */}
        <Polygon points="-16,-8 -24,-14 -16,0 -24,14 -16,8" fill={dark} />
        {/* hull */}
        <Ellipse cx={0} cy={0} rx={18} ry={11} fill={body} />
        <Ellipse cx={0} cy={0} rx={18} ry={11} fill="none" stroke={dark} strokeWidth={2} />
        {/* conning tower */}
        <Rect x={-4} y={-16} width={9} height={7} rx={2} fill={dark} />
        {/* porthole */}
        <Circle cx={5} cy={-1} r={4} fill={glass} opacity={0.9} />
        <Circle cx={5} cy={-1} r={4} fill="none" stroke={dark} strokeWidth={1.5} />
        {/* nose light */}
        <Circle cx={18} cy={0} r={2.5} fill="#ffe9a8" />
      </G>
    </G>
  );
});

export const MonsterSprite = memo(function MonsterSprite({ x, y, angle = 0, r }: SpriteProps) {
  const body = PALETTE.monster;
  const dark = PALETTE.monsterDark;
  const teeth = PALETTE.background;
  const deg = (angle * 180) / Math.PI;
  const s = r / 26;
  return (
    <G x={x} y={y} rotation={deg} originX={0} originY={0}>
      <G scale={s}>
        {/* tentacle trail */}
        <Path
          d="M -18 6 Q -34 14 -40 4 M -18 -6 Q -34 -14 -40 -4 M -20 0 Q -40 0 -48 0"
          stroke={dark}
          strokeWidth={4}
          fill="none"
          strokeLinecap="round"
        />
        {/* head */}
        <Circle cx={0} cy={0} r={22} fill={body} />
        <Circle cx={0} cy={0} r={22} fill="none" stroke={dark} strokeWidth={3} />
        {/* mouth */}
        <Path d="M 8 -9 L 24 -13 L 20 0 L 24 13 L 8 9 Z" fill={dark} />
        <Polygon points="12,-6 20,-9 16,-2" fill={teeth} />
        <Polygon points="12,6 20,9 16,2" fill={teeth} />
        {/* eyes */}
        <Circle cx={-2} cy={-9} r={5} fill="#fff" />
        <Circle cx={-2} cy={9} r={5} fill="#fff" />
        <Circle cx={0} cy={-9} r={2.4} fill={dark} />
        <Circle cx={0} cy={9} r={2.4} fill={dark} />
      </G>
    </G>
  );
});

export const DubloonSprite = memo(function DubloonSprite({
  x,
  y,
  r,
  bob,
}: SpriteProps & { bob: number }) {
  const gold = PALETTE.dubloon;
  const edge = PALETTE.dubloonEdge;
  const ink = PALETTE.seaDeep;
  // squash horizontally to fake a spinning coin
  const scaleX = 0.55 + 0.45 * Math.abs(Math.cos(bob));
  return (
    <G x={x} y={y}>
      <G scaleX={scaleX}>
        <Circle cx={0} cy={0} r={r} fill={gold} />
        <Circle cx={0} cy={0} r={r} fill="none" stroke={edge} strokeWidth={2.5} />
        <Circle cx={0} cy={0} r={r * 0.6} fill="none" stroke={edge} strokeWidth={1.5} />
        <Line x1={0} y1={-r * 0.5} x2={0} y2={r * 0.5} stroke={ink} strokeWidth={2} />
        <Line x1={-r * 0.4} y1={0} x2={r * 0.4} y2={0} stroke={ink} strokeWidth={2} />
      </G>
    </G>
  );
});

export const MineSprite = memo(function MineSprite({
  x,
  y,
  r,
  bob,
}: SpriteProps & { bob: number }) {
  const shell = PALETTE.mine;
  const spike = PALETTE.mineSpike;
  const danger = PALETTE.danger;
  const pulse = 0.6 + 0.4 * ((Math.sin(bob) + 1) / 2);
  const spikes = [0, 45, 90, 135, 180, 225, 270, 315];
  return (
    <G x={x} y={y}>
      {spikes.map((a) => {
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
            stroke={spike}
            strokeWidth={3}
            strokeLinecap="round"
          />
        );
      })}
      <Circle cx={0} cy={0} r={r} fill={shell} />
      <Circle cx={0} cy={0} r={r} fill="none" stroke={spike} strokeWidth={2} />
      <Circle cx={0} cy={0} r={r * 0.35} fill={danger} opacity={pulse} />
    </G>
  );
});
