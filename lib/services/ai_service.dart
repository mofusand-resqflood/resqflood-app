import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SosAiExtraction {
  final int peopleCount;
  final String helpType;
  final String summary;

  const SosAiExtraction({
    required this.peopleCount,
    required this.helpType,
    required this.summary,
  });

  static const List<String> allowedHelpTypes = [
    'Evacuation',
    'Walking Support',
    'Water Inside House',
  ];

  factory SosAiExtraction.fromJson(Map<String, dynamic> json) {
    final rawCount = json['people_count'];
    final int count = rawCount is num
        ? rawCount.toInt().clamp(1, 999)
        : (int.tryParse(rawCount?.toString() ?? '') ?? 1).clamp(1, 999);

    final rawHelpType = json['help_type']?.toString().trim() ?? '';
    final String normalizedHelpType = allowedHelpTypes.contains(rawHelpType)
        ? rawHelpType
        : 'Evacuation';

    final rawSummary = json['summary']?.toString().trim() ?? '';

    return SosAiExtraction(
      peopleCount: count,
      helpType: normalizedHelpType,
      summary: rawSummary,
    );
  }

  SosAiExtraction copyWith({
    int? peopleCount,
    String? helpType,
    String? summary,
  }) {
    return SosAiExtraction(
      peopleCount: peopleCount ?? this.peopleCount,
      helpType: helpType ?? this.helpType,
      summary: summary ?? this.summary,
    );
  }
}

class AiExtractionException implements Exception {
  final String message;
  const AiExtractionException(this.message);

  @override
  String toString() => message;
}

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  static const Duration _timeout = Duration(seconds: 30);

  Future<SosAiExtraction> extractSosInfo(String description) async {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      throw const AiExtractionException(
        'Please describe your emergency situation first.',
      );
    }

    final connectivityResults = await Connectivity().checkConnectivity();
    final isOffline = connectivityResults.isEmpty ||
        connectivityResults.every((r) => r == ConnectivityResult.none);

    if (isOffline) {
      throw const AiExtractionException(
        'You are offline. Please fill in the manual details below.',
      );
    }

    try {
      final response = await Supabase.instance.client.functions
          .invoke(
        'extract-sos-info',
        body: {'message': trimmed},
      )
          .timeout(_timeout);

      if (response.status != 200) {
        throw const AiExtractionException(
          'AI service unavailable. Please use the manual form below.',
        );
      }

      final dynamic rawData = response.data;
      final Map<String, dynamic> jsonMap;

      if (rawData is Map<String, dynamic>) {
        jsonMap = rawData;
      } else if (rawData is String) {
        jsonMap = jsonDecode(rawData) as Map<String, dynamic>;
      } else {
        throw const AiExtractionException(
          'Invalid AI response format. Please fill in the manual form.',
        );
      }

      return SosAiExtraction.fromJson(jsonMap);
    } on TimeoutException {
      throw const AiExtractionException(
        'AI request timed out after 10 seconds. Please fill in the manual details below.',
      );
    } on AiExtractionException {
      rethrow;
    } catch (_) {
      throw const AiExtractionException(
        'Could not analyze your message automatically. Please fill in the manual form.',
      );
    }
  }
}
