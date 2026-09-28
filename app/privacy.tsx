import { ScrollView, View } from 'react-native';
import { Stack } from 'expo-router';
import { Text } from 'heroui-native';

export default function PrivacyPolicy() {
  return (
    <>
      <Stack.Screen options={{ title: 'Privacy Policy' }} />
      <ScrollView style={{ flex: 1, backgroundColor: '#ffffff' }} contentContainerStyle={{ paddingHorizontal: 24, paddingVertical: 40 }}>
        <View style={{ width: '100%', maxWidth: 760, alignSelf: 'center' }}>
          <Text style={{ color: '#111111', fontSize: 30, fontWeight: '700' }}>Pirate&apos;s Plunder Privacy Policy</Text>
          <Text style={{ color: '#666666', marginTop: 8, fontSize: 14 }}>Last updated: September 28, 2026</Text>

          <Text style={{ color: '#111111', marginTop: 32, fontSize: 20, fontWeight: '600' }}>Overview</Text>
          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>Pirate&apos;s Plunder is a casual mobile game. The game does not require users to create an account or sign in.</Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>Information We Collect</Text>
          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>We do not ask you to provide personal information such as your name, phone number, or precise location. The app may use analytics and advertising services that automatically process device, app usage, advertising identifier, and diagnostic information as permitted by your device settings and applicable law.</Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>Game Data</Text>
          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>Game progress, settings, scores, and related gameplay information may be stored locally or processed to provide game features, analytics, and leaderboard functionality.</Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>Advertising</Text>
          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>Pirate&apos;s Plunder may display advertising provided by Google AdMob. Google and its advertising partners may process device information, advertising identifiers, approximate location derived from network information, and ad interaction data to provide, measure, and protect advertising, subject to your consent choices and applicable law.</Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>Analytics</Text>
          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>We may use analytics services, including Firebase Analytics, to understand game usage, improve gameplay, diagnose problems, and measure app performance.</Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>Children&apos;s Privacy</Text>
          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>Pirate&apos;s Plunder does not knowingly ask children to provide personal information. Advertising and analytics features are configured and used in accordance with applicable platform requirements and privacy laws.</Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>Changes to This Policy</Text>
          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>We may update this Privacy Policy when the game&apos;s features or data practices change. The revised policy will be posted here with an updated date.</Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>Contact</Text>
          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>For privacy-related questions, contact: heroinvestor15@gmail.com</Text>
        </View>
      </ScrollView>
    </>
  );
}
