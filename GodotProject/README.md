# Pirate's Plunder — Godot Migration

This is the new game-engine implementation of Pirate's Plunder. It replaces the Unity migration as the active engine direction while the existing React Native/Expo implementation remains in the repository as the visual/gameplay reference.

## Engine

Godot 4.x, using GDScript and the Compatibility renderer for broad desktop/mobile/web support.

## Already ported

- Existing boat thrust, drag, lateral grip, speed cap and speed-dependent turning
- Semi-dynamic joystick with the same 138px base, 40px throw, 7px dead zone and 72px base shift
- Seven weighted coin tiers worth 10 / 25 / 50 / 100 / 250 / 500 / 1000 points
- Exactly one active coin at a time
- One homing mine per pickup, capped at nine
- Mine arming delay, distance-based speed and sideways weave
- Mine-vs-mine destruction
- 13% whirlpool spawn chance
- Whirlpool influence extending outside the visible whirlpool
- Fatal center and stronger mine attraction
- Boat wake trail
- Current HUD structure
- SUNK / restart screen scaffold
- Procedural ocean, boat, coin, mine and whirlpool rendering so the first build does not depend on external sprite imports
- Android AdMob banner integration, shown during active gameplay in the upper-right banner strip
- Gameplay music toggle removed from the HUD; the music preference remains available in Settings

## Android ads

The Android AdMob plugin is included in `addons/AdmobPlugin` (version 5.1, MIT license). The scene is configured with the game's AdMob app ID and banner unit ID, but `is_real` is `false`, so development builds use Google's test app and banner IDs. The banner is positioned at the top-right and appears only during an active run. The score and coin/mine HUD remain below it, and the playfield begins below the HUD.

Before a release build, select the `Admob` node in `scenes/game.tscn` and enable `is_real` to use the production ad unit. Keep it disabled for development and testing. Do not click live ads while testing.

For Android export, install the Android export templates and SDK in Godot, enable **Gradle Build** in the Android export preset, and include the AdMob plugin. The repository does not include an export preset or a built APK.

## Run

1. Install Godot 4.x from https://godotengine.org/download/windows/
2. Open Godot Project Manager.
3. Import `GodotProject/project.godot`.
4. Press F6/F5 or the Play button.

The Godot project is configured for Godot 4.4 or newer. Android export and AdMob still need to be built and tested on the development machine.
