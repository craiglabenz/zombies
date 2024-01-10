import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:zombies/assets.dart';
import 'package:zombies/behaviors/behaviors.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/zombie_game.dart';

class Zombie extends PositionedEntity
    with
        HasGameReference<ZombieGame>,
        UnwalkableTerrainChecker,
        CollisionCallbacks {
  Zombie({
    required super.position,
    this.speed = worldTileSize * 2,
    this.debug = false,
  }) : super(
          size: Vector2.all(64),
          anchor: Anchor.center,
          priority: 1,
          children: [CircleHitbox()],
          behaviors: [GoalControllingBehavior()],
        );

  late ZombieGoalState goalState;

  double speed;
  LineComponent? visualizedPathToPlayer;
  bool debug;

  Random rnd = Random();

  late SpriteAnimationComponent walkingAnimation;
  late SpriteComponent idleComponent;

  static const defaultWalkingStepTime = 0.3;

  void useWalkingAnimation() {
    remove(idleComponent);
    add(walkingAnimation);
  }

  void useStandingAnimation() {
    remove(walkingAnimation);
    add(idleComponent);
  }

  @override
  void onLoad() {
    final idleSprite = Sprite(game.images.fromCache(
      Assets.assets_characters_Zombie_Poses_zombie_idle_png,
    ));
    idleComponent = SpriteComponent(
      sprite: idleSprite,
      size: Vector2.all(64.0),
    );

    final animation = SpriteAnimation.spriteList(
      [
        Sprite(
          game.images.fromCache(
            Assets.assets_characters_Zombie_Poses_zombie_walk1_png,
          ),
        ),
        Sprite(
          game.images.fromCache(
            Assets.assets_characters_Zombie_Poses_zombie_walk2_png,
          ),
        ),
      ],
      stepTime: defaultWalkingStepTime,
    );
    walkingAnimation = SpriteAnimationComponent(
      animation: animation,
      size: Vector2.all(64.0),
    );
    add(idleComponent);
  }

  void setStateToWandering() {
    if (hasBehavior<ChasingBehavior>()) {
      remove(findBehavior<ChasingBehavior>());
    }
    if (!hasBehavior<WanderingBehavior>()) {
      add(WanderingBehavior());
    }
  }

  void setStateToChasing() {
    if (hasBehavior<WanderingBehavior>()) {
      remove(findBehavior<WanderingBehavior>());
    }
    if (!hasBehavior<ChasingBehavior>()) {
      add(ChasingBehavior());
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    cleanUpMovement(
      collidingComponent: other,
      intersectionPoints: intersectionPoints,
      predicate: isZombie,
    );
    cleanUpMovement(
      collidingComponent: other,
      intersectionPoints: intersectionPoints,
      predicate: isUnwalkableTerrain,
    );
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void update(double dt) {
    lastPosition.setFrom(position);

    // final goalState = findBehavior<GoalControllingBehavior>().goalState;
    // switch (goalState) {
    //   case (ZombieGoalState.wander):
    //     wander(dt);
    //   case (ZombieGoalState.chase):
    //     chase(pathToPlayer, dt);
    // }
    cachedMovementThisFrame
      ..setFrom(position)
      ..sub(lastPosition);
  }

  // void moveAlongPath(Line pathToPlayer, double dt) {
  //   // Line? collision = _getUnwalkableCollision(pathToPlayer);

  //   // if (collision != null) {
  //   //   final distanceToStart =
  //   //       Line(game.world.player.position, collision.start).length2;
  //   //   final distanceToEnd =
  //   //       Line(game.world.player.position, collision.end).length2;
  //   //   if (distanceToStart < distanceToEnd) {
  //   //     pathToPlayer = Line(position, collision.start).extend(1.5);
  //   //   } else {
  //   //     pathToPlayer = Line(position, collision.end).extend(1.5);
  //   //   }
  //   // }

  //   final movement = pathToPlayer.vector2.normalized();
  //   applyMovement(applyLurch(movement));
  // }

  void applyMovement(Vector2 movement) {
    final originalPosition = position.clone();
    Vector2 movementThisFrame = movement * speed;

    // Fake update the position so our anchor calculations take into account
    // what movement we want to do this turn.
    position.add(movementThisFrame);

    // movementThisFrame = checkMovement(
    //   movementThisFrame: movementThisFrame,
    //   predicate: isUnwalkableTerrain,
    // );
    // movementThisFrame = checkMovement(
    //   movementThisFrame: movementThisFrame,
    //   predicate: isZombie,
    //   debug: debug,
    // );
    position = originalPosition..add(movementThisFrame);
    checkOutOfBounds();
  }

  Line? _getUnwalkableCollision(Line pathToPlayer) {
    Vector2? nearestIntersection;
    double? shortestLength;
    Line? unwalkableBoundary;
    for (final line in game.world.unwalkableComponentEdges) {
      Vector2? intersection = pathToPlayer.intersectsAt(line);
      if (intersection != null) {
        if (nearestIntersection == null) {
          nearestIntersection = intersection;
          shortestLength = Line(position, intersection).length2;
          unwalkableBoundary = line;
        } else {
          final lengthToThisPoint = Line(position, intersection).length2;
          if (lengthToThisPoint < shortestLength!) {
            shortestLength = lengthToThisPoint;
            nearestIntersection = intersection;
            unwalkableBoundary = line;
          }
        }
      }
    }
    return unwalkableBoundary;
  }
}
