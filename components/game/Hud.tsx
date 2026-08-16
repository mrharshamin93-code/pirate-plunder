import { View } from 'react-native';
import { Text } from 'heroui-native';

import { CoinArt, MineArt } from '@/components/game/Sprites';
import { GAME } from '@/lib/game/engine';

interface HudProps {
  score: number;
  coins: number;
  mines: number;
  coinTier: number;
}

const SHADOW = {
  textShadowColor: 'rgba(4,20,28,0.95)',
  textShadowOffset: { width: 0, height: 2 },
  textShadowRadius: 5,
} as const;

export function Hud({ score, coins, mines, coinTier }: HudProps) {
  return (
    <View className="pt-safe-offset-3 absolute top-0 right-0 left-0 flex-row justify-between px-5">
      <View>
        <Text
          className="text-foreground/80 text-xs font-semibold tracking-widest uppercase"
          style={SHADOW}
        >
          Score
        </Text>

        <Text className="text-foreground text-3xl font-bold" style={SHADOW}>
          {score.toLocaleString()}
        </Text>
      </View>

      <View
        style={{
          width: 82,
          height: 82,
          borderRadius: 14,
          paddingHorizontal: 9,
          paddingVertical: 8,
          justifyContent: 'center',
          backgroundColor: 'rgba(3, 19, 27, 0.76)',
          borderWidth: 1.5,
          borderColor: 'rgba(181, 235, 244, 0.30)',
          shadowColor: '#000000',
          shadowOpacity: 0.28,
          shadowRadius: 8,
          shadowOffset: { width: 0, height: 3 },
          elevation: 5,
        }}
      >
        <View
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
            minHeight: 31,
            marginBottom: 2,
          }}
        >
          <View
            style={{
              width: 30,
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <CoinArt tier={coinTier} size={24} />
          </View>

          <Text
            className="text-foreground text-lg font-bold"
            style={SHADOW}
          >
            {coins}
          </Text>
        </View>

        <View
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
            minHeight: 33,
            marginTop: 2,
          }}
        >
          <View
            style={{
              width: 30,
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <MineArt size={29} />
          </View>

          <Text
            className="text-foreground/90 text-sm font-bold"
            style={SHADOW}
          >
            {mines}/{GAME.maxMines}
          </Text>
        </View>
      </View>
    </View>
  );
}
