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
        stiffness: 280.0,
        ratio: 1.0,
      );

  @override
  double get minFlingVelocity => 300.0;

  @override
  double? get dragStartDistanceMotionThreshold => 4.0;
}
