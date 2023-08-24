import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/services.dart';
import 'package:zombies/assets.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/zombie_game.dart';

class Player extends SpriteComponent
    with KeyboardHandler, HasGameReference<ZombieGame> {
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

    if (movement.y < 0) {
      // Moving up
      final newTop = positionOfAnchor(Anchor.topCenter);
      for (final component in game.world.componentsAtPoint(newTop)) {
        if (component is UnwalkableComponent) {
          movementThisFrame.y = 0;
          break;
        }
      }
    }
    if (movement.y > 0) {
      // Moving down
      final newBottom = positionOfAnchor(Anchor.bottomCenter);
      for (final component in game.world.componentsAtPoint(newBottom)) {
        if (component is UnwalkableComponent) {
          movementThisFrame.y = 0;
          break;
        }
      }
    }
    if (movement.x < 0) {
      // Moving left
      final newLeft = positionOfAnchor(Anchor.centerLeft);
      for (final component in game.world.componentsAtPoint(newLeft)) {
        if (component is UnwalkableComponent) {
          movementThisFrame.x = 0;
          break;
        }
      }
    }
    if (movement.x > 0) {
      // Moving right
      final newRight = positionOfAnchor(Anchor.centerRight);
      for (final component in game.world.componentsAtPoint(newRight)) {
        if (component is UnwalkableComponent) {
          movementThisFrame.x = 0;
          break;
        }
      }
    }

    position = originalPosition + movementThisFrame;
    position.clamp(halfSize, maxPosition);
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
