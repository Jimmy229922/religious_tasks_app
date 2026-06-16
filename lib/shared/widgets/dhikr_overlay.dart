import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class DhikrOverlay extends StatefulWidget {
  const DhikrOverlay({super.key});

  @override
  State<DhikrOverlay> createState() => _DhikrOverlayState();
}

class _DhikrOverlayState extends State<DhikrOverlay> {
  String _dhikr = "سبحان الله";
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startAutoCloseTimer();
    // Listen for data updates if we want to change the text dynamically
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && data is String) {
        setState(() {
          _dhikr = data;
        });
        _startAutoCloseTimer();
      }
    });
  }

  void _startAutoCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(seconds: 10), () async {
      if (mounted) {
         await FlutterOverlayWindow.closeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _dhikr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
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
                  child: const Icon(Icons.close, color: Colors.grey, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
