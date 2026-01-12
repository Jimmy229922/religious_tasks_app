import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();

  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // Test ID for development. Verify this before release!
  // Production IDs should be used when releasing to store.
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-9685582860512381~2240553823' // Test Android Interstitial
      : 'ca-app-pub-9685582860512381/2048982138'; // Test iOS Interstitial

  Future<void> _initAdMobConfig() async {
    // 1. Set Content Rating to "G" (General Audiences) - safest level.
    // 2. Tag for Child Directed Treatment (optional, but good for safety).
    // 3. Tag for Under Age of Consent.
    RequestConfiguration configuration = RequestConfiguration(
      maxAdContentRating:
          MaxAdContentRating.g, // "G" is for General Audiences (No +18)
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
    );
    await MobileAds.instance.updateRequestConfiguration(configuration);
  }

  Future<void> init() async {
    await MobileAds.instance.initialize();
    await _initAdMobConfig(); // Apply safety settings
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          debugPrint('Interstitial Ad Loaded');
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd(); // Preload the next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial Ad Failed to Load: $error');
          _isAdLoaded = false;
          // Retry after a delay could be implemented here
        },
      ),
    );
  }

  /// Shows the interstitial ad if loaded.
  /// returns true if ad was shown, false otherwise.
  Future<bool> showInterstitialAd() async {
    if (_isAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
      _isAdLoaded = false;
      _interstitialAd = null;
      return true;
    } else {
      debugPrint('Interstitial Ad not ready yet');
      // Attempt to load for next time if it wasn't loaded
      if (_interstitialAd == null) {
        _loadInterstitialAd();
      }
      return false;
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
