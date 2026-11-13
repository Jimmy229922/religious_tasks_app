import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';

class FullAdhanOverlayDialog extends StatefulWidget {
  final String prayerName;
  final String prayerKey;

  const FullAdhanOverlayDialog({
    super.key,
    required this.prayerName,
    required this.prayerKey,
  });

  @override
  State<FullAdhanOverlayDialog> createState() => _FullAdhanOverlayDialogState();
}

class _FullAdhanOverlayDialogState extends State<FullAdhanOverlayDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showDua = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getPrayerIndex(String key) {
    switch (key.toLowerCase()) {
      case 'fajr':
        return 0;
      case 'dhuhr':
        return 1;
      case 'asr':
        return 2;
      case 'maghrib':
        return 3;
      case 'isha':
        return 4;
      default:
        return 0;
    }
  }

  void _onPrayerCompleted() {
    try {
      final vm = Provider.of<TasksViewModel>(context, listen: false);
      vm.toggleTask(_getPrayerIndex(widget.prayerKey), completionValue: true);
    } catch (_) {}

    AppNotificationService().stopAdhanAudio();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تقبل الله طاعتك وصالح أعمالك في صلاة ${widget.prayerName} 🤲"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _snoozeTenMinutes() {
    AppNotificationService().stopAdhanAudio();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("سيتم تذكيرك بالصلاة بعد 10 دقائق ⏱️"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog.fullscreen(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Title
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "تطبيق رفيق المسلم",
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "حَانَ الآنَ وَقْتُ أَذَانِ صَلَاةِ",
                        style: GoogleFonts.cairo(
                          color: Colors.amberAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.prayerName,
                        style: GoogleFonts.arefRuqaa(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Animated Mosque Pulsing Ring
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.withValues(alpha: 0.2),
                        border: Border.all(
                            color: Colors.amberAccent.withValues(alpha: 0.8),
                            width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mosque_rounded,
                          size: 90,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),

                  // Post-Adhan Dua Toggle Card
                  if (_showDua)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "دعاء ما بعد الأذان 📖",
                            style: GoogleFonts.cairo(
                              color: Colors.amberAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: () => setState(() => _showDua = true),
                      icon: const Icon(Icons.auto_stories_rounded,
                          color: Colors.amberAccent, size: 20),
                      label: Text(
                        "عرض دعاء ما بعد الأذان",
                        style: GoogleFonts.cairo(
                          color: Colors.amberAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Bottom Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _onPrayerCompleted,
                          icon: const Icon(Icons.check_circle_rounded,
                              color: Colors.white),
                          label: Text(
                            "تمت الصلاة بحمد الله 🤲",
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _snoozeTenMinutes,
                          icon: const Icon(Icons.snooze_rounded,
                              color: Colors.white70),
                          label: Text(
                            "تذكير بعد 10 دقائق ⏱️",
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: Colors.white30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
