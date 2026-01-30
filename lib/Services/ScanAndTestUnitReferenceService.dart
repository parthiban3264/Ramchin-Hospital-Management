import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class ScanAndTestUnitReferenceService {
  /// Create unit reference
  Future<void> create(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Create unit reference failed');
    }
  }

  /// Get all unit references by hospitals 
  Future<List<dynamic>> getByHospital(int hospitalId) async {
    final res = await http.get(Uri.parse('$baseUrl/hospital/$hospitalId'));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body);
    }
    throw Exception('Failed to load unit references');
  }

  /// Delete unit reference
  Future<void> delete(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/$id'));

    if (res.statusCode != 200) {
      throw Exception('Delete unit reference failed');
    }
  }
}
