import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tasbeeh_view_model.dart';
import '../widgets/custom/tasbeeh_counter.dart';

class CustomTasbeehScreen extends StatelessWidget {
  const CustomTasbeehScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TasbeehViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1D1B);
    final background = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [Color(0xFF0B1A16), Color(0xFF0F2E1A), Color(0xFF0B1320)]
          : const [Color(0xFFF7FBF6), Color(0xFFE7F1EA), Color(0xFFF3F6FF)],
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('السبحة الإلكترونية'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: textPrimary,
          actions: const [],
        ),
        body: Container(
          decoration: BoxDecoration(gradient: background),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  // TasbeehSelector is removed as per request to keep only one Dhikr
                  const SizedBox(height: 10),
                  _buildGlobalChallengeCard(vm, isDark),
                  const SizedBox(height: 30),
                  const Text(
                    'اللهم صلِّ وسلم وبارك على نبينا محمد',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const Spacer(),
                  TasbeehCounter(
                    count: vm.counter,
                    onIncrement: vm.increment,
                    isCompleted: vm.isChallengeCompleted,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalChallengeCard(TasbeehViewModel vm, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.groups_rounded, color: Colors.teal, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'تحدي المليون تسبيحة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(vm.globalProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: vm.globalProgress,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'وصلنا إلى: ${vm.globalCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'الهدف القادم: ${vm.currentMilestone}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (vm.achievedMilestones.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: vm.achievedMilestones.reversed.map((milestone) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          milestone >= 1000000
                              ? '${(milestone / 1000000).toStringAsFixed(0)}M'
                              : milestone >= 1000
                                  ? '${(milestone / 1000).toStringAsFixed(0)}K'
                                  : milestone.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (vm.isChallengeCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'تم تحقيق الهدف المليون! جزاكم الله خيراً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
