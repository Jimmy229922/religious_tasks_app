import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/radio_view_model.dart';
import 'package:religious_tasks_app/shared/services/audio/radio_service.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "راديو القرآن الكريم",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer<RadioViewModel>(
          builder: (context, vm, child) {
            return Column(
              children: [
                _buildCurrentPlayingCard(vm, isDark),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.radio, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        "المحطات المتاحة",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: RadioService.stations.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final station = RadioService.stations[index];
                      final isSelected = vm.currentStation?.id == station.id;
                      
                      return Card(
                        elevation: isSelected ? 4 : 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected 
                            ? const BorderSide(color: Colors.teal, width: 2)
                            : BorderSide.none,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.withValues(alpha: 0.1),
                            child: Icon(
                              isSelected && vm.isPlaying 
                                ? Icons.graphic_eq 
                                : Icons.radio_outlined,
                              color: Colors.teal,
                            ),
                          ),
                          title: Text(
                            station.title,
                            style: GoogleFonts.cairo(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: vm.isLoading && isSelected
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  isSelected && vm.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.teal,
                                  size: 32,
                                ),
                          onTap: () async {
                            try {
                              await vm.toggleStation(station);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("عذراً، تعذر تشغيل هذه المحطة حالياً")),
                                );
                              }
                            }
                          },
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

  Widget _buildCurrentPlayingCard(RadioViewModel vm, bool isDark) {
    if (vm.currentStation == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.teal.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.radio, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              "اختر محطة للبدء في الاستماع",
              style: GoogleFonts.cairo(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1a2a6c), const Color(0xFFb21f1f)]
            : [Colors.teal, Colors.teal.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            "بث مباشر",
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            vm.currentStation!.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 64,
                color: Colors.white,
                icon: Icon(
                  vm.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                ),
                onPressed: () => vm.toggleStation(vm.currentStation!),
              ),
              IconButton(
                iconSize: 32,
                color: Colors.white70,
                icon: const Icon(Icons.stop_circle),
                onPressed: () => vm.stop(),
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
