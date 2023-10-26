import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/zombie_game.dart';

bool isUnwalkableTerrain(Component component) =>
    component is UnwalkableComponent;

bool isZombie(Component component) => component is Zombie;

mixin UnwalkableTerrainChecker
    on PositionComponent, HasGameReference<ZombieGame> {
  Vector2 checkMovement({
    required Vector2 movementThisFrame,
    required Vector2 originalPosition,
    required bool Function(Component) predicate,
    bool debug = false,
  }) {
    if (movementThisFrame.y < 0) {
      // Moving up
      final newTop = positionOfAnchor(Anchor.topCenter);
      for (final component in game.world.componentsAtPoint(newTop)) {
        if (component != this && predicate(component)) {
          movementThisFrame.y = 0;
          break;
        }
      }
    }
    if (movementThisFrame.y > 0) {
      // Moving down
      final newBottom = positionOfAnchor(Anchor.bottomCenter);
      for (final component in game.world.componentsAtPoint(newBottom)) {
        if (component != this && predicate(component)) {
          movementThisFrame.y = 0;
          break;
        }
      }
    }
    if (movementThisFrame.x < 0) {
      // Moving left
      final newLeft = positionOfAnchor(Anchor.centerLeft);
      for (final component in game.world.componentsAtPoint(newLeft)) {
        if (component != this && predicate(component)) {
          movementThisFrame.x = 0;
          break;
        }
      }
    }
    if (movementThisFrame.x > 0) {
      // Moving right
      final newRight = positionOfAnchor(Anchor.centerRight);
      for (final component in game.world.componentsAtPoint(newRight)) {
        if (component != this && predicate(component)) {
          movementThisFrame.x = 0;
          break;
        }
      }
    }

    // TODO: move to another function because this doesn't need to run for
    // both unwalkable terrain AND zombies
    return movementThisFrame;
  }

  void checkOutOfBounds() {
    final halfSize = size / 2;
    position.clamp(halfSize, game.world.size - halfSize);
  }
}
