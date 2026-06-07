import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'package:flutter/foundation.dart';
import 'database.dart';

class HealthConnectService {
  static final HealthConnectService instance = HealthConnectService._();
  HealthConnectService._();

  final Health _health = Health();

  static const _types = [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_IN_BED];
  static const _permissions = [HealthDataAccess.READ, HealthDataAccess.READ];

  Future<HealthConnectAvailability> checkAvailability() async {
    // HealthKit ships with iOS — there's no separate SDK to install or check.
    if (Platform.isIOS) return HealthConnectAvailability.available;

    try {
      return await Health().getHealthConnectSdkStatus() ==
              HealthConnectSdkStatus.sdkAvailable
          ? HealthConnectAvailability.available
          : HealthConnectAvailability.notInstalled;
    } catch (_) {
      return HealthConnectAvailability.unavailable;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      await _health.configure();
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      return granted;
    } catch (e) {
      debugPrint('Health Connect permissions error: $e');
      return false;
    }
  }

  Future<List<SleepImportEntry>> fetchSleepData({int days = 30}) async {
    try {
      await _health.configure();
      final now = DateTime.now();
      final from = now.subtract(Duration(days: days));

      final data = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: now,
        types: _types,
      );

      // Group by day, take SLEEP_ASLEEP preferentially
      final grouped = <String, List<HealthDataPoint>>{};
      for (final point in data) {
        final dateStr = _fmt(point.dateFrom);
        grouped.putIfAbsent(dateStr, () => []).add(point);
      }

      final entries = <SleepImportEntry>[];
      for (final entry in grouped.entries) {
        // Find the longest continuous sleep window for this date
        final points = entry.value
          ..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

        if (points.isNotEmpty) {
          final start = points.first.dateFrom;
          final end = points.last.dateTo;
          var durationHrs = end.difference(start).inMinutes / 60.0;
          if (durationHrs < 0) durationHrs += 24;

          if (durationHrs >= 1.0 && durationHrs <= 14.0) {
            entries.add(SleepImportEntry(
              date: entry.key,
              sleepStart: start,
              sleepEnd: end,
              durationHours: durationHrs,
              source: points.first.sourceName,
            ));
          }
        }
      }

      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    } catch (e) {
      debugPrint('Health Connect fetch error: $e');
      return [];
    }
  }

  Future<int> importEntries(List<SleepImportEntry> entries) async {
    int imported = 0;
    for (final entry in entries) {
      try {
        await AppDatabase.instance.insertSleepLog({
          'date': entry.date,
          'sleep_start': entry.sleepStart.toIso8601String(),
          'sleep_end': entry.sleepEnd.toIso8601String(),
          'quality': 0, // no quality data from wearable
          'notes': 'Imported from ${entry.source}',
          'is_split_sleep': 0,
        });
        imported++;
      } catch (_) {}
    }
    return imported;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

enum HealthConnectAvailability { available, notInstalled, unavailable }

class SleepImportEntry {
  final String date;
  final DateTime sleepStart;
  final DateTime sleepEnd;
  final double durationHours;
  final String source;

  const SleepImportEntry({
    required this.date,
    required this.sleepStart,
    required this.sleepEnd,
    required this.durationHours,
    required this.source,
  });
}
