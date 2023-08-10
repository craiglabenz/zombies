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
  final List<Land> land = [];
  late final Player player;

  late TiledComponent map;

  @override
  Future<void> onLoad() async {
    map = await TiledComponent.load(
      'world.tmx',
      Vector2.all(worldTileSize),
    );
    player = Player();
    addAll([map, player]);

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
