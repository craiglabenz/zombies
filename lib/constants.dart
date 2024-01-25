const double tileSize = 16;
const double worldScale = 4;
const double worldTileSize = tileSize * worldScale;

class Priority {
  static const int goalSetting = 1;
  static const int pathFinding = 2;
  static const int movement = 3;
}

class RenderingPriority {
  static const int ground = 1;
  static const int object = 1;
  static const int player = 2;
  static const int zombie = 3;
  static const int effect = 4;
}
