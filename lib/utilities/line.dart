import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:vector_math/vector_math_64.dart';

class Line extends Equatable {
  Line(this.start, this.end);

  factory Line.doubles(
    double startX,
    double startY,
    double endX,
    double endY,
  ) =>
      Line(Vector2(startX, startY), Vector2(endX, endY));

  final Vector2 start;
  final Vector2 end;

  List<double> asList() => [start.x, start.y, end.x, end.y];

  double? get slope {
    if (start.x == end.x) return null;
    return dy / dx;
  }

  late final double dx = end.x - start.x;
  late final double dy = end.y - start.y;

  Vector2 get center => (start + end) / 2;

  Line extend(double multiplier) {
    final longerVector = vector2 * multiplier;
    return Line(start, longerVector + start);
  }

  Vector2? _vector2;
  Vector2 get vector2 {
    _vector2 ??= Vector2(end.x - start.x, end.y - start.y);
    return _vector2!;
  }

  double? _length;
  double get length {
    _length = sqrt(pow(dx, 2) + pow(dy, 2));
    return _length!;
  }

  double? _length2;
  double get length2 {
    _length2 = pow(dx, 2).toDouble() + pow(dy, 2).toDouble();
    return _length2!;
  }

  @override
  String toString() {
    return 'Line(start: $start, end: $end)';
  }

  double get angle => atan2(dy, dx);
  double get angleDeg => angle * radians2Degrees;

  Line copy() => Line.doubles(start.x, start.y, end.x, end.y);

  @override
  List<Object> get props => asList();

  Vector2? intersectsAt(Line other) {
    double s =
        (-dy * (start.x - other.start.x) + dx * (start.y - other.start.y)) /
            (-other.dx * dy + dx * other.dy);
    double t = (other.dx * (start.y - other.start.y) -
            other.dy * (start.x - other.start.x)) /
        (-other.dx * dy + dx * other.dy);

    if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
      // Collision!
      return Vector2(start.x + (t * dx), start.y + (t * dy));
    }
    return null;
  }
}
