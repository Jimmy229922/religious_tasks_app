import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/athkar_view_model.dart';
import 'athkar_details_screen.dart';

class DailyAthkarScreen extends StatefulWidget {
  const DailyAthkarScreen({super.key});

  @override
  State<DailyAthkarScreen> createState() => _DailyAthkarScreenState();
}

class _DailyAthkarScreenState extends State<DailyAthkarScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AthkarViewModel>(context, listen: false).loadDailyData();
    });
  }

  Future<void> _openAthkar(bool isMorning) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AthkarDetailsScreen(
          title: isMorning ? kAthkarMorning : kAthkarEvening,
          isMorning: isMorning,
        ),
      ),
    );
    if (!mounted) return;
    Provider.of<AthkarViewModel>(context, listen: false).loadDailyData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF0C1115) : const Color(0xFFF6F7FB);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text(
              '\u0627\u0644\u0623\u0630\u0643\u0627\u0631 \u0627\u0644\u064a\u0648\u0645\u064a\u0629'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Consumer<AthkarViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildStreakCard(context, viewModel.data),
                const SizedBox(height: 12),
                _buildEncouragementCard(context, viewModel.data),
                const SizedBox(height: 16),
                _buildAthkarCard(context, viewModel.data, isMorning: true),
                const SizedBox(height: 12),
                _buildAthkarCard(context, viewModel.data, isMorning: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, AthkarDataState data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: isDark
          ? const [Color(0xFF1C2B24), Color(0xFF0F1A16)]
          : const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    );
    final hint = data.todayComplete
        ? '\u0633\u0644\u0633\u0644\u0629 \u0645\u0633\u062a\u0645\u0631\u0629'
        : (data.streak > 0
            ? '\u0623\u0643\u0645\u0644 \u0627\u0644\u064a\u0648\u0645 \u0644\u062a\u062d\u0627\u0641\u0638 \u0639\u0644\u064a\u0647\u0627'
            : '\u0627\u0628\u062f\u0623 \u0627\u0644\u064a\u0648\u0645 \u0628\u0633\u0644\u0633\u0644\u0629 \u062c\u062f\u064a\u062f\u0629');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u0633\u0644\u0633\u0644\u0629 \u0627\u0644\u0623\u0630\u0643\u0627\u0631',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  '${data.streak}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '\u064a\u0648\u0645',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncouragementCard(BuildContext context, AthkarDataState data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF151B20) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final iconColor =
        isDark ? const Color(0xFFFFCC80) : const Color(0xFFF57C00);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.2 : 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_emotions, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.encouragement,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthkarCard(BuildContext context, AthkarDataState data,
      {required bool isMorning}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isMorning
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB));
    final surface = isDark ? const Color(0xFF151B20) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final progress = isMorning ? data.morning : data.evening;
    final label = isMorning ? kAthkarMorning : kAthkarEvening;
    final statusLabel = progress.isComplete
        ? '\u0645\u0643\u062a\u0645\u0644\u0629'
        : (progress.current > 0
            ? '\u062a\u0627\u0628\u0639'
            : '\u0627\u0628\u062f\u0623');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openAthkar(isMorning),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.22 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '\u0627\u0644\u062a\u0642\u062f\u0645: ${progress.current} / ${progress.total}',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 8,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
