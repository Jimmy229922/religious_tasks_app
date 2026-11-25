import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class GlobalChallengeService {
  static final GlobalChallengeService _instance =
      GlobalChallengeService._internal();
  factory GlobalChallengeService() => _instance;
  GlobalChallengeService._internal();

  final _supabase = Supabase.instance.client;
  bool get hasAuthenticatedSession => _supabase.auth.currentSession != null;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Stream controller for real-time updates
  final _countController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get challengeStream => _countController.stream;

  RealtimeChannel? _channel;

  /// Start listening to real-time changes on the global_challenges table
  void subscribeToChallenge() {
    _channel?.unsubscribe();
    _channel = _supabase
        .channel('public:global_challenges')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'global_challenges',
          callback: (payload) {
            if (payload.newRecord.isNotEmpty && !_countController.isClosed) {
              _countController.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    // Initial fetch
    fetchCurrentStatus();
  }

  /// Fetch initial data from Supabase
  Future<void> fetchCurrentStatus() async {
    try {
      final data = await _supabase
          .from('global_challenges')
          .select()
          .eq('id', 'tasbih_challenge')
          .single()
          .timeout(const Duration(seconds: 12));
      if (!_countController.isClosed) {
        _countController.add(data);
      }
    } catch (e) {
      debugPrint('Error fetching challenge status: $e');
    }
  }

  /// Increment the global counter through the reviewed, atomic server RPC.
  Future<bool> incrementGlobalCounter(int amount) async {
    if (amount <= 0 || amount > 100) return false;
    if (!hasAuthenticatedSession) return false;

    try {
      await _supabase
          .rpc('increment_challenge', params: {'amount': amount})
          .timeout(const Duration(seconds: 12));
      await fetchCurrentStatus();
      return true;
    } catch (e) {
      debugPrint('Error incrementing global counter: $e');
      return false;
    }
  }

  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
