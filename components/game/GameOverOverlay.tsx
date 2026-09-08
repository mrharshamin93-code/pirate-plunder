import { useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Platform,
  Pressable,
  ScrollView,
  Share,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import { Text } from 'heroui-native';
import Svg, { Circle, Defs, Ellipse, G, LinearGradient, Path, Rect, Stop } from 'react-native-svg';

import { loadLeaderboard, loadPlayerName, submitGlobalScore, type GlobalScore } from '@/lib/game/leaderboard';
import type { HighScore } from '@/lib/game/types';

interface GameOverOverlayProps {
  score: number;
  coins: number;
  highScores: HighScore[];
  onRetry: () => void;
  onMenu: () => void;
}

const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.harshamin.piratesplunder';
const INK = '#2b170b';
const GOLD = '#e6a92c';
const RED = '#9d1719';
const DARK_WOOD = '#2a170c';

function UnderwaterScene() {
  return (
    <Svg pointerEvents="none" width="100%" height="100%" viewBox="0 0 430 900" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0 }}>
      <Defs>
        <LinearGradient id="sea" x1="0" y1="0" x2="0" y2="1">
          <Stop offset="0" stopColor="#087b91" />
          <Stop offset="0.42" stopColor="#07546d" />
          <Stop offset="1" stopColor="#032d43" />
        </LinearGradient>
        <LinearGradient id="sand" x1="0" y1="0" x2="0" y2="1">
          <Stop offset="0" stopColor="#a78345" />
          <Stop offset="1" stopColor="#584423" />
        </LinearGradient>
      </Defs>
      <Rect width="430" height="900" fill="url(#sea)" />
      <Path d="M20 0 L145 0 L78 520 L0 650 Z" fill="#b9f5ef" opacity="0.08" />
      <Path d="M285 0 L405 0 L430 510 L355 410 Z" fill="#b9f5ef" opacity="0.06" />
      <G fill="#c6f7ed" opacity="0.28">
        <Circle cx="43" cy="105" r="3"/><Circle cx="58" cy="139" r="5"/><Circle cx="389" cy="181" r="4"/><Circle cx="371" cy="207" r="2"/>
        <Circle cx="24" cy="363" r="3"/><Circle cx="402" cy="390" r="5"/><Circle cx="45" cy="620" r="4"/><Circle cx="385" cy="674" r="3"/>
      </G>
      <Path d="M0 770 Q82 735 160 778 T315 770 T430 760 V900 H0 Z" fill="url(#sand)" />
      <Path d="M0 807 Q100 773 205 814 T430 800" fill="none" stroke="#c5a664" strokeWidth="4" opacity="0.25" />
      <G opacity="0.65">
        <Path d="M25 835 C15 790 32 760 22 715 M35 835 C52 790 44 758 58 728 M13 837 C2 804 8 780 4 755" stroke="#174f42" strokeWidth="8" fill="none" strokeLinecap="round" />
        <Path d="M398 842 C411 798 397 761 414 724 M385 845 C371 804 386 773 375 741" stroke="#174f42" strokeWidth="9" fill="none" strokeLinecap="round" />
      </G>
      <G transform="translate(342 745) rotate(-12)" opacity="0.8">
        <Path d="M34 0 V78 M8 27 H60 M14 25 C14 62 20 76 34 82 C48 76 54 62 54 25" fill="none" stroke="#21353a" strokeWidth="9" strokeLinecap="round" />
      </G>
      <G transform="translate(17 786)">
        <Ellipse cx="40" cy="49" rx="43" ry="16" fill="#4b351c" />
        <Path d="M5 45 Q10 5 38 0 Q72 6 79 44 Z" fill="#6c3c18" stroke="#2b190c" strokeWidth="5" />
        <Path d="M12 21 Q42 35 73 18" fill="none" stroke="#d19b31" strokeWidth="5" />
        <Circle cx="28" cy="17" r="7" fill="#f3c342"/><Circle cx="43" cy="22" r="6" fill="#e4a826"/><Circle cx="58" cy="16" r="7" fill="#f4d05b"/>
      </G>
    </Svg>
  );
}

function PirateSkull() {
  return (
    <Svg width={118} height={94} viewBox="0 0 118 94">
      <G stroke="#2a160b" strokeWidth="4" strokeLinejoin="round">
        <Path d="M18 33 Q29 4 59 9 Q91 3 102 34 Q88 29 76 32 Q58 22 39 32 Q28 29 18 33 Z" fill="#35180e" />
        <Path d="M17 33 Q59 21 102 34 Q89 42 76 39 Q57 34 38 40 Q27 41 17 33 Z" fill="#a3211e" />
        <Path d="M46 12 Q58 -2 72 13 Q59 21 46 12 Z" fill="#d9b36b" />
        <Circle cx="59" cy="12" r="4" fill="#2a160b" strokeWidth="1" />
        <Path d="M33 36 Q58 27 84 37 L82 63 Q76 78 59 78 Q41 78 35 63 Z" fill="#e7d39a" />
        <Ellipse cx="47" cy="51" rx="8" ry="9" fill="#24150d" />
        <Ellipse cx="70" cy="51" rx="8" ry="9" fill="#24150d" />
        <Path d="M58 55 L53 64 H63 Z" fill="#24150d" strokeWidth="1" />
        <Path d="M44 68 Q59 77 75 68 M51 69 V76 M59 70 V78 M67 69 V76" fill="none" stroke="#24150d" strokeWidth="3" />
        <Path d="M20 77 L97 48 M21 49 L97 78" stroke="#e7d39a" strokeWidth="8" strokeLinecap="round" />
        <Circle cx="18" cy="79" r="6" fill="#e7d39a"/><Circle cx="99" cy="46" r="6" fill="#e7d39a"/><Circle cx="19" cy="47" r="6" fill="#e7d39a"/><Circle cx="99" cy="80" r="6" fill="#e7d39a"/>
      </G>
    </Svg>
  );
}

function ScrollShell({ children }: { children: React.ReactNode }) {
  return (
    <View style={{ width: '94%', position: 'relative', marginTop: -2 }}>
      <View style={{ position: 'absolute', left: 5, right: 5, top: 8, bottom: 8, backgroundColor: '#8a5727', borderRadius: 18, transform: [{ rotate: '-0.5deg' }], opacity: 0.9 }} />
      <View style={{ backgroundColor: '#e8c982', borderColor: '#9a672d', borderWidth: 3, borderRadius: 15, paddingHorizontal: 17, paddingTop: 15, paddingBottom: 14, shadowColor: '#000', shadowOpacity: 0.4, shadowRadius: 9, elevation: 8 }}>
        <View style={{ position: 'absolute', left: -9, top: 34, width: 16, height: 32, backgroundColor: '#d7ae62', borderColor: '#875321', borderWidth: 2, borderRadius: 7 }} />
        <View style={{ position: 'absolute', right: -9, top: 90, width: 16, height: 38, backgroundColor: '#d7ae62', borderColor: '#875321', borderWidth: 2, borderRadius: 7 }} />
        <View style={{ position: 'absolute', left: -7, bottom: 64, width: 14, height: 29, backgroundColor: '#d7ae62', borderColor: '#875321', borderWidth: 2, borderRadius: 7 }} />
        {children}
      </View>
    </View>
  );
}

export function GameOverOverlay({ score, coins, onRetry }: GameOverOverlayProps) {
  const { height } = useWindowDimensions();
  const compact = height < 760;
  const [name, setName] = useState('');
  const [globalScores, setGlobalScores] = useState<GlobalScore[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    void loadPlayerName().then(setName);
    void loadLeaderboard().then((r) => setGlobalScores(r.leaderboard), () => setError('Leaderboard is temporarily unavailable.'));
  }, []);

  const leaderboard = useMemo(() => [...globalScores].sort((a, b) => b.score - a.score).slice(0, 10), [globalScores]);
  const projectedRank = useMemo(() => leaderboard.filter((entry) => entry.score > score).length + 1, [leaderboard, score]);
  const isTopTen = leaderboard.length < 10 || projectedRank <= 10;

  const submit = async () => {
    const clean = name.trim();
    if (!clean || submitting || submitted) return;
    setSubmitting(true);
    setError('');
    try {
      const result = await submitGlobalScore(clean, score, coins);
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
        const nav = globalThis.navigator as (Navigator & { share?: (data: { title?: string; text?: string; url?: string }) => Promise<void> }) | undefined;
        if (nav?.share) await nav.share({ title: "Pirate's Plunder", text: `I scored ${score.toLocaleString()} in Pirate's Plunder! Think you can beat my score?`, url: PLAY_STORE_URL });
        return;
      }
      await Share.share({ title: "Pirate's Plunder", message });
    } catch {}
  };

  const rowHeight = compact ? 25 : 29;

  return (
    <View style={{ position: 'absolute', inset: 0, backgroundColor: '#04384e' }}>
      <UnderwaterScene />
      <ScrollView bounces={false} showsVerticalScrollIndicator={false} contentContainerStyle={{ flexGrow: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 8, paddingTop: compact ? 7 : 13, paddingBottom: compact ? 9 : 16 }}>
        <View style={{ width: '100%', maxWidth: 430, alignItems: 'center' }}>
          <Pressable onPress={() => void shareScore()} style={({ pressed }) => ({ position: 'absolute', right: 8, top: 16, zIndex: 30, width: 62, height: 48, borderRadius: 8, borderWidth: 3, borderColor: '#e8b340', backgroundColor: pressed ? '#5a2b17' : '#351b0e', alignItems: 'center', justifyContent: 'center', shadowColor: '#000', shadowOpacity: 0.45, shadowRadius: 5, elevation: 8 })}>
            <Text maxFontSizeMultiplier={1} style={{ color: '#ffe29a', fontSize: 17, lineHeight: 18, fontWeight: '900' }}>↗</Text>
            <Text maxFontSizeMultiplier={1} style={{ color: '#ffe29a', fontSize: 9, fontWeight: '900', letterSpacing: 0.5 }}>SHARE</Text>
          </Pressable>

          <View style={{ zIndex: 8, marginBottom: -14 }}><PirateSkull /></View>
          <View style={{ width: '88%', backgroundColor: DARK_WOOD, borderWidth: 4, borderColor: '#75451f', borderRadius: 9, alignItems: 'center', paddingVertical: compact ? 4 : 6, zIndex: 7, shadowColor: '#000', shadowOpacity: 0.55, shadowRadius: 8, elevation: 9 }}>
            <View style={{ position: 'absolute', left: -12, top: 9, width: 17, height: 42, borderRadius: 5, backgroundColor: '#5b3218', borderWidth: 3, borderColor: '#8e5c29' }} />
            <View style={{ position: 'absolute', right: -12, top: 9, width: 17, height: 42, borderRadius: 5, backgroundColor: '#5b3218', borderWidth: 3, borderColor: '#8e5c29' }} />
            <Text maxFontSizeMultiplier={1} style={{ color: '#f2b62e', fontSize: compact ? 40 : 48, lineHeight: compact ? 43 : 51, fontWeight: '900', letterSpacing: 2, textShadowColor: '#100805', textShadowOffset: { width: 2, height: 2 }, textShadowRadius: 2 }}>SUNK!</Text>
            <Text maxFontSizeMultiplier={1} style={{ color: '#f7deb0', fontSize: 9, fontWeight: '900', letterSpacing: 0.5 }}>YOUR TREASURE SANK TO THE DEPTHS!</Text>
          </View>

          <ScrollShell>
            <Text maxFontSizeMultiplier={1} style={{ color: INK, textAlign: 'center', fontSize: compact ? 17 : 20, fontWeight: '900', letterSpacing: 0.8 }}>—  YOUR SCORE  —</Text>
            <View style={{ alignSelf: 'center', width: '70%', backgroundColor: '#25150c', borderRadius: 5, borderWidth: 3, borderColor: '#65401e', marginTop: 5, paddingVertical: compact ? 2 : 4, shadowColor: '#000', shadowOpacity: 0.3, shadowRadius: 3 }}>
              <Text maxFontSizeMultiplier={1} style={{ color: '#ffd759', textAlign: 'center', fontSize: compact ? 28 : 33, lineHeight: compact ? 31 : 36, fontWeight: '900', letterSpacing: 1 }}>{score.toLocaleString()}</Text>
            </View>

            <View style={{ flexDirection: 'row', marginTop: compact ? 7 : 9, gap: 7 }}>
              <TextInput value={name} onChangeText={setName} maxLength={20} editable={!submitted} autoCapitalize="words" returnKeyType="done" onSubmitEditing={() => void submit()} placeholder="Enter your name..." placeholderTextColor="#796348" style={{ flex: 1, minWidth: 0, height: compact ? 36 : 40, borderRadius: 6, borderWidth: 2, borderColor: '#7c5935', backgroundColor: '#f1dba9', paddingHorizontal: 10, color: INK, fontSize: 14, fontWeight: '700' }} />
              <Pressable disabled={!name.trim() || submitting || submitted} onPress={() => void submit()} style={({ pressed }) => ({ width: compact ? 90 : 98, height: compact ? 36 : 40, borderRadius: 6, borderWidth: 3, borderColor: '#672714', backgroundColor: submitted || !name.trim() ? '#927650' : pressed ? '#741015' : RED, alignItems: 'center', justifyContent: 'center', shadowColor: '#000', shadowOpacity: 0.25, shadowRadius: 2 })}>
                <Text maxFontSizeMultiplier={1} style={{ color: '#ffe8ad', fontSize: 13, fontWeight: '900', letterSpacing: 0.5 }}>{submitted ? 'SAVED' : 'SUBMIT'}</Text>
              </Pressable>
            </View>
            <Text maxFontSizeMultiplier={1} style={{ color: '#62482d', textAlign: 'center', fontSize: 9, marginTop: 3, fontWeight: '700' }}>Submit your name to claim your place among the captains!</Text>
            {submitting ? <ActivityIndicator color={RED} style={{ marginTop: 3 }} /> : null}
            {error ? <Text style={{ color: '#8b1e1e', textAlign: 'center', fontSize: 9, marginTop: 2 }}>{error}</Text> : null}

            <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: compact ? 7 : 9, marginBottom: 3 }}>
              <View style={{ flex: 1, height: 2, backgroundColor: '#8c683c' }} />
              <Text maxFontSizeMultiplier={1} style={{ color: INK, textAlign: 'center', fontSize: compact ? 18 : 21, fontWeight: '900', marginHorizontal: 8, letterSpacing: 0.8 }}>☠ LEADERBOARD ☠</Text>
              <View style={{ flex: 1, height: 2, backgroundColor: '#8c683c' }} />
            </View>

            <View style={{ borderTopWidth: 2, borderTopColor: '#967044' }}>
              {leaderboard.map((entry, index) => {
                const current = submitted && entry.name === name.trim() && entry.score === score;
                const rank = index + 1;
                return (
                  <View key={`${entry.createdAt}-${index}`} style={{ height: rowHeight, flexDirection: 'row', alignItems: 'center', borderBottomWidth: 1, borderBottomColor: 'rgba(94,61,27,.25)', paddingHorizontal: 4, backgroundColor: current ? '#49301d' : index % 2 ? 'rgba(126,86,39,.07)' : 'transparent', borderRadius: current ? 4 : 0 }}>
                    <View style={{ width: 42, alignItems: 'center' }}>
                      {rank <= 3 ? <View style={{ width: 23, height: 23, borderRadius: 12, backgroundColor: rank === 1 ? '#dca51e' : rank === 2 ? '#a8a39b' : '#a96832', borderWidth: 2, borderColor: rank === 1 ? '#7e5512' : '#6e5033', alignItems: 'center', justifyContent: 'center' }}><Text maxFontSizeMultiplier={1} style={{ color: '#fff1c4', fontSize: 11, fontWeight: '900' }}>{rank}</Text></View> : <Text maxFontSizeMultiplier={1} style={{ color: current ? '#fff1c5' : INK, fontSize: 12, fontWeight: '900' }}>{rank}</Text>}
                    </View>
                    <Text numberOfLines={1} maxFontSizeMultiplier={1} style={{ flex: 1, color: current ? '#fff1c5' : INK, fontSize: compact ? 12 : 13, fontWeight: current ? '900' : '700' }}>{current ? 'You' : entry.name}</Text>
                    <View style={{ width: 12, height: 12, borderRadius: 6, backgroundColor: '#d9a41c', borderWidth: 1, borderColor: '#805b10', marginRight: 7 }} />
                    <Text maxFontSizeMultiplier={1} style={{ width: 70, textAlign: 'right', color: current ? '#fff1c5' : INK, fontSize: compact ? 12 : 13, fontWeight: '900' }}>{entry.score.toLocaleString()}</Text>
                  </View>
                );
              })}
              {leaderboard.length === 0 && !error ? <Text style={{ color: '#684923', textAlign: 'center', paddingVertical: 12, fontSize: 11, fontWeight: '700' }}>Be the first captain on the leaderboard!</Text> : null}
            </View>
          </ScrollShell>

          <View style={{ width: '83%', marginTop: -1, backgroundColor: '#21160e', borderBottomLeftRadius: 12, borderBottomRightRadius: 12, borderWidth: 2, borderTopWidth: 0, borderColor: '#68431e', alignItems: 'center', paddingVertical: compact ? 6 : 8, paddingHorizontal: 10, shadowColor: '#000', shadowOpacity: 0.4, shadowRadius: 5, elevation: 6 }}>
            <Text maxFontSizeMultiplier={1} style={{ color: '#fff0c0', fontSize: compact ? 13 : 15, fontWeight: '900' }}>YOUR SCORE: <Text style={{ color: '#ffd95a' }}>{score.toLocaleString()}</Text></Text>
            <Text maxFontSizeMultiplier={1} style={{ color: '#ead7ac', fontSize: compact ? 9 : 10, marginTop: 1, textAlign: 'center' }}>{isTopTen ? `Currently good for #${projectedRank} on the leaderboard.` : 'Not in the top 10 yet — sail again and climb the ranks!'}</Text>
          </View>

          <Pressable onPress={onRetry} style={({ pressed }) => ({ width: '76%', height: compact ? 48 : 55, marginTop: compact ? 8 : 11, borderWidth: 4, borderColor: GOLD, backgroundColor: pressed ? '#761017' : RED, borderRadius: 9, alignItems: 'center', justifyContent: 'center', shadowColor: '#000', shadowOpacity: 0.55, shadowRadius: 7, elevation: 9 })}>
            <Text maxFontSizeMultiplier={1} style={{ color: '#ffe5a0', fontSize: compact ? 19 : 22, fontWeight: '900', letterSpacing: 0.7 }}>⚔  PLAY AGAIN</Text>
          </Pressable>
        </View>
      </ScrollView>
    </View>
  );
}
