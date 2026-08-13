Exit code: 0
Wall time: 0.8 seconds
Output:
import { useEffect, useState } from 'react';
import { ActivityIndicator, ScrollView, TextInput, View } from 'react-native';
import { Button, Separator, Text } from 'heroui-native';

import {
  loadLeaderboard,
  loadPlayerName,
  submitGlobalScore,
  type GlobalScore,
} from '@/lib/game/leaderboard';
import { isNewBest } from '@/lib/game/store';
import type { HighScore } from '@/lib/game/types';

interface GameOverOverlayProps {
  score: number;
  coins: number;
  highScores: HighScore[];
  onRetry: () => void;
  onMenu: () => void;
}

export function GameOverOverlay({
  score,
  coins,
  highScores,
  onRetry,
  onMenu,
}: GameOverOverlayProps) {
  const newBest = isNewBest(score, highScores);
  const localBest = highScores.length > 0 ? highScores[0].score : score;
  const [name, setName] = useState('');
  const [globalScores, setGlobalScores] = useState<GlobalScore[]>([]);
  const [personalBest, setPersonalBest] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    void loadPlayerName().then(setName);
    void loadLeaderboard().then(
      (result) => {
        setGlobalScores(result.leaderboard);
        setPersonalBest(result.personalBest);
      },
      () => setError('Global scores are temporarily unavailable.'),
    );
  }, []);

  const submit = async () => {
    const cleanName = name.trim();
    if (!cleanName || submitting || submitted) return;
    setSubmitting(true);
    setError('');
    try {
      const result = await submitGlobalScore(cleanName, score, coins);
      setGlobalScores(result.leaderboard);
      setPersonalBest(result.personalBest);
      setSubmitted(true);
    } catch {
      setError('Could not submit your score. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <View className="bg-sea-deep/55 absolute inset-0 px-8">
      <ScrollView contentContainerClassName="grow items-center justify-center py-8">
      <View className="bg-surface/90 border-border w-full max-w-sm rounded-3xl border px-7 py-6">
        <Text className="text-danger text-center text-3xl font-bold">Sunk!</Text>
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
            <Text className="text-foreground text-3xl font-bold">{coins}</Text>
          </View>
        </View>

        <View className="bg-sea-deep/35 mb-4 rounded-2xl px-4 py-3">
          <Text className="text-foreground/60 text-center text-xs tracking-widest uppercase">
            Your Best
          </Text>
          <Text className="text-accent text-center text-2xl font-bold">
            {Math.max(localBest, personalBest).toLocaleString()}
          </Text>
        </View>

        <Text className="text-foreground/70 mb-2 text-center text-xs tracking-widest uppercase">
          Enter your name for the global leaderboard
        </Text>
        <TextInput
          value={name}
          onChangeText={setName}
          maxLength={20}
          editable={!submitted}
          autoCapitalize="words"
          placeholder="Captain name"
          placeholderTextColor="#8fb3bd"
          className="text-foreground border-border mb-2 rounded-xl border bg-[rgba(8,46,60,0.72)] px-4 py-3"
        />
        <Button onPress={() => void submit()} className="mb-3">
          <Button.Label>
            {submitting ? 'Submitting...' : submitted ? 'Score Submitted' : 'Submit Score'}
          </Button.Label>
        </Button>
        {submitting ? <ActivityIndicator color="#e9bb45" className="mb-2" /> : null}
        {error ? <Text className="text-danger mb-2 text-center text-xs">{error}</Text> : null}

        <Separator className="my-2" />

        <Text className="text-foreground/60 mb-2 text-center text-xs tracking-widest uppercase">
          Global Top 10
        </Text>
        <View className="mb-4 gap-1">
          {globalScores.map((entry, index) => (
            <View key={entry.createdAt} className="flex-row items-center justify-between">
              <Text className="text-foreground/80 text-sm">
                {index + 1}. {entry.name}
              </Text>
              <Text className="text-accent text-sm font-semibold">
                {entry.score.toLocaleString()}
              </Text>
            </View>
          ))}
          {globalScores.length === 0 && !error ? (
            <Text className="text-foreground/50 text-center text-sm">Be the first captain!</Text>
          ) : null}
        </View>

        <Button onPress={onRetry} className="mb-2">
          <Button.Label>Row Again</Button.Label>
        </Button>
        <Button variant="tertiary" onPress={onMenu}>
          <Button.Label>Main Menu</Button.Label>
        </Button>
      </View>
      </ScrollView>
    </View>
  );
}

