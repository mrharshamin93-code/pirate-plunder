import { useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Platform,
  Pressable,
  ScrollView,
  Share,
  TextInput,
  View,
} from 'react-native';
import { Text } from 'heroui-native';

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

const PLAY_STORE_URL =
  'https://play.google.com/store/apps/details?id=com.harshamin.piratesplunder';

const GOLD = '#f2c14e';
const GOLD_DARK = '#a86616';
const PARCHMENT = '#e6c178';
const PARCHMENT_LIGHT = '#f4d995';
const INK = '#25160c';
const RED = '#9b1f1f';
const DEEP = '#062f3c';

export function GameOverOverlay({
  score,
  coins,
  highScores,
  onRetry,
  onMenu,
}: GameOverOverlayProps) {
  const newBest = isNewBest(score, highScores);
  const [name, setName] = useState('');
  const [globalScores, setGlobalScores] = useState<GlobalScore[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    void loadPlayerName().then(setName);
    void loadLeaderboard().then(
      (result) => setGlobalScores(result.leaderboard),
      () => setError('Leaderboard is temporarily unavailable.'),
    );
  }, []);

  const leaderboard = useMemo(
    () => [...globalScores].sort((a, b) => b.score - a.score).slice(0, 10),
    [globalScores],
  );

  const projectedRank = useMemo(() => {
    const scores = leaderboard.map((entry) => entry.score);
    return scores.filter((value) => value > score).length + 1;
  }, [leaderboard, score]);

  const isTopTen = leaderboard.length < 10 || projectedRank <= 10;

  const submit = async () => {
    const cleanName = name.trim();
    if (!cleanName || submitting || submitted) return;
    setSubmitting(true);
    setError('');
    try {
      const result = await submitGlobalScore(cleanName, score, coins);
      setGlobalScores(result.leaderboard);
      setSubmitted(true);
    } catch {
      setError('Could not submit your score. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  const shareScore = async () => {
    const message = `🏴‍☠️ I scored ${score.toLocaleString()} in Pirate's Plunder! Think you can beat my score?\n\n${PLAY_STORE_URL}`;

    try {
      if (Platform.OS === 'web') {
        const nav = globalThis.navigator as
          | (Navigator & {
              share?: (data: { title?: string; text?: string; url?: string }) => Promise<void>;
            })
          | undefined;

        if (nav?.share) {
          await nav.share({
            title: "Pirate's Plunder",
            text: `🏴‍☠️ I scored ${score.toLocaleString()} in Pirate's Plunder! Think you can beat my score?`,
            url: PLAY_STORE_URL,
          });
        }
        return;
      }

      await Share.share({ title: "Pirate's Plunder", message });
    } catch {
      // Dismissing the native share sheet can reject on some platforms.
    }
  };

  return (
    <View
      style={{
        position: 'absolute',
        inset: 0,
        backgroundColor: 'rgba(3, 34, 45, 0.93)',
      }}
    >
      <ScrollView
        contentContainerStyle={{
          flexGrow: 1,
          alignItems: 'center',
          justifyContent: 'center',
          paddingHorizontal: 18,
          paddingTop: 26,
          paddingBottom: 34,
        }}
        showsVerticalScrollIndicator={false}
      >
        <View style={{ width: '100%', maxWidth: 430, alignItems: 'center' }}>
          <View
            style={{
              width: 92,
              height: 72,
              borderRadius: 36,
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: -14,
              zIndex: 3,
              backgroundColor: '#1d1610',
              borderWidth: 3,
              borderColor: GOLD_DARK,
            }}
          >
            <Text style={{ fontSize: 42, lineHeight: 48 }}>☠️</Text>
          </View>

          <View
            style={{
              width: '86%',
              minHeight: 72,
              borderRadius: 14,
              backgroundColor: '#552619',
              borderWidth: 4,
              borderColor: GOLD_DARK,
              alignItems: 'center',
              justifyContent: 'center',
              paddingVertical: 7,
              shadowColor: '#000',
              shadowOpacity: 0.45,
              shadowRadius: 12,
              shadowOffset: { width: 0, height: 6 },
              elevation: 9,
              zIndex: 2,
            }}
          >
            <Text
              maxFontSizeMultiplier={1}
              style={{
                color: '#f4d46b',
                fontSize: 34,
                lineHeight: 38,
                fontWeight: '900',
                letterSpacing: 1.2,
                textShadowColor: '#240f08',
                textShadowRadius: 2,
                textShadowOffset: { width: 1, height: 2 },
              }}
            >
              SUNK!
            </Text>
            <Text
              maxFontSizeMultiplier={1}
              style={{ color: '#f4d995', fontSize: 10, fontWeight: '800', letterSpacing: 0.9 }}
            >
              YOUR TREASURE SANK TO THE DEPTHS!
            </Text>
          </View>

          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Share score"
            hitSlop={10}
            onPress={() => void shareScore()}
            style={({ pressed }) => ({
              position: 'absolute',
              top: 76,
              right: 6,
              zIndex: 7,
              minWidth: 74,
              height: 34,
              borderRadius: 17,
              paddingHorizontal: 14,
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: pressed ? '#8c4317' : '#a8511b',
              borderWidth: 2,
              borderColor: '#e3ad4d',
            })}
          >
            <Text
              maxFontSizeMultiplier={1}
              style={{ color: '#ffe3a0', fontSize: 12, fontWeight: '900', letterSpacing: 0.8 }}
            >
              SHARE
            </Text>
          </Pressable>

          <View
            style={{
              width: '100%',
              marginTop: -4,
              borderRadius: 22,
              backgroundColor: PARCHMENT,
              borderWidth: 5,
              borderColor: '#744416',
              paddingHorizontal: 16,
              paddingTop: 25,
              paddingBottom: 18,
              shadowColor: '#000',
              shadowOpacity: 0.5,
              shadowRadius: 16,
              shadowOffset: { width: 0, height: 8 },
              elevation: 10,
            }}
          >
            <View
              style={{
                backgroundColor: PARCHMENT_LIGHT,
                borderWidth: 2,
                borderColor: '#bc8733',
                borderRadius: 15,
                paddingVertical: 12,
                paddingHorizontal: 14,
                alignItems: 'center',
              }}
            >
              <Text
                maxFontSizeMultiplier={1}
                style={{ color: '#704018', fontSize: 11, fontWeight: '900', letterSpacing: 1.8 }}
              >
                YOUR SCORE
              </Text>
              <Text
                maxFontSizeMultiplier={1}
                style={{ color: '#ad7012', fontSize: 35, lineHeight: 39, fontWeight: '900' }}
              >
                {score.toLocaleString()}
              </Text>
              <Text
                maxFontSizeMultiplier={1}
                style={{ color: '#76522b', fontSize: 11, fontWeight: '700' }}
              >
                {coins} coins collected{newBest ? '  •  NEW BEST!' : ''}
              </Text>
            </View>

            <Text
              maxFontSizeMultiplier={1}
              style={{
                color: INK,
                fontSize: 14,
                fontWeight: '900',
                textAlign: 'center',
                marginTop: 15,
                marginBottom: 7,
              }}
            >
              ENTER YOUR PIRATE NAME
            </Text>

            <View style={{ flexDirection: 'row', gap: 8 }}>
              <TextInput
                value={name}
                onChangeText={setName}
                maxLength={20}
                editable={!submitted}
                autoCapitalize="words"
                returnKeyType="done"
                onSubmitEditing={() => void submit()}
                placeholder="Your name..."
                placeholderTextColor="#8f7650"
                style={{
                  flex: 1,
                  height: 42,
                  borderRadius: 9,
                  borderWidth: 2,
                  borderColor: '#8d5d24',
                  backgroundColor: '#f8e6b1',
                  paddingHorizontal: 12,
                  color: INK,
                  fontWeight: '800',
                }}
              />
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="Submit score"
                disabled={!name.trim() || submitting || submitted}
                onPress={() => void submit()}
                style={({ pressed }) => ({
                  minWidth: 88,
                  height: 42,
                  borderRadius: 9,
                  alignItems: 'center',
                  justifyContent: 'center',
                  backgroundColor:
                    submitted || !name.trim() ? '#9a8359' : pressed ? '#74303a' : '#8d3844',
                  borderWidth: 2,
                  borderColor: '#5c202a',
                  paddingHorizontal: 11,
                })}
              >
                <Text
                  maxFontSizeMultiplier={1}
                  style={{ color: '#ffe7b0', fontWeight: '900', fontSize: 12, letterSpacing: 0.4 }}
                >
                  {submitted ? 'SAVED' : 'SUBMIT'}
                </Text>
              </Pressable>
            </View>

            {submitting ? <ActivityIndicator color={RED} style={{ marginTop: 8 }} /> : null}
            {error ? (
              <Text style={{ color: '#8b1e1e', textAlign: 'center', fontSize: 11, marginTop: 8 }}>
                {error}
              </Text>
            ) : null}

            <View
              style={{
                marginTop: 16,
                borderRadius: 12,
                overflow: 'hidden',
                borderWidth: 3,
                borderColor: '#6d3f17',
                backgroundColor: '#d6ad64',
              }}
            >
              <View
                style={{
                  backgroundColor: '#6f3b18',
                  minHeight: 45,
                  alignItems: 'center',
                  justifyContent: 'center',
                  borderBottomWidth: 2,
                  borderBottomColor: '#4c290f',
                }}
              >
                <Text
                  maxFontSizeMultiplier={1}
                  style={{ color: '#f5d77e', fontSize: 20, fontWeight: '900', letterSpacing: 1.2 }}
                >
                  LEADERBOARD
                </Text>
              </View>

              <View style={{ paddingVertical: 4 }}>
                {leaderboard.map((entry, index) => {
                  const matchesCurrentScore = submitted && entry.name === name.trim() && entry.score === score;
                  return (
                    <View
                      key={`${entry.createdAt}-${index}`}
                      style={{
                        minHeight: 31,
                        paddingHorizontal: 12,
                        flexDirection: 'row',
                        alignItems: 'center',
                        backgroundColor: matchesCurrentScore
                          ? 'rgba(166, 75, 22, 0.24)'
                          : index % 2 === 0
                            ? 'rgba(255, 238, 190, 0.18)'
                            : 'transparent',
                      }}
                    >
                      <Text
                        maxFontSizeMultiplier={1}
                        style={{ width: 34, color: INK, fontSize: 13, fontWeight: '900' }}
                      >
                        {index + 1}.
                      </Text>
                      <Text
                        numberOfLines={1}
                        maxFontSizeMultiplier={1}
                        style={{ flex: 1, color: INK, fontSize: 13, fontWeight: '800' }}
                      >
                        {entry.name}
                      </Text>
                      <Text
                        maxFontSizeMultiplier={1}
                        style={{ color: '#56320f', fontSize: 13, fontWeight: '900' }}
                      >
                        {entry.score.toLocaleString()} 🪙
                      </Text>
                    </View>
                  );
                })}

                {leaderboard.length === 0 && !error ? (
                  <Text style={{ color: '#6a4a27', textAlign: 'center', paddingVertical: 14 }}>
                    Be the first captain on the leaderboard!
                  </Text>
                ) : null}
              </View>
            </View>

            <View
              style={{
                marginTop: 12,
                borderRadius: 10,
                backgroundColor: 'rgba(113, 64, 23, 0.11)',
                paddingHorizontal: 12,
                paddingVertical: 9,
                alignItems: 'center',
              }}
            >
              <Text
                maxFontSizeMultiplier={1}
                style={{ color: INK, fontSize: 12, fontWeight: '900' }}
              >
                YOUR SCORE: {score.toLocaleString()}
              </Text>
              <Text
                maxFontSizeMultiplier={1}
                style={{ color: '#6c4926', fontSize: 11, fontWeight: '700', marginTop: 2 }}
              >
                {isTopTen
                  ? `This score is currently good for #${projectedRank} on the leaderboard.`
                  : 'Not in the top 10 yet, but keep playing!'}
              </Text>
            </View>

            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Play again"
              onPress={onRetry}
              style={({ pressed }) => ({
                marginTop: 15,
                height: 52,
                borderRadius: 12,
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: pressed ? '#70242a' : RED,
                borderWidth: 3,
                borderColor: '#5a171c',
                shadowColor: '#000',
                shadowOpacity: 0.26,
                shadowRadius: 6,
                shadowOffset: { width: 0, height: 4 },
                elevation: 5,
              })}
            >
              <Text
                maxFontSizeMultiplier={1}
                style={{ color: '#ffe8a6', fontSize: 19, fontWeight: '900', letterSpacing: 1.1 }}
              >
                ⚔  PLAY AGAIN  ⚔
              </Text>
            </Pressable>

            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Main menu"
              onPress={onMenu}
              style={({ pressed }) => ({
                marginTop: 9,
                height: 40,
                borderRadius: 10,
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: pressed ? '#b88b44' : '#c99d55',
                borderWidth: 2,
                borderColor: '#81511d',
              })}
            >
              <Text
                maxFontSizeMultiplier={1}
                style={{ color: DEEP, fontSize: 13, fontWeight: '900', letterSpacing: 0.8 }}
              >
                MAIN MENU
              </Text>
            </Pressable>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}
