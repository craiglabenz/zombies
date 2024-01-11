import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:zombies/components/components.dart';

class DyingBehavior extends Behavior<Zombie> {
  void takeDamage(Fireball fireball) {
    parent.health -= 50;
    if (parent.health <= 0) {
      parent.clean();
    }
    fireball.clean();
  }
}
