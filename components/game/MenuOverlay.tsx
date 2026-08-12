import { View } from 'react-native';
import { Button, Text } from 'heroui-native';

import { DubloonArt, MineArt, MonsterArt, SPRITE_BOX, SubArt } from '@/components/game/Sprites';
import type { HighScore } from '@/lib/game/types';

interface MenuOverlayProps {
  highScores: HighScore[];
  onStart: () => void;
}

export function MenuOverlay({ highScores, onStart }: MenuOverlayProps) {
  const best = highScores.length > 0 ? highScores[0].score : 0;
  return (
    <View className="bg-sea-deep/45 absolute inset-0 items-center justify-center px-8">
      <View className="mb-8 items-center">
        <View style={{ width: 264, height: 140 }}>
          <View
            style={{
              position: 'absolute',
              left: 44 - SPRITE_BOX.dubloon / 2,
              top: 52 - SPRITE_BOX.dubloon / 2,
            }}
          >
            <DubloonArt />
          </View>
          <View
            style={{
              position: 'absolute',
              left: 74 - SPRITE_BOX.mine / 2,
              top: 106 - SPRITE_BOX.mine / 2,
            }}
          >
            <MineArt />
          </View>
          <View
            style={{
              position: 'absolute',
              left: 124 - SPRITE_BOX.sub / 2,
              top: 62 - SPRITE_BOX.sub / 2,
            }}
          >
            <SubArt />
          </View>
          <View
            style={{
              position: 'absolute',
              left: 200 - SPRITE_BOX.monster / 2,
              top: 60 - SPRITE_BOX.monster / 2,
            }}
          >
            <MonsterArt />
          </View>
        </View>
        <Text
          className="text-foreground mt-2 text-center text-4xl font-bold"
          style={{
            textShadowColor: 'rgba(10,51,88,0.9)',
            textShadowOffset: { width: 0, height: 3 },
            textShadowRadius: 6,
          }}
        >
          Coin Cascade
        </Text>
        <Text className="text-foreground/70 mt-2 text-center text-base leading-6">
          Steer with the joystick. Scoop up dubloons, dodge the grumpy urchins, and outswim the
          hungry sea beast.
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
