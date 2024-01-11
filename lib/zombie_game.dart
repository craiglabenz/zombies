import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:zombies/assets.dart';

import 'components/components.dart';

class ZombieGame extends FlameGame with HasKeyboardHandlerComponents {
  ZombieGame() : world = ZombieWorld() {
    cameraComponent = CameraComponent(world: world);
    images.prefix = '';
  }

  late final CameraComponent cameraComponent;

  @override
  final ZombieWorld world;

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      Assets.assets_characters_Adventurer_Poses_adventurer_idle_png,
      Assets.assets_characters_Adventurer_Poses_adventurer_walk1_png,
      Assets.assets_characters_Adventurer_Poses_adventurer_walk2_png,
      Assets.assets_characters_Zombie_Poses_zombie_idle_png,
      Assets.assets_characters_Zombie_Poses_zombie_walk1_png,
      Assets.assets_characters_Zombie_Poses_zombie_walk2_png,
      Assets.assets_town_tile_0000_png,
    ]);
    addAll([cameraComponent, world]);
    // debugMode = true;
  }
}
