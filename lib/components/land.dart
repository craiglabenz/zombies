import 'package:flame/components.dart';

class Land extends SpriteComponent {
  Land({super.position, super.sprite})
      : super(size: Vector2.all(64), anchor: Anchor.center);
}
