import { useCallback, useEffect, useRef, useState } from 'react';
import { View, useWindowDimensions } from 'react-native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

import { GameCanvas, type GameStats } from '@/components/game/GameCanvas';
import { GameOverOverlay } from '@/components/game/GameOverOverlay';
import { Hud } from '@/components/game/Hud';
import { MenuOverlay } from '@/components/game/MenuOverlay';
import { MusicToggle } from '@/components/game/MusicToggle';
import { ScorePopup, type Popup } from '@/components/game/ScorePopup';
import { OceanBackground } from '@/components/game/Sprites';
import { useBackgroundMusic } from '@/hooks/useBackgroundMusic';
import { useGameStore } from '@/lib/game/store';

const EMPTY_STATS: GameStats = { score: 0, coins: 0, mines: 0 };

export default function Home() {
  const { width, height } = useWindowDimensions();
  const phase = useGameStore((s) => s.phase);
  const highScores = useGameStore((s) => s.highScores);
  const lastScore = useGameStore((s) => s.lastScore);
  const lastCoins = useGameStore((s) => s.lastCoins);
  const startGame = useGameStore((s) => s.startGame);
  const endGame = useGameStore((s) => s.endGame);
  const goToMenu = useGameStore((s) => s.goToMenu);
  const loadScores = useGameStore((s) => s.loadScores);
  const musicMuted = useGameStore((s) => s.musicMuted);
  const toggleMusic = useGameStore((s) => s.toggleMusic);

  const [runId, setRunId] = useState(0);
  const [stats, setStats] = useState<GameStats>(EMPTY_STATS);
  const [popups, setPopups] = useState<Popup[]>([]);
  const popupId = useRef(0);

  useBackgroundMusic(phase === 'playing' && !musicMuted);

  useEffect(() => {
    void loadScores();
  }, [loadScores]);

  const handleStart = useCallback(() => {
    setStats(EMPTY_STATS);
    setPopups([]);
    setRunId((n) => n + 1);
    startGame();
  }, [startGame]);

  const handleGameOver = useCallback(
    (score: number, coins: number) => {
      void endGame(score, coins);
    },
    [endGame],
  );

  const handlePickup = useCallback((points: number, x: number, y: number) => {
    popupId.current += 1;
    const next: Popup = { id: popupId.current, points, x, y };
    setPopups((current) => [...current, next]);
  }, []);

  const handlePopupDone = useCallback((id: number) => {
    setPopups((current) => current.filter((p) => p.id !== id));
  }, []);

  return (
    <View className="bg-sea-deep flex-1">
      <Stack.Screen options={{ title: "Pirate's Plunder" }} />
      <StatusBar style="light" />

      <OceanBackground width={width} height={height} />

      {phase === 'playing' ? (
        <GameCanvas
          key={runId}
          width={width}
          height={height}
          onGameOver={handleGameOver}
          onStats={setStats}
          onPickup={handlePickup}
        />
      ) : null}

      {phase === 'playing' ? (
        <Hud score={stats.score} coins={stats.coins} mines={stats.mines} />
      ) : null}

      {popups.map((p) => (
        <ScorePopup key={p.id} popup={p} onDone={handlePopupDone} />
      ))}

      {phase === 'menu' ? <MenuOverlay highScores={highScores} onStart={handleStart} /> : null}

      {phase === 'gameover' ? (
        <GameOverOverlay
          score={lastScore}
          coins={lastCoins}
          highScores={highScores}
          onRetry={handleStart}
          onMenu={goToMenu}
        />
      ) : null}

      <MusicToggle muted={musicMuted} onToggle={toggleMusic} />
    </View>
  );
}
