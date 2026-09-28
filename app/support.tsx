import { Linking, Pressable, ScrollView, Text, View } from 'react-native';
import { Stack } from 'expo-router';

const EMAIL = 'heroinvestor15@gmail.com';

export default function Support() {
  return (
    <ScrollView style={{ flex: 1, backgroundColor: '#071f29' }} contentContainerStyle={{ paddingHorizontal: 24, paddingVertical: 60, flexGrow: 1 }}>
      <Stack.Screen options={{ title: "Pirate's Plunder Support" }} />
      <View style={{ width: '100%', maxWidth: 760, alignSelf: 'center' }}>
        <Text style={{ color: '#f5c542', fontSize: 14, fontWeight: '800', letterSpacing: 2 }}>PIRATE&apos;S PLUNDER</Text>
        <Text style={{ color: '#ffffff', fontSize: 42, fontWeight: '900', marginTop: 12 }}>Support</Text>
        <Text style={{ color: '#c7dfe3', fontSize: 18, lineHeight: 28, marginTop: 18 }}>
          Need help with the game, found a bug, or have feedback? Send us an email and include your device type and a short description of the issue.
        </Text>
        <Pressable onPress={() => void Linking.openURL(`mailto:${EMAIL}?subject=Pirate's%20Plunder%20Support`)} style={{ alignSelf: 'flex-start', marginTop: 30, backgroundColor: '#f5c542', paddingHorizontal: 24, paddingVertical: 15, borderRadius: 12 }}>
          <Text style={{ color: '#10252b', fontWeight: '900', fontSize: 16 }}>Email Support</Text>
        </Pressable>
        <Text style={{ color: '#91afb5', fontSize: 15, marginTop: 18 }}>{EMAIL}</Text>
      </View>
    </ScrollView>
  );
}
