import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MushafReaderTheme {
  final Color headerBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color actionIcon;
  final Color activeBookmark;
  final Color divider;
  final Color indicatorBackground;
  final Color indicatorBorder;
  final Color indicatorPrimaryText;
  final Color indicatorAccent;
  final Color chipStripBackground;
  final Color chipUnselectedBackground;
  final Color chipSelectedBackground;
  final SystemUiOverlayStyle statusBarOverlayStyle;

  const MushafReaderTheme({
    required this.headerBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.actionIcon,
    required this.activeBookmark,
    required this.divider,
    required this.indicatorBackground,
    required this.indicatorBorder,
    required this.indicatorPrimaryText,
    required this.indicatorAccent,
    required this.chipStripBackground,
    required this.chipUnselectedBackground,
    required this.chipSelectedBackground,
    required this.statusBarOverlayStyle,
  });

  static const MushafReaderTheme light = MushafReaderTheme(
    headerBackground: Color(0xD9F5EFE3),
    primaryText: Color(0xFF382C20),
    secondaryText: Color(0xFF7E6C56),
    actionIcon: Color(0xFF6B4A20),
    activeBookmark: Color(0xFFA47B32),
    divider: Color(0xFFD6C3A5),
    indicatorBackground: Color(0xFFFFF9ED),
    indicatorBorder: Color(0xFFC9A86A),
    indicatorPrimaryText: Color(0xFF382C20),
    indicatorAccent: Color(0xFFA47B32),
    chipStripBackground: Color(0xD4EDE4D3),
    chipUnselectedBackground: Color(0xFFFFF9ED),
    chipSelectedBackground: Color(0xFFA47B32),
    statusBarOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  static const MushafReaderTheme dark = MushafReaderTheme(
    headerBackground: Color(0xD9121A22),
    primaryText: Color(0xFFF5EBD8),
    secondaryText: Color(0xFFB7A992),
    actionIcon: Color(0xFFDFC38A),
    activeBookmark: Color(0xFFE0B85C),
    divider: Color(0xFF45505A),
    indicatorBackground: Color(0xFF202A32),
    indicatorBorder: Color(0xFFA9894C),
    indicatorPrimaryText: Color(0xFFF5EBD8),
    indicatorAccent: Color(0xFFE0B85C),
    chipStripBackground: Color(0xD418222C),
    chipUnselectedBackground: Color(0xFF202A32),
    chipSelectedBackground: Color(0xFFA9894C),
    statusBarOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  static MushafReaderTheme of(bool isDark) => isDark ? dark : light;
}
