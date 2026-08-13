import { ScrollView, View } from 'react-native';
import { Button, Text } from 'heroui-native';

import { BoatArt, CoinArt, MineArt, PawkeetArt, SPRITE_BOX } from '@/components/game/Sprites';
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
      contentContainerClassName="grow items-center justify-center px-7 py-10"
    >
      <View style={{ width: 300, height: 170 }}>
        <View style={at(210, 70, SPRITE_BOX.pawkeet)}>
          <PawkeetArt />
        </View>
        <View style={at(58, 58, SPRITE_BOX.coin)}>
          <CoinArt tier={6} />
        </View>
        <View style={at(120, 52, SPRITE_BOX.coin)}>
          <CoinArt tier={2} />
        </View>
        <View style={at(150, 118, SPRITE_BOX.mine)}>
          <MineArt />
        </View>
        <View style={at(88, 114, SPRITE_BOX.boat)}>
          <BoatArt />
        </View>
      </View>

      <Text className="text-foreground mt-1 text-center text-4xl font-bold" style={TITLE_SHADOW}>
        Pirate's Plunder
      </Text>
      <Text className="text-foreground/75 mt-2 text-center text-sm leading-5">
        You are Captain Marlow, rowing the wreckage of Blackwake Harbor. Salvage the treasure and stay clear of
        the homing mines fired from the Black Pawkeet.
      </Text>

      <View className="bg-surface/70 border-border mt-5 w-full max-w-sm rounded-2xl border px-4 py-3">
        <Text className="text-foreground/60 mb-2 text-center text-xs tracking-widest uppercase">
          Coin Values
        </Text>
        <View className="flex-row flex-wrap items-start justify-center gap-x-3 gap-y-1">
          {COIN_TIERS.map((tier, index) => (
            <View key={tier.value} className="items-center">
              <CoinArt tier={index} />
              <Text className="text-foreground/70 text-xs font-semibold">
                {tier.points.toLocaleString()}
              </Text>
            </View>
          ))}
        </View>
      </View>

      <Text className="text-foreground/60 mt-4 text-center text-xs leading-5">
        Push the thumbstick to point her where you want to go — she holds her line and answers the
        helm quickly. Every coin you take sends another mine after you.
      </Text>

      {best > 0 ? (
        <View className="bg-surface/70 border-border mt-5 rounded-2xl border px-6 py-3">
          <Text className="text-foreground/60 text-center text-xs tracking-widest uppercase">
            Best Score
          </Text>
          <Text className="text-accent text-center text-2xl font-bold">
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
