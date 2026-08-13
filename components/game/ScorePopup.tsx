import { useEffect } from 'react';
import { Text } from 'heroui-native';
import Animated, {
  Easing,
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';

export interface Popup {
  id: number;
  points: number;
  x: number;
  y: number;
}

const WIDTH = 96;
const DURATION = 850;

/** Floating "+250" that rises off a salvaged dubloon and fades out. */
export function ScorePopup({ popup, onDone }: { popup: Popup; onDone: (id: number) => void }) {
  const t = useSharedValue(0);

  useEffect(() => {
    t.value = withTiming(1, { duration: DURATION, easing: Easing.out(Easing.quad) }, (finished) => {
      'worklet';
      if (finished) runOnJS(onDone)(popup.id);
    });
  }, [t, onDone, popup.id]);

  const style = useAnimatedStyle(() => ({
    opacity: 1 - t.value * t.value,
    transform: [{ translateY: -48 * t.value }, { scale: 0.8 + 0.35 * Math.min(1, t.value * 5) }],
  }));

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        {
          position: 'absolute',
          left: popup.x - WIDTH / 2,
          top: popup.y - 34,
          width: WIDTH,
          alignItems: 'center',
        },
        style,
      ]}
    >
      <Text
        className="text-dubloon text-xl font-bold"
        style={{
          textShadowColor: 'rgba(4,20,28,0.95)',
          textShadowOffset: { width: 0, height: 2 },
          textShadowRadius: 4,
        }}
      >
        +{popup.points.toLocaleString()}
      </Text>
    </Animated.View>
  );
}
