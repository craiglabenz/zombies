import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/animation.dart';
import 'package:zombies/assets.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/zombie_game.dart';

enum ZombieGoalState { wander, chase }

enum ZombieMovementState { standing, stepping }

class Zombie extends PositionComponent
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
        );

  double speed;
  LineComponent? visualizedPathToPlayer;
  bool debug;
  final double maximumFollowDistance = worldTileSize * 10;
  late ZombieGoalState goalState;
  ZombieMovementState movementState = ZombieMovementState.standing;

  Random rnd = Random();

  Vector2? wanderPath;

  /// The maximum angle to the left (and/or right) the zombie will veer between.
  static const maxVeerDeg = 45;
  static const minimumVeerDurationMs = 3000;
  static const maximumVeerDurationMs = 6000;
  late Duration veerDuration;
  late DateTime veerStartedAt;
  late bool clockWiseVeerFirst;

  static const maximumStandingLurchDurationMs = 900;
  static const minimumStandingLurchDurationMs = 200;

  static const maximumSteppingLurchDurationMs = 1500;
  static const minimumSteppingLurchDurationMs = 300;
  // late Curve lurchCurve;
  late DateTime lurchStartedAt;
  late Duration lurchDuration;

  static const minimumWanderDelta = -3;
  static const maximumWanderDelta = 3;
  int? wanderDeltaDeg;
  DateTime? wanderStartedAt;

  late SpriteAnimationComponent walkingAnimation;
  late SpriteComponent idleComponent;

  /// Amount of time to follow a given wander path before resetting
  Duration? wanderLength;

  static const defaultWalkingStepTime = 0.3;

  Duration getStandingLurchDuration() => Duration(
        milliseconds: Random().nextInt(maximumStandingLurchDurationMs -
                minimumStandingLurchDurationMs) +
            minimumStandingLurchDurationMs,
      );

  Duration getStepLurchDuration() => Duration(
        milliseconds: Random().nextInt(maximumSteppingLurchDurationMs -
                minimumSteppingLurchDurationMs) +
            minimumSteppingLurchDurationMs,
      );

  @override
  void onLoad() {
    lurchStartedAt = DateTime.now();
    lurchDuration = getStandingLurchDuration();
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
    setVeer();
    setStateToWander();
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

  void setVeer() {
    veerStartedAt = DateTime.now();
    veerDuration = Duration(
      milliseconds: rnd.nextInt(maximumVeerDurationMs - minimumVeerDurationMs) +
          minimumVeerDurationMs,
    );
    clockWiseVeerFirst = rnd.nextBool();
  }

  @override
  void update(double dt) {
    lastPosition.setFrom(position);
    updateState();
    final pathToPlayer = Line(position, game.world.player.position);
    switch (goalState) {
      case (ZombieGoalState.wander):
        wander(dt);
      case (ZombieGoalState.chase):
        chase(pathToPlayer, dt);
    }
    cachedMovementThisFrame
      ..setFrom(position)
      ..sub(lastPosition);
  }

  void updateState() {
    final pathToPlayer = Line(position, game.world.player.position);
    if (pathToPlayer.length > maximumFollowDistance) {
      if (goalState != ZombieGoalState.wander) {
        setStateToWander();
      }
    } else {
      goalState = ZombieGoalState.chase;
    }
  }

  void setStateToWander() {
    goalState = ZombieGoalState.wander;
    wanderPath = getRandomWanderPath();
    wanderStartedAt = DateTime.now();
    wanderDeltaDeg ??= rnd.nextInt(maximumWanderDelta - minimumWanderDelta) +
        minimumWanderDelta;
    wanderLength = const Duration(milliseconds: 1500);
  }

  void wander(double dt) {
    if (DateTime.now().difference(wanderStartedAt!) > wanderLength!) {
      setStateToWander();
    }
    wanderPath = wanderPath!..rotate(wanderDeltaDeg! * degrees2Radians);
    applyMovement(wanderPath!, applyLurch(dt / 2));
  }

  Vector2 getRandomWanderPath() {
    int deg = rnd.nextInt(360);
    return Vector2(1, 0)..rotate(deg * degrees2Radians);
  }

  void chase(Line pathToPlayer, double dt) {
    wanderPath = null;
    wanderDeltaDeg = null;
    final pathToTake = applyVeerToPath(pathToPlayer);
    _debugPathfinding(pathToTake);
    moveAlongPath(pathToTake, dt);
  }

  Line applyVeerToPath(Line path) {
    // Percentage into the total veer we currently are
    double percentVeered =
        DateTime.now().difference(veerStartedAt).inMilliseconds /
            veerDuration.inMilliseconds;

    if (percentVeered > 1.0) {
      setVeer();
      percentVeered = 0;
    }

    late double veerAngleDeg;
    if (percentVeered < 0.25) {
      veerAngleDeg = maxVeerDeg * percentVeered * 4;
    } else if (percentVeered < 0.5) {
      veerAngleDeg = (0.5 - percentVeered) * 4 * maxVeerDeg;
    } else if (percentVeered < 0.75) {
      veerAngleDeg = -(maxVeerDeg * (percentVeered - 0.5) * 4);
    } else {
      veerAngleDeg = -(1 - percentVeered) * 4 * maxVeerDeg;
    }
    if (!clockWiseVeerFirst) {
      veerAngleDeg = veerAngleDeg * -1;
    }

    final rotated = path.vector2..rotate(veerAngleDeg * degrees2Radians);
    return Line(
      path.start,
      path.start + rotated,
    );
  }

  void moveAlongPath(Line pathToPlayer, double dt) {
    // Line? collision = _getUnwalkableCollision(pathToPlayer);

    // if (collision != null) {
    //   final distanceToStart =
    //       Line(game.world.player.position, collision.start).length2;
    //   final distanceToEnd =
    //       Line(game.world.player.position, collision.end).length2;
    //   if (distanceToStart < distanceToEnd) {
    //     pathToPlayer = Line(position, collision.start).extend(1.5);
    //   } else {
    //     pathToPlayer = Line(position, collision.end).extend(1.5);
    //   }
    // }

    final movement = pathToPlayer.vector2.normalized();
    applyMovement(movement, applyLurch(dt));
  }

  void applyMovement(Vector2 movement, double dt) {
    final originalPosition = position.clone();
    Vector2 movementThisFrame = movement * speed * dt;

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

  double applyLurch(double speed) {
    if (movementState == ZombieMovementState.standing) {
      if (DateTime.now().difference(lurchStartedAt) > lurchDuration) {
        movementState = ZombieMovementState.stepping;
        remove(idleComponent);
        add(walkingAnimation);
        lurchStartedAt = DateTime.now();
        lurchDuration = getStepLurchDuration();
      }
      return 0;
    } else {
      if (DateTime.now().difference(lurchStartedAt) > lurchDuration) {
        remove(walkingAnimation);
        add(idleComponent);
        movementState = ZombieMovementState.standing;
        lurchStartedAt = DateTime.now();
        lurchDuration = getStandingLurchDuration();
      }
      return speed;
    }
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

  void _debugPathfinding(Line pathToPlayer) {
    if (!debug) return;
    if (visualizedPathToPlayer == null) {
      visualizedPathToPlayer = LineComponent.blue(line: pathToPlayer);
      game.world.add(visualizedPathToPlayer!);
    } else {
      visualizedPathToPlayer!.line = pathToPlayer;
    }
  }
}
