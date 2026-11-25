import 'package:flutter/widgets.dart';

class MushafPageScrollPhysics extends PageScrollPhysics {
  const MushafPageScrollPhysics({super.parent});

  @override
  MushafPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MushafPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 165.0,
        ratio: 1.08,
      );

  @override
  double get minFlingVelocity => 420.0;

  @override
  double? get dragStartDistanceMotionThreshold => 6.0;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset * 0.94);
  }
}
