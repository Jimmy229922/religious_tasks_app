import 'package:flutter/material.dart';

class GuidedTasbeehScreen extends StatefulWidget {
  const GuidedTasbeehScreen({super.key});

  @override
  State<GuidedTasbeehScreen> createState() => _GuidedTasbeehScreenState();
}

class _GuidedTasbeehScreenState extends State<GuidedTasbeehScreen>
    with SingleTickerProviderStateMixin {
  // Sample Data for "The Loop"
  final List<Map<String, dynamic>> _loopItems = [
    {
      "text": "سبحان الله",
      "count": 3,
    },
    {
      "text": "الحمد لله",
      "count": 3,
    },
    {
      "text": "الله أكبر",
      "count": 3,
    },
    {
      "text": "لا إله إلا الله",
      "count": 3,
    },
  ];

  int _currentIndex = 0;
  int _currentCount = 0;
  bool _isCompleted = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isCompleted) return;

    _scaleController.forward().then((_) => _scaleController.reverse());

    setState(() {
      _currentCount++;
      if (_currentCount >= _loopItems[_currentIndex]['count']) {
        // Move to next
        if (_currentIndex < _loopItems.length - 1) {
          // Add a small delay for "professional" feel or just instant
          // Let's do instant but maybe with a transition effect in a real app.
          // For now, swap data.
          _currentIndex++;
          _currentCount = 0;
        } else {
          // Loop Finished
          _isCompleted = true;
          // You could save this session here
        }
      }
    });
  }

  void _reset() {
    setState(() {
      _currentIndex = 0;
      _currentCount = 0;
      _isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Current Item Data
    final item = _isCompleted ? null : _loopItems[_currentIndex];
    final target = _isCompleted ? 0 : item!['count'] as int;
    final text = _isCompleted ? "تقبل الله طاعتكم" : item!['text'] as String;

    // Progress for the whole loop
    final totalSteps =
        _loopItems.fold<int>(0, (sum, i) => sum + (i['count'] as int));
    // Calculate how many steps passed in previous items
    int stepsPassed = 0;
    for (int i = 0; i < _currentIndex; i++) {
      stepsPassed += _loopItems[i]['count'] as int;
    }
    stepsPassed += _currentCount;
    final overallProgress = totalSteps == 0 ? 0.0 : stepsPassed / totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark theme default
      appBar: AppBar(
        title: const Text("حلقة ذكر"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top Progress Bar
          LinearProgressIndicator(
            value: overallProgress,
            backgroundColor: Colors.white10,
            color: const Color(0xFFE94560),
            minHeight: 6,
          ),

          Expanded(
            child: Center(
              child: _isCompleted
                  ? _buildCompletionView()
                  : _buildCounterView(text, target),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterView(String text, int target) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque, // Tap anywhere
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "الذكر ${_currentIndex + 1} من ${_loopItems.length}",
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 30),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF16213E).withValues(alpha: 0.5),
                  border: Border.all(color: const Color(0xFFE94560), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE94560).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ]),
              child: Column(
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "$_currentCount / $target",
                    style: const TextStyle(
                      color: Color(0xFFE94560),
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 50),
          const Text(
            "اضغط للشاشة للعد",
            style: TextStyle(color: Colors.white30),
          )
        ],
      ),
    );
  }

  Widget _buildCompletionView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline,
            color: Colors.greenAccent, size: 80),
        const SizedBox(height: 20),
        const Text(
          "اكتملت الحلقة المباركة",
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
          child: const Text("عودة", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _reset,
          child: const Text("بدء مرة أخرى",
              style: TextStyle(color: Colors.white70)),
        )
      ],
    );
  }
}
