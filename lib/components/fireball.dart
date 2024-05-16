import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:zombies/assets.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/zombie_game.dart';

class Fireball extends PositionedEntity with HasGameRef<ZombieGame> {
  Fireball({
    required this.origin,
    required this.target,
  })  : path = Line(origin, target),
        super(
          children: [RectangleHitbox()],
          position: origin,
          priority: RenderingPriority.effect,
          size: Vector2.all(32.0),
        );

  final double speed = 3.0;

  /// Combined [origin] and [target].
  final Line path;

  /// From whence the fireball originated.
  final Vector2 origin;

  /// Where the user clicked and thus where the fireball is heading.
  /// This variable represents global coordinates and not on-screen coordinates.
  Vector2 target;

  late FireballSpriteComponent spriteComponent;

  @override
  void onLoad() {
    final sprite = Sprite(game.images.fromCache(
      Assets.assets_Fireball1_png,
    ));
    spriteComponent = FireballSpriteComponent(
      anchor: Anchor.center,
      angle: path.angle,
      position: Vector2.zero(),
      priority: RenderingPriority.effect,
      size: size,
      sprite: sprite,
    );

    add(spriteComponent);
  }

  @override
  void update(double dt) {
    position.add(path.vector2 * speed * dt);
  }

  void clean() {
    remove(spriteComponent);
    game.world.remove(this);
  }
}

class FireballSpriteComponent extends SpriteComponent {
  FireballSpriteComponent({
    required super.angle,
    required super.anchor,
    super.children,
    required super.position,
    required super.priority,
    required super.sprite,
    required super.size,
  });
}
