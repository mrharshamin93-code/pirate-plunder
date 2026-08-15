import { ScrollView, View } from 'react-native';
import { Stack } from 'expo-router';
import { Text } from 'heroui-native';

export default function PrivacyPolicy() {
  return (
    <>
      <Stack.Screen options={{ title: 'Privacy Policy' }} />

      <ScrollView
        style={{ flex: 1, backgroundColor: '#ffffff' }}
        contentContainerStyle={{ paddingHorizontal: 24, paddingVertical: 40 }}
      >
        <View style={{ width: '100%', maxWidth: 760, alignSelf: 'center' }}>
          <Text style={{ color: '#111111', fontSize: 30, fontWeight: '700' }}>
            Pirate&apos;s Plunder Privacy Policy
          </Text>

          <Text style={{ color: '#666666', marginTop: 8, fontSize: 14 }}>
            Last updated: August 14, 2026
          </Text>

          <Text style={{ color: '#111111', marginTop: 32, fontSize: 20, fontWeight: '600' }}>
            Overview
          </Text>

          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>
            Pirate&apos;s Plunder is a casual mobile game. The current version
            does not require users to create an account or sign in.
          </Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>
            Information We Collect
          </Text>

          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>
            Pirate&apos;s Plunder does not intentionally collect personal
            information such as your name, email address, phone number, or
            precise location.
          </Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>
            Game Data
          </Text>

          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>
            Game progress, settings, and high scores may be stored locally on
            your device. This information is used only to provide game
            functionality and is not intentionally transmitted to us.
          </Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>
            Advertising
          </Text>

          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>
            The current version of Pirate&apos;s Plunder does not contain
            advertising.
          </Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>
            Children&apos;s Privacy
          </Text>

          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>
            Pirate&apos;s Plunder does not knowingly collect personal
            information from children.
          </Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>
            Changes to This Policy
          </Text>

          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>
            We may update this Privacy Policy if the game&apos;s features or
            data practices change. Any updated policy will be posted on this
            page with a revised date.
          </Text>

          <Text style={{ color: '#111111', marginTop: 24, fontSize: 20, fontWeight: '600' }}>
            Contact
          </Text>

          <Text style={{ color: '#333333', marginTop: 8, fontSize: 16, lineHeight: 24 }}>
            For privacy-related questions, contact: heroinvestor15@gmail.com
          </Text>
        </View>
      </ScrollView>
    </>
  );
}
