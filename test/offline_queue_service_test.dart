import 'package:flutter_test/flutter_test.dart';
import 'package:resqflood_app/models/offline_item.dart';
import 'package:resqflood_app/services/local_database.dart';
import 'package:resqflood_app/services/offline_queue_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  final localDb = LocalDatabase.instance;
  final queueService = OfflineQueueService.instance;

  setUp(() async {
    final inMemoryDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    await localDb.setTestDatabase(inMemoryDb);
  });

  tearDown(() async {
    await localDb.closeForTesting();
  });

  group('OfflineItem model', () {
    test('serializes and deserializes SOS, update, and road_report types', () {
      for (final type in OfflineItemType.values) {
        final now = DateTime.parse('2026-11-25T15:00:00.000Z');
        final item = OfflineItem(
          id: 1,
          type: type,
          payload: {'lat': 3.139, 'lng': 101.6869, 'note': 'Test ${type.value}'},
          createdAt: now,
        );

        final restored = OfflineItem.fromMap(item.toMap());
        expect(restored.id, 1);
        expect(restored.type, type);
        expect(restored.payload['lat'], 3.139);
        expect(restored.status, 'pending');
        expect(restored.createdAt, now);
      }
    });

    test('throws ArgumentError for unsupported item types', () {
      expect(
            () => OfflineItemType.fromString('invalid_type'),
        throwsArgumentError,
      );
    });
  });

  group('OfflineQueueService', () {
    test('adds and lists SOS, quick updates, and road reports in FIFO order', () async {
      final sos = await queueService.queueSos({
        'urgency': 'critical',
        'victims': 4,
        'description': 'Water rising to second floor',
      });

      final update = await queueService.queueQuickUpdate({
        'status': 'safe_at_shelter',
        'shelter_name': 'SK Taman Sri Muda',
      });

      final roadReport = await queueService.queueRoadReport({
        'road_name': 'Persiaran Budiman',
        'severity': 'impassable',
      });

      expect(sos.id, isNotNull);
      expect(update.id, isNotNull);
      expect(roadReport.id, isNotNull);

      final allItems = await queueService.list();
      expect(allItems.length, 3);
      expect(allItems[0].type, OfflineItemType.sos);
      expect(allItems[0].payload['victims'], 4);
      expect(allItems[1].type, OfflineItemType.update);
      expect(allItems[2].type, OfflineItemType.roadReport);
      expect(await queueService.getQueuedCount(), 3);
    });

    test('filters listed items by OfflineItemType', () async {
      await queueService.queueSos({'note': 'SOS 1'});
      await queueService.queueRoadReport({'note': 'Road blocked'});
      await queueService.queueSos({'note': 'SOS 2'});

      final sosOnly = await queueService.list(type: OfflineItemType.sos);
      expect(sosOnly.length, 2);
      expect(sosOnly.every((item) => item.type == OfflineItemType.sos), isTrue);

      final roadsOnly = await queueService.list(type: OfflineItemType.roadReport);
      expect(roadsOnly.length, 1);
      expect(roadsOnly.first.payload['note'], 'Road blocked');
    });

    test('removes an item by ID and updates queue count stream', () async {
      final emittedCounts = <int>[];
      final sub = queueService.queueCountStream.listen(emittedCounts.add);

      final item1 = await queueService.queueSos({'note': 'First'});
      final item2 = await queueService.queueQuickUpdate({'note': 'Second'});

      expect(await queueService.getQueuedCount(), 2);

      final removed = await queueService.remove(item1.id!);
      expect(removed, isTrue);

      final remaining = await queueService.list();
      expect(remaining.length, 1);
      expect(remaining.first.id, item2.id);
      expect(await queueService.getQueuedCount(), 1);

      // Removing a non-existent ID returns false
      expect(await queueService.remove(9999), isFalse);

      await Future<void>.delayed(Duration.zero);
      expect(emittedCounts, containsAllInOrder([1, 2, 1]));

      await sub.cancel();
    });
  });
}