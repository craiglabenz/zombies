import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/services.dart';
import 'package:zombies/assets.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/zombie_game.dart';

class Player extends SpriteComponent
    with
        KeyboardHandler,
        HasGameReference<ZombieGame>,
        UnwalkableTerrainChecker {
  Player()
      : super(
          position: Vector2(worldTileSize * 9.6, worldTileSize * 2.5),
          size: Vector2.all(64),
          anchor: Anchor.center,
          priority: 1,
        ) {
    halfSize = size / 2;
  }

  late Vector2 halfSize;
  late Vector2 maxPosition = game.world.size - halfSize;
  Vector2 movement = Vector2.zero();
  double speed = worldTileSize * 4;

  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache(
      Assets.assets_characters_Adventurer_Poses_adventurer_action1_png,
    ));
  }

  @override
  void update(double dt) {
    // Save this to use after we zero out movement for unwalkable terrain.
    final originalPosition = position.clone();

    final movementThisFrame = movement * speed * dt;

    // Fake update the position so our anchor calculations take into account
    // what movement we want to do this turn.
    position.add(movementThisFrame);

    checkMovement(
      movementThisFrame: movementThisFrame,
      originalPosition: originalPosition,
    );
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        movement = Vector2(movement.x, -1);
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        movement = Vector2(movement.x, 1);
      }
      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        movement = Vector2(-1, movement.y);
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        movement = Vector2(1, movement.y);
      }
      return false;
    } else if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        movement.y = keysPressed.contains(LogicalKeyboardKey.keyS) ? 1 : 0;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        movement.y = keysPressed.contains(LogicalKeyboardKey.keyW) ? -1 : 0;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        movement.x = keysPressed.contains(LogicalKeyboardKey.keyD) ? 1 : 0;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        movement.x = keysPressed.contains(LogicalKeyboardKey.keyA) ? -1 : 0;
      }
      return false;
    }
    return true;
  }
}
