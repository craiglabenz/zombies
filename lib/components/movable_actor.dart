import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

/// Parent class of game actors that move, like [Player] and [Zombie] instances.
abstract class MovableActor extends PositionedEntity {
  MovableActor({
    required super.position,
    required this.speed,
    super.anchor,
    super.children,
    super.behaviors,
    super.priority,
    super.size,
  });

  double speed;

  /// The actor's desired movement this frame. This vector should not
  /// incorporate the actor's speed or the frame's `dt`.
  Vector2 get movementToMake;
}
