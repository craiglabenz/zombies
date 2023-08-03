import 'package:flame/components.dart';
import 'package:zombies/components/components.dart';

import '../assets.dart';
import '../zombie_game.dart';

class ZombieWorld extends World with HasGameRef<ZombieGame> {
  ZombieWorld({super.children});

  final List<Land> land = [];
  late final Player player;

  static Vector2 size = Vector2.all(100);

  @override
  Future<void> onLoad() async {
    final greenLandImage = game.images.fromCache(
      Assets.assets_town_tile_0000_png,
    );
    land.add(
      Land(position: Vector2.all(0), sprite: Sprite(greenLandImage)),
    );
    add(land.last);

    final playerImage = game.images.fromCache(
      Assets.assets_characters_Adventurer_Poses_adventurer_action1_png,
    );
    player = Player(position: Vector2.all(20), sprite: Sprite(playerImage));
    add(player);
  }
}
