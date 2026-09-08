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

export const SPRITE_BOX = {
  boat: 84,
  mine: 56,
  coin: 32,
  wake: 34,
  whirlpool: 170,
  explosion: 120,
  raiderShip: 132,
} as const;

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

      <Rect x={0} y={0} width={width} height={170} fill="url(#hudShade)" />
    </Svg>
  );
});

export const RaiderShipArt = memo(function RaiderShipArt() {
  const box = SPRITE_BOX.raiderShip;
  const half = box / 2;

  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Path
        d="M -22 6 L -22 -46 M 0 8 L 0 -56 M 22 6 L 22 -42"
        stroke={PALETTE.ink}
        strokeWidth={3}
        strokeLinecap="round"
      />
      <Path d="M -20 -44 Q -2 -36 -20 -8 Z" fill={PALETTE.ink} opacity={0.92} />
      <Path d="M 2 -54 Q 24 -42 2 -6 Z" fill={PALETTE.ink} opacity={0.92} />
      <Path d="M -24 -40 Q -44 -28 -24 -10 Z" fill={PALETTE.ink} opacity={0.82} />
      <Path d="M 0 -56 L 18 -50 L 0 -46 Z" fill={PALETTE.bandana} opacity={0.9} />
      <Path
        d="M -46 6 L 46 6 Q 40 24 26 26 L -28 26 Q -42 24 -46 6 Z"
        fill={PALETTE.ink}
        opacity={0.95}
      />
      <Path d="M -44 10 L 44 10" stroke={PALETTE.woodDark} strokeWidth={2.5} opacity={0.6} />
    </Svg>
  );
});

const HULL_PATH =
  'M 30 0 C 24 -11, 6 -16, -12 -15 Q -24 -14 -24 0 Q -24 14 -12 15 C 6 16, 24 11, 30 0 Z';

const DECK_PATH =
  'M 23 0 C 18 -8, 4 -11.5, -10 -11 Q -19 -10 -19 0 Q -19 10 -10 11 C 4 11.5, 18 8, 23 0 Z';

export const BoatArt = memo(function BoatArt() {
  const box = SPRITE_BOX.boat;
  const half = box / 2;

  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <G>
        <Path d="M -4 -9 L -17 -30" stroke={PALETTE.oar} strokeWidth={4} strokeLinecap="round" fill="none" />
        <Ellipse cx={-19} cy={-34} rx={4} ry={7} fill={PALETTE.woodLight} stroke={PALETTE.woodDark} strokeWidth={2} transform="rotate(30 -19 -34)" />
        <Path d="M -4 9 L -17 30" stroke={PALETTE.oar} strokeWidth={4} strokeLinecap="round" fill="none" />
        <Ellipse cx={-19} cy={34} rx={4} ry={7} fill={PALETTE.woodLight} stroke={PALETTE.woodDark} strokeWidth={2} transform="rotate(-30 -19 34)" />
      </G>
      <Path d={HULL_PATH} fill={PALETTE.woodDark} stroke={PALETTE.ink} strokeWidth={2.5} strokeLinejoin="round" />
      <Path d={DECK_PATH} fill={PALETTE.deck} />
      <Path d="M -14 -9 L -14 9 M -6 -10.5 L -6 10.5 M 4 -10 L 4 10 M 13 -7.5 L 13 7.5" stroke={PALETTE.woodDark} strokeWidth={1.6} opacity={0.55} />
      <Rect x={-2} y={-11} width={5} height={22} rx={1.5} fill={PALETTE.wood} />
      <Rect x={14} y={-8} width={4} height={16} rx={1.5} fill={PALETTE.wood} />
      <Path d="M 24 -6 C 16 -12, 2 -14.5, -11 -13.5" stroke={PALETTE.woodLight} strokeWidth={2} strokeLinecap="round" fill="none" opacity={0.85} />
      <G>
        <Ellipse cx={-8} cy={0} rx={7} ry={8} fill={PALETTE.sailorDark} />
        <Circle cx={-4} cy={0} r={6.2} fill={PALETTE.sailor} stroke={PALETTE.ink} strokeWidth={1.8} />
        <Path d="M 1 -3 Q 7 0 1 3 Z" fill={PALETTE.sailorDark} stroke={PALETTE.ink} strokeWidth={1.4} />
        <Path d="M -10.2 -4.6 A 6.2 6.2 0 0 1 -10.2 4.6 Z" fill={PALETTE.bandana} />
        <Path d="M -10 -1 L -16 -5 M -10 1 L -16 5" stroke={PALETTE.bandana} strokeWidth={2.4} strokeLinecap="round" />
        <Circle cx={-2.5} cy={-3} r={1.2} fill={PALETTE.ink} />
        <Circle cx={-2.5} cy={3} r={1.2} fill={PALETTE.ink} />
      </G>
      <Ellipse cx={-17} cy={0} rx={4.6} ry={5.4} fill="#c9a227" stroke={PALETTE.woodDark} strokeWidth={1.6} />
    </Svg>
  );
});

export const WakeArt = memo(function WakeArt() {
  const box = SPRITE_BOX.wake;
  const half = box / 2;

  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Defs>
        <LinearGradient id="wakeFade" x1="0" y1="0" x2="1" y2="0">
          <Stop offset="0%" stopColor="#ffffff" stopOpacity={0.08} />
          <Stop offset="35%" stopColor={PALETTE.foam} stopOpacity={0.92} />
          <Stop offset="100%" stopColor="#ffffff" stopOpacity={0} />
        </LinearGradient>
      </Defs>
      <Path d="M -14 0 C -9 -4.5, 0 -5.5, 14 0" stroke="url(#wakeFade)" strokeWidth={3.2} strokeLinecap="round" fill="none" />
      <Path d="M -11 5 C -4 1.5, 4 1, 11 3" stroke={PALETTE.foam} strokeOpacity={0.42} strokeWidth={1.8} strokeLinecap="round" fill="none" />
      <Circle cx={4} cy={-5} r={1.4} fill={PALETTE.foam} fillOpacity={0.7} />
      <Circle cx={9} cy={3} r={1} fill={PALETTE.foam} fillOpacity={0.5} />
      <Circle cx={-2} cy={6} r={0.8} fill={PALETTE.foam} fillOpacity={0.42} />
    </Svg>
  );
});

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
        <Polygon key={s.key} points={s.points} fill={PALETTE.mineBody} stroke={PALETTE.ink} strokeWidth={1.6} strokeLinejoin="round" />
      ))}
      <Circle cx={0} cy={0} r={bodyR} fill="url(#mineBody)" stroke={PALETTE.ink} strokeWidth={2.2} />
      <Path d={`M ${-bodyR + 1} 2 A ${bodyR} ${bodyR} 0 0 0 ${bodyR - 1} 2`} stroke={PALETTE.mineRust} strokeWidth={2.6} fill="none" opacity={0.85} />
      <Circle cx={-6} cy={6} r={1.3} fill={PALETTE.mineLight} opacity={0.7} />
      <Circle cx={6} cy={6} r={1.3} fill={PALETTE.mineLight} opacity={0.7} />
      <Circle cx={0} cy={-4} r={3.2} fill={PALETTE.mineLamp} stroke={PALETTE.ink} strokeWidth={1.6} />
      <Path d="M -8 -7 Q -3 -11 3 -9.5" stroke="#ffffff" strokeOpacity={0.45} strokeWidth={2} strokeLinecap="round" fill="none" />
    </Svg>
  );
});

const COIN_SHEET_SIZE = 1254;
const COIN_SPRITES = [
  { cx: 164, cy: 427, diameter: 306 },
  { cx: 474, cy: 427, diameter: 302 },
  { cx: 780, cy: 427, diameter: 302 },
  { cx: 165, cy: 848, diameter: 316 },
  { cx: 483, cy: 849, diameter: 320 },
  { cx: 1090, cy: 427, diameter: 302 },
  { cx: 872, cy: 844, diameter: 386 },
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

const WHIRLPOOL_VISUAL_RADIUS = 70;
const WHIRLPOOL_ARMS = [
  { rotate: 0, opacity: 0.92, width: 7.2 },
  { rotate: 58, opacity: 0.84, width: 6.6 },
  { rotate: 118, opacity: 0.76, width: 6.0 },
  { rotate: 181, opacity: 0.68, width: 5.4 },
  { rotate: 242, opacity: 0.60, width: 4.8 },
  { rotate: 302, opacity: 0.52, width: 4.2 },
] as const;

export const WhirlpoolArt = memo(function WhirlpoolArt() {
  const box = SPRITE_BOX.whirlpool;
  const half = box / 2;
  const outer = WHIRLPOOL_VISUAL_RADIUS;
  const eye = Math.max(5, GAME.whirlpoolCore * 0.48);

  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Defs>
        <RadialGradient id="whirlpoolWater" cx="47%" cy="45%" r="56%">
          <Stop offset="0%" stopColor="#00070c" stopOpacity={1} />
          <Stop offset="13%" stopColor="#01131e" stopOpacity={1} />
          <Stop offset="32%" stopColor="#032f43" stopOpacity={0.99} />
          <Stop offset="56%" stopColor="#075a75" stopOpacity={0.94} />
          <Stop offset="78%" stopColor="#0b7792" stopOpacity={0.78} />
          <Stop offset="100%" stopColor="#42bfd0" stopOpacity={0} />
        </RadialGradient>
        <RadialGradient id="whirlpoolEye" cx="46%" cy="43%" r="58%">
          <Stop offset="0%" stopColor="#000000" stopOpacity={1} />
          <Stop offset="60%" stopColor="#00070b" stopOpacity={1} />
          <Stop offset="100%" stopColor="#063247" stopOpacity={0.96} />
        </RadialGradient>
      </Defs>

      <Circle cx={0} cy={0} r={outer} fill="url(#whirlpoolWater)" />

      <Path
        d="M -68 -16 C -50 -41 -19 -56 18 -52 C 43 -49 60 -36 68 -18"
        stroke="#e7fbff"
        strokeOpacity={0.42}
        strokeWidth={3.8}
        strokeLinecap="round"
        fill="none"
      />
      <Path
        d="M -64 28 C -43 49 -13 57 18 49 C 42 43 58 28 65 11"
        stroke="#c6f3f8"
        strokeOpacity={0.34}
        strokeWidth={3.1}
        strokeLinecap="round"
        fill="none"
      />

      {WHIRLPOOL_ARMS.map((arm, index) => (
        <G key={index} transform={`rotate(${arm.rotate})`}>
          <Path
            d="M 67 -3 C 53 12 43 23 27 28 C 11 33 -3 25 -10 14 C -14 8 -14 3 -11 -2"
            stroke="#e5fbff"
            strokeOpacity={arm.opacity}
            strokeWidth={arm.width}
            strokeLinecap="round"
            fill="none"
          />
          <Path
            d="M 64 4 C 50 19 38 29 22 32 C 9 34 -2 29 -9 20"
            stroke="#4cbfd4"
            strokeOpacity={Math.max(0.26, arm.opacity - 0.34)}
            strokeWidth={Math.max(2.2, arm.width * 0.46)}
            strokeLinecap="round"
            fill="none"
          />
        </G>
      ))}

      <Path
        d="M 42 -43 C 25 -51 4 -54 -18 -46"
        stroke="#ffffff"
        strokeOpacity={0.58}
        strokeWidth={3.1}
        strokeLinecap="round"
        fill="none"
      />
      <Path
        d="M -56 29 C -41 44 -23 50 -6 48"
        stroke="#ffffff"
        strokeOpacity={0.46}
        strokeWidth={2.7}
        strokeLinecap="round"
        fill="none"
      />
      <Path
        d="M 16 52 C 35 47 49 38 56 27"
        stroke="#dffcff"
        strokeOpacity={0.4}
        strokeWidth={2.3}
        strokeLinecap="round"
        fill="none"
      />

      <Circle cx={0} cy={0} r={eye * 1.85} fill="url(#whirlpoolEye)" />
      <Circle cx={0} cy={0} r={eye} fill="#000000" opacity={0.99} />
      <Circle
        cx={0}
        cy={0}
        r={eye * 2.25}
        fill="none"
        stroke="#5bb8ca"
        strokeOpacity={0.28}
        strokeWidth={2.4}
      />

      <Circle cx={-67} cy={-18} r={2.2} fill="#dffbff" opacity={0.72} />
      <Circle cx={-70} cy={15} r={1.6} fill="#a9eaf3" opacity={0.68} />
      <Circle cx={61} cy={-31} r={2.4} fill="#e8fdff" opacity={0.75} />
      <Circle cx={68} cy={12} r={1.8} fill="#bceff6" opacity={0.72} />
      <Circle cx={49} cy={49} r={1.7} fill="#e7fdff" opacity={0.66} />
      <Circle cx={-39} cy={57} r={1.9} fill="#c8f5fa" opacity={0.64} />
      <Circle cx={8} cy={-69} r={1.5} fill="#ffffff" opacity={0.7} />
    </Svg>
  );
});

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
            points={`${Math.cos(a) * len},${Math.sin(a) * len} ${Math.cos(a - spread) * inner},${Math.sin(a - spread) * inner} ${Math.cos(a + spread) * inner},${Math.sin(a + spread) * inner}`}
            fill={PALETTE.blastEdge}
            opacity={0.9}
          />
        );
      })}
      <Circle cx={0} cy={0} r={26} fill={PALETTE.blastMid} />
      <Circle cx={0} cy={0} r={16} fill={PALETTE.blast} />
      <Circle cx={0} cy={0} r={7} fill="#ffffff" />
      <Circle cx={0} cy={0} r={outer} fill="none" stroke={PALETTE.blast} strokeOpacity={0.6} strokeWidth={3} />
    </Svg>
  );
});
