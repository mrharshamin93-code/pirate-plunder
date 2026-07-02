import { View } from 'react-native';
import { Text } from 'heroui-native';

interface HudProps {
  score: number;
  dubloons: number;
}

export function Hud({ score, dubloons }: HudProps) {
  return (
    <View className="pt-safe-offset-3 absolute top-0 right-0 left-0 flex-row justify-between px-5">
      <View>
        <Text className="text-foreground/70 text-xs font-semibold tracking-widest uppercase">
          Score
        </Text>
        <Text className="text-foreground text-3xl font-bold">{score.toLocaleString()}</Text>
      </View>
      <View className="items-end">
        <Text className="text-foreground/70 text-xs font-semibold tracking-widest uppercase">
          Dubloons
        </Text>
        <View className="flex-row items-center gap-2">
          <View className="bg-dubloon border-dubloon-edge h-4 w-4 rounded-full border" />
          <Text className="text-foreground text-3xl font-bold">{dubloons}</Text>
        </View>
      </View>
    </View>
  );
}
