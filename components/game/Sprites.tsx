import { memo } from 'react';
import Svg, {
  Circle,
  Defs,
  Ellipse,
  G,
  LinearGradient,
  Path,
  Polygon,
  RadialGradient,
  Rect,
  Stop,
} from 'react-native-svg';

import { GAME } from '@/lib/game/engine';

/**
 * All artwork here is original vector art authored for this game, drawn in a
 * bright cartoon "virtual pet" style: thick dark outlines, saturated flat
 * fills, a single glossy highlight and big expressive eyes.
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
  /** outline colour used on every sprite */
  ink: '#2b1a12',

  seaTop: '#34a9c9',
  seaMid: '#1a6ea3',
  seaDeep: '#0a3358',
  seabed: '#0b3f5c',
  kelp: '#126a72',

  hull: '#ffd84d',
  hullShade: '#f0a52b',
  hullLight: '#fff3b0',
  fin: '#ff7a4d',
  finShade: '#e05a30',
  glass: '#d8f3ff',
  glassShade: '#8fd6f5',
  blush: '#ff8fa8',

  monster: '#4fd6a5',
  monsterShade: '#2aa17a',
  monsterBelly: '#c4f7e3',
  maw: '#6d1f3f',
  tongue: '#ff7fa8',

  dubloon: '#ffd54a',
  dubloonLight: '#fff3bd',
  dubloonEdge: '#c98a1e',

  urchin: '#a877e8',
  urchinShade: '#7a49c0',
  urchinSpike: '#5f34a0',

  tooth: '#ffffff',
  danger: '#ff5a45',
} as const;

/** Square canvas size (px) of each sprite's static svg. */
export const SPRITE_BOX = {
  sub: 76,
  monster: 128,
  dubloon: 34,
  mine: 60,
} as const;

/* ------------------------------------------------------------------------- */
/* Background scene                                                          */
/* ------------------------------------------------------------------------- */

/** Deterministic decorative bubbles, expressed as fractions of the screen. */
const BUBBLES = [
  { fx: 0.14, fy: 0.24, r: 7 },
  { fx: 0.22, fy: 0.52, r: 4 },
  { fx: 0.34, fy: 0.14, r: 5 },
  { fx: 0.48, fy: 0.66, r: 8 },
  { fx: 0.62, fy: 0.32, r: 5 },
  { fx: 0.72, fy: 0.58, r: 6 },
  { fx: 0.84, fy: 0.2, r: 4 },
  { fx: 0.9, fy: 0.74, r: 7 },
] as const;

export const WaterBackground = memo(function WaterBackground({
  width,
  height,
}: {
  width: number;
  height: number;
}) {
  const bedTop = height - 92;
  return (
    <Svg width={width} height={height} style={{ position: 'absolute', left: 0, top: 0 }}>
      <Defs>
        <LinearGradient id="water" x1="0" y1="0" x2="0" y2="1">
          <Stop offset="0%" stopColor={PALETTE.seaTop} />
          <Stop offset="45%" stopColor={PALETTE.seaMid} />
          <Stop offset="100%" stopColor={PALETTE.seaDeep} />
        </LinearGradient>
        <LinearGradient id="ray" x1="0" y1="0" x2="0" y2="1">
          <Stop offset="0%" stopColor="#ffffff" stopOpacity={0.28} />
          <Stop offset="100%" stopColor="#ffffff" stopOpacity={0} />
        </LinearGradient>
        <LinearGradient id="topShade" x1="0" y1="0" x2="0" y2="1">
          <Stop offset="0%" stopColor={PALETTE.seaDeep} stopOpacity={0.55} />
          <Stop offset="100%" stopColor={PALETTE.seaDeep} stopOpacity={0} />
        </LinearGradient>
      </Defs>

      <Rect x={0} y={0} width={width} height={height} fill="url(#water)" />

      {/* god rays from the surface */}
      <Polygon
        points={`${width * 0.16},0 ${width * 0.3},0 ${width * 0.52},${height} ${width * 0.28},${height}`}
        fill="url(#ray)"
      />
      <Polygon
        points={`${width * 0.44},0 ${width * 0.52},0 ${width * 0.68},${height} ${width * 0.56},${height}`}
        fill="url(#ray)"
      />
      <Polygon
        points={`${width * 0.72},0 ${width * 0.86},0 ${width * 1.04},${height} ${width * 0.86},${height}`}
        fill="url(#ray)"
      />

      {/* keeps the HUD readable against the bright surface water */}
      <Rect x={0} y={0} width={width} height={150} fill="url(#topShade)" />

      {BUBBLES.map((b) => (
        <G key={`${b.fx}-${b.fy}`}>
          <Circle
            cx={width * b.fx}
            cy={height * b.fy}
            r={b.r}
            fill="none"
            stroke="#ffffff"
            strokeOpacity={0.22}
            strokeWidth={2}
          />
          <Circle
            cx={width * b.fx - b.r * 0.3}
            cy={height * b.fy - b.r * 0.35}
            r={b.r * 0.28}
            fill="#ffffff"
            fillOpacity={0.35}
          />
        </G>
      ))}

      {/* seabed with kelp silhouettes */}
      <Path
        d={`M -10 ${height + 10} L -10 ${bedTop + 30} Q ${width * 0.2} ${bedTop - 6} ${width * 0.45} ${bedTop + 22} Q ${width * 0.7} ${bedTop + 48} ${width * 0.86} ${bedTop + 10} Q ${width * 0.95} ${bedTop - 4} ${width + 10} ${bedTop + 24} L ${width + 10} ${height + 10} Z`}
        fill={PALETTE.seabed}
        fillOpacity={0.85}
      />
      <Path
        d={`M ${width * 0.12} ${height} Q ${width * 0.08} ${bedTop + 4} ${width * 0.17} ${bedTop - 34} Q ${width * 0.2} ${bedTop + 10} ${width * 0.16} ${height} Z`}
        fill={PALETTE.kelp}
        fillOpacity={0.6}
      />
      <Path
        d={`M ${width * 0.78} ${height} Q ${width * 0.83} ${bedTop + 6} ${width * 0.74} ${bedTop - 42} Q ${width * 0.73} ${bedTop + 12} ${width * 0.74} ${height} Z`}
        fill={PALETTE.kelp}
        fillOpacity={0.6}
      />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* Player submarine — a friendly, wide-eyed little sub                       */
/* ------------------------------------------------------------------------- */

export const SubArt = memo(function SubArt() {
  const box = SPRITE_BOX.sub;
  const half = box / 2;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      {/* tail fin */}
      <Path
        d="M -19 -3 L -31 -15 Q -35 -11 -33 0 Q -35 11 -31 15 L -19 3 Z"
        fill={PALETTE.fin}
        stroke={PALETTE.ink}
        strokeWidth={2.5}
        strokeLinejoin="round"
      />
      {/* periscope */}
      <Path
        d="M -1 -17 L -1 -25 L 6 -25"
        stroke={PALETTE.ink}
        strokeWidth={3.5}
        strokeLinecap="round"
        fill="none"
      />
      {/* conning tower */}
      <Path
        d="M -8 -11 Q -8 -19 -1 -19 L 5 -19 Q 9 -19 9 -11 Z"
        fill={PALETTE.fin}
        stroke={PALETTE.ink}
        strokeWidth={2.5}
        strokeLinejoin="round"
      />
      {/* hull */}
      <Ellipse
        cx={0}
        cy={0}
        rx={21}
        ry={14}
        fill={PALETTE.hull}
        stroke={PALETTE.ink}
        strokeWidth={2.5}
      />
      {/* belly shading */}
      <Path d="M -21 0 A 21 14 0 0 0 21 0 Z" fill={PALETTE.hullShade} fillOpacity={0.55} />
      {/* gloss */}
      <Path
        d="M -12 -8 Q -3 -12.5 6 -10"
        stroke={PALETTE.hullLight}
        strokeWidth={3}
        strokeLinecap="round"
        fill="none"
        opacity={0.9}
      />
      {/* blush */}
      <Ellipse cx={-8} cy={5} rx={4} ry={2.6} fill={PALETTE.blush} opacity={0.55} />
      {/* rivets */}
      <Circle cx={-14} cy={-2} r={1.4} fill={PALETTE.ink} opacity={0.5} />
      <Circle cx={-14} cy={4} r={1.4} fill={PALETTE.ink} opacity={0.5} />
      {/* porthole with a cheerful pilot face */}
      <Circle cx={7} cy={0} r={9} fill={PALETTE.glass} stroke={PALETTE.ink} strokeWidth={2.5} />
      <Path
        d="M 1 -4 Q 5 -8 10 -7"
        stroke="#ffffff"
        strokeWidth={2.4}
        strokeLinecap="round"
        fill="none"
      />
      <Ellipse cx={4} cy={-1} rx={1.9} ry={2.3} fill={PALETTE.ink} />
      <Ellipse cx={10.5} cy={-1} rx={1.9} ry={2.3} fill={PALETTE.ink} />
      <Circle cx={4.7} cy={-1.9} r={0.8} fill="#ffffff" />
      <Circle cx={11.2} cy={-1.9} r={0.8} fill="#ffffff" />
      <Path
        d="M 4 3.4 Q 7.2 6 10.6 3.4"
        stroke={PALETTE.ink}
        strokeWidth={1.8}
        strokeLinecap="round"
        fill="none"
      />
      <Circle cx={7} cy={0} r={9} fill={PALETTE.glassShade} fillOpacity={0.18} />
      {/* nose lamp */}
      <Circle
        cx={21}
        cy={0}
        r={3.4}
        fill={PALETTE.hullLight}
        stroke={PALETTE.ink}
        strokeWidth={2}
      />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* Chasing sea beast — big eyes, big grin, still hungry                      */
/* ------------------------------------------------------------------------- */

export const MonsterArt = memo(function MonsterArt() {
  const box = SPRITE_BOX.monster;
  const half = box / 2;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      {/* tentacles */}
      <Path
        d="M -20 8 Q -36 18 -46 8 M -20 -8 Q -36 -18 -46 -8 M -22 0 Q -42 2 -52 -4"
        stroke={PALETTE.monsterShade}
        strokeWidth={7}
        fill="none"
        strokeLinecap="round"
      />
      {/* back spines */}
      <Polygon
        points="-24,-14 -36,-26 -18,-22"
        fill={PALETTE.monsterShade}
        stroke={PALETTE.ink}
        strokeWidth={2}
        strokeLinejoin="round"
      />
      <Polygon
        points="-24,14 -36,26 -18,22"
        fill={PALETTE.monsterShade}
        stroke={PALETTE.ink}
        strokeWidth={2}
        strokeLinejoin="round"
      />
      {/* open maw behind the head */}
      <Path
        d="M 4 -16 Q 30 -20 34 0 Q 30 20 4 16 Z"
        fill={PALETTE.maw}
        stroke={PALETTE.ink}
        strokeWidth={2.5}
        strokeLinejoin="round"
      />
      <Path d="M 24 -6 Q 33 0 24 6 Q 29 0 24 -6 Z" fill={PALETTE.tongue} />
      <Polygon points="10,-13 20,-11 12,-5" fill={PALETTE.tooth} />
      <Polygon points="24,-9 30,-4 22,-3" fill={PALETTE.tooth} />
      <Polygon points="10,13 20,11 12,5" fill={PALETTE.tooth} />
      <Polygon points="24,9 30,4 22,3" fill={PALETTE.tooth} />
      {/* head */}
      <Circle cx={0} cy={0} r={25} fill={PALETTE.monster} stroke={PALETTE.ink} strokeWidth={3} />
      {/* belly / cheek highlight */}
      <Path
        d="M -25 0 A 25 25 0 0 0 12 22 A 22 22 0 0 1 -14 -14 Z"
        fill={PALETTE.monsterBelly}
        fillOpacity={0.35}
      />
      {/* spots */}
      <Circle cx={-14} cy={-4} r={3.4} fill={PALETTE.monsterShade} opacity={0.75} />
      <Circle cx={-9} cy={4} r={2.4} fill={PALETTE.monsterShade} opacity={0.75} />
      <Circle cx={-18} cy={6} r={2} fill={PALETTE.monsterShade} opacity={0.75} />
      {/* eyes */}
      <Circle cx={-1} cy={-11} r={8} fill="#ffffff" stroke={PALETTE.ink} strokeWidth={2.2} />
      <Circle cx={-1} cy={11} r={8} fill="#ffffff" stroke={PALETTE.ink} strokeWidth={2.2} />
      <Circle cx={2} cy={-11} r={4.2} fill="#ffb43d" />
      <Circle cx={2} cy={11} r={4.2} fill="#ffb43d" />
      <Circle cx={2.6} cy={-11} r={2.4} fill={PALETTE.ink} />
      <Circle cx={2.6} cy={11} r={2.4} fill={PALETTE.ink} />
      <Circle cx={0.4} cy={-13} r={1.5} fill="#ffffff" />
      <Circle cx={0.4} cy={9} r={1.5} fill="#ffffff" />
      {/* angry brows */}
      <Path d="M -9 -19 L 4 -17" stroke={PALETTE.ink} strokeWidth={3.4} strokeLinecap="round" />
      <Path d="M -9 19 L 4 17" stroke={PALETTE.ink} strokeWidth={3.4} strokeLinecap="round" />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* Dubloon coin                                                              */
/* ------------------------------------------------------------------------- */

export const DubloonArt = memo(function DubloonArt() {
  const box = SPRITE_BOX.dubloon;
  const half = box / 2;
  const r = GAME.dubloonRadius + 1;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Defs>
        <RadialGradient id="gold" cx="35%" cy="30%" r="80%">
          <Stop offset="0%" stopColor={PALETTE.dubloonLight} />
          <Stop offset="65%" stopColor={PALETTE.dubloon} />
          <Stop offset="100%" stopColor={PALETTE.dubloonEdge} />
        </RadialGradient>
      </Defs>
      <Circle cx={0} cy={0} r={r} fill="url(#gold)" stroke={PALETTE.ink} strokeWidth={2.4} />
      <Circle
        cx={0}
        cy={0}
        r={r * 0.72}
        fill="none"
        stroke={PALETTE.dubloonEdge}
        strokeWidth={1.6}
        strokeOpacity={0.8}
      />
      {/* embossed scallop shell */}
      <Path
        d="M 0 5.4 L -5.4 -1.6 Q 0 -6.4 5.4 -1.6 Z"
        fill={PALETTE.dubloonEdge}
        fillOpacity={0.9}
      />
      <Path
        d="M 0 5.4 L -2.2 -3.4 M 0 5.4 L 2.2 -3.4"
        stroke={PALETTE.dubloonLight}
        strokeWidth={1}
        strokeOpacity={0.8}
      />
      {/* gloss */}
      <Path
        d="M -6.4 -6 Q -2 -9.4 3 -7.6"
        stroke="#ffffff"
        strokeWidth={2.4}
        strokeLinecap="round"
        fill="none"
        opacity={0.85}
      />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* Hazard — a grumpy spiky urchin                                            */
/* ------------------------------------------------------------------------- */

const SPIKES = [0, 40, 80, 120, 160, 200, 240, 280, 320];

export const MineArt = memo(function MineArt() {
  const box = SPRITE_BOX.mine;
  const half = box / 2;
  const r = GAME.mineRadius;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      {SPIKES.map((a) => {
        const rad = (a * Math.PI) / 180;
        const perp = rad + Math.PI / 2;
        const baseR = r * 0.92;
        const tipR = r * 1.62;
        const halfWidth = 4;
        const bx = Math.cos(rad) * baseR;
        const by = Math.sin(rad) * baseR;
        const ox = Math.cos(perp) * halfWidth;
        const oy = Math.sin(perp) * halfWidth;
        return (
          <Polygon
            key={a}
            points={`${bx + ox},${by + oy} ${Math.cos(rad) * tipR},${Math.sin(rad) * tipR} ${bx - ox},${by - oy}`}
            fill={PALETTE.urchinSpike}
            stroke={PALETTE.ink}
            strokeWidth={1.6}
            strokeLinejoin="round"
          />
        );
      })}
      <Circle cx={0} cy={0} r={r} fill={PALETTE.urchin} stroke={PALETTE.ink} strokeWidth={2.6} />
      <Path d="M -14 0 A 14 14 0 0 0 14 0 Z" fill={PALETTE.urchinShade} fillOpacity={0.5} />
      <Path
        d="M -8 -7 Q -3 -10.5 3 -9"
        stroke="#ffffff"
        strokeWidth={2.2}
        strokeLinecap="round"
        fill="none"
        opacity={0.5}
      />
      {/* grumpy face */}
      <Circle cx={-4.6} cy={-1} r={4} fill="#ffffff" stroke={PALETTE.ink} strokeWidth={1.6} />
      <Circle cx={4.6} cy={-1} r={4} fill="#ffffff" stroke={PALETTE.ink} strokeWidth={1.6} />
      <Circle cx={-4} cy={-0.4} r={2} fill={PALETTE.ink} />
      <Circle cx={5.2} cy={-0.4} r={2} fill={PALETTE.ink} />
      <Path
        d="M -8.6 -6 L -1.6 -4.2 M 8.6 -6 L 1.6 -4.2"
        stroke={PALETTE.ink}
        strokeWidth={2.2}
        strokeLinecap="round"
      />
      <Path
        d="M -3.6 6.4 Q 0 3.6 3.6 6.4"
        stroke={PALETTE.ink}
        strokeWidth={2}
        strokeLinecap="round"
        fill="none"
      />
      <Polygon points="-1.6,5.6 1.2,5.6 -0.2,8.4" fill={PALETTE.tooth} />
    </Svg>
  );
});

export { PALETTE as GAME_PALETTE };
