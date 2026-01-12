import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tasbeeh_view_model.dart';
import '../widgets/custom/tasbeeh_selector.dart';
import '../widgets/custom/tasbeeh_counter.dart';
import '../widgets/custom/tasbeeh_display.dart';

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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'إعادة التصفير',
              onPressed: vm.reset,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(gradient: background),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  TasbeehSelector(
                    items: vm.allAthkar,
                    selectedItem: vm.selectedDhikr,
                    isCustomInput: vm.isCustomInput,
                    customController: vm.customController,
                    onAddCustom: () {
                      final message = vm.addCustomDhikr();
                      if (message != null) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    },
                    onChanged: vm.selectDhikr,
                    onCustomTextChanged: vm.updateCustomText,
                  ),
                  const SizedBox(height: 30),
                  TasbeehDisplay(text: vm.selectedDhikr),
                  const Spacer(),
                  TasbeehCounter(
                    count: vm.counter,
                    onIncrement: vm.increment,
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
}
