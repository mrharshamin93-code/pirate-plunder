import { View } from 'react-native';
import { Button, Text } from 'heroui-native';

import { DubloonArt, MonsterArt, SPRITE_BOX, SubArt } from '@/components/game/Sprites';
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
        <View style={{ width: 220, height: 110 }}>
          <View
            style={{
              position: 'absolute',
              left: 46 - SPRITE_BOX.dubloon / 2,
              top: 44 - SPRITE_BOX.dubloon / 2,
            }}
          >
            <DubloonArt />
          </View>
          <View
            style={{
              position: 'absolute',
              left: 112 - SPRITE_BOX.sub / 2,
              top: 60 - SPRITE_BOX.sub / 2,
            }}
          >
            <SubArt />
          </View>
          <View
            style={{
              position: 'absolute',
              left: 166 - SPRITE_BOX.monster / 2,
              top: 56 - SPRITE_BOX.monster / 2,
            }}
          >
            <MonsterArt />
          </View>
        </View>
        <Text className="text-foreground mt-2 text-center text-4xl font-bold">Coin Cascade</Text>
        <Text className="text-foreground/70 mt-2 text-center text-base leading-6">
          Steer with the joystick. Grab the gold, dodge the mines, and outrun the deep-sea beast.
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
