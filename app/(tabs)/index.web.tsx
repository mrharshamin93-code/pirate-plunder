import { Image, Linking, Pressable, ScrollView, Text, View, useWindowDimensions } from 'react-native';
import { Link, Stack } from 'expo-router';

const PLAY_URL = 'https://play.google.com/store/apps/details?id=com.harshamin.piratesplunder';

const features = [
  ['💰', 'Collect Treasure', 'Grab coins and push your score higher as the seas get more dangerous.'],
  ['💣', 'Dodge the Danger', 'Avoid explosive mines and deadly whirlpools. One mistake can end the run.'],
  ['🏴‍☠️', 'Unlock Your Fleet', 'Chase higher scores and unlock new ships and collectible mine styles.'],
];

export default function PiratePlunderWebsite() {
  const { width } = useWindowDimensions();
  const compact = width < 760;

  return (
    <ScrollView style={{ flex: 1, backgroundColor: '#041923' }} contentContainerStyle={{ flexGrow: 1 }}>
      <Stack.Screen options={{ title: "Pirate's Plunder", headerShown: false }} />

      <View style={{ minHeight: 720, backgroundColor: '#062936', overflow: 'hidden' }}>
        <View style={{ position: 'absolute', width: 520, height: 520, borderRadius: 260, backgroundColor: '#0d7891', opacity: 0.2, top: -160, right: -120 }} />
        <View style={{ position: 'absolute', width: 420, height: 420, borderRadius: 210, backgroundColor: '#f0b72d', opacity: 0.08, bottom: -210, left: -120 }} />

        <View style={{ width: '100%', maxWidth: 1120, alignSelf: 'center', paddingHorizontal: compact ? 22 : 40 }}>
          <View style={{ height: 82, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
              <Image source={{ uri: '/icons/icon-192.png' }} style={{ width: 48, height: 48, borderRadius: 12 }} resizeMode="cover" />
              <Text style={{ color: '#fff7dd', fontSize: 20, fontWeight: '800' }}>Pirate&apos;s Plunder</Text>
            </View>
            {!compact ? (
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 24 }}>
                <Link href="/privacy" style={{ color: '#d7e9ec', fontSize: 15 }}>Privacy</Link>
                <Link href="/support" style={{ color: '#d7e9ec', fontSize: 15 }}>Support</Link>
              </View>
            ) : null}
          </View>

          <View style={{ flexDirection: compact ? 'column' : 'row', alignItems: 'center', justifyContent: 'space-between', paddingTop: compact ? 35 : 70, paddingBottom: 80, gap: 54 }}>
            <View style={{ flex: 1, maxWidth: 620, alignItems: compact ? 'center' : 'flex-start' }}>
              <Text style={{ color: '#f5c542', fontSize: 14, fontWeight: '800', letterSpacing: 2 }}>FAST-PACED PIRATE ARCADE</Text>
              <Text style={{ color: '#ffffff', fontSize: compact ? 48 : 68, lineHeight: compact ? 54 : 72, fontWeight: '900', marginTop: 16, textAlign: compact ? 'center' : 'left' }}>
                Plunder treasure. Dodge danger. Rule the seas.
              </Text>
              <Text style={{ color: '#c7dfe3', fontSize: 19, lineHeight: 29, marginTop: 24, maxWidth: 560, textAlign: compact ? 'center' : 'left' }}>
                Sail the high seas in a quick, addictive arcade challenge. Collect treasure, avoid mines and whirlpools, and see how long you can survive.
              </Text>
              <Pressable onPress={() => void Linking.openURL(PLAY_URL)} style={({ pressed }) => ({ marginTop: 34, backgroundColor: pressed ? '#e4ac24' : '#f5c542', paddingHorizontal: 28, paddingVertical: 17, borderRadius: 14, shadowColor: '#000', shadowOpacity: 0.25, shadowRadius: 14 })}>
                <Text style={{ color: '#10252b', fontSize: 17, fontWeight: '900' }}>Get it free on Google Play →</Text>
              </Pressable>
              <Text style={{ color: '#89aeb5', marginTop: 14, fontSize: 13 }}>Free to play • Android</Text>
            </View>

            <View style={{ width: compact ? Math.min(width - 70, 390) : 410, height: compact ? Math.min(width - 70, 390) : 410, borderRadius: 44, padding: 12, backgroundColor: '#f5c542', shadowColor: '#000', shadowOpacity: 0.35, shadowRadius: 28 }}>
              <Image source={{ uri: '/icons/icon-512.png' }} style={{ width: '100%', height: '100%', borderRadius: 34 }} resizeMode="contain" />
            </View>
          </View>
        </View>
      </View>

      <View style={{ backgroundColor: '#f6f1e6', paddingVertical: 78, paddingHorizontal: 22 }}>
        <View style={{ width: '100%', maxWidth: 1060, alignSelf: 'center' }}>
          <Text style={{ color: '#10252b', fontSize: 36, fontWeight: '900', textAlign: 'center' }}>Simple to learn. Hard to put down.</Text>
          <Text style={{ color: '#52656a', fontSize: 17, lineHeight: 26, textAlign: 'center', marginTop: 12 }}>Built for quick runs, high-score chasing, and one-more-try gameplay.</Text>
          <View style={{ flexDirection: compact ? 'column' : 'row', gap: 18, marginTop: 44 }}>
            {features.map(([icon, title, body]) => (
              <View key={title} style={{ flex: 1, backgroundColor: '#ffffff', borderRadius: 20, padding: 26, minHeight: 210, borderWidth: 1, borderColor: '#e5ded0' }}>
                <Text style={{ fontSize: 34 }}>{icon}</Text>
                <Text style={{ color: '#10252b', fontSize: 21, fontWeight: '800', marginTop: 18 }}>{title}</Text>
                <Text style={{ color: '#617176', fontSize: 15, lineHeight: 23, marginTop: 10 }}>{body}</Text>
              </View>
            ))}
          </View>
        </View>
      </View>

      <View style={{ backgroundColor: '#071f29', paddingVertical: 74, paddingHorizontal: 22, alignItems: 'center' }}>
        <Text style={{ color: '#f5c542', fontSize: 13, fontWeight: '800', letterSpacing: 2 }}>HOW MUCH CAN YOU PLUNDER?</Text>
        <Text style={{ color: '#ffffff', fontSize: compact ? 34 : 44, fontWeight: '900', textAlign: 'center', marginTop: 14 }}>Set sail and chase your highest score.</Text>
        <Pressable onPress={() => void Linking.openURL(PLAY_URL)} style={{ marginTop: 28, backgroundColor: '#f5c542', paddingHorizontal: 28, paddingVertical: 16, borderRadius: 14 }}>
          <Text style={{ color: '#10252b', fontSize: 16, fontWeight: '900' }}>Download Pirate&apos;s Plunder</Text>
        </Pressable>
      </View>

      <View style={{ backgroundColor: '#041923', paddingVertical: 30, paddingHorizontal: 22 }}>
        <View style={{ width: '100%', maxWidth: 1060, alignSelf: 'center', flexDirection: compact ? 'column' : 'row', gap: 18, alignItems: 'center', justifyContent: 'space-between' }}>
          <Text style={{ color: '#88a7ad', fontSize: 13 }}>© 2026 Pirate&apos;s Plunder. Developed by Harsh Amin.</Text>
          <View style={{ flexDirection: 'row', gap: 20 }}>
            <Link href="/privacy" style={{ color: '#c8dadd', fontSize: 13 }}>Privacy Policy</Link>
            <Link href="/support" style={{ color: '#c8dadd', fontSize: 13 }}>Support</Link>
          </View>
        </View>
      </View>
    </ScrollView>
  );
}
