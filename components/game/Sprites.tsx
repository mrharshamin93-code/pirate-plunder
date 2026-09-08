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

export const WhirlpoolArt = memo(function WhirlpoolArt() {
  const box = SPRITE_BOX.whirlpool;
  const half = box / 2;
  const outer = WHIRLPOOL_VISUAL_RADIUS;
  const eye = Math.max(4.5, GAME.whirlpoolCore * 0.4);

  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Defs>
        <RadialGradient id="deepBasin" cx="49%" cy="47%" r="57%">
          <Stop offset="0%" stopColor="#000205" />
          <Stop offset="12%" stopColor="#00070c" />
          <Stop offset="26%" stopColor="#011824" />
          <Stop offset="43%" stopColor="#032f42" />
          <Stop offset="63%" stopColor="#07566d" stopOpacity={0.96} />
          <Stop offset="82%" stopColor="#0a7187" stopOpacity={0.62} />
          <Stop offset="100%" stopColor="#2aa7ba" stopOpacity={0} />
        </RadialGradient>
        <RadialGradient id="deepPit" cx="46%" cy="44%" r="62%">
          <Stop offset="0%" stopColor="#000000" />
          <Stop offset="55%" stopColor="#000306" />
          <Stop offset="100%" stopColor="#062632" stopOpacity={0.9} />
        </RadialGradient>
      </Defs>

      <Circle cx={0} cy={0} r={outer} fill="url(#deepBasin)" />

      <Ellipse cx={-2} cy={1} rx={61} ry={52} fill="none" stroke="#4da9b7" strokeOpacity={0.2} strokeWidth={5.5} transform="rotate(-11)" />
      <Ellipse cx={1} cy={-1} rx={50} ry={41} fill="none" stroke="#72c5cf" strokeOpacity={0.19} strokeWidth={5} transform="rotate(16)" />
      <Ellipse cx={-1} cy={1} rx={39} ry={31} fill="none" stroke="#9bdddf" strokeOpacity={0.17} strokeWidth={4.5} transform="rotate(-18)" />
      <Ellipse cx={1} cy={0} rx={29} ry={22} fill="none" stroke="#b9edf0" strokeOpacity={0.15} strokeWidth={3.8} transform="rotate(12)" />

      <Path d="M -67 -18 C -57 -41 -36 -55 -10 -59 C 9 -62 29 -57 43 -47 C 54 -39 62 -27 66 -15" stroke="#d9f5f7" strokeOpacity={0.48} strokeWidth={4.2} strokeLinecap="round" fill="none" />
      <Path d="M -62 21 C -52 41 -31 55 -7 59 C 15 62 38 54 52 39 C 59 31 64 22 66 13" stroke="#b7e8ec" strokeOpacity={0.4} strokeWidth={3.5} strokeLinecap="round" fill="none" />
      <Path d="M -49 -43 C -34 -51 -16 -54 2 -50 C 16 -47 28 -40 37 -30" stroke="#ffffff" strokeOpacity={0.54} strokeWidth={3.2} strokeLinecap="round" fill="none" />
      <Path d="M 41 39 C 26 49 8 52 -9 48 C -24 45 -35 37 -42 27" stroke="#eefeff" strokeOpacity={0.44} strokeWidth={2.8} strokeLinecap="round" fill="none" />

      <Path d="M -59 4 C -51 -12 -38 -22 -23 -24 C -10 -26 1 -21 6 -12 C 10 -5 8 2 3 7" stroke="#79c9d3" strokeOpacity={0.58} strokeWidth={5.2} strokeLinecap="round" fill="none" />
      <Path d="M 58 -8 C 50 9 38 20 24 23 C 11 26 1 22 -5 14 C -9 8 -9 2 -5 -3" stroke="#a9e4e8" strokeOpacity={0.5} strokeWidth={4.7} strokeLinecap="round" fill="none" />
      <Path d="M -31 48 C -17 39 -6 29 -2 18 C 2 8 -1 1 -8 -3" stroke="#c5eef1" strokeOpacity={0.38} strokeWidth={3.6} strokeLinecap="round" fill="none" />
      <Path d="M 30 -46 C 18 -38 8 -29 4 -19 C 0 -9 2 -2 8 2" stroke="#8fd4db" strokeOpacity={0.34} strokeWidth={3.3} strokeLinecap="round" fill="none" />

      <Path d="M -70 -6 C -65 -3 -60 -4 -55 -8" stroke="#ffffff" strokeOpacity={0.72} strokeWidth={2.6} strokeLinecap="round" fill="none" />
      <Path d="M -54 46 C -48 49 -42 48 -37 44" stroke="#f4ffff" strokeOpacity={0.62} strokeWidth={2.4} strokeLinecap="round" fill="none" />
      <Path d="M 53 -43 C 59 -39 63 -34 65 -28" stroke="#ffffff" strokeOpacity={0.67} strokeWidth={2.5} strokeLinecap="round" fill="none" />
      <Path d="M 59 30 C 55 36 50 41 44 44" stroke="#dff9fb" strokeOpacity={0.56} strokeWidth={2.2} strokeLinecap="round" fill="none" />

      <Circle cx={-66} cy={-29} r={2.2} fill="#efffff" opacity={0.68} />
      <Circle cx={-71} cy={10} r={1.5} fill="#bdeef2" opacity={0.58} />
      <Circle cx={-49} cy={55} r={1.8} fill="#ffffff" opacity={0.64} />
      <Circle cx={10} cy={-66} r={1.6} fill="#dffbfc" opacity={0.62} />
      <Circle cx={52} cy={-49} r={2.1} fill="#efffff" opacity={0.69} />
      <Circle cx={69} cy={17} r={1.7} fill="#c8f1f4" opacity={0.62} />
      <Circle cx={39} cy={57} r={1.4} fill="#ffffff" opacity={0.58} />

      <Ellipse cx={0} cy={1} rx={eye * 2.4} ry={eye * 2.05} fill="url(#deepPit)" transform="rotate(-8)" />
      <Ellipse cx={0} cy={0} rx={eye} ry={eye * 0.86} fill="#000000" transform="rotate(-8)" />
      <Ellipse cx={0} cy={0} rx={eye * 3.2} ry={eye * 2.7} fill="none" stroke="#4f9eaa" strokeOpacity={0.18} strokeWidth={2} transform="rotate(-8)" />
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