import { useCallback, useEffect, useState } from 'react';
import { View, useWindowDimensions } from 'react-native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

import { GameCanvas } from '@/components/game/GameCanvas';
import { GameOverOverlay } from '@/components/game/GameOverOverlay';
import { Hud } from '@/components/game/Hud';
import { MenuOverlay } from '@/components/game/MenuOverlay';
import { useGameStore } from '@/lib/game/store';

export default function Home() {
  const { width, height } = useWindowDimensions();
  const phase = useGameStore((s) => s.phase);
  const highScores = useGameStore((s) => s.highScores);
  const lastScore = useGameStore((s) => s.lastScore);
  const lastDubloons = useGameStore((s) => s.lastDubloons);
  const startGame = useGameStore((s) => s.startGame);
  const endGame = useGameStore((s) => s.endGame);
  const goToMenu = useGameStore((s) => s.goToMenu);
  const loadScores = useGameStore((s) => s.loadScores);

  const [runId, setRunId] = useState(0);
  const [liveScore, setLiveScore] = useState(0);
  const [liveDubloons, setLiveDubloons] = useState(0);

  useEffect(() => {
    void loadScores();
  }, [loadScores]);

  const handleStart = useCallback(() => {
    setLiveScore(0);
    setLiveDubloons(0);
    setRunId((n) => n + 1);
    startGame();
  }, [startGame]);

  const handleGameOver = useCallback(
    (score: number, dubloons: number) => {
      void endGame(score, dubloons);
    },
    [endGame],
  );

  return (
    <View className="bg-sea-deep flex-1">
      <Stack.Screen options={{ title: 'Dubloon Disaster' }} />
      <StatusBar style="light" />

      {phase === 'playing' ? (
        <GameCanvas
          key={runId}
          width={width}
          height={height}
          onGameOver={handleGameOver}
          onScoreChange={setLiveScore}
          onDubloonsChange={setLiveDubloons}
        />
      ) : null}

      {phase === 'playing' ? <Hud score={liveScore} dubloons={liveDubloons} /> : null}

      {phase === 'menu' ? <MenuOverlay highScores={highScores} onStart={handleStart} /> : null}

      {phase === 'gameover' ? (
        <GameOverOverlay
          score={lastScore}
          dubloons={lastDubloons}
          highScores={highScores}
          onRetry={handleStart}
          onMenu={goToMenu}
        />
      ) : null}
    </View>
  );
}
