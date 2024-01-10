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

class ChasingBehavior extends Behavior<Zombie>
    with HasGameRef<ZombieGame>, PathFindingBehavior {
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
    chase(dt);
    super.update(dt);
  }

  @override
  void onLoad() {
    lurchStartedAt = DateTime.now();
    lurchDuration = getStandingLurchDuration();
    setVeer();
    super.onLoad();
  }

  void chase(double dt) {
    final pathToPlayer = Line(parent.position, game.world.player.position);
    final pathToTake = applyVeerToPath(pathToPlayer);
    movementToMake = applyLurch(pathToTake.vector2);
    print('movementToMake: $movementToMake');
    parent.applyMovement(movementToMake * dt);
    // _debugPathfinding(pathToTake);
    // moveAlongPath(pathToTake, dt);
  }

  // void _debugPathfinding(Line pathToPlayer) {
  //   if (!debug) return;
  //   if (visualizedPathToPlayer == null) {
  //     visualizedPathToPlayer = LineComponent.blue(line: pathToPlayer);
  //     game.world.add(visualizedPathToPlayer!);
  //   } else {
  //     visualizedPathToPlayer!.line = pathToPlayer;
  //   }
  // }

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

  Vector2 applyLurch(Vector2 movement) {
    if (movementState == ZombieMovementState.standing) {
      if (DateTime.now().difference(lurchStartedAt) > lurchDuration) {
        movementState = ZombieMovementState.stepping;
        parent.useWalkingAnimation();
        lurchStartedAt = DateTime.now();
        lurchDuration = getStepLurchDuration();
      }
      return Vector2.zero();
    } else {
      if (DateTime.now().difference(lurchStartedAt) > lurchDuration) {
        parent.useStandingAnimation();

        movementState = ZombieMovementState.standing;
        lurchStartedAt = DateTime.now();
        lurchDuration = getStandingLurchDuration();
      }
      return movement;
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

class WanderingBehavior extends Behavior<Zombie>
    with HasGameRef<ZombieGame>, PathFindingBehavior {
  /// Amount of time to follow a given wander path before resetting
  Duration? wanderLength;
  Vector2? wanderPath;
  static const minimumWanderDelta = -3;
  static const maximumWanderDelta = 3;
  int? wanderDeltaDeg;
  DateTime? wanderStartedAt;

  @override
  void update(double dt) {
    wander(dt);
    super.update(dt);
  }

  @override
  void onMount() {
    initializeWanderingState();
    super.onMount();
  }

  void wander(double dt) {
    if (DateTime.now().difference(wanderStartedAt!) > wanderLength!) {
      initializeWanderingState();
    }
    wanderPath = wanderPath!..rotate(wanderDeltaDeg! * degrees2Radians);
    movementToMake = wanderPath!.normalized();
    // applyMovement(wanderPath!, applyLurch(dt / 2));
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
