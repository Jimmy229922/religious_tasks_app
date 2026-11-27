import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:religious_tasks_app/core/services/location_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/mosques/services/nearby_mosques_service.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';

class NearbyMosquesScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const NearbyMosquesScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFFDE68A);
  static const List<int> _radiusOptions = [1500, 3000, 5000, 10000];

  final NearbyMosquesService _mosquesService = NearbyMosquesService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  double _latitude = 30.0444;
  double _longitude = 31.2357;
  String _locationName = 'جاري تحديد الموقع...';
  int _selectedRadiusMeters = 3000;
  bool _isSatellite = false;
  bool _isLoading = true;
  bool _isRefreshingGps = false;
  String? _errorMessage;
  String _searchQuery = '';
  double _currentZoom = 14.6;
  int _fetchGeneration = 0;

  List<NearbyMosque> _mosques = [];
  NearbyMosque? _selectedMosque;

  @override
  void initState() {
    super.initState();
    _initLocationAndLoad();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndLoad() async {
    final vm = context.read<TasksViewModel>();
    final vmCoords = vm.prayerTimes?.coordinates;
    final hasInitialCoords =
        (widget.initialLatitude != null && widget.initialLongitude != null) ||
            vmCoords != null;
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _latitude = widget.initialLatitude!;
      _longitude = widget.initialLongitude!;
    } else if (vmCoords != null) {
      _latitude = vmCoords.latitude;
      _longitude = vmCoords.longitude;
    }

    final vmLoc = vm.locationName.trim();
    if (vmLoc.isNotEmpty &&
        !vmLoc.contains('تعذر') &&
        !vmLoc.contains('غير معروف')) {
      _locationName = vmLoc;
    }

    final cached = await _mosquesService.loadCachedMosques(
      userLat: _latitude,
      userLng: _longitude,
    );
    if (mounted && cached.isNotEmpty) {
      setState(() {
        _mosques = cached;
        _selectedMosque = cached.first;
        _isLoading = false;
      });
    }

    if (hasInitialCoords) {
      unawaited(_fetchMosques());
    }
    await _refreshLocationAndMosques(
      requestPermission: false,
      fetchEvenIfUnchanged: !hasInitialCoords,
    );
  }

  Future<void> _refreshLocationAndMosques({
    bool requestPermission = true,
    bool fetchEvenIfUnchanged = true,
  }) async {
    if (_isRefreshingGps) return;
    setState(() {
      _isRefreshingGps = true;
      if (_mosques.isEmpty && fetchEvenIfUnchanged) _isLoading = true;
      _errorMessage = null;
    });

    double movedMeters = 0;
    try {
      final res = await LocationService().getHighAccuracyPosition(
        requestPermission: requestPermission,
      );
      if (!mounted) return;
      if (res.position != null) {
        final pos = res.position!;
        movedMeters = Geolocator.distanceBetween(
          _latitude,
          _longitude,
          pos.latitude,
          pos.longitude,
        );
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        unawaited(
          LocationService().getLocationName(pos).then((name) {
            if (mounted &&
                name.trim().isNotEmpty &&
                !name.contains('تعذر') &&
                !name.contains('غير معروف')) {
              setState(() => _locationName = name);
            }
          }),
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isRefreshingGps = false);
      _moveMapTo(LatLng(_latitude, _longitude), zoom: _zoomForRadius());
      if (fetchEvenIfUnchanged || movedMeters > 150.0) {
        await _fetchMosques();
      }
    }
  }

  double _zoomForRadius() {
    switch (_selectedRadiusMeters) {
      case 1500:
        return 15.2;
      case 3000:
        return 14.2;
      case 5000:
        return 13.3;
      case 10000:
      default:
        return 12.2;
    }
  }

  Future<void> _fetchMosques() async {
    if (!mounted) return;
    final gen = ++_fetchGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await _mosquesService.fetchNearbyMosques(
        latitude: _latitude,
        longitude: _longitude,
        radiusMeters: _selectedRadiusMeters,
      );
      if (!mounted || gen != _fetchGeneration) return;
      setState(() {
        _mosques = fetched;
        _selectedMosque = fetched.isNotEmpty ? fetched.first : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || gen != _fetchGeneration) return;
      setState(() {
        _isLoading = false;
        if (_mosques.isEmpty) {
          _errorMessage =
              'تعذر جلب قائمة المساجد من الخادم الآن. يمكنك المحاولة مجدداً أو فتح خرائط جوجل مباشرة.';
        }
      });
    }
  }

  void _moveMapTo(LatLng target, {double? zoom}) {
    try {
      final nextZoom = zoom ?? _currentZoom;
      _currentZoom = nextZoom;
      _mapController.move(target, nextZoom);
    } catch (_) {}
  }

  void _fitAllMarkers() {
    final points = <LatLng>[
      LatLng(_latitude, _longitude),
      ..._filteredMosques
          .take(15)
          .map((m) => LatLng(m.latitude, m.longitude)),
    ];
    if (points.length <= 1) {
      _moveMapTo(LatLng(_latitude, _longitude), zoom: _zoomForRadius());
      return;
    }
    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(42)),
      );
    } catch (_) {}
  }

  Future<void> _openGoogleMapsDirections(NearbyMosque mosque) async {
    final encodedName = Uri.encodeComponent(mosque.name);
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${mosque.latitude},${mosque.longitude}&destination_place_id=$encodedName&travelmode=walking',
    );
    final fallbackUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${mosque.latitude},${mosque.longitude}',
    );
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تعذر فتح تطبيق الخرائط على هذا الجهاز',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }

  Future<void> _openAllMosquesInGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/%D9%85%D8%B3%D8%AC%D8%AF/@$_latitude,$_longitude,15z',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  List<NearbyMosque> get _filteredMosques {
    if (_searchQuery.isEmpty) return _mosques;
    return _mosques
        .where((m) =>
            m.name.contains(_searchQuery) || m.address.contains(_searchQuery))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    final visibleMosques = _filteredMosques;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.appScaffoldBg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.appBgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isDark, accent),
                        const SizedBox(height: 12),
                        _buildLocationAndControlsCard(isDark, accent),
                        const SizedBox(height: 12),
                        _buildInteractiveMapCard(
                          isDark,
                          accent,
                          visibleMosques,
                        ),
                        const SizedBox(height: 12),
                        _buildSearchField(isDark),
                        const SizedBox(height: 12),
                        _buildResultsHeader(isDark, accent, visibleMosques.length),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (_isLoading && _mosques.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: isDark ? _goldLight : accent,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'جاري البحث عن المساجد القريبة من موقعك...',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_errorMessage != null && visibleMosques.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildEmptyOrErrorCard(
                        isDark: isDark,
                        accent: accent,
                        message: _errorMessage!,
                        isError: true,
                      ),
                    ),
                  )
                else if (visibleMosques.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildEmptyOrErrorCard(
                        isDark: isDark,
                        accent: accent,
                        message: _searchQuery.isNotEmpty
                            ? 'لم نجد مساجد مطابقة لـ "$_searchQuery" ضمن هذا النطاق.'
                            : 'لم نعثر على مساجد مسجلة في هذا النطاق. جرّب توسيع نطاق البحث أو الفتح في خرائط جوجل.',
                        isError: false,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final mosque = visibleMosques[index];
                          final isSelected = _selectedMosque?.id == mosque.id;
                          return _buildMosqueCard(
                            mosque: mosque,
                            index: index,
                            isSelected: isSelected,
                            isDark: isDark,
                            accent: accent,
                          );
                        },
                        childCount: visibleMosques.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0A241D), Color(0xFF0F2D24)]
              : const [Color(0xFFFFFDF7), Color(0xFFF6EED9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
          bottom: Radius.circular(20),
        ),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.5 : 0.7),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          _buildCircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'رجوع',
            isDark: isDark,
            accent: accent,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'المساجد القريبة',
                  style: GoogleFonts.cairo(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: isDark ? _goldLight : context.primaryDarkColor,
                  ),
                ),
                Text(
                  _locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          _buildCircleBtn(
            icon: _isRefreshingGps
                ? Icons.hourglass_top_rounded
                : Icons.my_location_rounded,
            tooltip: 'تحديث موقعي',
            isDark: isDark,
            accent: accent,
            onTap: () => _refreshLocationAndMosques(requestPermission: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.9),
            border: Border.all(
              color: _gold.withValues(alpha: isDark ? 0.45 : 0.6),
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: isDark ? _goldLight : accent,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationAndControlsCard(bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.appCardGradient,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.42 : 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.radar_rounded,
                size: 18,
                color: isDark ? _goldLight : accent,
              ),
              const SizedBox(width: 6),
              Text(
                'نطاق البحث حول موقعك:',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? _goldLight : context.primaryDarkColor,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _openAllMosquesInGoogleMaps,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 13,
                        color: isDark ? _goldLight : accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'خرائط جوجل',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? _goldLight : accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: _radiusOptions.map((radius) {
              final selected = _selectedRadiusMeters == radius;
              final kmLabel = radius == 1500
                  ? '١.٥ كم'
                  : '${QuranTextFormatter.toArabicDigits((radius ~/ 1000).toString())} كم';
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: radius == _radiusOptions.last ? 0 : 6,
                  ),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (_selectedRadiusMeters == radius) return;
                      setState(() => _selectedRadiusMeters = radius);
                      _moveMapTo(
                        LatLng(_latitude, _longitude),
                        zoom: _zoomForRadius(),
                      );
                      _fetchMosques();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(
                                colors: isDark
                                    ? const [
                                        Color(0xFF92400E),
                                        Color(0xFFD4AF37),
                                      ]
                                    : const [
                                        Color(0xFFFDE68A),
                                        Color(0xFFE5B84B),
                                      ],
                              )
                            : null,
                        color: selected
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white.withValues(alpha: 0.85)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? _gold
                              : _gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          kmLabel,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? (isDark
                                    ? Colors.white
                                    : const Color(0xFF451A03))
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMapCard(
    bool isDark,
    Color accent,
    List<NearbyMosque> visibleMosques,
  ) {
    final userLatLng = LatLng(_latitude, _longitude);
    final selected = _selectedMosque;
    final tileUrl = _isSatellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.appCardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.5 : 0.7),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : _gold).withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 18,
                  color: isDark ? _goldLight : accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selected != null
                        ? 'المحدد: ${selected.name} (${selected.formattedDistanceArabic})'
                        : 'خريطة المساجد القريبة',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? _goldLight : context.primaryDarkColor,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isSatellite = !_isSatellite);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: isDark ? 0.18 : 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _gold.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.layers_rounded,
                          size: 13,
                          color: isDark ? _goldLight : const Color(0xFF78350F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isSatellite ? 'قمر صناعي' : 'خريطة عادية',
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? _goldLight
                                : const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 280,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: userLatLng,
                        initialZoom: _currentZoom,
                        minZoom: 3.0,
                        maxZoom: 18.5,
                        onPositionChanged: (pos, _) {
                          _currentZoom = pos.zoom;
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: tileUrl,
                          userAgentPackageName: 'com.jimmy.religiousapp',
                          errorTileCallback: (_, __, ___) {},
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: userLatLng,
                              radius: _selectedRadiusMeters.toDouble(),
                              useRadiusInMeter: true,
                              color: accent.withValues(alpha: 0.08),
                              borderColor: _gold.withValues(alpha: 0.55),
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),
                        if (selected != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [
                                  userLatLng,
                                  LatLng(selected.latitude, selected.longitude),
                                ],
                                strokeWidth: 3.4,
                                color: _gold,
                                borderStrokeWidth: 1.2,
                                borderColor: const Color(0xFF041D16),
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            ...visibleMosques.map((mosque) {
                              final isActive = selected?.id == mosque.id;
                              return Marker(
                                point:
                                    LatLng(mosque.latitude, mosque.longitude),
                                width: isActive ? 44 : 36,
                                height: isActive ? 44 : 36,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedMosque = mosque);
                                    _moveMapTo(
                                      LatLng(mosque.latitude, mosque.longitude),
                                      zoom: _currentZoom < 15.0
                                          ? 15.5
                                          : _currentZoom,
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? _gold
                                          : const Color(0xFF065F46),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: isActive ? 2.6 : 2.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.mosque_rounded,
                                      size: isActive ? 22 : 17,
                                      color: isActive
                                          ? const Color(0xFF041D16)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            Marker(
                              point: userLatLng,
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Column(
                        children: [
                          _buildMapActionBtn(
                            icon: Icons.add,
                            tooltip: 'تكبير',
                            isDark: isDark,
                            onTap: () => _moveMapTo(
                              _mapController.camera.center,
                              zoom: (_currentZoom + 1.0).clamp(3.0, 18.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildMapActionBtn(
                            icon: Icons.remove,
                            tooltip: 'تصغير',
                            isDark: isDark,
                            onTap: () => _moveMapTo(
                              _mapController.camera.center,
                              zoom: (_currentZoom - 1.0).clamp(3.0, 18.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildMapActionBtn(
                            icon: Icons.my_location_rounded,
                            tooltip: 'موقعي',
                            isDark: isDark,
                            onTap: () => _moveMapTo(
                              userLatLng,
                              zoom: _zoomForRadius(),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildMapActionBtn(
                            icon: Icons.fit_screen_rounded,
                            tooltip: 'عرض الكل',
                            isDark: isDark,
                            onTap: _fitAllMarkers,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionBtn({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0A241D).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold.withValues(alpha: 0.65)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? _goldLight : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0E211E), Color(0xFF0A171C)]
              : const [Color(0xFFFFFDF8), Color(0xFFF8F0DB)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.42 : 0.6),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: GoogleFonts.cairo(
          fontSize: 13.5,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'ابحث باسم المسجد أو الشارع...',
          hintStyle: GoogleFonts.cairo(
            fontSize: 12.5,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? _goldLight : context.primaryColor,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(bool isDark, Color accent, int count) {
    return Row(
      children: [
        Icon(
          Icons.mosque_rounded,
          size: 18,
          color: isDark ? _goldLight : accent,
        ),
        const SizedBox(width: 6),
        Text(
          'المساجد المكتشفة (${QuranTextFormatter.toArabicDigits(count.toString())})',
          style: GoogleFonts.cairo(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: isDark ? _goldLight : context.primaryDarkColor,
          ),
        ),
        const Spacer(),
        if (_isLoading && _mosques.isNotEmpty)
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? _goldLight : accent,
            ),
          )
        else
          InkWell(
            onTap: _fetchMosques,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: isDark ? _goldLight : accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'تحديث',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? _goldLight : accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMosqueCard({
    required NearbyMosque mosque,
    required int index,
    required bool isSelected,
    required bool isDark,
    required Color accent,
  }) {
    final isNearest = index == 0 && _searchQuery.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? (isDark
                  ? const [Color(0xFF13332A), Color(0xFF0F2028)]
                  : const [Color(0xFFFFFBEB), Color(0xFFFDF3D0)])
              : context.appCardGradient,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? _gold
              : _gold.withValues(alpha: isDark ? 0.32 : 0.5),
          width: isSelected ? 1.6 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isNearest ? _gold : accent)
                      .withValues(alpha: isDark ? 0.2 : 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.mosque_rounded,
                  size: 22,
                  color: isNearest
                      ? (isDark ? _goldLight : const Color(0xFFB45309))
                      : (isDark ? _goldLight : accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mosque.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isNearest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _gold),
                            ),
                            child: Text(
                              'الأقرب',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? _goldLight
                                    : const Color(0xFF78350F),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mosque.address.isNotEmpty
                          ? '${mosque.address} • باتجاه ${mosque.cardinalDirectionArabic}'
                          : 'باتجاه ${mosque.cardinalDirectionArabic}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color:
                            isDark ? Colors.white60 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildInfoChip(
                icon: Icons.straighten_rounded,
                label: mosque.formattedDistanceArabic,
                isDark: isDark,
                accent: accent,
              ),
              _buildInfoChip(
                icon: Icons.directions_walk_rounded,
                label: mosque.walkingTimeArabic,
                isDark: isDark,
                accent: accent,
              ),
              _buildInfoChip(
                icon: Icons.directions_car_rounded,
                label: mosque.drivingTimeArabic,
                isDark: isDark,
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedMosque = mosque);
                    _moveMapTo(
                      LatLng(mosque.latitude, mosque.longitude),
                      zoom: 16.0,
                    );
                  },
                  icon: const Icon(Icons.location_searching_rounded, size: 17),
                  label: Text(
                    'عرض على الخريطة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? _goldLight : accent,
                    side: BorderSide(
                      color: _gold.withValues(alpha: isDark ? 0.5 : 0.7),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openGoogleMapsDirections(mosque),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: Text(
                    'الاتجاهات',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13.5,
            color: isDark ? _goldLight : accent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrErrorCard({
    required bool isDark,
    required Color accent,
    required String message,
    required bool isError,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.appCardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isError ? Icons.wifi_off_rounded : Icons.mosque_outlined,
            size: 40,
            color: isDark ? _goldLight : accent,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fetchMosques,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'إعادة المحاولة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openAllMosquesInGoogleMaps,
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: Text(
                    'خرائط جوجل',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
