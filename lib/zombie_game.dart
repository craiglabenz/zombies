import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:zombies/assets.dart';

import 'components/components.dart';

class ZombieGame extends FlameGame with HasKeyboardHandlerComponents {
  ZombieGame() : _world = ZombieWorld() {
    cameraComponent = CameraComponent(world: _world);
    images.prefix = '';
  }

  late final CameraComponent cameraComponent;
  final ZombieWorld _world;

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      Assets.assets_characters_Adventurer_Poses_adventurer_action1_png,
      Assets.assets_town_tile_0000_png,
    ]);
    cameraComponent.viewfinder.anchor = Anchor.center;
    add(cameraComponent);
    add(_world);
    cameraComponent.follow(_world.player);
  }
}
