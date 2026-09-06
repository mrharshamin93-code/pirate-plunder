import { memo, useEffect, useMemo } from 'react';
import { View, useWindowDimensions } from 'react-native';
import { Gesture, GestureDetector, type GestureType } from 'react-native-gesture-handler';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { Circle, Polygon } from 'react-native-svg';

/**
 * Semi-dynamic thumbstick used to steer the boat.
 *
 * The joystick has a normal home position at the bottom centre of the screen.
 * A touch near that home position lets the base slide underneath the player's
 * thumb, while touches farther away only shift the base by a limited amount.
 * Releasing the finger returns the joystick to its home position.
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
  /** height of the bottom area that accepts joystick touches */
  touchZoneHeight: 158,
  /** maximum distance the joystick base can move away from home */
  baseShift: 72,
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
  const { width } = useWindowDimensions();
  const { dirX, dirY, knobX, knobY, magnitude } = input;

  const homeX = useSharedValue(width / 2);
  const homeY = useSharedValue(JOYSTICK.touchZoneHeight - JOYSTICK.base / 2 - 8);
  const originX = useSharedValue(width / 2);
  const originY = useSharedValue(JOYSTICK.touchZoneHeight - JOYSTICK.base / 2 - 8);
  const active = useSharedValue(0);

  useEffect(() => {
    homeX.value = width / 2;

    if (active.value === 0) {
      originX.value = width / 2;
    }
  }, [active, homeX, originX, width]);

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

    const recenterTowardTouch = (px: number, py: number) => {
      'worklet';

      const dx = px - homeX.value;
      const dy = py - homeY.value;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist <= JOYSTICK.baseShift || dist === 0) {
        originX.value = px;
        originY.value = py;
        return;
      }

      const scale = JOYSTICK.baseShift / dist;
      originX.value = homeX.value + dx * scale;
      originY.value = homeY.value + dy * scale;
    };

    return Gesture.Pan()
      .minDistance(0)
      .maxPointers(1)
      .onBegin((e) => {
        'worklet';
        active.value = 1;
        recenterTowardTouch(e.x, e.y);
        knobX.value = 0;
        knobY.value = 0;
        magnitude.value = 0;
        apply(e.x, e.y);
      })
      .onUpdate((e) => {
        'worklet';
        apply(e.x, e.y);
      })
      .onFinalize(() => {
        'worklet';
        magnitude.value = 0;
        knobX.value = withTiming(0, { duration: 120 });
        knobY.value = withTiming(0, { duration: 120 });
        originX.value = withTiming(homeX.value, { duration: 150 });
        originY.value = withTiming(homeY.value, { duration: 150 });
        active.value = withTiming(0, { duration: 120 });
      });
  }, [active, dirX, dirY, homeX, homeY, magnitude, knobX, knobY, originX, originY]);

  const ringStyle = useAnimatedStyle(() => ({
    opacity: active.value > 0 ? 0.78 + 0.22 * magnitude.value : 0.52,
    transform: [
      { translateX: originX.value - JOYSTICK.base / 2 },
      { translateY: originY.value - JOYSTICK.base / 2 },
    ],
  }));

  const knobStyle = useAnimatedStyle(() => ({
    opacity: active.value > 0 ? 0.78 + 0.22 * magnitude.value : 0.72,
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
