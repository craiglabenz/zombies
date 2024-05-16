import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/zombie_game.dart';

mixin PathFindingBehavior on Behavior<Zombie> {
  late Vector2 movementToMake;
}

enum ZombieGoalState { wander, chase }

class GoalControllingBehavior extends Behavior<Zombie>
    with HasGameRef<ZombieGame> {
  final double maximumFollowDistance = worldTileSize * 10;

  @override
  void update(double dt) {
    updateState();
    super.update(dt);
  }

  void updateState() {
    final pathToPlayer = Line(parent.position, game.world.player.position);
    if (pathToPlayer.length > maximumFollowDistance) {
      parent.setStateToWandering();
    } else {
      parent.setStateToChasing();
    }
  }
}

enum ZombieMovementState { standing, stepping }

class ChasingBehavior extends Behavior<Zombie> with PathFindingBehavior {
  ChasingBehavior() {
    priority = Priority.pathFinding;
  }

  /// The maximum angle to the left (and/or right) the zombie will veer between.
  static const maxVeerDeg = 45;
  static const minimumVeerDurationMs = 3000;
  static const maximumVeerDurationMs = 6000;
  late Duration veerDuration;
  late DateTime veerStartedAt;
  late bool clockWiseVeerFirst;

  ZombieMovementState movementState = ZombieMovementState.standing;

  static const maximumStandingLurchDurationMs = 900;
  static const minimumStandingLurchDurationMs = 200;

  static const maximumSteppingLurchDurationMs = 1500;
  static const minimumSteppingLurchDurationMs = 300;
  // late Curve lurchCurve;
  late DateTime lurchStartedAt;
  late Duration lurchDuration;

  @override
  void update(double dt) {
    // chase(dt);
    _debugPathfinding();
    super.update(dt);
  }

  @override
  void onLoad() {
    parent.useStandingAnimation(onLoad: true);
    lurchStartedAt = DateTime.now();
    lurchDuration = getStandingLurchDuration();
    setVeer();
    super.onLoad();
  }

  ZombieWorld get world => parent.game.world;

  @override
  Vector2 get movementToMake {
    return movementToMakeRaw.normalized();
  }

  Vector2 get movementToMakeRaw {
    Line pathToTake = Line(parent.position, world.player.position);
    Line? unwalkableTerrainBoundary = getUnwalkableCollision(pathToTake);
    if (unwalkableTerrainBoundary != null) {
      pathToTake = avoidCollision(unwalkableTerrainBoundary);
    }
    pathToTake = applyVeerToPath(pathToTake);
    pathToTake = applyLurch(pathToTake);
    return pathToTake.vector2;
  }

  Line avoidCollision(Line collidingLine) {
    final startToPlayer = Line(collidingLine.start, world.player.position);

    final endToPlayer = Line(collidingLine.end, world.player.position);
    if (startToPlayer.length2 < endToPlayer.length2) {
      return Line(parent.position, collidingLine.start).extend(1.5);
    } else {
      return Line(parent.position, collidingLine.end).extend(1.5);
    }
  }

  /// Checks whether the given Line intersects any [UnwalkableTerrain].
  Line? getUnwalkableCollision(Line pathToPlayer) {
    Vector2? nearestIntersection;
    double? shortestLength;
    Line? unwalkableBoundary;
    for (final line in world.unwalkableComponentEdges) {
      Vector2? intersection = pathToPlayer.intersectsAt(line);
      if (intersection != null) {
        if (nearestIntersection == null) {
          nearestIntersection = intersection;
          shortestLength = Line(parent.position, intersection).length2;
          unwalkableBoundary = line;
        } else {
          final lengthToThisPoint = Line(parent.position, intersection).length2;
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

  void _debugPathfinding() {
    final movementToRender = movementToMakeRaw;
    if (!parent.debug || movementToRender.length2 == 0) {
      if (parent.visualizedPathToPlayer != null) {
        parent.visualizedPathToPlayer!.clean();
        parent.visualizedPathToPlayer = null;
      }
      return;
    }
    final pathToPlayer = Line(
      parent.position,
      parent.position.clone()..add(movementToRender),
    );
    if (parent.visualizedPathToPlayer == null) {
      parent.visualizedPathToPlayer = LineComponent.blue(line: pathToPlayer);
      world.add(parent.visualizedPathToPlayer!);
    } else {
      parent.visualizedPathToPlayer!.line = pathToPlayer;
    }
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

  void setVeer() {
    veerStartedAt = DateTime.now();
    veerDuration = Duration(
      milliseconds:
          Random().nextInt(maximumVeerDurationMs - minimumVeerDurationMs) +
              minimumVeerDurationMs,
    );
    clockWiseVeerFirst = Random().nextBool();
  }

  Line applyLurch(Line pathToTake) {
    if (movementState == ZombieMovementState.standing) {
      if (DateTime.now().difference(lurchStartedAt) > lurchDuration) {
        movementState = ZombieMovementState.stepping;
        parent.useWalkingAnimation();
        lurchStartedAt = DateTime.now();
        lurchDuration = getStepLurchDuration();
      }
      return Line(pathToTake.start, pathToTake.start);
    } else {
      if (DateTime.now().difference(lurchStartedAt) > lurchDuration) {
        parent.useStandingAnimation();

        movementState = ZombieMovementState.standing;
        lurchStartedAt = DateTime.now();
        lurchDuration = getStandingLurchDuration();
      }
      return pathToTake;
    }
  }

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
}

class WanderingBehavior extends Behavior<Zombie> with PathFindingBehavior {
  WanderingBehavior() {
    priority = Priority.pathFinding;
    initializeWanderingState();
  }

  /// Amount of time to follow a given wander path before resetting
  Duration? wanderLength;
  Vector2? wanderPath;
  static const minimumWanderDelta = -3;
  static const maximumWanderDelta = 3;
  int? wanderDeltaDeg;
  DateTime? wanderStartedAt;

  ZombieWorld get world => parent.game.world;

  @override
  Vector2 get movementToMake {
    if (DateTime.now().difference(wanderStartedAt!) > wanderLength!) {
      initializeWanderingState();
    }
    wanderPath = wanderPath!..rotate(wanderDeltaDeg! * degrees2Radians);
    return wanderPath!.normalized();
  }

  void initializeWanderingState() {
    wanderPath = getRandomWanderPath();
    wanderStartedAt = DateTime.now();
    wanderDeltaDeg ??=
        Random().nextInt(maximumWanderDelta - minimumWanderDelta) +
            minimumWanderDelta;
    wanderLength = const Duration(milliseconds: 1500);
  }

  Vector2 getRandomWanderPath() {
    int deg = Random().nextInt(360);
    return Vector2(1, 0)..rotate(deg * degrees2Radians);
  }
}
