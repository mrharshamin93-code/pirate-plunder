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
  Text as SvgText,
} from 'react-native-svg';

import { COIN_TIERS, GAME } from '@/lib/game/engine';

/**
 * All artwork here is original vector art authored for this game, drawn to
 * match the look of the original Pirate's Plunder: a top-down view of open
 * ocean in dark teal, a wooden rowboat seen from above, spiked black naval
 * mines and gold coin coins.
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

  krawk: '#57a94a',
  krawkDark: '#3b7a32',
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
  coin: 36,
  whirlpool: 170,
  explosion: 120,
  pawkeet: 132,
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
/* The Black Pawkeet — the ship firing the mines, seen on the horizon        */
/* ------------------------------------------------------------------------- */

export const PawkeetArt = memo(function PawkeetArt() {
  const box = SPRITE_BOX.pawkeet;
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
/* Captain Marlow's rowboat — top-down, bow pointing right                            */
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

      {/* Captain Marlow, a fearless treasure hunter, seen from above */}
      <G>
        {/* shoulders */}
        <Ellipse cx={-8} cy={0} rx={7} ry={8} fill={PALETTE.krawkDark} />
        {/* head */}
        <Circle
          cx={-4}
          cy={0}
          r={6.2}
          fill={PALETTE.krawk}
          stroke={PALETTE.ink}
          strokeWidth={1.8}
        />
        {/* snout toward the bow */}
        <Path
          d="M 1 -3 Q 7 0 1 3 Z"
          fill={PALETTE.krawkDark}
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
/* Homing mine — spiked iron sphere fired from the Pawkeet                   */
/* ------------------------------------------------------------------------- */

const SPIKE_COUNT = 10;

export const MineArt = memo(function MineArt() {
  const box = SPRITE_BOX.mine;
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
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
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

/** Coppers for the common coins, silver in the middle, gold for the jackpots. */
const COIN_METALS = [
  { face: '#c98a4b', rim: '#8d5a26', gloss: '#f0c68f', text: '#5c3312' },
  { face: '#c98a4b', rim: '#8d5a26', gloss: '#f0c68f', text: '#5c3312' },
  { face: '#cdd6dd', rim: '#8e9aa4', gloss: '#f4f8fb', text: '#43505a' },
  { face: '#cdd6dd', rim: '#8e9aa4', gloss: '#f4f8fb', text: '#43505a' },
  { face: '#ffd34a', rim: '#b8801a', gloss: '#fff3bd', text: '#6b4708' },
  { face: '#ffdc5e', rim: '#c08b1c', gloss: '#fff8d6', text: '#6b4708' },
  { face: '#ffe882', rim: '#d19a1f', gloss: '#fffbe6', text: '#6b4708' },
] as const;

const NOTCH_COUNT = 16;

export const CoinArt = memo(function CoinArt({ tier, size = SPRITE_BOX.coin }: { tier: number; size?: number }) {
  const box = SPRITE_BOX.coin;
  const half = box / 2;
  const index = Math.max(0, Math.min(COIN_TIERS.length - 1, tier));
  const metal = COIN_METALS[index];
  const value = COIN_TIERS[index].value;
  const r = 13;

  return (
    <Svg width={size} height={size} viewBox={`${-half} ${-half} ${box} ${box}`}>
      {/* milled edge */}
      {Array.from({ length: NOTCH_COUNT }, (_, i) => {
        const a = (i / NOTCH_COUNT) * Math.PI * 2;
        return (
          <Rect
            key={i}
            x={r - 1}
            y={-1.4}
            width={3}
            height={2.8}
            rx={1}
            fill={metal.rim}
            transform={`rotate(${(a * 180) / Math.PI})`}
          />
        );
      })}

      <Circle cx={0} cy={0} r={r} fill={metal.rim} />
      <Circle cx={0} cy={0} r={r - 2} fill={metal.face} />
      <Circle
        cx={0}
        cy={0}
        r={r - 4}
        fill="none"
        stroke={metal.rim}
        strokeWidth={1}
        opacity={0.6}
      />

      <SvgText
        x={0}
        y={value >= 100 ? 3.6 : 4}
        fill={metal.text}
        fontSize={value >= 100 ? 10 : 13}
        fontWeight="bold"
        textAnchor="middle"
      >
        {String(value)}
      </SvgText>

      {/* gloss crescent */}
      <Path
        d={`M ${-r + 3} -4 A ${r - 3} ${r - 3} 0 0 1 -1 ${-r + 3}`}
        stroke={metal.gloss}
        strokeWidth={2.4}
        strokeLinecap="round"
        fill="none"
        opacity={0.9}
      />
    </Svg>
  );
});

/* ------------------------------------------------------------------------- */
/* Whirlpool                                                                 */
/* ------------------------------------------------------------------------- */

const VORTEX_ARMS = 4;

export const WhirlpoolArt = memo(function WhirlpoolArt() {
  const box = SPRITE_BOX.whirlpool;
  const half = box / 2;
  // The current reaches beyond the visible funnel, as a real vortex does.
  const pullRadius = GAME.whirlpoolRange;
  const visualRadius = pullRadius * 0.68;
  const eye = GAME.whirlpoolCore * 0.88;

  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Defs>
        <RadialGradient id="deepSeaVortex" cx="50%" cy="50%" r="50%">
          <Stop offset="0%" stopColor="#000207" stopOpacity={1} />
          <Stop offset="20%" stopColor="#020b18" stopOpacity={0.98} />
          <Stop offset="48%" stopColor="#07354a" stopOpacity={0.94} />
          <Stop offset="78%" stopColor="#087b91" stopOpacity={0.72} />
          <Stop offset="100%" stopColor="#1bb4c6" stopOpacity={0.08} />
        </RadialGradient>
      </Defs>

      <Circle cx={0} cy={0} r={visualRadius} fill="url(#deepSeaVortex)" />

      {/* Four high-contrast turquoise currents curl into the black eye. */}
      {Array.from({ length: VORTEX_ARMS }, (_, index) => {
        const rotation = index * (360 / VORTEX_ARMS);
        return (
          <Path
            key={index}
            d={`M ${visualRadius - 4} 0 C ${visualRadius * 0.72} ${visualRadius * 0.42} ${visualRadius * 0.35} ${visualRadius * 0.5} ${eye * 0.72} ${eye * 0.2}`}
            fill="none"
            stroke={index % 2 === 0 ? '#32d5d2' : '#16a9bd'}
            strokeWidth={index % 2 === 0 ? 6 : 4.5}
            strokeLinecap="round"
            strokeOpacity={0.82}
            transform={`rotate(${rotation})`}
          />
        );
      })}

      {/* Concentric rings make the depth readable even at gameplay scale. */}
      {[0.82, 0.61, 0.42].map((scale, index) => (
        <Circle
          key={scale}
          cx={0}
          cy={0}
          r={visualRadius * scale}
          fill="none"
          stroke={index === 0 ? '#42ddd8' : '#159eb3'}
          strokeWidth={index === 0 ? 3.2 : 2.4}
          strokeOpacity={0.5 - index * 0.08}
          strokeDasharray={index === 0 ? '14 7' : '10 8'}
        />
      ))}

      {/* Broken white foam marks the outer pull boundary. */}
      <Circle
        cx={0}
        cy={0}
        r={visualRadius - 2}
        fill="none"
        stroke="#f4fdff"
        strokeWidth={4.5}
        strokeOpacity={0.9}
        strokeLinecap="round"
        strokeDasharray="13 6 4 7"
      />

      {/* Small wood fragments caught in the current. */}
      <G transform="rotate(18)">
        <Rect x={visualRadius * 0.55} y={-4} width={15} height={6} rx={2} fill="#8d562c" />
        <Rect x={visualRadius * 0.31} y={visualRadius * 0.3} width={11} height={5} rx={1.5} fill="#bb7a3e" transform="rotate(48)" />
        <Polygon points={`${-visualRadius * 0.52},-6 ${-visualRadius * 0.4},-2 ${-visualRadius * 0.49},4`} fill="#9f6736" />
        <Rect x={-8} y={-visualRadius * 0.62} width={13} height={5} rx={1} fill="#704221" transform="rotate(-22)" />
      </G>

      {/* Deep navy-to-black center. */}
      <Circle cx={0} cy={0} r={eye * 1.35} fill="#020812" />
      <Circle cx={0} cy={0} r={eye * 0.78} fill="#000104" />
      <Circle cx={-eye * 0.2} cy={-eye * 0.2} r={eye * 0.28} fill="#081527" opacity={0.7} />
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
