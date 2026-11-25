import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/mushaf_reader_theme.dart';

class MushafPageSideIndicator extends StatefulWidget {
  final int pageNumber;
  final bool isDark;
  final PageController? pageController;
  final int pageIndexOffset;

  const MushafPageSideIndicator({
    super.key,
    required this.pageNumber,
    required this.isDark,
    this.pageController,
    this.pageIndexOffset = 1,
  });

  static const String rightPageAsset = 'assets/images/mushaf_right_page.png';
  static const String leftPageAsset = 'assets/images/mushaf_left_page.png';

  static String assetForPage(int page) =>
      page.isOdd ? rightPageAsset : leftPageAsset;

  static String toArabicDigits(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((c) => digits[int.parse(c)])
        .join();
  }

  @override
  State<MushafPageSideIndicator> createState() =>
      _MushafPageSideIndicatorState();
}

class _DragTurnState {
  final int fromPage;
  final int toPage;
  final double progress;

  const _DragTurnState({
    required this.fromPage,
    required this.toPage,
    required this.progress,
  });
}

class _MushafPageSideIndicatorState extends State<MushafPageSideIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turnController;
  late final Animation<double> _turnCurve;
  final ValueNotifier<_DragTurnState?> _dragState =
      ValueNotifier<_DragTurnState?>(null);
  int _fromPage = 1;
  int _toPage = 1;

  @override
  void initState() {
    super.initState();
    _fromPage = widget.pageNumber;
    _toPage = widget.pageNumber;
    _turnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _turnCurve = CurvedAnimation(
      parent: _turnController,
      curve: Curves.easeOutCubic,
    );
    widget.pageController?.addListener(_onPageScroll);
  }

  @override
  void didUpdateWidget(covariant MushafPageSideIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController?.removeListener(_onPageScroll);
      widget.pageController?.addListener(_onPageScroll);
    }
    if (oldWidget.pageNumber != widget.pageNumber) {
      if (_dragState.value == null) {
        _fromPage = _toPage;
        _toPage = widget.pageNumber;
        _turnController.forward(from: 0.0);
      } else {
        _fromPage = widget.pageNumber;
        _toPage = widget.pageNumber;
      }
    }
  }

  void _onPageScroll() {
    final controller = widget.pageController;
    if (controller == null ||
        !controller.hasClients ||
        !controller.position.haveDimensions) {
      return;
    }
    final raw = controller.page;
    if (raw == null) return;
    final floorIdx = raw.floor();
    final frac = raw - floorIdx;
    if (frac <= 0.005 || frac >= 0.995) {
      if (_dragState.value != null) {
        _fromPage = widget.pageNumber;
        _toPage = widget.pageNumber;
        _dragState.value = null;
      }
      return;
    }
    final fromAbs = (floorIdx + widget.pageIndexOffset).clamp(1, 604);
    final toAbs = (fromAbs + 1).clamp(1, 604);
    _dragState.value = _DragTurnState(
      fromPage: fromAbs,
      toPage: toAbs,
      progress: frac,
    );
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onPageScroll);
    _dragState.dispose();
    _turnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MushafReaderTheme.of(widget.isDark);

    return IgnorePointer(
      child: RepaintBoundary(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: theme.indicatorBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.indicatorBorder,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ValueListenableBuilder<_DragTurnState?>(
              valueListenable: _dragState,
              builder: (context, drag, _) {
                return AnimatedBuilder(
                  animation: _turnCurve,
                  builder: (context, _) {
                    final activeFrom = drag?.fromPage ?? _fromPage;
                    final activeTo = drag?.toPage ?? _toPage;
                    final progress = drag?.progress ??
                        (_fromPage == _toPage ? 1.0 : _turnCurve.value);
                    return _AnimatedMushafBookIcon(
                      fromPage: activeFrom,
                      toPage: activeTo,
                      progress: progress,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedMushafBookIcon extends StatelessWidget {
  final int fromPage;
  final int toPage;
  final double progress;

  const _AnimatedMushafBookIcon({
    required this.fromPage,
    required this.toPage,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    const double iconW = 64;
    const double iconH = 44;
    final clamped = progress.clamp(0.0, 1.0);
    final fromAsset = MushafPageSideIndicator.assetForPage(fromPage);
    final toAsset = MushafPageSideIndicator.assetForPage(toPage);
    final bool sameSide = fromAsset == toAsset;

    final double leafWave = math.sin(clamped * math.pi);
    final bool forward = toPage >= fromPage;
    final double turnAngle =
        (forward ? -1.0 : 1.0) * (clamped - 0.5) * math.pi * 0.88;

    return SizedBox(
      width: iconW,
      height: iconH,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (sameSide)
            Image.asset(
              toAsset,
              width: iconW,
              height: iconH,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            )
          else ...[
            Opacity(
              opacity: (1.0 - clamped).clamp(0.0, 1.0),
              child: Image.asset(
                fromAsset,
                width: iconW,
                height: iconH,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Opacity(
              opacity: clamped,
              child: Image.asset(
                toAsset,
                width: iconW,
                height: iconH,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
            if (leafWave > 0.04)
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0022)
                  ..rotateY(turnAngle),
                child: Opacity(
                  opacity: (leafWave * 0.82).clamp(0.0, 0.85),
                  child: Container(
                    width: 20,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFF6D6),
                          Color(0xFFE7C266),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFB8860B),
                        width: 0.7,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD76A).withValues(alpha: 0.45),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
