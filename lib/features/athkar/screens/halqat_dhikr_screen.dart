import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HalqatDhikrScreen extends StatefulWidget {
  const HalqatDhikrScreen({super.key});

  @override
  State<HalqatDhikrScreen> createState() => _HalqatDhikrScreenState();
}

class _DhikrSessionItem {
  final String text;
  final int target;
  int current;

  _DhikrSessionItem({required this.text})
      : target = 3,
        current = 0;
  bool get isDone => current >= target;
}

class _HalqatDhikrScreenState extends State<HalqatDhikrScreen> {
  final List<String> _masterAthkar = [
    "سبحان الله وبحمده",
    "سبحان الله العظيم",
    "لا إله إلا الله",
    "الله أكبر",
    "أستغفر الله",
    "لا حول ولا قوة إلا بالله",
    "اللهم صل وسلم على نبينا محمد",
    "سبحان الله والحمد لله ولا إله إلا الله والله أكبر",
    "رضيت بالله رباً وبالإسلام ديناً وبمحمد ﷺ نبياً",
    "اللهم إنك عفو تحب العفو فاعف عنا",
  ];

  late List<_DhikrSessionItem> _sessionAthkar;

  @override
  void initState() {
    super.initState();
    _startNewSession();
  }

  void _startNewSession() {
    final random = Random();
    final shuffled = List<String>.from(_masterAthkar)..shuffle(random);
    final selected = shuffled.take(3).toList();
    _sessionAthkar =
        selected.map((text) => _DhikrSessionItem(text: text)).toList();
  }

  void _handleTap(int index) {
    setState(() {
      if (!_sessionAthkar[index].isDone) {
        _sessionAthkar[index].current++;
      }
    });

    if (_sessionAthkar.every((d) => d.isDone)) {
      // Session Complete!
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 50),
        content: Text(
          "تقبل الله منك! أتممت حلقة الذكر.",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close screen
            },
            child: Text("تم", style: GoogleFonts.cairo(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              setState(() {
                _startNewSession(); // Restart
              });
            },
            child: Text("حلقة جديدة",
                style: GoogleFonts.cairo(color: Colors.tealAccent)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("حلقة الذكر",
            style: GoogleFonts.arefRuqaa(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
                : [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "ردد كل ذكر ${3} مرات",
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Colors.teal[800]),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessionAthkar.length,
                  itemBuilder: (ctx, index) {
                    final item = _sessionAthkar[index];
                    return _buildDhikrCard(item, index, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDhikrCard(_DhikrSessionItem item, int index, bool isDark) {
    final floatProgress = item.current / item.target;
    final isComplete = item.isDone;

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.2)
              : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isComplete ? Colors.green : Colors.transparent, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Circular Counter
            Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: floatProgress,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                      isComplete ? Colors.green : Colors.amber),
                ),
                if (isComplete)
                  const Icon(Icons.check, color: Colors.green, size: 20)
                else
                  Text(
                    "${item.current}",
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.text,
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
