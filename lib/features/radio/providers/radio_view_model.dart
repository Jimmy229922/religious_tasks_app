import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:religious_tasks_app/shared/services/audio/radio_service.dart';

class RadioViewModel extends ChangeNotifier {
  static const String _favoritesKey = 'favorite_radio_stations';
  static const String _recentKey = 'recent_radio_stations_v1';
  static const String _volumeKey = 'radio_volume_v1';

  final RadioService _radioService = RadioService();
  RadioStation? _currentStation;
  bool _isLoading = false;

  // Search, Categories, Favorites, Recents & Volume State
  String _searchQuery = '';
  String _selectedCategory =
      'all'; // 'all', 'favorites', 'radios', 'reciters', 'tafseer'
  List<String> _favoriteStationIds = [];
  List<String> _recentStationIds = [];
  double _volume = 1.0;
  String? _currentIcyTitle;
  String? _errorMessage;

  // Sleep Timer State
  Timer? _sleepTimer;
  Timer? _countdownTicker;
  Duration? _remainingSleepTime;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<IcyMetadata?>? _icySubscription;
  Future<void> _overlayOperation = Future<void>.value();
  int _overlayGeneration = 0;
  bool _isDisposed = false;

  RadioViewModel() {
    _loadPrefs();
    try {
      _playerStateSubscription =
          _radioService.player.playerStateStream.listen((state) {
        final generation = ++_overlayGeneration;
        _overlayOperation = _overlayOperation
            .then((_) => _handleOverlay(generation))
            .catchError((Object error) {
          debugPrint('Error updating radio overlay: $error');
        });
        notifyListeners();
      });

      _icySubscription = _radioService.icyMetadataStream.listen((metadata) {
        final title = metadata?.info?.title?.trim();
        final normalized = (title != null && title.isNotEmpty) ? title : null;
        if (normalized != _currentIcyTitle) {
          _currentIcyTitle = normalized;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Radio stream listener init skipped: $e');
    }
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favoriteStationIds = prefs.getStringList(_favoritesKey) ?? [];
      _recentStationIds = prefs.getStringList(_recentKey) ?? [];
      _volume = (prefs.getDouble(_volumeKey) ?? 1.0).clamp(0.0, 1.0);
      await _radioService.setVolume(_volume);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavorite(String stationId) async {
    if (_favoriteStationIds.contains(stationId)) {
      _favoriteStationIds.remove(stationId);
    } else {
      _favoriteStationIds.add(stationId);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteStationIds);
    } catch (_) {}
  }

  Future<void> _recordRecent(String stationId) async {
    _recentStationIds.remove(stationId);
    _recentStationIds.insert(0, stationId);
    if (_recentStationIds.length > 6) {
      _recentStationIds = _recentStationIds.take(6).toList();
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentKey, _recentStationIds);
    } catch (_) {}
  }

  Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    _volume = clamped;
    notifyListeners();
    try {
      await _radioService.setVolume(clamped);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumeKey, clamped);
    } catch (_) {}
  }

  bool isFavorite(String stationId) => _favoriteStationIds.contains(stationId);

  List<RadioStation> get recentStations {
    final stationsById = {
      for (final s in RadioService.stations) s.id: s,
    };
    return _recentStationIds
        .map((id) => stationsById[id])
        .whereType<RadioStation>()
        .toList();
  }

  double get volume => _volume;
  String? get currentIcyTitle => _currentIcyTitle;
  String? get errorMessage => _errorMessage;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

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

  int countForCategory(String category) {
    if (category == 'all') return RadioService.stations.length;
    if (category == 'favorites') return _favoriteStationIds.length;
    return RadioService.stations
        .where((s) => s.category == category)
        .length;
  }

  List<RadioStation> get filteredStations {
    final query = _searchQuery.trim().toLowerCase();
    return RadioService.stations.where((station) {
      final matchesSearch = query.isEmpty ||
          station.title.toLowerCase().contains(query) ||
          station.subtitle.toLowerCase().contains(query) ||
          station.badge.toLowerCase().contains(query) ||
          station.category.toLowerCase().contains(query);

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
      if (_remainingSleepTime == null ||
          _remainingSleepTime! <= Duration.zero) {
        timer.cancel();
      } else {
        _remainingSleepTime =
            _remainingSleepTime! - const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  String get formattedRemainingSleepTime {
    if (_remainingSleepTime == null) return '';
    final minutes = _remainingSleepTime!.inMinutes.toString().padLeft(2, '0');
    final seconds =
        (_remainingSleepTime!.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleOverlay(int generation) async {
    bool isStale() => _isDisposed || generation != _overlayGeneration;

    if (isStale()) return;
    if (isPlaying) {
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        return;
      }
      if (isStale() || !isPlaying) return;

      final bool isRunning = await FlutterOverlayWindow.isActive();
      if (isStale() || !isPlaying) return;
      if (!isRunning) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          flag: OverlayFlag.defaultFlag,
          width: 120,
          height: 120,
          alignment: OverlayAlignment.centerRight,
        );
      }
      if (isStale() || !isPlaying) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (isStale() || !isPlaying) return;
      await FlutterOverlayWindow.shareData("RADIO_MODE");
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
    _errorMessage = null;
    if (_currentStation?.id == station.id && isPlaying) {
      await _radioService.pause();
      notifyListeners();
    } else {
      try {
        _isLoading = true;
        _currentStation = station;
        _currentIcyTitle = null;
        notifyListeners();
        await _radioService.playStation(station);
        await _recordRecent(station.id);
      } catch (e) {
        debugPrint("Error in toggleStation: $e");
        _isLoading = false;
        _currentStation = null;
        _errorMessage = 'تعذر الاتصال بالبث المباشر للمحطة، حاول مرة أخرى';
        notifyListeners();
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> resumeLastOrDefaultStation() async {
    final target = _currentStation ??
        (recentStations.isNotEmpty
            ? recentStations.first
            : RadioService.stations.first);
    await toggleStation(target);
  }

  Future<void> nextStation() async {
    final pool = filteredStations.isNotEmpty
        ? filteredStations
        : RadioService.stations;
    if (pool.isEmpty) return;
    final idx = _currentStation == null
        ? -1
        : pool.indexWhere((s) => s.id == _currentStation!.id);
    final next = pool[(idx + 1) % pool.length];
    await toggleStation(next);
  }

  Future<void> previousStation() async {
    final pool = filteredStations.isNotEmpty
        ? filteredStations
        : RadioService.stations;
    if (pool.isEmpty) return;
    final idx = _currentStation == null
        ? 0
        : pool.indexWhere((s) => s.id == _currentStation!.id);
    final prevIdx = idx <= 0 ? pool.length - 1 : idx - 1;
    await toggleStation(pool[prevIdx]);
  }

  Future<void> stop() async {
    await _radioService.stop();
    _currentStation = null;
    _currentIcyTitle = null;
    setSleepTimer(null);
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sleepTimer?.cancel();
    _countdownTicker?.cancel();
    _playerStateSubscription?.cancel();
    _icySubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
