import 'dart:convert';

import '../models/sos_request.dart';
import 'offline_queue_service.dart';

class SosService {
  SosService._();

  static final SosService instance = SosService._();

  final OfflineQueueService _queueService = OfflineQueueService.instance;

  Future<int> submitRequest(SosRequest request) async {
    final payload = jsonEncode({
      'emergency_type': request.emergencyType,
      'description': request.description,
      'location': request.location,
      'people_affected': request.peopleAffected,
      'medical_emergency': request.medicalEmergency,
      'created_at': request.createdAt.toIso8601String(),
    });

    return await _queueService.addToQueue(requestType: 'sos', payload: payload);
  }
}
