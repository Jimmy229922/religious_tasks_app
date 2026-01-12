import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:religious_tasks_app/core/constants/app_constants.dart';
import '../providers/athkar_view_model.dart';
import 'athkar_details_screen.dart';
import '../widgets/daily/athkar_streak_card.dart';
import '../widgets/daily/athkar_encouragement_card.dart';
import '../widgets/daily/daily_athkar_card.dart';

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
          title: const Text('الأذكار اليومية'),
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
                AthkarStreakCard(data: viewModel.data),
                const SizedBox(height: 12),
                AthkarEncouragementCard(data: viewModel.data),
                const SizedBox(height: 16),
                DailyAthkarCard(
                  data: viewModel.data,
                  isMorning: true,
                  onTap: () => _openAthkar(true),
                ),
                const SizedBox(height: 12),
                DailyAthkarCard(
                  data: viewModel.data,
                  isMorning: false,
                  onTap: () => _openAthkar(false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
