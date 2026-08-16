import { memo } from 'react';
import { Image, View } from 'react-native';
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

import { COIN_TIERS, GAME } from '@/lib/game/engine';

/**
 * All artwork here is original vector art authored for this game, drawn to
 * support Pirate's Plunder: a top-down view of open ocean in dark teal, a
 * wooden rowboat seen from above, spiked black naval mines and gold coins.
 *
 * Each sprite is a STATIC svg drawn once and never re-rendered: position,
 * rotation and pulsing are applied by the Reanimated wrappers in GameCanvas.
 * Every viewBox is centered on (0,0) and square, so the view's own center
 * matches the entity center — rotation about the view center is correct.
 * Sprites that face a direction point along +x (angle 0 = heading right).
 *
 * NOTE: react-native-svg (iOS/Android) cannot parse CSS `oklch()` color
 * functions, so these are pre-resolved to hex. Do not use oklch() in SVG props.
 */
const PALETTE = {
  ink: '#0a1a20',

  seaLight: '#1f7d92',
  seaMid: '#125a6e',
  seaDeep: '#082e3c',
  crest: '#4fb6cc',
  foam: '#d9f4fb',

  wood: '#9a6231',
  woodDark: '#6b3f1c',
  woodLight: '#c58c50',
  deck: '#b47a42',
  oar: '#8a5527',

  sailor: '#57a94a',
  sailorDark: '#3b7a32',
  bandana: '#c8322f',

  mineBody: '#25292e',
  mineShade: '#12161a',
  mineLight: '#555f68',
  mineRust: '#8d3a24',
  mineLamp: '#ffd24a',

  blast: '#ffe066',
  blastMid: '#ff9b3d',
  blastEdge: '#e2452c',
} as const;

/** Square canvas size (px) of each sprite's static svg. */
export const SPRITE_BOX = {
  boat: 84,
  mine: 56,
  coin: 32,
  whirlpool: 170,
  explosion: 120,
  raiderShip: 132,
} as const;

/* ------------------------------------------------------------------------- */
/* Ocean — top-down open water                                               */
/* ------------------------------------------------------------------------- */

/** Deterministic wave streaks, expressed as fractions of the screen. */
const WAVES = [
  { fx: 0.1, fy: 0.12, w: 0.16 },
  { fx: 0.62, fy: 0.09, w: 0.2 },
  { fx: 0.3, fy: 0.22, w: 0.12 },
  { fx: 0.76, fy: 0.28, w: 0.14 },
  { fx: 0.08, fy: 0.37, w: 0.18 },
  { fx: 0.46, fy: 0.44, w: 0.14 },
  { fx: 0.82, fy: 0.5, w: 0.12 },
  { fx: 0.2, fy: 0.57, w: 0.2 },
  { fx: 0.58, fy: 0.65, w: 0.16 },
  { fx: 0.12, fy: 0.74, w: 0.13 },
  { fx: 0.7, fy: 0.8, w: 0.18 },
  { fx: 0.36, fy: 0.88, w: 0.15 },
] as const;

const FLECKS = [
  { fx: 0.24, fy: 0.31 },
  { fx: 0.53, fy: 0.19 },
  { fx: 0.86, fy: 0.4 },
  { fx: 0.17, fy: 0.63 },
  { fx: 0.66, fy: 0.55 },
  { fx: 0.42, fy: 0.77 },
  { fx: 0.9, fy: 0.68 },
  { fx: 0.3, fy: 0.95 },
] as const;

export const OceanBackground = memo(function OceanBackground({
  width,
  height,
}: {
  width: number;
  height: number;
}) {
  return (
    <Svg width={width} height={height} style={{ position: 'absolute', left: 0, top: 0 }}>
      <Defs>
        <RadialGradient id="sea" cx="50%" cy="42%" r="78%">
          <Stop offset="0%" stopColor={PALETTE.seaLight} />
          <Stop offset="55%" stopColor={PALETTE.seaMid} />
          <Stop offset="100%" stopColor={PALETTE.seaDeep} />
        </RadialGradient>
        <LinearGradient id="hudShade" x1="0" y1="0" x2="0" y2="1">
          <Stop offset="0%" stopColor={PALETTE.seaDeep} stopOpacity={0.7} />
          <Stop offset="100%" stopColor={PALETTE.seaDeep} stopOpacity={0} />
        </LinearGradient>
      </Defs>

      <Rect x={0} y={0} width={width} height={height} fill="url(#sea)" />

      {/* wave crests, drawn as flat lazy S strokes so the water reads top-down */}
      {WAVES.map((wave) => {
        const x = width * wave.fx;
        const y = height * wave.fy;
        const w = width * wave.w;
        return (
          <Path
            key={`${wave.fx}-${wave.fy}`}
            d={`M ${x} ${y} q ${w * 0.25} -5 ${w * 0.5} 0 q ${w * 0.25} 5 ${w * 0.5} 0`}
            stroke={PALETTE.crest}
            strokeOpacity={0.28}
            strokeWidth={3}
            strokeLinecap="round"
            fill="none"
          />
        );
      })}

      {FLECKS.map((f) => (
        <Circle
          key={`${f.fx}-${f.fy}`}
          cx={width * f.fx}
          cy={height * f.fy}
          r={2.5}
          fill={PALETTE.foam}
          fillOpacity={0.3}
        />
      ))}

      {/* keeps the HUD readable over the brighter middle water */}
      <Rect x={0} y={0} width={width} height={170} fill="url(#hudShade)" />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* The Dreadwake — the raider ship firing mines from the horizon             */
/* ------------------------------------------------------------------------- */

export const RaiderShipArt = memo(function RaiderShipArt() {
  const box = SPRITE_BOX.raiderShip;
  const half = box / 2;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      {/* masts */}
      <Path
        d="M -22 6 L -22 -46 M 0 8 L 0 -56 M 22 6 L 22 -42"
        stroke={PALETTE.ink}
        strokeWidth={3}
        strokeLinecap="round"
      />
      {/* sails, tattered pirate canvas */}
      <Path d="M -20 -44 Q -2 -36 -20 -8 Z" fill={PALETTE.ink} opacity={0.92} />
      <Path d="M 2 -54 Q 24 -42 2 -6 Z" fill={PALETTE.ink} opacity={0.92} />
      <Path d="M -24 -40 Q -44 -28 -24 -10 Z" fill={PALETTE.ink} opacity={0.82} />
      {/* jolly roger pennant */}
      <Path d="M 0 -56 L 18 -50 L 0 -46 Z" fill={PALETTE.bandana} opacity={0.9} />
      {/* hull */}
      <Path
        d="M -46 6 L 46 6 Q 40 24 26 26 L -28 26 Q -42 24 -46 6 Z"
        fill={PALETTE.ink}
        opacity={0.95}
      />
      <Path d="M -44 10 L 44 10" stroke={PALETTE.woodDark} strokeWidth={2.5} opacity={0.6} />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* Captain Marlow's rowboat — top-down, bow pointing right                   */
/* ------------------------------------------------------------------------- */

const HULL_PATH =
  'M 30 0 C 24 -11, 6 -16, -12 -15 Q -24 -14 -24 0 Q -24 14 -12 15 C 6 16, 24 11, 30 0 Z';
const DECK_PATH =
  'M 23 0 C 18 -8, 4 -11.5, -10 -11 Q -19 -10 -19 0 Q -19 10 -10 11 C 4 11.5, 18 8, 23 0 Z';

export const BoatArt = memo(function BoatArt() {
  const box = SPRITE_BOX.boat;
  const half = box / 2;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      {/* oars, angled back from the rowlocks */}
      <G>
        <Path
          d="M -4 -9 L -17 -30"
          stroke={PALETTE.oar}
          strokeWidth={4}
          strokeLinecap="round"
          fill="none"
        />
        <Ellipse
          cx={-19}
          cy={-34}
          rx={4}
          ry={7}
          fill={PALETTE.woodLight}
          stroke={PALETTE.woodDark}
          strokeWidth={2}
          transform="rotate(30 -19 -34)"
        />
        <Path
          d="M -4 9 L -17 30"
          stroke={PALETTE.oar}
          strokeWidth={4}
          strokeLinecap="round"
          fill="none"
        />
        <Ellipse
          cx={-19}
          cy={34}
          rx={4}
          ry={7}
          fill={PALETTE.woodLight}
          stroke={PALETTE.woodDark}
          strokeWidth={2}
          transform="rotate(-30 -19 34)"
        />
      </G>

      {/* hull */}
      <Path
        d={HULL_PATH}
        fill={PALETTE.woodDark}
        stroke={PALETTE.ink}
        strokeWidth={2.5}
        strokeLinejoin="round"
      />
      {/* inner deck */}
      <Path d={DECK_PATH} fill={PALETTE.deck} />
      {/* planking */}
      <Path
        d="M -14 -9 L -14 9 M -6 -10.5 L -6 10.5 M 4 -10 L 4 10 M 13 -7.5 L 13 7.5"
        stroke={PALETTE.woodDark}
        strokeWidth={1.6}
        opacity={0.55}
      />
      {/* thwarts */}
      <Rect x={-2} y={-11} width={5} height={22} rx={1.5} fill={PALETTE.wood} />
      <Rect x={14} y={-8} width={4} height={16} rx={1.5} fill={PALETTE.wood} />
      {/* gunwale highlight along the sunlit side */}
      <Path
        d="M 24 -6 C 16 -12, 2 -14.5, -11 -13.5"
        stroke={PALETTE.woodLight}
        strokeWidth={2}
        strokeLinecap="round"
        fill="none"
        opacity={0.85}
      />

      {/* Captain Marlow, seen from above */}
      <G>
        {/* shoulders */}
        <Ellipse cx={-8} cy={0} rx={7} ry={8} fill={PALETTE.sailorDark} />
        {/* head */}
        <Circle
          cx={-4}
          cy={0}
          r={6.2}
          fill={PALETTE.sailor}
          stroke={PALETTE.ink}
          strokeWidth={1.8}
        />
        {/* snout toward the bow */}
        <Path
          d="M 1 -3 Q 7 0 1 3 Z"
          fill={PALETTE.sailorDark}
          stroke={PALETTE.ink}
          strokeWidth={1.4}
        />
        {/* bandana with a knot trailing astern */}
        <Path d="M -10.2 -4.6 A 6.2 6.2 0 0 1 -10.2 4.6 Z" fill={PALETTE.bandana} />
        <Path
          d="M -10 -1 L -16 -5 M -10 1 L -16 5"
          stroke={PALETTE.bandana}
          strokeWidth={2.4}
          strokeLinecap="round"
        />
        <Circle cx={-2.5} cy={-3} r={1.2} fill={PALETTE.ink} />
        <Circle cx={-2.5} cy={3} r={1.2} fill={PALETTE.ink} />
      </G>

      {/* treasure sack in the stern */}
      <Ellipse
        cx={-17}
        cy={0}
        rx={4.6}
        ry={5.4}
        fill="#c9a227"
        stroke={PALETTE.woodDark}
        strokeWidth={1.6}
      />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* Homing mine — spiked iron sphere fired from the raider ship               */
/* ------------------------------------------------------------------------- */

const SPIKE_COUNT = 10;

export const MineArt = memo(function MineArt({ size }: { size?: number }) {
  const box = SPRITE_BOX.mine;
  const renderedSize = size ?? box;
  const half = box / 2;
  const bodyR = 13;
  const spikes = Array.from({ length: SPIKE_COUNT }, (_, i) => {
    const a = (i / SPIKE_COUNT) * Math.PI * 2;
    const baseA = 0.2;
    const tipX = Math.cos(a) * (bodyR + 9);
    const tipY = Math.sin(a) * (bodyR + 9);
    const b1x = Math.cos(a - baseA) * bodyR;
    const b1y = Math.sin(a - baseA) * bodyR;
    const b2x = Math.cos(a + baseA) * bodyR;
    const b2y = Math.sin(a + baseA) * bodyR;
    return { key: i, points: `${tipX},${tipY} ${b1x},${b1y} ${b2x},${b2y}` };
  });

  return (
    <Svg width={renderedSize} height={renderedSize} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Defs>
        <RadialGradient id="mineBody" cx="35%" cy="30%" r="75%">
          <Stop offset="0%" stopColor={PALETTE.mineLight} />
          <Stop offset="55%" stopColor={PALETTE.mineBody} />
          <Stop offset="100%" stopColor={PALETTE.mineShade} />
        </RadialGradient>
      </Defs>

      {spikes.map((s) => (
        <Polygon
          key={s.key}
          points={s.points}
          fill={PALETTE.mineBody}
          stroke={PALETTE.ink}
          strokeWidth={1.6}
          strokeLinejoin="round"
        />
      ))}

      <Circle
        cx={0}
        cy={0}
        r={bodyR}
        fill="url(#mineBody)"
        stroke={PALETTE.ink}
        strokeWidth={2.2}
      />
      {/* rusted band and rivets */}
      <Path
        d={`M ${-bodyR + 1} 2 A ${bodyR} ${bodyR} 0 0 0 ${bodyR - 1} 2`}
        stroke={PALETTE.mineRust}
        strokeWidth={2.6}
        fill="none"
        opacity={0.85}
      />
      <Circle cx={-6} cy={6} r={1.3} fill={PALETTE.mineLight} opacity={0.7} />
      <Circle cx={6} cy={6} r={1.3} fill={PALETTE.mineLight} opacity={0.7} />
      {/* trigger lamp */}
      <Circle
        cx={0}
        cy={-4}
        r={3.2}
        fill={PALETTE.mineLamp}
        stroke={PALETTE.ink}
        strokeWidth={1.6}
      />
      {/* gloss */}
      <Path
        d="M -8 -7 Q -3 -11 3 -9.5"
        stroke="#ffffff"
        strokeOpacity={0.45}
        strokeWidth={2}
        strokeLinecap="round"
        fill="none"
      />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* Coin coins — one static sprite per denomination                        */
/* ------------------------------------------------------------------------- */

const COIN_SHEET_SIZE = 1254;
const COIN_SPRITES = [
  { cx: 164, cy: 427, diameter: 306 }, // 10 points
  { cx: 474, cy: 427, diameter: 302 }, // 25 points
  { cx: 780, cy: 427, diameter: 302 }, // 50 points
  { cx: 165, cy: 848, diameter: 316 }, // 100 points
  { cx: 483, cy: 849, diameter: 320 }, // 250 points (former 500 artwork)
  { cx: 1090, cy: 427, diameter: 302 }, // 500 points (shiny silver artwork)
  { cx: 872, cy: 844, diameter: 386 }, // 1,000 points
] as const;

const COIN_SHEET = require('../../assets/images/treasure-coins-3d-v10.png');

export const CoinArt = memo(function CoinArt({ tier, size }: { tier: number; size?: number }) {
  const index = Math.max(0, Math.min(COIN_TIERS.length - 1, tier));
  const renderedSize = size ?? SPRITE_BOX.coin;
  const sprite = COIN_SPRITES[index];
  const scale = renderedSize / sprite.diameter;
  const sheetSize = COIN_SHEET_SIZE * scale;

  return (
    <View style={{ width: renderedSize, height: renderedSize, overflow: 'hidden' }}>
      <Image
        source={COIN_SHEET}
        resizeMode="stretch"
        style={{
          position: 'absolute',
          width: sheetSize,
          height: sheetSize,
          left: renderedSize / 2 - sprite.cx * scale,
          top: renderedSize / 2 - sprite.cy * scale,
        }}
      />
    </View>
  );
});

/* ------------------------------------------------------------------------- */
/* Whirlpool                                                                 */
/* ------------------------------------------------------------------------- */

const ARM_COUNT = 5;

export const WhirlpoolArt = memo(function WhirlpoolArt() {
  const box = SPRITE_BOX.whirlpool;
  const half = box / 2;
  /** taken straight from the rules, so the drag you feel is the water you see */
  const reach = GAME.whirlpoolRange;
  const eye = GAME.whirlpoolCore;
  const outer = reach * 0.83;

  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Defs>
        <RadialGradient id="vortex" cx="50%" cy="50%" r="50%">
          <Stop offset="0%" stopColor="#03151d" stopOpacity={0.95} />
          <Stop offset="42%" stopColor={PALETTE.seaDeep} stopOpacity={0.72} />
          <Stop offset="100%" stopColor={PALETTE.seaDeep} stopOpacity={0} />
        </RadialGradient>
      </Defs>

      <Circle cx={0} cy={0} r={reach} fill="url(#vortex)" />

      {/* foam arms spiralling into the eye */}
      {Array.from({ length: ARM_COUNT }, (_, i) => {
        const a = (i / ARM_COUNT) * Math.PI * 2;
        const deg = (a * 180) / Math.PI;
        return (
          <Path
            key={i}
            d={`M ${outer - 4} 0 C ${outer * 0.6} ${outer * 0.42} ${outer * 0.2} ${
              outer * 0.4
            } ${eye * 0.6} 3`}
            stroke={PALETTE.foam}
            strokeOpacity={0.5}
            strokeWidth={3}
            strokeLinecap="round"
            fill="none"
            transform={`rotate(${deg})`}
          />
        );
      })}

      {/* the outer ripple marks exactly where the water starts to take hold */}
      <Circle
        cx={0}
        cy={0}
        r={reach - 2}
        fill="none"
        stroke={PALETTE.foam}
        strokeOpacity={0.22}
        strokeWidth={2}
      />
      <Circle
        cx={0}
        cy={0}
        r={outer - 3}
        fill="none"
        stroke={PALETTE.crest}
        strokeOpacity={0.35}
        strokeWidth={2}
      />
      <Circle
        cx={0}
        cy={0}
        r={outer * 0.62}
        fill="none"
        stroke={PALETTE.crest}
        strokeOpacity={0.28}
        strokeWidth={1.8}
      />

      {/* the eye */}
      <Circle cx={0} cy={0} r={eye} fill="#02121a" />
      <Circle
        cx={0}
        cy={0}
        r={eye}
        fill="none"
        stroke={PALETTE.foam}
        strokeOpacity={0.6}
        strokeWidth={2}
      />
      <Circle cx={0} cy={0} r={eye * 0.46} fill="#000000" opacity={0.85} />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* Mine explosion                                                            */
/* ------------------------------------------------------------------------- */

const BURST_COUNT = 12;

export const ExplosionArt = memo(function ExplosionArt() {
  const box = SPRITE_BOX.explosion;
  const half = box / 2;
  const inner = 20;
  const outer = 48;

  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      {Array.from({ length: BURST_COUNT }, (_, i) => {
        const a = (i / BURST_COUNT) * Math.PI * 2;
        const spread = 0.14;
        const len = i % 2 === 0 ? outer : outer * 0.72;
        return (
          <Polygon
            key={i}
            points={`${Math.cos(a) * len},${Math.sin(a) * len} ${Math.cos(a - spread) * inner},${
              Math.sin(a - spread) * inner
            } ${Math.cos(a + spread) * inner},${Math.sin(a + spread) * inner}`}
            fill={PALETTE.blastEdge}
            opacity={0.9}
          />
        );
      })}
      <Circle cx={0} cy={0} r={26} fill={PALETTE.blastMid} />
      <Circle cx={0} cy={0} r={16} fill={PALETTE.blast} />
      <Circle cx={0} cy={0} r={7} fill="#ffffff" />
      <Circle
        cx={0}
        cy={0}
        r={outer}
        fill="none"
        stroke={PALETTE.blast}
        strokeOpacity={0.6}
        strokeWidth={3}
      />
    </Svg>
  );
});
