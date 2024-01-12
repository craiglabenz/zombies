import 'dart:collection';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/zombie_game.dart';

abstract class BaseMovingBehavior<T extends MovableActor> extends Behavior<T>
    with HasGameRef<ZombieGame> {
  BaseMovingBehavior() {
    priority = Priority.pathFinding;
  }

  final Queue<(Component, Set<Vector2>)> _queuedCollisions = Queue();

// Caching helper for `undoCollisions`
  final Vector2 _cachedMovementThisFrame = Vector2.zero();

  /// Caching helper for `undoCollisions`.
  final Vector2 _originalPosition = Vector2.zero();

  @override
  void update(double dt) {
    applyMovement(dt);
    checkOutOfBounds();
    processCollisions();
    super.update(dt);
  }

  void applyMovement(double dt) {
    _originalPosition.setFrom(parent.position);
    parent.position.add(parent.movementToMake * parent.speed * dt);
    _cachedMovementThisFrame
      ..setFrom(parent.position)
      ..sub(_originalPosition);
  }

  void checkOutOfBounds() {
    final halfSize = parent.size / 2;
    parent.position.clamp(halfSize, game.world.size - halfSize);
  }

  /// [MovableActor] instances should register any collisions from
  /// Flame with this method, so they can be processed after movement
  /// and thus influence movement.
  void queueCollision({
    required Component other,
    required Set<Vector2> intersectionPoints,
  }) {
    _queuedCollisions.add((other, intersectionPoints));
  }

  /// Handles any collisions registered via [queueCollisions].
  void processCollisions();
}

class ZombieMovingBehavior extends BaseMovingBehavior<Zombie> {
  ZombieMovingBehavior() {
    priority = Priority.pathFinding;
  }

  @override
  void processCollisions() {
    while (_queuedCollisions.isNotEmpty) {
      final (Component other, Set<Vector2> intersectionPoints) =
          _queuedCollisions.removeFirst();
      if (other is! Zombie && other is! UnwalkableComponent) {
        return;
      }
      final lineToCollision = Line(
        _originalPosition,
        intersectionPoints.average(),
      );

      if (lineToCollision.isUp && _cachedMovementThisFrame.isUp) {
        parent.position.y = _originalPosition.y;
      }
      if (lineToCollision.isDown && _cachedMovementThisFrame.isDown) {
        parent.position.y = _originalPosition.y;
      }
      if (lineToCollision.isLeft && _cachedMovementThisFrame.isLeft) {
        parent.position.x = _originalPosition.x;
      }
      if (lineToCollision.isRight && _cachedMovementThisFrame.isRight) {
        parent.position.x = _originalPosition.x;
      }
    }
  }
}

extension on Set<Vector2> {
  Vector2 average() {
    Vector2 sum = Vector2.zero();
    forEach(sum.add);
    return Vector2(sum.x / length, sum.y / length);
  }
}
