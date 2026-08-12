import { View } from 'react-native';
import { Text } from 'heroui-native';

interface HudProps {
  score: number;
  dubloons: number;
}

/** Keeps the cartoon-bright water from washing out the readouts. */
const SHADOW = {
  textShadowColor: 'rgba(10,51,88,0.9)',
  textShadowOffset: { width: 0, height: 2 },
  textShadowRadius: 5,
} as const;

export function Hud({ score, dubloons }: HudProps) {
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
      <View className="items-end">
        <Text
          className="text-foreground/80 text-xs font-semibold tracking-widest uppercase"
          style={SHADOW}
        >
          Coins
        </Text>
        <View className="flex-row items-center gap-2">
          <View className="bg-dubloon border-dubloon-edge h-4 w-4 rounded-full border-2" />
          <Text className="text-foreground text-3xl font-bold" style={SHADOW}>
            {dubloons}
          </Text>
        </View>
      </View>
    </View>
  );
}
