import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:religious_tasks_app/shared/services/audio/radio_service.dart';

class RadioViewModel extends ChangeNotifier {
  static const String _favoritesKey = 'favorite_radio_stations';

  final RadioService _radioService = RadioService();
  RadioStation? _currentStation;
  bool _isLoading = false;

  // Search, Categories & Favorites State
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'favorites', 'radios', 'reciters', 'tafseer'
  List<String> _favoriteStationIds = [];

  // Sleep Timer State
  Timer? _sleepTimer;
  Timer? _countdownTicker;
  Duration? _remainingSleepTime;

  RadioViewModel() {
    _loadFavorites();
    _radioService.player.playerStateStream.listen((state) {
      _handleOverlay();
      notifyListeners();
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteStationIds = prefs.getStringList(_favoritesKey) ?? [];
    notifyListeners();
  }

  Future<void> toggleFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favoriteStationIds.contains(stationId)) {
      _favoriteStationIds.remove(stationId);
    } else {
      _favoriteStationIds.add(stationId);
    }
    await prefs.setStringList(_favoritesKey, _favoriteStationIds);
    notifyListeners();
  }

  bool isFavorite(String stationId) => _favoriteStationIds.contains(stationId);

  // Search and Category Filter
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<RadioStation> get filteredStations {
    return RadioService.stations.where((station) {
      final matchesSearch = _searchQuery.isEmpty ||
          station.title.contains(_searchQuery) ||
          station.category.contains(_searchQuery);

      if (!matchesSearch) return false;

      if (_selectedCategory == 'favorites') {
        return isFavorite(station.id);
      } else if (_selectedCategory != 'all') {
        return station.category == _selectedCategory;
      }

      return true;
    }).toList();
  }

  // Sleep Timer Methods
  Duration? get remainingSleepTime => _remainingSleepTime;

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _countdownTicker?.cancel();

    if (duration == null || duration <= Duration.zero) {
      _remainingSleepTime = null;
      notifyListeners();
      return;
    }

    _remainingSleepTime = duration;
    notifyListeners();

    _sleepTimer = Timer(duration, () async {
      await stop();
      _remainingSleepTime = null;
      _countdownTicker?.cancel();
      notifyListeners();
    });

    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSleepTime == null || _remainingSleepTime! <= Duration.zero) {
        timer.cancel();
      } else {
        _remainingSleepTime = _remainingSleepTime! - const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  String get formattedRemainingSleepTime {
    if (_remainingSleepTime == null) return '';
    final minutes = _remainingSleepTime!.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remainingSleepTime!.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleOverlay() async {
    if (isPlaying) {
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        await FlutterOverlayWindow.requestPermission();
        return;
      }

      final bool isRunning = await FlutterOverlayWindow.isActive();
      if (!isRunning) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          flag: OverlayFlag.defaultFlag,
          width: 120,
          height: 120,
          alignment: OverlayAlignment.centerRight,
        );
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        FlutterOverlayWindow.shareData("RADIO_MODE");
      });
    } else {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  RadioStation? get currentStation => _currentStation;
  bool get isLoading =>
      _isLoading ||
      playerState.processingState == ProcessingState.loading ||
      playerState.processingState == ProcessingState.buffering;
  bool get isPlaying => _radioService.player.playing;
  PlayerState get playerState => _radioService.player.playerState;

  Future<void> toggleStation(RadioStation station) async {
    if (_currentStation?.id == station.id && isPlaying) {
      await _radioService.pause();
    } else {
      try {
        _isLoading = true;
        _currentStation = station;
        notifyListeners();
        await _radioService.playStation(station);
      } catch (e) {
        debugPrint("Error in toggleStation: $e");
        _isLoading = false;
        _currentStation = null;
        notifyListeners();
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    await _radioService.stop();
    _currentStation = null;
    setSleepTimer(null);
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _countdownTicker?.cancel();
    super.dispose();
  }
}
