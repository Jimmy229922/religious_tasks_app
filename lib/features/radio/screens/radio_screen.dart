import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/radio_view_model.dart';
import 'package:religious_tasks_app/shared/services/audio/radio_service.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSleepTimerDialog(BuildContext context, RadioViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "مؤقت النوم 🌙",
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.teal.shade900,
                    ),
                  ),
                  if (vm.remainingSleepTime != null)
                    TextButton.icon(
                      onPressed: () {
                        vm.setSleepTimer(null);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.timer_off_rounded, color: Colors.red),
                      label: const Text("إلغاء المؤقت", style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "سيتم إيقاف تشغيل الراديو تلقائياً بعد انقضاء الوقت المحدد:",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildTimerOption(ctx, vm, "15 دقيقة", const Duration(minutes: 15)),
                  _buildTimerOption(ctx, vm, "30 دقيقة", const Duration(minutes: 30)),
                  _buildTimerOption(ctx, vm, "45 دقيقة", const Duration(minutes: 45)),
                  _buildTimerOption(ctx, vm, "ساعة كاملة", const Duration(hours: 1)),
                  _buildTimerOption(ctx, vm, "ساعتان", const Duration(hours: 2)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerOption(
      BuildContext context, RadioViewModel vm, String label, Duration duration) {
    final isSelected = vm.remainingSleepTime != null &&
        (vm.remainingSleepTime!.inMinutes - duration.inMinutes).abs() < 1;

    return ActionChip(
      avatar: Icon(Icons.timer_rounded,
          size: 18, color: isSelected ? Colors.white : Colors.teal),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.teal.shade900,
        ),
      ),
      backgroundColor: isSelected ? Colors.teal : Colors.teal.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: () {
        vm.setSleepTimer(duration);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم ضبط مؤقت النوم على $label"),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "راديو القرآن الكريم",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          Consumer<RadioViewModel>(
            builder: (context, vm, _) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: vm.remainingSleepTime != null,
                  label: Text(vm.formattedRemainingSleepTime, style: const TextStyle(fontSize: 10)),
                  child: const Icon(Icons.bedtime_rounded),
                ),
                tooltip: "مؤقت النوم",
                onPressed: () => _showSleepTimerDialog(context, vm),
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer<RadioViewModel>(
          builder: (context, vm, child) {
            final stations = vm.filteredStations;

            return Column(
              children: [
                // Top Hero Player Card
                _buildCurrentPlayingCard(context, vm, isDark),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => vm.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: "ابحث باسم القارئ أو الإذاعة...",
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                vm.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
                ),

                // Filter Categories Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildCategoryChip(vm, 'all', 'الكل 📻'),
                      const SizedBox(width: 8),
                      _buildCategoryChip(vm, 'favorites', 'المفضلة ⭐'),
                      const SizedBox(width: 8),
                      _buildCategoryChip(vm, 'radios', 'الإذاعات 🎙️'),
                      const SizedBox(width: 8),
                      _buildCategoryChip(vm, 'reciters', 'أشهر القراء 👤'),
                      const SizedBox(width: 8),
                      _buildCategoryChip(vm, 'tafseer', 'التفسير والعلوم 📖'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Stations List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_outlined, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "المحطات المتاحة (${stations.length})",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Stations List View
                Expanded(
                  child: stations.isEmpty
                      ? _buildEmptyState(vm, isDark)
                      : ListView.builder(
                          itemCount: stations.length,
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final station = stations[index];
                            final isSelected = vm.currentStation?.id == station.id;
                            final isFav = vm.isFavorite(station.id);

                            return Card(
                              elevation: isSelected ? 4 : 1,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isSelected
                                    ? const BorderSide(color: Colors.teal, width: 2)
                                    : BorderSide.none,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? Colors.teal
                                      : Colors.teal.withValues(alpha: 0.12),
                                  child: isSelected && vm.isPlaying
                                      ? const _LiveSoundwaveWidget(color: Colors.white)
                                      : Icon(
                                          Icons.radio_rounded,
                                          color: isSelected ? Colors.white : Colors.teal,
                                          size: 22,
                                        ),
                                ),
                                title: Text(
                                  station.title,
                                  style: GoogleFonts.cairo(
                                    fontWeight:
                                        isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: isFav ? Colors.amber : Colors.grey,
                                      ),
                                      onPressed: () => vm.toggleFavorite(station.id),
                                      tooltip: "المفضلة",
                                    ),
                                    const SizedBox(width: 4),
                                    if (vm.isLoading && isSelected)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.5),
                                      )
                                    else
                                      IconButton(
                                        icon: Icon(
                                          isSelected && vm.isPlaying
                                              ? Icons.pause_circle_filled_rounded
                                              : Icons.play_circle_fill_rounded,
                                          color: Colors.teal,
                                          size: 36,
                                        ),
                                        onPressed: () => _toggleStation(context, vm, station),
                                      ),
                                  ],
                                ),
                                onTap: () => _toggleStation(context, vm, station),
                              ),
                            );
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

  Future<void> _toggleStation(
      BuildContext context, RadioViewModel vm, RadioStation station) async {
    try {
      await vm.toggleStation(station);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("عذراً، تعذر اتصال البث بهذه المحطة حالياً")),
        );
      }
    }
  }

  Widget _buildCategoryChip(RadioViewModel vm, String category, String label) {
    final isSelected = vm.selectedCategory == category;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.teal.shade900,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.teal,
      backgroundColor: Colors.teal.withValues(alpha: 0.1),
      onSelected: (_) => vm.setSelectedCategory(category),
    );
  }

  Widget _buildEmptyState(RadioViewModel vm, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              vm.selectedCategory == 'favorites'
                  ? Icons.star_outline_rounded
                  : Icons.search_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              vm.selectedCategory == 'favorites'
                  ? "لا توجد محطات في المفضلة بعد\nانقر على النجمة ⭐ بجانب أي محطة لإضافتها هنا"
                  : "لم نجد أي نتائج مطابقة للبحث",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white60 : Colors.grey[700],
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlayingCard(
      BuildContext context, RadioViewModel vm, bool isDark) {
    final currentStation = vm.currentStation;

    if (currentStation == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.teal.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.radio_outlined, size: 48, color: Colors.teal),
            const SizedBox(height: 10),
            Text(
              "اختر محطة للبدء في الاستماع إلى القرآن الكريم 🎧",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white70 : Colors.teal.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final isFav = vm.isFavorite(currentStation.id);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F2027), Color(0xFF2C5364)]
              : [const Color(0xFF0F766E), const Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: vm.isPlaying ? Colors.red : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (vm.isPlaying)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.fiber_manual_record,
                            size: 10, color: Colors.white),
                      ),
                    Text(
                      vm.isPlaying ? "بث مباشر LIVE 🔴" : "متوقف",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFav ? Colors.amber : Colors.white70,
                    ),
                    onPressed: () => vm.toggleFavorite(currentStation.id),
                    tooltip: "المفضلة",
                  ),
                  IconButton(
                    icon: const Icon(Icons.bedtime_outlined, color: Colors.white70),
                    onPressed: () => _showSleepTimerDialog(context, vm),
                    tooltip: "مؤقت النوم",
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            currentStation.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (vm.formattedRemainingSleepTime.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "إيقاف بعد: ${vm.formattedRemainingSleepTime}",
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            height: 28,
            child: vm.isPlaying
                ? const _LiveSoundwaveWidget(color: Colors.white, height: 28)
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 60,
                color: Colors.white,
                icon: Icon(
                  vm.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                ),
                onPressed: () => _toggleStation(context, vm, currentStation),
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 36,
                color: Colors.white70,
                icon: const Icon(Icons.stop_circle_rounded),
                onPressed: () => vm.stop(),
                tooltip: "إيقاف الراديو",
              ),
            ],
          ),

          if (vm.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveSoundwaveWidget extends StatefulWidget {
  final Color color;
  final double height;

  const _LiveSoundwaveWidget({
    required this.color,
    this.height = 18,
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
      duration: const Duration(milliseconds: 600),
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
            children: List.generate(4, (index) {
              final value = math.sin((_animController.value * math.pi) + (index * 0.8)).abs();
              final barHeight = math.max(4.0, widget.height * value);

              return Container(
                width: 3.5,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
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
