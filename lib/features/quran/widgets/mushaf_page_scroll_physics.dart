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
        stiffness: 560.0,
        ratio: 1.0,
      );

  @override
  double get minFlingVelocity => 150.0;
}
