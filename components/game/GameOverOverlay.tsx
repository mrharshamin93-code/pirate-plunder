import { View } from 'react-native';
import { Button, Separator, Text } from 'heroui-native';

import { isNewBest } from '@/lib/game/store';
import type { HighScore } from '@/lib/game/types';

interface GameOverOverlayProps {
  score: number;
  dubloons: number;
  highScores: HighScore[];
  onRetry: () => void;
  onMenu: () => void;
}

export function GameOverOverlay({
  score,
  dubloons,
  highScores,
  onRetry,
  onMenu,
}: GameOverOverlayProps) {
  const newBest = isNewBest(score, highScores);
  return (
    <View className="absolute inset-0 items-center justify-center px-8">
      <View className="bg-surface/85 border-border w-full max-w-sm rounded-3xl border px-7 py-7">
        <Text className="text-danger text-center text-3xl font-bold">Caught!</Text>
        {newBest ? (
          <Text className="text-accent mt-1 text-center text-sm font-semibold tracking-widest uppercase">
            New Best Score
          </Text>
        ) : null}

        <View className="mt-5 mb-4 flex-row justify-around">
          <View className="items-center">
            <Text className="text-foreground/60 text-xs tracking-widest uppercase">Score</Text>
            <Text className="text-foreground text-3xl font-bold">{score.toLocaleString()}</Text>
          </View>
          <View className="items-center">
            <Text className="text-foreground/60 text-xs tracking-widest uppercase">Coins</Text>
            <Text className="text-foreground text-3xl font-bold">{dubloons}</Text>
          </View>
        </View>

        <Separator className="my-2" />

        <Text className="text-foreground/60 mb-2 text-center text-xs tracking-widest uppercase">
          High Scores
        </Text>
        <View className="mb-5 gap-1">
          {highScores.slice(0, 5).map((h, i) => (
            <View key={h.date} className="flex-row items-center justify-between">
              <Text className="text-foreground/80 text-sm">
                {i + 1}. {h.score.toLocaleString()}
              </Text>
              <Text className="text-foreground/50 text-xs">{h.dubloons} coins</Text>
            </View>
          ))}
          {highScores.length === 0 ? (
            <Text className="text-foreground/50 text-center text-sm">No scores yet</Text>
          ) : null}
        </View>

        <Button onPress={onRetry} className="mb-2">
          <Button.Label>Dive Again</Button.Label>
        </Button>
        <Button variant="tertiary" onPress={onMenu}>
          <Button.Label>Main Menu</Button.Label>
        </Button>
      </View>
    </View>
  );
}
