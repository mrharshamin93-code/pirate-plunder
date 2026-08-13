import { View } from 'react-native';
import { PressableFeedback } from 'heroui-native';
import { Volume2, VolumeX } from 'lucide-react-native';

interface MusicToggleProps {
  muted: boolean;
  onToggle: () => void;
}

/** Small always-on-top control so the shanty can be silenced mid-run. */
export function MusicToggle({ muted, onToggle }: MusicToggleProps) {
  const Icon = muted ? VolumeX : Volume2;
  return (
    <View
      pointerEvents="box-none"
      className="pt-safe-offset-3 absolute top-0 right-0 left-0 items-center"
    >
      <PressableFeedback
        onPress={onToggle}
        accessibilityRole="button"
        accessibilityLabel={muted ? 'Turn music on' : 'Turn music off'}
      >
        <View className="border-border/70 h-9 w-9 items-center justify-center rounded-full border bg-[rgba(8,46,60,0.72)]">
          <Icon size={17} color={muted ? '#8fb3bd' : '#d9f4fb'} />
        </View>
      </PressableFeedback>
    </View>
  );
}
