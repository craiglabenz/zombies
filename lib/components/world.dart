import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:zombies/components/components.dart';

import '../zombie_game.dart';
import '../../constants.dart';

class ZombieWorld extends World with HasGameRef<ZombieGame> {
  ZombieWorld({super.children});

  late Vector2 size = Vector2(
    map.tileMap.map.width * worldTileSize,
    map.tileMap.map.height * worldTileSize,
  );
  final unwalkableComponentEdges = <Line>[];
  late final Player player;
  late final Zombie zombie;

  late TiledComponent map;

  @override
  Future<void> onLoad() async {
    map = await TiledComponent.load(
      'world.tmx',
      Vector2.all(worldTileSize),
    );

    final objectLayer = map.tileMap.getLayer<ObjectGroup>('Objects')!;
    for (final TiledObject object in objectLayer.objects) {
      if (!object.isPolygon) continue;
      if (!object.properties.byName.containsKey('blocksMovement')) return;
      final vertices = <Vector2>[];
      Vector2? lastPoint;
      Vector2? nextPoint;
      Vector2? firstPoint;
      for (final point in object.polygon) {
        nextPoint = Vector2((point.x + object.x) * worldScale,
            (point.y + object.y) * worldScale);
        firstPoint ??= nextPoint;
        vertices.add(nextPoint);

        // If there is a last point, or this is the end of the list, we have a
        // line to add to our cached list of lines
        if (lastPoint != null) {
          unwalkableComponentEdges.add(Line(lastPoint, nextPoint));
        }
        lastPoint = nextPoint;
      }
      unwalkableComponentEdges.add(Line(lastPoint!, firstPoint!));
      add(UnwalkableComponent(vertices));
    }

    zombie = Zombie(
      position: Vector2(worldTileSize * 14.6, worldTileSize * 6.5),
    );
    player = Player();
    addAll([map, player, zombie]);

    // Set up Camera
    gameRef.cameraComponent.follow(player);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    setCameraBounds(size);
  }

  void setCameraBounds(Vector2 gameSize) {
    gameRef.cameraComponent.setBounds(
      Rectangle.fromLTRB(
        gameSize.x / 2,
        gameSize.y / 2,
        size.x - gameSize.x / 2,
        size.y - gameSize.y / 2,
      ),
    );
  }
}

class Line {
  Line(this.start, this.end);
  final Vector2 start;
  final Vector2 end;

  List<double> asList() => [start.x, start.y, end.x, end.y];

  double get slope {
    return end.y - start.y / end.x - start.x;
  }
}
