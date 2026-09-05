import { useCallback, useEffect, useRef, useState } from 'react';
import { View, useWindowDimensions } from 'react-native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { GameCanvas, type GameStats } from '@/components/game/GameCanvas';
import { GameOverOverlay } from '@/components/game/GameOverOverlay';
import { Hud } from '@/components/game/Hud';
import { MenuOverlay } from '@/components/game/MenuOverlay';
import { MusicToggle } from '@/components/game/MusicToggle';
import { ScorePopup, type Popup } from '@/components/game/ScorePopup';
import { OceanBackground } from '@/components/game/Sprites';
import { useBackgroundMusic } from '@/hooks/useBackgroundMusic';
import { trackCoinPickup, trackGameEnded, trackGameStarted } from '@/lib/analytics';
import { useGameStore } from '@/lib/game/store';

const EMPTY_STATS: GameStats = { score: 0, coins: 0, mines: 0, coinTier: 0 };

export default function Home() {
  const { width, height } = useWindowDimensions();
  const insets = useSafeAreaInsets();
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
  const runStartedAt = useRef<number | null>(null);

  // Keep the entire interactive game layer inside the device safe area.
  // GameCanvas already reserves its top HUD zone and bottom joystick zone,
  // so this prevents either control from ever overlapping system UI or
  // pushing into the playable arena on phones with larger insets.
  const gameTop = Math.max(0, insets.top);
  const gameBottom = Math.max(0, insets.bottom);
  const gameHeight = Math.max(320, height - gameTop - gameBottom);

  useBackgroundMusic(phase === 'playing' && !musicMuted);

  useEffect(() => {
    void loadScores();
  }, [loadScores]);

  const handleStart = useCallback(() => {
    setStats(EMPTY_STATS);
    setPopups([]);
    setRunId((n) => n + 1);
    runStartedAt.current = Date.now();
    void trackGameStarted();
    startGame();
  }, [startGame]);

  const handleGameOver = useCallback(
    (score: number, coins: number) => {
      const startedAt = runStartedAt.current;
      const durationSeconds = startedAt === null ? 0 : (Date.now() - startedAt) / 1000;
      runStartedAt.current = null;

      void trackGameEnded({ score, coins, durationSeconds });
      void endGame(score, coins);
    },
    [endGame],
  );

  const handlePickup = useCallback(
    (points: number, x: number, y: number) => {
      popupId.current += 1;
      const next: Popup = { id: popupId.current, points, x, y: y + gameTop };
      setPopups((current) => [...current, next]);
      void trackCoinPickup(points);
    },
    [gameTop],
  );

  const handlePopupDone = useCallback((id: number) => {
    setPopups((current) => current.filter((p) => p.id !== id));
  }, []);

  return (
    <View className="bg-sea-deep flex-1">
      <Stack.Screen options={{ title: "Pirate's Plunder" }} />
      <StatusBar style="light" />

      <OceanBackground width={width} height={height} />

      {phase === 'playing' ? (
        <View
          pointerEvents="box-none"
          style={{
            position: 'absolute',
            left: 0,
            right: 0,
            top: gameTop,
            height: gameHeight,
          }}
        >
          <GameCanvas
            key={runId}
            width={width}
            height={gameHeight}
            onGameOver={handleGameOver}
            onStats={setStats}
            onPickup={handlePickup}
          />
        </View>
      ) : null}

      {phase === 'playing' ? (
        <Hud
          score={stats.score}
          coins={stats.coins}
          mines={stats.mines}
          coinTier={stats.coinTier}
        />
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
