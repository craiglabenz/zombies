import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:zombies/assets.dart';
import 'package:zombies/behaviors/behaviors.dart';
import 'package:zombies/components/components.dart';
import 'package:zombies/constants.dart';
import 'package:zombies/utilities/utilities.dart';
import 'package:zombies/zombie_game.dart';

class Zombie extends PositionedEntity
    with
        HasGameReference<ZombieGame>,
        UnwalkableTerrainChecker,
        CollisionCallbacks {
  Zombie({
    required super.position,
    this.speed = worldTileSize * 2,
    this.debug = false,
  }) : super(
          size: Vector2.all(64),
          anchor: Anchor.center,
          priority: 1,
          children: [CircleHitbox.relative(0.8, parentSize: Vector2.all(64))],
          behaviors: [GoalControllingBehavior(), ZombieMovingBehavior()],
        );

  late ZombieGoalState goalState;

  double speed;
  LineComponent? visualizedPathToPlayer;
  LineComponent? visualizedPathToCollision;
  bool debug;

  Random rnd = Random();

  late SpriteAnimationComponent walkingAnimation;
  late SpriteComponent idleComponent;

  late PathFindingBehavior pathFinding;

  static const defaultWalkingStepTime = 0.3;

  void useWalkingAnimation() {
    remove(idleComponent);
    add(walkingAnimation);
  }

  void useStandingAnimation({bool onLoad = false}) {
    // On the first call, there isn't yet a walking animation to remove
    if (!onLoad) {
      remove(walkingAnimation);
    }
    add(idleComponent);
  }

  @override
  void onLoad() {
    final idleSprite = Sprite(game.images.fromCache(
      Assets.assets_characters_Zombie_Poses_zombie_idle_png,
    ));
    idleComponent = SpriteComponent(
      sprite: idleSprite,
      size: Vector2.all(64.0),
    );

    final animation = SpriteAnimation.spriteList(
      [
        Sprite(
          game.images.fromCache(
            Assets.assets_characters_Zombie_Poses_zombie_walk1_png,
          ),
        ),
        Sprite(
          game.images.fromCache(
            Assets.assets_characters_Zombie_Poses_zombie_walk2_png,
          ),
        ),
      ],
      stepTime: defaultWalkingStepTime,
    );
    walkingAnimation = SpriteAnimationComponent(
      animation: animation,
      size: Vector2.all(64.0),
    );
    add(idleComponent);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    findBehavior<ZombieMovingBehavior>().undoCollisions(
      other: other,
      intersectionPoints: intersectionPoints,
    );
  }

  void setStateToWandering() {
    if (hasBehavior<ChasingBehavior>()) {
      remove(findBehavior<ChasingBehavior>());
    }
    if (!hasBehavior<WanderingBehavior>()) {
      pathFinding = WanderingBehavior();
      add(pathFinding);
    }
  }

  void setStateToChasing() {
    if (hasBehavior<WanderingBehavior>()) {
      remove(findBehavior<WanderingBehavior>());
    }
    if (!hasBehavior<ChasingBehavior>()) {
      pathFinding = ChasingBehavior();
      add(pathFinding);
    }
  }
}
