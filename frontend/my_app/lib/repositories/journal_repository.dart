// lib/repositories/journal_repository.dart

import '../services/api_service.dart';
import '../models/journal_entry.dart';

class JournalRepository {
  final ApiService _api = ApiService();

  /// Save a new journal entry
  Future<bool> saveJournalEntry(JournalEntry entry) async {
    try {
      print('📤 Saving journal entry...');
      
      final response = await _api.post('/journal-entries', entry.toJson());
      
      print('✅ Journal entry saved: $response');
      return true;
    } catch (e) {
      print('❌ Error saving journal entry: $e');
      return false;
    }
  }

  /// Get all journal entries for the current user
  Future<List<JournalEntry>> getAllJournalEntries() async {
    try {
      print('📤 Fetching all journal entries...');
      
      final response = await _api.get('/journal-entries');
      
      if (response == null) {
        print('⚠️ No response from server');
        return [];
      }

      // The response structure from your Java DTO
      if (response is Map<String, dynamic> && response.containsKey('journalEntries')) {
        final List<dynamic> entriesJson = response['journalEntries'] as List<dynamic>;
        
        final entries = entriesJson
            .map((json) => JournalEntry.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('✅ Loaded ${entries.length} journal entries');
        return entries;
      }
      
      print('⚠️ Unexpected response format: $response');
      return [];
      
    } catch (e) {
      print('❌ Error fetching journal entries: $e');
      rethrow;
    }
  }

  /// Get a specific journal entry by ID
  Future<JournalEntry?> getJournalEntryById(int id) async {
    try {
      print('📤 Fetching journal entry: $id');
      
      final data = await _api.get('/journal-entries/$id');
      
      if (data != null) {
        return JournalEntry.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching journal entry by ID: $e');
      return null;
    }
  }

  /// Delete a journal entry
  Future<bool> deleteJournalEntry(int id) async {
    try {
      print('📤 Deleting journal entry: $id');
      
      await _api.delete('/journal-entries/$id');
      
      print('✅ Journal entry deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting journal entry: $e');
      return false;
    }
  }
}