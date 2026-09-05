import { ScrollView, View, useWindowDimensions } from 'react-native';
import { Button, Text } from 'heroui-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

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

const MAX_TEXT_SCALE = 1.1;

/** Absolute placement helper for the hero collage. */
function at(cx: number, cy: number, size: number) {
  return { position: 'absolute' as const, left: cx - size / 2, top: cy - size / 2 };
}

export function MenuOverlay({ highScores, onStart }: MenuOverlayProps) {
  const best = highScores.length > 0 ? highScores[0].score : 0;
  const { width, height } = useWindowDimensions();
  const insets = useSafeAreaInsets();

  const compact = width < 390 || height < 780;
  const horizontalPadding = compact ? 16 : 20;
  const heroScale = Math.min(1, (width - horizontalPadding * 2) / 350);
  const heroHeight = Math.round(205 * heroScale);
  const coinSize = compact ? 34 : 38;

  return (
    <ScrollView
      className="bg-sea-deep/45 absolute inset-0"
      showsVerticalScrollIndicator={false}
      contentContainerStyle={{
        alignItems: 'center',
        paddingHorizontal: horizontalPadding,
        paddingTop: Math.max(insets.top + 14, 28),
        paddingBottom: Math.max(insets.bottom + 28, 48),
      }}
    >
      <View
        style={{
          width: 350,
          height: 205,
          transform: [{ scale: heroScale }],
          marginBottom: heroHeight - 205,
        }}
      >
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

      <Text
        className={`text-foreground mt-1 text-center font-bold ${compact ? 'text-4xl' : 'text-5xl'}`}
        style={TITLE_SHADOW}
        maxFontSizeMultiplier={MAX_TEXT_SCALE}
      >
        Pirate’s Plunder
      </Text>

      <Text
        className={`text-foreground/80 max-w-md text-center ${compact ? 'mt-3 text-sm leading-6' : 'mt-4 text-base leading-7'}`}
        maxFontSizeMultiplier={MAX_TEXT_SCALE}
      >
        You are Captain Marlow, rowing through the wreckage of Blackwake Harbor. Salvage the
        treasure and stay clear of the homing mines fired from the Dreadwake.
      </Text>

      <View
        className={`bg-surface/60 border-foreground/20 w-full max-w-md rounded-3xl border px-2 ${compact ? 'mt-5 py-4' : 'mt-7 py-5'}`}
      >
        <Text
          className={`text-foreground/70 text-center tracking-[4px] uppercase ${compact ? 'mb-3 text-xs' : 'mb-4 text-sm'}`}
          maxFontSizeMultiplier={MAX_TEXT_SCALE}
        >
          Coin Values
        </Text>

        <View className="w-full flex-row items-end justify-between">
          {COIN_TIERS.map((tier, index) => (
            <View
              key={tier.value}
              className="min-w-0 flex-1 items-center"
              style={{ paddingHorizontal: 1 }}
            >
              <CoinArt tier={index} size={coinSize} />
              <Text
                className="text-foreground/75 mt-1 w-full text-center text-[11px] font-bold"
                maxFontSizeMultiplier={1}
                numberOfLines={1}
                adjustsFontSizeToFit
                minimumFontScale={0.72}
              >
                {tier.points.toLocaleString()}
              </Text>
            </View>
          ))}
        </View>
      </View>

      <Text
        className={`text-foreground/70 max-w-md text-center ${compact ? 'mt-5 text-xs leading-5' : 'mt-7 text-sm leading-6'}`}
        maxFontSizeMultiplier={MAX_TEXT_SCALE}
      >
        Push the thumbstick to point her where you want to go — she holds her line and answers the
        helm quickly. Every coin you take sends another mine after you.
      </Text>

      {best > 0 ? (
        <View
          className={`bg-surface/60 border-foreground/20 rounded-3xl border px-9 ${compact ? 'mt-4 py-3' : 'mt-6 py-4'}`}
        >
          <Text
            className="text-foreground/70 text-center text-sm tracking-[3px] uppercase"
            maxFontSizeMultiplier={MAX_TEXT_SCALE}
          >
            Best Score
          </Text>
          <Text
            className={`text-accent mt-1 text-center font-bold ${compact ? 'text-3xl' : 'text-4xl'}`}
            maxFontSizeMultiplier={MAX_TEXT_SCALE}
          >
            {best.toLocaleString()}
          </Text>
        </View>
      ) : null}

      <Button onPress={onStart} className={`${compact ? 'mt-4' : 'mt-6'} w-full max-w-xs`}>
        <Button.Label>Set Sail</Button.Label>
      </Button>
    </ScrollView>
  );
}
