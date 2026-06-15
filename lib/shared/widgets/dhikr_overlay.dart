import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class DhikrOverlay extends StatefulWidget {
  const DhikrOverlay({super.key});

  @override
  State<DhikrOverlay> createState() => _DhikrOverlayState();
}

class _DhikrOverlayState extends State<DhikrOverlay> {
  String _dhikr = "سبحان الله";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Listen for data updates if we want to change the text dynamically
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && data is String) {
        setState(() {
          _dhikr = data;
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    // Some versions of the plugin might use a different way to get initial data
    // but the listener should also receive it if shared right after showing.
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFC5A059), size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _dhikr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await FlutterOverlayWindow.closeOverlay();
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.grey, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
