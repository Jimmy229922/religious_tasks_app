import 'dart:math' as math;

class QiblaGeodesicResult {
  final double bearingDeg;
  final double distanceKm;
  final bool isValid;
  final bool isNearKaaba;

  const QiblaGeodesicResult({
    required this.bearingDeg,
    required this.distanceKm,
    required this.isValid,
    this.isNearKaaba = false,
  });
}

class QiblaGeoPoint {
  final double latitude;
  final double longitude;

  const QiblaGeoPoint(this.latitude, this.longitude);
}

class QiblaGeodesicService {
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  // WGS84 ellipsoid constants
  static const double _a = 6378137.0;
  static const double _f = 1.0 / 298.257223563;
  static const double _b = _a * (1.0 - _f);

  static double _degToRad(double deg) => deg * math.pi / 180.0;
  static double _radToDeg(double rad) => rad * 180.0 / math.pi;

  static double normalizeAngle(double angle) {
    if (angle.isNaN || angle.isInfinite) return 0.0;
    final normalized = ((angle % 360.0) + 360.0) % 360.0;
    return normalized >= 360.0 || normalized < 0.0 ? 0.0 : normalized;
  }

  static double normalizeLongitude(double lng) {
    if (lng.isNaN || lng.isInfinite) return 0.0;
    var wrapped = ((lng + 180.0) % 360.0 + 360.0) % 360.0 - 180.0;
    if (wrapped == -180.0 && lng > 0) wrapped = 180.0;
    return wrapped;
  }

  /// Shortest signed angular difference in [-180, 180).
  /// Positive = clockwise (turn right), negative = counter-clockwise (turn left).
  static double shortestSignedDelta(double fromDeg, double toDeg) {
    return ((toDeg - fromDeg + 540.0) % 360.0) - 180.0;
  }

  static bool isAligned(double signedDiffDeg, {double toleranceDeg = 4.0}) {
    return signedDiffDeg.abs() <= toleranceDeg;
  }

  static bool isValidCoordinate(double lat, double lng) {
    if (lat.isNaN || lat.isInfinite || lng.isNaN || lng.isInfinite) {
      return false;
    }
    return lat >= -90.0 && lat <= 90.0;
  }

  /// Authoritative WGS84 Vincenty inverse calculation from (lat, lng) to the Kaaba.
  /// Falls back to spherical azimuth only at antipodal/non-convergent points.
  static QiblaGeodesicResult calculate(double lat, double lng) {
    if (!isValidCoordinate(lat, lng)) {
      return const QiblaGeodesicResult(
        bearingDeg: 0.0,
        distanceKm: 0.0,
        isValid: false,
      );
    }

    final safeLng = normalizeLongitude(lng);

    if (lat >= 89.999) {
      final dist = _sphericalDistanceKm(lat, safeLng, kaabaLatitude, kaabaLongitude);
      return QiblaGeodesicResult(
        bearingDeg: 180.0,
        distanceKm: dist,
        isValid: true,
      );
    }
    if (lat <= -89.999) {
      final dist = _sphericalDistanceKm(lat, safeLng, kaabaLatitude, kaabaLongitude);
      return QiblaGeodesicResult(
        bearingDeg: 0.0,
        distanceKm: dist,
        isValid: true,
      );
    }

    if ((lat - kaabaLatitude).abs() < 1e-5 &&
        (safeLng - kaabaLongitude).abs() < 1e-5) {
      return const QiblaGeodesicResult(
        bearingDeg: 0.0,
        distanceKm: 0.0,
        isValid: true,
        isNearKaaba: true,
      );
    }

    final vincenty = _vincentyInverse(
      lat,
      safeLng,
      kaabaLatitude,
      kaabaLongitude,
    );
    if (vincenty != null) {
      return QiblaGeodesicResult(
        bearingDeg: normalizeAngle(vincenty.initialBearingDeg),
        distanceKm: vincenty.distanceMeters / 1000.0,
        isValid: true,
        isNearKaaba: vincenty.distanceMeters < 15.0,
      );
    }

    // Fallback for antipodal points where Vincenty does not converge
    final sphericalBearing =
        _sphericalBearing(lat, safeLng, kaabaLatitude, kaabaLongitude);
    final sphericalDist =
        _sphericalDistanceKm(lat, safeLng, kaabaLatitude, kaabaLongitude);
    return QiblaGeodesicResult(
      bearingDeg: normalizeAngle(sphericalBearing),
      distanceKm: sphericalDist,
      isValid: true,
    );
  }

  static ({double initialBearingDeg, double distanceMeters})? _vincentyInverse(
    double lat1Deg,
    double lng1Deg,
    double lat2Deg,
    double lng2Deg,
  ) {
    final phi1 = _degToRad(lat1Deg);
    final phi2 = _degToRad(lat2Deg);
    final u1 = math.atan((1.0 - _f) * math.tan(phi1));
    final u2 = math.atan((1.0 - _f) * math.tan(phi2));
    final l = _degToRad(normalizeLongitude(lng2Deg - lng1Deg));

    final sinU1 = math.sin(u1);
    final cosU1 = math.cos(u1);
    final sinU2 = math.sin(u2);
    final cosU2 = math.cos(u2);

    var lambda = l;
    double sinSigma = 0.0;
    double cosSigma = 0.0;
    double sigma = 0.0;
    double sinAlpha = 0.0;
    double cosSqAlpha = 0.0;
    double cos2SigmaM = 0.0;

    for (int iter = 0; iter < 200; iter++) {
      final sinLambda = math.sin(lambda);
      final cosLambda = math.cos(lambda);
      final t1 = cosU2 * sinLambda;
      final t2 = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda;
      sinSigma = math.sqrt(t1 * t1 + t2 * t2);
      if (sinSigma == 0.0) {
        return (initialBearingDeg: 0.0, distanceMeters: 0.0);
      }
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = math.atan2(sinSigma, cosSigma);
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1.0 - sinAlpha * sinAlpha;
      cos2SigmaM =
          cosSqAlpha != 0.0 ? cosSigma - 2.0 * sinU1 * sinU2 / cosSqAlpha : 0.0;

      final c = _f / 16.0 * cosSqAlpha * (4.0 + _f * (4.0 - 3.0 * cosSqAlpha));
      final prevLambda = lambda;
      lambda = l +
          (1.0 - c) *
              _f *
              sinAlpha *
              (sigma +
                  c *
                      sinSigma *
                      (cos2SigmaM +
                          c * cosSigma * (-1.0 + 2.0 * cos2SigmaM * cos2SigmaM)));

      if ((lambda - prevLambda).abs() <= 1e-12) {
        final uSq = cosSqAlpha * (_a * _a - _b * _b) / (_b * _b);
        final aCoeff = 1.0 +
            uSq /
                16384.0 *
                (4096.0 + uSq * (-768.0 + uSq * (320.0 - 175.0 * uSq)));
        final bCoeff = uSq /
            1024.0 *
            (256.0 + uSq * (-128.0 + uSq * (74.0 - 47.0 * uSq)));
        final deltaSigma = bCoeff *
            sinSigma *
            (cos2SigmaM +
                bCoeff /
                    4.0 *
                    (cosSigma * (-1.0 + 2.0 * cos2SigmaM * cos2SigmaM) -
                        bCoeff /
                            6.0 *
                            cos2SigmaM *
                            (-3.0 + 4.0 * sinSigma * sinSigma) *
                            (-3.0 + 4.0 * cos2SigmaM * cos2SigmaM)));
        final s = _b * aCoeff * (sigma - deltaSigma);
        final fwdAz = math.atan2(
          cosU2 * math.sin(lambda),
          cosU1 * sinU2 - sinU1 * cosU2 * math.cos(lambda),
        );
        return (
          initialBearingDeg: normalizeAngle(_radToDeg(fwdAz)),
          distanceMeters: s,
        );
      }
    }
    return null;
  }

  static double _sphericalBearing(
    double lat1Deg,
    double lng1Deg,
    double lat2Deg,
    double lng2Deg,
  ) {
    final phi1 = _degToRad(lat1Deg);
    final phi2 = _degToRad(lat2Deg);
    final dLambda = _degToRad(lng2Deg - lng1Deg);
    final y = math.sin(dLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    return normalizeAngle(_radToDeg(math.atan2(y, x)));
  }

  static double _sphericalDistanceKm(
    double lat1Deg,
    double lng1Deg,
    double lat2Deg,
    double lng2Deg,
  ) {
    const r = 6371.0088;
    final phi1 = _degToRad(lat1Deg);
    final phi2 = _degToRad(lat2Deg);
    final dPhi = _degToRad(lat2Deg - lat1Deg);
    final dLambda = _degToRad(lng2Deg - lng1Deg);
    final h = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
  }

  /// Computes a destination point from (lat, lng) along [bearingDeg] for [distanceMeters].
  /// Used for the short local directional ray on the map.
  static QiblaGeoPoint destinationPoint(
    double lat,
    double lng,
    double bearingDeg,
    double distanceMeters,
  ) {
    const r = 6371008.8;
    final delta = distanceMeters / r;
    final theta = _degToRad(bearingDeg);
    final phi1 = _degToRad(lat);
    final lambda1 = _degToRad(lng);

    final sinPhi2 = math.sin(phi1) * math.cos(delta) +
        math.cos(phi1) * math.sin(delta) * math.cos(theta);
    final phi2 = math.asin(sinPhi2.clamp(-1.0, 1.0));
    final lambda2 = lambda1 +
        math.atan2(
          math.sin(theta) * math.sin(delta) * math.cos(phi1),
          math.cos(delta) - math.sin(phi1) * math.sin(phi2),
        );

    return QiblaGeoPoint(
      _radToDeg(phi2),
      normalizeLongitude(_radToDeg(lambda2)),
    );
  }

  /// Generates intermediate points along the great-circle path to the Kaaba.
  static List<QiblaGeoPoint> generateGeodesicPath(
    double startLat,
    double startLng, {
    int segments = 48,
  }) {
    if (!isValidCoordinate(startLat, startLng)) return const [];
    final phi1 = _degToRad(startLat);
    final lambda1 = _degToRad(normalizeLongitude(startLng));
    final phi2 = _degToRad(kaabaLatitude);
    final lambda2 = _degToRad(kaabaLongitude);

    final d = 2.0 *
        math.asin(math.min(
          1.0,
          math.sqrt(
            math.pow(math.sin((phi2 - phi1) / 2.0), 2) +
                math.cos(phi1) *
                    math.cos(phi2) *
                    math.pow(math.sin((lambda2 - lambda1) / 2.0), 2),
          ),
        ));

    if (d < 1e-7) {
      return [
        QiblaGeoPoint(startLat, normalizeLongitude(startLng)),
        const QiblaGeoPoint(kaabaLatitude, kaabaLongitude),
      ];
    }

    final points = <QiblaGeoPoint>[];
    final sinD = math.sin(d);
    for (int i = 0; i <= segments; i++) {
      final f = i / segments;
      final a = math.sin((1.0 - f) * d) / sinD;
      final b = math.sin(f * d) / sinD;
      final x = a * math.cos(phi1) * math.cos(lambda1) +
          b * math.cos(phi2) * math.cos(lambda2);
      final y = a * math.cos(phi1) * math.sin(lambda1) +
          b * math.cos(phi2) * math.sin(lambda2);
      final z = a * math.sin(phi1) + b * math.sin(phi2);
      final phi = math.atan2(z, math.sqrt(x * x + y * y));
      final lambda = math.atan2(y, x);
      points.add(QiblaGeoPoint(_radToDeg(phi), normalizeLongitude(_radToDeg(lambda))));
    }
    return points;
  }
}
