import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';

class ZombieMovingBehavior extends Behavior<Zombie> {
  ZombieMovingBehavior() {
    priority = Priority.pathFinding;
  }
  ZombieWorld get world => parent.game.world;

  // Caching helper for `undoCollisions`
  final Vector2 _cachedMovementThisFrame = Vector2.zero();

  /// Caching helper for `undoCollisions`.
  final Vector2 _pathToCollision = Vector2.zero();

  /// Caching helper for `undoCollisions`.
  final Vector2 _originalPosition = Vector2.zero();

  @override
  void update(double dt) {
    applyMovement(dt);
    checkOutOfBounds();
    super.update(dt);
  }

  void applyMovement(double dt) {
    _originalPosition.setFrom(parent.position);
    parent.position.add(parent.pathFinding.movementToMake * parent.speed * dt);
    _cachedMovementThisFrame
      ..setFrom(parent.position)
      ..sub(_originalPosition);
  }

  void checkOutOfBounds() {
    final halfSize = parent.size / 2;
    parent.position.clamp(halfSize, world.size - halfSize);
  }

  void undoCollisions({
    required Component other,
    required Set<Vector2> intersectionPoints,
  }) {
    if (other is! Zombie && other is! UnwalkableComponent) {
      return;
    }
    final Vector2 avg = intersectionPoints.average();
    _pathToCollision.x = avg.x - parent.position.x;
    _pathToCollision.y = avg.y - parent.position.y;

    final lineToCollision = Line(parent.position, avg);
    // print('vector to collision: ${lineToCollision.vector2}');
    final directionToCollision = lineToCollision.angleDeg.angleDirection;
    // print('angle to collision: ${lineToCollision.angleDeg}');
    // print('direction to collision: $directionToCollision');
    // print('_cachedMovementThisFrame: $_cachedMovementThisFrame');

    // print('position pre  movement: $_originalPosition');
    // print('position pre  adjustment: ${parent.position}');

    switch (directionToCollision) {
      case (Direction.up):
        {
          if (_cachedMovementThisFrame.y < 0) {
            if (other.containsPoint(parent.positionOfAnchor(Anchor.topLeft))) {
              // print('zeroing out Y from UP LEFT movement');
              parent.position.y = _originalPosition.y;
            } else if (other
                .containsPoint(parent.positionOfAnchor(Anchor.topRight))) {
              // print('zeroing out Y from UP RIGHT movement');
              parent.position.y = _originalPosition.y;
            } else if (other
                .containsPoint(parent.positionOfAnchor(Anchor.topCenter))) {
              // print('zeroing out Y from UP CENTER movement');
              parent.position.y = _originalPosition.y;
            }
          }
        }
      case (Direction.down):
        {
          if (_cachedMovementThisFrame.y > 0) {
            if (other
                .containsPoint(parent.positionOfAnchor(Anchor.bottomLeft))) {
              // print('zeroing out Y from DOWN LEFT movement');
              parent.position.y = _originalPosition.y;
            } else if (other
                .containsPoint(parent.positionOfAnchor(Anchor.bottomRight))) {
              // print('zeroing out Y from DOWN RIGHT movement');
              parent.position.y = _originalPosition.y;
            } else if (other
                .containsPoint(parent.positionOfAnchor(Anchor.bottomCenter))) {
              // print('zeroing out Y from DOWN CENTER movement');
              parent.position.y = _originalPosition.y;
            }
          }
        }
      case (Direction.left):
        {
          if (_cachedMovementThisFrame.x < 0) {
            if (other.containsPoint(parent.positionOfAnchor(Anchor.topLeft))) {
              // print('zeroing out X from TOP LEFT movement');
              parent.position.x = _originalPosition.x;
            } else if (other
                .containsPoint(parent.positionOfAnchor(Anchor.bottomLeft))) {
              // print('zeroing out X from BOTTOM LEFT movement');
              parent.position.x = _originalPosition.x;
            } else if (other
                .containsPoint(parent.positionOfAnchor(Anchor.centerLeft))) {
              // print('zeroing out X from CENTER LEFT movement');
              parent.position.x = _originalPosition.x;
            }
          }
        }
      case (Direction.right):
        {
          if (_cachedMovementThisFrame.x > 0) {
            if (other.containsPoint(parent.positionOfAnchor(Anchor.topRight))) {
              // print('zeroing out X from TOP RIGHT movement');
              parent.position.x = _originalPosition.x;
            } else if (other
                .containsPoint(parent.positionOfAnchor(Anchor.bottomRight))) {
              // print('zeroing out X from BOTTOM RIGHT movement');
              parent.position.x = _originalPosition.x;
            } else if (other
                .containsPoint(parent.positionOfAnchor(Anchor.centerRight))) {
              // print('zeroing out X from CENTER RIGHT movement');
              parent.position.x = _originalPosition.x;
            }
          }
        }
    }
    // print('position POST adjustment: ${parent.position}');
  }
}

extension on Set<Vector2> {
  Vector2 average() {
    Vector2 sum = Vector2.zero();
    forEach(sum.add);
    return Vector2(sum.x / length, sum.y / length);
  }
}
