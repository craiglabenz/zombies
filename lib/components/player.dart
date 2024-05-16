import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:zombies/assets.dart';
import 'package:zombies/behaviors/behaviors.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/zombie_game.dart';

class Player extends MovableActor
    with
        KeyboardHandler,
        HasGameReference<ZombieGame>,
        UnwalkableTerrainChecker {
  Player({super.speed = worldTileSize * 4})
      : super(
          anchor: Anchor.center,
          behaviors: [
            MovingBehavior(
              unwalkableComponentChecker: (Component other) =>
                  other is UnwalkableComponent,
            ),
          ],
          children: [
            RectangleHitbox.relative(Vector2(0.9, 0.9),
                parentSize: Vector2.all(64))
          ],
          position: Vector2(worldTileSize * 9.6, worldTileSize * 2.5),
          priority: RenderingPriority.player,
          size: Vector2.all(64),
        ) {
    halfSize = size / 2;
  }

  late Vector2 halfSize;
  late Vector2 maxPosition = game.world.size - halfSize;
  late SpriteAnimationComponent walkingAnimation;
  late SpriteComponent idleComponent;

  @override
  Future<void> onLoad() async {
    final idleSprite = Sprite(game.images.fromCache(
      Assets.assets_characters_Adventurer_Poses_adventurer_idle_png,
    ));
    idleComponent = SpriteComponent(
      sprite: idleSprite,
      size: Vector2.all(64.0),
    );

    final animation = SpriteAnimation.spriteList(
      [
        Sprite(
          game.images.fromCache(
            Assets.assets_characters_Adventurer_Poses_adventurer_walk1_png,
          ),
        ),
        Sprite(
          game.images.fromCache(
            Assets.assets_characters_Adventurer_Poses_adventurer_walk2_png,
          ),
        ),
      ],
      stepTime: 0.15,
    );
    walkingAnimation = SpriteAnimationComponent(
      animation: animation,
      size: Vector2.all(64.0),
    );
    add(idleComponent);
  }

  @override
  void update(double dt) {
    if (movementToMake.length2 == 0) {
      if (children.contains(walkingAnimation)) {
        remove(walkingAnimation);
      }
      if (!children.contains(idleComponent)) {
        add(idleComponent);
      }
    } else {
      if (!children.contains(walkingAnimation)) {
        add(walkingAnimation);
      }
      if (children.contains(idleComponent)) {
        remove(idleComponent);
      }
    }
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        game.world.isPaused = false;
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.space) {
        game.world.isPausing = !game.world.isPausing;
        game.world.isPaused = game.world.isPausing;
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        movementToMake = Vector2(movementToMake.x, -1);
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        movementToMake = Vector2(movementToMake.x, 1);
      }
      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        movementToMake = Vector2(-1, movementToMake.y);
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        movementToMake = Vector2(1, movementToMake.y);
      }
      return false;
    } else if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        movementToMake.y =
            keysPressed.contains(LogicalKeyboardKey.keyS) ? 1 : 0;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        movementToMake.y =
            keysPressed.contains(LogicalKeyboardKey.keyW) ? -1 : 0;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        movementToMake.x =
            keysPressed.contains(LogicalKeyboardKey.keyD) ? 1 : 0;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        movementToMake.x =
            keysPressed.contains(LogicalKeyboardKey.keyA) ? -1 : 0;
      }
      return false;
    }
    return true;
  }

  void castFireball(Vector2 target) {
    game.world.add(
      Fireball(
        origin: position,
        target: target,
      ),
    );
  }
}
