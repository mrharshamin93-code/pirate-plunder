import { memo, useMemo } from 'react';
import { View } from 'react-native';
import { Gesture, GestureDetector, type GestureType } from 'react-native-gesture-handler';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { Circle, Polygon } from 'react-native-svg';

/**
 * Dynamic thumbstick used to steer the boat.
 *
 * The player can press anywhere inside the bottom control zone. That first touch
 * becomes the centre of the joystick, and dragging away from it controls heading
 * and thrust. Releasing the finger hides and resets the joystick.
 */
export const JOYSTICK = {
  /** diameter of the base ring */
  base: 138,
  /** diameter of the thumb knob */
  knob: 58,
  /** how far the knob travels from centre before it is clamped */
  throw: 40,
  /** offsets smaller than this read as "let go of the stick" */
  deadZone: 7,
  /** height of the bottom area in which a dynamic joystick can be started */
  touchZoneHeight: 158,
} as const;

export interface JoystickInput {
  /** unit heading the stick points in, x/y in screen space */
  dirX: SharedValue<number>;
  dirY: SharedValue<number>;
  /** 0 = centred, 1 = full deflection */
  magnitude: SharedValue<number>;
  /** knob offset in px, already clamped to JOYSTICK.throw */
  knobX: SharedValue<number>;
  knobY: SharedValue<number>;
  /** retained for compatibility with the existing GameCanvas input shape */
  gesture: GestureType;
}

const RingArt = memo(function RingArt() {
  const box = JOYSTICK.base;
  const half = box / 2;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Circle
        r={half - 3}
        fill="rgba(6,32,42,0.42)"
        stroke="rgba(217,244,251,0.3)"
        strokeWidth={3}
      />
      <Circle r={half - 16} fill="none" stroke="rgba(217,244,251,0.12)" strokeWidth={1.5} />
      {[0, 90, 180, 270].map((deg) => (
        <Polygon
          key={deg}
          points={`${half - 9},0 ${half - 17},-5 ${half - 17},5`}
          fill="rgba(217,244,251,0.32)"
          transform={`rotate(${deg})`}
        />
      ))}
    </Svg>
  );
});

const KnobArt = memo(function KnobArt() {
  const box = JOYSTICK.knob;
  const half = box / 2;
  return (
    <Svg width={box} height={box} viewBox={`${-half} ${-half} ${box} ${box}`}>
      <Circle r={half - 2} fill="rgba(217,244,251,0.9)" />
      <Circle r={half - 2} fill="none" stroke="rgba(6,32,42,0.35)" strokeWidth={2} />
      <Circle cx={-5} cy={-6} r={7} fill="rgba(255,255,255,0.85)" />
      <Circle r={5} fill="rgba(6,32,42,0.22)" />
    </Svg>
  );
});

export function Joystick({ input }: { input: JoystickInput }) {
  const { dirX, dirY, knobX, knobY, magnitude } = input;
  const originX = useSharedValue(0);
  const originY = useSharedValue(0);
  const active = useSharedValue(0);

  const gesture = useMemo(() => {
    const apply = (px: number, py: number) => {
      'worklet';

      const dx = px - originX.value;
      const dy = py - originY.value;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < JOYSTICK.deadZone) {
        magnitude.value = 0;
        knobX.value = dx;
        knobY.value = dy;
        return;
      }

      dirX.value = dx / dist;
      dirY.value = dy / dist;
      magnitude.value = Math.min(1, dist / JOYSTICK.throw);

      const clamped = Math.min(dist, JOYSTICK.throw);
      knobX.value = (dx / dist) * clamped;
      knobY.value = (dy / dist) * clamped;
    };

    return Gesture.Pan()
      .minDistance(0)
      .maxPointers(1)
      .onBegin((e) => {
        'worklet';
        originX.value = e.x;
        originY.value = e.y;
        knobX.value = 0;
        knobY.value = 0;
        magnitude.value = 0;
        active.value = 1;
      })
      .onUpdate((e) => {
        'worklet';
        apply(e.x, e.y);
      })
      .onFinalize(() => {
        'worklet';
        magnitude.value = 0;
        knobX.value = withTiming(0, { duration: 110 });
        knobY.value = withTiming(0, { duration: 110 });
        active.value = withTiming(0, { duration: 90 });
      });
  }, [active, dirX, dirY, magnitude, knobX, knobY, originX, originY]);

  const ringStyle = useAnimatedStyle(() => ({
    opacity: active.value * (0.7 + 0.3 * magnitude.value),
    transform: [
      { translateX: originX.value - JOYSTICK.base / 2 },
      { translateY: originY.value - JOYSTICK.base / 2 },
    ],
  }));

  const knobStyle = useAnimatedStyle(() => ({
    opacity: active.value * (0.75 + 0.25 * magnitude.value),
    transform: [
      { translateX: originX.value - JOYSTICK.knob / 2 + knobX.value },
      { translateY: originY.value - JOYSTICK.knob / 2 + knobY.value },
    ],
  }));

  return (
    <View pointerEvents="box-none" className="absolute right-0 bottom-0 left-0">
      <GestureDetector gesture={gesture}>
        <Animated.View
          accessibilityRole="adjustable"
          accessibilityLabel="Steer the boat"
          style={{ width: '100%', height: JOYSTICK.touchZoneHeight }}
        >
          <Animated.View
            pointerEvents="none"
            style={[
              {
                position: 'absolute',
                left: 0,
                top: 0,
                width: JOYSTICK.base,
                height: JOYSTICK.base,
              },
              ringStyle,
            ]}
          >
            <RingArt />
          </Animated.View>

          <Animated.View
            pointerEvents="none"
            style={[
              {
                position: 'absolute',
                left: 0,
                top: 0,
                width: JOYSTICK.knob,
                height: JOYSTICK.knob,
              },
              knobStyle,
            ]}
          >
            <KnobArt />
          </Animated.View>
        </Animated.View>
      </GestureDetector>
    </View>
  );
}
