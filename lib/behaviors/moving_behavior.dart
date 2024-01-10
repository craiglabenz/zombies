import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:zombies/components/zombie.dart';
import 'package:zombies/zombie_game.dart';

class MovingBehavior extends Behavior<Zombie> with HasGameRef<ZombieGame> {}
