import { View } from 'react-native';
import { Button, Text } from 'heroui-native';
import Svg from 'react-native-svg';

import { DubloonSprite, MonsterSprite, SubSprite } from '@/components/game/Sprites';
import type { HighScore } from '@/lib/game/types';

interface MenuOverlayProps {
  highScores: HighScore[];
  onStart: () => void;
}

export function MenuOverlay({ highScores, onStart }: MenuOverlayProps) {
  const best = highScores.length > 0 ? highScores[0].score : 0;
  return (
    <View className="absolute inset-0 items-center justify-center px-8">
      <View className="mb-8 items-center">
        <Svg width={180} height={90}>
          <DubloonSprite x={34} y={30} r={13} bob={0.4} angle={0} />
          <SubSprite x={92} y={48} r={20} angle={0} />
          <MonsterSprite x={150} y={40} r={22} angle={3.14} />
        </Svg>
        <Text className="text-foreground mt-2 text-center text-4xl font-bold">
          Coin Cascade
        </Text>
        <Text className="text-foreground/70 mt-2 text-center text-base leading-6">
          Drag to pilot your sub. Grab the gold, dodge the mines, and outrun the deep-sea beast.
        </Text>
      </View>

      {best > 0 ? (
        <View className="bg-surface/70 border-border mb-6 rounded-2xl border px-6 py-3">
          <Text className="text-foreground/60 text-center text-xs tracking-widest uppercase">
            Best Score
          </Text>
          <Text className="text-accent text-center text-2xl font-bold">
            {best.toLocaleString()}
          </Text>
        </View>
      ) : null}

      <Button onPress={onStart} className="w-full max-w-xs">
        <Button.Label>Dive In</Button.Label>
      </Button>
    </View>
  );
}
