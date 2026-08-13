import { View } from 'react-native';
import { Text } from 'heroui-native';

import { GAME } from '@/lib/game/engine';

interface HudProps {
  score: number;
  dubloons: number;
  mines: number;
}

/** Keeps the readouts legible over open water. */
const SHADOW = {
  textShadowColor: 'rgba(4,20,28,0.95)',
  textShadowOffset: { width: 0, height: 2 },
  textShadowRadius: 5,
} as const;

export function Hud({ score, dubloons, mines }: HudProps) {
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

      <View className="items-end gap-1">
        <View className="flex-row items-center gap-2">
          <View className="bg-dubloon border-dubloon-edge h-4 w-4 rounded-full border-2" />
          <Text className="text-foreground text-xl font-bold" style={SHADOW}>
            {dubloons}
          </Text>
        </View>
        <View className="flex-row items-center gap-2">
          <View className="bg-mine h-3.5 w-3.5 rounded-full border-2 border-white/40" />
          <Text className="text-foreground/85 text-base font-semibold" style={SHADOW}>
            {mines}/{GAME.maxMines}
          </Text>
        </View>
      </View>
    </View>
  );
}
