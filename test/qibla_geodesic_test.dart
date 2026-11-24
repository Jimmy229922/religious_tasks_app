import 'package:flutter_test/flutter_test.dart';
import 'package:religious_tasks_app/features/qibla/services/qibla_geodesic_service.dart';

void main() {
  group('QiblaGeodesicService WGS84 Reference Bearings', () {
    const toleranceDeg = 0.08;

    test('Cairo bearing matches WGS84 geodesic (~135.982°)', () {
      final res = QiblaGeodesicService.calculate(30.0444, 31.2357);
      expect(res.isValid, isTrue);
      expect(res.bearingDeg, closeTo(135.982, toleranceDeg));
    });

    test('Fayoum bearing matches WGS84 geodesic (~132.001°)', () {
      final res = QiblaGeodesicService.calculate(29.3084, 30.8428);
      expect(res.isValid, isTrue);
      expect(res.bearingDeg, closeTo(132.001, toleranceDeg));
    });

    test('Jakarta bearing matches WGS84 geodesic (~295.025°)', () {
      final res = QiblaGeodesicService.calculate(-6.2088, 106.8456);
      expect(res.isValid, isTrue);
      expect(res.bearingDeg, closeTo(295.025, toleranceDeg));
    });

    test('New York bearing matches WGS84 geodesic (~58.396°)', () {
      final res = QiblaGeodesicService.calculate(40.7128, -74.0060);
      expect(res.isValid, isTrue);
      expect(res.bearingDeg, closeTo(58.396, toleranceDeg));
    });

    test('London bearing matches WGS84 geodesic (~118.868°)', () {
      final res = QiblaGeodesicService.calculate(51.5074, -0.1278);
      expect(res.isValid, isTrue);
      expect(res.bearingDeg, closeTo(118.868, toleranceDeg));
    });

    test('Sydney bearing matches WGS84 geodesic (~277.319°)', () {
      final res = QiblaGeodesicService.calculate(-33.8688, 151.2093);
      expect(res.isValid, isTrue);
      expect(res.bearingDeg, closeTo(277.319, toleranceDeg));
    });
  });

  group('QiblaGeodesicService Edge Cases & Angular Math', () {
    test('Handles 359° to 0° wraparound and shortestSignedDelta', () {
      expect(QiblaGeodesicService.normalizeAngle(360.0), equals(0.0));
      expect(QiblaGeodesicService.normalizeAngle(-1.0), equals(359.0));
      expect(QiblaGeodesicService.shortestSignedDelta(359.0, 1.0), closeTo(2.0, 1e-6));
      expect(QiblaGeodesicService.shortestSignedDelta(1.0, 359.0), closeTo(-2.0, 1e-6));
      expect(QiblaGeodesicService.shortestSignedDelta(0.0, 180.0), closeTo(-180.0, 1e-6));
      expect(QiblaGeodesicService.shortestSignedDelta(90.0, 180.0), closeTo(90.0, 1e-6));
      expect(QiblaGeodesicService.shortestSignedDelta(270.0, 180.0), closeTo(-90.0, 1e-6));
    });

    test('Handles longitude wraparound at ±180°', () {
      final a = QiblaGeodesicService.calculate(0.0, 180.0);
      final b = QiblaGeodesicService.calculate(0.0, -180.0);
      expect(a.isValid, isTrue);
      expect(b.isValid, isTrue);
      expect(a.bearingDeg, closeTo(b.bearingDeg, 0.01));
    });

    test('Handles poles safely', () {
      final northPole = QiblaGeodesicService.calculate(90.0, 0.0);
      final southPole = QiblaGeodesicService.calculate(-90.0, 0.0);
      expect(northPole.isValid, isTrue);
      expect(northPole.bearingDeg, equals(180.0));
      expect(southPole.isValid, isTrue);
      expect(southPole.bearingDeg, equals(0.0));
    });

    test('Handles near-Kaaba and antipodal points safely', () {
      final atKaaba = QiblaGeodesicService.calculate(21.4225, 39.8262);
      expect(atKaaba.isValid, isTrue);
      expect(atKaaba.isNearKaaba, isTrue);

      final antipodal = QiblaGeodesicService.calculate(-21.4225, -140.1738);
      expect(antipodal.isValid, isTrue);
      expect(antipodal.bearingDeg.isFinite, isTrue);
    });

    test('Rejects NaN and out-of-range latitude', () {
      expect(QiblaGeodesicService.calculate(double.nan, 31.0).isValid, isFalse);
      expect(QiblaGeodesicService.calculate(95.0, 31.0).isValid, isFalse);
    });

    test('Generates geodesic path ending at the Kaaba', () {
      final path = QiblaGeodesicService.generateGeodesicPath(30.0444, 31.2357);
      expect(path.length, greaterThan(10));
      expect(path.first.latitude, closeTo(30.0444, 0.001));
      expect(path.last.latitude, closeTo(QiblaGeodesicService.kaabaLatitude, 0.001));
      expect(path.last.longitude, closeTo(QiblaGeodesicService.kaabaLongitude, 0.001));
    });
  });
}
