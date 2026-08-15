import { ScrollView, View } from 'react-native';
import { Stack } from 'expo-router';
import { Text } from 'heroui-native';

export default function PrivacyPolicy() {
  return (
    <>
      <Stack.Screen options={{ title: 'Privacy Policy' }} />

      <ScrollView
        className="bg-sea-deep flex-1"
        contentContainerClassName="px-6 py-10"
      >
        <View className="mx-auto w-full max-w-2xl">
          <Text className="text-foreground text-3xl font-bold">
            Pirate&apos;s Plunder Privacy Policy
          </Text>

          <Text className="text-foreground/60 mt-2 text-sm">
            Last updated: August 14, 2026
          </Text>

          <Text className="text-foreground mt-8 text-xl font-semibold">
            Overview
          </Text>
          <Text className="text-foreground/80 mt-2 leading-6">
            Pirate&apos;s Plunder is a casual mobile game. The current version
            does not require users to create an account or sign in.
          </Text>

          <Text className="text-foreground mt-6 text-xl font-semibold">
            Information We Collect
          </Text>
          <Text className="text-foreground/80 mt-2 leading-6">
            Pirate&apos;s Plunder does not intentionally collect personal
            information such as your name, email address, phone number, or
            precise location.
          </Text>

          <Text className="text-foreground mt-6 text-xl font-semibold">
            Game Data
          </Text>
          <Text className="text-foreground/80 mt-2 leading-6">
            Game progress, settings, and high scores may be stored locally on
            your device. This information is used only to provide game
            functionality and is not intentionally transmitted to us.
          </Text>

          <Text className="text-foreground mt-6 text-xl font-semibold">
            Advertising
          </Text>
          <Text className="text-foreground/80 mt-2 leading-6">
            The current version of Pirate&apos;s Plunder does not contain
            advertising.
          </Text>

          <Text className="text-foreground mt-6 text-xl font-semibold">
            Children&apos;s Privacy
          </Text>
          <Text className="text-foreground/80 mt-2 leading-6">
            Pirate&apos;s Plunder does not knowingly collect personal
            information from children.
          </Text>

          <Text className="text-foreground mt-6 text-xl font-semibold">
            Changes to This Policy
          </Text>
          <Text className="text-foreground/80 mt-2 leading-6">
            We may update this Privacy Policy if the game&apos;s features or
            data practices change. Any updated policy will be posted on this
            page with a revised date.
          </Text>

          <Text className="text-foreground mt-6 text-xl font-semibold">
            Contact
          </Text>
          <Text className="text-foreground/80 mt-2 leading-6">
            For privacy-related questions, contact: heroinvestor15@gmail.com
          </Text>
        </View>
      </ScrollView>
    </>
  );
}
