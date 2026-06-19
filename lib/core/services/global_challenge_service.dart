import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class GlobalChallengeService {
  static final GlobalChallengeService _instance = GlobalChallengeService._internal();
  factory GlobalChallengeService() => _instance;
  GlobalChallengeService._internal();

  final _supabase = Supabase.instance.client;
  
  // Stream controller for real-time updates
  final _countController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get challengeStream => _countController.stream;

  RealtimeChannel? _channel;

  /// Start listening to real-time changes on the global_challenges table
  void subscribeToChallenge() {
    _channel = _supabase
        .channel('public:global_challenges')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'global_challenges',
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
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
          .single();
      _countController.add(data);
    } catch (e) {
      debugPrint('Error fetching challenge status: $e');
    }
  }

  /// Increment the global counter
  Future<void> incrementGlobalCounter(int amount) async {
    try {
      // Using a RPC or direct update. Since we want to be safe with concurrent updates, 
      // in a real app a database function is better. 
      // For now, we'll fetch and update or use a simple increment logic if Supabase supports it directly via client.
      // Supabase JS/Dart client doesn't have a direct atomic increment yet without an RPC function.
      
      // Let's use an RPC if you created one, or a simple update for now.
      // Ideally, the user should run this SQL in Supabase:
      /*
      create or replace function increment_challenge(amount int)
      returns void as $$
      update global_challenges
      set count = count + amount
      where id = 'tasbih_challenge';
      $$ language sql;
      */
      
      // Try to call RPC if exists, else fallback to simple update (though less accurate with many users)
      try {
        await _supabase.rpc('increment_challenge', params: {'amount': amount});
      } catch (e) {
        // Fallback: Fetch current, add, and save (Note: can cause race conditions)
        final data = await _supabase.from('global_challenges').select('count').eq('id', 'tasbih_challenge').single();
        final currentCount = data['count'] as int;
        await _supabase.from('global_challenges').update({'count': currentCount + amount}).eq('id', 'tasbih_challenge');
      }
      await fetchCurrentStatus();
    } catch (e) {
      debugPrint('Error incrementing global counter: $e');
    }
  }

  void dispose() {
    _channel?.unsubscribe();
    _countController.close();
  }
}
