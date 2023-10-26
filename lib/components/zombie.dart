import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/animation.dart';
import 'package:zombies/assets.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/zombie_game.dart';

enum ZombieState { wander, chase }

class Zombie extends SpriteComponent
    with HasGameReference<ZombieGame>, UnwalkableTerrainChecker {
  Zombie({
    required super.position,
    this.speed = worldTileSize * 4,
    this.debug = false,
  }) : super(
          size: Vector2.all(64),
          anchor: Anchor.center,
          priority: 1,
        );

  double speed;
  LineComponent? visualizedPathToPlayer;
  bool debug;
  final double maximumFollowDistance = worldTileSize * 10;
  late ZombieState state;

  Random rnd = Random();

  Vector2? wanderPath;

  /// The maximum angle to the left (and/or right) the zombie will veer between.
  static const maxVeerDeg = 45;
  static const minimumVeerDurationMs = 3000;
  static const maximumVeerDurationMs = 6000;
  late Duration veerDuration;
  late DateTime veerStartedAt;
  late bool clockWiseVeerFirst;

  static const minimumLurchDurationMs = 300;
  static const maximumLurchDurationMs = 1500;
  late Duration lurchDuration;
  late DateTime lurchStartedAt;
  late Curve lurchCurve;

  static const minimumWanderDelta = -3;
  static const maximumWanderDelta = 3;
  int? wanderDeltaDeg;
  DateTime? wanderStartedAt;

  /// Amount of time to follow a given wander path before resetting
  Duration? wanderLength;

  final curves = <Curve>[
    Curves.easeIn,
    Curves.easeInBack,
    Curves.easeInOut,
    Curves.easeInOutBack,
  ];

  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache(
      Assets.assets_characters_Zombie_Poses_zombie_cheer1_png,
    ));
    setVeer();
    setLurch();
    setStateToWander();
  }

  void setVeer() {
    veerStartedAt = DateTime.now();
    veerDuration = Duration(
      milliseconds: rnd.nextInt(maximumVeerDurationMs - minimumVeerDurationMs) +
          minimumVeerDurationMs,
    );
    clockWiseVeerFirst = rnd.nextBool();
  }

  void setLurch() {
    lurchStartedAt = DateTime.now();
    lurchDuration = Duration(
      milliseconds:
          rnd.nextInt(maximumLurchDurationMs - minimumLurchDurationMs) +
              minimumLurchDurationMs,
    );
    curves.shuffle();
    lurchCurve = curves.first;
  }

  @override
  void update(double dt) {
    updateState();
    final pathToPlayer = Line(position, game.world.player.position);
    switch (state) {
      case (ZombieState.wander):
        wander(dt);
      case (ZombieState.chase):
        chase(pathToPlayer, dt);
    }
  }

  void updateState() {
    final pathToPlayer = Line(position, game.world.player.position);
    if (pathToPlayer.length > maximumFollowDistance) {
      if (state != ZombieState.wander) {
        setStateToWander();
      }
    } else {
      state = ZombieState.chase;
    }
  }

  void setStateToWander() {
    state = ZombieState.wander;
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
    Line? collision = _getUnwalkableCollision(pathToPlayer);

    if (collision != null) {
      final distanceToStart =
          Line(game.world.player.position, collision.start).length2;
      final distanceToEnd =
          Line(game.world.player.position, collision.end).length2;
      if (distanceToStart < distanceToEnd) {
        pathToPlayer = Line(position, collision.start).extend(1.5);
      } else {
        pathToPlayer = Line(position, collision.end).extend(1.5);
      }
    }

    final movement = pathToPlayer.vector2.normalized();
    applyMovement(movement, applyLurch(dt));
  }

  void applyMovement(Vector2 movement, double dt) {
    final originalPosition = position.clone();
    Vector2 movementThisFrame = movement * speed * dt;

    // Fake update the position so our anchor calculations take into account
    // what movement we want to do this turn.
    position.add(movementThisFrame);

    movementThisFrame = checkMovement(
      movementThisFrame: movementThisFrame,
      originalPosition: originalPosition,
      predicate: isUnwalkableTerrain,
    );
    movementThisFrame = checkMovement(
      movementThisFrame: movementThisFrame,
      originalPosition: originalPosition,
      predicate: isZombie,
      debug: debug,
    );
    position = originalPosition..add(movementThisFrame);
    checkOutOfBounds();
  }

  double applyLurch(double speed) {
    double percentLurched =
        DateTime.now().difference(lurchStartedAt).inMilliseconds /
            lurchDuration.inMilliseconds;
    if (percentLurched > 1.0) {
      setLurch();
      percentLurched = 0;
    }
    percentLurched = Curves.easeIn.transform(percentLurched);
    return percentLurched * speed;
  }

  Line? _getUnwalkableCollision(pathToPlayer) {
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
