import { ScrollView, View } from 'react-native';
import { Button, Text } from 'heroui-native';

import { BoatArt, CoinArt, MineArt, RaiderShipArt, SPRITE_BOX } from '@/components/game/Sprites';
import { COIN_TIERS } from '@/lib/game/engine';
import type { HighScore } from '@/lib/game/types';

interface MenuOverlayProps {
  highScores: HighScore[];
  onStart: () => void;
}

const TITLE_SHADOW = {
  textShadowColor: 'rgba(4,20,28,0.95)',
  textShadowOffset: { width: 0, height: 3 },
  textShadowRadius: 6,
} as const;

/** Absolute placement helper for the hero collage. */
function at(cx: number, cy: number, size: number) {
  return { position: 'absolute' as const, left: cx - size / 2, top: cy - size / 2 };
}

export function MenuOverlay({ highScores, onStart }: MenuOverlayProps) {
  const best = highScores.length > 0 ? highScores[0].score : 0;

  return (
    <ScrollView
      className="bg-sea-deep/45 absolute inset-0"
      contentContainerClassName="grow items-center justify-center px-5 py-9"
    >
      <View style={{ width: 350, height: 205, maxWidth: '100%' }}>
        <View style={at(270, 92, SPRITE_BOX.raiderShip)}>
          <RaiderShipArt />
        </View>
        <View style={at(168, 125, SPRITE_BOX.mine)}>
          <MineArt />
        </View>
        <View style={at(78, 126, SPRITE_BOX.boat)}>
          <BoatArt />
        </View>
      </View>

      <Text className="text-foreground mt-1 text-center text-5xl font-bold" style={TITLE_SHADOW}>
        Pirate’s Plunder
      </Text>
      <Text className="text-foreground/80 mt-4 max-w-md text-center text-base leading-7">
        You are Captain Marlow, rowing through the wreckage of Blackwake Harbor. Salvage the
        treasure and stay clear of the homing mines fired from the Dreadwake.
      </Text>

      <View className="bg-surface/60 border-foreground/20 mt-7 w-full max-w-md rounded-3xl border px-2 py-5">
        <Text className="text-foreground/70 mb-4 text-center text-sm tracking-[4px] uppercase">
          Coin Values
        </Text>
        <View className="flex-row flex-wrap items-end justify-center gap-x-1 gap-y-3">
          {COIN_TIERS.map((tier, index) => (
            <View key={tier.value} className="items-center" style={{ width: 38 + index * 2 }}>
              <CoinArt tier={index} size={38 + index * 2} />
              <Text className="text-foreground/75 mt-1 text-xs font-bold">
                {tier.points.toLocaleString()}
              </Text>
            </View>
          ))}
        </View>
      </View>

      <Text className="text-foreground/70 mt-7 max-w-md text-center text-sm leading-6">
        Push the thumbstick to point her where you want to go — she holds her line and answers the
        helm quickly. Every coin you take sends another mine after you.
      </Text>

      {best > 0 ? (
        <View className="bg-surface/60 border-foreground/20 mt-6 rounded-3xl border px-9 py-4">
          <Text className="text-foreground/70 text-center text-sm tracking-[3px] uppercase">
            Best Score
          </Text>
          <Text className="text-accent mt-1 text-center text-4xl font-bold">
            {best.toLocaleString()}
          </Text>
        </View>
      ) : null}

      <Button onPress={onStart} className="mt-6 w-full max-w-xs">
        <Button.Label>Set Sail</Button.Label>
      </Button>
    </ScrollView>
  );
}
