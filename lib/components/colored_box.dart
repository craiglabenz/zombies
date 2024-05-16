import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class ColoredSquare extends PositionComponent {
  ColoredSquare(Vector2 position,
      {this.color = const Color(0xFF000000), double? size})
      : super(
          anchor: Anchor.center,
          position: position,
          priority: 100,
          size: Vector2.all(size ?? 10),
        );

  factory ColoredSquare.red(Vector2 position, {double? size}) => ColoredSquare(
        position,
        color: const Color(0xFFFF0000),
        size: size,
      );

  factory ColoredSquare.green(Vector2 position, {double? size}) =>
      ColoredSquare(
        position,
        color: const Color(0xFF00FF00),
        size: size,
      );

  factory ColoredSquare.blue(Vector2 position, {double? size}) =>
      ColoredSquare(position, color: const Color(0xFF0000FF), size: size);

  final Color color;

  @override
  void onLoad() {
    add(
      RectangleComponent(
        paint: Paint()..color = color,
        size: size,
      ),
    );
  }
}
