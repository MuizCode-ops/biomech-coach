// lib/services/backup_service.dart
// Offline backup import and export service using JSON files.

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/lift_session.dart';
import 'database_service.dart';

class BackupService {
  /// Exports all workout logs to a JSON file and opens the native share menu.
  static Future<bool> exportBackup() async {
    try {
      final db = DatabaseService.instance;
      final sessions = db.getAllSessions();

      if (sessions.isEmpty) {
        return false;
      }

      // Convert all sessions to a JSON-compatible list
      final jsonList = sessions.map((s) => s.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

      // Save to a temporary file
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/biomech_coach_backup.json');
      await backupFile.writeAsString(jsonString);

      // Trigger the native share sheet using the latest SharePlus API
      final result = await SharePlus.instance.share(
        ShareParams(
          subject: 'Biomech Coach Backup Data',
          files: [XFile(backupFile.path)],
        ),
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      print('[BackupService] Export error: $e');
      return false;
    }
  }

  /// Opens the file picker to import a JSON backup file.
  /// Returns the number of newly imported (non-duplicate) sessions, or -1 on failure.
  static Future<int> importBackup() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        // User cancelled
        return -1;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      // Parse and validate JSON list
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      final db = DatabaseService.instance;
      final existingSessions = db.getAllSessions();
      int importCount = 0;

      for (var item in jsonList) {
        if (item is Map<String, dynamic>) {
          final session = LiftSession.fromJson(item);

          // Check if session already exists based on startTime
          final isDuplicate = existingSessions.any(
            (s) => s.startTime.isAtSameMomentAs(session.startTime),
          );

          if (!isDuplicate) {
            await db.saveSession(session);
            importCount++;
          }
        }
      }

      return importCount;
    } catch (e) {
      print('[BackupService] Import error: $e');
      return -1;
    }
  }
}
