import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/shared/services/audio/radio_service.dart';
import '../providers/radio_view_model.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  Color get _emerald => context.primaryColor;
  Color get _emeraldDark => context.primaryDarkColor;
  static const Color _gold = Color(0xFFD4AF37);

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSleepTimerDialog(BuildContext context, RadioViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final presets = <(String, Duration)>[
          ('١٠ دقائق', const Duration(minutes: 10)),
          ('١٥ دقيقة', const Duration(minutes: 15)),
          ('٣٠ دقيقة', const Duration(minutes: 30)),
          ('٤٥ دقيقة', const Duration(minutes: 45)),
          ('ساعة كاملة', const Duration(hours: 1)),
          ('٩٠ دقيقة', const Duration(minutes: 90)),
          ('ساعتان', const Duration(hours: 2)),
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D2B) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _emerald.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.bedtime_rounded,
                          color: _emerald, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مؤقت النوم التلقائي',
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'يتوقف البث تلقائياً بعد انتهاء المدة المحددة',
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (vm.remainingSleepTime != null)
                      TextButton.icon(
                        onPressed: () {
                          vm.setSleepTimer(null);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.timer_off_rounded,
                            color: Colors.redAccent, size: 18),
                        label: Text(
                          'إلغاء',
                          style: GoogleFonts.cairo(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (vm.remainingSleepTime != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_bottom_rounded,
                            color: _emerald, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'الوقت المتبقي: ${QuranTextFormatter.toArabicDigits(vm.formattedRemainingSleepTime)}',
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.tealAccent : _emeraldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: presets.map((item) {
                    return _buildTimerOption(ctx, vm, item.$1, item.$2);
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerOption(
    BuildContext context,
    RadioViewModel vm,
    String label,
    Duration duration,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = vm.remainingSleepTime != null &&
        (vm.remainingSleepTime!.inMinutes - duration.inMinutes).abs() < 1;

    return ActionChip(
      avatar: Icon(
        Icons.timer_rounded,
        size: 17,
        color: isSelected ? Colors.white : _emerald,
      ),
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.tealAccent.shade100 : _emeraldDark),
        ),
      ),
      backgroundColor: isSelected
          ? _emerald
          : (isDark
              ? const Color(0xFF1D2B3B)
              : const Color(0xFFF1F8F6)),
      side: BorderSide(
        color: isSelected
            ? _gold
            : _emerald.withValues(alpha: isDark ? 0.35 : 0.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      onPressed: () {
        vm.setSleepTimer(duration);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text(
              'تم ضبط مؤقت النوم على $label',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B131E) : const Color(0xFFF3F8F6),
      appBar: AppBar(
        title: Text(
          'راديو القرآن الكريم',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF0B131E) : _emerald,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        actions: [
          Consumer<RadioViewModel>(
            builder: (context, vm, _) {
              final favOnly = vm.selectedCategory == 'favorites';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'المحطات المفضلة',
                    icon: Icon(
                      favOnly ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: favOnly ? Colors.amberAccent : Colors.white,
                    ),
                    onPressed: () {
                      vm.setSelectedCategory(favOnly ? 'all' : 'favorites');
                    },
                  ),
                  IconButton(
                    tooltip: 'مؤقت النوم',
                    icon: Badge(
                      isLabelVisible: vm.remainingSleepTime != null,
                      backgroundColor: _gold,
                      textColor: const Color(0xFF0F172A),
                      label: Text(
                        QuranTextFormatter.toArabicDigits(
                            vm.formattedRemainingSleepTime),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Icon(Icons.bedtime_rounded),
                    ),
                    onPressed: () => _showSleepTimerDialog(context, vm),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer<RadioViewModel>(
          builder: (context, vm, _) {
            final stations = vm.filteredStations;
            final recent = vm.recentStations;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Hero Player Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: _buildHeroPlayerCard(context, vm, isDark),
                  ),
                ),

                // 2. Recently Listened Strip
                if (recent.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded,
                                  size: 18,
                                  color: isDark ? Colors.tealAccent : _emerald),
                              const SizedBox(width: 6),
                              Text(
                                'استمعت مؤخراً',
                                style: GoogleFonts.cairo(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: recent.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final st = recent[idx];
                              final active = vm.currentStation?.id == st.id;
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _toggleStation(context, vm, st),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? _emerald
                                        : (isDark
                                            ? const Color(0xFF172231)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: active
                                          ? _gold
                                          : _emerald.withValues(
                                              alpha: isDark ? 0.35 : 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        active && vm.isPlaying
                                            ? Icons.graphic_eq_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 16,
                                        color: active
                                            ? Colors.amberAccent
                                            : _emerald,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        st.title,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: active
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF0F172A)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // 3. Search Bar & Category Chips
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: TextField(
                          controller: _searchController,
                          onChanged: vm.setSearchQuery,
                          style: GoogleFonts.cairo(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'ابحث باسم القارئ أو الإذاعة...',
                            hintStyle: GoogleFonts.cairo(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500,
                            ),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: _emerald),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      vm.setSearchQuery('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF172231)
                                : Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white12
                                    : _emerald.withValues(alpha: 0.18),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white12
                                    : _emerald.withValues(alpha: 0.18),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: _emerald, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildCategoryChip(
                                vm, 'all', 'الكل 📻', isDark),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                                vm, 'favorites', 'المفضلة ⭐', isDark),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                                vm, 'radios', 'الإذاعات 🎙️', isDark),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                                vm, 'reciters', 'أشهر القراء 👤', isDark),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                                vm, 'tafseer', 'التفسير 📖', isDark),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                        child: Row(
                          children: [
                            Icon(Icons.podcasts_rounded,
                                color: isDark ? Colors.tealAccent : _emerald,
                                size: 19),
                            const SizedBox(width: 8),
                            Text(
                              'المحطات المتاحة (${QuranTextFormatter.toArabicDigits(stations.length.toString())})',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Stations List or Empty State
                if (stations.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(vm, isDark),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    sliver: SliverList.builder(
                      itemCount: stations.length,
                      itemBuilder: (context, index) {
                        final station = stations[index];
                        return _buildStationCard(
                            context, vm, station, isDark);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroPlayerCard(
    BuildContext context,
    RadioViewModel vm,
    bool isDark,
  ) {
    final currentStation = vm.currentStation;

    if (currentStation == null) {
      return Container(
        padding: const EdgeInsets.all(20),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold.withValues(alpha: 0.55)),
                  ),
                  child: const Icon(
                    Icons.radio_rounded,
                    color: Colors.amberAccent,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بث مباشر على مدار الساعة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'استمع لأشهر القراء وإذاعات القرآن والتفسير بجودة عالية',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await vm.resumeLastOrDefaultStation();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'عذراً، تعذر الاتصال بالبث المباشر حالياً',
                            style: GoogleFonts.cairo(),
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(
                  vm.recentStations.isNotEmpty
                      ? 'متابعة: ${vm.recentStations.first.title}'
                      : 'تشغيل إذاعة القرآن الكريم الآن',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    final isFav = vm.isFavorite(currentStation.id);
    final volumePercent = QuranTextFormatter.toArabicDigits(
      '${(vm.volume * 100).round()}%',
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
          color: _gold.withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : _emerald).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Status + Badge + Favorite/Sleep Actions
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: vm.isLoading
                      ? Colors.amber.withValues(alpha: 0.25)
                      : (vm.isPlaying
                          ? const Color(0xFFDC2626)
                          : Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (vm.isPlaying && !vm.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Icon(Icons.fiber_manual_record,
                            size: 9, color: Colors.white),
                      ),
                    Text(
                      vm.isLoading
                          ? 'جاري الاتصال...'
                          : (vm.isPlaying ? 'بث مباشر LIVE' : 'متوقف مؤقتاً'),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withValues(alpha: 0.45)),
                ),
                child: Text(
                  currentStation.badge,
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? Colors.amberAccent : Colors.white70,
                ),
                onPressed: () => vm.toggleFavorite(currentStation.id),
                tooltip: 'المفضلة',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.bedtime_outlined, color: Colors.white70),
                onPressed: () => _showSleepTimerDialog(context, vm),
                tooltip: 'مؤقت النوم',
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            currentStation.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            vm.currentIcyTitle ?? currentStation.subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),

          if (vm.formattedRemainingSleepTime.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'إيقاف تلقائي بعد: ${QuranTextFormatter.toArabicDigits(vm.formattedRemainingSleepTime)}',
                style: GoogleFonts.cairo(
                  color: Colors.amberAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            height: 28,
            child: vm.isPlaying
                ? const _LiveSoundwaveWidget(
                    color: Colors.amberAccent,
                    height: 28,
                    barCount: 7,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      7,
                      (_) => Container(
                        width: 3.5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Transport Controls: Previous | Play-Pause | Next | Stop
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'المحطة السابقة',
                iconSize: 32,
                color: Colors.white.withValues(alpha: 0.9),
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () => _runSafe(context, vm.previousStation),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold,
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: vm.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      )
                    : IconButton(
                        iconSize: 40,
                        color: const Color(0xFF0F172A),
                        icon: Icon(
                          vm.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: () =>
                            _toggleStation(context, vm, currentStation),
                      ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'المحطة التالية',
                iconSize: 32,
                color: Colors.white.withValues(alpha: 0.9),
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: () => _runSafe(context, vm.nextStation),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'إيقاف الراديو',
                iconSize: 28,
                color: Colors.white70,
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: vm.stop,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Volume Slider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  vm.volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: _gold,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: vm.volume,
                      onChanged: vm.setVolume,
                    ),
                  ),
                ),
                Text(
                  volumePercent,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(
    BuildContext context,
    RadioViewModel vm,
    RadioStation station,
    bool isDark,
  ) {
    final isSelected = vm.currentStation?.id == station.id;
    final isFav = vm.isFavorite(station.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? _emerald.withValues(alpha: 0.22)
                : const Color(0xFFEAF7F4))
            : (isDark ? const Color(0xFF172231) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? _emerald
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200),
          width: isSelected ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _toggleStation(context, vm, station),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _emerald
                      : _emerald.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: isSelected && vm.isPlaying
                    ? const _LiveSoundwaveWidget(
                        color: Colors.white,
                        height: 20,
                        barCount: 4,
                      )
                    : Icon(
                        station.category == 'tafseer'
                            ? Icons.menu_book_rounded
                            : (station.category == 'radios'
                                ? Icons.radio_rounded
                                : Icons.record_voice_over_rounded),
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.tealAccent : _emerald),
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _gold.withValues(alpha: 0.24)
                                : _emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            station.badge,
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? (isDark
                                      ? Colors.amberAccent
                                      : const Color(0xFF92400E))
                                  : (isDark ? Colors.tealAccent : _emeraldDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav
                      ? Colors.amber
                      : (isDark ? Colors.white38 : Colors.grey.shade400),
                ),
                onPressed: () => vm.toggleFavorite(station.id),
                tooltip: 'المفضلة',
              ),
              if (vm.isLoading && isSelected)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    isSelected && vm.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: isDark ? Colors.tealAccent : _emerald,
                    size: 34,
                  ),
                  onPressed: () => _toggleStation(context, vm, station),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleStation(
    BuildContext context,
    RadioViewModel vm,
    RadioStation station,
  ) async {
    await _runSafe(context, () => vm.toggleStation(station));
  }

  Future<void> _runSafe(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'عذراً، تعذر اتصال البث بهذه المحطة حالياً',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  Widget _buildCategoryChip(
    RadioViewModel vm,
    String category,
    String label,
    bool isDark,
  ) {
    final isSelected = vm.selectedCategory == category;
    final count = QuranTextFormatter.toArabicDigits(
      vm.countForCategory(category).toString(),
    );

    return ChoiceChip(
      showCheckmark: false,
      label: Text(
        '$label ($count)',
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : _emeraldDark),
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: _emerald,
      backgroundColor: isDark ? const Color(0xFF172231) : Colors.white,
      side: BorderSide(
        color: isSelected
            ? _gold
            : (isDark
                ? Colors.white12
                : _emerald.withValues(alpha: 0.2)),
      ),
      onSelected: (_) => vm.setSelectedCategory(category),
    );
  }

  Widget _buildEmptyState(RadioViewModel vm, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              vm.selectedCategory == 'favorites'
                  ? Icons.star_outline_rounded
                  : Icons.search_off_rounded,
              size: 62,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              vm.selectedCategory == 'favorites'
                  ? 'لا توجد محطات في المفضلة بعد\nانقر على النجمة ⭐ بجانب أي محطة لحفظها هنا'
                  : 'لم نجد أي نتائج مطابقة للبحث',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white60 : Colors.grey.shade700,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveSoundwaveWidget extends StatefulWidget {
  final Color color;
  final double height;
  final int barCount;

  const _LiveSoundwaveWidget({
    required this.color,
    this.height = 18,
    this.barCount = 4,
  });

  @override
  State<_LiveSoundwaveWidget> createState() => _LiveSoundwaveWidgetState();
}

class _LiveSoundwaveWidgetState extends State<_LiveSoundwaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (index) {
              final value =
                  math.sin((_animController.value * math.pi) + (index * 0.75))
                      .abs();
              final barHeight = math.max(4.0, widget.height * value);

              return Container(
                width: 3.5,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.8),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
