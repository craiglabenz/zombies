import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:zombies/assets.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/zombie_game.dart';

class Zombie extends SpriteComponent
    with HasGameReference<ZombieGame>, UnwalkableTerrainChecker {
  Zombie({required super.position, this.speed = worldTileSize * 2})
      : super(
          size: Vector2.all(64),
          anchor: Anchor.center,
          priority: 1,
        );

  double speed;
  LineComponent? visualizedPathToPlayer;

  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache(
      Assets.assets_characters_Zombie_Poses_zombie_cheer1_png,
    ));
  }

  @override
  void update(double dt) {
    final pathToPlayer = Line(position, game.world.player.position);
    _debugPathfinding(pathToPlayer);
    moveAlongPath(pathToPlayer, dt);
  }

  void moveAlongPath(Line pathToPlayer, double dt) {
    final originalPosition = position.clone();

    Line? collision = _getUnwalkableCollision(pathToPlayer);

    if (collision != null) {
      final distanceToStart =
          Line(game.world.player.position, collision.start).length2;
      final distanceToEnd =
          Line(game.world.player.position, collision.end).length2;
      if (distanceToStart < distanceToEnd) {
        pathToPlayer = Line(position, collision.start).extend(1.1);
      } else {
        pathToPlayer = Line(position, collision.end).extend(1.1);
      }
    }

    final movement = pathToPlayer.vector2.normalized();
    final movementThisFrame = movement * speed * dt;
    position.add(movementThisFrame);
    checkMovement(
      movementThisFrame: movementThisFrame,
      originalPosition: originalPosition,
    );
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
    if (visualizedPathToPlayer == null) {
      visualizedPathToPlayer = LineComponent.blue(line: pathToPlayer);
      game.world.add(visualizedPathToPlayer!);
    } else {
      visualizedPathToPlayer!.line = pathToPlayer;
    }
  }
}
