import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sos_request.dart';
import 'connectivity_service.dart';
import 'offline_queue_service.dart';

class SosSubmissionResult {
  const SosSubmissionResult._({required this.id, required this.isQueued});

  factory SosSubmissionResult.server(String requestId) {
    return SosSubmissionResult._(id: requestId, isQueued: false);
  }

  factory SosSubmissionResult.queued(int queueId) {
    return SosSubmissionResult._(id: queueId.toString(), isQueued: true);
  }

  /// A server UUID when submitted online, or a local queue ID when offline.
  final String id;
  final bool isQueued;
}

class SosService {
  SosService._();

  static final SosService instance = SosService._();

  final OfflineQueueService _queueService = OfflineQueueService.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  Future<SosSubmissionResult> submitRequest(SosRequest request) async {
    final hasInternet = await _connectivityService.checkConnection();

    if (!hasInternet) {
      final payload = jsonEncode({
        'emergency_type': request.emergencyType,
        'description': request.description,
        'location': request.location,
        'people_affected': request.peopleAffected,
        'medical_emergency': request.medicalEmergency,
        'created_at': request.createdAt.toIso8601String(),
      });

      final queueId = await _queueService.addToQueue(
        requestType: 'sos',
        payload: payload,
      );

      return SosSubmissionResult.queued(queueId);
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to submit an SOS request.');
    }

    // The current requests table has no separate address column.
    // Preserve the resident-entered location in its description.
    final fullDescription = [
      'Reported location: ${request.location}',
      'Medical emergency: ${request.medicalEmergency ? 'Yes' : 'No'}',
      if (request.description.trim().isNotEmpty) request.description.trim(),
    ].join('\n\n');

    final response = await client
        .from('requests')
        .insert({
          'resident_id': user.id,
          'help_type': request.emergencyType,
          'people_count': request.peopleAffected,
          'description': fullDescription,
        })
        .select('id')
        .single();

    final requestId = response['id'] as String;

    return SosSubmissionResult.server(requestId);
  }
}
