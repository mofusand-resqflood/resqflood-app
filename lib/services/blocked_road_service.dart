import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blocked_road.dart';

class BlockedRoadService {
  Stream<List<BlockedRoad>> getVerifiedRoads() {
    return Supabase.instance.client
        .from('blocked_roads')
        .stream(primaryKey: ['id'])
        .eq('status', 'verified')
        .map((data) => data.map((json) => BlockedRoad.fromJson(json)).toList());
  }
}
