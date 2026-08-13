import { memo } from 'react';
import { View } from 'react-native';
import { GestureDetector, type GestureType } from 'react-native-gesture-handler';
import Animated, { useAnimatedStyle, type SharedValue } from 'react-native-reanimated';
import Svg, { Polygon } from 'react-native-svg';

/**
 * Tank controls, matching the original's arrow keys: the left cluster comes
 * about to port or starboard, the right cluster rows forward or backs the oars.
 *
 * Each button is driven by a 0/1 shared value so several can be held at once
 * and releasing one never cancels another. The shared value and the gesture
 * that writes to it are both built by the owning GameCanvas (the component
 * that created the shared value via useSharedValue) and handed down here
 * fully formed, so this component only ever reads `pressed` for styling and
 * attaches the pre-built gesture — it never mutates a prop itself.
 */
export interface ControlButtonInput {
  pressed: SharedValue<number>;
  gesture: GestureType;
}

export interface ControlInputs {
  turnLeft: ControlButtonInput;
  turnRight: ControlButtonInput;
  forward: ControlButtonInput;
  reverse: ControlButtonInput;
}

const BUTTON = 68;
const GLYPH = 30;

type Glyph = 'left' | 'right' | 'up' | 'down';

const GLYPH_ROTATION: Record<Glyph, number> = {
  right: 0,
  down: 90,
  left: 180,
  up: 270,
};

/** Triangle pointing right at 0deg, rotated into the requested direction. */
const Arrow = memo(function Arrow({ glyph }: { glyph: Glyph }) {
  const half = GLYPH / 2;
  return (
    <Svg width={GLYPH} height={GLYPH} viewBox={`${-half} ${-half} ${GLYPH} ${GLYPH}`}>
      <Polygon
        points="9,0 -7,-10 -7,10"
        fill="#ffffff"
        fillOpacity={0.92}
        transform={`rotate(${GLYPH_ROTATION[glyph]})`}
      />
    </Svg>
  );
});

function HoldButton({
  input,
  glyph,
  label,
}: {
  input: ControlButtonInput;
  glyph: Glyph;
  label: string;
}) {
  const { pressed, gesture } = input;

  const style = useAnimatedStyle(() => ({
    backgroundColor: pressed.value === 1 ? 'rgba(255,255,255,0.34)' : 'rgba(255,255,255,0.13)',
    borderColor: pressed.value === 1 ? 'rgba(255,255,255,0.78)' : 'rgba(255,255,255,0.34)',
    transform: [{ scale: pressed.value === 1 ? 0.94 : 1 }],
  }));

  return (
    <GestureDetector gesture={gesture}>
      <Animated.View
        accessibilityRole="button"
        accessibilityLabel={label}
        style={[
          {
            width: BUTTON,
            height: BUTTON,
            borderRadius: BUTTON / 2,
            borderWidth: 3,
            alignItems: 'center',
            justifyContent: 'center',
          },
          style,
        ]}
      >
        <Arrow glyph={glyph} />
      </Animated.View>
    </GestureDetector>
  );
}

export function ControlPad({ inputs }: { inputs: ControlInputs }) {
  return (
    <>
      <View
        pointerEvents="box-none"
        className="pb-safe-offset-4 absolute bottom-0 left-4 flex-row gap-3"
      >
        <HoldButton input={inputs.turnLeft} glyph="left" label="Come about to port" />
        <HoldButton input={inputs.turnRight} glyph="right" label="Come about to starboard" />
      </View>

      <View
        pointerEvents="box-none"
        className="pb-safe-offset-4 absolute right-4 bottom-0 flex-row gap-3"
      >
        <HoldButton input={inputs.reverse} glyph="down" label="Back the oars" />
        <HoldButton input={inputs.forward} glyph="up" label="Row forward" />
      </View>
    </>
  );
}
