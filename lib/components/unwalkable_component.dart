import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class UnwalkableComponent extends PolygonComponent {
  UnwalkableComponent(super._vertices)
      : super(
          anchor: Anchor.center,
          children: [
            RectangleHitbox(),
            // TODO: Make this work, but the _vertices values have to be made
            //       relative; right now they are absolute
            // PolygonHitbox(_vertices),
          ],
          priority: 10,
        );

  @override
  bool get renderShape => false;
}
