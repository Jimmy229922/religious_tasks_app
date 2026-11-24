import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/qibla/services/qibla_geodesic_service.dart';

class QiblaInteractiveMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double qiblaBearingDeg;
  final double? deviceHeadingDeg;
  final bool isHeadingReliable;
  final bool isDark;

  const QiblaInteractiveMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.qiblaBearingDeg,
    required this.deviceHeadingDeg,
    required this.isHeadingReliable,
    required this.isDark,
  });

  @override
  State<QiblaInteractiveMap> createState() => _QiblaInteractiveMapState();
}

class _QiblaInteractiveMapState extends State<QiblaInteractiveMap> {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFFDE68A);

  final MapController _mapController = MapController();
  bool _isSatellite = true;
  bool _followHeading = true;
  bool _showFullGeodesic = false;
  double _currentZoom = 16.0;

  @override
  void didUpdateWidget(covariant QiblaInteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_followHeading &&
        widget.isHeadingReliable &&
        widget.deviceHeadingDeg != null &&
        !_showFullGeodesic) {
      try {
        _mapController.rotate(-widget.deviceHeadingDeg!);
      } catch (_) {}
    } else if (!_followHeading && oldWidget.deviceHeadingDeg != null) {
      try {
        _mapController.rotate(0.0);
      } catch (_) {}
    }

    if ((oldWidget.latitude - widget.latitude).abs() > 0.001 ||
        (oldWidget.longitude - widget.longitude).abs() > 0.001) {
      _recenterMap();
    }
  }

  void _recenterMap() {
    try {
      if (_showFullGeodesic) {
        final bounds = LatLngBounds.fromPoints([
          LatLng(widget.latitude, widget.longitude),
          const LatLng(
            QiblaGeodesicService.kaabaLatitude,
            QiblaGeodesicService.kaabaLongitude,
          ),
        ]);
        _mapController.rotate(0.0);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(42),
          ),
        );
      } else {
        _currentZoom = 16.0;
        _mapController.move(
          LatLng(widget.latitude, widget.longitude),
          _currentZoom,
        );
        if (_followHeading &&
            widget.isHeadingReliable &&
            widget.deviceHeadingDeg != null) {
          _mapController.rotate(-widget.deviceHeadingDeg!);
        } else {
          _mapController.rotate(0.0);
        }
      }
    } catch (_) {}
  }

  void _toggleFollowHeading() {
    if (!widget.isHeadingReliable || widget.deviceHeadingDeg == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _followHeading = !_followHeading;
      if (_followHeading && _showFullGeodesic) {
        _showFullGeodesic = false;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _recenterMap());
  }

  void _toggleFullGeodesic() {
    HapticFeedback.selectionClick();
    setState(() {
      _showFullGeodesic = !_showFullGeodesic;
      if (_showFullGeodesic) {
        _followHeading = false;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _recenterMap());
  }

  @override
  Widget build(BuildContext context) {
    final userLatLng = LatLng(widget.latitude, widget.longitude);
    const kaabaLatLng = LatLng(
      QiblaGeodesicService.kaabaLatitude,
      QiblaGeodesicService.kaabaLongitude,
    );

    final localRayEnd = QiblaGeodesicService.destinationPoint(
      widget.latitude,
      widget.longitude,
      widget.qiblaBearingDeg,
      450.0,
    );
    final localRayLatLng = LatLng(localRayEnd.latitude, localRayEnd.longitude);

    final geodesicPoints = _showFullGeodesic
        ? QiblaGeodesicService.generateGeodesicPath(
            widget.latitude,
            widget.longitude,
          ).map((p) => LatLng(p.latitude, p.longitude)).toList()
        : <LatLng>[userLatLng, localRayLatLng];

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
          color: _gold.withValues(alpha: widget.isDark ? 0.5 : 0.7),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isDark ? Colors.black : _gold).withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withValues(alpha: widget.isDark ? 0.16 : 0.14),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    size: 18,
                    color: widget.isDark ? _goldLight : context.primaryColor,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اتجاه القبلة على الخريطة',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark
                              ? _goldLight
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'الزاوية من الشمال الحقيقي: ${QuranTextFormatter.toArabicDigits(widget.qiblaBearingDeg.toStringAsFixed(1))}°',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: widget.isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildModeBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildToggleChip(
                  label: _followHeading ? 'تتبع اتجاه الهاتف' : 'الشمال للأعلى',
                  icon: _followHeading
                      ? Icons.screen_rotation_alt_rounded
                      : Icons.north_rounded,
                  active: _followHeading,
                  enabled: widget.isHeadingReliable && widget.deviceHeadingDeg != null,
                  onTap: _toggleFollowHeading,
                ),
                _buildToggleChip(
                  label: _showFullGeodesic ? 'عرض المسار الكامل' : 'شعاع محلي دقيق',
                  icon: Icons.timeline_rounded,
                  active: _showFullGeodesic,
                  enabled: true,
                  onTap: _toggleFullGeodesic,
                ),
                _buildToggleChip(
                  label: _isSatellite ? 'قمر صناعي' : 'خريطة عادية',
                  icon: Icons.layers_rounded,
                  active: _isSatellite,
                  enabled: true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isSatellite = !_isSatellite);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 290,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: userLatLng,
                        initialZoom: _currentZoom,
                        minZoom: 2.0,
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
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: geodesicPoints,
                              strokeWidth: _showFullGeodesic ? 3.2 : 4.2,
                              color: _gold,
                              borderStrokeWidth: 1.5,
                              borderColor: const Color(0xFF041D16),
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            if (!_showFullGeodesic)
                              Marker(
                                point: localRayLatLng,
                                width: 28,
                                height: 28,
                                child: Transform.rotate(
                                  angle: widget.qiblaBearingDeg * math.pi / 180.0,
                                  child: const Icon(
                                    Icons.navigation_rounded,
                                    color: _gold,
                                    size: 24,
                                  ),
                                ),
                              ),
                            Marker(
                              point: kaabaLatLng,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF041D16),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _gold, width: 2),
                                ),
                                child: const Center(
                                  child: Text('🕋', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ),
                            Marker(
                              point: userLatLng,
                              width: 44,
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (widget.isHeadingReliable &&
                                      widget.deviceHeadingDeg != null)
                                    Transform.rotate(
                                      angle: widget.deviceHeadingDeg! * math.pi / 180.0,
                                      child: const Icon(
                                        Icons.navigation_rounded,
                                        color: Color(0xFF10B981),
                                        size: 38,
                                      ),
                                    ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ],
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
                          _buildMapBtn(
                            icon: Icons.add,
                            tooltip: 'تكبير',
                            onTap: () {
                              final next = (_currentZoom + 1.0).clamp(2.0, 18.5);
                              _mapController.move(
                                _mapController.camera.center,
                                next,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildMapBtn(
                            icon: Icons.remove,
                            tooltip: 'تصغير',
                            onTap: () {
                              final next = (_currentZoom - 1.0).clamp(2.0, 18.5);
                              _mapController.move(
                                _mapController.camera.center,
                                next,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildMapBtn(
                            icon: Icons.my_location_rounded,
                            tooltip: 'إعادة التمركز',
                            onTap: _recenterMap,
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

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: widget.isDark ? 0.16 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: Text(
        _followHeading ? 'متحرك' : 'شمال ثابت',
        style: GoogleFonts.cairo(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: widget.isDark ? _goldLight : const Color(0xFF78350F),
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool active,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: widget.isDark
                        ? const [Color(0xFF92400E), Color(0xFFD4AF37)]
                        : const [Color(0xFFFDE68A), Color(0xFFE5B84B)],
                  )
                : null,
            color: active
                ? null
                : (widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? _gold : _gold.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: active
                    ? (widget.isDark ? Colors.white : const Color(0xFF451A03))
                    : (widget.isDark ? _goldLight : const Color(0xFF78350F)),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: active
                      ? (widget.isDark ? Colors.white : const Color(0xFF451A03))
                      : (widget.isDark
                          ? Colors.white70
                          : const Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapBtn({
    required IconData icon,
    required String tooltip,
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
            color: widget.isDark
                ? const Color(0xFF0A241D).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold.withValues(alpha: 0.65)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: widget.isDark ? _goldLight : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}
