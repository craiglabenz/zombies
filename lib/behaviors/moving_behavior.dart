import 'dart:collection';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:logging/logging.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/zombie_game.dart';

final _log = Logger('MovingBehavior');

class MovingBehavior<T extends MovableActor> extends Behavior<T>
    with HasGameRef<ZombieGame> {
  MovingBehavior({required this.unwalkableComponentChecker}) {
    priority = Priority.pathFinding;
  }

  /// Function which evaluates whether this [actor] can share space with the
  /// given [Component].
  final bool Function(Component) unwalkableComponentChecker;

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
  void processCollisions() {
    while (_queuedCollisions.isNotEmpty) {
      final (Component other, Set<Vector2> intersectionPoints) =
          _queuedCollisions.removeFirst();
      if (!unwalkableComponentChecker(other)) {
        return;
      }

      final average = intersectionPoints.average();
      _log.finest('[${parent.runtimeType}] Colliding with $average');
      final lineToCollision = Line(_originalPosition, average);

      final collisionOnTop =
          other.containsPoint(parent.positionOfAnchor(Anchor.topCenter));
      final collisionOnBottom =
          other.containsPoint(parent.positionOfAnchor(Anchor.bottomCenter));
      final collisionOnLeft =
          other.containsPoint(parent.positionOfAnchor(Anchor.centerLeft));
      final collisionOnRight =
          other.containsPoint(parent.positionOfAnchor(Anchor.centerRight));

      if (_cachedMovementThisFrame.isUp && collisionOnTop) {
        _log.fine(
          '[${parent.runtimeType}] Undoing UP portion of movement - '
          'resetting Y to ${_originalPosition.y}',
        );
        parent.position.y = _originalPosition.y;
      }
      if (_cachedMovementThisFrame.isDown && collisionOnBottom) {
        _log.fine(
          '[${parent.runtimeType}] Undoing DOWN portion of movement - '
          'resetting Y to ${_originalPosition.y}',
        );
        parent.position.y = _originalPosition.y;
      }
      if (_cachedMovementThisFrame.isLeft && collisionOnLeft) {
        _log.fine(
          '[${parent.runtimeType}] Undoing LEFT portion of movement - '
          'resetting X to ${_originalPosition.x}',
        );
        parent.position.x = _originalPosition.x;
      }
      if (_cachedMovementThisFrame.isRight && collisionOnRight) {
        _log.fine(
          '[${parent.runtimeType}] Undoing RIGHT portion of movement - '
          'resetting X to ${_originalPosition.x}',
        );
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
