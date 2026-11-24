import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/happiness_jar/data/happiness_jar_data.dart';
import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences_service.dart';

class HappinessJarScreen extends StatefulWidget {
  const HappinessJarScreen({super.key});

  @override
  State<HappinessJarScreen> createState() => _HappinessJarScreenState();
}

class _HappinessJarScreenState extends State<HappinessJarScreen>
    with TickerProviderStateMixin {
  static const String _favoritesKey = 'happiness_jar_favorites_v1';
  Color get _emerald => context.primaryColor;
  Color get _emeraldDark => context.primaryDarkColor;
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _amber = Color(0xFFD97706);

  final NotificationPreferencesService _prefsService =
      NotificationPreferencesService();
  final AppNotificationService _notificationService = AppNotificationService();

  late AnimationController _shakeController;
  late AnimationController _floatController;
  late AnimationController _drawScrollController;

  HappinessCategory _selectedCategory = HappinessCategory.all;
  late HappinessMessage _drawnMessage;
  late HappinessMessage _todayMessage;
  Set<String> _favoriteIds = {};
  NotificationPreferences _prefs = NotificationPreferences.defaults();
  bool _isUpdatingSchedule = false;
  bool _isDrawing = false;
  int _bottomSection = 0; // 0: رسالة اليوم, 1: المفضلة, 2: إعداد الإشعار اليومي

  @override
  void initState() {
    super.initState();
    _todayMessage = HappinessJarData.getMessageForDate(DateTime.now());
    _drawnMessage = _todayMessage;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _drawScrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _loadInitialState();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _floatController.dispose();
    _drawScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favs = prefs.getStringList(_favoritesKey) ?? [];
      final notifPrefs = await _prefsService.load();
      if (!mounted) return;
      setState(() {
        _favoriteIds = favs.toSet();
        _prefs = notifPrefs;
      });
    } catch (_) {
      // Keep safe defaults if storage is unavailable in isolated test harnesses
    }
  }

  Future<void> _drawRandomMessage() async {
    if (_isDrawing) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isDrawing = true;
    });
    _shakeController.forward(from: 0);
    _drawScrollController.forward(from: 0);

    final next = HappinessJarData.getRandomMessage(
      category: _selectedCategory,
      excludeId: _drawnMessage.id,
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _drawnMessage = next;
      _isDrawing = false;
    });
    _drawScrollController.reset();
  }

  Future<void> _toggleFavorite(HappinessMessage message) async {
    HapticFeedback.lightImpact();
    final updated = Set<String>.from(_favoriteIds);
    final added = !updated.contains(message.id);
    if (added) {
      updated.add(message.id);
    } else {
      updated.remove(message.id);
    }
    setState(() {
      _favoriteIds = updated;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, updated.toList());
    } catch (_) {}
    _showSnack(
      added
          ? 'تم حفظ الرسالة في مفضلة السعادة ❤️'
          : 'تمت إزالة الرسالة من المفضلة',
    );
  }

  void _copyMessage(HappinessMessage message) {
    final text = _formatShareText(message);
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    _showSnack('تم نسخ الرسالة، شاركها لمن تحب 💛');
  }

  void _shareMessage(HappinessMessage message) {
    SharePlus.instance.share(
      ShareParams(
        text: _formatShareText(message),
        subject: 'رسالة من برطمان السعادة — ${message.title}',
      ),
    );
  }

  void _openCardDialog(HappinessMessage message) {
    showDialog(
      context: context,
      builder: (_) => IslamicCardGeneratorDialog(
        title: message.title,
        content: message.body,
        subtitle: message.reflection ?? 'من برطمان السعادة • رفيق المسلم',
      ),
    );
  }

  String _formatShareText(HappinessMessage message) {
    final reflection =
        message.reflection != null ? '\n\n✨ ${message.reflection}' : '';
    return '🫙 ${message.title}\n\n${message.body}$reflection\n\n— تطبيق رفيق المسلم';
  }

  Future<void> _toggleDailyNotification(bool enabled) async {
    if (_isUpdatingSchedule) return;
    setState(() {
      _isUpdatingSchedule = true;
      _prefs = _prefs.copyWith(happinessJarEnabled: enabled);
    });
    try {
      await _prefsService.setHappinessJarEnabled(enabled);
      await _notificationService.scheduleHappinessJarNotifications(
        settings: _prefs,
      );
      _showSnack(
        enabled
            ? 'تم تفعيل رسالة السعادة اليومية الساعة ${_formatTime(_prefs.happinessJarHour, _prefs.happinessJarMinute)}'
            : 'تم إيقاف الإشعار اليومي لبرطمان السعادة',
      );
    } catch (_) {
      _showSnack('حدثت مشكلة أثناء تحديث جدولة الإشعار');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSchedule = false);
      }
    }
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _prefs.happinessJarHour,
        minute: _prefs.happinessJarMinute,
      ),
      helpText: 'اختر وقت وصول رسالة السعادة اليومية',
      cancelText: 'إلغاء',
      confirmText: 'حفظ الوقت',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _isUpdatingSchedule = true;
      _prefs = _prefs.copyWith(
        happinessJarEnabled: true,
        happinessJarHour: picked.hour,
        happinessJarMinute: picked.minute,
      );
    });
    try {
      await _prefsService.setHappinessJarEnabled(true);
      await _prefsService.setHappinessJarTime(picked.hour, picked.minute);
      await _notificationService.scheduleHappinessJarNotifications(
        settings: _prefs,
      );
      _showSnack(
        'سيصلك إشعار مبهج كل يوم الساعة ${_formatTime(picked.hour, picked.minute)} بإذن الله 💛',
      );
    } catch (_) {
      _showSnack('تعذر تحديث موعد الإشعار');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSchedule = false);
      }
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await _notificationService.testHappinessJarNotification();
      _showSnack('تم إرسال رسالة سعادة تجريبية إلى إشعاراتك 🔔');
    } catch (_) {
      _showSnack('تأكد من تفعيل صلاحية الإشعارات للتطبيق');
    }
  }

  String _formatTime(int hour, int minute) {
    final isPm = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final paddedMin = minute.toString().padLeft(2, '0');
    final period = isPm ? 'م' : 'ص';
    return QuranTextFormatter.toArabicDigits('$displayHour:$paddedMin $period');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: GoogleFonts.cairo()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = HappinessJarData.messages
        .where((m) => _favoriteIds.contains(m.id))
        .toList();

    return Scaffold(
      backgroundColor: context.appScaffoldBg,
      appBar: AppBar(
        title: Text(
          'برطمان السعادة 💛',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? const Color(0xFFFDE68A) : Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? context.appHeaderBg : _emerald,
        foregroundColor: isDark ? const Color(0xFFFDE68A) : Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'إرسال إشعار سعادة تجريبي',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: _sendTestNotification,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.appBgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // 1. Hero Interactive Jar Banner
              _buildJarHeroCard(isDark),

              const SizedBox(height: 16),

              // 2. Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: HappinessCategory.values.map((cat) {
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        selected: selected,
                        selectedColor: _emerald,
                        backgroundColor:
                            isDark ? const Color(0xFF172231) : Colors.white,
                        side: BorderSide(
                          color: selected
                              ? _gold
                              : (isDark
                                  ? Colors.white12
                                  : _emerald.withValues(alpha: 0.2)),
                        ),
                        showCheckmark: false,
                        label: Text(
                          '${cat.emoji} ${cat.label}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF0F172A)),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = cat;
                            if (cat != HappinessCategory.all &&
                                _drawnMessage.category != cat) {
                              _drawnMessage = HappinessJarData.getRandomMessage(
                                category: cat,
                              );
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Drawn Message Card
              _buildDrawnMessageCard(_drawnMessage, isDark),

              const SizedBox(height: 18),

              // 4. Bottom Switcher: Today's Message | Favorites | Daily Notification
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF172231) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    _buildTabChip(0, 'رسالة اليوم ☀️', isDark),
                    _buildTabChip(
                      1,
                      'المفضلة (${QuranTextFormatter.toArabicDigits(favorites.length.toString())})',
                      isDark,
                    ),
                    _buildTabChip(2, 'الإشعار اليومي 🔔', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (_bottomSection == 0)
                _buildTodayMessageSection(isDark)
              else if (_bottomSection == 1)
                _buildFavoritesSection(favorites, isDark)
              else
                _buildNotificationScheduleSection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJarHeroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0E2926), Color(0xFF132234)]
              : [_emerald, _emeraldDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _gold.withValues(alpha: 0.55),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : _emerald).withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isDrawing ? null : _drawRandomMessage,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_shakeController, _floatController]),
                  builder: (context, child) {
                    final shakeProgress = _shakeController.value;
                    final angle = math.sin(shakeProgress * math.pi * 6) *
                        (1 - shakeProgress) *
                        0.14;
                    final scaleBoost = _isDrawing
                        ? 1.0 + math.sin(shakeProgress * math.pi) * 0.07
                        : 1.0;
                    final floatDy = (_floatController.value - 0.5) * 6;
                    return Transform.translate(
                      offset: Offset(0, floatDy),
                      child: Transform.scale(
                        scale: scaleBoost,
                        child: Transform.rotate(
                          angle: angle,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _gold,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.3),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        isDark
                            ? 'assets/images/happiness_jar.jpg'
                            : 'assets/images/happiness_jar_light.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _drawScrollController,
                  builder: (context, _) {
                    if (!_isDrawing && _drawScrollController.value == 0) {
                      return const SizedBox.shrink();
                    }
                    final t = Curves.easeOutCubic
                        .transform(_drawScrollController.value);
                    final opacity = t < 0.2
                        ? (t / 0.2)
                        : (t > 0.78 ? ((1 - t) / 0.22).clamp(0.0, 1.0) : 1.0);
                    return Positioned(
                      top: 6 - (t * 44),
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.75 + (t * 0.35),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFDE68A), Color(0xFFD4AF37)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFDE68A)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mark_email_read_rounded,
                                  size: 16,
                                  color: Color(0xFF0F172A),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'رسالة لك 💛',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'اضغط على البرطمان لتسحب رسالة تفرح قلبك',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDrawing ? null : _drawRandomMessage,
              icon: _isDrawing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF0F172A),
                      ),
                    )
                  : const Icon(Icons.volunteer_activism_rounded, size: 20),
              label: Text(
                _isDrawing ? 'جاري سحب رسالتك...' : 'اسحب رسالة سعادة جديدة ✨',
                style: GoogleFonts.cairo(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                disabledBackgroundColor: _gold.withValues(alpha: 0.78),
                foregroundColor: const Color(0xFF0F172A),
                disabledForegroundColor: const Color(0xFF0F172A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawnMessageCard(HappinessMessage message, bool isDark) {
    final isFav = _favoriteIds.contains(message.id);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
      ),
      child: _isDrawing
          ? Container(
              key: const ValueKey('drawing_placeholder'),
              padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF172231) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.5),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: _gold,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تُفتح لك رسالة سعادة الآن...',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amberAccent : _emeraldDark,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              key: ValueKey(message.id),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF172231) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _gold.withValues(alpha: isDark ? 0.35 : 0.45),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${message.category.emoji} ${message.category.label}',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.amberAccent : _amber,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: isFav ? 'إزالة من المفضلة' : 'حفظ في المفضلة',
                        onPressed: () => _toggleFavorite(message),
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav
                              ? Colors.pinkAccent
                              : (isDark
                                  ? Colors.white54
                                  : Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.title,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.tealAccent : _emeraldDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message.body,
                    style: GoogleFonts.amiri(
                      fontSize: 21,
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (message.reflection != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? _emerald.withValues(alpha: 0.16)
                            : const Color(0xFFF0FDF9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _emerald.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.spa_rounded,
                            size: 18,
                            color: isDark ? Colors.tealAccent : _emerald,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.reflection!,
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark ? Colors.tealAccent : _emeraldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionChipButton(
                          isDark: isDark,
                          icon: Icons.copy_rounded,
                          label: 'نسخ',
                          onTap: () => _copyMessage(message),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionChipButton(
                          isDark: isDark,
                          icon: Icons.share_rounded,
                          label: 'مشاركة',
                          onTap: () => _shareMessage(message),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionChipButton(
                          isDark: isDark,
                          icon: Icons.image_rounded,
                          label: 'بطاقة',
                          onTap: () => _openCardDialog(message),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionChipButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2D3E) : const Color(0xFFF4F7F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.tealAccent : _emerald),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(int index, String label, bool isDark) {
    final selected = _bottomSection == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _bottomSection = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? _emerald : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayMessageSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.wb_sunny_rounded, color: _amber, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رسالة اليوم المجدولة للجميع',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _todayMessage.title,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: isDark ? Colors.amberAccent : _amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _drawnMessage = _todayMessage);
                },
                child: Text(
                  'عرض بالأعلى',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.tealAccent : _emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _todayMessage.body,
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              height: 1.65,
              color:
                  isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(List<HappinessMessage> favorites, bool isDark) {
    if (favorites.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF172231) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 40,
                color: isDark ? Colors.white38 : Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'لا توجد رسائل مفضلة بعد',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              'اضغط على رمز القلب ❤️ على أي رسالة لتحتفظ بها وتعود لها وقتما تشاء.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: favorites.map((msg) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
            ),
          ),
          child: InkWell(
            onTap: () => setState(() => _drawnMessage = msg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.category.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.title,
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        msg.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_rounded,
                      color: Colors.pinkAccent, size: 20),
                  onPressed: () => _toggleFavorite(msg),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationScheduleSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _prefs.happinessJarEnabled
              ? _emerald.withValues(alpha: 0.35)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mark_email_unread_rounded,
                    color: _amber, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إشعار برطمان السعادة اليومي',
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'تصلك رسالة جديدة مختلفة ومبهجة كل يوم تلقائياً',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _prefs.happinessJarEnabled,
                activeTrackColor: _emerald,
                activeThumbColor: Colors.white,
                onChanged:
                    _isUpdatingSchedule ? null : _toggleDailyNotification,
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isUpdatingSchedule ? null : _pickNotificationTime,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E2B3C) : const Color(0xFFF6FAF9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _emerald.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_filled_rounded,
                      color: isDark ? Colors.tealAccent : _emerald, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'وقت وصول الرسالة اليومية',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _formatTime(
                        _prefs.happinessJarHour,
                        _prefs.happinessJarMinute,
                      ),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.tealAccent : _emeraldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _sendTestNotification,
            icon: const Icon(Icons.notifications_active_rounded, size: 18),
            label: Text(
              'تجربة إشعار السعادة الآن 🔔',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.amberAccent : _amber,
              side: BorderSide(
                color: _amber.withValues(alpha: 0.55),
              ),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
