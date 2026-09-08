# Pirate's Plunder — Unity Migration

This folder is the native Unity 2D rebuild of Pirate's Plunder. The existing React Native/Expo application remains in the repository as the reference implementation while gameplay is migrated feature-by-feature.

## Unity version

Unity 6 LTS project scaffold (6000.0.x).

## First-pass systems now in place

- Core game phase and score state (`GameManager`)
- Rigidbody2D boat movement (`BoatController`)
- Coin pickup/scoring (`CoinPickup`)
- Mine/player game-over collision (`Mine`)
- Whirlpool with a pull radius larger than its visual radius and increasingly strong attraction near the center (`Whirlpool`)
- Unity Input System package included for mobile joystick/controller work

## Migration order

1. Recreate the gameplay scene and import existing visual assets.
2. Reproduce the current semi-dynamic mobile joystick.
3. Port coin tiers, spawn timing and scoring rules exactly.
4. Port mine spawning/mine-vs-mine behavior and effects.
5. Match the current whirlpool visuals, spawn behavior and physics.
6. Recreate HUD and score popups.
7. Recreate menu and SUNK/Leaderboard screen.
8. Connect persistent/global leaderboard service.
9. Add background music, then sound effects through one Unity audio manager.
10. Add analytics/ads and configure Android/iOS production builds.

## Important

Do not delete the existing React Native source until the Unity version has reached feature parity and has been tested on both Android and iOS.
