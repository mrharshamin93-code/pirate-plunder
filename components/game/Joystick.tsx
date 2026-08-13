import { memo } from 'react';
import { View } from 'react-native';
import { GestureDetector, type GestureType } from 'react-native-gesture-handler';
import Animated, { useAnimatedStyle, type SharedValue } from 'react-native-reanimated';
import Svg, { Circle, Polygon } from 'react-native-svg';

/**
 * Thumbstick used to steer the boat: she heads where the stick points and rows
 * harder the further it is pushed.
 *
 * The shared values and the gesture that writes to them are both created by the
 * owning GameCanvas and handed down here fully formed, so this component only
 * reads them for styling and never mutates a prop.
 */
export const JOYSTICK = {
  /** diameter of the base ring, and of the touch target */
  base: 138,
  /** diameter of the thumb knob */
  knob: 58,
  /** how far the knob travels from centre before it is clamped */
  throw: 40,
  /** offsets smaller than this read as "let go of the stick" */
  deadZone: 7,
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
      {/* compass ticks, one per quarter */}
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
  const { knobX, knobY, magnitude, gesture } = input;
  const half = JOYSTICK.knob / 2;

  const knobStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: knobX.value }, { translateY: knobY.value }],
    opacity: 0.75 + 0.25 * magnitude.value,
  }));

  const ringStyle = useAnimatedStyle(() => ({
    opacity: 0.7 + 0.3 * magnitude.value,
  }));

  return (
    <View
      pointerEvents="box-none"
      className="pb-safe-offset-3 absolute right-0 bottom-0 left-0 items-center"
    >
      <GestureDetector gesture={gesture}>
        <Animated.View
          accessibilityRole="adjustable"
          accessibilityLabel="Steer the boat"
          style={{ width: JOYSTICK.base, height: JOYSTICK.base }}
        >
          <Animated.View pointerEvents="none" style={ringStyle}>
            <RingArt />
          </Animated.View>
          <Animated.View
            pointerEvents="none"
            style={[
              {
                position: 'absolute',
                left: JOYSTICK.base / 2 - half,
                top: JOYSTICK.base / 2 - half,
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
