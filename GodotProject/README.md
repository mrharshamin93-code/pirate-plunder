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

## Run

1. Install Godot 4.x from https://godotengine.org/download/windows/
2. Open Godot Project Manager.
3. Import `GodotProject/project.godot`.
4. Press F6/F5 or the Play button.

The first goal is gameplay parity. Once the core feel is approved, the current polished artwork, leaderboard UI, audio, haptics, Android export and ads can be wired in.
